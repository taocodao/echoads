// PlayerViewModel.swift — Arenza
// Orchestrates: HLS Direct → AVPlayer → AdPodInserter → PoDSubmitter
// SSAI session is attempted as an async enrichment when the backend is reachable.
// Engines: ProfileEngine → BidAssembler → PredictionEngine → BettingEngine

import Foundation
import AVFoundation
import Combine
import SwiftUI

@MainActor
final class PlayerViewModel: ObservableObject {

    // MARK: - Published State

    @Published var player: AVPlayer?
    @Published var isLoading = true
    @Published var errorMessage: String?
    @Published var currentBreakEvent: AdBreakEvent?
    @Published var sgaiOverlay: SGAIOverlayData?
    @Published var podToast: PoDToastData?
    @Published var sessionInfo: String = ""
    @Published var switchLatencyMs: Double = 0
    @Published var isInAdBreak = false

    // Phase 2 — Prediction overlay
    @Published var activePredictionQuestion: PredictionQuestion?
    @Published var couponUnlock: SponsorCoupon?

    // Phase 3 — Betting overlay
    @Published var bettingOverlay: BettingOverlayContext?

    // MARK: - Dependencies

    private let channel: Channel
    var channelName: String { channel.name }
    private let env: AppEnvironment

    private let adBreakDetector = AdBreakDetector()
    let adPodInserter = AdPodInserter()   // internal: PlayerView reads activeCreative
    private var session: PlaybackSession?
    private var podSubmitter: PoDSubmitter { env.podSubmitter }

    // Engine integrations
    private let predictionEngine = PredictionEngine.shared
    private let bettingTrigger = BettingMomentTrigger()
    private let signalCollector = SignalCollector.shared
    private let anomalyDetector = AnomalyDetector.shared
    private var cancellables = Set<AnyCancellable>()

    // Demo break timer (fires first pod 20s after playback begins)
    private var firstPodTimer: Timer?

    // MARK: - Init

    init(channel: Channel, env: AppEnvironment) {
        self.channel = channel
        self.env = env

        // ── Phase 4: Set AVAudioSession BEFORE creating AVPlayer ─────────
        // .playback category: audio plays through silent switch + survives
        // interruptions (phone calls, Siri). Without this it defaults to
        // .soloAmbient which mutes on the ring/silent switch.
        // ──────────────────────────────────────────────────────────────────
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("[Audio] Failed to set audio session: \(error)")
        }

        // ── CRITICAL: Create AVPlayer SYNCHRONOUSLY in init ──────────────
        // The player must exist BEFORE the sheet finishes presenting.
        // Creating it async inside .task causes the render surface to never
        // attach on real iPhones (works in Simulator due to different
        // GPU/compositor timing).
        // ──────────────────────────────────────────────────────────────────
        if let streamURL = channel.streamURL {
            let playerItem = AVPlayerItem(url: streamURL)
            let newPlayer = AVPlayer(playerItem: playerItem)
            newPlayer.automaticallyWaitsToMinimizeStalling = true
            self.player = newPlayer
            self.adPodInserter.attach(to: newPlayer)
            self.observePlayerItemStatus(playerItem)
            self.observePlaybackEnd(for: newPlayer)
            print("[Player] AVPlayer created for \(channel.name): \(streamURL)")
        }

