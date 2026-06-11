// SpinGameAdCard.swift — Arenza (TableSpin Integration Phase 2)
// Bottom-panel tab card showing sponsor-branded spin wheel game.
// Cycles through SponsorBusiness.all every 30 seconds automatically.

import SwiftUI
import SpriteKit

// MARK: - Main Card

struct SpinGameAdCard: View {
    @ObservedObject var engine: GameEngine
    @ObservedObject var adEngine: InteractiveAdEngine
    @StateObject private var spinEngine = SpinGameEngine()
    @StateObject private var wallet = QRWalletService.shared

    @State private var showScratch = false

    var body: some View {
        mainContent
            .background(Color(arenza: "#0d0f14"))
            .onAppear { spinEngine.startRotation() }
            .onDisappear { spinEngine.stopRotation() }
            .sheet(isPresented: $spinEngine.showRewardModal) {
                rewardSheet
            }
    }

    private var mainContent: some View {
        VStack(spacing: 0) {
            sponsorHeader
            activePanel
            sponsorSwitchBar
        }
    }

    @ViewBuilder
    private var activePanel: some View {
        if showScratch {
            ScratchGamePanel(spinEngine: spinEngine)
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
        } else {
            SpinWheelPanel(spinEngine: spinEngine, gameEngine: engine)
                .transition(.asymmetric(
                    insertion: .move(edge: .leading).combined(with: .opacity),
                    removal: .move(edge: .trailing).combined(with: .opacity)
                ))
        }
    }

    private var rewardSheet: some View {
        RewardRevealModal(reward: spinEngine.latestReward, onSave: {
            if let r = spinEngine.latestReward {
                spinEngine.saveRewardToWallet(r)
                engine.awardPointsPublic(100, label: "Sponsor reward earned! 🎉")
            }
            spinEngine.showRewardModal = false
        }, onDismiss: { spinEngine.showRewardModal = false })
    }

    // MARK: - Sponsor Header

