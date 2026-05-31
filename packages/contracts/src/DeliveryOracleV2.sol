// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

interface ICMXSMinter {
    function mintReward(address nodeOperator, uint256 amount) external;
    function mintNetEmission(address pool, uint256 amount) external;
}

interface INodeStaking {
    function isActiveNode(address operator) external view returns (bool);
    function recordVerifiedImpressions(address operator, uint256 count) external;
}

interface IAdBurnV2 {
    struct Campaign {
        address advertiser;
        uint256 impressionsPurchased;
        uint256 impressionsDelivered;
        uint256 usdcAmount;
        uint256 cmxsBurned;
        uint256 timestamp;
        bool    active;
    }
    function campaigns(bytes32 campaignId) external view returns (Campaign memory);
    function recordDelivery(bytes32 campaignId) external;
    function getDailyBurns() external view returns (uint256);
}

/**
 * @title DeliveryOracleV2
 * @notice Spec-compliant PoD verification engine.
 *         Verifies batches of viewer-signed PoD receipts, enforces latency SLA,
 *         prevents replays, checks node stake, mints CMXS rewards, and applies
 *         Helium-style Net Emissions when daily burns exceed mints.
 *
 * @dev    Deployment order: deploy after CMXSToken, NodeStaking, AdBurnV2.
 *         Post-deploy (via Gnosis Safe):
 *           CMXSToken.grantRole(MINTER_ROLE, address(this))
 *           NodeStaking.grantRole(SLASHER_ROLE, address(this))
 *           AdBurnV2.grantRole(ORACLE_CALLER_ROLE, address(this))
 */
