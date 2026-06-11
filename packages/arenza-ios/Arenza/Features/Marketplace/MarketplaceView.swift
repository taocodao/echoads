// MarketplaceView.swift — Arenza (Token Marketplace)
// Browsable sponsor offer catalog with three display modes:
//   1. Near Me — GPS-ranked local sponsors
//   2. For You — AI-ranked by viewing history
//   3. Browse All — full catalog with category filters
//
// Revenue: every card impression (1s+ dwell) = CPM, every tap = CPC, every redeem = CPA.

import SwiftUI
import SafariServices

// MARK: - Marketplace Tab View

struct MarketplaceView: View {
    @StateObject private var vm = MarketplaceViewModel()
    @ObservedObject private var engine = PredictionEngine.shared
    @ObservedObject private var geo = LocalizationEngine.shared
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // AZT balance header
                aztBalanceHeader

                // Search bar
                searchBar

                // Stadium Mode banner
                if geo.isAtStadium, let stadium = geo.nearbyStadium {
                    stadiumBanner(stadium: stadium)
                }

                // Browse mode picker (hidden when searching)
                if searchText.isEmpty {
                    Picker("", selection: $vm.browseMode) {
                        Text("Near Me").tag(BrowseMode.nearMe)
                        Text("For You").tag(BrowseMode.forYou)
                        Text("Browse All").tag(BrowseMode.browseAll)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                }

                // Category filter chips (Browse All mode)
                if vm.browseMode == .browseAll && searchText.isEmpty {
                    categoryChips
                }

                // Offer list
                ScrollView {
                    LazyVStack(spacing: 0) {
                        // Sponsor businesses section
                        sponsorBusinessesSection

                        // Regular offers
                        if !vm.filteredOffers.filter({ searchText.isEmpty || $0.sponsorName.localizedCaseInsensitiveContains(searchText) || $0.offerTitle.localizedCaseInsensitiveContains(searchText) }).isEmpty {
                            sectionHeader("Sponsor Offers")
                            LazyVStack(spacing: 12) {
                                ForEach(vm.filteredOffers.filter { searchText.isEmpty || $0.sponsorName.localizedCaseInsensitiveContains(searchText) || $0.offerTitle.localizedCaseInsensitiveContains(searchText) }) { offer in
                                    SponsorOfferCard(
                                        offer: offer,
                                        userBalance: engine.wallet.aztBalance,
                                        onTap: { vm.selectedOffer = offer },
                                        onImpression: { vm.logImpression(offer: offer) }
                                    )
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.bottom, 16)
                        } else if searchText.isEmpty && vm.filteredOffers.isEmpty {
                            emptyState
                        }
                    }
                }
            }
            .navigationTitle("Marketplace")
            .navigationBarTitleDisplayMode(.large)
            .background(Color(white: 0.05).ignoresSafeArea())
            .onAppear { geo.requestLocationIfNeeded() }
            .sheet(item: $vm.selectedOffer) { offer in
                OfferDetailSheet(offer: offer, wallet: $engine.wallet) {
                    vm.logClick(offer: offer)
                } onRedeem: {
                    vm.redeemOffer(offer, wallet: &engine.wallet)
                    engine.saveWallet()
                }
            }
        }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.4))
            TextField("Search businesses, offers...", text: $searchText)
                .font(.system(size: 14))
                .foregroundColor(.white)
                .autocorrectionDisabled()
            if !searchText.isEmpty {
                Button { searchText = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.white.opacity(0.4))
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 16)
        .padding(.bottom, 4)
    }

    // MARK: - Sponsor Businesses Section (gamified sponsors)

    private var sponsorBusinessesSection: some View {
        let filtered = SponsorBusiness.all.filter {
            searchText.isEmpty ||
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.tagline.localizedCaseInsensitiveContains(searchText) ||
            $0.category.rawValue.localizedCaseInsensitiveContains(searchText)
        }
        return Group {
            if !filtered.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    sectionHeader("🎰 Gamified Sponsors — Apply Your Points")
                    ForEach(filtered, id: \.id) { biz in
                        SponsorBusinessMarketplaceCard(
                            business: biz,
                            userBalance: engine.wallet.aztBalance
                        )
                    }
                }
                .padding(.bottom, 8)
            }
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 12, weight: .black))
            .foregroundColor(.white.opacity(0.5))
            .tracking(0.5)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 4)
    }

    // MARK: - Stadium Mode Banner

    private func stadiumBanner(stadium: Stadium) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "stadium")
                .font(.system(size: 16))
                .foregroundColor(.orange)
            VStack(alignment: .leading, spacing: 1) {
                Text("STADIUM MODE")
                    .font(.system(size: 10, weight: .black))
                    .foregroundColor(.orange)
                    .tracking(1.2)
                Text(stadium.name)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.7))
            }
            Spacer()
            Text("3× local boost")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.orange)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.orange.opacity(0.10))
    }

    // MARK: - AZT Balance Header

    private var aztBalanceHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("YOUR BALANCE")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.white.opacity(0.5))
                    .tracking(1.2)
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(engine.wallet.aztBalance)")
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                    Text("AZT")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Color(red: 0.0, green: 0.82, blue: 0.60))
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(engine.wallet.tier.emoji + " " + engine.wallet.tier.label)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white.opacity(0.7))
                Text("🔥 \(engine.wallet.currentStreak) streak")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.4))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            LinearGradient(
                colors: [Color(white: 0.08), Color(white: 0.04)],
                startPoint: .top, endPoint: .bottom
            )
        )
    }

    // MARK: - Category Chips

    private var categoryChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                chipButton(label: "All", isSelected: vm.selectedCategory == nil) {
                    vm.selectedCategory = nil
                }
                ForEach(CouponCategory.allCases, id: \.rawValue) { cat in
                    chipButton(label: cat.rawValue.capitalized, isSelected: vm.selectedCategory == cat) {
                        vm.selectedCategory = cat
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
        }
    }

    private func chipButton(label: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(isSelected ? .black : .white.opacity(0.7))
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(isSelected ? Color(red: 0.0, green: 0.82, blue: 0.60) : Color.white.opacity(0.08))
                .clipShape(Capsule())
        }
    }

    // MARK: - Offer List

    private var offerList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(vm.filteredOffers) { offer in
                    SponsorOfferCard(
                        offer: offer,
                        userBalance: engine.wallet.aztBalance,
                        onTap: { vm.selectedOffer = offer },
                        onImpression: { vm.logImpression(offer: offer) }
                    )
                }
            }
            .padding(16)
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "storefront")
                .font(.system(size: 48))
                .foregroundColor(.white.opacity(0.15))
            Text(vm.browseMode == .nearMe ? "No local offers nearby" : "No offers available")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white.opacity(0.4))
            Text("Check back soon — new deals are added daily!")
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.25))
                .multilineTextAlignment(.center)
            Spacer()
        }
        .padding(32)
    }
}

