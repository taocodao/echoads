// OracleSubmitter.swift
// Builds and submits the PoD receipt after a verified ad impression.
// For demo: mocks the on-chain call; swap mock for real web3swift call
// once contract addresses are deployed.

import Foundation
import CryptoKit

// ── PoD Receipt model (mirrors DeliveryOracle.sol struct) ────────────────────
struct PoDReceipt: Codable {
    let impressionId: String
    let nodeOperator: String
    let channelId: String
    let cpmi: UInt32              // CPM in milli-dollars: 47500 = $47.50
    let timestamp: UInt32
    let adComplete: Bool
    let signature: String         // DER-encoded hex
    let txHash: String            // Base Sepolia tx hash (mock for demo)

    var cpm: Double { Double(cpmi) / 1000 }
}

// ── Submitter ─────────────────────────────────────────────────────────────────
final class OracleSubmitter {

    static let shared = OracleSubmitter()
    private init() {}

    private let seManager = SecureEnclaveManager.shared

    func submitPoD(impressionId: String, cpm: Double, channelId: String) async throws -> PoDReceipt {
        let wallet = try seManager.currentWalletAddress()
        let cpmi   = UInt32(cpm * 1000)
        let ts     = UInt32(Date().timeIntervalSince1970)

        // 1. Build receipt payload
        let payload = "\(impressionId)|\(wallet)|\(cpmi)|\(ts)".data(using: .utf8)!

        // 2. Sign with Secure Enclave (or software key on Simulator)
        let signature = try seManager.sign(data: payload)
        let sigHex = signature.map { String(format: "%02x", $0) }.joined()

        print("[PoD] Signing receipt for impression \(impressionId)")
        print("[PoD] Wallet: \(wallet)")
        print("[PoD] Signature: \(sigHex.prefix(32))…")

        // 3. Submit to backend / oracle
        //    ── Production path ───────────────────────────────────────────────
        //    let body: [String: Any] = [
        //        "impressionId": impressionId,
        //        "signature": sigHex,
        //        "publicKey": publicKeyHex,
        //        "receiptData": ["impressionId": impressionId, "timestamp": ts,
        //                        "channelId": channelId, "cpmi": cpmi]
        //    ]
        //    let result = try await CMXSAPIClient().post("/pod/submit-receipt", body: body)
        //    ─────────────────────────────────────────────────────────────────

        // ── Demo mock (simulates 35s round-trip) ─────────────────────────────
        try await Task.sleep(nanoseconds: 500_000_000)   // 0.5s simulated latency

        let mockTxHash = "0x" + (0..<32).map { _ in
            String(format: "%02x", UInt8.random(in: 0...255))
        }.joined()

        let receipt = PoDReceipt(
            impressionId: impressionId,
            nodeOperator: wallet,
            channelId: channelId,
            cpmi: cpmi,
            timestamp: ts,
            adComplete: true,
            signature: sigHex,
            txHash: mockTxHash
        )

        print("[PoD] ✅ Receipt minted (mock) – txHash: \(mockTxHash.prefix(20))…")
        return receipt
    }
}
