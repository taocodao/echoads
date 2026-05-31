// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @dev Chainlink AggregatorV3 — inline to avoid extra lib dependency pre-TGE.
interface AggregatorV3Interface {
    function latestRoundData() external view returns (
        uint80  roundId,
        int256  answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80  answeredInRound
    );
}

interface ICMXSTokenBurner {
    function burnForAd(address advertiser, uint256 cmxsAmount) external;
}

interface ITreasury {
    function recordPlatformFeeIncome(uint256 usdcAmount) external;
}

/**
 * @title AdBurnV2
 * @notice Spec-compliant ad spend engine.
 *         Advertisers deposit USDC → USDC is split (platform fee → Treasury,
 *         remainder → content partner) → CMXS is burned at the Chainlink
 *         price-derived rate → campaign is recorded for DeliveryOracleV2.
 *
 *         Pre-TGE: if `priceFeed` is address(0) the contract uses a fixed
 *         fallback price set by governance until a Chainlink feed is available.
 */
contract AdBurnV2 is AccessControl, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // ── Roles ─────────────────────────────────────────────────────────────────

    bytes32 public constant GOVERNANCE_ROLE   = keccak256("GOVERNANCE_ROLE");
    bytes32 public constant ORACLE_CALLER_ROLE = keccak256("ORACLE_CALLER_ROLE"); // DeliveryOracleV2

    // ── Immutables ────────────────────────────────────────────────────────────

    IERC20              public immutable usdc;
    ICMXSTokenBurner    public immutable cmxsToken;

    // ── Parameters (governance-adjustable) ───────────────────────────────────

    ITreasury public treasury;
    AggregatorV3Interface public priceFeed; // CMXS/USD Chainlink feed (post-TGE)

    uint256 public burnRateBps        = 1000;  // 10% of ad spend value burned
    uint256 public platformFeeBps     = 1500;  // 15% of USDC to Treasury
    uint256 public contentPartnerBps  = 8500;  // 85% to content partner
    uint256 public minCPM             = 15 * 1e6; // $15 USDC per 1000 impressions (6 dec)

    /// @notice Fallback fixed price (8 decimals, same as Chainlink) used pre-TGE.
    ///         Governance sets this until a Chainlink feed exists.
    int256  public fallbackCmxsPriceUSD = 1_00000000; // $1.00 (8 dec)

    uint256 public constant STALENESS_THRESHOLD = 3600; // 1 hour

    // ── Daily burn tracking (for Net Emissions calculation) ───────────────────

    uint256 public dailyBurnedToday;
    uint256 public lastBurnDay;

    // ── Campaign Tracking ─────────────────────────────────────────────────────

    struct Campaign {
        address advertiser;
        uint256 impressionsPurchased;
        uint256 impressionsDelivered;
        uint256 usdcAmount;
        uint256 cmxsBurned;
        uint256 timestamp;
        bool    active;
    }

    mapping(bytes32 => Campaign) public campaigns;

    // ── Events ────────────────────────────────────────────────────────────────

    event ImpressionsPurchased(
        address indexed advertiser,
        bytes32 indexed campaignId,
        uint256 usdcAmount,
        uint256 cmxsBurned
    );
    event DeliveryRecorded(bytes32 indexed campaignId, uint256 totalDelivered);
    event BurnRateUpdated(uint256 oldRate, uint256 newRate);
    event PlatformFeeUpdated(uint256 oldFee, uint256 newFee);
    event PriceFeedUpdated(address oldFeed, address newFeed);
    event FallbackPriceUpdated(int256 oldPrice, int256 newPrice);

    // ── Errors ────────────────────────────────────────────────────────────────

    error BelowMinCPM();
    error InvalidCampaignId();
    error CampaignNotActive();
    error InvalidPriceFeed();
    error StalePriceFeed(uint256 updatedAt, uint256 threshold);
    error ZeroAddress();

    // ── Constructor ───────────────────────────────────────────────────────────

    constructor(
        address _usdc,
        address _cmxsToken,
        address _treasury,
        address _adminMultisig
    ) {
        require(
            _usdc != address(0) && _cmxsToken != address(0) &&
            _treasury != address(0) && _adminMultisig != address(0),
            "Zero address"
        );
        usdc       = IERC20(_usdc);
        cmxsToken  = ICMXSTokenBurner(_cmxsToken);
        treasury   = ITreasury(_treasury);

        _grantRole(DEFAULT_ADMIN_ROLE, _adminMultisig);
        _grantRole(GOVERNANCE_ROLE,   _adminMultisig);
    }

    // ── Core Purchase Function ────────────────────────────────────────────────

    /**
     * @notice Advertiser purchases verified ad impressions.
     *         Pulls USDC, splits it, burns CMXS at oracle price, records campaign.
     *
     * @param contentPartnerWallet  Wallet to receive 85% USDC.
     * @param usdcAmount            Total USDC the advertiser pays (6 decimals).
     * @param impressionCount       Number of impressions being purchased.
     * @param campaignId            Unique campaign identifier (keccak256 of campaign data).
     */
    function purchaseImpressions(
        address contentPartnerWallet,
        uint256 usdcAmount,
        uint256 impressionCount,
        bytes32 campaignId
    ) external nonReentrant {
        if (contentPartnerWallet == address(0)) revert ZeroAddress();
        // CPM floor check: usdcAmount must cover minCPM per 1000 impressions
        if (usdcAmount < (minCPM * impressionCount) / 1000) revert BelowMinCPM();

        // 1. Pull USDC from advertiser
        usdc.safeTransferFrom(msg.sender, address(this), usdcAmount);

        // 2. Calculate splits
        uint256 platformFee    = (usdcAmount * platformFeeBps)    / 10000;
        uint256 partnerPayment = (usdcAmount * contentPartnerBps) / 10000;

        // 3. Route USDC
        usdc.safeTransfer(address(treasury), platformFee);
        treasury.recordPlatformFeeIncome(platformFee);
        usdc.safeTransfer(contentPartnerWallet, partnerPayment);

        // 4. Calculate CMXS burn amount via Chainlink (or fallback)
        uint256 cmxsBurnAmount = _calculateBurnAmount(usdcAmount);

        // 5. Burn CMXS from advertiser's balance (advertiser must have pre-approved)
        cmxsToken.burnForAd(msg.sender, cmxsBurnAmount);

        // 6. Track daily burns for Net Emissions
        _trackDailyBurn(cmxsBurnAmount);

        // 7. Record campaign
        campaigns[campaignId] = Campaign({
            advertiser:           msg.sender,
            impressionsPurchased: impressionCount,
            impressionsDelivered: 0,
            usdcAmount:           usdcAmount,
            cmxsBurned:           cmxsBurnAmount,
            timestamp:            block.timestamp,
            active:               true
        });

        emit ImpressionsPurchased(msg.sender, campaignId, usdcAmount, cmxsBurnAmount);
    }

    // ── Oracle Callback ───────────────────────────────────────────────────────

    /**
     * @notice Record a verified delivery against a campaign.
     *         Called by DeliveryOracleV2 (holds ORACLE_CALLER_ROLE).
     */
    function recordDelivery(bytes32 campaignId)
        external onlyRole(ORACLE_CALLER_ROLE)
    {
        Campaign storage c = campaigns[campaignId];
        if (!c.active) revert CampaignNotActive();

        c.impressionsDelivered++;

        // Auto-deactivate when all impressions are delivered
        if (c.impressionsDelivered >= c.impressionsPurchased) {
            c.active = false;
        }

        emit DeliveryRecorded(campaignId, c.impressionsDelivered);
    }

    // ── Internal ──────────────────────────────────────────────────────────────

    /**
     * @dev  Burn amount formula (from spec):
     *       cmxsToBurn = (usdcAmount × burnRateBps × 10^20) / (cmxsPrice × 10000)
     *
     *       usdcAmount: 6 decimals
     *       cmxsPrice:  8 decimals (Chainlink)
     *       result:    18 decimals (CMXS)
     *
     *       The price floor mechanism: lower CMXS price → more tokens burned per $.
     */
    function _calculateBurnAmount(uint256 usdcAmount) internal view returns (uint256) {
        int256 cmxsPrice = _getPrice();
        require(cmxsPrice > 0, "Invalid price");
        // Decimal math: (usdcAmount[6] * burnRateBps * 10^20) / (price[8] * 10000)
        // = usdcAmount * burnRateBps * 10^20 / price / 10000
        // Net exponent: 6 + 20 - 8 - 0 = 18 ✓
        return (usdcAmount * burnRateBps * 1e20) / (uint256(cmxsPrice) * 10000);
    }

    /**
     * @dev Return Chainlink price or fallback. Enforces staleness.
     */
    function _getPrice() internal view returns (int256) {
        if (address(priceFeed) == address(0)) {
            return fallbackCmxsPriceUSD;
        }
        (, int256 answer,, uint256 updatedAt,) = priceFeed.latestRoundData();
        if (block.timestamp - updatedAt > STALENESS_THRESHOLD)
            revert StalePriceFeed(updatedAt, STALENESS_THRESHOLD);
        if (answer <= 0) revert InvalidPriceFeed();
        return answer;
    }

    function _trackDailyBurn(uint256 amount) internal {
        uint256 today = block.timestamp / 1 days;
        if (today > lastBurnDay) {
            dailyBurnedToday = 0;
            lastBurnDay      = today;
        }
        dailyBurnedToday += amount;
    }

    // ── View ──────────────────────────────────────────────────────────────────

    function getDailyBurns() external view returns (uint256) {
        uint256 today = block.timestamp / 1 days;
        if (today > lastBurnDay) return 0;
        return dailyBurnedToday;
    }

    function previewBurnAmount(uint256 usdcAmount) external view returns (uint256) {
        return _calculateBurnAmount(usdcAmount);
    }

    // ── Governance ────────────────────────────────────────────────────────────

    function setBurnRate(uint256 newBps) external onlyRole(GOVERNANCE_ROLE) {
        require(newBps <= 5000, "Max 50%");
        emit BurnRateUpdated(burnRateBps, newBps);
        burnRateBps = newBps;
    }

    function setPlatformFee(uint256 newPlatformBps, uint256 newPartnerBps)
        external onlyRole(GOVERNANCE_ROLE)
    {
        require(newPlatformBps + newPartnerBps == 10000, "Must sum to 100%");
        emit PlatformFeeUpdated(platformFeeBps, newPlatformBps);
        platformFeeBps    = newPlatformBps;
        contentPartnerBps = newPartnerBps;
    }

    function setMinCPM(uint256 newMinCPM) external onlyRole(GOVERNANCE_ROLE) {
        minCPM = newMinCPM;
    }

    function setPriceFeed(address newFeed) external onlyRole(DEFAULT_ADMIN_ROLE) {
        emit PriceFeedUpdated(address(priceFeed), newFeed);
        priceFeed = AggregatorV3Interface(newFeed);
    }

    function setFallbackPrice(int256 newPrice) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(newPrice > 0, "Price must be positive");
        emit FallbackPriceUpdated(fallbackCmxsPriceUSD, newPrice);
        fallbackCmxsPriceUSD = newPrice;
    }

    function setTreasury(address newTreasury) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (newTreasury == address(0)) revert ZeroAddress();
        treasury = ITreasury(newTreasury);
    }
}
