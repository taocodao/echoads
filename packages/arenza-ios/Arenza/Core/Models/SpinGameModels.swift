// SpinGameModels.swift — Arenza (TableSpin Integration)
// Data models for sponsor-branded spin/scratch games and QR membership wallet.

import Foundation
import SwiftUI

// MARK: - Sponsor Business

struct SponsorBusiness: Identifiable {
    let id: String
    let name: String
    let tagline: String
    let emoji: String
    let brandColor: String          // hex
    let brandColorSecondary: String
    let category: BusinessCategory
    let websiteURL: String
    let address: String
    let phoneNumber: String
    let spinConfig: SpinConfig

    var brandSwiftColor: Color { Color(arenza: brandColor) }
    var secondarySwiftColor: Color { Color(arenza: brandColorSecondary) }
}

enum BusinessCategory: String {
    case restaurant = "Restaurant"
    case bar        = "Bar & Lounge"
    case cafe       = "Café"
    case qsr        = "Fast Casual"
    case venue      = "Venue"
}

// MARK: - Spin Config

struct SpinConfig {
    let maxDailySpins: Int
    let rewardExpiryMinutes: Int
    let segments: [WheelSegment]
}

struct WheelSegment: Identifiable {
    let id: String
    let label: String
    let emoji: String
    let rewardType: SpinRewardType
    let rewardValue: String         // "20%", "$5", "Free Edamame"
    let probability: Double         // 0.0–1.0 (must sum to 1.0)
    let color: String               // hex
    let isWin: Bool                 // false = "Try Again"
}

enum SpinRewardType: String {
    case percentOff     = "percent_off"
    case fixedDiscount  = "fixed"
    case freeItem       = "free_item"
    case bonusPoints    = "bonus_pts"
    case tryAgain       = "try_again"
    case mystery        = "mystery"
}

// MARK: - Spin Reward (won prize)

struct SpinReward: Identifiable {
    let id: UUID
    let rewardCode: String
    let sponsorId: String
    let sponsorName: String
    let sponsorEmoji: String
    let sponsorBrandColor: String
    let sponsorWebsiteURL: String
    let rewardType: SpinRewardType
    let rewardLabel: String
    let rewardValue: String
    var status: RewardStatus
    let createdAt: Date
    let expiresAt: Date
    var claimedAt: Date?

    var isExpired: Bool { expiresAt < Date() && status == .active }
    var isValid: Bool   { status == .active && !isExpired }
    var timeRemaining: TimeInterval { max(0, expiresAt.timeIntervalSinceNow) }

    var qrPayload: String {
        // Simple signed payload (production would be HMAC-SHA256)
        let payload: [String: String] = [
            "v": "1", "type": "reward",
            "rid": id.uuidString, "sid": sponsorId,
            "code": rewardCode, "exp": "\(Int(expiresAt.timeIntervalSince1970))"
        ]
        return (try? JSONSerialization.data(withJSONObject: payload))
            .flatMap { String(data: $0, encoding: .utf8) } ?? rewardCode
    }
}

enum RewardStatus: String {
    case active  = "active"
    case claimed = "claimed"
    case expired = "expired"
}

// MARK: - Member Card

struct MemberCard: Identifiable {
    let id: String                  // same as sponsorId
    let memberId: String
    let sponsorId: String
    let sponsorName: String
    let sponsorEmoji: String
    let sponsorBrandColor: String
    let sponsorWebsiteURL: String
    let tierLabel: String
    let tierEmoji: String
    let tierColor: String
    let totalPoints: Int
    let totalSpend: Double
    let memberSince: Date

    var qrPayload: String {
        let payload: [String: String] = [
            "v": "1", "type": "member",
            "mid": memberId, "sid": sponsorId
        ]
        return (try? JSONSerialization.data(withJSONObject: payload))
            .flatMap { String(data: $0, encoding: .utf8) } ?? memberId
    }
}

// MARK: - Demo Sponsor Businesses

extension SponsorBusiness {
    static let all: [SponsorBusiness] = [sakuraBites, copperGrill, tapRoom, blueAgave]

