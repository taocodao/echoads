# Arenza iPhone App — Complete Implementation Plan for Antigravity
## CMXS Network Integration · iOS/tvOS · Production-Ready Specification

**Document Purpose:** This is a hand-off specification for Antigravity to design and code the Arenza iOS (and tvOS) app that connects to the existing CMXS backend. Every section contains exact API endpoints, data structures, Swift code patterns, and acceptance criteria. No ambiguity should remain after reading this document.

**App Name:** Arenza  
**Bundle ID:** `com.cmxs.arenza`  
**Minimum iOS Target:** iOS 17.0  
**tvOS Target:** tvOS 17.0 (shared codebase, multiplatform SwiftUI)  
**Primary Language:** Swift 5.10 / SwiftUI  
**Architecture:** MVVM + Combine + async/await  
**Backend:** Existing CMXS microservices (AWS API Gateway + Node.js/Rust/Go services)  

---

## Part 1: Executive Summary & Scope

Arenza is the consumer-facing iPhone and Apple TV app for the CMXS sports FAST platform. It connects to the already-built CMXS backend infrastructure — the video ingest pipeline (AWS MediaLive/MediaPackage), the SSAI programmatic ad stack (AWS MediaTailor + Custom SSP), the blockchain PoD verification layer (DeliveryOracle.sol on Base L2), and the DePIN viewer-node contribution system.

The app's five revenue-critical features are non-negotiable requirements, not enhancements:

1. **MoQ/QUIC-backed live video playback** via Caton C3CVP SDK — Wi-Fi-to-5G seamless handoff
2. **SCTE-35 ad break detection** via `AVPlayerItemMetadataOutputPushDelegate` — triggers OpenRTB auction at T=0ms
3. **iOS Secure Enclave ECDSA PoD signing** via `SecureEnclave.P256.Signing.PrivateKey` — hardware-attested impression receipts submitted to DeliveryOracle.sol
4. **SGAI interactive overlay system** — shoppable ads, fan polls, in-play betting prompts, double-box squeeze-back
5. **APNs push notifications** — game start reminders, score alerts with sponsored overlays, shoppable product pushes

These five features together unlock the $45–65 verified CPM tier. Any implementation that omits or approximates any of these five will reduce CPM to $20–28 (unverified SSAI baseline) and destroy the revenue model.

---

## Part 2: Architecture Overview

### 2.1 System Context Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                    ARENZA iOS APP                               │
│                                                                 │
│  ┌──────────────┐  ┌────────────────┐  ┌───────────────────┐  │
│  │ Video Player │  │  Ad Engine     │  │  PoD Module       │  │
│  │ AVFoundation │  │  SCTE-35 +     │  │  SecureEnclave    │  │
│  │ + MoQ/QUIC   │  │  SGAI Overlay  │  │  ECDSA Signer     │  │
│  └──────┬───────┘  └───────┬────────┘  └────────┬──────────┘  │
│         │                  │                     │             │
│  ┌──────▼──────────────────▼─────────────────────▼──────────┐  │
│  │                   CMXS API Client                        │  │
│  │  REST (API Gateway) + WebSocket (live events)            │  │
│  └────────────────────────┬─────────────────────────────────┘  │
│                           │                                     │
│  ┌────────────────────────▼─────────────────────────────────┐  │
│  │   DePIN Node Service (BGProcessingTask - background)     │  │
│  │   Bandwidth contribution → CMXS token rewards            │  │
│  └──────────────────────────────────────────────────────────┘  │
└──────────────────────────────┬──────────────────────────────────┘
                               │ HTTPS / WebSocket / QUIC
┌──────────────────────────────▼──────────────────────────────────┐
│               CMXS BACKEND (already built)                      │
│                                                                 │
│  Content Service  │  Ad Service     │  PoD Oracle Service       │
│  (EPG, channels)  │  (SSP/OpenRTB)  │  (Base L2 bridge)        │
│                   │                 │                           │
│  AWS MediaTailor  │  DeliveryOracle │  Node Mgmt Service        │
│  (SSAI manifest)  │  .sol on Base   │  (rewards, staking)       │
└─────────────────────────────────────────────────────────────────┘
```

### 2.2 iOS App Module Structure

```
Arenza/
├── App/
│   ├── ArenzaApp.swift              # @main entry point
│   ├── AppEnvironment.swift         # Dependency injection container
│   └── AppRouter.swift              # NavigationPath-based routing
│
├── Features/
│   ├── Home/
│   │   ├── HomeView.swift           # Channel grid + featured live events
│   │   └── HomeViewModel.swift
│   ├── Player/
│   │   ├── PlayerView.swift         # Full-screen video player
│   │   ├── PlayerViewModel.swift    # SCTE-35, SGAI, PoD orchestration
│   │   ├── SCTE35Detector.swift     # AVPlayerItemMetadataOutputPushDelegate
│   │   ├── SGAIOverlayView.swift    # Interactive ad overlay rendering
│   │   └── PoDBroadcastSigner.swift # Secure Enclave signing
│   ├── EPG/
│   │   ├── EPGView.swift            # Electronic Program Guide
│   │   └── EPGViewModel.swift
│   ├── Channels/
│   │   ├── ChannelListView.swift    # All CMXS channels
│   │   └── ChannelDetailView.swift  # Channel page + schedule
│   ├── Commerce/
│   │   ├── ShoppableOverlayView.swift  # x402 purchase overlay
│   │   ├── ProductDetailSheet.swift    # Product info + Apple Pay
│   │   └── CommerceViewModel.swift
│   ├── DePINNode/
│   │   ├── NodeDashboardView.swift  # Earnings, uptime, wallet
│   │   └── NodeService.swift        # BGProcessingTask node logic
│   ├── Wallet/
│   │   ├── WalletView.swift         # CMXS token balance + USDC
│   │   └── WalletViewModel.swift
│   └── Notifications/
│       ├── NotificationManager.swift  # APNs registration + handling
│       └── NotificationPayloadParser.swift
│
├── Core/
│   ├── Network/
│   │   ├── CMXSAPIClient.swift      # URLSession-based REST client
│   │   ├── CMXSWebSocketClient.swift # Live event WebSocket
│   │   └── MoQStreamClient.swift    # Caton C3CVP MoQ integration
│   ├── SecureEnclave/
│   │   ├── SecureEnclaveManager.swift  # Key generation + signing
│   │   └── WalletDerivation.swift      # Ethereum address from P256 pubkey
│   ├── Blockchain/
│   │   ├── BaseL2Client.swift       # JSON-RPC to Base L2
│   │   ├── PoDBroadcastReceipt.swift # Receipt data structure
│   │   └── OracleBeaconSubmitter.swift # Submit signed receipts
│   ├── Models/
│   │   ├── Channel.swift
│   │   ├── Program.swift
│   │   ├── AdBreak.swift
│   │   ├── ImpressioReceipt.swift
│   │   └── CMXSNode.swift
│   └── Extensions/
│       ├── AVPlayer+SCTE35.swift
│       └── View+SGAIOverlay.swift
│
└── Resources/
    ├── Assets.xcassets
    ├── Localizable.strings
    └── Info.plist
