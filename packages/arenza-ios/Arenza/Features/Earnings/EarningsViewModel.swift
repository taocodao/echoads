// EarningsViewModel.swift — Arenza Prototype

import Foundation
import Combine

@MainActor
final class EarningsViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var totalCMXS: Double = 0
    @Published var records: [LocalPoDRecord] = []
    @Published var walletAddress: String = ""
    @Published var shortWalletAddress: String = ""
    @Published var isHardwareSigned: Bool = false
    @Published var auctionStats: AuctionStatsResponse?

    private let env: AppEnvironment

    init(env: AppEnvironment) {
        self.env = env
    }

    func load() async {
        walletAddress = env.walletAddress
        shortWalletAddress = WalletDerivation.shortAddress(env.walletAddress)
        isHardwareSigned = env.seManager.isUsingSecureEnclave
        totalCMXS = env.totalCMXSEarned
        records = env.allPoDRecords

        // Fetch auction stats from backend (non-critical)
        if let stats = try? await env.apiClient.fetchAuctionStats() {
            auctionStats = stats
        }
    }
}
