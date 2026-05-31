// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title Treasury
 * @notice Gnosis Safe-backed protocol treasury. Receives USDC platform fees from
 *         AdBurnV2, holds slashed CMXS, and disburses USDC to veToken holders.
 *         Large transfers (>$100K USDC) are subject to a 48-hour timelock.
 */
contract Treasury is AccessControl, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // ── Roles ─────────────────────────────────────────────────────────────────

    bytes32 public constant INTAKE_ROLE    = keccak256("INTAKE_ROLE");    // AdBurnV2
    bytes32 public constant TREASURER_ROLE = keccak256("TREASURER_ROLE"); // Gelato / veToken

    // ── Constants ─────────────────────────────────────────────────────────────

    uint256 public constant FEE_DISTRIBUTION_BPS      = 7000;          // 70% to ve holders
    uint256 public constant LARGE_TRANSFER_THRESHOLD  = 100_000 * 1e6; // $100K USDC (6 dec)
    uint256 public constant LARGE_TRANSFER_TIMELOCK   = 48 hours;

    // ── Immutables ────────────────────────────────────────────────────────────

    IERC20 public immutable usdc;

    // ── State ─────────────────────────────────────────────────────────────────

    uint256 public totalUSDCReceived;
    uint256 public currentEpochFees;
    uint256 public feesAvailableForVeHolders;

    struct PendingTransfer {
        address recipient;
        uint256 amount;
        uint256 scheduledAt;
        bool    executed;
    }

    mapping(uint256 => PendingTransfer) public pendingTransfers;
    uint256 public pendingTransferCount;

    // ── Events ────────────────────────────────────────────────────────────────

    event FeeReceived(uint256 usdcAmount, uint256 timestamp);
    event EpochFeesDistributed(uint256 toDistribute);
    event FeesDisbursed(address indexed recipient, uint256 amount);
    event LargeTransferScheduled(uint256 indexed transferId, address recipient, uint256 amount, uint256 executeAfter);
    event LargeTransferExecuted(uint256 indexed transferId, address recipient, uint256 amount);

    // ── Errors ────────────────────────────────────────────────────────────────

    error TransferTooEarly(uint256 executeAfter, uint256 now_);
    error AlreadyExecuted();
    error InsufficientFees();
    error BelowLargeTransferThreshold();
    error ZeroAddress();

    // ── Constructor ───────────────────────────────────────────────────────────

    /**
     * @param _usdc         USDC contract on Base (6 decimals).
     * @param _adminMultisig Gnosis Safe 3/5 multisig address.
     */
    constructor(address _usdc, address _adminMultisig) {
        require(_usdc != address(0) && _adminMultisig != address(0), "Zero address");
        usdc = IERC20(_usdc);
        _grantRole(DEFAULT_ADMIN_ROLE, _adminMultisig);
        _grantRole(TREASURER_ROLE, _adminMultisig);
    }

    // ── Fee Intake ────────────────────────────────────────────────────────────

    /**
     * @notice Record platform fee income received from AdBurnV2.
     *         USDC must already be transferred to this contract before calling.
     *         Called by AdBurnV2 (holds INTAKE_ROLE).
     */
    function recordPlatformFeeIncome(uint256 usdcAmount) external onlyRole(INTAKE_ROLE) {
        totalUSDCReceived   += usdcAmount;
        currentEpochFees    += usdcAmount;
        emit FeeReceived(usdcAmount, block.timestamp);
    }

    // ── Epoch Distribution ────────────────────────────────────────────────────

    /**
     * @notice Move 70% of epoch fees into the ve-holder claimable pool.
     *         Remaining 30% stays in treasury for operations.
     *         Called weekly by governance or Gelato Automate.
     */
    function distributeEpochFees() external onlyRole(TREASURER_ROLE) {
        uint256 toDistribute  = (currentEpochFees * FEE_DISTRIBUTION_BPS) / 10000;
        currentEpochFees     -= toDistribute;
        feesAvailableForVeHolders += toDistribute;
        emit EpochFeesDistributed(toDistribute);
    }

    /**
     * @notice Disburse USDC fee share to a veToken holder.
     *         Called by veToken.sol (holds TREASURER_ROLE) on claimFees().
     */
    function disburseFees(address recipient, uint256 amount)
        external onlyRole(TREASURER_ROLE) nonReentrant
    {
        if (feesAvailableForVeHolders < amount) revert InsufficientFees();
        feesAvailableForVeHolders -= amount;
        usdc.safeTransfer(recipient, amount);
        emit FeesDisbursed(recipient, amount);
    }

    // ── Large Transfer (Timelock) ─────────────────────────────────────────────

    /**
     * @notice Schedule a transfer >= $100K USDC with 48-hour timelock.
     *         Requires DEFAULT_ADMIN_ROLE (Gnosis Safe approval).
     */
    function scheduleLargeTransfer(address recipient, uint256 amount)
        external onlyRole(DEFAULT_ADMIN_ROLE)
    {
        if (recipient == address(0)) revert ZeroAddress();
        if (amount < LARGE_TRANSFER_THRESHOLD) revert BelowLargeTransferThreshold();

        uint256 id = pendingTransferCount++;
        uint256 executeAfter = block.timestamp + LARGE_TRANSFER_TIMELOCK;

        pendingTransfers[id] = PendingTransfer({
            recipient:   recipient,
            amount:      amount,
            scheduledAt: block.timestamp,
            executed:    false
        });

        emit LargeTransferScheduled(id, recipient, amount, executeAfter);
    }

    /**
     * @notice Execute a scheduled large transfer after the 48-hour timelock.
     */
    function executeLargeTransfer(uint256 transferId)
        external onlyRole(DEFAULT_ADMIN_ROLE) nonReentrant
    {
        PendingTransfer storage pt = pendingTransfers[transferId];
        if (pt.executed) revert AlreadyExecuted();

        uint256 executeAfter = pt.scheduledAt + LARGE_TRANSFER_TIMELOCK;
        if (block.timestamp < executeAfter)
            revert TransferTooEarly(executeAfter, block.timestamp);

        pt.executed = true;
        usdc.safeTransfer(pt.recipient, pt.amount);
        emit LargeTransferExecuted(transferId, pt.recipient, pt.amount);
    }

    // ── View ──────────────────────────────────────────────────────────────────

    /**
     * @notice Returns fees available for ve holders (used by veToken.claimFees).
     *         veToken is responsible for proportional allocation based on voting power.
     */
    function getFeesAvailable() external view returns (uint256) {
        return feesAvailableForVeHolders;
    }

    // ── Recovery ──────────────────────────────────────────────────────────────

    /**
     * @notice Rescue any ERC-20 accidentally sent here (except USDC operational funds).
     */
    function rescueToken(address token, address to, uint256 amount)
        external onlyRole(DEFAULT_ADMIN_ROLE)
    {
        IERC20(token).safeTransfer(to, amount);
    }
}
