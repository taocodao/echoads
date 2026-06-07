# Arenza iOS App — AI-Powered User Profiling & Ad Targeting
## Complete Implementation Plan for Antigravity

**Document Type:** Developer Hand-Off Specification  
**App Name:** Arenza  
**Network:** CMXS (Connected to existing DeliveryOracle.sol, MoQ/Caton C3CVP, MediaTailor SGAI stack)  
**Platform:** iOS 17+ / tvOS 17+ (Swift 5.9, Xcode 15+)  
**Prepared for:** Antigravity Engineering Team  
**Version:** 1.0 — June 2026

---

## Executive Summary

The FAST sports ad market has reached a structural inflection point. FAST users in the US will reach 131.4 million in 2026, representing 54% of all CTV users, yet sports FAST channels remain the most chronically underfunded segment in the ecosystem — fill rates as low as 5% are common, CPMs are depressed to $15–25 for unverified inventory, and advertiser demand chronically outpaces the platform's ability to prove delivery. The attached source document identifies seven core structural challenges. AI is the only viable solution to all seven simultaneously.

This plan specifies the full AI-powered user profiling and ad targeting system to be built into the **Arenza** iOS/tvOS app, connected to the existing CMXS network. Every module described below is implementation-ready: data schemas, Swift API contracts, Core ML model pipeline specs, CMXS backend endpoint bindings, and Antigravity prompt instructions are all included.

---

## Part 1 — The Seven Challenges and Their AI Solutions

### Challenge 1: Low Fill Rates (5% or Less)

**Root Cause:** Viewer growth on FAST sports channels is massively outpacing advertiser demand. Many channels run with ad fill rates as low as 5%, meaning 95% of available ad inventory runs as generic "fill-in-right-back" slates. Every unfilled slot is direct revenue destruction.

**AI Solution: Predictive Fill Rate Optimizer (PFRO)**

The PFRO module uses a demand forecasting model trained on historical bid response data from the CMXS `BidOrchestrator` service to predict, for each upcoming SCTE-35 ad break, the probability of a programmatic fill and the expected clearing price. When the model predicts a low-fill scenario (probability < 40%), the system automatically:

1. **Waterfalls to house ads** — pre-cached local advertiser creatives stored on-device that always fill
2. **Triggers EABN (Early Ad Break Notification)** to Google Ad Manager 60+ seconds before the break, maximizing DSP response time
3. **Lowers the floor price dynamically** by signaling the SSP layer to reduce the bid floor from the default $35 CPM to a configurable fallback floor ($18 CPM) to attract more demand

Production data from the IAB Tech Lab confirms that properly configured FAST ad stacks with real-time bidding can dynamically choose which ad to serve based on bid price, audience data, and ad performance — the PFRO implements this at the device level.

**Key Insight:** Google Ad Manager's SGAI EABN documentation explicitly states that calling the API approximately one minute before each break "results in better ad fill rate, more relevant ads and smoother transitions." The Arenza app must implement EABN as a mandatory component — not optional.

---

### Challenge 2: Depressed CPMs from Lack of Audience Verification

**Root Cause:** Sports FAST inventory currently clears at $15–25 CPM on private marketplaces when unverified. The ceiling for verified premium sports is $45–65 CPM — a 2–3× premium that cannot be claimed without proof-of-delivery (PoD) and audience identity signals.

**AI Solution: On-Device AI Audience Profile Engine (AAPE)**

The AAPE is a two-layer system:

**Layer 1 — On-Device Core ML Behavioral Classifier**  
Running entirely on the iPhone/Apple TV using Apple's Core ML framework, the classifier builds a persistent viewer profile from first-party behavioral signals collected within the Arenza app. Core ML models run strictly on the user's device, eliminating any need for a network connection and keeping the process privacy-compliant with Apple's ATT framework.

Profile signals collected:
- Sports genre affinity (which channels watched, for how long)
- Day-part viewing patterns (morning news sports, primetime live, late night highlights)
- Ad engagement history (skip rate, tap-to-expand rate, conversion on shoppable overlays)
- Content completion rate per sport type (soccer vs. golf vs. boxing vs. F1)
- Session frequency and recency (RFM scoring)
- Notification click-through rate per event type

**Layer 2 — Probabilistic Audience Segment Assignment**  
The on-device model outputs a probability vector across 12 pre-defined audience segments. Only the *segment ID* (not raw behavioral data) is transmitted to the CMXS `ProfileService` API for bidstream enrichment. This architecture satisfies Apple ATT requirements while providing DSPs with actionable targeting signals.

The 12 Arenza audience segments:

| Segment ID | Label | Key Signals | Target CPM |
|---|---|---|---|
| SEG-01 | Premium Sports Fanatic | >15h/week watch time, high completion | $55–65 |
| SEG-02 | Live Event Enthusiast | >80% live vs. VOD ratio, APNs opens | $50–60 |
| SEG-03 | Sports Bettor | Betting overlay taps, sportsbook ad clicks | $55–65 |
| SEG-04 | Sports Commerce Buyer | Shoppable overlay conversions >1% | $45–55 |
| SEG-05 | Casual Sports Fan | <5h/week, highlights preferred | $30–40 |
| SEG-06 | Multi-Sport Superfan | 4+ sports categories watched | $45–55 |
| SEG-07 | Young Male 18–34 | Estimated from viewing patterns | $45–60 |
| SEG-08 | Household Decision Maker | Device shared, prime-time dominant | $40–50 |
| SEG-09 | Affluent Sports Viewer | High completion + Apple Pay usage | $55–65 |
| SEG-10 | Sports Travel Intender | F1 + golf + tennis viewing combo | $50–60 |
| SEG-11 | New Viewer / Unknown | Insufficient signal (<3 sessions) | $20–28 |
| SEG-12 | Re-engaged Lapsed User | Gap >14 days then returns | $30–40 |

---

### Challenge 3: Ad Fraud — 20.6% of Programmatic Traffic Is Invalid

**Root Cause:** Global ad fraud will hit $100 billion in 2026. One in five CTV impressions is estimated to be fake. The CTV fraud environment is particularly acute because high sports CPMs make it the most economically attractive target for fraud networks.

