// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title CMXS — CometX Streaming Token
 * @notice ERC-20 reward token for SlingDePIN node operators.
 *         Nodes earn CMXS for each verified ad delivery that meets the 500ms SLA.
 * @dev 35% of supply is held in this contract as the node rewards pool.
 *      Only the designated oracle contract can call rewardNode().
 */
contract CMXS is ERC20, Ownable {
    // -------------------------------------------------------------------------
    // Constants
    // -------------------------------------------------------------------------

    /// @notice Maximum total supply: 1 billion CMXS
    uint256 public constant MAX_SUPPLY = 1_000_000_000 * 10 ** 18;

    /// @notice Reward per verified delivery: 0.001 CMXS
    uint256 public constant REWARD_PER_VERIFIED_DELIVERY = 1 * 10 ** 15;

    // -------------------------------------------------------------------------
    // State
    // -------------------------------------------------------------------------

    /// @notice The oracle contract authorized to call rewardNode()
    address public oracleContract;

    // -------------------------------------------------------------------------
    // Events
    // -------------------------------------------------------------------------

    event OracleUpdated(address indexed oldOracle, address indexed newOracle);
    event NodeRewarded(address indexed node, uint256 amount, bytes32 indexed deliveryId);
    event TokensBurned(address indexed burner, uint256 amount);

    // -------------------------------------------------------------------------
    // Errors
    // -------------------------------------------------------------------------

    error OnlyOracle();
    error RewardPoolEmpty();
    error ZeroAddress();

    // -------------------------------------------------------------------------
    // Constructor
    // -------------------------------------------------------------------------

    /**
     * @param _oracle The DeliveryOracle contract address
     * @dev 35% of MAX_SUPPLY is minted to this contract as the rewards pool.
     *      Remaining 65% held by owner for team/ecosystem allocation.
     */
    constructor(address _oracle) ERC20("CometX Streaming Token", "CMXS") Ownable(msg.sender) {
        if (_oracle == address(0)) revert ZeroAddress();
        oracleContract = _oracle;

        // Mint 35% to this contract (rewards pool)
        _mint(address(this), (MAX_SUPPLY * 35) / 100);

        // Mint 65% to owner (team, ecosystem, ICO presale allocation)
        _mint(msg.sender, (MAX_SUPPLY * 65) / 100);
    }

    // -------------------------------------------------------------------------
    // Oracle-only functions
    // -------------------------------------------------------------------------

    /**
     * @notice Transfer CMXS reward to a node operator for a verified delivery.
     * @param nodeOperator  The node's wallet address
     * @param deliveryId    Unique delivery identifier (for event indexing)
     * @dev Only callable by the oracleContract. Amount is fixed at REWARD_PER_VERIFIED_DELIVERY.
     */
    function rewardNode(address nodeOperator, bytes32 deliveryId) external {
        if (msg.sender != oracleContract) revert OnlyOracle();
        if (nodeOperator == address(0)) revert ZeroAddress();

        uint256 poolBalance = balanceOf(address(this));
        if (poolBalance < REWARD_PER_VERIFIED_DELIVERY) revert RewardPoolEmpty();

        _transfer(address(this), nodeOperator, REWARD_PER_VERIFIED_DELIVERY);
        emit NodeRewarded(nodeOperator, REWARD_PER_VERIFIED_DELIVERY, deliveryId);
    }

    // -------------------------------------------------------------------------
    // Public functions
    // -------------------------------------------------------------------------

    /**
     * @notice Burn CMXS tokens for premium ad slot access (burn-and-mint equilibrium).
     * @param amount  Amount to burn (in wei)
     */
    function burnForPremiumSlot(uint256 amount) external {
        _burn(msg.sender, amount);
        emit TokensBurned(msg.sender, amount);
    }

    // -------------------------------------------------------------------------
    // Admin functions
    // -------------------------------------------------------------------------

    /**
     * @notice Update the oracle contract address.
     * @dev Used when upgrading from trusted-signer oracle to Chainlink CRE.
     */
    function setOracleContract(address newOracle) external onlyOwner {
        if (newOracle == address(0)) revert ZeroAddress();
        emit OracleUpdated(oracleContract, newOracle);
        oracleContract = newOracle;
    }

    /**
     * @notice View the current node rewards pool balance.
     */
    function rewardsPoolBalance() external view returns (uint256) {
        return balanceOf(address(this));
    }
}
