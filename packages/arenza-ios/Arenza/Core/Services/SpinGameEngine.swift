// SpinGameEngine.swift — Arenza (TableSpin Integration)
// Manages sponsor rotation, daily spin limits, odds calculation, and reward generation.
// Cycles through SponsorBusiness.all every 30 seconds in the bottom panel.

import Foundation
import Combine
import SwiftUI

@MainActor
final class SpinGameEngine: ObservableObject {

    // MARK: - Published State

    @Published var currentBusiness: SponsorBusiness = SponsorBusiness.all[0]
    @Published var businessIndex: Int = 0
    @Published var spinsUsedToday: Int = 0
    @Published var lastSpinDate: Date?
    @Published var isSpinning: Bool = false
    @Published var spinResultSegmentIndex: Int? = nil
    @Published var latestReward: SpinReward? = nil
    @Published var showRewardModal: Bool = false

    // Scratch state
    @Published var scratchRevealed: Bool = false
    @Published var scratchReward: SpinReward? = nil


    var maxSpins: Int { currentBusiness.spinConfig.maxDailySpins }
    var spinsRemaining: Int { max(0, maxSpins - spinsUsedToday) }
    var canSpin: Bool { spinsRemaining > 0 && !isSpinning }

    // MARK: - Init

    init() {
        resetDailyIfNeeded()
    }

    // MARK: - Sponsor Selection (manual only — no auto-cycling)

    func startRotation() {
        // No-op: auto-rotation disabled. User selects sponsors manually.
    }

    func stopRotation() {
        // No-op: no timers to invalidate.
    }

    func advanceSponsor() {
        withAnimation(.easeInOut(duration: 0.4)) {
            businessIndex = (businessIndex + 1) % SponsorBusiness.all.count
            currentBusiness = SponsorBusiness.all[businessIndex]
        }
        resetSpinState()
    }

    func selectSponsor(_ index: Int) {
        guard index < SponsorBusiness.all.count else { return }
        withAnimation(.easeInOut(duration: 0.3)) {
            businessIndex = index
            currentBusiness = SponsorBusiness.all[index]
        }
        resetSpinState()
    }

    private func resetSpinState() {
        spinResultSegmentIndex = nil
        latestReward = nil
        showRewardModal = false
        scratchRevealed = false
        scratchReward = nil
        resetDailyIfNeeded()
    }

    // MARK: - Daily Reset

    private func resetDailyIfNeeded() {
        let calendar = Calendar.current
        if let last = lastSpinDate, !calendar.isDateInToday(last) {
            spinsUsedToday = 0
        }
    }

    // MARK: - Spin Logic (server-authoritative in prod; local odds here)

    func spin() {
        guard canSpin else { return }
        isSpinning = true
        spinsUsedToday += 1
        lastSpinDate = Date()

        // Pick segment by weighted probability
        let segments = currentBusiness.spinConfig.segments
        let resultIndex = weightedRandom(segments: segments)

        // Simulate 4–5 second wheel animation then reveal
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.5) { [weak self] in
            guard let self else { return }
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                self.spinResultSegmentIndex = resultIndex
                self.isSpinning = false
            }
            let segment = segments[resultIndex]
            if segment.isWin {
                self.latestReward = self.generateReward(from: segment)
                // Show modal after brief pause
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    withAnimation(.spring()) { self.showRewardModal = true }
                }
            }
        }
    }

    private func weightedRandom(segments: [WheelSegment]) -> Int {
        let total = segments.reduce(0) { $0 + $1.probability }
        var r = Double.random(in: 0..<total)
        for (i, seg) in segments.enumerated() {
            r -= seg.probability
            if r <= 0 { return i }
        }
        return segments.count - 1
    }

    // MARK: - Scratch Logic

    func revealScratch() {
        guard !scratchRevealed else { return }
        let segments = currentBusiness.spinConfig.segments.filter { $0.isWin }
        guard let segment = segments.randomElement() else { return }
        scratchReward = generateReward(from: segment)
        scratchRevealed = true

        // Count scratch as one spin
        if spinsRemaining > 0 {
            spinsUsedToday += 1
            lastSpinDate = Date()
        }
    }

    // MARK: - Reward Generation

    private func generateReward(from segment: WheelSegment) -> SpinReward {
        let expiry = Date().addingTimeInterval(
            Double(currentBusiness.spinConfig.rewardExpiryMinutes) * 60
        )
        let code = generateCode(prefix: currentBusiness.id.uppercased().prefix(4) + "")
        return SpinReward(
            id: UUID(),
            rewardCode: code,
            sponsorId: currentBusiness.id,
            sponsorName: currentBusiness.name,
            sponsorEmoji: currentBusiness.emoji,
            sponsorBrandColor: currentBusiness.brandColor,
            sponsorWebsiteURL: currentBusiness.websiteURL,
            rewardType: segment.rewardType,
            rewardLabel: "\(segment.label) at \(currentBusiness.name)",
            rewardValue: segment.rewardValue,
            status: .active,
            createdAt: Date(),
            expiresAt: expiry,
            claimedAt: nil
        )
    }

    private func generateCode(prefix: String) -> String {
        let chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
        let suffix = (0..<6).map { _ in chars.randomElement()! }
        return "\(prefix)-\(String(suffix))"
    }

    // MARK: - Wallet Interaction (saves to QRWalletService)

    func saveRewardToWallet(_ reward: SpinReward) {
        QRWalletService.shared.addReward(reward)
    }
}
