// GameEngine.swift — Arenza
// Drives all game-layer state synced to the video timeline:
// predictions, ads, bingo auto-marks, live feed, and points.

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
    let appearsAt: Int   // seconds into game clock
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

// MARK: - Scripted Data

private let PREDICTIONS: [GamePrediction] = [
    GamePrediction(id: "p1", question: "Next play: Pass or Rush?",
        options: [.init(label: "Pass", odds: "1.6×", emoji: "🏈"),
                  .init(label: "Rush", odds: "2.4×", emoji: "🏃")],
        pointReward: 75, durationSec: 15, appearsAt: 5, correctIndex: 0, sponsor: "Nike"),
    GamePrediction(id: "p2", question: "Will Eagles score this drive?",
        options: [.init(label: "TD", odds: "2.1×", emoji: "✅"),
                  .init(label: "FG", odds: "3.0×", emoji: "🥅"),
                  .init(label: "No Score", odds: "1.8×", emoji: "❌")],
        pointReward: 125, durationSec: 18, appearsAt: 25, correctIndex: 0, sponsor: nil),
    GamePrediction(id: "p3", question: "Next play outcome?",
        options: [.init(label: "1st Down", odds: "1.7×", emoji: "📍"),
                  .init(label: "Incomplete", odds: "2.2×", emoji: "💨"),
                  .init(label: "Penalty", odds: "4.0×", emoji: "🚩")],
        pointReward: 100, durationSec: 12, appearsAt: 48, correctIndex: 1, sponsor: "DraftKings"),
    GamePrediction(id: "p4", question: "Eagles score before end of Q3?",
        options: [.init(label: "Yes", odds: "1.9×", emoji: "🎯"),
                  .init(label: "No", odds: "2.0×", emoji: "🛡️")],
        pointReward: 150, durationSec: 20, appearsAt: 62, correctIndex: 0, sponsor: nil),
]

let AD_CATALOG: [GameAdCreative] = [
    GameAdCreative(id: "nike", brand: "Nike", tagline: "Just Do It", emoji: "👟", cpm: 55,
        targetSegment: "Sports Enthusiast · M 25–34",
        whyChosen: ["High sports engagement (87/100)", "Male 25–34 demo match", "Football affinity: 92%", "Won OpenRTB at $55 CPM"],
        color: Color(hex: "#ff6b35"), appearsAt: 10, durationSec: 8),
    GameAdCreative(id: "pepsi", brand: "Pepsi", tagline: "Game Day Fuel", emoji: "🥤", cpm: 42,
        targetSegment: "Mass Market · All Adults",
        whyChosen: ["Game-day context match", "Food & beverage affinity", "Top-of-funnel brand awareness", "Won OpenRTB at $42 CPM"],
        color: Color(hex: "#00c9b1"), appearsAt: 32, durationSec: 8),
    GameAdCreative(id: "draftkings", brand: "DraftKings", tagline: "Bet on the Action", emoji: "🎯", cpm: 68,
        targetSegment: "High-Engagement Bettors · 21+",
        whyChosen: ["Active prediction player", "Betting affinity signal", "21+ verified", "Won OpenRTB at $68 CPM — highest bidder"],
        color: Color(hex: "#7c3aed"), appearsAt: 55, durationSec: 8),
    GameAdCreative(id: "statefarm", brand: "State Farm", tagline: "Like a Good Neighbor", emoji: "🏠", cpm: 38,
        targetSegment: "Homeowners · 30–50",
        whyChosen: ["Homeowner demographic signal", "Timeout moment — attention peak", "Premium viewer loyalty: A", "Won OpenRTB at $38 CPM"],
        color: Color(hex: "#ffc107"), appearsAt: 70, durationSec: 8),
]

private struct GameEvent {
    let at: Int
    let emoji: String
    let text: String
    let bingoLabel: String?
    let homeScoreDelta: Int
    let awayScoreDelta: Int
}

private let GAME_EVENTS: [GameEvent] = [
    GameEvent(at: 8,  emoji: "📍", text: "Eagles convert on 3rd & 7 — First Down!", bingoLabel: "First Down", homeScoreDelta: 0, awayScoreDelta: 0),
    GameEvent(at: 22, emoji: "🏈", text: "TOUCHDOWN EAGLES! #11 Brown — 34-yard strike!", bingoLabel: "Touchdown", homeScoreDelta: 6, awayScoreDelta: 0),
    GameEvent(at: 30, emoji: "🚩", text: "Flag on the play — Holding, Bears #72", bingoLabel: "Penalty Flag", homeScoreDelta: 0, awayScoreDelta: 0),
    GameEvent(at: 42, emoji: "💥", text: "SACK! Eagles #99 drops Bears QB for -8 yards", bingoLabel: "Sack", homeScoreDelta: 0, awayScoreDelta: 0),
    GameEvent(at: 50, emoji: "🙌", text: "INTERCEPTION! Eagles #24 picks it off at midfield!", bingoLabel: "Interception", homeScoreDelta: 0, awayScoreDelta: 0),
    GameEvent(at: 60, emoji: "🥅", text: "Bears kick a 47-yard field goal — 3 points!", bingoLabel: "Field Goal", homeScoreDelta: 0, awayScoreDelta: 3),
    GameEvent(at: 68, emoji: "⏸️", text: "Bears call timeout — 2 remaining in Q3", bingoLabel: "Timeout Called", homeScoreDelta: 0, awayScoreDelta: 0),
    GameEvent(at: 75, emoji: "🏈", text: "TOUCHDOWN EAGLES! #82 Smith — 12-yard grab!", bingoLabel: "Touchdown", homeScoreDelta: 6, awayScoreDelta: 0),
]

