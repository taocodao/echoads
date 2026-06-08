// SocialLeaderboardView.swift — Arenza (Phase 6: Social / Leaderboards)
// Full leaderboard screen with Friends, Local (DMA), and Season scopes.
// Private League creation flow + share sheet for invites.

import SwiftUI

// MARK: - Enhanced Leaderboard View

struct SocialLeaderboardView: View {
    @ObservedObject private var engine = PredictionEngine.shared
    @ObservedObject private var geo = LocalizationEngine.shared
    @StateObject private var vm = SocialLeaderboardViewModel()
    @State private var showCreateLeague = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Your ranking card
                myRankCard

                // Scope picker (now includes Local + Friends from Phase 1 model)
                Picker("", selection: $vm.scope) {
                    Text("Season").tag(LeaderboardScope.season)
                    Text("Weekly").tag(LeaderboardScope.weekly)
                    Text("Near Me").tag(LeaderboardScope.local)
                    Text("Friends").tag(LeaderboardScope.friends)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)

                // Leaderboard list
                leaderboardList
            }
            .navigationTitle("Leaderboard")
            .navigationBarTitleDisplayMode(.large)
            .background(Color(white: 0.05).ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showCreateLeague = true
                    } label: {
                        Image(systemName: "person.3.fill")
                            .foregroundColor(Color(red: 0.0, green: 0.82, blue: 0.60))
                    }
                }
            }
            .sheet(isPresented: $showCreateLeague) {
                CreateLeagueSheet()
            }
            .task { await vm.loadLeaderboard(scope: vm.scope, dmaCode: geo.currentDMACode) }
            .onChange(of: vm.scope) { _, newScope in
                Task { await vm.loadLeaderboard(scope: newScope, dmaCode: geo.currentDMACode) }
            }
        }
    }

    // MARK: - My Rank Card

    private var myRankCard: some View {
        HStack(spacing: 14) {
            // Avatar
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 0.0, green: 0.82, blue: 0.60), Color(hue: 0.52, saturation: 0.8, brightness: 0.6)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)
                Text("👤")
                    .font(.system(size: 22))
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text("You")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                    Text(engine.wallet.tier.emoji + " " + engine.wallet.tier.label)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white.opacity(0.5))
                }
                HStack(spacing: 12) {
                    rankStat(label: "AZT", value: "\(engine.wallet.weeklyAZT)")
                    rankStat(label: "Streak", value: "🔥\(engine.wallet.currentStreak)")
                    rankStat(label: "Balance", value: "\(engine.wallet.aztBalance)")
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("#\(vm.myRank)")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundColor(Color(red: 0.0, green: 0.82, blue: 0.60))
                Text("RANK")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.white.opacity(0.35))
                    .tracking(1)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            LinearGradient(
                colors: [Color(red: 0.0, green: 0.82, blue: 0.60).opacity(0.08), Color(white: 0.06)],
                startPoint: .leading, endPoint: .trailing
            )
        )
    }

    private func rankStat(label: String, value: String) -> some View {
        VStack(spacing: 0) {
            Text(value)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.white)
            Text(label)
                .font(.system(size: 9))
                .foregroundColor(.white.opacity(0.35))
        }
    }

    // MARK: - Leaderboard List

    private var leaderboardList: some View {
        ScrollView {
            LazyVStack(spacing: 2) {
                ForEach(Array(vm.entries.enumerated()), id: \.element.id) { index, entry in
                    LeaderboardRow(entry: entry, rank: index + 1, isMe: entry.userID == "me")
                }
            }
            .padding(.top, 8)
            .padding(.bottom, 16)
        }
    }
}

// MARK: - Leaderboard Row

struct LeaderboardRow: View {
    let entry: LeaderboardEntry
    let rank: Int
    let isMe: Bool

    private var rankColor: Color {
        switch rank {
        case 1: return .yellow
        case 2: return Color(white: 0.75)
        case 3: return Color(red: 0.80, green: 0.50, blue: 0.20)
        default: return .white.opacity(0.3)
        }
    }

    private var rankIcon: String? {
        switch rank {
        case 1: return "🥇"
        case 2: return "🥈"
        case 3: return "🥉"
        default: return nil
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            // Rank
            if let icon = rankIcon {
                Text(icon).font(.system(size: 18)).frame(width: 32)
            } else {
                Text("#\(rank)")
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundColor(rankColor)
                    .frame(width: 32)
            }

            // Avatar
            Circle()
                .fill(Color(white: 0.15))
                .frame(width: 36, height: 36)
                .overlay(
                    Text(String(entry.displayName.prefix(1)))
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white.opacity(0.6))
                )

            // Name + tier
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(entry.displayName)
                        .font(.system(size: 14, weight: isMe ? .black : .semibold))
                        .foregroundColor(isMe ? Color(red: 0.0, green: 0.82, blue: 0.60) : .white)
                    Text(entry.tier.emoji)
                        .font(.system(size: 10))
                }
                Text("🔥 \(entry.currentStreak) streak  •  \(entry.correctPredictions)/\(entry.totalPredictions) correct")
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.35))
            }

            Spacer()

            // Points
            Text("\(entry.points)")
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundColor(isMe ? Color(red: 0.0, green: 0.82, blue: 0.60) : .white.opacity(0.8))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(isMe ? Color(red: 0.0, green: 0.82, blue: 0.60).opacity(0.06) : Color.clear)
    }
}

