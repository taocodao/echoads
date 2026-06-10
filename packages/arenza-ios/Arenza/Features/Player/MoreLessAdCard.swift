// MoreLessAdCard.swift — Arenza
// Ad Format 4: More or Less Player Props (PrizePicks-style)
// Sponsored by Gatorade — binary picks on player stats with multipliers.
// Free-to-play with Arenza points. Pick 2+ for a multiplier.

import SwiftUI

struct MoreLessAdCard: View {
    @ObservedObject var engine: GameEngine
    @ObservedObject var adEngine: InteractiveAdEngine

    var body: some View {
        VStack(spacing: 0) {
            moreLessHeader
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 8) {
                    // Subtitle
                    HStack {
                        Text("Pick 2+ for bonus pts · Free to play")
                            .font(.system(size: 10))
                            .foregroundColor(Color(arenza: "#8892b0"))
                        Spacer()
                        multiplierBadge
                    }
                    .padding(.horizontal, 12)

                    // Player cards
                    playerGrid

                    // Footer bar
                    moreLessFooter
                }
                .padding(.vertical, 10)
            }
        }
        .background(Color(arenza: "#0d0f14"))
    }

    // MARK: - Header

    private var moreLessHeader: some View {
        HStack(spacing: 8) {
            HStack(spacing: 4) {
                Text("📊")
                Text("MORE OR LESS")
                    .font(.system(size: 10, weight: .black))
                    .foregroundColor(Color(arenza: "#22c55e"))
                    .tracking(0.8)
            }
            Spacer()
            HStack(spacing: 4) {
                Text("💪")
                Text("Gatorade")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(Color(arenza: "#22c55e"))
                Text("Player Challenge")
                    .font(.system(size: 10))
                    .foregroundColor(Color(arenza: "#8892b0"))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(
            LinearGradient(
                colors: [Color(arenza: "#001a08"), Color(arenza: "#0d0f14")],
                startPoint: .leading, endPoint: .trailing
            )
        )
        .overlay(Rectangle().fill(Color.white.opacity(0.06)).frame(height: 1), alignment: .bottom)
    }

    // MARK: - Multiplier Badge

    private var multiplierBadge: some View {
        Group {
            if adEngine.mlPicks.count >= 2 {
                HStack(spacing: 4) {
                    Text("\(adEngine.mlPicks.count) picks")
                        .font(.system(size: 10))
                        .foregroundColor(Color(arenza: "#8892b0"))
                    Text("×\(String(format: "%.1f", adEngine.mlMultiplier))")
                        .font(.system(size: 11, weight: .black))
                        .foregroundColor(Color(arenza: "#22c55e"))
                }
                .padding(.horizontal, 8).padding(.vertical, 3)
                .background(Color(arenza: "#22c55e").opacity(0.1))
                .clipShape(Capsule())
                .overlay(Capsule().stroke(Color(arenza: "#22c55e").opacity(0.3), lineWidth: 1))
                .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.3), value: adEngine.mlPicks.count)
    }

    // MARK: - Player Grid (2-column)

    private var playerGrid: some View {
        LazyVGrid(
            columns: [GridItem(.flexible(), spacing: 6), GridItem(.flexible(), spacing: 6)],
            spacing: 6
        ) {
            ForEach(adEngine.mlPlayers) { player in
                MLPlayerCardView(
                    player: player,
                    pick: adEngine.mlPicks[player.id],
                    isSubmitted: adEngine.mlSubmitted
                ) { direction in
                    adEngine.pickML(playerIndex: player.id, direction: direction, gameEngine: engine)
                }
            }
        }
        .padding(.horizontal, 10)
    }

    // MARK: - Footer

    private var moreLessFooter: some View {
        VStack(spacing: 8) {
            if let msg = adEngine.mlResultMessage {
                Text(msg)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Color(arenza: "#22c55e"))
                    .multilineTextAlignment(.center)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .animation(.spring(response: 0.3), value: adEngine.mlResultMessage != nil)
            }

            HStack {
                VStack(alignment: .leading, spacing: 1) {
                    Text("Picks: \(adEngine.mlPicks.count) / 4")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Color(arenza: "#8892b0"))
                    if adEngine.mlMaxWin > 0 {
                        Text("All correct = +\(adEngine.mlMaxWin) pts")
                            .font(.system(size: 10))
                            .foregroundColor(Color(arenza: "#22c55e"))
                    }
                }
                Spacer()
                Button {
                    adEngine.submitMLEntry(gameEngine: engine)
                } label: {
                    Text(adEngine.mlSubmitted ? "✅ Submitted!" : "Submit Entry")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(adEngine.mlSubmitted ? Color(arenza: "#22c55e") : Color(arenza: "#0d0f14"))
                        .padding(.horizontal, 16).padding(.vertical, 8)
                        .background(
                            adEngine.mlSubmitted ? Color(arenza: "#22c55e").opacity(0.2) : Color(arenza: "#22c55e")
                        )
                        .clipShape(Capsule())
                }
                .disabled(adEngine.mlPicks.count < 2 || adEngine.mlSubmitted)
                .buttonStyle(.plain)
                .animation(.spring(response: 0.25), value: adEngine.mlSubmitted)
            }
            .padding(.horizontal, 12)

            // Mini leaderboard
            miniLeaderboard
        }
    }

    // MARK: - Mini Leaderboard

    private var miniLeaderboard: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("🏆 TONIGHT'S LEADERBOARD")
                    .font(.system(size: 9, weight: .black))
                    .foregroundColor(Color(arenza: "#4a5568"))
                    .tracking(0.8)
                Spacer()
            }
            .padding(.horizontal, 12)

            ForEach([
                (1, "SportsKing99", 4200, false, "🥇"),
                (2, "You", engine.points, true, "🥈"),
                (3, "FastBreak22", 980, false, "🥉"),
            ], id: \.0) { rank, name, pts, isYou, medal in
                HStack(spacing: 8) {
                    Text(medal).font(.system(size: 12))
                    Text(name)
                        .font(.system(size: 11, weight: isYou ? .black : .semibold))
                        .foregroundColor(isYou ? Color(arenza: "#22c55e") : Color(arenza: "#f0f2ff"))
                    if isYou {
                        Text("YOU")
                            .font(.system(size: 8, weight: .black))
                            .foregroundColor(Color(arenza: "#22c55e"))
                            .padding(.horizontal, 5).padding(.vertical, 1)
                            .background(Color(arenza: "#22c55e").opacity(0.15))
                            .clipShape(Capsule())
                    }
                    Spacer()
                    Text("\(pts.formatted())")
                        .font(.system(size: 12, weight: .black, design: .monospaced))
                        .foregroundColor(Color(arenza: "#22c55e"))
                }
                .padding(.horizontal, 12).padding(.vertical, 3)
            }
        }
        .padding(.vertical, 6)
        .background(Color(arenza: "#141720").opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal, 10)
    }
}

