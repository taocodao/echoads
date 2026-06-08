// ShakeGesture.swift — Arenza (Demo)
// Enables shake-to-reveal the TargetingDebugHUD in PlayerView.
// UIWindow.motionEnded broadcasts a notification; PlayerView listens via onReceive.

import UIKit

// MARK: - UIDevice Shake Notification

extension UIDevice {
    /// Broadcasted when the device is shaken. Used to toggle TargetingDebugHUD.
    static let deviceDidShakeNotification = Notification.Name("arenza.device.shake")
}

// MARK: - UIWindow Override

extension UIWindow {
    open override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        super.motionEnded(motion, with: event)
        if motion == .motionShake {
            NotificationCenter.default.post(
                name: UIDevice.deviceDidShakeNotification,
                object: nil
            )
        }
    }
}