**AI Solution: Secure Enclave Anomaly Detection + On-Chain PoD**

This is the most important fraud-prevention mechanism in the entire system. The CMXS Secure Enclave architecture, implemented in prior documents, provides the hardware attestation layer. The AI layer adds behavioral anomaly detection *before* the bid request is even issued.

**Fraud Signal Detection (Client-Side ML):**
The on-device anomaly detector monitors for signals consistent with bot behavior or device spoofing:
- Session start without prior APNs engagement (bots cannot receive push)
- Viewership patterns inconsistent with human behavior (no pause events, no seek events, no orientation changes)
- Ad completion at exactly 100% across every ad (humans skip or partially watch)
- Screen-off detection during ad playback (using `UIApplication.shared.isIdleTimerDisabled`)
- Accelerometer/gyroscope inactivity during claimed mobile viewing sessions

When anomaly score exceeds threshold (configurable, default: 0.75), the SCTE-35 detection pipeline suppresses the bid request and logs the session as suspect. The Secure Enclave PoD signing step will also be withheld — no signature means no PoD receipt — and the impression is excluded from the on-chain ledger.

**On-Chain PoD as the Definitive Fraud Proof:**  
Every legitimate impression signed by the iOS Secure Enclave produces an ECDSA signature verifiable on Base L2 by any third party. Advertisers can independently verify on Basescan that their CPM spend corresponds to real hardware-attested device impressions — not bot traffic. This is the only mechanism in the industry that provides cryptographic proof of delivery independent of the platform operator.

---

### Challenge 4: No Contextual Intelligence — Wrong Ads at Wrong Moments

**Root Cause:** Platforms like DAZN and LIV Golf distribute live sports free to 200+ markets but remain trapped in the unverified CPM tier because they serve generic ads with no contextual alignment to game moments. A beer ad playing immediately after a goal is worth 3× more than the same ad playing during a lull.

**AI Solution: Real-Time Contextual Moment Engine (RCME)**

NBCU's "Contextual Targeting in LIVE" (launched 2026) proved this works: AI continuously scans live content to align ad creative with the most relevant moments, achieving 27% higher creative enjoyment and 10% higher unaided brand awareness vs. baseline.

The Arenza RCME implements an equivalent system for the CMXS network:

**Stream Metadata Analysis Pipeline:**
1. The CMXS `ContentIntelligenceService` (backend, not on-device) processes the live stream audio in near real-time using a sports event classifier model
2. The classifier outputs game-state events: GOAL, SAVE, FOUL, HALFTIME, TIMEOUT, INJURY, CELEBRATION
3. Game-state events are broadcast to all active Arenza clients via WebSocket (`wss://api.arenza.tv/v1/moments/stream`)
4. The client enriches every OpenRTB bid request with a `game_state` custom extension field
5. DSPs and direct advertisers can bid selectively on game-state-aligned inventory — e.g., a sportsbook bids higher during a GOAL event, a beer brand bids higher during CELEBRATION

**iOS Implementation:**
```swift
// Arenza/Services/ContextualMomentService.swift
class ContextualMomentService: NSObject {
    private var webSocketTask: URLSessionWebSocketTask?
    
    @Published var currentMoment: GameMoment = .neutral
    
    enum GameMoment: String {
        case goal = "GOAL"
        case save = "SAVE"
        case celebration = "CELEBRATION"
        case halftime = "HALFTIME"
        case timeout = "TIMEOUT"
        case neutral = "NEUTRAL"
        
        var cpmMultiplier: Double {
            switch self {
            case .goal, .celebration: return 1.35   // 35% premium
            case .halftime: return 0.85             // 15% discount (attention divides)
            case .timeout: return 1.15              // 15% premium (captive audience)
            default: return 1.0
            }
        }
    }
    
    func connect(channelID: String) {
        let url = URL(string: "wss://api.arenza.tv/v1/moments/stream?channel=\(channelID)")!
        webSocketTask = URLSession.shared.webSocketTask(with: url)
        webSocketTask?.resume()
        receiveNextMessage()
    }
    
    private func receiveNextMessage() {
        webSocketTask?.receive { [weak self] result in
            switch result {
            case .success(let message):
                if case .string(let json) = message {
                    self?.handleMomentEvent(json)
                }
                self?.receiveNextMessage()
            case .failure:
                // Reconnect with exponential backoff
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    self?.receiveNextMessage()
                }
            }
        }
    }
    
    private func handleMomentEvent(_ json: String) {
        guard let data = json.data(using: .utf8),
              let event = try? JSONDecoder().decode(MomentEvent.self, from: data) else { return }
        DispatchQueue.main.async {
            self.currentMoment = GameMoment(rawValue: event.momentType) ?? .neutral
        }
    }
}
```

**Bid Request Enrichment:**
```swift
// In BidRequestAssembler.swift — enriches every OpenRTB 2.6 bid request
extension BidRequestAssembler {
    func enrichWithContext(
        segmentID: String,
        moment: ContextualMomentService.GameMoment,
        podPosition: Int,
        breakDuration: Int
    ) -> [String: Any] {
        return [
            "ext": [
                "cmxs": [
                    "segment_id": segmentID,
                    "game_moment": moment.rawValue,
                    "cpm_multiplier_hint": moment.cpmMultiplier,
                    "pod_position": podPosition,       // 1 = first in break (highest value)
                    "break_duration_sec": breakDuration,
                    "secure_enclave_attested": true,
                    "pod_verification": "base_l2"
                ]
            ]
        ]
    }
}
```

---

### Challenge 5: Ad Frequency Fatigue — Same Ads Shown Repeatedly

**Root Cause:** Without proper frequency management, sports viewers see the same 2–3 ads on repeat during a 90-minute match. Ad fatigue causes skip behavior, muted devices, and ultimately app uninstalls. Fill rates appear adequate but engagement collapses.

**AI Solution: ML-Powered Adaptive Frequency Controller (AFC)**

