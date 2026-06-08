// AdaptiveFrequencyController.swift — Arenza (C1: AI Profile Engine)
// ML-powered ad frequency capping — prevents ad fatigue, enforces pod diversity.
// Sprint 1: rule-based. Phase 4: replace with FrequencyScorer.mlmodel.

import Foundation

// MARK: - Impression Record (in-memory for Sprint 1; GRDB SQLite in Phase 4)

struct ImpressionRecord {
    let creativeID: String
    let advertiserID: String
    var impressionCount: Int
    var skipCount: Int
    var engagementCount: Int
    var completionRateAvg: Double
    var lastSeenAt: Date
}

// MARK: - Adaptive Frequency Controller

final class AdaptiveFrequencyController {

    static let shared = AdaptiveFrequencyController()

    // Hard limits (always enforced regardless of ML score)
    static let hardMaxImpressionsPerSession: Int = 4
    static let maxConsecutiveFromSameAdvertiser: Int = 2
    static let minUniqueCretivesPerPod: Int = 3

    private var records: [String: ImpressionRecord] = [:]      // keyed by creativeID
    private var recentAdvertiserHistory: [String] = []         // FIFO, last N advertisers served

    private init() {}

    // MARK: - Decision: should we serve this creative?

    func shouldServe(creativeID: String, advertiserID: String) -> Bool {
        let record = records[creativeID] ?? ImpressionRecord(
            creativeID: creativeID, advertiserID: advertiserID,
            impressionCount: 0, skipCount: 0, engagementCount: 0,
            completionRateAvg: 0.5, lastSeenAt: .distantPast
        )

        // Hard cap 1: max impressions per session
        guard record.impressionCount < Self.hardMaxImpressionsPerSession else {
            print("[AFC] ❌ Hard cap reached for \(creativeID.prefix(8))")
            return false
        }

        // Hard cap 2: max consecutive from same advertiser
        let recentConsecutive = consecutiveCount(advertiserID: advertiserID)
        guard recentConsecutive < Self.maxConsecutiveFromSameAdvertiser else {
            print("[AFC] ❌ Consecutive advertiser cap for \(advertiserID)")
            return false
        }

        // Rule-based score (Sprint 1 — replace with Core ML in Phase 4)
        let score = computeScore(record: record)
        let decision = score >= 0.3
        print("[AFC] Creative \(creativeID.prefix(8))… score: \(String(format: "%.2f", score)) → \(decision ? "✅ serve" : "❌ suppress")")
        return decision
    }

    // MARK: - Record impression feedback

    func recordImpression(
        creativeID: String,
        advertiserID: String,
        completionPercent: Double,
        wasEngaged: Bool,
        wasSkipped: Bool
    ) {
        var record = records[creativeID] ?? ImpressionRecord(
            creativeID: creativeID, advertiserID: advertiserID,
            impressionCount: 0, skipCount: 0, engagementCount: 0,
            completionRateAvg: 0.5, lastSeenAt: .distantPast
        )
        record.impressionCount += 1
        if wasSkipped   { record.skipCount += 1 }
        if wasEngaged   { record.engagementCount += 1 }
        record.completionRateAvg = (record.completionRateAvg + completionPercent) / 2.0
        record.lastSeenAt = Date()
        records[creativeID] = record

        // Update advertiser history (FIFO, keep last 5)
        recentAdvertiserHistory.append(advertiserID)
        if recentAdvertiserHistory.count > 5 {
            recentAdvertiserHistory.removeFirst()
        }
    }

    // MARK: - Diversity check: is this pod diverse enough?

    func validatePodDiversity(creativeIDs: [String]) -> Bool {
        let advertiserIDs = Set(creativeIDs.compactMap { records[$0]?.advertiserID })
        let isValid = advertiserIDs.count >= Self.minUniqueCretivesPerPod
        if !isValid {
            print("[AFC] ⚠️ Pod diversity check failed — only \(advertiserIDs.count) unique advertisers")
        }
        return isValid
    }

    // MARK: - Reset for new session

    func resetSession() {
        records.removeAll()
        recentAdvertiserHistory.removeAll()
        print("[AFC] Session reset")
    }

    // MARK: - Private scoring

    private func computeScore(record: ImpressionRecord) -> Double {
        guard record.impressionCount > 0 else { return 1.0 }

        let skipRate = Double(record.skipCount) / Double(record.impressionCount)
        let engagementRate = Double(record.engagementCount) / Double(record.impressionCount)
        let minutesSinceSeen = Date().timeIntervalSince(record.lastSeenAt) / 60.0

        // Base score from completion rate
        var score = record.completionRateAvg

        // Penalize skips
        score -= skipRate * 0.4

        // Boost for engagement
        score += engagementRate * 0.2

        // Freshness boost: reward time since last seen (up to 30 min)
        score += min(minutesSinceSeen / 30.0, 0.3)

        // Penalize high impression count
        score -= Double(record.impressionCount) * 0.1

        // Apply segment modifier (SEG-01 through SEG-04 tolerate more impressions).
        // ProfileEngine.shared.currentSegment is @MainActor — we read a cached value instead
        // to avoid actor-isolation violations in this synchronous context.
        let cachedSegmentRaw = UserDefaults.standard.integer(forKey: "arenza.cachedSegmentID")
        let segmentBoost = (cachedSegmentRaw > 0 && cachedSegmentRaw <= 4) ? 0.1 : 0.0
        score += segmentBoost

        return max(0, min(1, score))
    }

    private func consecutiveCount(advertiserID: String) -> Int {
        var count = 0
        for id in recentAdvertiserHistory.reversed() {
            if id == advertiserID { count += 1 }
            else { break }
        }
        return count
    }
}
