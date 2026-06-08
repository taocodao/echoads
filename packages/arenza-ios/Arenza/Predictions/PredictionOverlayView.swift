// PredictionOverlayView.swift — Arenza (C4: Prediction Engine)
// SwiftUI overlay that fires during timeouts, halftimes, and ad breaks.
// Extends the existing SGAIShoppableCard design language.

import SwiftUI
import Combine

// MARK: - Prediction Overlay View

struct PredictionOverlayView: View {

    @ObservedObject var engine: PredictionEngine
    let question: PredictionQuestion
    var onDismiss: () -> Void = {}

    @State private var selectedOptionID: String?
    @State private var submitted = false
    @State private var resolved = false
    @State private var isCorrect: Bool?
    @State private var pointsEarned: Int?
    @State private var timeRemaining: Int
    @State private var opacity: Double = 0
    @State private var dragOffset: CGFloat = 0
    @State private var cancellables = Set<AnyCancellable>()

    init(engine: PredictionEngine, question: PredictionQuestion, onDismiss: @escaping () -> Void = {}) {
        self.engine = engine
        self.question = question
        self.onDismiss = onDismiss
        _timeRemaining = State(initialValue: question.timeWindowSeconds)
    }

    var body: some View {
        VStack {
            Spacer()
            overlayCard
                .padding(.horizontal, 16)
                .padding(.bottom, 96)
        }
        .opacity(opacity)
        .offset(y: dragOffset)
        .gesture(swipeToDismissGesture)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { opacity = 1 }
            startCountdown()
            subscribeToResolution()
        }
    }

    // MARK: - Main card

    private var overlayCard: some View {
        VStack(spacing: 14) {
            // Sponsor attribution
            sponsorHeader

            // Question text
            Text(question.questionText)
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)

            // Timer ring
            if !submitted {
                CountdownRingView(seconds: timeRemaining, total: question.timeWindowSeconds)
                    .frame(width: 48, height: 48)
            }

            // Resolution feedback
            if let correct = isCorrect {
                resolutionBanner(correct: correct)
            }

            // Options grid
            if !resolved {
                optionsGrid
            }

            // Points preview
            if !submitted {
                Text("Correct answer = +\(question.adjustedPoints) pts")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.45))
            }
        }
        .padding(18)
        .background(.ultraThinMaterial)
        .background(Color.black.opacity(0.45))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.5), radius: 16, y: 4)
    }

    // MARK: - Sponsor header

    private var sponsorHeader: some View {
        HStack {
            if let name = question.sponsorName {
                Text("Brought to you by \(name)")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.45))
                    .tracking(0.5)
            } else {
                Text("LIVE PREDICTION")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(Color(red: 0.0, green: 0.82, blue: 0.60))
                    .tracking(1.5)
            }
            Spacer()
            Button { dismiss() } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.white.opacity(0.4))
                    .font(.system(size: 18))
            }
        }
    }

    // MARK: - Resolution banner

    private func resolutionBanner(correct: Bool) -> some View {
        HStack(spacing: 8) {
            Image(systemName: correct ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(correct ? Color(red: 0.0, green: 0.82, blue: 0.60) : .red)
            if correct, let pts = pointsEarned {
                Text("+\(pts) points!")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Color(red: 0.0, green: 0.82, blue: 0.60))
            } else {
                Text(correct ? "Correct!" : "Not quite — better luck next time!")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 14)
        .background(
            (correct ? Color(red: 0.0, green: 0.82, blue: 0.60) : .red).opacity(0.15)
        )
        .clipShape(Capsule())
        .transition(.scale.combined(with: .opacity))
    }

    // MARK: - Options grid (2-col for 2–4 options)

    private var optionsGrid: some View {
        let cols = question.options.count == 2 ? 2 : 2
        return LazyVGrid(columns: Array(repeating: .init(.flexible()), count: cols), spacing: 10) {
            ForEach(question.options) { option in
                PredictionOptionButton(
                    option: option,
                    isSelected: selectedOptionID == option.id,
                    isDisabled: submitted,
                    correctID: resolved ? engine.activePrediction?.options.first?.id : nil
                ) {
                    guard !submitted else { return }
                    selectedOptionID = option.id
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    engine.submitPrediction(questionID: question.id, optionID: option.id)
                    submitted = true
                }
            }
        }
    }

    // MARK: - Countdown

    private func startCountdown() {
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            guard timeRemaining > 0, !submitted else {
                timer.invalidate()
                if !submitted { dismiss() }   // timed out
                return
            }
            timeRemaining -= 1
        }
    }

    // MARK: - Subscribe to resolution

    private func subscribeToResolution() {
        engine.resolutionPublisher
            .filter { $0.questionID == question.id }
            .receive(on: DispatchQueue.main)
            .first()
            .sink { [self] resolution in
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    isCorrect = resolution.isCorrect
                    pointsEarned = resolution.totalPoints
                    resolved = true
                }
                if resolution.isCorrect {
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                }
                // Auto-dismiss after 3s
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) { dismiss() }
            }
            .store(in: &cancellables)
    }

    private var swipeToDismissGesture: some Gesture {
        DragGesture()
            .onChanged { v in if v.translation.height > 0 { dragOffset = v.translation.height } }
            .onEnded { v in
                if v.translation.height > 60 { dismiss() }
                else { withAnimation(.spring()) { dragOffset = 0 } }
            }
    }

    private func dismiss() {
        withAnimation(.easeOut(duration: 0.25)) { opacity = 0; dragOffset = 100 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            engine.dismissActivePrediction()
            onDismiss()
        }
    }
}

