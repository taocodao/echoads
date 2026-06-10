// ScratchAdCard.swift — Arenza
// Ad Format 3: Scratch & Win Coupon
// Sponsored by Domino's — tap to reveal scratch cards.
// Winners get real coupon codes saved to their wallet.

import SwiftUI

struct ScratchAdCard: View {
    @ObservedObject var engine: GameEngine
    @ObservedObject var adEngine: InteractiveAdEngine

    var body: some View {
        VStack(spacing: 0) {
            scratchHeader
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 10) {
                    // Subtitle
                    HStack {
                        Text("You earned 3 cards. Tap each to reveal your prize.")
                            .font(.system(size: 11))
                            .foregroundColor(Color(arenza: "#8892b0"))
                        Spacer()
                        Text("\(adEngine.scratchTotalCardsLeft) left")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(Color(arenza: "#ff6b35"))
                            .padding(.horizontal, 8).padding(.vertical, 3)
                            .background(Color(arenza: "#ff6b35").opacity(0.12))
                            .clipShape(Capsule())
                    }
                    .padding(.horizontal, 12)

                    // 3 Cards (horizontal)
                    HStack(spacing: 8) {
                        ForEach(adEngine.scratchCards) { card in
                            ScratchCardView(card: card) {
                                adEngine.revealScratchCard(id: card.id, gameEngine: engine)
                            }
                        }
                    }
                    .padding(.horizontal, 12)

                    // Coupon wallet reveal
                    if !adEngine.couponWallet.isEmpty {
                        couponWalletSection
                    }
                }
                .padding(.vertical, 10)
            }
        }
        .background(Color(arenza: "#0d0f14"))
    }

    // MARK: - Header

    private var scratchHeader: some View {
        HStack(spacing: 8) {
            HStack(spacing: 4) {
                Text("🎟️")
                    .font(.system(size: 12))
                Text("HALFTIME SCRATCH")
                    .font(.system(size: 10, weight: .black))
                    .foregroundColor(Color(arenza: "#ff6b35"))
                    .tracking(0.8)
            }
            Spacer()
            HStack(spacing: 4) {
                Text("🍕")
                Text("Domino's")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(Color(arenza: "#ff6b35"))
                Text("×")
                    .font(.system(size: 10))
                    .foregroundColor(Color(arenza: "#4a5568"))
                Text("FOX Sports")
                    .font(.system(size: 10))
                    .foregroundColor(Color(arenza: "#8892b0"))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(
            LinearGradient(
                colors: [Color(arenza: "#1a0800"), Color(arenza: "#0d0f14")],
                startPoint: .leading, endPoint: .trailing
            )
        )
        .overlay(Rectangle().fill(Color.white.opacity(0.06)).frame(height: 1), alignment: .bottom)
    }

    // MARK: - Coupon Wallet

    private var couponWalletSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("🎉 YOUR COUPONS — saved to Arenza Wallet")
                    .font(.system(size: 9, weight: .black))
                    .foregroundColor(Color(arenza: "#4a5568"))
                    .tracking(0.8)
                Spacer()
            }

            ForEach(adEngine.couponWallet) { coupon in
                CouponWalletCard(coupon: coupon)
            }
        }
        .padding(.horizontal, 12)
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .animation(.spring(response: 0.4), value: adEngine.couponWallet.count)
    }
}

// MARK: - Scratch Card View

struct ScratchCardView: View {
    let card: ScratchCard
    let onReveal: () -> Void

    @State private var coverScale: CGFloat = 1.0
    @State private var coverRotation: Double = 0
    @State private var coverOpacity: Double = 1.0
    @State private var revealed = false

