// PlayerView.swift — Arenza
// Full-screen video player with SGAI, prediction, and betting overlays.

import SwiftUI
import AVKit

struct PlayerView: View {
    let channel: Channel
    @EnvironmentObject var env: AppEnvironment
    @StateObject private var vm: PlayerViewModel
    @Environment(\.dismiss) private var dismiss

    init(channel: Channel) {
        self.channel = channel
        self._vm = StateObject(wrappedValue: PlayerViewModel(channel: channel, env: .shared))
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            // ── Video Player ─────────────────────────────────────────────
            if let player = vm.player {
                VideoPlayerWrapper(player: player)
                    .ignoresSafeArea()
            }

            // ── Loading Overlay ──────────────────────────────────────────
            if vm.isLoading {
                loadingOverlay
            }

            // ── Error Overlay ────────────────────────────────────────────
            if let error = vm.errorMessage {
                errorOverlay(message: error)
            }

            // ── Top Controls ─────────────────────────────────────────────
            VStack {
                topBar
                Spacer()

                // ── Ad Break Indicator ───────────────────────────────────
                if vm.isInAdBreak {
                    adBreakBanner
                        .transition(.move(edge: .top).combined(with: .opacity))
                }

                Spacer()

                // ── PoD Verification Toast ───────────────────────────────
                if let toast = vm.podToast {
                    PoDVerificationToast(toast: toast)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 100)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                // ── SGAI Shoppable Overlay ───────────────────────────────
                if let overlay = vm.sgaiOverlay {
                    SGAIShoppableCard(data: overlay) {
                        withAnimation { vm.sgaiOverlay = nil }
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                // ── Prediction Overlay (C4) ────────────────────────────
                if let question = vm.activePredictionQuestion {
                    PredictionOverlayView(
                        engine: PredictionEngine.shared,
                        question: question,
                        onDismiss: {}
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(10)
                }

                // ── Coupon Unlock Notification (C5) ───────────────────
                if let coupon = vm.couponUnlock {
                    RewardUnlockOverlayView(
                        coupon: coupon,
                        onRedeem: { vm.couponUnlock = nil },
                        onDismiss: { vm.couponUnlock = nil }
                    )
                    .transition(.scale.combined(with: .opacity))
                    .zIndex(20)
                }

                // ── Betting Overlay (C6) ──────────────────────────────
                if let bettingCtx = vm.bettingOverlay,
                   vm.activePredictionQuestion == nil {   // Never stack with predictions
                    BetSlipOverlayView(context: bettingCtx) {
                        withAnimation { vm.bettingOverlay = nil }
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(5)
                }
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: vm.isInAdBreak)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: vm.podToast != nil)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: vm.sgaiOverlay != nil)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: vm.activePredictionQuestion != nil)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: vm.bettingOverlay != nil)
        .task { await vm.startPlayback() }
        .onDisappear { vm.stop() }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            Button {
                vm.stop()
                dismiss()
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
                Text(channel.name)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.85))
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    // MARK: - Ad Break Banner

    private var adBreakBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "play.rectangle.fill")
                .foregroundColor(Color(red: 0.0, green: 0.82, blue: 0.60))
                .font(.system(size: 14))
            Text("Ad break")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white)
            Spacer()
            if let event = vm.currentBreakEvent {
                Text(event.adSlot.advertiser)
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.6))
                Text("· $\(String(format: "%.0f", event.adSlot.cpm)) CPM")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Color(red: 0.0, green: 0.82, blue: 0.60))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
        .background(Color.black.opacity(0.4))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 16)
    }

    // MARK: - Loading

    private var loadingOverlay: some View {
        VStack(spacing: 16) {
            ProgressView()
                .tint(.white)
                .scaleEffect(1.3)
            Text("Connecting to stream...")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
            if env.isBackendReachable {
                Text("Running auction...")
                    .font(.system(size: 11))
                    .foregroundColor(Color(red: 0.0, green: 0.82, blue: 0.60))
            }
        }
    }

    // MARK: - Error

    private func errorOverlay(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 36))
                .foregroundColor(.white.opacity(0.4))
            Text("Could not load stream")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
            Text(message)
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.5))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button("Try Again") {
                Task { await vm.startPlayback() }
            }
            .foregroundColor(Color(red: 0.0, green: 0.82, blue: 0.60))
            .font(.system(size: 14, weight: .semibold))
            .padding(.top, 4)
        }
    }
}

// MARK: - AVPlayer UIKit Wrapper

struct VideoPlayerWrapper: UIViewControllerRepresentable {
    let player: AVPlayer

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let vc = AVPlayerViewController()
        vc.player = player
        vc.showsPlaybackControls = true
        vc.videoGravity = .resizeAspect
        return vc
    }

    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        uiViewController.player = player
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
