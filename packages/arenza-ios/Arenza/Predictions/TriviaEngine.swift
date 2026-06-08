// TriviaEngine.swift — Arenza (Phase 4: Game Formats)
// Sport-specific trivia quiz packs triggered during halftime.
// Correct answers earn AZT on a difficulty scale: Easy=10, Medium=25, Hard=50.
// Three wrong answers ends the streak; a 5-correct streak earns a 2× bonus.

import Foundation
import Combine

// MARK: - Trivia Models

struct TriviaQuestion: Codable, Identifiable {
    let id: UUID
    let questionText: String
    let options: [TriviaOption]
    let correctOptionId: String
    let difficulty: TriviaDifficulty
    let sport: String?                  // nil = general sports
    let sponsorId: String?
    let sponsorName: String?
    let aztReward: Int                  // base reward (difficulty multiplied in engine)

    var adjustedReward: Int { Int(Double(aztReward) * difficulty.multiplier) }
}

struct TriviaOption: Codable, Identifiable {
    let id: String
    let label: String
}

enum TriviaDifficulty: String, Codable {
    case easy   = "easy"
    case medium = "medium"
    case hard   = "hard"

    var label: String { rawValue.capitalized }
    var multiplier: Double {
        switch self { case .easy: return 1.0; case .medium: return 2.5; case .hard: return 5.0 }
    }
    var color: String {
        switch self { case .easy: return "green"; case .medium: return "orange"; case .hard: return "red" }
    }
}

struct TriviaSession: Identifiable {
    let id: UUID
    var questions: [TriviaQuestion]
    var currentIndex: Int = 0
    var correctCount: Int = 0
    var wrongCount: Int = 0
    var totalAZTEarned: Int = 0
    var isComplete: Bool { currentIndex >= questions.count || wrongCount >= 3 }
    var currentQuestion: TriviaQuestion? {
        guard currentIndex < questions.count else { return nil }
        return questions[currentIndex]
    }
}

// MARK: - Trivia Engine

@MainActor
final class TriviaEngine: ObservableObject {
    static let shared = TriviaEngine()

    @Published var activeSession: TriviaSession?
    @Published var lastAnswerCorrect: Bool?
    @Published var sessionComplete: Bool = false

    let sessionCompletePublisher = PassthroughSubject<TriviaSession, Never>()

    private var cancellables = Set<AnyCancellable>()

    private init() {
        // Trigger trivia during halftime only
        ContextualMomentService.shared.momentPublisher
            .receive(on: DispatchQueue.main)
            .filter { $0 == .halftime }
            .filter { [weak self] _ in self?.activeSession == nil }
            .sink { [weak self] _ in
                Task { await self?.startDemoSession() }
            }
            .store(in: &cancellables)
    }

    // MARK: - Start session

    func startSession(questions: [TriviaQuestion]) {
        activeSession = TriviaSession(id: UUID(), questions: questions)
        sessionComplete = false
        lastAnswerCorrect = nil
    }

    func startDemoSession() async {
        let q = TriviaQuestion.demoQuestions.shuffled().prefix(5)
        startSession(questions: Array(q))
    }

    // MARK: - Answer

    func submitAnswer(optionId: String) {
        guard var session = activeSession,
              let question = session.currentQuestion else { return }

        let correct = optionId == question.correctOptionId
        lastAnswerCorrect = correct

        if correct {
            let earned = question.adjustedReward
            session.correctCount += 1
            session.totalAZTEarned += earned
            PredictionEngine.shared.wallet.earn(earned, source: .trivia, gameId: session.id.uuidString)
            PredictionEngine.shared.saveWallet()
            print("[Trivia] ✅ Correct! +\(earned) AZT")
        } else {
            session.wrongCount += 1
            print("[Trivia] ❌ Wrong (\(session.wrongCount)/3 lives)")
        }

        session.currentIndex += 1

        // Streak bonus: 5 correct in a row = extra 100 AZT
        if session.correctCount == 5 && session.wrongCount == 0 {
            PredictionEngine.shared.wallet.earn(100, source: .streakBonus)
            PredictionEngine.shared.saveWallet()
            print("[Trivia] 🔥 Perfect 5-streak! +100 AZT bonus")
        }

        activeSession = session

        // Auto-advance after 1.2s
        Task {
            try? await Task.sleep(nanoseconds: 1_200_000_000)
            lastAnswerCorrect = nil
            if session.isComplete {
                finishSession()
            }
        }
    }

