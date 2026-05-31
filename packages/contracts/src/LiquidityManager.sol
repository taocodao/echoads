// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

// ── Uniswap v3 Interfaces (inline — avoids lib dep for now) ──────────────────

interface IUniswapV3Pool {
    function slot0() external view returns (
        uint160 sqrtPriceX96,
        int24   tick,
        uint16  observationIndex,
        uint16  observationCardinality,
        uint16  observationCardinalityNext,
        uint8   feeProtocol,
        bool    unlocked
    );
    function token0() external view returns (address);
    function token1() external view returns (address);
    function tickSpacing() external view returns (int24);
}

interface INonfungiblePositionManager {
    struct MintParams {
        address token0;
        address token1;
        uint24  fee;
        int24   tickLower;
        int24   tickUpper;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        address recipient;
        uint256 deadline;
    }
    struct IncreaseLiquidityParams {
        uint256 tokenId;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }
    struct DecreaseLiquidityParams {
        uint256 tokenId;
        uint128 liquidity;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }
    struct CollectParams {
        uint256 tokenId;
        address recipient;
        uint128 amount0Max;
        uint128 amount1Max;
    }
    function mint(MintParams calldata params) external returns (
        uint256 tokenId, uint128 liquidity, uint256 amount0, uint256 amount1
    );
    function increaseLiquidity(IncreaseLiquidityParams calldata params) external returns (
        uint128 liquidity, uint256 amount0, uint256 amount1
    );
    function decreaseLiquidity(DecreaseLiquidityParams calldata params) external returns (
        uint256 amount0, uint256 amount1
    );
    function collect(CollectParams calldata params) external returns (uint256 amount0, uint256 amount1);
    function burn(uint256 tokenId) external;
    function positions(uint256 tokenId) external view returns (
        uint96  nonce, address operator, address token0, address token1,
        uint24  fee, int24 tickLower, int24 tickUpper, uint128 liquidity,
        uint256 feeGrowthInside0LastX128, uint256 feeGrowthInside1LastX128,
        uint128 tokensOwed0, uint128 tokensOwed1
    );
}

/**
 * @title LiquidityManager
 * @notice On-chain self-managed Uniswap v3 concentrated liquidity for CMXS/USDC on Base.
 *         Maintains an asymmetric range (-30% / +15%) aligned with BME price floor.
 *         Triggered by Gelato Automate when price moves outside 80% of range.
 *
 * @dev    Pool must be created externally (1% fee tier) before deploying this contract.
 *         Gelato resolver: checkRebalanceNeeded() → rebalance()
 */
