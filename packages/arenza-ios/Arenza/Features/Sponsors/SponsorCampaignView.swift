// SponsorCampaignView.swift — Arenza (Phase 4: Sponsor CMS Client)
// Displays active sponsor campaigns and their real-time engagement metrics.
// Data flows from the B2B dashboard CMS → API → this view.

import SwiftUI

// MARK: - Sponsor Campaigns Tab

struct SponsorCampaignView: View {
    @StateObject private var vm = SponsorCampaignViewModel()
    @State private var selectedCampaign: SponsorCampaign?

    var body: some View {
        NavigationStack {
            ZStack {
                Color(white: 0.05).ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Summary metrics
                        overviewCards

                        // Active campaigns
                        campaignList

                        Spacer(minLength: 32)
                    }
                    .padding(.top, 8)
                }
                .refreshable { await vm.load() }
            }
            .navigationTitle("Sponsor Hub")
            .navigationBarTitleDisplayMode(.large)
            .task { await vm.load() }
            .sheet(item: $selectedCampaign) { campaign in
                CampaignDetailSheet(campaign: campaign)
            }
        }
    }

    // MARK: - Overview Cards

    private var overviewCards: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                MetricCard(
                    title: "ACTIVE CAMPAIGNS",
                    value: "\(vm.activeCampaigns.count)",
                    icon: "megaphone.fill",
                    color: Color(red: 0.0, green: 0.82, blue: 0.60)
                )
                MetricCard(
                    title: "TOTAL INTERACTIONS",
                    value: vm.formattedTotalInteractions,
                    icon: "hand.tap.fill",
                    color: .cyan
                )
            }
            HStack(spacing: 12) {
                MetricCard(
                    title: "COUPONS REDEEMED",
                    value: "\(vm.totalCouponsRedeemed)",
                    icon: "ticket.fill",
                    color: .orange
                )
                MetricCard(
                    title: "AVG OPT-IN",
                    value: "\(Int(vm.avgOptInRate * 100))%",
                    icon: "person.fill.checkmark",
                    color: .purple
                )
            }
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Campaign List

    private var campaignList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("ACTIVE CAMPAIGNS")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white.opacity(0.5))
                .tracking(1.2)
                .padding(.horizontal, 16)

            if vm.activeCampaigns.isEmpty {
                emptyState
            } else {
                ForEach(vm.activeCampaigns) { campaign in
                    CampaignRow(campaign: campaign) {
                        selectedCampaign = campaign
                    }
                    .padding(.horizontal, 16)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "megaphone")
                .font(.system(size: 40))
                .foregroundColor(.white.opacity(0.15))
            Text("No active campaigns")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white.opacity(0.4))
            Text("Sponsor campaigns will appear here during live games.")
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.25))
                .multilineTextAlignment(.center)
        }
        .padding(40)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Metric Card

struct MetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(color)
                Spacer()
            }
            Text(value)
                .font(.system(size: 24, weight: .black, design: .rounded))
                .foregroundColor(.white)
            Text(title)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.white.opacity(0.4))
                .tracking(0.8)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(color.opacity(0.15), lineWidth: 1)
        )
    }
}

// MARK: - Campaign Row

struct CampaignRow: View {
    let campaign: SponsorCampaign
    let onTap: () -> Void

