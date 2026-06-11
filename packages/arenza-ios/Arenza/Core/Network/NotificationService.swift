// NotificationService.swift — Arenza (Phase 5: Push Notifications)
// APNs push notification registration, handling, and scheduling.
// Replaces FCM (Firebase) with native APNs for iOS.

import Foundation
import UserNotifications
import UIKit

// MARK: - Notification Service

@MainActor
final class NotificationService: NSObject, ObservableObject {
    static let shared = NotificationService()

    @Published var isAuthorized = false
    @Published var deviceToken: String?

    private override init() {
        super.init()
    }

    // MARK: - Request Permission

    func requestAuthorization() async {
        do {
            let center = UNUserNotificationCenter.current()
            let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
            isAuthorized = granted

            if granted {
                await MainActor.run {
                    UIApplication.shared.registerForRemoteNotifications()
                }
                print("[Push] Notification permission granted")
            } else {
                print("[Push] Notification permission denied")
            }
        } catch {
            print("[Push] Authorization error: \(error.localizedDescription)")
        }
    }

    // MARK: - Handle Device Token

    func didRegisterForRemoteNotifications(deviceToken data: Data) {
        let token = data.map { String(format: "%02.2hhx", $0) }.joined()
        self.deviceToken = token
        print("[Push] Device token: \(token)")

        // TODO: POST token to /v1/push/register with userId
        Task {
            await registerTokenWithServer(token: token)
        }
    }

    private func registerTokenWithServer(token: String) async {
        // TODO: Replace with actual API call
        print("[Push] Registering token with server: \(token.prefix(12))…")
    }

    // MARK: - Schedule Local Notifications