// MARK: - CouponCategory CaseIterable conformance

extension CouponCategory: CaseIterable {
    static var allCases: [CouponCategory] {
        [.food, .sports, .betting, .retail, .travel, .streaming, .electronics, .entertainment]
    }
}

// MARK: - Sponsor Offer Card

struct SponsorOfferCard: View {
    let offer: SponsorOffer
    let userBalance: Int
    let onTap: () -> Void
    let onImpression: () -> Void

    @State private var dwellTimerFired = false

    private var canAfford: Bool { userBalance >= offer.aztCost }
    private var categoryIcon: String {
        switch offer.category {
        case .food:          return "fork.knife"
        case .sports:        return "sportscourt"
        case .betting:       return "dice"
        case .retail:        return "bag"
        case .travel:        return "airplane"
        case .streaming:     return "play.tv"
        case .electronics:   return "laptopcomputer"
        case .entertainment: return "ticket"
        }
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                // Category icon
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(red: 0.0, green: 0.82, blue: 0.60).opacity(0.12))
                        .frame(width: 52, height: 52)
                    Image(systemName: categoryIcon)
                        .font(.system(size: 22))
                        .foregroundColor(Color(red: 0.0, green: 0.82, blue: 0.60))
                }

                // Offer details
                VStack(alignment: .leading, spacing: 4) {
                    Text(offer.sponsorName)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white.opacity(0.5))
                        .textCase(.uppercase)
                        .tracking(0.5)
                    Text(offer.offerTitle)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(2)
                    HStack(spacing: 6) {
                        Text("$\(String(format: "%.0f", offer.dollarValue)) value")
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.4))
                        if offer.isLocalOnly {
                            Label("Local", systemImage: "location.fill")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.orange.opacity(0.8))
                        }
                    }
                }

                Spacer()

                // AZT cost badge
                VStack(spacing: 2) {
                    Text("\(offer.aztCost)")
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .foregroundColor(canAfford ? Color(red: 0.0, green: 0.82, blue: 0.60) : .white.opacity(0.3))
                    Text("AZT")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(canAfford ? Color(red: 0.0, green: 0.82, blue: 0.60).opacity(0.7) : .white.opacity(0.2))
                }
            }
            .padding(14)
            .background(Color.white.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(canAfford ? Color(red: 0.0, green: 0.82, blue: 0.60).opacity(0.15) : Color.white.opacity(0.06), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .onAppear {
            // Log impression after 1-second dwell (CPM)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                guard !dwellTimerFired else { return }
                dwellTimerFired = true
                onImpression()
            }
        }
    }
}

