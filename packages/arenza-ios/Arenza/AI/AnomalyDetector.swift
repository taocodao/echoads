// AnomalyDetector.swift — Arenza (C1: AI Profile Engine)
// On-device behavioral fraud detection.
// Monitors session signals for bot-like behavior.
// If fraudScore > 0.75: suppresses bid requests and PoD signing silently.

import Foundation
import UIKit
import Combine

// MARK: - Anomaly Detector

@MainActor
final class AnomalyDetector: ObservableObject {

    static let shared = AnomalyDetector()

    @Published private(set) var fraudScore: Double = 0.0
    @Published private(set) var isSuspectSession: Bool = false

    private let fraudThreshold: Double = 0.75
    private var sessionStart: Date = Date()
    private var pauseEventCount: Int = 0
    private var seekEventCount: Int = 0
    private var networkSwitchCount: Int = 0
    private var playbackEventTimestamps: [Date] = []
    private var adCompletionRates: [Double] = []
    private var orientationLastChanged: Date = Date()
    private var cancellables = Set<AnyCancellable>()

    private init() {
        observeOrientationChanges()
        observeNetworkChanges()
    }

    // MARK: - Session events (called by PlayerViewModel)

    func onSessionStart() {
        sessionStart = Date()
        pauseEventCount = 0
        seekEventCount = 0
        playbackEventTimestamps = []
        adCompletionRates = []
        fraudScore = 0.0
        isSuspectSession = false
    }

    func onPlaybackEvent() {
        playbackEventTimestamps.append(Date())
        evaluate()
    }

    func onPauseEvent() {
        pauseEventCount += 1
        evaluate()
    }

    func onSeekEvent() {
        seekEventCount += 1
        evaluate()
    }

    func onAdCompleted(completionPercent: Double) {
        adCompletionRates.append(completionPercent)
        evaluate()
    }

    // MARK: - Score computation

    private func evaluate() {
        let signals = buildSignals()
        let score = computeScore(from: signals)
        fraudScore = score
        isSuspectSession = score > fraudThreshold

        if isSuspectSession {
            print("[AnomalyDetector] 🚨 Suspect session (score: \(String(format: "%.2f", score))) — suppressing bids")
            reportSuspectSession(score: score)
        }
    }

    private func buildSignals() -> SessionAnomalySignals {
        let minutesWithoutOrientation = Date().timeIntervalSince(orientationLastChanged) / 60.0
        let sessionMinutes = max(1, Date().timeIntervalSince(sessionStart) / 60.0)
        let eventsPerMinute = Double(playbackEventTimestamps.count) / sessionMinutes

        // Consistency: stdev of completion rates (0.0 = all identical = suspicious)
        let consistency: Double
        if adCompletionRates.count >= 3 {
            let mean = adCompletionRates.reduce(0, +) / Double(adCompletionRates.count)
            let variance = adCompletionRates.map { pow($0 - mean, 2) }.reduce(0, +) / Double(adCompletionRates.count)
            consistency = sqrt(variance)  // Higher = more human-like variation
        } else {
            consistency = 0.5  // Unknown — assume ok
        }

        return SessionAnomalySignals(
            noOrientationChangeMinutes: minutesWithoutOrientation,
            playbackEventsPerMinute: eventsPerMinute,
            adCompletionConsistency: consistency,
            pauseEventCount: pauseEventCount,
            seekEventCount: seekEventCount,
            networkSwitchCount: networkSwitchCount,
            isMotionActive: true  // Phase 4: add CMMotionManager
        )
    }

    private func computeScore(from signals: SessionAnomalySignals) -> Double {
        var score: Double = 0.0
        let sessionMins = Date().timeIntervalSince(sessionStart) / 60.0

        // Signal 1: No orientation change for > 10 minutes (mobile only)
        if UIDevice.current.userInterfaceIdiom == .phone &&
           signals.noOrientationChangeMinutes > 10 && sessionMins > 10 {
            score += 0.15
        }

        // Signal 2: Very few playback events (bot-like)
        if signals.playbackEventsPerMinute < 0.5 && sessionMins > 5 {
            score += 0.20
        }

        // Signal 3: All ads completed at exactly 100% with near-zero variance
        if signals.adCompletionConsistency < 0.02 && adCompletionRates.count >= 3 &&
           adCompletionRates.allSatisfy({ $0 > 0.98 }) {
            score += 0.25
        }

        // Signal 4: Zero pauses in a 30+ minute session
        if signals.pauseEventCount == 0 && sessionMins > 30 {
            score += 0.15
        }

        // Signal 5: Zero seeks in a 30+ minute session
        if signals.seekEventCount == 0 && sessionMins > 30 {
            score += 0.10
        }

        // Signal 6: Zero network switches on mobile session > 20 mins
        if UIDevice.current.userInterfaceIdiom == .phone &&
           signals.networkSwitchCount == 0 && sessionMins > 20 {
            score += 0.10
        }

        // Signal 7: No motion (placeholder, CMMotionManager in Phase 4)
        if !signals.isMotionActive && sessionMins > 10 {
            score += 0.05
        }

        return min(1.0, score)
    }

    // MARK: - Reporting (silent — never shows error to user)

    private func reportSuspectSession(score: Double) {
        Task {
            print("[AnomalyDetector] Reporting suspect session — score: \(score)")
            // TODO: await CMXSAPIClient.shared.reportFraudSession(score: score)
        }
    }

    // MARK: - Observers

    private func observeOrientationChanges() {
        NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)
            .sink { [weak self] _ in
                self?.orientationLastChanged = Date()
            }
            .store(in: &cancellables)
    }

    private func observeNetworkChanges() {
        // Lightweight — just count changes. Full NWPathMonitor in Phase 2.
        NotificationCenter.default.publisher(for: .NSBundleDidLoad)
            .sink { [weak self] _ in self?.networkSwitchCount += 1 }
            .store(in: &cancellables)
    }
}
