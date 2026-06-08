// RewardsWalletView.swift — Arenza (C5: Rewards & Leaderboard)
// New "Rewards" tab: points balance, tier status, coupon inventory, leaderboard.

import SwiftUI
import SafariServices

// MARK: - Rewards Wallet View (Tab)

struct RewardsWalletView: View {

    @ObservedObject private var engine = PredictionEngine.shared
    @State private var selectedTab: RewardsTab = .wallet
    @State private var couponToRedeem: SponsorCoupon?
    @State private var showRedeemConfirmation = false

    enum RewardsTab { case wallet, leaderboard }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Tab switcher
                Picker("", selection: $selectedTab) {
                    Text("My Wallet").tag(RewardsTab.wallet)
                    Text("Leaderboard").tag(RewardsTab.leaderboard)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

                if selectedTab == .wallet {
                    walletContent
                } else {
                    LeaderboardView()
                }
            }
            .navigationTitle("Rewards")
            .navigationBarTitleDisplayMode(.large)
            .background(Color(white: 0.05).ignoresSafeArea())
            .sheet(item: $couponToRedeem) { coupon in
                CouponRedemptionSheet(coupon: coupon)
            }
        }
    }

    // MARK: - Wallet Content

    private var walletContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                TierStatusCard(wallet: engine.wallet)
                PointsProgressCard(wallet: engine.wallet)
                couponSection
            }
            .padding(16)
        }
    }

    private var couponSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Available Rewards")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)

            if engine.wallet.availableCoupons.isEmpty {
                emptyCouponState
            } else {
                ForEach(engine.wallet.availableCoupons) { coupon in
                    CouponCard(coupon: coupon) {
                        couponToRedeem = coupon
                    }
                }
            }

            if !engine.wallet.redeemedCoupons.isEmpty {
                Text("Redeemed")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white.opacity(0.5))
                    .padding(.top, 8)
                ForEach(engine.wallet.redeemedCoupons) { coupon in
                    CouponCard(coupon: coupon, isRedeemed: true, onRedeem: {})
                        .opacity(0.5)
                }
            }
        }
    }

    private var emptyCouponState: some View {
        VStack(spacing: 12) {
            Image(systemName: "gift")
                .font(.system(size: 40))
                .foregroundColor(.white.opacity(0.2))
            Text("Keep predicting to earn rewards!")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.45))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(32)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Tier Status Card

struct TierStatusCard: View {
    let wallet: RewardsWallet

    private var tierGradient: [Color] {
        switch wallet.tier {
        case .bronze:   return [Color(hue: 0.06, saturation: 0.6, brightness: 0.7), Color(hue: 0.06, saturation: 0.4, brightness: 0.5)]
        case .silver:   return [Color(white: 0.75), Color(white: 0.5)]
        case .gold:     return [Color(hue: 0.12, saturation: 0.9, brightness: 0.9), Color(hue: 0.10, saturation: 0.7, brightness: 0.6)]
        case .platinum: return [Color(hue: 0.55, saturation: 0.6, brightness: 0.9), Color(hue: 0.75, saturation: 0.5, brightness: 0.7)]
        }
    }

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(colors: tierGradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .frame(height: 130)

            VStack(alignment: .leading, spacing: 6) {
                Text(wallet.tier.emoji + " " + wallet.tier.label + " Member")
                    .font(.system(size: 22, weight: .black))
                    .foregroundColor(.white)
                HStack(spacing: 20) {
                    statBadge(label: "Season", value: "\(wallet.seasonPoints) pts")
                    statBadge(label: "Streak", value: "🔥 \(wallet.currentStreak)")
                    statBadge(label: "Best", value: "\(wallet.bestStreak)")
                }
            }
            .padding(20)
        }
    }

    private func statBadge(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.white.opacity(0.7))
                .textCase(.uppercase)
                .tracking(0.8)
            Text(value)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.white)
        }
    }
}

// MARK: - Points Progress Card

struct PointsProgressCard: View {
    let wallet: RewardsWallet

    private var nextTier: RewardsTier? {
        RewardsTier.allCases.first { $0 > wallet.tier }
    }