```

### 2.3 Technology Stack

| Layer | Technology | Version / Notes |
|---|---|---|
| UI Framework | SwiftUI | iOS 17+ only — no UIKit fallbacks needed |
| Navigation | NavigationStack + NavigationPath | iOS 16+ |
| Video Playback | AVFoundation + AVKit | Native HLS, SSAI manifest injection |
| MoQ/QUIC transport | Caton C3CVP SDK | Import via Swift Package Manager |
| SCTE-35 detection | AVPlayerItemMetadataOutput | `AVPlayerItemMetadataOutputPushDelegate` |
| Secure Enclave | CryptoKit `SecureEnclave.P256` | iOS 14+, requires `NSFaceIDUsageDescription` |
| Push Notifications | UserNotifications + APNs | `UNUserNotificationCenterDelegate` |
| Background tasks | BackgroundTasks framework | `BGProcessingTask` for DePIN node |
| Networking | URLSession async/await | No Alamofire — keep dependencies minimal |
| State management | Combine + `@StateObject` | No Redux/TCA — MVVM is sufficient |
| Dependency injection | Swift's native `@Environment` | `AppEnvironment` container |
| Blockchain reads | JSON-RPC over HTTPS | Direct calls to Base L2 RPC |
| Payments | Apple Pay (PassKit) | For x402 commerce overlay |
| Analytics | CMXS custom analytics SDK | Provided by CMXS team |
| Testing | XCTest + XCUITest | Unit + integration tests |
| CI/CD | Xcode Cloud | Fastlane for TestFlight distribution |

---

## Part 3: Backend API Reference

All API calls go through: `https://api.cmxs.io/v1/`  
Authentication: Bearer JWT (obtained via `/auth/token`)  
Content-Type: `application/json`  
WebSocket base: `wss://live.cmxs.io/`

### 3.1 Authentication Endpoints

```
POST /auth/device-register
Body: { "deviceId": "<UIDevice.current.identifierForVendor>", 
        "publicKey": "<SecureEnclave P256 compressed pubkey hex>",
        "platform": "ios",
        "appVersion": "1.0.0" }
Response: { "deviceToken": "<JWT>", "walletAddress": "<0x...>", "refreshToken": "<...>" }

POST /auth/refresh
Body: { "refreshToken": "<token>" }
Response: { "deviceToken": "<new JWT>" }
```

**iOS Implementation Note:** The `publicKey` sent here is the Ethereum-compatible public key derived from the Secure Enclave P256 key. This registers the device as a PoD signer in the CMXS system. Store `walletAddress` in Keychain, NOT UserDefaults.

### 3.2 Content Service Endpoints

```
GET /channels
Response: { "channels": [Channel], "featured": [Channel] }

GET /channels/{channelId}
Response: Channel object

GET /channels/{channelId}/epg?date=2026-06-04&hours=24
Response: { "programs": [Program] }

GET /channels/{channelId}/stream
Response: { 
  "ssaiManifestUrl": "https://mediatailor.us-east-1.amazonaws.com/v1/manifest/...",
  "moqRelayUrl": "https://us-west.moq-demo.liveviewing.com:4444/anon",
  "drmLicenseUrl": "https://fairplay.cmxs.io/license",
  "channelId": "...",
  "currentProgram": Program
}

GET /search?q={query}&type=channel,program
Response: { "results": [SearchResult] }
```

### 3.3 Ad Service Endpoints (called internally by PoD module — NOT by app UI)

```
POST /ad/break-detected
Body: {
  "channelId": "...",
  "programId": "...",
  "breakDuration": 30,
  "scte35CueId": "...",
  "ifa": "<hashed IFA or anonymous hash>",
  "deviceToken": "<JWT>",
  "timestamp": 1717459200
}
Response: {
  "bidId": "cmxs-bid-001",
  "adCreativeUrl": "https://ads.cmxs.io/creative/...",
  "impressionId": "...",
  "winningCPM": 45.00,
  "sgaiOverlay": {
    "enabled": true,
    "type": "shoppable|poll|betting|squeeze_back",
    "activateAtSecond": 20,
    "payload": { ... }
  }
}

POST /ad/beacon
Body: {
  "impressionId": "...",
  "event": "impression|quartile_25|quartile_50|quartile_75|complete",
  "timestamp": 1717459230,
  "podSignature": "<ECDSA sig from Secure Enclave>",
  "viewerIFA": "...",
  "nodeOperatorAddress": "<0x...>"
}
Response: { "podReceiptTxHash": "<Base L2 tx hash>", "tokenReward": 0.001 }
```

### 3.4 PoD Oracle Service (app submits signed receipts here)

```
POST /pod/submit-receipt
Body: {
  "impressionId": "...",
  "signature": "<DER-encoded ECDSA signature hex>",
  "publicKey": "<compressed P256 pubkey hex>",
  "receiptData": {
    "impressionId": "...",
    "timestamp": 1717459230,
    "ifa": "...",
    "channelId": "...",
    "cpmi": 45000
  }
}
Response: { "accepted": true, "txHash": "<Base L2 tx>", "reward": 0.001 }

GET /pod/receipts?address={walletAddress}&limit=50
Response: { "receipts": [PodReceipt], "totalImpressions": 1234, "totalRewards": 1.234 }
```

### 3.5 Node Service Endpoints

```
POST /node/register
Body: {
  "walletAddress": "0x...",
  "deviceType": "iphone|ipad|appletv",
  "uplinkMbps": 45.2,
  "geoHash": "9q5c" // H3 geohash, no precise location
}
Response: { "nodeId": "...", "nodeType": "viewer_node", "rewardMultiplier": 1.3 }

POST /node/heartbeat
Body: { "nodeId": "...", "uptimeSeconds": 3600, "bytesServed": 1073741824 }
Response: { "rewardAccrued": 0.005, "totalBalance": 1.250 }

GET /node/earnings?address={walletAddress}
Response: { 
  "pendingCMXS": 0.045,
  "claimedCMXS": 12.34,
  "uptimeHours": 240,
  "impressionsVerified": 4500
}
```

