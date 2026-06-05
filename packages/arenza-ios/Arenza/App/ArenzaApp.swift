// ArenzaApp.swift — Arenza Prototype
// @main entry point — TabView shell with Home and Earnings tabs.

import SwiftUI

@main
struct ArenzaApp: App {
    @StateObject private var env = AppEnvironment.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(env)
                .preferredColorScheme(.dark)
        }
    }
}

// MARK: - Root Tab View

struct ContentView: View {
    @EnvironmentObject var env: AppEnvironment

    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Watch", systemImage: "play.circle.fill")
                }

            EarningsView()
                .tabItem {
                    Label("Earnings", systemImage: "chart.line.uptrend.xyaxis")
                }
        }
        .tint(Color(red: 0.0, green: 0.82, blue: 0.60))  // CMXS brand green
    }
}