Traditional frequency capping uses a fixed rule (e.g., max 3 impressions per day per creative). ML-based frequency management, as described in industry research, replaces the one-size-fits-all cap with per-user, per-creative optimization based on predicted click-through probability. Users in the west may need 3 exposures before clicking; users in the east may need 8. A fixed cap wastes impressions on the former and under-serves the latter.

**AFC Architecture:**

The AFC maintains a per-device impression ledger stored in a local SQLite database (via GRDB.swift). For each `(creativeID, sessionID)` pair, the AFC tracks:
- `impression_count` — total exposures this session
- `skip_count` — number of times user skipped this creative
- `engagement_count` — taps, holds, or overlay interactions
- `completion_rate` — percentage of ad duration watched
- `last_seen_timestamp` — for inter-session frequency calculation

The Core ML `FrequencyScorer.mlmodel` takes these signals plus the current session context and outputs a `shouldServe: Bool` and `recommendedDelay: TimeInterval`.

**Key Rule Set (enforced in addition to ML scoring):**
- Hard cap: max 4 impressions of same creative per 60-minute session (non-negotiable floor)
- Hard cap: max 2 consecutive ads from same advertiser
- Soft cap: ML model score < 0.3 → suppress creative for remainder of session
- Diversity rule: min 3 unique creatives per ad pod
- Position rule: highest-value creative always plays in pod position 1

```swift
// Arenza/AI/AdaptiveFrequencyController.swift
class AdaptiveFrequencyController {
    private let db: DatabaseQueue  // GRDB SQLite
    private let model: FrequencyScorer  // Core ML model
    
    struct ImpressionRecord: Codable, FetchableRecord, PersistableRecord {
        var creativeID: String
        var advertiserID: String
        var sessionID: String
        var impressionCount: Int
        var skipCount: Int
        var engagementCount: Int
        var completionRateAvg: Double
        var lastSeenAt: Date
    }
    
    func shouldServeCreative(_ creativeID: String, advertiserID: String) -> Bool {
        let record = fetchRecord(creativeID: creativeID)
        
        // Hard caps (always enforced)
        if record.impressionCount >= 4 { return false }
        if consecutiveAdsFromSameAdvertiser(advertiserID) >= 2 { return false }
        
        // ML scoring
        let input = FrequencyScorerInput(
            impressionCount: Double(record.impressionCount),
            skipRate: Double(record.skipCount) / max(1.0, Double(record.impressionCount)),
            engagementRate: Double(record.engagementCount) / max(1.0, Double(record.impressionCount)),
            completionRate: record.completionRateAvg,
            minutesSinceLastSeen: Date().timeIntervalSince(record.lastSeenAt) / 60.0,
            currentViewerSegment: ProfileEngine.shared.currentSegmentIndex
        )
        
        guard let output = try? model.prediction(input: input) else { return true }
        return output.shouldServe > 0.5
    }
    
    func recordImpression(_ creativeID: String, completion: Double, engaged: Bool, skipped: Bool) {
        // Update SQLite record
        try? db.write { db in
            var record = fetchRecord(creativeID: creativeID)
            record.impressionCount += 1
            if skipped { record.skipCount += 1 }
            if engaged { record.engagementCount += 1 }
            record.completionRateAvg = (record.completionRateAvg + completion) / 2.0
            record.lastSeenAt = Date()
            try record.save(db)
        }
    }
}
```

---

### Challenge 6: Poor Advertiser ROI Measurement — No Attribution Chain

**Root Cause:** Sports FAST channels sell impressions but cannot prove that those impressions drove real-world outcomes. Advertisers cannot link a World Cup ad exposure to a website visit, app install, or purchase. This caps CPM at commodity rates because brands cannot justify premium budgets without attribution.

**AI Solution: Privacy-Preserving Attribution Layer (PPAL)**

The PPAL implements a three-tier attribution architecture compatible with Apple's ATT and SKAdNetwork privacy requirements:

**Tier 1 — In-App Engagement Attribution (No ATT Required)**  
Measures actions taken within the Arenza app directly following an ad impression:
- Shoppable overlay taps (tap-to-expand, Apple Pay checkout)
- Channel subscriptions post-ad exposure
- Content engagement (sport type, team search) following a brand ad

These events are logged by the CMXS `CommerceService` and the `DeliveryOracle.sol` contract simultaneously — creating an on-chain + API dual record.

**Tier 2 — SKAdNetwork Attribution (ATT Not Required)**  
For advertisers running app install campaigns, Arenza integrates with Apple's SKAdNetwork framework. SKAdNetwork allows advertisers to track which ad campaigns drove new app installs without disclosing user-level data. Arenza registers as a publisher in the SKAdNetwork ecosystem, enabling install measurement for sportsbook, streaming, and e-commerce advertisers.

```swift
// Arenza/Attribution/SKAdNetworkManager.swift
import StoreKit

class SKAdNetworkManager {
    static func registerAdImpression(
        networkID: String,
        campaignID: Int,
        creativeID: String,
        nonce: UUID,
        timestamp: Date,
        signature: String
    ) {
        if #available(iOS 14.5, *) {
            let impression = SKAdImpression(
                sourceAppStoreItemIdentifier: NSNumber(value: ArenzaAppStoreID),
                advertisedAppStoreItemIdentifier: NSNumber(value: Int(campaignID)),
                adNetworkIdentifier: networkID,
                adCampaignIdentifier: NSNumber(value: campaignID),
                adImpressionIdentifier: nonce.uuidString,
                timestamp: NSNumber(value: timestamp.timeIntervalSince1970),
                signature: signature,
                version: "3.0"
            )
            SKAdNetwork.startImpression(impression) { error in
                if let error = error {
                    print("SKAdNetwork impression error: \(error)")
                }
            }
        }
    }
}
```

**Tier 3 — Blockchain PoD as Immutable Attribution Anchor**  
The Secure Enclave ECDSA signature for each ad impression serves as an immutable, timestamped attribution anchor. Advertisers using the CMXS PoD API can query Basescan for their impression receipts and cross-reference with their own CRM data in a privacy-preserving way — without CMXS being in the data loop.

---

### Challenge 7: Dynamic Ad Insertion Failures — Buffer Events and Latency

