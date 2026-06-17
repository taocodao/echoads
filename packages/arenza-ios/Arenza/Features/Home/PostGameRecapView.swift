// PostGameRecapView.swift — Arenza
// Swift/SwiftUI port of PostGameRecap.tsx (web demo).
// Post-game summary overlay:
//   • Score hero banner (victory/consolation)
//   • Your stats grid (points / pick accuracy / predictions grade)
//   • Prediction letter grade badge
//   • Contextual post-game offer (Victory Round | Consolation Pint)
//   • Total Arenza Points balance
//   • Close button

import SwiftUI

// MARK: - Grade helpers (mirrors web grade() function)

private struct PredictionGrade {
    let letter: String
    let color: String

    static func compute(correct: Int, total: Int) -> PredictionGrade {
        guard total > 0 else { return PredictionGrade(letter: "N/A", color: "#8892b0") }
        let pct = Double(correct) / Double(total)
        if pct >= 0.85 { return PredictionGrade(letter: "A+", color: "#22c55e") }
        if pct >= 0.70 { return PredictionGrade(letter: "A",  color: "#22c55e") }
        if pct >= 0.55 { return PredictionGrade(letter: "B",  color: "#00c9b1") }
        if pct >= 0.40 { return PredictionGrade(letter: "C",  color: "#ffc107") }
        return PredictionGrade(letter: "D", color: "#ff6b35")
    }
}

// MARK: - PostGameRecapView

struct PostGameRecapView: View {

    let points: Int
    let correctPredictions: Int
    let totalPredictions: Int
    let adsWatched: Int
    let couponsClaimedCount: Int
    let homeScore: Int
    let awayScore: Int
    let onClose: () -> Void

    @State private var victoryClaimPressed = false
    @State private var appeared = false