    // 1. Sakura Bites — Japanese-NYC Fusion
    static let sakuraBites = SponsorBusiness(
        id: "sakura-bites",
        name: "Sakura Bites",
        tagline: "Japanese-NYC Fusion",
        emoji: "🌸",
        brandColor: "#c9924e",
        brandColorSecondary: "#8b1a1a",
        category: .restaurant,
        websiteURL: "https://sakurabites.com",
        address: "342 W 44th St, New York, NY 10036",
        phoneNumber: "(212) 555-0181",
        spinConfig: SpinConfig(
            maxDailySpins: 3,
            rewardExpiryMinutes: 5,
            segments: [
                WheelSegment(id: "sb1", label: "10% OFF",       emoji: "🎉", rewardType: .percentOff,    rewardValue: "10%",           probability: 0.20, color: "#c9924e", isWin: true),
                WheelSegment(id: "sb2", label: "Try Again",     emoji: "🔄", rewardType: .tryAgain,      rewardValue: "",              probability: 0.22, color: "#3a3a3a", isWin: false),
                WheelSegment(id: "sb3", label: "Free Edamame",  emoji: "🫘", rewardType: .freeItem,      rewardValue: "Free Edamame",  probability: 0.18, color: "#2a6e3a", isWin: true),
                WheelSegment(id: "sb4", label: "+200 AZT",      emoji: "⭐", rewardType: .bonusPoints,   rewardValue: "200 AZT",       probability: 0.15, color: "#7c3aed", isWin: true),
                WheelSegment(id: "sb5", label: "20% OFF",       emoji: "🔥", rewardType: .percentOff,    rewardValue: "20%",           probability: 0.10, color: "#8b1a1a", isWin: true),
                WheelSegment(id: "sb6", label: "Try Again",     emoji: "🔄", rewardType: .tryAgain,      rewardValue: "",              probability: 0.07, color: "#2a2a2a", isWin: false),
                WheelSegment(id: "sb7", label: "Free Mochi",    emoji: "🍡", rewardType: .freeItem,      rewardValue: "Free Mochi",    probability: 0.05, color: "#d946ef", isWin: true),
                WheelSegment(id: "sb8", label: "Mystery 🎁",    emoji: "🎁", rewardType: .mystery,       rewardValue: "Mystery Prize", probability: 0.03, color: "#c9924e", isWin: true),
            ]
        )
    )

    // 2. The Copper Grill — American Steakhouse
    static let copperGrill = SponsorBusiness(
        id: "copper-grill",
        name: "The Copper Grill",
        tagline: "Prime Cuts. Craft Cocktails.",
        emoji: "🥩",
        brandColor: "#8B4513",
        brandColorSecondary: "#D2691E",
        category: .restaurant,
        websiteURL: "https://coppergrill.com",
        address: "89 Hudson St, New York, NY 10013",
        phoneNumber: "(212) 555-0247",
        spinConfig: SpinConfig(
            maxDailySpins: 3,
            rewardExpiryMinutes: 5,
            segments: [
                WheelSegment(id: "cg1", label: "15% OFF",        emoji: "🔥", rewardType: .percentOff,   rewardValue: "15%",            probability: 0.18, color: "#8B4513", isWin: true),
                WheelSegment(id: "cg2", label: "Try Again",      emoji: "🔄", rewardType: .tryAgain,     rewardValue: "",               probability: 0.24, color: "#3a2a1a", isWin: false),
                WheelSegment(id: "cg3", label: "Free Appetizer", emoji: "🥗", rewardType: .freeItem,     rewardValue: "Free Appetizer", probability: 0.15, color: "#5a3010", isWin: true),
                WheelSegment(id: "cg4", label: "+300 AZT",       emoji: "⭐", rewardType: .bonusPoints,  rewardValue: "300 AZT",        probability: 0.14, color: "#7c3aed", isWin: true),
                WheelSegment(id: "cg5", label: "$10 OFF",        emoji: "💵", rewardType: .fixedDiscount, rewardValue: "$10",           probability: 0.12, color: "#D2691E", isWin: true),
                WheelSegment(id: "cg6", label: "Try Again",      emoji: "🔄", rewardType: .tryAgain,     rewardValue: "",               probability: 0.08, color: "#2a1a0a", isWin: false),
                WheelSegment(id: "cg7", label: "Free Dessert",   emoji: "🍮", rewardType: .freeItem,     rewardValue: "Free Dessert",   probability: 0.06, color: "#c45c00", isWin: true),
                WheelSegment(id: "cg8", label: "Happy Hour",     emoji: "🍹", rewardType: .mystery,      rewardValue: "Happy Hour Deal", probability: 0.03, color: "#8B4513", isWin: true),
            ]
        )
    )

