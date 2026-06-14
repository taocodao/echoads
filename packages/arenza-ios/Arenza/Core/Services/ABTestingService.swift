// ABTestingService.swift — Arenza
// Phase 3: A/B Testing Framework for game format optimization.
//
// Tests alternate game formats (spin vs scratch vs bingo) per session,
// measures engagement delta per sponsor. Runs entirely on-device for demo;
// production would use a server-side assignment with Statsig or LaunchDarkly.
//
// Usage:
//   let variant = ABTestingService.shared.variant(for: .gameFormat)
//   if variant == .spinWheel { ... } else { ... }
//
// Results are stored locally and can be exported to the analytics API.

import Foundation
import SwiftUI
import Combine

// MARK: - A/B Testing Service

@MainActor
final class ABTestingService: ObservableObject {

    static let shared = ABTestingService()

    // MARK: - Experiment Definitions

    enum Experiment: String, CaseIterable {
        case gameFormat         = "game_format"
        case sponsorRotation    = "sponsor_rotation"
        case rewardDisplay      = "reward_display"
        case onboardingFlow     = "onboarding_flow"
    }

    enum GameFormatVariant: String {
        case spinWheel  = "spin_wheel"
        case scratchCard = "scratch_card"
        case bingo      = "bingo"
        case control    = "control"   // current default
    }

    enum SponsorRotationVariant: String {
        case geo        = "geo"       // nearest first
        case engagement = "engagement" // most interactions first
        case random     = "random"
        case control    = "control"
    }

    // MARK: - Published

    @Published private(set) var activeVariants: [String: String] = [:]
    @Published private(set) var sessionMetrics: [String: ExperimentMetric] = [:]

    // MARK: - Private

    private let userDefaults = UserDefaults.standard
    private let kVariantKey = "arenza_ab_variants"
    private let sessionId: String

    private init() {
        sessionId = UUID().uuidString
        loadOrAssignVariants()
    }

    // MARK: - Variant Assignment

    func variant(for experiment: Experiment) -> String {
        activeVariants[experiment.rawValue] ?? "control"
    }

    var gameFormatVariant: GameFormatVariant {
        GameFormatVariant(rawValue: variant(for: .gameFormat)) ?? .control
    }

    var sponsorRotationVariant: SponsorRotationVariant {
        SponsorRotationVariant(rawValue: variant(for: .sponsorRotation)) ?? .control
    }

    private func loadOrAssignVariants() {
        if let saved = userDefaults.dictionary(forKey: kVariantKey) as? [String: String] {
            activeVariants = saved
        } else {
            // Fresh assignment — randomly assign each experiment
            var variants: [String: String] = [:]
            variants[Experiment.gameFormat.rawValue] = assignGameFormat()
            variants[Experiment.sponsorRotation.rawValue] = assignSponsorRotation()
            variants[Experiment.rewardDisplay.rawValue] = Bool.random() ? "prominent" : "control"
            variants[Experiment.onboardingFlow.rawValue] = Bool.random() ? "gamified" : "control"
            activeVariants = variants
            userDefaults.set(variants, forKey: kVariantKey)
        }
    }

    private func assignGameFormat() -> String {
        // 25% each: spin, scratch, bingo, control
        let r = Double.random(in: 0..<1)
        switch r {
        case 0..<0.25: return GameFormatVariant.spinWheel.rawValue
        case 0.25..<0.5: return GameFormatVariant.scratchCard.rawValue
        case 0.5..<0.75: return GameFormatVariant.bingo.rawValue
        default: return GameFormatVariant.control.rawValue
        }
    }

    private func assignSponsorRotation() -> String {
        let r = Double.random(in: 0..<1)
        switch r {
        case 0..<0.33: return SponsorRotationVariant.geo.rawValue
        case 0.33..<0.67: return SponsorRotationVariant.engagement.rawValue
        default: return SponsorRotationVariant.control.rawValue
        }
    }

    // MARK: - Metric Tracking

