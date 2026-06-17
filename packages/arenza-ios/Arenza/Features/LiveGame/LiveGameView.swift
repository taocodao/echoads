// LiveGameView.swift — Arenza
import SwiftUI
import AVFoundation
import Combine

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
}

enum LiveTab: String, CaseIterable, Identifiable {
    case predict, bingo, scratch, moreless, market, wallet, board, me, ads
    var id: String { rawValue }
    var icon: String {
        switch self {
        case .predict: return "🎯"; case .bingo: return "🎲"; case .scratch: return "🎟"
        case .moreless: return "📊"; case .market: return "📍"; case .wallet: return "💳"
        case .board: return "🏆"; case .me: return "👤"; case .ads: return "📺"
        }
    }
    var label: String {
        switch self {
        case .predict: return "Predict"; case .bingo: return "Bingo"; case .scratch: return "Scratch"
        case .moreless: return "M/L"; case .market: return "Local"; case .wallet: return "Wallet"
        case .board: return "Leaders"; case .me: return "Me"; case .ads: return "Ads"
        }
    }
}

// MARK: - Main View

@MainActor
struct LiveGameView: View {
    @EnvironmentObject var env: AppEnvironment
    @StateObject private var game = GameEngine()
    @StateObject private var adEngine = InteractiveAdEngine()
    @ObservedObject private var nflPlayer = NFLDemoPlayer.shared
    @ObservedObject private var demo = DemoOrchestrator.shared

    @State private var activeTab: LiveTab = .predict
    @State private var tabUserInteracted = false
    @State private var autoCycleTimer: Timer?

    // Ad break state
    @State private var currentAdBreak: CommercialBreak? = nil
    @State private var currentAd: AdCreative? = nil
    @State private var adProgress: Double = 0
    @State private var podToastVisible = false
    @State private var podTxHash = ""
    @State private var _firedBreakIds: Set<String> = []
    @State private var isBreakActive = false

    // Fullscreen (points-gated landscape)
    @State private var fullscreenUnlocked = false
    @State private var isLandscape = false
    @State private var showPointsAlert = false

    // Toasts
    @State private var couponClaimToast: String? = nil
    @State private var walletJoinToast: String? = nil
    @State private var walletBadgeCount = 0

    // In-app web
    @State private var webURL: IdentifiableURL? = nil

    // Multi-ad queue (mirrors web demo adQueueRef)
    @State private var adQueue: [AdCreative] = []
    // Ad watch history for Ads tab
    @State private var adHistory: [(ad: AdCreative, txHash: String)] = []

    var body: some View {
        ZStack {
            ArenzaSplitView(state: .constant(.splitView)) {
                videoPanel
            } panel: {
                bottomPanel
            }
            .ignoresSafeArea(edges: .top)

            if let toast = couponClaimToast { couponToast(text: toast) }
            if let toast = walletJoinToast  { walletToastView(text: toast) }

            if demo.showPostGameRecap {
                Color.black.opacity(0.6).ignoresSafeArea().zIndex(60)
                PostGameRecapView(
                    points: MembershipService.shared.totalPointsAcrossAllBusinesses + demo.totalAZTEarned,
                    correctPredictions: PredictionEngine.shared.wallet.currentStreak,
                    totalPredictions: max(1, PredictionEngine.shared.wallet.currentStreak + 2),
                    adsWatched: _firedBreakIds.count,
                    couponsClaimedCount: MembershipService.shared.allActiveCoupons.count,
                    homeScore: 27, awayScore: 14
                ) { withAnimation { demo.showPostGameRecap = false } }
                .transition(.move(edge: .bottom).combined(with: .opacity)).zIndex(70)
            }
        }
        .background(T.bg)
        .preferredColorScheme(.dark)
        .sheet(item: $webURL) { item in InAppWebSheet(url: item.url) }
        .alert("Unlock Fullscreen", isPresented: $showPointsAlert) {
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("You need 500 points to unlock landscape fullscreen. Keep playing to earn more!")
        }
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
        // Single clock: drive ad breaks from GameEngine elapsed (matches web demo)
        .onChange(of: game.elapsedPublic) { elapsed in
            checkAdBreaks(elapsed: elapsed)
        }
        .pointsFlyUp(text: game.flyText)
        .overlay(BingoCelebrationOverlay(lineCount: game.bingoLines))
    }

