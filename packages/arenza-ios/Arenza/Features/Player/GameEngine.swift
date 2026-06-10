// GameEngine.swift — Arenza
// Drives all game-layer state synced to the ~10-minute NFL video timeline.
// All timestamps are in seconds matching the Vercel Blob MP4 clip.

import Foundation
import Combine
import SwiftUI

// MARK: - Data Models

struct GamePrediction: Identifiable {
    let id: String
    let question: String
    let options: [PredictionOption]
    let pointReward: Int
    let durationSec: Int
    let appearsAt: Int
    let correctIndex: Int
    let sponsor: String?

    struct PredictionOption {
        let label: String
        let odds: String
        let emoji: String
    }
}

struct GameAdCreative: Identifiable {
    let id: String
    let brand: String
    let tagline: String
    let emoji: String
    let cpm: Int
    let targetSegment: String
    let whyChosen: [String]
    let color: Color
    let appearsAt: Int
    let durationSec: Int
}

struct FeedEntry: Identifiable {
    let id = UUID()
    let type: FeedType
    let emoji: String
    let text: String
    let detail: String?
    let timestamp: Date

    enum FeedType { case game, ad, prediction, chat, pod }
}

struct BingoCell: Identifiable {
    let id: Int
    let label: String
    var marked: Bool
    let isFree: Bool
}

// MARK: - 10-Minute NFL Timeline Data

private let PREDICTIONS: [GamePrediction] = [
    GamePrediction(id: "p1", question: "Next play: Pass or Rush?",
        options: [.init(label: "Pass", odds: "1.6×", emoji: "🏈"),
                  .init(label: "Rush", odds: "2.4×", emoji: "🏃")],
        pointReward: 75, durationSec: 18, appearsAt: 20, correctIndex: 0, sponsor: "Nike"),
    GamePrediction(id: "p2", question: "Will Eagles score this drive?",
        options: [.init(label: "Touchdown", odds: "2.1×", emoji: "✅"),
                  .init(label: "Field Goal", odds: "3.0×", emoji: "🥅"),
                  .init(label: "No Score", odds: "1.8×", emoji: "❌")],
        pointReward: 150, durationSec: 20, appearsAt: 85, correctIndex: 0, sponsor: nil),
    GamePrediction(id: "p3", question: "Who scores the next TD?",
        options: [.init(label: "Eagles WR", odds: "2.0×", emoji: "🦅"),
                  .init(label: "Eagles RB", odds: "2.8×", emoji: "💨"),
                  .init(label: "Bears", odds: "3.5×", emoji: "🐻")],
        pointReward: 200, durationSec: 20, appearsAt: 190, correctIndex: 0, sponsor: "DraftKings"),
    GamePrediction(id: "p4", question: "Next play outcome?",
        options: [.init(label: "1st Down", odds: "1.7×", emoji: "📍"),
                  .init(label: "Incomplete", odds: "2.2×", emoji: "💨"),
                  .init(label: "Penalty", odds: "4.0×", emoji: "🚩")],
        pointReward: 100, durationSec: 15, appearsAt: 285, correctIndex: 2, sponsor: nil),
    GamePrediction(id: "p5", question: "Will Bears convert on 4th down?",
        options: [.init(label: "Yes — Go for it", odds: "2.5×", emoji: "💪"),
                  .init(label: "No — Punt", odds: "1.5×", emoji: "🦶")],
        pointReward: 125, durationSec: 18, appearsAt: 350, correctIndex: 1, sponsor: "State Farm"),
    GamePrediction(id: "p6", question: "Eagles score before end of Q3?",
        options: [.init(label: "Yes", odds: "1.9×", emoji: "🎯"),
                  .init(label: "No", odds: "2.0×", emoji: "🛡️")],
        pointReward: 175, durationSec: 20, appearsAt: 440, correctIndex: 0, sponsor: nil),
    GamePrediction(id: "p7", question: "Final Q4 possession winner?",
        options: [.init(label: "Eagles win drive", odds: "1.8×", emoji: "🦅"),
                  .init(label: "Bears turnover", odds: "2.3×", emoji: "💥"),
                  .init(label: "Field goal trade", odds: "3.2×", emoji: "🥅")],
        pointReward: 250, durationSec: 22, appearsAt: 530, correctIndex: 0, sponsor: "DraftKings"),
]

