// DemoOverlays.swift — Arenza (Demo Visual Components)
// Three demo-specific overlays wired into PlayerView:
//   1. ViewerProfilingCard  — slides in to show on-device classification result
//   2. AdIncomingBadge      — "Ad break in 4s..." countdown badge
//   3. TargetingDebugHUD    — shake-to-reveal real-time profiling + revenue data
//   4. DemoSummaryCard      — end-of-demo summary with AZT + revenue totals
//   5. DemoNarrationBar     — bottom narration strip (for recordings/demos)

import SwiftUI

// MARK: - 1. Viewer Profiling Card

struct ViewerProfilingCard: View {
    @ObservedObject private var profile = ProfileEngine.shared
    @State private var appeared = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(spacing: 8) {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 14))
                    .foregroundColor(Color(red: 0.0, green: 0.82, blue: 0.60))
                Text("ON-DEVICE VIEWER PROFILE")
                    .font(.system(size: 10, weight: .black))
                    .foregroundColor(.white.opacity(0.5))
                    .tracking(1.2)
                Spacer()
                Text("No PII transmitted")
                    .font(.system(size: 9))
                    .foregroundColor(.white.opacity(0.3))
            }

            // Segment classification
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("VIEWER SEGMENT")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(.white.opacity(0.35))
                        .tracking(0.8)
                    Text(profile.currentSegment.label)
                        .font(.system(size: 18, weight: .black))
                        .foregroundColor(.white)
                }
                Spacer()
                // Score gauge
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.1), lineWidth: 4)
                        .frame(width: 52, height: 52)
                    Circle()
                        .trim(from: 0, to: profile.viewerScore)
                        .stroke(Color(red: 0.0, green: 0.82, blue: 0.60), style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .frame(width: 52, height: 52)
                        .rotationEffect(.degrees(-90))
                        .animation(.spring(response: 1.0), value: profile.viewerScore)
                    Text("\(Int(profile.viewerScore * 100))")
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                }
            }

            Divider().background(Color.white.opacity(0.08))

            // Sport affinities
            if !profile.sportAffinities.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("SPORT AFFINITIES")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(.white.opacity(0.35))
                        .tracking(0.8)
                    ForEach(Array(profile.sportAffinities.sorted { $0.value > $1.value }.prefix(3)), id: \.key) { key, val in
                        affinityRow(label: key.replacingOccurrences(of: "_", with: " ").capitalized, value: val)
                    }
                }
            }

            // Segments targeted by current ad
            Text("→ TARGETED BY: DraftKings ($62.00 CPM)")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(Color(red: 0.0, green: 0.82, blue: 0.60))
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .background(Color.black.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16)
            .stroke(Color(red: 0.0, green: 0.82, blue: 0.60).opacity(0.3), lineWidth: 1))
        .shadow(color: .black.opacity(0.5), radius: 16, y: 4)
        .padding(.horizontal, 16)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : -20)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                appeared = true
            }
        }
    }

    private func affinityRow(label: String, value: Double) -> some View {
        HStack(spacing: 8) {
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.6))
                .frame(width: 100, alignment: .leading)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.white.opacity(0.07))
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color(red: 0.0, green: 0.82, blue: 0.60).opacity(0.7))
                        .frame(width: geo.size.width * value)
                        .animation(.spring(response: 0.8), value: value)
                }
            }
            .frame(height: 4)
            Text(String(format: "%.0f%%", value * 100))
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(.white.opacity(0.4))
                .frame(width: 32, alignment: .trailing)
        }
    }
}

// MARK: - 2. Ad Incoming Badge

struct AdIncomingBadge: View {
    @State private var pulse = false

