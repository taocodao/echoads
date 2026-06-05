// WalletDerivation.swift — Arenza Prototype
// Derives an Ethereum-compatible wallet address from a P256 public key.
//
// PRODUCTION NOTE: Proper Ethereum address derivation requires Keccak256 hashing.
// This prototype uses SHA256 as a placeholder (add swift-keccak SPM package for prod).
// The derived address is used for CMXS token reward accounting, NOT for Ethereum txs.

import Foundation
import CryptoKit

enum WalletDerivation {

    /// Derives a deterministic wallet address from P256 compressed public key hex.
    /// Format: "0x" + last 20 bytes of SHA256(uncompressed pubkey) — prototype approximation.
    static func deriveAddress(from compressedPublicKeyHex: String) -> String {
        guard let compressedData = Data(hex: compressedPublicKeyHex),
              compressedData.count == 33 else {
            return "0x0000000000000000000000000000000000000000"
        }

        // SHA256 hash of the compressed public key bytes
        // PRODUCTION: Replace with Keccak256 of uncompressed key (04 || x || y)
        let hash = SHA256.hash(data: compressedData)
        let hashData = Data(hash)

        // Take last 20 bytes → Ethereum-style address
        let addressBytes = hashData.suffix(20)
        let addressHex = addressBytes.map { String(format: "%02x", $0) }.joined()
        return "0x\(addressHex)"
    }

    /// Derives from the SecureEnclaveManager's current key
    static func currentWalletAddress() -> String {
        guard let hex = try? SecureEnclaveManager.shared.publicKeyHex() else {
            return "0x0000000000000000000000000000000000000000"
        }
        return deriveAddress(from: hex)
    }

    /// Short display format: "0x1a2b...c3d4"
    static func shortAddress(_ address: String) -> String {
        guard address.count >= 12 else { return address }
        let start = address.prefix(6)
        let end = address.suffix(4)
        return "\(start)...\(end)"
    }
}

// MARK: - Data hex init

extension Data {
    init?(hex: String) {
        let cleaned = hex.hasPrefix("0x") ? String(hex.dropFirst(2)) : hex
        guard cleaned.count % 2 == 0 else { return nil }
        var data = Data()
        var index = cleaned.startIndex
        while index < cleaned.endIndex {
            let nextIndex = cleaned.index(index, offsetBy: 2)
            guard let byte = UInt8(cleaned[index..<nextIndex], radix: 16) else { return nil }
            data.append(byte)
            index = nextIndex
        }
        self = data
    }
}
