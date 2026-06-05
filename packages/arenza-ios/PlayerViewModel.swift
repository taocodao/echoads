// PlayerViewModel.swift
// Orchestrates: MoQ stream resolution → AVPlayer → SCTE-35 detection →
//               SGAI overlay scheduling → Secure Enclave PoD signing.

import Foundation
import AVFoundation
import Combine

@MainActor
final class PlayerViewModel: ObservableObject {

    // ── Published state ──────────────────────────────────────────────────────
    @Published var player: AVPlayer?
    @Published var latencyMs: Int?
    @Published var adBreakActive  = false
    @Published var adProgress: Double = 0
    @Published var showSGAIOverlay = false
    @Published var currentOverlay: SGAIOverlay?
    @Published var showPoDReceipt  = false
    @Published var lastPoD: PoDReceipt?
    @Published var errorMessage: String?

    // ── Private ──────────────────────────────────────────────────────────────
    private let channelId: String
    private var adBreakTimer: Timer?
    private var overlayTimer: Timer?
    private var scte35Detector: SCTE35Detector?
    private var adStartTime: Date?
    private var currentImpressionId: String?

    // Demo break triggers so the demo works even without live SCTE-35 cues
    private var demoBreakTimer: Timer?

    init(channelId: String) {
        self.channelId = channelId
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: – Playback
    // ─────────────────────────────────────────────────────────────────────────

    func startPlayback() async {
        // 1. Try MoQ stream (Caton public relay)
        //    For demo: we fall back to a public HLS stream since C3CVP SDK
        //    requires a real Caton API key for production. When your key is ready,
        //    replace the fallback URL with: C3CVPSession(relayURL: moqURL).resolveStreamURL()
        let moqURL = URL(string: Constants.moqStreamURL)!
        let fallbackHLS = URL(string: "https://devstreaming-cdn.apple.com/videos/streaming/examples/img_bipbop_adv_example_fmp4/master.m3u8")!

        let streamURL = await resolveMoQStream(moqURL: moqURL, fallback: fallbackHLS)

        // 2. Build AVPlayerItem + attach SCTE-35 detector
        let item = AVPlayerItem(url: streamURL)
        let detector = SCTE35Detector()
        detector.delegate = self
        let metaOutput = AVPlayerItemMetadataOutput(identifiers: nil)
        metaOutput.setDelegate(detector, queue: .main)
        item.add(metaOutput)
        self.scte35Detector = detector

        // 3. Start player
        let avPlayer = AVPlayer(playerItem: item)
        self.player = avPlayer
        avPlayer.play()

        // 4. Simulate latency reading (would come from Caton SDK telemetry)
        simulateLatencyReadings()

        // 5. Demo: auto-trigger a synthetic ad break every 45 s
        scheduleDemoAdBreaks()
    }

    private func resolveMoQStream(moqURL: URL, fallback: URL) async -> URL {
        // ── Production path (requires C3CVP SDK + Caton API key) ─────────────
        // do {
        //     let session = try await C3CVPSession(relayURL: moqURL)
        //     return try await session.resolveStreamURL()
        // } catch {
        //     print("[MoQ] Failed, falling back to HLS: \(error)")
        // }

        // ── Demo path ────────────────────────────────────────────────────────
        // For demonstration we play a reliable HLS stream. When the Caton API
        // key is available, uncomment the block above.
        print("[MoQ] Using demo HLS stream (swap to C3CVP SDK with API key)")
        return fallback
    }

    private func simulateLatencyReadings() {
        Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                // Simulate MoQ's sub-300ms p95 latency
                self?.latencyMs = Int.random(in: 211...298)
            }
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: – Ad Break Handling
    // ─────────────────────────────────────────────────────────────────────────

    // Called by SCTE35Detector when a splice insert is detected
    func handleAdBreak(duration: Double, cueId: String) {
        print("[SCTE-35] Ad Break Detected: \(duration) seconds  cueId=\(cueId)")

        let impressionId = UUID().uuidString
        currentImpressionId = impressionId
        adStartTime = Date()
        adBreakActive = true
        adProgress = 0

        // Schedule SGAI overlay at T+20s
        overlayTimer = Timer.scheduledTimer(withTimeInterval: 20, repeats: false) { [weak self] _ in
            DispatchQueue.main.async {
                self?.showOverlay(impressionId: impressionId)
            }
        }

        // Run ad progress bar
        adBreakTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] timer in
            guard let self = self, let start = self.adStartTime else { return }
            let elapsed = Date().timeIntervalSince(start)
            DispatchQueue.main.async {
                self.adProgress = min(elapsed / duration, 1.0)
                if self.adProgress >= 1.0 {
                    timer.invalidate()
                    Task { await self.handleAdComplete(impressionId: impressionId) }
                }
            }
        }
    }

    private func showOverlay(impressionId: String) {
        // Demo overlay content – in production this comes from the ad response SGAI payload
        currentOverlay = SGAIOverlay(
            id: impressionId,
            productName: "Callaway Paradym Driver",
            priceFormatted: "$549",
            emoji: "⛳",
            impressionId: impressionId
        )
        withAnimation { showSGAIOverlay = true }
    }

    func dismissOverlay() {
        withAnimation { showSGAIOverlay = false }
    }

    private func handleAdComplete(impressionId: String) async {
        adBreakActive = false
        adProgress = 0
        overlayTimer?.invalidate()
        withAnimation { showSGAIOverlay = false }

        // Sign & submit PoD receipt via Secure Enclave
        do {
            let receipt = try await OracleSubmitter.shared.submitPoD(
                impressionId: impressionId,
                cpm: 47.50,
                channelId: channelId
            )
            withAnimation {
                lastPoD = receipt
                showPoDReceipt = true
            }
            // Auto-dismiss toast after 6s
            DispatchQueue.main.asyncAfter(deadline: .now() + 6) {
                withAnimation { self.showPoDReceipt = false }
            }
        } catch {
            print("[PoD] Error submitting receipt: \(error)")
        }
    }

    // ── Demo: synthetic SCTE-35 break every 45 s ─────────────────────────────
    private func scheduleDemoAdBreaks() {
        demoBreakTimer = Timer.scheduledTimer(withTimeInterval: 45, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                self?.handleAdBreak(duration: 30, cueId: "demo-scte35-\(UUID().uuidString.prefix(8))")
            }
        }
        // Fire first break after 10s so demo is immediately impressive
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) { [weak self] in
            self?.handleAdBreak(duration: 30, cueId: "demo-initial-break")
        }
    }
}

// ── SCTE35Detector delegate conformance ──────────────────────────────────────
extension PlayerViewModel: SCTE35DetectorDelegate {
    func scte35Detected(duration: Double, cueId: String) {
        handleAdBreak(duration: duration, cueId: cueId)
    }
}
