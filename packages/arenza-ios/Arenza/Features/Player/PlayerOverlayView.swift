// PlayerOverlayView.swift — Arenza
// Pure SwiftUI overlay view, hosted by UIHostingController as a sibling
// UIView on top of AVPlayerViewController. No player rendering happens here.

import SwiftUI

struct PlayerOverlayView: View {
    @ObservedObject var vm: PlayerViewModel
    @ObservedObject var demo: DemoOrchestrator
    let onDismiss: () -> Void

    @State private var showDebugHUD = false

    var body: some View {
        ZStack {
            Color.clear  // transparent — video shows through

            // ── Top Bar ───────────────────────────────────────────────────
            VStack {
                topBar
                Spacer()
            }

            // ── Loading / Error ───────────────────────────────────────────
            if vm.isLoading {
                VStack(spacing: 16) {
                    ProgressView().tint(.white).scaleEffect(1.3)
                    Text("Connecting to stream...")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
            }

            if let error = vm.errorMessage {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.orange)
                    Text(error)
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
            }

            // ── Game Overlays (bottom) ────────────────────────────────────
            VStack {
                Spacer()

                if vm.isInAdBreak {
                    AdPodProgressOverlay(vm: vm)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }

                if let toast = vm.podToast {
                    PoDVerificationToast(toast: toast)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                if let overlay = vm.sgaiOverlay {
                    SGAIShoppableCard(data: overlay) {
                        withAnimation { vm.sgaiOverlay = nil }
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                if let question = vm.activePredictionQuestion {
                    PredictionOverlayView(
                        engine: PredictionEngine.shared,
                        question: question,
                        onDismiss: {}
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                if let coupon = vm.couponUnlock {
                    RewardUnlockOverlayView(
                        coupon: coupon,
                        onRedeem: { vm.couponUnlock = nil },
                        onDismiss: { vm.couponUnlock = nil }
                    )
                    .transition(.scale.combined(with: .opacity))
                }

                if let poll = PollEngine.shared.activePoll,
                   vm.activePredictionQuestion == nil, !vm.isInAdBreak {
                    PollOverlayView(engine: PollEngine.shared, poll: poll, onDismiss: {})
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                if TriviaEngine.shared.activeSession != nil,
                   vm.activePredictionQuestion == nil,
                   PollEngine.shared.activePoll == nil,
                   !vm.isInAdBreak {
                    TriviaOverlayView(engine: TriviaEngine.shared, onDismiss: {})
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                if let bettingCtx = vm.bettingOverlay, vm.activePredictionQuestion == nil {
                    BetSlipOverlayView(context: bettingCtx) {
                        withAnimation { vm.bettingOverlay = nil }
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                if demo.isRunning && !demo.stepNarration.isEmpty {
                    DemoNarrationBar(
                        narration: demo.stepNarration,
                        step: demo.currentStep,
                        elapsed: demo.elapsedSeconds
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }

            // ── Demo Ad Card (full screen, during pod) ────────────────────
            if vm.isInAdBreak, let creative = vm.adPodInserter.activeCreative {
                DemoAdCardView(
                    creative: creative,
                    podProgress: vm.adPodInserter.podProgress,
                    podDurationRemaining: vm.adPodInserter.podDurationRemaining,
                    currentSegment: ProfileEngine.shared.currentSegment.label
                )
                .transition(.opacity)
            }

            // ── Demo Profiling Card ───────────────────────────────────────
            if demo.showProfilingCard {
                VStack {
                    Spacer().frame(height: 80)
                    ViewerProfilingCard()
                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }

            // ── Ad Incoming Badge ─────────────────────────────────────────
            if demo.showAdIncomingBadge {
                VStack {
                    Spacer().frame(height: 70)
                    HStack { Spacer(); AdIncomingBadge(); Spacer() }
                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }

            // ── Debug HUD (shake) ─────────────────────────────────────────
            if showDebugHUD {
                VStack {
                    Spacer()
                    TargetingDebugHUD().padding(.bottom, 100)
                }
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }

            // ── Demo Summary ──────────────────────────────────────────────
            if demo.showDemoSummary {
                Color.black.opacity(0.6)
                VStack {
                    Spacer()
                    DemoSummaryCard(
                        aztEarned: demo.totalAZTEarned,
                        revenueGenerated: demo.revenueGenerated
                    ) {
                        demo.stop()
                        demo.start(for: vm)
                    }
                    Spacer()
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.35), value: vm.isInAdBreak)
        .animation(.spring(response: 0.35), value: vm.podToast != nil)
        .animation(.spring(response: 0.35), value: vm.activePredictionQuestion != nil)
        .animation(.spring(response: 0.35), value: vm.bettingOverlay != nil)
        .animation(.spring(response: 0.35), value: demo.showProfilingCard)
        .animation(.spring(response: 0.35), value: demo.showAdIncomingBadge)
        .animation(.spring(response: 0.5),  value: demo.showDemoSummary)
        .animation(.spring(response: 0.3),  value: showDebugHUD)
        .ignoresSafeArea()
        .onReceive(NotificationCenter.default.publisher(for: UIDevice.deviceDidShakeNotification)) { _ in
            withAnimation { showDebugHUD.toggle() }
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            Button {
                onDismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 36, height: 36)
                    .background(Color.black.opacity(0.5))
                    .clipShape(Circle())
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                HStack(spacing: 5) {
                    Circle().fill(Color.red).frame(width: 6, height: 6)
                    Text("LIVE")
                        .font(.system(size: 10, weight: .black))
                        .foregroundColor(.white)
                        .tracking(1.5)
                }
                Text(vm.channelName)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.85))
                    .lineLimit(1)
            }

            if demo.isRunning {
                HStack(spacing: 4) {
                    Circle().fill(Color.orange).frame(width: 6, height: 6)
                    Text("DEMO T+\(demo.elapsedSeconds)s")
                        .font(.system(size: 9, weight: .black))
                        .foregroundColor(.orange)
                        .tracking(0.8)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.orange.opacity(0.15))
                .clipShape(Capsule())
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 56)
        .padding(.bottom, 8)
    }
}

// MARK: - Ad Pod Progress Overlay (CSAI)

struct AdPodProgressOverlay: View {
    @ObservedObject var vm: PlayerViewModel

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Text("AD")
                    .font(.system(size: 10, weight: .black))
                    .foregroundColor(.black)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color(red: 1.0, green: 0.82, blue: 0.0))
                    .clipShape(RoundedRectangle(cornerRadius: 4))

                if let event = vm.currentBreakEvent {
                    Text(event.adSlot.advertiser)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                    Spacer()
                    Text("$\(String(format: "%.0f", event.adSlot.cpm)) CPM")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Color(red: 0.0, green: 0.82, blue: 0.60))
                } else {
                    Text("Ad break")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                    Spacer()
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            // Live pod progress bar driven by AdPodInserter's timer
            AdPodProgressBar(progress: podFraction)
        }
        .background(.ultraThinMaterial)
        .background(Color.black.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 16)
    }

    // Compute progress from AdPodInserter if available via vm.switchLatencyMs,
    // otherwise fall back to adBreakBanner style with no bar.
    private var podFraction: Double {
        guard let event = vm.currentBreakEvent else { return 0 }
        let elapsed = max(0, vm.switchLatencyMs / 1000)
        return min(elapsed / event.duration, 1.0)
    }
}

// MARK: - Thin progress bar

struct AdPodProgressBar: View {
    let progress: Double

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Rectangle().fill(Color.white.opacity(0.15))
                Rectangle()
                    .fill(LinearGradient(
                        colors: [Color(red: 1.0, green: 0.82, blue: 0.0),
                                 Color(red: 1.0, green: 0.55, blue: 0.0)],
                        startPoint: .leading,
                        endPoint: .trailing
                    ))
                    .frame(width: geo.size.width * max(0, min(progress, 1)))
                    .animation(.linear(duration: 0.5), value: progress)
            }
        }
        .frame(height: 3)
    }
}

// MARK: - PoD Verification Toast

struct PoDVerificationToast: View {
    let toast: PoDToastData
    @State private var showDetails = false

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                // Animated checkmark
                ZStack {
                    Circle()
                        .fill(Color(red: 0.0, green: 0.82, blue: 0.60).opacity(0.2))
                        .frame(width: 36, height: 36)
                    Image(systemName: "checkmark.shield.fill")
                        .font(.system(size: 18))
                        .foregroundColor(Color(red: 0.0, green: 0.82, blue: 0.60))
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text("Ad Verified")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                        if toast.isHardwareSigned {
                            Text("SE")
                                .font(.system(size: 9, weight: .black))
                                .foregroundColor(.black)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(Color(red: 0.0, green: 0.82, blue: 0.60))
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                        }
                    }
                    Text("+\(String(format: "%.4f", toast.cmxsEarned)) CMXS · \(Int(toast.latencyMs))ms")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.6))
                }

                Spacer()

                if toast.txHash != nil {
                    Button {
                        withAnimation { showDetails.toggle() }
                    } label: {
                        Image(systemName: "arrow.up.right.square")
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)

            if showDetails, let url = toast.basescanURL {
                Divider().background(Color.white.opacity(0.1))
                Link(destination: url) {
                    HStack(spacing: 6) {
                        Text("View on Basescan")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color(red: 0.0, green: 0.65, blue: 0.95))
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 10))
                            .foregroundColor(Color(red: 0.0, green: 0.65, blue: 0.95))
                        Spacer()
                        if let hash = toast.txHash {
                            Text(hash.prefix(12) + "...")
                                .font(.system(size: 9, design: .monospaced))
                                .foregroundColor(.white.opacity(0.3))
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                }
            }
        }
        .background(.ultraThinMaterial)
        .background(Color(white: 0.08).opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(red: 0.0, green: 0.82, blue: 0.60).opacity(0.3), lineWidth: 1)
        )
        .shadow(color: Color(red: 0.0, green: 0.82, blue: 0.60).opacity(0.15), radius: 12)
    }
}
