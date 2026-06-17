// LiveGameView.swift — Arenza
// Main split-screen experience matching the web demo exactly:
//   Top 42%  → Live video + ArenzaTV logo + audience tier badge + AI commentary
//   Bottom 58% → 9-tab bar (Predict|Bingo|Scratch|M/L|Local|Wallet|Leaders|Me|Ads) + content
//   Inline ad breaks replace the tab content when a commercial break fires.

import SwiftUI
import AVFoundation

// MARK: - Design Tokens (matching web demo T object)

private enum T {
    static let bg      = Color(arenza: "#0d0f14")
    static let surface = Color(arenza: "#141720")
    static let surface2 = Color(arenza: "#1a1e2a")
    static let border  = Color.white.opacity(0.08)
    static let text    = Color(arenza: "#f0f2ff")
    static let muted   = Color(arenza: "#8892b0")
    static let faint   = Color(arenza: "#4a5568")
    static let orange  = Color(arenza: "#ff6b35")
    static let teal    = Color(arenza: "#00c9b1")
    static let gold    = Color(arenza: "#ffc107")
    static let green   = Color(arenza: "#22c55e")
    static let red     = Color(arenza: "#ef4444")
    static let purple  = Color(arenza: "#7c3aed")
}

// MARK: - 9-Tab Definition (matching web IOSTabBar exactly)

enum LiveTab: String, CaseIterable, Identifiable {
    case predict  = "predict"
    case bingo    = "bingo"
    case scratch  = "scratch"
    case moreless = "moreless"
    case market   = "market"
    case wallet   = "wallet"
    case board    = "board"
    case me       = "me"
    case ads      = "ads"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .predict:  return "🎯"
        case .bingo:    return "🎲"
        case .scratch:  return "🎟"
        case .moreless: return "📊"
        case .market:   return "📍"
        case .wallet:   return "💳"
        case .board:    return "🏆"
        case .me:       return "👤"
        case .ads:      return "📺"
        }
    }

    var label: String {
        switch self {
        case .predict:  return "Predict"
        case .bingo:    return "Bingo"
        case .scratch:  return "Scratch"
        case .moreless: return "M/L"
        case .market:   return "Local"
        case .wallet:   return "Wallet"
        case .board:    return "Leaders"
        case .me:       return "Me"
        case .ads:      return "Ads"
        }
    }
}

// MARK: - LiveGameView

struct LiveGameView: View {
    @EnvironmentObject var env: AppEnvironment
    @StateObject private var game = GameEngine()
    @StateObject private var adEngine = InteractiveAdEngine()
    @ObservedObject private var nflPlayer = NFLDemoPlayer.shared
    @ObservedObject private var demo = DemoOrchestrator.shared

    // Tab state
    @State private var activeTab: LiveTab = .predict
    @State private var tabUserInteracted = false

    // Split state
    @State private var splitState: SplitState = .splitView

    // Ad break state (inline, replaces tab content)
    @State private var adBreakActive = false
    @State private var currentAdBusiness: LocalBusiness? = nil
    @State private var podToastVisible = false
    @State private var podTxHash = ""

    // Toasts
    @State private var couponClaimToast: String? = nil
    @State private var walletJoinToast: String? = nil

    // Wallet badge
    @State private var walletBadgeCount: Int = 0

    // Auto-cycle timer
    @State private var autoCycleTimer: Timer? = nil