let AD_CATALOG: [GameAdCreative] = [
    GameAdCreative(id: "nike", brand: "Nike", tagline: "Just Do It", emoji: "👟", cpm: 55,
        targetSegment: "Sports Enthusiast · M 25–34",
        whyChosen: ["High sports engagement (87/100)", "Male 25–34 demo match", "Football affinity: 92%", "Won OpenRTB at $55 CPM"],
        color: Color(arenza: "#ff6b35"), appearsAt: 50, durationSec: 12),
    GameAdCreative(id: "pepsi", brand: "Pepsi", tagline: "Game Day Fuel", emoji: "🥤", cpm: 42,
        targetSegment: "Mass Market · All Adults",
        whyChosen: ["Game-day context match", "Food & beverage affinity", "Top-of-funnel brand awareness", "Won OpenRTB at $42 CPM"],
        color: Color(arenza: "#00c9b1"), appearsAt: 155, durationSec: 12),
    GameAdCreative(id: "draftkings", brand: "DraftKings", tagline: "Bet on the Action", emoji: "🎯", cpm: 68,
        targetSegment: "High-Engagement Bettors · 21+",
        whyChosen: ["Active prediction player (3 picks)", "Betting affinity signal: 94%", "21+ verified", "Won OpenRTB at $68 CPM — highest bidder"],
        color: Color(arenza: "#7c3aed"), appearsAt: 260, durationSec: 12),
    GameAdCreative(id: "statefarm", brand: "State Farm", tagline: "Like a Good Neighbor", emoji: "🏠", cpm: 38,
        targetSegment: "Homeowners · 30–50",
        whyChosen: ["Homeowner demographic signal", "Timeout moment — attention peak", "Premium viewer loyalty: A", "Won OpenRTB at $38 CPM"],
        color: Color(arenza: "#ffc107"), appearsAt: 380, durationSec: 12),
    GameAdCreative(id: "geico", brand: "GEICO", tagline: "15 Minutes Could Save You 15%", emoji: "🦎", cpm: 45,
        targetSegment: "Auto Owners · 25–55",
        whyChosen: ["Auto insurance affinity signal", "Q3/Q4 high-attention moment", "Repeat exposure boosts recall +34%", "Won OpenRTB at $45 CPM"],
        color: Color(arenza: "#22c55e"), appearsAt: 470, durationSec: 12),
    GameAdCreative(id: "amazon", brand: "Amazon Prime", tagline: "Stream Every Game", emoji: "📺", cpm: 72,
        targetSegment: "Premium Streamers · 18–45",
        whyChosen: ["Sports streaming intent signal", "Prime subscriber lookalike", "High LTV segment: $189/yr", "Won OpenRTB at $72 CPM — premium"],
        color: Color(arenza: "#ff9900"), appearsAt: 545, durationSec: 12),
]

private struct GameEvent {
    let at: Int       // seconds
    let emoji: String
    let text: String
    let bingoLabel: String?
    let homeScoreDelta: Int
    let awayScoreDelta: Int
    let quarter: Int?
}

