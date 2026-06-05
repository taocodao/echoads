// SSAISession.swift — Arenza Prototype
// Models matching POST /api/ssai/session response from existing Hono backend

import Foundation

// MARK: - SSAI Session Response

struct SSAISessionResponse: Codable {
    let sessionId: String
    let manifestUrl: String
    let auctionLatencyMs: Int
    let adBreaks: Int
    let totalDurationSeconds: Double
    let podMetadata: PodMetadata?
    let adSlots: [AdSlotInfo]
}

struct PodMetadata: Codable {
    let breakType: String?
    let fillRate: Double?
    let bidsReceived: Int?
}

struct AdSlotInfo: Codable, Identifiable {
    var id: String { impressionId }
    let impressionId: String
    let advertiser: String
    let cpm: Double
    let dspName: String
}

// MARK: - Active Playback Session

struct PlaybackSession {
    let sessionId: String
    let manifestURL: URL
    let adSlots: [AdSlotInfo]
    let totalDurationSeconds: Double
    let auctionLatencyMs: Int

    /// Estimated start offsets (seconds) for each ad break based on slot count
    /// The SSAI manifest interleaves ad segments; we approximate 30s slots.
    var adBreakOffsets: [Double] {
        let contentDuration = totalDurationSeconds - Double(adSlots.count) * 30.0
        guard adSlots.count > 0, contentDuration > 0 else { return [] }
        let interval = contentDuration / Double(adSlots.count + 1)
        return adSlots.enumerated().map { idx, _ in
            interval * Double(idx + 1) + Double(idx) * 30.0
        }
    }
}
