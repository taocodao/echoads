// SportBingoLabels.swift — Arenza (ArenzaTV Prototype)
// Per-sport bingo label sets so the bingo card matches the game being watched.
// Each set contains 25 labels (5×5 grid, center is FREE).
// These replace the hardcoded BINGO_LABELS in GameEngine.swift.

import Foundation

// MARK: - Sport Bingo Pack

struct SportBingoPack {
    let sport: String
    let labels: [String]     // exactly 25 items; index 12 is always "FREE"

    /// Returns labels with the center slot forced to FREE
    var boardLabels: [String] {
        var result = labels
        if result.count >= 13 {
            result[12] = "FREE"
        }
        return result
    }

    /// Shuffled board (keeps FREE in center)
    func shuffledBoard() -> [String] {
        var items = labels.filter { $0 != "FREE" }
        items.shuffle()
        // Take 24 items (some packs may have more than 25 for variety)
        let selected = Array(items.prefix(24))
        var board = Array(selected.prefix(12))
        board.append("FREE")
        board.append(contentsOf: Array(selected.dropFirst(12).prefix(12)))
        return board
    }
}

// MARK: - NFL Bingo

extension SportBingoPack {
    static let nfl = SportBingoPack(
        sport: "NFL",
        labels: [
            "Touchdown",       "Field Goal",      "Interception",    "Sack",            "Penalty Flag",
            "First Down",      "Timeout Called",   "4th Down",        "QB Scramble",     "Big Hit",
            "Fumble",          "Punt",             "FREE",            "Long Pass",       "No Gain",
            "Touchdown",       "3rd Down Conv.",   "Red Zone",        "Pick-6",          "Holding Call",
            "False Start",     "Incomplete",       "Safety",          "2-Pt Conv.",      "Challenge Flag",
        ]
    )

    // Extended pool for shuffled boards
    static let nflExtended: [String] = [
        "Touchdown", "Field Goal", "Interception", "Sack", "Penalty Flag",
        "First Down", "Timeout Called", "4th Down", "QB Scramble", "Big Hit",
        "Fumble", "Punt", "Long Pass", "No Gain", "3rd Down Conv.",
        "Red Zone", "Pick-6", "Holding Call", "False Start", "Incomplete",
        "Safety", "2-Pt Conv.", "Challenge Flag", "Roughing Passer",
        "Offsides", "Hail Mary", "Onside Kick", "Blocked Punt",
        "End Around", "Screen Pass", "Play Action",
    ]
}

// MARK: - NBA Bingo

extension SportBingoPack {
    static let nba = SportBingoPack(
        sport: "NBA",
        labels: [
            "Three-Pointer",   "Slam Dunk",       "Technical Foul",  "Steal",           "Blocked Shot",
            "Free Throw",      "Timeout Called",   "Fast Break",      "Alley-Oop",       "And-One",
            "Turnover",        "Charge",           "FREE",            "Buzzer Beater",   "Double-Double",
            "Air Ball",        "Flagrant Foul",    "Paint Score",     "Offensive Reb.",   "Full-Court Press",
            "Assist",          "Crossover",        "Coach Challenge", "6th Man Score",   "Behind-the-Back",
        ]
    )
}

// MARK: - Soccer Bingo

extension SportBingoPack {
    static let soccer = SportBingoPack(
        sport: "Soccer",
        labels: [
            "Goal",            "Yellow Card",      "Corner Kick",     "Free Kick",       "Offside",
            "Substitution",    "Header",           "Penalty Kick",    "Save",            "Throw-In",
            "Red Card",        "Goal Kick",        "FREE",            "Crossbar Hit",    "Injury Time",
            "Bicycle Kick",    "Hat Trick",        "Own Goal",        "VAR Review",      "Handball",
            "Direct Free Kick","Long Ball",        "Dribble Run",     "Nutmeg",          "Clean Sheet",
        ]
    )
}

// MARK: - Pack Registry

extension SportBingoPack {
    /// Get the bingo pack for a given sport string
    static func pack(for sport: String) -> SportBingoPack {
        switch sport.lowercased() {
        case "nfl", "football":     return .nfl
        case "nba", "basketball":   return .nba
        case "soccer", "mls":       return .soccer
        default:                    return .nfl  // default to NFL for prototype
        }
    }
}