    private func finishSession() {
        guard let session = activeSession else { return }
        sessionComplete = true
        sessionCompletePublisher.send(session)
        print("[Trivia] Session done — \(session.correctCount)/\(session.questions.count) correct — \(session.totalAZTEarned) AZT earned")

        Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            activeSession = nil
            sessionComplete = false
        }
    }

    func dismissSession() {
        activeSession = nil
        sessionComplete = false
        lastAnswerCorrect = nil
    }
}

// MARK: - Demo Trivia Questions

extension TriviaQuestion {
    static let demoQuestions: [TriviaQuestion] = [
        TriviaQuestion(
            id: UUID(), questionText: "How many points is a touchdown worth in the NFL?",
            options: [
                TriviaOption(id: "a", label: "3"), TriviaOption(id: "b", label: "6"),
                TriviaOption(id: "c", label: "7"), TriviaOption(id: "d", label: "2"),
            ],
            correctOptionId: "b", difficulty: .easy, sport: "NFL",
            sponsorId: nil, sponsorName: nil, aztReward: 10
        ),
        TriviaQuestion(
            id: UUID(), questionText: "What does 'MVP' stand for?",
            options: [
                TriviaOption(id: "a", label: "Most Valuable Player"),
                TriviaOption(id: "b", label: "Maximum Victory Points"),
                TriviaOption(id: "c", label: "Most Versatile Performer"),
                TriviaOption(id: "d", label: "Major Victory Player"),
            ],
            correctOptionId: "a", difficulty: .easy, sport: nil,
            sponsorId: nil, sponsorName: nil, aztReward: 10
        ),
        TriviaQuestion(
            id: UUID(), questionText: "In basketball, how long is a standard NBA quarter?",
            options: [
                TriviaOption(id: "a", label: "10 minutes"), TriviaOption(id: "b", label: "12 minutes"),
                TriviaOption(id: "c", label: "15 minutes"), TriviaOption(id: "d", label: "8 minutes"),
            ],
            correctOptionId: "b", difficulty: .medium, sport: "NBA",
            sponsorId: nil, sponsorName: nil, aztReward: 10
        ),
        TriviaQuestion(
            id: UUID(), questionText: "Which team has won the most Super Bowls?",
            options: [
                TriviaOption(id: "a", label: "New England Patriots"),
                TriviaOption(id: "b", label: "Pittsburgh Steelers"),
                TriviaOption(id: "c", label: "San Francisco 49ers"),
                TriviaOption(id: "d", label: "Dallas Cowboys"),
            ],
            correctOptionId: "a", difficulty: .medium, sport: "NFL",
            sponsorId: nil, sponsorName: nil, aztReward: 10
        ),
        TriviaQuestion(
            id: UUID(), questionText: "What is the maximum break score in snooker?",
            options: [
                TriviaOption(id: "a", label: "147"), TriviaOption(id: "b", label: "155"),
                TriviaOption(id: "c", label: "180"), TriviaOption(id: "d", label: "200"),
            ],
            correctOptionId: "a", difficulty: .hard, sport: "Snooker",
            sponsorId: nil, sponsorName: nil, aztReward: 10
        ),
        TriviaQuestion(
            id: UUID(), questionText: "In soccer, how many players are on a team including the goalkeeper?",
            options: [
                TriviaOption(id: "a", label: "10"), TriviaOption(id: "b", label: "11"),
                TriviaOption(id: "c", label: "12"), TriviaOption(id: "d", label: "9"),
            ],
            correctOptionId: "b", difficulty: .easy, sport: "Soccer",
            sponsorId: nil, sponsorName: nil, aztReward: 10
        ),
    ]
}
