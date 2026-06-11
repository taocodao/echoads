// RealtimeService.swift — Arenza (Phase 6: Real-time Infrastructure)
// WebSocket client for game events, bingo auto-marks, predictions, and leaderboard updates.
// Connects to Supabase Realtime / custom WebSocket server.

import Foundation
import Combine

// MARK: - Realtime Service

@MainActor
final class RealtimeService: ObservableObject {
    static let shared = RealtimeService()

    @Published var connectionState: ConnectionState = .disconnected
    @Published var latencyMs: Int?

    private var webSocket: URLSessionWebSocketTask?
    private var session: URLSession?
    private var pingTimer: Timer?
    private var reconnectTimer: Timer?
    private var reconnectAttempts = 0
    private let maxReconnectAttempts = 10
    private var cancellables = Set<AnyCancellable>()

    // Event publishers
    let predictionResultPublisher = PassthroughSubject<PredictionResultEvent, Never>()
    let cellAutoMarkedPublisher = PassthroughSubject<CellAutoMarkedEvent, Never>()
    let bingoDetectedPublisher = PassthroughSubject<BingoDetectedEvent, Never>()
    let pointsEarnedPublisher = PassthroughSubject<PointsEarnedEvent, Never>()
    let leaderboardUpdatePublisher = PassthroughSubject<LeaderboardUpdateEvent, Never>()
    let couponReadyPublisher = PassthroughSubject<CouponReadyEvent, Never>()
    let scratchCardReadyPublisher = PassthroughSubject<ScratchCardReadyEvent, Never>()

    private init() {}

    // MARK: - Connection

    enum ConnectionState: String {
        case disconnected
        case connecting
        case connected
        case reconnecting
    }

    /// Connect to the game's WebSocket channel.
    func connect(gameId: String, userId: String) {
        guard connectionState == .disconnected || connectionState == .reconnecting else { return }

        connectionState = .connecting

        let urlString = "\(Constants.wsBaseURL)/game/\(gameId)?userId=\(userId)"
        guard let url = URL(string: urlString) else {
            print("[WS] Invalid URL: \(urlString)")
            return
        }

        let config = URLSessionConfiguration.default
        config.waitsForConnectivity = true
        config.timeoutIntervalForRequest = 30
        session = URLSession(configuration: config)

        var request = URLRequest(url: url)
        request.setValue("Bearer \(UserDefaults.standard.string(forKey: "auth_token") ?? "")", forHTTPHeaderField: "Authorization")

        webSocket = session?.webSocketTask(with: request)
        webSocket?.resume()

        connectionState = .connected
        reconnectAttempts = 0
        print("[WS] Connected to game:\(gameId)")

        startListening()
        startPingLoop()
    }

    /// Disconnect from the WebSocket.
    func disconnect() {
        webSocket?.cancel(with: .normalClosure, reason: nil)
        webSocket = nil
        pingTimer?.invalidate()
        reconnectTimer?.invalidate()
        connectionState = .disconnected
        latencyMs = nil
        print("[WS] Disconnected")
    }

    // MARK: - Listen for Messages

    private func startListening() {
        webSocket?.receive { [weak self] result in
            Task { @MainActor in
                switch result {
                case .success(let message):
                    self?.handleMessage(message)
                    self?.startListening() // continue listening
                case .failure(let error):
                    print("[WS] Receive error: \(error.localizedDescription)")
                    self?.handleDisconnect()
                }
            }
        }
    }

    private func handleMessage(_ message: URLSessionWebSocketTask.Message) {
        switch message {
        case .string(let text):
            parseEvent(text)
        case .data(let data):
            if let text = String(data: data, encoding: .utf8) {
                parseEvent(text)
            }
        @unknown default:
            break
        }
    }

    // MARK: - Parse Events

    private func parseEvent(_ json: String) {
        guard let data = json.data(using: .utf8) else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        // Try to decode the wrapper first to identify event type
        guard let wrapper = try? decoder.decode(EventWrapper.self, from: data) else {
            print("[WS] Unknown event format: \(json.prefix(100))")
            return
        }

        switch wrapper.type {
        case "PREDICTION_RESULT":
            if let event = try? decoder.decode(PredictionResultEvent.self, from: data) {
                predictionResultPublisher.send(event)
            }
        case "CELL_AUTO_MARKED":
            if let event = try? decoder.decode(CellAutoMarkedEvent.self, from: data) {
                cellAutoMarkedPublisher.send(event)
            }
        case "BINGO_DETECTED":
            if let event = try? decoder.decode(BingoDetectedEvent.self, from: data) {
                bingoDetectedPublisher.send(event)
            }
        case "POINTS_EARNED":
            if let event = try? decoder.decode(PointsEarnedEvent.self, from: data) {
                pointsEarnedPublisher.send(event)
            }
        case "LEADERBOARD_UPDATE":
            if let event = try? decoder.decode(LeaderboardUpdateEvent.self, from: data) {
                leaderboardUpdatePublisher.send(event)
            }
        case "COUPON_READY":
            if let event = try? decoder.decode(CouponReadyEvent.self, from: data) {
                couponReadyPublisher.send(event)
            }
        case "SCRATCH_CARD_READY":
            if let event = try? decoder.decode(ScratchCardReadyEvent.self, from: data) {
                scratchCardReadyPublisher.send(event)
            }
        case "PONG":
            // Calculate round-trip latency
            if let ts = wrapper.timestamp {
                let rtt = Date().timeIntervalSince(ts)
                latencyMs = Int(rtt * 1000)
            }
        default:
            print("[WS] Unhandled event type: \(wrapper.type)")
        }
    }