    private var progressToNext: Double {
        guard let next = nextTier else { return 1.0 }
        let from = Double(wallet.tier.minPoints)
        let to   = Double(next.minPoints)
        let curr = Double(wallet.seasonPoints)
        return (curr - from) / (to - from)
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Total Points")
                        .font(.system(size: 12)).foregroundColor(.white.opacity(0.5))
                    Text("\(wallet.totalPoints)")
                        .font(.system(size: 32, weight: .black)).foregroundColor(.white)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("This Week")
                        .font(.system(size: 12)).foregroundColor(.white.opacity(0.5))
                    Text("+\(wallet.weeklyPoints)")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(Color(red: 0.0, green: 0.82, blue: 0.60))
                }
            }

            if let next = nextTier {
                VStack(spacing: 6) {
                    HStack {
                        Text("Progress to \(next.label)")
                            .font(.system(size: 12)).foregroundColor(.white.opacity(0.5))
                        Spacer()
                        Text("\(next.minPoints - wallet.seasonPoints) pts to go")
                            .font(.system(size: 12)).foregroundColor(.white.opacity(0.5))
                    }
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.white.opacity(0.1)).frame(height: 6)
                            Capsule()
                                .fill(LinearGradient(colors: [Color(red: 0.0, green: 0.82, blue: 0.60), .cyan],
                                                    startPoint: .leading, endPoint: .trailing))
                                .frame(width: geo.size.width * progressToNext, height: 6)
                                .animation(.spring(response: 0.8), value: progressToNext)
                        }
                    }
                    .frame(height: 6)
                }
            }
        }
        .padding(18)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Coupon Card

struct CouponCard: View {
    let coupon: SponsorCoupon
    var isRedeemed: Bool = false
    let onRedeem: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            // Coupon icon
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(red: 0.0, green: 0.82, blue: 0.60).opacity(0.15))
                    .frame(width: 52, height: 52)
                Image(systemName: "tag.fill")
                    .font(.system(size: 22))
                    .foregroundColor(Color(red: 0.0, green: 0.82, blue: 0.60))
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(coupon.sponsorName)
                    .font(.system(size: 12)).foregroundColor(.white.opacity(0.5))
                Text(coupon.description)
                    .font(.system(size: 15, weight: .semibold)).foregroundColor(.white)
                Text("Expires in \(coupon.daysUntilExpiry) days")
                    .font(.system(size: 11)).foregroundColor(.white.opacity(0.35))
            }

            Spacer()

            if !isRedeemed && coupon.isValid {
                Button(action: onRedeem) {
                    Text("Use")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color(red: 0.0, green: 0.82, blue: 0.60))
                        .clipShape(Capsule())
                }
            } else {
                Text(isRedeemed ? "Used" : "Expired")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.3))
            }
        }
        .padding(14)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.08)))
    }
}

// MARK: - Coupon Redemption Sheet

struct CouponRedemptionSheet: View {
    let coupon: SponsorCoupon
    @Environment(\.dismiss) var dismiss
    @State private var showSafari = false
    @State private var safariURL: URL?
    @State private var codeCopied = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "gift.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(LinearGradient(colors: [.yellow, .orange], startPoint: .top, endPoint: .bottom))

                VStack(spacing: 8) {
                    Text(coupon.sponsorName)
                        .font(.system(size: 14)).foregroundColor(.secondary)
                    Text(coupon.description)
                        .font(.system(size: 24, weight: .bold))
                        .multilineTextAlignment(.center)
                }

                // Coupon code
                Button {
                    UIPasteboard.general.string = coupon.couponCode
                    codeCopied = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) { codeCopied = false }
                } label: {
                    HStack(spacing: 8) {
                        Text(coupon.couponCode)
                            .font(.system(size: 22, weight: .black, design: .monospaced))
                        Image(systemName: codeCopied ? "checkmark" : "doc.on.doc")
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                if codeCopied {
                    Text("Code copied to clipboard!")
                        .font(.system(size: 13))
                        .foregroundColor(Color(red: 0.0, green: 0.82, blue: 0.60))
                        .transition(.opacity)
                }

                // Redeem buttons
                VStack(spacing: 12) {
                    if let deepLink = coupon.deepLinkURL, UIApplication.shared.canOpenURL(deepLink) {
                        Button("Open \(coupon.sponsorName) App") {
                            UIApplication.shared.open(deepLink)
                            dismiss()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Color(red: 0.0, green: 0.82, blue: 0.60))
                        .frame(maxWidth: .infinity)
                    }

                    if let webURL = coupon.sponsorWebURL {
                        Button("Open in Browser") {
                            safariURL = webURL
                            showSafari = true
                        }
                        .buttonStyle(.bordered)
                        .frame(maxWidth: .infinity)
                    }
                }

                if let minPurchase = coupon.minimumPurchase {
                    Text("Minimum purchase: $\(String(format: "%.2f", minPurchase))")
                        .font(.system(size: 12)).foregroundColor(.secondary)
                }

                Spacer()
            }
            .padding(24)
            .navigationTitle("Redeem Reward")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showSafari) {
                if let url = safariURL {
                    SafariView(url: url)
                }
            }
        }
    }
}

