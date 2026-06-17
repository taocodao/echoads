// ArenzaQRToken.swift — Arenza
// Swift port of qrToken.ts (web demo)
//
// Generates time-windowed, tamper-proof QR tokens.
// Token format: ARZ-{userId}-{bizId}-{window36}-{checksum}
// Window = 5-minute epoch bucket. Checksum = FNV-1a 32-bit (base36).
//
// iOS usage:
//   let token = ArenzaQRToken.generate(userId: userId, businessId: "roccos")
//   let payload = ArenzaQRToken.validate(token: scannedString)

import Foundation

enum ArenzaQRToken {

    // MARK: - Constants
    private static let secretSalt = "ARENZA_DEMO_SALT_2026"
    private static let windowSeconds: TimeInterval = 5 * 60  // 5 min
    private static let maxWindowDelta = 2  // ±2 windows = 10 min grace

    // MARK: - Public API

    /// Generate a new token for the current 5-minute window.
    static func generate(userId: String, businessId: String = "ALL") -> String {
        let window = currentWindow()
        let windowStr = toBase36(window)
        let checksum = computeChecksum(userId: userId, businessId: businessId, windowStr: windowStr)
        return "ARZ-\(userId)-\(businessId)-\(windowStr)-\(checksum)"
    }

    struct TokenPayload {
        let valid: Bool
        let userId: String?
        let businessId: String?
        let error: String?
    }

    /// Validate a scanned token string. Returns payload if valid.
    static func validate(token: String) -> TokenPayload {
        guard token.hasPrefix("ARZ-") else {
            return TokenPayload(valid: false, userId: nil, businessId: nil, error: "Invalid token format")
        }

        let parts = token.split(separator: "-", omittingEmptySubsequences: false).map(String.init)
        // Minimum: ARZ, userId, bizId, window, checksum = 5 parts
        guard parts.count >= 5 else {
            return TokenPayload(valid: false, userId: nil, businessId: nil, error: "Malformed token")
        }

        let checksum   = parts[parts.count - 1]
        let windowStr  = parts[parts.count - 2]
        let businessId = parts[parts.count - 3]
        let userId     = parts[1..<(parts.count - 3)].joined(separator: "-")

        // Validate time window
        guard let windowInt = Int(windowStr, radix: 36) else {
            return TokenPayload(valid: false, userId: nil, businessId: nil, error: "Bad window value")
        }
        let currentW = currentWindow()
        guard abs(currentW - windowInt) <= maxWindowDelta else {
            return TokenPayload(valid: false, userId: nil, businessId: nil, error: "Token expired — customer must refresh QR")
        }

        // Validate checksum
        let expected = computeChecksum(userId: userId, businessId: businessId, windowStr: windowStr)
        guard checksum == expected else {
            return TokenPayload(valid: false, userId: nil, businessId: nil, error: "Invalid token — cannot verify")
        }

        return TokenPayload(valid: true, userId: userId, businessId: businessId, error: nil)
    }

    // MARK: - Persistent User ID (stored in Keychain)

    static func getOrCreateUserId() -> String {
        let key = "arenza_user_id"
        // Try UserDefaults for demo (Keychain in production)
        if let existing = UserDefaults.standard.string(forKey: key) { return existing }
        let newId = "U" + String((0..<7).map { _ in "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789".randomElement()! })
        UserDefaults.standard.set(newId, forKey: key)
        return newId
    }

    // MARK: - Private Helpers

    private static func currentWindow() -> Int {
        Int(Date().timeIntervalSince1970 / windowSeconds)
    }

    private static func computeChecksum(userId: String, businessId: String, windowStr: String) -> String {
        let raw = "\(userId)|\(businessId)|\(windowStr)|\(secretSalt)"
        let hash = fnv1a32(raw)
        return String(hash, radix: 36, uppercase: true)
            .padding(toLength: 6, withPad: "0", startingAt: 0)
            .prefix(6)
            .description
    }

    /// FNV-1a 32-bit hash — identical algorithm to web qrToken.ts
    private static func fnv1a32(_ str: String) -> UInt32 {
        var hash: UInt32 = 2166136261
        for byte in str.utf8 {
            hash ^= UInt32(byte)
            hash = hash &* 16777619
        }
        return hash
    }

    private static func toBase36(_ n: Int) -> String {
        String(n, radix: 36, uppercase: true)
    }
}
