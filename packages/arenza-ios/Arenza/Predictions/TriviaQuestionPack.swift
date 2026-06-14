// TriviaQuestionPack.swift — Arenza (ArenzaTV Prototype)
// Sport-specific and sponsor-specific trivia question banks.
// Packs are loaded from MatchSim API or bundled JSON; each pack targets
// a specific team, head-to-head rivalry, or sponsor business.

import Foundation

// MARK: - Trivia Question Pack

struct TriviaQuestionPack: Codable, Identifiable {
    let id: UUID
    let sport: String                    // "NFL", "NBA", "Soccer"
    let teamIds: [String]                // ["PHI", "CHI"] — teams in the current game
    let category: TriviaPackCategory
    let sponsorId: String?               // non-nil for sponsor-branded packs
    let sponsorName: String?
    let title: String                    // "Eagles Franchise History"
    let subtitle: String?                // "Test your Philly knowledge!"
    let questions: [TriviaQuestion]      // reuses existing TriviaQuestion model

    /// Number of questions to serve per session (subset of total bank)
    var sessionSize: Int { min(5, questions.count) }

    /// Randomized subset for a single play session
    func sessionQuestions() -> [TriviaQuestion] {
        Array(questions.shuffled().prefix(sessionSize))
    }
}

// MARK: - Pack Category

enum TriviaPackCategory: String, Codable, CaseIterable {
    case teamHistory        = "team_history"       // "Eagles franchise history"
    case headToHead         = "head_to_head"       // "Eagles vs Bears rivalry"
    case playerStats        = "player_stats"       // "Jalen Hurts career stats"
    case sponsorBusiness    = "sponsor_business"   // "About our sponsor: Pepsi"
    case sportRules         = "sport_rules"        // "NFL rules deep dive"

    var emoji: String {
        switch self {
        case .teamHistory:     return "🏟️"
        case .headToHead:      return "⚔️"
        case .playerStats:     return "📊"
        case .sponsorBusiness: return "🏢"
        case .sportRules:      return "📖"
        }
    }

    var label: String {
        switch self {
        case .teamHistory:     return "Team History"
        case .headToHead:      return "Head-to-Head"
        case .playerStats:     return "Player Stats"
        case .sponsorBusiness: return "Sponsor Quiz"
        case .sportRules:      return "Rules Expert"
        }
    }

    /// AZT bonus multiplier for this category
    var aztMultiplier: Double {
        switch self {
        case .teamHistory:     return 1.0
        case .headToHead:      return 1.5    // harder, more niche
        case .playerStats:     return 1.25
        case .sponsorBusiness: return 1.0    // sponsor-funded, generous odds
        case .sportRules:      return 1.5
        }
    }
}

// MARK: - Demo Question Packs

extension TriviaQuestionPack {

    // MARK: Eagles Franchise History

    static let eaglesHistory = TriviaQuestionPack(
        id: UUID(),
        sport: "NFL",
        teamIds: ["PHI"],
        category: .teamHistory,
        sponsorId: nil,
        sponsorName: nil,
        title: "Eagles Franchise History",
        subtitle: "How well do you know Philly?",
        questions: [
            TriviaQuestion(
                id: UUID(), questionText: "In what year did the Eagles win their first Super Bowl?",
                options: [
                    TriviaOption(id: "a", label: "2018"), TriviaOption(id: "b", label: "2020"),
                    TriviaOption(id: "c", label: "2015"), TriviaOption(id: "d", label: "2023"),
                ],
                correctOptionId: "a", difficulty: .easy, sport: "NFL",
                sponsorId: nil, sponsorName: nil, aztReward: 10
            ),
            TriviaQuestion(
                id: UUID(), questionText: "Who was the Super Bowl LII MVP for the Eagles?",
                options: [
                    TriviaOption(id: "a", label: "Carson Wentz"), TriviaOption(id: "b", label: "Nick Foles"),
                    TriviaOption(id: "c", label: "Zach Ertz"), TriviaOption(id: "d", label: "Fletcher Cox"),
                ],
                correctOptionId: "b", difficulty: .medium, sport: "NFL",
                sponsorId: nil, sponsorName: nil, aztReward: 10
            ),
            TriviaQuestion(
                id: UUID(), questionText: "What stadium do the Eagles play their home games at?",
                options: [
                    TriviaOption(id: "a", label: "Lincoln Financial Field"), TriviaOption(id: "b", label: "Veterans Stadium"),
                    TriviaOption(id: "c", label: "Wells Fargo Center"), TriviaOption(id: "d", label: "Citizens Bank Park"),
                ],
                correctOptionId: "a", difficulty: .easy, sport: "NFL",
                sponsorId: nil, sponsorName: nil, aztReward: 10
            ),
            TriviaQuestion(
                id: UUID(), questionText: "Who holds the Eagles' all-time passing yards record?",
                options: [
                    TriviaOption(id: "a", label: "Donovan McNabb"), TriviaOption(id: "b", label: "Ron Jaworski"),
                    TriviaOption(id: "c", label: "Randall Cunningham"), TriviaOption(id: "d", label: "Michael Vick"),
                ],
                correctOptionId: "a", difficulty: .hard, sport: "NFL",
                sponsorId: nil, sponsorName: nil, aztReward: 10
            ),
            TriviaQuestion(
                id: UUID(), questionText: "What year were the Philadelphia Eagles founded?",
                options: [
                    TriviaOption(id: "a", label: "1933"), TriviaOption(id: "b", label: "1920"),
                    TriviaOption(id: "c", label: "1941"), TriviaOption(id: "d", label: "1955"),
                ],
                correctOptionId: "a", difficulty: .hard, sport: "NFL",
                sponsorId: nil, sponsorName: nil, aztReward: 10
            ),
        ]
    )

