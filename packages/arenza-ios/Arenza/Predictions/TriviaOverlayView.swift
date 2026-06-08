// TriviaOverlayView.swift — Arenza (Phase 4: Game Formats)
// Halftime trivia quiz card — floats above video.
// Shows difficulty badge, AZT reward, 3-life system, and session summary.

import SwiftUI

struct TriviaOverlayView: View {
    @ObservedObject var engine: TriviaEngine
    var onDismiss: () -> Void = {}

    @State private var opacity: Double = 0
    @State private var dragOffset: CGFloat = 0
    @State private var selectedId: String?

    var body: some View {
        VStack {
            Spacer()
            content
                .padding(.horizontal, 16)
                .padding(.bottom, 100)
        }
        .opacity(opacity)
        .offset(y: dragOffset)
        .gesture(swipeToDismiss)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) { opacity = 1 }
        }
    }

    @ViewBuilder
    private var content: some View {
        if engine.sessionComplete, let session = engine.activeSession {
            sessionSummaryCard(session: session)
        } else if let question = engine.activeSession?.currentQuestion {
            questionCard(question: question)
        }
    }

    // MARK: - Question Card

    private func questionCard(question: TriviaQuestion) -> some View {
        VStack(spacing: 14) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("HALFTIME TRIVIA")
                        .font(.system(size: 10, weight: .black))
                        .foregroundColor(.orange)
                        .tracking(1.5)
                    if let session = engine.activeSession {
                        Text("Q\(session.currentIndex + 1) of \(session.questions.count)")
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
                Spacer()
                livesView
                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.white.opacity(0.3))
                }
            }

            // Difficulty + reward
            HStack(spacing: 8) {
                difficultyBadge(question.difficulty)
                Label("+\(question.adjustedReward) AZT", systemImage: "star.fill")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Color(red: 0.0, green: 0.82, blue: 0.60))
                Spacer()
            }

            // Question text
            Text(question.questionText)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 4)

            // Options
            LazyVGrid(columns: [.init(.flexible()), .init(.flexible())], spacing: 8) {
                ForEach(question.options) { option in
                    TriviaOptionButton(
                        option: option,
                        isSelected: selectedId == option.id,
                        correctId: engine.lastAnswerCorrect != nil ? question.correctOptionId : nil,
                        isDisabled: engine.lastAnswerCorrect != nil
                    ) {
                        guard engine.lastAnswerCorrect == nil else { return }
                        selectedId = option.id
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        engine.submitAnswer(optionId: option.id)
                        if option.id == question.correctOptionId {
                            UINotificationFeedbackGenerator().notificationOccurred(.success)
                        } else {
                            UINotificationFeedbackGenerator().notificationOccurred(.error)
                        }
                    }
                }
            }

            // Answer feedback
            if let correct = engine.lastAnswerCorrect {
                answerFeedback(correct: correct, question: question)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(18)
        .background(.ultraThinMaterial)
        .background(Color.black.opacity(0.55))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.orange.opacity(0.2), lineWidth: 1))
        .shadow(color: .black.opacity(0.5), radius: 20, y: 6)
    }

    // MARK: - Session Summary

    private func sessionSummaryCard(session: TriviaSession) -> some View {
        let accuracy: Int = session.questions.isEmpty ? 0
            : Int(Double(session.correctCount) / Double(session.questions.count) * 100)
        let headline: String = session.wrongCount >= 3 ? "Game Over!" : "Trivia Complete!"

        return VStack(spacing: 16) {
            Text(headline)
                .font(.system(size: 22, weight: .black))
                .foregroundColor(.white)

            HStack(spacing: 32) {
                statView(label: "Correct", value: "\(session.correctCount)")
                statView(label: "AZT Earned", value: "+\(session.totalAZTEarned)")
                statView(label: "Accuracy", value: "\(accuracy)%")
            }

            Button {
                dismiss()
            } label: {
                Text("Collect Rewards")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(Color(red: 0.0, green: 0.82, blue: 0.60))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(22)
        .background(.ultraThinMaterial)
        .background(Color.black.opacity(0.55))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.orange.opacity(0.2), lineWidth: 1))
        .shadow(color: .black.opacity(0.5), radius: 20, y: 6)
    }

    // MARK: - Sub-views

    private var livesView: some View {
        HStack(spacing: 3) {
            ForEach(0..<3, id: \.self) { i in
                Image(systemName: "heart.fill")
                    .font(.system(size: 12))
                    .foregroundColor(i < (3 - (engine.activeSession?.wrongCount ?? 0)) ? .red : .white.opacity(0.15))
            }
        }
    }

    private func difficultyBadge(_ diff: TriviaDifficulty) -> some View {
        let color: Color = diff == .easy ? .green : diff == .medium ? .orange : .red
        return Text(diff.label)
            .font(.system(size: 9, weight: .black))
            .foregroundColor(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.15))
            .clipShape(Capsule())
    }

    private func answerFeedback(correct: Bool, question: TriviaQuestion) -> some View {
        HStack(spacing: 6) {
            Image(systemName: correct ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(correct ? Color(red: 0.0, green: 0.82, blue: 0.60) : .red)
            Text(correct ? "+\(question.adjustedReward) AZT!" : "Better luck next time!")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background((correct ? Color(red: 0.0, green: 0.82, blue: 0.60) : Color.red).opacity(0.12))
        .clipShape(Capsule())
    }

    private func statView(label: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 22, weight: .black))
                .foregroundColor(Color(red: 0.0, green: 0.82, blue: 0.60))
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.white.opacity(0.4))
                .textCase(.uppercase)
        }
    }

    private var swipeToDismiss: some Gesture {
        DragGesture()
            .onChanged { v in if v.translation.height > 0 { dragOffset = v.translation.height } }
            .onEnded { v in
                if v.translation.height > 60 { dismiss() }
                else { withAnimation(.spring()) { dragOffset = 0 } }
            }
    }

    private func dismiss() {
        withAnimation(.easeOut(duration: 0.25)) { opacity = 0; dragOffset = 80 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            engine.dismissSession()
            onDismiss()
        }
    }
}

// MARK: - Trivia Option Button

struct TriviaOptionButton: View {
    let option: TriviaOption
    let isSelected: Bool
    let correctId: String?
    let isDisabled: Bool
    let action: () -> Void

    private var isCorrect: Bool { correctId == option.id }
    private var borderColor: Color {
        guard let _ = correctId else {
            return isSelected ? Color(hue: 0.14, saturation: 0.8, brightness: 0.9) : Color.white.opacity(0.1)
        }
        if isCorrect { return Color(red: 0.0, green: 0.82, blue: 0.60) }
        if isSelected { return .red }
        return Color.white.opacity(0.05)
    }

    var body: some View {
        Button(action: action) {
            Text(option.label)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .padding(.horizontal, 8)
                .background(borderColor.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(borderColor, lineWidth: 1.5))
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .animation(.spring(response: 0.3), value: isSelected)
        .animation(.spring(response: 0.3), value: correctId)
    }
}
