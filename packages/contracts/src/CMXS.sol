// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract CMXS is ERC20, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    uint256 public constant MAX_SUPPLY = 1_000_000_000 * 1e18;
    uint256 public constant DAILY_MINT_CAP = 2_880_000 * 1e18;
    uint256 public constant POD_REWARD = 0.001 * 1e18; // 1e15

    uint256 public dailyMinted;
    uint256 public lastMintDay;
    uint256 public totalBurned;
    uint256 public totalMinted;

    event TokensMinted(address indexed node, uint256 amount, bytes32 indexed podHash);
    event TokensBurned(address indexed advertiser, uint256 amount, uint256 usdcSpent);

    constructor(address treasury) ERC20("CatonMX Settlement Token", "CMXS") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        
        uint256 initialMint = 200_000_000 * 1e18;
        _mint(treasury, initialMint);
        totalMinted += initialMint;
    }

    function mintReward(address node, bytes32 podHash) external onlyRole(MINTER_ROLE) {
        _enforceDailyCap(POD_REWARD);
        require(totalMinted + POD_REWARD <= MAX_SUPPLY, "Max supply reached");
        
        _mint(node, POD_REWARD);
        totalMinted += POD_REWARD;
        emit TokensMinted(node, POD_REWARD, podHash);
    }

    function burnFromAdSpend(address advertiser, uint256 usdcAmount) external onlyRole(BURNER_ROLE) {
        // Burn rate: 1 CMXS per $0.10 USDC (USDC has 6 decimals, CMXS has 18)
        uint256 burnAmount = (usdcAmount * 10 * 1e18) / 1e6;
        require(balanceOf(advertiser) >= burnAmount, "Insufficient CMXS balance");
        
        _burn(advertiser, burnAmount);
        totalBurned += burnAmount;
        emit TokensBurned(advertiser, burnAmount, usdcAmount);
    }

    function _enforceDailyCap(uint256 amount) internal {
        uint256 today = block.timestamp / 1 days;
        if (today > lastMintDay) {
            dailyMinted = 0;
            lastMintDay = today;
        }
        require(dailyMinted + amount <= DAILY_MINT_CAP, "Daily mint cap exceeded");
        dailyMinted += amount;
    }

    function circulatingSupply() external view returns (uint256) {
        return totalSupply();
    }

    function burnRatio() external view returns (uint256) {
        if (totalMinted == 0) return 0;
        return (totalBurned * 10000) / totalMinted;
    }
}
