// HomeView.swift
// Home screen: channel grid + live event spotlight.

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var env: AppEnvironment
    @StateObject private var vm = HomeViewModel()

    let columns = [
        GridItem(.adaptive(minimum: 160, maximum: 220), spacing: 16)
    ]

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    // ── Header ─────────────────────────────────────
                    HStack {
                        Image(systemName: "triangle.fill")
                            .font(.title2)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.indigo, .purple, .cyan],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        Text("Arenza")
                            .font(.title.bold())
                            .foregroundColor(.white)
                        Spacer()
                        NavigationLink(value: Route.wallet) {
                            Label("Wallet", systemImage: "bitcoinsign.circle.fill")
                                .font(.subheadline.bold())
                                .foregroundColor(.indigo)
                        }
                    }
                    .padding(.horizontal)

                    // ── Live Now Spotlight ──────────────────────────
                    if let featured = vm.featured {
                        ChannelSpotlight(channel: featured)
                            .padding(.horizontal)
                    }

                    // ── Channel Grid ────────────────────────────────
                    VStack(alignment: .leading) {
                        Text("LIVE CHANNELS")
                            .font(.caption.bold())
                            .foregroundColor(.gray)
                            .padding(.horizontal)

                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(vm.channels) { channel in
                                NavigationLink(value: Route.channel(channel.id)) {
                                    ChannelCard(channel: channel)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.top)
            }
        }
        .task { await vm.load() }
        .navigationBarHidden(true)
    }
}

// ── Spotlight banner ─────────────────────────────────────────────────────────
struct ChannelSpotlight: View {
    let channel: Channel

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "1a0533"), Color(hex: "0a1428")],
                        startPoint: .topTrailing,
                        endPoint: .bottomLeading
                    )
                )
                .frame(maxWidth: .infinity, minHeight: 200)

            // Decorative orbit rings
            Circle().stroke(Color.indigo.opacity(0.25), lineWidth: 1)
                .frame(width: 160, height: 160)
                .offset(x: 80, y: -40)
            Circle().stroke(Color.cyan.opacity(0.15), lineWidth: 1)
                .frame(width: 240, height: 240)
                .offset(x: 100, y: -60)

            VStack(alignment: .leading, spacing: 6) {
                Text("🔴 LIVE")
                    .font(.caption2.bold())
                    .foregroundColor(.red)
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(Color.red.opacity(0.15))
                    .clipShape(Capsule())

                Text(channel.name)
                    .font(.title2.bold())
                    .foregroundColor(.white)

                Text(channel.tagline ?? "Live sports on Arenza")
                    .font(.subheadline)
                    .foregroundColor(.gray)

                HStack(spacing: 6) {
                    Label("$47.50 CPM verified", systemImage: "checkmark.seal.fill")
                        .font(.caption.bold())
                        .foregroundColor(.green)
                }
            }
            .padding()
        }
    }
}

// ── Channel grid card ────────────────────────────────────────────────────────
struct ChannelCard: View {
    let channel: Channel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(hex: "111827"))
                    .frame(height: 110)
                Text(channel.emoji ?? "📺")
                    .font(.system(size: 40))
            }
            Text(channel.name)
                .font(.subheadline.bold())
                .foregroundColor(.white)
                .lineLimit(1)
            Text(channel.sport ?? "Sports")
                .font(.caption)
                .foregroundColor(.gray)
        }
    }
}

// ── Color extension ──────────────────────────────────────────────────────────
extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)
        let r = Double((rgb >> 16) & 0xFF) / 255
        let g = Double((rgb >> 8)  & 0xFF) / 255
        let b = Double( rgb        & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