    // MARK: - Send Messages

    /// Send a prediction lock to the server.
    func sendPredictionLock(questionId: UUID, selectedOptionId: String) {
        let payload: [String: Any] = [
            "type": "PREDICTION_LOCK",
            "questionId": questionId.uuidString,
            "selectedOptionId": selectedOptionId,
            "lockedAt": ISO8601DateFormatter().string(from: Date())
        ]
        sendJSON(payload)
    }

    /// Send a bingo cell mark confirmation.
    func sendBingoCellMark(boardId: String, cellId: String) {
        let payload: [String: Any] = [
            "type": "BINGO_CELL_MARK",
            "boardId": boardId,
            "cellId": cellId,
            "markedAt": ISO8601DateFormatter().string(from: Date())
        ]
        sendJSON(payload)
    }

    private func sendJSON(_ dict: [String: Any]) {
        guard let data = try? JSONSerialization.data(withJSONObject: dict),
              let text = String(data: data, encoding: .utf8) else { return }

        webSocket?.send(.string(text)) { error in
            if let error {
                print("[WS] Send error: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Ping / Pong

    private func startPingLoop() {
        pingTimer?.invalidate()
        pingTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.sendPing()
            }
        }
    }

    private func sendPing() {
        let payload: [String: Any] = [
            "type": "PING",
            "timestamp": ISO8601DateFormatter().string(from: Date())
        ]
        sendJSON(payload)
        webSocket?.sendPing { [weak self] error in
            if let error {
                print("[WS] Ping failed: \(error.localizedDescription)")
                Task { @MainActor in
                    self?.handleDisconnect()
                }
            }
        }
    }

    // MARK: - Reconnect

    private func handleDisconnect() {
        guard connectionState != .disconnected else { return }

        connectionState = .reconnecting
        reconnectAttempts += 1

        guard reconnectAttempts <= maxReconnectAttempts else {
            print("[WS] Max reconnect attempts reached. Giving up.")
            connectionState = .disconnected
            return
        }

        // Exponential backoff: 1s, 2s, 4s, 8s... capped at 30s
        let delay = min(30.0, pow(2.0, Double(reconnectAttempts - 1)))
        print("[WS] Reconnecting in \(delay)s (attempt \(reconnectAttempts)/\(maxReconnectAttempts))")

        reconnectTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            Task { @MainActor in
                // Re-use last game/user IDs
                // In production, store these and re-connect
                print("[WS] Attempting reconnect...")
                self?.connectionState = .disconnected
            }
        }
    }
}

// MARK: - WebSocket Event Types

struct EventWrapper: Codable {
    let type: String
    let timestamp: Date?
}

struct PredictionResultEvent: Codable {
    let type: String
    let questionId: UUID
    let correctOptionId: String
    let totalResponses: Int
    let distribution: [String: Double]  // optionId → percentage
}

struct CellAutoMarkedEvent: Codable {
    let type: String
    let cellTypes: [String]             // game events that occurred
}

struct BingoDetectedEvent: Codable {
    let type: String
    let userId: String
    let lineType: String                // "row", "col", "diag"
    let pointsEarned: Int
}

struct PointsEarnedEvent: Codable {
    let type: String
    let amount: Int
    let newBalance: Int
    let source: String
}

struct LeaderboardUpdateEvent: Codable {
    let type: String
    let topEntries: [LeaderboardEntryDTO]
}

struct LeaderboardEntryDTO: Codable {
    let userId: String
    let displayName: String
    let points: Int
    let rank: Int
}

struct CouponReadyEvent: Codable {
    let type: String
    let couponCode: String
    let sponsorName: String
    let discount: String
}

struct ScratchCardReadyEvent: Codable {
    let type: String
    let cardId: String
    let sponsorName: String
}

// MARK: - Constants Extension

extension Constants {
    /// WebSocket base URL for real-time game events.
    /// Overridable via ARENZA_WS_URL environment variable.
    static var wsBaseURL: String {
        ProcessInfo.processInfo.environment["ARENZA_WS_URL"]
            ?? "wss://realtime.arenza.app/ws"
    }
}