### 3.6 Wallet / Commerce Endpoints

```
GET /wallet/balance?address={walletAddress}
Response: { "cmxsBalance": 12.34, "usdcBalance": 0.00, "walletAddress": "0x..." }

POST /commerce/checkout
Body: {
  "productId": "...",
  "impressionId": "...",   // links purchase to ad impression
  "paymentMethod": "apple_pay|usdc",
  "deviceToken": "<JWT>"
}
Response: { "orderId": "...", "paymentUrl": "...", "usdcAmount": 0.00 }

GET /commerce/products/{productId}
Response: { "product": Product }
```

### 3.7 WebSocket Events (Live Channel Updates)

Connect to: `wss://live.cmxs.io/channel/{channelId}?token={JWT}`

```json
// Score update (triggers sponsored push notification)
{ "type": "score_update", "data": { "homeScore": 1, "awayScore": 0, "minute": 23, "sponsorId": "modelo" }}

// Ad break incoming (app pre-buffers)
{ "type": "ad_break_incoming", "data": { "startsInSeconds": 15, "duration": 30 }}

// SGAI overlay activation
{ "type": "sgai_activate", "data": { "overlayType": "shoppable", "impressionId": "...", "product": {...} }}

// Program change
{ "type": "program_change", "data": { "program": Program }}
```

### 3.8 APNs Push Notification Payload Structures

```json
// Game start reminder
{
  "aps": { "alert": { "title": "LIV Golf Round 2 🏌️", "body": "Starting in 5 minutes — tap to watch free" },
           "badge": 1, "sound": "default", "content-available": 1 },
  "cmxs": { "type": "game_start", "channelId": "livgolf-r2", "deepLink": "arenza://channel/livgolf-r2" }
}

// Score alert with sponsor
{
  "aps": { "alert": { "title": "⚽ USA Scores! 1-0", "body": "Sponsored by Modelo · Tap to watch" },
           "sound": "goal.caf" },
  "cmxs": { "type": "score_alert", "channelId": "...", "sponsorId": "modelo", "impressionId": "..." }
}

// Shoppable product push
{
  "aps": { "alert": { "title": "The driver Tiger just hit 🏌️", "body": "Callaway Paradym — $549 · Tap to see" }},
  "cmxs": { "type": "shoppable", "productId": "callaway-paradym-driver", "impressionId": "...", 
             "deepLink": "arenza://product/callaway-paradym-driver" }
}
```

---

## Part 4: Core Feature Implementation

### 4.1 Feature 1 — MoQ/QUIC Video Playback with Wi-Fi-to-5G Handoff

**Integration:** Caton C3CVP SDK handles the MoQ transport layer. The CMXS backend (`GET /channels/{id}/stream`) returns both a `ssaiManifestUrl` (standard HLS fallback) and a `moqRelayUrl` (Caton relay endpoint). Use MoQ first; fall back to HLS SSAI if MoQ unavailable.

```swift
// Core/Network/MoQStreamClient.swift
import CatonC3CVP  // Caton SDK via SPM

class MoQStreamClient: ObservableObject {
    private var session: C3CVPSession?
    
    func connect(to relayURL: URL, fallbackSSAI: URL) async throws -> URL {
        do {
            session = try await C3CVPSession(relayURL: relayURL)
            let streamURL = try await session!.resolveStreamURL()
            return streamURL  // Returns playable HLS URL via MoQ transport
        } catch {
            // Fallback to standard SSAI HLS on MoQ failure
            return fallbackSSAI
        }
    }
    
    // QUIC connection migration happens automatically in C3CVP
    // Wi-Fi → 5G handoff is transparent — no app code required
    // C3CVP maintains QUIC connection ID across network changes
}
```

**AVPlayer setup with SSAI manifest injection:**

```swift
// Features/Player/PlayerViewModel.swift
func startPlayback(channel: Channel) async {
    let streamInfo = try await apiClient.getStream(channelId: channel.id)
    
    // Prefer MoQ; fall back to SSAI HLS
    let playbackURL = try await moqClient.connect(
        to: streamInfo.moqRelayUrl,
        fallbackSSAI: streamInfo.ssaiManifestUrl
    )
    
    let playerItem = AVPlayerItem(url: playbackURL)
    
    // Register SCTE-35 metadata delegate (Feature 2)
    let metadataOutput = AVPlayerItemMetadataOutput(identifiers: nil)
    metadataOutput.setDelegate(scte35Detector, queue: .main)
    playerItem.add(metadataOutput)
    
    // FairPlay DRM
    if let drmURL = streamInfo.drmLicenseUrl {
        let contentKeySession = AVContentKeySession(keySystem: .fairPlayStreaming)
        contentKeySession.setDelegate(fairPlayDelegate, queue: .main)
        contentKeySession.addContentKeyRecipient(playerItem)
    }
    
    player.replaceCurrentItem(with: playerItem)
    player.play()
}
```

**Acceptance Criteria:**
- [ ] Stream plays at correct ABR profile for network conditions (360p to 4K)
- [ ] Wi-Fi to 5G transition causes zero rebuffer (verify with Network Link Conditioner)
- [ ] FairPlay DRM license fetched correctly for protected content
- [ ] Playback resumes after app backgrounding (Background Modes: `audio`)

---

### 4.2 Feature 2 — SCTE-35 Ad Break Detection

**This is the timing engine for all ad monetization.** The SCTE-35 detector fires at T=0ms of an ad break, triggering the OpenRTB auction via the Ad Service. The auction must complete (T=150ms) before the break is visible to the viewer.