    // 3. The Tap Room — Sports Bar
    static let tapRoom = SponsorBusiness(
        id: "tap-room",
        name: "The Tap Room",
        tagline: "Watch the Game. Win the Deal.",
        emoji: "🍺",
        brandColor: "#1a472a",
        brandColorSecondary: "#ffd700",
        category: .bar,
        websiteURL: "https://taproom.bar",
        address: "215 Bleecker St, New York, NY 10012",
        phoneNumber: "(212) 555-0319",
        spinConfig: SpinConfig(
            maxDailySpins: 3,
            rewardExpiryMinutes: 5,
            segments: [
                WheelSegment(id: "tr1", label: "Free Draft",    emoji: "🍺", rewardType: .freeItem,     rewardValue: "Free Draft Beer",   probability: 0.18, color: "#1a472a", isWin: true),
                WheelSegment(id: "tr2", label: "Try Again",     emoji: "🔄", rewardType: .tryAgain,     rewardValue: "",                  probability: 0.22, color: "#1a1a1a", isWin: false),
                WheelSegment(id: "tr3", label: "$5 OFF",        emoji: "💵", rewardType: .fixedDiscount, rewardValue: "$5",               probability: 0.18, color: "#145222", isWin: true),
                WheelSegment(id: "tr4", label: "+250 AZT",      emoji: "⭐", rewardType: .bonusPoints,  rewardValue: "250 AZT",           probability: 0.15, color: "#7c3aed", isWin: true),
                WheelSegment(id: "tr5", label: "20% OFF Tab",   emoji: "🔥", rewardType: .percentOff,   rewardValue: "20%",               probability: 0.12, color: "#ffd700", isWin: true),
                WheelSegment(id: "tr6", label: "Try Again",     emoji: "🔄", rewardType: .tryAgain,     rewardValue: "",                  probability: 0.08, color: "#111111", isWin: false),
                WheelSegment(id: "tr7", label: "Free Wing Basket", emoji: "🍗", rewardType: .freeItem,  rewardValue: "Free Wing Basket",  probability: 0.05, color: "#0f3d1f", isWin: true),
                WheelSegment(id: "tr8", label: "Game Pass",     emoji: "🎮", rewardType: .mystery,      rewardValue: "Sunday Ticket Deal", probability: 0.02, color: "#1a472a", isWin: true),
            ]
        )
    )

    // 4. Blue Agave — Mexican Cantina
    static let blueAgave = SponsorBusiness(
        id: "blue-agave",
        name: "Blue Agave",
        tagline: "Handcrafted Tacos & Mezcal",
        emoji: "🌮",
        brandColor: "#1e5fa8",
        brandColorSecondary: "#f59e0b",
        category: .restaurant,
        websiteURL: "https://blueagave.mx",
        address: "540 LaGuardia Pl, New York, NY 10012",
        phoneNumber: "(212) 555-0402",
        spinConfig: SpinConfig(
            maxDailySpins: 3,
            rewardExpiryMinutes: 5,
            segments: [
                WheelSegment(id: "ba1", label: "2 Free Tacos",  emoji: "🌮", rewardType: .freeItem,     rewardValue: "2 Free Tacos",     probability: 0.18, color: "#1e5fa8", isWin: true),
                WheelSegment(id: "ba2", label: "Try Again",     emoji: "🔄", rewardType: .tryAgain,     rewardValue: "",                 probability: 0.23, color: "#1a2a3a", isWin: false),
                WheelSegment(id: "ba3", label: "15% OFF",       emoji: "🎉", rewardType: .percentOff,   rewardValue: "15%",              probability: 0.18, color: "#f59e0b", isWin: true),
                WheelSegment(id: "ba4", label: "+150 AZT",      emoji: "⭐", rewardType: .bonusPoints,  rewardValue: "150 AZT",          probability: 0.15, color: "#7c3aed", isWin: true),
                WheelSegment(id: "ba5", label: "Free Guac",     emoji: "🥑", rewardType: .freeItem,     rewardValue: "Free Guacamole",   probability: 0.12, color: "#166534", isWin: true),
                WheelSegment(id: "ba6", label: "Try Again",     emoji: "🔄", rewardType: .tryAgain,     rewardValue: "",                 probability: 0.07, color: "#111a2a", isWin: false),
                WheelSegment(id: "ba7", label: "$8 OFF",        emoji: "💵", rewardType: .fixedDiscount, rewardValue: "$8",              probability: 0.05, color: "#1d4ed8", isWin: true),
                WheelSegment(id: "ba8", label: "Mezcal Flight", emoji: "🥃", rewardType: .mystery,      rewardValue: "Free Mezcal Flight", probability: 0.02, color: "#1e5fa8", isWin: true),
            ]
        )
    )
}

// MARK: - Demo Member Cards

extension MemberCard {
    static func demo(for business: SponsorBusiness) -> MemberCard {
        MemberCard(
            id: business.id,
            memberId: "MBR-A3F2-9X71",
            sponsorId: business.id,
            sponsorName: business.name,
            sponsorEmoji: business.emoji,
            sponsorBrandColor: business.brandColor,
            sponsorWebsiteURL: business.websiteURL,
            tierLabel: "Regular",
            tierEmoji: "🔥",
            tierColor: business.brandColor,
            totalPoints: 1250,
            totalSpend: 67.50,
            memberSince: Date().addingTimeInterval(-30 * 86400)
        )
    }
}
