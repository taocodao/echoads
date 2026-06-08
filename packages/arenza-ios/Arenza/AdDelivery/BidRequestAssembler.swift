// BidRequestAssembler.swift — Arenza (C2: Ad Delivery Pipeline)
// Assembles enriched OpenRTB 2.6 bid requests with segment, moment, and PoD extension.
// Called before every SCTE-35 ad break.

import Foundation

// MARK: - Enriched Bid Request

struct EnrichedBidRequest: Codable {
    let channelID: String
    let breakDurationSec: Int
    let podPosition: Int
    let cmxsExtension: CMXSBidExtension
    let deviceJWT: String?
    let timestamp: Double
}

struct BidResponse: Codable {
    let bidID: String
    let creativeURL: URL?
    let creativeID: String
    let advertiserID: String
    let advertiserName: String
    let clearedCPM: Double
    let impressionID: String
    var isFilled: Bool { creativeURL != nil }
}

// MARK: - Bid Request Assembler

actor BidRequestAssembler {

    static let shared = BidRequestAssembler()
    private let session: URLSession

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 5   // fast timeout — ad breaks are time-sensitive
        self.session = URLSession(configuration: config)
    }

    // MARK: - Assemble + submit bid request

    func requestBid(
        channelID: String,
        breakDurationSec: Int,
        podPosition: Int
    ) async -> BidResponse? {
        // Gate: don't bid for suspect sessions
        guard await !MainActor.run(body: { AnomalyDetector.shared.isSuspectSession }) else {
            print("[BidAssembler] 🚫 Skipping bid — suspect session")
            return nil
        }

        let moment = await MainActor.run { ContextualMomentService.shared.currentMoment }
        let segment = await MainActor.run { ProfileEngine.shared.currentSegment }

        let ext = CMXSBidExtension(
            segmentID: segment.rawValue,
            gameMoment: moment.rawValue,
            cpmMultiplierHint: moment.cpmMultiplier,
            podPosition: podPosition,
            breakDurationSec: breakDurationSec,
            secureEnclaveAttested: true,
            podVerification: "base_l2"
        )

        let request = EnrichedBidRequest(
            channelID: channelID,
            breakDurationSec: breakDurationSec,
            podPosition: podPosition,
            cmxsExtension: ext,
            deviceJWT: nil,   // TODO: inject JWT from AppEnvironment
            timestamp: Date().timeIntervalSince1970
        )

        return await submitBidRequest(request)
    }

    // MARK: - Submit to CMXS BidOrchestrator

    private func submitBidRequest(_ bidRequest: EnrichedBidRequest) async -> BidResponse? {
        guard let url = URL(string: "\(CMXSConfig.apiBase)/v1/bid/request") else { return nil }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try? JSONEncoder().encode(bidRequest)

        do {
            let (data, response) = try await session.data(for: urlRequest)
            if let http = response as? HTTPURLResponse, http.statusCode == 200 {
                return try? JSONDecoder().decode(BidResponse.self, from: data)
            }
        } catch {
            print("[BidAssembler] ❌ Bid request failed: \(error.localizedDescription)")
        }

        // Fallback: serve house ad
        return makeFallbackResponse(bidRequest: bidRequest)
    }

    // MARK: - House ad fallback response

    private func makeFallbackResponse(bidRequest: EnrichedBidRequest) -> BidResponse? {
        let houseAd = HouseAdCache.shared.nextHouseAd()
        guard let ad = houseAd else { return nil }

        return BidResponse(
            bidID: UUID().uuidString,
            creativeURL: ad.localFileURL ?? ad.creativeURL,
            creativeID: ad.id,
            advertiserID: ad.advertiserID,
            advertiserName: ad.advertiserName,
            clearedCPM: 5.0,    // house ad CPM (internal)
            impressionID: UUID().uuidString
        )
    }
}

// MARK: - EABN Service

actor EABNService {

    static let shared = EABNService()
    private let session = URLSession.shared

    private init() {}

    /// Fire Early Ad Break Notification to CMXS AdOrchestrator
    /// Should be called 60+ seconds before expected break.
    func notifyUpcomingBreak(
        channelID: String,
        expectedBreakOffset: TimeInterval,
        breakDurationSec: Int
    ) async {
        let segment = await MainActor.run { ProfileEngine.shared.currentSegment }
        let moment  = await MainActor.run { ContextualMomentService.shared.currentMoment }

        let eabn = EABNRequest(
            channelID: channelID,
            expectedBreakTime: Date().addingTimeInterval(expectedBreakOffset),
            breakDurationSeconds: breakDurationSec,
            viewerSegmentID: segment.rawValue,
            gameMoment: moment.rawValue,
            expectedImpressions: 1,
            floorCPMOverride: nil
        )

        guard let url = URL(string: "\(CMXSConfig.apiBase)/v1/breaks/eabn") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONEncoder().encode(eabn)

        _ = try? await session.data(for: request)
        print("[EABN] 📣 Notified upcoming break at T+\(Int(expectedBreakOffset))s (segment: \(segment.label))")
    }
}