    /// Schedule a coupon expiry reminder
    func scheduleCouponExpiryReminder(couponCode: String, sponsorName: String, expiresAt: Date) {
        let twoHoursBefore = expiresAt.addingTimeInterval(-2 * 3600)
        guard twoHoursBefore > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = "⏰ Coupon Expiring Soon!"
        content.body = "Your \(sponsorName) coupon \(couponCode) expires in 2 hours."
        content.sound = .default
        content.categoryIdentifier = "COUPON_EXPIRY"
        content.userInfo = ["couponCode": couponCode, "type": "coupon_expiry"]

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: twoHoursBefore.timeIntervalSinceNow,
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: "coupon_expiry_\(couponCode)",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error {
                print("[Push] Failed to schedule coupon expiry: \(error.localizedDescription)")
            } else {
                print("[Push] Scheduled expiry reminder for \(couponCode)")
            }
        }
    }

    /// Schedule a game start reminder
    func scheduleGameReminder(gameId: String, title: String, startsAt: Date) {
        let fifteenMinBefore = startsAt.addingTimeInterval(-15 * 60)
        guard fifteenMinBefore > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = "🏈 Game Starting Soon!"
        content.body = "\(title) starts in 15 minutes. Open Arenza to earn points!"
        content.sound = .default
        content.categoryIdentifier = "GAME_REMINDER"
        content.userInfo = ["gameId": gameId, "type": "game_reminder"]

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: fifteenMinBefore.timeIntervalSinceNow,
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: "game_\(gameId)",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    /// Schedule daily engagement reminder
    func scheduleDailyCheckInReminder() {
        let content = UNMutableNotificationContent()
        content.title = "⚡ Daily Check-In Available"
        content.body = "Claim your daily AZT bonus and keep your streak alive!"
        content.sound = .default
        content.categoryIdentifier = "DAILY_CHECKIN"

        var dateComponents = DateComponents()
        dateComponents.hour = 18 // 6 PM local
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: true
        )

        let request = UNNotificationRequest(
            identifier: "daily_checkin",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Handle Notification Response

    func handleNotificationResponse(_ response: UNNotificationResponse) {
        let userInfo = response.notification.request.content.userInfo
        guard let type = userInfo["type"] as? String else { return }

        switch type {
        case "coupon_expiry":
            // Navigate to coupon wallet
            NotificationCenter.default.post(name: .navigateToCoupons, object: nil)
        case "game_reminder":
            // Navigate to watch tab
            NotificationCenter.default.post(name: .navigateToWatch, object: nil)
        case "daily_checkin":
            // Navigate to predictions tab
            NotificationCenter.default.post(name: .navigateToPredictions, object: nil)
        default:
            break
        }
    }

    // MARK: - Temporal Retention Notifications (Phase 1)

    func scheduleGamePhaseAlert(phase: TemporalRetentionService.GamePhase) {
        let content = UNMutableNotificationContent()
        content.title = "Arenza LIVE"
        content.body = phase.label + " - Open to spin & win!"
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "game_phase_\(phase.rawValue)_\(Date().timeIntervalSince1970)", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    func scheduleBonusSpinAlert(eventLabel: String, seconds: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Bonus Spin Window!"
        content.body = "\(eventLabel) - You have \(seconds) seconds to spin & win bonus rewards!"
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "bonus_spin_\(Date().timeIntervalSince1970)", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    func scheduleStreakMilestone(streak: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Streak Milestone!"
        content.body = "You have a \(streak)-day spin streak! Multiplier upgraded to \(streak >= 14 ? "3.0x" : streak >= 7 ? "2.0x" : "1.5x"). Keep it going!"
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)
        let request = UNNotificationRequest(identifier: "streak_\(streak)", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    func schedulePostGameExtensionAlert() {
        let content = UNMutableNotificationContent()
        content.title = "Your Rewards Were Extended!"
        content.body = "Great game! Your rewards have been extended 30 minutes. Don't miss out!"
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3, repeats: false)
        let request = UNNotificationRequest(identifier: "post_game_ext_\(Date().timeIntervalSince1970)", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    func scheduleRewardExpiryWarning(inMinutes minutes: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Rewards Expiring Soon!"
        content.body = "Your Arenza rewards expire in \(minutes) minutes. Visit the restaurant to claim them!"
        content.sound = .default
        guard Double(minutes * 60) > 0 else { return }
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1, Double(minutes * 60) - 60), repeats: false)
        let request = UNNotificationRequest(identifier: "reward_expiry_\(Date().timeIntervalSince1970)", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    func scheduleTierAdvancementAlert(sponsorName: String, newTier: String) {
        let content = UNMutableNotificationContent()
        content.title = "Tier Upgrade at \(sponsorName)!"
        content.body = "Congratulations! You've reached \(newTier) tier. New perks and better rewards await you."
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "tier_up_\(sponsorName)_\(newTier)", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Register Notification Categories

    func registerCategories() {
        let couponAction = UNNotificationAction(
            identifier: "VIEW_COUPON",
            title: "View Coupon",
            options: .foreground
        )

        let couponCategory = UNNotificationCategory(
            identifier: "COUPON_EXPIRY",
            actions: [couponAction],
            intentIdentifiers: [],
            options: .customDismissAction
        )

        let gameAction = UNNotificationAction(
            identifier: "WATCH_GAME",
            title: "Watch Now",
            options: .foreground
        )

        let gameCategory = UNNotificationCategory(
            identifier: "GAME_REMINDER",
            actions: [gameAction],
            intentIdentifiers: [],
            options: .customDismissAction
        )

        let dailyAction = UNNotificationAction(
            identifier: "CHECK_IN",
            title: "Check In",
            options: .foreground
        )

        let dailyCategory = UNNotificationCategory(
            identifier: "DAILY_CHECKIN",
            actions: [dailyAction],
            intentIdentifiers: [],
            options: .customDismissAction
        )

        UNUserNotificationCenter.current().setNotificationCategories([
            couponCategory, gameCategory, dailyCategory
        ])
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationService: UNUserNotificationCenterDelegate {
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        // Show banner even when app is in foreground
        return [.banner, .sound, .badge]
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        await MainActor.run {
            handleNotificationResponse(response)
        }
    }
}

// MARK: - Navigation Notifications

extension Notification.Name {
    static let navigateToCoupons = Notification.Name("navigateToCoupons")
    static let navigateToWatch = Notification.Name("navigateToWatch")
    static let navigateToPredictions = Notification.Name("navigateToPredictions")
}
