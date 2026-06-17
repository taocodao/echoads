// OnboardingView.swift — Arenza
// Swift/SwiftUI port of OnboardingFlow.tsx (web demo).
// 3-step micro-survey shown on first launch:
//   Step 1 — What do you like nearby? (restaurant, bar, cafe…)
//   Step 2 — Favorite sports? (NFL, NBA, MLB…)
//   Step 3 — Favorite teams? (auto-filtered by sport selections)
// Profile saved to UserDefaults and fed into ProfileEngine.

import SwiftUI

// MARK: - Onboarding Profile

struct OnboardingProfile: Codable {
    var interests: [String]   // e.g. ["restaurant", "bar"]
    var sports: [String]      // e.g. ["NFL", "NBA"]
    var teams: [String]       // e.g. ["Eagles", "Knicks"]
    var completedAt: Date
}

// MARK: - Constants (mirrors OnboardingFlow.tsx)

private let interests: [(id: String, emoji: String, label: String)] = [
    ("restaurant", "🍽️", "Restaurant"),
    ("bar",        "🍺", "Bar"),
    ("pizza",      "🍕", "Pizza"),
    ("cafe",       "☕",  "Cafe"),
    ("gym",        "💪", "Gym"),
    ("diner",      "🥞", "Diner"),
]

private let sports: [(id: String, emoji: String, label: String)] = [
    ("NFL", "🏈", "NFL"),
    ("NBA", "🏀", "NBA"),
    ("MLB", "⚾",  "MLB"),
    ("NHL", "🏒", "NHL"),
    ("MLS", "⚽", "Soccer"),
    ("UFC", "🥊", "UFC/MMA"),
]

private let teamsBySport: [String: [(id: String, emoji: String, label: String)]] = [
    "NFL": [
        ("Eagles", "🦅", "Eagles"), ("Giants", "🗽", "Giants"),
        ("Cowboys", "⭐", "Cowboys"), ("Bears", "🐻", "Bears"),
        ("Chiefs", "🔴", "Chiefs"), ("49ers", "🏆", "49ers"),
    ],
    "NBA": [
        ("Knicks", "🗽", "Knicks"), ("Nets", "🎯", "Nets"),
        ("Lakers", "💛", "Lakers"), ("Bulls", "🐂", "Bulls"),
        ("Celtics", "☘️", "Celtics"), ("Heat", "🌡️", "Heat"),
    ],
]

// MARK: - OnboardingView

struct OnboardingView: View {
    let onComplete: (OnboardingProfile) -> Void

    @State private var step = 1
    @State private var selectedInterests: Set<String> = []
    @State private var selectedSports:    Set<String> = []
    @State private var selectedTeams:     Set<String> = []

    private var availableTeams: [(id: String, emoji: String, label: String)] {
        selectedSports.flatMap { teamsBySport[$0] ?? [] }
    }

    var body: some View {
        ZStack {
            // Backdrop
            Color.black.opacity(0.92).ignoresSafeArea()
            Color(arenza: "#0d0f14").opacity(0.5).ignoresSafeArea()

            VStack(spacing: 20) {
                // Card
                VStack(spacing: 18) {

                    // Logo + headline
                    VStack(spacing: 8) {
                        Text("📺")
                            .font(.system(size: 36))
                        Text("Welcome to ArenzaTV")
                            .font(.system(size: 20, weight: .black))
                            .foregroundColor(.white)
                        Text("Watch live sports. Earn rewards. Discover local deals.")
                            .font(.system(size: 12))
                            .foregroundColor(Color(arenza: "#8892b0"))
                            .multilineTextAlignment(.center)
                    }

                    // Step progress bar
                    HStack(spacing: 6) {
                        ForEach([1, 2, 3], id: \.self) { s in
                            RoundedRectangle(cornerRadius: 2)
                                .fill(s <= step ? Color(arenza: "#ff6b35") : Color(arenza: "#1a1e2a"))
                                .frame(maxWidth: .infinity)
                                .frame(height: 4)
                                .animation(.easeInOut(duration: 0.3), value: step)
                        }
                    }

                    // Step content
                    switch step {
                    case 1: interestsStep
                    case 2: sportsStep
                    default: teamsStep
                    }

                }
                .padding(24)
                .background(Color(arenza: "#141720"))
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.08), lineWidth: 1))
                .padding(.horizontal, 20)
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Step 1: Interests

