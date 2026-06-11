// PlayerView.swift — Arenza V2
// Layout: Top 40% video (PlayerLayerView — tap-to-play/pause)
//          Bottom 60% unified tabs (🎯 Predict | 🎲 Bingo | 🎟 Scratch | 📊 M/L | 👤 Me)
// Features: landscape fullscreen toggle, share/refer button, audio-session fix.

import SwiftUI
import AVKit
import AVFoundation
import UIKit

// MARK: - PlayerLayerView (Phase 4 fix: replaces VideoPlayer to enable tap gestures)

struct PlayerLayerView: UIViewRepresentable {
    let player: AVPlayer

    func makeUIView(context: Context) -> UIView {
        let view = PlayerUIView()
        view.playerLayer.player = player
        view.playerLayer.videoGravity = .resizeAspectFill
        view.backgroundColor = .black
        // Phase 1: Crop bottom 10% to hide CBS Sports broadcast ticker baked into demo clip.
        // Normalized rect: (x, y, width, height) where y=0 is top, height=0.90 drops bottom 10%.
        view.playerLayer.contentsRect = CGRect(x: 0, y: 0, width: 1.0, height: 0.90)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        guard let view = uiView as? PlayerUIView else { return }
        view.playerLayer.player = player
    }

    class PlayerUIView: UIView {
        override class var layerClass: AnyClass { AVPlayerLayer.self }
        var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
    }
}

// MARK: - PlayerView

struct PlayerView: View {
    let channel: Channel
    @EnvironmentObject var env: AppEnvironment
    @StateObject private var vm: PlayerViewModel
    @StateObject private var game = GameEngine()
    @StateObject private var adEngine = InteractiveAdEngine()
    @Environment(\.dismiss) private var dismiss

    // Tab state
    @State private var activeTab: UnifiedTab = .predict
    @State private var tabUserInteracted = false
    @State private var autoCycleTimer: Timer? = nil

    // Fullscreen state (Phase 2)
    @State private var isFullscreen = false
    @State private var fullscreenControlsVisible = true
    @State private var controlsHideTimer: Timer? = nil

    // Play/pause display feedback (Phase 4)
    @State private var showPauseIcon = false

    // Toast (Phase 3)
    @State private var showShareToast = false

    enum UnifiedTab: String, CaseIterable {
        case predict  = "🎯 Predict"
        case bingo    = "🎲 Bingo"
        case spin     = "🎰 Spin"
        case scratch  = "🎟 Scratch"
        case me       = "👤 Me"

        var adFormat: InteractiveAdEngine.AdFormat? {
            switch self {
            case .predict:  return .prediction
            case .bingo:    return .bingo
            case .spin:     return nil
            case .scratch:  return .scratch
            case .me:       return nil
            }
        }
    }

    init(channel: Channel) {
        self.channel = channel
        self._vm = StateObject(wrappedValue: PlayerViewModel(channel: channel, env: .shared))
    }

    // MARK: - Body

    var body: some View {
        Group {
            if isFullscreen {
                fullscreenLayout
                    .ignoresSafeArea()
                    .statusBarHidden(true)
                    .persistentSystemOverlays(.hidden)
            } else {
                portraitLayout
            }
        }
        .background(Color(arenza: "#0d0f14"))
        .preferredColorScheme(.dark)
        .task { await vm.startPlayback() }
        .onAppear {
            vm.player?.play()
            game.start()
            adEngine.startCycling()
            startAutoCycle()
        }
        .onDisappear {
            vm.stop()
            game.stop()
            adEngine.stop()
            autoCycleTimer?.invalidate()
        }
        .overlay(shareToast, alignment: .top)
    }

    // MARK: - Portrait Layout (Phase 1: 2-panel 40/60)

    private var portraitLayout: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                // ── TOP 40%: Video Panel ──────────────────────────────────────
                videoPanel
                    .frame(height: geo.size.height * 0.40)

