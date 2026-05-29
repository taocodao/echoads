// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ICMXSBurner {
    function burnFromAdSpend(address advertiser, uint256 usdcAmount) external;
}

contract AdBurn {
    IERC20 public usdc;
    ICMXSBurner public cmxs;
    address public platform;
    uint256 public platformFee;

    event AdPaymentSettled(
        bytes32 indexed impressionId,
        address indexed advertiser,
        address indexed publisher,
        uint256 usdcAmount,
        uint256 cmxsBurned
    );

    constructor(address _usdc, address _cmxs, address _platform, uint256 _feeBps) {
        usdc = IERC20(_usdc);
        cmxs = ICMXSBurner(_cmxs);
        platform = _platform;
        platformFee = _feeBps;
    }

    function settleAdPayment(
        bytes32 impressionId,
        address advertiser,
        address publisher,
        uint256 usdcAmount
    ) external {
        require(usdc.transferFrom(advertiser, address(this), usdcAmount), "USDC transfer failed");

        uint256 platformShare = (usdcAmount * platformFee) / 10000;
        uint256 publisherShare = usdcAmount - platformShare;

        require(usdc.transfer(platform, platformShare), "USDC fee transfer failed");
        require(usdc.transfer(publisher, publisherShare), "USDC pub transfer failed");

        uint256 burnAmount = (usdcAmount * 10 * 1e18) / 1e6;
        cmxs.burnFromAdSpend(advertiser, usdcAmount);

        emit AdPaymentSettled(impressionId, advertiser, publisher, usdcAmount, burnAmount);
    }
}
