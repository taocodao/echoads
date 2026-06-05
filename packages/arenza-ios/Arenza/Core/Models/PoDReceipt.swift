// PoDReceipt.swift — Arenza Prototype
// Proof of Delivery receipt data structures
// Must align with DeliveryOracle.sol ABI on Base Sepolia

import Foundation

// MARK: - Receipt to sign (matches DeliveryOracle.sol PoD struct)

struct PoDReceiptData: Codable {
    let impressionId: String    // 0x-prefixed hex, 32 bytes
    let nodeOperator: String    // 0x Ethereum address
    let channelId: String
    let cpmi: UInt32            // CPM in milli-dollars: 45000 = $45.00
    let viewerIFA: String       // Anonymized viewer ID
    let timestamp: UInt64       // Unix timestamp seconds
    let adComplete: Bool        // True if >80% of ad was viewed

    var jsonData: Data? {
        try? JSONEncoder().encode(self)
    }
}

// MARK: - Submission payload (POST /api/delivery/pod)

struct PoDSubmissionPayload: Codable {
    let impressionId: String
    let signature: String           // Hex-encoded DER ECDSA signature
    let publicKey: String           // Hex-encoded compressed P256 public key
    let receiptData: PoDReceiptData
    let switchLatencyMs: Double
    let walletAddress: String
}

// MARK: - Backend response after PoD accepted

struct PoDSubmissionResult: Codable {
    let accepted: Bool
    let txHash: String?             // Base L2 transaction hash
    let reward: Double?             // CMXS tokens earned (0.001)
    let message: String?
}

// MARK: - Local record for Earnings UI

struct LocalPoDRecord: Identifiable {
    let id = UUID()
    let impressionId: String
    let advertiser: String
    let cpm: Double
    let cmxsEarned: Double
    let txHash: String?
    let timestamp: Date
    let slaMet: Bool
    let switchLatencyMs: Double

    var basescanURL: URL? {
        guard let hash = txHash else { return nil }
        return URL(string: "https://sepolia.basescan.org/tx/\(hash)")
    }

    var formattedTimestamp: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }
}
