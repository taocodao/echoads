// InteractiveAdEngine.swift — Arenza
// Auto-cycling carousel engine for the middle interactive ad panel.
// Cycles: Prediction → Bingo → Scratch & Win → More or Less every 15s.
// Pauses on user interaction, resumes after timeout.

import Foundation
import SwiftUI
import Combine

// MARK: - Scratch Card Models

struct ScratchCard: Identifiable {
    let id: Int
    let prize: ScratchPrize
    var isRevealed: Bool = false
}

enum ScratchPrize {
    case coupon(label: String, code: String, description: String, points: Int)
    case loss(points: Int)
    
    var points: Int {
        switch self {
        case .coupon(_, _, _, let pts): return pts
        case .loss(let pts): return pts
        }
    }
    
    var isWin: Bool {
        if case .coupon = self { return true }
        return false
    }
}

struct CouponCode: Identifiable {
    let id = UUID()
    let brand: String
    let code: String
    let description: String
    let expiresIn: String
}

// MARK: - More or Less Models

struct MLPlayerCard: Identifiable {
    let id: Int
    let emoji: String
    let name: String
    let team: String
    let stat: String
    let line: Double
    let description: String
}

enum PickDirection: Equatable { case more, less }

// MARK: - Interactive Ad Engine

@MainActor
final class InteractiveAdEngine: ObservableObject {
    
    enum AdFormat: Int, CaseIterable, Hashable {
        case prediction = 0
        case bingo      = 1
        case scratch    = 2
        case moreLess   = 3
        
        var title: String {
            switch self {
            case .prediction: return "🏈 Live Prediction"
            case .bingo:      return "🎲 Bingo Card"
            case .scratch:    return "🎟️ Scratch & Win"
            case .moreLess:   return "📊 More or Less"
            }
        }
        
        var sponsor: String {
            switch self {
            case .prediction: return "Pepsi"
            case .bingo:      return "Budweiser"
            case .scratch:    return "Domino's"
            case .moreLess:   return "Gatorade"
            }
        }
        
        var sponsorEmoji: String {
            switch self {
            case .prediction: return "🥤"
            case .bingo:      return "🍻"
            case .scratch:    return "🍕"
            case .moreLess:   return "💪"
            }
        }
        
        var accentColor: Color {
            switch self {
            case .prediction: return Color(arenza: "#00c9b1")
            case .bingo:      return Color(arenza: "#ffc107")
            case .scratch:    return Color(arenza: "#ff6b35")
            case .moreLess:   return Color(arenza: "#22c55e")
            }
        }
    }
    
    // MARK: - Published State
    
    @Published var currentFormat: AdFormat = .prediction
    @Published var isUserInteracting = false
    
    // Scratch state
    @Published var scratchCards: [ScratchCard] = [
        ScratchCard(id: 0, prize: .coupon(label: "30% Off", code: "DOM-SAVE30", description: "30% off your next Domino's order. Valid online only.", points: 300)),
        ScratchCard(id: 1, prize: .coupon(label: "FREE Brownie", code: "DOM-BROWNIE", description: "Free brownie with any $10 order. Show at checkout.", points: 150)),
        ScratchCard(id: 2, prize: .loss(points: 25)),
    ]
    @Published var couponWallet: [CouponCode] = []
    @Published var scratchTotalCardsLeft: Int = 3
    
    // More or Less state
    @Published var mlPicks: [Int: PickDirection] = [:]
    @Published var mlSubmitted: Bool = false
    @Published var mlResultMessage: String? = nil
    
    let mlPlayers: [MLPlayerCard] = [
        MLPlayerCard(id: 0, emoji: "🦅", name: "J. Hurts",     team: "Eagles", stat: "Pass TDs",  line: 2.5, description: "Avg 2.3 TD passes"),
        MLPlayerCard(id: 1, emoji: "🦅", name: "A.J. Brown",   team: "Eagles", stat: "Rec Yards", line: 75.5, description: "Avg 82.1 yards"),
        MLPlayerCard(id: 2, emoji: "🐻", name: "J. Fields",    team: "Bears",  stat: "Rush Yards",line: 35.5, description: "Avg 41.3 rush yds"),
        MLPlayerCard(id: 3, emoji: "🐻", name: "D. Montgomery",team: "Bears",  stat: "Carries",   line: 16.5, description: "Avg 15.8 carries"),
    ]
    
