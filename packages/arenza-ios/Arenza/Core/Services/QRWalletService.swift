// QRWalletService.swift — Arenza (TableSpin Integration)
// Singleton that manages the in-memory wallet of member cards and rewards.
// In production, persists to SwiftData / CloudKit.

import Foundation
import Combine
import SwiftUI

@MainActor
final class QRWalletService: ObservableObject {

    static let shared = QRWalletService()

    @Published var rewards: [SpinReward] = []
    @Published var memberCards: [MemberCard] = []

    private var expiryTimer: Timer?

    private init() {
        // Seed demo member cards for all sponsor businesses
        memberCards = SponsorBusiness.all.map { MemberCard.demo(for: $0) }

        // Add demo rewards
        seedDemoRewards()

        startExpiryMonitor()
    }

    // MARK: - Rewards

    func addReward(_ reward: SpinReward) {
        rewards.insert(reward, at: 0)
        if rewards.count > 50 { rewards = Array(rewards.prefix(50)) }
    }

    func claimReward(id: UUID) {
        guard let idx = rewards.firstIndex(where: { $0.id == id }) else { return }
        rewards[idx].status = .claimed
        rewards[idx].claimedAt = Date()
    }

    var activeRewards: [SpinReward] {
        rewards.filter { $0.status == .active && !$0.isExpired }
    }

    var allRewards: [SpinReward] {
        rewards
    }

    // MARK: - Member Cards

    func memberCard(for sponsorId: String) -> MemberCard? {
        memberCards.first { $0.sponsorId == sponsorId }
    }

    func updatePoints(sponsorId: String, delta: Int) {
        guard let idx = memberCards.firstIndex(where: { $0.sponsorId == sponsorId }) else { return }
        let old = memberCards[idx]
        let newPoints = old.totalPoints + delta
        let (tier, emoji, color) = memberTier(for: newPoints)
        let didTierUp = tier != old.tierLabel

        memberCards[idx] = MemberCard(
            id: old.id, memberId: old.memberId,
            sponsorId: old.sponsorId, sponsorName: old.sponsorName,
            sponsorEmoji: old.sponsorEmoji, sponsorBrandColor: old.sponsorBrandColor,
            sponsorWebsiteURL: old.sponsorWebsiteURL,
            tierLabel: tier, tierEmoji: emoji, tierColor: color,
            totalPoints: newPoints,
            totalSpend: old.totalSpend,
            memberSince: old.memberSince
        )

        // Fire tier-up notification
        if didTierUp && delta > 0 {
            NotificationService.shared.scheduleTierAdvancementAlert(
                sponsorName: old.sponsorName,
                newTier: tier
            )
        }
    }

    // MARK: - Tier Progression (Bronze -> Silver -> Gold -> VIP)

    private func memberTier(for points: Int) -> (label: String, emoji: String, color: String) {
        switch points {
        case 0..<100:   return ("Bronze",  "🥉", "#cd7f32")
        case 100..<300: return ("Silver",  "🥈", "#a8a9ad")
        case 300..<600: return ("Gold",    "🥇", "#ffd700")
        default:        return ("VIP",     "💎", "#00c9b1")
        }
    }

    // MARK: - Expiry Monitor

    private func startExpiryMonitor() {
        expiryTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.markExpiredRewards()
            }
        }
    }

    private func markExpiredRewards() {
        for i in rewards.indices {
            if rewards[i].status == .active && rewards[i].isExpired {
                rewards[i].status = .expired
            }
        }
    }

    // MARK: - Demo Data

    private func seedDemoRewards() {
        let pastReward = SpinReward(
            id: UUID(),
            rewardCode: "SAKR-XK9A12",
            sponsorId: "sakura-bites",
            sponsorName: "Sakura Bites",
            sponsorEmoji: "🌸",
            sponsorBrandColor: "#c9924e",
            sponsorWebsiteURL: "https://sakurabites.com",
            rewardType: .percentOff,
            rewardLabel: "10% OFF at Sakura Bites",
            rewardValue: "10%",
            status: .claimed,
            createdAt: Date().addingTimeInterval(-86400),
            expiresAt: Date().addingTimeInterval(-83100),
            claimedAt: Date().addingTimeInterval(-84000)
        )
        rewards.append(pastReward)
    }
}
