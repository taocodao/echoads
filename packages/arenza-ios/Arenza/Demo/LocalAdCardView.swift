// LocalAdCardView.swift — Arenza
// Swift/SwiftUI port of LocalAdCard.tsx (web demo).
// Hyperlocal business ad card with 3 CTAs:
//   🎟 Claim Coupon  |  🪪 Join Club  |  🛒 Order Now
//
// Shown as an overlay during ad breaks — wired into DemoOrchestrator.
// iOS equivalent: AVPlayerItemOutput + timed metadata trigger

import SwiftUI

// MARK: - Data Model

struct LocalBusiness: Identifiable, Hashable {
    let id: String
    let name: String
    let emoji: String
    let primaryColor: String   // hex e.g. "#ff6b35"
    let rating: Double         // 4.1 etc
    let reviewCount: Int
    let distanceMiles: Double?
    let city: String
    let activeOffer: BusinessOffer?
    let membership: MembershipPlan?
    let orderEnabled: Bool
    let orderUrl: String?
    let arenzaPointsAccepted: Bool
}

struct BusinessOffer: Hashable {
    let headline: String
    let value: String
    let expiresAt: Date?
}

struct MembershipPlan: Hashable {
    let enabled: Bool
    let cardName: String
    let perks: [String]
    let stampsRequired: Int?
    let reward: String
}

// MARK: - Demo Business Catalog (matches web sharedTypes.ts BUSINESSES)

let demoBusinesses: [LocalBusiness] = [
    LocalBusiness(
        id: "ajward", name: "AJ.Ward", emoji: "🍽️", primaryColor: "#ff6b35",
        rating: 4.8, reviewCount: 312, distanceMiles: 0.3, city: "Norwich",
        activeOffer: BusinessOffer(headline: "20% off your bill tonight", value: "20% OFF", expiresAt: Date().addingTimeInterval(4 * 3600)),
        membership: MembershipPlan(enabled: true, cardName: "AJ's Inner Circle", perks: ["Free dessert on 5th visit", "Birthday meal deal", "Priority booking"], stampsRequired: 9, reward: "Free main course"),
        orderEnabled: true, orderUrl: "https://www.ajrestaurant.co.uk/",
        arenzaPointsAccepted: true
    ),
    LocalBusiness(
        id: "bonsai", name: "Bonsai Cafe", emoji: "🍜", primaryColor: "#2d6a4f",
        rating: 4.6, reviewCount: 189, distanceMiles: 0.5, city: "Norwich",
        activeOffer: BusinessOffer(headline: "Free miso soup with any ramen", value: "FREE SOUP", expiresAt: Date().addingTimeInterval(2 * 3600)),
        membership: MembershipPlan(enabled: true, cardName: "Bonsai Member", perks: ["Free tea on every visit", "Monthly chef's special"], stampsRequired: 9, reward: "Free ramen bowl"),
        orderEnabled: false, orderUrl: nil,
        arenzaPointsAccepted: true
    ),
    LocalBusiness(
        id: "roccos", name: "Rocco's Bar", emoji: "🍸", primaryColor: "#e63946",
        rating: 4.5, reviewCount: 421, distanceMiles: 0.2, city: "Norwich",
        activeOffer: BusinessOffer(headline: "2-for-1 cocktails until 9pm", value: "2-FOR-1", expiresAt: nil),
        membership: MembershipPlan(enabled: true, cardName: "Rocco's VIP", perks: ["Skip the queue on match nights", "Free shot on birthday", "Members-only events"], stampsRequired: 9, reward: "Free cocktail"),
        orderEnabled: true, orderUrl: "http://www.roccos.com",
        arenzaPointsAccepted: true
    ),
    LocalBusiness(
        id: "rooftop", name: "Rooftop Gardens", emoji: "🌿", primaryColor: "#588157",
        rating: 4.9, reviewCount: 278, distanceMiles: 0.7, city: "Norwich",
        activeOffer: BusinessOffer(headline: "Sunset cocktail menu — 25% off", value: "25% OFF", expiresAt: Date().addingTimeInterval(3 * 3600)),
        membership: MembershipPlan(enabled: true, cardName: "Garden Society", perks: ["Early access to bookings", "Members' cocktail of the month"], stampsRequired: 9, reward: "Free drinks round"),
        orderEnabled: true, orderUrl: "https://rooftopgardens.co.uk/",
        arenzaPointsAccepted: true
    ),
]

