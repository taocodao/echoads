// CMXSAPIClient.swift
// URLSession-based REST client for the CMXS backend.
// For demo mode, all methods fall back to mock data when the API is unreachable.

import Foundation

final class CMXSAPIClient {

    private let base = Constants.apiBase
    private var authToken: String?

    // ── Generic GET ───────────────────────────────────────────────────────────
    func get<T: Decodable>(_ path: String) async throws -> T {
        let url = URL(string: base + path)!
        var req = URLRequest(url: url)
        if let token = authToken { req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }
        let (data, _) = try await URLSession.shared.data(for: req)
        return try JSONDecoder().decode(T.self, from: data)
    }

    // ── Generic POST ──────────────────────────────────────────────────────────
    func post<T: Decodable>(_ path: String, body: [String: Any]) async throws -> T {
        let url = URL(string: base + path)!
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = authToken { req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }
        req.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, _) = try await URLSession.shared.data(for: req)
        return try JSONDecoder().decode(T.self, from: data)
    }

    // ── PoD receipt submission ─────────────────────────────────────────────────
    func submitPoDReceipt(impressionId: String, signature: String, publicKey: String,
                          channelId: String, cpmi: UInt32, timestamp: UInt32) async throws -> PoDSubmitResponse {
        try await post("/pod/submit-receipt", body: [
            "impressionId": impressionId,
            "signature": signature,
            "publicKey": publicKey,
            "receiptData": [
                "impressionId": impressionId,
                "timestamp": timestamp,
                "channelId": channelId,
                "cpmi": cpmi
            ]
        ])
    }
}

struct PoDSubmitResponse: Codable {
    let accepted: Bool
    let txHash: String?
    let reward: Double?
}
