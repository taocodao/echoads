// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface ITreasuryFees {
    function disburseFees(address recipient, uint256 amount) external;
    function getFeesAvailable() external view returns (uint256);
    function distributeEpochFees() external;
}

/**
 * @title veToken (veCMXS)
 * @notice Curve-style vote-escrow governance. Lock CMXS for 1 week – 4 years to
 *         receive non-transferable, time-decaying voting power. veHolders earn
 *         a proportional share of Treasury USDC fee revenue.
 *
 *         Voting power formula: cmxsLocked × (weeksRemaining / 208)
 *         where 208 = MAX_LOCK_WEEKS (4 years).
 */
contract veToken is AccessControl, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // ── Roles ─────────────────────────────────────────────────────────────────

    bytes32 public constant GOVERNANCE_ROLE = keccak256("GOVERNANCE_ROLE");

    // ── Constants ─────────────────────────────────────────────────────────────

    uint256 public constant MIN_LOCK_DURATION  = 1 weeks;
    uint256 public constant MAX_LOCK_DURATION  = 208 weeks;  // 4 years
    uint256 public constant MAX_LOCK_WEEKS     = 208;
    uint256 public constant PROPOSAL_THRESHOLD = 10_000 * 1e18; // 10k veCMXS to propose

    // ── Immutables ────────────────────────────────────────────────────────────

    IERC20          public immutable cmxsToken;
    ITreasuryFees   public immutable treasury;

    // ── State ─────────────────────────────────────────────────────────────────

    struct LockPosition {
        address owner;
        uint256 amount;       // CMXS locked
        uint256 start;        // timestamp of lock
        uint256 end;          // timestamp when lock expires
        uint256 lastClaimTime;
    }

    uint256 public lockCount;
    uint256 public totalLocked;
    mapping(uint256  => LockPosition)  public locks;
    mapping(address  => uint256[])     public ownerToLocks;

    // Gauge emission weights (weekly voting)
    // gaugeId → weight in BPS (must sum to 10000)
    mapping(uint256 => uint256) public gaugeWeights;
    uint256 public constant GAUGE_CMXS_USDC_LP = 1;
    uint256 public constant GAUGE_NODE_BONUS    = 2;
    uint256 public constant GAUGE_ECOSYSTEM     = 3;

    // ── Events ────────────────────────────────────────────────────────────────

    event Locked(address indexed owner, uint256 indexed lockId, uint256 amount, uint256 end);
    event Unlocked(address indexed owner, uint256 indexed lockId, uint256 amount);
    event FeesClaimed(address indexed owner, uint256 indexed lockId, uint256 usdcAmount);
    event LockExtended(uint256 indexed lockId, uint256 newEnd);
    event GaugeVoteCast(address indexed voter, uint256 indexed lockId, uint256[] gaugeIds, uint256[] weights);

    // ── Errors ────────────────────────────────────────────────────────────────

    error InvalidLockDuration();
    error NotLockOwner();
    error LockNotExpired();
    error LockExpired();
    error NothingToClaim();
    error ZeroAmount();

    // ── Constructor ───────────────────────────────────────────────────────────

    constructor(address _cmxsToken, address _treasury, address _adminMultisig) {
        require(
            _cmxsToken != address(0) &&
            _treasury != address(0) &&
            _adminMultisig != address(0),
            "Zero address"
        );
        cmxsToken = IERC20(_cmxsToken);
        treasury  = ITreasuryFees(_treasury);
        _grantRole(DEFAULT_ADMIN_ROLE, _adminMultisig);
        _grantRole(GOVERNANCE_ROLE,   _adminMultisig);
    }

    // ── Lock / Unlock ─────────────────────────────────────────────────────────

    /**
     * @notice Lock CMXS tokens for governance + fee income.
     * @param amount     CMXS amount to lock (18 decimals).
     * @param unlockTime Unix timestamp when tokens unlock (must be 1 week – 4 years out).
     * @return lockId    Unique lock position identifier.
     */
    function lock(uint256 amount, uint256 unlockTime)
        external nonReentrant returns (uint256 lockId)
    {
        if (amount == 0) revert ZeroAmount();
        if (
            unlockTime < block.timestamp + MIN_LOCK_DURATION ||
            unlockTime > block.timestamp + MAX_LOCK_DURATION
        ) revert InvalidLockDuration();

        cmxsToken.safeTransferFrom(msg.sender, address(this), amount);

        lockId = ++lockCount;
        locks[lockId] = LockPosition({
            owner:         msg.sender,
            amount:        amount,
            start:         block.timestamp,
            end:           unlockTime,
            lastClaimTime: block.timestamp
        });

        totalLocked += amount;
        ownerToLocks[msg.sender].push(lockId);

        emit Locked(msg.sender, lockId, amount, unlockTime);
    }

    /**
     * @notice Withdraw locked CMXS after lock expires.
     */
    function unlock(uint256 lockId) external nonReentrant {
        LockPosition storage pos = locks[lockId];
        if (pos.owner != msg.sender) revert NotLockOwner();
        if (block.timestamp < pos.end) revert LockNotExpired();

        uint256 amount = pos.amount;
        totalLocked   -= amount;
        pos.amount     = 0;

        cmxsToken.safeTransfer(msg.sender, amount);
        emit Unlocked(msg.sender, lockId, amount);
    }

    /**
     * @notice Extend an existing lock to a later unlock time.
     */
    function extendLock(uint256 lockId, uint256 newUnlockTime) external {
        LockPosition storage pos = locks[lockId];
        if (pos.owner != msg.sender)    revert NotLockOwner();
        if (block.timestamp >= pos.end) revert LockExpired();
        if (newUnlockTime <= pos.end || newUnlockTime > block.timestamp + MAX_LOCK_DURATION)
            revert InvalidLockDuration();

        pos.end = newUnlockTime;
        emit LockExtended(lockId, newUnlockTime);
    }

    // ── Fee Claims ────────────────────────────────────────────────────────────

    /**
     * @notice Claim proportional USDC fee share from Treasury.
     *         Share = (this lock's voting power / total voting power) × fees available.
     */
    function claimFees(uint256 lockId) external nonReentrant {
        LockPosition storage pos = locks[lockId];
        if (pos.owner != msg.sender)    revert NotLockOwner();
        if (block.timestamp >= pos.end) revert LockExpired();

        uint256 myPower    = getVotingPowerById(lockId);
        uint256 totalPower = getTotalVotingPower();
        if (myPower == 0 || totalPower == 0) revert NothingToClaim();

        uint256 available = treasury.getFeesAvailable();
        if (available == 0) revert NothingToClaim();

        uint256 userShare = (available * myPower) / totalPower;
        if (userShare == 0) revert NothingToClaim();

        pos.lastClaimTime = block.timestamp;
        treasury.disburseFees(msg.sender, userShare);

        emit FeesClaimed(msg.sender, lockId, userShare);
    }

    // ── Gauge Voting ──────────────────────────────────────────────────────────

    /**
     * @notice Cast gauge emission votes. weights must sum to 10000 (BPS).
     */
    function voteGauge(
        uint256 lockId,
        uint256[] calldata gaugeIds,
        uint256[] calldata weights
    ) external {
        LockPosition storage pos = locks[lockId];
        if (pos.owner != msg.sender)    revert NotLockOwner();
        if (block.timestamp >= pos.end) revert LockExpired();
        require(gaugeIds.length == weights.length, "Length mismatch");

        uint256 total;
        for (uint256 i = 0; i < weights.length; i++) total += weights[i];
        require(total == 10000, "Weights must sum to 10000");

        emit GaugeVoteCast(msg.sender, lockId, gaugeIds, weights);
    }

    // ── Voting Power ──────────────────────────────────────────────────────────

    /**
     * @notice Voting power for a lock: cmxsLocked × (weeksRemaining / 208).
     */
    function getVotingPowerById(uint256 lockId) public view returns (uint256) {
        LockPosition storage pos = locks[lockId];
        if (block.timestamp >= pos.end || pos.amount == 0) return 0;

        uint256 weeksRemaining = (pos.end - block.timestamp) / 1 weeks;
        return (pos.amount * weeksRemaining) / MAX_LOCK_WEEKS;
    }

    /**
     * @notice Aggregate voting power for an address across all locks.
     */
    function getVotingPower(address owner) external view returns (uint256 power) {
        uint256[] storage ids = ownerToLocks[owner];
        for (uint256 i = 0; i < ids.length; i++) {
            power += getVotingPowerById(ids[i]);
        }
    }

    /**
     * @notice Total protocol voting power (all active locks).
     */
    function getTotalVotingPower() public view returns (uint256 power) {
        for (uint256 i = 1; i <= lockCount; i++) {
            power += getVotingPowerById(i);
        }
    }

    function getLockIds(address owner) external view returns (uint256[] memory) {
        return ownerToLocks[owner];
    }
}