    private var interestsStep: some View {
        VStack(spacing: 14) {
            stepHeader(title: "What do you like nearby?", subtitle: "Select all that apply")
            chipGrid(items: interests, selected: selectedInterests, color: "#ff6b35") { id in
                toggle(set: &selectedInterests, id: id)
            }
            nextButton(label: "Next →", disabled: selectedInterests.isEmpty) { step = 2 }
            skipButton
        }
    }

    // MARK: - Step 2: Sports

    private var sportsStep: some View {
        VStack(spacing: 14) {
            stepHeader(title: "Favorite sports?", subtitle: "Select all that apply")
            chipGrid(items: sports, selected: selectedSports, color: "#00c9b1") { id in
                toggle(set: &selectedSports, id: id)
            }
            nextButton(label: "Next →", disabled: selectedSports.isEmpty) { step = 3 }
            skipButton
        }
    }

    // MARK: - Step 3: Teams

    private var teamsStep: some View {
        VStack(spacing: 14) {
            stepHeader(title: "Favorite teams?", subtitle: "We'll personalize your experience")
            if availableTeams.isEmpty {
                Text("Teams auto-suggested based on your sports picks.")
                    .font(.system(size: 12))
                    .foregroundColor(Color(arenza: "#8892b0"))
                    .multilineTextAlignment(.center)
            } else {
                chipGrid(items: availableTeams, selected: selectedTeams, color: "#ffc107") { id in
                    toggle(set: &selectedTeams, id: id)
                }
            }
            nextButton(label: "Let's Go! 🏈", disabled: false) { finish() }
            skipButton
        }
    }

    // MARK: - Helpers

    private func stepHeader(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.system(size: 14, weight: .black))
                .foregroundColor(.white)
            Text(subtitle)
                .font(.system(size: 11))
                .foregroundColor(Color(arenza: "#8892b0"))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func chipGrid(
        items: [(id: String, emoji: String, label: String)],
        selected: Set<String>,
        color: String,
        onTap: @escaping (String) -> Void
    ) -> some View {
        LazyVGrid(columns: [.init(.flexible()), .init(.flexible()), .init(.flexible())], spacing: 8) {
            ForEach(items, id: \.id) { item in
                Button { onTap(item.id) } label: {
                    VStack(spacing: 4) {
                        Text(item.emoji).font(.system(size: 22))
                        Text(item.label)
                            .font(.system(size: 11, weight: selected.contains(item.id) ? .bold : .regular))
                            .foregroundColor(selected.contains(item.id) ? Color(arenza: color) : Color(arenza: "#8892b0"))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color(arenza: selected.contains(item.id) ? "\(color)22" : "#1a1e2a"))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(selected.contains(item.id) ? Color(arenza: color) : Color.white.opacity(0.08), lineWidth: 1.5)
                    )
                }
                .buttonStyle(.plain)
                .animation(.easeInOut(duration: 0.15), value: selected.contains(item.id))
            }
        }
    }

    private func nextButton(label: String, disabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 14, weight: .black))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                // Base background is always a solid Color (no type conflict)
                .background(Color(arenza: disabled ? "#4a5568" : "#ff6b35"))
                // Gradient overlay layered on top when active
                .overlay(
                    LinearGradient(
                        colors: [Color(arenza: "#ff6b35"), Color(arenza: "#ffc107")],
                        startPoint: .leading, endPoint: .trailing
                    )
                    .opacity(disabled ? 0 : 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: disabled ? .clear : Color(arenza: "#ff6b35").opacity(0.35), radius: 12, y: 4)
        }
        .buttonStyle(.plain)
        .disabled(disabled)
    }

    private var skipButton: some View {
        Button("Skip for now") { finish() }
            .font(.system(size: 11))
            .foregroundColor(Color(arenza: "#4a5568"))
    }

    private func toggle(set: inout Set<String>, id: String) {
        if set.contains(id) { set.remove(id) } else { set.insert(id) }
    }

    private func finish() {
        let profile = OnboardingProfile(
            interests: Array(selectedInterests),
            sports: Array(selectedSports),
            teams: Array(selectedTeams),
            completedAt: Date()
        )
        // Persist
        if let data = try? JSONEncoder().encode(profile) {
            UserDefaults.standard.set(data, forKey: "arenza_onboarding_v1")
        }
        UserDefaults.standard.set(true, forKey: "arenza_onboarding_complete")
        onComplete(profile)
    }
}

// MARK: - Onboarding Gate (wrap root ContentView)

extension UserDefaults {
    var arenzaOnboardingComplete: Bool {
        get { bool(forKey: "arenza_onboarding_complete") }
        set { set(newValue, forKey: "arenza_onboarding_complete") }
    }
}
