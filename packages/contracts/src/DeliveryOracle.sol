// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

interface ICMXS {
    function rewardNode(address nodeOperator, bytes32 deliveryId) external;
}

/**
 * @title DeliveryOracle — Trusted-signer proof submission oracle
 * @notice Verifies ECDSA-signed delivery proofs from the Project Clarity backend
 *         and triggers CMXS token rewards for node operators.
 *
 * @dev Phase 0: A trusted backend signing key verifies delivery proofs.
 *      Phase 1 upgrade path: call updateTrustedSigner() with the Chainlink CRE
 *      workflow contract address — zero contract rewrite required.
 *
 *      Security: proofs include block.chainid to prevent cross-chain replay.
 *      Proofs include expiry timestamps to prevent delayed replay.
 *      deliveryIds are one-time-use (nonce-like) to prevent double submission.
 */
contract DeliveryOracle is Ownable {
    using ECDSA for bytes32;
    using MessageHashUtils for bytes32;

    // -------------------------------------------------------------------------
    // State
    // -------------------------------------------------------------------------

    /// @notice Backend signing key (or CRE contract in Phase 1)
    address public trustedSigner;

    /// @notice CMXS token contract
    ICMXS public cmxsToken;

    /// @notice One-time-use delivery IDs (nonce protection against double-spend)
    mapping(bytes32 => bool) public usedDeliveryIds;

    // -------------------------------------------------------------------------
    // Events
    // -------------------------------------------------------------------------

    event DeliveryProofAccepted(
        bytes32 indexed deliveryId,
        address indexed nodeOperator,
        uint256 segmentCount,
        uint256 latencyMs,
        uint256 timestamp
    );

    event TrustedSignerUpdated(address indexed oldSigner, address indexed newSigner);

    // -------------------------------------------------------------------------
    // Errors
    // -------------------------------------------------------------------------

    error ProofExpired();
    error ProofAlreadyUsed();
    error InvalidSignature();
    error ZeroAddress();

    // -------------------------------------------------------------------------
    // Constructor
    // -------------------------------------------------------------------------

    /**
     * @param _trustedSigner  Backend oracle signing key address
     * @param _cmxsToken      CMXS token contract address
     */
    constructor(address _trustedSigner, address _cmxsToken) Ownable(msg.sender) {
        if (_trustedSigner == address(0) || _cmxsToken == address(0)) revert ZeroAddress();
        trustedSigner = _trustedSigner;
        cmxsToken = ICMXS(_cmxsToken);
    }

    // -------------------------------------------------------------------------
    // Core: Submit a delivery proof
    // -------------------------------------------------------------------------

    /**
     * @notice Submit a signed delivery proof and trigger CMXS node reward.
     * @param deliveryId    Unique ID: keccak256(txHash + nodeAddr + timestamp) — computed off-chain
     * @param nodeOperator  Address of the node operator claiming the reward
     * @param segmentCount  Number of MOQ segments delivered in this batch
     * @param latencyMs     Measured delivery latency (must be < 500ms for SLA)
     * @param expiry        Unix timestamp after which this proof is invalid
     * @param signature     ECDSA signature from trustedSigner over the above params
     */
    function submitDeliveryProof(
        bytes32 deliveryId,
        address nodeOperator,
        uint256 segmentCount,
        uint256 latencyMs,
        uint256 expiry,
        bytes calldata signature
    ) external {
        // Time-bound: reject stale proofs
        if (block.timestamp > expiry) revert ProofExpired();

        // Nonce: reject replayed proofs
        if (usedDeliveryIds[deliveryId]) revert ProofAlreadyUsed();

        // Verify ECDSA signature
        bytes32 messageHash = keccak256(
            abi.encodePacked(
                deliveryId,
                nodeOperator,
                segmentCount,
                latencyMs,
                expiry,
                block.chainid // cross-chain replay protection
            )
        );

        address recovered = messageHash.toEthSignedMessageHash().recover(signature);
        if (recovered != trustedSigner) revert InvalidSignature();

        // Mark deliveryId as used
        usedDeliveryIds[deliveryId] = true;

        // Emit proof event (indexed for advertiser dashboard queries)
        emit DeliveryProofAccepted(deliveryId, nodeOperator, segmentCount, latencyMs, block.timestamp);

        // Trigger CMXS reward (only if latency SLA met — oracle backend enforces this
        // before signing, contract trusts the signature for gas efficiency in Phase 0)
        cmxsToken.rewardNode(nodeOperator, deliveryId);
    }

    // -------------------------------------------------------------------------
    // Admin: Upgrade path
    // -------------------------------------------------------------------------

    /**
     * @notice Update the trusted signer.
     * @dev Phase 1 upgrade: set newSigner = Chainlink CRE workflow contract.
     *      The CRE contract must implement the same signing scheme,
     *      or this contract can be extended to support a CRE callback interface.
     */
    function updateTrustedSigner(address newSigner) external onlyOwner {
        if (newSigner == address(0)) revert ZeroAddress();
        emit TrustedSignerUpdated(trustedSigner, newSigner);
        trustedSigner = newSigner;
    }

    /**
     * @notice Update the CMXS token contract (e.g., if token is upgraded)
     */
    function setCmxsToken(address newToken) external onlyOwner {
        if (newToken == address(0)) revert ZeroAddress();
        cmxsToken = ICMXS(newToken);
    }
}
