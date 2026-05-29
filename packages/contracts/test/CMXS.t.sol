// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/CMXS.sol";

contract CMXSTest is Test {
    CMXS public cmxs;
    
    address public treasury = makeAddr("treasury");
    address public admin = makeAddr("admin");
    address public minter = makeAddr("minter");
    address public burner = makeAddr("burner");
    address public randomUser = makeAddr("randomUser");
    address public node = makeAddr("node");
    address public advertiser = makeAddr("advertiser");

    function setUp() public {
        vm.startPrank(admin);
        cmxs = new CMXS(treasury);
        cmxs.grantRole(cmxs.MINTER_ROLE(), minter);
        cmxs.grantRole(cmxs.BURNER_ROLE(), burner);
        vm.stopPrank();
    }

    function test_Constructor() public {
        assertEq(cmxs.balanceOf(treasury), 200_000_000 * 1e18);
        assertEq(cmxs.totalMinted(), 200_000_000 * 1e18);
        assertTrue(cmxs.hasRole(cmxs.DEFAULT_ADMIN_ROLE(), admin));
    }

    function test_MintReward_Success() public {
        vm.prank(minter);
        cmxs.mintReward(node, keccak256("pod1"));
        assertEq(cmxs.balanceOf(node), 0.001 * 1e18);
        assertEq(cmxs.dailyMinted(), 0.001 * 1e18);
    }

    function test_MintReward_RevertNonMinter() public {
        vm.prank(randomUser);
        vm.expectRevert();
        cmxs.mintReward(node, keccak256("pod1"));
    }

    function test_BurnFromAdSpend_Success() public {
        // Give advertiser some CMXS by transferring from treasury
        vm.prank(treasury);
        cmxs.transfer(advertiser, 100 * 1e18);
        
        vm.prank(burner);
        // burn 1 CMXS for 0.1 USDC (100,000 units since 6 decimals)
        // Let's burn for $10 USDC => 10_000_000 units
        // formula: 10_000_000 * 10 * 1e18 / 1e6 = 100 * 1e18
        cmxs.burnFromAdSpend(advertiser, 10_000_000);
        
        assertEq(cmxs.balanceOf(advertiser), 0);
        assertEq(cmxs.totalBurned(), 100 * 1e18);
    }

    function test_BurnFromAdSpend_RevertNonBurner() public {
        vm.prank(randomUser);
        vm.expectRevert();
        cmxs.burnFromAdSpend(advertiser, 1_000_000);
    }
}
