// PollOverlayView.swift — Arenza (Phase 4: Game Formats)
// Sponsor-branded poll card — floats above the video during game breaks.
// Shows live vote percentages after submission, then auto-dismisses.

import SwiftUI

struct PollOverlayView: View {
    @ObservedObject var engine: PollEngine
    let poll: SponsorPoll
    var onDismiss: () -> Void = {}

    @State private var selectedId: String?
    @State private var submitted = false
    @State private var timeRemaining: Int
    @State private var opacity: Double = 0
    @State private var dragOffset: CGFloat = 0

    init(engine: PollEngine, poll: SponsorPoll, onDismiss: @escaping () -> Void = {}) {
        self.engine = engine
        self.poll = poll
        self.onDismiss = onDismiss
        _timeRemaining = State(initialValue: poll.durationSeconds)
    }

    var result: PollResult? { engine.pendingResult }

    var body: some View {
        VStack {
            Spacer()
            card
                .padding(.horizontal, 16)
                .padding(.bottom, 100)
        }
        .opacity(opacity)
        .offset(y: dragOffset)
        .gesture(swipeToDismiss)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) { opacity = 1 }
            startCountdown()
        }
    }

    // MARK: - Card

    private var card: some View {
        VStack(spacing: 14) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    if let name = poll.sponsorName {
                        Text("Brought to you by \(name)")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(.white.opacity(0.4))
                    }
                    Text("QUICK POLL")
                        .font(.system(size: 11, weight: .black))
                        .foregroundColor(Color(hue: 0.52, saturation: 0.6, brightness: 0.9))
                        .tracking(1.5)
                }
                Spacer()
                if !submitted {
                    CountdownRingView(seconds: timeRemaining, total: poll.durationSeconds)
                        .frame(width: 38, height: 38)
                }
                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.white.opacity(0.3))
                }
            }

            // Question
            Text(poll.question)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 4)

            // AZT reward badge
            if !submitted {
                Label("+\(poll.aztReward) AZT for voting", systemImage: "star.fill")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Color(red: 0.0, green: 0.82, blue: 0.60))
            }

            // Options
            VStack(spacing: 8) {
                ForEach(poll.options) { option in
                    PollOptionRow(
                        option: option,
                        isSelected: selectedId == option.id,
                        isSubmitted: submitted,
                        percentage: result?.percentage(for: option.id) ?? 0,
                        totalVotes: result?.totalVotes ?? 0
                    ) {
                        guard !submitted else { return }
                        selectedId = option.id
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        withAnimation(.spring(response: 0.3)) {
                            submitted = true
                        }
                        engine.submitVote(pollId: poll.id, optionId: option.id)
                    }
                }
            }

            if submitted {
                Text("Thanks for voting! 🎉")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.5))
                    .transition(.opacity)
            }
        }
        .padding(18)
        .background(.ultraThinMaterial)
        .background(Color.black.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color(hue: 0.52, saturation: 0.4, brightness: 0.6).opacity(0.3), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.5), radius: 20, y: 6)
    }

    // MARK: - Timer

    private func startCountdown() {
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            guard timeRemaining > 0, !submitted else {
                timer.invalidate()
                if !submitted { dismiss() }
                return
            }
            timeRemaining -= 1
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
            engine.dismissActivePoll()
            onDismiss()
        }
    }
}

// MARK: - Poll Option Row (with results bar)

struct PollOptionRow: View {
    let option: PollOption
    let isSelected: Bool
    let isSubmitted: Bool
    let percentage: Double
    let totalVotes: Int
    let action: () -> Void

    private var accentColor: Color {
        isSelected
            ? Color(hue: 0.52, saturation: 0.6, brightness: 0.9)
            : Color.white.opacity(0.08)
    }

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .leading) {
                // Result fill bar
                if isSubmitted {
                    GeometryReader { geo in
                        RoundedRectangle(cornerRadius: 10)
                            .fill(isSelected
                                  ? Color(hue: 0.52, saturation: 0.5, brightness: 0.8).opacity(0.25)
                                  : Color.white.opacity(0.05))
                            .frame(width: geo.size.width * percentage)
                            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: percentage)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                HStack {
                    if let emoji = option.emoji {
                        Text(emoji).font(.system(size: 16))
                    }
                    Text(option.label)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                    Spacer()
                    if isSubmitted {
                        Text("\(Int(percentage * 100))%")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(isSelected
                                            ? Color(hue: 0.52, saturation: 0.6, brightness: 0.9)
                                            : .white.opacity(0.5))
                    }
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(Color(hue: 0.52, saturation: 0.6, brightness: 0.9))
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
            }
            .frame(height: 42)
            .background(isSelected && !isSubmitted ? accentColor.opacity(0.15) : Color.white.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? accentColor : Color.white.opacity(0.08), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(isSubmitted)
    }
}