    var body: some View {
        HStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(Color.yellow.opacity(0.3))
                    .frame(width: 28, height: 28)
                    .scaleEffect(pulse ? 1.4 : 1.0)
                    .animation(.easeInOut(duration: 0.7).repeatForever(), value: pulse)
                Circle()
                    .fill(Color.yellow)
                    .frame(width: 10, height: 10)
            }
            VStack(alignment: .leading, spacing: 1) {
                Text("AD BREAK INCOMING")
                    .font(.system(size: 11, weight: .black))
                    .foregroundColor(.yellow)
                    .tracking(0.8)
                Text("DSP auction in progress...")
                    .font(.system(size: 9))
                    .foregroundColor(.white.opacity(0.5))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
        .background(Color.yellow.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12)
            .stroke(Color.yellow.opacity(0.3), lineWidth: 1))
        .onAppear { pulse = true }
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}

// MARK: - 3. Targeting Debug HUD (shake to reveal)

struct TargetingDebugHUD: View {
    @ObservedObject private var profile = ProfileEngine.shared
    @ObservedObject private var revenue = RevenueReporter.UIProxy.shared
    @State private var appeared = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header
            HStack {
                Image(systemName: "ladybug.fill")
                    .font(.system(size: 11))
                    .foregroundColor(.orange)
                Text("AD TECH DEBUG HUD")
                    .font(.system(size: 9, weight: .black))
                    .foregroundColor(.orange)
                    .tracking(1)
                Spacer()
                Text("Shake to dismiss")
                    .font(.system(size: 8))
                    .foregroundColor(.white.opacity(0.3))
            }

            Divider().background(Color.white.opacity(0.1))

            // Live metrics grid
            LazyVGrid(columns: [.init(.flexible()), .init(.flexible())], spacing: 8) {
                hudMetric(label: "SEGMENT", value: profile.currentSegment.label, color: .cyan)
                hudMetric(label: "SCORE", value: String(format: "%.0f%%", profile.viewerScore * 100), color: Color(red: 0.0, green: 0.82, blue: 0.60))
                hudMetric(label: "SESSION CPM", value: "$\(String(format: "%.2f", revenue.sessionCPM))", color: .yellow)
                hudMetric(label: "AD EVENTS", value: "\(revenue.totalEvents)", color: .orange)
                hudMetric(label: "AZT EARNED", value: "\(PredictionEngine.shared.wallet.aztBalance) pts", color: Color(red: 0.0, green: 0.82, blue: 0.60))
                hudMetric(label: "IMPRESSIONS", value: "\(revenue.impressionCount)", color: .purple)
            }

            Divider().background(Color.white.opacity(0.1))

            // Attribution trail
            Text("ATTRIBUTION TRAIL")
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(.white.opacity(0.3))
                .tracking(1)
            VStack(alignment: .leading, spacing: 4) {
                attributionRow(type: "CPM", desc: "DraftKings — $0.062 per impression", color: .yellow)
                attributionRow(type: "CPC", desc: "Nike — $0.85 per click (if tapped)", color: .blue)
                attributionRow(type: "CPA", desc: "Domino's — $2.50 per redemption", color: Color(red: 0.0, green: 0.82, blue: 0.60))
            }
        }
        .padding(14)
        .background(Color.black.opacity(0.85))
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12)
            .stroke(Color.orange.opacity(0.3), lineWidth: 1))
        .shadow(color: .black.opacity(0.7), radius: 20)
        .padding(.horizontal, 12)
        .opacity(appeared ? 1 : 0)
        .scaleEffect(appeared ? 1 : 0.9)
        .onAppear {
            withAnimation(.spring(response: 0.4)) { appeared = true }
        }
    }

    private func hudMetric(label: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label)
                .font(.system(size: 8, weight: .semibold))
                .foregroundColor(.white.opacity(0.3))
                .tracking(0.5)
            Text(value)
                .font(.system(size: 13, weight: .black, design: .monospaced))
                .foregroundColor(color)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func attributionRow(type: String, desc: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Text(type)
                .font(.system(size: 8, weight: .black))
                .foregroundColor(color)
                .padding(.horizontal, 5)
                .padding(.vertical, 2)
                .background(color.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 3))
            Text(desc)
                .font(.system(size: 9))
                .foregroundColor(.white.opacity(0.4))
                .lineLimit(1)
        }
    }
}

// MARK: - 4. Demo Summary Card

