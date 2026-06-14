// MatchEvent.swift — Arenza (ArenzaTV Prototype)
// Unified event model for the MatchSim timeline.
// Each event represents something that happens in the scripted match:
// a play, a score change, a prediction trigger, a trivia burst, or an ad break.
//
// The MatchEventProviding protocol lets us swap MatchSimClient (demo)
// for SportradarClient (production) without changing any downstream code.

import Foundation
import Combine

// MARK: - Match Event (from MatchSim or production feed)

struct MatchEvent: Codable, Identifiable {
    let id: UUID
    let at: Int                          // seconds into the match
    let type: MatchEventType
    let data: MatchEventData

    init(id: UUID = UUID(), at: Int, type: MatchEventType, data: MatchEventData) {
        self.id = id
        self.at = at
        self.type = type
        self.data = data
    }
}

enum MatchEventType: String, Codable {
    case play           = "play"           // game action (first down, sack, etc.)
    case score          = "score"          // scoring play
    case prediction     = "prediction"     // trigger a prediction question
    case trivia         = "trivia"         // trigger a trivia pack question
    case sponsorQuiz    = "sponsor_quiz"   // trigger a sponsor business quiz
    case adBreak        = "ad_break"       // commercial break
    case quarterChange  = "quarter_change" // period/quarter transition
    case timeout        = "timeout"        // team timeout
    case chat           = "chat"           // simulated fan chat message
}

struct MatchEventData: Codable {
    // Play / Score
    var description: String?
    var emoji: String?
    var bingoLabel: String?              // auto-mark bingo cell
    var homeScoreDelta: Int?
    var awayScoreDelta: Int?

    // Prediction
    var question: String?
    var options: [String]?
    var correctIndex: Int?
    var pointReward: Int?
    var sponsor: String?
    var durationSec: Int?

    // Trivia
    var triviaPack: String?              // e.g. "eagles_history"
    var questionIndex: Int?

    // Sponsor Quiz
    var sponsorId: String?

    // Ad Break
    var adDuration: Int?

    // Quarter Change
    var newQuarter: Int?

    // Chat
    var chatUser: String?
    var chatText: String?
}

// MARK: - Match Timeline (collection of events for a game)

struct MatchTimeline: Codable {
    let matchId: String
    let sport: String                    // "NFL", "NBA", "Soccer"
    let homeTeam: TeamInfo
    let awayTeam: TeamInfo
    let durationSeconds: Int             // total clip length
    let events: [MatchEvent]
}

struct TeamInfo: Codable {
    let id: String                       // "PHI", "CHI"
    let name: String                     // "Eagles", "Bears"
    let emoji: String                    // "🦅", "🐻"
    let startingScore: Int               // score at clip start
}

// MARK: - MatchEventProviding Protocol

/// Abstraction for the match event source.
/// Prototype: MatchSimClient (WebSocket to Node.js)
/// Production: SportradarClient (live data API)
@MainActor
protocol MatchEventProviding: AnyObject {
    var eventPublisher: AnyPublisher<MatchEvent, Never> { get }
    var timelinePublisher: AnyPublisher<MatchTimeline, Never> { get }
    func connect(matchId: String) async
    func disconnect()
}

// MARK: - Demo Timeline (hardcoded fallback when MatchSim server is unavailable)

