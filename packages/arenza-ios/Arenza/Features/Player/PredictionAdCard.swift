// PredictionAdCard.swift â€” Arenza
// Ad Format 1: Live Prediction Banner
// Sponsored by Pepsi â€” countdown-gated question tied to live game moments.
// Fans select an outcome, lock in before timer expires, earn points if correct.
// Directly reads from GameEngine.activePrediction.

import SwiftUI

struct PredictionAdCard: View {
    @ObservedObject var engine: GameEngine
    @ObservedObject var adEngine: InteractiveAdEngine

    var body: some View {
        VStack(spacing: 0) {
            // Header
            predHeader

            // Body
            if let pred = engine.activePrediction {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 10) {
                        questionView(pred: pred)
                        optionsGrid(pred: pred)
                        timerBar(pred: pred)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                }
                .transition(.opacity)
            } else {
                idleView
            }
        }
        .background(Color(arenza: "#0d0f14"))
    }

    // MARK: - Header

    private var predHeader: some View {
        HStack(spacing: 8) {
            // Live dot
            HStack(spacing: 4) {
                PulsingDot(color: Color(arenza: "#ef4444"))
                Text("LIVE Â· Q\(engine.quarter) Â· \(engine.clockDisplay)")
                    .font(.system(size: 10, weight: .black))
                    .foregroundColor(Color(arenza: "#ef4444"))
                    .tracking(0.8)
            }
            Spacer()
            // Sponsor
            HStack(spacing: 4) {
                Text("ðŸ¥¤")
                Text("Pepsi")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(Color(arenza: "#00c9b1"))
                Text("Presents")
                    .font(.system(size: 10))
                    .foregroundColor(Color(arenza: "#8892b0"))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(
            LinearGradient(
                colors: [Color(arenza: "#1a0a00"), Color(arenza: "#0d0a15")],
                startPoint: .leading, endPoint: .trailing
            )
        )
        .overlay(Rectangle().fill(Color.white.opacity(0.06)).frame(height: 1), alignment: .bottom)
    }

    // MARK: - Question

    private func questionView(pred: GamePrediction) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            if let sponsor = pred.sponsor {
                Text("ðŸŽ¯ Sponsored by \(sponsor)")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(Color(arenza: "#ff6b35"))
            }
            Text(pred.question)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(Color(arenza: "#f0f2ff"))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Options

    private func optionsGrid(pred: GamePrediction) -> some View {
        let cols = pred.options.count <= 2 ? 2 : 2
        return LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: cols),
            spacing: 6
        ) {
            ForEach(Array(pred.options.enumerated()), id: \.offset) { i, opt in
                predOptionButton(pred: pred, opt: opt, index: i)
            }
        }
        .onChange(of: engine.activePrediction?.id) { _ in
            adEngine.userBeganInteraction(pauseFor: 30)
        }
    }

    private func predOptionButton(pred: GamePrediction, opt: GamePrediction.PredictionOption, index: Int) -> some View {
        let isCorrect = engine.predictionResolved && index == pred.correctIndex
        let isWrong   = engine.predictionResolved && engine.userPick == index && index != pred.correctIndex
        let isPicked  = engine.userPick == index
        let borderColor = isCorrect ? Color(arenza: "#22c55e") :
                          isWrong   ? Color(arenza: "#ef4444") :
                          isPicked  ? Color(arenza: "#ff6b35") : Color.white.opacity(0.08)
        let bgColor = isCorrect ? Color(arenza: "#22c55e").opacity(0.15) :
                      isWrong   ? Color(arenza: "#ef4444").opacity(0.1) :
                      isPicked  ? Color(arenza: "#ff6b35").opacity(0.15) : Color(arenza: "#1a1e2a")

        // Phase 3: Simulated vote distribution for social-proof fill bars
        let votePcts: [Double] = [0.62, 0.38, 0.51, 0.49]
        let fillPct = index < votePcts.count ? votePcts[index] : 0.5

        return Button {
            engine.pickOption(index)
            adEngine.userBeganInteraction(pauseFor: 30)
        } label: {
            GeometryReader { geo in
                ZStack(alignment: .bottomLeading) {
                    // Fill bar (pred-opt-bar from HTML reference)
                    Rectangle()
                        .fill((isCorrect ? Color(arenza: "#22c55e") : Color(arenza: "#ff6b35")).opacity(0.18))
                        .frame(width: geo.size.width * fillPct, height: 3)
                        .animation(.timingCurve(0.16, 1, 0.3, 1, duration: 0.8), value: fillPct)
                }
                HStack(spacing: 6) {
                    Text(opt.emoji).font(.system(size: 16))
                    VStack(alignment: .leading, spacing: 1) {
                        Text(opt.label)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(Color(arenza: "#f0f2ff"))
                        Text(opt.odds)
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(isCorrect ? Color(arenza: "#22c55e") : Color(arenza: "#8892b0"))
                    }
                    Spacer()
                    // Social proof % label
                    Text("\(Int(fillPct * 100))%")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(isPicked ? Color(arenza: "#ff6b35") : Color(arenza: "#4a5568"))
                    if isPicked {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(isCorrect ? Color(arenza: "#22c55e") : Color(arenza: "#ff6b35"))
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
            }
            .frame(height: 46)
            .background(bgColor)
            .clipShape(RoundedRectangle(cornerRadius: 9))
            .overlay(RoundedRectangle(cornerRadius: 9).stroke(borderColor, lineWidth: 1))
        }
        .disabled(engine.userPick != nil)
        .buttonStyle(.plain)
        .animation(.spring(response: 0.25), value: isPicked)
    }

    // MARK: - Timer Bar

    private func timerBar(pred: GamePrediction) -> some View {
        VStack(spacing: 5) {
            HStack {
                Text("â± Locks in \(engine.predictionTimer)s")
                    .font(.system(size: 10))
                    .foregroundColor(engine.predictionTimer <= 5 ? Color(arenza: "#ef4444") : Color(arenza: "#8892b0"))
                Spacer()
                if engine.predictionResolved {
                    Text(engine.userPick == pred.correctIndex ? "âœ… Correct! +\(pred.pointReward) pts" : "âŒ Not quite! +10 pts")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(engine.userPick == pred.correctIndex ? Color(arenza: "#22c55e") : Color(arenza: "#ef4444"))
                } else {
                    Text("ðŸŽ– +\(pred.pointReward) pts")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Color(arenza: "#ffc107"))
                }
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3).fill(Color.white.opacity(0.08)).frame(height: 3)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(engine.predictionTimer <= 5 ? Color(arenza: "#ef4444") : Color(arenza: "#00c9b1"))
                        .frame(
                            width: geo.size.width * CGFloat(engine.predictionTimer) / CGFloat(max(pred.durationSec, 1)),
                            height: 3
                        )
                        .animation(.linear(duration: 1), value: engine.predictionTimer)
                }
            }
            .frame(height: 3)
        }
        .onChange(of: engine.predictionResolved) { resolved in
            // PREDICT & SPIN BRIDGE: correct answer earns a bonus spin token
            if resolved, let pick = engine.userPick, pick == pred.correctIndex {
                Task { @MainActor in
                    TemporalRetentionService.shared.addBonusSpin(count: 1)
                }
            }
        }
    }

    // MARK: - Idle View

    private var idleView: some View {
        VStack(spacing: 8) {
            Text("ðŸ”®").font(.system(size: 28))
            Text("Next prediction incoming...")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Color(arenza: "#8892b0"))
            Text("Stay tuned â€” sponsored by Pepsi")
                .font(.system(size: 10))
                .foregroundColor(Color(arenza: "#4a5568"))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

// MARK: - Shared: Pulsing Live Dot

struct PulsingDot: View {
    let color: Color
    @State private var pulse = false

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 6, height: 6)
            .shadow(color: color.opacity(pulse ? 0 : 0.7), radius: pulse ? 6 : 0)
            .animation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true), value: pulse)
            .onAppear { pulse = true }
    }
}
