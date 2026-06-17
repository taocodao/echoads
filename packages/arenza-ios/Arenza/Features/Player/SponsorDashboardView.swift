// SponsorDashboardView.swift — Arenza (ArenzaTV Prototype)
// Aggregate engagement metrics view for the sponsor/operator side.
// Shows how many ads served, engagement rates, coupon redemptions,
// quiz participation, and revenue generated.
// Accessible from the Profile tab or Operator mode.

import SwiftUI

// MARK: - Design Tokens

private enum SD {
    static let bg       = Color(arenza: "#0d0f14")
    static let surface  = Color(arenza: "#141720")
    static let surface2 = Color(arenza: "#1a1e2a")
    static let border   = Color.white.opacity(0.08)
    static let text     = Color(arenza: "#f0f2ff")
    static let muted    = Color(arenza: "#8892b0")
    static let faint    = Color(arenza: "#4a5568")
    static let orange   = Color(arenza: "#ff6b35")
    static let teal     = Color(arenza: "#00c9b1")
    static let gold     = Color(arenza: "#ffc107")
    static let green    = Color(arenza: "#22c55e")
    static let red      = Color(arenza: "#ef4444")
    static let purple   = Color(arenza: "#7c3aed")
}

// MARK: - Sponsor Dashboard

@MainActor
struct SponsorDashboardView: View {
    @ObservedObject var engine: GameEngine
    @Environment(\.dismiss) private var dismiss

    // Demo metrics (in production these come from the analytics API)
    private var totalAdsServed: Int { engine.adsServed }
    private var sessionRevenue: Double { engine.sessionRevenue }
    private var avgCPM: Double {
        totalAdsServed > 0 ? sessionRevenue * 1000 / Double(totalAdsServed) : 0
    }

