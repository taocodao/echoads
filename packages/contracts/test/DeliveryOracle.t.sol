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

    uint256 public signerPrivateKey = 0xA11CE;
    address public trustedSigner;
    
    uint256 public viewerPrivateKey = 0xB11CE;
    address public viewer;

    function setUp() public {
        trustedSigner = vm.addr(signerPrivateKey);
        viewer = vm.addr(viewerPrivateKey);

        vm.startPrank(owner);
        cmxs = new CMXS(makeAddr("treasury"));
        oracle = new DeliveryOracle(trustedSigner, address(cmxs));
        cmxs.grantRole(cmxs.MINTER_ROLE(), address(oracle));
        vm.stopPrank();
    }

    function _signViewerPoD(
        bytes32 impressionId,
        address nodeAddr,
        uint256 cpmPaid
    ) internal view returns (bytes memory) {
        bytes32 msgHash = keccak256(abi.encodePacked(impressionId, nodeAddr, cpmPaid));
        bytes32 ethSignedHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", msgHash));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(viewerPrivateKey, ethSignedHash);
        return abi.encodePacked(r, s, v);
    }

    function test_RecordDelivery_Success() public {
        bytes32 impressionId = keccak256("imp-1");
        uint256 cpmPaid = 25_000_000;
        
        bytes memory sig = _signViewerPoD(impressionId, nodeOperator, cpmPaid);
        
        uint256 balBefore = cmxs.balanceOf(nodeOperator);
        
        vm.prank(viewer);
        bytes32 podHash = oracle.recordDelivery(impressionId, nodeOperator, cpmPaid, sig);
        
        assertEq(cmxs.balanceOf(nodeOperator), balBefore + 0.001 * 1e18);
        assertTrue(oracle.usedHashes(podHash));
    }

    function test_RecordDelivery_RevertInvalidSig() public {
        bytes32 impressionId = keccak256("imp-2");
        uint256 cpmPaid = 25_000_000;
        
        // Signed by someone else
        bytes32 msgHash = keccak256(abi.encodePacked(impressionId, nodeOperator, cpmPaid));
        bytes32 ethSignedHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", msgHash));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerPrivateKey, ethSignedHash);
        bytes memory badSig = abi.encodePacked(r, s, v);
        
        vm.prank(viewer);
        vm.expectRevert(DeliveryOracle.InvalidSignature.selector);
        oracle.recordDelivery(impressionId, nodeOperator, cpmPaid, badSig);
    }
}
