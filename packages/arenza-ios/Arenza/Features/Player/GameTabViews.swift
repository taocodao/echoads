// GameTabViews.swift — Arenza
// Four bottom-panel tabs for the split-screen player:
// Bets, Bingo, Live Feed, and Profile/Targeting.

import SwiftUI

// MARK: - Design Tokens

private enum G {
    static let bg       = Color(arenza: "#0d0f14")
    static let surface  = Color(arenza: "#141720")
    static let surface2 = Color(arenza: "#1a1e2a")
    static let border   = Color.white.opacity(0.08)
    static let text     = Color(arenza: "#f0f2ff")
    static let muted    = Color(arenza: "#8892b0")
    static let faint    = Color(arenza: "#4a5568")
    static let orange   = Color(arenza: "#ff6b35")
    static let teal     = Color(arenza: "#00c9b1")
    static let gold     = Color(arenza: "#ffc107")
    static let green    = Color(arenza: "#22c55e")
    static let red      = Color(arenza: "#ef4444")
}

// MARK: - Bets Tab

struct BetsTab: View {
    @ObservedObject var engine: GameEngine

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                if let pred = engine.activePrediction {
                    PredictionCardView(
                        pred: pred,
                        timer: engine.predictionTimer,
                        userPick: engine.userPick,
                        resolved: engine.predictionResolved,
                        onPick: { engine.pickOption($0) }
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                } else {
                    idleBetsView
                }

                upcomingBetsView
            }
            .padding(12)
        }
        .animation(.spring(response: 0.4), value: engine.activePrediction?.id)
    }

    private var idleBetsView: some View {
        VStack(spacing: 8) {
            Text("⏳").font(.system(size: 28))
            Text("Next prediction incoming...")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(G.muted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }

    private var upcomingBetsView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("UPCOMING PROPS")
                .font(.system(size: 10, weight: .black))
                .foregroundColor(G.faint)
                .tracking(1.2)

            ForEach(["Nike", "Pepsi", "DraftKings"], id: \.self) { brand in
                HStack(spacing: 8) {
                    Text("🎯").font(.system(size: 14))
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Sponsored prediction by \(brand)")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(G.text)
                        Text("Arriving soon")
                            .font(.system(size: 10))
                            .foregroundColor(G.muted)
                    }
                    Spacer()
                    Text("Soon")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(G.orange)
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(G.orange.opacity(0.12))
                        .clipShape(Capsule())
                }
                .padding(10)
                .background(G.surface2)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(G.border))
            }
        }
    }
}

// MARK: - Prediction Card

struct PredictionCardView: View {
    let pred: GamePrediction
    let timer: Int
    let userPick: Int?
    let resolved: Bool
    let onPick: (Int) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Sponsor badge
            if let sponsor = pred.sponsor {
                Text("🎯 Sponsored by \(sponsor)")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(G.orange)
            }

            Text(pred.question)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(G.text)

            // Options
            LazyVGrid(columns: Array(repeating: .init(.flexible(), spacing: 8), count: min(pred.options.count, 2)), spacing: 8) {
                ForEach(Array(pred.options.enumerated()), id: \.offset) { i, opt in
                    let isCorrect = resolved && i == pred.correctIndex
                    let isWrong   = resolved && userPick == i && i != pred.correctIndex
                    let isPicked  = userPick == i

                    Button { onPick(i) } label: {
                        VStack(spacing: 4) {
                            Text(opt.emoji).font(.system(size: 20))
                            Text(opt.label)
                                .font(.system(size: 12, weight: .bold))
                            Text(opt.odds)
                                .font(.system(size: 11, weight: .medium, design: .monospaced))
                                .foregroundColor(isCorrect ? G.green : isWrong ? G.red : isPicked ? G.orange : G.muted)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            isCorrect ? G.green.opacity(0.15) :
                            isWrong   ? G.red.opacity(0.1) :
                            isPicked  ? G.orange.opacity(0.15) : G.surface2
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(
                            isCorrect ? G.green : isWrong ? G.red : isPicked ? G.orange : G.border, lineWidth: 1
                        ))
                    }
                    .disabled(userPick != nil)
                    .buttonStyle(.plain)
                }
            }

            // Timer bar
            VStack(spacing: 6) {
                HStack {
                    Text("⏱ Locks in \(timer)s")
                        .font(.system(size: 11))
                        .foregroundColor(G.muted)
                    Spacer()
                    Text("🎖 +\(pred.pointReward) pts")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(G.gold)
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3).fill(G.border).frame(height: 4)
                        RoundedRectangle(cornerRadius: 3)
                            .fill(timer > 5 ? G.teal : G.red)
                            .frame(width: geo.size.width * CGFloat(timer) / CGFloat(max(pred.durationSec, 1)), height: 4)
                            .animation(.linear(duration: 1), value: timer)
                    }
                }
                .frame(height: 4)
            }
        }
        .padding(14)
        .background(G.surface2)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(G.orange.opacity(0.3), lineWidth: 1))
    }
}

