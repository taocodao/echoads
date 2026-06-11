// SponsorCampaign.swift — Arenza (Phase 4: Sponsor CMS Integration)
// Models for sponsor campaigns, attribution tracking, and webhook payloads.
// The B2B dashboard (web) creates campaigns; the iOS app consumes and renders them.

import Foundation

// MARK: - Sponsor Campaign

struct SponsorCampaign: Codable, Identifiable {
    let id: UUID
    let sponsorId: String
    let sponsorName: String
    let brandLogoURL: URL?
    let brandColor: String              // hex e.g. "#FF0000"
    let brandTagline: String?
    let adFormat: AdFormat
    let prizeTiers: [PrizeTier]
    let couponPrefix: String            // e.g. "PEPSI", "DOM"
    let targetSport: String?
    let targetGameDate: Date?
    let triggerMoments: [GameMoment]    // from AdModels.swift
    let pointsBudget: Int               // sponsor-allocated AZT pool
    let maxWinnersPerGame: Int
    let status: CampaignStatus
    let pricingTier: PricingTier
    let redemptionWebhookURL: URL?
    let fulfillmentEmail: String?
    let createdAt: Date
    let startsAt: Date
    let endsAt: Date
    let metrics: CampaignMetrics?

    var isActive: Bool {
        status == .live && Date() >= startsAt && Date() <= endsAt
    }

    var isUpcoming: Bool {
        status == .live && Date() < startsAt
    }
}

// MARK: - Ad Format Type

enum AdFormat: String, Codable, CaseIterable {
    case prediction   = "prediction"
    case bingo        = "bingo"
    case scratchCard  = "scratch_card"
    case moreLess     = "more_less"

    var displayName: String {
        switch self {
        case .prediction:  return "Live Prediction"
        case .bingo:       return "Bingo Card"
        case .scratchCard: return "Scratch & Win"
        case .moreLess:    return "More or Less"
        }
    }

    var icon: String {
        switch self {
        case .prediction:  return "sparkles"
        case .bingo:       return "checkerboard.rectangle"
        case .scratchCard: return "ticket.fill"
        case .moreLess:    return "arrow.up.arrow.down"
        }
    }

    var emoji: String {
        switch self {
        case .prediction:  return "🔮"
        case .bingo:       return "🎯"
        case .scratchCard: return "🎰"
        case .moreLess:    return "📊"
        }
    }
}

// MARK: - Prize Tier

struct PrizeTier: Codable, Identifiable {
    let id: UUID
    let label: String                   // "Small", "Medium", "Jackpot"
    let value: PrizeValue
    let quantity: Int                   // max per game
    let expiryHours: Int               // coupon TTL after reveal
    let odds: Double                   // 0.0–1.0 probability

    var oddsFormatted: String {
        if odds >= 1.0 { return "Guaranteed" }
        return "\(Int(odds * 100))%"
    }
}

enum PrizeValue: Codable {
    case percent(Int)                   // e.g. 30% off
    case fixed(Double)                  // e.g. $5 off
    case freeItem(String)              // e.g. "Free brownie"
    case points(Int)                   // e.g. +500 AZT

    var displayText: String {
        switch self {
        case .percent(let p):    return "\(p)% OFF"
        case .fixed(let f):      return "$\(String(format: "%.0f", f)) OFF"
        case .freeItem(let i):   return "FREE \(i.uppercased())"
        case .points(let p):     return "+\(p) AZT"
        }
    }
}

// MARK: - Campaign Status

enum CampaignStatus: String, Codable {
    case draft    = "draft"
    case review   = "review"
    case live     = "live"
    case paused   = "paused"
    case ended    = "ended"

    var color: String {
        switch self {
        case .draft:  return "gray"
        case .review: return "orange"
        case .live:   return "green"
        case .paused: return "yellow"
        case .ended:  return "red"
        }
    }
}

// MARK: - Pricing Tier

enum PricingTier: String, Codable, CaseIterable {
    case starter    = "starter"     // 1 campaign/month, basic analytics
    case season     = "season"      // unlimited campaigns, full analytics
    case enterprise = "enterprise"  // white-label, API access, dedicated support