```swift
// Features/Player/SCTE35Detector.swift
import AVFoundation

class SCTE35Detector: NSObject, AVPlayerItemMetadataOutputPushDelegate {
    weak var playerViewModel: PlayerViewModel?
    
    func metadataOutput(_ output: AVPlayerItemMetadataOutput,
                        didOutputTimedMetadataGroups groups: [AVTimedMetadataGroup],
                        from track: AVPlayerItemTrack?) {
        for group in groups {
            for item in group.items {
                // SCTE-35 splice insert detection
                if item.identifier == AVMetadataIdentifier("urn:scte:scte35:2013:bin") ||
                   item.key as? String == "com.apple.streaming.transportStreamTimestamp" {
                    
                    guard let data = item.dataValue else { continue }
                    let cue = parseSCTE35(data)
                    
                    if cue.spliceInsert != nil {
                        let duration = cue.spliceInsert?.breakDuration ?? 30.0
                        Task { @MainActor in
                            await playerViewModel?.handleAdBreak(
                                duration: duration,
                                cueId: cue.spliceEventId
                            )
                        }
                    }
                }
            }
        }
    }
    
    private func parseSCTE35(_ data: Data) -> SCTE35Cue {
        // Parse SCTE-35 binary splice_info_section
        // Reference: SCTE 35 2022 spec, Table 5
        var cue = SCTE35Cue()
        // ... parsing implementation
        return cue
    }
}

// PlayerViewModel handles the break
func handleAdBreak(duration: Double, cueId: String) async {
    // T=0ms: SCTE-35 detected
    let breakRequest = AdBreakRequest(
        channelId: currentChannel.id,
        programId: currentProgram.id,
        breakDuration: duration,
        scte35CueId: cueId,
        ifa: identityManager.hashedIFA,
        timestamp: Date().timeIntervalSince1970
    )
    
    // T=0–150ms: OpenRTB auction
    let adResponse = try await apiClient.detectAdBreak(breakRequest)
    
    // T=150ms: Begin SGAI overlay preparation
    if adResponse.sgaiOverlay.enabled {
        scheduleSGAIOverlay(adResponse.sgaiOverlay, impressionId: adResponse.impressionId)
    }
    
    // Schedule PoD signing at ad completion (T+30s)
    schedulePoD(impressionId: adResponse.impressionId, 
                cpm: adResponse.winningCPM,
                completesAt: Date().addingTimeInterval(duration))
}
```

**Acceptance Criteria:**
- [ ] SCTE-35 metadata detected with <50ms latency from HLS segment boundary
- [ ] Ad Service POST fires within 50ms of detection
- [ ] No missed ad breaks during live sports (test with LIV Golf SCTE-35 test stream)
- [ ] SGAI overlay scheduled correctly based on ad response payload

---

### 4.3 Feature 3 — iOS Secure Enclave ECDSA PoD Signing

**This is the hardware-attestation mechanism that justifies the $45–65 CPM tier.** Every ad impression generates a unique ECDSA signature from the Secure Enclave that proves a real iPhone (not a bot) received the ad. The signature goes on-chain via DeliveryOracle.sol on Base L2.

```swift
// Core/SecureEnclave/SecureEnclaveManager.swift
import CryptoKit
import Security

class SecureEnclaveManager {
    private static let keyTag = "com.cmxs.arenza.pod-signing-key"
    
    // Called once on first app launch
    static func getOrCreateSigningKey() throws -> SecureEnclave.P256.Signing.PrivateKey {
        // Try to load existing key
        if let existingKey = try? loadKey() {
            return existingKey
        }
        // Generate new key in Secure Enclave
        let key = try SecureEnclave.P256.Signing.PrivateKey(
            accessControl: SecAccessControlCreateWithFlags(
                nil,
                kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
                [.privateKeyUsage, .biometryCurrentSet],  // Biometric protection
                nil
            )!
        )
        try saveKey(key)
        return key
    }
    
    // Sign a PoD receipt — called at ad completion (T+30s)
    static func signPoDReceipt(_ receipt: PoDBroadcastReceipt) throws -> Data {
        let key = try getOrCreateSigningKey()
        let data = try JSONEncoder().encode(receipt)
        let signature = try key.signature(for: data)
        return signature.derRepresentation
    }
    
    // Derive Ethereum-compatible wallet address from P256 public key
    static func deriveWalletAddress(from publicKey: P256.Signing.PublicKey) -> String {
        // Uncompressed pubkey: 04 || x || y (64 bytes, no prefix)
        let rawRepresentation = publicKey.rawRepresentation
        let x = rawRepresentation.prefix(32)
        let y = rawRepresentation.suffix(32)
        let uncompressed = x + y
        
        // Keccak256 hash → take last 20 bytes → EIP-55 checksum
        let hash = SHA256.hash(data: uncompressed)  // Use proper keccak256 lib
        let address = "0x" + Data(hash.suffix(20)).hexEncodedString().checksumEncoded
        return address
    }
}
```

**PoD Receipt Data Structure (must match DeliveryOracle.sol ABI):**

```swift
// Core/Blockchain/PoDBroadcastReceipt.swift
struct PoDBroadcastReceipt: Codable {
    let impressionId: String        // OpenRTB bid ID, keccak256 hashed
    let nodeOperator: String        // 0x... Ethereum wallet address
    let channelId: String
    let cpmi: UInt16               // CPM in milli-dollars: 45000 = $45.00
    let viewerIFA: String          // Hashed IFA or anonymous hash if ATT denied
    let timestamp: UInt32          // Unix timestamp
    let adComplete: Bool           // True if 80%+ of ad was viewed
    
    // Keccak256 of encoded receipt for signing
    func keccak256() throws -> Data {
        let encoded = try JSONEncoder().encode(self)
        // Use keccak256 (not SHA256) — Base L2 compatibility required
        // Use web3swift or CryptoSwift for keccak256
        return keccak256Hash(encoded)
    }
}
```

**Oracle Submission:**

```swift
// Core/Blockchain/OracleBeaconSubmitter.swift
class OracleBeaconSubmitter {
    func submitPoDReceipt(impressionId: String, cpm: Double) async throws {
        let ifa = ATTrackingManager.trackingAuthorizationStatus == .authorized
            ? ASIdentifierManager.shared().advertisingIdentifier.uuidString
            : UUID().uuidString.hashed(algorithm: .sha256)  // Anonymized
        
        let receipt = PoDBroadcastReceipt(
            impressionId: impressionId,
            nodeOperator: walletAddress,
            channelId: currentChannelId,
            cpmi: UInt16(cpm * 1000),
            viewerIFA: ifa,
            timestamp: UInt32(Date().timeIntervalSince1970),
            adComplete: true
        )
        
        let signature = try SecureEnclaveManager.signPoDReceipt(receipt)
        
        let submission = PoDSubmission(
            impressionId: impressionId,
            signature: signature.hexEncodedString,
            publicKey: signingPublicKeyHex,
            receiptData: receipt
        )
        
        let result = try await apiClient.submitPoDReceipt(submission)
        // result.txHash = Base L2 transaction hash — store for user's earnings dashboard
        await walletViewModel.recordEarning(txHash: result.txHash, reward: result.reward)
    }
}
```