    // MARK: Bears Franchise History

    static let bearsHistory = TriviaQuestionPack(
        id: UUID(),
        sport: "NFL",
        teamIds: ["CHI"],
        category: .teamHistory,
        sponsorId: nil,
        sponsorName: nil,
        title: "Bears Franchise History",
        subtitle: "Da Bears challenge!",
        questions: [
            TriviaQuestion(
                id: UUID(), questionText: "Who holds the Bears' all-time rushing record?",
                options: [
                    TriviaOption(id: "a", label: "Walter Payton"), TriviaOption(id: "b", label: "Gale Sayers"),
                    TriviaOption(id: "c", label: "Matt Forte"), TriviaOption(id: "d", label: "Neal Anderson"),
                ],
                correctOptionId: "a", difficulty: .medium, sport: "NFL",
                sponsorId: nil, sponsorName: nil, aztReward: 10
            ),
            TriviaQuestion(
                id: UUID(), questionText: "In what year did the '85 Bears win the Super Bowl?",
                options: [
                    TriviaOption(id: "a", label: "1986"), TriviaOption(id: "b", label: "1985"),
                    TriviaOption(id: "c", label: "1984"), TriviaOption(id: "d", label: "1987"),
                ],
                correctOptionId: "a", difficulty: .easy, sport: "NFL",
                sponsorId: nil, sponsorName: nil, aztReward: 10
            ),
            TriviaQuestion(
                id: UUID(), questionText: "What is the famous Bears fight song called?",
                options: [
                    TriviaOption(id: "a", label: "Bear Down, Chicago Bears"), TriviaOption(id: "b", label: "Go Bears Go"),
                    TriviaOption(id: "c", label: "Monsters of the Midway"), TriviaOption(id: "d", label: "Chicago Strong"),
                ],
                correctOptionId: "a", difficulty: .medium, sport: "NFL",
                sponsorId: nil, sponsorName: nil, aztReward: 10
            ),
            TriviaQuestion(
                id: UUID(), questionText: "Who coached the Bears' only Super Bowl win?",
                options: [
                    TriviaOption(id: "a", label: "Mike Ditka"), TriviaOption(id: "b", label: "Lovie Smith"),
                    TriviaOption(id: "c", label: "George Halas"), TriviaOption(id: "d", label: "Dave Wannstedt"),
                ],
                correctOptionId: "a", difficulty: .easy, sport: "NFL",
                sponsorId: nil, sponsorName: nil, aztReward: 10
            ),
            TriviaQuestion(
                id: UUID(), questionText: "What number did Walter Payton wear?",
                options: [
                    TriviaOption(id: "a", label: "34"), TriviaOption(id: "b", label: "40"),
                    TriviaOption(id: "c", label: "22"), TriviaOption(id: "d", label: "32"),
                ],
                correctOptionId: "a", difficulty: .easy, sport: "NFL",
                sponsorId: nil, sponsorName: nil, aztReward: 10
            ),
        ]
    )

    // MARK: Eagles vs Bears Head-to-Head