    private var sponsorHeader: some View {
        let biz = spinEngine.currentBusiness
        return HStack(spacing: 8) {
            PulsingDot(color: Color(arenza: biz.brandColor))

            Text(biz.emoji)
                .font(.system(size: 14))

            VStack(alignment: .leading, spacing: 1) {
                Text(biz.name)
                    .font(.system(size: 11, weight: .black))
                    .foregroundColor(Color(arenza: biz.brandColor))
                Text(biz.tagline)
                    .font(.system(size: 9))
                    .foregroundColor(Color(arenza: "#8892b0"))
            }

            Spacer()

            // Spin/Scratch toggle
            HStack(spacing: 0) {
                modeButton(label: "🎰 Spin", active: !showScratch) {
                    withAnimation(.easeInOut(duration: 0.3)) { showScratch = false }
                }
                modeButton(label: "🎟 Scratch", active: showScratch) {
                    withAnimation(.easeInOut(duration: 0.3)) { showScratch = true }
                }
            }
            .background(Color(arenza: "#141720"))
            .clipShape(Capsule())

            // Spins remaining pips
            HStack(spacing: 3) {
                ForEach(0..<spinEngine.maxSpins, id: \.self) { i in
                    Circle()
                        .fill(i < spinEngine.spinsRemaining
                              ? Color(arenza: biz.brandColor)
                              : Color(arenza: "#2a2a3a"))
                        .frame(width: 6, height: 6)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            LinearGradient(
                colors: [
                    Color(arenza: biz.brandColor).opacity(0.18),
                    Color(arenza: "#0d0a15")
                ],
                startPoint: .leading, endPoint: .trailing
            )
        )
        .overlay(Rectangle().fill(Color.white.opacity(0.06)).frame(height: 1), alignment: .bottom)
        .animation(.easeInOut(duration: 0.4), value: spinEngine.businessIndex)
    }

    private func modeButton(label: String, active: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(active ? .white : Color(arenza: "#6a7490"))
                .padding(.horizontal, 8).padding(.vertical, 4)
                .background(active ? Color(arenza: "#ff6b35").opacity(0.85) : Color.clear)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Sponsor Switch Bar

    private var sponsorSwitchBar: some View {
        VStack(spacing: 4) {
            // Progress bar (time to next sponsor)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle().fill(Color.white.opacity(0.05)).frame(height: 2)
                    Rectangle()
                        .fill(Color(arenza: spinEngine.currentBusiness.brandColor).opacity(0.7))
                        .frame(width: geo.size.width * spinEngine.autoRotateProgress, height: 2)
                        .animation(.linear(duration: 0.1), value: spinEngine.autoRotateProgress)
                }
            }
            .frame(height: 2)

            // Sponsor dots
            HStack(spacing: 8) {
                ForEach(Array(SponsorBusiness.all.enumerated()), id: \.offset) { i, biz in
                    Button {
                        spinEngine.selectSponsor(i)
                        adEngine.userBeganInteraction(pauseFor: 30)
                    } label: {
                        HStack(spacing: 4) {
                            Text(biz.emoji).font(.system(size: 10))
                            if i == spinEngine.businessIndex {
                                Text(biz.name)
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(Color(arenza: biz.brandColor))
                            }
                        }
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(
                            i == spinEngine.businessIndex
                                ? Color(arenza: biz.brandColor).opacity(0.18)
                                : Color.clear
                        )
                        .clipShape(Capsule())
                        .overlay(
                            Capsule().stroke(
                                i == spinEngine.businessIndex
                                    ? Color(arenza: biz.brandColor).opacity(0.4)
                                    : Color.clear,
                                lineWidth: 1
                            )
                        )
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
                // Wallet shortcut
                HStack(spacing: 3) {
                    Image(systemName: "qrcode")
                        .font(.system(size: 9, weight: .bold))
                    Text("\(QRWalletService.shared.activeRewards.count)")
                        .font(.system(size: 9, weight: .black, design: .monospaced))
                }
                .foregroundColor(
                    QRWalletService.shared.activeRewards.isEmpty
                        ? Color(arenza: "#4a5568")
                        : Color(arenza: "#00c9b1")
                )
            }
            .padding(.horizontal, 10)
        }
        .padding(.vertical, 4)
        .background(Color(arenza: "#141720"))
    }
}

// MARK: - Spin Wheel Panel

struct SpinWheelPanel: View {
    @ObservedObject var spinEngine: SpinGameEngine
    @ObservedObject var gameEngine: GameEngine

    var body: some View {
        let biz = spinEngine.currentBusiness
        ZStack {
            // Sponsor gradient background
            LinearGradient(
                colors: [
                    Color(arenza: biz.brandColor).opacity(0.12),
                    Color(arenza: "#0d0f14")
                ],
                startPoint: .top, endPoint: .bottom
            )

            VStack(spacing: 8) {
                // Wheel
                ZStack {
                    SpinWheelView(
                        segments: biz.spinConfig.segments,
                        brandColor: biz.brandColor,
                        targetIndex: spinEngine.spinResultSegmentIndex,
                        isSpinning: spinEngine.isSpinning
                    )
                    .frame(width: 180, height: 180)

                    // Center hub
                    Circle()
                        .fill(Color(arenza: "#0d0f14"))
                        .frame(width: 36, height: 36)
                    Text(biz.emoji)
                        .font(.system(size: 20))
                }

                // Result label
                if let idx = spinEngine.spinResultSegmentIndex {
                    let seg = biz.spinConfig.segments[idx]
                    Text(seg.isWin ? "\(seg.emoji) \(seg.label)!" : "\(seg.emoji) \(seg.label)")
                        .font(.system(size: 13, weight: .black))
                        .foregroundColor(seg.isWin ? Color(arenza: biz.brandColor) : Color(arenza: "#8892b0"))
                        .transition(.scale.combined(with: .opacity))
                } else {
                    Text("Tap SPIN to play")
                        .font(.system(size: 11))
                        .foregroundColor(Color(arenza: "#8892b0"))
                }

                // Spin button
                Button {
                    spinEngine.spin()
                    gameEngine.awardPointsPublic(0, label: "")
                } label: {
                    HStack(spacing: 6) {
                        if spinEngine.isSpinning {
                            ProgressView()
                                .tint(.white)
                                .scaleEffect(0.8)
                            Text("Spinning...")
                                .font(.system(size: 13, weight: .black))
                        } else if spinEngine.spinsRemaining == 0 {
                            Image(systemName: "clock.arrow.circlepath")
                            Text("Come back tomorrow")
                                .font(.system(size: 12, weight: .bold))
                        } else {
                            Text("🎰 SPIN (\(spinEngine.spinsRemaining) left)")
                                .font(.system(size: 13, weight: .black))
                        }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        spinEngine.canSpin
                            ? Color(arenza: biz.brandColor)
                            : Color(arenza: "#2a2a3a")
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
                .disabled(!spinEngine.canSpin)
                .padding(.horizontal, 24)
            }
            .padding(.vertical, 8)
        }
        .animation(.easeInOut(duration: 0.4), value: biz.id)
    }
}

// MARK: - Spin Wheel Renderer (Canvas-based, no SpriteKit dependency for tvOS compat)

struct SpinWheelView: View {
    let segments: [WheelSegment]
    let brandColor: String
    var targetIndex: Int?
    var isSpinning: Bool

    @State private var rotation: Double = 0
    @State private var prevTarget: Int? = nil

    var body: some View {
        ZStack {
            // Draw wheel segments
            Canvas { ctx, size in
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                let radius = min(size.width, size.height) / 2 - 2
                let total = segments.count
                let sliceAngle = 2 * Double.pi / Double(total)

                for (i, seg) in segments.enumerated() {
                    let start = Double(i) * sliceAngle - Double.pi / 2
                    let end   = start + sliceAngle

                    var path = Path()
                    path.move(to: center)
                    path.addArc(center: center, radius: radius,
                                startAngle: .radians(start), endAngle: .radians(end),
                                clockwise: false)
                    path.closeSubpath()

                    ctx.fill(path, with: .color(Color(arenza: seg.color).opacity(0.9)))

                    // Segment border
                    ctx.stroke(path, with: .color(.white.opacity(0.15)), lineWidth: 1)
                }

                // Outer ring
                let outerPath = Path(ellipseIn: CGRect(
                    x: center.x - radius, y: center.y - radius,
                    width: radius * 2, height: radius * 2
                ))
                ctx.stroke(outerPath, with: .color(Color(arenza: brandColor).opacity(0.5)), lineWidth: 3)
            }
            .rotationEffect(.degrees(rotation))
            .animation(
                isSpinning
                    ? .timingCurve(0.05, 0.9, 0.1, 1.0, duration: 4.5)
                    : .easeOut(duration: 0.3),
                value: rotation
            )

            // Emoji labels on segments (rendered separately)
            ForEach(Array(segments.enumerated()), id: \.offset) { i, seg in
                let angle = Double(i) * (360.0 / Double(segments.count)) - 90 + (180.0 / Double(segments.count))
                let radius: CGFloat = 58
                let x = cos(angle * .pi / 180) * radius
                let y = sin(angle * .pi / 180) * radius

                Text(seg.emoji)
                    .font(.system(size: 14))
                    .rotationEffect(.degrees(rotation + angle + 90))
                    .offset(x: x, y: y)
                    .animation(
                        isSpinning ? .timingCurve(0.05, 0.9, 0.1, 1.0, duration: 4.5) : .easeOut(duration: 0.3),
                        value: rotation
                    )
            }

            // Pointer arrow at top
            VStack {
                Image(systemName: "arrowtriangle.down.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                    .shadow(color: Color(arenza: brandColor), radius: 4)
                Spacer()
            }
        }
        .onChange(of: isSpinning) { spinning in
            if spinning {
                // 4+ full rotations + random extra
                let extraSpins = Double.random(in: 3...5) * 360
                rotation += extraSpins + 1440
            }
        }
        .onChange(of: targetIndex) { idx in
            guard let idx, !isSpinning else { return }
            let sliceDeg = 360.0 / Double(segments.count)
            // Snap to segment center
            let targetDeg = -(Double(idx) * sliceDeg) - sliceDeg / 2
            let turns = (rotation / 360).rounded(.down)
            rotation = turns * 360 + targetDeg
        }
    }
}

// MARK: - Scratch Card Panel

struct ScratchGamePanel: View {
    @ObservedObject var spinEngine: SpinGameEngine

    var body: some View {
        let biz = spinEngine.currentBusiness
        ZStack {
            LinearGradient(
                colors: [Color(arenza: biz.brandColor).opacity(0.1), Color(arenza: "#0d0f14")],
                startPoint: .top, endPoint: .bottom
            )

            VStack(spacing: 10) {
                Text("🎟 Scratch & Win")
                    .font(.system(size: 13, weight: .black))
                    .foregroundColor(Color(arenza: biz.brandColor))

                Text("\(biz.emoji) \(biz.name)")
                    .font(.system(size: 10))
                    .foregroundColor(Color(arenza: "#8892b0"))

                // Scratch card
                SpinScratchCardView(
                    business: biz,
                    isRevealed: spinEngine.scratchRevealed,
                    reward: spinEngine.scratchReward,
                    onReveal: {
                        spinEngine.revealScratch()
                        // Save reward automatically
                        if let r = spinEngine.scratchReward {
                            spinEngine.saveRewardToWallet(r)
                        }
                    }
                )
                .frame(height: 90)
                .padding(.horizontal, 24)

                // Status
                if spinEngine.scratchRevealed, let reward = spinEngine.scratchReward {
                    HStack(spacing: 6) {
                        Text("🎉")
                        Text("\(reward.rewardLabel) saved to Wallet!")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(Color(arenza: "#22c55e"))
                    }
                    .transition(.scale.combined(with: .opacity))
                } else if spinEngine.spinsRemaining == 0 {
                    Text("No plays remaining today")
                        .font(.system(size: 10))
                        .foregroundColor(Color(arenza: "#4a5568"))
                } else {
                    Text("Swipe to scratch your card")
                        .font(.system(size: 10))
                        .foregroundColor(Color(arenza: "#8892b0"))
                }
            }
            .padding(.vertical, 10)
        }
        .animation(.easeInOut(duration: 0.4), value: biz.id)
    }
}

// MARK: - Scratch Card View (touch-based canvas)

struct SpinScratchCardView: View {
    let business: SponsorBusiness
    let isRevealed: Bool
    let reward: SpinReward?
    let onReveal: () -> Void

    @State private var scratchedPoints: [CGPoint] = []
    @State private var hasTriggered = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                backgroundLayer
                contentLayer
                if !isRevealed {
                    scratchLayer(in: geo.size)
                }
            }
        }
    }

    private var backgroundLayer: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(LinearGradient(
                colors: [
                    Color(arenza: business.brandColor).opacity(0.3),
                    Color(arenza: "#141720")
                ],
                startPoint: .topLeading, endPoint: .bottomTrailing
            ))
    }

    @ViewBuilder
    private var contentLayer: some View {
        if let reward {
            VStack(spacing: 4) {
                Text(reward.rewardValue)
                    .font(.system(size: 22, weight: .black))
                    .foregroundColor(Color(arenza: business.brandColor))
                Text(reward.rewardLabel)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(Color(arenza: "#c0c8e0"))
                    .multilineTextAlignment(.center)
                Text(reward.rewardCode)
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(Color(arenza: "#8892b0"))
            }
            .padding(8)
        } else {
            Text("Scratch to reveal")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Color(arenza: "#8892b0"))
        }
    }

    private func scratchLayer(in size: CGSize) -> some View {
        Canvas { ctx, canvasSize in
            // Base scratch surface
            ctx.fill(
                RoundedRectangle(cornerRadius: 12).path(in: CGRect(origin: .zero, size: canvasSize)),
                with: .color(Color(arenza: business.brandColorSecondary).opacity(0.85))
            )

            // Scratch texture pattern
            for row in stride(from: 0, to: Int(canvasSize.height), by: 8) {
                for col in stride(from: 0, to: Int(canvasSize.width), by: 12) {
                    ctx.fill(
                        Path(CGRect(x: col, y: row, width: 6, height: 2)),
                        with: .color(.white.opacity(0.06))
                    )
                }
            }

            // "SCRATCH HERE" text
            ctx.draw(
                Text("✦ SCRATCH HERE ✦")
                    .font(.system(size: 11, weight: .black))
                    .foregroundColor(.white.opacity(0.6)),
                at: CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2)
            )

            // Clear scratched paths
            ctx.blendMode = .clear
            for pt in scratchedPoints {
                ctx.fill(
                    Path(ellipseIn: CGRect(x: pt.x - 22, y: pt.y - 22, width: 44, height: 44)),
                    with: .color(.white)
                )
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { val in
                    scratchedPoints.append(val.location)
                    // Auto-reveal at ~50% scratched
                    let area = size.width * size.height
                    let scratched = Double(scratchedPoints.count) * (44 * 44)
                    if !hasTriggered && scratched / area > 0.45 {
                        hasTriggered = true
                        withAnimation(.easeOut(duration: 0.4)) { onReveal() }
                    }
                }
        )
    }
}

// MARK: - Reward Reveal Modal

struct RewardRevealModal: View {
    let reward: SpinReward?
    let onSave: () -> Void
    let onDismiss: () -> Void

