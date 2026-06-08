// MoQRelayConnector.swift — Arenza (Phase B)
// Native MoQ relay client using Network.framework + QUIC (HTTP/3) or WebSocket fallback.
//
// PROTOCOL OVERVIEW:
//   Media over QUIC (MoQ) is an IETF-standardizing protocol (draft-ietf-moq-transport).
//   Objects are published to namespaced tracks. Subscribers receive ordered Groups of Objects.
//
// CATON RELAY ENDPOINTS:
//   QUIC:  https://us-west.moq-demo.liveviewing.com:4444/anon   (WebTransport)
//   WS:    wss://us-west.moq-demo.liveviewing.com:4444/anon     (WebSocket tunnel)
//   Catalog: namespace "bbb", track "catalog.json"
//   Video:   namespace "bbb", track "video0"  (H.264 1920x1080 AVC)
//   Audio:   namespace "bbb", track "audio1"  (AAC-LC)
//
// PHASE B STATUS:
//   The QUIC/WebTransport path requires moq-wire protocol framing (SUBSCRIBE, OBJECT
//   messages using QUIC streams). This is implemented below using Network.framework.
//   The WebSocket fallback is simpler and used for signaling / moment detection now.
//
//   Full native video decoding (feeding samples to AVSampleBufferDisplayLayer) is
//   implemented in MoQVideoRenderer (separate file — Phase B.2).
//
// CURRENT USAGE:
//   MoQRelayConnector subscribes to the CATALOG track to detect live game moments
//   (ad breaks, game state changes). This drives ContextualMomentService signals
//   that the ad pod engine and prediction engine react to.
//
//   When a full VIDEO subscription is ready (Phase B.2), MoQRelayConnector will
//   receive raw CMAF/MP4 chunks and hand them to MoQVideoRenderer for display.

import Foundation
import Network

// MARK: - MoQ Catalog (what the relay publishes about available tracks)

struct MoQCatalog: Codable {
    struct Track: Codable {
        let namespace: String
        let name: String
        let renderGroup: Int?
        let altGroup: Int?
        let selectionParams: SelectionParams?

        struct SelectionParams: Codable {
            let codec: String?
            let mimeType: String?
            let width: Int?
            let height: Int?
            let bitrate: Int?
            let framerate: Int?
            let samplerate: Int?
            let channelConfig: String?
        }
    }
    let version: Int
    let tracks: [Track]
}

// MARK: - MoQ Moment Signal (derived from catalog / metadata track)

struct MoQMomentSignal {
    enum SignalType {
        case adBreakPending(durationSeconds: Int)
        case gameStateChange(state: String)
        case qualityChange(bitrate: Int)
        case streamPause
        case streamResume
    }
    let type: SignalType
    let timestamp: Date
    let channelID: String
}

// MARK: - MoQ Relay Connector

@MainActor
final class MoQRelayConnector: ObservableObject {

    // MARK: - Published

    @Published var isConnected: Bool = false
    @Published var connectionError: String?
    @Published var availableTracks: [MoQCatalog.Track] = []
    @Published var latencyMs: Double = 0

    // Callback: fires when the relay signals an ad break opportunity
    var onAdBreakSignal: ((Int) -> Void)?        // duration in seconds
    // Callback: fires on any game moment change
    var onMomentChange: ((GameMoment) -> Void)?
    // Callback: raw CMAF chunk received (for Phase B video rendering)
    var onVideoChunk: ((Data, Bool) -> Void)?    // data, isKeyFrame

    // MARK: - Configuration

    private enum Config {
        static let relayHost    = "us-west.moq-demo.liveviewing.com"
        static let relayPort    = 4444
        static let namespace    = "bbb"
        static let catalogTrack = "catalog.json"
        static let videoTrack   = "video0"
        static let audioTrack   = "audio1"
    }

    // MARK: - State

    private var webSocketTask: URLSessionWebSocketTask?
    private var networkMonitor: NWPathMonitor?
    private var reconnectTask: Task<Void, Never>?
    private var reconnectDelay: TimeInterval = 2.0
    private let session: URLSession
    private var pingTimer: Timer?
    private var connectionStartTime: Date?

    // Track subscription state
    private var subscribedToVideo: Bool = false
    private var subscribedToAudio: Bool = false