// MARK: - Safari View Wrapper

struct SafariView: UIViewControllerRepresentable {
    let url: URL
    func makeUIViewController(context: Context) -> SFSafariViewController {
        SFSafariViewController(url: url)
    }
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}

// MARK: - Leaderboard View

struct LeaderboardView: View {
    @StateObject private var vm = LeaderboardViewModel()

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                // My rank (sticky-style highlight)
                if let myEntry = vm.myEntry {
                    LeaderboardRowView(entry: myEntry, isMe: true)
                        .padding(.horizontal, 16).padding(.vertical, 8)
                        .background(Color(red: 0.0, green: 0.82, blue: 0.60).opacity(0.1))
                }
                Divider().background(Color.white.opacity(0.08))

                ForEach(vm.entries) { entry in
                    LeaderboardRowView(entry: entry, isMe: entry.id == vm.myEntry?.id)
                        .padding(.horizontal, 16)
                    Divider().padding(.leading, 64).background(Color.white.opacity(0.05))
                }
            }
        }
        .background(Color(white: 0.05))
        .task { await vm.load(scope: .weekly) }
        .overlay {
            if vm.isLoading {
                ProgressView().tint(.white)
            }
        }
    }
}

struct LeaderboardRowView: View {
    let entry: LeaderboardEntry
    let isMe: Bool

    var body: some View {
        HStack(spacing: 14) {
            // Rank
            Text("#\(entry.rank)")
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundColor(rankColor)
                .frame(width: 40, alignment: .leading)

            // Tier emoji
            Text(entry.tier.emoji)
                .font(.system(size: 22))

            VStack(alignment: .leading, spacing: 2) {
                Text(isMe ? "You" : entry.displayName)
                    .font(.system(size: 14, weight: isMe ? .bold : .medium))
                    .foregroundColor(.white)
                Text("\(entry.correctPredictions)/\(entry.totalPredictions) correct · \(entry.accuracyFormatted)")
                    .font(.system(size: 11)).foregroundColor(.white.opacity(0.45))
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(entry.points)")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color(red: 0.0, green: 0.82, blue: 0.60))
                Text("pts")
                    .font(.system(size: 10)).foregroundColor(.white.opacity(0.4))
            }
        }
        .padding(.vertical, 12)
        .background(isMe ? Color(red: 0.0, green: 0.82, blue: 0.60).opacity(0.05) : .clear)
    }

    private var rankColor: Color {
        switch entry.rank {
        case 1: return .yellow
        case 2: return Color(white: 0.75)
        case 3: return Color(hue: 0.06, saturation: 0.6, brightness: 0.7)
        default: return .white.opacity(0.4)
        }
    }
}

// MARK: - Leaderboard View Model

@MainActor
final class LeaderboardViewModel: ObservableObject {
    @Published var entries: [LeaderboardEntry] = []
    @Published var myEntry: LeaderboardEntry?
    @Published var isLoading = false

    func load(scope: LeaderboardScope) async {
        isLoading = true
        defer { isLoading = false }

        // TODO: fetch from /v1/leaderboard?scope=weekly&limit=100
        // Demo data — broken into discrete steps to avoid Swift type-checker timeout
        let names = ["SportsGuru", "PredictKing", "FanZone", "LiveBet", "GOAT"]
        var demos: [LeaderboardEntry] = []
        for rank in 1...20 {
            let pts: Int = max(0, 500 - (rank * 20) + Int.random(in: -10...10))
            let correct: Int = Int.random(in: 15...40)
            let total: Int = Int.random(in: 45...60)
            let streak: Int = max(0, 10 - rank)
            let tier: RewardsTier = RewardsTier.tier(for: max(0, 500 - rank * 20))
            let name: String = names[rank % 5] + " \(rank)"
            let entry = LeaderboardEntry(
                id: UUID(), userID: "user_\(rank)", displayName: name,
                avatarURL: nil, rank: rank, points: pts,
                correctPredictions: correct, totalPredictions: total,
                currentStreak: streak, tier: tier
            )
            demos.append(entry)
        }
        entries = demos

        let wallet = PredictionEngine.shared.wallet
        myEntry = LeaderboardEntry(
            id: UUID(), userID: "me", displayName: "You",
            avatarURL: nil, rank: 7,
            points: wallet.weeklyPoints,
            correctPredictions: 12, totalPredictions: 20,
            currentStreak: wallet.currentStreak,
            tier: wallet.tier
        )
    }
}
