// SponsorQuizOverlayView.swift — Arenza (ArenzaTV Prototype)
// Full-width overlay card for sponsor business quizzes.
// Appears in the bottom companion panel when a sponsor_quiz MatchSim event fires.
// Styled to match the existing GameTabViews design tokens.

import SwiftUI

// MARK: - Design Tokens

private enum SQ {
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

// MARK: - Sponsor Quiz Overlay

struct SponsorQuizOverlayView: View {
    @ObservedObject var engine: SponsorQuizEngine

    var body: some View {
        if let session = engine.activeSession {
            if engine.sessionComplete {
                sessionCompleteCard(session)
            } else if let question = session.currentQuestion {
                questionCard(session: session, question: question)
            }
        }
    }

    // MARK: - Question Card

    private func questionCard(session: SponsorQuizSession, question: TriviaQuestion) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Sponsor header
            HStack(spacing: 8) {
                Text(session.sponsorEmoji).font(.system(size: 20))
                VStack(alignment: .leading, spacing: 1) {
                    Text(session.pack.title)
                        .font(.system(size: 13, weight: .black))
                        .foregroundColor(SQ.text)
                    Text("Sponsored by \(session.sponsorName)")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(Color(arenza: session.sponsorBrandColor))
                }
                Spacer()
                // Progress
                Text("\(session.currentIndex + 1)/\(session.questions.count)")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(SQ.muted)
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(SQ.surface2)
                    .clipShape(Capsule())
            }

            // Question
            Text(question.questionText)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(SQ.text)
                .fixedSize(horizontal: false, vertical: true)

            // Difficulty badge
            HStack(spacing: 6) {
                Text(question.difficulty.label)
                    .font(.system(size: 9, weight: .black))
                    .foregroundColor(difficultyColor(question.difficulty))
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(difficultyColor(question.difficulty).opacity(0.12))
                    .clipShape(Capsule())
                Text("+\(question.aztReward > 0 ? question.aztReward : 15) AZT")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(SQ.gold)
            }

            // Answer options
            VStack(spacing: 8) {
                ForEach(question.options) { option in
                    let isCorrectAnswer = engine.lastAnswerCorrect != nil && option.id == question.correctOptionId
                    let isWrongPick = engine.lastAnswerCorrect == false && option.id != question.correctOptionId

                    Button {
                        engine.submitAnswer(optionId: option.id)
                    } label: {
                        HStack(spacing: 10) {
                            Text(option.label)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(SQ.text)
                                .multilineTextAlignment(.leading)
                            Spacer()
                            if isCorrectAnswer {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(SQ.green)
                            }
                        }
                        .padding(12)
                        .background(
                            isCorrectAnswer ? SQ.green.opacity(0.15) :
                            isWrongPick ? SQ.red.opacity(0.08) :
                            SQ.surface2
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10).stroke(
                                isCorrectAnswer ? SQ.green.opacity(0.5) :
                                SQ.border,
                                lineWidth: 1
                            )
                        )
                    }
                    .disabled(engine.lastAnswerCorrect != nil)
                    .buttonStyle(.plain)
                }
            }

            // Score so far
            HStack {
                Text("✅ \(session.correctCount) correct")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(SQ.teal)
                Spacer()
                Text("💰 +\(session.totalAZTEarned) AZT earned")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(SQ.gold)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(SQ.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color(arenza: session.sponsorBrandColor).opacity(0.3), lineWidth: 1)
                )
        )
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    // MARK: - Session Complete Card

    private func sessionCompleteCard(_ session: SponsorQuizSession) -> some View {
        VStack(spacing: 14) {
            // Celebration
            Text(session.isPerfect ? "🎉" : "✅")
                .font(.system(size: 36))

            Text(session.isPerfect ? "Perfect Score!" : "Quiz Complete!")
                .font(.system(size: 17, weight: .black))
                .foregroundColor(SQ.text)

            // Results
            HStack(spacing: 20) {
                VStack(spacing: 2) {
                    Text("\(session.correctCount)/\(session.questions.count)")
                        .font(.system(size: 20, weight: .black, design: .monospaced))
                        .foregroundColor(SQ.teal)
                    Text("Correct")
                        .font(.system(size: 10))
                        .foregroundColor(SQ.muted)
                }

                VStack(spacing: 2) {
                    Text("+\(session.totalAZTEarned)")
                        .font(.system(size: 20, weight: .black, design: .monospaced))
                        .foregroundColor(SQ.gold)
                    Text("AZT Earned")
                        .font(.system(size: 10))
                        .foregroundColor(SQ.muted)
                }
            }

            // Coupon unlocked
            if let coupon = engine.couponUnlocked {
                VStack(spacing: 6) {
                    HStack(spacing: 6) {
                        Image(systemName: "ticket.fill")
                            .foregroundColor(SQ.green)
                        Text("Coupon Unlocked!")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(SQ.green)
                    }
                    Text(coupon.description)
                        .font(.system(size: 11))
                        .foregroundColor(SQ.text)
                    Text("Check your Wallet to redeem")
                        .font(.system(size: 10))
                        .foregroundColor(SQ.muted)
                }
                .padding(10)
                .background(SQ.green.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(SQ.green.opacity(0.3), lineWidth: 1))
            }

            // Sponsor branding
            Text("Brought to you by \(session.sponsorName) \(session.sponsorEmoji)")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(Color(arenza: session.sponsorBrandColor))
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(SQ.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color(arenza: session.sponsorBrandColor).opacity(0.3), lineWidth: 1)
                )
        )
        .transition(.scale.combined(with: .opacity))
    }

    // MARK: - Helpers

    private func difficultyColor(_ difficulty: TriviaDifficulty) -> Color {
        switch difficulty {
        case .easy:   return SQ.green
        case .medium: return SQ.orange
        case .hard:   return SQ.red
        }
    }
}
