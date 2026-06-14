// SponsorQuizEngine.swift — Arenza (ArenzaTV Prototype)
// Coordinates sponsor-business quiz sessions during game breaks.
// When a MatchSim "sponsor_quiz" event fires, this engine loads the
// appropriate TriviaQuestionPack and drives a short quiz session
// that awards AZT + unlocks sponsor coupons.
//
// Key insight from the discussion document: viewers learn about the
// sponsor's business while earning points — the unique value prop
// that local businesses will pay for.

import Foundation
import Combine

// MARK: - Sponsor Quiz Session

struct SponsorQuizSession: Identifiable {
    let id: UUID
    let sponsorId: String
    let sponsorName: String
    let sponsorEmoji: String
    let sponsorBrandColor: String
    let pack: TriviaQuestionPack
    var questions: [TriviaQuestion]
    var currentIndex: Int = 0
    var correctCount: Int = 0
    var totalAZTEarned: Int = 0
    var isComplete: Bool { currentIndex >= questions.count }

    var currentQuestion: TriviaQuestion? {
        guard currentIndex < questions.count else { return nil }
        return questions[currentIndex]
    }

    var isPerfect: Bool { correctCount == questions.count && isComplete }

    /// AZT bonus for perfect score
    static let perfectBonus = 75
}

// MARK: - Sponsor Quiz Engine

@MainActor
final class SponsorQuizEngine: ObservableObject {
    static let shared = SponsorQuizEngine()

    @Published var activeSession: SponsorQuizSession?
    @Published var lastAnswerCorrect: Bool?
    @Published var sessionComplete: Bool = false
    @Published var couponUnlocked: SponsorCoupon?

    let sessionCompletePublisher = PassthroughSubject<SponsorQuizSession, Never>()

    private init() {}

    // MARK: - Start a quiz for a sponsor

    func startQuiz(sponsorId: String) {
        guard activeSession == nil else { return }

        // Look up pack from demo registry
        guard let pack = TriviaQuestionPack.demoPacks[sponsorId] else {
            print("[SponsorQuiz] No question pack found for sponsor: \(sponsorId)")
            return
        }

        // Resolve sponsor info from SponsorBusiness catalog
        let business = SponsorBusiness.all.first { $0.id == sponsorId }

        let session = SponsorQuizSession(
            id: UUID(),
            sponsorId: sponsorId,
            sponsorName: pack.sponsorName ?? business?.name ?? sponsorId.capitalized,
            sponsorEmoji: business?.emoji ?? "🏢",
            sponsorBrandColor: business?.brandColor ?? "#ff6b35",
            pack: pack,
            questions: pack.sessionQuestions()
        )

        activeSession = session
        sessionComplete = false
        lastAnswerCorrect = nil
        couponUnlocked = nil

        print("[SponsorQuiz] Started quiz for \(session.sponsorName) — \(session.questions.count) questions")
    }

    // MARK: - Submit answer

    func submitAnswer(optionId: String) {
        guard var session = activeSession,
              let question = session.currentQuestion else { return }

        let correct = optionId == question.correctOptionId
        lastAnswerCorrect = correct

        if correct {
            let earned = question.aztReward > 0 ? question.aztReward : 15
            session.correctCount += 1
            session.totalAZTEarned += earned

            // Award AZT through the central wallet
            PredictionEngine.shared.wallet.earn(
                earned,
                source: .sponsorQuiz,
                sponsorId: session.sponsorId
            )
            PredictionEngine.shared.saveWallet()

            // Enrich AI profile with sponsor engagement signal
            ProfileEngine.shared.ingestPredictionResult(
                category: .trivia,
                isCorrect: true,
                timeToAnswerSeconds: 5.0,
                currentStreak: session.correctCount
            )

            print("[SponsorQuiz] ✅ Correct! +\(earned) AZT for \(session.sponsorName)")
        } else {
            print("[SponsorQuiz] ❌ Wrong answer")
        }

        session.currentIndex += 1
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

    // MARK: - Finish session

    private func finishSession() {
        guard var session = activeSession else { return }

        // Perfect score bonus
        if session.isPerfect {
            let bonus = SponsorQuizSession.perfectBonus
            session.totalAZTEarned += bonus
            PredictionEngine.shared.wallet.earn(
                bonus,
                source: .sponsorQuiz,
                sponsorId: session.sponsorId
            )
            PredictionEngine.shared.saveWallet()
            print("[SponsorQuiz] 🔥 Perfect score! +\(bonus) AZT bonus")
        }

        // Check if quiz unlocks a sponsor coupon (at ≥ 3/5 correct)
        if session.correctCount >= 3 {
            let coupon = generateSponsorCoupon(for: session)
            couponUnlocked = coupon
            PredictionEngine.shared.wallet.availableCoupons.append(coupon)
            PredictionEngine.shared.saveWallet()
            print("[SponsorQuiz] 🎟️ Coupon unlocked: \(coupon.description)")
        }

        activeSession = session
        sessionComplete = true
        sessionCompletePublisher.send(session)

        print("[SponsorQuiz] Session done — \(session.correctCount)/\(session.questions.count) correct — \(session.totalAZTEarned) AZT earned")

        // Auto-dismiss after 3s
        Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            activeSession = nil
            sessionComplete = false
            couponUnlocked = nil
        }
    }

    // MARK: - Coupon generation

    private func generateSponsorCoupon(for session: SponsorQuizSession) -> SponsorCoupon {
        let discountPercent = session.isPerfect ? 20 : 10
        return SponsorCoupon(
            id: UUID(),
            sponsorID: session.sponsorId,
            sponsorName: session.sponsorName,
            sponsorLogoURL: nil,
            description: "\(discountPercent)% off at \(session.sponsorName)",
            couponCode: "\(session.sponsorId.prefix(4).uppercased())-\(String(UUID().uuidString.prefix(6)))",
            deepLinkURL: nil,
            sponsorWebURL: URL(string: "https://\(session.sponsorId).example.com"),
            expiresAt: Date().addingTimeInterval(7 * 86400),  // 7-day expiry
            minimumPurchase: nil,
            maximumDiscount: nil,
            category: .food,
            aztCost: 0,  // free — earned through quiz
            isRedeemed: false,
            redeemedAt: nil,
            unlockedAt: Date()
        )
    }

    // MARK: - Dismiss

    func dismissSession() {
        activeSession = nil
        sessionComplete = false
        lastAnswerCorrect = nil
        couponUnlocked = nil
    }
}