**Acceptance Criteria:**
- [ ] Secure Enclave key created on first launch and persists across app updates
- [ ] Signing completes in <100ms (benchmark on iPhone XS or newer)
- [ ] Wallet address derived correctly and matches CMXS backend registration
- [ ] PoD receipt submitted within 35 seconds of ad completion
- [ ] Base L2 tx hash returned and displayed in earnings dashboard
- [ ] App handles Face ID authentication failure gracefully (fallback signing)

---

### 4.4 Feature 4 — SGAI Interactive Overlay System

**SGAI overlays are the primary CPM multiplier.** Dolby production deployments proved 76% eCPM improvement. Four overlay types are required:

**Overlay Types:**

| Type | Trigger | User Action | Revenue Event |
|---|---|---|---|
| `shoppable` | At 20s of 30s ad | Tap → product sheet → Apple Pay | 1.5% commerce fee |
| `poll` | During natural breaks | Tap option | Sponsor impression uplift |
| `betting` | Live odds update | Tap → sportsbook deep link | Affiliate CPA |
| `squeeze_back` | Full ad break | None (passive) | Premium non-interruptive CPM |

```swift
// Features/Player/SGAIOverlayView.swift
struct SGAIOverlayView: View {
    @Binding var overlay: SGAIOverlay?
    @State private var isExpanded = false
    let onInteraction: (SGAIInteraction) -> Void
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            if let overlay = overlay {
                switch overlay.type {
                case .shoppable:
                    ShoppableOverlayCard(overlay: overlay, isExpanded: $isExpanded)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                isExpanded = true
                            }
                            onInteraction(.tap(impressionId: overlay.impressionId))
                        }
                    
                case .poll:
                    PollOverlayView(overlay: overlay)
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                    
                case .betting:
                    BettingOddsOverlay(overlay: overlay)
                        .transition(.asymmetric(insertion: .scale, removal: .opacity))
                    
                case .squeeze_back:
                    // Content reduced to 75% — ad occupies remaining 25%
                    EmptyView()  // Layout handled by PlayerView geometry
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: overlay?.id)
    }
}

// Shoppable overlay — the highest-value interaction
struct ShoppableOverlayCard: View {
    let overlay: SGAIOverlay
    @Binding var isExpanded: Bool
    @State private var product: Product?
    
    var body: some View {
        Group {
            if isExpanded {
                ProductDetailSheet(product: product, impressionId: overlay.impressionId)
            } else {
                // Compact overlay card
                HStack(spacing: 12) {
                    AsyncImage(url: overlay.payload.productImageURL) { image in
                        image.resizable().aspectRatio(contentMode: .fill)
                    } placeholder: { Color.gray.opacity(0.3) }
                    .frame(width: 48, height: 48)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(overlay.payload.productName)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                        Text(overlay.payload.priceFormatted)
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    Spacer()
                    
                    Text("Tap to Buy")
                        .font(.system(size: 11, weight: .bold))
                        .padding(.horizontal, 10).padding(.vertical, 6)
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                }
                .padding(12)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 16).padding(.bottom, 80)
            }
        }
    }
}
```

**Apple Pay integration for commerce checkout:**

```swift
// Features/Commerce/CommerceViewModel.swift
import PassKit

class CommerceViewModel: NSObject, ObservableObject, PKPaymentAuthorizationControllerDelegate {
    func initiateApplePay(product: Product, impressionId: String) {
        let paymentRequest = PKPaymentRequest()
        paymentRequest.merchantIdentifier = "merchant.com.cmxs.arenza"
        paymentRequest.supportedNetworks = [.visa, .masterCard, .amex, .discover]
        paymentRequest.merchantCapabilities = .threeDSecure
        paymentRequest.countryCode = "US"
        paymentRequest.currencyCode = "USD"
        paymentRequest.paymentSummaryItems = [
            PKPaymentSummaryItem(label: product.name, amount: NSDecimalNumber(string: product.price)),
            PKPaymentSummaryItem(label: "Arenza", amount: NSDecimalNumber(string: product.price))
        ]
        
        let controller = PKPaymentAuthorizationController(paymentRequest: paymentRequest)
        controller.delegate = self
        controller.present()
        
        self.pendingImpressionId = impressionId  // Links purchase to ad impression
    }
    
    func paymentAuthorizationController(_ controller: PKPaymentAuthorizationController,
                                        didAuthorizePayment payment: PKPayment) async -> PKPaymentAuthorizationResult {
        // Submit to CMXS commerce endpoint
        let result = try? await apiClient.checkout(
            productId: pendingProductId,
            impressionId: pendingImpressionId,
            paymentToken: payment.token.paymentData.base64EncodedString()
        )
        return PKPaymentAuthorizationResult(status: result != nil ? .success : .failure, errors: nil)
    }
}
```

**Acceptance Criteria:**
- [ ] Shoppable overlay appears at exactly T=20s of 30s ad (configurable via SGAI payload)
- [ ] Overlay tap-to-expand animation completes in <300ms
- [ ] Apple Pay sheet presented correctly with product details
- [ ] Purchase completion triggers 1.5% fee transaction to CMXS oracle
- [ ] Poll results submitted to CMXS analytics within 2s of user selection
- [ ] Squeeze-back layout resizes content view to 75% width (AVPlayerViewController frame constraint)
- [ ] All overlays dismiss automatically when ad ends

---

### 4.5 Feature 5 — APNs Push Notifications

**Push notifications drive viewership spikes during high-CPM opening segments.** 7.8% CTR in 2026 — 3× higher than email.