    // MARK: - Video Panel

    private var videoPanel: some View {
        ZStack(alignment: .topLeading) {
            Color.black
            if let player = nflPlayer.player {
                PlayerLayerView(player: player).ignoresSafeArea(edges: .top)
            } else {
                LinearGradient(colors: [Color(arenza: "#0d1a0f"), T.bg], startPoint: .top, endPoint: .bottom)
                VStack(spacing: 8) {
                    Text("🏈").font(.system(size: 48))
                    Text("Eagles vs Bears").font(.system(size: 16, weight: .black)).foregroundColor(T.text)
                    Text("🔴 LIVE · Q\(game.quarter) · \(game.clockDisplay)").font(.system(size: 11, weight: .bold)).foregroundColor(T.red)
                }
            }

            // ArenzaTV text logo (reliable — no asset dependency)
            arenzaLogo
                .padding(.top, 8).padding(.leading, 12)

            // Tier badge top-right
            AudienceTierBadgeView(aztBalance: PredictionEngine.shared.wallet.aztBalance)
                .frame(maxWidth: .infinity, alignment: .topTrailing).padding(.top, 10).padding(.trailing, 10)

            // LIVE badge top-center
            HStack(spacing: 4) {
                Circle().fill(T.red).frame(width: 6, height: 6)
                Text("LIVE").font(.system(size: 9, weight: .black)).foregroundColor(T.red).tracking(1.5)
            }
            .padding(.horizontal, 8).padding(.vertical, 4)
            .background(Color.black.opacity(0.6)).clipShape(Capsule())
            .frame(maxWidth: .infinity, alignment: .top).padding(.top, 12)

            // Score strip bottom
            scoreStrip.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom).padding(.bottom, 30)

            // Commentary lower-third
            CommentaryOverlayView(engine: game)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)

            // Points fly-up
            if let fly = game.flyText {
                Text(fly).font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundColor(T.gold).shadow(color: T.gold.opacity(0.8), radius: 12)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .transition(.asymmetric(insertion: .move(edge: .bottom).combined(with: .opacity), removal: .opacity))
            }

