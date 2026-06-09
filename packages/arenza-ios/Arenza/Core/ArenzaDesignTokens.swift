// ArenzaDesignTokens.swift — Arenza
// Shared design helpers for the game layer.
// Provides a non-failable Color(arenza:) initializer to avoid
// conflicts with the existing failable Color(hex:) in DemoAdCardView.swift.

import SwiftUI

extension Color {
    /// Non-failable hex initializer for hardcoded Arenza design tokens.
    /// Uses `arenza:` label to distinguish from the failable `hex:` in DemoAdCardView.
    init(arenza hex: String) {
        let h = hex.trimmingCharacters(in: .init(charactersIn: "#"))
        let val = UInt64(h, radix: 16) ?? 0
        self.init(
            red:   Double((val >> 16) & 0xff) / 255,
            green: Double((val >>  8) & 0xff) / 255,
            blue:  Double( val        & 0xff) / 255
        )
    }
}