    private var brandColor: Color {
        Color(arenza: campaign.brandColor)
    }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                // Header with brand accent
                HStack(spacing: 12) {
                    // Brand icon
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(brandColor.opacity(0.15))
                            .frame(width: 48, height: 48)
                        Text(campaign.adFormat.emoji)
                            .font(.system(size: 22))
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 6) {
                            Text(campaign.sponsorName)
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.white)
                            CampaignStatusBadge(status: campaign.status)
                        }
                        Text(campaign.adFormat.displayName)
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.5))
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white.opacity(0.25))
                }
                .padding(16)

                // Metrics bar
                if let metrics = campaign.metrics {
                    HStack(spacing: 0) {
                        campaignStat(label: "Interactions", value: formatK(metrics.totalInteractions))
                        Divider().frame(height: 28).background(Color.white.opacity(0.08))
                        campaignStat(label: "Opt-In", value: "\(Int(metrics.optInRate * 100))%")
                        Divider().frame(height: 28).background(Color.white.opacity(0.08))
                        campaignStat(label: "Redeemed", value: "\(metrics.couponsRedeemed)")
                        Divider().frame(height: 28).background(Color.white.opacity(0.08))
                        campaignStat(label: "Revenue", value: "$\(formatK(Int(metrics.revenueAttributed)))")
                    }
                    .padding(.vertical, 10)
                    .background(Color.white.opacity(0.02))
                }
            }
            .background(Color.white.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(brandColor.opacity(0.12), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func campaignStat(label: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.white)
            Text(label)
                .font(.system(size: 9))
                .foregroundColor(.white.opacity(0.35))
        }
        .frame(maxWidth: .infinity)
    }

    private func formatK(_ n: Int) -> String {
        if n >= 1000 { return "\(n / 1000).\(n % 1000 / 100)K" }
        return "\(n)"
    }
}

// MARK: - Campaign Status Badge

struct CampaignStatusBadge: View {
    let status: CampaignStatus

    private var badgeColor: Color {
        switch status {
        case .live:   return Color(red: 0.0, green: 0.82, blue: 0.60)
        case .paused: return .yellow
        case .ended:  return .red
        case .draft:  return .gray
        case .review: return .orange
        }
    }

    var body: some View {
        Text(status.rawValue.uppercased())
            .font(.system(size: 9, weight: .black))
            .foregroundColor(badgeColor)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(badgeColor.opacity(0.12))
            .clipShape(Capsule())
    }
}

// MARK: - Campaign Detail Sheet

struct CampaignDetailSheet: View {
    let campaign: SponsorCampaign
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    campaignHeader

                    // Engagement Funnel
                    if let funnel = campaign.metrics?.engagementFunnel {
                        funnelCard(funnel)
                    }

                    // Prize Tiers
                    prizeTierSection

                    // Campaign Config
                    configSection