```swift
// Notifications/NotificationManager.swift
import UserNotifications
import UIKit

class NotificationManager: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    
    func requestPermission() async -> Bool {
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        
        let granted = try? await center.requestAuthorization(options: [.alert, .badge, .sound])
        if granted == true {
            await MainActor.run {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
        return granted ?? false
    }
    
    // Called by AppDelegate.application(_:didRegisterForRemoteNotificationsWithDeviceToken:)
    func registerDeviceToken(_ deviceToken: Data) async {
        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        try? await apiClient.registerAPNsToken(tokenString, walletAddress: walletAddress)
    }
    
    // Foreground notification handling
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        // Always show notifications even when app is in foreground
        return [.banner, .badge, .sound]
    }
    
    // Deep link handling from notification tap
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse) async {
        let userInfo = response.notification.request.content.userInfo
        guard let cmxsPayload = userInfo["cmxs"] as? [String: Any],
              let type = cmxsPayload["type"] as? String else { return }
        
        switch type {
        case "game_start", "score_alert":
            if let channelId = cmxsPayload["channelId"] as? String {
                await MainActor.run {
                    appRouter.navigate(to: .channel(channelId))
                }
            }
        case "shoppable":
            if let productId = cmxsPayload["productId"] as? String,
               let impressionId = cmxsPayload["impressionId"] as? String {
                await MainActor.run {
                    appRouter.navigate(to: .product(productId, impressionId: impressionId))
                }
                // Submitting PoD for notification-triggered impression
                await oracleSubmitter.submitNotificationImpression(impressionId: impressionId)
            }
        default: break
        }
    }
}
```

**Deep link scheme:** `arenza://channel/{channelId}` | `arenza://product/{productId}` | `arenza://wallet`

Configure in Info.plist:
```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLName</key>
        <string>com.cmxs.arenza</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>arenza</string>
        </array>
    </dict>
</array>
```

**Acceptance Criteria:**
- [ ] APNs device token registered with CMXS backend on first launch
- [ ] All three notification types render correctly (game_start, score_alert, shoppable)
- [ ] Deep links navigate to correct screen
- [ ] Notification permission prompt follows Apple HIG timing (shown after first value moment)
- [ ] Badge count cleared on app open

---

## Part 5: Additional Features

### 5.1 Electronic Program Guide (EPG)

Full-screen EPG showing 24-hour schedule across all CMXS channels.

```swift
// Features/EPG/EPGView.swift
struct EPGView: View {
    @StateObject var vm = EPGViewModel()
    
    var body: some View {
        ScrollView([.horizontal, .vertical]) {
            LazyHStack(alignment: .top, spacing: 0) {
                // Time axis (fixed left column)
                TimeAxisColumn()
                
                // Channel rows
                ForEach(vm.channels) { channel in
                    EPGChannelRow(channel: channel, programs: vm.programs[channel.id] ?? [])
                        .containerRelativeFrame(.horizontal, count: 6, spacing: 8)
                }
            }
        }
        .task { await vm.loadEPG() }
    }
}
```

### 5.2 DePIN Node Dashboard

Shows the viewer's node contribution status, earnings, and CMXS token balance.

```swift
// Features/DePINNode/NodeDashboardView.swift
struct NodeDashboardView: View {
    @StateObject var vm = NodeDashboardViewModel()
    
    var body: some View {
        List {
            // Status header
            Section {
                NodeStatusCard(
                    isActive: vm.isNodeActive,
                    uptimeHours: vm.uptimeHours,
                    bytesServed: vm.bytesServed
                )
            }
            
            // Earnings
            Section("Earnings") {
                EarningsRow(label: "Pending CMXS", value: vm.pendingCMXS)
                EarningsRow(label: "Total Earned", value: vm.totalCMXS)
                EarningsRow(label: "Impressions Verified", value: "\(vm.impressionsVerified)")
            }
            
            // Wallet
            Section("Wallet") {
                WalletAddressRow(address: vm.walletAddress)
                CMXSBalanceRow(balance: vm.cmxsBalance)
            }
        }
        .task { await vm.loadNodeData() }
        .refreshable { await vm.loadNodeData() }
    }
}
```

**Background node service (`BGProcessingTask`):**

```swift
// Features/DePINNode/NodeService.swift
import BackgroundTasks

class NodeService {
    static let taskIdentifier = "com.cmxs.arenza.node-contribution"
    
    static func register() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: taskIdentifier, using: nil) { task in
            handleNodeTask(task as! BGProcessingTask)
        }
    }
    
    static func schedule() {
        let request = BGProcessingTaskRequest(identifier: taskIdentifier)
        request.requiresNetworkConnectivity = true
        request.requiresExternalPower = false  // Run on battery too
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60)
        try? BGTaskScheduler.shared.submit(request)
    }
    
    private static func handleNodeTask(_ task: BGProcessingTask) {
        task.expirationHandler = { task.setTaskCompleted(success: false) }
        
        Task {
            // Send heartbeat to CMXS node service
            let earnings = try? await apiClient.sendHeartbeat(nodeId: nodeId)
            // Cache bandwidth for pending serves
            await cacheUpcomingContent()
            task.setTaskCompleted(success: true)
            schedule()  // Reschedule
        }
    }
}
```

**Info.plist additions required:**
```xml
<key>BGTaskSchedulerPermittedIdentifiers</key>
<array>
    <string>com.cmxs.arenza.node-contribution</string>
</array>
```

### 5.3 Wallet & CMXS Token Management

```swift
// Features/Wallet/WalletView.swift
struct WalletView: View {
    @StateObject var vm = WalletViewModel()
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Balance card
                BalanceCard(
                    walletAddress: vm.walletAddress,
                    cmxsBalance: vm.cmxsBalance,
                    usdValue: vm.usdValue
                )
                
                // Recent transactions
                TransactionList(transactions: vm.transactions)
                
                // Claim pending rewards
                if vm.pendingRewards > 0 {
                    ClaimRewardsButton(pendingAmount: vm.pendingRewards) {
                        await vm.claimRewards()
                    }
                }
            }
            .navigationTitle("Arenza Wallet")
        }
    }
}
```

---

## Part 6: tvOS Adaptation (Apple TV)

The tvOS target shares ~65% of the iOS codebase via SwiftUI multiplatform. Key adaptations:

### 6.1 Focus Engine Navigation

```swift
// All interactive elements need focus engine support
struct ChannelGridView: View {
    @FocusState private var focusedChannel: String?
    
    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 300))]) {
            ForEach(channels) { channel in
                ChannelCard(channel: channel)
                    .focusable()
                    .focused($focusedChannel, equals: channel.id)
                    .scaleEffect(focusedChannel == channel.id ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 0.15), value: focusedChannel)
            }
        }
        .onMoveCommand { direction in
            // Handle Siri Remote directional navigation
            navigateChannels(direction: direction)
        }
    }
}
```

### 6.2 SGAI Overlay for Siri Remote

On tvOS, the "Tap to Buy" tap gesture becomes a Siri Remote OK button press:

