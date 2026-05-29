// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract CPMAuction {
    struct AuctionSlot {
        bytes32 slotId;
        uint256 floorCPM;
        address winner;
        uint256 winningCPM;
        uint256 settledAt;
        bool isPoD_verified;
    }

    mapping(bytes32 => AuctionSlot) public slots;
    address public admin;

    event AuctionWon(bytes32 indexed slotId, address indexed winner, uint256 cpm);
    event SlotVerified(bytes32 indexed slotId, bytes32 podHash);

    constructor() {
        admin = msg.sender;
    }

    function recordWinner(
        bytes32 slotId,
        uint256 floorCPM,
        address winner,
        uint256 winningCPM
    ) external {
        require(msg.sender == admin, "Only admin");
        require(winningCPM >= floorCPM, "Below floor CPM");
        slots[slotId] = AuctionSlot({
            slotId: slotId,
            floorCPM: floorCPM,
            winner: winner,
            winningCPM: winningCPM,
            settledAt: block.timestamp,
            isPoD_verified: false
        });
        emit AuctionWon(slotId, winner, winningCPM);
    }

    function markVerified(bytes32 slotId, bytes32 podHash) external {
        require(msg.sender == admin, "Only admin");
        slots[slotId].isPoD_verified = true;
        emit SlotVerified(slotId, podHash);
    }
}