contract DeliveryOracleV2 is AccessControl, ReentrancyGuard {
    using ECDSA for bytes32;
    using MessageHashUtils for bytes32;

    // ── Roles ─────────────────────────────────────────────────────────────────

    bytes32 public constant ORACLE_ADMIN_ROLE = keccak256("ORACLE_ADMIN_ROLE");

    // ── Constants ─────────────────────────────────────────────────────────────

    uint256 public constant NODE_REWARD_PER_IMPRESSION = 0.001 * 1e18; // 1e15 wei
    uint256 public constant MAX_LATENCY_MS             = 500;
    uint256 public constant REPLAY_WINDOW              = 300;  // 5 minutes in seconds
    uint256 public constant MAX_BATCH_SIZE             = 50;
    uint256 public constant NET_EMISSIONS_CAP_BPS      = 100;  // 1% of daily cap

    // ── Immutables ────────────────────────────────────────────────────────────

    ICMXSMinter  public immutable cmxsToken;
    INodeStaking public immutable nodeStaking;

    // ── State ─────────────────────────────────────────────────────────────────

    IAdBurnV2 public adBurn;
    address   public nodeRewardPool;

    uint256 public maxDailyMint    = 500_000 * 1e18;
    uint256 public dailyMintedToday;
    uint256 public lastMintDay;

    mapping(address  => bool) public authorizedSigners;
    mapping(bytes32  => bool) public usedImpressionIds;

    // ── Structs ───────────────────────────────────────────────────────────────

    struct PoDReceipt {
        bytes32 impressionId;
        address nodeOperator;
        uint256 cpm;          // USDC microunits (6 dec)
        uint256 timestamp;    // Unix ms from viewer device
        uint256 latencyMs;
        bytes32 campaignId;
    }

    struct ReceiptBatch {
        PoDReceipt[] receipts;
        bytes[]      signatures; // One ECDSA sig per receipt (viewer device key)
    }

    // ── Events ────────────────────────────────────────────────────────────────

    event PoDVerified(
        bytes32 indexed impressionId,
        address indexed nodeOperator,
        uint256 cpm,
        uint256 latencyMs
    );
    event BatchProcessed(uint256 count, uint256 totalMinted);
    event NetEmissionsApplied(uint256 amount);
    event SignerUpdated(address indexed signer, bool authorized);
    event MaxDailyMintUpdated(uint256 oldValue, uint256 newValue);
    event AdBurnUpdated(address newAdBurn);
    event NodeRewardPoolUpdated(address newPool);

    // ── Errors ────────────────────────────────────────────────────────────────

    error LengthMismatch();
    error BatchTooLarge();
    error AlreadyVerified();
    error ReceiptExpired();
    error SLAViolation(uint256 latencyMs);
    error InvalidSignature();
    error NodeNotStaked();
    error CampaignInactive();
    error DailyMintCapExceeded();
    error ZeroAddress();

    // ── Constructor ───────────────────────────────────────────────────────────

    constructor(
        address _cmxsToken,
        address _nodeStaking,
        address _adBurn,         // can be address(0) initially
        address _nodeRewardPool, // can be address(0) initially
        address _adminMultisig
    ) {
        require(
            _cmxsToken != address(0) &&
            _nodeStaking != address(0) &&
            _adminMultisig != address(0),
            "Zero address"
        );
        cmxsToken      = ICMXSMinter(_cmxsToken);
        nodeStaking    = INodeStaking(_nodeStaking);
        adBurn         = IAdBurnV2(_adBurn);
        nodeRewardPool = _nodeRewardPool;

        _grantRole(DEFAULT_ADMIN_ROLE, _adminMultisig);
        _grantRole(ORACLE_ADMIN_ROLE,  _adminMultisig);
    }

    // ── Core: Batch Verify & Mint ─────────────────────────────────────────────

    /**
     * @notice Verify a batch of viewer-signed PoD receipts and mint CMXS rewards.
     *
     *         Each receipt is verified for:
     *           1. No replay (usedImpressionIds)
     *           2. Freshness (timestamp within REPLAY_WINDOW)
     *           3. Latency SLA (<= 500ms)
     *           4. Valid ECDSA signature from an authorizedSigner
     *           5. Node is actively staked
     *           6. Campaign is active (if adBurn configured)
     *
     *         Rewards are batched per operator for gas efficiency.
     *         Net Emissions are applied after minting.
     */
    function verifyAndMintBatch(ReceiptBatch calldata batch)
        external nonReentrant
    {
        if (batch.receipts.length != batch.signatures.length) revert LengthMismatch();
        if (batch.receipts.length > MAX_BATCH_SIZE)           revert BatchTooLarge();

        _resetDailyMintIfNeeded();

        // Accumulate per-operator rewards (avoid multiple mint calls per operator)
        address[] memory operators = new address[](batch.receipts.length);
        uint256[] memory amounts   = new uint256[](batch.receipts.length);
        uint256 operatorCount      = 0;
        uint256 totalMinted        = 0;

        for (uint256 i = 0; i < batch.receipts.length; i++) {
            PoDReceipt calldata r = batch.receipts[i];

            // 1. Replay protection
            if (usedImpressionIds[r.impressionId]) revert AlreadyVerified();

            // 2. Freshness: timestamp is Unix ms → convert to seconds for comparison
            if (block.timestamp > (r.timestamp / 1000) + REPLAY_WINDOW)
                revert ReceiptExpired();

            // 3. Latency SLA
            if (r.latencyMs > MAX_LATENCY_MS) revert SLAViolation(r.latencyMs);

            // 4. ECDSA signature (viewer device key)
            bytes32 msgHash = keccak256(abi.encodePacked(
                r.impressionId,
                r.nodeOperator,
                r.cpm,
                r.timestamp,
                r.latencyMs,
                r.campaignId,
                block.chainid
            ));
            address signer = msgHash.toEthSignedMessageHash().recover(batch.signatures[i]);
            if (!authorizedSigners[signer]) revert InvalidSignature();

            // 5. Node stake check
            if (!nodeStaking.isActiveNode(r.nodeOperator)) revert NodeNotStaked();

            // 6. Campaign check (optional — adBurn may not be set in Phase 0)
            if (address(adBurn) != address(0)) {
                IAdBurnV2.Campaign memory c = adBurn.campaigns(r.campaignId);
                if (!c.active) revert CampaignInactive();
                adBurn.recordDelivery(r.campaignId);
            }

            // Mark impression used
            usedImpressionIds[r.impressionId] = true;

            // Batch rewards per operator
            bool found = false;
            for (uint256 j = 0; j < operatorCount; j++) {
                if (operators[j] == r.nodeOperator) {
                    amounts[j] += NODE_REWARD_PER_IMPRESSION;
                    found = true;
                    break;
                }
            }
            if (!found) {
                operators[operatorCount] = r.nodeOperator;
                amounts[operatorCount]   = NODE_REWARD_PER_IMPRESSION;
                operatorCount++;
            }

            totalMinted += NODE_REWARD_PER_IMPRESSION;

            emit PoDVerified(r.impressionId, r.nodeOperator, r.cpm, r.latencyMs);
        }

        // Daily cap circuit breaker
        if (dailyMintedToday + totalMinted > maxDailyMint) revert DailyMintCapExceeded();
        dailyMintedToday += totalMinted;

        // Mint rewards per operator (batched)
        for (uint256 i = 0; i < operatorCount; i++) {
            cmxsToken.mintReward(operators[i], amounts[i]);
        }

        // Record impressions in NodeStaking
        for (uint256 i = 0; i < batch.receipts.length; i++) {
            nodeStaking.recordVerifiedImpressions(batch.receipts[i].nodeOperator, 1);
        }

        // Net Emissions: recycle burn surplus to node reward pool
        _applyNetEmissions();

        emit BatchProcessed(batch.receipts.length, totalMinted);
    }

    // ── Net Emissions ─────────────────────────────────────────────────────────

    /**
     * @dev If today's ad burns exceed today's mints, recycle the surplus
     *      (capped at 1% of MAX_DAILY_MINT) back to the node reward pool.
     *      These are not new tokens — they reissue from the burn surplus.
     */
    function _applyNetEmissions() internal {
        if (address(adBurn) == address(0) || nodeRewardPool == address(0)) return;

        uint256 todayBurns = adBurn.getDailyBurns();
        uint256 todayMints = dailyMintedToday;

        if (todayBurns > todayMints) {
            uint256 surplus     = todayBurns - todayMints;
            uint256 cap         = (maxDailyMint * NET_EMISSIONS_CAP_BPS) / 10000;
            uint256 netEmission = surplus < cap ? surplus : cap;

            if (dailyMintedToday + netEmission <= maxDailyMint) {
                dailyMintedToday += netEmission;
                cmxsToken.mintNetEmission(nodeRewardPool, netEmission);
                emit NetEmissionsApplied(netEmission);
            }
        }
    }

    function _resetDailyMintIfNeeded() internal {
        uint256 today = block.timestamp / 1 days;
        if (today > lastMintDay) {
            dailyMintedToday = 0;
            lastMintDay      = today;
        }
    }

    // ── Admin ─────────────────────────────────────────────────────────────────

    function addAuthorizedSigner(address signer) external onlyRole(ORACLE_ADMIN_ROLE) {
        authorizedSigners[signer] = true;
        emit SignerUpdated(signer, true);
    }

    function removeAuthorizedSigner(address signer) external onlyRole(ORACLE_ADMIN_ROLE) {
        authorizedSigners[signer] = false;
        emit SignerUpdated(signer, false);
    }

    function setAdBurn(address _adBurn) external onlyRole(DEFAULT_ADMIN_ROLE) {
        adBurn = IAdBurnV2(_adBurn);
        emit AdBurnUpdated(_adBurn);
    }

    function setNodeRewardPool(address _pool) external onlyRole(DEFAULT_ADMIN_ROLE) {
        nodeRewardPool = _pool;
        emit NodeRewardPoolUpdated(_pool);
    }

    function setMaxDailyMint(uint256 newMax) external onlyRole(DEFAULT_ADMIN_ROLE) {
        emit MaxDailyMintUpdated(maxDailyMint, newMax);
        maxDailyMint = newMax;
    }

    // ── View ──────────────────────────────────────────────────────────────────

    function getDailyMintedToday() external view returns (uint256) {
        return dailyMintedToday;
    }

    function isImpressionUsed(bytes32 impressionId) external view returns (bool) {
        return usedImpressionIds[impressionId];
    }
}
