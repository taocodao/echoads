// CommentaryOverlay.swift — Arenza
// AI commentary lower-third on the video panel.
// Appears contextually based on game moment (scoring play, prediction, ad break).
// Matches web demo CommentaryOverlay.tsx exactly.

import SwiftUI

struct CommentaryOverlayView: View {
    @ObservedObject var engine: GameEngine
    @State private var visible = false
    @State private var currentLine = ""
    @State private var hideTimer: Timer? = nil

    private static let lines: [String] = [
        "🏈 Eagles driving — 3rd & 4 at the Bears 22",
        "⚡ Jalen Hurts scrambles for 8 yards — great run!",
        "📊 Bears defense giving up 6.2 yds/carry today",
        "🎯 Eagles are 3-for-3 in the red zone this half",
        "🔥 That's Hurts' 2nd rushing TD of the game!",
        "🛡 Bears calling timeout — trying to ice the kicker",
        "📡 2nd & Goal from the 4 — key play coming up",
        "🏆 Eagles have scored on 4 straight possessions",
    ]

    var body: some View {
        Group {
            if visible {
                HStack(spacing: 8) {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color(arenza: "#ef4444"))
                            .frame(width: 5, height: 5)
                        Text("AI")
                            .font(.system(size: 7, weight: .black))
                            .foregroundColor(Color(arenza: "#ef4444"))
                            .tracking(1)
                    }
                    Text(currentLine)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(Color(arenza: "#f0f2ff"))
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                    Spacer()
                }
                .padding(.horizontal, 10).padding(.vertical, 7)
                .background(Color.black.opacity(0.82))
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .padding(.horizontal, 8)
                .padding(.bottom, 8)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.easeInOut(duration: 0.4), value: visible)
            }
        }
        .animation(.easeInOut(duration: 0.4), value: visible)
        .onAppear { scheduleNext() }
        .onDisappear {
            hideTimer?.invalidate()
            visible = false
        }
    }

    private func scheduleNext() {
        let delay = Double.random(in: 12...20)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            showLine()
        }
    }

    private func showLine() {
        currentLine = Self.lines.randomElement() ?? Self.lines[0]
        withAnimation { visible = true }
        hideTimer?.invalidate()
        hideTimer = Timer.scheduledTimer(withTimeInterval: 4.5, repeats: false) { _ in
            Task { @MainActor in
                withAnimation { visible = false }
                scheduleNext()
            }
        }
        RunLoop.main.add(hideTimer!, forMode: .common)
    }
}
