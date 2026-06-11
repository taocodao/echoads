// AdModels.swift — Arenza
// Shared data models: ad segments, slots, game moments, prediction, rewards, betting.

import Foundation

// MARK: - Viewer Audience Segments (12 tiers, from AI profiling plan)

enum ViewerSegment: Int, Codable, CaseIterable {
    case premiumSportsFanatic  = 1
    case liveEventEnthusiast   = 2
    case sportsBettor          = 3
    case sportsCommerceBuyer   = 4
    case casualSportsFan       = 5
    case multiSportSuperfan    = 6
    case youngMale1834         = 7
    case householdDecisionMaker = 8
    case affluentSportsViewer  = 9
    case sportsTravelIntender  = 10
    case newViewerUnknown      = 11   // default
    case reEngagedLapsedUser   = 12

    var label: String {
        switch self {
        case .premiumSportsFanatic:     return "Premium Sports Fanatic"
        case .liveEventEnthusiast:      return "Live Event Enthusiast"
        case .sportsBettor:             return "Sports Bettor"
        case .sportsCommerceBuyer:      return "Sports Commerce Buyer"
        case .casualSportsFan:          return "Casual Sports Fan"
        case .multiSportSuperfan:       return "Multi-Sport Superfan"
        case .youngMale1834:            return "Young Male 18–34"
        case .householdDecisionMaker:   return "Household Decision Maker"
        case .affluentSportsViewer:     return "Affluent Sports Viewer"
        case .sportsTravelIntender:     return "Sports Travel Intender"
        case .newViewerUnknown:         return "New Viewer / Unknown"
        case .reEngagedLapsedUser:      return "Re-engaged Lapsed User"
        }
    }

    /// Target floor CPM in USD for this segment
    var targetCPM: ClosedRange<Double> {
        switch self {
        case .premiumSportsFanatic:     return 55...65
        case .liveEventEnthusiast:      return 50...60
        case .sportsBettor:             return 55...65
        case .sportsCommerceBuyer:      return 45...55
        case .casualSportsFan:          return 30...40
        case .multiSportSuperfan:       return 45...55
        case .youngMale1834:            return 45...60
        case .householdDecisionMaker:   return 40...50
        case .affluentSportsViewer:     return 55...65
        case .sportsTravelIntender:     return 50...60
        case .newViewerUnknown:         return 20...28
        case .reEngagedLapsedUser:      return 30...40
        }
    }

    var baseCPM: Double { targetCPM.lowerBound }
}

// MARK: - Game Moment (Contextual CPM multipliers)

enum GameMoment: String, Codable, CaseIterable {
    case goal         = "GOAL"
    case save         = "SAVE"
    case celebration  = "CELEBRATION"
    case foul         = "FOUL"
    case halftime     = "HALFTIME"
    case timeout      = "TIMEOUT"
    case preGame      = "PRE_GAME"
    case postGame     = "POST_GAME"
    case quarterBreak = "QUARTER_BREAK"
    case periodBreak  = "PERIOD_BREAK"
    case neutral      = "NEUTRAL"

    /// CPM multiplier vs. baseline neutral
    var cpmMultiplier: Double {
        switch self {
        case .goal, .celebration: return 1.35
        case .timeout:            return 1.15
        case .quarterBreak,
             .periodBreak:       return 1.10
        case .preGame:            return 1.05
        case .postGame:           return 0.90
        case .halftime:           return 0.85
        default:                  return 1.0
        }
    }

    /// Safe moments for betting CTAs (conservative whistle-to-whistle policy)
    var isBettingSafe: Bool {
        switch self {
        case .halftime, .preGame, .postGame, .quarterBreak, .periodBreak:
            return true
        default:
            return false
        }
    }

    /// Safe moments for prediction overlays
    var isPredictionTrigger: Bool {
        switch self {
        case .timeout, .halftime, .quarterBreak, .periodBreak:
            return true
        default:
            return false
        }
    }

    /// Human-readable label for campaign config display
    var displayLabel: String {
        switch self {
        case .goal:         return "Goal"
        case .save:         return "Save"
        case .celebration:  return "Celebration"
        case .foul:         return "Foul"
        case .halftime:     return "Halftime"
        case .timeout:      return "Timeout"
        case .preGame:      return "Pre-Game"
        case .postGame:     return "Post-Game"
        case .quarterBreak: return "Quarter Break"
        case .periodBreak:  return "Period Break"
        case .neutral:      return "Neutral"
        }
    }
}

// MARK: - Ad Event Types (for SignalCollector)

enum AdEventType: String, Codable {
    case adBreakStarted
    case adStarted
    case adCompleted
    case adSkipped
    case adQuartile25
    case adQuartile50
    case adQuartile75
    case overlayTapped
    case overlayExpanded
    case overlayDismissed
    case applePayInitiated
    case applePayCompleted
    case firstCommercePurchase
    case highEngagement
}

enum ContentEventType: String, Codable {
    case channelSelected
    case playbackStarted
    case playbackPaused
    case playbackResumed
    case playbackEnded
    case sportSearched
    case channelFavorited
    case notificationOpened
}

struct AdEvent: Codable {
    let type: AdEventType
    let creativeID: String
    let advertiserID: String
    let completionPercent: Double   // 0.0–1.0
    let timestamp: Date
    let sessionID: String
}

struct ContentEvent: Codable {
    let type: ContentEventType
    let channelID: String
    let sportType: String
    let isLive: Bool
    let timestamp: Date
    let sessionID: String
}

// MARK: - Viewer Feature Vector (fed into rule-based classifier / Core ML)

struct ViewerFeatureVector {
    var totalWatchTimeHours: Double
    var liveVsVODRatio: Double          // 0.0 (all VOD) → 1.0 (all live)
    var uniqueSportsWatched: Int
    var avgSessionDurationMinutes: Double
    var adEngagementRate: Double        // interactions per impression
    var adCompletionRate: Double        // avg % of ad watched
    var commerceInteractionCount: Int
    var apnsOpenRate: Double
    var skippedAdsRate: Double
    var sessionFrequencyPerWeek: Double
    var daysSinceFirstSession: Int
    var bettingOverlayTaps: Int
    var predictionParticipationRate: Double
}

// MARK: - House Ad

struct HouseAd: Codable, Identifiable {
    let id: String
    let advertiserID: String
    let advertiserName: String
    let creativeURL: URL
    let localFileURL: URL?
    let durationSeconds: Int
    let expiresAt: Date

    var isValid: Bool { expiresAt > Date() }
}

// MARK: - Bid Request Extension (CMXS OpenRTB extras)

struct CMXSBidExtension: Codable {
    let segmentID: Int
    let gameMoment: String
    let cpmMultiplierHint: Double
    let podPosition: Int
    let breakDurationSec: Int
    let secureEnclaveAttested: Bool
    let podVerification: String         // "base_l2"
}

// MARK: - EABN Request

struct EABNRequest: Codable {
    let channelID: String
    let expectedBreakTime: Date
    let breakDurationSeconds: Int
    let viewerSegmentID: Int
    let gameMoment: String
    let expectedImpressions: Int
    let floorCPMOverride: Double?
}

// MARK: - Session Anomaly Signals (fraud detection)

struct SessionAnomalySignals {
    var noOrientationChangeMinutes: Double
    var playbackEventsPerMinute: Double
    var adCompletionConsistency: Double   // stdev; 0.0 = all exactly 100%
    var pauseEventCount: Int
    var seekEventCount: Int
    var networkSwitchCount: Int
    var isMotionActive: Bool
}