// MARK: - LocalAdCardView

struct LocalAdCardView: View {

    let business: LocalBusiness
    let onCouponClaim: (LocalBusiness) -> Void
    let onJoinClub: (LocalBusiness) -> Void
    var expanded: Bool = false

    @State private var couponClaimed = false
    @State private var clubJoined = false
    @State private var showPerks = false

    private var brandColor: Color { Color(arenza: business.primaryColor) }

    var body: some View {
        VStack(spacing: 0) {

            // ── Header ────────────────────────────────────────────────────────
            HStack(spacing: 10) {
                Text(business.emoji).font(.system(size: 28))
                VStack(alignment: .leading, spacing: 2) {
                    Text(business.name)
                        .font(.system(size: 13, weight: .black))
                        .foregroundColor(.white)
                    starRating(business.rating)
                    Text("(\(business.reviewCount) reviews)")
                        .font(.system(size: 9))
                        .foregroundColor(Color(arenza: "#8892b0"))
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    if let dist = business.distanceMiles {
                        Text(String(format: "%.1f mi", dist))
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(brandColor)
                    }
                    Text(business.city)
                        .font(.system(size: 9))
                        .foregroundColor(Color(arenza: "#8892b0"))
                }
            }
            .padding(.horizontal, 12).padding(.vertical, 10)
            .background(
                LinearGradient(
                    colors: [brandColor.opacity(0.13), Color(arenza: "#1a1e2a")],
                    startPoint: .leading, endPoint: .trailing
                )
            )

            Divider().background(Color.white.opacity(0.08))

            // ── Offer strip ───────────────────────────────────────────────────
            if let offer = business.activeOffer {
                HStack(spacing: 6) {
                    Text("🎯")
                    Text(offer.headline)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                    if let exp = offer.expiresAt {
                        countdownBadge(expiresAt: exp)
                    }
                }
                .padding(.horizontal, 12).padding(.vertical, 8)

                Divider().background(Color.white.opacity(0.08))
            }

            // ── 3 CTA buttons ─────────────────────────────────────────────────
            HStack(spacing: 6) {

                // Coupon
                if business.activeOffer != nil {
                    ctaButton(
                        emoji: couponClaimed ? "✅" : "🎟",
                        label: couponClaimed ? "Claimed!" : "COUPON",
                        active: couponClaimed,
                        activeColor: Color(arenza: "#22c55e"),
                        inactiveColor: brandColor
                    ) {
                        if !couponClaimed {
                            couponClaimed = true
                            onCouponClaim(business)
                        }
                    }
                }

                // Join Club
                if business.membership?.enabled == true {
                    ctaButton(
                        emoji: clubJoined ? "⭐" : "🪪",
                        label: clubJoined ? "Joined!" : "JOIN CLUB",
                        active: clubJoined,
                        activeColor: Color(arenza: "#22c55e"),
                        inactiveColor: Color(arenza: "#7c3aed")
                    ) {
                        if !clubJoined {
                            clubJoined = true
                            onJoinClub(business)
                        }
                    }
                }

                // Order Now
                if business.orderEnabled, let url = business.orderUrl, let orderURL = URL(string: url) {
                    Link(destination: orderURL) {
                        VStack(spacing: 3) {
                            Text("🛒").font(.system(size: 14))
                            Text("ORDER NOW")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(Color(arenza: "#22c55e"))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color(arenza: "#22c55e").opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(arenza: "#22c55e").opacity(0.4), lineWidth: 1))
                    }
                }
            }
            .padding(10)

            // ── Membership perks (expandable) ─────────────────────────────────
            if let plan = business.membership, plan.enabled {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { showPerks.toggle() }
                } label: {
                    HStack {
                        Text(showPerks ? "Hide perks ▲" : "View \(plan.cardName) perks ▼")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(Color(arenza: "#7c3aed"))
                        Spacer()
                    }
                    .padding(.horizontal, 12).padding(.bottom, 6)
                }
                .buttonStyle(.plain)

                if showPerks {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(plan.perks, id: \.self) { perk in
                            HStack(spacing: 4) {
                                Text("✓").foregroundColor(Color(arenza: "#22c55e"))
                                Text(perk).foregroundColor(.white)
                            }
                            .font(.system(size: 10))
                        }
                        if let stamps = plan.stampsRequired {
                            Text("🎯 \(plan.reward) (after \(stamps) visits)")
                                .font(.system(size: 9))
                                .foregroundColor(Color(arenza: "#8892b0"))
                                .padding(.top, 2)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.bottom, 10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                Divider().background(Color.white.opacity(0.08))
            }

            // ── Arenza Points badge ───────────────────────────────────────────
            if business.arenzaPointsAccepted {
                HStack {
                    Text("🏆 Arenza Points accepted here")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(Color(arenza: "#ff6b35"))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 12).padding(.vertical, 5)
                .background(Color(arenza: "#ff6b35").opacity(0.07))
            }
        }
        .background(Color(arenza: "#141720"))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(brandColor.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: brandColor.opacity(0.07), radius: 12, y: 3)
    }

