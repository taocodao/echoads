// PlayerView.swift — Arenza
// Full-screen player using the SAME pattern as VideoTestView (which works).
//
// KEY INSIGHT from diagnostic: VideoPlayer inside .sheet works perfectly.
// The failure is .fullScreenCover specifically. Solution: present via .sheet
// with .presentationDetents([.fraction(1.0)]) for true fullscreen appearance,
// using the exact VideoPlayer pattern proven to work.

import SwiftUI
import AVKit

struct PlayerView: View {
    let channel: Channel
    @EnvironmentObject var env: AppEnvironment
    @StateObject private var vm: PlayerViewModel
    @Environment(\.dismiss) private var dismiss
    @StateObject private var demo = DemoOrchestrator.shared
    @State private var showDebugHUD = false

    init(channel: Channel) {
        self.channel = channel
        self._vm = StateObject(wrappedValue: PlayerViewModel(channel: channel, env: .shared))
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            // ── VideoPlayer — same pattern as VideoTestView (proven to work) ──
            if let player = vm.player {
                VideoPlayer(player: player)
                    .ignoresSafeArea()
            }

            // ── Loading ────────────────────────────────────────────────────
            if vm.isLoading {
                VStack(spacing: 16) {
                    ProgressView().tint(.white).scaleEffect(1.3)
                    Text("Connecting...")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
            }

            // ── Error ──────────────────────────────────────────────────────
            if let error = vm.errorMessage {
                VStack(spacing: 12) {
                    Image(systemName: "wifi.slash").font(.system(size: 32)).foregroundColor(.orange)
                    Text(error).font(.system(size: 13)).foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center).padding(.horizontal, 32)
                }
            }

            // ── Overlays ───────────────────────────────────────────────────
            VStack {
                // Top bar
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 36, height: 36)
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        HStack(spacing: 4) {
                            Circle().fill(Color.red).frame(width: 6, height: 6)
                            Text("LIVE").font(.system(size: 10, weight: .black)).foregroundColor(.white).tracking(1.5)
                        }
                        Text(channel.name).font(.system(size: 12, weight: .semibold)).foregroundColor(.white.opacity(0.85))
                    }
                    if demo.isRunning {
                        Text("DEMO T+\(demo.elapsedSeconds)s")
                            .font(.system(size: 9, weight: .black)).foregroundColor(.orange)
                            .padding(.horizontal, 8).padding(.vertical, 4)
                            .background(Color.orange.opacity(0.15)).clipShape(Capsule())
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 56)

                Spacer()

                // Game overlays
                if vm.isInAdBreak {
                    AdPodProgressOverlay(vm: vm)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }

                if let toast = vm.podToast {
                    PoDVerificationToast(toast: toast)
                        .padding(.horizontal, 16).padding(.bottom, 16)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                if let question = vm.activePredictionQuestion {
                    PredictionOverlayView(engine: PredictionEngine.shared, question: question, onDismiss: {})
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                if let coupon = vm.couponUnlock {
                    RewardUnlockOverlayView(coupon: coupon, onRedeem: { vm.couponUnlock = nil }, onDismiss: { vm.couponUnlock = nil })
                        .transition(.scale.combined(with: .opacity))
                }

                if let poll = PollEngine.shared.activePoll, vm.activePredictionQuestion == nil, !vm.isInAdBreak {
                    PollOverlayView(engine: PollEngine.shared, poll: poll, onDismiss: {})
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                if TriviaEngine.shared.activeSession != nil, vm.activePredictionQuestion == nil, PollEngine.shared.activePoll == nil, !vm.isInAdBreak {
                    TriviaOverlayView(engine: TriviaEngine.shared, onDismiss: {})
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                if let bettingCtx = vm.bettingOverlay, vm.activePredictionQuestion == nil {
                    BetSlipOverlayView(context: bettingCtx) { withAnimation { vm.bettingOverlay = nil } }
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                if demo.isRunning && !demo.stepNarration.isEmpty {
                    DemoNarrationBar(narration: demo.stepNarration, step: demo.currentStep, elapsed: demo.elapsedSeconds)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }

            // Demo full-screen ad card
            if vm.isInAdBreak, let creative = vm.adPodInserter.activeCreative {
                DemoAdCardView(
                    creative: creative,
                    podProgress: vm.adPodInserter.podProgress,
                    podDurationRemaining: vm.adPodInserter.podDurationRemaining,
                    currentSegment: ProfileEngine.shared.currentSegment.label
                )
                .ignoresSafeArea().transition(.opacity).zIndex(50)
            }

            // Demo profiling card
            if demo.showProfilingCard {
                VStack { Spacer().frame(height: 80); ViewerProfilingCard(); Spacer() }
                    .transition(.move(edge: .top).combined(with: .opacity)).zIndex(30)
            }

            // Ad incoming badge
            if demo.showAdIncomingBadge {
                VStack { Spacer().frame(height: 70); HStack { Spacer(); AdIncomingBadge(); Spacer() }; Spacer() }
                    .transition(.move(edge: .top).combined(with: .opacity)).zIndex(31)
            }

            // Debug HUD
            if showDebugHUD {
                VStack { Spacer(); TargetingDebugHUD().padding(.bottom, 100) }
                    .transition(.opacity).zIndex(55)
            }

            // Demo summary
            if demo.showDemoSummary {
                Color.black.opacity(0.6).ignoresSafeArea().zIndex(59)
                VStack {
                    Spacer()
                    DemoSummaryCard(aztEarned: demo.totalAZTEarned, revenueGenerated: demo.revenueGenerated) {
                        demo.stop(); demo.start(for: vm)
                    }
                    Spacer()
                }
                .transition(.scale.combined(with: .opacity)).zIndex(60)
            }
        }
        .animation(.spring(response: 0.35), value: vm.isInAdBreak)
        .animation(.spring(response: 0.35), value: vm.activePredictionQuestion != nil)
        .animation(.spring(response: 0.35), value: demo.showProfilingCard)
        .animation(.spring(response: 0.35), value: demo.showAdIncomingBadge)
        .animation(.spring(response: 0.5),  value: demo.showDemoSummary)
        .task { await vm.startPlayback() }
        .onAppear {
            vm.player?.play()
            demo.start(for: vm)
        }
        .onDisappear { vm.stop(); demo.stop() }
        .onReceive(NotificationCenter.default.publisher(for: UIDevice.deviceDidShakeNotification)) { _ in
            withAnimation { showDebugHUD.toggle() }
        }
        .ignoresSafeArea()
        .preferredColorScheme(.dark)
    }
}
