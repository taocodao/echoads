// PostGameRetentionView.swift — Arenza
// Phase 3: Post-Game Retention Loop
//
// Shown automatically (or via notification deep-link) within 2h of game end.
// Displays:
//   - Session summary (AZT earned, spins played, rewards won)
//   - Streak status + next milestone
//   - Active rewards with countdown (extended +30 min by TemporalRetentionService)
//   - "Bring a friend" share CTA for bonus AZT
//   - Weekly recap stats

import SwiftUI

struct PostGameRetentionView: View {
    @ObservedObject private var wallet    = QRWalletService.shared
    @ObservedObject private var temporal  = TemporalRetentionService.shared
    @ObservedObject private var prediction = PredictionEngine.shared
    @Environment(\.dismiss) private var dismiss

    // Session stats passed in from the game session
    let sessionAZTEarned: Int
    let sessionSpinsPlayed: Int
    let sessionRewardsWon: Int
    let sessionDurationMinutes: Int

    var body: some View {
        NavigationView {
            ZStack {
                Color(arenza: "#0a0c12").ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        sessionSummaryCard
                        streakCard
                        if !wallet.activeRewards.isEmpty { activeRewardsCard }
                        weeklyRecapCard
                        shareCTACard
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 20)
                }
            }
            .navigationTitle("Game Recap")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(Color(arenza: "#00c9b1"))
                }
            }
            .toolbarBackground(Color(arenza: "#0a0c12"), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Session Summary

    private var sessionSummaryCard: some View {
        VStack(spacing: 16) {
            Text("Tonight's Session")
                .font(.system(size: 11, weight: .black))
                .foregroundColor(.white.opacity(0.4))
                .tracking(1.2)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 0) {
                statColumn(value: "\(sessionAZTEarned)", label: "AZT Earned", color: "#ffc107")
                divider
                statColumn(value: "\(sessionSpinsPlayed)", label: "Spins Played", color: "#00c9b1")
                divider
                statColumn(value: "\(sessionRewardsWon)", label: "Rewards Won", color: "#ff6b35")
                divider
                statColumn(value: "\(sessionDurationMinutes)m", label: "Watch Time", color: "#8892b0")
            }
            .padding(.vertical, 16)
            .background(Color.white.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }

    private var divider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.08))
            .frame(width: 1, height: 40)
    }

    private func statColumn(value: String, label: String, color: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 22, weight: .black, design: .monospaced))
                .foregroundColor(Color(arenza: color))
            Text(label)
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(.white.opacity(0.4))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Streak Card

    private var streakCard: some View {
        HStack(spacing: 14) {
            Text("🔥")
                .font(.system(size: 32))

            VStack(alignment: .leading, spacing: 4) {
                Text("\(temporal.spinStreak)-Day Streak!")
                    .font(.system(size: 16, weight: .black))
                    .foregroundColor(.white)
                Text(streakMessage)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.5))
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(String(format: "%.1f", temporal.streakMultiplier))×")
                    .font(.system(size: 20, weight: .black, design: .monospaced))
                    .foregroundColor(Color(arenza: "#ff6b35"))
                Text("multiplier")
                    .font(.system(size: 9))
                    .foregroundColor(.white.opacity(0.4))
            }
        }
        .padding(16)
        .background(
            LinearGradient(
                colors: [Color(arenza: "#ff6b35").opacity(0.12), Color.clear],
                startPoint: .leading, endPoint: .trailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(arenza: "#ff6b35").opacity(0.2), lineWidth: 1))
    }

    private var streakMessage: String {
        switch temporal.spinStreak {
        case 1:       return "Great start! Come back tomorrow to build your streak."
        case 2:       return "2 days in a row! One more for a 1.5× bonus."
        case 3..<7:   return "1.5× multiplier active! Keep going for 2.0× at 7 days."
        case 7..<14:  return "2.0× multiplier! You're crushing it — 3.0× at 14 days."
        default:      return "3.0× multiplier maxed out! You're a legend."
        }
    }

    // MARK: - Active Rewards

    private var activeRewardsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Active Rewards")
                    .font(.system(size: 11, weight: .black))
                    .foregroundColor(.white.opacity(0.4))
                    .tracking(1.2)
                Spacer()
                Text("Extended +30 min")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(Color(arenza: "#00c9b1"))
                    .padding(.horizontal, 7).padding(.vertical, 3)
                    .background(Color(arenza: "#00c9b1").opacity(0.1))
                    .clipShape(Capsule())
            }

            ForEach(wallet.activeRewards.prefix(3)) { reward in
                HStack(spacing: 12) {
                    Text(reward.sponsorEmoji)
                        .font(.system(size: 20))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(reward.rewardLabel)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                        Text("at \(reward.sponsorName)")
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    Spacer()
                    // Countdown
                    Text(formatCountdown(reward.timeRemaining))
                        .font(.system(size: 11, weight: .black, design: .monospaced))
                        .foregroundColor(reward.timeRemaining < 120 ? Color(arenza: "#ef4444") : Color(arenza: "#ffc107"))
                }
                .padding(12)
                .background(Color.white.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
    }

    // MARK: - Weekly Recap

    private var weeklyRecapCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your Week")
                .font(.system(size: 11, weight: .black))
                .foregroundColor(.white.opacity(0.4))
                .tracking(1.2)

            HStack(spacing: 0) {
                statColumn(value: "\(prediction.wallet.aztBalance)", label: "AZT Balance", color: "#ffc107")
                divider
                statColumn(value: "\(prediction.wallet.totalEarned)", label: "Total Earned", color: "#00c9b1")
                divider
                statColumn(value: "\(wallet.memberCards.count)", label: "Memberships", color: "#ff6b35")
            }
            .padding(.vertical, 12)
            .background(Color.white.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }

    // MARK: - Share CTA

    private var shareCTACard: some View {
        VStack(spacing: 12) {
            Text("Bring a Friend, Earn More")
                .font(.system(size: 15, weight: .black))
                .foregroundColor(.white)
            Text("Share Arenza with a friend and earn +100 AZT when they play their first spin.")
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.5))
                .multilineTextAlignment(.center)

            Button {
                let text = "I'm earning rewards watching sports with Arenza! Join me: https://arenza.app"
                let av = UIActivityViewController(activityItems: [text], applicationActivities: nil)
                if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let root = scene.windows.first?.rootViewController {
                    root.present(av, animated: true)
                }
            } label: {
                Label("Share & Earn +100 AZT", systemImage: "square.and.arrow.up")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            colors: [Color(arenza: "#ff6b35"), Color(arenza: "#ffc107")],
                            startPoint: .leading, endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(Color.white.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(arenza: "#ff6b35").opacity(0.2), lineWidth: 1))
    }

    // MARK: - Helpers

    private func formatCountdown(_ t: TimeInterval) -> String {
        let m = Int(t) / 60, s = Int(t) % 60
        return String(format: "%d:%02d", m, s)
    }
}