// MARK: - Bingo Tab

struct BingoTab: View {
    @ObservedObject var engine: GameEngine

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 5), count: 5)

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                // Header row B I N G O
                HStack {
                    ForEach(["B","I","N","G","O"], id: \.self) { letter in
                        Text(letter)
                            .font(.custom("", size: 16).bold())
                            .frame(maxWidth: .infinity)
                            .foregroundColor(G.orange)
                    }
                }
                .padding(.horizontal, 2)

                // Grid
                LazyVGrid(columns: columns, spacing: 5) {
                    ForEach(engine.bingoBoard) { cell in
                        BingoCellView(cell: cell)
                            .onTapGesture { engine.markBingoCell(cell.id) }
                    }
                }

                // Lines progress
                HStack(spacing: 6) {
                    Text("Lines: \(engine.bingoLines)")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(G.muted)
                    Spacer()
                    Text("+500 pts per BINGO!")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(G.gold)
                }
                .padding(.top, 4)

                Text("Tap any cell to mark it (+25 pts). Game events auto-mark cells.")
                    .font(.system(size: 10))
                    .foregroundColor(G.faint)
                    .multilineTextAlignment(.center)
            }
            .padding(12)
        }
    }
}

struct BingoCellView: View {
    let cell: BingoCell

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 7)
                .fill(cell.marked || cell.isFree ? G.orange.opacity(0.2) : G.surface2)
                .overlay(
                    Group {
                        if cell.isFree {
                            RoundedRectangle(cornerRadius: 7)
                                .fill(LinearGradient(
                                    colors: [Color(arenza: "#ff6b35"), Color(arenza: "#00c9b1")],
                                    startPoint: .topLeading, endPoint: .bottomTrailing
                                ))
                        }
                    }
                )
                .overlay(RoundedRectangle(cornerRadius: 7).stroke(
                    cell.isFree ? Color.clear : cell.marked ? G.orange : G.border, lineWidth: 1
                ))

            VStack(spacing: 2) {
                Text(cell.isFree ? "FREE" : cell.label)
                    .font(.system(size: 8, weight: cell.marked ? .bold : .regular))
                    .foregroundColor(cell.isFree ? .white : cell.marked ? G.text : G.muted)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                if cell.marked && !cell.isFree {
                    Text("✓").font(.system(size: 7)).foregroundColor(G.teal)
                }
            }
            .padding(3)
        }
        .aspectRatio(1, contentMode: .fill)
    }
}

// MARK: - Live Feed Tab

struct LiveFeedTab: View {
    @ObservedObject var engine: GameEngine

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 7) {
                if engine.feed.isEmpty {
                    Text("⏳ Waiting for game events...")
                        .font(.system(size: 13))
                        .foregroundColor(G.faint)
                        .padding(.vertical, 24)
                } else {
                    ForEach(engine.feed) { entry in
                        FeedEntryRow(entry: entry)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }
                }
            }
            .padding(12)
            .animation(.spring(response: 0.4), value: engine.feed.count)
        }
    }
}

struct FeedEntryRow: View {
    let entry: FeedEntry

    private var bgColor: Color {
        switch entry.type {
        case .ad:         return Color(arenza: "#ff6b35").opacity(0.08)
        case .prediction: return Color(arenza: "#00c9b1").opacity(0.08)
        case .pod:        return Color(arenza: "#22c55e").opacity(0.08)
        default:          return G.surface2
        }
    }
    private var borderColor: Color {
        switch entry.type {
        case .ad:         return Color(arenza: "#ff6b35").opacity(0.25)
        case .pod:        return G.green.opacity(0.25)
        default:          return G.border
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text(entry.emoji).font(.system(size: 16))
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.text)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(G.text)
                    .fixedSize(horizontal: false, vertical: true)
                if let detail = entry.detail {
                    Text(detail)
                        .font(.system(size: 10))
                        .foregroundColor(G.muted)
                }
            }
            Spacer()
            Text(entry.timestamp, style: .time)
                .font(.system(size: 9, design: .monospaced))
                .foregroundColor(G.faint)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(bgColor)
        .clipShape(RoundedRectangle(cornerRadius: 9))
        .overlay(RoundedRectangle(cornerRadius: 9).stroke(borderColor, lineWidth: 1))
    }
}

// MARK: - Profile / Targeting Tab

struct ProfileTab: View {
    @ObservedObject var engine: GameEngine

