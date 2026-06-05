// AdBreakDetector.swift — Arenza Prototype
// Detects ad breaks from the SSAI session's podMetadata timing.
// Uses timer-based approach (most reliable for prototype) rather than
// parsing HLS EXT-X-DATERANGE tags from AVPlayerItemMetadataOutput.

import Foundation
import AVFoundation
import Combine

// MARK: - Ad Break Event

struct AdBreakEvent {
    let slotIndex: Int
    let adSlot: AdSlotInfo
    let startTime: Double   // seconds from stream start
    let duration: Double    // seconds (always 30 for prototype)
}

// MARK: - Detector

final class AdBreakDetector: NSObject {

    // Called when an ad break starts
    var onAdBreakStarted: ((AdBreakEvent) -> Void)?
    // Called when an ad break completes
    var onAdBreakCompleted: ((AdBreakEvent, Double) -> Void)?  // event + latencyMs

    private var session: PlaybackSession?
    private var player: AVPlayer?
    private var breakTimers: [Timer] = []
    private var completionTimers: [Timer] = []
    private var timeObserver: Any?
    private var adBreakStartTimes: [Int: Date] = [:]

    // MARK: - Attach to Player + Session

    func attach(to player: AVPlayer, session: PlaybackSession) {
        self.player = player
        self.session = session
        scheduleBreaks(session: session)
    }

    func detach() {
        breakTimers.forEach { $0.invalidate() }
        completionTimers.forEach { $0.invalidate() }
        breakTimers = []
        completionTimers = []
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
        }
        timeObserver = nil
        player = nil
        session = nil
    }

    // MARK: - Schedule Timers from Pod Metadata

    private func scheduleBreaks(session: PlaybackSession) {
        let offsets = session.adBreakOffsets
        let adSlots = session.adSlots

        for (index, offset) in offsets.enumerated() {
            guard index < adSlots.count else { break }
            let slot = adSlots[index]
            let adDuration: Double = 30.0

            // Schedule start timer
            let startTimer = Timer.scheduledTimer(withTimeInterval: offset, repeats: false) { [weak self] _ in
                guard let self else { return }
                let event = AdBreakEvent(
                    slotIndex: index,
                    adSlot: slot,
                    startTime: offset,
                    duration: adDuration
                )
                self.adBreakStartTimes[index] = Date()
                DispatchQueue.main.async {
                    self.onAdBreakStarted?(event)
                }

                // Schedule completion timer
                let completionTimer = Timer.scheduledTimer(
                    withTimeInterval: adDuration,
                    repeats: false
                ) { [weak self] _ in
                    guard let self else { return }
                    let startDate = self.adBreakStartTimes[index] ?? Date()
                    let latencyMs = Date().timeIntervalSince(startDate) * 1000
                    DispatchQueue.main.async {
                        self.onAdBreakCompleted?(event, latencyMs)
                    }
                }
                RunLoop.main.add(completionTimer, forMode: .common)
                self.completionTimers.append(completionTimer)
            }

            RunLoop.main.add(startTimer, forMode: .common)
            breakTimers.append(startTimer)

            print("[AdBreakDetector] Scheduled break \(index) at T+\(Int(offset))s (slot: \(slot.impressionId.prefix(12))...)")
        }
    }

    // MARK: - Demo Mode: Force trigger a break for testing

    func triggerDemoBreak(adSlot: AdSlotInfo) {
        let event = AdBreakEvent(
            slotIndex: 0,
            adSlot: adSlot,
            startTime: 0,
            duration: 30
        )
        adBreakStartTimes[0] = Date()
        onAdBreakStarted?(event)

        Timer.scheduledTimer(withTimeInterval: 30, repeats: false) { [weak self] _ in
            guard let self else { return }
            let latency = Date().timeIntervalSince(self.adBreakStartTimes[0] ?? Date()) * 1000
            DispatchQueue.main.async {
                self.onAdBreakCompleted?(event, latency)
            }
        }
    }
}