// Timeline matched to a ~10-min NFL clip (Eagles vs Bears)
private let GAME_EVENTS: [GameEvent] = [
    GameEvent(at: 15,  emoji: "📍", text: "Eagles convert on 3rd & 5 — First Down!", bingoLabel: "First Down", homeScoreDelta: 0, awayScoreDelta: 0, quarter: nil),
    GameEvent(at: 35,  emoji: "💨", text: "Eagles RB breaks for 12 yards up the middle", bingoLabel: nil, homeScoreDelta: 0, awayScoreDelta: 0, quarter: nil),
    GameEvent(at: 70,  emoji: "🚩", text: "Flag on the play — Holding, Bears #72 (-10 yards)", bingoLabel: "Penalty Flag", homeScoreDelta: 0, awayScoreDelta: 0, quarter: nil),
    GameEvent(at: 105, emoji: "🏈", text: "TOUCHDOWN EAGLES! #11 A.J. Brown — 28-yard strike! Eagles lead 21–10", bingoLabel: "Touchdown", homeScoreDelta: 7, awayScoreDelta: 0, quarter: nil),
    GameEvent(at: 130, emoji: "🏃", text: "Bears quick drive — RB Montgomery gains 15 yards", bingoLabel: nil, homeScoreDelta: 0, awayScoreDelta: 0, quarter: nil),
    GameEvent(at: 175, emoji: "💥", text: "SACK! Eagles #99 Sweat drops Fields for -9 yards", bingoLabel: "Sack", homeScoreDelta: 0, awayScoreDelta: 0, quarter: nil),
    GameEvent(at: 210, emoji: "🥅", text: "Bears kick 52-yard FG — Cairo Santos is good! Bears 13, Eagles 21", bingoLabel: "Field Goal", homeScoreDelta: 0, awayScoreDelta: 3, quarter: nil),
    GameEvent(at: 235, emoji: "⏸️", text: "Eagles call timeout — 2 remaining in Q3", bingoLabel: "Timeout Called", homeScoreDelta: 0, awayScoreDelta: 0, quarter: nil),
    GameEvent(at: 270, emoji: "🚩", text: "Pass interference on Bears #23 — 15-yard penalty Eagles ball", bingoLabel: "Penalty Flag", homeScoreDelta: 0, awayScoreDelta: 0, quarter: nil),
    GameEvent(at: 305, emoji: "📍", text: "Eagles convert on 4th & 2 — gutsy call pays off!", bingoLabel: "4th Down", homeScoreDelta: 0, awayScoreDelta: 0, quarter: nil),
    GameEvent(at: 330, emoji: "🙌", text: "INTERCEPTION! Eagles #24 Darius Slay picks off Fields at the 35!", bingoLabel: "Interception", homeScoreDelta: 0, awayScoreDelta: 0, quarter: nil),
    GameEvent(at: 360, emoji: "🏈", text: "TOUCHDOWN! Eagles #82 Smith — 6-yard TD grab. Eagles 28, Bears 13", bingoLabel: "Touchdown", homeScoreDelta: 7, awayScoreDelta: 0, quarter: nil),
    GameEvent(at: 390, emoji: "🏟️", text: "END OF Q3 — Eagles lead 28–13 heading into the 4th", bingoLabel: nil, homeScoreDelta: 0, awayScoreDelta: 0, quarter: 4),
    GameEvent(at: 420, emoji: "💥", text: "BIG HIT! Eagles LB stops Bears RB for no gain on 1st & 10", bingoLabel: "Big Hit", homeScoreDelta: 0, awayScoreDelta: 0, quarter: nil),
    GameEvent(at: 450, emoji: "🦶", text: "Bears forced to punt — Eagles take over at their own 22", bingoLabel: "Punt", homeScoreDelta: 0, awayScoreDelta: 0, quarter: nil),
    GameEvent(at: 490, emoji: "🏃", text: "Hurts scrambles for 18 yards — QB keeper up the middle!", bingoLabel: "QB Scramble", homeScoreDelta: 0, awayScoreDelta: 0, quarter: nil),
    GameEvent(at: 510, emoji: "🏈", text: "TOUCHDOWN EAGLES! Hurts sneaks in from the 1! Eagles 35, Bears 13", bingoLabel: "Touchdown", homeScoreDelta: 7, awayScoreDelta: 0, quarter: nil),
    GameEvent(at: 540, emoji: "⏸️", text: "Bears call final timeout — 1 remaining in Q4", bingoLabel: "Timeout Called", homeScoreDelta: 0, awayScoreDelta: 0, quarter: nil),
    GameEvent(at: 565, emoji: "🏈", text: "Bears TD — garbage time score. Fields to Kmet. Eagles 35, Bears 20", bingoLabel: "Touchdown", homeScoreDelta: 0, awayScoreDelta: 7, quarter: nil),
    GameEvent(at: 590, emoji: "🎉", text: "FINAL: Eagles 35 — Bears 20. Eagles improve to 9-2!", bingoLabel: nil, homeScoreDelta: 0, awayScoreDelta: 0, quarter: nil),
]

private let BINGO_LABELS = [
    "Touchdown", "Field Goal", "Interception", "Sack", "Penalty Flag",
    "First Down", "Timeout Called", "4th Down", "QB Scramble", "Big Hit",
    "Fumble", "Punt", "FREE", "Long Pass", "No Gain",
    "Touchdown", "3rd Down Conv.", "Red Zone", "Pick-6", "Holding Call",
    "False Start", "Incomplete", "Safety", "2-Pt Conv.", "Challenge Flag",
]

