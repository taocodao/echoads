// SecureEnclaveManager.swift
// Generates and manages the app's Secure Enclave P256 signing key.
// Used to produce ECDSA Proof-of-Delivery signatures for each ad impression.
//
// ⚠️  Secure Enclave is NOT available in the iOS Simulator.
//     Test PoD signing on a real iPhone or use the software fallback below.

import CryptoKit
import Security
import Foundation

final class SecureEnclaveManager {

    static let shared = SecureEnclaveManager()
    private init() {}

    private let keyTag = "com.cmxs.arenza.pod-signing-key"

    // ── Bootstrap (call from AppDelegate / @main init) ────────────────────────
    static func bootstrap() {
        _ = try? SecureEnclaveManager.shared.getOrCreateKey()
    }

    // ── Key creation / retrieval ──────────────────────────────────────────────
    func getOrCreateKey() throws -> (privateKey: SecureEnclave.P256.Signing.PrivateKey?, softKey: P256.Signing.PrivateKey?) {
        // Try Secure Enclave first (physical device)
        if let seKey = try? loadSecureEnclaveKey() {
            return (seKey, nil)
        }

        // Simulator / device without biometrics: use software key stored in Keychain
        if let softKey = loadSoftwareKey() {
            return (nil, softKey)
        }

        // Generate new keys
        do {
            let seKey = try SecureEnclave.P256.Signing.PrivateKey(
                accessControl: SecAccessControlCreateWithFlags(
                    nil,
                    kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
                    [.privateKeyUsage],
                    nil
                )!
            )
            try saveSecureEnclaveKey(seKey)
            print("[SE] Secure Enclave key created: \(walletAddress(from: seKey.publicKey))")
            return (seKey, nil)
        } catch {
            print("[SE] Secure Enclave unavailable, using software key: \(error)")
            let softKey = P256.Signing.PrivateKey()
            saveSoftwareKey(softKey)
            print("[SE] Software key wallet: \(walletAddress(from: softKey.publicKey))")
            return (nil, softKey)
        }
    }

    // ── Sign a PoD message ────────────────────────────────────────────────────
    func sign(data: Data) throws -> Data {
        let (seKey, softKey) = try getOrCreateKey()
        if let seKey = seKey {
            return try seKey.signature(for: data).derRepresentation
        } else if let softKey = softKey {
            return try softKey.signature(for: data).derRepresentation
        }
        throw SecureEnclaveError.noKeyAvailable
    }

    // ── Derive Ethereum wallet address from P256 public key ───────────────────
    // EVM uses secp256k1, but for demo purposes we hash the P256 compressed key
    // with SHA-256 and take the last 20 bytes as the "address".
    func walletAddress(from pubKey: P256.Signing.PublicKey) -> String {
        let raw = pubKey.compressedRepresentation
        let hash = SHA256.hash(data: raw)
        let addrBytes = Data(hash).suffix(20)
        return "0x" + addrBytes.map { String(format: "%02x", $0) }.joined()
    }

    func walletAddress(from pubKey: SecureEnclave.P256.Signing.PublicKey) -> String {
        let raw = pubKey.compressedRepresentation
        let hash = SHA256.hash(data: raw)
        let addrBytes = Data(hash).suffix(20)
        return "0x" + addrBytes.map { String(format: "%02x", $0) }.joined()
    }

    func currentWalletAddress() throws -> String {
        let (seKey, softKey) = try getOrCreateKey()
        if let seKey = seKey  { return walletAddress(from: seKey.publicKey) }
        if let softKey = softKey { return walletAddress(from: softKey.publicKey) }
        throw SecureEnclaveError.noKeyAvailable
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: – Keychain helpers
    // ─────────────────────────────────────────────────────────────────────────

    private func saveSecureEnclaveKey(_ key: SecureEnclave.P256.Signing.PrivateKey) throws {
        let query: [String: Any] = [
            kSecClass as String:            kSecClassGenericPassword,
            kSecAttrService as String:      keyTag + ".se",
            kSecValueData as String:        key.dataRepresentation,
            kSecAttrAccessible as String:   kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]
        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else { throw SecureEnclaveError.keychainSave(status) }
    }

    private func loadSecureEnclaveKey() throws -> SecureEnclave.P256.Signing.PrivateKey? {
        let query: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrService as String: keyTag + ".se",
            kSecReturnData as String:  true
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return try SecureEnclave.P256.Signing.PrivateKey(dataRepresentation: data)
    }

    private func saveSoftwareKey(_ key: P256.Signing.PrivateKey) {
        let query: [String: Any] = [
            kSecClass as String:          kSecClassGenericPassword,
            kSecAttrService as String:    keyTag + ".sw",
            kSecValueData as String:      key.rawRepresentation,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }

    private func loadSoftwareKey() -> P256.Signing.PrivateKey? {
        let query: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrService as String: keyTag + ".sw",
            kSecReturnData as String:  true
        ]
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else { return nil }
        return try? P256.Signing.PrivateKey(rawRepresentation: data)
    }
}

enum SecureEnclaveError: Error {
    case noKeyAvailable
    case keychainSave(OSStatus)
}
