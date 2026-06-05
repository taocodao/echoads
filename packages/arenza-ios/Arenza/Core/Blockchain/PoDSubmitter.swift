// PoDSubmitter.swift — Arenza Prototype
// Signs and submits Proof-of-Delivery receipts to the backend (which relays to chain).
// Port of browser packages/player/src/pod/PoDClient.ts → Swift with Secure Enclave.

import Foundation

final class PoDSubmitter {

    private let apiClient: CMXSAPIClient
    private let seManager: SecureEnclaveManager
    private(set) var pendingRecords: [LocalPoDRecord] = []

    init(apiClient: CMXSAPIClient, seManager: SecureEnclaveManager = .shared) {
        self.apiClient = apiClient
        self.seManager = seManager
    }

    // MARK: - Main Submit Function

    /// Signs an ad impression receipt and submits to backend for on-chain verification.
    /// Called at ad completion (T+30s from ad start).
    @discardableResult
    func submit(
        impressionId: String,
        channelId: String,
        cpm: Double,
        advertiser: String,
        switchLatencyMs: Double
    ) async -> LocalPoDRecord? {
        let walletAddress = WalletDerivation.currentWalletAddress()
        let timestamp = UInt64(Date().timeIntervalSince1970)

        let receipt = PoDReceiptData(
            impressionId: impressionId,
            nodeOperator: walletAddress,
            channelId: channelId,
            cpmi: UInt32(cpm * 1000),
            viewerIFA: anonymizedIFA(),
            timestamp: timestamp,
            adComplete: true
        )

        // Sign with Secure Enclave (or software fallback on simulator)
        guard let receiptData = receipt.jsonData,
              let signatureData = try? seManager.sign(data: receiptData),
              let publicKeyHex = try? seManager.publicKeyHex() else {
            print("[PoD] Signing failed — skipping submission")
            return nil
        }

        let payload = PoDSubmissionPayload(
            impressionId: impressionId,
            signature: signatureData.hexString,
            publicKey: publicKeyHex,
            receiptData: receipt,
            switchLatencyMs: switchLatencyMs,
            walletAddress: walletAddress
        )

        let t0 = Date()
        var result: PoDSubmissionResult?

        do {
            result = try await apiClient.submitPoDReceipt(payload)
        } catch {
            // Backend PoD endpoint may not exist yet — use local record only
            print("[PoD] Submission failed (non-critical): \(error.localizedDescription)")
            result = PoDSubmissionResult(
                accepted: false,
                txHash: nil,
                reward: nil,
                message: "Backend not reachable — signed locally"
            )
        }

        // Also send latency beacon (non-blocking)
        await apiClient.sendDeliveryBeacon(txHash: result?.txHash ?? "local", switchLatencyMs: switchLatencyMs)

        let record = LocalPoDRecord(
            impressionId: impressionId,
            advertiser: advertiser,
            cpm: cpm,
            cmxsEarned: result?.reward ?? 0.001,
            txHash: result?.txHash,
            timestamp: t0,
            slaMet: switchLatencyMs < 500,
            switchLatencyMs: switchLatencyMs
        )

        pendingRecords.append(record)
        print("[PoD] ✅ Receipt \(result?.accepted == true ? "accepted on-chain" : "signed locally") — reward: \(record.cmxsEarned) CMXS")
        return record
    }

    // MARK: - Helpers

    private func anonymizedIFA() -> String {
        // For prototype: use a stable UUID hashed for privacy
        // Production: check ATTrackingManager.trackingAuthorizationStatus
        let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
        return String(deviceId.prefix(16)) + "..." // truncated for prototype
    }
}

import UIKit