private let CHAT_MSGS: [(at: Int, user: String, text: String)] = [
    (10,  "🦅 PhillyFan",      "Let's GOOOO Birds!! 🔥"),
    (25,  "🎯 BetKing",        "Picked PASS — looking good"),
    (40,  "🐻 ChiTownBear",    "Bears D hold them here!"),
    (72,  "🚩 RefWatch",       "Holding call goes against Bears typical lol"),
    (108, "🦅 PhillyFan",      "AJ BROWN IS UNSTOPPABLE 🏈🎉"),
    (112, "🎯 BetKing",        "Eagles TD! +150 pts! 🔥"),
    (178, "🐻 ChiTownBear",    "Sack!! NOW we're talking 💪"),
    (213, "🥅 FieldGoalFan",   "Santos is so reliable. 52 yarder easy"),
    (237, "🐻 ChiTownBear",    "Eagles panicking 😂 timeout used"),
    (333, "🦅 PhillyFan",      "SLAY WITH THE PICK!!! 🙌🙌🙌"),
    (363, "🎯 BetKing",        "Called it! Eagles score again. Cashing out 💰"),
    (392, "📺 NFLNerd",        "Q4 incoming. Eagles by 15 — game over?"),
    (513, "🦅 PhillyFan",      "HURTS SNEAKS IT IN!! MVP SEASON 🏆"),
    (567, "🐻 ChiTownBear",    "garbage TD lol, at least we're on the board"),
    (592, "🎯 BetKing",        "Eagles cover the spread. Another W for the sharps 💵"),
]

// MARK: - Engine

@MainActor
final class GameEngine: ObservableObject {

    // Scoreboard — starts mid-game Q3
    @Published var homeScore  = 14  // Eagles
    @Published var awayScore  = 10  // Bears
    @Published var quarter    = 3
    @Published var clockDisplay = "12:00"

    // Prediction
    @Published var activePrediction: GamePrediction?
    @Published var predictionTimer   = 0
    @Published var userPick: Int?
    @Published var predictionResolved = false

    // Ads
    @Published var activeAd: GameAdCreative?
    @Published var lastAd: GameAdCreative?
    @Published var adTimerRemaining = 0

    // Points
    @Published var points  = 1250
    @Published var flyText: String?

    // Feed & chat
    @Published var feed: [FeedEntry] = []
    @Published var chatMessages: [(user: String, text: String)] = []

    // Bingo
    @Published var bingoBoard: [BingoCell] = BINGO_LABELS.enumerated().map { i, label in
        BingoCell(id: i, label: label, marked: label == "FREE", isFree: label == "FREE")
    }
    @Published var bingoLines = 0

    // Revenue tracking
    var adsServed: Int     { AD_CATALOG.filter { $0.appearsAt <= elapsed }.count }
    var sessionRevenue: Double { AD_CATALOG.filter { $0.appearsAt <= elapsed }.reduce(0) { $0 + Double($1.cpm) / 1000.0 } }

    private var elapsed  = 0
    private let duration = 600   // 10-min clip
    private var timer: Timer?
    private var firedKeys = Set<String>()