**Root Cause:** Traditional SSAI (Server-Side Ad Insertion) introduces buffering artifacts, manifest swap delays, and frame-accurate alignment failures. Live sports is the worst environment for SSAI because content is unpredictable, network conditions are variable, and viewer tolerance for buffering is near zero.

**AI Solution: Predictive ABR + SGAI Hybrid Delivery with MoQ Fallback**

The Arenza app implements a three-tier ad delivery resilience system:

**Tier 1 — SGAI with Predictive Prefetch (Primary)**  
The SGAI system polls `api.arenza.tv/v1/breaks/upcoming?channelID=X` every 30 seconds. When an upcoming break is detected within 90 seconds, the app immediately:
1. Calls EABN with current viewer profile and game moment context
2. Pre-fetches the ad pod manifest URL
3. Begins buffering ad creative assets in the background

By the time the SCTE-35 cue fires, the creative is already buffered — the "switch" from content to ad is instantaneous.

**Tier 2 — MoQ/QUIC Connection Continuity (Network Resilience)**  
The Caton C3CVP MoQ integration maintains QUIC connection migration during network transitions. If the viewer moves from Wi-Fi to 5G during an ad break, the QUIC connection migrates without a TCP teardown — the ad continues without rebuffering.

**Tier 3 — On-Device House Ad Cache (Ultimate Fallback)**  
If both SGAI and programmatic fill fail entirely, the `HouseAdCache` module serves pre-downloaded local creatives. House ads are refreshed every 24 hours via `BGProcessingTask` and stored in the app's container. The viewer always sees *something* — never a black screen or a "We'll be right back" slate.

```swift
// Arenza/AdDelivery/HouseAdCache.swift
class HouseAdCache {
    static let shared = HouseAdCache()
    private let cacheDirectory: URL
    private var cachedAds: [HouseAd] = []
    
    struct HouseAd: Codable {
        let advertiserID: String
        let creativeURL: URL
        let duration: Int
        let localFileURL: URL?
        let expiresAt: Date
    }
    
    func refreshCache() async {
        // Called from BGProcessingTask when device is charging + on Wi-Fi
        let response = try? await APIClient.shared.get("/v1/house-ads")
        let ads = try? JSONDecoder().decode([HouseAd].self, from: response ?? Data())
        
        for ad in ads ?? [] {
            let localURL = cacheDirectory.appendingPathComponent("\(ad.advertiserID).mp4")
            if !FileManager.default.fileExists(atPath: localURL.path) {
                try? await downloadCreative(from: ad.creativeURL, to: localURL)
            }
        }
        self.cachedAds = (ads ?? []).filter { $0.expiresAt > Date() }
    }
    
    func nextHouseAd(excluding: Set<String> = []) -> HouseAd? {
        return cachedAds
            .filter { !excluding.contains($0.advertiserID) }
            .randomElement()
    }
}
```

---

## Part 2 — AI User Profile Engine: Complete System Design

### 2.1 Architecture Overview

The Arenza AI User Profile Engine (AUPE) is a privacy-first, on-device first-party data system. It never sends raw behavioral data off the device. Only derived segment identifiers and aggregated signals are transmitted to the CMXS backend.

```
┌─────────────────────────────────────────────────────────────┐
│                    ARENZA iOS APP                           │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │              ON-DEVICE AI LAYER                     │   │
│  │                                                     │   │
│  │  ┌──────────────┐    ┌───────────────────────────┐  │   │
│  │  │ Signal       │    │ Core ML Models            │  │   │
│  │  │ Collector    │───▶│ • ViewerClassifier.mlmodel│  │   │
│  │  │              │    │ • FrequencyScorer.mlmodel  │  │   │
│  │  │ • Viewing    │    │ • ChurnPredictor.mlmodel   │  │   │
│  │  │   history    │    │ • EngagementScorer.mlmodel │  │   │
│  │  │ • Ad events  │    └──────────────┬────────────┘  │   │
│  │  │ • Commerce   │                   │               │   │
│  │  │ • APNs taps  │    ┌──────────────▼────────────┐  │   │
│  │  │ • Session    │    │ Profile Store (encrypted) │  │   │
│  │  │   metadata   │    │ • SegmentID (1-12)        │  │   │
│  │  └──────────────┘    │ • ViewerScore (0.0-1.0)  │  │   │
│  │                      │ • SportAffinities []      │  │   │
│  │                      │ • DayPartPattern          │  │   │
│  │                      │ • EngagementTier          │  │   │
│  │                      └──────────────┬────────────┘  │   │
│  └─────────────────────────────────────┼───────────────┘   │
│                                        │                    │
│  ┌─────────────────────────────────────▼───────────────┐   │
│  │              BID REQUEST ASSEMBLER                  │   │
│  │  OpenRTB 2.6 + CMXS extensions                     │   │
│  │  Injects: segmentID, moment, PoD attestation        │   │
│  └──────────────────────────────────┬──────────────────┘   │
│                                     │                       │
└─────────────────────────────────────┼───────────────────────┘
                                      │
                    ┌─────────────────▼─────────────────┐
                    │        CMXS BACKEND                │
                    │                                    │
                    │  BidOrchestrator → DSPs/SSPs       │
                    │  ProfileService (segment only)     │
                    │  DeliveryOracle.sol (Base L2)      │
                    │  ContentIntelligenceService        │
                    │  CommerceService                   │
                    └────────────────────────────────────┘
```

### 2.2 Core ML Model Specifications

#### Model 1: ViewerClassifier.mlmodel

**Purpose:** Assigns a viewer to one of 12 audience segments  
**Input Features:**
- `totalWatchTimeHours` (Float) — last 30 days
- `liveVsVODRatio` (Float) — 0.0 (all VOD) to 1.0 (all live)
- `uniqueSportsWatched` (Int64) — number of distinct sport categories
- `avgSessionDurationMinutes` (Float)
- `adEngagementRate` (Float) — interactions per impression
- `adCompletionRate` (Float) — average % of ad watched
- `commerceInteractionCount` (Int64) — Apple Pay taps
- `apnsOpenRate` (Float)
- `dayPartDistribution` (MultiArray[6]) — morning/midday/afternoon/evening/prime/late
- `skippedAdsRate` (Float)
- `sessionFrequencyPerWeek` (Float)
- `daysSinceFirstSession` (Int64)

