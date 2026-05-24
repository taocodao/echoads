// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title NodeRegistry — Node operator registration and staking
 * @notice Manages EchoStar edge node registration, staking, and slashing.
 *         Nodes must stake a minimum amount to participate in ad delivery.
 */
contract NodeRegistry is Ownable {
    // -------------------------------------------------------------------------
    // Types
    // -------------------------------------------------------------------------

    enum NodeStatus {
        Inactive,
        Active,
        Slashed
    }

    struct NodeInfo {
        address operator;
        string endpoint;        // MOQ relay endpoint, e.g., "moqs://node.example.com:4433"
        uint256 stakedAmount;   // ETH staked (wei) — Phase 0 uses ETH, Phase 1 may use CMXS
        NodeStatus status;
        uint256 registeredAt;
        uint256 totalDeliveries;
        uint256 slaPassCount;
    }

    // -------------------------------------------------------------------------
    // State
    // -------------------------------------------------------------------------

    /// @notice Minimum stake to register (0.01 ETH in Phase 0)
    uint256 public minimumStake = 0.01 ether;

    /// @notice All registered nodes by operator address
    mapping(address => NodeInfo) public nodes;

    /// @notice Set of all registered node addresses (for enumeration)
    address[] public nodeList;

    // -------------------------------------------------------------------------
    // Events
    // -------------------------------------------------------------------------

    event NodeRegistered(address indexed operator, string endpoint, uint256 stake);
    event NodeDeregistered(address indexed operator, uint256 returnedStake);
    event NodeSlashed(address indexed operator, uint256 slashedAmount, string reason);
    event NodeEndpointUpdated(address indexed operator, string newEndpoint);
    event DeliveryRecorded(address indexed operator, bool slaMet);

    // -------------------------------------------------------------------------
    // Errors
    // -------------------------------------------------------------------------

    error InsufficientStake(uint256 required, uint256 provided);
    error NodeAlreadyRegistered();
    error NodeNotActive();
    error TransferFailed();

    // -------------------------------------------------------------------------
    // Constructor
    // -------------------------------------------------------------------------

    constructor() Ownable(msg.sender) {}

    // -------------------------------------------------------------------------
    // Node registration
    // -------------------------------------------------------------------------

    /**
     * @notice Register as an edge node operator.
     * @param endpoint  MOQ relay endpoint URL for this node
     */
    function registerNode(string calldata endpoint) external payable {
        if (msg.value < minimumStake) {
            revert InsufficientStake(minimumStake, msg.value);
        }
        if (nodes[msg.sender].status == NodeStatus.Active) {
            revert NodeAlreadyRegistered();
        }

        nodes[msg.sender] = NodeInfo({
            operator: msg.sender,
            endpoint: endpoint,
            stakedAmount: msg.value,
            status: NodeStatus.Active,
            registeredAt: block.timestamp,
            totalDeliveries: 0,
            slaPassCount: 0
        });

        nodeList.push(msg.sender);
        emit NodeRegistered(msg.sender, endpoint, msg.value);
    }

    /**
     * @notice Deregister and withdraw stake.
     */
    function deregisterNode() external {
        NodeInfo storage node = nodes[msg.sender];
        if (node.status != NodeStatus.Active) revert NodeNotActive();

        uint256 stake = node.stakedAmount;
        node.status = NodeStatus.Inactive;
        node.stakedAmount = 0;

        (bool sent,) = msg.sender.call{value: stake}("");
        if (!sent) revert TransferFailed();

        emit NodeDeregistered(msg.sender, stake);
    }

    /**
     * @notice Update the MOQ relay endpoint.
     */
    function updateEndpoint(string calldata newEndpoint) external {
        if (nodes[msg.sender].status != NodeStatus.Active) revert NodeNotActive();
        nodes[msg.sender].endpoint = newEndpoint;
        emit NodeEndpointUpdated(msg.sender, newEndpoint);
    }

    // -------------------------------------------------------------------------
    // Oracle-called functions
    // -------------------------------------------------------------------------

    /**
     * @notice Record a delivery (called by DeliveryOracle on proof acceptance).
     * @dev In Phase 0, the oracle emits an event that the API listens to.
     *      Direct call integration can be added in Phase 1.
     */
    function recordDelivery(address operator, bool slaMet) external onlyOwner {
        NodeInfo storage node = nodes[operator];
        if (node.status != NodeStatus.Active) revert NodeNotActive();
        node.totalDeliveries += 1;
        if (slaMet) node.slaPassCount += 1;
        emit DeliveryRecorded(operator, slaMet);
    }

    // -------------------------------------------------------------------------
    // Admin
    // -------------------------------------------------------------------------

    /**
     * @notice Slash a node for misconduct (e.g., fake delivery proofs).
     */
    function slash(address operator, string calldata reason) external onlyOwner {
        NodeInfo storage node = nodes[operator];
        if (node.status != NodeStatus.Active) revert NodeNotActive();

        uint256 slashed = node.stakedAmount;
        node.status = NodeStatus.Slashed;
        node.stakedAmount = 0;

        // Slashed stake goes to contract owner (team treasury)
        (bool sent,) = owner().call{value: slashed}("");
        if (!sent) revert TransferFailed();

        emit NodeSlashed(operator, slashed, reason);
    }

    function setMinimumStake(uint256 newMinimum) external onlyOwner {
        minimumStake = newMinimum;
    }

    // -------------------------------------------------------------------------
    // View functions
    // -------------------------------------------------------------------------

    function getNodeCount() external view returns (uint256) {
        return nodeList.length;
    }

    function getNode(address operator) external view returns (NodeInfo memory) {
        return nodes[operator];
    }

    function isActiveNode(address operator) external view returns (bool) {
        return nodes[operator].status == NodeStatus.Active;
    }

    /**
     * @notice Get SLA pass rate for a node (returns basis points: 10000 = 100%)
     */
    function getSlaPassRateBps(address operator) external view returns (uint256) {
        NodeInfo storage node = nodes[operator];
        if (node.totalDeliveries == 0) return 0;
        return (node.slaPassCount * 10_000) / node.totalDeliveries;
    }
}
