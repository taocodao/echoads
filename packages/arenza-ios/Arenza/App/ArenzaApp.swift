// ArenzaApp.swift — Arenza
// @main entry point — TabView shell with Watch, Predict, Rewards, and Earnings tabs.

import SwiftUI
import BackgroundTasks
import AVFoundation

@main
struct ArenzaApp: App {
    @StateObject private var env = AppEnvironment.shared

    init() {
        // Configure audio session BEFORE any AVPlayer is created.
        // Without .playback category, AVPlayerLayer shows black on physical iPhones
        // even though Simulator works fine (Simulator doesn't enforce audio session routing).
        configureAudioSession()

        // Register background task handlers on launch
        HouseAdBGTask.register()
    }

    private func configureAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            // .playback: allows video+audio even when silent switch is on
            // .moviePlayback: optimised mode for video content
            try session.setCategory(.playback, mode: .moviePlayback, options: [.allowAirPlay])
            try session.setActive(true)
        } catch {
            // Non-fatal — log and continue. Video may still play without audio on some devices.
            print("[Audio] AVAudioSession setup failed: \(error.localizedDescription)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(env)
                .preferredColorScheme(.dark)
                .onAppear {
                    // Warm up engines on first appear
                    Task { await HouseAdCache.shared.refresh() }
                    HouseAdBGTask.schedule()
                }
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

            // Phase 2: Predictions tab
            PredictionsTabView()
                .tabItem {
                    Label("Predict", systemImage: "sparkles")
                }

            // Phase 2: Rewards tab
            RewardsWalletView()
                .tabItem {
                    Label("Rewards", systemImage: "gift.fill")
                }

            // Token Marketplace
            MarketplaceView()
                .tabItem {
                    Label("Shop", systemImage: "storefront")
                }

            EarningsView()
                .tabItem {
                    Label("Earnings", systemImage: "chart.line.uptrend.xyaxis")
                }
        }
        .tint(Color(red: 0.0, green: 0.82, blue: 0.60))  // CMXS brand green
    }
}

// MARK: - Predictions Tab (entry point for prediction history and stats)

struct PredictionsTabView: View {
    @ObservedObject private var engine = PredictionEngine.shared

    var body: some View {
        NavigationStack {
            List {
                Section("Your Stats") {
                    HStack {
                        Label("Total Points", systemImage: "star.fill")
                            .foregroundColor(.primary)
                        Spacer()
                        Text("\(engine.wallet.aztBalance) AZT")
                            .fontWeight(.bold)
                            .foregroundColor(Color(red: 0.0, green: 0.82, blue: 0.60))
                    }
                    HStack {
                        Label("Current Streak", systemImage: "flame.fill")
                            .foregroundColor(.primary)
                        Spacer()
                        Text("🔥 \(engine.wallet.currentStreak)")
                            .fontWeight(.bold)
                    }
                    HStack {
                        Label("Tier", systemImage: "medal.fill")
                            .foregroundColor(.primary)
                        Spacer()
                        Text(engine.wallet.tier.emoji + " " + engine.wallet.tier.label)
                            .fontWeight(.semibold)
                    }
                }

                Section("How It Works") {
                    Label("Predictions appear during game breaks", systemImage: "clock.fill")
                    Label("Answer before the timer runs out", systemImage: "checkmark.circle.fill")
                    Label("Earn points for correct answers", systemImage: "plus.circle.fill")
                    Label("Streaks multiply your points up to 3×", systemImage: "multiply.circle.fill")
                    Label("Reach thresholds to unlock sponsor coupons", systemImage: "gift.fill")
                }
            }
            .navigationTitle("Predictions")
        }
    }
}