**Output:**
- `segmentID` (Int64) — 1–12
- `segmentProbabilities` (MultiArray[12]) — confidence vector

**Training Data Source:** Synthetic profiles generated from CMXS testnet session logs, bootstrapped with public FAST viewer behavior datasets from IAB and Nielsen. Model retrained monthly via federated learning.

**Model Size Target:** < 2MB (quantized INT8)  
**Inference Latency Target:** < 5ms on iPhone 12+  
**Framework:** Create ML (`.mlpackage` format), deployed via `MLModel`

#### Model 2: FrequencyScorer.mlmodel

**Purpose:** Per-impression decision on whether to serve a specific creative  
**Input Features:**
- `impressionCount` (Double) — times seen this creative this session
- `skipRate` (Double) — historical skip rate for this creative
- `engagementRate` (Double) — historical engagement rate
- `completionRate` (Double) — average completion
- `minutesSinceLastSeen` (Double)
- `currentViewerSegment` (Int64) — from ViewerClassifier

**Output:**
- `shouldServe` (Double) — 0.0 (suppress) to 1.0 (serve)
- `recommendedDelayMinutes` (Double) — when to next consider serving

#### Model 3: ChurnPredictor.mlmodel

**Purpose:** Predicts 7-day churn probability to trigger re-engagement APNs push  
**Output:** `churnProbability` (Double)  
**Trigger:** If > 0.65 → schedule personalized re-engagement APNs push via `APNsReEngagementService`

#### Model 4: EngagementScorer.mlmodel

**Purpose:** Predicts ad engagement probability for each creative × viewer pair (used to rank ad pod order)  
**Output:** `engagementScore` (Double) — used as tiebreaker when multiple creatives have identical CPMs

---

### 2.3 Swift Module Structure (Arenza/AI/)

```
Arenza/
├── AI/
│   ├── ProfileEngine.swift              ← Singleton: owns all ML models + profile store
│   ├── ViewerClassifier.mlmodel         ← Core ML model file
│   ├── FrequencyScorer.mlmodel          ← Core ML model file
│   ├── ChurnPredictor.mlmodel           ← Core ML model file
│   ├── EngagementScorer.mlmodel         ← Core ML model file
│   ├── AdaptiveFrequencyController.swift← Challenge 5 solution
│   ├── AnomalyDetector.swift            ← Challenge 3 fraud detection
│   ├── SignalCollector.swift            ← Event capture + buffering
│   └── ModelUpdateService.swift        ← OTA model refresh
│
├── AdDelivery/
│   ├── BidRequestAssembler.swift        ← OpenRTB 2.6 + CMXS extensions
│   ├── SCTEDetector.swift               ← AVPlayerItemMetadataOutputPushDelegate
│   ├── EABNService.swift                ← Early Ad Break Notification
│   ├── PredictiveFillOptimizer.swift    ← Challenge 1 solution
│   ├── SGAIOverlayController.swift      ← Interactive ad overlays
│   ├── HouseAdCache.swift               ← Challenge 7 fallback
│   └── PoDBroadcastSigner.swift         ← Secure Enclave ECDSA signing
│
├── Attribution/
│   ├── SKAdNetworkManager.swift         ← Challenge 6 tier 2
│   ├── InAppAttributionTracker.swift    ← Challenge 6 tier 1
│   └── OnChainReceiptSubmitter.swift    ← DeliveryOracle.sol submission
│
├── Contextual/
│   ├── ContextualMomentService.swift    ← Challenge 4 WebSocket
│   └── GameMomentEnricher.swift        ← Bid request enrichment
│
└── Privacy/
    ├── ATTConsentManager.swift          ← AppTrackingTransparency
    ├── ProfilePrivacyGuard.swift        ← Ensures no PII leaves device
    └── DifferentialPrivacyEncoder.swift ← Adds noise before segment upload
```

---

### 2.4 ProfileEngine Singleton

```swift
// Arenza/AI/ProfileEngine.swift
import CoreML
import Combine

@MainActor
class ProfileEngine: ObservableObject {
    static let shared = ProfileEngine()
    
    // Published state (consumed by BidRequestAssembler)
    @Published private(set) var currentSegmentID: Int = 11  // Default: SEG-11 New Viewer
    @Published private(set) var currentSegmentLabel: String = "New Viewer / Unknown"
    @Published private(set) var viewerScore: Double = 0.0   // 0.0–1.0 premium score
    @Published private(set) var sportAffinities: [String: Double] = [:]
    
    private var classifier: ViewerClassifier?
    private var churnPredictor: ChurnPredictor?
    private let signalCollector: SignalCollector
    private var profileStore: ProfileStore  // Encrypted local storage
    
    private init() {
        signalCollector = SignalCollector()
        profileStore = ProfileStore()
        loadModels()
        
        // Re-classify every 4 hours or after significant signal change
        Timer.scheduledTimer(withTimeInterval: 4 * 3600, repeats: true) { [weak self] _ in
            Task { await self?.reclassify() }
        }
    }
    
    private func loadModels() {
        do {
            classifier = try ViewerClassifier(configuration: MLModelConfiguration())
            churnPredictor = try ChurnPredictor(configuration: MLModelConfiguration())
        } catch {
            print("Core ML model load failed: \(error)")
        }
    }
    
    func reclassify() async {
        let features = await signalCollector.buildFeatureVector()
        
        guard let output = try? classifier?.prediction(
            totalWatchTimeHours: features.totalWatchTimeHours,
            liveVsVODRatio: features.liveVsVODRatio,
            uniqueSportsWatched: features.uniqueSportsWatched,
            avgSessionDurationMinutes: features.avgSessionDurationMinutes,
            adEngagementRate: features.adEngagementRate,
            adCompletionRate: features.adCompletionRate,
            commerceInteractionCount: features.commerceInteractionCount,
            apnsOpenRate: features.apnsOpenRate,
            dayPartDistribution: features.dayPartDistribution,
            skippedAdsRate: features.skippedAdsRate,
            sessionFrequencyPerWeek: features.sessionFrequencyPerWeek,
            daysSinceFirstSession: features.daysSinceFirstSession
        ) else { return }
        
        let newSegmentID = Int(output.segmentID)
        currentSegmentID = newSegmentID
        currentSegmentLabel = SegmentDefinitions.label(for: newSegmentID)
        viewerScore = calculateViewerScore(output.segmentProbabilities)
        
        // Upload segment ID only (no raw behavioral data) to CMXS ProfileService
        await ProfileAPIClient.shared.updateSegment(
            segmentID: newSegmentID,
            viewerScore: viewerScore,
            sportAffinities: sportAffinities
        )
        
        // Check churn risk
        await checkChurnRisk(features: features)
    }
    
    private func checkChurnRisk(features: ViewerFeatureVector) async {
        guard let output = try? churnPredictor?.prediction(input: ChurnPredictorInput(features: features)),
              output.churnProbability > 0.65 else { return }
        
        // Trigger re-engagement push via CMXS APNs service
        await APNsService.shared.scheduleReEngagementPush(
            segmentID: currentSegmentID,
            churnProbability: output.churnProbability
        )
    }
    
    // Called by SignalCollector after each ad impression
    func recordAdEvent(_ event: AdEvent) {
        signalCollector.record(event)
        profileStore.persist(event)
        
        // Lightweight immediate re-score if signal is significant
        if event.type == .firstCommercePurchase || event.type == .highEngagement {
            Task { await reclassify() }
        }
    }
}
```

