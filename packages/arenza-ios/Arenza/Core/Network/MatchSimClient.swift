// MatchSimClient.swift — Arenza (ArenzaTV Prototype)
// WebSocket + REST client for the MatchSim demo backend.
// Falls back to the hardcoded MatchTimeline.eaglesBears when the server is unavailable.

import Foundation
import Combine

// MARK: - MatchSim Client

@MainActor
final class MatchSimClient: ObservableObject, MatchEventProviding {

    static let shared = MatchSimClient()

    // MARK: - Published state

    @Published private(set) var isConnected = false
    @Published private(set) var timeline: MatchTimeline?

    // MARK: - Protocol conformance

    private let _eventSubject = PassthroughSubject<MatchEvent, Never>()
    private let _timelineSubject = PassthroughSubject<MatchTimeline, Never>()

    var eventPublisher: AnyPublisher<MatchEvent, Never> { _eventSubject.eraseToAnyPublisher() }
    var timelinePublisher: AnyPublisher<MatchTimeline, Never> { _timelineSubject.eraseToAnyPublisher() }

    // MARK: - Internal

    private var webSocketTask: URLSessionWebSocketTask?
    private var reconnectAttempts = 0
    private let maxReconnectAttempts = 3
    private let baseURL: String

    private init() {
        // MatchSim server URL — configurable via environment
        self.baseURL = ProcessInfo.processInfo.environment["MATCHSIM_URL"]
            ?? "ws://localhost:3001"
    }

    // MARK: - Connect

    func connect(matchId: String) async {
        // Try WebSocket connection to MatchSim server
        guard let url = URL(string: "\(baseURL)/ws/match/\(matchId)") else {
            fallbackToLocal(matchId: matchId)
            return
        }

        let session = URLSession(configuration: .default)
        webSocketTask = session.webSocketTask(with: url)
        webSocketTask?.resume()

        // Start receiving messages
        Task { await receiveLoop() }

        // Wait briefly to see if connection succeeds
        try? await Task.sleep(nanoseconds: 2_000_000_000)

        if !isConnected {
            print("[MatchSim] WebSocket connection failed — using local fallback")
            fallbackToLocal(matchId: matchId)
        }
    }

    func disconnect() {
        webSocketTask?.cancel(with: .normalClosure, reason: nil)
        webSocketTask = nil
        isConnected = false
    }

    // MARK: - WebSocket receive loop

    private func receiveLoop() async {
        guard let task = webSocketTask else { return }

        do {
            let message = try await task.receive()
            isConnected = true
            reconnectAttempts = 0

            switch message {
            case .string(let text):
                if let data = text.data(using: .utf8) {
                    handleMessage(data)
                }
            case .data(let data):
                handleMessage(data)
            @unknown default:
                break
            }

            // Continue receiving
            await receiveLoop()
        } catch {
            isConnected = false
            print("[MatchSim] WebSocket error: \(error.localizedDescription)")

            // Attempt reconnect
            if reconnectAttempts < maxReconnectAttempts {
                reconnectAttempts += 1
                try? await Task.sleep(nanoseconds: UInt64(reconnectAttempts) * 2_000_000_000)
                if let matchId = timeline?.matchId {
                    await connect(matchId: matchId)
                }
            }
        }
    }

    private func handleMessage(_ data: Data) {
        // Try to decode as a single MatchEvent
        if let event = try? JSONDecoder().decode(MatchEvent.self, from: data) {
            _eventSubject.send(event)
            return
        }

        // Try to decode as a full MatchTimeline
        if let tl = try? JSONDecoder().decode(MatchTimeline.self, from: data) {
            timeline = tl
            _timelineSubject.send(tl)
            return
        }

        print("[MatchSim] Could not decode message: \(String(data: data, encoding: .utf8) ?? "?")")
    }

    // MARK: - Local fallback (no server needed for demo)

    private func fallbackToLocal(matchId: String) {
        let tl = MatchTimeline.eaglesBears
        timeline = tl
        _timelineSubject.send(tl)
        isConnected = true  // "connected" to local data

        // Replay events on a timer (simulates WebSocket pushes)
        Task { await replayTimeline(tl) }
    }

    private func replayTimeline(_ tl: MatchTimeline) async {
        let sorted = tl.events.sorted { $0.at < $1.at }
        var elapsed = 0

        while elapsed <= tl.durationSeconds {
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            elapsed += 1

            // Fire any events at this timestamp
            for event in sorted where event.at == elapsed {
                _eventSubject.send(event)
            }

            // Loop the timeline for continuous demo
            if elapsed >= tl.durationSeconds {
                elapsed = 0
            }
        }
    }

    // MARK: - REST API helpers

    /// Fetch trivia pack for a team from MatchSim API
    func fetchTriviaPack(teamId: String) async -> TriviaQuestionPack? {
        // Try server first
        let urlStr = baseURL.replacingOccurrences(of: "ws://", with: "http://")
            .replacingOccurrences(of: "wss://", with: "https://")
        guard let url = URL(string: "\(urlStr)/api/trivia/\(teamId)") else { return nil }

        if let (data, _) = try? await URLSession.shared.data(from: url),
           let pack = try? JSONDecoder().decode(TriviaQuestionPack.self, from: data) {
            return pack
        }

        // Fallback to local demo packs
        return TriviaQuestionPack.demoPacks["\(teamId)_history"]
    }

    /// Fetch sponsor quiz pack from MatchSim API
    func fetchSponsorQuiz(sponsorId: String) async -> TriviaQuestionPack? {
        let urlStr = baseURL.replacingOccurrences(of: "ws://", with: "http://")
            .replacingOccurrences(of: "wss://", with: "https://")
        guard let url = URL(string: "\(urlStr)/api/sponsor/\(sponsorId)/quiz") else { return nil }

        if let (data, _) = try? await URLSession.shared.data(from: url),
           let pack = try? JSONDecoder().decode(TriviaQuestionPack.self, from: data) {
            return pack
        }

        return TriviaQuestionPack.demoPacks[sponsorId]
    }
}
