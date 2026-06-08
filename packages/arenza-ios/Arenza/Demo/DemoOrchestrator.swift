// DemoOrchestrator.swift — Arenza (Scripted Demo Timeline)
// Drives the full ad-tech flywheel demo in a timed ~90-second sequence.
// Designed for hands-free partner/investor demos — no manual tapping required.
//
// DEMO NARRATIVE:
//   "Here is a live sports stream → we profile the viewer on-device →
//    we insert a targeted ad → the viewer earns AZT tokens → they make
//    predictions and place sports bets → they spend tokens in the marketplace →
//    we generate $45-65 CPM tracked revenue."

import Foundation
import SwiftUI
import Combine

// MARK: - Demo Step

enum DemoStep: String, CaseIterable {
    case idle               = "Idle"
    case contentPlaying     = "Content Playing"
    case profilingVisible   = "Viewer Profiling"
    case adBreakIncoming    = "Ad Break Incoming"
    case adPodActive        = "Ad Pod Playing"
    case adComplete         = "Ad Complete — AZT Earned"
    case predictionActive   = "Prediction Overlay"
    case bettingActive      = "Betting Overlay"
    case marketplaceOpen    = "Marketplace Open"
    case demoComplete       = "Demo Complete"
}

// MARK: - Demo Orchestrator

@MainActor
final class DemoOrchestrator: ObservableObject {

    static let shared = DemoOrchestrator()

    @Published var currentStep: DemoStep = .idle
    @Published var isRunning: Bool = false
    @Published var showProfilingCard: Bool = false
    @Published var showAdIncomingBadge: Bool = false
    @Published var showDemoSummary: Bool = false
    @Published var totalAZTEarned: Int = 0
    @Published var revenueGenerated: Double = 0.0
    @Published var stepNarration: String = ""
    @Published var elapsedSeconds: Int = 0

    // References set by PlayerView on init
    weak var playerViewModel: PlayerViewModel?

    private var demoTask: Task<Void, Never>?
    private var elapsedTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    private let predEngine = PredictionEngine.shared
    private let profileEngine = ProfileEngine.shared

    private init() {}

    // MARK: - Start Demo

    func start(for vm: PlayerViewModel) {
        guard !isRunning else { return }
        self.playerViewModel = vm
        isRunning = true
        elapsedSeconds = 0
        totalAZTEarned = 0
        revenueGenerated = 0
        showDemoSummary = false

        startElapsedTimer()

        demoTask = Task { [weak self] in
            guard let self else { return }
            await self.runDemoSequence()
        }

        print("[DemoOrchestrator] 🎬 Demo started")
    }

    func stop() {
        demoTask?.cancel()
        demoTask = nil
        elapsedTimer?.invalidate()
        elapsedTimer = nil
        isRunning = false
        reset()
    }

    // MARK: - Demo Sequence (T+0s → T+90s)

    private func runDemoSequence() async {

        // ── T+0s: Content playing ──────────────────────────────────────────
        await step(.contentPlaying,
                   narration: "Sports content is live. Viewer profiling begins on-device — no PII leaves the phone.")
        await sleep(5)

        // ── T+5s: Show profiling card ──────────────────────────────────────
        await step(.profilingVisible,
                   narration: "Viewer classified as '\(profileEngine.currentSegment.label)'. Sport affinities computed.")
        showProfilingCard = true
        await sleep(6)

        // ── T+11s: Hide profiling, show incoming ad badge ──────────────────
        showProfilingCard = false
        await sleep(1)

        await step(.adBreakIncoming,
                   narration: "EABN signal sent — DSP auction begins 8 seconds before ad break.")
        showAdIncomingBadge = true
        await sleep(4)
        showAdIncomingBadge = false

        // ── T+16s: Fire ad pod ─────────────────────────────────────────────
        await step(.adPodActive,
                   narration: "DraftKings won at $62.00 CPM — targeted to '\(profileEngine.currentSegment.label)' segment.")
        revenueGenerated += 0.062   // per-impression revenue
        playerViewModel?.triggerDemoAdPodFromOrchestrator()
        await sleep(16)             // 15s pod + 1s buffer

        // ── T+32s: Ad complete, AZT awarded ───────────────────────────────
        await step(.adComplete,
                   narration: "PoD signed by Secure Enclave. +15 AZT awarded for watching the ad.")
        totalAZTEarned += 15
        await sleep(5)

        // ── T+37s: Prediction overlay ──────────────────────────────────────
        await step(.predictionActive,
                   narration: "Game break — prediction overlay fires. Viewer engages with 'Who scores next?'")
        triggerDemoPrediction()
        await sleep(18)             // 30s window — auto-resolves after 12s

        // ── T+55s: Betting overlay ─────────────────────────────────────────
        await step(.bettingActive,
                   narration: "Live betting odds update. DraftKings integration: Patriots -3.5 in-play.")
        triggerDemoBetting()
        await sleep(12)

        // ── T+67s: Marketplace tab ─────────────────────────────────────────
        await step(.marketplaceOpen,
                   narration: "Viewer redeems AZT tokens in the sponsor marketplace — Near Me offers ranked by DMA.")
        await sleep(3)
        NotificationCenter.default.post(name: .demoOpenMarketplace, object: nil)
        await sleep(10)

        // ── T+80s: Demo complete ───────────────────────────────────────────
        await step(.demoComplete,
                   narration: "Demo complete. \(totalAZTEarned) AZT earned. $\(String(format: "%.3f", revenueGenerated)) revenue attributed.")
        showDemoSummary = true
    }

    // MARK: - Trigger Helpers

    private func triggerDemoPrediction() {
        let question = PredictionAPIClient.demoQuestion(channelID: "cmxs-nfl-live")
        predEngine.activePrediction = question
        // Auto-resolve after 12s for demo continuity
        Task {
            try? await Task.sleep(nanoseconds: 12_000_000_000)
            await MainActor.run {
                if self.predEngine.activePrediction != nil {
                    let resolution = PredictionAPIClient.demoResolution(questionID: question.id)
                    if resolution.isCorrect {
                        self.totalAZTEarned += 100
                    }
                    self.predEngine.resolveForDemo(resolution: resolution)
                }
            }
        }
    }

    private func triggerDemoBetting() {
        let context = BettingOverlayContext.demo(channelID: "cmxs-nfl-live")
        playerViewModel?.bettingOverlay = context
        // Auto-dismiss after 10s
        Task {
            try? await Task.sleep(nanoseconds: 10_000_000_000)
            await MainActor.run { self.playerViewModel?.bettingOverlay = nil }
        }
    }

    // MARK: - Step + Narration

    private func step(_ step: DemoStep, narration: String) async {
        currentStep = step
        stepNarration = narration
        print("[Demo] T+\(elapsedSeconds)s [\(step.rawValue)]: \(narration)")
    }

    // MARK: - Helpers

    private func sleep(_ seconds: TimeInterval) async {
        try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
    }

    private func startElapsedTimer() {
        elapsedTimer?.invalidate()
        elapsedTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.elapsedSeconds += 1
        }
        RunLoop.main.add(elapsedTimer!, forMode: .common)
    }

    private func reset() {
        currentStep = .idle
        showProfilingCard = false
        showAdIncomingBadge = false
        stepNarration = ""
    }
}

// MARK: - Notification names

extension Notification.Name {
    static let demoOpenMarketplace = Notification.Name("arenza.demo.openMarketplace")
}
