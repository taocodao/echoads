// BettingModels.swift — Arenza
// Data models for the sports betting affiliate integration.

import Foundation

// MARK: - US States with Legal Online Sports Betting (June 2026)

let legalBettingStates: Set<String> = [
    "AZ", "CO", "CT", "DC", "DE", "FL", "IA", "IL", "IN", "KS",
    "KY", "LA", "MA", "MD", "ME", "MI", "MS", "MT", "NC", "NE",
    "NH", "NJ", "NY", "OH", "OR", "PA", "PR", "RI", "TN", "VA",
    "VT", "WA", "WV", "WY"
]

// MARK: - Live Odds

struct LiveOdds: Codable, Identifiable {
    let id: String
    let eventID: String
    let homeTeam: String
    let awayTeam: String
    let homeMoneyline: String          // e.g. "-145"
    let awayMoneyline: String          // e.g. "+120"
    let spread: String?                // e.g. "PHX -3.5"
    let total: String?                 // e.g. "O/U 214.5"
    let aiSuggestedBet: AIBetSuggestion?
    let updatedAt: Date

    var allLines: [String] {
        [homeTeam, homeMoneyline, awayTeam, awayMoneyline].compactMap { $0 }
    }

    static func demo(homeTeam: String, awayTeam: String) -> LiveOdds {
        LiveOdds(
            id: UUID().uuidString,
            eventID: "demo_event",
            homeTeam: homeTeam,
            awayTeam: awayTeam,
            homeMoneyline: "-115",
            awayMoneyline: "-105",
            spread: "\(homeTeam) -1.5",
            total: "O/U 221.5",
            aiSuggestedBet: AIBetSuggestion(
                description: "Moneyline \(homeTeam) at -115",
                reasoning: "Strong home record this season"
            ),
            updatedAt: Date()
        )
    }
}

struct AIBetSuggestion: Codable {
    let description: String
    let reasoning: String
}

// MARK: - Betting Trigger Reason

enum BettingTriggerReason: CustomStringConvertible {
    case adBreakOpportunity
    case gameStateMoment(GameMoment)

    var description: String {
        switch self {
        case .adBreakOpportunity:        return "ad_break"
        case .gameStateMoment(let m):   return m.rawValue.lowercased()
        }
    }
}

// MARK: - Betting Trigger Policy

enum BettingTriggerPolicy {
    case conservative   // Breaks + halftime only — safe in all states
    case standard       // Adds pre/post-game, quarter/period breaks
    case extended       // All moments — do NOT enable without legal review
}

// MARK: - Betting Overlay Context (shown in BetSlipOverlayView)

struct BettingOverlayContext: Identifiable {
    let id = UUID()
    let odds: LiveOdds
    let triggerReason: BettingTriggerReason
    let breakDuration: TimeInterval
    let deepLinkURL: URL
    let responsibleGamingText: String
    let affiliatePartner: AffiliatePartner
    let createdAt: Date

    init(
        odds: LiveOdds,
        triggerReason: BettingTriggerReason,
        breakDuration: TimeInterval = 30,
        affiliatePartner: AffiliatePartner = .draftKings
    ) {
        self.odds = odds
        self.triggerReason = triggerReason
        self.breakDuration = breakDuration
        self.affiliatePartner = affiliatePartner
        self.responsibleGamingText = "Gambling Problem? Call 1-800-GAMBLER"
        self.deepLinkURL = affiliatePartner.buildDeepLink(odds: odds)
        self.createdAt = Date()
    }

    /// Scripted demo context — Patriots vs Eagles, DraftKings, live in-play odds.
    static func demo(channelID: String) -> BettingOverlayContext {
        let odds = LiveOdds(
            id: "demo_nfl_001",
            eventID: channelID,
            homeTeam: "Patriots",
            awayTeam: "Eagles",
            homeMoneyline: "-140",
            awayMoneyline: "+118",
            spread: "Patriots -3.5",
            total: "O/U 44.5",
            aiSuggestedBet: AIBetSuggestion(
                description: "Patriots -3.5 spread",
                reasoning: "Home field advantage + Eagles 3rd-quarter struggles (22% cover rate)"
            ),
            updatedAt: Date()
        )
        return BettingOverlayContext(
            odds: odds,
            triggerReason: .adBreakOpportunity,
            breakDuration: 30,
            affiliatePartner: .draftKings
        )
    }
}


// MARK: - Affiliate Partner

enum AffiliatePartner: String, Codable {
    case draftKings  = "draftkings"
    case fanDuel     = "fanduel"
    case betMGM      = "betmgm"
    case fanatics    = "fanatics"

    var displayName: String {
        switch self {
        case .draftKings: return "DraftKings"
        case .fanDuel:    return "FanDuel"
        case .betMGM:     return "BetMGM"
        case .fanatics:   return "Fanatics"
        }
    }

    var brandColor: String {
        switch self {
        case .draftKings: return "#53D337"
        case .fanDuel:    return "#1493FF"
        case .betMGM:     return "#C8A84B"
        case .fanatics:   return "#E31837"
        }
    }

    // Build affiliate deep link — replace with actual affiliate IDs at launch
    func buildDeepLink(odds: LiveOdds) -> URL {
        switch self {
        case .draftKings:
            var components = URLComponents(string: "https://www.draftkings.com/lobby")!
            components.queryItems = [
                URLQueryItem(name: "event", value: odds.eventID),
                URLQueryItem(name: "utm_source", value: "arenza"),
                URLQueryItem(name: "utm_medium", value: "overlay"),
                URLQueryItem(name: "utm_campaign", value: "live_betting")
            ]
            return components.url ?? URL(string: "https://www.draftkings.com")!

        case .fanDuel:
            var components = URLComponents(string: "https://www.fanduel.com/sportsbook")!
            components.queryItems = [
                URLQueryItem(name: "utm_source", value: "arenza"),
                URLQueryItem(name: "event_id", value: odds.eventID)
            ]
            return components.url ?? URL(string: "https://www.fanduel.com")!

        default:
            return URL(string: "https://\(rawValue).com")!
        }
    }
}

// MARK: - Affiliate Click Event (for CPA attribution)

struct AffiliateClickEvent: Codable {
    let sessionToken: String          // HMAC-SHA256 of deviceID + hourSlot — not PII
    let eventID: String
    let triggerMoment: String
    let oddsDisplayed: [String]
    let timestamp: Int64
    let affiliatePartner: String
}

// MARK: - Self-Exclusion Response

struct SelfExclusionResponse: Codable {
    let excluded: Bool
    let reason: String?
}