            // Fullscreen button bottom-right
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    fullscreenButton.padding(.bottom, 8).padding(.trailing, 10)
                }
            }

            // Glowing divider
            Rectangle()
                .fill(LinearGradient(colors: [.clear, T.orange.opacity(0.5), .clear], startPoint: .leading, endPoint: .trailing))
                .frame(height: 1).frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        }
        .clipped()
    }

    private var fullscreenButton: some View {
        Button {
            let pts = PredictionEngine.shared.wallet.aztBalance
            if fullscreenUnlocked || pts >= 500 {
                if !fullscreenUnlocked {
                    // Spend 500 pts to unlock
                    _ = PredictionEngine.shared.wallet.spend(500, source: .landscapeUnlock)
                    PredictionEngine.shared.saveWallet()
                    fullscreenUnlocked = true
                }
                withAnimation { isLandscape.toggle() }
                let orientation: UIInterfaceOrientationMask = isLandscape ? .landscapeRight : .portrait
                UIDevice.current.setValue(
                    isLandscape ? UIInterfaceOrientation.landscapeRight.rawValue : UIInterfaceOrientation.portrait.rawValue,
                    forKey: "orientation"
                )
            } else {
                showPointsAlert = true
            }
        } label: {
            Group {
                if fullscreenUnlocked {
                    Text(isLandscape ? "⤡" : "⤢")
                        .font(.system(size: 14, weight: .bold)).foregroundColor(.white)
                } else {
                    HStack(spacing: 4) {
                        Text("🔓").font(.system(size: 10))
                        Text("500 pts").font(.system(size: 9, weight: .bold)).foregroundColor(T.gold)
                    }
                }
            }
            .padding(8)
            .background(Color.black.opacity(0.65))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.2), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private var arenzaLogo: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text("ARENZA")
                .font(.system(size: 20, weight: .black, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color(arenza: "#00d4a8"), Color(arenza: "#ff6b35")],
                        startPoint: .leading, endPoint: .trailing
                    )
                )
            Text("TV")
                .font(.system(size: 9, weight: .heavy))
                .foregroundColor(T.orange.opacity(0.8))
                .tracking(4)
        }
        .padding(.horizontal, 10).padding(.vertical, 5)
        .background(Color.black.opacity(0.55))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(color: T.orange.opacity(0.4), radius: 8)
    }

    private var scoreStrip: some View {
        HStack(spacing: 12) {
            Text("🦅 \(game.homeScore)").font(.system(size: 13, weight: .black, design: .monospaced)).foregroundColor(T.orange)
            Text("Q\(game.quarter) · \(game.clockDisplay)").font(.system(size: 10, weight: .bold)).foregroundColor(T.muted)
            Text("\(game.awayScore) 🐻").font(.system(size: 13, weight: .black, design: .monospaced)).foregroundColor(T.teal)
        }
        .padding(.horizontal, 12).padding(.vertical, 5)
        .background(Color.black.opacity(0.7)).clipShape(Capsule())
    }

    // MARK: - Bottom Panel

    private var bottomPanel: some View {
        VStack(spacing: 0) {
            TemporalStatusBanner()
            if let ad = currentAd {
                inlineAdZone(ad: ad)
                    .frame(maxHeight: .infinity)
            } else {
                tabContent.frame(maxHeight: .infinity)
            }
            liveTabBar
        }
        .background(T.bg)
    }

    // MARK: - Inline Ad Zone

    private func inlineAdZone(ad: AdCreative) -> some View {
        VStack(spacing: 0) {
            // Ad header bar
            HStack(spacing: 8) {
                Circle().fill(T.red).frame(width: 6, height: 6)
                    .opacity(0.9)
                Text("SPONSORED AD")
                    .font(.system(size: 9, weight: .black))
                    .foregroundColor(Color.white.opacity(0.6)).tracking(1.2)
                Spacer()
                Text("$\(ad.cpm) CPM · \(ad.durationSec)s")
                    .font(.system(size: 9)).foregroundColor(T.muted)
            }
            .padding(.horizontal, 14).padding(.vertical, 6)
            .background(T.surface)
            .overlay(Rectangle().fill(T.border).frame(height: 1), alignment: .bottom)

            // Progress bar (driven by real video progress)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Color.white.opacity(0.08)
                    ad.primaryColor.opacity(0.9)
                        .frame(width: geo.size.width * adProgress)
                        .animation(.linear(duration: 0.25), value: adProgress)
                }
            }
            .frame(height: 3)

            // Ad video player
            ZStack {
                if let videoURL = ad.videoURL {
                    AdVideoPlayerView(ad: ad, progress: $adProgress) {
                        // video.ended — matches web demo exactly
                        adProgress = 1.0
                        let tx = "0x" + String((0..<16).map { _ in "0123456789abcdef".randomElement()! })
                        podTxHash = tx
                        adHistory.append((ad: ad, txHash: tx))
                        withAnimation { podToastVisible = true }
                        // 1.2s PoD toast — matches web demo (was 2.5s)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                            withAnimation { podToastVisible = false }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                currentAd = nil
                                adProgress = 0
                                // Play next ad in queue (multi-ad break support)
                                if !adQueue.isEmpty {
                                    let next = adQueue.removeFirst()
                                    adProgress = 0
                                    withAnimation(.spring(response: 0.4)) { currentAd = next }
                                } else {
                                    isBreakActive = false
                                }
                            }
                        }
                    }
                } else {
                    // No URL fallback: show brand card and auto-dismiss after duration
                    VStack(spacing: 12) {
                        Text(ad.emoji).font(.system(size: 56))
                        Text(ad.brand).font(.system(size: 16, weight: .black)).foregroundColor(T.text)
                        Text(ad.tagline).font(.system(size: 11)).foregroundColor(T.muted)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(ad.primaryColor.opacity(0.08))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + Double(ad.durationSec)) {
                            currentAd = nil; isBreakActive = false; adProgress = 0
                        }
                    }
                }

                // PoD verified overlay
                if podToastVisible {
                    Color.black.opacity(0.85)
                        .ignoresSafeArea()
                    VStack(spacing: 6) {
                        Text("✅").font(.system(size: 32))
                        Text("Proof-of-Delivery Verified")
                            .font(.system(size: 13, weight: .black)).foregroundColor(T.green)
                        Text("\(ad.brand) · $\(ad.cpm) CPM")
                            .font(.system(size: 11)).foregroundColor(Color.white.opacity(0.7))
                        Text(podTxHash)
                            .font(.system(size: 9, design: .monospaced)).foregroundColor(T.teal).tracking(0.5)
                        Text("+10 Arenza Points earned")
                            .font(.system(size: 9)).foregroundColor(T.muted)
                    }
                    .padding(20).frame(maxWidth: .infinity)
                    .transition(.opacity)
                }
            }
            .frame(maxHeight: .infinity)

            // Brand info + offer + 3-button CTA
            VStack(spacing: 8) {
                HStack(spacing: 10) {
                    Text(ad.emoji).font(.system(size: 28))
                        .frame(width: 44, height: 44)
                        .background(T.surface2)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(ad.brand).font(.system(size: 13, weight: .black)).foregroundColor(T.text)
                        Text(ad.tagline).font(.system(size: 10)).foregroundColor(T.muted)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("📍 Personalized for you").font(.system(size: 9)).foregroundColor(T.faint)
                        Text(ad.targetSegment).font(.system(size: 9)).foregroundColor(T.muted)
                    }
                }

                // Offer headline
                HStack(spacing: 8) {
                    Text("🎁").font(.system(size: 14))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(ad.offerHeadline).font(.system(size: 11, weight: .bold)).foregroundColor(T.text)
                        Text("\(ad.offerValue) · Tap Claim to save to Wallet").font(.system(size: 9)).foregroundColor(T.muted)
                    }
                    Spacer()
                }
                .padding(10)
                .background(ad.primaryColor.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(ad.primaryColor.opacity(0.3), lineWidth: 1))

                // 3 CTA buttons
                HStack(spacing: 6) {
                    // Claim
                    Button {
                        MembershipService.shared.addCoupon(businessId: ad.id, offer: ad.offerHeadline, value: ad.offerValue)
                        walletBadgeCount += 1
                        showCouponToast("\(ad.offerHeadline) — \(ad.brand)")
                    } label: {
                        VStack(spacing: 4) {
                            Text("🎟").font(.system(size: 20))
                            Text("Claim").font(.system(size: 10, weight: .bold)).foregroundColor(ad.primaryColor)
                        }
                        .frame(maxWidth: .infinity).padding(.vertical, 10)
                        .background(ad.primaryColor.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(ad.primaryColor.opacity(0.35), lineWidth: 1))
                    }.buttonStyle(.plain)

                    // Join Club
                    Button {
                        MembershipService.shared.addStamp(businessId: ad.id)
                        walletBadgeCount += 1
                        showWalletToast("🎉 Joined \(ad.brand) Club!")
                    } label: {
                        VStack(spacing: 4) {
                            Text("🤝").font(.system(size: 20))
                            Text("Join").font(.system(size: 10, weight: .bold)).foregroundColor(T.teal)
                        }
                        .frame(maxWidth: .infinity).padding(.vertical, 10)
                        .background(T.teal.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(T.teal.opacity(0.35), lineWidth: 1))
                    }.buttonStyle(.plain)

                    // Order / Visit website (in-app browser)
                    Button {
                        if let url = ad.websiteURL { webURL = IdentifiableURL(url: url) }
                    } label: {
                        VStack(spacing: 4) {
                            Text("🛒").font(.system(size: 20))
                            Text("Order").font(.system(size: 10, weight: .bold)).foregroundColor(T.green)
                        }
                        .frame(maxWidth: .infinity).padding(.vertical, 10)
                        .background(T.green.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(T.green.opacity(0.35), lineWidth: 1))
                    }.buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 14).padding(.bottom, 12).padding(.top, 8)
            .background(T.surface)
            .overlay(Rectangle().fill(T.border).frame(height: 1), alignment: .top)
        }
    }

    // MARK: - Tab Content

    @ViewBuilder
    private var tabContent: some View {
        ScrollView {
            VStack(spacing: 0) {
                switch activeTab {
                case .predict:  PredictionAdCard(engine: game, adEngine: adEngine).padding(12)
                case .bingo:    BingoAdCard(engine: game, adEngine: adEngine).padding(12)
                case .scratch:  ScratchAdCard(engine: game, adEngine: adEngine).padding(12)
                case .moreless: MoreLessAdCard(engine: game, adEngine: adEngine).padding(12)
                case .market:   MarketplaceView().frame(maxHeight: .infinity)
                case .wallet:   QRWalletView().frame(maxHeight: .infinity)
                case .board:    SocialLeaderboardView().frame(maxHeight: .infinity)
                case .me:       ProfileTab(engine: game).padding(12)
                case .ads:      AdsHistoryTabView().padding(12)
                }
            }
        }
    }

    // MARK: - Tab Bar

    private var liveTabBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(LiveTab.allCases) { tab in
                    Button {
                        withAnimation(.easeInOut(duration: 0.18)) { activeTab = tab }
                        onUserTabTap()
                    } label: {
                        VStack(spacing: 2) {
                            Text(tab.icon).font(.system(size: 18))
                            Text(tab.label).font(.system(size: 8, weight: .semibold))
                                .foregroundColor(activeTab == tab ? T.orange : T.muted)
                        }
                        .frame(minWidth: 52).padding(.vertical, 6)
                        .overlay(
                            Group {
                                if tab == .wallet && walletBadgeCount > 0 {
                                    Text(walletBadgeCount > 9 ? "9+" : "\(walletBadgeCount)")
                                        .font(.system(size: 8, weight: .black)).foregroundColor(.white)
                                        .frame(width: 14, height: 14).background(T.red).clipShape(Circle())
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

    // MARK: - Ad Break Logic (single clock — mirrors web demo architecture)

    private func checkAdBreaks(elapsed: Int) {
        // Reset fired IDs when game loops (t<=3)
        if elapsed <= 3 { _firedBreakIds.removeAll() }
        guard !isBreakActive else { return }
        // >= range: handles any occasional missed onChange tick
        guard let brk = COMMERCIAL_BREAKS.first(where: {
            elapsed >= $0.triggerAt &&
            elapsed < $0.triggerAt + 3 &&
            !_firedBreakIds.contains($0.id)
        }) else { return }
        _firedBreakIds.insert(brk.id)
        scheduleBreak(brk)
    }

    // MARK: - Courtesy Delay (mirrors web demo isUserBusy + scheduleBreak)

    private func isUserBusy() -> Bool {
        // User is mid-prediction and hasn't voted yet
        return activeTab == .predict && game.activePrediction != nil
    }

    private func scheduleBreak(_ brk: CommercialBreak) {
        guard !isBreakActive else { return }
        // Courtesy delay: if user is mid-prediction, retry after 2s (up to 15s then force)
        func tryStart(retriesLeft: Int) {
            if !isUserBusy() || retriesLeft <= 0 {
                startBreak(brk)
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    guard !isBreakActive else { return }  // break fired by other means
                    tryStart(retriesLeft: retriesLeft - 1)
                }
            }
        }
        tryStart(retriesLeft: 7)  // 7 × 2s = 14s max courtesy window
    }

    private func startBreak(_ brk: CommercialBreak) {
        guard !isBreakActive else { return }
        guard !brk.ads.isEmpty else { return }
        isBreakActive = true
        // Load full ad queue (multi-ad break support)
        adQueue = Array(brk.ads.dropFirst())
        adProgress = 0
        withAnimation(.spring(response: 0.4)) { currentAd = brk.ads[0] }
    }

    // MARK: - Toasts

    private func couponToast(text: String) -> some View {
        VStack {
            Spacer()
            HStack(spacing: 10) {
                Text("🎟").font(.system(size: 22))
                VStack(alignment: .leading, spacing: 1) {
                    Text("Coupon Saved to Wallet!").font(.system(size: 13, weight: .black))
                    Text(text).font(.system(size: 10)).opacity(0.85)
                }
            }
            .foregroundColor(.white).padding(.horizontal, 18).padding(.vertical, 12)
            .background(LinearGradient(colors: [T.orange, T.gold], startPoint: .leading, endPoint: .trailing))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: T.orange.opacity(0.5), radius: 16)
            .padding(.bottom, 70)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
        .zIndex(300)
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: couponClaimToast)
    }

    private func walletToastView(text: String) -> some View {
        VStack {
            Spacer()
            HStack(spacing: 10) {
                Text("🤝").font(.system(size: 22))
                Text(text).font(.system(size: 13, weight: .black))
            }
            .foregroundColor(.white).padding(.horizontal, 18).padding(.vertical, 12)
            .background(LinearGradient(colors: [T.teal, Color(arenza: "#00a896")], startPoint: .leading, endPoint: .trailing))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: T.teal.opacity(0.5), radius: 16)
            .padding(.bottom, 70)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
        .zIndex(300)
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: walletJoinToast)
    }

    private func showCouponToast(_ text: String) {
        withAnimation { couponClaimToast = text }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { withAnimation { couponClaimToast = nil } }
    }

    private func showWalletToast(_ text: String) {
        withAnimation { walletJoinToast = text }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { withAnimation { walletJoinToast = nil } }
    }

    // MARK: - Auto-Cycle

    private func startAutoCycle() {
        autoCycleTimer?.invalidate()
        autoCycleTimer = Timer.scheduledTimer(withTimeInterval: 25, repeats: true) { _ in
            guard !tabUserInteracted else { return }
            Task { @MainActor in
                let cycle: [LiveTab] = [.predict, .bingo, .scratch, .moreless, .market]
                guard let idx = cycle.firstIndex(of: activeTab) else { activeTab = .predict; return }
                withAnimation(.easeInOut(duration: 0.3)) { activeTab = cycle[(idx + 1) % cycle.count] }
            }
        }
        RunLoop.main.add(autoCycleTimer!, forMode: .common)
    }

    private func onUserTabTap() {
        tabUserInteracted = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 60) { tabUserInteracted = false }
    }
}