// MARK: - Offer Detail Sheet

struct OfferDetailSheet: View {
    let offer: SponsorOffer
    @Binding var wallet: RewardsWallet
    let onBrowse: () -> Void
    let onRedeem: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var showSafari = false
    @State private var codeRevealed = false
    @State private var redeemSuccess = false

    private var canAfford: Bool { wallet.aztBalance >= offer.aztCost }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Sponsor header
                    VStack(spacing: 8) {
                        Text(offer.sponsorName)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white.opacity(0.5))
                            .textCase(.uppercase)
                        Text(offer.offerTitle)
                            .font(.system(size: 24, weight: .black))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                        Text("$\(String(format: "%.2f", offer.dollarValue)) value")
                            .font(.system(size: 15))
                            .foregroundColor(Color(red: 0.0, green: 0.82, blue: 0.60))
                    }
                    .padding(.top, 8)

                    // Description
                    Text(offer.offerDescription)
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)

                    // Cost display
                    HStack {
                        VStack(spacing: 2) {
                            Text("COST")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white.opacity(0.4))
                            Text("\(offer.aztCost) AZT")
                                .font(.system(size: 20, weight: .black, design: .rounded))
                                .foregroundColor(.white)
                        }
                        Spacer()
                        VStack(spacing: 2) {
                            Text("YOUR BALANCE")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white.opacity(0.4))
                            Text("\(wallet.aztBalance) AZT")
                                .font(.system(size: 20, weight: .black, design: .rounded))
                                .foregroundColor(canAfford ? Color(red: 0.0, green: 0.82, blue: 0.60) : .red)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                    .background(Color.white.opacity(0.04))
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                    // Coupon code (revealed after redeem)
                    if codeRevealed {
                        VStack(spacing: 8) {
                            Text("YOUR CODE")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white.opacity(0.4))
                            Text(offer.couponCode)
                                .font(.system(size: 28, weight: .black, design: .monospaced))
                                .foregroundColor(Color(red: 0.0, green: 0.82, blue: 0.60))
                                .textSelection(.enabled)
                            Text("Tap to copy")
                                .font(.system(size: 11))
                                .foregroundColor(.white.opacity(0.3))
                        }
                        .padding(20)
                        .frame(maxWidth: .infinity)
                        .background(Color(red: 0.0, green: 0.82, blue: 0.60).opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .onTapGesture {
                            UIPasteboard.general.string = offer.couponCode
                            UINotificationFeedbackGenerator().notificationOccurred(.success)
                        }
                        .transition(.scale.combined(with: .opacity))
                    }

                    // Action buttons
                    VStack(spacing: 10) {
                        // Browse sponsor site
                        Button {
                            onBrowse()
                            showSafari = true
                        } label: {
                            HStack {
                                Image(systemName: "safari")
                                Text("Browse \(offer.sponsorName)")
                            }
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.white.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }

                        // Redeem button
                        if !codeRevealed {
                            Button {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                    onRedeem()
                                    codeRevealed = true
                                    redeemSuccess = true
                                }
                                UINotificationFeedbackGenerator().notificationOccurred(.success)
                            } label: {
                                HStack {
                                    Image(systemName: "ticket")
                                    Text("Redeem for \(offer.aztCost) AZT")
                                }
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(canAfford ? Color(red: 0.0, green: 0.82, blue: 0.60) : Color.gray.opacity(0.3))
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                            }
                            .disabled(!canAfford)
                        }

                        if !canAfford && !codeRevealed {
                            Text("You need \(offer.aztCost - wallet.aztBalance) more AZT")
                                .font(.system(size: 12))
                                .foregroundColor(.red.opacity(0.7))
                        }
                    }

                    // Legal disclaimer
                    Text("No cash value. Virtual points only. Coupon subject to sponsor terms.")
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.2))
                        .multilineTextAlignment(.center)

                    // Expiry
                    let days = Calendar.current.dateComponents([.day], from: Date(), to: offer.expiryDate).day ?? 0
                    Text("Expires in \(days) days")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.3))
                }
                .padding(20)
            }
            .background(Color(white: 0.06).ignoresSafeArea())
            .navigationTitle("Offer Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(Color(red: 0.0, green: 0.82, blue: 0.60))
                }
            }
            .sheet(isPresented: $showSafari) {
                if let url = offer.affiliateURL {
                    SafariView(url: url)
                }
            }
        }
    }
}