    var body: some View {
        ZStack {
            ArenzaSplitView(state: $splitState) {
                videoPanel
            } panel: {
                bottomPanel
            }
            .ignoresSafeArea(edges: .top)

            // Onboarding handled at ContentView level

            // Coupon toast (bottom, orange gradient)
            if let toast = couponClaimToast {
                couponToast(text: toast)
            }

            // Wallet join toast (bottom, teal gradient)
            if let toast = walletJoinToast {
                walletToast(text: toast)
            }

            // Post-game recap
            if demo.showPostGameRecap {
                Color.black.opacity(0.6).ignoresSafeArea().zIndex(60)
                PostGameRecapView(
                    points: MembershipService.shared.totalPointsAcrossAllBusinesses + demo.totalAZTEarned,
                    correctPredictions: PredictionEngine.shared.wallet.currentStreak,
                    totalPredictions: max(1, PredictionEngine.shared.wallet.currentStreak + 2),
                    adsWatched: 2,
                    couponsClaimedCount: MembershipService.shared.allActiveCoupons.count,
                    homeScore: 27, awayScore: 14
                ) {
                    withAnimation { demo.showPostGameRecap = false }
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .zIndex(70)
            }
        }
        .background(T.bg)
        .preferredColorScheme(.dark)
        .onAppear {
            game.start()
            adEngine.startCycling()
            startAutoCycle()
        }
        .onDisappear {
            game.stop()
            adEngine.stop()
            autoCycleTimer?.invalidate()
        }
        // Ad break fires → show inline
        .onChange(of: demo.showLocalAdOverlay) { showing in
            if showing {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                    adBreakActive = true
                    currentAdBusiness = demoBusinesses.first
                }
            }
        }
        .pointsFlyUp(text: game.flyText)
        .overlay(BingoCelebrationOverlay(lineCount: game.bingoLines))
    }

    // MARK: - Video Panel (top 42%)

