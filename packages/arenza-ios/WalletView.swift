// WalletView.swift
// Displays the viewer's CMXS earnings, wallet address, and PoD history.

import SwiftUI

struct WalletView: View {
    @StateObject private var vm = WalletViewModel()

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 20) {
                    // ── Balance card ────────────────────────────────────────
                    VStack(spacing: 16) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("CMXS BALANCE")
                                    .font(.caption.bold())
                                    .foregroundColor(.gray)
                                    .tracking(2)
                                Text(String(format: "%.4f CMXS", vm.cmxsBalance))
                                    .font(.title.bold())
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.indigo, .purple],
                                            startPoint: .leading, endPoint: .trailing
                                        )
                                    )
                            }
                            Spacer()
                            Image(systemName: "hexagon.fill")
                                .font(.system(size: 44))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.indigo, .cyan],
                                        startPoint: .topLeading, endPoint: .bottomTrailing
                                    )
                                )
                        }

                        Divider().background(Color.white.opacity(0.08))

                        // Wallet address
                        HStack {
                            Text("ADDRESS")
                                .font(.caption2.bold())
                                .foregroundColor(.gray)
                                .tracking(2)
                            Spacer()
                            Text(vm.walletAddress)
                                .font(.caption2)
                                .foregroundColor(.indigo)
                                .fontDesign(.monospaced)
                                .lineLimit(1)
                                .truncationMode(.middle)
                        }
                    }
                    .padding(20)
                    .background(Color(hex: "0f172a"))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(Color.indigo.opacity(0.3))
                    )

                    // ── Earnings summary ────────────────────────────────────
                    HStack(spacing: 12) {
                        EarningStatCard(title: "PENDING", value: String(format: "%.3f", vm.pendingCMXS), color: .yellow)
                        EarningStatCard(title: "EARNED", value: String(format: "%.3f", vm.claimedCMXS), color: .green)
                        EarningStatCard(title: "IMPRESSIONS", value: "\(vm.impressionsVerified)", color: .cyan)
                    }

                    // ── PoD History ─────────────────────────────────────────
                    VStack(alignment: .leading, spacing: 12) {
                        Text("PoD RECEIPT HISTORY")
                            .font(.caption.bold())
                            .foregroundColor(.gray)
                            .tracking(2)

                        if vm.receipts.isEmpty {
                            Text("Watch a live channel to earn your first verified impression.")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color(hex: "0f172a"))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        } else {
                            ForEach(vm.receipts, id: \.impressionId) { pod in
                                PoDHistoryRow(pod: pod)
                            }
                        }
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Arenza Wallet")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task { await vm.load() }
    }
}

struct EarningStatCard: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.caption2.bold())
                .foregroundColor(.gray)
                .tracking(1.5)
            Text(value)
                .font(.subheadline.bold())
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color(hex: "0f172a"))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(color.opacity(0.2))
        )
    }
}

struct PoDHistoryRow: View {
    let pod: PoDReceipt

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.seal.fill")
                .foregroundColor(.green)

            VStack(alignment: .leading, spacing: 3) {
                Text(pod.impressionId.prefix(12) + "…")
                    .font(.caption.bold())
                    .foregroundColor(.white)
                    .fontDesign(.monospaced)
                Text(pod.txHash.prefix(16) + "…")
                    .font(.caption2)
                    .foregroundColor(.gray)
                    .fontDesign(.monospaced)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                Text(String(format: "$%.2f CPM", pod.cpm))
                    .font(.caption.bold())
                    .foregroundColor(.green)
                Text("0.001 CMXS")
                    .font(.caption2)
                    .foregroundColor(.indigo)
            }
        }
        .padding(14)
        .background(Color(hex: "0f172a"))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.green.opacity(0.15))
        )
    }
}

// ── ViewModel ─────────────────────────────────────────────────────────────────
@MainActor
final class WalletViewModel: ObservableObject {
    @Published var cmxsBalance: Double = 0
    @Published var pendingCMXS: Double = 0
    @Published var claimedCMXS: Double = 0
    @Published var impressionsVerified: Int = 0
    @Published var walletAddress: String = "Generating…"
    @Published var receipts: [PoDReceipt] = []

    func load() async {
        walletAddress = (try? SecureEnclaveManager.shared.currentWalletAddress()) ?? "0x000…"
        // Demo data – replace with real API call
        pendingCMXS = 0.045
        claimedCMXS = 1.234
        impressionsVerified = 1234
        cmxsBalance = claimedCMXS
    }
}

// ── WalletService (shared) ────────────────────────────────────────────────────
final class WalletService: ObservableObject {
    @Published var cmxsBalance: Double = 0
    @Published var pendingCMXS: Double = 0

    func recordEarning(txHash: String, reward: Double) {
        DispatchQueue.main.async {
            self.pendingCMXS += reward
        }
    }
}