```swift
#if os(tvOS)
struct ShoppableOverlayCard: View {
    var body: some View {
        Button(action: handlePurchase) {
            // Overlay content
        }
        .buttonStyle(.card)  // tvOS card style — focus ring handled automatically
    }
}
#endif
```

### 6.3 Top Shelf Extension

```swift
// TopShelfExtension/TopShelfProvider.swift
import TVServices

class TopShelfProvider: TVTopShelfContentProvider {
    override func loadTopShelfContent() async -> TVTopShelfContent {
        let items = await fetchLiveNowChannels()
        let sections = TVTopShelfSectionedContent(sections: [
            TVTopShelfItemCollection(items: items.map { channel in
                let item = TVTopShelfSectionedItem(identifier: channel.id)
                item.title = channel.name
                item.displayURL = URL(string: "arenza://channel/\(channel.id)")!
                item.imageURL = channel.thumbnailURL
                return item
            })
        ])
        return sections
    }
}
```

### 6.4 Handoff (TV → iPhone commerce checkout)

When a user wants to purchase via the Siri Remote but prefers iPhone payment:

```swift
// In tvOS PlayerView
func initiateHandoffCheckout(product: Product) {
    let userActivity = NSUserActivity(activityType: "com.cmxs.arenza.checkout")
    userActivity.title = "Complete Purchase on iPhone"
    userActivity.userInfo = [
        "productId": product.id,
        "impressionId": currentImpressionId
    ]
    userActivity.becomeCurrent()
    // iOS Arenza app picks this up via scene(_:continue:)
}
```

---

## Part 7: Info.plist Required Entries

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "...">
<plist version="1.0">
<dict>
    <!-- Secure Enclave / Face ID -->
    <key>NSFaceIDUsageDescription</key>
    <string>Arenza uses Face ID to protect your PoD signing key and verify ad impressions.</string>
    
    <!-- Tracking (ATT) -->
    <key>NSUserTrackingUsageDescription</key>
    <string>Arenza uses your advertising identifier to deliver relevant sports ads and verify impression delivery. You can deny this — a privacy-preserving anonymous identifier will be used instead.</string>
    
    <!-- Background Tasks -->
    <key>BGTaskSchedulerPermittedIdentifiers</key>
    <array>
        <string>com.cmxs.arenza.node-contribution</string>
    </array>
    
    <!-- Background Modes -->
    <key>UIBackgroundModes</key>
    <array>
        <string>audio</string>
        <string>fetch</string>
        <string>processing</string>
        <string>remote-notification</string>
    </array>
    
    <!-- Deep Links -->
    <key>CFBundleURLTypes</key>
    <array>
        <dict>
            <key>CFBundleURLSchemes</key>
            <array><string>arenza</string></array>
        </dict>
    </array>
    
    <!-- FairPlay DRM -->
    <key>com.apple.developer.coremedia.allow-fairplay-streaming</key>
    <true/>
    
    <!-- Network security for CMXS APIs -->
    <key>NSAppTransportSecurity</key>
    <dict>
        <key>NSExceptionDomains</key>
        <dict>
            <key>cmxs.io</key>
            <dict>
                <key>NSIncludesSubdomains</key>
                <true/>
                <key>NSTemporaryExceptionAllowsInsecureHTTPLoads</key>
                <false/>
            </dict>
        </dict>
    </dict>
</dict>
</plist>
```

---

## Part 8: Required Entitlements

```xml
<!-- Arenza.entitlements -->
<dict>
    <!-- Push Notifications -->
    <key>aps-environment</key>
    <string>production</string>
    
    <!-- Secure Enclave access -->
    <key>com.apple.developer.authentication-services.autofill-credential-provider</key>
    <false/>
    
    <!-- Associated Domains (for Universal Links) -->
    <key>com.apple.developer.associated-domains</key>
    <array>
        <string>applinks:arenza.cmxs.io</string>
    </array>
    
    <!-- Apple Pay -->
    <key>com.apple.developer.in-app-payments</key>
    <array>
        <string>merchant.com.cmxs.arenza</string>
    </array>
    
    <!-- FairPlay -->
    <key>com.apple.developer.coremedia.hls.low-latency</key>
    <true/>
</dict>
```

---

## Part 9: Third-Party Swift Package Dependencies

```swift
// Package.swift dependencies — add these to Xcode project via SPM
dependencies: [
    // Caton MoQ/QUIC transport SDK
    .package(url: "https://github.com/caton-network/c3cvp-ios-sdk", from: "2.0.0"),
    
    // Keccak256 hashing (Ethereum-compatible, for PoD receipt signing)
    .package(url: "https://github.com/nicholasgasior/swift-keccak", from: "1.0.0"),
    
    // web3swift for Base L2 JSON-RPC interactions
    .package(url: "https://github.com/web3swift-team/web3swift", from: "3.1.0"),
    
    // SDWebImageSwiftUI for async image loading (channel thumbnails, product images)
    .package(url: "https://github.com/SDWebImage/SDWebImageSwiftUI", from: "2.2.0")
]
// NOTE: No networking library (Alamofire). Use URLSession async/await only.
// NOTE: No state management library (TCA/Redux). MVVM + Combine is sufficient.
// NOTE: Minimize total dependency count — each adds App Review risk.
```

---

## Part 10: Build Phases & Xcode Project Setup

### 10.1 Targets Required

| Target | Platform | Bundle ID | Purpose |
|---|---|---|---|
| `Arenza` | iOS 17+ | `com.cmxs.arenza` | Main iPhone/iPad app |
| `ArenzaTV` | tvOS 17+ | `com.cmxs.arenza.tv` | Apple TV app (shared code) |
| `ArenzaTopShelf` | tvOS 17+ | `com.cmxs.arenza.topshelf` | Top Shelf Extension |
| `ArenzaNotificationService` | iOS 17+ | `com.cmxs.arenza.notification-service` | Rich push notifications |
| `ArenzaTests` | iOS | — | XCTest unit tests |
| `ArenzaUITests` | iOS | — | XCUITest integration tests |

### 10.2 Signing & Capabilities (Main Target)

Enable in Xcode → Target → Signing & Capabilities:
- ✅ Push Notifications
- ✅ Background Modes (Audio, Background fetch, Background processing, Remote notifications)
- ✅ Associated Domains
- ✅ Apple Pay
- ✅ Access Wi-Fi Information (for node bandwidth measurement)
- ✅ Hardened Runtime (required for App Store)

### 10.3 Build Configurations

```
Debug:
  CMXS_API_BASE_URL = https://api-staging.cmxs.io/v1
  CMXS_MOQ_RELAY_URL = https://us-west.moq-demo.liveviewing.com:4444/anon
  BASE_L2_RPC_URL = https://sepolia.base.org
  POD_CONTRACT_ADDRESS = 0x... (Sepolia testnet)

