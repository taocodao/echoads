// SecureEnclaveManager.swift — Arenza Prototype
// Manages P256 signing key in Secure Enclave (device) or software (simulator).
// THIS IS THE CORE REVENUE FEATURE — hardware attestation for $45–65 CPM tier.

import Foundation
import CryptoKit
import Security

// MARK: - Protocol (abstracts SE vs simulator)

protocol SigningKeyProtocol {
    func signature(for data: Data) throws -> Data  // DER-encoded ECDSA
    var publicKeyCompressedHex: String { get }
}

// MARK: - Secure Enclave Key (Physical Device Only)

@available(iOS 14.0, *)
struct SecureEnclaveSigningKey: SigningKeyProtocol {
    private let privateKey: SecureEnclave.P256.Signing.PrivateKey

    init(privateKey: SecureEnclave.P256.Signing.PrivateKey) {
        self.privateKey = privateKey
    }

    func signature(for data: Data) throws -> Data {
        let sig = try privateKey.signature(for: data)
        return sig.derRepresentation
    }

    var publicKeyCompressedHex: String {
        privateKey.publicKey.compressedRepresentation.hexString
    }
}

// MARK: - Software Fallback Key (Simulator / testing)

struct SoftwareSigningKey: SigningKeyProtocol {
    private let privateKey: P256.Signing.PrivateKey

    init() {
        self.privateKey = P256.Signing.PrivateKey()
    }

    init(privateKey: P256.Signing.PrivateKey) {
        self.privateKey = privateKey
    }

    func signature(for data: Data) throws -> Data {
        let sig = try privateKey.signature(for: data)
        return sig.derRepresentation
    }

    var publicKeyCompressedHex: String {
        privateKey.publicKey.compressedRepresentation.hexString
    }

    var privateKeyData: Data {
        privateKey.rawRepresentation
    }
}

// MARK: - Manager

final class SecureEnclaveManager {

    static let shared = SecureEnclaveManager()

    private let keychainTag = "com.cmxs.arenza.pod-signing-key"
    private var cachedKey: (any SigningKeyProtocol)?

    private init() {}

    // MARK: - Public API

    /// Returns the signing key, creating it if needed.
    /// Automatically uses SE on device, software key on simulator.
    func getOrCreateKey() throws -> any SigningKeyProtocol {
        if let cached = cachedKey { return cached }

        #if targetEnvironment(simulator)
        let key = try getOrCreateSimulatorKey()
        cachedKey = key
        return key
        #else
        let key = try getOrCreateSecureEnclaveKey()
        cachedKey = key
        return key
        #endif
    }

    /// Sign arbitrary data — returns DER-encoded ECDSA signature
    func sign(data: Data) throws -> Data {
        let key = try getOrCreateKey()
        return try key.signature(for: data)
    }

    /// Returns the hex-encoded compressed public key for backend registration
    func publicKeyHex() throws -> String {
        let key = try getOrCreateKey()
        return key.publicKeyCompressedHex
    }

    var isUsingSecureEnclave: Bool {
        #if targetEnvironment(simulator)
        return false
        #else
        return SecureEnclave.isAvailable
        #endif
    }

    // MARK: - Secure Enclave (Device)

    @available(iOS 14.0, *)
    private func getOrCreateSecureEnclaveKey() throws -> SecureEnclaveSigningKey {
        // Try to load existing key from Keychain
        if let existingData = loadFromKeychain(),
           let key = try? SecureEnclave.P256.Signing.PrivateKey(dataRepresentation: existingData) {
            return SecureEnclaveSigningKey(privateKey: key)
        }

        // Create new SE key with biometric protection
        let accessControl = SecAccessControlCreateWithFlags(
            nil,
            kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
            [.privateKeyUsage],     // Removed .biometryCurrentSet for prototype (no Face ID prompt)
            nil
        )!

        let key = try SecureEnclave.P256.Signing.PrivateKey(
            accessControl: accessControl
        )

        // Persist the data representation to Keychain
        saveToKeychain(data: key.dataRepresentation)
        return SecureEnclaveSigningKey(privateKey: key)
    }

    // MARK: - Software Key (Simulator)

    private func getOrCreateSimulatorKey() throws -> SoftwareSigningKey {
        if let existingData = loadFromKeychain(),
           let key = try? P256.Signing.PrivateKey(rawRepresentation: existingData) {
            return SoftwareSigningKey(privateKey: key)
        }
        let key = SoftwareSigningKey()
        saveToKeychain(data: key.privateKeyData)
        return key
    }

    // MARK: - Keychain Helpers

    private func saveToKeychain(data: Data) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: keychainTag,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }

    private func loadFromKeychain() -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: keychainTag,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        SecItemCopyMatching(query as CFDictionary, &result)
        return result as? Data
    }
}

// MARK: - Data Extension

extension Data {
    var hexString: String {
        map { String(format: "%02x", $0) }.joined()
    }
}