// MARK: - Create League Sheet

struct CreateLeagueSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var leagueName = ""
    @State private var showShareSheet = false
    @State private var inviteCode = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "person.3.sequence.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(red: 0.0, green: 0.82, blue: 0.60), .blue],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )

                Text("Create a Private League")
                    .font(.system(size: 22, weight: .black))
                    .foregroundColor(.white)

                Text("Challenge your friends in a private prediction league. Invite up to 50 people.")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.5))
                    .multilineTextAlignment(.center)

                // League name input
                VStack(alignment: .leading, spacing: 6) {
                    Text("LEAGUE NAME")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white.opacity(0.4))
                        .tracking(1)
                    TextField("e.g. \"Sunday Crew\"", text: $leagueName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(14)
                        .background(Color.white.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .tint(Color(red: 0.0, green: 0.82, blue: 0.60))
                }

                if !inviteCode.isEmpty {
                    // Invite code reveal
                    VStack(spacing: 8) {
                        Text("INVITE CODE")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white.opacity(0.4))
                            .tracking(1)
                        Text(inviteCode)
                            .font(.system(size: 32, weight: .black, design: .monospaced))
                            .foregroundColor(Color(red: 0.0, green: 0.82, blue: 0.60))
                            .textSelection(.enabled)
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity)
                    .background(Color(red: 0.0, green: 0.82, blue: 0.60).opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .transition(.scale.combined(with: .opacity))

                    // Share button
                    Button {
                        showShareSheet = true
                    } label: {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Invite Friends")
                        }
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color(red: 0.0, green: 0.82, blue: 0.60))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .sheet(isPresented: $showShareSheet) {
                        ShareSheet(items: ["Join my Arenza league \"\(leagueName)\" — code: \(inviteCode) 🏈 https://arenza.app/join/\(inviteCode)"])
                    }
                } else {
                    // Create button
                    Button {
                        withAnimation(.spring(response: 0.4)) {
                            inviteCode = generateCode()
                        }
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                    } label: {
                        Text("Create League")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(leagueName.isEmpty
                                        ? Color.gray.opacity(0.3)
                                        : Color(red: 0.0, green: 0.82, blue: 0.60))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(leagueName.isEmpty)
                }

                Spacer()
            }
            .padding(24)
            .background(Color(white: 0.07).ignoresSafeArea())
            .navigationTitle("Private League")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(Color(red: 0.0, green: 0.82, blue: 0.60))
                }
            }
        }
    }

    private func generateCode() -> String {
        let chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
        return String((0..<6).map { _ in chars.randomElement()! })
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ uvc: UIActivityViewController, context: Context) {}
}

// MARK: - Social Leaderboard ViewModel

@MainActor
final class SocialLeaderboardViewModel: ObservableObject {
    @Published var entries: [LeaderboardEntry] = []
    @Published var scope: LeaderboardScope = .season
    @Published var myRank: Int = 0

    func loadLeaderboard(scope: LeaderboardScope, dmaCode: String?) async {
        // Try API first
        if let data = await PredictionAPIClient.shared.fetchLeaderboard(scope: scope, dmaCode: dmaCode) {
            entries = data.entries
            myRank = data.myRank
        } else {
            loadDemoEntries(scope: scope)
        }
    }

    private func loadDemoEntries(scope: LeaderboardScope) {
        let names = ["Marcus T.", "Jordan W.", "Riley P.", "Casey M.", "Devon H.",
                     "Skyler A.", "Morgan B.", "Taylor C.", "Quinn D.", "Avery F."]
        var result: [LeaderboardEntry] = []
        for (i, name) in names.enumerated() {
            let entryId: UUID       = UUID()
            let pts: Int            = Int.random(in: 150...5000) - (i * 120)
            let correct: Int        = Int.random(in: 8...40)
            let total: Int          = Int.random(in: 15...50)
            let streak: Int         = Int.random(in: 0...12)
            let tier: RewardsTier   = RewardsTier.allCases.randomElement() ?? .bronze
            result.append(LeaderboardEntry(
                id: entryId, userID: "user_\(i)", displayName: name,
                avatarURL: nil, rank: i + 1,
                points: pts, correctPredictions: correct,
                totalPredictions: total, currentStreak: streak, tier: tier
            ))
        }
        entries = result.sorted { $0.points > $1.points }

        let wallet = PredictionEngine.shared.wallet
        let myEntry = LeaderboardEntry(
            id: UUID(), userID: "me", displayName: "You",
            avatarURL: nil, rank: 0,
            points: scope == .weekly ? wallet.weeklyAZT : wallet.seasonAZT,
            correctPredictions: 12, totalPredictions: 20,
            currentStreak: wallet.currentStreak,
            tier: wallet.tier
        )
        entries.insert(myEntry, at: min(4, entries.count))
        myRank = 5
    }
}
