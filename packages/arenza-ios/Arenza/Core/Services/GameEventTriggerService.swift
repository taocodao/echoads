// GameEventTriggerService.swift — Arenza
// Phase 2: Game-Event Bonus Triggers
// Manual trigger system for demo + SCTE-35 marker detection stub for production.
//
// Phase 1 (Demo):   A "Scoring Play!" button fires a 60-second bonus spin window
// Phase 2 (Prod):   SCTE-35 splice_insert markers from HLS/DASH stream trigger automatically
//
// Events fire into TemporalRetentionService.triggerGameEventBonus()
// which opens the bonus window and awards a bonus spin token.

import Foundation
import SwiftUI
import Combine

// MARK: - Game Event Trigger Service

@MainActor
final class GameEventTriggerService: ObservableObject {

    static let shared = GameEventTriggerService()

    // MARK: - Published

    @Published private(set) var recentEvents: [GameEvent] = []
    @Published private(set) var isMonitoring: Bool = false

    // MARK: - Demo Event Types

    struct GameEvent: Identifiable {
        let id = UUID()
        let timestamp: Date
        let eventType: EventType
        let label: String
        let team: String?

        enum EventType: String, CaseIterable {
            case touchdown  = "Touchdown"
            case fieldGoal  = "Field Goal"
            case safety     = "Safety"
            case interception = "Interception"
            case sack       = "Sack"
            case kickoff    = "Kickoff"
            case twoMinute  = "2-Minute Warning"

            var emoji: String {
                switch self {
                case .touchdown:    return "🏈"
                case .fieldGoal:    return "🎯"
                case .safety:       return "🛡️"
                case .interception: return "🔄"
                case .sack:         return "💥"
                case .kickoff:      return "🦶"
                case .twoMinute:    return "⏰"
                }
            }

            var bonusDuration: Int {
                switch self {
                case .touchdown:    return 90
                case .fieldGoal:    return 60
                case .safety:       return 45
                case .interception: return 75
                case .sack:         return 45
                case .kickoff:      return 30
                case .twoMinute:    return 120
                }
            }

            var aztMultiplierBoost: Double {
                switch self {
                case .touchdown:    return 2.0
                case .fieldGoal:    return 1.5
                case .safety:       return 1.5
                case .interception: return 1.75
                default:            return 1.25
                }
            }
        }
    }

    // MARK: - Manual Trigger (Demo)

    func triggerEvent(_ type: GameEvent.EventType, team: String? = nil) {
        let event = GameEvent(
            timestamp: Date(),
            eventType: type,
            label: "\(type.emoji) \(type.rawValue)\(team != nil ? " — \(team!)" : "")",
            team: team
        )

        recentEvents.insert(event, at: 0)
        if recentEvents.count > 20 { recentEvents = Array(recentEvents.prefix(20)) }

        // Fire into Temporal Retention
        TemporalRetentionService.shared.triggerGameEventBonus(
            eventLabel: event.label,
            durationSeconds: type.bonusDuration
        )
    }

    // MARK: - SCTE-35 Integration Stub (Phase 2 Production)
    // In production: parse HLS playlist for EXT-X-DATERANGE or EXT-X-CUE-IN
    // markers and call triggerEvent() based on splice_insert type.

    func startSCTE35Monitoring(streamURL: URL) {
        isMonitoring = true
        // TODO: Implement HLS manifest polling + SCTE-35 binary parsing
        // For now, use demo auto-trigger every 5 minutes during live game
        print("[SCTE-35] Monitoring stub started for \(streamURL.absoluteString)")
    }

    func stopSCTE35Monitoring() {
        isMonitoring = false
    }
}

// MARK: - Game Event Trigger Panel (Demo UI for operator/test)

struct GameEventTriggerPanel: View {
    @ObservedObject private var svc = GameEventTriggerService.shared
    @State private var selectedEvent: GameEventTriggerService.GameEvent.EventType = .touchdown

    let teams = ["Home Team", "Visitors"]
    @State private var selectedTeam = "Home Team"

    var body: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                Image(systemName: "bolt.fill")
                    .foregroundColor(Color(arenza: "#ffc107"))
                Text("DEMO: Game Event Trigger")
                    .font(.system(size: 11, weight: .black))
                    .foregroundColor(Color(arenza: "#ffc107"))
                Spacer()
                if GameEventTriggerService.shared.recentEvents.isEmpty == false {
                    Text("\(GameEventTriggerService.shared.recentEvents.count) events")
                        .font(.system(size: 9))
                        .foregroundColor(.white.opacity(0.4))
                }
            }

            // Event type picker
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(GameEventTriggerService.GameEvent.EventType.allCases, id: \.self) { type in
                        Button {
                            selectedEvent = type
                        } label: {
                            HStack(spacing: 4) {
                                Text(type.emoji).font(.system(size: 11))
                                Text(type.rawValue).font(.system(size: 10, weight: .semibold))
                            }
                            .foregroundColor(selectedEvent == type ? .black : .white)
                            .padding(.horizontal, 8).padding(.vertical, 4)
                            .background(selectedEvent == type ? Color(arenza: "#ffc107") : Color.white.opacity(0.08))
                            .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 1)
            }

            // Trigger button
            Button {
                svc.triggerEvent(selectedEvent, team: selectedTeam)
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "bolt.fill")
                    Text("Fire \(selectedEvent.emoji) \(selectedEvent.rawValue) Event")
                        .font(.system(size: 13, weight: .black))
                    Text("+\(selectedEvent.bonusDuration)s")
                        .font(.system(size: 10, weight: .bold))
                        .padding(.horizontal, 5).padding(.vertical, 2)
                        .background(Color.black.opacity(0.25))
                        .clipShape(Capsule())
                }
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color(arenza: "#ffc107"))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.plain)

            // Recent events
            if !svc.recentEvents.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("RECENT EVENTS")
                        .font(.system(size: 8, weight: .black))
                        .foregroundColor(.white.opacity(0.3))
                        .tracking(1)
                    ForEach(svc.recentEvents.prefix(3)) { event in
                        HStack {
                            Text(event.label)
                                .font(.system(size: 10))
                                .foregroundColor(.white.opacity(0.7))
                            Spacer()
                            Text(timeAgo(event.timestamp))
                                .font(.system(size: 9))
                                .foregroundColor(.white.opacity(0.3))
                        }
                    }
                }
            }
        }
        .padding(12)
        .background(Color(arenza: "#ffc107").opacity(0.06))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(arenza: "#ffc107").opacity(0.2), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func timeAgo(_ date: Date) -> String {
        let secs = Int(-date.timeIntervalSinceNow)
        if secs < 60 { return "\(secs)s ago" }
        return "\(secs / 60)m ago"
    }
}
