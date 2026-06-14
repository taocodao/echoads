// GamesTab.swift — Arenza (ArenzaTV Prototype)
// Unified "Games" tab for the split-screen companion panel.
// Shows all active game formats: Team Trivia, Sponsor Quiz, and
// links to Bingo and Predictions. This is the main engagement hub.

import SwiftUI

// MARK: - Design Tokens (shared with GameTabViews)

private enum GT {
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
    static let purple   = Color(arenza: "#7c3aed")
}

// MARK: - Games Tab

struct GamesTab: View {
    @ObservedObject var gameEngine: GameEngine
    @ObservedObject var triviaEngine: TriviaEngine = .shared
    @ObservedObject var sponsorQuizEngine: SponsorQuizEngine = .shared

    /// The sport of the current match (drives bingo labels + trivia packs)
    let sport: String
    let homeTeamId: String
    let awayTeamId: String

    @State private var showTeamTrivia = false
    @State private var selectedPack: TriviaQuestionPack?

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                // Active game overlays (take priority)
                if sponsorQuizEngine.activeSession != nil {
                    SponsorQuizOverlayView(engine: sponsorQuizEngine)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                if triviaEngine.activeSession != nil {
                    activeTriviaCard
                }

                // Points banner
                pointsBanner

                // Game format cards
                availableGamesSection

                // Available trivia packs
                triviaPacksSection
            }
            .padding(12)
        }
        .animation(.spring(response: 0.4), value: sponsorQuizEngine.activeSession?.id)
        .animation(.spring(response: 0.4), value: triviaEngine.activeSession?.id)
    }

    // MARK: - Points Banner

    private var pointsBanner: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("YOUR POINTS")
                    .font(.system(size: 9, weight: .black))
                    .foregroundColor(GT.faint)
                    .tracking(1)
                Text("\(gameEngine.points.formatted())")
                    .font(.system(size: 22, weight: .black, design: .monospaced))
                    .foregroundColor(GT.gold)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("≈ $\(String(format: "%.2f", Double(gameEngine.points) / 200.0)) value")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(GT.muted)
                Text("🔥 Keep playing to earn more!")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(GT.teal)
            }
        }
        .padding(12)
        .background(GT.gold.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(GT.gold.opacity(0.25), lineWidth: 1))
    }

    // MARK: - Available Games Section

    private var availableGamesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("PLAY & EARN")
                .font(.system(size: 10, weight: .black))
                .foregroundColor(GT.faint)
                .tracking(1.2)

            LazyVGrid(columns: [.init(.flexible(), spacing: 8), .init(.flexible(), spacing: 8)], spacing: 8) {
                gameFormatCard(
                    emoji: "🏆",
                    title: "Team Trivia",
                    subtitle: "History & stats",
                    reward: "+10–50 AZT",
                    color: GT.orange,
                    action: { showTeamTrivia = true }
                )

                gameFormatCard(
                    emoji: "🔮",
                    title: "Predictions",
                    subtitle: "Next play outcome",
                    reward: "+75–250 AZT",
                    color: GT.teal,
                    isActive: gameEngine.activePrediction != nil,
                    action: {} // handled by BetsTab
                )

                gameFormatCard(
                    emoji: "🎯",
                    title: "Live Bingo",
                    subtitle: "\(sport) events",
                    reward: "+25–500 AZT",
                    color: GT.purple,
                    action: {} // handled by BingoTab
                )

                gameFormatCard(
                    emoji: "🏢",
                    title: "Sponsor Quiz",
                    subtitle: "Learn & earn",
                    reward: "+15 AZT each",
                    color: GT.green,
                    action: {} // triggered by MatchSim
                )
            }
        }
    }

    private func gameFormatCard(
        emoji: String, title: String, subtitle: String,
        reward: String, color: Color, isActive: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Text(emoji).font(.system(size: 24))
                Text(title)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(GT.text)
                Text(subtitle)
                    .font(.system(size: 9))
                    .foregroundColor(GT.muted)
                Text(reward)
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(GT.gold)
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(GT.gold.opacity(0.1))
                    .clipShape(Capsule())
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isActive ? color.opacity(0.12) : GT.surface2)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12).stroke(
                    isActive ? color.opacity(0.5) : GT.border, lineWidth: 1
                )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Trivia Packs Section

    private var triviaPacksSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("TRIVIA PACKS")
                .font(.system(size: 10, weight: .black))
                .foregroundColor(GT.faint)
                .tracking(1.2)

            let packs = TriviaQuestionPack.packsForMatch(
                homeTeamId: homeTeamId,
                awayTeamId: awayTeamId
            )

            ForEach(packs) { pack in
                Button {
                    startTriviaPack(pack)
                } label: {
                    HStack(spacing: 10) {
                        Text(pack.category.emoji).font(.system(size: 18))

                        VStack(alignment: .leading, spacing: 2) {
                            Text(pack.title)
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(GT.text)
                            if let sub = pack.subtitle {
                                Text(sub)
                                    .font(.system(size: 10))
                                    .foregroundColor(GT.muted)
                            }
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 2) {
                            Text("\(pack.sessionSize) Q's")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(GT.teal)
                            if let sponsor = pack.sponsorName {
                                Text("by \(sponsor)")
                                    .font(.system(size: 9))
                                    .foregroundColor(GT.faint)
                            }
                        }

                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 18))
                            .foregroundColor(pack.category == .sponsorBusiness ? GT.green : GT.orange)
                    }
                    .padding(10)
                    .background(GT.surface2)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(GT.border))
                }
                .buttonStyle(.plain)
                .disabled(triviaEngine.activeSession != nil)
            }
        }
    }

    // MARK: - Active Trivia Card (inline summary)

    private var activeTriviaCard: some View {
        Group {
            if let session = triviaEngine.activeSession {
                VStack(spacing: 8) {
                    HStack {
                        Text("🏆 Trivia in Progress")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(GT.text)
                        Spacer()
                        Text("\(session.currentIndex)/\(session.questions.count)")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(GT.muted)
                    }
                    HStack {
                        Text("✅ \(session.correctCount) correct")
                            .font(.system(size: 10))
                            .foregroundColor(GT.teal)
                        Spacer()
                        Text("+\(session.totalAZTEarned) AZT")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(GT.gold)
                    }
                }
                .padding(10)
                .background(GT.orange.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(GT.orange.opacity(0.3), lineWidth: 1))
            }
        }
    }

    // MARK: - Actions

    private func startTriviaPack(_ pack: TriviaQuestionPack) {
        if pack.category == .sponsorBusiness, let sid = pack.sponsorId {
            sponsorQuizEngine.startQuiz(sponsorId: sid)
        } else {
            triviaEngine.startSession(questions: pack.sessionQuestions())
        }
    }
}
