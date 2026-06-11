// SponsorBusinessCards.swift — Arenza
// Marketplace cards for gamified sponsor businesses.
// Allows users to search businesses and redeem AZT points earned from
// spin/scratch games and business shares.

import SwiftUI

// MARK: - Sponsor Business Marketplace Card

struct SponsorBusinessMarketplaceCard: View {
    let business: SponsorBusiness
    let userBalance: Int

    @ObservedObject private var walletService = QRWalletService.shared
    @State private var showRedeemSheet = false

    private var redeemCost: Int { 200 }
    private var canAfford: Bool { userBalance >= redeemCost }
    private var memberCard: MemberCard? { walletService.memberCard(for: business.id) }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Top: brand + address + tier badge
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(arenza: business.brandColor).opacity(0.15))
                        .frame(width: 52, height: 52)
                    Text(business.emoji)
                        .font(.system(size: 26))
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(business.name)
                        .font(.system(size: 15, weight: .black))
                        .foregroundColor(.white)
                    Text(business.tagline)
                        .font(.system(size: 11))
                        .foregroundColor(Color(arenza: business.brandColor))
                    HStack(spacing: 4) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.system(size: 9))
                            .foregroundColor(.white.opacity(0.35))
                        Text(business.address.components(separatedBy: ",").first ?? business.address)
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.35))
                            .lineLimit(1)
                    }
                }

                Spacer()

                // Member tier badge (if user has a card for this sponsor)
                if let card = memberCard {
                    VStack(spacing: 2) {
                        Text(card.tierEmoji).font(.system(size: 16))
                        Text(card.tierLabel)
                            .font(.system(size: 8, weight: .black))
                            .foregroundColor(Color(arenza: business.brandColor))
                        Text("\(card.totalPoints) pts")
                            .font(.system(size: 8, design: .monospaced))
                            .foregroundColor(.white.opacity(0.4))
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, 14)
            .padding(.bottom, 10)

            // Divider
            Rectangle()
                .fill(Color.white.opacity(0.05))
                .frame(height: 1)
                .padding(.horizontal, 14)

            // Bottom: redeem CTA
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Redeem Points for Rewards")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                    Text("Spin wins + shares = AZT you can spend here")
                        .font(.system(size: 9))
                        .foregroundColor(.white.opacity(0.4))
                }
                Spacer()
                Button { showRedeemSheet = true } label: {
                    VStack(spacing: 1) {
                        Text("\(redeemCost)")
                            .font(.system(size: 13, weight: .black, design: .rounded))
                            .foregroundColor(canAfford ? Color(arenza: business.brandColor) : .white.opacity(0.25))
                        Text("AZT")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(canAfford ? Color(arenza: business.brandColor).opacity(0.7) : .white.opacity(0.15))
                    }
                    .padding(.horizontal, 14).padding(.vertical, 8)
                    .background(canAfford ? Color(arenza: business.brandColor).opacity(0.15) : Color.white.opacity(0.04))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(canAfford ? Color(arenza: business.brandColor).opacity(0.4) : Color.white.opacity(0.06), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .disabled(!canAfford)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
        }
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(arenza: business.brandColor).opacity(canAfford ? 0.2 : 0.06), lineWidth: 1)
        )
        .padding(.horizontal, 16)
        .sheet(isPresented: $showRedeemSheet) {
            SponsorRedeemSheet(business: business, redeemCost: redeemCost)
        }
    }
}

// MARK: - Sponsor Redeem Sheet

struct SponsorRedeemSheet: View {
    let business: SponsorBusiness
    let redeemCost: Int
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var engine = PredictionEngine.shared
    @State private var redeemed = false

    private var canAfford: Bool { engine.wallet.aztBalance >= redeemCost }

    var body: some View {
        NavigationView {
            ZStack {
                Color(arenza: "#0a0c12").ignoresSafeArea()
                VStack(spacing: 24) {
                    // Business branding
                    VStack(spacing: 8) {
                        Text(business.emoji).font(.system(size: 48))
                        Text(business.name)
                            .font(.system(size: 22, weight: .black)).foregroundColor(.white)
                        Text(business.tagline)
                            .font(.system(size: 13)).foregroundColor(Color(arenza: business.brandColor))
                    }
                    .padding(.top, 8)

                    if redeemed {
                        // Success state
                        VStack(spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 52)).foregroundColor(Color(arenza: "#00c9b1"))
                            Text("Reward Redeemed!")
                                .font(.system(size: 20, weight: .black)).foregroundColor(.white)
                            Text("Show your QR Wallet at \(business.name) to claim your reward.")
                                .font(.system(size: 13)).foregroundColor(.white.opacity(0.6))
                                .multilineTextAlignment(.center).padding(.horizontal, 24)
                        }
                    } else {
                        // Redeem form
                        VStack(spacing: 14) {
                            // Cost display
                            VStack(spacing: 6) {
                                Text("Spend \(redeemCost) AZT")
                                    .font(.system(size: 18, weight: .black))
                                    .foregroundColor(Color(arenza: business.brandColor))
                                Text("Your balance: \(engine.wallet.aztBalance) AZT")
                                    .font(.system(size: 12)).foregroundColor(.white.opacity(0.5))
                            }
                            .padding(16).frame(maxWidth: .infinity)
                            .background(Color(arenza: business.brandColor).opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .padding(.horizontal, 20)

                            Text("Redeem for a reward coupon at \(business.name).\nShow your QR Wallet when you visit.")
                                .font(.system(size: 12)).foregroundColor(.white.opacity(0.5))
                                .multilineTextAlignment(.center).padding(.horizontal, 24)

                            // Redeem button
                            Button {
                                let ok = engine.wallet.spend(redeemCost, source: .redemption, sponsorId: business.id)
                                if ok { engine.saveWallet(); withAnimation { redeemed = true } }
                            } label: {
                                Text(canAfford ? "Redeem \(redeemCost) AZT" : "Not Enough AZT")
                                    .font(.system(size: 15, weight: .black)).foregroundColor(.white)
                                    .frame(maxWidth: .infinity).padding(.vertical, 14)
                                    .background(canAfford ? Color(arenza: business.brandColor) : Color(arenza: "#2a2a3a"))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            .buttonStyle(.plain).disabled(!canAfford)
                            .padding(.horizontal, 20)

                            // How to earn more
                            if !canAfford {
                                VStack(spacing: 4) {
                                    Text("How to earn more AZT:")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(.white.opacity(0.5))
                                    Text("🎰 Spin & win rewards (+100-200 AZT)")
                                        .font(.system(size: 11)).foregroundColor(.white.opacity(0.35))
                                    Text("📤 Share a sponsor business (+50 AZT)")
                                        .font(.system(size: 11)).foregroundColor(.white.opacity(0.35))
                                    Text("🎯 Answer predictions correctly (+pts)")
                                        .font(.system(size: 11)).foregroundColor(.white.opacity(0.35))
                                }
                                .padding(14)
                                .background(Color.white.opacity(0.03))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .padding(.horizontal, 20)
                            }
                        }
                    }
                    Spacer()
                }
            }
            .navigationTitle("Redeem at \(business.name)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) { Button("Done") { dismiss() } }
            }
        }
        .preferredColorScheme(.dark)
    }
}