    private let interests: [(label: String, pct: Double, color: Color)] = [
        ("Football", 0.92, Color(arenza: "#ff6b35")),
        ("Basketball", 0.68, Color(arenza: "#00c9b1")),
        ("Baseball", 0.41, Color(arenza: "#7c3aed")),
        ("Soccer", 0.35, Color(arenza: "#ffc107")),
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                viewerSegmentCard
                interestSignalsCard
                if let lastAd = engine.lastAd { whyThisAdCard(lastAd) }
                sessionRevenueCard
                pointsSummaryCard
            }
            .padding(12)
        }
    }

    // Viewer Segment
    private var viewerSegmentCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("👤 Viewer Profile")
            LazyVGrid(columns: [.init(.flexible()), .init(.flexible())], spacing: 8) {
                ForEach([
                    ("Segment", "Sports Enthusiast"),
                    ("Demo", "Male · 25–34"),
                    ("Engagement", "87 / 100"),
                    ("Loyalty", "Grade A"),
                ], id: \.0) { key, val in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(key).font(.system(size: 10)).foregroundColor(G.faint)
                        Text(val).font(.system(size: 12, weight: .bold)).foregroundColor(G.text)
                    }
                }
            }
        }
        .surfaceCard()
    }

    // Interest Signals
    private var interestSignalsCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("📊 Interest Signals")
            ForEach(interests, id: \.label) { interest in
                VStack(spacing: 4) {
                    HStack {
                        Text(interest.label).font(.system(size: 12)).foregroundColor(G.text)
                        Spacer()
                        Text("\(Int(interest.pct * 100))%")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(interest.color)
                    }
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 3).fill(G.border).frame(height: 5)
                            RoundedRectangle(cornerRadius: 3).fill(interest.color)
                                .frame(width: geo.size.width * interest.pct, height: 5)
                        }
                    }
                    .frame(height: 5)
                }
            }
        }
        .surfaceCard()
    }

    // Why This Ad
    private func whyThisAdCard(_ ad: GameAdCreative) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("🎯 Why \(ad.brand) Was Served")
            HStack(spacing: 10) {
                Text(ad.emoji).font(.system(size: 24))
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(ad.brand) — \(ad.tagline)")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(G.text)
                    Text("$\(ad.cpm) CPM · Won OpenRTB auction")
                        .font(.system(size: 10))
                        .foregroundColor(ad.color)
                }
            }
            Divider().background(G.border)
            ForEach(ad.whyChosen, id: \.self) { reason in
                HStack(spacing: 6) {
                    Text("✓").font(.system(size: 11)).foregroundColor(G.green)
                    Text(reason).font(.system(size: 11)).foregroundColor(G.muted)
                }
            }
        }
        .padding(12)
        .background(ad.color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(ad.color.opacity(0.3), lineWidth: 1))
    }

    // Session Revenue
    private var sessionRevenueCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("💰 Session Revenue")
            HStack {
                revenueMetric(String(engine.adsServed), label: "Ads Served", color: G.orange)
                Divider().frame(height: 40).background(G.border)
                revenueMetric(String(format: "$%.3f", engine.sessionRevenue), label: "Revenue", color: G.green)
                Divider().frame(height: 40).background(G.border)
                let avgCPM = engine.adsServed > 0 ? engine.sessionRevenue * 1000 / Double(engine.adsServed) : 0
                revenueMetric(engine.adsServed > 0 ? "$\(Int(avgCPM))" : "—", label: "Avg CPM", color: G.teal)
            }
        }
        .surfaceCard()
    }

    private func revenueMetric(_ val: String, label: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(val)
                .font(.system(size: 18, weight: .black, design: .monospaced))
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(G.faint)
        }
        .frame(maxWidth: .infinity)
    }

    // Points Summary
    private var pointsSummaryCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("YOUR POINTS")
                    .font(.system(size: 10, weight: .black))
                    .foregroundColor(G.faint)
                    .tracking(1)
                Text("\(engine.points.formatted())")
                    .font(.system(size: 28, weight: .black, design: .monospaced))
                    .foregroundColor(G.gold)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text("≈ $\(String(format: "%.2f", Double(engine.points) / 200.0)) value")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(G.muted)
                Text("Top 12% this game")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(G.teal)
            }
        }
        .padding(12)
        .background(G.gold.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(G.gold.opacity(0.25), lineWidth: 1))
    }

    private func sectionLabel(_ label: String) -> some View {
        Text(label)
            .font(.system(size: 10, weight: .black))
            .foregroundColor(G.muted)
            .tracking(0.8)
    }
}

// MARK: - View Modifiers

private extension View {
    func surfaceCard() -> some View {
        self
            .padding(12)
            .background(Color(arenza: "#1a1e2a"))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.08), lineWidth: 1))
    }
}