                    Spacer(minLength: 40)
                }
                .padding(20)
            }
            .background(Color(white: 0.06).ignoresSafeArea())
            .navigationTitle(campaign.sponsorName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(Color(red: 0.0, green: 0.82, blue: 0.60))
                }
            }
        }
    }

    // MARK: - Campaign Header

    private var campaignHeader: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(arenza: campaign.brandColor).opacity(0.2))
                        .frame(width: 64, height: 64)
                    Text(campaign.adFormat.emoji)
                        .font(.system(size: 32))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(campaign.sponsorName)
                        .font(.system(size: 20, weight: .black))
                        .foregroundColor(.white)
                    if let tagline = campaign.brandTagline {
                        Text(tagline)
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    HStack(spacing: 8) {
                        CampaignStatusBadge(status: campaign.status)
                        Text(campaign.adFormat.displayName)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.white.opacity(0.4))
                    }
                }

                Spacer()
            }

            // Key metrics row
            if let m = campaign.metrics {
                HStack(spacing: 12) {
                    detailMetric(label: "Users", value: "\(m.uniqueUsers)", color: .cyan)
                    detailMetric(label: "Opt-In", value: "\(Int(m.optInRate * 100))%", color: Color(red: 0.0, green: 0.82, blue: 0.60))
                    detailMetric(label: "Revenue", value: "$\(String(format: "%.0f", m.revenueAttributed))", color: .orange)
                }
            }
        }
        .padding(18)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color(arenza: campaign.brandColor).opacity(0.2), lineWidth: 1)
        )
    }

    private func detailMetric(label: String, value: String, color: Color) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.white.opacity(0.4))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Engagement Funnel

    private func funnelCard(_ funnel: EngagementFunnel) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("ENGAGEMENT FUNNEL")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.white.opacity(0.4))
                .tracking(1)

            let steps: [(String, Int, Color)] = [
                ("Views", funnel.views, .blue),
                ("Plays", funnel.plays, .cyan),
                ("Correct", funnel.correct, Color(red: 0.0, green: 0.82, blue: 0.60)),
                ("Coupon Revealed", funnel.couponRevealed, .orange),
                ("Redeemed", funnel.couponRedeemed, .yellow),
            ]

            let maxVal = Double(funnel.views)

            ForEach(Array(steps.enumerated()), id: \.offset) { _, step in
                HStack(spacing: 10) {
                    Text(step.0)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white.opacity(0.6))
                        .frame(width: 100, alignment: .trailing)

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.white.opacity(0.06))
                                .frame(height: 8)
                            Capsule()
                                .fill(step.2)
                                .frame(width: geo.size.width * CGFloat(Double(step.1) / max(maxVal, 1)), height: 8)
                        }
                    }
                    .frame(height: 8)

                    Text("\(step.1)")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(.white.opacity(0.6))
                        .frame(width: 50, alignment: .trailing)
                }
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Prize Tiers

    private var prizeTierSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("PRIZE TIERS")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.white.opacity(0.4))
                .tracking(1)

            ForEach(campaign.prizeTiers) { tier in
                HStack(spacing: 12) {
                    Image(systemName: "gift.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.orange)
                        .frame(width: 32)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(tier.label)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                        Text(tier.value.displayText)
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.5))
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text(tier.oddsFormatted)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Color(red: 0.0, green: 0.82, blue: 0.60))
                        Text("Qty: \(tier.quantity)")
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.35))
                    }
                }
                .padding(12)
                .background(Color.white.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    // MARK: - Config Section

    private var configSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("CAMPAIGN CONFIG")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.white.opacity(0.4))
                .tracking(1)

            VStack(spacing: 0) {
                configRow(label: "Pricing Tier", value: campaign.pricingTier.label)
                Divider().background(Color.white.opacity(0.06))
                configRow(label: "Coupon Prefix", value: campaign.couponPrefix)
                Divider().background(Color.white.opacity(0.06))
                configRow(label: "Points Budget", value: "\(campaign.pointsBudget) AZT")
                Divider().background(Color.white.opacity(0.06))
                configRow(label: "Max Winners/Game", value: "\(campaign.maxWinnersPerGame)")
                if let sport = campaign.targetSport {
                    Divider().background(Color.white.opacity(0.06))
                    configRow(label: "Target Sport", value: sport)
                }
                Divider().background(Color.white.opacity(0.06))
                let triggers = campaign.triggerMoments.map { $0.displayLabel }.joined(separator: ", ")
                configRow(label: "Trigger Moments", value: triggers)
            }
            .background(Color.white.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    private func configRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.5))
            Spacer()
            Text(value)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }
}

// MARK: - ViewModel

@MainActor
final class SponsorCampaignViewModel: ObservableObject {
    @Published var campaigns: [SponsorCampaign] = []

    var activeCampaigns: [SponsorCampaign] {
        campaigns.filter { $0.isActive || $0.isUpcoming }
    }

    var totalCouponsRedeemed: Int {
        campaigns.compactMap { $0.metrics?.couponsRedeemed }.reduce(0, +)
    }

    var avgOptInRate: Double {
        let rates = campaigns.compactMap { $0.metrics?.optInRate }
        guard !rates.isEmpty else { return 0 }
        return rates.reduce(0, +) / Double(rates.count)
    }

    var formattedTotalInteractions: String {
        let total = campaigns.compactMap { $0.metrics?.totalInteractions }.reduce(0, +)
        if total >= 1000 { return "\(total / 1000).\(total % 1000 / 100)K" }
        return "\(total)"
    }

    func load() async {
        // TODO: Replace with API call: GET /v1/campaigns?status=live
        campaigns = SponsorCampaign.demoCampaigns
    }
}
