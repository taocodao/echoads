// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/DeliveryOracle.sol";
import "../src/CMXS.sol";

contract DeliveryOracleTest is Test {
    DeliveryOracle public oracle;
    CMXS public cmxs;

    address public owner = makeAddr("owner");
    address public nodeOperator = makeAddr("nodeOperator");
    address public randomUser = makeAddr("randomUser");

    // The trusted signer key pair
    uint256 public signerPrivateKey = 0xA11CE;
    address public trustedSigner;

    function setUp() public {
        trustedSigner = vm.addr(signerPrivateKey);

        vm.startPrank(owner);
        oracle = new DeliveryOracle(trustedSigner, address(1)); // temp cmxs
        cmxs = new CMXS(address(oracle));
        oracle.setCmxsToken(address(cmxs));
        vm.stopPrank();
    }

    // -------------------------------------------------------------------------
    // Helpers
    // -------------------------------------------------------------------------

    function _signProof(
        bytes32 deliveryId,
        address nodeAddr,
        uint256 segmentCount,
        uint256 latencyMs,
        uint256 expiry
    ) internal view returns (bytes memory) {
        bytes32 messageHash = keccak256(
            abi.encodePacked(deliveryId, nodeAddr, segmentCount, latencyMs, expiry, block.chainid)
        );
        bytes32 ethSignedHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerPrivateKey, ethSignedHash);
        return abi.encodePacked(r, s, v);
    }

    // -------------------------------------------------------------------------
    // submitDeliveryProof — Happy path
    // -------------------------------------------------------------------------

    function test_SubmitProof_Success() public {
        bytes32 deliveryId = keccak256("delivery-001");
        uint256 expiry = block.timestamp + 3600;
        uint256 latencyMs = 287; // well under 500ms SLA

        bytes memory sig = _signProof(deliveryId, nodeOperator, 10, latencyMs, expiry);

        uint256 balanceBefore = cmxs.balanceOf(nodeOperator);

        oracle.submitDeliveryProof(deliveryId, nodeOperator, 10, latencyMs, expiry, sig);

        // Node should have received CMXS reward
        assertEq(cmxs.balanceOf(nodeOperator), balanceBefore + cmxs.REWARD_PER_VERIFIED_DELIVERY());
    }

    function test_SubmitProof_EmitsEvent() public {
        bytes32 deliveryId = keccak256("delivery-002");
        uint256 expiry = block.timestamp + 3600;

        bytes memory sig = _signProof(deliveryId, nodeOperator, 5, 350, expiry);

        vm.expectEmit(true, true, false, true);
        emit DeliveryOracle.DeliveryProofAccepted(deliveryId, nodeOperator, 5, 350, block.timestamp);

        oracle.submitDeliveryProof(deliveryId, nodeOperator, 5, 350, expiry, sig);
    }

    // -------------------------------------------------------------------------
    // submitDeliveryProof — Rejection cases
    // -------------------------------------------------------------------------

    function test_RejectProof_Expired() public {
        bytes32 deliveryId = keccak256("delivery-003");
        uint256 expiry = block.timestamp - 1; // already expired

        bytes memory sig = _signProof(deliveryId, nodeOperator, 10, 200, expiry);

        vm.expectRevert(DeliveryOracle.ProofExpired.selector);
        oracle.submitDeliveryProof(deliveryId, nodeOperator, 10, 200, expiry, sig);
    }

    function test_RejectProof_DoubleSpend() public {
        bytes32 deliveryId = keccak256("delivery-004");
        uint256 expiry = block.timestamp + 3600;

        bytes memory sig = _signProof(deliveryId, nodeOperator, 10, 300, expiry);

        // First submission: success
        oracle.submitDeliveryProof(deliveryId, nodeOperator, 10, 300, expiry, sig);

        // Second submission with same deliveryId: must revert
        vm.expectRevert(DeliveryOracle.ProofAlreadyUsed.selector);
        oracle.submitDeliveryProof(deliveryId, nodeOperator, 10, 300, expiry, sig);
    }

    function test_RejectProof_InvalidSignature() public {
        bytes32 deliveryId = keccak256("delivery-005");
        uint256 expiry = block.timestamp + 3600;

        // Sign with wrong private key
        uint256 wrongKey = 0xBAD;
        bytes32 messageHash = keccak256(
            abi.encodePacked(deliveryId, nodeOperator, uint256(10), uint256(250), expiry, block.chainid)
        );
        bytes32 ethSignedHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(wrongKey, ethSignedHash);
        bytes memory badSig = abi.encodePacked(r, s, v);

        vm.expectRevert(DeliveryOracle.InvalidSignature.selector);
        oracle.submitDeliveryProof(deliveryId, nodeOperator, 10, 250, expiry, badSig);
    }

    function test_RejectProof_TamperedParams() public {
        bytes32 deliveryId = keccak256("delivery-006");
        uint256 expiry = block.timestamp + 3600;

        // Sign for 10 segments but submit 999 — tampered params
        bytes memory sig = _signProof(deliveryId, nodeOperator, 10, 200, expiry);

        vm.expectRevert(DeliveryOracle.InvalidSignature.selector);
        oracle.submitDeliveryProof(deliveryId, nodeOperator, 999, 200, expiry, sig);
    }

    // -------------------------------------------------------------------------
    // updateTrustedSigner — CRE upgrade path
    // -------------------------------------------------------------------------

    function test_UpdateSigner_Success() public {
        address cre = makeAddr("chainlinkCREContract");
        vm.prank(owner);
        oracle.updateTrustedSigner(cre);
        assertEq(oracle.trustedSigner(), cre);
    }

    function test_UpdateSigner_RevertsIfNotOwner() public {
        vm.prank(randomUser);
        vm.expectRevert();
        oracle.updateTrustedSigner(makeAddr("cre"));
    }

    // -------------------------------------------------------------------------
    // Fuzz: multiple unique proofs all succeed
    // -------------------------------------------------------------------------

    function testFuzz_MultipleProofs_UniqueIds(uint8 count) public {
        count = uint8(bound(uint256(count), 1, 20));
        uint256 expiry = block.timestamp + 3600;

        for (uint256 i = 0; i < count; i++) {
            bytes32 deliveryId = keccak256(abi.encodePacked("fuzz-delivery", i));
            bytes memory sig = _signProof(deliveryId, nodeOperator, 5, 400, expiry);
            oracle.submitDeliveryProof(deliveryId, nodeOperator, 5, 400, expiry, sig);
        }

        assertEq(
            cmxs.balanceOf(nodeOperator),
            uint256(count) * cmxs.REWARD_PER_VERIFIED_DELIVERY()
        );
    }
}
