// PredictionModels.swift — Arenza
// Data models for the Play-to-Earn prediction engine and rewards wallet.

import Foundation

// MARK: - Prediction Question

struct PredictionQuestion: Codable, Identifiable {
    let id: UUID
    let gameID: String
    let channelID: String
    let triggerMoment: GameMoment
    let questionText: String
    let options: [PredictionOption]
    let timeWindowSeconds: Int          // how long user has to answer
    let pointValue: Int                 // base points for correct
    let difficultyMultiplier: Float     // 1.0–3.0
    let sponsorID: String?
    let sponsorName: String?
    let sponsorLogoURL: URL?
    let expiresAt: Date
    let category: PredictionCategory

    var isExpired: Bool { expiresAt < Date() }
    var adjustedPoints: Int { Int(Float(pointValue) * difficultyMultiplier) }
}

enum PredictionCategory: String, Codable {
    case nextScore       = "next_score"
    case nextPlay        = "next_play"
    case finalScore      = "final_score"
    case playerPerf      = "player_performance"
    case gameEvent       = "game_event"
    case trivia          = "trivia"
}

struct PredictionOption: Codable, Identifiable {
    let id: String
    let label: String
    let iconURL: URL?
    let impliedProbability: Float?       // used for difficulty multiplier
}

// MARK: - User's submitted prediction

struct UserPrediction: Codable, Identifiable {
    let id: UUID
    let questionID: UUID
    let selectedOptionID: String
    let submittedAt: Date
    let streakMultiplierApplied: Float
    var resolvedAt: Date?
    var isCorrect: Bool?
    var pointsEarned: Int?
    var timeToAnswerSeconds: Double?

    var isPending: Bool { resolvedAt == nil }
}

// MARK: - Resolution result from server / WebSocket

struct PredictionResolution: Codable {
    let questionID: UUID
    let correctOptionID: String
    let isCorrect: Bool                 // relative to this user's answer
    let basePoints: Int
    let streakMultiplier: Float
    let resolvedAt: Date

    var totalPoints: Int { Int(Float(basePoints) * streakMultiplier) }
}

// MARK: - AZT Entry (lightweight transaction record for history display)
//
// AZT = Arenza Tokens — simple integer points stored in the DB.
// Not a crypto token. No blockchain. Backend holds canonical balance;
// the app caches a local copy in UserDefaults.

struct AZTEntry: Codable, Identifiable {
    let id: UUID
    let amount: Int                     // positive = earned, negative = spent
    let source: AZTSource
    let date: Date
    let expiresAt: Date?                // nil = never expires; 90 days from earn by default
    let gameId: String?
    let sponsorId: String?

    var isExpired: Bool {
        guard let exp = expiresAt else { return false }
        return exp < Date()
    }
}

enum AZTSource: String, Codable {
    case prediction     = "prediction"
    case poll           = "poll"
    case trivia         = "trivia"
    case adView         = "ad_view"
    case dailyCheckIn   = "daily_checkin"
    case streakBonus    = "streak_bonus"
    case referral       = "referral"
    case socialShare    = "social_share"
    case spinGame       = "spin_game"        // spin/scratch reward
    case businessShare  = "business_share"   // shared sponsor info
    case redemption     = "redemption"       // negative (spend)
    case landscapeUnlock = "landscape_unlock" // negative (spend for fullscreen)
    case expired        = "expired"          // negative (auto-expire)
}

// MARK: - Rewards Wallet

struct RewardsWallet: Codable {
    var aztBalance: Int                 // total active AZT (DB is source of truth)
    var weeklyAZT: Int                  // earned this week
    var seasonAZT: Int                  // earned this season (drives tier)
    var currentStreak: Int
    var bestStreak: Int
    var tier: RewardsTier
    var availableCoupons: [SponsorCoupon]
    var redeemedCoupons: [SponsorCoupon]
    var pendingAZT: Int                 // from unresolved predictions
    var aztHistory: [AZTEntry]          // recent transaction log for UI
    var lastCheckInDate: Date?          // tracks daily check-in streak

    static var empty: RewardsWallet {
        RewardsWallet(
            aztBalance: 0, weeklyAZT: 0, seasonAZT: 0,
            currentStreak: 0, bestStreak: 0, tier: .bronze,
            availableCoupons: [], redeemedCoupons: [],
            pendingAZT: 0, aztHistory: [], lastCheckInDate: nil
        )
    }

    // MARK: - Earn AZT (positive)

    mutating func earn(_ amount: Int, source: AZTSource, gameId: String? = nil, sponsorId: String? = nil) {
        aztBalance += amount
        weeklyAZT  += amount
        seasonAZT  += amount
        tier = RewardsTier.tier(for: seasonAZT)

        let entry = AZTEntry(
            id: UUID(), amount: amount, source: source,
            date: Date(),
            expiresAt: Date().addingTimeInterval(90 * 86400), // 90-day expiry
            gameId: gameId, sponsorId: sponsorId
        )
        aztHistory.insert(entry, at: 0)

        // Cap history to last 200 entries locally
        if aztHistory.count > 200 { aztHistory = Array(aztHistory.prefix(200)) }
    }

    // MARK: - Spend AZT (negative)