                // ── BOTTOM 60%: Unified Tabs ──────────────────────────────────
                unifiedTabPanel
                    .frame(height: geo.size.height * 0.60)
            }
        }
        .ignoresSafeArea(edges: .top)
    }

    // MARK: - Fullscreen Layout (Phase 2)

    private var fullscreenLayout: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            if let player = vm.player {
                PlayerLayerView(player: player)
                    .ignoresSafeArea()
                    .onTapGesture {
                        togglePlayPause()
                        showFullscreenControls()
                    }
            }
            if fullscreenControlsVisible {
                fullscreenOverlay
                    .transition(.opacity)
            }
            pauseIconOverlay
        }
        .animation(.easeInOut(duration: 0.25), value: fullscreenControlsVisible)
        .onAppear {
            setOrientation(.landscapeRight)
            showFullscreenControls()
        }
        .onDisappear { setOrientation(.portrait) }
    }

    private var fullscreenOverlay: some View {
        VStack {
            HStack {
                // Exit fullscreen
                Button {
                    withAnimation(.easeInOut(duration: 0.3)) { isFullscreen = false }
                } label: {
                    Image(systemName: "arrow.down.right.and.arrow.up.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 40, height: 40)
                        .background(Color.black.opacity(0.6))
                        .clipShape(Circle())
                }
                Spacer()
                // Scoreboard in fullscreen
                HStack(spacing: 10) {
                    Text("🦅 \(game.homeScore)")
                        .font(.system(size: 16, weight: .black, design: .monospaced))
                        .foregroundColor(Color(arenza: "#ff6b35"))
                    Text("Q\(game.quarter) · \(game.clockDisplay)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white.opacity(0.7))
                    Text("\(game.awayScore) 🐻")
                        .font(.system(size: 16, weight: .black, design: .monospaced))
                        .foregroundColor(Color(arenza: "#00c9b1"))
                }
                .padding(.horizontal, 14).padding(.vertical, 6)
                .background(Color.black.opacity(0.75))
                .clipShape(Capsule())
                Spacer()
                // Live badge
                HStack(spacing: 4) {
                    Circle().fill(Color.red).frame(width: 6, height: 6)
                    Text("LIVE").font(.system(size: 9, weight: .black)).foregroundColor(.red).tracking(1.5)
                }
                .padding(.horizontal, 8).padding(.vertical, 4)
                .background(Color.black.opacity(0.6))
                .clipShape(Capsule())
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            Spacer()
        }
    }

    // MARK: - Video Panel (Portrait)

    private var videoPanel: some View {
        ZStack(alignment: .bottom) {
            Color.black

            // Video layer — tap to play/pause (Phase 4)
            if let player = vm.player {
                PlayerLayerView(player: player)
                    .ignoresSafeArea(edges: .top)
                    .onTapGesture { togglePlayPause() }
            }

            // Loading
            if vm.isLoading {
                VStack(spacing: 12) {
                    ProgressView().tint(.white).scaleEffect(1.2)
                    Text("Connecting to stream…")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                }
            }

            // Error
            if let error = vm.errorMessage {
                VStack(spacing: 8) {
                    Image(systemName: "wifi.slash").font(.system(size: 28)).foregroundColor(.orange)
                    Text(error).font(.system(size: 12)).foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center).padding(.horizontal, 24)
                }
            }

            // Scoreboard overlay (top)
            scoreboardOverlay

            // Points fly-up
            if let fly = game.flyText {
                Text(fly)
                    .font(.system(size: 32, weight: .black))
                    .foregroundColor(Color(arenza: "#ffc107"))
                    .shadow(color: Color(arenza: "#ffc107").opacity(0.6), radius: 12)
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity),
                        removal: .move(edge: .top).combined(with: .opacity)
                    ))
                    .id(fly)
            }

            // Pause/play icon flash
            pauseIconOverlay
        }
        .animation(.easeInOut(duration: 0.3), value: game.flyText)
        .clipped()
    }

    // Pause icon flash feedback
    private var pauseIconOverlay: some View {
        Group {
            if showPauseIcon {
                Image(systemName: vm.player?.rate == 0 ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 52))
                    .foregroundColor(.white.opacity(0.85))
                    .shadow(radius: 10)
                    .transition(.opacity.combined(with: .scale(scale: 0.7)))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: showPauseIcon)
    }

    // MARK: - Scoreboard

    private var scoreboardOverlay: some View {
        VStack {
            HStack(alignment: .center, spacing: 0) {
                // Close
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(Color.black.opacity(0.55))
                        .clipShape(Circle())
                }

                Spacer()

                // Scoreboard
                HStack(spacing: 10) {
                    teamScoreView(emoji: "🦅", name: "EAGLES", score: game.homeScore, color: Color(arenza: "#ff6b35"))
                    VStack(spacing: 0) {
                        Text("Q\(game.quarter)")
                            .font(.system(size: 10, weight: .black)).foregroundColor(.white.opacity(0.6))
                        Text(game.clockDisplay)
                            .font(.system(size: 14, weight: .black, design: .monospaced)).foregroundColor(.white)
                    }
                    teamScoreView(emoji: "🐻", name: "BEARS", score: game.awayScore, color: Color(arenza: "#00c9b1"))
                }
                .padding(.horizontal, 14).padding(.vertical, 6)
                .background(Color.black.opacity(0.75))
                .clipShape(Capsule())

                Spacer()

                // Fullscreen toggle button (Phase 2)
                Button {
                    withAnimation(.easeInOut(duration: 0.3)) { isFullscreen = true }
                } label: {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 30, height: 30)
                        .background(Color.black.opacity(0.55))
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, 50)
            Spacer()
        }
    }

    private func teamScoreView(emoji: String, name: String, score: Int, color: Color) -> some View {
        VStack(spacing: 1) {
            Text("\(emoji) \(name)")
                .font(.system(size: 9, weight: .semibold)).foregroundColor(.white.opacity(0.7))
            Text("\(score)")
                .font(.system(size: 28, weight: .black, design: .monospaced)).foregroundColor(color)
        }
    }

    // MARK: - Unified Tab Panel (Phase 1)

    private var unifiedTabPanel: some View {
        VStack(spacing: 0) {
            unifiedTabBar
            unifiedTabContent
        }
        .background(Color(arenza: "#0d0f14"))
    }

    private var unifiedTabBar: some View {
        HStack(spacing: 0) {
            ForEach(UnifiedTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { activeTab = tab }
                    onUserTabTap()
                } label: {
                    VStack(spacing: 3) {
                        Text(tab.rawValue)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(activeTab == tab ? Color(arenza: "#ff6b35") : Color(arenza: "#8892b0"))
                        Rectangle()
                            .fill(activeTab == tab ? Color(arenza: "#ff6b35") : Color.clear)
                            .frame(height: 2)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
                .buttonStyle(.plain)
            }

            // Points badge
            VStack(spacing: 1) {
                Text("⭐")
                    .font(.system(size: 11))
                Text("\(game.points.formatted())")
                    .font(.system(size: 10, weight: .black, design: .monospaced))
                    .foregroundColor(Color(arenza: "#ffc107"))
            }
            .padding(.horizontal, 6)

            // Share button (Phase 3)
            Button { shareGame() } label: {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color(arenza: "#ff6b35"))
                    .frame(width: 32, height: 32)
                    .background(Color(arenza: "#ff6b35").opacity(0.12))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .padding(.trailing, 8)
        }
        .background(Color(arenza: "#141720"))
        .overlay(Rectangle().fill(Color.white.opacity(0.08)).frame(height: 1), alignment: .top)
    }

    @ViewBuilder
    private var unifiedTabContent: some View {
        switch activeTab {
        case .predict:
            PredictionAdCard(engine: game, adEngine: adEngine)
        case .bingo:
            BingoAdCard(engine: game, adEngine: adEngine)
        case .spin:
            // TableSpin: sponsor-branded spin wheel + scratch cycling through 4 businesses
            SpinGameAdCard(engine: game, adEngine: adEngine)
        case .scratch:
            ScratchAdCard(engine: game, adEngine: adEngine)
        case .me:
            ProfileTab(engine: game)
        }
    }

    // MARK: - Auto-Cycle (rotates first 4 tabs every 15s unless user tapped)

    private func startAutoCycle() {
        autoCycleTimer?.invalidate()
        autoCycleTimer = Timer.scheduledTimer(withTimeInterval: 15.0, repeats: true) { _ in
            guard !tabUserInteracted else { return }
            Task { @MainActor in
                let cyclingTabs: [UnifiedTab] = [.predict, .bingo, .spin, .scratch]
                guard let idx = cyclingTabs.firstIndex(of: activeTab) else { return }
                let next = cyclingTabs[(idx + 1) % cyclingTabs.count]
                withAnimation(.easeInOut(duration: 0.3)) { activeTab = next }
            }
        }
        RunLoop.main.add(autoCycleTimer!, forMode: .common)
    }

    private func onUserTabTap() {
        tabUserInteracted = true
        // Resume auto-cycle after 30s
        DispatchQueue.main.asyncAfter(deadline: .now() + 30) {
            tabUserInteracted = false
        }
    }

    // MARK: - Play / Pause (Phase 4)

    private func togglePlayPause() {
        guard let player = vm.player else { return }
        if player.rate == 0 {
            player.play()
        } else {
            player.pause()
        }
        // Flash the icon
        showPauseIcon = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation { showPauseIcon = false }
        }
    }

    // MARK: - Fullscreen Controls (Phase 2)

    private func showFullscreenControls() {
        fullscreenControlsVisible = true
        controlsHideTimer?.invalidate()
        controlsHideTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in
            Task { @MainActor in
                withAnimation { fullscreenControlsVisible = false }
            }
        }
    }

    private func setOrientation(_ orientation: UIInterfaceOrientation) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
        let mask: UIInterfaceOrientationMask = orientation == .landscapeRight ? .landscapeRight : .portrait
        windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: mask))
    }

    // MARK: - Share / Refer (Phase 3)

    private func shareGame() {
        let text = "I'm watching Eagles vs Bears LIVE on Arenza! Join me and earn 500 bonus points 🏈🔥"
        let url = URL(string: "https://arenza.tv/join?ref=demo-user")!
        let ac = UIActivityViewController(activityItems: [text, url], applicationActivities: nil)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(ac, animated: true)
        }
    }

    private var shareToast: some View {
        Group {
            if showShareToast {
                Text("🔗 Link copied!")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16).padding(.vertical, 10)
                    .background(Color(arenza: "#22c55e"))
                    .clipShape(Capsule())
                    .padding(.top, 60)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.35), value: showShareToast)
    }
}
