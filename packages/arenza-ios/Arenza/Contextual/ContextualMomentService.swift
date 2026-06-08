// ContextualMomentService.swift — Arenza (C3: Contextual Moment Engine)
// WebSocket client that receives real-time game state events from CMXS backend.
// Used by BidRequestAssembler (CPM multipliers) and BettingMomentTrigger (safe windows).

import Foundation
import Combine

// MARK: - Moment Event (from WebSocket)

private struct MomentEvent: Codable {
    let momentType: String
    let channelID: String
    let confidence: Double?
    let timestamp: String?
}

// MARK: - Contextual Moment Service

@MainActor
final class ContextualMomentService: ObservableObject {

    static let shared = ContextualMomentService()

    @Published private(set) var currentMoment: GameMoment = .neutral
    @Published private(set) var isConnected: Bool = false

    // Publishers that other services can subscribe to
    let momentPublisher = PassthroughSubject<GameMoment, Never>()

    private var webSocketTask: URLSessionWebSocketTask?
    private var currentChannelID: String?
    private var reconnectDelay: TimeInterval = 2.0
    private let maxReconnectDelay: TimeInterval = 60.0
    private var reconnectTask: Task<Void, Never>?
    private let session: URLSession

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10
        self.session = URLSession(configuration: config)
    }

    // MARK: - Connect / Disconnect

    func connect(channelID: String) {
        guard channelID != currentChannelID else { return }
        currentChannelID = channelID
        reconnectDelay = 2.0
        openWebSocket(channelID: channelID)
    }

    func disconnect() {
        reconnectTask?.cancel()
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        currentChannelID = nil
        isConnected = false
        currentMoment = .neutral
    }

    // MARK: - WebSocket lifecycle

    private func openWebSocket(channelID: String) {
        // Use sandbox stub URL if CMXS WebSocket endpoint is not yet live
        let baseURL = ProcessInfo.processInfo.environment["CMXS_WS_URL"]
                   ?? "wss://api.arenza.tv"
        let urlString = "\(baseURL)/v1/moments/stream?channel=\(channelID)"

        guard let url = URL(string: urlString) else {
            print("[Moments] ⚠️ Invalid WebSocket URL — using demo mode")
            startDemoMode()
            return
        }

        webSocketTask = session.webSocketTask(with: url)
        webSocketTask?.resume()
        isConnected = true
        reconnectDelay = 2.0
        print("[Moments] 🔌 Connected to \(urlString)")
        receiveNextMessage()
    }

    private func receiveNextMessage() {
        webSocketTask?.receive { [weak self] result in
            Task { @MainActor [weak self] in
                guard let self else { return }
                switch result {
                case .success(let message):
                    if case .string(let json) = message {
                        self.handleMomentJSON(json)
                    }
                    self.receiveNextMessage()  // keep listening
                case .failure(let error):
                    print("[Moments] ❌ WebSocket error: \(error.localizedDescription)")
                    self.isConnected = false
                    self.scheduleReconnect()
                }
            }
        }
    }

    private func handleMomentJSON(_ json: String) {
        guard let data = json.data(using: .utf8),
              let event = try? JSONDecoder().decode(MomentEvent.self, from: data) else {
            return
        }
        let moment = GameMoment(rawValue: event.momentType) ?? .neutral
        print("[Moments] 📡 \(moment.rawValue) (CPM ×\(moment.cpmMultiplier))")
        currentMoment = moment
        momentPublisher.send(moment)
    }

    // MARK: - Reconnect with exponential backoff

    private func scheduleReconnect() {
        guard let channelID = currentChannelID else { return }
        let delay = reconnectDelay + Double.random(in: -0.5...0.5)  // ±0.5s jitter
        reconnectDelay = min(reconnectDelay * 2, maxReconnectDelay)

        print("[Moments] 🔄 Reconnecting in \(String(format: "%.1f", delay))s…")
        reconnectTask = Task {
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            guard !Task.isCancelled else { return }
            await MainActor.run { self.openWebSocket(channelID: channelID) }
        }
    }

    // MARK: - Demo mode (fires simulated moments when no backend)

    private var demoMomentIndex: Int = 0  // class property avoids captured-var concurrency error

    private func startDemoMode() {
        isConnected = true
        let moments: [GameMoment] = [.neutral, .neutral, .timeout, .neutral, .neutral, .halftime, .neutral]

        Timer.scheduledTimer(withTimeInterval: 15.0, repeats: true) { [weak self] timer in
            guard let self else { timer.invalidate(); return }
            Task { @MainActor [weak self] in
                guard let self else { return }
                let moment = moments[self.demoMomentIndex % moments.count]
                self.demoMomentIndex += 1
                self.currentMoment = moment
                self.momentPublisher.send(moment)
                print("[Moments] Demo moment: \(moment.rawValue)")
            }
        }
    }
}

// MARK: - Game Moment Enricher (bid request extension)

enum GameMomentEnricher {
    /// Builds the CMXS extension dict for OpenRTB bid requests.
    /// segmentID is passed in from the caller (who is @MainActor) to avoid isolation crossing.
    static func buildBidExtension(
        moment: GameMoment,
        segmentID: Int,
        podPosition: Int,
        breakDurationSec: Int
    ) -> CMXSBidExtension {
        CMXSBidExtension(
            segmentID: segmentID,
            gameMoment: moment.rawValue,
            cpmMultiplierHint: moment.cpmMultiplier,
            podPosition: podPosition,
            breakDurationSec: breakDurationSec,
            secureEnclaveAttested: true,
            podVerification: "base_l2"
        )
    }

    /// Effective CPM for this moment x segment combination
    static func effectiveCPM(baseCPM: Double, moment: GameMoment) -> Double {
        baseCPM * moment.cpmMultiplier
    }
}
