// PointsFlyUpView.swift — Arenza (ArenzaTV Prototype)
// Animated "+X pts" particle fly-up with glow effect.
// Shows when a viewer earns AZT from any game format.
// Usage: overlay with .pointsFlyUp(text: engine.flyText)

import SwiftUI

// MARK: - Points Fly-Up Modifier

struct PointsFlyUpModifier: ViewModifier {
    let text: String?

    @State private var isVisible = false
    @State private var offset: CGFloat = 0
    @State private var scale: CGFloat = 0.3
    @State private var opacity: Double = 0

    func body(content: Content) -> some View {
        content.overlay(
            ZStack {
                if let text = text, isVisible {
                    flyUpContent(text)
                        .offset(y: offset)
                        .scaleEffect(scale)
                        .opacity(opacity)
                }
            }
            .allowsHitTesting(false),
            alignment: .center
        )
        .onChange(of: text) { newValue in
            if newValue != nil {
                triggerAnimation()
            }
        }
    }

    private func flyUpContent(_ text: String) -> some View {
        HStack(spacing: 4) {
            Text("⭐")
                .font(.system(size: 14))
            Text(text)
                .font(.system(size: 16, weight: .black, design: .rounded))
                .foregroundColor(Color(arenza: "#ffc107"))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(Color(arenza: "#ffc107").opacity(0.15))
                .overlay(
                    Capsule()
                        .stroke(Color(arenza: "#ffc107").opacity(0.4), lineWidth: 1)
                )
        )
        .shadow(color: Color(arenza: "#ffc107").opacity(0.4), radius: 12, y: -2)
    }

    private func triggerAnimation() {
        // Reset
        isVisible = true
        offset = 0
        scale = 0.3
        opacity = 0

        // Phase 1: Pop in
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            scale = 1.15
            opacity = 1.0
        }

        // Phase 2: Settle
        withAnimation(.spring(response: 0.2, dampingFraction: 0.8).delay(0.15)) {
            scale = 1.0
        }

        // Phase 3: Float up and fade
        withAnimation(.easeOut(duration: 0.8).delay(0.6)) {
            offset = -60
            opacity = 0
        }

        // Cleanup
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isVisible = false
            offset = 0
        }
    }
}

extension View {
    func pointsFlyUp(text: String?) -> some View {
        modifier(PointsFlyUpModifier(text: text))
    }
}

// MARK: - Confetti View

struct ConfettiView: View {
    let isActive: Bool
    let colors: [Color]

    @State private var particles: [ConfettiParticle] = []

    init(isActive: Bool, colors: [Color] = [
        Color(arenza: "#ff6b35"),
        Color(arenza: "#00c9b1"),
        Color(arenza: "#ffc107"),
        Color(arenza: "#7c3aed"),
        Color(arenza: "#22c55e"),
        Color(arenza: "#ef4444"),
    ]) {
        self.isActive = isActive
        self.colors = colors
    }

    var body: some View {
        ZStack {
            ForEach(particles) { particle in
                particle.shape
                    .fill(particle.color)
                    .frame(width: particle.size.width, height: particle.size.height)
                    .rotationEffect(.degrees(particle.rotation))
                    .position(particle.position)
                    .opacity(particle.opacity)
            }
        }
        .allowsHitTesting(false)
        .onChange(of: isActive) { active in
            if active { spawnConfetti() }
        }
    }