    static let eaglesVsBears = TriviaQuestionPack(
        id: UUID(),
        sport: "NFL",
        teamIds: ["PHI", "CHI"],
        category: .headToHead,
        sponsorId: nil,
        sponsorName: nil,
        title: "Eagles vs Bears Rivalry",
        subtitle: "The all-time matchup",
        questions: [
            TriviaQuestion(
                id: UUID(), questionText: "Which team has won more games in the all-time series?",
                options: [
                    TriviaOption(id: "a", label: "Bears"), TriviaOption(id: "b", label: "Eagles"),
                    TriviaOption(id: "c", label: "Tied"), TriviaOption(id: "d", label: "Unknown"),
                ],
                correctOptionId: "a", difficulty: .medium, sport: "NFL",
                sponsorId: nil, sponsorName: nil, aztReward: 10
            ),
            TriviaQuestion(
                id: UUID(), questionText: "In the 2018 NFC Wild Card, who won Eagles vs Bears?",
                options: [
                    TriviaOption(id: "a", label: "Eagles"), TriviaOption(id: "b", label: "Bears"),
                    TriviaOption(id: "c", label: "Game was tied"), TriviaOption(id: "d", label: "They didn't play"),
                ],
                correctOptionId: "a", difficulty: .hard, sport: "NFL",
                sponsorId: nil, sponsorName: nil, aztReward: 10
            ),
        ]
    )

    // MARK: Pepsi Sponsor Quiz

    static let pepsiQuiz = TriviaQuestionPack(
        id: UUID(),
        sport: "NFL",
        teamIds: [],
        category: .sponsorBusiness,
        sponsorId: "pepsi",
        sponsorName: "Pepsi",
        title: "Pepsi Game Break",
        subtitle: "How well do you know Pepsi? 🥤",
        questions: [
            TriviaQuestion(
                id: UUID(), questionText: "What year was Pepsi founded?",
                options: [
                    TriviaOption(id: "a", label: "1893"), TriviaOption(id: "b", label: "1902"),
                    TriviaOption(id: "c", label: "1886"), TriviaOption(id: "d", label: "1910"),
                ],
                correctOptionId: "a", difficulty: .medium, sport: nil,
                sponsorId: "pepsi", sponsorName: "Pepsi", aztReward: 15
            ),
            TriviaQuestion(
                id: UUID(), questionText: "What is Pepsi's signature color?",
                options: [
                    TriviaOption(id: "a", label: "Blue"), TriviaOption(id: "b", label: "Red"),
                    TriviaOption(id: "c", label: "Green"), TriviaOption(id: "d", label: "Orange"),
                ],
                correctOptionId: "a", difficulty: .easy, sport: nil,
                sponsorId: "pepsi", sponsorName: "Pepsi", aztReward: 15
            ),
            TriviaQuestion(
                id: UUID(), questionText: "Which Super Bowl halftime show did Pepsi sponsor featuring Dr. Dre?",
                options: [
                    TriviaOption(id: "a", label: "Super Bowl LVI (2022)"), TriviaOption(id: "b", label: "Super Bowl LIII (2019)"),
                    TriviaOption(id: "c", label: "Super Bowl LIV (2020)"), TriviaOption(id: "d", label: "Super Bowl LV (2021)"),
                ],
                correctOptionId: "a", difficulty: .hard, sport: nil,
                sponsorId: "pepsi", sponsorName: "Pepsi", aztReward: 15
            ),
            TriviaQuestion(
                id: UUID(), questionText: "Pepsi is a product of which parent company?",
                options: [
                    TriviaOption(id: "a", label: "PepsiCo"), TriviaOption(id: "b", label: "Coca-Cola Co"),
                    TriviaOption(id: "c", label: "Nestlé"), TriviaOption(id: "d", label: "Dr Pepper Snapple"),
                ],
                correctOptionId: "a", difficulty: .easy, sport: nil,
                sponsorId: "pepsi", sponsorName: "Pepsi", aztReward: 15
            ),
            TriviaQuestion(
                id: UUID(), questionText: "What was Pepsi originally called when it was created?",
                options: [
                    TriviaOption(id: "a", label: "Brad's Drink"), TriviaOption(id: "b", label: "Pepsi-Cola"),
                    TriviaOption(id: "c", label: "Carolina Cola"), TriviaOption(id: "d", label: "Sweet Fizz"),
                ],
                correctOptionId: "a", difficulty: .hard, sport: nil,
                sponsorId: "pepsi", sponsorName: "Pepsi", aztReward: 15
            ),
        ]
    )

    // MARK: Domino's Sponsor Quiz

