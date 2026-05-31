// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title NodeStaking
 * @notice Spec-compliant DePIN node staking: CMXS-backed collateral, severity-based
 *         slashing, 7-day jail, 30-day unbonding period, EchoStar tower ID support.
 * @dev    Replaces NodeRegistry (which used ETH). Deploy after CMXSToken.
 *         DeliveryOracleV2 is granted SLASHER_ROLE post-deployment.
 */
contract NodeStaking is AccessControl, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // ── Roles ─────────────────────────────────────────────────────────────────

    bytes32 public constant SLASHER_ROLE = keccak256("SLASHER_ROLE");

    // ── Immutables ────────────────────────────────────────────────────────────

    IERC20 public immutable cmxsToken;

    // ── Parameters (governance-adjustable) ───────────────────────────────────

    address public treasury;
    uint256 public minStake          = 10_000 * 1e18; // 10,000 CMXS
    uint256 public constant SLASH_BPS_MINOR  =   500; // 5%
    uint256 public constant SLASH_BPS_MAJOR  =  2000; // 20%
    uint256 public constant JAIL_DURATION    = 7 days;
    uint256 public constant UNBONDING_PERIOD = 30 days;
    uint256 public constant MAX_SLASH_COUNT  = 3;

    // ── Types ─────────────────────────────────────────────────────────────────

    enum NodeStatus    { UNREGISTERED, ACTIVE, JAILED, DEREGISTERED }
    enum SlashSeverity { MINOR, MAJOR }

    struct NodeInfo {
        address   operator;
        uint256   stakedAmount;
        uint256   registeredAt;
        uint256   verifiedImpressions;
        uint256   slashCount;
        NodeStatus status;
        uint256   jailUntil;
        uint256   unstakeRequestedAt;
        bytes32   echoStarTowerId;   // optional EchoStar site identifier
        string    endpointURL;       // MoQ/QUIC relay endpoint
    }

    // ── State ─────────────────────────────────────────────────────────────────

    mapping(address => NodeInfo) public nodes;
    address[] public nodeList;
    uint256 public totalActiveNodes;

    // ── Events ────────────────────────────────────────────────────────────────

    event NodeRegistered(address indexed operator, bytes32 towerId, uint256 stakedAmount);
    event NodeSlashed(address indexed operator, uint256 slashAmount, SlashSeverity severity, string reason);
    event NodeJailed(address indexed operator, uint256 jailUntil);
    event NodeUnjailed(address indexed operator);
    event UnstakeRequested(address indexed operator, uint256 availableAt);
    event NodeUnstaked(address indexed operator, uint256 amount);
    event NodeDeregistered(address indexed operator);
    event MinStakeUpdated(uint256 oldMin, uint256 newMin);
    event TreasuryUpdated(address oldTreasury, address newTreasury);
    event ImpressionsRecorded(address indexed operator, uint256 count);

    // ── Errors ────────────────────────────────────────────────────────────────

    error AlreadyRegistered();
    error NotActive();
    error StillJailed();
    error NotJailed();
    error UnbondingNotRequested();
    error UnbondingNotComplete();
    error ZeroAddress();

    // ── Constructor ───────────────────────────────────────────────────────────

    constructor(address _cmxsToken, address _treasury, address _adminMultisig) {
        require(_cmxsToken != address(0) && _treasury != address(0) && _adminMultisig != address(0),
            "Zero address");
        cmxsToken = IERC20(_cmxsToken);
        treasury  = _treasury;
        _grantRole(DEFAULT_ADMIN_ROLE, _adminMultisig);
    }

    // ── Node Lifecycle ────────────────────────────────────────────────────────

    /**
     * @notice Register and stake CMXS to become an active delivery node.
     * @param towerId     Optional EchoStar site ID (bytes32(0) for third-party nodes).
     * @param endpointURL MoQ/QUIC delivery endpoint, e.g. "moqs://node.example.com:4433"
     */
    function registerNode(bytes32 towerId, string calldata endpointURL)
        external nonReentrant
    {
        if (nodes[msg.sender].status != NodeStatus.UNREGISTERED) revert AlreadyRegistered();

        cmxsToken.safeTransferFrom(msg.sender, address(this), minStake);

        nodes[msg.sender] = NodeInfo({
            operator:             msg.sender,
            stakedAmount:         minStake,
            registeredAt:         block.timestamp,
            verifiedImpressions:  0,
            slashCount:           0,
            status:               NodeStatus.ACTIVE,
            jailUntil:            0,
            unstakeRequestedAt:   0,
            echoStarTowerId:      towerId,
            endpointURL:          endpointURL
        });

        nodeList.push(msg.sender);
        totalActiveNodes++;
        emit NodeRegistered(msg.sender, towerId, minStake);
    }

    /**
     * @notice Slash a node for SLA breach or fraud. Called by DeliveryOracleV2 (SLASHER_ROLE).
     * @param operator  Node operator address.
     * @param severity  MINOR = 5% slash + 7-day jail. MAJOR = 20% slash + jail.
     * @param reason    Human-readable reason for the slash (stored in event).
     */
    function slashNode(
        address operator,
        SlashSeverity severity,
        string calldata reason
    ) external onlyRole(SLASHER_ROLE) {
        NodeInfo storage node = nodes[operator];
        require(node.status == NodeStatus.ACTIVE, "Node not active");

        uint256 bps         = severity == SlashSeverity.MINOR ? SLASH_BPS_MINOR : SLASH_BPS_MAJOR;
        uint256 slashAmount = (node.stakedAmount * bps) / 10000;
        node.stakedAmount  -= slashAmount;
        node.slashCount++;

        cmxsToken.safeTransfer(treasury, slashAmount);
        emit NodeSlashed(operator, slashAmount, severity, reason);

        // Deregister if stake too low or too many violations
        if (node.stakedAmount < minStake / 2 || node.slashCount >= MAX_SLASH_COUNT) {
            node.status = NodeStatus.DEREGISTERED;
            totalActiveNodes--;
            emit NodeDeregistered(operator);
        } else {
            node.status   = NodeStatus.JAILED;
            node.jailUntil = block.timestamp + JAIL_DURATION;
            emit NodeJailed(operator, node.jailUntil);
        }
    }

    /**
     * @notice Exit jail after the jail period expires. Node returns to ACTIVE.
     */
    function unjail() external {
        NodeInfo storage node = nodes[msg.sender];
        if (node.status != NodeStatus.JAILED) revert NotJailed();
        if (block.timestamp < node.jailUntil)  revert StillJailed();
        node.status = NodeStatus.ACTIVE;
        emit NodeUnjailed(msg.sender);
    }

    /**
     * @notice Start the 30-day unbonding clock. Must call before unstakeAndExit.
     */
    function requestUnstake() external {
        NodeInfo storage node = nodes[msg.sender];
        require(
            node.status == NodeStatus.ACTIVE || node.status == NodeStatus.JAILED,
            "Cannot request unstake"
        );
        node.unstakeRequestedAt = block.timestamp;
        emit UnstakeRequested(msg.sender, block.timestamp + UNBONDING_PERIOD);
    }

    /**
     * @notice Withdraw staked CMXS after the 30-day unbonding period.
     */
    function unstakeAndExit() external nonReentrant {
        NodeInfo storage node = nodes[msg.sender];
        require(
            node.status == NodeStatus.ACTIVE || node.status == NodeStatus.JAILED,
            "Cannot unstake"
        );
        if (block.timestamp < node.jailUntil)     revert StillJailed();
        if (node.unstakeRequestedAt == 0)          revert UnbondingNotRequested();
        if (block.timestamp < node.unstakeRequestedAt + UNBONDING_PERIOD)
            revert UnbondingNotComplete();

        uint256 amount    = node.stakedAmount;
        node.stakedAmount = 0;
        node.status       = NodeStatus.DEREGISTERED;
        totalActiveNodes--;

        cmxsToken.safeTransfer(msg.sender, amount);
        emit NodeUnstaked(msg.sender, amount);
    }

    // ── Oracle Callbacks ──────────────────────────────────────────────────────

    /**
     * @notice Increment verified impression count for a node.
     *         Called by DeliveryOracleV2 (SLASHER_ROLE — reused for oracle access).
     */
    function recordVerifiedImpressions(address operator, uint256 count)
        external onlyRole(SLASHER_ROLE)
    {
        nodes[operator].verifiedImpressions += count;
        emit ImpressionsRecorded(operator, count);
    }

    // ── View Functions ────────────────────────────────────────────────────────

    function isActiveNode(address operator) external view returns (bool) {
        return nodes[operator].status == NodeStatus.ACTIVE;
    }

    function getNode(address operator) external view returns (NodeInfo memory) {
        return nodes[operator];
    }

    function getNodeCount() external view returns (uint256) {
        return nodeList.length;
    }

    // ── Admin ─────────────────────────────────────────────────────────────────

    function setMinStake(uint256 newMin) external onlyRole(DEFAULT_ADMIN_ROLE) {
        emit MinStakeUpdated(minStake, newMin);
        minStake = newMin;
    }

    function setTreasury(address newTreasury) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (newTreasury == address(0)) revert ZeroAddress();
        emit TreasuryUpdated(treasury, newTreasury);
        treasury = newTreasury;
    }
}