struct DemoSummaryCard: View {
    let aztEarned: Int
    let revenueGenerated: Double
    var onDismiss: () -> Void = {}
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 52))
                .foregroundStyle(LinearGradient(
                    colors: [Color(red: 0.0, green: 0.82, blue: 0.60), .blue],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ))

            Text("Demo Complete!")
                .font(.system(size: 24, weight: .black))
                .foregroundColor(.white)

            Text("The full Arenza ad-tech flywheel ran in ~90 seconds.")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.5))
                .multilineTextAlignment(.center)

            HStack(spacing: 32) {
                summaryMetric(icon: "star.fill", label: "AZT Earned", value: "+\(aztEarned)", color: Color(red: 0.0, green: 0.82, blue: 0.60))
                summaryMetric(icon: "dollarsign.circle.fill", label: "Revenue", value: "$\(String(format: "%.3f", revenueGenerated))", color: .yellow)
                summaryMetric(icon: "shield.fill", label: "PoD Signed", value: "✓", color: .blue)
            }

            Divider().background(Color.white.opacity(0.1))

            Text("Demonstrated: Ad Targeting · Sports Betting · AZT Rewards · Sponsor Marketplace")
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.4))
                .multilineTextAlignment(.center)

            Button {
                withAnimation { onDismiss() }
            } label: {
                Text("Restart Demo")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color(red: 0.0, green: 0.82, blue: 0.60))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
        .padding(28)
        .background(Color(white: 0.07))
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(RoundedRectangle(cornerRadius: 24)
            .stroke(Color(red: 0.0, green: 0.82, blue: 0.60).opacity(0.3), lineWidth: 1))
        .shadow(color: .black.opacity(0.6), radius: 40, y: 10)
        .padding(.horizontal, 20)
        .scaleEffect(appeared ? 1 : 0.8)
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) {
                appeared = true
            }
        }
    }

    private func summaryMetric(icon: String, label: String, value: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundColor(color)
            Text(value)
                .font(.system(size: 20, weight: .black, design: .rounded))
                .foregroundColor(.white)
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(.white.opacity(0.4))
        }
    }
}

// MARK: - 5. Demo Narration Bar

struct DemoNarrationBar: View {
    let narration: String
    let step: DemoStep
    let elapsed: Int

    var body: some View {
        HStack(spacing: 10) {
            // Step indicator
            ZStack {
                Circle()
                    .fill(Color(red: 0.0, green: 0.82, blue: 0.60).opacity(0.2))
                    .frame(width: 32, height: 32)
                Image(systemName: stepIcon)
                    .font(.system(size: 13))
                    .foregroundColor(Color(red: 0.0, green: 0.82, blue: 0.60))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(step.rawValue.uppercased())
                    .font(.system(size: 9, weight: .black))
                    .foregroundColor(Color(red: 0.0, green: 0.82, blue: 0.60))
                    .tracking(1)
                Text(narration)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(2)
            }

            Spacer()

            Text("T+\(elapsed)s")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(.white.opacity(0.3))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
        .background(Color.black.opacity(0.7))
    }

    private var stepIcon: String {
        switch step {
        case .idle:             return "play.circle"
        case .contentPlaying:   return "play.tv"
        case .profilingVisible: return "brain.head.profile"
        case .adBreakIncoming:  return "timer"
        case .adPodActive:      return "megaphone.fill"
        case .adComplete:       return "checkmark.circle.fill"
        case .predictionActive: return "questionmark.bubble.fill"
        case .bettingActive:    return "sportscar.fill"
        case .marketplaceOpen:  return "cart.fill"
        case .demoComplete:     return "flag.checkered"
        }
    }
}

// MARK: - RevenueReporter UI Proxy (thread-safe read for SwiftUI)

extension RevenueReporter {
    @MainActor
    final class UIProxy: ObservableObject {
        static let shared = UIProxy()
        @Published var sessionCPM: Double = 62.0
        @Published var totalEvents: Int = 3
        @Published var impressionCount: Int = 1
    }
}
