// QRWalletView.swift — Arenza
// 4-tab wallet matching web demo WalletTab exactly:
//   📲 My QR   →  MembershipQRView (scannable QR + stamps + coupons)
//   🎟 Redeem  →  points redemption catalog
//   🏷 Coupons →  ad-claimed coupons
//   🪪 Cards   →  sponsor loyalty cards

import SwiftUI

struct QRWalletView: View {
    @StateObject private var wallet  = QRWalletService.shared
    @StateObject private var svc     = MembershipService.shared
    @State private var activeTab: WalletSection = .qr
    @State private var selectedCard: MemberCard? = nil
    @State private var selectedReward: SpinReward? = nil

    enum WalletSection: String, CaseIterable {
        case qr      = "📲 My QR"
        case redeem  = "🎟 Redeem"
        case coupons = "🏷 Coupons"
        case cards   = "🪪 Cards"
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color(arenza: "#0d0f14").ignoresSafeArea()
                VStack(spacing: 0) {
                    pointsBanner
                    tabBar
                    Divider().background(Color.white.opacity(0.08))
                    ScrollView {
                        VStack(spacing: 14) {
                            switch activeTab {
                            case .qr:      MembershipQRView().padding(.top, 4)
                            case .redeem:  redeemSection
                            case .coupons: couponsSection
                            case .cards:   cardsSection
                            }
                        }
                        .padding(14)
                        .padding(.bottom, 24)
                    }
                }
            }
            .navigationTitle("💳 Wallet & Points")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color(arenza: "#0d0f14"), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .sheet(item: $selectedCard)   { MemberCardFullScreen(card: $0) }
        .sheet(item: $selectedReward) { reward in
            RewardDetailSheet(reward: reward, onClaim: {
                wallet.claimReward(id: reward.id)
                selectedReward = nil
            })
        }
    }

    // MARK: - Points Banner (matches web "Arenza Points" card)

    private var pointsBanner: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("ARENZA POINTS")
                    .font(.system(size: 9, weight: .black))
                    .foregroundColor(Color(arenza: "#8892b0"))
                    .tracking(1.2)
                Text("\(svc.totalPointsAcrossAllBusinesses)")
                    .font(.system(size: 34, weight: .black, design: .monospaced))
                    .foregroundColor(Color(arenza: "#ffc107"))
                Text("Redeemable at \(wallet.memberCards.count) sponsor locations")
                    .font(.system(size: 9))
                    .foregroundColor(Color(arenza: "#8892b0"))
            }
            Spacer()
            Text("🏆")
                .font(.system(size: 32))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            LinearGradient(
                colors: [Color(arenza: "#ff6b35").opacity(0.13), Color(arenza: "#7c3aed").opacity(0.13)],
                startPoint: .leading, endPoint: .trailing
            )
        )
        .overlay(Rectangle().frame(height: 1).foregroundColor(.white.opacity(0.08)), alignment: .bottom)
    }

    // MARK: - Tab Bar (matches web 4-button section toggle)

    private var tabBar: some View {
        HStack(spacing: 4) {
            ForEach(WalletSection.allCases, id: \.self) { section in
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) { activeTab = section }
                } label: {
                    Text(section.rawValue)
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(activeTab == section ? Color(arenza: "#ff6b35") : Color(arenza: "#8892b0"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(activeTab == section ? Color(arenza: "#ff6b35").opacity(0.12) : Color.clear)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(activeTab == section ? Color(arenza: "#ff6b35") : Color(arenza: "#ffffff14"), lineWidth: 1)
                                )
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(arenza: "#0d0f14"))
    }

    // MARK: - Redeem Section

    private var redeemSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("Redemption Catalog")
            ForEach(wallet.activeRewards) { reward in
                RewardRowView(reward: reward)
                    .onTapGesture { selectedReward = reward }
            }
            if wallet.activeRewards.isEmpty {
                emptyState(emoji: "🎰", title: "No active rewards", subtitle: "Watch a game and play games to earn rewards")
            }
        }
    }

    // MARK: - Coupons Section

    private var couponsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("Claimed Coupons")
            let all = svc.allActiveCoupons
            if all.isEmpty {
                emptyState(emoji: "🎟", title: "No coupons claimed yet", subtitle: "Claim deals from ad cards to see them here")
            } else {
                ForEach(all) { coupon in
                    couponRow(coupon)
                }
            }
        }
    }

    private func couponRow(_ coupon: MemberCoupon) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(coupon.offer)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white)
            Text(coupon.value)
                .font(.system(size: 10))
                .foregroundColor(Color(arenza: "#8892b0"))
            Text("📲 Show QR at counter — staff scans to redeem")
                .font(.system(size: 8))
                .foregroundColor(Color(arenza: "#4a5568"))
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(arenza: "#141720"))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(arenza: "#22c55e").opacity(0.3), lineWidth: 1))
    }

    // MARK: - Cards Section

    private var cardsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("\(wallet.memberCards.count) Sponsor Cards")
            if wallet.memberCards.isEmpty {
                emptyState(emoji: "🪪", title: "No loyalty cards yet", subtitle: "Join business clubs to earn stamps and perks")
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 14) {
                        ForEach(wallet.memberCards) { card in
                            MemberCardTile(card: card)
                                .onTapGesture { selectedCard = card }
                        }
                    }
                }
            }

            // History
            if wallet.rewards.contains(where: { $0.status != .active }) {
                sectionHeader("History")
                ForEach(wallet.rewards.filter { $0.status != .active }) { reward in
                    RewardRowView(reward: reward).opacity(0.6)
                }
            }
        }
    }

    // MARK: - Helpers

    private func sectionHeader(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.system(size: 9, weight: .black))
            .foregroundColor(Color(arenza: "#8892b0"))
            .tracking(1.2)
    }

    private func emptyState(emoji: String, title: String, subtitle: String) -> some View {
        VStack(spacing: 10) {
            Text(emoji).font(.system(size: 32))
            Text(title)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(Color(arenza: "#8892b0"))
            Text(subtitle)
                .font(.system(size: 10))
                .foregroundColor(Color(arenza: "#4a5568"))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .background(Color(arenza: "#141720"))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