    private var homeWon: Bool { homeScore > awayScore }
    private var grade: PredictionGrade { PredictionGrade.compute(correct: correctPredictions, total: totalPredictions) }
    private var pct: Int {
        totalPredictions > 0 ? Int(Double(correctPredictions) / Double(totalPredictions) * 100) : 0
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {

                // ── Hero result ───────────────────────────────────────────────
                heroSection

                // ── Your stats grid ───────────────────────────────────────────
                statsGrid

                // ── Grade badge ───────────────────────────────────────────────
                gradeBadge

                // ── Post-game offer ───────────────────────────────────────────
                postGameOffer

                // ── Points total ──────────────────────────────────────────────
                pointsTotal

                // ── Close ─────────────────────────────────────────────────────
                Button(action: onClose) {
                    Text("Close Recap")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(Color(arenza: "#8892b0"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(Color(arenza: "#1a1e2a"))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }
            .padding(14)
        }
        .background(Color(arenza: "#0d0f14").ignoresSafeArea())
        .preferredColorScheme(.dark)
        .opacity(appeared ? 1 : 0)
        .scaleEffect(appeared ? 1 : 0.94)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { appeared = true }
        }
    }

    // MARK: - Sections

    private var heroSection: some View {
        VStack(spacing: 8) {
            Text(homeWon ? "🏆" : "💪").font(.system(size: 40))
            Text(homeWon ? "Eagles Win!" : "Better Luck Next Time")
                .font(.system(size: 22, weight: .black))
                .foregroundColor(.white)
            Text("🦅 \(homeScore) — \(awayScore) 🐻")
                .font(.system(size: 28, weight: .black, design: .rounded))
                .foregroundColor(Color(arenza: "#ffc107"))
            Text(homeWon
                ? "What a game! Eagles dominate the Bears on Arenza Sports."
                : "The Bears showed heart. Eagles will bounce back.")
                .font(.system(size: 11))
                .foregroundColor(Color(arenza: "#8892b0"))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(
            LinearGradient(
                colors: homeWon
                    ? [Color(arenza: "#ff6b35").opacity(0.13), Color(arenza: "#ffc107").opacity(0.07)]
                    : [Color(arenza: "#7c3aed").opacity(0.13), Color(arenza: "#ef4444").opacity(0.07)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(arenza: homeWon ? "#ff6b35" : "#7c3aed").opacity(0.25), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var statsGrid: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("YOUR GAME STATS")
            HStack(spacing: 8) {
                statCell("🏆", value: "\(points)", label: "Points Earned", color: "#ffc107")
                statCell("🎯", value: "\(pct)%", label: "Pick Accuracy", color: "#ff6b35")
                statCell(grade.letter, value: "\(correctPredictions)/\(totalPredictions)", label: "Predictions", color: grade.color)
            }
        }
        .padding(12)
        .background(Color(arenza: "#141720"))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.08), lineWidth: 1))
    }

    private var gradeBadge: some View {
        HStack(spacing: 14) {
            // Grade square
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(arenza: grade.color).opacity(0.13))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(arenza: grade.color), lineWidth: 2))
                Text(grade.letter)
                    .font(.system(size: 26, weight: .black, design: .rounded))
                    .foregroundColor(Color(arenza: grade.color))
            }
            .frame(width: 56, height: 56)

            VStack(alignment: .leading, spacing: 3) {
                Text("Prediction Grade")
                    .font(.system(size: 13, weight: .black))
                    .foregroundColor(.white)
                Text(gradeSubtitle)
                    .font(.system(size: 11))
                    .foregroundColor(Color(arenza: "#8892b0"))
                Text("📺 \(adsWatched) ads watched · 🎟 \(couponsClaimedCount) coupons claimed")
                    .font(.system(size: 10))
                    .foregroundColor(Color(arenza: "#4a5568"))
                    .padding(.top, 1)
            }
            Spacer()
        }
        .padding(12)
        .background(Color(arenza: "#141720"))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.08), lineWidth: 1))
    }

    private var postGameOffer: some View {
        Group {
            if homeWon {
                // Victory Round
                VStack(spacing: 10) {
                    Text("🏆 Victory Round — Come Celebrate!")
                        .font(.system(size: 16, weight: .black))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    Text("Any sponsor bar is ready for you. Mention Arenza for 10% off tonight.")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.85))
                        .multilineTextAlignment(.center)
                    Button {
                        withAnimation { victoryClaimPressed = true }
                        MembershipService.shared.addCoupon(businessId: "roccos", offer: "Victory Drink", value: "10% off tonight", expiryHours: 6)
                    } label: {
                        Text(victoryClaimPressed ? "✅ Claimed!" : "🎟 Claim Victory Drink")
                            .font(.system(size: 13, weight: .black))
                            .foregroundColor(.white)
                            .padding(.horizontal, 20).padding(.vertical, 9)
                            .background(Color.black.opacity(0.3))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.3), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    .disabled(victoryClaimPressed)
                }
                .frame(maxWidth: .infinity)
                .padding(14)
                .background(
                    LinearGradient(colors: [Color(arenza: "#ff6b35"), Color(arenza: "#ffc107")], startPoint: .leading, endPoint: .trailing)
                )
                .clipShape(RoundedRectangle(cornerRadius: 14))

            } else {
                // Consolation Pint
                VStack(spacing: 10) {
                    Text("💪 Consolation Pint — 10% Off")
                        .font(.system(size: 16, weight: .black))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    Text("Come commiserate at any sponsor bar. Show this screen.")
                        .font(.system(size: 11))
                        .foregroundColor(Color(arenza: "#8892b0"))
                        .multilineTextAlignment(.center)
                    Button {
                        withAnimation { victoryClaimPressed = true }
                        MembershipService.shared.addCoupon(businessId: "roccos", offer: "Consolation Pint", value: "10% off tonight", expiryHours: 6)
                    } label: {
                        Text(victoryClaimPressed ? "✅ Claimed!" : "🍺 Claim Consolation Drink")
                            .font(.system(size: 13, weight: .black))
                            .foregroundColor(.white)
                            .padding(.horizontal, 20).padding(.vertical, 9)
                            .background(Color(arenza: "#7c3aed"))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                    .disabled(victoryClaimPressed)
                }
                .frame(maxWidth: .infinity)
                .padding(14)
                .background(Color(arenza: "#7c3aed").opacity(0.13))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(arenza: "#7c3aed").opacity(0.4), lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
    }

    private var pointsTotal: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Total Arenza Points")
                    .font(.system(size: 12, weight: .black))
                    .foregroundColor(.white)
                Text("Redeemable at any sponsor business")
                    .font(.system(size: 10))
                    .foregroundColor(Color(arenza: "#8892b0"))
            }
            Spacer()
            Text("\(points)")
                .font(.system(size: 28, weight: .black, design: .monospaced))
                .foregroundColor(Color(arenza: "#ffc107"))
        }
        .padding(12)
        .background(Color(arenza: "#141720"))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.08), lineWidth: 1))
    }

    // MARK: - Helpers

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 9, weight: .black))
            .foregroundColor(Color(arenza: "#8892b0"))
            .tracking(1.2)
    }

    private func statCell(_ emoji: String, value: String, label: String, color: String) -> some View {
        VStack(spacing: 3) {
            Text(emoji).font(.system(size: 22))
            Text(value)
                .font(.system(size: 22, weight: .black, design: .rounded))
                .foregroundColor(Color(arenza: color))
            Text(label)
                .font(.system(size: 9))
                .foregroundColor(Color(arenza: "#4a5568"))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color(arenza: "#1a1e2a"))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private var gradeSubtitle: String {
        if totalPredictions == 0 { return "Join predictions next game to earn a grade!" }
        if pct >= 70 { return "Sharp picker — you read the game well!" }
        if pct >= 40 { return "Solid effort — keep predicting!" }
        return "Tough game — you'll get 'em next time."
    }
}