    var body: some View {
        ZStack {
            // Reveal layer (behind cover)
            revealContent
                .opacity(revealed ? 1 : 0)
                .scaleEffect(revealed ? 1 : 0.85)
                .animation(.spring(response: 0.4).delay(0.25), value: revealed)

            // Scratch cover
            if !revealed {
                scratchCover
                    .scaleEffect(coverScale)
                    .rotationEffect(.degrees(coverRotation))
                    .opacity(coverOpacity)
            }
        }
        .aspectRatio(0.75, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    revealed && card.prize.isWin ? Color(arenza: "#ff6b35").opacity(0.5) : Color.white.opacity(0.08),
                    lineWidth: 1
                )
        )
        .shadow(color: Color.black.opacity(0.3), radius: 4, y: 2)
        .onTapGesture {
            guard !card.isRevealed else { return }
            reveal()
        }
        .onChange(of: card.isRevealed) { isRevealed in
            if isRevealed && !revealed { reveal() }
        }
    }

    private func reveal() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
            coverScale = 1.15
            coverRotation = 8
            coverOpacity = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            revealed = true
            onReveal()
        }
    }

    private var scratchCover: some View {
        ZStack {
            LinearGradient(
                colors: [Color(arenza: "#252a30"), Color(arenza: "#1a1e2a")],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            VStack(spacing: 6) {
                Text("🎟️")
                    .font(.system(size: 24))
                Text("TAP TO\nSCRATCH")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(Color(arenza: "#8892b0"))
                    .multilineTextAlignment(.center)
                    .tracking(0.5)
            }
        }
    }

    private var revealContent: some View {
        ZStack {
            switch card.prize {
            case .coupon(let label, _, _, let pts):
                LinearGradient(
                    colors: [Color(arenza: "#1a0800").opacity(0.8), Color(arenza: "#0d0f14")],
                    startPoint: .top, endPoint: .bottom
                )
                VStack(spacing: 6) {
                    Text("You won!")
                        .font(.system(size: 9, weight: .black))
                        .foregroundColor(Color(arenza: "#4a5568"))
                        .tracking(0.8)
                    Text(label)
                        .font(.system(size: 16, weight: .black))
                        .foregroundColor(Color(arenza: "#ff6b35"))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Text("+\(pts) pts")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(Color(arenza: "#ff6b35"))
                        .padding(.horizontal, 8).padding(.vertical, 2)
                        .background(Color(arenza: "#ff6b35").opacity(0.15))
                        .clipShape(Capsule())
                }
                .padding(8)

            case .loss(let pts):
                Color(arenza: "#1a1e2a")
                VStack(spacing: 6) {
                    Text("😢")
                        .font(.system(size: 20))
                    Text("Try again\nnext game")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Color(arenza: "#4a5568"))
                        .multilineTextAlignment(.center)
                    Text("+\(pts) pts for playing")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(Color(arenza: "#8892b0"))
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(Color(arenza: "#ff6b35").opacity(0.08))
                        .clipShape(Capsule())
                }
                .padding(8)
            }
        }
    }
}

// MARK: - Coupon Wallet Card

struct CouponWalletCard: View {
    let coupon: CouponCode
    @State private var copied = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(coupon.brand) Coupon")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Color(arenza: "#f0f2ff"))
                    Text(coupon.description)
                        .font(.system(size: 10))
                        .foregroundColor(Color(arenza: "#8892b0"))
                }
                Spacer()
                Text("Expires in \(coupon.expiresIn)")
                    .font(.system(size: 9))
                    .foregroundColor(Color(arenza: "#4a5568"))
            }

            HStack(spacing: 8) {
                Text(coupon.code)
                    .font(.system(size: 14, weight: .black, design: .monospaced))
                    .foregroundColor(Color(arenza: "#ff6b35"))
                    .tracking(1.5)
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .background(Color(arenza: "#141720"))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [4]))
                            .foregroundColor(Color(arenza: "#ff6b35").opacity(0.5))
                    )

                Spacer()

                Button {
                    UIPasteboard.general.string = coupon.code
                    withAnimation(.spring(response: 0.25)) { copied = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        withAnimation { copied = false }
                    }
                } label: {
                    Text(copied ? "✓ Copied" : "Copy")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(copied ? Color(arenza: "#22c55e") : Color(arenza: "#0d0f14"))
                        .padding(.horizontal, 12).padding(.vertical, 6)
                        .background(copied ? Color(arenza: "#22c55e").opacity(0.2) : Color(arenza: "#ff6b35"))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(10)
        .background(
            LinearGradient(
                colors: [Color(arenza: "#ff6b35").opacity(0.08), Color.clear],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(arenza: "#ff6b35").opacity(0.25), lineWidth: 1))
    }
}
