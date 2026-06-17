// QRWalletSubviews.swift — Arenza
// Supporting views used by QRWalletView:
//   • RewardRowView      — single row in the Redeem catalog
//   • RewardDetailSheet  — full-screen sheet for a SpinReward
//   • MemberCardTile     — horizontal scroll card in the Cards tab
//   • MemberCardFullScreen — full-screen detail for a MemberCard

import SwiftUI

// MARK: - RewardRowView

struct RewardRowView: View {
    let reward: SpinReward

    var body: some View {
        HStack(spacing: 12) {
            Text(reward.sponsorEmoji).font(.system(size: 28))

            VStack(alignment: .leading, spacing: 3) {
                Text(reward.rewardLabel)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                Text(reward.sponsorName)
                    .font(.system(size: 10))
                    .foregroundColor(Color(arenza: "#8892b0"))
                HStack(spacing: 4) {
                    statusBadge
                    if reward.status == .active {
                        Text("Expires \(reward.expiresAt, style: .relative)")
                            .font(.system(size: 8))
                            .foregroundColor(Color(arenza: "#4a5568"))
                    }
                }
            }

            Spacer()

            Text(reward.rewardValue)
                .font(.system(size: 14, weight: .black, design: .rounded))
                .foregroundColor(Color(arenza: reward.sponsorBrandColor))
        }
        .padding(12)
        .background(Color(arenza: "#141720"))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(arenza: reward.sponsorBrandColor).opacity(0.25), lineWidth: 1)
        )
    }

    private var statusBadge: some View {
        Text(reward.status == .claimed ? "CLAIMED" : reward.status == .expired ? "EXPIRED" : "ACTIVE")
            .font(.system(size: 7, weight: .black))
            .foregroundColor(reward.status == .active ? Color(arenza: "#22c55e") : Color(arenza: "#4a5568"))
            .padding(.horizontal, 5).padding(.vertical, 2)
            .background((reward.status == .active ? Color(arenza: "#22c55e") : Color(arenza: "#4a5568")).opacity(0.15))
            .clipShape(Capsule())
    }
}

// MARK: - RewardDetailSheet

struct RewardDetailSheet: View {
    let reward: SpinReward
    let onClaim: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color(arenza: "#0d0f14").ignoresSafeArea()
            VStack(spacing: 20) {

                // Header
                VStack(spacing: 8) {
                    Text(reward.sponsorEmoji).font(.system(size: 56))
                    Text(reward.rewardLabel)
                        .font(.system(size: 20, weight: .black))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    Text(reward.sponsorName)
                        .font(.system(size: 13))
                        .foregroundColor(Color(arenza: "#8892b0"))
                }
                .padding(.top, 32)

                // Big value
                Text(reward.rewardValue)
                    .font(.system(size: 52, weight: .black, design: .rounded))
                    .foregroundColor(Color(arenza: reward.sponsorBrandColor))

                // Code box
                VStack(spacing: 6) {
                    Text("REDEMPTION CODE")
                        .font(.system(size: 9, weight: .black))
                        .foregroundColor(Color(arenza: "#8892b0"))
                        .tracking(1.2)
                    Text(reward.rewardCode)
                        .font(.system(size: 18, weight: .black, design: .monospaced))
                        .foregroundColor(.white)
                        .padding(.horizontal, 24).padding(.vertical, 12)
                        .background(Color(arenza: "#1a1e2a"))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.1), lineWidth: 1))
                }

                Spacer()

                // Claim button
                if reward.status == .active {
                    Button(action: onClaim) {
                        Text("Mark as Claimed")
                            .font(.system(size: 15, weight: .black))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color(arenza: reward.sponsorBrandColor))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 20)
                }

                Button("Close") { dismiss() }
                    .font(.system(size: 12))
                    .foregroundColor(Color(arenza: "#4a5568"))
                    .padding(.bottom, 24)
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - MemberCardTile

struct MemberCardTile: View {
    let card: MemberCard

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(card.sponsorEmoji).font(.system(size: 22))
                Spacer()
                Text(card.tierEmoji).font(.system(size: 14))
            }
            Text(card.sponsorName)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.white)
                .lineLimit(1)
            Text(card.tierLabel)
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(Color(arenza: card.tierColor))
            Text("\(card.totalPoints) pts")
                .font(.system(size: 18, weight: .black, design: .monospaced))
                .foregroundColor(.white)
        }
        .padding(12)
        .frame(width: 130, alignment: .leading)
        .background(
            LinearGradient(
                colors: [Color(arenza: card.sponsorBrandColor).opacity(0.2), Color(arenza: "#141720")],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color(arenza: card.sponsorBrandColor).opacity(0.35), lineWidth: 1)
        )
    }
}

// MARK: - MemberCardFullScreen

struct MemberCardFullScreen: View {
    let card: MemberCard
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color(arenza: "#0d0f14").ignoresSafeArea()
            VStack(spacing: 20) {

                // Card hero
                VStack(spacing: 6) {
                    Text(card.sponsorEmoji).font(.system(size: 56))
                    Text(card.sponsorName)
                        .font(.system(size: 22, weight: .black))
                        .foregroundColor(.white)
                    HStack(spacing: 4) {
                        Text(card.tierEmoji)
                        Text(card.tierLabel + " Member")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Color(arenza: card.tierColor))
                    }
                }
                .padding(.top, 32)

                // Stats row
                HStack(spacing: 16) {
                    statCell(emoji: "🏆", value: "\(card.totalPoints)", label: "Points")
                    statCell(emoji: "📅", value: card.memberSince.formatted(.dateTime.month().year()), label: "Member Since")
                }
                .padding(.horizontal, 20)

                // Website link
                if let url = URL(string: card.sponsorWebsiteURL) {
                    Link("Visit \(card.sponsorName)", destination: url)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color(arenza: card.sponsorBrandColor))
                }

                Spacer()

                Button("Close") { dismiss() }
                    .font(.system(size: 12))
                    .foregroundColor(Color(arenza: "#4a5568"))
                    .padding(.bottom, 24)
            }
        }
        .preferredColorScheme(.dark)
    }

    private func statCell(emoji: String, value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(emoji).font(.system(size: 24))
            Text(value)
                .font(.system(size: 20, weight: .black, design: .monospaced))
                .foregroundColor(.white)
            Text(label)
                .font(.system(size: 9))
                .foregroundColor(Color(arenza: "#8892b0"))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color(arenza: "#141720"))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