    mutating func spend(_ amount: Int, source: AZTSource = .redemption, sponsorId: String? = nil) -> Bool {
        guard aztBalance >= amount else { return false }
        aztBalance -= amount

        let entry = AZTEntry(
            id: UUID(), amount: -amount, source: source,
            date: Date(), expiresAt: nil,
            gameId: nil, sponsorId: sponsorId
        )
        aztHistory.insert(entry, at: 0)
        if aztHistory.count > 200 { aztHistory = Array(aztHistory.prefix(200)) }
        return true
    }

    // MARK: - Apply prediction resolution (updates streak + awards AZT)

    mutating func applyResolution(_ resolution: PredictionResolution) {
        pendingAZT = max(0, pendingAZT - resolution.basePoints)
        if resolution.isCorrect {
            earn(resolution.totalPoints, source: .prediction)
            currentStreak += 1
            bestStreak     = max(bestStreak, currentStreak)
        } else {
            currentStreak = 0
        }
        tier = RewardsTier.tier(for: seasonAZT)
    }

    // MARK: - Daily check-in

    mutating func performDailyCheckIn() -> Int {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())

        // Already checked in today?
        if let last = lastCheckInDate, cal.isDate(last, inSameDayAs: today) {
            return 0
        }

        lastCheckInDate = today
        var bonus = 10  // base daily AZT

        // 7-day streak bonus
        if currentStreak >= 7 && currentStreak.isMultiple(of: 7) {
            bonus += 50
            earn(50, source: .streakBonus)
        }

        earn(bonus, source: .dailyCheckIn)
        return bonus
    }
}

// MARK: - Rewards Tier

enum RewardsTier: String, Codable, CaseIterable, Comparable {
    case bronze   = "bronze"    // 0–499 season pts
    case silver   = "silver"    // 500–1,999
    case gold     = "gold"      // 2,000–4,999
    case platinum = "platinum"  // 5,000+

    static func tier(for seasonPoints: Int) -> RewardsTier {
        switch seasonPoints {
        case 0..<500:   return .bronze
        case 500..<2000: return .silver
        case 2000..<5000: return .gold
        default:         return .platinum
        }
    }

    var label: String { rawValue.capitalized }

    var emoji: String {
        switch self {
        case .bronze:   return "🥉"
        case .silver:   return "🥈"
        case .gold:     return "🥇"
        case .platinum: return "💎"
        }
    }

    var minPoints: Int {
        switch self {
        case .bronze:   return 0
        case .silver:   return 500
        case .gold:     return 2000
        case .platinum: return 5000
        }
    }

    static func < (lhs: RewardsTier, rhs: RewardsTier) -> Bool {
        lhs.minPoints < rhs.minPoints
    }
}

// MARK: - Sponsor Coupon

enum CouponCategory: String, Codable {
    case food           = "food"
    case sports         = "sports"
    case betting        = "betting"
    case retail         = "retail"
    case travel         = "travel"
    case streaming      = "streaming"
    case electronics    = "electronics"
    case entertainment  = "entertainment"
}

struct SponsorCoupon: Codable, Identifiable {
    let id: UUID
    let sponsorID: String
    let sponsorName: String
    let sponsorLogoURL: URL?
    let description: String             // "20% off your next order"
    let couponCode: String
    let deepLinkURL: URL?               // "dominos://promo?code=ARENZA20"
    let sponsorWebURL: URL?
    let expiresAt: Date
    let minimumPurchase: Double?
    let maximumDiscount: Double?
    let category: CouponCategory
    let aztCost: Int                    // AZT required to redeem
    var isRedeemed: Bool
    var redeemedAt: Date?
    var unlockedAt: Date

    var isExpired: Bool { expiresAt < Date() }
    var isValid: Bool { !isExpired && !isRedeemed }
    var daysUntilExpiry: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: expiresAt).day ?? 0
    }

    // Backward compat alias
    var pointCost: Int { aztCost }

    // Demo coupon for UI testing
    static func demo() -> SponsorCoupon {
        SponsorCoupon(
            id: UUID(),
            sponsorID: "dominos",
            sponsorName: "Domino's",
            sponsorLogoURL: nil,
            description: "20% off your next order",
            couponCode: "ARENZA20",
            deepLinkURL: URL(string: "https://www.dominos.com/?promo=ARENZA20"),
            sponsorWebURL: URL(string: "https://www.dominos.com"),
            expiresAt: Date().addingTimeInterval(7 * 86400),
            minimumPurchase: 15.00,
            maximumDiscount: 10.00,
            category: .food,
            aztCost: 2500,              // 2,500 AZT ≈ $2.50 implied value
            isRedeemed: false,
            redeemedAt: nil,
            unlockedAt: Date()
        )
    }
}

// MARK: - Leaderboard

struct LeaderboardEntry: Codable, Identifiable {
    let id: UUID
    let userID: String
    let displayName: String
    let avatarURL: URL?
    let rank: Int
    let points: Int
    let correctPredictions: Int
    let totalPredictions: Int
    let currentStreak: Int
    let tier: RewardsTier

    var accuracy: Double {
        guard totalPredictions > 0 else { return 0 }
        return Double(correctPredictions) / Double(totalPredictions)
    }

    var accuracyFormatted: String {
        String(format: "%.0f%%", accuracy * 100)
    }
}

enum LeaderboardScope: String, CaseIterable, Identifiable {
    case weekly  = "weekly"
    case monthly = "monthly"
    case season  = "season"
    case local   = "local"      // DMA-scoped leaderboard
    case friends = "friends"    // custom private league

    var id: String { rawValue }
    var label: String { rawValue.capitalized }
}
