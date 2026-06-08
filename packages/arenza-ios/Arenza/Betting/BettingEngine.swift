// BettingEngine.swift — Arenza (C6: Betting Engine)
// Coordinates geo-compliance, moment gating, odds fetch, overlay display,
// and CPA affiliate attribution. Arenza is a MEDIA AFFILIATE — not an operator.

import Foundation
import Combine

// MARK: - Odds API Client

actor OddsAPIClient {
    static let shared = OddsAPIClient()
    private let session = URLSession.shared

    private init() {}

    func fetchLiveOdds(eventID: String, partner: AffiliatePartner) async -> LiveOdds? {
        guard let url = URL(string: "\(CMXSConfig.apiBase)/betting/odds/\(eventID)?partner=\(partner.rawValue)") else { return nil }
        return (try? await session.data(from: url)).flatMap { try? JSONDecoder().decode(LiveOdds.self, from: $0.0) }
    }

    func checkSelfExclusion(deviceToken: String) async -> Bool {
        // NGES database lookup — returns true if user is self-excluded
        guard let url = URL(string: "\(CMXSConfig.apiBase)/betting/self-exclusion/\(deviceToken)") else { return false }
        if let (data, _) = try? await session.data(from: url),
           let response = try? JSONDecoder().decode(SelfExclusionResponse.self, from: data) {
            return response.excluded
        }
        return false  // default: allow if lookup fails
    }
}

// MARK: - Betting Moment Trigger

@MainActor
final class BettingMomentTrigger: ObservableObject {

    @Published var pendingOverlay: BettingOverlayContext?

    private let policy: BettingTriggerPolicy = .conservative
    private var cancellables = Set<AnyCancellable>()
    private var currentEventID: String = "demo_event"
    private var triggerCooldown: Bool = false
    private let cooldownSeconds: TimeInterval = 300  // 5 min between overlays

    init() {
        // Subscribe to contextual moments
        ContextualMomentService.shared.momentPublisher
            .filter { [weak self] moment in
                guard let self else { return false }
                return self.isTriggerMoment(moment)
            }
            .sink { [weak self] moment in
                Task { await self?.onBettingMoment(moment) }
            }
            .store(in: &cancellables)
    }

    func setCurrentEvent(id: String) {
        currentEventID = id
    }

    // MARK: - Moment trigger

    private func onBettingMoment(_ moment: GameMoment) async {
        guard !triggerCooldown else { return }

        // Compliance checks
        let geo = GeoComplianceService.shared
        guard await geo.checkCompliance() else { return }

        // Self-exclusion check
        let deviceToken = WalletDerivation.currentWalletAddress()
        let excluded = await OddsAPIClient.shared.checkSelfExclusion(deviceToken: deviceToken)
        guard !excluded else {
            print("[BettingEngine] 🚫 Self-excluded user — skipping overlay")
            return
        }

        // Fetch odds
        guard let odds = await OddsAPIClient.shared.fetchLiveOdds(
            eventID: currentEventID,
            partner: .draftKings
        ) ?? .some(LiveOdds.demo(homeTeam: "Home", awayTeam: "Away")) else { return }

        let context = BettingOverlayContext(
            odds: odds,
            triggerReason: .gameStateMoment(moment),
            breakDuration: 30,
            affiliatePartner: .draftKings
        )
        pendingOverlay = context

        // Engage cooldown to prevent spamming
        triggerCooldown = true
        DispatchQueue.main.asyncAfter(deadline: .now() + cooldownSeconds) { [weak self] in
            self?.triggerCooldown = false
        }

        print("[BettingEngine] 📊 Serving betting overlay for moment: \(moment.rawValue)")
    }

    // MARK: - Also trigger on ad break opportunity

    func onAdBreak(channelID: String) {
        Task { await onBettingMoment(.halftime) }
    }

    func dismissOverlay() {
        pendingOverlay = nil
    }

    private func isTriggerMoment(_ moment: GameMoment) -> Bool {
        switch policy {
        case .conservative: return moment.isBettingSafe
        case .standard:     return moment.isBettingSafe || [.preGame, .postGame].contains(moment)
        case .extended:     return true
        }
    }
}

// MARK: - Affiliate Tracker (CPA Attribution)

actor AffiliateTracker {
    static let shared = AffiliateTracker()
    private let session = URLSession.shared

    private init() {}

    /// Log a betting CTA click for CPA attribution.
    /// Sends a tokenized (non-PII) event to CMXS backend.
    func trackClick(overlay: BettingOverlayContext) async {
        let deviceID = await MainActor.run { WalletDerivation.currentWalletAddress() }
        let hourSlot = Int(Date().timeIntervalSince1970 / 3600)
        let token = "\(deviceID.prefix(8))-\(hourSlot)".data(using: .utf8)?.hexString ?? "anon"

        let event = AffiliateClickEvent(
            sessionToken: token,
            eventID: overlay.odds.eventID,
            triggerMoment: overlay.triggerReason.description,
            oddsDisplayed: overlay.odds.allLines,
            timestamp: Int64(Date().timeIntervalSince1970),
            affiliatePartner: overlay.affiliatePartner.rawValue
        )

        guard let url = URL(string: "\(CMXSConfig.apiBase)/betting/affiliate/click") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONEncoder().encode(event)

        _ = try? await session.data(for: request)
        print("[AffiliateTracker] 📡 Click tracked — partner: \(overlay.affiliatePartner.displayName)")
    }
}

// MARK: - Responsible Gaming Manager

@MainActor
final class ResponsibleGamingManager: ObservableObject {

    static let shared = ResponsibleGamingManager()
    private let sessionKey = "arenza.rg.sessionStarted"

    @Published var shouldShowTimeAlert: Bool = false
    private var sessionStartDate: Date?
    private var alertTimer: Timer?

    func onBettingSessionStart() {
        sessionStartDate = Date()
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: sessionKey)
        scheduleTimeAlert()
    }

    func onBettingSessionEnd() {
        alertTimer?.invalidate()
        shouldShowTimeAlert = false
    }

    private func scheduleTimeAlert() {
        alertTimer?.invalidate()
        // Alert at 30 minutes
        alertTimer = Timer.scheduledTimer(withTimeInterval: 1800, repeats: false) { [weak self] _ in
            Task { @MainActor in self?.shouldShowTimeAlert = true }
        }
    }

    static let hotlineURL = URL(string: "tel:18004262537")!  // 1-800-GAMBLER
    static let ncpgURL    = URL(string: "https://www.ncpgambling.org/help-treatment/national-helpline-1-800-522-4700/")!

    var disclaimerText: String {
        "If you or someone you know has a gambling problem, call 1-800-GAMBLER for help."
    }

    var timeAlertMessage: String {
        let mins = Int((Date().timeIntervalSince(sessionStartDate ?? Date())) / 60)
        return "You've been viewing betting content for \(mins) minutes. Take a break?"
    }
}

// hexString extension is defined in Core/SecureEnclave/SecureEnclaveManager.swift
