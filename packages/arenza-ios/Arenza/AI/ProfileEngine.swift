// ProfileEngine.swift — Arenza (C1: AI Profile Engine)
// On-device viewer classification into 12 audience segments.
// Sprint 1: rule-based classifier (no Core ML dependency).
// Phase 4: replace with ViewerClassifier.mlmodel via hot-swap.

import Foundation
import Combine

// MARK: - Profile Engine

@MainActor
final class ProfileEngine: ObservableObject {

    static let shared = ProfileEngine()

    // Published for BidRequestAssembler and UI
    @Published private(set) var currentSegment: ViewerSegment = .newViewerUnknown
    @Published private(set) var viewerScore: Double = 0.0     // 0.0–1.0 premium tier
    @Published private(set) var sportAffinities: [String: Double] = [:]

    private let signalCollector: SignalCollector
    private var reclassifyTimer: Timer?
    private var cancellables = Set<AnyCancellable>()

    private init() {
        self.signalCollector = SignalCollector.shared
        schedulePeriodicReclassify()
        Task { await reclassify() }
    }

    // MARK: - Reclassification (rule-based, Sprint 1)

    func reclassify() async {
        let features = signalCollector.buildFeatureVector()
        let (segment, score) = RuleBasedViewerClassifier.classify(features: features)
        currentSegment = segment
        viewerScore    = score
        sportAffinities = buildSportAffinities(from: features)

        // Cache segment ID for nonisolated consumers (e.g. AdaptiveFrequencyController)
        UserDefaults.standard.set(segment.rawValue, forKey: "arenza.cachedSegmentID")

        // Upload segment ID only — never raw behavioral data
        await uploadSegment(segment: segment, score: score)

        // Check churn risk
        checkChurnRisk(features: features)
    }

    // MARK: - Enrichment from prediction results (Profile Enrichment Bridge)

    func ingestPredictionResult(
        category: PredictionCategory,
        isCorrect: Bool,
        timeToAnswerSeconds: Double,
        currentStreak: Int
    ) {
        // Prediction behavior signals enrich sport affinities
        let sportKey = category.sportKey
        let boost = isCorrect ? 0.1 : 0.02
        sportAffinities[sportKey, default: 0.5] =
            min(1.0, (sportAffinities[sportKey, default: 0.5] + boost))

        // Fast answerers are engaged fans — boost engagement-based segments
        if timeToAnswerSeconds < 5.0 && isCorrect {
            Task { await reclassify() }
        }
    }

    // MARK: - Churn Risk

    private func checkChurnRisk(features: ViewerFeatureVector) {
        let churnScore = ChurnPredictor.predict(features: features)
        if churnScore > 0.65 {
            print("[ProfileEngine] ⚠️ High churn risk (\(String(format: "%.2f", churnScore))) — scheduling re-engagement push")
            // TODO Phase 2: APNsReEngagementService.shared.schedule(segmentID: currentSegment.rawValue, churnScore: churnScore)
        }
    }

    // MARK: - Scheduling

    private func schedulePeriodicReclassify() {
        reclassifyTimer?.invalidate()
        reclassifyTimer = Timer.scheduledTimer(withTimeInterval: 4 * 3600, repeats: true) { [weak self] _ in
            Task { await self?.reclassify() }
        }
    }

    // MARK: - Backend sync (segment only, no PII)

    private func uploadSegment(segment: ViewerSegment, score: Double) async {
        // POST /v1/profile/segment — only transmits { segmentID, viewerScore, sportAffinities }
        // Laplace noise added to viewerScore before upload (differential privacy)
        let noisyScore = DifferentialPrivacy.addLaplaceNoise(to: score, scale: 0.05)
        print("[ProfileEngine] Segment: \(segment.label) | Score: \(String(format: "%.3f", noisyScore))")
        // TODO: await CMXSAPIClient.shared.uploadSegment(segmentID: segment.rawValue, viewerScore: noisyScore, affinities: sportAffinities)
    }

    // MARK: - Sport affinity mapping

    private func buildSportAffinities(from features: ViewerFeatureVector) -> [String: Double] {
        var affinities: [String: Double] = [:]
        if features.bettingOverlayTaps > 0 {
            affinities["betting"] = min(1.0, Double(features.bettingOverlayTaps) / 10.0)
        }
        if features.predictionParticipationRate > 0 {
            affinities["live_sports"] = features.predictionParticipationRate
        }
        if features.commerceInteractionCount > 0 {
            affinities["sports_commerce"] = min(1.0, Double(features.commerceInteractionCount) / 5.0)
        }
        return affinities
    }
}