// MARK: - Option Button

struct PredictionOptionButton: View {
    let option: PredictionOption
    let isSelected: Bool
    let isDisabled: Bool
    let correctID: String?
    let action: () -> Void

    private var isCorrect: Bool { correctID == option.id }
    private var accentColor: Color {
        if isSelected && isCorrect  { return Color(red: 0.0, green: 0.82, blue: 0.60) }
        if isSelected && !isCorrect { return .red }
        if isCorrect                { return Color(red: 0.0, green: 0.82, blue: 0.60) }
        return .white.opacity(0.12)
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                if let iconURL = option.iconURL {
                    AsyncImage(url: iconURL) { img in img.resizable().scaledToFit() } placeholder: { EmptyView() }
                        .frame(width: 32, height: 32)
                }
                Text(option.label)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isSelected ? accentColor.opacity(0.25) : Color.white.opacity(0.07))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(accentColor, lineWidth: isSelected ? 1.5 : 0.5))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .disabled(isDisabled)
        .animation(.spring(response: 0.3), value: isSelected)
    }
}

// MARK: - Countdown Ring View

struct CountdownRingView: View {
    let seconds: Int
    let total: Int

    private var progress: Double { Double(seconds) / Double(max(1, total)) }
    private var ringColor: Color {
        if progress > 0.5 { return Color(red: 0.0, green: 0.82, blue: 0.60) }
        if progress > 0.2 { return .orange }
        return .red
    }

    var body: some View {
        ZStack {
            Circle().stroke(Color.white.opacity(0.1), lineWidth: 3)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(ringColor, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1), value: progress)
            Text("\(seconds)")
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
        }
    }
}

// MARK: - Reward Unlock Overlay

struct RewardUnlockOverlayView: View {
    let coupon: SponsorCoupon
    let onRedeem: () -> Void
    let onDismiss: () -> Void

    @State private var opacity: Double = 0
    @State private var scale: CGFloat = 0.8

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "gift.fill")
                .font(.system(size: 44))
                .foregroundStyle(
                    LinearGradient(colors: [.yellow, .orange], startPoint: .top, endPoint: .bottom)
                )
                .symbolEffect(.bounce, value: true)

            Text("You earned a reward!")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)

            VStack(spacing: 4) {
                Text(coupon.sponsorName)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white.opacity(0.6))
                Text(coupon.description)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
            }

            Text("Expires in \(coupon.daysUntilExpiry) days")
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.4))

            HStack(spacing: 12) {
                Button(action: onDismiss) {
                    Text("Save for Later")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.3)))
                }

                Button(action: onRedeem) {
                    Text("Redeem Now")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color(red: 0.0, green: 0.82, blue: 0.60))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .padding(24)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.white.opacity(0.1)))
        .shadow(radius: 20)
        .padding(.horizontal, 24)
        .scaleEffect(scale)
        .opacity(opacity)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                opacity = 1; scale = 1
            }
        }
    }
}