---

### 2.5 CMXS Backend API Endpoints Required

All endpoints must be implemented by the CMXS backend team before Arenza can go live. These are the contracts Antigravity will code against:

| Method | Endpoint | Purpose | Auth |
|---|---|---|---|
| `POST` | `/v1/profile/segment` | Upload derived segment ID + viewer score | Device JWT |
| `GET` | `/v1/breaks/upcoming?channelID=X` | Poll for upcoming ad breaks (30s interval) | Device JWT |
| `POST` | `/v1/breaks/eabn` | Early Ad Break Notification | Device JWT |
| `GET` | `/v1/moments/stream` (WebSocket) | Real-time game moment events | Device JWT |
| `POST` | `/v1/bid/request` | Submit enriched OpenRTB 2.6 bid request | Device JWT |
| `GET` | `/v1/house-ads` | Fetch house ad manifest for cache refresh | Device JWT |
| `POST` | `/v1/pod/submit` | Submit Secure Enclave ECDSA PoD receipt | Device JWT |
| `POST` | `/v1/commerce/event` | Log shoppable overlay interaction | Device JWT |
| `POST` | `/v1/attribution/impression` | Log SKAdNetwork impression for attribution | Device JWT |
| `GET` | `/v1/models/latest` | Check for Core ML model updates | Device JWT |
| `GET` | `/v1/models/download?model=X` | Download updated .mlpackage | Device JWT |

---

## Part 3 — Complete Antigravity Implementation Prompt

---

### ANTIGRAVITY ENGINEERING PROMPT
### Project: Arenza iOS App — AI User Profiling & Ad Targeting System
### Version: 1.0

---

**To:** Antigravity iOS Engineering Team  
**Re:** Full implementation specification for Arenza AI modules  
**Context:** The CMXS network backend (DeliveryOracle.sol on Base L2, MoQ/Caton C3CVP delivery, MediaTailor SGAI, BidOrchestrator) is already built. You are building the iOS client that connects to it.

---

#### TASK OVERVIEW

Build the complete AI-powered user profiling and ad targeting system for the Arenza iOS app. This system must be production-ready, App Store compliant, and connected to the CMXS network APIs specified in Part 2.5 of this document.

---

#### TECHNICAL REQUIREMENTS

**Language:** Swift 5.9+  
**Minimum iOS:** iOS 17.0 (tvOS 17.0 for the tvOS target)  
**Xcode:** 15.0+  
**Architecture:** MVVM + Combine + async/await  
**Dependency Manager:** Swift Package Manager (SPM) only — no CocoaPods  
**Database:** GRDB.swift (for impression ledger + profile store)  
**Networking:** URLSession (no Alamofire)  
**ML Framework:** Core ML + Create ML (no TensorFlow Lite)  
**Privacy Framework:** AppTrackingTransparency, SKAdNetwork  
**Crypto:** CryptoKit (Secure Enclave, not CommonCrypto)  

**Required SPM Dependencies:**
```swift
// Package.swift dependencies
.package(url: "https://github.com/groue/GRDB.swift.git", from: "6.0.0"),
.package(url: "https://github.com/daltoniam/Starscream.git", from: "4.0.0"),  // WebSocket
.package(url: "https://github.com/nicklockwood/SwiftyJSON.git", from: "5.0.0")
```

---

#### MODULE 1: ProfileEngine + Core ML Pipeline

**What to build:**
Implement `ProfileEngine.swift` exactly as specified in Section 2.4 of this document. The engine must:

1. Load all four `.mlmodel` files from the app bundle on first launch
2. Run `reclassify()` on a 4-hour timer AND immediately after any high-signal ad event
3. Store the profile locally in an encrypted SQLite database via GRDB (encryption key derived from Secure Enclave)
4. Call `POST /v1/profile/segment` after each reclassification — transmitting ONLY `{ segmentID, viewerScore, sportAffinities }` — never raw behavioral signals

**Privacy requirements (non-negotiable):**
- Never log device IDFA without explicit ATT authorization (`ATTrackingManager.requestTrackingAuthorization`)
- If ATT is denied, use a zero-IV anonymized hash for viewer identification
- All profile data stored on-device must be encrypted using `ChaChaPoly` from CryptoKit
- The differential privacy encoder must add Laplace noise to `viewerScore` before upload: noise scale = 0.05

**Core ML model placeholder approach:**
For Sprint 1, create a rule-based `ViewerClassifier` (pure Swift, no `.mlmodel`) that implements the 12-segment classification using hard-coded thresholds. Replace with the trained Core ML model in Sprint 3 once 10,000+ real sessions are available from TestFlight.