extension MatchTimeline {
    /// Eagles vs Bears — 10-minute demo clip timeline
    static let eaglesBears = MatchTimeline(
        matchId: "eagles-bears-demo",
        sport: "NFL",
        homeTeam: TeamInfo(id: "PHI", name: "Eagles", emoji: "🦅", startingScore: 14),
        awayTeam: TeamInfo(id: "CHI", name: "Bears", emoji: "🐻", startingScore: 10),
        durationSeconds: 600,
        events: [
            // Play events
            MatchEvent(at: 15,  type: .play, data: .init(description: "Eagles convert on 3rd & 5 — First Down!", emoji: "📍", bingoLabel: "First Down")),
            MatchEvent(at: 35,  type: .play, data: .init(description: "Eagles RB breaks for 12 yards up the middle", emoji: "💨")),
            MatchEvent(at: 70,  type: .play, data: .init(description: "Flag — Holding, Bears #72 (-10 yards)", emoji: "🚩", bingoLabel: "Penalty Flag")),

            // Prediction at :20
            MatchEvent(at: 20,  type: .prediction, data: .init(question: "Next play: Pass or Rush?", options: ["Pass", "Rush"], correctIndex: 0, pointReward: 75, sponsor: "Nike", durationSec: 18)),

            // Trivia at :65
            MatchEvent(at: 65,  type: .trivia, data: .init(triviaPack: "eagles_history", questionIndex: 0)),

            // Score at :105
            MatchEvent(at: 105, type: .score, data: .init(description: "TOUCHDOWN EAGLES! #11 A.J. Brown — 28-yard strike!", emoji: "🏈", bingoLabel: "Touchdown", homeScoreDelta: 7)),

            // Sponsor quiz at :155
            MatchEvent(at: 155, type: .sponsorQuiz, data: .init(sponsorId: "pepsi")),

            // Ad break at :50
            MatchEvent(at: 50,  type: .adBreak, data: .init(sponsor: "nike", adDuration: 12)),

            // More game events
            MatchEvent(at: 175, type: .play, data: .init(description: "SACK! Eagles #99 Sweat drops Fields for -9", emoji: "💥", bingoLabel: "Sack")),
            MatchEvent(at: 210, type: .score, data: .init(description: "Bears FG — Cairo Santos 52 yards!", emoji: "🥅", bingoLabel: "Field Goal", awayScoreDelta: 3)),
            MatchEvent(at: 235, type: .timeout, data: .init(description: "Eagles call timeout — 2 remaining", emoji: "⏸️", bingoLabel: "Timeout Called")),

            // Prediction at :285
            MatchEvent(at: 285, type: .prediction, data: .init(question: "Next play outcome?", options: ["1st Down", "Incomplete", "Penalty"], correctIndex: 2, pointReward: 100, durationSec: 15)),

            // Chat messages
            MatchEvent(at: 10,  type: .chat, data: .init(chatUser: "🦅 PhillyFan", chatText: "Let's GOOOO Birds!! 🔥")),
            MatchEvent(at: 108, type: .chat, data: .init(chatUser: "🦅 PhillyFan", chatText: "AJ BROWN IS UNSTOPPABLE 🏈🎉")),
            MatchEvent(at: 112, type: .chat, data: .init(chatUser: "🎯 BetKing", chatText: "Eagles TD! +150 pts! 🔥")),

            // Quarter change
            MatchEvent(at: 390, type: .quarterChange, data: .init(description: "END OF Q3 — Eagles lead heading into the 4th", emoji: "🏟️", newQuarter: 4)),

            // Late game
            MatchEvent(at: 330, type: .play, data: .init(description: "INTERCEPTION! Eagles #24 Slay picks off Fields!", emoji: "🙌", bingoLabel: "Interception")),
            MatchEvent(at: 360, type: .score, data: .init(description: "TOUCHDOWN! Eagles #82 Smith — 6-yard TD grab", emoji: "🏈", bingoLabel: "Touchdown", homeScoreDelta: 7)),
            MatchEvent(at: 440, type: .prediction, data: .init(question: "Eagles score before end of Q3?", options: ["Yes", "No"], correctIndex: 0, pointReward: 175, durationSec: 20)),
            MatchEvent(at: 490, type: .play, data: .init(description: "Hurts scrambles for 18 yards!", emoji: "🏃", bingoLabel: "QB Scramble")),
            MatchEvent(at: 510, type: .score, data: .init(description: "TOUCHDOWN EAGLES! Hurts sneaks in from the 1!", emoji: "🏈", bingoLabel: "Touchdown", homeScoreDelta: 7)),
            MatchEvent(at: 565, type: .score, data: .init(description: "Bears TD — garbage time score", emoji: "🏈", bingoLabel: "Touchdown", awayScoreDelta: 7)),
            MatchEvent(at: 590, type: .play, data: .init(description: "FINAL: Eagles 35 — Bears 20. Eagles improve to 9-2!", emoji: "🎉")),

            // Trivia at :350
            MatchEvent(at: 350, type: .trivia, data: .init(triviaPack: "bears_history", questionIndex: 0)),

            // Sponsor quiz at :470
            MatchEvent(at: 470, type: .sponsorQuiz, data: .init(sponsorId: "dominos")),
        ]
    )
}
