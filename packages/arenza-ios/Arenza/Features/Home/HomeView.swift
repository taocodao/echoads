// HomeView.swift — Arenza Prototype
// Premium dark sports grid with featured hero and live channel cards.

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var env: AppEnvironment
    @StateObject private var vm: HomeViewModel = HomeViewModel(env: .shared)
    @State private var selectedChannel: Channel?
    @State private var showPlayer = false

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Color(white: 0.05), Color(white: 0.08), Color(white: 0.05)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {

                        // ── Header ──────────────────────────────────────────
                        headerSection

                        // ── Featured Hero ───────────────────────────────────
                        if let featured = vm.featuredChannel {
                            featuredHero(channel: featured)
                        }

                        // ── Live Now Grid ───────────────────────────────────
                        sectionHeader("Live Now")
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(vm.channels.filter(\.isLive)) { channel in
                                ChannelCard(channel: channel)
                                    .onTapGesture { selectChannel(channel) }
                            }
                        }
                        .padding(.horizontal, 16)

                        // ── Coming Up ───────────────────────────────────────
                        sectionHeader("Coming Up")
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(vm.channels.filter { !$0.isLive }) { channel in
                                ChannelCard(channel: channel)
                                    .onTapGesture { selectChannel(channel) }
                                    .opacity(0.65)
                            }
                        }
                        .padding(.horizontal, 16)

                        Spacer(minLength: 32)
                    }
                }
                .refreshable { await vm.load() }
            }
            .navigationTitle("")
            .navigationBarHidden(true)
            .task { await vm.load() }
            .fullScreenCover(isPresented: $showPlayer) {
                if let channel = selectedChannel {
                    PlayerView(channel: channel)
                        .environmentObject(env)
                }
            }
        }
    }

    // MARK: - Subviews

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("ARENZA")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(red: 0.0, green: 0.82, blue: 0.60), Color(red: 0.0, green: 0.65, blue: 0.95)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                Text("Sports · Free · Verified")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.45))
                    .tracking(2)
            }
            Spacer()
            // Backend status indicator
            Circle()
                .fill(env.isBackendReachable ? Color.green : Color.orange)
                .frame(width: 8, height: 8)
                .overlay(
                    Circle()
                        .stroke(env.isBackendReachable ? Color.green.opacity(0.3) : Color.orange.opacity(0.3), lineWidth: 4)
                )
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    private func featuredHero(channel: Channel) -> some View {
        ZStack(alignment: .bottomLeading) {
            AsyncImage(url: channel.thumbnailURL) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().aspectRatio(16/9, contentMode: .fill)
                case .failure:
                    Rectangle().fill(Color(white: 0.15))
                default:
                    Rectangle().fill(Color(white: 0.12))
                        .overlay(ProgressView())
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 200)
            .clipped()
            .overlay(
                LinearGradient(
                    colors: [.clear, .black.opacity(0.8)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    liveChip
                    Text("\(formatViewers(channel.viewerCount)) watching")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
                Text(channel.currentProgram)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(2)

                Button {
                    selectChannel(channel)
                } label: {
                    Label("Watch Free", systemImage: "play.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 10)
                        .background(Color(red: 0.0, green: 0.82, blue: 0.60))
                        .clipShape(Capsule())
                }
                .padding(.top, 4)
            }
            .padding(16)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 16)
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 15, weight: .bold))
            .foregroundColor(.white.opacity(0.8))
            .padding(.horizontal, 16)
            .padding(.top, 8)
    }

    private var liveChip: some View {
        HStack(spacing: 4) {
            Circle().fill(Color.red).frame(width: 6, height: 6)
            Text("LIVE")
                .font(.system(size: 10, weight: .black))
                .foregroundColor(.white)
                .tracking(1.5)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.red.opacity(0.25))
        .overlay(
            Capsule().stroke(Color.red.opacity(0.5), lineWidth: 1)
        )
        .clipShape(Capsule())
    }

    // MARK: - Helpers

    private func selectChannel(_ channel: Channel) {
        selectedChannel = channel
        showPlayer = true
    }

    private func formatViewers(_ count: Int) -> String {
        if count >= 1000 {
            return String(format: "%.1fK", Double(count) / 1000)
        }
        return "\(count)"
    }
}

// MARK: - Channel Card

struct ChannelCard: View {
    let channel: Channel
    @State private var isPressed = false

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            AsyncImage(url: channel.thumbnailURL) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().aspectRatio(16/9, contentMode: .fill)
                default:
                    Rectangle().fill(Color(white: 0.13))
                        .overlay(
                            Image(systemName: sportIcon(channel.sport))
                                .font(.system(size: 28))
                                .foregroundColor(.white.opacity(0.2))
                        )
                }
            }
            .frame(maxWidth: .infinity)
            .aspectRatio(16/9, contentMode: .fit)
            .clipped()
            .overlay(
                LinearGradient(
                    colors: [.clear, .black.opacity(0.75)],
                    startPoint: .center,
                    endPoint: .bottom
                )
            )

            VStack(alignment: .leading, spacing: 3) {
                if channel.isLive {
                    HStack(spacing: 3) {
                        Circle().fill(Color.red).frame(width: 5, height: 5)
                        Text("LIVE").font(.system(size: 8, weight: .black))
                            .foregroundColor(.red).tracking(1.5)
                    }
                }
                Text(channel.name)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                Text(channel.sport)
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding(8)
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.07), lineWidth: 1)
        )
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .animation(.easeInOut(duration: 0.12), value: isPressed)
        .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }

    private func sportIcon(_ sport: String) -> String {
        switch sport.lowercased() {
        case "golf": return "figure.golf"
        case "soccer", "football": return "soccerball"
        case "basketball": return "basketball"
        case "mma", "boxing": return "figure.boxing"
        case "racing": return "flag.checkered"
        default: return "sportscourt"
        }
    }
}