Sprint 1 rule-based classifier thresholds:
- SEG-01: `totalWatchTimeHours > 15 AND adEngagementRate > 0.05`
- SEG-02: `liveVsVODRatio > 0.8`  
- SEG-03: `commerceInteractionCount > 0 AND sportAffinities["betting"] > 0.3`
- SEG-09: `adCompletionRate > 0.8 AND commerceInteractionCount > 2`
- SEG-11: `totalWatchTimeHours < 1` (default for new users)
- All others: proportional scoring

---

#### MODULE 2: SignalCollector

**What to build:**
Passive event collection pipeline that feeds ProfileEngine. Must be zero-latency (never block the main thread) and battery-efficient.

**Events to capture:**

```swift
enum AdEventType: String, Codable {
    case adBreakStarted
    case adStarted
    case adCompleted        // 100% completion
    case adSkipped          // User dismissed early
    case adQuartile25
    case adQuartile50
    case adQuartile75
    case overlayTapped      // SGAI interaction
    case overlayExpanded
    case overlayDismissed
    case applepayInitiated
    case applepayCompleted
    case firstCommercePurchase
    case highEngagement     // combination trigger
}

enum ContentEventType: String, Codable {
    case channelSelected(channelID: String, sportType: String)
    case playbackStarted(contentID: String, isLive: Bool)
    case playbackPaused
    case playbackResumed
    case playbackEnded(completionPercent: Double)
    case sportSearched(query: String)
    case channelFavorited(channelID: String)
    case notificationOpened(notificationType: String)
}
```

**Collection rules:**
- Buffer events in memory (max 100 events) before writing to SQLite in batch
- Write batch to SQLite every 60 seconds OR when buffer reaches 100 events
- Purge events older than 30 days from SQLite
- Never write to SQLite on the main thread — use a dedicated serial DispatchQueue

---

#### MODULE 3: AdaptiveFrequencyController (AFC)

**What to build:**
Implement `AdaptiveFrequencyController.swift` exactly as specified in Section 1, Challenge 5 of this document.

**Hard requirements:**
- The AFC must be called by `SCTEDetector` BEFORE each bid request is issued
- If AFC returns `shouldServe = false` for a creative, that creative must be excluded from the bid request's `badv` (blocked advertisers) or handled by filtering the pod response
- Impression ledger must survive app restarts (SQLite, not UserDefaults)
- Diversity rule is non-negotiable: pod coordinator must ensure min 3 unique creatives per break

**Database schema for impression ledger:**
```sql
CREATE TABLE IF NOT EXISTS impression_records (
    creative_id TEXT NOT NULL,
    advertiser_id TEXT NOT NULL,
    session_id TEXT NOT NULL,
    impression_count INTEGER DEFAULT 0,
    skip_count INTEGER DEFAULT 0,
    engagement_count INTEGER DEFAULT 0,
    completion_rate_avg REAL DEFAULT 0.0,
    last_seen_at REAL NOT NULL,
    created_at REAL NOT NULL,
    PRIMARY KEY (creative_id, session_id)
);

CREATE INDEX IF NOT EXISTS idx_advertiser ON impression_records(advertiser_id, session_id);
CREATE INDEX IF NOT EXISTS idx_last_seen ON impression_records(last_seen_at);
```

---

#### MODULE 4: ContextualMomentService

**What to build:**
WebSocket client connecting to `wss://api.arenza.tv/v1/moments/stream?channel={channelID}`. Implement exactly as specified in Section 1, Challenge 4.

**Requirements:**
- Reconnect with exponential backoff (base 2s, max 60s, jitter ±0.5s)
- Emit `currentMoment` updates via `@Published` for Combine subscribers
- BidRequestAssembler subscribes to `currentMoment` and injects it into every bid request
- If WebSocket is disconnected at bid time, default to `.neutral` moment (do not block the bid)
- Log all moment events to SQLite for offline analysis

---

#### MODULE 5: AnomalyDetector (Fraud Prevention)

**What to build:**
On-device behavioral anomaly detector that runs a fraud score for each session.

**Signals to monitor:**
```swift
struct SessionAnomalySignals {
    var noOrientationChangeInMinutes: Double  // Mobile only; >10 min = suspicious
    var playbackEventsPerMinute: Double       // <0.5 events/min = bot-like
    var adCompletionConsistency: Double       // All ads exactly 100% = suspicious
    var pauseEventCount: Int                  // Zero pauses in 60+ min = suspicious
    var seekEventCount: Int                   // Zero seeks in 60+ min = suspicious
    var networkSwitchCount: Int               // Zero switches on mobile = suspicious
    var deviceMotionActive: Bool              // No accelerometer = suspicious (mobile)
}
```

**Scoring logic:**
- Each suspicious signal contributes to `fraudScore` (0.0–1.0)
- If `fraudScore > 0.75`: set `isSuspect = true`, stop issuing bid requests, stop PoD signing
- Log suspect sessions to `POST /v1/fraud/report` for backend review
- Never show an error to the user — silently degrade to house ads

---

#### MODULE 6: Attribution Layer

**What to build:**
Implement `SKAdNetworkManager.swift` and `InAppAttributionTracker.swift` as specified in Section 1, Challenge 6.

**SKAdNetwork:**
- Register every ad impression via `SKAdNetwork.startImpression()` when `adNetworkIdentifier` is present in the bid response
- Handle `SKAdNetwork.endImpression()` on ad completion
- Support SKAN 4.0 (source identifier with fine-grained campaign measurement)

**In-App Attribution:**
- Fire `POST /v1/attribution/impression` within 100ms of PoD receipt submission
- Include: `{ impressionID, creativeID, advertiserID, segmentID, momentType, podPosition, timestamp }`
- This endpoint is the bridge between the Secure Enclave PoD and advertiser reporting

---

#### MODULE 7: On-Device House Ad Cache

**What to build:**
Implement `HouseAdCache.swift` as specified in Section 1, Challenge 7.