    var label: String { rawValue.capitalized }

    var monthlyFee: Double {
        switch self {
        case .starter:    return 499
        case .season:     return 1999
        case .enterprise: return 4999
        }
    }
}

// MARK: - Campaign Metrics (from B2B dashboard API)

struct CampaignMetrics: Codable {
    let totalImpressions: Int
    let totalInteractions: Int
    let optInRate: Double               // 0.0–1.0
    let avgSessionTime: Double          // seconds
    let couponsIssued: Int
    let couponsRevealed: Int
    let couponsRedeemed: Int
    let redemptionRate: Double          // 0.0–1.0
    let revenueAttributed: Double       // sponsor-reported
    let uniqueUsers: Int
    let engagementFunnel: EngagementFunnel?

    var interactionRate: Double {
        guard totalImpressions > 0 else { return 0 }
        return Double(totalInteractions) / Double(totalImpressions)
    }
}

struct EngagementFunnel: Codable {
    let views: Int
    let plays: Int
    let correct: Int
    let couponRevealed: Int
    let couponRedeemed: Int
}

// MARK: - Attribution Event (sent to sponsor webhook)

struct AttributionEvent: Codable {
    let event: String                   // "coupon.redeemed", "impression", "click"
    let timestamp: Date
    let data: AttributionData
}

struct AttributionData: Codable {
    let orderId: String
    let couponCode: String
    let sponsorId: String
    let campaignId: String
    let fan: FanAttribution
    let prize: PrizeAttribution?
    let gameContext: GameContext?
}

struct FanAttribution: Codable {
    let anonymousId: String             // hashed, never PII
    let ageRange: String?               // "18-24", "25-34", etc.
    let engagementTier: String          // "casual", "active", "superfan"
}

struct PrizeAttribution: Codable {
    let type: String                    // "percent", "fixed", "free_item"
    let value: String
}

struct GameContext: Codable {
    let sport: String
    let team: String?
    let gameId: String?
}

// MARK: - Demo Campaigns

