// ArenzaApp.swift — Arenza
// @main entry point — TabView shell with Watch, Predict, Rewards, and Earnings tabs.

import SwiftUI
import BackgroundTasks
import AVFoundation
import UserNotifications

@main
struct ArenzaApp: App {
    @StateObject private var env = AppEnvironment.shared
    @StateObject private var notifications = NotificationService.shared
    @StateObject private var realtime = RealtimeService.shared

    init() {
        // Configure audio session BEFORE any AVPlayer is created.
        // Without .playback category, AVPlayerLayer shows black on physical iPhones
        // even though Simulator works fine (Simulator doesn't enforce audio session routing).
        configureAudioSession()

        // Register background task handlers on launch
        HouseAdBGTask.register()

        // Phase 5: Register push notification categories
        NotificationService.shared.registerCategories()
        UNUserNotificationCenter.current().delegate = NotificationService.shared
    }

    private func configureAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            // .playback: allows video+audio even when silent switch is on
            // .moviePlayback: optimised mode for video content
            // .mixWithOthers: game interactions won't interrupt audio
            try session.setCategory(.playback, mode: .moviePlayback, options: [.mixWithOthers, .allowAirPlay])
            try session.setActive(true, options: .notifyOthersOnDeactivation)
            // Force speaker on physical devices
            try session.overrideOutputAudioPort(.speaker)
        } catch {
            // Non-fatal — log and continue. Video may still play without audio on some devices.
            print("[Audio] AVAudioSession setup failed: \(error.localizedDescription)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(env)
                .environmentObject(notifications)
                .environmentObject(realtime)
                .preferredColorScheme(.dark)
                .onAppear {
                    // Warm up engines on first appear
                    Task { await HouseAdCache.shared.refresh() }
                    HouseAdBGTask.schedule()

                    // Phase 5: Request push notification permission
                    Task { await notifications.requestAuthorization() }
                    notifications.scheduleDailyCheckInReminder()
                }
        }
    }
}

// MARK: - Root Tab View

struct ContentView: View {
    @EnvironmentObject var env: AppEnvironment
    @State private var onboardingDone = UserDefaults.standard.arenzaOnboardingComplete
    @State private var showPostGame = false
    @ObservedObject private var demo = DemoOrchestrator.shared

    var body: some View {
        ZStack {
            mainTabs

            // First-launch onboarding
            if !onboardingDone {
                OnboardingView { _ in
                    withAnimation { onboardingDone = true }
                }
                .transition(.opacity)
                .zIndex(100)
            }

            // Local ad card overlay (fires during demo ad break)
            if demo.showLocalAdOverlay {
                VStack {
                    Spacer()
                    LocalAdBreakOverlay(
                        businesses: Array(demoBusinesses.prefix(3)),
                        onDismiss: { demo.showLocalAdOverlay = false },
                        onCouponClaim: { biz in
                            MembershipService.shared.addCoupon(
                                businessId: biz.id,
                                offer: biz.activeOffer?.headline ?? "Discount",
                                value: biz.activeOffer?.value ?? ""
                            )
                            demo.showLocalAdOverlay = false
                        },
                        onJoinClub: { biz in
                            MembershipService.shared.addStamp(businessId: biz.id)
                            demo.showLocalAdOverlay = false
                        }
                    )
                    .padding(.bottom, 100)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.spring(response: 0.4, dampingFraction: 0.85), value: demo.showLocalAdOverlay)
                .zIndex(50)
            }

            // Post-game recap sheet
            if demo.showPostGameRecap {
                Color.black.opacity(0.6).ignoresSafeArea().zIndex(60)
                PostGameRecapView(
                    points: MembershipService.shared.totalPointsAcrossAllBusinesses + demo.totalAZTEarned,
                    correctPredictions: PredictionEngine.shared.wallet.correctPredictions,
                    totalPredictions: PredictionEngine.shared.wallet.totalPredictions,
                    adsWatched: 2,
                    couponsClaimedCount: MembershipService.shared.allActiveCoupons.count,
                    homeScore: 27, awayScore: 14
                ) {
                    withAnimation { demo.showPostGameRecap = false }
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.spring(response: 0.45, dampingFraction: 0.82), value: demo.showPostGameRecap)
                .zIndex(70)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: onboardingDone)
    }

    private var mainTabs: some View {
        TabView {
            HomeView()
                .tabItem { Label("Watch", systemImage: "play.circle.fill") }

            PredictionsTabView()
                .tabItem { Label("Predict", systemImage: "sparkles") }

            RewardsWalletView()
                .tabItem { Label("Rewards", systemImage: "gift.fill") }

            QRWalletView()
                .tabItem { Label("Wallet", systemImage: "qrcode") }

            SponsorCampaignView()
                .tabItem { Label("Sponsors", systemImage: "megaphone.fill") }

            EarningsView()
                .tabItem { Label("Earnings", systemImage: "chart.line.uptrend.xyaxis") }

            MarketplaceView()
                .tabItem { Label("Shop", systemImage: "storefront.fill") }

            OperatorScanView()
                .tabItem { Label("Operator", systemImage: "qrcode.viewfinder") }
        }
        .tint(Color(red: 0.0, green: 0.82, blue: 0.60))
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
