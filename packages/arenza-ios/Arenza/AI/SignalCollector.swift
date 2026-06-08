// SignalCollector.swift — Arenza (C1: AI Profile Engine)
// Passive event collection pipeline for viewer behavior signals.
// Zero-latency — never blocks the main thread. Batch-writes to ProfileStore.

import Foundation
import Combine
import UIKit

// MARK: - Profile Store (in-memory + persistence via UserDefaults for prototype)
// TODO Phase 4: Replace UserDefaults with GRDB.swift encrypted SQLite

final class ProfileStore {
    static let shared = ProfileStore()
    private let defaults = UserDefaults.standard
    private let sessionID = UUID().uuidString

    private init() {}

    // MARK: - Current Viewer Feature Vector
    var featureVector: ViewerFeatureVector {
        ViewerFeatureVector(
            totalWatchTimeHours:          defaults.double(forKey: "totalWatchHours"),
            liveVsVODRatio:               defaults.double(forKey: "liveVsVODRatio"),
            uniqueSportsWatched:          defaults.integer(forKey: "uniqueSports"),
            avgSessionDurationMinutes:    defaults.double(forKey: "avgSessionMins"),
            adEngagementRate:             defaults.double(forKey: "adEngagementRate"),
            adCompletionRate:             defaults.double(forKey: "adCompletionRate"),
            commerceInteractionCount:     defaults.integer(forKey: "commerceCount"),
            apnsOpenRate:                 defaults.double(forKey: "apnsOpenRate"),
            skippedAdsRate:               defaults.double(forKey: "skippedAdsRate"),
            sessionFrequencyPerWeek:      defaults.double(forKey: "sessionsPerWeek"),
            daysSinceFirstSession:        defaults.integer(forKey: "daysSinceFirst"),
            bettingOverlayTaps:           defaults.integer(forKey: "bettingTaps"),
            predictionParticipationRate:  defaults.double(forKey: "predictionRate")
        )
    }

    // MARK: - Persist an AdEvent signal

    func record(adEvent: AdEvent) {
        let queue = DispatchQueue(label: "com.arenza.profilestore", qos: .background)
        queue.async { [weak self] in
            guard let self else { return }
            switch adEvent.type {
            case .adCompleted:
                self.incrementDouble("adCompletionRate", newSample: adEvent.completionPercent)
            case .adSkipped:
                self.incrementDouble("skippedAdsRate", newSample: 1.0)
                self.incrementDouble("adCompletionRate", newSample: adEvent.completionPercent)
            case .overlayTapped, .overlayExpanded:
                self.incrementDouble("adEngagementRate", newSample: 1.0)
            case .applePayCompleted, .firstCommercePurchase:
                self.defaults.set(self.defaults.integer(forKey: "commerceCount") + 1,
                                  forKey: "commerceCount")
            default: break
            }
        }
    }

    func record(contentEvent: ContentEvent) {
        let queue = DispatchQueue(label: "com.arenza.profilestore", qos: .background)
        queue.async { [weak self] in
            guard let self else { return }
            switch contentEvent.type {
            case .playbackEnded:
                self.defaults.set(self.defaults.integer(forKey: "uniqueSports") + 1,
                                  forKey: "uniqueSports")
                let isLive = contentEvent.isLive
                let current = self.defaults.double(forKey: "liveVsVODRatio")
                self.defaults.set((current + (isLive ? 1.0 : 0.0)) / 2.0, forKey: "liveVsVODRatio")
            case .notificationOpened:
                self.incrementDouble("apnsOpenRate", newSample: 1.0)
            default: break
            }
        }
    }

    func recordWatchTime(minutes: Double) {
        let current = defaults.double(forKey: "totalWatchHours")
        defaults.set(current + (minutes / 60.0), forKey: "totalWatchHours")
    }

    func recordSessionEnd(durationMinutes: Double) {
        let current = defaults.double(forKey: "avgSessionMins")
        defaults.set((current + durationMinutes) / 2.0, forKey: "avgSessionMins")
        // Update sessions per week (rolling)
        let sessions = defaults.double(forKey: "sessionsPerWeek")
        defaults.set(min(sessions + 0.14, 21), forKey: "sessionsPerWeek")  // 0.14 ≈ 1/7
    }

    func recordFirstLaunch() {
        if defaults.integer(forKey: "daysSinceFirst") == 0 {
            defaults.set(0, forKey: "daysSinceFirst")
            defaults.set(Date().timeIntervalSince1970, forKey: "firstLaunchTimestamp")
        } else {
            let first = defaults.double(forKey: "firstLaunchTimestamp")
            let days = Int((Date().timeIntervalSince1970 - first) / 86400)
            defaults.set(days, forKey: "daysSinceFirst")
        }
    }

    func recordBettingTap() {
        defaults.set(defaults.integer(forKey: "bettingTaps") + 1, forKey: "bettingTaps")
    }

    func recordPredictionParticipation(correct: Bool) {
        let current = defaults.double(forKey: "predictionRate")
        defaults.set((current + (correct ? 1.0 : 0.5)) / 2.0, forKey: "predictionRate")
    }

    // MARK: - Rolling average helper

    private func incrementDouble(_ key: String, newSample: Double) {
        let current = defaults.double(forKey: key)
        defaults.set((current + newSample) / 2.0, forKey: key)
    }
}

// MARK: - Signal Collector (event capture, batched writes)

@MainActor
final class SignalCollector: ObservableObject {

    static let shared = SignalCollector()
    private let store = ProfileStore.shared
    private var sessionStart = Date()
    private var cancellables = Set<AnyCancellable>()

    private init() {
        observeAppLifecycle()
        store.recordFirstLaunch()
    }

    // MARK: - Public record API

    func record(_ event: AdEvent) {
        store.record(adEvent: event)
        // Trigger immediate reclassify on high-signal events
        if event.type == .firstCommercePurchase || event.type == .applePayCompleted {
            Task { await ProfileEngine.shared.reclassify() }
        }
    }

    func record(_ event: ContentEvent) {
        store.record(contentEvent: event)
    }

    func recordBettingTap() {
        store.recordBettingTap()
    }

    func recordPredictionResult(correct: Bool) {
        store.recordPredictionParticipation(correct: correct)
    }

    // MARK: - Current feature vector for ProfileEngine

    func buildFeatureVector() -> ViewerFeatureVector {
        store.featureVector
    }

    // MARK: - App lifecycle

    private func observeAppLifecycle() {
        NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)
            .sink { [weak self] _ in self?.onAppBackground() }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in self?.onAppForeground() }
            .store(in: &cancellables)
    }

    private func onAppBackground() {
        let durationMins = Date().timeIntervalSince(sessionStart) / 60.0
        store.recordSessionEnd(durationMinutes: durationMins)
    }

    private func onAppForeground() {
        sessionStart = Date()
    }
}