        subscribeToPredictionAndBetting()
        wireAdPodInserter()
    }

    // MARK: - Lifecycle

    /// Called from .task — player already exists, this starts ancillary services.
    /// NOTE: player.play() is called by PlayerHostViewController.viewDidAppear()
    /// to guarantee the AVPlayerLayer is fully attached to the window first.
    func startPlayback() async {
        guard player != nil else {
            errorMessage = "No stream available for this channel."
            isLoading = false
            return
        }

        // Connect contextual moments (MoQ relay via WebSocket)
        ContextualMomentService.shared.connect(channelID: channel.id)
        bettingTrigger.setCurrentEvent(id: channel.id)
        anomalyDetector.onSessionStart()

        sessionInfo = "Direct HLS — \(channel.name)"

        // Signal AI engine
        signalCollector.record(ContentEvent(
            type: .playbackStarted,
            channelID: channel.id,
            sportType: channel.sport,
            isLive: channel.isLive,
            timestamp: Date(),
            sessionID: "direct-\(channel.id)"
        ))

        // Schedule first demo ad pod (20s into content) — subsequent ones auto-fire
        scheduleFirstDemoPod()

        // Background: try SSAI enrichment (non-blocking, won't affect playback)
        Task(priority: .background) { await trySSAIEnrichment() }
    }


    func stop() {
        firstPodTimer?.invalidate()
        firstPodTimer = nil
        adPodInserter.cancelPod()
        player?.pause()
        adBreakDetector.detach()
        ContextualMomentService.shared.disconnect()
        player = nil
        predictionEngine.saveWallet()
    }

    // MARK: - SSAI Enrichment (background, optional)

    private func trySSAIEnrichment() async {
        guard env.isBackendReachable else { return }

        do {
            let walletAddress = WalletDerivation.currentWalletAddress()
            let response = try await env.apiClient.createSSAISession(
                channelId: channel.id,
                nodeOperator: walletAddress
            )

            // If we got ad slots, attach the detector for future breaks
            if !response.adSlots.isEmpty, let player {
                guard let manifestURL = env.apiClient.manifestURL(for: response.sessionId) else { return }
                let playbackSession = PlaybackSession(
                    sessionId: response.sessionId,
                    manifestURL: manifestURL,
                    adSlots: response.adSlots,
                    totalDurationSeconds: response.totalDurationSeconds,
                    auctionLatencyMs: response.auctionLatencyMs
                )
                self.session = playbackSession
                adBreakDetector.onAdBreakStarted = { [weak self] event in
                    self?.handleAdBreakStart(event)
                }
                adBreakDetector.onAdBreakCompleted = { [weak self] event, latencyMs in
                    Task { await self?.handleAdBreakComplete(event, latencyMs: latencyMs) }
                }
                adBreakDetector.attach(to: player, session: playbackSession)
                sessionInfo = "SSAI enriched — \(response.adBreaks) breaks"
                print("[Player] SSAI enrichment attached — \(response.adBreaks) ad breaks")
            }
        } catch {
            // Silent — direct HLS is already playing fine
            print("[Player] SSAI enrichment unavailable (expected on device): \(error.localizedDescription)")
        }
    }

    // MARK: - Player Item Status Observation

    private var itemStatusObserver: AnyCancellable?

    private func observePlayerItemStatus(_ item: AVPlayerItem) {
        // Use Combine publisher on AVPlayerItem.status
        itemStatusObserver = item.publisher(for: \.status)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                guard let self else { return }
                switch status {
                case .readyToPlay:
                    // Video buffer ready — hide the loading spinner
                    self.isLoading = false
                    print("[Player] ✅ Item ready to play")
                case .failed:
                    self.isLoading = false
                    let err = item.error?.localizedDescription ?? "Unknown playback error"
                    self.errorMessage = err
                    print("[Player] ❌ Item failed: \(err)")
                case .unknown:
                    // Still loading — keep spinner visible
                    self.isLoading = true
                @unknown default:
                    break
                }
            }
    }

    // MARK: - Playback End → Loop

    private var endObserver: Any?
    private var interruptionObserver: Any?

    private func observePlaybackEnd(for player: AVPlayer) {
        // Loop observer — seek to zero and resume
        endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player.currentItem,
            queue: .main
        ) { [weak player] _ in
            player?.seek(to: .zero, toleranceBefore: .zero, toleranceAfter: .zero) { _ in
                player?.play()
            }
        }

        // Phase 4 Fix B — resume audio after interruption (phone call, Siri, etc.)
        interruptionObserver = NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance(),
            queue: .main
        ) { [weak self, weak player] notification in
            guard let info = notification.userInfo,
                  let typeValue = info[AVAudioSessionInterruptionTypeKey] as? UInt,
                  let type = AVAudioSession.InterruptionType(rawValue: typeValue) else { return }
            switch type {
            case .ended:
                // Re-activate session and resume playback
                try? AVAudioSession.sharedInstance().setActive(true)
                player?.play()
                print("[Audio] Interruption ended — resumed playback")
            case .began:
                print("[Audio] Interruption began")
            @unknown default:
                break
            }
        }
    }

    // MARK: - Demo Pod Scheduling

    /// Fires the first ad pod 20s after content starts, then every 90s.
    private func scheduleFirstDemoPod() {
        firstPodTimer = Timer.scheduledTimer(withTimeInterval: 20.0, repeats: false) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor [weak self] in
                self?.triggerDemoAdPod()
            }
        }
        RunLoop.main.add(firstPodTimer!, forMode: .common)
    }

    /// Called by DemoOrchestrator to fire a scripted ad pod at the right step.
    func triggerDemoAdPodFromOrchestrator() {
        triggerDemoAdPod()
    }

    private func triggerDemoAdPod() {
        guard !isInAdBreak, !adPodInserter.isInAdPod else { return }

        // Rotate through advertisers for demo variety
        let advertisers = ["DraftKings", "Nike", "Domino's"]
        let advertiser = advertisers.randomElement()!
        let cpm: Double = advertiser == "DraftKings" ? 62.0 : advertiser == "Nike" ? 48.5 : 41.75
        let slot = AdSlotInfo(
            impressionId: "0x" + UUID().uuidString.replacingOccurrences(of: "-", with: "").lowercased().prefix(40),
            advertiser: advertiser,
            cpm: cpm,
            dspName: "SimDSP-Demo"
        )

        print("[Player] Triggering demo ad pod — \(slot.advertiser)")
        handleAdBreakStart(AdBreakEvent(slotIndex: 0, adSlot: slot, startTime: 0, duration: 30))
        adPodInserter.insertPod(for: slot, channelID: channel.id)

        // Schedule next pod in 90s
        Timer.scheduledTimer(withTimeInterval: 90.0, repeats: false) { [weak self] _ in
            Task { @MainActor [weak self] in self?.triggerDemoAdPod() }
        }
    }

    // MARK: - Ad Pod Inserter Wiring

    private func wireAdPodInserter() {
        adPodInserter.onAdPodCompleted = { [weak self] slot, latencyMs in
            Task { @MainActor in
                // Award 15 AZT for watching the ad pod
                PredictionEngine.shared.wallet.earn(15, source: .adView, sponsorId: slot.advertiser)
                PredictionEngine.shared.saveWallet()
                print("[AZT] +15 AZT for ad view — \(slot.advertiser)")

                await self?.handleAdBreakComplete(
                    AdBreakEvent(slotIndex: 0, adSlot: slot, startTime: 0, duration: 30),
                    latencyMs: latencyMs
                )
            }
        }
        // Mirror AdPodInserter state into PlayerViewModel published state
        adPodInserter.$isInAdPod
            .receive(on: DispatchQueue.main)
            .sink { [weak self] inPod in self?.isInAdBreak = inPod }
            .store(in: &cancellables)
    }

    // MARK: - Ad Break Handling (shared by SSAI + CSAI)

    private func handleAdBreakStart(_ event: AdBreakEvent) {
        print("[Player] Ad break \(event.slotIndex) started — \(event.adSlot.advertiser)")
        isInAdBreak = true
        currentBreakEvent = event

        // Anomaly + signal collection
        anomalyDetector.onPlaybackEvent()
        signalCollector.record(AdEvent(
            type: .adBreakStarted,
            creativeID: event.adSlot.impressionId,
            advertiserID: event.adSlot.advertiser,
            completionPercent: 0,
            timestamp: Date(),
            sessionID: session?.sessionId ?? "direct"
        ))

        // Betting overlay opportunity
        bettingTrigger.onAdBreak(channelID: channel.id)

        // EABN for next break
        Task {
            await EABNService.shared.notifyUpcomingBreak(
                channelID: channel.id,
                expectedBreakOffset: 90,
                breakDurationSec: 30
            )
        }

        // SGAI shoppable overlay at T+20s (10s before break ends)
        let overlayDelay = max(5, event.duration - 10)
        DispatchQueue.main.asyncAfter(deadline: .now() + overlayDelay) { [weak self] in
            guard let self, self.isInAdBreak else { return }
            self.sgaiOverlay = SGAIOverlayData.demo(
                for: event.adSlot.advertiser,
                impressionId: event.adSlot.impressionId
            )
        }
    }

    private func handleAdBreakComplete(_ event: AdBreakEvent, latencyMs: Double) async {
        print("[Player] Ad break \(event.slotIndex) complete — signing PoD...")
        isInAdBreak = false
        switchLatencyMs = latencyMs
        sgaiOverlay = nil
        currentBreakEvent = nil

        // Signal collection
        anomalyDetector.onAdCompleted(completionPercent: 1.0)
        signalCollector.record(AdEvent(
            type: .adCompleted,
            creativeID: event.adSlot.impressionId,
            advertiserID: event.adSlot.advertiser,
            completionPercent: 1.0,
            timestamp: Date(),
            sessionID: session?.sessionId ?? "direct"
        ))
        AdaptiveFrequencyController.shared.recordImpression(
            creativeID: event.adSlot.impressionId,
            advertiserID: event.adSlot.advertiser,
            completionPercent: 1.0,
            wasEngaged: sgaiOverlay != nil,
            wasSkipped: false
        )

        // Sign and submit PoD receipt
        let record = await podSubmitter.submit(
            impressionId: event.adSlot.impressionId,
            channelId: channel.id,
            cpm: event.adSlot.cpm,
            advertiser: event.adSlot.advertiser,
            switchLatencyMs: latencyMs
        )

        if let record {
            env.recordPoD(record)
            podToast = PoDToastData(
                cmxsEarned: record.cmxsEarned,
                txHash: record.txHash,
                latencyMs: latencyMs,
                isHardwareSigned: env.seManager.isUsingSecureEnclave
            )
            DispatchQueue.main.asyncAfter(deadline: .now() + 4) { [weak self] in
                Task { @MainActor [weak self] in
                    withAnimation { self?.podToast = nil }
                }
            }
        }
    }

    // MARK: - Engine Subscriptions

    private func subscribeToPredictionAndBetting() {
        predictionEngine.$activePrediction
            .receive(on: DispatchQueue.main)
            .sink { [weak self] q in self?.activePredictionQuestion = q }
            .store(in: &cancellables)

        predictionEngine.couponUnlockPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] coupon in
                self?.couponUnlock = coupon
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) { self?.couponUnlock = nil }
            }
            .store(in: &cancellables)

        bettingTrigger.$pendingOverlay
            .receive(on: DispatchQueue.main)
            .sink { [weak self] ctx in self?.bettingOverlay = ctx }
            .store(in: &cancellables)
    }
}

// MARK: - PoD Toast Data

struct PoDToastData {
    let cmxsEarned: Double
    let txHash: String?
    let latencyMs: Double
    let isHardwareSigned: Bool

    var basescanURL: URL? {
        guard let hash = txHash else { return nil }
        return URL(string: "https://sepolia.basescan.org/tx/\(hash)")
    }
}
