// PredictionEngine.swift — Arenza (C4: Prediction Engine)
// Coordinates the play-to-earn prediction game lifecycle:
//   SCTE-35 trigger → fetch question → overlay → submission → resolution → points → coupon check

import Foundation
import Combine

// MARK: - Prediction API Client (CMXS backend)

actor PredictionAPIClient {
    static let shared = PredictionAPIClient()
    private let session = URLSession.shared

    private init() {}

    func fetchNextQuestion(channelID: String, triggerMoment: GameMoment) async -> PredictionQuestion? {
        guard let url = URL(string: "\(CMXSConfig.apiBase)/v1/predictions/next?channelId=\(channelID)&triggerType=\(triggerMoment.rawValue.lowercased())") else { return nil }

        if let (data, _) = try? await session.data(from: url),
           let question = try? JSONDecoder().decode(PredictionQuestion.self, from: data) {
            return question
        }

        // Demo question when backend not available
        return PredictionAPIClient.demoQuestion(channelID: channelID)
    }

    func submitAnswer(questionID: UUID, optionID: String, streakMultiplier: Float) async throws -> String {
        guard let url = URL(string: "\(CMXSConfig.apiBase)/v1/predictions/\(questionID)/answer") else {
            throw CMXSAPIError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = ["optionId": optionID, "submittedAt": Date().timeIntervalSince1970, "streakMultiplier": streakMultiplier]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        let (_, _) = try await session.data(for: request)
        return "pending"
    }

    func pollResolution(questionID: UUID) async -> PredictionResolution? {
        guard let url = URL(string: "\(CMXSConfig.apiBase)/v1/predictions/\(questionID)/resolution") else { return nil }
        if let (data, _) = try? await session.data(from: url),
           let resolution = try? JSONDecoder().decode(PredictionResolution.self, from: data) {
            return resolution
        }
        // Demo resolution (correct 60% of time for testing)
        return PredictionAPIClient.demoResolution(questionID: questionID)
    }

    func fetchWallet() async -> RewardsWallet? {
        guard let url = URL(string: "\(CMXSConfig.apiBase)/v1/wallet") else { return nil }
        return (try? await session.data(from: url)).flatMap { try? JSONDecoder().decode(RewardsWallet.self, from: $0.0) }
    }

    func checkCouponUnlock(seasonPoints: Int, tier: RewardsTier) async -> SponsorCoupon? {
        guard let url = URL(string: "\(CMXSConfig.apiBase)/v1/rewards/check-unlock?seasonPoints=\(seasonPoints)&tier=\(tier.rawValue)") else { return nil }
        return (try? await session.data(from: url)).flatMap { try? JSONDecoder().decode(SponsorCoupon.self, from: $0.0) }
    }

    // MARK: - Demo data

    static func demoQuestion(channelID: String) -> PredictionQuestion {
        PredictionQuestion(
            id: UUID(),
            gameID: "demo_game",
            channelID: channelID,
            triggerMoment: .timeout,
            questionText: "Who will score next?",
            options: [
                PredictionOption(id: "home", label: "Home Team", iconURL: nil, impliedProbability: 0.52),
                PredictionOption(id: "away", label: "Away Team", iconURL: nil, impliedProbability: 0.38),
                PredictionOption(id: "none", label: "No Score", iconURL: nil, impliedProbability: 0.10)
            ],
            timeWindowSeconds: 30,
            pointValue: 100,
            difficultyMultiplier: 1.2,
            sponsorID: "modelo",
            sponsorName: "Modelo",
            sponsorLogoURL: nil,
            expiresAt: Date().addingTimeInterval(30),
            category: .nextScore
        )
    }

    static func demoResolution(questionID: UUID) -> PredictionResolution {
        let isCorrect = Double.random(in: 0...1) < 0.6  // 60% correct for demo
        return PredictionResolution(
            questionID: questionID,
            correctOptionID: isCorrect ? "home" : "away",
            isCorrect: isCorrect,
            basePoints: 100,
            streakMultiplier: 1.0,
            resolvedAt: Date()
        )
    }
}

// MARK: - Prediction Engine (Main Coordinator)

@MainActor
final class PredictionEngine: ObservableObject {

    static let shared = PredictionEngine()

    @Published var activePrediction: PredictionQuestion?
    @Published var wallet: RewardsWallet = .empty
    @Published var pendingUnlock: SponsorCoupon?
    @Published var leaderboardRank: Int?

    let resolutionPublisher = PassthroughSubject<PredictionResolution, Never>()
    let couponUnlockPublisher = PassthroughSubject<SponsorCoupon, Never>()

    private var pendingPredictions: [UUID: UserPrediction] = [:]
    private var cancellables = Set<AnyCancellable>()
    private var resolutionPollingTask: Task<Void, Never>?

    private init() {
        // Subscribe to contextual moments for auto-triggering
        ContextualMomentService.shared.momentPublisher
            .filter { $0.isPredictionTrigger }
            .sink { [weak self] moment in
                Task { await self?.onMomentTrigger(moment) }
            }
            .store(in: &cancellables)

        Task { await loadWallet() }
    }

    // MARK: - Triggered by ContextualMomentService or AdBreakDetector

    func onMomentTrigger(_ moment: GameMoment, channelID: String = "current") async {
        guard activePrediction == nil else { return }  // don't stack overlays
        let question = await PredictionAPIClient.shared.fetchNextQuestion(
            channelID: channelID,
            triggerMoment: moment
        )
        if let q = question, !q.isExpired {
            activePrediction = q
            wallet.pendingAZT += q.adjustedPoints
        }
    }

    // MARK: - User submits a prediction answer

    func submitPrediction(questionID: UUID, optionID: String) {
        guard let question = activePrediction, question.id == questionID else { return }

        let prediction = UserPrediction(
            id: UUID(),
            questionID: questionID,
            selectedOptionID: optionID,
            submittedAt: Date(),
            streakMultiplierApplied: streakMultiplier
        )
        pendingPredictions[questionID] = prediction
        SignalCollector.shared.recordPredictionResult(correct: false)  // will be updated on resolution

        Task {
            _ = try? await PredictionAPIClient.shared.submitAnswer(
                questionID: questionID,
                optionID: optionID,
                streakMultiplier: streakMultiplier
            )
            // Poll for resolution after 30s (next game action)
            startResolutionPolling(for: questionID)
        }
    }

    // MARK: - Dismiss active prediction (timed out)

    func dismissActivePrediction() {
        wallet.pendingAZT = max(0, wallet.pendingAZT - (activePrediction?.adjustedPoints ?? 0))
        activePrediction = nil
    }

    // MARK: - Resolution handling

    private func startResolutionPolling(for questionID: UUID) {
        resolutionPollingTask?.cancel()
        resolutionPollingTask = Task {
            // Poll every 5s for up to 3 minutes
            for _ in 0..<36 {
                try? await Task.sleep(nanoseconds: 5_000_000_000)
                guard !Task.isCancelled else { return }

                if let resolution = await PredictionAPIClient.shared.pollResolution(questionID: questionID) {
                    await MainActor.run { self.onResolution(resolution) }
                    return
                }
            }
        }
    }

    private func onResolution(_ resolution: PredictionResolution) {
        resolutionPublisher.send(resolution)

        // Update wallet
        wallet.applyResolution(resolution)

        // Update pending prediction record
        pendingPredictions[resolution.questionID]?.isCorrect = resolution.isCorrect
        pendingPredictions[resolution.questionID]?.pointsEarned = resolution.totalPoints

        // Enrich AI profile
        if let question = activePrediction {
            ProfileEngine.shared.ingestPredictionResult(
                category: question.category,
                isCorrect: resolution.isCorrect,
                timeToAnswerSeconds: pendingPredictions[resolution.questionID]?.timeToAnswerSeconds ?? 10,
                currentStreak: wallet.currentStreak
            )
        }

        // Signal collector
        SignalCollector.shared.recordPredictionResult(correct: resolution.isCorrect)

        // Check for coupon unlock
        Task { await checkCouponUnlock() }

        // Clear active
        activePrediction = nil
    }

    // MARK: - Coupon unlock check

    func checkCouponUnlock() async {
        if let coupon = await PredictionAPIClient.shared.checkCouponUnlock(
            seasonPoints: wallet.seasonAZT,
            tier: wallet.tier
        ) {
            wallet.availableCoupons.append(coupon)
            pendingUnlock = coupon
            couponUnlockPublisher.send(coupon)
        }

        // Demo: unlock a coupon at 100+ season points
        #if DEBUG
        if wallet.seasonAZT >= 100 && wallet.availableCoupons.isEmpty {
            let demo = SponsorCoupon.demo()
            wallet.availableCoupons.append(demo)
            pendingUnlock = demo
            couponUnlockPublisher.send(demo)
        }
        #endif
    }

    // MARK: - Wallet persistence

    private func loadWallet() async {
        if let serverWallet = await PredictionAPIClient.shared.fetchWallet() {
            wallet = serverWallet
        }
        // Load from UserDefaults as cache
        if let data = UserDefaults.standard.data(forKey: "arenza.wallet"),
           let saved = try? JSONDecoder().decode(RewardsWallet.self, from: data) {
            wallet = saved
        }
        // Perform daily check-in on each app launch
        let bonus = wallet.performDailyCheckIn()
        if bonus > 0 {
            print("[AZT] Daily check-in: +\(bonus) AZT")
            saveWallet()
        }
    }

    func saveWallet() {
        if let data = try? JSONEncoder().encode(wallet) {
            UserDefaults.standard.set(data, forKey: "arenza.wallet")
        }
    }

    // MARK: - Streak multiplier

    var streakMultiplier: Float {
        switch wallet.currentStreak {
        case 0...2:  return 1.0
        case 3...5:  return 1.5
        case 6...9:  return 2.0
        default:     return 3.0
        }
    }
}
