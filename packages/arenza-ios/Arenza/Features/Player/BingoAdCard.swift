// BingoAdCard.swift — Arenza
// Ad Format 2: Auto-Updating Bingo Card
// Sponsored by Budweiser — 5×5 grid auto-marks on live game events.
// First to complete a line wins a sponsor prize.

import SwiftUI

struct BingoAdCard: View {
    @ObservedObject var engine: GameEngine
    @ObservedObject var adEngine: InteractiveAdEngine

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 3), count: 5)

    var body: some View {
        VStack(spacing: 0) {
            bingoHeader
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 8) {
                    // BINGO column headers
                    bingoColumnHeaders
                    // 5×5 Grid
                    LazyVGrid(columns: columns, spacing: 3) {
                        ForEach(engine.bingoBoard) { cell in
                            BingoAdCellView(cell: cell)
                                .onTapGesture {
                                    engine.markBingoCell(cell.id)
                                    adEngine.userBeganInteraction(pauseFor: 25)
                                }
                        }
                    }
                    // Status + prize info
                    bingoFooter
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
            }
        }
        .background(Color(arenza: "#0d0f14"))
    }

    // MARK: - Header

    private var bingoHeader: some View {
        HStack(spacing: 8) {
            HStack(spacing: 4) {
                PulsingDot(color: Color(arenza: "#ffc107"))
                Text("BINGO · LIVE GAME")
                    .font(.system(size: 10, weight: .black))
                    .foregroundColor(Color(arenza: "#ffc107"))
                    .tracking(0.8)
            }
            Spacer()
            HStack(spacing: 4) {
                Text("🍻")
                Text("Budweiser")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(Color(arenza: "#ffc107"))
                Text("Game-Day")
                    .font(.system(size: 10))
                    .foregroundColor(Color(arenza: "#8892b0"))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(
            LinearGradient(
                colors: [Color(arenza: "#1a1200"), Color(arenza: "#0d0f14")],
                startPoint: .leading, endPoint: .trailing
            )
        )
        .overlay(Rectangle().fill(Color.white.opacity(0.06)).frame(height: 1), alignment: .bottom)
    }

    // MARK: - Column Headers

    private var bingoColumnHeaders: some View {
        HStack(spacing: 3) {
            ForEach(["B", "I", "N", "G", "O"], id: \.self) { letter in
                Text(letter)
                    .font(.system(size: 13, weight: .black))
                    .foregroundColor(Color(arenza: "#ffc107"))
                    .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Footer

    private var bingoFooter: some View {
        VStack(spacing: 6) {
            // Lines progress
            HStack {
                HStack(spacing: 4) {
                    ForEach(0..<3) { i in
                        Image(systemName: i < engine.bingoLines ? "star.fill" : "star")
                            .font(.system(size: 10))
                            .foregroundColor(i < engine.bingoLines ? Color(arenza: "#ffc107") : Color(arenza: "#4a5568"))
                    }
                }
                Text("Lines: \(engine.bingoLines)")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(Color(arenza: "#8892b0"))
                Spacer()
                Text("+500 pts per BINGO!")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(Color(arenza: "#ffc107"))
            }

            // Prize row
            HStack(spacing: 8) {
                prizeChip(emoji: "🍺", label: "Free 6-pack")
                prizeChip(emoji: "🎽", label: "$50 off jersey")
                prizeChip(emoji: "🎟️", label: "Game ticket")
            }

            // Hint text
            Text("Tap cells to mark (+25 pts) · Game events auto-mark")
                .font(.system(size: 9))
                .foregroundColor(Color(arenza: "#4a5568"))
                .multilineTextAlignment(.center)
        }
    }

    private func prizeChip(emoji: String, label: String) -> some View {
        HStack(spacing: 3) {
            Text(emoji).font(.system(size: 10))
            Text(label)
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(Color(arenza: "#8892b0"))
        }
        .padding(.horizontal, 6).padding(.vertical, 3)
        .background(Color(arenza: "#1a1e2a"))
        .clipShape(Capsule())
        .overlay(Capsule().stroke(Color.white.opacity(0.08), lineWidth: 1))
    }
}

// MARK: - Bingo Cell (Ad variant — smaller, compact)

struct BingoAdCellView: View {
    let cell: BingoCell
    @State private var popped = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 5)
                .fill(cellBg)
                .overlay(
                    Group {
                        if cell.isFree {
                            RoundedRectangle(cornerRadius: 5)
                                .fill(LinearGradient(
                                    colors: [Color(arenza: "#ff6b35"), Color(arenza: "#ffc107")],
                                    startPoint: .topLeading, endPoint: .bottomTrailing
                                ))
                        }
                    }
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(cell.isFree ? Color.clear : cell.marked ? Color(arenza: "#ffc107") : Color.white.opacity(0.07), lineWidth: 1)
                )

            VStack(spacing: 1) {
                Text(cell.isFree ? "FREE" : cell.label)
                    .font(.system(size: 7, weight: cell.marked ? .bold : .regular))
                    .foregroundColor(cell.isFree ? .white : cell.marked ? Color(arenza: "#f0f2ff") : Color(arenza: "#8892b0"))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
                if cell.marked && !cell.isFree {
                    Text("✓")
                        .font(.system(size: 7, weight: .black))
                        .foregroundColor(Color(arenza: "#ffc107"))
                }
            }
            .padding(2)
        }
        .aspectRatio(1, contentMode: .fill)
        .scaleEffect(popped ? 1.15 : 1.0)
        .onChange(of: cell.marked) { isMarked in
            if isMarked {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.5)) { popped = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.spring(response: 0.2)) { popped = false }
                }
            }
        }
    }

    private var cellBg: Color {
        if cell.isFree { return Color.clear }
        if cell.marked { return Color(arenza: "#ffc107").opacity(0.15) }
        return Color(arenza: "#1a1e2a")
    }
}
