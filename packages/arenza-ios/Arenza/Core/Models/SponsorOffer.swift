// SponsorOffer.swift — Arenza (Token Marketplace)
// The offer listing model for the sponsor marketplace.
// Each offer generates up to three revenue events: impression (CPM), click (CPC), redemption (CPA).

import Foundation
import CoreLocation

// MARK: - Sponsor Offer

struct SponsorOffer: Codable, Identifiable {
    let id: UUID
    let sponsorId: String
    let sponsorName: String
    let brandLogoURL: URL?
    let offerTitle: String              // "20% off your next order"
    let offerDescription: String
    let aztCost: Int                    // AZT required to redeem (e.g. 5000 = ~$5 coupon)
    let dollarValue: Double             // displayed to user as "$5.00"
    let category: CouponCategory
    let expiryDate: Date
    let isLocalOnly: Bool
    let localRadius: Double?            // km, nil if national
    let latitude: Double?
    let longitude: Double?
    let affiliateClickURL: String       // tracked URL with utm params
    let couponCode: String              // revealed only after redemption
    let couponTrackingId: String        // unique per issuance for attribution
    let impressionCPM: Double           // what sponsor pays per 1000 browse views
    let clickCPC: Double                // what sponsor pays per click-through
    let redemptionFee: Double           // flat fee per coupon code used
    let dmaCode: String?               // DMA code for regional targeting
    let remainingInventory: Int?        // nil = unlimited

    var isExpired: Bool { expiryDate < Date() }
    var isSoldOut: Bool { (remainingInventory ?? 1) <= 0 }
    var isAvailable: Bool { !isExpired && !isSoldOut }

    var coordinate: CLLocationCoordinate2D? {
        guard let lat = latitude, let lng = longitude else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lng)
    }

    func distanceFrom(_ location: CLLocation) -> Double? {
        guard let coord = coordinate else { return nil }
        let offerLoc = CLLocation(latitude: coord.latitude, longitude: coord.longitude)
        return offerLoc.distance(from: location) / 1000.0  // km
    }

    var affiliateURL: URL? {
        URL(string: affiliateClickURL)
    }
}

// MARK: - Demo Sponsor Offers

extension SponsorOffer {
    static let demoOffers: [SponsorOffer] = [
        SponsorOffer(
            id: UUID(), sponsorId: "dominos", sponsorName: "Domino's Pizza",
            brandLogoURL: nil,
            offerTitle: "20% off your next order",
            offerDescription: "Valid on any menu-price order of $15 or more. Online orders only.",
            aztCost: 5000, dollarValue: 5.00, category: .food,
            expiryDate: Date().addingTimeInterval(30 * 86400),
            isLocalOnly: true, localRadius: 10.0,
            latitude: 40.7128, longitude: -74.0060,
            affiliateClickURL: "https://www.dominos.com/?utm_source=arenza&utm_medium=token_marketplace&utm_campaign=azt_reward",
            couponCode: "ARENZA20", couponTrackingId: "trk_dom_001",
            impressionCPM: 12.0, clickCPC: 0.55, redemptionFee: 2.50,
            dmaCode: "501", remainingInventory: nil
        ),
        SponsorOffer(
            id: UUID(), sponsorId: "nike", sponsorName: "Nike",
            brandLogoURL: nil,
            offerTitle: "$15 off $75+ purchase",
            offerDescription: "Use online at nike.com or in-store. Excludes sale items.",
            aztCost: 15000, dollarValue: 15.00, category: .retail,
            expiryDate: Date().addingTimeInterval(45 * 86400),
            isLocalOnly: false, localRadius: nil,
            latitude: nil, longitude: nil,
            affiliateClickURL: "https://www.nike.com/?utm_source=arenza&utm_medium=token_marketplace&utm_campaign=azt_reward",
            couponCode: "ARENZA15", couponTrackingId: "trk_nike_001",
            impressionCPM: 10.0, clickCPC: 0.85, redemptionFee: 5.00,
            dmaCode: nil, remainingInventory: nil
        ),
        SponsorOffer(
            id: UUID(), sponsorId: "draftkings", sponsorName: "DraftKings",
            brandLogoURL: nil,
            offerTitle: "Free $5 DK Dollars",
            offerDescription: "New accounts only. $5 in DraftKings Dollars credited instantly.",
            aztCost: 3000, dollarValue: 5.00, category: .betting,
            expiryDate: Date().addingTimeInterval(21 * 86400),
            isLocalOnly: false, localRadius: nil,
            latitude: nil, longitude: nil,
            affiliateClickURL: "https://www.draftkings.com/?utm_source=arenza&utm_medium=token_marketplace&utm_campaign=azt_reward",
            couponCode: "ARENZA5DK", couponTrackingId: "trk_dk_001",
            impressionCPM: 15.0, clickCPC: 1.10, redemptionFee: 3.00,
            dmaCode: nil, remainingInventory: 500
        ),
        SponsorOffer(
            id: UUID(), sponsorId: "fanatics", sponsorName: "Fanatics",
            brandLogoURL: nil,
            offerTitle: "25% off team gear",
            offerDescription: "All licensed jerseys, hats, and accessories. Free shipping over $50.",
            aztCost: 8000, dollarValue: 10.00, category: .sports,
            expiryDate: Date().addingTimeInterval(60 * 86400),
            isLocalOnly: false, localRadius: nil,
            latitude: nil, longitude: nil,
            affiliateClickURL: "https://www.fanatics.com/?utm_source=arenza&utm_medium=token_marketplace&utm_campaign=azt_reward",
            couponCode: "ARENZA25FAN", couponTrackingId: "trk_fan_001",
            impressionCPM: 11.0, clickCPC: 0.65, redemptionFee: 4.00,
            dmaCode: nil, remainingInventory: nil
        ),
        SponsorOffer(
            id: UUID(), sponsorId: "bufwild", sponsorName: "Buffalo Wild Wings",
            brandLogoURL: nil,
            offerTitle: "Free appetizer with $20+ order",
            offerDescription: "Show code to server. Dine-in only. Valid at participating locations.",
            aztCost: 4000, dollarValue: 6.00, category: .food,
            expiryDate: Date().addingTimeInterval(14 * 86400),
            isLocalOnly: true, localRadius: 15.0,
            latitude: 40.7580, longitude: -73.9855,
            affiliateClickURL: "https://www.buffalowildwings.com/?utm_source=arenza&utm_medium=token_marketplace",
            couponCode: "ARENZABWW", couponTrackingId: "trk_bww_001",
            impressionCPM: 9.0, clickCPC: 0.40, redemptionFee: 2.00,
            dmaCode: "501", remainingInventory: nil
        ),
        SponsorOffer(
            id: UUID(), sponsorId: "espnplus", sponsorName: "ESPN+",
            brandLogoURL: nil,
            offerTitle: "1 month free ESPN+",
            offerDescription: "New subscribers only. Cancellation anytime after trial.",
            aztCost: 10000, dollarValue: 10.99, category: .streaming,
            expiryDate: Date().addingTimeInterval(30 * 86400),
            isLocalOnly: false, localRadius: nil,
            latitude: nil, longitude: nil,
            affiliateClickURL: "https://plus.espn.com/?utm_source=arenza&utm_medium=token_marketplace",
            couponCode: "ARENZAESPN", couponTrackingId: "trk_espn_001",
            impressionCPM: 14.0, clickCPC: 0.95, redemptionFee: 6.00,
            dmaCode: nil, remainingInventory: 200
        ),
    ]
}