// MARK: - Rule-Based Viewer Classifier (Sprint 1 stub)
// Replaced by Core ML ViewerClassifier.mlmodel in Phase 4.

enum RuleBasedViewerClassifier {

    static func classify(features: ViewerFeatureVector) -> (ViewerSegment, Double) {
        // SEG-11: Insufficient signal (default for new users)
        guard features.totalWatchTimeHours >= 1.0 else {
            return (.newViewerUnknown, 0.1)
        }

        // SEG-03: Sports Bettor
        if features.bettingOverlayTaps > 0 && (features.sportAffinities["betting"] ?? 0) > 0.3 {
            return (.sportsBettor, 0.85)
        }

        // SEG-09: Affluent Sports Viewer (high completion + commerce)
        if features.adCompletionRate > 0.8 && features.commerceInteractionCount > 2 {
            return (.affluentSportsViewer, 0.90)
        }

        // SEG-01: Premium Sports Fanatic
        if features.totalWatchTimeHours > 15 && features.adEngagementRate > 0.05 {
            return (.premiumSportsFanatic, 0.88)
        }

        // SEG-02: Live Event Enthusiast
        if features.liveVsVODRatio > 0.8 {
            return (.liveEventEnthusiast, 0.80)
        }

        // SEG-04: Sports Commerce Buyer
        if features.commerceInteractionCount > 0 {
            return (.sportsCommerceBuyer, 0.75)
        }

        // SEG-06: Multi-Sport Superfan
        if features.uniqueSportsWatched >= 4 {
            return (.multiSportSuperfan, 0.72)
        }

        // SEG-10: Sports Travel Intender (high session duration, diverse sports)
        if features.avgSessionDurationMinutes > 60 && features.uniqueSportsWatched >= 3 {
            return (.sportsTravelIntender, 0.70)
        }

        // SEG-07: Young Male 18–34 (high engagement, short sessions)
        if features.adEngagementRate > 0.03 && features.avgSessionDurationMinutes < 30 {
            return (.youngMale1834, 0.65)
        }

        // SEG-08: Household Decision Maker (prime-time viewing)
        if features.sessionFrequencyPerWeek > 4 && features.adCompletionRate > 0.6 {
            return (.householdDecisionMaker, 0.65)
        }

        // SEG-12: Re-engaged lapsed user
        if features.daysSinceFirstSession > 14 && features.sessionFrequencyPerWeek > 0 {
            return (.reEngagedLapsedUser, 0.55)
        }

        // SEG-05: Casual Sports Fan (default known viewer)
        return (.casualSportsFan, 0.40)
    }
}

// MARK: - Churn Predictor (rule-based stub)

enum ChurnPredictor {
    static func predict(features: ViewerFeatureVector) -> Double {
        var score: Double = 0.0
        if features.daysSinceFirstSession > 14 { score += 0.4 }
        if features.sessionFrequencyPerWeek < 1 { score += 0.3 }
        if features.adCompletionRate < 0.3      { score += 0.2 }
        if features.skippedAdsRate > 0.7        { score += 0.1 }
        return min(1.0, score)
    }
}

// MARK: - Differential Privacy Helper

enum DifferentialPrivacy {
    /// Adds Laplace noise to a value before external transmission
    static func addLaplaceNoise(to value: Double, scale: Double) -> Double {
        // Laplace distribution: L(0, scale)
        let u = Double.random(in: -0.5...0.5)
        let noise = -scale * (u >= 0 ? 1 : -1) * log(1 - 2 * abs(u))
        return max(0, min(1, value + noise))
    }
}

// MARK: - Helper for PredictionCategory → sport key

extension PredictionCategory {
    var sportKey: String {
        switch self {
        case .nextScore, .finalScore, .gameEvent: return "live_sports"
        case .playerPerf:  return "player_stats"
        case .nextPlay:    return "live_sports"
        case .trivia:      return "sports_knowledge"
        }
    }
}

// MARK: - Placeholder until ProfileEngine reads sportAffinities
extension ViewerFeatureVector {
    var sportAffinities: [String: Double] { [:] }
}