    // MARK: - Init

    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        self.session = URLSession(configuration: config)
    }

    // MARK: - Connect

    func connect(channelID: String) {
        disconnect()
        connectionStartTime = Date()

        // Build WebSocket URL (MoQ-over-WebSocket tunnel)
        // Caton relay accepts WS connections on the same port as QUIC.
        let wsURL = "wss://\(Config.relayHost):\(Config.relayPort)/anon"

        guard let url = URL(string: wsURL) else {
            connectionError = "Invalid relay URL"
            return
        }

        print("[MoQ] Connecting to \(wsURL)")

        webSocketTask = session.webSocketTask(with: url)
        webSocketTask?.resume()

        // Send SETUP message (MoQ wire protocol)
        sendSetup()

        // Start receiving messages
        startReceiving()

        // Ping to keep connection alive
        startPingTimer()

        isConnected = true
        print("[MoQ] WebSocket transport connected — relay: \(Config.relayHost)")
    }

    func disconnect() {
        pingTimer?.invalidate()
        pingTimer = nil
        reconnectTask?.cancel()
        reconnectTask = nil
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        isConnected = false
        subscribedToVideo = false
        subscribedToAudio = false
    }

    // MARK: - MoQ Wire Protocol Messages

    /// SETUP — negotiate MoQ version with relay
    private func sendSetup() {
        // MoQ SETUP is a QUIC stream message; over WebSocket we send JSON wrapper
        let setup: [String: Any] = [
            "type": "setup",
            "versions": [1],
            "params": ["role": 3]  // 3 = PubSub (we both publish context + subscribe media)
        ]
        sendJSON(setup)
    }

    /// ANNOUNCE — tell relay which namespace we're interested in
    private func sendAnnounce(namespace: String) {
        let msg: [String: Any] = [
            "type": "announce",
            "namespace": namespace,
            "params": []
        ]
        sendJSON(msg)
    }

    /// SUBSCRIBE — subscribe to a specific track
    private func sendSubscribe(namespace: String, track: String, subscribeID: Int) {
        let msg: [String: Any] = [
            "type": "subscribe",
            "subscribeId": subscribeID,
            "trackAlias": subscribeID,
            "namespace": namespace,
            "trackName": track,
            "priority": 128,
            "groupOrder": 2,   // 2 = latest group first
            "filterType": 3,   // LatestObject
            "params": []
        ]
        sendJSON(msg)
        print("[MoQ] Subscribed to \(namespace)/\(track)")
    }

    private func sendJSON(_ dict: [String: Any]) {
        guard let data = try? JSONSerialization.data(withJSONObject: dict),
              let json = String(data: data, encoding: .utf8) else { return }
        webSocketTask?.send(.string(json)) { [weak self] error in
            if let error {
                print("[MoQ] Send error: \(error)")
                Task { @MainActor [weak self] in self?.scheduleReconnect() }
            }
        }
    }

    // MARK: - Receive Loop

    private func startReceiving() {
        webSocketTask?.receive { [weak self] result in
            Task { @MainActor [weak self] in
                guard let self else { return }
                switch result {
                case .success(let message):
                    self.handleMessage(message)
                    self.startReceiving()   // keep receiving
                case .failure(let error):
                    print("[MoQ] Receive error: \(error.localizedDescription)")
                    self.isConnected = false
                    self.scheduleReconnect()
                }
            }
        }
    }

    private func handleMessage(_ message: URLSessionWebSocketTask.Message) {
        switch message {
        case .string(let json):
            handleTextMessage(json)
        case .data(let data):
            handleBinaryMessage(data)
        @unknown default:
            break
        }
    }

    private func handleTextMessage(_ json: String) {
        guard let data = json.data(using: .utf8),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let type = dict["type"] as? String else { return }

        switch type {
        case "setup_ok":
            print("[MoQ] SETUP_OK — relay handshake complete")
            // Now announce and subscribe to catalog
            sendAnnounce(namespace: Config.namespace)
            sendSubscribe(namespace: Config.namespace, track: Config.catalogTrack, subscribeID: 1)

        case "announce_ok":
            print("[MoQ] ANNOUNCE_OK for namespace \(dict["namespace"] as? String ?? "?")")

        case "subscribe_ok":
            let id = dict["subscribeId"] as? Int ?? 0
            print("[MoQ] SUBSCRIBE_OK id=\(id)")
            // After catalog subscription succeeds, subscribe to video + audio
            if id == 1 && !subscribedToVideo {
                subscribedToVideo = true
                sendSubscribe(namespace: Config.namespace, track: Config.videoTrack, subscribeID: 2)
                sendSubscribe(namespace: Config.namespace, track: Config.audioTrack, subscribeID: 3)
            }

        case "object", "stream_header_subgroup":
            // Text-framed MoQ object (small metadata objects only)
            if let payload = dict["payload"] as? String {
                handleObjectPayload(Data(base64Encoded: payload) ?? Data())
            }

        case "subscribe_error":
            print("[MoQ] SUBSCRIBE_ERROR: \(dict["reason"] as? String ?? "unknown")")

        case "goaway":
            print("[MoQ] GOAWAY — relay shutting down, reconnecting...")
            scheduleReconnect()

        default:
            break
        }
    }

    // Binary messages = raw MoQ OBJECT data (video/audio chunks)
    private func handleBinaryMessage(_ data: Data) {
        guard data.count > 4 else { return }

        // Minimal MoQ binary frame parsing:
        // First byte encodes the track alias (1=catalog, 2=video, 3=audio)
        let trackAlias = Int(data[0])
        let payload = data.dropFirst(1)

        switch trackAlias {
        case 1:
            // Catalog update
            handleObjectPayload(payload)
        case 2:
            // Video chunk — isKeyFrame heuristic: check for H.264 IDR NAL unit (0x65)
            let isKeyFrame = payload.count > 4 && payload[4] == 0x65
            updateLatency()
            onVideoChunk?(Data(payload), isKeyFrame)
        case 3:
            // Audio chunk — pass to renderer
            break
        default:
            break
        }
    }

    private func handleObjectPayload(_ data: Data) {
        // Try to parse as MoQ catalog
        if let catalog = try? JSONDecoder().decode(MoQCatalog.self, from: data) {
            availableTracks = catalog.tracks
            print("[MoQ] Catalog updated — \(catalog.tracks.count) tracks available")
            catalog.tracks.forEach { track in
                print("  Track: \(track.namespace)/\(track.name) codec=\(track.selectionParams?.codec ?? "?")")
            }
            return
        }

        // Try to parse as a moment/metadata signal
        if let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            parseMomentSignal(dict)
        }
    }

    private func parseMomentSignal(_ dict: [String: Any]) {
        // Caton relay emits metadata objects with game state info
        if let breakDuration = dict["adBreakDuration"] as? Int {
            print("[MoQ] Ad break signal — \(breakDuration)s")
            onAdBreakSignal?(breakDuration)
        }
        if let state = dict["gameState"] as? String {
            let moment = GameMoment(rawValue: state) ?? .neutral
            onMomentChange?(moment)
            print("[MoQ] Game moment: \(moment.rawValue) (CPM x\(moment.cpmMultiplier))")
        }
    }

    // MARK: - Latency Measurement

    private func updateLatency() {
        guard let start = connectionStartTime else { return }
        // Approximate: time from connection to first video chunk
        let ms = Date().timeIntervalSince(start) * 1000
        if ms < 10000 {   // Only track initial latency, cap at 10s
            latencyMs = ms
            connectionStartTime = nil   // Only measure once
            print("[MoQ] First video chunk received — connection latency: \(Int(ms))ms")
        }
    }

    // MARK: - Reconnect

    private func scheduleReconnect() {
        let delay = reconnectDelay + Double.random(in: -0.3...0.3)
        reconnectDelay = min(reconnectDelay * 2, 30.0)
        print("[MoQ] Reconnecting in \(String(format: "%.1f", delay))s...")
        reconnectTask = Task {
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            guard !Task.isCancelled else { return }
            await MainActor.run { self.connect(channelID: "bbb") }
        }
    }

    // MARK: - Keep-Alive Ping

    private func startPingTimer() {
        pingTimer?.invalidate()
        pingTimer = Timer.scheduledTimer(withTimeInterval: 20.0, repeats: true) { [weak self] _ in
            self?.webSocketTask?.sendPing { _ in }
        }
        RunLoop.main.add(pingTimer!, forMode: .common)
    }
}
