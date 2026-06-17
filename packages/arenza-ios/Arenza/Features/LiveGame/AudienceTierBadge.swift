// AudienceTierBadge.swift — Arenza
// Top-right badge on the video panel showing the user's engagement tier.
// Matches web demo AudienceTierBadge.tsx exactly.
//
// NOTE: RewardsWallet is a Codable struct (not ObservableObject),
// so we pass the aztBalance as a plain Int to keep this view simple.

import SwiftUI

struct AudienceTierBadgeView: View {
    let aztBalance: Int

    init(aztBalance: Int) {
        self.aztBalance = aztBalance
    }

    private var tierData: (label: String, emoji: String, color: Color, bg: Color) {
        switch aztBalance {
        case 0..<100:
            return ("Casual",   "👀", Color(arenza: "#8892b0"), Color(arenza: "#141720"))
        case 100..<500:
            return ("Regular",  "🔥", Color(arenza: "#ff6b35"), Color(arenza: "#1a0e08"))
        case 500..<1500:
            return ("Superfan", "⚡", Color(arenza: "#ffc107"), Color(arenza: "#1a1500"))
        default:
            return ("Elite",    "👑", Color(arenza: "#7c3aed"), Color(arenza: "#120d1a"))
        }
    }

    var body: some View {
        let tier = tierData
        HStack(spacing: 4) {
            Text(tier.emoji).font(.system(size: 11))
            Text(tier.label)
                .font(.system(size: 9, weight: .black))
                .foregroundColor(tier.color)
                .tracking(0.3)
            Text("·")
                .font(.system(size: 9))
                .foregroundColor(tier.color.opacity(0.5))
            Text("\(aztBalance) pts")
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundColor(tier.color.opacity(0.8))
        }
        .padding(.horizontal, 8).padding(.vertical, 4)
        .background(tier.bg.opacity(0.85))
        .overlay(
            Capsule().stroke(tier.color.opacity(0.4), lineWidth: 1)
        )
        .clipShape(Capsule())
        .shadow(color: tier.color.opacity(0.3), radius: 6)
    }
}