extension SponsorCampaign {
    static let demoCampaigns: [SponsorCampaign] = [
        SponsorCampaign(
            id: UUID(), sponsorId: "pepsi", sponsorName: "Pepsi",
            brandLogoURL: nil, brandColor: "#004B93",
            brandTagline: "For the Love of It",
            adFormat: .prediction,
            prizeTiers: [
                PrizeTier(id: UUID(), label: "Consolation", value: .points(25), quantity: 999, expiryHours: 48, odds: 1.0),
                PrizeTier(id: UUID(), label: "Small Win", value: .percent(15), quantity: 100, expiryHours: 48, odds: 0.4),
                PrizeTier(id: UUID(), label: "Jackpot", value: .freeItem("12-Pack"), quantity: 10, expiryHours: 24, odds: 0.05),
            ],
            couponPrefix: "PEPSI",
            targetSport: "NFL", targetGameDate: Date().addingTimeInterval(86400),
            triggerMoments: [.halftime, .quarterBreak],
            pointsBudget: 50000, maxWinnersPerGame: 200,
            status: .live, pricingTier: .season,
            redemptionWebhookURL: URL(string: "https://api.pepsi.example/webhooks/arenza"),
            fulfillmentEmail: "promo@pepsi.example",
            createdAt: Date().addingTimeInterval(-7 * 86400),
            startsAt: Date().addingTimeInterval(-86400),
            endsAt: Date().addingTimeInterval(30 * 86400),
            metrics: CampaignMetrics(
                totalImpressions: 48291, totalInteractions: 37680,
                optInRate: 0.78, avgSessionTime: 142,
                couponsIssued: 1840, couponsRevealed: 1520, couponsRedeemed: 487,
                redemptionRate: 0.32, revenueAttributed: 14350.0,
                uniqueUsers: 12400,
                engagementFunnel: EngagementFunnel(
                    views: 48291, plays: 37680, correct: 18900,
                    couponRevealed: 1520, couponRedeemed: 487
                )
            )
        ),
        SponsorCampaign(
            id: UUID(), sponsorId: "dominos", sponsorName: "Domino's",
            brandLogoURL: nil, brandColor: "#006491",
            brandTagline: "It's What We Do",
            adFormat: .scratchCard,
            prizeTiers: [
                PrizeTier(id: UUID(), label: "Try Again", value: .points(25), quantity: 999, expiryHours: 48, odds: 0.55),
                PrizeTier(id: UUID(), label: "Free Breadsticks", value: .freeItem("Breadsticks"), quantity: 200, expiryHours: 48, odds: 0.3),
                PrizeTier(id: UUID(), label: "30% Off", value: .percent(30), quantity: 50, expiryHours: 24, odds: 0.12),
                PrizeTier(id: UUID(), label: "Free Pizza!", value: .freeItem("Large Pizza"), quantity: 5, expiryHours: 12, odds: 0.03),
            ],
            couponPrefix: "DOM",
            targetSport: "NFL", targetGameDate: nil,
            triggerMoments: [.halftime],
            pointsBudget: 30000, maxWinnersPerGame: 150,
            status: .live, pricingTier: .starter,
            redemptionWebhookURL: URL(string: "https://api.dominos.example/webhooks/arenza"),
            fulfillmentEmail: "promo@dominos.example",
            createdAt: Date().addingTimeInterval(-14 * 86400),
            startsAt: Date().addingTimeInterval(-3 * 86400),
            endsAt: Date().addingTimeInterval(21 * 86400),
            metrics: CampaignMetrics(
                totalImpressions: 22100, totalInteractions: 18500,
                optInRate: 0.84, avgSessionTime: 96,
                couponsIssued: 3200, couponsRevealed: 2800, couponsRedeemed: 896,
                redemptionRate: 0.32, revenueAttributed: 8960.0,
                uniqueUsers: 8200,
                engagementFunnel: EngagementFunnel(
                    views: 22100, plays: 18500, correct: 9250,
                    couponRevealed: 2800, couponRedeemed: 896
                )
            )
        ),
        SponsorCampaign(
            id: UUID(), sponsorId: "budweiser", sponsorName: "Budweiser",
            brandLogoURL: nil, brandColor: "#C8102E",
            brandTagline: "King of Beers",
            adFormat: .bingo,
            prizeTiers: [
                PrizeTier(id: UUID(), label: "1 Line", value: .points(500), quantity: 100, expiryHours: 48, odds: 0.20),
                PrizeTier(id: UUID(), label: "2 Lines", value: .percent(20), quantity: 30, expiryHours: 24, odds: 0.08),
                PrizeTier(id: UUID(), label: "Blackout", value: .freeItem("6-Pack"), quantity: 5, expiryHours: 12, odds: 0.01),
            ],
            couponPrefix: "BUD",
            targetSport: "NFL", targetGameDate: nil,
            triggerMoments: [.quarterBreak, .halftime, .periodBreak],
            pointsBudget: 40000, maxWinnersPerGame: 100,
            status: .live, pricingTier: .enterprise,
            redemptionWebhookURL: URL(string: "https://api.abinbev.example/webhooks/arenza"),
            fulfillmentEmail: "sports@abinbev.example",
            createdAt: Date().addingTimeInterval(-21 * 86400),
            startsAt: Date().addingTimeInterval(-7 * 86400),
            endsAt: Date().addingTimeInterval(60 * 86400),
            metrics: CampaignMetrics(
                totalImpressions: 65000, totalInteractions: 50700,
                optInRate: 0.78, avgSessionTime: 210,
                couponsIssued: 980, couponsRevealed: 850, couponsRedeemed: 280,
                redemptionRate: 0.33, revenueAttributed: 19600.0,
                uniqueUsers: 22100,
                engagementFunnel: EngagementFunnel(
                    views: 65000, plays: 50700, correct: 25350,
                    couponRevealed: 850, couponRedeemed: 280
                )
            )
        ),
    ]
}