// MARK: - NFLDemoPlayer

@MainActor
final class NFLDemoPlayer: ObservableObject {
    static let shared = NFLDemoPlayer()
    @Published var player: AVPlayer?
    private static let nflURL = "https://lavcma6duvpplftv.public.blob.vercel-storage.com/NFL%20video%20clips%20for%20demo.mp4"
    private init() {
        // Set audio session before creating player
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback, options: [.mixWithOthers])
        try? AVAudioSession.sharedInstance().setActive(true)

        guard let url = URL(string: Self.nflURL) else { return }
        let item = AVPlayerItem(url: url)
        // Buffer just 10s ahead — lets large MP4 start playing fast
        item.preferredForwardBufferDuration = 10
        let p = AVPlayer(playerItem: item)
        p.isMuted = false
        p.automaticallyWaitsToMinimizeStalling = true
        self.player = p
        // Watchdog: retry play every 2s if stalled — mirrors web demo setInterval guard
        let watchdog = Timer(timeInterval: 2, repeats: true) { [weak p] _ in
            guard let p else { return }
            if p.timeControlStatus == .paused || p.timeControlStatus == .waitingToPlayAtSpecifiedRate {
                p.play()
            }
        }
        RunLoop.main.add(watchdog, forMode: .common)
        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: item, queue: .main) { [weak p] _ in
            p?.seek(to: .zero) { _ in p?.play() }
        }
        p.play()
    }
}
