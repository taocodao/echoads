// MembershipService.swift — Arenza
// Swift port of memberStore.ts (web demo)
//
// Manages per-business membership data: stamp cards, active coupons,
// purchase history, tier progression, and points balance.
//
// Storage: UserDefaults (demo) — replace with Firebase Firestore in production.
// iOS equivalent patterns:
//   memberStore.getMember()           → MembershipService.shared.getMember()
//   memberStore.addStamp()            → MembershipService.shared.addStamp()
//   memberStore.redeemCoupon()        → MembershipService.shared.redeemCoupon()
//   memberStore.recordPurchase()      → MembershipService.shared.recordPurchase()

import Foundation
import Combine

// MARK: - Models

struct BusinessMembership: Codable, Identifiable {
    var id: String { businessId }
    let businessId: String
    let businessName: String
    var stamps: Int
    let stampsRequired: Int
    var pointsBalance: Int
    var memberTier: MemberTier
    var visitCount: Int
    var lastVisit: Date?
    var activeCoupons: [MemberCoupon]
    var purchaseHistory: [PurchaseRecord]

    var activeCouponsFiltered: [MemberCoupon] {
        activeCoupons.filter { !$0.redeemed && $0.expiresAt > Date() }
    }

    var tierColor: String {
        switch memberTier {
        case .guest:          return "#8892b0"
        case .regular:        return "#00c9b1"
        case .vip:            return "#ffc107"
        case .foundingMember: return "#ff6b35"
        }
    }
}

enum MemberTier: String, Codable, CaseIterable {
    case guest          = "Guest"
    case regular        = "Regular"
    case vip            = "VIP"
    case foundingMember = "Founding Member"

    var emoji: String {
        switch self {
        case .guest:          return "👤"
        case .regular:        return "⭐"
        case .vip:            return "🏆"
        case .foundingMember: return "💎"
        }
    }
}

struct MemberCoupon: Codable, Identifiable {
    let id: String
    let offer: String
    let value: String
    let claimedAt: Date
    let expiresAt: Date
    var redeemed: Bool
    var redeemedAt: Date?

    var isActive: Bool { !redeemed && expiresAt > Date() }

    var timeRemainingDisplay: String {
        let remaining = expiresAt.timeIntervalSince(Date())
        if remaining <= 0 { return "Expired" }
        let hours = Int(remaining / 3600)
        let mins  = Int((remaining.truncatingRemainder(dividingBy: 3600)) / 60)
        if hours > 0 { return "\(hours)h \(mins)m left" }
        return "\(mins)m left"
    }
}

struct PurchaseRecord: Codable, Identifiable {
    let id: String
    let amount: Double?
    let description: String
    let pointsEarned: Int
    let timestamp: Date
    let staffNote: String?
}

struct MemberRecord: Codable {
    let userId: String
    var displayName: String
    let joinedAt: Date
    var businesses: [String: BusinessMembership]
}

// MARK: - Business Catalog

struct BusinessInfo {
    let name: String
    let stampsRequired: Int
    let emoji: String
    let brandColor: String
}

let businessCatalog: [String: BusinessInfo] = [
    "ajward":   BusinessInfo(name: "AJ.Ward",                 stampsRequired: 9, emoji: "🍽️", brandColor: "#1a1a2e"),
    "bonsai":   BusinessInfo(name: "Bonsai Cafe",             stampsRequired: 9, emoji: "🍜",  brandColor: "#2d6a4f"),
    "roccos":   BusinessInfo(name: "Rocco's Bar & Restaurant",stampsRequired: 9, emoji: "🍸",  brandColor: "#e63946"),
    "rooftop":  BusinessInfo(name: "Rooftop Gardens",         stampsRequired: 9, emoji: "🌿",  brandColor: "#588157"),
    "oldram":   BusinessInfo(name: "Old Ram Coaching Inn",    stampsRequired: 9, emoji: "🍺",  brandColor: "#7c5c3e"),
]

// MARK: - Service

@MainActor
final class MembershipService: ObservableObject {

    static let shared = MembershipService()
    private init() { loadFromStorage() }

    @Published private(set) var currentRecord: MemberRecord?

    private let storageKey = "arenza_member_store_v2"

    // MARK: - Load / Save

