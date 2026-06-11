// QRWalletView.swift — Arenza (TableSpin Integration Phase 4)
// Full tab showing: member cards (per sponsor) + active/claimed rewards with QR codes.

import SwiftUI

struct QRWalletView: View {
    @StateObject private var wallet = QRWalletService.shared
    @State private var selectedCard: MemberCard? = nil
    @State private var selectedReward: SpinReward? = nil

    var body: some View {
        NavigationView {
            ZStack {
                Color(arenza: "#0a0c12").ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Section 1: Member Cards
                        memberCardsSection

                        // Section 2: Active Rewards
                        activeRewardsSection

                        // Section 3: Reward History
                        if wallet.rewards.contains(where: { $0.status != .active }) {
                            rewardHistorySection
                        }
                    }
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle("QR Wallet")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color(arenza: "#0a0c12"), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .preferredColorScheme(.dark)
        }
        .sheet(item: $selectedCard) { card in
            MemberCardFullScreen(card: card)
        }
        .sheet(item: $selectedReward) { reward in
            RewardDetailSheet(reward: reward, onClaim: {
                wallet.claimReward(id: reward.id)
                selectedReward = nil
            })
        }
    }

    // MARK: - Member Cards Section

    private var memberCardsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(title: "🪪 Membership Cards", subtitle: "\(wallet.memberCards.count) sponsors")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(wallet.memberCards) { card in
                        MemberCardTile(card: card)
                            .onTapGesture { selectedCard = card }
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }

    // MARK: - Active Rewards

    private var activeRewardsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(
                title: "🎁 Active Rewards",
                subtitle: wallet.activeRewards.isEmpty ? "Play games to win rewards" : "\(wallet.activeRewards.count) available"
            )

            if wallet.activeRewards.isEmpty {
                emptyRewardsPlaceholder
            } else {
                VStack(spacing: 8) {
                    ForEach(wallet.activeRewards) { reward in
                        RewardRowView(reward: reward)
                            .onTapGesture { selectedReward = reward }
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }

    // MARK: - History

    private var rewardHistorySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(title: "📋 History", subtitle: "Past rewards")

            VStack(spacing: 6) {
                ForEach(wallet.rewards.filter { $0.status != .active }) { reward in
                    RewardRowView(reward: reward)
                        .opacity(0.6)
                }
            }
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Helpers

    private func sectionHeader(title: String, subtitle: String) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .black))
                    .foregroundColor(.white)
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundColor(Color(arenza: "#8892b0"))
            }
            Spacer()
        }
        .padding(.horizontal, 16)
    }

    private var emptyRewardsPlaceholder: some View {
        VStack(spacing: 10) {
            Text("🎰")
                .font(.system(size: 36))
            Text("No active rewards")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(Color(arenza: "#8892b0"))
            Text("Watch a game and play Spin or Scratch\nto earn sponsor rewards")
                .font(.system(size: 11))
                .foregroundColor(Color(arenza: "#4a5568"))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .background(Color(arenza: "#141720"))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal, 16)
    }
}

// MARK: - Member Card Tile (credit-card style)

struct MemberCardTile: View {
    let card: MemberCard

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Card face
            ZStack(alignment: .topLeading) {
                // Background gradient
                RoundedRectangle(cornerRadius: 14)
                    .fill(LinearGradient(
                        colors: [
                            Color(arenza: card.sponsorBrandColor).opacity(0.85),
                            Color(arenza: card.sponsorBrandColor).opacity(0.4),
                            Color.black.opacity(0.7)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))

                // Subtle pattern
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color(arenza: card.sponsorBrandColor).opacity(0.3), lineWidth: 1)

                VStack(alignment: .leading) {
                    // Top: Logo + Tier
                    HStack {
                        Text(card.sponsorEmoji)
                            .font(.system(size: 22))
                        Spacer()
                        // Tier badge
                        HStack(spacing: 3) {
                            Text(card.tierEmoji)
                                .font(.system(size: 9))
                            Text(card.tierLabel)
                                .font(.system(size: 8, weight: .black))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 7).padding(.vertical, 3)
                        .background(Color(arenza: card.sponsorBrandColor).opacity(0.6))
                        .clipShape(Capsule())
                    }

                    Spacer()

                    // Middle: QR code (small)
                    HStack {
                        Spacer()
                        QRCodeView(
                            payload: card.qrPayload,
                            size: 56,
                            foreground: .black,
                            background: .white
                        )
                        Spacer()
                    }

                    Spacer()

                    // Bottom: name + points
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(card.sponsorName)
                                .font(.system(size: 11, weight: .black))
                                .foregroundColor(.white)
                            Text("MBR-\(String(card.memberId.suffix(8)))")
                                .font(.system(size: 8, design: .monospaced))
                                .foregroundColor(.white.opacity(0.5))
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("\(card.totalPoints)")
                                .font(.system(size: 14, weight: .black, design: .monospaced))
                                .foregroundColor(.white)
                            Text("AZT pts")
                                .font(.system(size: 8))
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                }
                .padding(14)
            }
            .frame(width: 180, height: 120)
            .shadow(color: Color(arenza: card.sponsorBrandColor).opacity(0.4), radius: 12, y: 6)
        }
    }
}