// MARK: - Operator Analytics View

struct OperatorAnalyticsView: View {
    @ObservedObject private var wallet = QRWalletService.shared

    var body: some View {
        NavigationView {
            ZStack {
                Color(arenza: "#0a0c12").ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {
                        sectionHeader("Redemption Stats")

                        HStack(spacing: 0) {
                            analyticsColumn("\(wallet.rewards.filter { $0.status == .claimed }.count)", "Claimed", "#00c9b1")
                            analyticsColumn("\(wallet.rewards.filter { $0.status == .active }.count)", "Active", "#ffc107")
                            analyticsColumn("\(wallet.rewards.filter { $0.status == .expired }.count)", "Expired", "#4a5568")
                        }
                        .padding(.vertical, 16)
                        .background(Color.white.opacity(0.04))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .padding(.horizontal, 16)

                        sectionHeader("Member Tiers")

                        VStack(spacing: 8) {
                            ForEach([("VIP", "💎", "#00c9b1"), ("Gold", "🥇", "#ffd700"),
                                     ("Silver", "🥈", "#a8a9ad"), ("Bronze", "🥉", "#cd7f32")], id: \.0) { tier in
                                let count = wallet.memberCards.filter { $0.tierLabel == tier.0 }.count
                                tierRow(emoji: tier.1, tier: tier.0, count: count, color: tier.2,
                                        total: wallet.memberCards.count)
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle("Analytics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color(arenza: "#0a0c12"), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .preferredColorScheme(.dark)
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.system(size: 9, weight: .black))
            .foregroundColor(.white.opacity(0.35))
            .tracking(1.5)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
    }

    private func analyticsColumn(_ value: String, _ label: String, _ color: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 28, weight: .black, design: .monospaced))
                .foregroundColor(Color(arenza: color))
            Text(label)
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(.white.opacity(0.4))
        }
        .frame(maxWidth: .infinity)
    }

    private func tierRow(emoji: String, tier: String, count: Int, color: String, total: Int) -> some View {
        let pct = total > 0 ? Double(count) / Double(total) : 0
        return HStack(spacing: 10) {
            Text(emoji).font(.system(size: 16))
            Text(tier)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(Color(arenza: color))
                .frame(width: 55, alignment: .leading)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4).fill(Color.white.opacity(0.06)).frame(height: 8)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(arenza: color).opacity(0.7))
                        .frame(width: geo.size.width * pct, height: 8)
                }
            }
            .frame(height: 8)
            Text("\(count)")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(.white.opacity(0.6))
                .frame(width: 24)
        }
        .padding(12)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