    private func loadFromStorage() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let record = try? JSONDecoder().decode(MemberRecord.self, from: data) else {
            // Seed new record
            let userId = ArenzaQRToken.getOrCreateUserId()
            currentRecord = MemberRecord(
                userId: userId,
                displayName: "Member \(userId.prefix(4))",
                joinedAt: Date(),
                businesses: [:]
            )
            return
        }
        currentRecord = record
    }

    private func save() {
        guard let record = currentRecord,
              let data = try? JSONEncoder().encode(record) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }

    // MARK: - Public API

    func getMembership(businessId: String) -> BusinessMembership {
        guard var record = currentRecord else {
            fatalError("MembershipService not initialized")
        }
        if record.businesses[businessId] == nil {
            let biz = businessCatalog[businessId]
            record.businesses[businessId] = BusinessMembership(
                businessId: businessId,
                businessName: biz?.name ?? businessId,
                stamps: 0,
                stampsRequired: biz?.stampsRequired ?? 9,
                pointsBalance: 0,
                memberTier: .guest,
                visitCount: 0,
                lastVisit: nil,
                activeCoupons: [],
                purchaseHistory: []
            )
            currentRecord = record
            save()
        }
        return record.businesses[businessId]!
    }

    /// Add a stamp. Returns whether a free-reward was unlocked.
    @discardableResult
    func addStamp(businessId: String) -> (membership: BusinessMembership, rewardUnlocked: Bool) {
        guard var record = currentRecord else { return (getMembership(businessId: businessId), false) }
        var biz = getMembership(businessId: businessId)

        biz.stamps += 1
        biz.visitCount += 1
        biz.lastVisit = Date()
        biz.pointsBalance += 25

        var rewardUnlocked = false
        if biz.stamps >= biz.stampsRequired {
            biz.stamps = 0
            rewardUnlocked = true
            biz.activeCoupons.append(MemberCoupon(
                id: "reward-\(UUID().uuidString)",
                offer: "Free Reward",
                value: "Free item — loyalty reward",
                claimedAt: Date(),
                expiresAt: Date().addingTimeInterval(7 * 24 * 3600),
                redeemed: false
            ))
        }

        // Tier progression
        if biz.visitCount >= 12      { biz.memberTier = .vip }
        else if biz.visitCount >= 6  { biz.memberTier = .regular }

        record.businesses[businessId] = biz
        currentRecord = record
        save()
        return (biz, rewardUnlocked)
    }

    struct RedeemResult {
        let success: Bool
        let coupon: MemberCoupon?
        let error: String?
    }

    func redeemCoupon(businessId: String, couponId: String) -> RedeemResult {
        guard var record = currentRecord else {
            return RedeemResult(success: false, coupon: nil, error: "Not initialized")
        }
        guard var biz = record.businesses[businessId] else {
            return RedeemResult(success: false, coupon: nil, error: "No membership found")
        }
        guard let idx = biz.activeCoupons.firstIndex(where: { $0.id == couponId && !$0.redeemed }) else {
            return RedeemResult(success: false, coupon: nil, error: "Coupon not found or already used")
        }
        guard biz.activeCoupons[idx].isActive else {
            return RedeemResult(success: false, coupon: nil, error: "Coupon expired")
        }

        biz.activeCoupons[idx].redeemed = true
        biz.activeCoupons[idx].redeemedAt = Date()
        record.businesses[businessId] = biz
        currentRecord = record
        save()
        return RedeemResult(success: true, coupon: biz.activeCoupons[idx], error: nil)
    }

    @discardableResult
    func recordPurchase(businessId: String, description: String, amount: Double? = nil) -> BusinessMembership {
        guard var record = currentRecord else { return getMembership(businessId: businessId) }
        var biz = getMembership(businessId: businessId)

        let pts = amount != nil ? Int(amount! * 10) : 50
        biz.pointsBalance += pts
        biz.visitCount += 1
        biz.lastVisit = Date()
        biz.purchaseHistory.append(PurchaseRecord(
            id: "p-\(UUID().uuidString)",
            amount: amount,
            description: description,
            pointsEarned: pts,
            timestamp: Date(),
            staffNote: nil
        ))

        record.businesses[businessId] = biz
        currentRecord = record
        save()
        return biz
    }

    func addCoupon(businessId: String, offer: String, value: String, expiryHours: Double = 24) {
        guard var record = currentRecord else { return }
        var biz = getMembership(businessId: businessId)

        // Avoid duplicates
        if biz.activeCoupons.contains(where: { $0.offer == offer && !$0.redeemed }) { return }

        biz.activeCoupons.append(MemberCoupon(
            id: "c-\(UUID().uuidString)",
            offer: offer,
            value: value,
            claimedAt: Date(),
            expiresAt: Date().addingTimeInterval(expiryHours * 3600),
            redeemed: false
        ))
        record.businesses[businessId] = biz
        currentRecord = record
        save()
    }

    var userId: String {
        currentRecord?.userId ?? ArenzaQRToken.getOrCreateUserId()
    }

    var displayName: String {
        currentRecord?.displayName ?? "Member"
    }

    var totalPointsAcrossAllBusinesses: Int {
        currentRecord?.businesses.values.reduce(0) { $0 + $1.pointsBalance } ?? 0
    }

    var allActiveCoupons: [MemberCoupon] {
        currentRecord?.businesses.values.flatMap { $0.activeCouponsFiltered } ?? []
    }
}