    @State private var showConfetti = false
    @State private var timeRemaining: TimeInterval = 0
    @State private var countdownTimer: Timer? = nil

    var body: some View {
        NavigationView {
            ZStack {
                Color(arenza: "#0d0f14").ignoresSafeArea()

                if let reward {
                    ScrollView {
                        mainRewardContent(reward: reward)
                    }
                }
            }
            .navigationTitle("Reward Won!")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") { onDismiss() }
                        .foregroundColor(Color(arenza: "#8892b0"))
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            showConfetti = true
            timeRemaining = reward?.timeRemaining ?? 0
            countdownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                Task { @MainActor in
                    timeRemaining = max(0, (reward?.timeRemaining ?? 0))
                }
            }
        }
        .onDisappear {
            countdownTimer?.invalidate()
        }
    }

    private func mainRewardContent(reward: SpinReward) -> some View {
        VStack(spacing: 20) {
            // Confetti header
            Text(showConfetti ? "🎉🎊🎉" : reward.sponsorEmoji)
                .font(.system(size: 40))
                .scaleEffect(showConfetti ? 1.3 : 1.0)
                .animation(.spring(response: 0.4, dampingFraction: 0.5), value: showConfetti)

            Text("You Won!")
                .font(.system(size: 28, weight: .black))
                .foregroundColor(.white)

            rewardCard(reward: reward)
            ctaButtons()
        }
        .padding(.vertical, 24)
    }

