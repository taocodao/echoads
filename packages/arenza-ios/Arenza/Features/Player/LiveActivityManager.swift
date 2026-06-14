// LiveActivityManager.swift — Arenza (ArenzaTV Prototype)
// Manages Dynamic Island Live Activity for displaying live game scores.
// When a game is active, shows the score in the Dynamic Island and Lock Screen.
//
// Note: Full ActivityKit integration requires a Widget Extension target.
// This file provides the model + manager that can be wired up when the
// widget extension is added. For now it uses UserDefaults to sync state.

import Foundation
import SwiftUI

// MARK: - Live Score State

struct LiveScoreState: Codable {
    var homeTeam: String         // "Eagles"
    var homeEmoji: String        // "🦅"
    var homeScore: Int
    var awayTeam: String         // "Bears"
    var awayEmoji: String        // "🐻"
    var awayScore: Int
    var quarter: Int
    var clockDisplay: String     // "8:32"
    var isLive: Bool
    var lastPlay: String?

    static var demo: LiveScoreState {
        LiveScoreState(
            homeTeam: "Eagles", homeEmoji: "🦅", homeScore: 14,
            awayTeam: "Bears", awayEmoji: "🐻", awayScore: 10,
            quarter: 3, clockDisplay: "12:00", isLive: true,
            lastPlay: nil
        )
    }
}

// MARK: - Live Activity Manager

@MainActor
final class LiveActivityManager: ObservableObject {
    static let shared = LiveActivityManager()

    @Published var currentState: LiveScoreState?
    @Published var isActivityRunning = false

    private let suiteDefaults = UserDefaults(suiteName: "group.tv.arenza.app")
    private let stateKey = "arenza_live_score"

    private init() {}

    // MARK: - Start Activity

    func startActivity(state: LiveScoreState) {
        currentState = state
        isActivityRunning = true
        syncToDefaults(state)

        // In production, this would call:
        // let activity = try Activity.request(
        //     attributes: ArenzaScoreAttributes(homeTeam: state.homeTeam, awayTeam: state.awayTeam),
        //     content: .init(state: ArenzaScoreContentState(from: state), staleDate: nil),
        //     pushType: nil
        // )
        print("[LiveActivity] Started for \(state.homeTeam) vs \(state.awayTeam)")
    }

    // MARK: - Update Activity

    func updateScore(homeScore: Int, awayScore: Int, quarter: Int, clock: String, lastPlay: String? = nil) {
        guard var state = currentState else { return }
        state.homeScore = homeScore
        state.awayScore = awayScore
        state.quarter = quarter
        state.clockDisplay = clock
        state.lastPlay = lastPlay
        currentState = state
        syncToDefaults(state)

        // In production:
        // await activity?.update(using: ArenzaScoreContentState(from: state))
        print("[LiveActivity] Updated: \(homeScore)-\(awayScore) Q\(quarter) \(clock)")
    }

    // MARK: - End Activity

    func endActivity() {
        currentState = nil
        isActivityRunning = false
        suiteDefaults?.removeObject(forKey: stateKey)

        // In production:
        // await activity?.end(using: finalState, dismissalPolicy: .after(.now + 300))
        print("[LiveActivity] Ended")
    }

    // MARK: - Sync to App Group for Widget Extension

    private func syncToDefaults(_ state: LiveScoreState) {
        guard let data = try? JSONEncoder().encode(state) else { return }
        suiteDefaults?.set(data, forKey: stateKey)
    }

    // MARK: - Read from App Group (for Widget Extension)

    static func readFromDefaults() -> LiveScoreState? {
        let defaults = UserDefaults(suiteName: "group.tv.arenza.app")
        guard let data = defaults?.data(forKey: "arenza_live_score"),
              let state = try? JSONDecoder().decode(LiveScoreState.self, from: data) else {
            return nil
        }
        return state
    }
}

// MARK: - Dynamic Island Preview (for demo purposes)

/// A compact preview of what the Dynamic Island would show.
/// Useful for demo presentations even without the Widget Extension.
struct DynamicIslandPreview: View {
    let state: LiveScoreState

    var body: some View {
        HStack(spacing: 10) {
            // Compact leading
            HStack(spacing: 4) {
                Text(state.homeEmoji)
                    .font(.system(size: 14))
                Text("\(state.homeScore)")
                    .font(.system(size: 14, weight: .black, design: .monospaced))
                    .foregroundColor(Color(arenza: "#ff6b35"))
            }

            // Center
            VStack(spacing: 1) {
                HStack(spacing: 3) {
                    Circle().fill(Color.red).frame(width: 4, height: 4)
                    Text("LIVE")
                        .font(.system(size: 7, weight: .black))
                        .foregroundColor(.red)
                        .tracking(1)
                }
                Text("Q\(state.quarter) · \(state.clockDisplay)")
                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.6))
            }

            // Compact trailing
            HStack(spacing: 4) {
                Text("\(state.awayScore)")
                    .font(.system(size: 14, weight: .black, design: .monospaced))
                    .foregroundColor(Color(arenza: "#00c9b1"))
                Text(state.awayEmoji)
                    .font(.system(size: 14))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(Color.black)
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.5), radius: 8)
    }
}

// MARK: - Expanded Island View (for demo)

struct ExpandedIslandPreview: View {
    let state: LiveScoreState

    var body: some View {
        VStack(spacing: 8) {
            // Score row
            HStack(spacing: 16) {
                VStack(spacing: 2) {
                    Text(state.homeEmoji).font(.system(size: 20))
                    Text(state.homeTeam)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)

                VStack(spacing: 2) {
                    HStack(spacing: 8) {
                        Text("\(state.homeScore)")
                            .font(.system(size: 28, weight: .black, design: .monospaced))
                            .foregroundColor(Color(arenza: "#ff6b35"))
                        Text("—")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white.opacity(0.3))
                        Text("\(state.awayScore)")
                            .font(.system(size: 28, weight: .black, design: .monospaced))
                            .foregroundColor(Color(arenza: "#00c9b1"))
                    }
                    Text("Q\(state.quarter) · \(state.clockDisplay)")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(.white.opacity(0.5))
                }

                VStack(spacing: 2) {
                    Text(state.awayEmoji).font(.system(size: 20))
                    Text(state.awayTeam)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
            }

            // Last play
            if let play = state.lastPlay {
                Text(play)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
                    .lineLimit(1)
            }

            // CTA
            HStack(spacing: 6) {
                Image(systemName: "gamecontroller.fill")
                    .font(.system(size: 10))
                Text("Play games & earn AZT")
                    .font(.system(size: 9, weight: .semibold))
            }
            .foregroundColor(Color(arenza: "#00c9b1"))
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Color(arenza: "#00c9b1").opacity(0.12))
            .clipShape(Capsule())
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.black)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.5), radius: 12)
    }
}