    // MARK: - Sub-components

    private func ctaButton(emoji: String, label: String, active: Bool, activeColor: Color, inactiveColor: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Text(emoji).font(.system(size: 14))
                Text(label)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(active ? activeColor : inactiveColor)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background((active ? activeColor : inactiveColor).opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke((active ? activeColor : inactiveColor).opacity(0.4), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func starRating(_ rating: Double) -> some View {
        HStack(spacing: 1) {
            let full = Int(rating)
            let half = (rating - Double(full)) >= 0.5
            ForEach(0..<full, id: \.self) { _ in
                Text("★").foregroundColor(Color(arenza: "#fbbf24")).font(.system(size: 9))
            }
            if half { Text("½").foregroundColor(Color(arenza: "#fbbf24")).font(.system(size: 9)) }
            ForEach(0..<(5 - full - (half ? 1 : 0)), id: \.self) { _ in
                Text("☆").foregroundColor(Color(arenza: "#fbbf24")).font(.system(size: 9))
            }
            Text(String(format: "%.1f", rating))
                .font(.system(size: 9))
                .foregroundColor(Color(arenza: "#8892b0"))
        }
    }

    private func countdownBadge(expiresAt: Date) -> some View {
        let remaining = max(0, expiresAt.timeIntervalSince(Date()))
        let hours = Int(remaining / 3600)
        let mins = Int((remaining.truncatingRemainder(dividingBy: 3600)) / 60)
        return Text("⏱ Expires in \(hours)h \(mins)m")
            .font(.system(size: 9, weight: .bold))
            .foregroundColor(Color(arenza: "#fbbf24"))
    }
}

// MARK: - Ad Break Overlay (shown during demo ad breaks)

struct LocalAdBreakOverlay: View {
    let businesses: [LocalBusiness]
    let onDismiss: () -> Void
    var onCouponClaim: ((LocalBusiness) -> Void)? = nil
    var onJoinClub: ((LocalBusiness) -> Void)? = nil

    @State private var expanded: String? = nil
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                HStack(spacing: 6) {
                    Circle().fill(Color(arenza: "#ff6b35")).frame(width: 7, height: 7)
                    Text("LOCAL SPONSORS NEAR YOU")
                        .font(.system(size: 10, weight: .black))
                        .foregroundColor(Color(arenza: "#ff6b35"))
                        .tracking(0.8)
                }
                Spacer()
                Button { onDismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Color(arenza: "#4a5568"))
                        .padding(6)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 14).padding(.vertical, 10)
            .background(Color(arenza: "#1a1e2a"))
            .overlay(Rectangle().frame(height: 1).foregroundColor(.white.opacity(0.07)), alignment: .bottom)

            // Cards
            ScrollView {
                VStack(spacing: 10) {
                    ForEach(businesses) { biz in
                        LocalAdCardView(
                            business: biz,
                            onCouponClaim: { onCouponClaim?($0) },
                            onJoinClub: { onJoinClub?($0) },
                            expanded: expanded == biz.id
                        )
                        .onTapGesture { withAnimation { expanded = expanded == biz.id ? nil : biz.id } }
                    }
                }
                .padding(12)
            }
        }
        .background(Color(arenza: "#0d0f14"))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.6), radius: 30, y: 10)
        .padding(.horizontal, 12)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 30)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                appeared = true
            }
        }
    }
}