// MARK: - Reward Row

struct RewardRowView: View {
    let reward: SpinReward
    @State private var timeRemaining: TimeInterval = 0
    @State private var timer: Timer? = nil

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color(arenza: reward.sponsorBrandColor).opacity(0.15))
                    .frame(width: 42, height: 42)
                Text(reward.sponsorEmoji)
                    .font(.system(size: 20))
            }

            // Info
            VStack(alignment: .leading, spacing: 3) {
                Text(reward.rewardLabel)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Color(arenza: "#e0e8ff"))
                    .lineLimit(1)
                Text(reward.rewardCode)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(Color(arenza: "#8892b0"))
            }

            Spacer()

            // Status / countdown
            statusBadge
        }
        .padding(12)
        .background(Color(arenza: "#141720"))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    reward.status == .active
                        ? Color(arenza: reward.sponsorBrandColor).opacity(0.25)
                        : Color.white.opacity(0.05),
                    lineWidth: 1
                )
        )
        .onAppear {
            timeRemaining = reward.timeRemaining
            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                Task { @MainActor in timeRemaining = reward.timeRemaining }
            }
        }
        .onDisappear { timer?.invalidate() }
    }

    @ViewBuilder
    private var statusBadge: some View {
        switch reward.status {
        case .active:
            if reward.isExpired {
                Text("Expired")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(Color(arenza: "#ef4444"))
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(Color(arenza: "#ef4444").opacity(0.1))
                    .clipShape(Capsule())
            } else {
                VStack(spacing: 2) {
                    Image(systemName: "qrcode")
                        .font(.system(size: 14))
                        .foregroundColor(Color(arenza: reward.sponsorBrandColor))
                    Text(formatTime(timeRemaining))
                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                        .foregroundColor(timeRemaining < 60 ? Color(arenza: "#ef4444") : Color(arenza: "#8892b0"))
                }
            }
        case .claimed:
            HStack(spacing: 3) {
                Image(systemName: "checkmark.circle.fill")
                Text("Claimed")
            }
            .font(.system(size: 9, weight: .bold))
            .foregroundColor(Color(arenza: "#22c55e"))
            .padding(.horizontal, 8).padding(.vertical, 4)
            .background(Color(arenza: "#22c55e").opacity(0.1))
            .clipShape(Capsule())
        case .expired:
            Text("Expired")
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(Color(arenza: "#4a5568"))
                .padding(.horizontal, 8).padding(.vertical, 4)
                .background(Color.white.opacity(0.04))
                .clipShape(Capsule())
        }
    }

    private func formatTime(_ t: TimeInterval) -> String {
        let m = Int(t) / 60; let s = Int(t) % 60
        return String(format: "%d:%02d", m, s)
    }
}

// MARK: - Member Card Full Screen

struct MemberCardFullScreen: View {
    let card: MemberCard
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                Color(arenza: "#0a0c12").ignoresSafeArea()
                VStack(spacing: 28) {
                    // Large card
                    ZStack(alignment: .topLeading) {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(LinearGradient(
                                colors: [
                                    Color(arenza: card.sponsorBrandColor),
                                    Color(arenza: card.sponsorBrandColor).opacity(0.5),
                                    Color.black.opacity(0.8)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))

                        VStack(alignment: .leading) {
                            HStack {
                                Text(card.sponsorEmoji).font(.system(size: 32))
                                Spacer()
                                HStack(spacing: 4) {
                                    Text(card.tierEmoji)
                                    Text(card.tierLabel)
                                        .font(.system(size: 12, weight: .black))
                                        .foregroundColor(.white)
                                }
                                .padding(.horizontal, 12).padding(.vertical, 6)
                                .background(Color(arenza: card.sponsorBrandColor).opacity(0.5))
                                .clipShape(Capsule())
                            }
                            Spacer()
                            HStack {
                                Spacer()
                                QRCodeView(payload: card.qrPayload, size: 180, foreground: .black, background: .white)
                                Spacer()
                            }
                            Spacer()
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(card.sponsorName)
                                        .font(.system(size: 18, weight: .black))
                                        .foregroundColor(.white)
                                    Text(card.memberId)
                                        .font(.system(size: 11, design: .monospaced))
                                        .foregroundColor(.white.opacity(0.5))
                                }
                                Spacer()
                                VStack(alignment: .trailing, spacing: 4) {
                                    Text("\(card.totalPoints)")
                                        .font(.system(size: 24, weight: .black, design: .monospaced))
                                        .foregroundColor(.white)
                                    Text("AZT Points")
                                        .font(.system(size: 10))
                                        .foregroundColor(.white.opacity(0.6))
                                }
                            }
                        }
                        .padding(22)
                    }
                    .frame(height: 280)
                    .padding(.horizontal, 24)
                    .shadow(color: Color(arenza: card.sponsorBrandColor).opacity(0.5), radius: 20, y: 10)