    struct ExperimentMetric: Codable {
        var impressions: Int = 0
        var interactions: Int = 0
        var completions: Int = 0
        var rewardsEarned: Int = 0
        var sessionDurationSeconds: Double = 0

        var engagementRate: Double {
            guard impressions > 0 else { return 0 }
            return Double(interactions) / Double(impressions)
        }
        var completionRate: Double {
            guard interactions > 0 else { return 0 }
            return Double(completions) / Double(interactions)
        }
    }

    func trackImpression(experiment: Experiment) {
        var m = sessionMetrics[experiment.rawValue] ?? ExperimentMetric()
        m.impressions += 1
        sessionMetrics[experiment.rawValue] = m
        flushMetrics()
    }

    func trackInteraction(experiment: Experiment) {
        var m = sessionMetrics[experiment.rawValue] ?? ExperimentMetric()
        m.interactions += 1
        sessionMetrics[experiment.rawValue] = m
        flushMetrics()
    }

    func trackCompletion(experiment: Experiment, rewardEarned: Bool = false) {
        var m = sessionMetrics[experiment.rawValue] ?? ExperimentMetric()
        m.completions += 1
        if rewardEarned { m.rewardsEarned += 1 }
        sessionMetrics[experiment.rawValue] = m
        flushMetrics()
    }

    private func flushMetrics() {
        // Production: POST to /api/v1/ab/metrics
        // Demo: print summary
        #if DEBUG
        let summary = sessionMetrics.map { key, val in
            "\(key): \(val.interactions) interactions, \(String(format: "%.1f%%", val.engagementRate * 100)) engagement"
        }.joined(separator: " | ")
        print("[A/B] \(summary)")
        #endif
    }

    // MARK: - Reset (for testing)

    func resetVariants() {
        userDefaults.removeObject(forKey: kVariantKey)
        loadOrAssignVariants()
    }
}

// MARK: - A/B Dashboard View (for Settings or Debug screen)

struct ABTestingDashboardView: View {
    @ObservedObject private var ab = ABTestingService.shared

    var body: some View {
        NavigationView {
            List {
                Section("Active Variants") {
                    ForEach(ABTestingService.Experiment.allCases, id: \.self) { exp in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(exp.rawValue.replacingOccurrences(of: "_", with: " ").capitalized)
                                    .font(.system(size: 13, weight: .semibold))
                                Text("variant: \(ab.variant(for: exp))")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Text(ab.variant(for: exp))
                                .font(.system(size: 10, weight: .bold))
                                .padding(.horizontal, 8).padding(.vertical, 3)
                                .background(Color(arenza: "#00c9b1").opacity(0.15))
                                .foregroundColor(Color(arenza: "#00c9b1"))
                                .clipShape(Capsule())
                        }
                    }
                }

                Section("Session Metrics") {
                    if ab.sessionMetrics.isEmpty {
                        Text("No interactions yet this session.")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(Array(ab.sessionMetrics), id: \.key) { key, metric in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(key).font(.system(size: 12, weight: .semibold))
                                HStack(spacing: 12) {
                                    metricBadge("Impr", "\(metric.impressions)")
                                    metricBadge("Intr", "\(metric.interactions)")
                                    metricBadge("Comp", "\(metric.completions)")
                                    metricBadge("ER", "\(String(format: "%.0f%%", metric.engagementRate * 100))")
                                }
                            }
                        }
                    }
                }

                Section {
                    Button("Reset All Variants") {
                        ab.resetVariants()
                    }
                    .foregroundColor(Color(arenza: "#ff6b35"))
                }
            }
            .navigationTitle("A/B Testing")
            .navigationBarTitleDisplayMode(.inline)
        }
        .preferredColorScheme(.dark)
    }

    private func metricBadge(_ label: String, _ value: String) -> some View {
        VStack(spacing: 1) {
            Text(value).font(.system(size: 11, weight: .bold)).foregroundColor(.white)
            Text(label).font(.system(size: 8)).foregroundColor(.secondary)
        }
    }
}
// trigger testflight