    func start() {
        guard timer == nil else { return }
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in self?.tick() }
        }
    }

    func stop() { timer?.invalidate(); timer = nil }

    private func tick() {
        elapsed += 1
        if elapsed > duration { elapsed = 1; firedKeys.removeAll() }

        // Q3: 12:00 countdown, Q4 starts at 390s
        if elapsed < 390 {
            let remaining = max(0, 12 * 60 - elapsed)
            clockDisplay = "\(remaining / 60):\(String(format: "%02d", remaining % 60))"
        } else {
            let remaining = max(0, 15 * 60 - (elapsed - 390))
            clockDisplay = "\(remaining / 60):\(String(format: "%02d", remaining % 60))"
        }

        // Ad countdown
        if adTimerRemaining > 0 { adTimerRemaining -= 1; if adTimerRemaining == 0 { activeAd = nil } }

        // Prediction countdown
        if predictionTimer > 0 {
            predictionTimer -= 1
            if predictionTimer == 0, userPick == nil { activePrediction = nil }
        }

        // Game events
        for evt in GAME_EVENTS {
            let key = "evt-\(evt.at)"
            guard elapsed == evt.at, !firedKeys.contains(key) else { continue }
            firedKeys.insert(key)
            homeScore += evt.homeScoreDelta
            awayScore += evt.awayScoreDelta
            if let q = evt.quarter { quarter = q }
            if let label = evt.bingoLabel { autoMarkBingo(label) }
            addFeed(.init(type: .game, emoji: evt.emoji, text: evt.text, detail: nil, timestamp: Date()))
        }

        // Predictions
        for pred in PREDICTIONS {
            let key = "pred-\(pred.id)"
            guard elapsed == pred.appearsAt, !firedKeys.contains(key) else { continue }
            firedKeys.insert(key)
            activePrediction = pred
            predictionTimer  = pred.durationSec
            userPick         = nil
            predictionResolved = false
            addFeed(.init(type: .prediction, emoji: "🔮", text: "Prediction: \"\(pred.question)\"", detail: "+\(pred.pointReward) pts if correct", timestamp: Date()))
        }
        for pred in PREDICTIONS {
            let key = "pred-resolve-\(pred.id)"
            guard elapsed == pred.appearsAt + pred.durationSec + 3, !firedKeys.contains(key) else { continue }
            firedKeys.insert(key)
            predictionResolved = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { [weak self] in
                self?.activePrediction = nil; self?.predictionResolved = false
            }
        }

        // Ads
        for ad in AD_CATALOG {
            let key = "ad-\(ad.id)"
            guard elapsed == ad.appearsAt, !firedKeys.contains(key) else { continue }
            firedKeys.insert(key)
            activeAd = ad; lastAd = ad; adTimerRemaining = ad.durationSec
            addFeed(.init(type: .ad, emoji: ad.emoji, text: "\(ad.brand) — \"\(ad.tagline)\"", detail: "$\(ad.cpm) CPM · \(ad.targetSegment) · PoD ✅", timestamp: Date()))
        }

        // Chat
        for msg in CHAT_MSGS {
            let key = "chat-\(msg.at)-\(msg.user)"
            guard elapsed == msg.at, !firedKeys.contains(key) else { continue }
            firedKeys.insert(key)
            chatMessages.append((user: msg.user, text: msg.text))
            if chatMessages.count > 30 { chatMessages.removeFirst() }
        }
    }

    // MARK: - Bingo

    func markBingoCell(_ index: Int) {
        guard !bingoBoard[index].marked, !bingoBoard[index].isFree else { return }
        bingoBoard[index].marked = true
        awardPoints(25, label: "Bingo cell marked")
        checkBingoLines()
    }

    private func autoMarkBingo(_ label: String) {
        guard let i = bingoBoard.firstIndex(where: { $0.label == label && !$0.marked && !$0.isFree }) else { return }
        bingoBoard[i].marked = true
        checkBingoLines()
    }

    private func checkBingoLines() {
        let lines: [[Int]] = [
            [0,1,2,3,4],[5,6,7,8,9],[10,11,12,13,14],[15,16,17,18,19],[20,21,22,23,24],
            [0,5,10,15,20],[1,6,11,16,21],[2,7,12,17,22],[3,8,13,18,23],[4,9,14,19,24],
            [0,6,12,18,24],[4,8,12,16,20],
        ]
        let completed = lines.filter { $0.allSatisfy { bingoBoard[$0].marked || bingoBoard[$0].isFree } }.count
        if completed > bingoLines { awardPoints(500, label: "BINGO! Line \(completed) complete!") }
        bingoLines = completed
    }

    // MARK: - Predictions

    func pickOption(_ index: Int) {
        guard let pred = activePrediction, userPick == nil else { return }
        userPick = index
        if index == pred.correctIndex { awardPoints(pred.pointReward, label: "Correct prediction!") }
    }

    // MARK: - Points

    private func awardPoints(_ pts: Int, label: String) {
        points += pts
        flyText = "+\(pts) pts"
        addFeed(.init(type: .prediction, emoji: "⭐", text: label, detail: "+\(pts) pts earned", timestamp: Date()))
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in self?.flyText = nil }
    }

    // MARK: - Public Hooks for InteractiveAdEngine

    /// Called by ScratchAdCard and MoreLessAdCard to award points from the interactive ad panel.
    func awardPointsPublic(_ pts: Int, label: String) {
        awardPoints(pts, label: label)
    }

    /// Called by ScratchAdCard to inject events into the live feed.
    func addFeedPublic(_ entry: FeedEntry) {
        addFeed(entry)
    }
}
