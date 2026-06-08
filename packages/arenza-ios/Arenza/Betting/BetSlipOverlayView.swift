// BetSlipOverlayView.swift — Arenza (C6: Betting Engine)
// Live odds overlay that slides up during safe game moments and ad breaks.
// Shows moneyline/spread/total with AI-suggested bet. Deep-links to DK/FD.

import SwiftUI
import UIKit

// MARK: - Bet Slip Overlay View

struct BetSlipOverlayView: View {

    let context: BettingOverlayContext
    var onDismiss: () -> Void = {}

    @State private var opacity: Double = 0
    @State private var dragOffset: CGFloat = 0
    @State private var tapped = false

    var body: some View {
        VStack {
            Spacer()
            card
                .padding(.horizontal, 16)
                .padding(.bottom, 96)
        }
        .opacity(opacity)
        .offset(y: dragOffset)
        .gesture(swipeToDismiss)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { opacity = 1 }
        }
    }

    // MARK: - Card

    private var card: some View {
        VStack(spacing: 0) {
            // Handle
            Capsule()
                .fill(Color.white.opacity(0.2))
                .frame(width: 36, height: 4)
                .padding(.top, 10)
                .padding(.bottom, 12)

            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("LIVE BETTING")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(Color(red: 0.0, green: 0.82, blue: 0.60))
                        .tracking(2)
                    Text("via \(context.affiliatePartner.displayName)")
                        .font(.system(size: 12)).foregroundColor(.white.opacity(0.4))
                }
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.white.opacity(0.35))
                        .font(.system(size: 20))
                }
            }
            .padding(.horizontal, 18)

            Divider().background(Color.white.opacity(0.08)).padding(.vertical, 10)

            // Matchup
            HStack {
                teamLabel(context.odds.homeTeam, line: context.odds.homeMoneyline)
                Spacer()
                Text("vs")
                    .font(.system(size: 12)).foregroundColor(.white.opacity(0.35))
                Spacer()
                teamLabel(context.odds.awayTeam, line: context.odds.awayMoneyline)
            }
            .padding(.horizontal, 18)

            // Spread + Total
            HStack(spacing: 12) {
                if let spread = context.odds.spread {
                    oddsChip(label: "Spread", value: spread)
                }
                if let total = context.odds.total {
                    oddsChip(label: "Total", value: total)
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 10)

            // AI Suggestion
            if let suggestion = context.odds.aiSuggestedBet {
                aiSuggestionBanner(suggestion)
                    .padding(.horizontal, 18)
                    .padding(.top, 10)
            }

            // CTA
            ctaButton
                .padding(.horizontal, 18)
                .padding(.top, 14)

            // Responsible gaming footer
            Text(ResponsibleGamingManager.shared.disclaimerText)
                .font(.system(size: 9))
                .foregroundColor(.white.opacity(0.25))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
        }
        .background(.ultraThinMaterial)
        .background(Color(white: 0.06).opacity(0.95))
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .overlay(RoundedRectangle(cornerRadius: 22).stroke(Color.white.opacity(0.1), lineWidth: 1))
        .shadow(color: .black.opacity(0.4), radius: 20, y: 6)
    }

    // MARK: - Sub-components

    private func teamLabel(_ name: String, line: String) -> some View {
        VStack(spacing: 4) {
            Text(name)
                .font(.system(size: 14, weight: .semibold)).foregroundColor(.white)
                .lineLimit(1)
            Text(line)
                .font(.system(size: 18, weight: .black))
                .foregroundColor(line.hasPrefix("-") ? .orange : Color(red: 0.0, green: 0.82, blue: 0.60))
        }
    }

    private func oddsChip(label: String, value: String) -> some View {
        VStack(spacing: 3) {
            Text(label)
                .font(.system(size: 9)).foregroundColor(.white.opacity(0.4)).tracking(1)
            Text(value)
                .font(.system(size: 13, weight: .semibold)).foregroundColor(.white)
        }
        .padding(.vertical, 8).padding(.horizontal, 12)
        .background(Color.white.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func aiSuggestionBanner(_ suggestion: AIBetSuggestion) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "sparkles")
                .font(.system(size: 12))
                .foregroundColor(.yellow)
            VStack(alignment: .leading, spacing: 1) {
                Text("AI Pick: \(suggestion.description)")
                    .font(.system(size: 12, weight: .semibold)).foregroundColor(.white)
                Text(suggestion.reasoning)
                    .font(.system(size: 10)).foregroundColor(.white.opacity(0.45))
            }
        }
        .padding(10)
        .background(Color.yellow.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.yellow.opacity(0.2), lineWidth: 0.5))
    }

    private var ctaButton: some View {
        Button {
            guard !tapped else { return }
            tapped = true
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()

            // Track CPA click
            Task { await AffiliateTracker.shared.trackClick(overlay: context) }

            // Signal collector
            SignalCollector.shared.recordBettingTap()

            // Open deep link
            UIApplication.shared.open(context.deepLinkURL)

            // Dismiss after short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { dismiss() }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "arrow.up.right.square.fill")
                Text("Bet on \(context.affiliatePartner.displayName)")
                    .font(.system(size: 16, weight: .bold))
            }
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                LinearGradient(
                    colors: [Color(red: 0.0, green: 0.82, blue: 0.60), .cyan.opacity(0.8)],
                    startPoint: .leading, endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .scaleEffect(tapped ? 0.97 : 1.0)
        .animation(.spring(response: 0.2), value: tapped)
    }

    // MARK: - Dismiss

    private var swipeToDismiss: some Gesture {
        DragGesture()
            .onChanged { v in if v.translation.height > 0 { dragOffset = v.translation.height } }
            .onEnded { v in
                if v.translation.height > 60 { dismiss() }
                else { withAnimation(.spring()) { dragOffset = 0 } }
            }
    }

    private func dismiss() {
        withAnimation(.easeOut(duration: 0.25)) { opacity = 0; dragOffset = 120 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { onDismiss() }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        BetSlipOverlayView(context: BettingOverlayContext(
            odds: LiveOdds.demo(homeTeam: "Los Angeles Lakers", awayTeam: "Boston Celtics"),
            triggerReason: .gameStateMoment(.halftime)
        ))
    }
    .preferredColorScheme(.dark)
}
