// ContextualMomentService.swift — Arenza (C3: Contextual Moment Engine)
// Receives real-time game state signals from the Caton MoQ relay.
// Primary transport: MoQRelayConnector (WebSocket/QUIC).
// Fallback: timer-based demo mode when relay is unreachable.
// Feeds: BidRequestAssembler (CPM multipliers) + BettingMomentTrigger (safe windows).

import Foundation
import Combine

// MARK: - Moment Event (legacy CMXS WebSocket format — kept for backward compat)

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

    // MoQ relay connector (Phase B)
    private let moqConnector = MoQRelayConnector()

    private var currentChannelID: String?
    private var reconnectDelay: TimeInterval = 2.0
    private let maxReconnectDelay: TimeInterval = 60.0
    private var reconnectTask: Task<Void, Never>?
    private let session: URLSession

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10
        self.session = URLSession(configuration: config)
        wireMoQConnector()
    }

    // MARK: - Wire MoQ Connector signals

    private func wireMoQConnector() {
        // Ad break signals from relay → publish as .timeout moment
        moqConnector.onAdBreakSignal = { [weak self] durationSeconds in
            Task { @MainActor [weak self] in
                guard let self else { return }
                let moment: GameMoment = durationSeconds >= 60 ? .halftime : .timeout
                self.publishMoment(moment)
                print("[Moments] MoQ ad break signal — \(durationSeconds)s -> \(moment.rawValue)")
            }
        }
        // Game state changes from relay catalog
        moqConnector.onMomentChange = { [weak self] moment in
            Task { @MainActor [weak self] in
                self?.publishMoment(moment)
            }
        }
    }

    private func publishMoment(_ moment: GameMoment) {
        currentMoment = moment
        momentPublisher.send(moment)
    }

    // MARK: - Connect / Disconnect

    func connect(channelID: String) {
        guard channelID != currentChannelID else { return }
        currentChannelID = channelID
        reconnectDelay = 2.0

        // Try Caton MoQ relay first — it provides real live signals for the bbb broadcast.
        // If the relay is unreachable we fall back to demo mode after a short timeout.
        moqConnector.connect(channelID: channelID)
        isConnected = true

        // Start demo-mode fallback timer (fires if relay doesn't send a moment in 30s)
        startDemoModeFallbackIfNeeded()

        // Also try the legacy CMXS WebSocket (no-op if backend not running)
        let baseURL = ProcessInfo.processInfo.environment["CMXS_WS_URL"]
        if baseURL != nil {
            openCMXSWebSocket(channelID: channelID)
        }
    }


    func disconnect() {
        reconnectTask?.cancel()
        moqConnector.disconnect()
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        currentChannelID = nil
        isConnected = false
        currentMoment = .neutral
    }

    // MARK: - Demo Mode Fallback (when MoQ relay is unreachable)

    private var demoFallbackTask: Task<Void, Never>?

    private func startDemoModeFallbackIfNeeded() {
        demoFallbackTask?.cancel()
        // If MoQ relay hasn't sent any moment in 30s, switch to demo mode
        demoFallbackTask = Task {
            try? await Task.sleep(nanoseconds: 30_000_000_000)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                if self.currentMoment == .neutral {
                    print("[Moments] MoQ relay timeout — starting demo mode fallback")
                    self.startDemoMode()
                }
            }
        }
    }

    // MARK: - Legacy CMXS WebSocket (for when backend is deployed)

    private var webSocketTask: URLSessionWebSocketTask?

    private func openCMXSWebSocket(channelID: String) {
        let baseURL = ProcessInfo.processInfo.environment["CMXS_WS_URL"] ?? "wss://api.arenza.tv"
        let urlString = "\(baseURL)/v1/moments/stream?channel=\(channelID)"

        guard let url = URL(string: urlString) else {
            print("[Moments] Invalid CMXS WebSocket URL")
            return
        }

        webSocketTask = session.webSocketTask(with: url)
        webSocketTask?.resume()
        print("[Moments] CMXS WebSocket connected to \(urlString)")
        receiveCMXSMessage()
    }

    private func receiveCMXSMessage() {
        webSocketTask?.receive { [weak self] result in
            Task { @MainActor [weak self] in
                guard let self else { return }
                switch result {
                case .success(let message):
                    if case .string(let json) = message {
                        self.handleMomentJSON(json)
                    }
                    self.receiveCMXSMessage()  // keep listening
                case .failure(let error):
                    print("[Moments] CMXS WebSocket error: \(error.localizedDescription)")
                    self.isConnected = false
                    self.scheduleCMXSReconnect()
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

    private func scheduleCMXSReconnect() {
        guard let channelID = currentChannelID else { return }
        let delay = reconnectDelay + Double.random(in: -0.5...0.5)
        reconnectDelay = min(reconnectDelay * 2, maxReconnectDelay)
        print("[Moments] CMXS reconnecting in \(String(format: "%.1f", delay))s")
        reconnectTask = Task {
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            guard !Task.isCancelled else { return }
            await MainActor.run { self.openCMXSWebSocket(channelID: channelID) }
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