    // MARK: - Private
    
    private var cycleTimer: Timer?
    private let cycleDuration: TimeInterval = 15.0
    private var interactionTimer: DispatchWorkItem?
    
    // MARK: - Lifecycle
    
    func startCycling() {
        guard cycleTimer == nil else { return }
        cycleTimer = Timer.scheduledTimer(withTimeInterval: cycleDuration, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self, !self.isUserInteracting else { return }
                self.advanceToNext()
            }
        }
    }
    
    func stop() {
        cycleTimer?.invalidate()
        cycleTimer = nil
    }
    
    // MARK: - Navigation
    
    func advanceToNext() {
        let next = (currentFormat.rawValue + 1) % AdFormat.allCases.count
        withAnimation(.easeInOut(duration: 0.35)) {
            currentFormat = AdFormat(rawValue: next) ?? .prediction
        }
    }
    
    func userBeganInteraction(pauseFor seconds: TimeInterval = 30) {
        isUserInteracting = true
        interactionTimer?.cancel()
        let work = DispatchWorkItem { [weak self] in
            Task { @MainActor [weak self] in
                self?.isUserInteracting = false
            }
        }
        interactionTimer = work
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds, execute: work)
    }
    
    func selectFormat(_ format: AdFormat) {
        withAnimation(.easeInOut(duration: 0.25)) {
            currentFormat = format
        }
        userBeganInteraction(pauseFor: 20)
    }
    
    // MARK: - Scratch Actions
    
    func revealScratchCard(id: Int, gameEngine: GameEngine) {
        guard let idx = scratchCards.firstIndex(where: { $0.id == id }),
              !scratchCards[idx].isRevealed else { return }
        scratchCards[idx].isRevealed = true
        scratchTotalCardsLeft = max(0, scratchTotalCardsLeft - 1)
        
        let prize = scratchCards[idx].prize
        gameEngine.awardPointsPublic(prize.points, label: "Scratch card!")
        
        if case .coupon(let label, let code, let description, _) = prize {
            couponWallet.append(CouponCode(
                brand: "Domino's",
                code: code,
                description: description,
                expiresIn: "48 hours"
            ))
            gameEngine.addFeedPublic(FeedEntry(
                type: .ad, emoji: "🎟️",
                text: "Domino's coupon unlocked: \(label)!",
                detail: "Code: \(code) · Saved to wallet",
                timestamp: Date()
            ))
        }
        userBeganInteraction(pauseFor: 25)
    }
    
    // MARK: - More or Less Actions
    
    func pickML(playerIndex: Int, direction: PickDirection, gameEngine: GameEngine) {
        guard !mlSubmitted else { return }
        if mlPicks[playerIndex] == direction {
            mlPicks.removeValue(forKey: playerIndex)
        } else {
            mlPicks[playerIndex] = direction
        }
        userBeganInteraction(pauseFor: 30)
    }
    
    func submitMLEntry(gameEngine: GameEngine) {
        guard !mlSubmitted, mlPicks.count >= 2 else { return }
        mlSubmitted = true
        
        let multiplierMap = [2: 1.5, 3: 3.0, 4: 6.0]
        let mult = multiplierMap[mlPicks.count] ?? 1.5
        let base = 250
        let bonus = Int(Double(base) * mult)
        
        gameEngine.awardPointsPublic(bonus, label: "More or Less entry!")
        mlResultMessage = "Entry locked! Win up to +\(bonus) pts 🚀"
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) { [weak self] in
            self?.mlResultMessage = nil
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
            self?.mlSubmitted = false
            self?.mlPicks = [:]
        }
    }
    
    var mlMultiplier: Double {
        let map = [2: 1.5, 3: 3.0, 4: 6.0]
        return map[mlPicks.count] ?? 1.0
    }
    
    var mlMaxWin: Int {
        mlPicks.count >= 2 ? Int(250.0 * mlMultiplier) : 0
    }
}
