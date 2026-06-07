// CMXSAPIClient.swift — Arenza Prototype
// URLSession-based REST client targeting existing Hono backend at packages/api
// No Alamofire — URLSession async/await only.

import Foundation

// MARK: - Configuration

enum CMXSConfig {
    #if DEBUG
    static let apiBase = "http://localhost:3001"   // local dev
    // static let apiBase = "https://your-vercel-deployment.vercel.app"
    #else
    static let apiBase = "https://api.cmxs.io/v1"  // production stub
    #endif

    static let contentURL = apiBase  // same origin for prototype
}

// MARK: - API Errors

enum CMXSAPIError: LocalizedError {
    case invalidURL
    case httpError(Int, String)
    case decodingFailed(Error)
    case networkError(Error)
    case noData

    var errorDescription: String? {
        switch self {
        case .invalidURL:          return "Invalid URL"
        case .httpError(let c, let m): return "HTTP \(c): \(m)"
        case .decodingFailed(let e):   return "Decode error: \(e.localizedDescription)"
        case .networkError(let e):     return "Network error: \(e.localizedDescription)"
        case .noData:              return "No data received"
        }
    }
}

// MARK: - Client

actor CMXSAPIClient {

    private let session: URLSession
    private var deviceToken: String?

    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        config.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: config)
    }

    // ── Health ──────────────────────────────────────────────────────────────

    func checkHealth() async throws -> Bool {
        let url = try makeURL("/health")
        let (data, response) = try await session.data(from: url)
        return (response as? HTTPURLResponse)?.statusCode == 200 && !data.isEmpty
    }

    // ── SSAI Session ────────────────────────────────────────────────────────

    func createSSAISession(channelId: String, nodeOperator: String) async throws -> SSAISessionResponse {
        let url = try makeURL("/api/ssai/session")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "contentId": channelId,
            "nodeOperator": nodeOperator,
            "resolution": "1080p",
            "campaignId": "0xdeadbeef00000000000000000000000000000000000000000000000000000000"
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        addAuthHeader(to: &request)

        return try await fetch(SSAISessionResponse.self, from: request)
    }

    /// Returns the full manifest URL (absolute) for AVPlayer
    nonisolated func manifestURL(for sessionId: String) -> URL? {
        URL(string: "\(CMXSConfig.apiBase)/api/ssai/manifest/\(sessionId)")
    }

    // ── Delivery Beacon ─────────────────────────────────────────────────────

    func sendDeliveryBeacon(txHash: String, switchLatencyMs: Double) async {
        guard let url = try? makeURL("/api/delivery/beacon") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        addAuthHeader(to: &request)

        let body: [String: Any] = ["txHash": txHash, "switchLatencyMs": switchLatencyMs]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        _ = try? await session.data(for: request)
    }

    // ── PoD Receipt Submission ──────────────────────────────────────────────

    func submitPoDReceipt(_ payload: PoDSubmissionPayload) async throws -> PoDSubmissionResult {
        let url = try makeURL("/api/delivery/pod")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        addAuthHeader(to: &request)
        request.httpBody = try JSONEncoder().encode(payload)
        return try await fetch(PoDSubmissionResult.self, from: request)
    }

    // ── Auction Stats (for Earnings) ────────────────────────────────────────

    func fetchAuctionStats() async throws -> AuctionStatsResponse {
        let url = try makeURL("/api/auction/stats")
        let request = makeGETRequest(url: url)
        return try await fetch(AuctionStatsResponse.self, from: request)
    }

    // ── Stub: Device Registration ───────────────────────────────────────────
    // Full auth not built yet — returns a hardcoded token for prototype

    func registerDevice(publicKeyHex: String) async -> String {
        // In production: POST /auth/device-register
        // Returns JWT + walletAddress. For prototype, return a static token.
        return "prototype-jwt-\(publicKeyHex.prefix(8))"
    }

    // MARK: - Private Helpers

    private func makeURL(_ path: String) throws -> URL {
        guard let url = URL(string: CMXSConfig.apiBase + path) else {
            throw CMXSAPIError.invalidURL
        }
        return url
    }

    private func makeGETRequest(url: URL) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        addAuthHeader(to: &request)
        return request
    }

    private func addAuthHeader(to request: inout URLRequest) {
        if let token = deviceToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
    }

    private func fetch<T: Decodable>(_ type: T.Type, from request: URLRequest) async throws -> T {
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw CMXSAPIError.networkError(error)
        }

        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            let message = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw CMXSAPIError.httpError(http.statusCode, message)
        }

        do {
            return try JSONDecoder().decode(type, from: data)
        } catch {
            throw CMXSAPIError.decodingFailed(error)
        }
    }
}

// MARK: - Supporting Response Types

struct AuctionStatsResponse: Codable {
    let totalAuctions: Int
    let avgLatencyMs: Int
    let avgCpm: Double
    let avgFillRate: Double
}