contract LiquidityManager is AccessControl, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // ── Roles ─────────────────────────────────────────────────────────────────

    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    // ── Immutables ────────────────────────────────────────────────────────────

    IUniswapV3Pool               public immutable pool;
    INonfungiblePositionManager  public immutable positionManager;
    IERC20                       public immutable cmxsToken;
    IERC20                       public immutable usdc;
    address                      public immutable treasury;
    uint24                       public immutable feeTier; // e.g. 10000 = 1%

    // ── State ─────────────────────────────────────────────────────────────────

    uint256 public currentPositionId;  // Uniswap v3 NFT tokenId of active position

    int24 public tickLower;
    int24 public tickUpper;

    // Rebalance when price moves outside 80% of range
    uint256 public rebalanceTriggerBps = 8000;

    // BME-aware asymmetric range: -30% lower / +15% upper (in tick half-width)
    // Approximately: ±20% → adjusted to -30%/+15% via separate lower/upper widths
    int24 public lowerRangeWidthTicks;  // ticks below current (wider — BME floor support)
    int24 public upperRangeWidthTicks;  // ticks above current (narrower)

    // Authorized Gelato Automate keeper address
    address public automationKeeper;

    // ── Events ────────────────────────────────────────────────────────────────

    event Rebalanced(int24 newTickLower, int24 newTickUpper, int24 currentTick, uint256 timestamp);
    event FeesCollected(uint256 cmxsAmount, uint256 usdcAmount);
    event LiquidityDeployed(uint256 tokenId, uint256 amount0, uint256 amount1);
    event KeeperUpdated(address newKeeper);
    event RangeParamsUpdated(int24 lowerWidth, int24 upperWidth, uint256 triggerBps);

    // ── Errors ────────────────────────────────────────────────────────────────

    error Unauthorized();
    error RebalanceNotNeeded();
    error NoActivePosition();
    error ZeroAddress();

    // ── Constructor ───────────────────────────────────────────────────────────

    /**
     * @param _pool             Uniswap v3 CMXS/USDC pool (1% fee tier) on Base.
     * @param _positionManager  Uniswap v3 NonfungiblePositionManager.
     * @param _cmxsToken        CMXSToken address.
     * @param _usdc             USDC address.
     * @param _treasury         Treasury.sol — receives collected LP fees.
     * @param _feeTier          Pool fee tier (10000 = 1%).
     * @param _adminMultisig    Gnosis Safe 3/5.
     */
    constructor(
        address _pool,
        address _positionManager,
        address _cmxsToken,
        address _usdc,
        address _treasury,
        uint24  _feeTier,
        address _adminMultisig
    ) {
        require(
            _pool != address(0) && _positionManager != address(0) &&
            _cmxsToken != address(0) && _usdc != address(0) &&
            _treasury != address(0) && _adminMultisig != address(0),
            "Zero address"
        );
        pool            = IUniswapV3Pool(_pool);
        positionManager = INonfungiblePositionManager(_positionManager);
        cmxsToken       = IERC20(_cmxsToken);
        usdc            = IERC20(_usdc);
        treasury        = _treasury;
        feeTier         = _feeTier;

        // Default range widths (approximate ticks for -30% / +15%)
        // At 1% fee tier, tickSpacing = 200. ~30% price change ≈ 2500 ticks.
        lowerRangeWidthTicks = 2500;  // -30% (wider for BME floor support)
        upperRangeWidthTicks = 1250;  // +15%

        _grantRole(DEFAULT_ADMIN_ROLE, _adminMultisig);
        _grantRole(MANAGER_ROLE,       _adminMultisig);
    }

    // ── Gelato Integration ────────────────────────────────────────────────────

    /**
     * @notice Gelato resolver — returns true when price has moved outside
     *         the inner 80% of the current tick range.
     */
    function checkRebalanceNeeded() external view returns (bool) {
        if (currentPositionId == 0) return false;
        (, int24 currentTick,,,,,) = pool.slot0();

        int24 rangeTotal = tickUpper - tickLower;
        int24 buffer     = int24(int256((uint256(int256(rangeTotal)) * (10000 - rebalanceTriggerBps)) / 20000));
        int24 innerLower = tickLower + buffer;
        int24 innerUpper = tickUpper - buffer;

        return currentTick < innerLower || currentTick > innerUpper;
    }

    /**
     * @notice Rebalance LP position. Callable by Gelato keeper or MANAGER_ROLE.
     */
    function rebalance() external nonReentrant {
        if (msg.sender != automationKeeper && !hasRole(MANAGER_ROLE, msg.sender))
            revert Unauthorized();
        if (!this.checkRebalanceNeeded()) revert RebalanceNotNeeded();

        // 1. Remove existing position
        if (currentPositionId != 0) {
            _removeLiquidity();
        }

        // 2. Calculate new asymmetric range centered on current tick
        (, int24 currentTick,,,,,) = pool.slot0();
        int24 spacing = pool.tickSpacing();

        int24 rawLower = currentTick - lowerRangeWidthTicks;
        int24 rawUpper = currentTick + upperRangeWidthTicks;
        int24 newLower = (rawLower / spacing) * spacing;
        int24 newUpper = (rawUpper / spacing) * spacing;

        // 3. Deploy liquidity in new range
        uint256 cmxsBal = cmxsToken.balanceOf(address(this));
        uint256 usdcBal = usdc.balanceOf(address(this));

        if (cmxsBal > 0 || usdcBal > 0) {
            _addLiquidity(newLower, newUpper, cmxsBal, usdcBal);
        }

        tickLower = newLower;
        tickUpper = newUpper;

        emit Rebalanced(newLower, newUpper, currentTick, block.timestamp);
    }

    // ── Fee Collection ────────────────────────────────────────────────────────

    /**
     * @notice Collect accumulated LP trading fees and forward to Treasury.
     */
    function collectAndForwardFees() external nonReentrant {
        if (currentPositionId == 0) revert NoActivePosition();

        (uint256 amount0, uint256 amount1) = positionManager.collect(
            INonfungiblePositionManager.CollectParams({
                tokenId:     currentPositionId,
                recipient:   treasury,
                amount0Max:  type(uint128).max,
                amount1Max:  type(uint128).max
            })
        );

        emit FeesCollected(amount0, amount1);
    }

    // ── Internal ──────────────────────────────────────────────────────────────

    function _addLiquidity(int24 lower, int24 upper, uint256 amount0, uint256 amount1) internal {
        cmxsToken.forceApprove(address(positionManager), amount0);
        usdc.forceApprove(address(positionManager), amount1);

        (uint256 tokenId,, uint256 deposited0, uint256 deposited1) = positionManager.mint(
            INonfungiblePositionManager.MintParams({
                token0:         pool.token0(),
                token1:         pool.token1(),
                fee:            feeTier,
                tickLower:      lower,
                tickUpper:      upper,
                amount0Desired: amount0,
                amount1Desired: amount1,
                amount0Min:     0,
                amount1Min:     0,
                recipient:      address(this),
                deadline:       block.timestamp + 300
            })
        );

        currentPositionId = tokenId;
        emit LiquidityDeployed(tokenId, deposited0, deposited1);
    }

    function _removeLiquidity() internal {
        (,,,,,,, uint128 liquidity,,,,) = positionManager.positions(currentPositionId);

        if (liquidity > 0) {
            positionManager.decreaseLiquidity(
                INonfungiblePositionManager.DecreaseLiquidityParams({
                    tokenId:     currentPositionId,
                    liquidity:   liquidity,
                    amount0Min:  0,
                    amount1Min:  0,
                    deadline:    block.timestamp + 300
                })
            );
        }

        positionManager.collect(
            INonfungiblePositionManager.CollectParams({
                tokenId:    currentPositionId,
                recipient:  address(this),
                amount0Max: type(uint128).max,
                amount1Max: type(uint128).max
            })
        );

        positionManager.burn(currentPositionId);
        currentPositionId = 0;
    }

    // ── Admin ─────────────────────────────────────────────────────────────────

    function setAutomationKeeper(address keeper) external onlyRole(DEFAULT_ADMIN_ROLE) {
        automationKeeper = keeper;
        emit KeeperUpdated(keeper);
    }

    function setRangeParams(
        int24 _lowerWidth,
        int24 _upperWidth,
        uint256 _triggerBps
    ) external onlyRole(MANAGER_ROLE) {
        require(_triggerBps <= 10000, "Invalid bps");
        lowerRangeWidthTicks  = _lowerWidth;
        upperRangeWidthTicks  = _upperWidth;
        rebalanceTriggerBps   = _triggerBps;
        emit RangeParamsUpdated(_lowerWidth, _upperWidth, _triggerBps);
    }

    /// @notice Manual initial liquidity deploy before first Gelato trigger.
    function deployInitialLiquidity() external onlyRole(MANAGER_ROLE) nonReentrant {
        require(currentPositionId == 0, "Position already active");
        (, int24 currentTick,,,,,) = pool.slot0();
        int24 spacing = pool.tickSpacing();

        int24 lower = ((currentTick - lowerRangeWidthTicks) / spacing) * spacing;
        int24 upper = ((currentTick + upperRangeWidthTicks) / spacing) * spacing;

        uint256 cmxsBal = cmxsToken.balanceOf(address(this));
        uint256 usdcBal = usdc.balanceOf(address(this));

        _addLiquidity(lower, upper, cmxsBal, usdcBal);
        tickLower = lower;
        tickUpper = upper;
    }

    /// @notice Rescue tokens not in an active LP position.
    function rescueTokens(address token, address to, uint256 amount)
        external onlyRole(DEFAULT_ADMIN_ROLE)
    {
        IERC20(token).safeTransfer(to, amount);
    }
}