    private func spawnConfetti() {
        let screenWidth: CGFloat = UIScreen.main.bounds.width
        let count = 40

        particles = (0..<count).map { i in
            ConfettiParticle(
                id: i,
                color: colors.randomElement() ?? .white,
                size: CGSize(
                    width: CGFloat.random(in: 4...10),
                    height: CGFloat.random(in: 6...14)
                ),
                position: CGPoint(
                    x: CGFloat.random(in: 0...screenWidth),
                    y: -20
                ),
                rotation: Double.random(in: 0...360),
                opacity: 1.0,
                shape: Bool.random() ? AnyShape(Rectangle()) : AnyShape(Circle())
            )
        }

        // Animate each particle falling
        for i in particles.indices {
            let delay = Double.random(in: 0...0.4)
            let duration = Double.random(in: 1.2...2.0)
            let endX = particles[i].position.x + CGFloat.random(in: -80...80)
            let endY = CGFloat.random(in: 400...700)
            let endRotation = particles[i].rotation + Double.random(in: 180...720)

            withAnimation(.easeOut(duration: duration).delay(delay)) {
                particles[i].position = CGPoint(x: endX, y: endY)
                particles[i].rotation = endRotation
                particles[i].opacity = 0
            }
        }

        // Cleanup
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            particles.removeAll()
        }
    }
}

struct ConfettiParticle: Identifiable {
    let id: Int
    let color: Color
    let size: CGSize
    var position: CGPoint
    var rotation: Double
    var opacity: Double
    let shape: AnyShape
}

// MARK: - Bingo Celebration Overlay

struct BingoCelebrationOverlay: View {
    let lineCount: Int
    @State private var showConfetti = false
    @State private var showBanner = false
    @State private var previousLines = 0

    var body: some View {
        ZStack {
            ConfettiView(isActive: showConfetti)

            if showBanner {
                VStack(spacing: 6) {
                    Text("🎉").font(.system(size: 40))
                    Text("BINGO!")
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color(arenza: "#ff6b35"),
                                    Color(arenza: "#ffc107"),
                                    Color(arenza: "#ff6b35"),
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    Text("Line \(lineCount) complete! +500 AZT")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(Color(arenza: "#00c9b1"))
                }
                .padding(.horizontal, 28)
                .padding(.vertical, 18)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color(arenza: "#ffc107").opacity(0.4), lineWidth: 2)
                        )
                )
                .shadow(color: Color(arenza: "#ffc107").opacity(0.3), radius: 20)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .onChange(of: lineCount) { newCount in
            if newCount > previousLines {
                triggerCelebration()
            }
            previousLines = newCount
        }
        .allowsHitTesting(false)
    }

    private func triggerCelebration() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
            showBanner = true
        }
        showConfetti = true

        // Auto-dismiss after 2.5s
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation(.easeOut(duration: 0.3)) {
                showBanner = false
            }
        }
    }
}

// MARK: - AZT Earn Toast (compact notification)

struct AZTEarnToast: View {
    let source: String
    let amount: Int
    let sponsorName: String?

    @State private var isShowing = false

    var body: some View {
        if isShowing {
            HStack(spacing: 8) {
                Text(sourceEmoji)
                    .font(.system(size: 16))
                VStack(alignment: .leading, spacing: 1) {
                    Text("+\(amount) AZT")
                        .font(.system(size: 12, weight: .black, design: .monospaced))
                        .foregroundColor(Color(arenza: "#ffc107"))
                    Text(source)
                        .font(.system(size: 9))
                        .foregroundColor(Color(arenza: "#8892b0"))
                }
                if let sponsor = sponsorName {
                    Spacer()
                    Text("by \(sponsor)")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(Color(arenza: "#00c9b1"))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(Color(arenza: "#141720"))
                    .overlay(
                        Capsule()
                            .stroke(Color(arenza: "#ffc107").opacity(0.3), lineWidth: 1)
                    )
            )
            .shadow(color: Color.black.opacity(0.4), radius: 8)
            .transition(.move(edge: .top).combined(with: .opacity))
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    withAnimation(.easeOut(duration: 0.3)) {
                        isShowing = false
                    }
                }
            }
        }
    }

    private var sourceEmoji: String {
        switch source {
        case "Prediction":   return "🔮"
        case "Team Trivia":  return "🏆"
        case "Sponsor Quiz": return "🏢"
        case "Bingo":        return "🎯"
        default:             return "⭐"
        }
    }
}