    static let dominosQuiz = TriviaQuestionPack(
        id: UUID(),
        sport: "NFL",
        teamIds: [],
        category: .sponsorBusiness,
        sponsorId: "dominos",
        sponsorName: "Domino's",
        title: "Domino's Game Break",
        subtitle: "Pizza knowledge challenge! 🍕",
        questions: [
            TriviaQuestion(
                id: UUID(), questionText: "What year was Domino's Pizza founded?",
                options: [
                    TriviaOption(id: "a", label: "1960"), TriviaOption(id: "b", label: "1975"),
                    TriviaOption(id: "c", label: "1952"), TriviaOption(id: "d", label: "1968"),
                ],
                correctOptionId: "a", difficulty: .medium, sport: nil,
                sponsorId: "dominos", sponsorName: "Domino's", aztReward: 15
            ),
            TriviaQuestion(
                id: UUID(), questionText: "How many dots are on the Domino's logo?",
                options: [
                    TriviaOption(id: "a", label: "3"), TriviaOption(id: "b", label: "5"),
                    TriviaOption(id: "c", label: "2"), TriviaOption(id: "d", label: "6"),
                ],
                correctOptionId: "a", difficulty: .easy, sport: nil,
                sponsorId: "dominos", sponsorName: "Domino's", aztReward: 15
            ),
            TriviaQuestion(
                id: UUID(), questionText: "What state was the first Domino's store located in?",
                options: [
                    TriviaOption(id: "a", label: "Michigan"), TriviaOption(id: "b", label: "New York"),
                    TriviaOption(id: "c", label: "Ohio"), TriviaOption(id: "d", label: "California"),
                ],
                correctOptionId: "a", difficulty: .medium, sport: nil,
                sponsorId: "dominos", sponsorName: "Domino's", aztReward: 15
            ),
        ]
    )

    // MARK: Tap Room (local business sponsor quiz)

    static let tapRoomQuiz = TriviaQuestionPack(
        id: UUID(),
        sport: "NFL",
        teamIds: [],
        category: .sponsorBusiness,
        sponsorId: "tap-room",
        sponsorName: "The Tap Room",
        title: "Tap Room Trivia",
        subtitle: "Know your local sports bar! 🍺",
        questions: [
            TriviaQuestion(
                id: UUID(), questionText: "What is The Tap Room's tagline?",
                options: [
                    TriviaOption(id: "a", label: "Watch the Game. Win the Deal."),
                    TriviaOption(id: "b", label: "Drink. Eat. Win."),
                    TriviaOption(id: "c", label: "Your Game Day HQ"),
                    TriviaOption(id: "d", label: "Sports & Suds"),
                ],
                correctOptionId: "a", difficulty: .easy, sport: nil,
                sponsorId: "tap-room", sponsorName: "The Tap Room", aztReward: 15
            ),
            TriviaQuestion(
                id: UUID(), questionText: "Where is The Tap Room located?",
                options: [
                    TriviaOption(id: "a", label: "Bleecker St, NYC"), TriviaOption(id: "b", label: "Broadway, NYC"),
                    TriviaOption(id: "c", label: "5th Ave, NYC"), TriviaOption(id: "d", label: "Houston St, NYC"),
                ],
                correctOptionId: "a", difficulty: .easy, sport: nil,
                sponsorId: "tap-room", sponsorName: "The Tap Room", aztReward: 15
            ),
            TriviaQuestion(
                id: UUID(), questionText: "Which category best describes The Tap Room?",
                options: [
                    TriviaOption(id: "a", label: "Sports Bar & Lounge"), TriviaOption(id: "b", label: "Fine Dining"),
                    TriviaOption(id: "c", label: "Coffee Shop"), TriviaOption(id: "d", label: "Fast Casual"),
                ],
                correctOptionId: "a", difficulty: .easy, sport: nil,
                sponsorId: "tap-room", sponsorName: "The Tap Room", aztReward: 15
            ),
        ]
    )

    // MARK: Pack Registry

    /// All available demo packs, keyed by pack identifier
    static let demoPacks: [String: TriviaQuestionPack] = [
        "eagles_history":  eaglesHistory,
        "bears_history":   bearsHistory,
        "eagles_vs_bears": eaglesVsBears,
        "pepsi":           pepsiQuiz,
        "dominos":         dominosQuiz,
        "tap_room":        tapRoomQuiz,
    ]

    /// Find packs relevant to a given match
    static func packsForMatch(homeTeamId: String, awayTeamId: String) -> [TriviaQuestionPack] {
        demoPacks.values.filter { pack in
            pack.teamIds.isEmpty ||  // sponsor packs apply to all games
            pack.teamIds.contains(homeTeamId) ||
            pack.teamIds.contains(awayTeamId) ||
            (pack.teamIds.contains(homeTeamId) && pack.teamIds.contains(awayTeamId))
        }
    }
}
