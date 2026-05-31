// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title CMXSToken
 * @notice Spec-compliant CMXS ERC-20: capped 1B supply, role-based mint/burn,
 *         ERC-2612 permit (for Uniswap v3 LP), emergency pause, Net Emissions support.
 * @dev    Deployment order: deploy first, then grant MINTER_ROLE to DeliveryOracleV2
 *         and BURNER_ROLE to AdBurnV2 via the Gnosis Safe multisig.
 */
contract CMXSToken is ERC20, ERC20Burnable, ERC20Capped, ERC20Permit, ERC20Pausable, AccessControl {

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    bytes32 public constant PAUSER_ROLE  = keccak256("PAUSER_ROLE");

    uint256 public constant MAX_SUPPLY    = 1_000_000_000 * 1e18; // 1 billion
    uint256 public constant INITIAL_MINT  =   200_000_000 * 1e18; // 20% TGE

    // ── Events ───────────────────────────────────────────────────────────────

    event RewardMinted(address indexed node, uint256 amount, uint256 timestamp);
    event TokensBurnedForAds(address indexed advertiser, uint256 amount, uint256 timestamp);
    event NetEmissionMinted(address indexed pool, uint256 amount, uint256 timestamp);

    // ── Constructor ───────────────────────────────────────────────────────────

    /**
     * @param adminMultisig Gnosis Safe 3/5 multisig — receives DEFAULT_ADMIN_ROLE,
     *                      PAUSER_ROLE, and the 200 M initial mint.
     */
    constructor(address adminMultisig)
        ERC20("CMXS Protocol Token", "CMXS")
        ERC20Capped(MAX_SUPPLY)
        ERC20Permit("CMXS Protocol Token")
    {
        require(adminMultisig != address(0), "Zero admin");
        _grantRole(DEFAULT_ADMIN_ROLE, adminMultisig);
        _grantRole(PAUSER_ROLE, adminMultisig);
        // Initial mint to multisig/treasury for TGE distribution
        _mint(adminMultisig, INITIAL_MINT);
    }

    // ── Minting ───────────────────────────────────────────────────────────────

    /**
     * @notice Mint PoD reward to a node operator.
     *         Called exclusively by DeliveryOracleV2 (holds MINTER_ROLE).
     */
    function mintReward(address nodeOperator, uint256 amount)
        external onlyRole(MINTER_ROLE)
    {
        _mint(nodeOperator, amount);
        emit RewardMinted(nodeOperator, amount, block.timestamp);
    }

    /**
     * @notice Mint net-emission tokens to the node reward pool.
     *         Recycles burn surplus without increasing outstanding supply beyond cap.
     *         Called by DeliveryOracleV2 (holds MINTER_ROLE).
     */
    function mintNetEmission(address nodeRewardPool, uint256 amount)
        external onlyRole(MINTER_ROLE)
    {
        _mint(nodeRewardPool, amount);
        emit NetEmissionMinted(nodeRewardPool, amount, block.timestamp);
    }

    // ── Burning ───────────────────────────────────────────────────────────────

    /**
     * @notice Burn CMXS from an advertiser's balance proportional to ad spend.
     *         Called exclusively by AdBurnV2 (holds BURNER_ROLE).
     *         AdBurnV2 pre-calculates the amount via the Chainlink price feed.
     */
    function burnForAd(address advertiser, uint256 cmxsAmount)
        external onlyRole(BURNER_ROLE)
    {
        _burn(advertiser, cmxsAmount);
        emit TokensBurnedForAds(advertiser, cmxsAmount, block.timestamp);
    }

    // ── Pause ─────────────────────────────────────────────────────────────────

    function pause()   external onlyRole(PAUSER_ROLE) { _pause(); }
    function unpause() external onlyRole(PAUSER_ROLE) { _unpause(); }

    // ── Overrides ─────────────────────────────────────────────────────────────

    /**
     * @dev Resolve diamond inheritance: ERC20Capped and ERC20Pausable both
     *      override _update; delegate to super which resolves via C3 linearisation.
     */
    function _update(address from, address to, uint256 value)
        internal override(ERC20, ERC20Capped, ERC20Pausable)
    {
        super._update(from, to, value);
    }
}
