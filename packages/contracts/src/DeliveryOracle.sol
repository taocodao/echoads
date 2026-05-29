// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

interface ICMXSToken {
    function mintReward(address node, bytes32 podHash) external;
}

contract DeliveryOracle is Ownable {
    using ECDSA for bytes32;
    using MessageHashUtils for bytes32;

    address public trustedSigner;
    ICMXSToken public cmxs;

    struct PoDRecord {
        bytes32 podHash;
        address viewer;
        address node;
        uint256 timestamp;
        uint256 cpmPaid;
        bool rewarded;
        string txHash;
    }

    mapping(bytes32 => PoDRecord) public records;
    mapping(bytes32 => bool) public usedHashes;
    bytes32[] public allPods;

    event ProofOfDeliveryRecorded(
        bytes32 indexed podHash,
        address indexed viewer,
        address indexed node,
        uint256 cpmPaid,
        uint256 timestamp
    );
    event NodeRewarded(address indexed node, bytes32 podHash, uint256 amount);
    event DeliveryProofAccepted(
        bytes32 indexed deliveryId,
        address indexed nodeOperator,
        uint256 segmentCount,
        uint256 latencyMs,
        uint256 timestamp
    );
    event TrustedSignerUpdated(address indexed oldSigner, address indexed newSigner);

    error ProofExpired();
    error ProofAlreadyUsed();
    error InvalidSignature();
    error ZeroAddress();

    constructor(address _trustedSigner, address _cmxsToken) Ownable(msg.sender) {
        if (_trustedSigner == address(0) || _cmxsToken == address(0)) revert ZeroAddress();
        trustedSigner = _trustedSigner;
        cmxs = ICMXSToken(_cmxsToken);
    }

    // New Viewer-signed PoD
    function recordDelivery(
        bytes32 impressionId,
        address node,
        uint256 cpmPaid,
        bytes calldata viewerSig
    ) external returns (bytes32 podHash) {
        podHash = keccak256(abi.encodePacked(impressionId, msg.sender, block.timestamp, node));
        if (usedHashes[podHash]) revert ProofAlreadyUsed();

        bytes32 msgHash = keccak256(abi.encodePacked(impressionId, node, cpmPaid)).toEthSignedMessageHash();
        address signer = msgHash.recover(viewerSig);
        if (signer != msg.sender) revert InvalidSignature();

        records[podHash] = PoDRecord({
            podHash: podHash,
            viewer: msg.sender,
            node: node,
            timestamp: block.timestamp,
            cpmPaid: cpmPaid,
            rewarded: true,
            txHash: ""
        });
        usedHashes[podHash] = true;
        allPods.push(podHash);

        cmxs.mintReward(node, podHash);

        emit ProofOfDeliveryRecorded(podHash, msg.sender, node, cpmPaid, block.timestamp);
        emit NodeRewarded(node, podHash, 0.001 ether); // 0.001 CMXS

        return podHash;
    }

    // Existing Trusted Signer PoD (Legacy / Phase 0 fallback)
    function submitDeliveryProof(
        bytes32 deliveryId,
        address nodeOperator,
        uint256 segmentCount,
        uint256 latencyMs,
        uint256 expiry,
        bytes calldata signature
    ) external {
        if (block.timestamp > expiry) revert ProofExpired();
        if (usedHashes[deliveryId]) revert ProofAlreadyUsed();

        bytes32 messageHash = keccak256(
            abi.encodePacked(
                deliveryId,
                nodeOperator,
                segmentCount,
                latencyMs,
                expiry,
                block.chainid
            )
        );

        address recovered = messageHash.toEthSignedMessageHash().recover(signature);
        if (recovered != trustedSigner) revert InvalidSignature();

        usedHashes[deliveryId] = true;

        emit DeliveryProofAccepted(deliveryId, nodeOperator, segmentCount, latencyMs, block.timestamp);

        cmxs.mintReward(nodeOperator, deliveryId);
    }

    function updateTrustedSigner(address newSigner) external onlyOwner {
        if (newSigner == address(0)) revert ZeroAddress();
        emit TrustedSignerUpdated(trustedSigner, newSigner);
        trustedSigner = newSigner;
    }

    function setCmxsToken(address newToken) external onlyOwner {
        if (newToken == address(0)) revert ZeroAddress();
        cmxs = ICMXSToken(newToken);
    }

    function getPoDCount() external view returns (uint256) {
        return allPods.length;
    }

    function getRecord(bytes32 podHash) external view returns (PoDRecord memory) {
        return records[podHash];
    }
}
