// PollEngine.swift — Arenza (Phase 4: Game Formats)
// Sponsor-branded polls triggered during game breaks.
// Each vote earns 5 AZT. Polls are non-predictive (no right/wrong answer).
// Results display live vote percentages after submission.

import Foundation
import Combine

// MARK: - Poll Models

struct SponsorPoll: Codable, Identifiable {
    let id: UUID
    let sponsorId: String?
    let sponsorName: String?
    let question: String
    let options: [PollOption]
    let durationSeconds: Int
    let aztReward: Int              // AZT awarded just for voting (default: 5)
    let category: PollCategory
    let expiresAt: Date
    var isExpired: Bool { expiresAt < Date() }
}

struct PollOption: Codable, Identifiable {
    let id: String
    let label: String
    let emoji: String?
}

struct PollResult: Codable {
    let pollId: UUID
    let selectedOptionId: String
    let finalTally: [String: Int]   // optionId → vote count
    var totalVotes: Int { finalTally.values.reduce(0, +) }
    func percentage(for optionId: String) -> Double {
        let votes = Double(finalTally[optionId] ?? 0)
        return totalVotes > 0 ? votes / Double(totalVotes) : 0
    }
}

enum PollCategory: String, Codable {
    case gamePlay   = "game_play"
    case mvp        = "mvp"
    case prediction = "prediction"
    case fun        = "fun"
    case brand      = "brand"       // sponsor-specific
}

// MARK: - Poll Engine

@MainActor
final class PollEngine: ObservableObject {
    static let shared = PollEngine()

    @Published var activePoll: SponsorPoll?
    @Published var pendingResult: PollResult?

    let pollPublisher = PassthroughSubject<SponsorPoll, Never>()
    let resultPublisher = PassthroughSubject<PollResult, Never>()

    private var cancellables = Set<AnyCancellable>()

    private init() {
        // Trigger polls on game moments that aren't already used for predictions
        ContextualMomentService.shared.momentPublisher
            .receive(on: DispatchQueue.main)
            .filter { [weak self] m in
                m.isPollTrigger && self?.activePoll == nil
            }
            .sink { [weak self] _ in
                Task { await self?.triggerDemoPoll() }
            }
            .store(in: &cancellables)
    }

    // MARK: - Trigger

    func triggerPoll(_ poll: SponsorPoll) {
        guard !poll.isExpired, activePoll == nil else { return }
        activePoll = poll
        pollPublisher.send(poll)
    }

    func triggerDemoPoll() async {
        let demos = SponsorPoll.demoPolls
        guard let poll = demos.randomElement() else { return }
        triggerPoll(poll)
    }

    // MARK: - Submit vote

    func submitVote(pollId: UUID, optionId: String) {
        guard activePoll?.id == pollId else { return }

        // Award AZT for voting
        let reward = activePoll?.aztReward ?? 5
        PredictionEngine.shared.wallet.earn(reward, source: .poll)
        PredictionEngine.shared.saveWallet()
        print("[Poll] +\(reward) AZT for voting")

        // Build demo result (real percentages would come from server)
        let options = activePoll?.options ?? []
        var tally: [String: Int] = [:]
        for opt in options {
            tally[opt.id] = opt.id == optionId
                ? Int.random(in: 55...70)   // selected option gets majority
                : Int.random(in: 8...25)
        }
        let result = PollResult(pollId: pollId, selectedOptionId: optionId, finalTally: tally)
        pendingResult = result
        resultPublisher.send(result)

        // Post to backend (non-blocking)
        Task { await submitVoteToBackend(pollId: pollId, optionId: optionId) }

        // Auto-clear after 4s
        Task {
            try? await Task.sleep(nanoseconds: 4_000_000_000)
            activePoll = nil
            pendingResult = nil
        }
    }

    func dismissActivePoll() {
        activePoll = nil
        pendingResult = nil
    }

    private func submitVoteToBackend(pollId: UUID, optionId: String) async {
        guard let url = URL(string: "\(CMXSConfig.apiBase)/v1/polls/\(pollId)/vote") else { return }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try? JSONSerialization.data(withJSONObject: ["optionId": optionId])
        _ = try? await URLSession.shared.data(for: req)
    }
}

// MARK: - GameMoment poll trigger extension

extension GameMoment {
    var isPollTrigger: Bool {
        switch self {
        case .halftime, .preGame, .postGame: return true
        default: return false
        }
    }
}

// MARK: - Demo Polls

extension SponsorPoll {
    static let demoPolls: [SponsorPoll] = [
        SponsorPoll(
            id: UUID(), sponsorId: "modelo", sponsorName: "Modelo",
            question: "Who is the MVP of the first half?",
            options: [
                PollOption(id: "a", label: "Home QB", emoji: "🏈"),
                PollOption(id: "b", label: "Away RB", emoji: "💨"),
                PollOption(id: "c", label: "Home WR", emoji: "⚡️"),
                PollOption(id: "d", label: "Away DB", emoji: "🛡️"),
            ],
            durationSeconds: 20, aztReward: 5,
            category: .mvp,
            expiresAt: Date().addingTimeInterval(20)
        ),
        SponsorPoll(
            id: UUID(), sponsorId: nil, sponsorName: nil,
            question: "Who wins this game?",
            options: [
                PollOption(id: "home", label: "Home Team", emoji: "🏠"),
                PollOption(id: "away", label: "Away Team", emoji: "✈️"),
                PollOption(id: "ot", label: "Goes to OT", emoji: "⏰"),
            ],
            durationSeconds: 25, aztReward: 5,
            category: .prediction,
            expiresAt: Date().addingTimeInterval(25)
        ),
        SponsorPoll(
            id: UUID(), sponsorId: "dominos", sponsorName: "Domino's",
            question: "Best halftime snack?",
            options: [
                PollOption(id: "pizza", label: "Pizza 🍕", emoji: nil),
                PollOption(id: "wings", label: "Wings 🍗", emoji: nil),
                PollOption(id: "nachos", label: "Nachos 🧀", emoji: nil),
                PollOption(id: "chips", label: "Chips & Dip", emoji: nil),
            ],
            durationSeconds: 20, aztReward: 5,
            category: .brand,
            expiresAt: Date().addingTimeInterval(20)
        ),
    ]
}
