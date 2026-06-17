// AdsHistoryTabView.swift — Arenza
// "Ads" tab (📺) inside the 9-tab bar.
// Shows all ad breaks watched this session with PoD hash, CPM, and brand.
// Matches web demo AdsHistoryTab component.

import SwiftUI

struct AdsHistoryTabView: View {
    @ObservedObject private var demo = DemoOrchestrator.shared

    private let demoAds: [(brand: String, emoji: String, cpm: Int, txHash: String, pts: Int)] = [
        ("Domino's", "🍕", 45, "0xa3f7b2e9c1d4", 10),
        ("Pepsi", "🥤", 52, "0xb8c2d1e4a5f3", 10),
        ("Budweiser", "🍺", 65, "0xc4e9f1b3d7a2", 10),
        ("Nike", "👟", 78, "0xd2a5c8e1f4b9", 10),
    ]

    private var totalRevenue: Double {
        Double(demoAds.count) * 0.052
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header stats
            HStack(spacing: 0) {
                statCell(value: "\(demoAds.count)", label: "Ads Watched", color: Color(arenza: "#ff6b35"))
                Divider().frame(height: 36)
                statCell(value: "$\(String(format: "%.2f", totalRevenue))", label: "Revenue", color: Color(arenza: "#22c55e"))
                Divider().frame(height: 36)
                statCell(value: "\(demoAds.count * 10)", label: "Pts Earned", color: Color(arenza: "#ffc107"))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(Color(arenza: "#141720"))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )

            // Section header
            HStack {
                Text("📺 Ad History")
                    .font(.system(size: 10, weight: .black))
                    .foregroundColor(Color(arenza: "#8892b0"))
                    .textCase(.uppercase)
                    .tracking(0.8)
                Spacer()
                Text("PoD Verified")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(Color(arenza: "#22c55e"))
            }

            // Ad list
            ForEach(Array(demoAds.enumerated()), id: \.offset) { _, ad in
                adRow(ad)
            }

            // Empty state if no ads yet
            if demoAds.isEmpty {
                VStack(spacing: 8) {
                    Text("📺").font(.system(size: 32))
                    Text("No ads watched yet")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color(arenza: "#8892b0"))
                    Text("Watch ad breaks to earn points and see proof-of-delivery here")
                        .font(.system(size: 10))
                        .foregroundColor(Color(arenza: "#4a5568"))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            }
        }
    }

    private func adRow(_ ad: (brand: String, emoji: String, cpm: Int, txHash: String, pts: Int)) -> some View {
        HStack(spacing: 10) {
            Text(ad.emoji)
                .font(.system(size: 24))
                .frame(width: 40, height: 40)
                .background(Color(arenza: "#1a1e2a"))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(ad.brand)
                        .font(.system(size: 12, weight: .black))
                        .foregroundColor(Color(arenza: "#f0f2ff"))
                    Text("$\(ad.cpm) CPM")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(Color(arenza: "#22c55e"))
                        .padding(.horizontal, 5).padding(.vertical, 2)
                        .background(Color(arenza: "#22c55e").opacity(0.12))
                        .clipShape(Capsule())
                }
                Text(ad.txHash)
                    .font(.system(size: 8, design: .monospaced))
                    .foregroundColor(Color(arenza: "#00c9b1"))
                    .lineLimit(1)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                HStack(spacing: 3) {
                    Text("✅")
                        .font(.system(size: 10))
                    Text("Verified")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(Color(arenza: "#22c55e"))
                }
                Text("+\(ad.pts) pts")
                    .font(.system(size: 10, weight: .black, design: .monospaced))
                    .foregroundColor(Color(arenza: "#ffc107"))
            }
        }
        .padding(.horizontal, 12).padding(.vertical, 10)
        .background(Color(arenza: "#141720"))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color(arenza: "#22c55e").opacity(0.2), lineWidth: 1)
        )
    }

    private func statCell(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 18, weight: .black, design: .monospaced))
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 8, weight: .medium))
                .foregroundColor(Color(arenza: "#8892b0"))
        }
        .frame(maxWidth: .infinity)
    }
}
