// ArenzaTests.swift — Unit Tests
import XCTest
@testable import Arenza

final class WalletDerivationTests: XCTestCase {

    func testDeriveAddressFormat() {
        let pubKeyHex = "02" + String(repeating: "ab", count: 32) // compressed P256
        let address = WalletDerivation.deriveAddress(from: pubKeyHex)
        XCTAssertTrue(address.hasPrefix("0x"))
        XCTAssertEqual(address.count, 42)  // 0x + 40 hex chars
    }

    func testShortAddressFormat() {
        let address = "0x1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b"
        let short = WalletDerivation.shortAddress(address)
        XCTAssertTrue(short.contains("..."))
        XCTAssertLessThan(short.count, address.count)
    }

    func testInvalidKeyReturnsZeroAddress() {
        let address = WalletDerivation.deriveAddress(from: "invalid")
        XCTAssertEqual(address, "0x0000000000000000000000000000000000000000")
    }
}

final class PoDReceiptTests: XCTestCase {

    func testReceiptEncoding() throws {
        let receipt = PoDReceiptData(
            impressionId: "0xabcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890",
            nodeOperator: "0x1234567890abcdef1234567890abcdef12345678",
            channelId: "cmxs-livgolf-r2",
            cpmi: 45000,
            viewerIFA: "anon-test-id",
            timestamp: 1717459200,
            adComplete: true
        )

        let data = receipt.jsonData
        XCTAssertNotNil(data)

        let decoded = try JSONDecoder().decode(PoDReceiptData.self, from: data!)
        XCTAssertEqual(decoded.impressionId, receipt.impressionId)
        XCTAssertEqual(decoded.cpmi, 45000)
        XCTAssertTrue(decoded.adComplete)
    }
}

final class DataHexTests: XCTestCase {

    func testHexInit() {
        let hex = "deadbeef"
        let data = Data(hex: hex)
        XCTAssertNotNil(data)
        XCTAssertEqual(data?.count, 4)
    }

    func testHexInitWith0xPrefix() {
        let data = Data(hex: "0xdeadbeef")
        XCTAssertNotNil(data)
        XCTAssertEqual(data?.count, 4)
    }

    func testHexString() {
        let data = Data([0xde, 0xad, 0xbe, 0xef])
        XCTAssertEqual(data.hexString, "deadbeef")
    }

    func testOddLengthFails() {
        XCTAssertNil(Data(hex: "abc"))
    }
}

final class SecureEnclaveManagerTests: XCTestCase {

    func testKeyCreation() throws {
        // On Simulator: creates software key
        // On Device: creates SE key
        let manager = SecureEnclaveManager.shared
        let key = try manager.getOrCreateKey()
        let pubKeyHex = key.publicKeyCompressedHex
        XCTAssertFalse(pubKeyHex.isEmpty)
        XCTAssertEqual(pubKeyHex.count, 66)  // 33 bytes × 2 hex chars
    }

    func testSigningProducesDERSignature() throws {
        let manager = SecureEnclaveManager.shared
        let testData = Data("test-impression-id".utf8)
        let signature = try manager.sign(data: testData)
        // DER signature is at least 70 bytes for P256
        XCTAssertGreaterThanOrEqual(signature.count, 70)
    }

    func testPublicKeyHex() throws {
        let hex = try SecureEnclaveManager.shared.publicKeyHex()
        XCTAssertFalse(hex.isEmpty)
        // Compressed P256 key: starts with 02 or 03
        XCTAssertTrue(hex.hasPrefix("02") || hex.hasPrefix("03"))
    }
}

final class ChannelTests: XCTestCase {

    func testDemoChannelsNotEmpty() {
        XCTAssertGreaterThan(Channel.demoChannels.count, 0)
    }

    func testAtLeastOneLiveChannel() {
        let live = Channel.demoChannels.filter(\.isLive)
        XCTAssertGreaterThan(live.count, 0)
    }
}