private let BINGO_LABELS = [
    "Touchdown", "Field Goal", "Interception", "Sack", "Penalty Flag",
    "First Down", "Timeout Called", "Challenge Flag", "2-Pt Conv.", "False Start",
    "Fumble", "Big Hit", "FREE", "Long Pass", "No Gain",
    "Touchdown", "3rd Down Conv.", "Punt", "QB Scramble", "Red Zone",
    "Holding Call", "Incomplete", "Safety", "4th Down", "Pick-6",
]

private let CHAT_MSGS: [(at: Int, user: String, text: String)] = [
    (0,  "🦅 EaglesFan23",   "Let's gooo Eagles!! 🔥🔥🔥"),
    (3,  "🎯 SportsBetKing", "Picked PASS — feels right"),
    (9,  "🐻 ChiTownBear",   "Bears D needs to step up fr"),
    (23, "🦅 EaglesFan23",   "YESSS TOUCHDOWN!!! 🎉🎉🎉"),
    (31, "🚩 RefWatch",      "Another holding call lmao"),
    (43, "🐻 ChiTownBear",   "Come on Bears O-line 😤"),
    (51, "🏈 NFLNerd42",     "INTERCEPTION! Game might be over 💀"),
    (61, "🐻 ChiTownBear",   "At least we got 3. Build on it"),
    (77, "🎯 SportsBetKing", "BINGO!! Cashing out 🔥"),
]

// MARK: - Engine

@MainActor
final class GameEngine: ObservableObject {

    // Scoreboard
    @Published var homeScore = 14
    @Published var awayScore = 10
    @Published var quarter  = 3
    @Published var clockDisplay = "8:44"

    // Prediction
    @Published var activePrediction: GamePrediction?
    @Published var predictionTimer = 0
    @Published var userPick: Int?
    @Published var predictionResolved = false

    // Ads
    @Published var activeAd: GameAdCreative?
    @Published var lastAd: GameAdCreative?
    @Published var adTimerRemaining = 0

    // Points
    @Published var points = 1250
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
    var adsServed: Int { AD_CATALOG.filter { $0.appearsAt <= elapsed }.count }
    var sessionRevenue: Double { AD_CATALOG.filter { $0.appearsAt <= elapsed }.reduce(0) { $0 + Double($1.cpm) / 1000.0 } }

    private var elapsed = 0
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
        if elapsed > 78 { elapsed = 1; firedKeys.removeAll() }

        // Clock countdown from 8:44 in Q3
        let remaining = max(0, 8 * 60 + 44 - elapsed)
        clockDisplay = "\(remaining / 60):\(String(format: "%02d", remaining % 60))"

        // Ad countdown
        if adTimerRemaining > 0 {
            adTimerRemaining -= 1
            if adTimerRemaining == 0 { activeAd = nil }
        }

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
            if let label = evt.bingoLabel { autoMarkBingo(label) }
            addFeed(.init(type: .game, emoji: evt.emoji, text: evt.text, detail: nil, timestamp: Date()))
        }

        // Predictions
        for pred in PREDICTIONS {
            let key = "pred-\(pred.id)"
            guard elapsed == pred.appearsAt, !firedKeys.contains(key) else { continue }
            firedKeys.insert(key)
            activePrediction = pred
            predictionTimer = pred.durationSec
            userPick = nil
            predictionResolved = false
            addFeed(.init(type: .prediction, emoji: "🔮", text: "Prediction: \"\(pred.question)\"", detail: "+\(pred.pointReward) pts if correct", timestamp: Date()))
        }
        // Auto-resolve
        for pred in PREDICTIONS {
            let key = "pred-resolve-\(pred.id)"
            guard elapsed == pred.appearsAt + pred.durationSec + 2, !firedKeys.contains(key) else { continue }
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
            activeAd = ad
            lastAd = ad
            adTimerRemaining = ad.durationSec
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
        let completed = lines.filter { line in line.allSatisfy { bingoBoard[$0].marked || bingoBoard[$0].isFree } }.count
        if completed > bingoLines {
            awardPoints(500, label: "BINGO! Line \(completed) complete!")
        }
        bingoLines = completed
    }

    // MARK: - Predictions

    func pickOption(_ index: Int) {
        guard let pred = activePrediction, userPick == nil else { return }
        userPick = index
        if index == pred.correctIndex {
            awardPoints(pred.pointReward, label: "Correct prediction!")
        }
    }

    // MARK: - Points

    private func awardPoints(_ pts: Int, label: String) {
        points += pts
        flyText = "+\(pts) pts"
        addFeed(.init(type: .prediction, emoji: "⭐", text: label, detail: "+\(pts) pts earned", timestamp: Date()))
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in self?.flyText = nil }
    }

    private func addFeed(_ entry: FeedEntry) {
        feed.insert(entry, at: 0)
        if feed.count > 40 { feed.removeLast() }
    }
}