**Requirements:**
- BGProcessingTask identifier: `com.arenza.housead.refresh`
- Register in Info.plist: `BGTaskSchedulerPermittedIdentifiers`
- Minimum refresh: once every 24 hours when device is charging and on Wi-Fi
- Maximum cache size: 200MB (≈8–10 house ad creatives at 15–25MB each)
- Eviction policy: LRU, expire by `expiresAt` field from API
- Must prefetch at least 5 valid house ads before the app goes live (bootstrap on first launch)

---

#### MODULE 8: PredictiveFillOptimizer (PFRO)

**What to build:**
Demand forecasting module that predicts fill probability for upcoming breaks.

**Algorithm (Sprint 1, before ML model is trained):**
Use historical fill rate data from the CMXS `BidOrchestrator` response logs:
- If last 3 ad breaks had fill rate < 40%: trigger EABN immediately on next break detection
- If current time is in low-demand window (11pm–6am): lower floor price signal
- If current segment is SEG-11 (Unknown): do not lower floor — serve house ads instead (unknown segments attract low bids, not fill problems)

**EABN API call:**
```swift
// Arenza/AdDelivery/EABNService.swift
struct EABNRequest: Codable {
    let channelID: String
    let expectedBreakTime: Date
    let breakDurationSeconds: Int
    let viewerSegmentID: Int
    let gameMoment: String
    let expectedImpressions: Int
    let floorCPMOverride: Double?  // nil = use server default
}

func notifyUpcomingBreak(_ request: EABNRequest) async {
    let _ = try? await APIClient.shared.post("/v1/breaks/eabn", body: request)
}
```

---

#### MODULE 9: ModelUpdateService

**What to build:**
OTA model update checker. On app launch and every 7 days:
1. Call `GET /v1/models/latest` → returns model version manifest
2. Compare with locally stored model versions
3. If newer version available: download in background via `BGProcessingTask`
4. Validate downloaded `.mlpackage` before replacing production model
5. Hot-swap model in ProfileEngine without app restart

---

#### Info.plist Required Additions

```xml
<!-- AI + ML -->
<key>NSUserTrackingUsageDescription</key>
<string>Arenza uses your advertising identifier to show you relevant sports ads and to measure their effectiveness.</string>

<!-- Background Tasks -->
<key>BGTaskSchedulerPermittedIdentifiers</key>
<array>
    <string>com.arenza.housead.refresh</string>
    <string>com.arenza.model.update</string>
    <string>com.arenza.profile.sync</string>
    <string>com.arenza.node.earn</string>
</array>

<!-- Privacy descriptions (already required for AV + Secure Enclave from prior spec) -->
<key>NSMicrophoneUsageDescription</key>
<string>Arenza uses the microphone only for screen recording detection to prevent ad fraud.</string>
```

---

#### Sprint Plan

| Sprint | Duration | Modules | Gate |
|---|---|---|---|
| Sprint 1 | Weeks 1–2 | SignalCollector + ProfileStore (GRDB) + rule-based ViewerClassifier (no ML) | ProfileEngine logging events to SQLite |
| Sprint 2 | Weeks 3–4 | AnomalyDetector + AdaptiveFrequencyController + HouseAdCache | No duplicate creatives in any test pod; fraud score fires on simulated bot session |
| Sprint 3 | Weeks 5–6 | ContextualMomentService (WebSocket) + BidRequestAssembler enrichment + EABN | Enriched bid requests verified against CMXS sandbox |
| Sprint 4 | Weeks 7–8 | SKAdNetworkManager + InAppAttributionTracker + OnChainReceiptSubmitter | Full attribution chain visible: bid → impression → PoD → Basescan |
| Sprint 5 | Weeks 9–10 | Core ML model files (replace rule-based) + ModelUpdateService + PredictiveFillOptimizer | Real ML inference running on device; OTA model update verified |
| Sprint 6 | Weeks 11–12 | Integration testing + TestFlight beta + App Store submission | All 7 challenge solutions working end-to-end in sandbox environment |

---

#### CMXS Items Required Before Sprint 3

1. CMXS sandbox API base URL and JWT authentication spec
2. WebSocket `moments/stream` endpoint operational in sandbox
3. `breaks/upcoming` polling endpoint with test channel data
4. `breaks/eabn` endpoint accepting test EABN requests
5. `profile/segment` endpoint accepting segment ID uploads
6. `house-ads` endpoint with at least 5 test creatives (MP4, H.264, 15s and 30s)
7. Test `channelID` values for sandbox testing
8. DeliveryOracle.sol ABI and Base Sepolia contract address for PoD submission testing

---

#### Testing Requirements

1. **Unit tests (XCTest):** ProfileEngine, AdaptiveFrequencyController, AnomalyDetector — minimum 80% coverage
2. **Integration tests:** BidRequestAssembler → CMXS sandbox → PoD receipt → Basescan verification
3. **Performance tests:** Core ML inference must complete in < 5ms (XCTest performance measurement)
4. **Privacy audit:** Confirm no raw behavioral data in outbound network requests (Charles Proxy / Proxyman verification)
5. **Battery test:** Background tasks must not contribute > 2% CPU average over 8-hour idle period

---

## Part 4 — Privacy Architecture Summary

The Arenza AI system is designed to be App Store-compliant and GDPR/CCPA-ready from day one. The following principles are architecturally enforced — not policy-level declarations:

| Privacy Principle | Technical Mechanism |
|---|---|
| Raw behavior stays on device | Core ML runs entirely on-device; only derived segment ID leaves the device |
| No PII in bidstream | Segment ID (integer 1–12) is the only audience signal in OpenRTB bid requests |
| ATT compliance | IDFA only used with explicit ATT authorization; anonymized hash for denied users |
| Data minimization | Profile store auto-purges events > 30 days |
| Differential privacy | Laplace noise added to `viewerScore` before upload |
| Cryptographic integrity | Profile store encrypted with Secure Enclave-derived key |
| On-chain immutability | PoD receipts are irreversible audit trail — cannot be retracted by CMXS |
| SKAdNetwork | Install/conversion attribution without user-level data disclosure |

---

*This document is the authoritative implementation specification for the Arenza AI user profiling and ad targeting system. Questions should be directed to the CMXS product team. All API contracts specified herein are binding on the CMXS backend team.*

