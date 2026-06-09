// PlayerView.swift — Arenza
// Split-screen sports game player:
//   Top 50%  — HLS video with scoreboard overlay + ad L-bar
//   Bottom 50% — Four game tabs: Bets, Bingo, Live Feed, Profile
//
// Video is served from Vercel: https://cmxs-arenza.vercel.app/streams/game.m3u8
// Presentation: .sheet with .fraction(1.0) — proven stable on real device.

import SwiftUI
import AVKit

struct PlayerView: View {
    let channel: Channel
    @EnvironmentObject var env: AppEnvironment
    @StateObject private var vm: PlayerViewModel
    @StateObject private var game = GameEngine()
    @Environment(\.dismiss) private var dismiss

    @State private var activeTab: GameTab = .bets

    enum GameTab: String, CaseIterable {
        case bets   = "🎯 Bets"
        case bingo  = "🎲 Bingo"
        case feed   = "🏆 Feed"
        case profile = "👤 Profile"
    }

    init(channel: Channel) {
        self.channel = channel
        self._vm = StateObject(wrappedValue: PlayerViewModel(channel: channel, env: .shared))
    }

    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                // ── TOP: Video Panel ─────────────────────────────────────────
                videoPanel
                    .frame(height: geo.size.height * 0.50)

                // ── BOTTOM: Game Tabs ────────────────────────────────────────
                gamePanel
                    .frame(height: geo.size.height * 0.50)
            }
        }
        .background(Color(hex: "#0d0f14"))
        .ignoresSafeArea(edges: .top)
        .preferredColorScheme(.dark)
        .task { await vm.startPlayback() }
        .onAppear { vm.player?.play(); game.start() }
        .onDisappear { vm.stop(); game.stop() }
    }

    // MARK: - Video Panel

    private var videoPanel: some View {
        ZStack(alignment: .bottom) {
            Color.black

            // Video
            if let player = vm.player {
                VideoPlayer(player: player)
                    .ignoresSafeArea(edges: .top)
                    .disabled(true) // disable native controls — we overlay our own
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

            // Ad L-bar overlay (bottom)
            if let ad = game.activeAd {
                adLBar(ad)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            // Points fly-up
            if let fly = game.flyText {
                Text(fly)
                    .font(.system(size: 32, weight: .black))
                    .foregroundColor(Color(hex: "#ffc107"))
                    .shadow(color: Color(hex: "#ffc107").opacity(0.6), radius: 12)
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity),
                        removal: .move(edge: .top).combined(with: .opacity)
                    ))
                    .id(fly)
            }
        }
        .animation(.spring(response: 0.4), value: game.activeAd?.id)
        .animation(.easeInOut(duration: 0.3), value: game.flyText)
        .clipped()
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
                    teamScoreView(emoji: "🦅", name: "EAGLES", score: game.homeScore, color: Color(hex: "#ff6b35"))
                    VStack(spacing: 0) {
                        Text("Q\(game.quarter)")
                            .font(.system(size: 10, weight: .black)).foregroundColor(.white.opacity(0.6))
                        Text(game.clockDisplay)
                            .font(.system(size: 14, weight: .black, design: .monospaced)).foregroundColor(.white)
                    }
                    teamScoreView(emoji: "🐻", name: "BEARS", score: game.awayScore, color: Color(hex: "#00c9b1"))
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
                .background(Color.black.opacity(0.55))
                .clipShape(Capsule())
            }
            .padding(.horizontal, 14)
            .padding(.top, 50) // safe area
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

    // MARK: - Ad L-Bar

    private func adLBar(_ ad: GameAdCreative) -> some View {
        HStack(spacing: 12) {
            Text(ad.emoji).font(.system(size: 24))
            VStack(alignment: .leading, spacing: 1) {
                Text("SPONSORED")
                    .font(.system(size: 8, weight: .black)).foregroundColor(.white.opacity(0.5)).tracking(1.2)
                Text("\(ad.brand) — \(ad.tagline)")
                    .font(.system(size: 13, weight: .bold)).foregroundColor(.white)
                Text("$\(ad.cpm) CPM · \(ad.targetSegment)")
                    .font(.system(size: 10)).foregroundColor(.white.opacity(0.6))
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text("✅ PoD Verified")
                    .font(.system(size: 10, weight: .semibold)).foregroundColor(Color(hex: "#22c55e"))
                // Timer bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2).fill(Color.white.opacity(0.15)).frame(height: 3)
                        RoundedRectangle(cornerRadius: 2).fill(ad.color)
                            .frame(width: geo.size.width * CGFloat(game.adTimerRemaining) / CGFloat(max(ad.durationSec, 1)), height: 3)
                            .animation(.linear(duration: 1), value: game.adTimerRemaining)
                    }
                }
                .frame(width: 80, height: 3)
            }
        }
        .padding(.horizontal, 14).padding(.vertical, 10)
        .background(LinearGradient(
            colors: [Color.black.opacity(0.92), Color.black.opacity(0.7)],
            startPoint: .bottom, endPoint: .top
        ))
        .overlay(Divider().background(ad.color.opacity(0.6)), alignment: .top)
    }

    // MARK: - Game Panel

    private var gamePanel: some View {
        VStack(spacing: 0) {
            // Tab bar
            tabBar

            // Tab content
            tabContent
        }
        .background(Color(hex: "#0d0f14"))
    }

    private var tabBar: some View {
        HStack(spacing: 0) {
            ForEach(GameTab.allCases, id: \.self) { tab in
                Button { withAnimation(.easeInOut(duration: 0.2)) { activeTab = tab } } label: {
                    VStack(spacing: 3) {
                        Text(tab.rawValue)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(activeTab == tab ? Color(hex: "#ff6b35") : Color(hex: "#8892b0"))
                        Rectangle()
                            .fill(activeTab == tab ? Color(hex: "#ff6b35") : Color.clear)
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
                    .foregroundColor(Color(hex: "#ffc107"))
            }
            .padding(.horizontal, 10)
        }
        .background(Color(hex: "#141720"))
        .overlay(Rectangle().fill(Color.white.opacity(0.08)).frame(height: 1), alignment: .top)
    }

    @ViewBuilder
    private var tabContent: some View {
        switch activeTab {
        case .bets:
            BetsTab(engine: game)
        case .bingo:
            BingoTab(engine: game)
        case .feed:
            LiveFeedTab(engine: game)
        case .profile:
            ProfileTab(engine: game)
        }
    }
}
