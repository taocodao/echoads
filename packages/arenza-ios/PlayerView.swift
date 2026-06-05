// PlayerView.swift
// Full-screen live video player with:
//   • MoQ stream via Caton WebTransport (or HLS fallback)
//   • SGAI overlay at T+20s of each ad break
//   • PoD receipt display after ad completes

import SwiftUI
import AVKit

struct PlayerView: View {
    let channelId: String
    @StateObject private var vm: PlayerViewModel
    @Environment(\.dismiss) var dismiss

    init(channelId: String) {
        self.channelId = channelId
        _vm = StateObject(wrappedValue: PlayerViewModel(channelId: channelId))
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            // ── Video Player ───────────────────────────────────────────────
            if let player = vm.player {
                VideoPlayer(player: player)
                    .ignoresSafeArea()
            } else {
                loadingView
            }

            // ── Status HUD (top) ───────────────────────────────────────────
            VStack {
                HStack {
                    // Back button
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.left")
                            .font(.title3.bold())
                            .foregroundColor(.white)
                            .padding(12)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                    Spacer()

                    // MoQ latency badge
                    if let latency = vm.latencyMs {
                        Label("\(latency)ms", systemImage: "bolt.fill")
                            .font(.caption.bold())
                            .foregroundColor(.green)
                            .padding(.horizontal, 10).padding(.vertical, 6)
                            .background(.ultraThinMaterial)
                            .clipShape(Capsule())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 54)    // below notch

                Spacer()
            }

            // ── SGAI Overlay (bottom) ──────────────────────────────────────
            if vm.showSGAIOverlay, let overlay = vm.currentOverlay {
                VStack {
                    Spacer()
                    SGAIOverlayCard(overlay: overlay) {
                        vm.dismissOverlay()
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .padding(.bottom, 100)
                }
            }

            // ── PoD Receipt Toast (top-right) ──────────────────────────────
            if vm.showPoDReceipt, let pod = vm.lastPoD {
                VStack {
                    HStack {
                        Spacer()
                        PoDReceiptBadge(pod: pod)
                            .transition(.scale.combined(with: .opacity))
                            .padding(.top, 54)
                            .padding(.trailing, 20)
                    }
                    Spacer()
                }
            }

            // ── Ad Break Timer bar ─────────────────────────────────────────
            if vm.adBreakActive {
                VStack {
                    Spacer()
                    AdBreakProgressBar(progress: vm.adProgress)
                }
            }
        }
        .ignoresSafeArea()
        .navigationBarHidden(true)
        .statusBarHidden(true)
        .task { await vm.startPlayback() }
        .animation(.easeInOut(duration: 0.3), value: vm.showSGAIOverlay)
        .animation(.easeInOut(duration: 0.4), value: vm.showPoDReceipt)
    }

    // ── Loading placeholder ──────────────────────────────────────────────────
    var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(.indigo)
            Text("Connecting via MoQ…")
                .font(.subheadline)
                .foregroundColor(.gray)
            Text(Constants.moqStreamURL)
                .font(.caption2)
                .foregroundColor(Color(hex: "334155"))
                .padding(.horizontal, 32)
                .multilineTextAlignment(.center)
        }
    }
}

// ── SGAI Overlay Card ─────────────────────────────────────────────────────────
struct SGAIOverlayCard: View {
    let overlay: SGAIOverlay
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            // Product icon
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.indigo.opacity(0.2))
                    .frame(width: 56, height: 56)
                Text(overlay.emoji)
                    .font(.system(size: 28))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(overlay.productName)
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                Text(overlay.priceFormatted)
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            Spacer()

            Button {
                onDismiss()
            } label: {
                Text("More Info")
                    .font(.caption.bold())
                    .foregroundColor(.white)
                    .padding(.horizontal, 14).padding(.vertical, 8)
                    .background(Color.indigo)
                    .clipShape(Capsule())
            }
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color.indigo.opacity(0.4))
        )
        .padding(.horizontal, 20)
    }
}

// ── PoD Receipt Badge ─────────────────────────────────────────────────────────
struct PoDReceiptBadge: View {
    let pod: PoDReceipt

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("On-Chain PoD Minted", systemImage: "checkmark.seal.fill")
                .font(.caption.bold())
                .foregroundColor(.green)
            Text("CPM: \(String(format: "$%.2f", pod.cpm))")
                .font(.caption)
                .foregroundColor(.white)
            Text("Tx: \(pod.txHash.prefix(10))…")
                .font(.caption2)
                .foregroundColor(.gray)
                .fontDesign(.monospaced)
        }
        .padding(12)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.green.opacity(0.4))
        )
    }
}

// ── Ad Break Progress Bar ─────────────────────────────────────────────────────
struct AdBreakProgressBar: View {
    let progress: Double  // 0…1

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Rectangle().fill(Color.white.opacity(0.08))
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.indigo, .purple, .cyan],
                            startPoint: .leading, endPoint: .trailing
                        )
                    )
                    .frame(width: geo.size.width * progress)
                    .animation(.linear(duration: 0.1), value: progress)
            }
        }
        .frame(height: 3)
    }
}
