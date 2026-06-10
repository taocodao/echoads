// InteractiveAdPanel.swift — Arenza
// Middle section of the 3-panel layout: auto-cycling carousel of 4 interactive ad formats.
// Auto-advances every 15s. Pauses on user interaction.

import SwiftUI

struct InteractiveAdPanel: View {
    @ObservedObject var engine: GameEngine
    @StateObject private var adEngine = InteractiveAdEngine()

    var body: some View {
        VStack(spacing: 0) {
            // Top divider (glowing accent line)
            panelDivider(color: Color(arenza: "#ff6b35"))

            // Sponsor strip + format selector
            formatSelectorBar

            // Carousel content
            ZStack {
                switch adEngine.currentFormat {
                case .prediction:
                    PredictionAdCard(engine: engine, adEngine: adEngine)
                        .transition(cardTransition)
                case .bingo:
                    BingoAdCard(engine: engine, adEngine: adEngine)
                        .transition(cardTransition)
                case .scratch:
                    ScratchAdCard(engine: engine, adEngine: adEngine)
                        .transition(cardTransition)
                case .moreLess:
                    MoreLessAdCard(engine: engine, adEngine: adEngine)
                        .transition(cardTransition)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()
            .animation(.easeInOut(duration: 0.35), value: adEngine.currentFormat)

            // Bottom: page indicator dots + progress bar
            bottomBar

            // Bottom divider
            panelDivider(color: Color(arenza: "#00c9b1"))
        }
        .background(Color(arenza: "#0d0f14"))
        .onAppear { adEngine.startCycling() }
        .onDisappear { adEngine.stop() }
    }

    // MARK: - Panel Dividers

    private func panelDivider(color: Color) -> some View {
        LinearGradient(
            colors: [Color.clear, color.opacity(0.4), Color.clear],
            startPoint: .leading, endPoint: .trailing
        )
        .frame(height: 1)
    }

    // MARK: - Format Selector Bar (tab strip)

    private var formatSelectorBar: some View {
        HStack(spacing: 0) {
            ForEach(InteractiveAdEngine.AdFormat.allCases, id: \.self) { format in
                Button {
                    adEngine.selectFormat(format)
                } label: {
                    VStack(spacing: 2) {
                        HStack(spacing: 3) {
                            Text(format.sponsorEmoji)
                                .font(.system(size: 10))
                            Text(format.sponsor)
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(
                                    adEngine.currentFormat == format
                                    ? format.accentColor
                                    : Color(arenza: "#4a5568")
                                )
                                .lineLimit(1)
                        }
                        Rectangle()
                            .fill(adEngine.currentFormat == format ? format.accentColor : Color.clear)
                            .frame(height: 2)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 5)
                }
                .buttonStyle(.plain)
            }
        }
        .background(Color(arenza: "#141720"))
        .overlay(Rectangle().fill(Color.white.opacity(0.05)).frame(height: 1), alignment: .bottom)
    }

    // MARK: - Bottom Bar (page dots + auto-cycle indicator)

    private var bottomBar: some View {
        HStack(spacing: 0) {
            // Page dots
            HStack(spacing: 5) {
                ForEach(InteractiveAdEngine.AdFormat.allCases, id: \.self) { format in
                    Circle()
                        .fill(
                            adEngine.currentFormat == format
                            ? format.accentColor
                            : Color.white.opacity(0.18)
                        )
                        .frame(
                            width: adEngine.currentFormat == format ? 8 : 5,
                            height: adEngine.currentFormat == format ? 8 : 5
                        )
                        .animation(.spring(response: 0.3), value: adEngine.currentFormat)
                }
            }
            Spacer()
            // Auto-cycle badge
            if !adEngine.isUserInteracting {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 8))
                        .foregroundColor(Color(arenza: "#4a5568"))
                    Text("Auto")
                        .font(.system(size: 9))
                        .foregroundColor(Color(arenza: "#4a5568"))
                }
                .transition(.opacity)
            } else {
                HStack(spacing: 4) {
                    Image(systemName: "hand.tap")
                        .font(.system(size: 8))
                        .foregroundColor(Color(arenza: "#ff6b35").opacity(0.6))
                    Text("Paused")
                        .font(.system(size: 9))
                        .foregroundColor(Color(arenza: "#ff6b35").opacity(0.6))
                }
                .transition(.opacity)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 5)
        .background(Color(arenza: "#141720"))
    }

    // MARK: - Card Transition

    private var cardTransition: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        )
    }
}
