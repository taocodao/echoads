// AdPodInserter.swift — Arenza
// Client-Side Ad Insertion (CSAI) engine.
//
// HOW IT WORKS:
//   1. When a pod break fires, we save the current content AVPlayerItem.
//   2. We swap in an ad AVPlayerItem and play it.
//   3. After the ad finishes (or duration elapses), we restore the content item.
//   4. The onCompleted callback carries the AdBreakEvent back to PlayerViewModel
//      so PoD signing and CMXS reward accounting can happen.
//
// AD CREATIVES used here are placeholder HLS streams.
// Replace with actual ad inventory from BidRequestAssembler when DSP is live.

import Foundation
import AVFoundation
import Combine

// MARK: - Ad Creative Registry

enum AdCreativeRegistry {
    // Pre-loaded ad creatives as HLS streams.
    // In production these come from BidRequestAssembler / DSP win notice.
    struct Creative {
        let advertiser: String
        let cpm: Double
        let hlsURL: URL
        let durationSeconds: Double
        let impressionPixelURL: URL?
    }

    static let library: [Creative] = [
        Creative(
            advertiser: "Callaway Golf",
            cpm: 48.50,
            hlsURL: URL(string: "https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8")!,
            durationSeconds: 30,
            impressionPixelURL: nil
        ),
        Creative(
            advertiser: "DraftKings",
            cpm: 62.00,
            hlsURL: URL(string: "https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_16x9/bipbop_16x9_variant.m3u8")!,
            durationSeconds: 30,
            impressionPixelURL: nil
        ),
        Creative(
            advertiser: "Fanatics",
            cpm: 41.75,
            hlsURL: URL(string: "https://bitdash-a.akamaihd.net/content/sintel/hls/playlist.m3u8")!,
            durationSeconds: 15,
            impressionPixelURL: nil
        )
    ]

    static func pick(for advertiser: String?) -> Creative {
        if let advertiser,
           let match = library.first(where: { $0.advertiser == advertiser }) {
            return match
        }
        return library.randomElement() ?? library[0]
    }
}

// MARK: - Ad Pod Inserter

@MainActor
final class AdPodInserter: ObservableObject {

    // Reports current ad state to the UI
    @Published var isInAdPod: Bool = false
    @Published var currentAdvertiser: String = ""
    @Published var podProgress: Double = 0      // 0.0 → 1.0
    @Published var podDurationRemaining: Double = 0

    // Called when an ad pod finishes — carries slot info and measured latency
    var onAdPodCompleted: ((AdSlotInfo, Double) -> Void)?

    private var player: AVPlayer?
    private var savedContentItem: AVPlayerItem?
    private var progressTimer: Timer?
    private var podStartTime: Date?
    private var currentPodDuration: Double = 30
    private var endObserver: NSObjectProtocol?
    private var currentAdItem: AVPlayerItem?

    // MARK: - Attach

    func attach(to player: AVPlayer) {
        self.player = player
    }

    // MARK: - Insert Ad Pod

    /// Swap the current content out, play an ad, then restore.
    /// `slot` is the AdSlotInfo from the winning bid / demo break.
    func insertPod(for slot: AdSlotInfo, channelID: String) {
        guard let player, !isInAdPod else { return }

        let creative = AdCreativeRegistry.pick(for: slot.advertiser)
        let adItem = AVPlayerItem(url: creative.hlsURL)

        // Save content
        savedContentItem = player.currentItem

        // Mark start
        podStartTime = Date()
        currentPodDuration = creative.durationSeconds
        currentAdvertiser = creative.advertiser
        isInAdPod = true
        podProgress = 0
        podDurationRemaining = creative.durationSeconds

        // Swap to ad
        currentAdItem = adItem
        player.replaceCurrentItem(with: adItem)
        player.seek(to: .zero)
        player.play()

        // Fire impression pixel if present
        if let pixel = creative.impressionPixelURL {
            Task { _ = try? await URLSession.shared.data(from: pixel) }
        }

        print("[AdPod] Pod started — \(creative.advertiser) — $\(String(format: "%.2f", creative.cpm)) CPM")

        // Start progress ticker (updates every 0.5s)
        startProgressTimer(duration: creative.durationSeconds, slot: slot)
    }

    // MARK: - Progress timer

    private func startProgressTimer(duration: Double, slot: AdSlotInfo) {
        progressTimer?.invalidate()

        let startDate = Date()
        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] timer in
            guard let self else { timer.invalidate(); return }
            Task { @MainActor [weak self] in
                guard let self, self.isInAdPod else { timer.invalidate(); return }
                let elapsed = Date().timeIntervalSince(startDate)
                self.podProgress = min(elapsed / duration, 1.0)
                self.podDurationRemaining = max(duration - elapsed, 0)

                if elapsed >= duration {
                    timer.invalidate()
                    self.finishPod(slot: slot)
                }
            }
        }
        RunLoop.main.add(progressTimer!, forMode: .common)
    }

    // MARK: - Finish Pod + Restore Content

    private func finishPod(slot: AdSlotInfo) {
        guard isInAdPod, let player else { return }

        let latencyMs = Date().timeIntervalSince(podStartTime ?? Date()) * 1000
        progressTimer?.invalidate()
        progressTimer = nil

        // Remove end-of-item observer
        if let obs = endObserver {
            NotificationCenter.default.removeObserver(obs)
            endObserver = nil
        }

        // Restore content
        if let contentItem = savedContentItem {
            player.replaceCurrentItem(with: contentItem)
            player.play()
        }

        isInAdPod = false
        podProgress = 0
        podDurationRemaining = 0
        currentAdItem = nil
        savedContentItem = nil

        print("[AdPod] Pod complete — latency \(Int(latencyMs))ms")
        onAdPodCompleted?(slot, latencyMs)
    }

    // MARK: - Early dismiss (user skips, error, etc)

    func cancelPod() {
        guard isInAdPod else { return }
        progressTimer?.invalidate()
        progressTimer = nil
        isInAdPod = false
        if let obs = endObserver {
            NotificationCenter.default.removeObserver(obs)
            endObserver = nil
        }
        if let contentItem = savedContentItem, let player {
            player.replaceCurrentItem(with: contentItem)
            player.play()
        }
    }
}