                    // Info
                    VStack(spacing: 14) {
                        infoRow(label: "Website", value: card.sponsorWebsiteURL, icon: "globe")
                        infoRow(label: "Member Since", value: card.memberSince.formatted(date: .abbreviated, time: .omitted), icon: "calendar")
                        infoRow(label: "Total Spend", value: "$\(String(format: "%.2f", card.totalSpend))", icon: "dollarsign.circle")
                        infoRow(label: "Tier", value: "\(card.tierEmoji) \(card.tierLabel)", icon: "star.fill")
                    }
                    .padding(.horizontal, 24)

                    Text("Show QR at \(card.sponsorName) to access your membership and rewards")
                        .font(.system(size: 11))
                        .foregroundColor(Color(arenza: "#8892b0"))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)

                    // Apple Wallet
                    AddToWalletButton {
                        await WalletPassGenerator.shared.addMemberCard(card)
                    }

                    Spacer()
                }
                .padding(.top, 20)
            }
            .navigationTitle(card.sponsorName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func infoRow(label: String, value: String, icon: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(Color(arenza: card.sponsorBrandColor))
                .frame(width: 24)
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(Color(arenza: "#8892b0"))
            Spacer()
            Text(value)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white)
        }
        .padding(12)
        .background(Color(arenza: "#141720"))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - Reward Detail Sheet

struct RewardDetailSheet: View {
    let reward: SpinReward
    let onClaim: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var timeRemaining: TimeInterval = 0
    @State private var countdownTimer: Timer? = nil

    var body: some View {
        NavigationView {
            ZStack {
                Color(arenza: "#0a0c12").ignoresSafeArea()

                VStack(spacing: 24) {
                    // QR Code
                    VStack(spacing: 12) {
                        QRCodeView(
                            payload: reward.qrPayload,
                            size: 200,
                            foreground: .black,
                            background: .white
                        )

                        Text(reward.rewardValue)
                            .font(.system(size: 28, weight: .black))
                            .foregroundColor(Color(arenza: reward.sponsorBrandColor))

                        Text(reward.rewardLabel)
                            .font(.system(size: 14))
                            .foregroundColor(Color(arenza: "#c0c8e0"))
                            .multilineTextAlignment(.center)

                        Text(reward.rewardCode)
                            .font(.system(size: 14, weight: .black, design: .monospaced))
                            .foregroundColor(Color(arenza: reward.sponsorBrandColor))
                            .padding(.horizontal, 16).padding(.vertical, 8)
                            .background(Color(arenza: reward.sponsorBrandColor).opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 8))

                        // Countdown
                        HStack(spacing: 4) {
                            Image(systemName: "clock.fill")
                                .font(.system(size: 11))
                            Text(timeRemaining > 0 ? "Expires in \(formatTime(timeRemaining))" : "Expired")
                                .font(.system(size: 11, weight: .bold))
                        }
                        .foregroundColor(
                            timeRemaining < 60
                                ? Color(arenza: "#ef4444")
                                : Color(arenza: "#8892b0")
                        )
                    }
                    .padding(24)
                    .background(Color(arenza: "#141720"))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color(arenza: reward.sponsorBrandColor).opacity(0.25), lineWidth: 1)
                    )
                    .padding(.horizontal, 24)

                    Text("Present this QR code at \(reward.sponsorName) to redeem your reward")
                        .font(.system(size: 12))
                        .foregroundColor(Color(arenza: "#8892b0"))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)

                    // Apple Wallet integration
                    AddToWalletButton {
                        await WalletPassGenerator.shared.addReward(reward)
                    }

                    Spacer()
                }
                .padding(.top, 24)
            }
            .navigationTitle("Redeem Reward")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            timeRemaining = reward.timeRemaining
            countdownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                Task { @MainActor in timeRemaining = reward.timeRemaining }
            }
        }
        .onDisappear { countdownTimer?.invalidate() }
    }

    private func formatTime(_ t: TimeInterval) -> String {
        let m = Int(t) / 60; let s = Int(t) % 60
        return String(format: "%d:%02d", m, s)
    }
}
