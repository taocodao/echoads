// RevenueReporter.swift — Arenza (Token Marketplace Revenue)
// Batches CPM impression, CPC click, and CPA redemption events.
// Flushes to CMXS backend every 60 seconds or when batch reaches 20 events.
// Falls back to persisted queue if network is unavailable.

import Foundation
import Combine

// MARK: - Revenue Event

struct RevenueEvent: Codable {
    enum EventType: String, Codable {
        case impression = "impression"   // CPM — 1s+ card dwell
        case click      = "click"        // CPC — affiliate tap
        case redemption = "redemption"   // CPA — coupon code revealed
    }

    let id: UUID
    let type: EventType
    let sponsorId: String
    let sponsorName: String
    let offerId: UUID
    let revenueAmount: Double          // CPM rate / CPC rate / CPA flat fee
    let aztSpent: Int                  // AZT the user spent (0 for impression/click)
    let couponCode: String?            // only for redemption
    let trackingId: String?            // affiliate/coupon tracking ID
    let timestamp: Date
    let sessionId: String
    let dmaCode: String?
}

// MARK: - Revenue Reporter

actor RevenueReporter {
    static let shared = RevenueReporter()

    private let sessionId = UUID().uuidString
    private var pendingEvents: [RevenueEvent] = []
    private var flushTask: Task<Void, Never>?
    private let maxBatchSize = 20
    private let flushInterval: TimeInterval = 60
    private let persistenceKey = "arenza.revenue.pending"

    private init() {
        loadPersistedEvents()
        scheduleFlushLoop()
    }

    // MARK: - Record events

    func recordImpression(offer: SponsorOffer, dmaCode: String? = nil) {
        let event = RevenueEvent(
            id: UUID(), type: .impression,
            sponsorId: offer.sponsorId, sponsorName: offer.sponsorName,
            offerId: offer.id, revenueAmount: offer.impressionCPM / 1000.0,  // per impression
            aztSpent: 0, couponCode: nil, trackingId: offer.couponTrackingId,
            timestamp: Date(), sessionId: sessionId, dmaCode: dmaCode
        )
        enqueue(event)
        print("[Revenue] +CPM \(String(format: "$%.4f", event.revenueAmount)) — \(offer.sponsorName)")
    }

    func recordClick(offer: SponsorOffer, dmaCode: String? = nil) {
        let event = RevenueEvent(
            id: UUID(), type: .click,
            sponsorId: offer.sponsorId, sponsorName: offer.sponsorName,
            offerId: offer.id, revenueAmount: offer.clickCPC,
            aztSpent: 0, couponCode: nil, trackingId: offer.couponTrackingId,
            timestamp: Date(), sessionId: sessionId, dmaCode: dmaCode
        )
        enqueue(event)
        print("[Revenue] +CPC $\(String(format: "%.2f", event.revenueAmount)) — \(offer.sponsorName)")
    }

    func recordRedemption(offer: SponsorOffer, aztSpent: Int, dmaCode: String? = nil) {
        let event = RevenueEvent(
            id: UUID(), type: .redemption,
            sponsorId: offer.sponsorId, sponsorName: offer.sponsorName,
            offerId: offer.id, revenueAmount: offer.redemptionFee,
            aztSpent: aztSpent, couponCode: offer.couponCode,
            trackingId: offer.couponTrackingId,
            timestamp: Date(), sessionId: sessionId, dmaCode: dmaCode
        )
        enqueue(event)
        print("[Revenue] +CPA $\(String(format: "%.2f", event.revenueAmount)) — \(offer.sponsorName) code:\(offer.couponCode)")
    }

    // MARK: - Queue management

    private func enqueue(_ event: RevenueEvent) {
        pendingEvents.append(event)
        persistEvents()
        if pendingEvents.count >= maxBatchSize {
            Task { await flush() }
        }
    }

    // MARK: - Flush to backend

    func flush() async {
        guard !pendingEvents.isEmpty else { return }
        let batch = pendingEvents
        pendingEvents.removeAll()
        persistEvents()

        guard let url = URL(string: "\(CMXSConfig.apiBase)/v1/revenue/batch") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 10

        guard let body = try? JSONEncoder().encode(batch) else { return }
        request.httpBody = body

        do {
            let (_, resp) = try await URLSession.shared.data(for: request)
            let code = (resp as? HTTPURLResponse)?.statusCode ?? 0
            print("[Revenue] Flushed \(batch.count) events → HTTP \(code)")
        } catch {
            // Re-queue on failure
            print("[Revenue] Flush failed — re-queuing \(batch.count) events: \(error.localizedDescription)")
            pendingEvents.insert(contentsOf: batch, at: 0)
            persistEvents()
        }
    }

    // MARK: - Periodic flush loop

    private func scheduleFlushLoop() {
        flushTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: UInt64(flushInterval) * 1_000_000_000)
                await flush()
            }
        }
    }

    // MARK: - Persistence (survive app restarts)

    private func persistEvents() {
        guard let data = try? JSONEncoder().encode(pendingEvents) else { return }
        UserDefaults.standard.set(data, forKey: persistenceKey)
    }

    private func loadPersistedEvents() {
        guard let data = UserDefaults.standard.data(forKey: persistenceKey),
              let events = try? JSONDecoder().decode([RevenueEvent].self, from: data) else { return }
        pendingEvents = events
        print("[Revenue] Loaded \(events.count) persisted events from previous session")
    }
}
