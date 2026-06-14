// ScoreTab.swift — Arenza (ArenzaTV Prototype)
// Live scoreboard + play-by-play tab for the split-screen companion panel.
// Shows the current score, quarter/clock, and a scrolling list of recent plays.
// Driven by the GameEngine's feed and scoreboard state.

import SwiftUI

// MARK: - Design Tokens (shared palette)

private enum S {
    static let bg       = Color(arenza: "#0d0f14")
    static let surface  = Color(arenza: "#141720")
    static let surface2 = Color(arenza: "#1a1e2a")
    static let border   = Color.white.opacity(0.08)
    static let text     = Color(arenza: "#f0f2ff")
    static let muted    = Color(arenza: "#8892b0")
    static let faint    = Color(arenza: "#4a5568")
    static let orange   = Color(arenza: "#ff6b35")
    static let teal     = Color(arenza: "#00c9b1")
    static let gold     = Color(arenza: "#ffc107")
    static let green    = Color(arenza: "#22c55e")
    static let red      = Color(arenza: "#ef4444")
}

// MARK: - Score Tab

struct ScoreTab: View {
    @ObservedObject var engine: GameEngine

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                // Live scoreboard
                scoreboardCard

                // Score chart (visual timeline)
                scoreTimelineBar

                // Recent plays (live feed filtered to game events only)
                playByPlaySection
            }
            .padding(12)
        }
    }

    // MARK: - Scoreboard Card

    private var scoreboardCard: some View {
        VStack(spacing: 0) {
            // Game header
            HStack(spacing: 6) {
                HStack(spacing: 4) {
                    Circle().fill(S.red).frame(width: 6, height: 6)
                    Text("LIVE")
                        .font(.system(size: 9, weight: .black))
                        .foregroundColor(S.red)
                        .tracking(1.5)
                }
                Spacer()
                Text("Q\(engine.quarter) · \(engine.clockDisplay)")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(S.muted)
                Spacer()
                Text("NFL · Week 11")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(S.faint)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(S.surface)

            Divider().background(S.border)

            // Teams + scores
            HStack(spacing: 0) {
                // Home team
                VStack(spacing: 4) {
                    Text("🦅").font(.system(size: 28))
                    Text("Eagles")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(S.text)
                    Text("PHI · 8-2")
                        .font(.system(size: 9))
                        .foregroundColor(S.faint)
                }
                .frame(maxWidth: .infinity)

                // Score display
                VStack(spacing: 4) {
                    HStack(spacing: 12) {
                        Text("\(engine.homeScore)")
                            .font(.system(size: 36, weight: .black, design: .monospaced))
                            .foregroundColor(S.orange)
                        Text("—")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(S.faint)
                        Text("\(engine.awayScore)")
                            .font(.system(size: 36, weight: .black, design: .monospaced))
                            .foregroundColor(S.teal)
                    }
                    if engine.homeScore > engine.awayScore {
                        Text("Eagles lead by \(engine.homeScore - engine.awayScore)")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundColor(S.green)
                    } else if engine.awayScore > engine.homeScore {
                        Text("Bears lead by \(engine.awayScore - engine.homeScore)")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundColor(S.red)
                    } else {
                        Text("Tied")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundColor(S.gold)
                    }
                }

                // Away team
                VStack(spacing: 4) {
                    Text("🐻").font(.system(size: 28))
                    Text("Bears")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(S.text)
                    Text("CHI · 4-6")
                        .font(.system(size: 9))
                        .foregroundColor(S.faint)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.vertical, 14)
        }
        .background(S.surface2)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(S.border, lineWidth: 1))
    }

    // MARK: - Score Timeline Bar

    private var scoreTimelineBar: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("SCORING SUMMARY")
                .font(.system(size: 9, weight: .black))
                .foregroundColor(S.faint)
                .tracking(1.2)

            // Quarter boxes
            HStack(spacing: 6) {
                quarterBox("Q1", home: "7", away: "3")
                quarterBox("Q2", home: "7", away: "7")
                quarterBox(engine.quarter >= 4 ? "Q3" : "Q3 ▸",
                           home: "\(engine.homeScore - 14)",
                           away: "\(engine.awayScore - 10)",
                           isActive: engine.quarter == 3)
                if engine.quarter >= 4 {
                    quarterBox("Q4 ▸", home: "—", away: "—", isActive: true)
                }
            }
        }
        .padding(10)
        .background(S.surface2)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(S.border))
    }

    private func quarterBox(_ label: String, home: String, away: String, isActive: Bool = false) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.system(size: 9, weight: .black))
                .foregroundColor(isActive ? S.gold : S.faint)
            HStack(spacing: 6) {
                Text(home)
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(S.orange)
                Text("-")
                    .font(.system(size: 9))
                    .foregroundColor(S.faint)
                Text(away)
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(S.teal)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(isActive ? S.gold.opacity(0.08) : S.surface)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isActive ? S.gold.opacity(0.3) : S.border, lineWidth: 1)
        )
    }

    // MARK: - Play-by-Play Section

    private var playByPlaySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("PLAY-BY-PLAY")
                    .font(.system(size: 9, weight: .black))
                    .foregroundColor(S.faint)
                    .tracking(1.2)
                Spacer()
                Text("\(engine.feed.filter { $0.type == .game }.count) plays")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(S.muted)
            }

            let gamePlays = engine.feed.filter { $0.type == .game }
            if gamePlays.isEmpty {
                VStack(spacing: 6) {
                    Text("⏳").font(.system(size: 20))
                    Text("Waiting for plays...")
                        .font(.system(size: 11))
                        .foregroundColor(S.faint)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
            } else {
                ForEach(gamePlays) { play in
                    HStack(alignment: .top, spacing: 8) {
                        Text(play.emoji).font(.system(size: 14))

                        VStack(alignment: .leading, spacing: 2) {
                            Text(play.text)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(S.text)
                                .fixedSize(horizontal: false, vertical: true)
                            if let detail = play.detail {
                                Text(detail)
                                    .font(.system(size: 9))
                                    .foregroundColor(S.muted)
                            }
                        }
                        Spacer()
                        Text(play.timestamp, style: .time)
                            .font(.system(size: 8, design: .monospaced))
                            .foregroundColor(S.faint)
                    }
                    .padding(8)
                    .background(
                        play.text.contains("TOUCHDOWN") || play.text.contains("FINAL")
                            ? S.orange.opacity(0.08) : S.surface
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8).stroke(
                            play.text.contains("TOUCHDOWN") ? S.orange.opacity(0.25) : S.border,
                            lineWidth: 1
                        )
                    )
                }
            }

            // Live chat section
            chatSection
        }
    }

    // MARK: - Chat Section

    private var chatSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("FAN CHAT")
                .font(.system(size: 9, weight: .black))
                .foregroundColor(S.faint)
                .tracking(1.2)
                .padding(.top, 4)

            if engine.chatMessages.isEmpty {
                Text("💬 Chat will appear during the game...")
                    .font(.system(size: 10))
                    .foregroundColor(S.faint)
                    .padding(.vertical, 8)
            } else {
                ForEach(engine.chatMessages.suffix(6), id: \.text) { msg in
                    HStack(alignment: .top, spacing: 6) {
                        Text(msg.user)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(S.teal)
                        Text(msg.text)
                            .font(.system(size: 10))
                            .foregroundColor(S.text)
                    }
                }
            }
        }
        .padding(10)
        .background(S.surface2)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(S.border))
    }
}