    // Quiz/trivia metrics from engines
    private var quizSessions: Int { 2 }  // demo: Pepsi + Domino's
    private var quizCorrectRate: Double { 0.73 }
    private var couponRedemptions: Int { PredictionEngine.shared.wallet.redeemedCoupons.count }
    private var couponsUnlocked: Int { PredictionEngine.shared.wallet.availableCoupons.count }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 14) {
                    // Hero metrics
                    heroMetrics

                    // Revenue breakdown
                    revenueCard

                    // Engagement funnel
                    engagementFunnel

                    // Quiz performance
                    quizPerformanceCard

                    // Ad creative performance
                    adCreativePerformance

                    // Coupon metrics
                    couponMetricsCard

                    // Platform comparison
                    platformComparison
                }
                .padding(14)
            }
            .background(SD.bg)
            .navigationTitle("Sponsor Dashboard")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(SD.teal)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Hero Metrics

    private var heroMetrics: some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                heroMetric(
                    value: "\(totalAdsServed)",
                    label: "Ads Served",
                    color: SD.orange,
                    icon: "play.rectangle.fill"
                )
                heroMetric(
                    value: String(format: "$%.3f", sessionRevenue),
                    label: "Revenue",
                    color: SD.green,
                    icon: "dollarsign.circle.fill"
                )
                heroMetric(
                    value: String(format: "$%.0f", avgCPM),
                    label: "Avg CPM",
                    color: SD.teal,
                    icon: "chart.bar.fill"
                )
            }

            HStack(spacing: 8) {
                heroMetric(
                    value: "87%",
                    label: "Engagement",
                    color: SD.gold,
                    icon: "hand.tap.fill"
                )
                heroMetric(
                    value: "\(couponsUnlocked)",
                    label: "Coupons",
                    color: SD.purple,
                    icon: "ticket.fill"
                )
                heroMetric(
                    value: "\(engine.points.formatted())",
                    label: "AZT Earned",
                    color: SD.gold,
                    icon: "star.fill"
                )
            }
        }
    }

    private func heroMetric(value: String, label: String, color: Color, icon: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)

            Text(value)
                .font(.system(size: 18, weight: .black, design: .monospaced))
                .foregroundColor(color)
                .lineLimit(1)
                .minimumScaleFactor(0.6)

            Text(label)
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(SD.faint)
                .tracking(0.5)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
    }

    // MARK: - Revenue Card

    private var revenueCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("💰 Revenue Breakdown")

            ForEach(AD_CATALOG.filter { $0.appearsAt <= 600 }, id: \.id) { ad in
                HStack(spacing: 10) {
                    Text(ad.emoji).font(.system(size: 16))
                    VStack(alignment: .leading, spacing: 1) {
                        Text(ad.brand)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(SD.text)
                        Text(ad.targetSegment)
                            .font(.system(size: 9))
                            .foregroundColor(SD.muted)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 1) {
                        Text("$\(ad.cpm) CPM")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(SD.green)
                        Text(String(format: "$%.4f", Double(ad.cpm) / 1000.0))
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundColor(SD.faint)
                    }
                }
                .padding(8)
                .background(ad.color.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .dashboardCard()
    }

    // MARK: - Engagement Funnel

    private var engagementFunnel: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("📊 Engagement Funnel")

            funnelRow("Impressions", value: "\(totalAdsServed)", pct: 1.0, color: SD.orange)
            funnelRow("Interactions", value: "\(max(totalAdsServed - 1, 0))", pct: 0.87, color: SD.teal)
            funnelRow("Completions", value: "\(max(totalAdsServed - 2, 0))", pct: 0.73, color: SD.green)
            funnelRow("Conversions", value: "\(couponsUnlocked)", pct: 0.35, color: SD.purple)
        }
        .dashboardCard()
    }

    private func funnelRow(_ label: String, value: String, pct: Double, color: Color) -> some View {
        VStack(spacing: 4) {
            HStack {
                Text(label)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(SD.text)
                Spacer()
                Text(value)
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(color)
                Text("(\(Int(pct * 100))%)")
                    .font(.system(size: 9))
                    .foregroundColor(SD.faint)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(SD.border)
                        .frame(height: 4)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(color)
                        .frame(width: geo.size.width * pct, height: 4)
                }
            }
            .frame(height: 4)
        }
    }

    // MARK: - Quiz Performance

    private var quizPerformanceCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("🏢 Sponsor Quiz Performance")

            HStack(spacing: 10) {
                quizStat(label: "Sessions", value: "\(quizSessions)", color: SD.teal)
                quizStat(label: "Correct %", value: "\(Int(quizCorrectRate * 100))%", color: SD.green)
                quizStat(label: "Avg Time", value: "4.2s", color: SD.gold)
                quizStat(label: "Brand Recall", value: "91%", color: SD.orange)
            }

            HStack {
                Text("💡")
                Text("Sponsor quizzes drive 3.2× higher brand recall vs passive ads")
                    .font(.system(size: 10))
                    .foregroundColor(SD.muted)
            }
            .padding(8)
            .background(SD.teal.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .dashboardCard()
    }

    private func quizStat(label: String, value: String, color: Color) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.system(size: 16, weight: .black, design: .monospaced))
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(SD.faint)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Ad Creative Performance

    private var adCreativePerformance: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("🎯 Ad Format Comparison")

            HStack(spacing: 6) {
                formatStat(format: "Prediction", engagement: 92, color: SD.orange)
                formatStat(format: "Quiz", engagement: 87, color: SD.teal)
                formatStat(format: "Bingo", engagement: 78, color: SD.purple)
                formatStat(format: "Scratch", engagement: 65, color: SD.gold)
            }
        }
        .dashboardCard()
    }

    private func formatStat(format: String, engagement: Int, color: Color) -> some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .stroke(SD.border, lineWidth: 3)
                    .frame(width: 40, height: 40)
                Circle()
                    .trim(from: 0, to: Double(engagement) / 100.0)
                    .stroke(color, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: 40, height: 40)
                    .rotationEffect(.degrees(-90))
                Text("\(engagement)%")
                    .font(.system(size: 9, weight: .black, design: .monospaced))
                    .foregroundColor(color)
            }
            Text(format)
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(SD.muted)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Coupon Metrics

    private var couponMetricsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("🎟️ Coupon Performance")

            HStack(spacing: 10) {
                quizStat(label: "Unlocked", value: "\(couponsUnlocked)", color: SD.green)
                quizStat(label: "Redeemed", value: "\(couponRedemptions)", color: SD.orange)
                quizStat(label: "Redemption %", value: couponsUnlocked > 0 ? "\(Int(Double(couponRedemptions) / Double(couponsUnlocked) * 100))%" : "—", color: SD.teal)
                quizStat(label: "Value", value: "$\(couponsUnlocked * 3)", color: SD.gold)
            }
        }
        .dashboardCard()
    }

    // MARK: - Platform Comparison

    private var platformComparison: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("📈 Arenza vs Industry Benchmarks")

            comparisonRow("Engagement Rate", arenza: "87%", industry: "2.1%", multiplier: "41×")
            comparisonRow("Brand Recall", arenza: "91%", industry: "34%", multiplier: "2.7×")
            comparisonRow("Coupon Redemption", arenza: "35%", industry: "1.2%", multiplier: "29×")
            comparisonRow("Effective CPM", arenza: "$53", industry: "$12", multiplier: "4.4×")

            HStack {
                Text("🚀")
                Text("Interactive sport-contextual games deliver dramatically higher engagement than passive video ads")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(SD.green)
            }
            .padding(8)
            .background(SD.green.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .dashboardCard()
    }

    private func comparisonRow(_ label: String, arenza: String, industry: String, multiplier: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(SD.muted)
                .frame(width: 110, alignment: .leading)

            Text(arenza)
                .font(.system(size: 11, weight: .black, design: .monospaced))
                .foregroundColor(SD.green)
                .frame(width: 50, alignment: .trailing)

            Text("vs")
                .font(.system(size: 8))
                .foregroundColor(SD.faint)

            Text(industry)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(SD.faint)
                .frame(width: 50, alignment: .trailing)

            Spacer()

            Text(multiplier)
                .font(.system(size: 10, weight: .black))
                .foregroundColor(SD.orange)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(SD.orange.opacity(0.12))
                .clipShape(Capsule())
        }
    }

    // MARK: - Helpers

    private func sectionLabel(_ label: String) -> some View {
        Text(label)
            .font(.system(size: 10, weight: .black))
            .foregroundColor(SD.muted)
            .tracking(0.8)
    }
}

// MARK: - Dashboard Card Modifier

private extension View {
    func dashboardCard() -> some View {
        self
            .padding(12)
            .background(SD.surface2)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(SD.border, lineWidth: 1)
            )
    }
}
