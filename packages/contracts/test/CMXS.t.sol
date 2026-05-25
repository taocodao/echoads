// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/CMXS.sol";
import "../src/DeliveryOracle.sol";

contract CMXSTest is Test {
    CMXS public cmxs;
    DeliveryOracle public oracle;

    address public owner = makeAddr("owner");
    address public nodeOperator = makeAddr("nodeOperator");
    address public oracleAddr = makeAddr("oracleSignerEOA"); // signing key
    address public randomUser = makeAddr("randomUser");

    function setUp() public {
        vm.startPrank(owner);
        // Deploy oracle first (needs a placeholder cmxs address — update after)
        oracle = new DeliveryOracle(oracleAddr, address(1)); // placeholder
        cmxs = new CMXS(address(oracle));
        // Update oracle's cmxs reference
        oracle.setCmxsToken(address(cmxs));
        vm.stopPrank();
    }

    // -------------------------------------------------------------------------
    // Constructor
    // -------------------------------------------------------------------------

    function test_Constructor_CorrectSupply() public {
        uint256 expectedMax = 1_000_000_000 * 10 ** 18;
        assertEq(cmxs.MAX_SUPPLY(), expectedMax);
    }

    function test_Constructor_RewardsPool35Percent() public {
        uint256 expected = (cmxs.MAX_SUPPLY() * 35) / 100;
        assertEq(cmxs.rewardsPoolBalance(), expected);
    }

    function test_Constructor_Owner65Percent() public {
        uint256 expected = (cmxs.MAX_SUPPLY() * 65) / 100;
        assertEq(cmxs.balanceOf(owner), expected);
    }

    function test_Constructor_OracleSet() public {
        assertEq(cmxs.oracleContract(), address(oracle));
    }

    // -------------------------------------------------------------------------
    // rewardNode
    // -------------------------------------------------------------------------

    function test_RewardNode_Success() public {
        bytes32 deliveryId = keccak256("delivery-001");
        uint256 poolBefore = cmxs.rewardsPoolBalance();
        uint256 nodeBefore = cmxs.balanceOf(nodeOperator);

        vm.prank(address(oracle));
        cmxs.rewardNode(nodeOperator, deliveryId);

        assertEq(cmxs.rewardsPoolBalance(), poolBefore - cmxs.REWARD_PER_VERIFIED_DELIVERY());
        assertEq(cmxs.balanceOf(nodeOperator), nodeBefore + cmxs.REWARD_PER_VERIFIED_DELIVERY());
    }

    function test_RewardNode_EmitsEvent() public {
        bytes32 deliveryId = keccak256("delivery-002");
        vm.expectEmit(true, false, false, true);
        emit CMXS.NodeRewarded(nodeOperator, cmxs.REWARD_PER_VERIFIED_DELIVERY(), deliveryId);

        vm.prank(address(oracle));
        cmxs.rewardNode(nodeOperator, deliveryId);
    }

    function test_RewardNode_RevertsIfNotOracle() public {
        vm.prank(randomUser);
        vm.expectRevert(CMXS.OnlyOracle.selector);
        cmxs.rewardNode(nodeOperator, keccak256("delivery-003"));
    }

    function test_RewardNode_RevertsOnZeroAddress() public {
        vm.prank(address(oracle));
        vm.expectRevert(CMXS.ZeroAddress.selector);
        cmxs.rewardNode(address(0), keccak256("delivery-004"));
    }

    // -------------------------------------------------------------------------
    // burnForPremiumSlot
    // -------------------------------------------------------------------------

    function test_Burn_ReducesSupply() public {
        // Give owner some tokens to burn
        uint256 burnAmount = 1000 * 10 ** 18;
        uint256 supplyBefore = cmxs.totalSupply();

        vm.prank(owner);
        cmxs.burnForPremiumSlot(burnAmount);

        assertEq(cmxs.totalSupply(), supplyBefore - burnAmount);
    }

    function test_Burn_EmitsEvent() public {
        uint256 burnAmount = 500 * 10 ** 18;
        vm.expectEmit(true, false, false, true);
        emit CMXS.TokensBurned(owner, burnAmount);

        vm.prank(owner);
        cmxs.burnForPremiumSlot(burnAmount);
    }

    // -------------------------------------------------------------------------
    // setOracleContract
    // -------------------------------------------------------------------------

    function test_SetOracle_Success() public {
        address newOracle = makeAddr("newOracle");
        vm.prank(owner);
        cmxs.setOracleContract(newOracle);
        assertEq(cmxs.oracleContract(), newOracle);
    }

    function test_SetOracle_RevertsIfNotOwner() public {
        vm.prank(randomUser);
        vm.expectRevert();
        cmxs.setOracleContract(makeAddr("newOracle"));
    }

    function test_SetOracle_RevertsOnZeroAddress() public {
        vm.prank(owner);
        vm.expectRevert(CMXS.ZeroAddress.selector);
        cmxs.setOracleContract(address(0));
    }

    // -------------------------------------------------------------------------
    // Fuzz tests
    // -------------------------------------------------------------------------

    function testFuzz_Burn_NeverExceedsBalance(uint256 burnAmount) public {
        uint256 ownerBalance = cmxs.balanceOf(owner);
        burnAmount = bound(burnAmount, 0, ownerBalance);

        vm.prank(owner);
        cmxs.burnForPremiumSlot(burnAmount);
        assertEq(cmxs.balanceOf(owner), ownerBalance - burnAmount);
    }
}