    private func rewardCard(reward: SpinReward) -> some View {
        VStack(spacing: 12) {
            Text(reward.rewardValue)
                .font(.system(size: 36, weight: .black))
                .foregroundColor(Color(arenza: reward.sponsorBrandColor))

            Text(reward.rewardLabel)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(Color(arenza: "#c0c8e0"))
                .multilineTextAlignment(.center)

            Divider().background(Color.white.opacity(0.1))

            // QR Code
            QRCodeView(
                payload: reward.qrPayload,
                size: 160,
                foreground: .black,
                background: .white
            )

            // Reward code
            HStack {
                Text(reward.rewardCode)
                    .font(.system(size: 14, weight: .black, design: .monospaced))
                    .foregroundColor(Color(arenza: reward.sponsorBrandColor))
                Button {
                    UIPasteboard.general.string = reward.rewardCode
                } label: {
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 12))
                        .foregroundColor(Color(arenza: "#8892b0"))
                }
            }

            // Countdown
            if reward.isValid {
                HStack(spacing: 4) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 11))
                    Text("Expires in \(formatCountdown(timeRemaining))")
                        .font(.system(size: 11, weight: .bold))
                }
                .foregroundColor(
                    timeRemaining < 60
                        ? Color(arenza: "#ef4444")
                        : Color(arenza: "#8892b0")
                )
            }

            // Sponsor info
            HStack(spacing: 6) {
                Text(reward.sponsorEmoji)
                Text(reward.sponsorName)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Color(arenza: "#8892b0"))
                Text("·")
                    .foregroundColor(Color(arenza: "#4a5568"))
                Text(reward.sponsorWebsiteURL)
                    .font(.system(size: 10))
                    .foregroundColor(Color(arenza: "#4a5568"))
            }
        }
        .padding(20)
        .background(Color(arenza: "#141720"))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(arenza: reward.sponsorBrandColor).opacity(0.3), lineWidth: 1)
        )
        .padding(.horizontal, 24)
    }

    private func ctaButtons() -> some View {
        VStack(spacing: 10) {
            Button(action: onSave) {
                Label("Save to QR Wallet", systemImage: "qrcode")
                    .font(.system(size: 14, weight: .black))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color(arenza: reward?.sponsorBrandColor ?? "#ffffff"))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)

            Button(action: onDismiss) {
                Text("Use Later")
                    .font(.system(size: 13))
                    .foregroundColor(Color(arenza: "#8892b0"))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 24)
    }

    private func formatCountdown(_ t: TimeInterval) -> String {
        let m = Int(t) / 60
        let s = Int(t) % 60
        return String(format: "%d:%02d", m, s)
    }
}
