// DemoAdCardView.swift — Arenza (Demo Ad Placement Showcase)
// Full-screen SwiftUI overlay displayed during ad pods.
// Replaces the AVPlayer item-swap approach to:
//   • Eliminate the stale-buffer black-screen bug
//   • Make ad breaks 100% visually distinct from sports content
//   • Show real-time targeting data (segment, CPM, why this ad was chosen)
//   • Demonstrate the sports-betting / sponsored action integration

import SwiftUI

// MARK: - Demo Ad Card View

struct DemoAdCardView: View {
    let creative: AdCreativeRegistry.Creative
    let podProgress: Double                     // 0.0 → 1.0
    let podDurationRemaining: Double            // seconds left
    let currentSegment: String                  // e.g. "SEG-03: Sports Bettor"
    var onSkip: (() -> Void)? = nil             // nil = non-skippable

    @State private var appeared = false
    @State private var tapped = false

    // Parse brand hex color
    private var brandColor: Color {
        Color(hex: creative.brandColorHex) ?? Color(red: 0.0, green: 0.82, blue: 0.60)
    }

    var body: some View {
        ZStack {
            // ── Background Gradient (brand-themed) ──────────────────────────
            LinearGradient(
                colors: [brandColor.opacity(0.95), Color.black],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // ── Top Bar ─────────────────────────────────────────────────
                topBar

                Spacer()

                // ── Ad Creative Content ──────────────────────────────────────
                adContent

                Spacer()

                // ── Targeting Intelligence Strip ─────────────────────────────
                targetingStrip

                // ── CTA Button ───────────────────────────────────────────────
                ctaButton
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
            }
        }
        .opacity(appeared ? 1 : 0)
        .scaleEffect(appeared ? 1 : 0.96)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                appeared = true
            }
        }
    }

    // MARK: - Top Bar (Ad badge + timer + skip)

    private var topBar: some View {
        HStack(spacing: 12) {
            // AD badge
            HStack(spacing: 5) {
                Image(systemName: "megaphone.fill")
                    .font(.system(size: 10))
                Text("AD")
                    .font(.system(size: 10, weight: .black))
                    .tracking(1)
            }
            .foregroundColor(.black)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.yellow)
            .clipShape(RoundedRectangle(cornerRadius: 5))

            // Advertiser name
            Text(creative.advertiser.uppercased())
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.white.opacity(0.6))
                .tracking(0.8)

            Spacer()

            // Countdown
            HStack(spacing: 4) {
                Image(systemName: "timer")
                    .font(.system(size: 11))
                Text("\(Int(ceil(podDurationRemaining)))s")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
            }
            .foregroundColor(.white.opacity(0.5))

            // Skip button (appears at 80% progress)
            if podProgress >= 0.8, let onSkip {
                Button {
                    withAnimation { onSkip() }
                } label: {
                    HStack(spacing: 4) {
                        Text("Skip")
                            .font(.system(size: 12, weight: .semibold))
                        Image(systemName: "forward.end.fill")
                            .font(.system(size: 10))
                    }
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Capsule())
                }
                .transition(.opacity.combined(with: .scale))
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 60)
        .padding(.bottom, 16)
    }

    // MARK: - Ad Creative Content

    private var adContent: some View {
        VStack(spacing: 24) {
            // Brand logo placeholder (circle with initials)
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.12))
                    .frame(width: 100, height: 100)
                Text(creative.advertiser.prefix(2).uppercased())
                    .font(.system(size: 36, weight: .black, design: .rounded))
                    .foregroundColor(.white)
            }
            .overlay(
                Circle()
                    .stroke(Color.white.opacity(0.2), lineWidth: 1.5)
            )

            // Tagline
            Text(creative.tagline)
                .font(.system(size: 26, weight: .black))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .shadow(color: .black.opacity(0.3), radius: 4, y: 2)
                .scaleEffect(appeared ? 1 : 0.9)
                .animation(.spring(response: 0.5).delay(0.15), value: appeared)

            // Sponsor category badge
            Text(creative.sponsorCategory.uppercased())
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(brandColor)
                .tracking(1.5)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.08))
                .clipShape(Capsule())
        }
    }

    // MARK: - Targeting Intelligence Strip

    private var targetingStrip: some View {
        VStack(spacing: 0) {
            Divider().background(Color.white.opacity(0.1))

            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 6) {
                    Image(systemName: "scope")
                        .font(.system(size: 11))
                        .foregroundColor(brandColor)
                    Text("AD TARGETING INTELLIGENCE")
                        .font(.system(size: 9, weight: .black))
                        .foregroundColor(.white.opacity(0.4))
                        .tracking(1.2)
                }

                HStack(spacing: 16) {
                    targetingPill(icon: "person.fill", label: "Viewer", value: currentSegment)
                    targetingPill(icon: "dollarsign.circle.fill", label: "Bid", value: "$\(String(format: "%.2f", creative.cpm)) CPM")
                    targetingPill(icon: "target", label: "Match", value: creative.targetSegments.first?.components(separatedBy: ":").last?.trimmingCharacters(in: .whitespaces) ?? "Broad")
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(Color.black.opacity(0.4))
        }
        .opacity(appeared ? 1 : 0)
        .animation(.easeIn.delay(0.3), value: appeared)
    }

    private func targetingPill(icon: String, label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 8))
                    .foregroundColor(.white.opacity(0.3))
                Text(label.uppercased())
                    .font(.system(size: 8, weight: .semibold))
                    .foregroundColor(.white.opacity(0.3))
                    .tracking(0.5)
            }
            Text(value)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.white.opacity(0.85))
                .lineLimit(1)
        }
    }

    // MARK: - CTA Button

    private var ctaButton: some View {
        Button {
            tapped = true
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        } label: {
            HStack {
                Text(creative.ctaText)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(brandColor == .black ? .white : .black)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(tapped ? Color.white.opacity(0.8) : Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: Color.white.opacity(0.2), radius: 8, y: 4)
        }
        .padding(.top, 20)
        .scaleEffect(tapped ? 0.97 : 1)
        .animation(.spring(response: 0.2), value: tapped)
    }
}

// MARK: - Ad Progress Bar (used in PlayerView HUD)

struct AdProgressBar: View {
    let progress: Double
    let advertiser: String
    let cpm: Double
    let durationRemaining: Double
    let brandColorHex: String

    private var brandColor: Color {
        Color(hex: brandColorHex) ?? Color(red: 0.0, green: 0.82, blue: 0.60)
    }

    var body: some View {
        VStack(spacing: 6) {
            HStack {
                // AD label
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.yellow)
                        .frame(width: 6, height: 6)
                    Text("AD BREAK")
                        .font(.system(size: 9, weight: .black))
                        .foregroundColor(.yellow)
                        .tracking(1)
                }

                Spacer()

                Text(advertiser)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white.opacity(0.7))

                Text("$\(String(format: "%.0f", cpm)) CPM")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(brandColor)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2)
                    .background(brandColor.opacity(0.15))
                    .clipShape(Capsule())
            }

            // Progress track
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 3)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(brandColor)
                        .frame(width: geo.size.width * progress, height: 3)
                        .animation(.linear(duration: 0.25), value: progress)
                }
            }
            .frame(height: 3)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
    }
}

// MARK: - Color hex init helper

extension Color {
    init?(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        guard Scanner(string: hex).scanHexInt64(&int), hex.count == 6 else { return nil }
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8)  & 0xFF) / 255
        let b = Double(int         & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
