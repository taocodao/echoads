// PlayerViewModel.swift — Arenza Prototype
// Orchestrates: SSAI session → AVPlayer → AdBreakDetector → SGAI → PoDSubmitter

import Foundation
import AVFoundation
import Combine

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

    // MARK: - Dependencies

    private let channel: Channel
    private let env: AppEnvironment
    private let adBreakDetector = AdBreakDetector()
    private var session: PlaybackSession?
    private var podSubmitter: PoDSubmitter { env.podSubmitter }

    // MARK: - Init

    init(channel: Channel, env: AppEnvironment) {
        self.channel = channel
        self.env = env
    }

    // MARK: - Lifecycle

    func startPlayback() async {
        isLoading = true
        errorMessage = nil

        do {
            // 1. Create SSAI session → get manifest URL
            let walletAddress = WalletDerivation.currentWalletAddress()
            let response = try await env.apiClient.createSSAISession(
                channelId: channel.id,
                nodeOperator: walletAddress
            )

            guard let manifestURL = env.apiClient.manifestURL(for: response.sessionId) else {
                throw CMXSAPIError.invalidURL
            }

            let playbackSession = PlaybackSession(
                sessionId: response.sessionId,
                manifestURL: manifestURL,
                adSlots: response.adSlots,
                totalDurationSeconds: response.totalDurationSeconds,
                auctionLatencyMs: response.auctionLatencyMs
            )
            self.session = playbackSession

            sessionInfo = "Session: \(response.sessionId) · \(response.adBreaks) breaks · \(response.auctionLatencyMs)ms"

            // 2. Set up AVPlayer with SSAI manifest
            let playerItem = AVPlayerItem(url: manifestURL)
            let newPlayer = AVPlayer(playerItem: playerItem)
            self.player = newPlayer

            // 3. Attach ad break detector
            adBreakDetector.onAdBreakStarted = { [weak self] event in
                self?.handleAdBreakStart(event)
            }
            adBreakDetector.onAdBreakCompleted = { [weak self] event, latencyMs in
                Task { await self?.handleAdBreakComplete(event, latencyMs: latencyMs) }
            }
            adBreakDetector.attach(to: newPlayer, session: playbackSession)

            // 4. Start playback
            newPlayer.play()
            isLoading = false

            print("[Player] ▶️ Playing \(channel.name) via SSAI: \(manifestURL)")

            // 5. Demo mode: trigger first break after 10s if no real breaks
            if response.adSlots.isEmpty {
                scheduleDemoBreak()
            }

        } catch {
            errorMessage = "Playback failed: \(error.localizedDescription)"
            isLoading = false
            print("[Player] ❌ \(error)")
        }
    }

    func stop() {
        player?.pause()
        adBreakDetector.detach()
        player = nil
    }

    // MARK: - Ad Break Handling

    private func handleAdBreakStart(_ event: AdBreakEvent) {
        print("[Player] 🎬 Ad break \(event.slotIndex) started — \(event.adSlot.advertiser)")
        isInAdBreak = true
        currentBreakEvent = event

        // Show SGAI shoppable overlay at T+20s
        let overlayDelay = max(0, event.duration - 10)
        DispatchQueue.main.asyncAfter(deadline: .now() + overlayDelay) { [weak self] in
            guard let self, self.isInAdBreak else { return }
            self.sgaiOverlay = SGAIOverlayData.demo(
                for: event.adSlot.advertiser,
                impressionId: event.adSlot.impressionId
            )
        }
    }

    private func handleAdBreakComplete(_ event: AdBreakEvent, latencyMs: Double) async {
        print("[Player] ✅ Ad break \(event.slotIndex) complete — signing PoD...")
        isInAdBreak = false
        switchLatencyMs = latencyMs
        sgaiOverlay = nil

        // Sign and submit PoD receipt
        let record = await podSubmitter.submit(
            impressionId: event.adSlot.impressionId,
            channelId: channel.id,
            cpm: event.adSlot.cpm,
            advertiser: event.adSlot.advertiser,
            switchLatencyMs: latencyMs
        )

        if let record = record {
            env.recordPoD(record)
            // Show verification toast
            podToast = PoDToastData(
                cmxsEarned: record.cmxsEarned,
                txHash: record.txHash,
                latencyMs: latencyMs,
                isHardwareSigned: env.seManager.isUsingSecureEnclave
            )
            // Auto-hide toast after 4s
            DispatchQueue.main.asyncAfter(deadline: .now() + 4) { [weak self] in
                withAnimation { self?.podToast = nil }
            }
        }
    }

    // MARK: - Demo Break (fallback when no SSAI ad slots)

    private func scheduleDemoBreak() {
        let demoSlot = AdSlotInfo(
            impressionId: "0x\(UUID().uuidString.replacingOccurrences(of: "-", with: "").lowercased().prefix(64))",
            advertiser: "Callaway Golf",
            cpm: 47.5,
            dspName: "SimDSP-Demo"
        )

        DispatchQueue.main.asyncAfter(deadline: .now() + 12) { [weak self] in
            guard let self else { return }
            self.adBreakDetector.triggerDemoBreak(adSlot: demoSlot)
        }
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
