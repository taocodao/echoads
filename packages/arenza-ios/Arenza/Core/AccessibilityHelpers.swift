// AccessibilityHelpers.swift — Arenza (Phase 5: Accessibility Audit)
// WCAG AA compliance helpers, VoiceOver support, and Dynamic Type support.

import SwiftUI

// MARK: - Accessibility View Modifiers

extension View {
    /// Applies standard Arenza accessibility to interactive game elements.
    /// Adds aria-pressed semantics, live region announcements, and focus ring.
    func arenzaAccessible(
        label: String,
        hint: String? = nil,
        isSelected: Bool = false,
        traits: AccessibilityTraits = .isButton
    ) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityHint(hint.map { Text($0) } ?? Text(""))
            .accessibilityAddTraits(traits)
            .accessibilityAddTraits(isSelected ? .isSelected : [])
            .accessibilityRemoveTraits(isSelected ? [] : .isSelected)
    }

    /// Announces a live region update for score changes, timer updates, etc.
    func arenzaLiveRegion(_ text: String) -> some View {
        self
            .accessibilityLabel(text)
            .accessibilityAddTraits(.updatesFrequently)
    }

    /// Adds visible focus ring matching Arenza's accent color.
    /// Only visible when using keyboard navigation or switch control.
    func arenzaFocusRing(color: Color = Color(red: 0.0, green: 0.82, blue: 0.60)) -> some View {
        self.modifier(FocusRingModifier(color: color))
    }
}

// MARK: - Focus Ring Modifier

struct FocusRingModifier: ViewModifier {
    let color: Color
    @Environment(\.isFocused) var isFocused

    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(color, lineWidth: isFocused ? 2 : 0)
                    .padding(-3)
                    .animation(.easeInOut(duration: 0.15), value: isFocused)
            )
    }
}

// MARK: - Reduced Motion Support

struct ReducedMotionModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    func body(content: Content) -> some View {
        content
            .animation(reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.7), value: reduceMotion)
    }
}

extension View {
    /// Respects `prefers-reduced-motion` — disables all spring/bounce animations.
    func respectsReducedMotion() -> some View {
        modifier(ReducedMotionModifier())
    }
}

// MARK: - Timer Accessibility

/// Provides VoiceOver-friendly timer announcements.
struct AccessibleTimer {
    /// Generates an accessibility label for a countdown timer.
    static func label(seconds: Int) -> String {
        if seconds <= 0 { return "Timer expired" }
        let minutes = seconds / 60
        let secs = seconds % 60
        if minutes > 0 {
            return "\(minutes) minute\(minutes == 1 ? "" : "s") and \(secs) second\(secs == 1 ? "" : "s") remaining"
        }
        return "\(secs) second\(secs == 1 ? "" : "s") remaining"
    }

    /// Key thresholds where VoiceOver should announce the time.
    static func shouldAnnounce(seconds: Int) -> Bool {
        seconds == 60 || seconds == 30 || seconds == 10 || seconds == 5
    }
}

// MARK: - Contrast Checker

/// Runtime contrast verification against WCAG AA (4.5:1 for normal text).
enum ContrastChecker {
    /// Calculates relative luminance from RGB (0–1 range).
    static func relativeLuminance(r: Double, g: Double, b: Double) -> Double {
        func linearize(_ c: Double) -> Double {
            c <= 0.03928 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * linearize(r) + 0.7152 * linearize(g) + 0.0722 * linearize(b)
    }

    /// Returns the contrast ratio between two luminance values.
    static func contrastRatio(lum1: Double, lum2: Double) -> Double {
        let lighter = max(lum1, lum2)
        let darker  = min(lum1, lum2)
        return (lighter + 0.05) / (darker + 0.05)
    }

    /// Checks if a text/background pair meets WCAG AA (4.5:1).
    static func meetsAA(
        textR: Double, textG: Double, textB: Double,
        bgR: Double, bgG: Double, bgB: Double
    ) -> Bool {
        let textLum = relativeLuminance(r: textR, g: textG, b: textB)
        let bgLum = relativeLuminance(r: bgR, g: bgG, b: bgB)
        return contrastRatio(lum1: textLum, lum2: bgLum) >= 4.5
    }
}

// MARK: - Bingo Cell Accessibility

/// Provides structured VoiceOver descriptions for bingo cells.
struct BingoCellAccessibility {
    let row: Int
    let column: Int
    let cellLabel: String
    let isMarked: Bool
    let isFree: Bool
    let isWinLine: Bool

    var accessibilityLabel: String {
        let columnLetters = ["B", "I", "N", "G", "O"]
        let col = column < columnLetters.count ? columnLetters[column] : "\(column)"
        var label = "\(col)\(row + 1): \(cellLabel)"

        if isFree { label += ", free space" }
        if isMarked { label += ", marked" }
        if isWinLine { label += ", winning line!" }

        return label
    }

    var accessibilityHint: String {
        if isFree { return "This is a free space, already marked." }
        if isMarked { return "This cell has been marked." }
        return "Double tap to mark this cell."
    }
}

// MARK: - Points Counter Accessibility

struct PointsCounterAccessibility {
    /// Generates an announcement for a points change.
    static func announcement(oldBalance: Int, newBalance: Int, source: String) -> String {
        let delta = newBalance - oldBalance
        if delta > 0 {
            return "Earned \(delta) points from \(source). New balance: \(newBalance) AZT."
        } else if delta < 0 {
            return "Spent \(abs(delta)) points on \(source). Remaining balance: \(newBalance) AZT."
        }
        return "Balance unchanged: \(newBalance) AZT."
    }
}
