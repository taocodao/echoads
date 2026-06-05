// EarningsView.swift — Arenza Prototype
// CMXS token balance + PoD receipt history + wallet info

import SwiftUI

struct EarningsView: View {
    @EnvironmentObject var env: AppEnvironment
    @StateObject private var vm: EarningsViewModel = EarningsViewModel(env: .shared)

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color(white: 0.05), Color(white: 0.08)],
                    startPoint: .top, endPoint: .bottom
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {

                        // ── Balance Hero Card ────────────────────────────
                        balanceCard

                        // ── Secure Enclave Status ───────────────────────
                        seStatusBanner

                        // ── Auction Stats ───────────────────────────────
                        if let stats = vm.auctionStats {
                            auctionStatsCard(stats)
                        }

                        // ── PoD Receipt History ─────────────────────────
                        receiptsSection

                        Spacer(minLength: 32)
                    }
                    .padding(.top, 8)
                }
                .refreshable { await vm.load() }
            }
            .navigationTitle("Earnings")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark)
            .task { await vm.load() }
        }
    }

    // MARK: - Balance Hero

    private var balanceCard: some View {
        VStack(spacing: 16) {
            VStack(spacing: 6) {
                Text("CMXS Balance")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
                    .tracking(1.5)
                    .textCase(.uppercase)

                Text(String(format: "%.4f", vm.totalCMXS))
                    .font(.system(size: 44, weight: .black, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(red: 0.0, green: 0.82, blue: 0.60), Color(red: 0.0, green: 0.65, blue: 0.95)],
                            startPoint: .leading, endPoint: .trailing
                        )
                    )

                Text("CMXS")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white.opacity(0.4))
            }

            Divider().background(Color.white.opacity(0.1))

            // Wallet address
            HStack(spacing: 8) {
                Image(systemName: "wallet.pass")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.4))
                Text(vm.shortWalletAddress)
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundColor(.white.opacity(0.6))
                Spacer()
                Button {
                    UIPasteboard.general.string = vm.walletAddress
                } label: {
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.4))
                }
            }

            // Stats row
            HStack(spacing: 0) {
                statBubble(label: "Ads Verified", value: "\(vm.records.count)")
                Divider().frame(height: 32).background(Color.white.opacity(0.1))
                statBubble(label: "SLA Met", value: "\(vm.records.filter(\.slaMet).count)/\(vm.records.count)")
                Divider().frame(height: 32).background(Color.white.opacity(0.1))
                statBubble(label: "Avg CPM", value: vm.records.isEmpty ? "—" : String(format: "$%.0f", vm.records.map(\.cpm).reduce(0, +) / Double(vm.records.count)))
            }
        }
        .padding(20)
        .background(Color(white: 0.1))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    LinearGradient(
                        colors: [Color(red: 0.0, green: 0.82, blue: 0.60).opacity(0.4), Color.clear],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .padding(.horizontal, 16)
    }

    private func statBubble(label: String, value: String) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(.white.opacity(0.4))
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - SE Status

    private var seStatusBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: vm.isHardwareSigned ? "lock.shield.fill" : "exclamationmark.triangle.fill")
                .font(.system(size: 16))
                .foregroundColor(vm.isHardwareSigned
                    ? Color(red: 0.0, green: 0.82, blue: 0.60)
                    : Color.orange)

            VStack(alignment: .leading, spacing: 2) {
                Text(vm.isHardwareSigned ? "Secure Enclave Active" : "Software Signing (Simulator)")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                Text(vm.isHardwareSigned
                    ? "Hardware-attested PoD · $45–65 CPM eligible"
                    : "Run on iPhone for hardware attestation")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.5))
            }
            Spacer()
        }
        .padding(14)
        .background(
            vm.isHardwareSigned
            ? Color(red: 0.0, green: 0.82, blue: 0.60).opacity(0.1)
            : Color.orange.opacity(0.1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(
                    vm.isHardwareSigned
                    ? Color(red: 0.0, green: 0.82, blue: 0.60).opacity(0.3)
                    : Color.orange.opacity(0.3),
                    lineWidth: 1
                )
        )
        .padding(.horizontal, 16)
    }

    // MARK: - Auction Stats

    private func auctionStatsCard(_ stats: AuctionStatsResponse) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Auction Performance")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.white.opacity(0.6))
                .tracking(1)
                .textCase(.uppercase)

            HStack(spacing: 12) {
                metricTile(label: "Avg Latency", value: "\(stats.avgLatencyMs)ms",
                          good: stats.avgLatencyMs < 500)
                metricTile(label: "Avg CPM", value: "$\(String(format: "%.2f", stats.avgCpm))",
                          good: true)
                metricTile(label: "Fill Rate", value: "\(Int(stats.avgFillRate * 100))%",
                          good: stats.avgFillRate > 0.8)
            }
        }
        .padding(16)
        .background(Color(white: 0.1))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.07), lineWidth: 1))
        .padding(.horizontal, 16)
    }

    private func metricTile(label: String, value: String, good: Bool) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(good ? Color(red: 0.0, green: 0.82, blue: 0.60) : Color.orange)
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(.white.opacity(0.4))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color(white: 0.14))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Receipts

    private var receiptsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Proof of Delivery Receipts")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white.opacity(0.6))
                    .tracking(1)
                    .textCase(.uppercase)
                Spacer()
                Text("\(vm.records.count) total")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.35))
            }
            .padding(.horizontal, 16)

            if vm.records.isEmpty {
                emptyState
            } else {
                ForEach(vm.records) { record in
                    PoDReceiptRow(record: record)
                        .padding(.horizontal, 16)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "shield.slash")
                .font(.system(size: 32))
                .foregroundColor(.white.opacity(0.15))
            Text("No receipts yet")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.35))
            Text("Watch a channel and let an ad play to earn CMXS")
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.25))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

// MARK: - PoD Receipt Row

struct PoDReceiptRow: View {
    let record: LocalPoDRecord

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(record.txHash != nil
                          ? Color(red: 0.0, green: 0.82, blue: 0.60).opacity(0.15)
                          : Color.orange.opacity(0.1))
                    .frame(width: 40, height: 40)
                Image(systemName: record.txHash != nil ? "checkmark.shield.fill" : "shield")
                    .font(.system(size: 16))
                    .foregroundColor(record.txHash != nil
                                     ? Color(red: 0.0, green: 0.82, blue: 0.60)
                                     : Color.orange.opacity(0.7))
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(record.advertiser)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                HStack(spacing: 6) {
                    Text(record.formattedTimestamp)
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.4))
                    Text("·")
                        .foregroundColor(.white.opacity(0.2))
                    Text("\(Int(record.switchLatencyMs))ms")
                        .font(.system(size: 11))
                        .foregroundColor(record.slaMet ? Color(red: 0.0, green: 0.82, blue: 0.60) : .orange)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                Text("+\(String(format: "%.4f", record.cmxsEarned))")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Color(red: 0.0, green: 0.82, blue: 0.60))
                Text("$\(String(format: "%.0f", record.cpm)) CPM")
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.35))
            }
        }
        .padding(14)
        .background(Color(white: 0.1))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
        .overlay(alignment: .topTrailing) {
            if let url = record.basescanURL {
                Link(destination: url) {
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.25))
                        .padding(8)
                }
            }
        }
    }
}
