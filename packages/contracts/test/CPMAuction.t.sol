// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/CPMAuction.sol";

contract CPMAuctionTest is Test {
    CPMAuction public auction;
    address public admin = makeAddr("admin");
    address public winner = makeAddr("winner");

    function setUp() public {
        vm.startPrank(admin);
        auction = new CPMAuction();
        vm.stopPrank();
    }

    function test_RecordWinner_Success() public {
        bytes32 slotId = keccak256("slot-1");

        vm.startPrank(admin);
        auction.recordWinner(slotId, 15_000_000, winner, 20_000_000);
        vm.stopPrank();

        (bytes32 id, uint256 floor, address w, uint256 winCpm, uint256 settled, bool verified) = auction.slots(slotId);
        assertEq(id, slotId);
        assertEq(w, winner);
        assertEq(winCpm, 20_000_000);
        assertFalse(verified);
    }

    function test_RecordWinner_RevertBelowFloor() public {
        bytes32 slotId = keccak256("slot-2");
        vm.startPrank(admin);
        vm.expectRevert("Below floor CPM");
        auction.recordWinner(slotId, 15_000_000, winner, 10_000_000);
        vm.stopPrank();
    }

    function test_MarkVerified() public {
        bytes32 slotId = keccak256("slot-3");

        vm.startPrank(admin);
        auction.recordWinner(slotId, 15_000_000, winner, 20_000_000);
        auction.markVerified(slotId, keccak256("pod-1"));
        vm.stopPrank();

        (,,,,, bool verified) = auction.slots(slotId);
        assertTrue(verified);
    }
}
