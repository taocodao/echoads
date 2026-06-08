// AdPodInserter.swift — Arenza
// Client-Side Ad Insertion (CSAI) engine.
//
// HOW IT WORKS (DEMO MODE):
//   For demo clarity, ad pods are rendered as a full-screen SwiftUI overlay
//   card (DemoAdCard) rather than swapping the AVPlayer item. This ensures:
//     • No black-screen stale-buffer bug
//     • Content keeps playing underneath (audio muted during pod)
//     • Ad creative is visually 100% distinct from content
//   In production, swap DemoAdCard for a true CSAI/SSAI creative URL.
//
// PRODUCTION MODE (future):
//   insertPodProduction() does the real AVPlayer item-swap.
//   The content URL (not AVPlayerItem) is saved so restoration always
//   creates a fresh item — eliminating the stale-buffer black frame.

import Foundation
import AVFoundation
import Combine

// MARK: - Ad Creative Registry

enum AdCreativeRegistry {
    struct Creative {
        let advertiser: String
        let sponsorCategory: String     // used by ProfileEngine for targeting
        let cpm: Double
        let tagline: String             // shown on the DemoAdCard
        let ctaText: String             // call-to-action button label
        let brandColorHex: String       // dominant brand color for card theming
        let targetSegments: [String]    // e.g. ["SEG-03: Sports Bettor"]
        let hlsURL: URL                 // fallback for production mode
        let durationSeconds: Double
    }

    static let library: [Creative] = [
        Creative(
            advertiser: "DraftKings",
            sponsorCategory: "Sports Betting",
            cpm: 62.00,
            tagline: "Bet $5, Get $200 in Bonus Bets",
            ctaText: "Claim Offer →",
            brandColorHex: "#1B5E20",
            targetSegments: ["SEG-03: Sports Bettor", "SEG-01: Premium Sports Fanatic"],
            hlsURL: URL(string: "https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_16x9/bipbop_16x9_variant.m3u8")!,
            durationSeconds: 15
        ),
        Creative(
            advertiser: "Nike",
            sponsorCategory: "Sports Retail",
            cpm: 48.50,
            tagline: "Just Do It — New Season Collection",
            ctaText: "Shop Now →",
            brandColorHex: "#000000",
            targetSegments: ["SEG-09: Affluent Sports Viewer", "SEG-04: Sports Commerce Buyer"],
            hlsURL: URL(string: "https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8")!,
            durationSeconds: 15
        ),
        Creative(
            advertiser: "Domino's",
            sponsorCategory: "Food & Delivery",
            cpm: 41.75,
            tagline: "Game Day Deal — 20% Off Your Order",
            ctaText: "Order Now →",
            brandColorHex: "#1565C0",
            targetSegments: ["SEG-02: Live Event Enthusiast", "SEG-08: Household Decision Maker"],
            hlsURL: URL(string: "https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_16x9/bipbop_16x9_variant.m3u8")!,
            durationSeconds: 15
        ),
    ]

    static func pick(for advertiser: String?) -> Creative {
        if let advertiser,
           let match = library.first(where: { $0.advertiser == advertiser }) {
            return match
        }
        // Default to highest-CPM creative
        return library.max(by: { $0.cpm < $1.cpm }) ?? library[0]
    }
}

// MARK: - Ad Pod Inserter

@MainActor
final class AdPodInserter: ObservableObject {

    @Published var isInAdPod: Bool = false
    @Published var currentAdvertiser: String = ""
    @Published var podProgress: Double = 0
    @Published var podDurationRemaining: Double = 0

    // Published for DemoAdCard display
    @Published var activeCreative: AdCreativeRegistry.Creative?

    var onAdPodCompleted: ((AdSlotInfo, Double) -> Void)?

    private var player: AVPlayer?
    // Save URL (not AVPlayerItem) — fresh item on restore avoids stale-buffer black frame
    private var savedContentURL: URL?
    private var progressTimer: Timer?
    private var podStartTime: Date?
    private var currentPodDuration: Double = 15

    // MARK: - Attach

    func attach(to player: AVPlayer) {
        self.player = player
    }

    // MARK: - Insert Ad Pod (Demo Mode — SwiftUI overlay, no AVPlayer swap)

    func insertPod(for slot: AdSlotInfo, channelID: String) {
        guard let player, !isInAdPod else { return }

        let creative = AdCreativeRegistry.pick(for: slot.advertiser)

        // Save content URL for production restore path
        savedContentURL = (player.currentItem?.asset as? AVURLAsset)?.url

        // Mute content audio during ad (but keep video playing for background)
        player.isMuted = true

        // State
        podStartTime = Date()
        currentPodDuration = creative.durationSeconds
        currentAdvertiser = creative.advertiser
        activeCreative = creative
        isInAdPod = true
        podProgress = 0
        podDurationRemaining = creative.durationSeconds

        print("[AdPod] 🎬 Pod started — \(creative.advertiser) — $\(String(format: "%.2f", creative.cpm)) CPM → targeting: \(creative.targetSegments.first ?? "broad")")

        startProgressTimer(duration: creative.durationSeconds, slot: slot)
    }

    // MARK: - Progress Timer

    private func startProgressTimer(duration: Double, slot: AdSlotInfo) {
        progressTimer?.invalidate()
        let startDate = Date()

        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] timer in
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

    // MARK: - Finish Pod

    private func finishPod(slot: AdSlotInfo) {
        guard isInAdPod, let player else { return }

        let latencyMs = Date().timeIntervalSince(podStartTime ?? Date()) * 1000
        progressTimer?.invalidate()
        progressTimer = nil

        // Restore audio
        player.isMuted = false

        isInAdPod = false
        podProgress = 0
        podDurationRemaining = 0
        activeCreative = nil
        savedContentURL = nil

        print("[AdPod] ✅ Pod complete — \(Int(latencyMs))ms")
        onAdPodCompleted?(slot, latencyMs)
    }

    func cancelPod() {
        guard isInAdPod else { return }
        progressTimer?.invalidate()
        progressTimer = nil
        player?.isMuted = false
        isInAdPod = false
        activeCreative = nil
        savedContentURL = nil
    }
}