Release:
  CMXS_API_BASE_URL = https://api.cmxs.io/v1
  CMXS_MOQ_RELAY_URL = https://us-west.moq-demo.liveviewing.com:4444/anon
  BASE_L2_RPC_URL = https://mainnet.base.org
  POD_CONTRACT_ADDRESS = 0x... (Base mainnet — provided by CMXS team)
```

---

## Part 11: API Integration Checklist for Antigravity

Before writing a single line of UI code, Antigravity should verify these backend integrations work end-to-end:

### Phase 0 — Environment Verification (Week 1)
- [ ] Obtain CMXS staging API credentials from CMXS team
- [ ] Verify `POST /auth/device-register` returns valid JWT and wallet address
- [ ] Verify `GET /channels` returns channel list with valid SSAI manifest URLs
- [ ] Verify `GET /channels/{id}/stream` returns playable MediaTailor manifest
- [ ] Test AVPlayer playback of SSAI manifest (content + ads stitched)
- [ ] Verify MoQ relay URL plays back via Caton C3CVP SDK
- [ ] Test Secure Enclave key generation on physical device (NOT simulator — Secure Enclave unavailable on simulator)
- [ ] Verify `POST /pod/submit-receipt` accepts signature and returns txHash
- [ ] Verify APNs device token registration (`POST /notifications/register`)
- [ ] Test WebSocket connection to `wss://live.cmxs.io/channel/{id}`

### Phase 1 — Core Video (Weeks 2–3)
- [ ] Full-screen video player with ABR quality selection
- [ ] SCTE-35 metadata detection triggering console log on ad break
- [ ] SSAI ad break playing seamlessly (no black screen, no rebuffer)
- [ ] MoQ failover to HLS SSAI when Caton unavailable

### Phase 2 — Ad Engine (Weeks 3–5)
- [ ] `POST /ad/break-detected` fires correctly on SCTE-35 event
- [ ] SGAI overlay renders for all four overlay types
- [ ] Shoppable overlay Apple Pay checkout completes successfully
- [ ] PoD receipt signed by Secure Enclave and submitted within 35s of ad completion
- [ ] All four ad beacons (impression, 25%, 50%, complete) POST correctly

### Phase 3 — Notifications & Node (Weeks 5–6)
- [ ] APNs token registered
- [ ] All three notification types render and deep-link correctly
- [ ] DePIN node BGProcessingTask running and sending heartbeats
- [ ] Earnings dashboard showing correct pending CMXS balance

### Phase 4 — tvOS & Polish (Weeks 6–8)
- [ ] tvOS focus engine navigation (all interactive elements)
- [ ] Top Shelf Extension showing live channels
- [ ] Handoff commerce checkout iOS ↔ tvOS
- [ ] App Store Connect metadata prepared (screenshots, preview video)
- [ ] TestFlight build distributed to CMXS team

---

## Part 12: Development Timeline

| Week | Deliverable | Owner Notes |
|---|---|---|
| 1 | Environment setup, API verification, Xcode project scaffold | CMXS provides API keys + staging env |
| 2 | Video player (AVFoundation + MoQ + SSAI + FairPlay DRM) | Caton SDK integration |
| 3 | SCTE-35 detector + ad break API integration | Test against CMXS staging SCTE-35 stream |
| 4 | Secure Enclave PoD signer + Oracle submitter | Physical device required |
| 5 | SGAI overlay system (all 4 types) + Apple Pay | CMXS provides overlay test payloads |
| 6 | APNs + DePIN node BGProcessingTask + Wallet UI | |
| 7 | Home screen + EPG + Channel grid + Search | |
| 8 | tvOS target + Top Shelf + Handoff | |
| 9 | Unit tests + UI tests + performance profiling | |
| 10 | App Store submission (TestFlight → Production) | |

**Total estimated timeline: 10 weeks**  
**Recommended team: 2 senior iOS engineers (1 specializing in AVFoundation/streaming, 1 in blockchain/CryptoKit)**

---

## Part 13: CMXS Backend Deliverables Needed from CMXS Team

Antigravity cannot complete the following without input from the CMXS engineering team:

1. **Staging API credentials:** `X-API-Key` and initial device registration endpoint
2. **Caton C3CVP SDK license key** for MoQ integration
3. **FairPlay DRM license server URL** (`drmLicenseUrl` from stream endpoint)
4. **DeliveryOracle.sol ABI and contract addresses** (Sepolia testnet + Base mainnet)
5. **SCTE-35 test stream URL** that fires predictable ad breaks for QA
6. **SGAI test payloads** for all four overlay types
7. **APNs certificate / push key** (`.p8` AuthKey for CMXS Apple Developer account)
8. **Apple Pay merchant certificate** (`merchant.com.cmxs.arenza` created in Developer Portal)
9. **Associated Domain file** at `https://arenza.cmxs.io/.well-known/apple-app-site-association`
10. **App Store Connect invite** to the `com.cmxs.arenza` app record

---

## Part 14: Key Acceptance Criteria Summary

| Feature | Must-Pass Criteria | How to Verify |
|---|---|---|
| MoQ Playback | Zero rebuffer on Wi-Fi→5G | Network Link Conditioner + Charles proxy |
| SCTE-35 | Ad break detected <50ms | AVPlayerItemMetadataOutput timing log |
| Secure Enclave PoD | Signature verified by oracle | `POST /pod/submit-receipt` → `{ accepted: true }` |
| SGAI Overlay | Appears at T=20s of 30s ad | Frame-accurate timer test with test creative |
| Apple Pay | Checkout completes, txHash returned | Sandbox Apple Pay test card |
| APNs | All 3 notification types render | APNs sandbox via Pusher or Apple's push utility |
| DePIN Node | BGProcessingTask sends heartbeat | Xcode BGTask debugger |
| tvOS Focus | All elements keyboard-navigable | tvOS Simulator + physical Apple TV |
| Deep Links | All scheme routes navigate correctly | `xcrun simctl openurl booted arenza://channel/livgolf` |
| PoD on-chain | txHash visible on Basescan | https://sepolia.basescan.org/tx/{txHash} |