    private var videoPanel: some View {
        ZStack(alignment: .topLeading) {
            Color.black

            // Live video
            if let player = nflPlayer.player {
                PlayerLayerView(player: player)
                    .ignoresSafeArea(edges: .top)
            } else {
                // Fallback: dark placeholder with game info
                LinearGradient(
                    colors: [Color(arenza: "#0d1a0f"), Color(arenza: "#0d0f14")],
                    startPoint: .top, endPoint: .bottom
                )
                .ignoresSafeArea(edges: .top)
                VStack(spacing: 8) {
                    Text("🏈").font(.system(size: 48))
                    Text("Eagles vs Bears")
                        .font(.system(size: 16, weight: .black))
                        .foregroundColor(T.text)
                    Text("🔴 LIVE · Q\(game.quarter) · \(game.clockDisplay)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(T.red)
                }
            }

            // ArenzaTV Logo — top-left, always visible (network branding)
            Image("arenza-logo")
                .resizable()
                .scaledToFit()
                .frame(height: 54)
                .shadow(color: T.orange.opacity(0.8), radius: 14, x: 0, y: 0)
                .padding(.top, 8)
                .padding(.leading, 12)

            // Audience Tier Badge — top-right
            AudienceTierBadgeView(aztBalance: PredictionEngine.shared.wallet.aztBalance)
                .frame(maxWidth: .infinity, alignment: .topTrailing)
                .padding(.top, 10)
                .padding(.trailing, 10)

            // Live badge + LIVE indicator — top center
            HStack(spacing: 4) {
                Circle().fill(T.red).frame(width: 6, height: 6)
                    .opacity(0.9)
                Text("LIVE")
                    .font(.system(size: 9, weight: .black))
                    .foregroundColor(T.red)
                    .tracking(1.5)
            }
            .padding(.horizontal, 8).padding(.vertical, 4)
            .background(Color.black.opacity(0.6))
            .clipShape(Capsule())
            .frame(maxWidth: .infinity, alignment: .top)
            .padding(.top, 12)

            // Score strip — bottom of video
            scoreStrip
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                .padding(.bottom, 4)

            // AI Commentary lower-third
            CommentaryOverlayView(engine: game)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)

            // Points fly-up overlay
            if let fly = game.flyText {
                Text(fly)
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundColor(T.gold)
                    .shadow(color: T.gold.opacity(0.8), radius: 12)
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity),
                        removal: .opacity
                    ))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            }

            // Glowing orange bottom divider
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.clear, T.orange.opacity(0.5), .clear],
                        startPoint: .leading, endPoint: .trailing
                    )
                )
                .frame(height: 1)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        }
        .clipped()
    }

    private var scoreStrip: some View {
        HStack(spacing: 12) {
            Text("🦅 \(game.homeScore)")
                .font(.system(size: 13, weight: .black, design: .monospaced))
                .foregroundColor(T.orange)
            Text("Q\(game.quarter) · \(game.clockDisplay)")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(T.muted)
            Text("\(game.awayScore) 🐻")
                .font(.system(size: 13, weight: .black, design: .monospaced))
                .foregroundColor(T.teal)
        }
        .padding(.horizontal, 12).padding(.vertical, 5)
        .background(Color.black.opacity(0.7))
        .clipShape(Capsule())
    }

    // MARK: - Bottom Panel (tab bar + content)

    private var bottomPanel: some View {
        VStack(spacing: 0) {
            // Status banner
            TemporalStatusBanner()

            if adBreakActive, let biz = currentAdBusiness {
                // ── INLINE AD BREAK ──────────────────────────────────────────
                inlineAdZone(business: biz)
            } else {
                // ── INTERACTIVE TABS ──────────────────────────────────────────
                tabContent
                    .frame(maxHeight: .infinity)
            }

            // Tab bar — always visible
            liveTabBar
        }
        .background(T.bg)
    }

    // MARK: - Inline Ad Zone (matches web demo bottom ad section exactly)

    private func inlineAdZone(business: LocalBusiness) -> some View {
        VStack(spacing: 0) {
            // Ad header
            HStack(spacing: 8) {
                Circle().fill(T.red).frame(width: 6, height: 6)
                Text("SPONSORED AD")
                    .font(.system(size: 9, weight: .black))
                    .foregroundColor(Color.white.opacity(0.6))
                    .tracking(1.2)
                Spacer()
                Text("$45 CPM · 30s")
                    .font(.system(size: 9))
                    .foregroundColor(T.muted)
            }
            .padding(.horizontal, 14).padding(.vertical, 6)
            .background(T.surface)
            .overlay(Rectangle().fill(T.border).frame(height: 1), alignment: .bottom)

            // Progress bar
            ProgressView(value: 0.6)
                .tint(T.orange)
                .scaleEffect(x: 1, y: 0.4, anchor: .center)

            // Business card (logo area)
            HStack(spacing: 10) {
                Text(business.emoji)
                    .font(.system(size: 28))
                    .frame(width: 44, height: 44)
                    .background(T.surface2)
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                VStack(alignment: .leading, spacing: 2) {
                    Text(business.name)
                        .font(.system(size: 13, weight: .black))
                        .foregroundColor(T.text)
                    Text(business.activeOffer?.headline ?? "Special Offer")
                        .font(.system(size: 10))
                        .foregroundColor(T.muted)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("📍 Personalized for you")
                        .font(.system(size: 9))
                        .foregroundColor(T.faint)
                    Text(business.city)
                        .font(.system(size: 9))
                        .foregroundColor(T.muted)
                }
            }
            .padding(.horizontal, 14).padding(.top, 10)

            // Offer highlight
            if let offer = business.activeOffer {
                HStack(spacing: 8) {
                    Text("🎁").font(.system(size: 14))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(offer.headline)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(T.text)
                        Text("Tap Claim to save to Wallet")
                            .font(.system(size: 9))
                            .foregroundColor(T.muted)
                    }
                    Spacer()
                }
                .padding(.horizontal, 14).padding(.vertical, 8)
                .background(T.orange.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 0)
                        .stroke(T.orange.opacity(0.25), lineWidth: 1)
                )
                .padding(.horizontal, 14).padding(.top, 6)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            // 3-button CTA row — 🎟 Claim | 🤝 Join | 🛒 Order
            HStack(spacing: 6) {
                adCTAButton(icon: "🎟", label: "Claim", color: T.orange) {
                    handleCouponClaim(business)
                }
                adCTAButton(icon: "🤝", label: "Join", color: T.teal) {
                    handleJoinClub(business)
                }
                adCTAButton(icon: "🛒", label: "Order", color: T.green) {
                    // Link opens in Safari — handled by .openURL in environment
                }
            }
            .padding(.horizontal, 14).padding(.vertical, 10)

            // PoD verified overlay
            if podToastVisible {
                podVerifiedOverlay
            }

            Spacer()
        }
    }

    private func adCTAButton(icon: String, label: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(icon).font(.system(size: 20))
                Text(label)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(color)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(color.opacity(0.12))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(color.opacity(0.35), lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }

    private var podVerifiedOverlay: some View {
        VStack(spacing: 6) {
            Text("✅").font(.system(size: 32))
            Text("Proof-of-Delivery Verified")
                .font(.system(size: 13, weight: .black))
                .foregroundColor(T.green)
            Text("$45 CPM")
                .font(.system(size: 11))
                .foregroundColor(Color.white.opacity(0.7))
            Text(podTxHash)
                .font(.system(size: 9, design: .monospaced))
                .foregroundColor(T.teal)
                .tracking(0.5)
            Text("+10 Arenza Points earned")
                .font(.system(size: 9))
                .foregroundColor(T.muted)
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(Color.black.opacity(0.85))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 14)
        .transition(.opacity)
    }

    // MARK: - Tab Content

    @ViewBuilder
    private var tabContent: some View {
        ScrollView {
            VStack(spacing: 0) {
                switch activeTab {
                case .predict:
                    PredictionAdCard(engine: game, adEngine: adEngine)
                        .padding(12)
                case .bingo:
                    BingoAdCard(engine: game, adEngine: adEngine)
                        .padding(12)
                case .scratch:
                    ScratchAdCard(engine: game, adEngine: adEngine)
                        .padding(12)
                case .moreless:
                    MoreLessAdCard(engine: game, adEngine: adEngine)
                        .padding(12)
                case .market:
                    MarketplaceView()
                        .frame(maxHeight: .infinity)
                case .wallet:
                    QRWalletView()
                        .frame(maxHeight: .infinity)
                case .board:
                    SocialLeaderboardView()
                        .frame(maxHeight: .infinity)
                case .me:
                    ProfileTab(engine: game)
                        .padding(12)
                case .ads:
                    AdsHistoryTabView()
                        .padding(12)
                }
            }
        }
    }

    // MARK: - 9-Tab Bar (matching web IOSTabBar exactly)

    private var liveTabBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(LiveTab.allCases) { tab in
                    Button {
                        withAnimation(.easeInOut(duration: 0.18)) {
                            activeTab = tab
                            adBreakActive = false
                        }
                        onUserTabTap()
                    } label: {
                        VStack(spacing: 2) {
                            Text(tab.icon).font(.system(size: 18))
                            Text(tab.label)
                                .font(.system(size: 8, weight: .semibold))
                                .foregroundColor(activeTab == tab ? T.orange : T.muted)
                        }
                        .frame(minWidth: 52)
                        .padding(.vertical, 6)
                        .overlay(
                            // Wallet notification badge
                            Group {
                                if tab == .wallet && walletBadgeCount > 0 {
                                    Text(walletBadgeCount > 9 ? "9+" : "\(walletBadgeCount)")
                                        .font(.system(size: 8, weight: .black))
                                        .foregroundColor(.white)
                                        .frame(width: 14, height: 14)
                                        .background(T.red)
                                        .clipShape(Circle())
                                        .offset(x: 18, y: -10)
                                }
                            }
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 4)
        }
        .frame(height: 56)
        .background(Color.black.opacity(0.96))
        .overlay(Rectangle().fill(T.border).frame(height: 1), alignment: .top)
    }

    // MARK: - Toasts

    private func couponToast(text: String) -> some View {
        VStack {
            Spacer()
            HStack(spacing: 10) {
                Text("🎟").font(.system(size: 22))
                VStack(alignment: .leading, spacing: 1) {
                    Text("Coupon Saved to Wallet!")
                        .font(.system(size: 13, weight: .black))
                    Text(text)
                        .font(.system(size: 10))
                        .opacity(0.85)
                }
            }
            .foregroundColor(.white)
            .padding(.horizontal, 18).padding(.vertical, 12)
            .background(
                LinearGradient(
                    colors: [T.orange, T.gold],
                    startPoint: .leading, endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: T.orange.opacity(0.5), radius: 16)
            .padding(.bottom, 70)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
        .zIndex(300)
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: couponClaimToast)
    }

    private func walletToast(text: String) -> some View {
        VStack {
            Spacer()
            HStack(spacing: 10) {
                Text("🤝").font(.system(size: 22))
                Text(text)
                    .font(.system(size: 13, weight: .black))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 18).padding(.vertical, 12)
            .background(
                LinearGradient(
                    colors: [T.teal, Color(arenza: "#00a896")],
                    startPoint: .leading, endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: T.teal.opacity(0.5), radius: 16)
            .padding(.bottom, 70)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
        .zIndex(300)
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: walletJoinToast)
    }

    // MARK: - Actions

    private func handleCouponClaim(_ business: LocalBusiness) {
        MembershipService.shared.addCoupon(
            businessId: business.id,
            offer: business.activeOffer?.headline ?? "Discount",
            value: business.activeOffer?.value ?? ""
        )
        walletBadgeCount += 1
        showCouponToast("\(business.activeOffer?.headline ?? "Special Offer") — \(business.name)")
        // Show PoD verified
        podTxHash = "0x" + String((0..<16).map { _ in "0123456789abcdef".randomElement()! })
        withAnimation { podToastVisible = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation { podToastVisible = false }
            withAnimation(.spring(response: 0.4)) {
                adBreakActive = false
                demo.showLocalAdOverlay = false
            }
        }
    }

    private func handleJoinClub(_ business: LocalBusiness) {
        MembershipService.shared.addStamp(businessId: business.id)
        walletBadgeCount += 1
        showWalletToast("🎉 Joined \(business.name) Club! Check your Wallet.")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.spring(response: 0.4)) {
                adBreakActive = false
                demo.showLocalAdOverlay = false
            }
        }
    }

    private func showCouponToast(_ text: String) {
        withAnimation { couponClaimToast = text }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            withAnimation { couponClaimToast = nil }
        }
    }

    private func showWalletToast(_ text: String) {
        withAnimation { walletJoinToast = text }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation { walletJoinToast = nil }
        }
    }

    // MARK: - Auto-Cycle (tabs rotate every 25s matching web demo)

    private func startAutoCycle() {
        autoCycleTimer?.invalidate()
        autoCycleTimer = Timer.scheduledTimer(withTimeInterval: 25.0, repeats: true) { _ in
            guard !tabUserInteracted else { return }
            Task { @MainActor in
                let cycle: [LiveTab] = [.predict, .bingo, .scratch, .moreless, .market]
                guard let idx = cycle.firstIndex(of: activeTab) else {
                    activeTab = .predict; return
                }
                withAnimation(.easeInOut(duration: 0.3)) {
                    activeTab = cycle[(idx + 1) % cycle.count]
                }
            }
        }
        RunLoop.main.add(autoCycleTimer!, forMode: .common)
    }

    private func onUserTabTap() {
        tabUserInteracted = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 60) {
            tabUserInteracted = false
        }
    }
}

// MARK: - NFL Demo Player (standalone, no channel dependency)

@MainActor
final class NFLDemoPlayer: ObservableObject {
    static let shared = NFLDemoPlayer()
    @Published var player: AVPlayer?

    private static let nflURL = "https://lavcma6duvpplftv.public.blob.vercel-storage.com/NFL%20video%20clips%20for%20demo.mp4"

    private init() {
        guard let url = URL(string: Self.nflURL) else { return }
        let item = AVPlayerItem(url: url)
        let p = AVPlayer(playerItem: item)
        p.isMuted = false
        p.automaticallyWaitsToMinimizeStalling = true
        self.player = p
        // Loop on end
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: item,
            queue: .main
        ) { [weak p] _ in
            p?.seek(to: .zero) { _ in p?.play() }
        }
        p.play()
    }
}

// LocalBusiness is defined in LocalAdCardView.swift — no alias needed here.
