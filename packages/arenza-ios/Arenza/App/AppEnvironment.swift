// AppEnvironment.swift — Arenza Prototype
// Dependency injection container — single instances shared across the app.

import Foundation
import SwiftUI

@MainActor
final class AppEnvironment: ObservableObject {

    // Core services
    let apiClient = CMXSAPIClient()
    let seManager = SecureEnclaveManager.shared
    let podSubmitter: PoDSubmitter

    // Derived wallet info
    @Published var walletAddress: String = "Initializing..."
    @Published var isBackendReachable: Bool = false
    @Published var allPoDRecords: [LocalPoDRecord] = []

    // Session state
    @Published var totalCMXSEarned: Double = 0.0

    static let shared = AppEnvironment()

    private init() {
        self.podSubmitter = PoDSubmitter(apiClient: apiClient)
        Task { await self.initialize() }
    }

    private func initialize() async {
        // Derive wallet address from SE key
        walletAddress = WalletDerivation.currentWalletAddress()

        // Check backend health
        isBackendReachable = (try? await apiClient.checkHealth()) ?? false

        print("[AppEnvironment] Wallet: \(walletAddress)")
        print("[AppEnvironment] Backend reachable: \(isBackendReachable)")
        print("[AppEnvironment] Secure Enclave: \(seManager.isUsingSecureEnclave ? "✅ Hardware" : "⚠️ Software (Simulator)")")
    }

    func recordPoD(_ record: LocalPoDRecord) {
        allPoDRecords.insert(record, at: 0)
        totalCMXSEarned += record.cmxsEarned
    }
}