// SafariView is defined in RewardsWalletView.swift and shared app-wide.


enum BrowseMode: String, CaseIterable {
    case nearMe = "Near Me"
    case forYou = "For You"
    case browseAll = "Browse All"
}

@MainActor
final class MarketplaceViewModel: ObservableObject {
    @Published var browseMode: BrowseMode = .forYou
    @Published var selectedCategory: CouponCategory?
    @Published var selectedOffer: SponsorOffer?
    @Published var offers: [SponsorOffer] = SponsorOffer.demoOffers

    private var impressionLog: Set<UUID> = []  // prevent duplicate CPM events per session

    var filteredOffers: [SponsorOffer] {
        var result = offers.filter { $0.isAvailable }
        let geo = LocalizationEngine.shared

        switch browseMode {
        case .nearMe:
            // Geo-ranked: local offers first, then national
            result = geo.localOffers(from: result)
            result = geo.rankOffers(result)
        case .forYou:
            // AI profile ranking (ProfileEngine.shared.currentSegment)
            // For now: weight by impressionCPM as a proxy for relevance
            result = result.sorted { $0.impressionCPM > $1.impressionCPM }
        case .browseAll:
            if let cat = selectedCategory {
                result = result.filter { $0.category == cat }
            }
        }

        return result
    }

    // MARK: - Revenue Event Logging

    func logImpression(offer: SponsorOffer) {
        guard !impressionLog.contains(offer.id) else { return }
        impressionLog.insert(offer.id)
        Task { await RevenueReporter.shared.recordImpression(offer: offer) }
    }

    func logClick(offer: SponsorOffer) {
        Task { await RevenueReporter.shared.recordClick(offer: offer) }
    }

    func redeemOffer(_ offer: SponsorOffer, wallet: inout RewardsWallet) {
        let success = wallet.spend(offer.aztCost, source: .redemption, sponsorId: offer.sponsorId)
        if success {
            Task { await RevenueReporter.shared.recordRedemption(offer: offer, aztSpent: offer.aztCost) }
        } else {
            print("[Revenue] Redeem failed — insufficient AZT (balance: \(wallet.aztBalance), cost: \(offer.aztCost))")
        }
    }
}