// MARK: - ML Player Card View

struct MLPlayerCardView: View {
    let player: MLPlayerCard
    let pick: PickDirection?
    let isSubmitted: Bool
    let onPick: (PickDirection) -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Player info
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(Color(arenza: "#1a1e2a"))
                        .frame(width: 36, height: 36)
                    Text(player.emoji)
                        .font(.system(size: 18))
                }
                VStack(alignment: .leading, spacing: 1) {
                    Text(player.name)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Color(arenza: "#f0f2ff"))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Text(player.team)
                        .font(.system(size: 9))
                        .foregroundColor(Color(arenza: "#8892b0"))
                }
                Spacer()
            }
            .padding(.horizontal, 8).padding(.top, 8).padding(.bottom, 6)
            .background(Color(arenza: "#1a1e2a"))

            Divider().background(Color.white.opacity(0.06))

            // Stat line
            VStack(spacing: 2) {
                Text(player.stat.uppercased())
                    .font(.system(size: 8, weight: .black))
                    .foregroundColor(Color(arenza: "#4a5568"))
                    .tracking(0.8)
                Text(String(format: "%.1f", player.line))
                    .font(.system(size: 22, weight: .black, design: .monospaced))
                    .foregroundColor(Color(arenza: "#22c55e"))
                Text(player.description)
                    .font(.system(size: 9))
                    .foregroundColor(Color(arenza: "#8892b0"))
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .padding(.horizontal, 6).padding(.vertical, 6)
            .frame(maxWidth: .infinity)

            // More / Less buttons
            HStack(spacing: 4) {
                mlButton(direction: .more, label: "↑ MORE", color: Color(arenza: "#22c55e"))
                mlButton(direction: .less, label: "↓ LESS", color: Color(arenza: "#ef4444"))
            }
            .padding(.horizontal, 6).padding(.bottom, 8)
        }
        .background(Color(arenza: "#141720"))
        .clipShape(RoundedRectangle(cornerRadius: 11))
        .overlay(
            RoundedRectangle(cornerRadius: 11).stroke(
                pick != nil ? (pick == .more ? Color(arenza: "#22c55e") : Color(arenza: "#ef4444")).opacity(0.4) : Color.white.opacity(0.07),
                lineWidth: 1
            )
        )
        .scaleEffect(pick != nil ? 1.02 : 1.0)
        .animation(.spring(response: 0.25), value: pick)
    }

    private func mlButton(direction: PickDirection, label: String, color: Color) -> some View {
        let isPicked = pick == direction
        return Button {
            onPick(direction)
        } label: {
            Text(label)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(isPicked ? color : Color(arenza: "#8892b0"))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 7)
                .background(isPicked ? color.opacity(0.15) : Color(arenza: "#1a1e2a"))
                .clipShape(RoundedRectangle(cornerRadius: 7))
                .overlay(RoundedRectangle(cornerRadius: 7).stroke(isPicked ? color.opacity(0.5) : Color.white.opacity(0.07), lineWidth: 1))
        }
        .disabled(isSubmitted)
        .buttonStyle(.plain)
        .animation(.spring(response: 0.2), value: isPicked)
    }
}
