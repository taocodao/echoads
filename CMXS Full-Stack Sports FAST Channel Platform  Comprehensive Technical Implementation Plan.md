# CMXS Full-Stack Sports FAST Channel Platform: Comprehensive Technical Implementation Plan

## Executive Summary

This document provides an exhaustive technical implementation plan for the CMXS full-stack sports FAST (Free Ad-Supported Streaming TV) channel platform. The architecture integrates five interdependent layers: (1) a multi-platform media player distribution layer across Roku, Apple TV, Amazon Fire TV, Samsung Tizen, and LG webOS; (2) a cloud-native video ingest, transcoding, and CDN delivery pipeline; (3) a server-side ad insertion (SSAI) and programmatic monetization stack; (4) a blockchain-based PoD (Proof-of-Delivery) ad verification layer powered by the CMXS token; and (5) a DePIN viewer-node contribution system where audience members contribute idle bandwidth to earn CMXS tokens. Every component is grounded in the platform's core differentiation described in the source document: delivering verified ad impressions at $35–$45 CPMs on sports FAST content — a category simultaneously the fastest-growing genre on CTV and the most poorly served by existing verification infrastructure.

***

## Part I: Platform Architecture Overview

### System Topology

The CMXS platform is a **five-layer integrated stack**. Each layer is independently scalable but tightly coupled through standardized APIs:

```
Layer 5: DePIN Viewer-Node Network (CMXS token rewards for bandwidth contribution)
    ↕ CMXS token minting/settlement via smart contract
Layer 4: Blockchain PoD Verification (DeliveryTracke.sol on Base L2 / EVM)
    ↕ On-chain receipt per verified impression
Layer 3: SSAI + Programmatic Ad Stack (OpenRTB 2.6, VAST/VMAP, SCTE-35)
    ↕ Ad decision calls + manifest rewriting
Layer 2: Video Ingest, Transcoding & CDN Delivery (HLS/DASH, ABR, edge caching)
    ↕ Manifest URLs served to device players
Layer 1: Platform Distribution (Roku, Apple TV, Amazon Fire TV, Samsung Tizen, LG webOS)
```

The CMXS source document describes this as a "B2B infrastructure layer that delivers a complete, white-labeled channel-in-a-box to sports content providers like LIV Golf and DAZN, distributes free sports content across Roku, Apple TV, and Amazon Fire TV, and enables real-time interactive shoppable advertising via remote control — and is not only viable in 2025, it is precisely the right architecture at the right moment in the streaming market's evolution."

### Core Technical Differentiators

The platform's structural moat — as described in the source document — is its **five-layer integration**:
1. DEPIN delivery infrastructure (EchoStar's 5,800 towers as physical edge nodes)
2. Programmatic OpenRTB 2.6 auction engine with real-time bidding
3. Blockchain PoD verification (every impression tied to an on-chain receipt)
4. Interactive commerce layer (x302 overlay enabling remote-control purchase flows)
5. CMXS token incentive system (viewer-node contributors earn per verified impression)

No competitor combines all five. Traditional FAST operators like Fubo and StreamLayer handle interactive overlays but lack verification. DAZN and LIV Golf have FAST distribution but run unverified ad infrastructure. Verizon's physical tower infrastructure has no FAST channel platform. This five-layer integration is the structural moat.

***

## Part II: Layer 1 — Multi-Platform Distribution Integration

### 2.1 Roku Integration

**Platform Context**
Roku is the largest US FAST platform with 84.3 million active accounts and is projected to reach a 10% share of total TV viewing for FAST channels in 2026. The platform dominates US CTV FAST viewership at 84.3 million viewers. CMXS must be available here on Day 1.[^1]

**Integration Path: Roku SDK (BrightScript + SceneGraph), Not Direct Publisher**

The source document specifies CMXS requires a full-featured app with interactive commerce, custom ad stack, and PoD verification. This mandates the **Roku SDK path** (not Roku Direct Publisher), as Direct Publisher restricts ad server control and limits CMXS to playing only on The Roku Channel rather than as an independent branded channel.[^2][^3]

The Roku SDK uses two languages in tandem:[^4]
- **SceneGraph (XML)**: Describes UI layout as a tree of nodes (scene → groups → posters → labels). Retained-mode rendering engine that automatically repaints changes.
- **BrightScript**: Imperative scripting language that controls node field values, handles events, manages API calls, and drives application logic.

**Roku App Architecture for CMXS**

```
/components/
  MainScene.xml            ← Root scene definition
  MainScene.brs            ← BrightScript logic for main scene
  /channel/
    ChannelGrid.xml         ← EPG/channel grid UI component
    ChannelGrid.brs
  /player/
    VideoPlayer.xml         ← HLS/DASH playback wrapper
    VideoPlayer.brs         ← SSAI manifest URL injection
  /commerce/
    CommerceOverlay.xml     ← x302 shoppable ad overlay
    CommerceOverlay.brs     ← Remote control OK→buy flow
  /ads/
    AdBreak.xml             ← SCTE-35 triggered ad pod container
    PodVerification.brs     ← Signs PoD receipt before transmission
/source/
  main.brs                  ← App entry point
  ApiClient.brs             ← REST calls to CMXS backend
/images/
  splash_screen.png
  channel_logo.png
```

**Key Roku Requirements and Best Practices**

- **Content formats**: HLS (preferred), DASH, MP4. For SSAI with live sports, HLS with `EXT-X-DISCONTINUITY` tags for ad stitching is the standard.[^5][^6]
- **Content feed**: JSON or MRSS feed containing title, description (≤110 characters), thumbnail, content URL, and availability metadata.[^5]
- **Deep linking**: Roku certification requires deep link support for all media types (Section 5.1). CMXS must implement `roMessagePort` with `roURLTransfer` to handle deep links from search, voice, and the Roku Channel guide.[^7]
- **Voice playback**: Section 5.2 mandates Direct to Play for voice commands (e.g., "Hey Roku, play LIV Golf"). Requires `roInput` event listener and content metadata passing.[^7]
- **Device performance tiers**: Apps must run on all Roku devices currently receiving OS updates — from entry-level sticks (512MB RAM) to Roku Ultra (4K/HDR). Best practice: serve SD/HD/FHD UI assets and video at different resolutions; defer animations for low-memory devices.[^8][^7]
- **Ad integration**: Do NOT use Roku's Advertising Framework (RAF) for CMXS's primary ad serving — this would route revenue through Roku's RAF split (Roku takes 30% of ad revenue on RAF). Instead, implement CMXS's own SSAI system and connect to Roku Exchange via OpenRTB only for demand fill. CMXS's blockchain PoD verification requires the ad impression pipeline to flow through CMXS's own SSP layer, not Roku's.[^9]
- **Certification timeline**: 2–3 weeks for Roku Direct review, 4–12 weeks for full Roku SDK certification. Source document's Roku Direct Publisher path (2–3 weeks) is suitable for MVP; Roku SDK app certification (4–12 weeks) is required for full SSAI, interactive commerce, and PoD verification.[^5]
- **Spring 2025 Certification Update**: Roku added a new requirement for Instant Resume by October 1, 2025 for high-volume apps. CMXS should plan for this from launch.

**Programmatic Integration with Roku Exchange**
Roku Exchange leverages OpenRTB infrastructure for real-time bidding. CMXS's own SSP should integrate with Roku Exchange as one demand source via Magnite's SSP layer. The CMXS PoD verification layer appends blockchain receipt metadata to ad impression signals passing through the Roku Exchange bid stream — enabling advertisers to independently verify delivery on-chain.[^10][^9]

***

### 2.2 Apple TV Integration

**Platform Context**
Apple TV (tvOS) requires a formal Apple TV Channel partnership agreement. The process is more demanding than Roku's but offers strong editorial placement and premium brand association. As of April 2025, all tvOS submissions must target tvOS 18 SDK built with Xcode 15 or later.[^11][^12]

**Integration Path: tvOS Native App (SwiftUI)**

Apple TV development uses:[^13][^12]
- **Swift / SwiftUI**: Preferred for new development. Enables native declarative UI with `NavigationView`, `LazyVGrid`, and `AVPlayerViewController` for video playback.
- **AVFoundation / AVKit**: Core frameworks for HLS video playback. tvOS uses HLS as its primary streaming protocol.[^12]
- **FairPlay Streaming DRM**: Apple's proprietary DRM for protected content. Sports rights holders (LIV Golf, DAZN) will typically require FairPlay on Apple TV.
- **TVML/TVMLKit** (legacy): Server-driven templating framework, now deprecated for new projects. Migrate away from TVML for long-term maintainability.

**tvOS App Architecture for CMXS**

```swift
// App entry point
@main
struct CMXSApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(CMXSViewModel())
        }
    }
}

// Main navigation: EPG channel grid → content detail → player
struct ContentView: View {
    @EnvironmentObject var vm: CMXSViewModel
    var body: some View {
        NavigationView {
            ChannelGridView()           // EPG channel row grid
            ChannelDetailView()        // Program info + shoppable ad overlay
        }
    }
}

// SSAI-aware video player
struct CMXSPlayerView: UIViewControllerRepresentable {
    let manifestURL: URL               // SSAI-stitched HLS manifest URL
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let player = AVPlayer(url: manifestURL)
        player.addPeriodicTimeObserver(/* SCTE-35 boundary detection */)
        let vc = AVPlayerViewController()
        vc.player = player
        return vc
    }
}
```

**Apple TV Channel Requirements**

The Apple TV Channels partnership path (for integration into the Apple TV app with zero sign-on) requires:[^11]
1. **Brand registration**: Provide brand name, territories, network logos per Apple Artwork Specifications.
2. **Catalog feed**: Adopt the UMC Catalog Data Interface Specification (XML with XSD validation). Feed must include title, description, release date, content type, and artwork.
3. **Availability feed**: UMC Availability Data Interface Specification describing access windows and restrictions.
4. **Media Feed Validator**: No XSD errors, no MFV errors/warnings. Apple's Metadata Ops team reviews and reports Must Fix / Should Fix issues.
5. **Asset qualification**: Minimum 5 test titles submitted via Apple Transporter CLI. Apple evaluates video, audio, and subtitle asset quality against the Apple TV Channels Subscription Video Asset Specification.
6. **Timeline**: 8–16 weeks from application to live.

**Key tvOS Best Practices for CMXS**

- **Focus engine navigation**: tvOS uses a focus engine (directional swiping on Siri Remote). All interactive elements — channel rows, shoppable overlays, ad interactions — must be focus-engine compatible with clear `focusedValue` and `onMoveCommand` handlers.
- **Top Shelf extension**: Implement tvOS Top Shelf Extension to surface live sports content on the Apple TV home screen. This provides significant discoverability uplift for live events.
- **SCTE-35 ad break detection**: `AVPlayer` emits `AVPlayerItemMetadataOutput` events for ID3/SCTE-35 timed metadata embedded in HLS streams. Register a `AVPlayerItemMetadataOutputPushDelegate` to detect ad break boundaries and trigger the x302 commerce overlay.
- **FairPlay DRM integration**: Implement `AVContentKeySession` for FairPlay key request/response. The key server must integrate with the sports rights holder's license server (typically Vualto or BuyDRM).
- **Background fetch**: Use `BGAppRefreshTask` to pre-fetch EPG schedule data and warm CDN caches for upcoming live events.
- **Important distinction — Apple TV App vs. Apple TV Channel**: An Apple TV App is a standalone app in the App Store (preferred for full CMXS control). An Apple TV Channel is deeply integrated into the Apple TV app with zero sign-on — more discovery but requires the full partnership process above. CMXS should pursue both: App Store app first (8 weeks), then Channel partnership (16+ weeks).[^11]

***

### 2.3 Amazon Fire TV Integration

**Platform Context**
Amazon Fire TV offers two integration paths: a standard Android TV app submitted via the Amazon Appstore, and deep integration with the Fire TV Universal Search and Channel Guide via the TV Input Framework (TIF) and Catalog Data Format (CDF).[^14]

**Integration Path: Android App (Kotlin/Java) + TIF + CDF Catalog**

Fire TV apps are Android apps targeting the Fire OS variant of AOSP. The recommended stack:[^14]
- **Kotlin + Jetpack Compose for TV**: Modern, declarative UI framework.
- **Leanback Library** (legacy) or **Compose TV**: Navigation and content grid patterns optimized for D-pad/remote.
- **ExoPlayer (Media3)**: Google's open-source media player, supports HLS/DASH/SSAI with full SCTE-35 support.

**CDF Catalog Integration for Universal Search**

To appear in Fire TV's Universal Search and the On Now row, CMXS must ingest a Catalog Data Format (CDF) XML file into Amazon's S3-based catalog system:[^14]

1. **Create catalog XML** per Amazon's CDF schema (XSD validation required).
2. **Validate** against CDF XSD schema.
3. **Upload** to CMXS-designated S3 bucket via AWS CLI.
4. **Verify ingestion report** in Amazon's catalog console.
5. **Update catalog** regularly (minimum weekly, ideally daily for live sports schedules).
6. **TV Input Framework (TIF)**: Register a `TvInputService` in the Android manifest. Push entitled channels to the local TIF database via `TvContract.Channels`. Include Gracenote channel IDs or CDF Station IDs in `COLUMN_INTERNAL_PROVIDER_DATA` for automatic guide matching.[^15]
7. **Deep link integration**: Configure `Intent` filters to handle Fire TV launcher deep links (`amzn://apps/android?asin=...` or content deep links). Launcher integration allows single-click content launch from the Fire TV home screen.[^14]

**ExoPlayer SSAI Integration**

```kotlin
// ExoPlayer with IMA SSAI (AWS MediaTailor endpoint)
val ssaiManifestUrl = "https://mediatailor.us-east-1.amazonaws.com/v1/manifest/..." 
val mediaItem = MediaItem.Builder()
    .setUri(ssaiManifestUrl)
    .setAdsConfiguration(
        AdsConfiguration.Builder(Uri.parse(ssaiAdTagUrl)).build()
    )
    .build()

val player = ExoPlayer.Builder(context)
    .setMediaSourceFactory(
        DefaultMediaSourceFactory(context)
            .setServerSideAdInsertionMediaSourceFactory(
                ImaServerSideAdInsertionMediaSource.Factory(
                    ImaServerSideAdInsertionMediaSource.AdsLoader.Builder(context).build()
                )
            )
    )
    .build()
player.setMediaItem(mediaItem)
player.addListener(object : Player.Listener {
    override fun onPositionDiscontinuity(/* ... */) {
        // SCTE-35 boundary detected → trigger PoD beacon + commerce overlay
    }
})
```

**Fire TV Timeline**: 3–5 weeks for standard app approval. CDF catalog ingestion is parallel and can be completed in 1–2 weeks.

***

### 2.4 Samsung Tizen (Smart TV)

Samsung Smart TVs run the Tizen OS and support HTML5 web application development via the Samsung TV SDK. The development approach:[^16]
- **Tech stack**: React.js + TypeScript, Samsung TV SDK, Tizen Studio IDE.
- **Video playback**: HTML5 `<video>` element with HLS support via `hls.js` or native AVPlay API (Samsung-specific, supports DRM/DASH natively).
- **Ad integration**: Client-side or server-side. For SSAI, the CMXS SSAI endpoint serves a stitched HLS/DASH manifest directly — Samsung's player handles it as a single stream.
- **App submission**: Tizen Studio generates a `.wgt` package (signed certificate required per Tizen policy). Submit to Samsung Apps TV Developer Portal.[^16]
- **EPG integration**: Samsung's native Channel Guide integration requires registering via Samsung's FAST channel program (Samsung TV Plus partnership) — a separate B2B agreement.
- **White-label acceleration**: Third-party platforms like Norigin Media provide React.js-based EPG modules for Samsung Tizen that integrate existing video backends, ad servers, and analytics.[^17]
- **Timeline**: 3–5 weeks for Tizen app certification.

***

### 2.5 LG webOS (Smart TV)

LG Smart TVs run webOS and support HTML5 app development via the LG TV SDK:
- **Tech stack**: React.js + Enact framework (LG's open-source React-based framework for webOS). Standard HTML5/CSS/JavaScript.
- **Video playback**: HTML5 `<video>` + `hls.js` for HLS, or LG's native `luna-service2` API for advanced DRM/DASH playback.
- **Ad integration**: Same SSAI manifest approach as Samsung.
- **App submission**: Submit via the LG Developer portal. Apps require QA review (~3–4 weeks).
- **LG Channels integration**: LG operates its own FAST channel platform (LG Channels). A separate B2B partnership enables CMXS content to appear in LG Channels' EPG — high-value for discovery.
- **Timeline**: 3–4 weeks for webOS certification.

***

### 2.6 Platform Comparison and Launch Priority

| Platform | Market Share (US CTV FAST) | Integration Path | Technical Complexity | Launch Timeline | Revenue Priority |
|----------|--------------------------|-----------------|---------------------|-----------------|-----------------|
| **Roku** | #1 — 84.3M viewers[^1] | BrightScript/SceneGraph SDK | High | 4–12 weeks | P0 |
| **Amazon Fire TV** | #2 | Android/Kotlin + TIF + CDF | Medium | 3–5 weeks + 1–2 weeks catalog | P0 |
| **Apple TV** | #3 | SwiftUI/tvOS 18 | High | 8–16 weeks | P1 |
| **Samsung Tizen** | #4 | HTML5/React + Tizen SDK | Medium | 3–5 weeks | P1 |
| **LG webOS** | #5 | HTML5/React + webOS SDK | Medium | 3–4 weeks | P2 |

***

## Part III: Layer 2 — Video Ingest, Transcoding, and CDN Delivery Pipeline

### 3.1 Live Sports Ingest Architecture

Live sports content arrives at the CMXS origin from sports rights holders (LIV Golf, DAZN, regional leagues) via one of three ingest paths:

| Ingest Method | Protocol | Use Case | Latency |
|--------------|---------|---------|---------|
| SRT (Secure Reliable Transport) | SRT | Venue encoder → CMXS ingest | ~2s glass-to-glass |
| RTMP/RTMPS | RTMP | Broadcast encoder → cloud ingest | ~4–8s |
| HLS contribution | HLS | Pre-packaged streams from rights holders | ~6–15s |
| Satellite/DSNG | ASI/SDI | EchoStar tower ground stations | ~<1s + processing |

**EchoStar Tower Integration**: The source document specifies EchoStar's 5,800 tower sites as DEPIN delivery nodes. In practice, each tower with an active SRT receive path connects to the CMXS origin ingest cluster via dark fiber or MPLS private circuits. Tower ground stations are registered as named ingest endpoints in the CMXS ingest management API.

### 3.2 Transcoding Pipeline

All live and VOD content is transcoded into adaptive bitrate (ABR) ladders for HLS and DASH delivery:

**ABR Ladder (Sports-Optimized)**
| Profile | Resolution | Bitrate | Codec | Frame Rate |
|---------|-----------|---------|-------|-----------|
| 4K HDR | 3840×2160 | 15 Mbps | HEVC/H.265 | 60fps |
| 1080p | 1920×1080 | 8 Mbps | H.264 | 60fps |
| 720p | 1280×720 | 4.5 Mbps | H.264 | 60fps |
| 540p | 960×540 | 2.5 Mbps | H.264 | 30fps |
| 360p | 640×360 | 1.2 Mbps | H.264 | 30fps |
| Audio only | — | 128 kbps | AAC | — |

Sports content requires 60fps profiles at 720p/1080p to preserve motion clarity. Standard entertainment content uses 30fps.

**Transcoding Stack**
- **Live**: AWS MediaLive or Elemental Live for redundant channel processing. Output: HLS with 2-second segment duration (low-latency) or 6-second segments (standard).
- **VOD**: AWS MediaConvert for file-based transcoding. Output: packaged HLS and DASH in AWS S3.
- **Packaging**: AWS MediaPackage for origin packaging — generates HLS (`.m3u8`) and DASH (`.mpd`) manifests on demand. Inserts SCTE-35 ad break markers.
- **SCTE-35 insertion**: Ad break cue markers embedded in the live stream at natural content breaks (halftime, between holes). These are the trigger points for SSAI manifest rewriting.

### 3.3 CDN Architecture

CMXS deploys a **multi-CDN strategy** for redundancy and geographic optimization:[^18]

**Primary CDN: AWS CloudFront** — integrated with MediaPackage, lowest latency for AWS-origin content, supports HTTP/2 and HTTP/3/QUIC.[^19]

**Secondary CDN: Akamai or Fastly** — failover path; provides ISP peering agreements unavailable to CloudFront in some regions.

**DePIN Edge Layer (EchoStar/CMXS Viewer Nodes)**: Community viewer nodes (Phase 1: pure IP caching; Phase 2: CBRS-extended) serve as a tertiary CDN tier. Content is pushed to viewer nodes as LRU (Least Recently Used) caches. Viewer devices with sufficient uplink speed and uptime are promoted to active caching nodes and earn CMXS tokens per verified cache hit.

**CDN Configuration Best Practices**[^19]
- **Immutable media segments**: Long TTL (`Cache-Control: public, max-age=31536000, immutable`) for HLS `.ts` segments and DASH `.m4s` fragments with content-addressed filenames.
- **Live manifests**: Short TTL (`no-cache` or `max-age=2`) for live `.m3u8` playlists — players fetch manifests on every segment refresh cycle.
- **Origin shielding**: All CDN POPs aggregate through a single AWS region's MediaPackage output before hitting origin — reduces origin load during live event spikes.
- **Cache warming**: Pre-seed CDN edge caches with ABR segment init files and first segments 15 minutes before live event start.
- **CORS headers**: `Access-Control-Allow-Origin: *` on all manifest and segment responses to support web-based players.
- **Tokenized URLs**: HLS manifest URLs include HMAC-signed tokens (`?token=<sig>&expires=<ts>`) for premium DRM-protected content.

***

## Part IV: Layer 3 — SSAI and Programmatic Monetization Stack

### 4.1 Server-Side Ad Insertion Architecture

SSAI is the foundational technology enabling CMXS's $35–$45 CPM verified sports ad inventory. The source document identifies ad verification sub-600ms latency as a core platform feature. SSAI achieves this by stitching ads into the video stream at the origin — the viewer's device receives a single continuous stream with no client-side ad requests, eliminating ad blockers and reducing buffering.[^20]

**SSAI Flow (Live Sports)**

```
1. Live stream → MediaLive transcoder → SCTE-35 markers inserted at ad breaks
2. Stream → MediaPackage origin packager
3. Viewer device requests manifest → MediaTailor SSAI endpoint intercepts
4. MediaTailor sends VMAP/VAST bid request to CMXS Custom SSP
5. CMXS SSP runs OpenRTB 2.6 auction among connected DSPs (The Trade Desk, DV360, Amazon DSP)
6. Winning ad creative (pre-transcoded to match ABR ladder) received
7. MediaTailor rewrites HLS manifest: EXT-X-DISCONTINUITY tags added at ad break boundaries
8. Stitched manifest delivered to viewer device (single continuous stream)
9. Ad plays; device sends beacon events (impression, quartile, complete) to MediaTailor
10. MediaTailor forwards beacons to CMXS PoD verification layer → on-chain receipt minted
```

**HLS Manifest Structure with SSAI**
```m3u8
#EXTM3U
#EXT-X-VERSION:3
#EXT-X-TARGETDURATION:6

# Content segment
#EXTINF:6.0,
https://cdn.cmxs.io/content/seg001.ts

# Ad break boundary
#EXT-X-DISCONTINUITY
#EXT-X-CUE-OUT:DURATION=30
#EXTINF:6.0,
https://ads.cmxs.io/creative/ad001_seg1.ts
#EXTINF:6.0,
https://ads.cmxs.io/creative/ad001_seg2.ts
#EXTINF:6.0,
https://ads.cmxs.io/creative/ad001_seg3.ts
#EXT-X-CUE-IN
#EXT-X-DISCONTINUITY

# Content resumes
#EXTINF:6.0,
https://cdn.cmxs.io/content/seg002.ts
```

### 4.2 OpenRTB 2.6 Auction Engine

The CMXS Custom SSP implements **OpenRTB 2.6** — the CTV industry standard that enables structured, dynamic, and hybrid ad pods.[^21][^22]

**Pod Structure for Sports FAST**
- **Structured Pod**: Pre-game: 2×30s slots. Halftime/major break: 4×30s or 2×60s. Between holes/innings: 2×15s. End of game: 3×30s.
- **Dynamic Pod**: During live action breaks of uncertain duration, a dynamic pod with `poddur=90` and `maxseq=6` allows the SSP to fill whatever time is available.[^22]
- **`mincpmpersec` floor pricing**: Sports premium inventory priced at $1.10–$1.50/second (equating to $33–$45 CPM for 30-second slots).[^22]

**Bid Request Components (OpenRTB 2.6)**
```json
{
  "id": "cmxs-bid-001",
  "imp": [{
    "id": "1",
    "video": {
      "mimes": ["video/mp4"],
      "minduration": 15,
      "maxduration": 30,
      "protocols": [2, 3, 5, 6],  // VAST 2.0, 3.0, 4.0, 4.1
      "w": 1920, "h": 1080,
      "linearity": 1,
      "podid": "halftime_pod_1",
      "podseq": 1,          // First pod in program (premium positioning)
      "slotinpod": 1,       // First slot in pod
      "mincpmpersec": 1.17  // $1.17/sec = ~$35 CPM floor for 30s
    }
  }],
  "site": {
    "content": {
      "id": "liv_golf_round2",
      "title": "LIV Golf — Round 2",
      "genre": "Sports",
      "cat": ["IAB17-18"]  // Golf
    },
    "ext": {
      "channel": { "name": "CMXS LIV Golf" },
      "network": { "name": "CMXS Sports" }
    }
  },
  "device": {
    "devicetype": 3,  // Connected TV
    "ifa": "[VIEWER_IFA_HASHED]"  // Hashed for privacy
  }
}
```

**Connected DSPs**
- **Tier 1**: The Trade Desk, Google DV360, Amazon DSP, Magnite (via Roku Exchange)[^9]
- **Tier 2**: FreeWheel (NBCUniversal), SpotX, Index Exchange
- **Direct deals**: LIV Golf sponsors, Callaway, TaylorMade, athletic brands — sold directly at $45+ CPM

### 4.3 Interactive Commerce Layer (x302 Overlay)

The source document specifically highlights the x302 remote-control commerce overlay as a key differentiator — allowing viewers to click through to purchase pages without leaving the content environment. This drives 3–5% conversion rates and $60–120 average purchase values.

**Technical Implementation**

The x302 overlay is triggered by a VAST `<NonLinearAds>` extension or a custom SCTE-35 signal within the ad break. At the 20-second mark of a 30-second ad, the overlay appears:

```
[Content playing]
──────────────────────────────────────
│ ⛳ Callaway Paradym Driver — $549  │
│ [Press OK to learn more] [Buy Now] │  ← Appears at 20s mark
──────────────────────────────────────
```

**Per-platform implementation**:
- **Roku**: `roMessagePort` catches `isRemoteKeyPressed("OK")` event → opens `roURLTransfer` to CMXS commerce URL → launches branded web browser sheet or deep links to shopping app.
- **Apple TV**: `UIFocusGuide` directs Siri Remote selection to overlay button → `SFSafariViewController` opens merchant checkout URL → Apple Pay integration for one-tap purchase.
- **Fire TV**: Android `Intent` broadcasts catch D-pad OK press → `CustomTabsIntent` opens merchant checkout → Amazon Pay integration available via Amazon's native APIs.
- **Samsung/LG**: JavaScript `keydown` event for Enter/OK key → `tizen.application.launch()` or `webOS.service.request()` opens commerce deep link.

**USDC Payment Settlement** (from source document): When a viewer completes a purchase via the x302 overlay, the 1.5% transaction fee is automatically charged in USDC (or fiat-equivalent) via the CMXS smart contract treasury, creating a fully automated settlement layer requiring no human intervention.

***

## Part V: Layer 4 — Blockchain PoD (Proof-of-Delivery) Verification

### 5.1 Why On-Chain Verification Matters

CTV ad fraud costs the industry approximately $73 billion annually. 1 in 5 CTV impressions are estimated to be fake. CMXS's structural innovation is minting a cryptographic receipt on-chain for every verified ad impression — creating an independently auditable ledger that justifies the $35–$45 CPM premium sports inventory commands.[^23]

The IAB Tech Lab's OpenRTB 2.6 and ads.cert framework already provides cryptographic authentication of ad supply chain transactions. CMXS's PoD layer extends this with on-chain settlement.[^21]

### 5.2 PoD Smart Contract Architecture

**Chain Selection**: Deploy on **Base** (Coinbase's Ethereum L2) for:
- Sub-second transaction finality
- Sub-cent transaction costs (critical for high-volume impression logging)
- EVM compatibility (Solidity)
- Institutional credibility (Coinbase backing)

**DeliveryTracke.sol — Core Verification Contract**

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract CMXSDeliveryTracker {
    
    struct ImpressionReceipt {
        bytes32 impressionId;    // OpenRTB bid ID (keccak256 hashed)
        address nodeOperator;    // EchoStar tower or viewer node wallet
        uint32 campaignId;       // Advertiser campaign identifier
        uint16 cpmi;             // CPM in milli-dollars (e.g., 35000 = $35.00 CPM)
        uint32 timestamp;        // Unix timestamp of impression
        bytes32 viewerSig;       // Viewer device signature (ECDSA, keccak256 of IFA+timestamp)
        bool adComplete;         // True if ≥80% of ad viewed (quartile beacon)
    }
    
    mapping(bytes32 => ImpressionReceipt) public receipts;
    mapping(address => uint256) public nodeRewards;  // CMXS token rewards pending
    
    event ImpressionVerified(bytes32 indexed impressionId, address indexed node, uint16 cpmi);
    event TokensMinted(address indexed node, uint256 amount);
    
    // Called by CMXS oracle after verifying SSAI beacon + IFA signature
    function recordImpression(
        bytes32 impressionId,
        address nodeOperator,
        uint32 campaignId,
        uint16 cpmi,
        bytes32 viewerSig,
        bool adComplete
    ) external onlyOracle {
        require(receipts[impressionId].timestamp == 0, "Duplicate impression");
        receipts[impressionId] = ImpressionReceipt(
            impressionId, nodeOperator, campaignId, cpmi, 
            uint32(block.timestamp), viewerSig, adComplete
        );
        if (adComplete) {
            nodeRewards[nodeOperator] += calculateReward(cpmi);
            emit ImpressionVerified(impressionId, nodeOperator, cpmi);
        }
    }
    
    function calculateReward(uint16 cpmi) internal pure returns (uint256) {
        // 0.001 CMXS per verified impression at $35 CPM; scales with CPM
        return (uint256(cpmi) * 1e15) / 35000;  // Normalized to 0.001 CMXS at base CPM
    }
}
```

### 5.3 PoD Oracle and Verification Pipeline

The on-chain contract requires an off-chain oracle to bridge SSAI beacon data (HTTP) to blockchain transactions:

```
SSAI beacon (HTTP POST) → CMXS Oracle Service → Verification checks → Base L2 transaction

Verification checks performed by oracle before minting:
1. SSAI impression beacon received from MediaTailor ✓
2. ViewerDevice signature valid (ECDSA verify against registered IFA) ✓
3. ECDS signature from node operator valid ✓
4. Impression not already recorded (duplicate check via impressionId) ✓
5. Ad completion beacon received (≥80% of ad duration) ✓
6. Latency from bid win to beacon < 35 seconds (prevents stale impressions) ✓
```

**Oracle Infrastructure**: Chainlink Functions or a custom Node.js oracle service with multi-sig consensus (3-of-5 validators required for high-value impressions >$10 CPM).

### 5.4 Viewer Device PoD Signature

Each viewer device (Roku, Apple TV, Fire TV) runs a lightweight PoD client that:
1. Generates a device-specific ECDSA keypair on first app launch (private key stored in platform keystore/Secure Enclave).
2. Signs the ad impression receipt: `sign(keccak256(IFA || impressionId || timestamp))`.
3. Transmits the signature with the SSAI completion beacon.

This proves the impression was delivered to a real, registered device — not a bot or server farm. The device signature is the cryptographic proof replacing the traditional third-party verification vendor (DoubleVerify, IAS).

***

## Part VI: Layer 5 — DePIN Viewer-Node Contribution System

### 6.1 Node Architecture

Viewer-contributed nodes serve as a tertiary CDN layer that caches sports content segments and relays them to nearby peers. Every successfully served verified request earns CMXS tokens.

**Node Types**

| Node Type | Contribution | Hardware Requirement | Phase | CMXS Reward Multiplier |
|-----------|-------------|---------------------|-------|----------------------|
| Roku Device Node | IP data relay, CDN caching | Roku Ultra or Streambar (≥1GB RAM) | Phase 1 | 1.0× |
| Fire TV Cube Node | IP data relay, compute | Fire TV Cube (octa-core) | Phase 1 | 1.2× |
| Apple TV Node | IP data relay, secure storage | Apple TV 4K | Phase 1 | 1.3× |
| Home Broadband Node | Full CDN caching, high uplink | Any device with ≥100Mbps uplink | Phase 1 | 1.5× |
| CBRS Radio Node | Wireless coverage + CDN | CBRS-certified small cell + router | Phase 2 | 3.0× |

### 6.2 CMXS Node Software (Cross-Platform)

The CMXS node software runs as a **background process within the CMXS streaming app**:

```javascript
// CMXS Node Service (runs in app background)
class CMXSNodeService {
    
    async initialize() {
        this.walletAddress = await this.getOrCreateWallet();
        this.nodeId = await this.registerNode({
            wallet: this.walletAddress,
            deviceType: Platform.OS,  // 'roku' | 'firetv' | 'appletv'
            uplinkBandwidth: await this.measureUplink(),
            location: await this.getAnonymousGeoHash()  // H3 geohash, no precise location
        });
    }
    
    async serveContent(request) {
        const segment = await this.cache.get(request.segmentId);
        if (segment) {
            await this.sendResponse(request.peerId, segment);
            const receipt = await this.signDeliveryReceipt(request.segmentId);
            await this.submitReceiptToOracle(receipt);  // Triggers CMXS reward
        }
    }
    
    async signDeliveryReceipt(segmentId) {
        const data = ethers.utils.keccak256(
            ethers.utils.defaultAbiCoder.encode(
                ['string', 'string', 'uint256'],
                [this.nodeId, segmentId, Date.now()]
            )
        );
        return await this.wallet.signMessage(ethers.utils.arrayify(data));
    }
}
```

### 6.3 Reward Calculation

CMXS tokens are minted per verified impression and per verified cache-hit delivery:

| Contribution Type | Reward Rate | Verification Method |
|------------------|-------------|---------------------|
| Verified ad impression delivery | 0.001 CMXS / impression | PoD smart contract (DeliveryTracke.sol) |
| CDN cache hit (100MB segment served) | 0.0001 CMXS / 100MB | Signed delivery receipt |
| Uptime contribution (per hour active) | 0.0005 CMXS / hour | Heartbeat oracle |
| CBRS wireless coverage attestation | 0.005 CMXS / hour active | Proof-of-Coverage via RF challenge |

At 500,000 active monthly viewers on a CMXS channel, generating 3 ads/hour × 1.5 hours average watch time = 4.5 ads/viewer/session:
- Gross impression rewards: 500,000 × 4.5 × 0.001 CMXS = **2,250 CMXS/month per channel**
- At initial token pricing of $10/CMXS: $22,500/month in contributor rewards per 500k-viewer channel

***

## Part VII: Backend Services Architecture

### 7.1 Microservices Topology

```
API Gateway (AWS API Gateway + CloudFront)
    │
    ├── Content Service (Node.js/TypeScript)
    │     ├── EPG schedule management (PostgreSQL)
    │     ├── Content feed generation (JSON/MRSS for Roku, CDF XML for Fire TV, UMC XML for Apple TV)
    │     └── Rights metadata management
    │
    ├── Ad Service (Node.js/TypeScript)
    │     ├── Custom SSP (OpenRTB 2.6 bid engine)
    │     ├── VAST/VMAP response assembly
    │     ├── Creative transcoding pipeline (FFmpeg + MediaConvert)
    │     └── Ad pod management (deduplication, competitive separation, frequency capping)
    │
    ├── PoD Verification Service (Rust — performance-critical)
    │     ├── Beacon ingestion (HTTP/2 POST endpoints)
    │     ├── ECDSA signature verification
    │     ├── Oracle transaction submission (Base L2)
    │     └── Fraud detection (ML anomaly scoring)
    │
    ├── Node Management Service (Go)
    │     ├── Node registration and health monitoring
    │     ├── Reward calculation and CMXS token minting
    │     ├── Bandwidth measurement (Proof-of-Bandwidth oracles)
    │     └── Sybil detection (staking + device attestation checks)
    │
    ├── Commerce Service (Node.js)
    │     ├── x302 overlay campaign management
    │     ├── Merchant product catalog integration (Shopify, WooCommerce APIs)
    │     ├── Transaction fee collection (USDC via smart contract)
    │     └── Conversion tracking and attribution
    │
    └── Analytics Service (ClickHouse + Grafana)
          ├── Real-time impression dashboard for content partners
          ├── CMXS token flow analytics
          └── Node performance metrics
```

### 7.2 Database Architecture

| Data Store | Technology | Purpose |
|-----------|-----------|---------|
| Relational | PostgreSQL (RDS) | Content catalog, user accounts, ad campaigns, node registry |
| Time-series | ClickHouse | Ad impression analytics, beacon event streams, node uptime tracking |
| Cache | Redis (ElastiCache) | EPG schedule cache, ad pod state, session tokens |
| Object storage | S3 | Video segments, manifests, creative assets, CDF catalog files |
| Blockchain | Base L2 | Impression receipts, CMXS token balances, node staking |
| Search | Elasticsearch | Content discovery, EPG search, analytics queries |

### 7.3 Authentication and Identity

- **Viewer identity**: Anonymous IFA (Identifier for Advertisers) per platform — Roku RIDA, Apple IDFA (limited post-ATT), Amazon AFAI. Never PII. Used for frequency capping and attribution only.
- **Node operator identity**: Ethereum wallet address + platform-attested device ID. KYC via Boost Mobile subscriber relationship for CMXS/EchoStar viewers.
- **Content partner identity**: OAuth 2.0 with PKCE for partner dashboard access. API keys for programmatic content feed updates.
- **Advertiser identity**: IAB Tech Lab `ads.cert` cryptographic authentication for all bid requests.[^21]

***

## Part VIII: SCTE-35 Live Event Ad Workflow

The complete millisecond-level timeline for a live sports ad break on CMXS:

| Time | Event |
|------|-------|
| **T=0ms** | Natural break in live sports (timeout, commercial break signal) |
| **T=0–50ms** | SCTE-35 cue marker inserted in live stream by encoder |
| **T=50ms** | MediaPackage detects SCTE-35 → notifies CMXS Ad Service |
| **T=50–100ms** | CMXS SSP assembles OpenRTB 2.6 bid request with pod structure, content signals, device IFA |
| **T=100–550ms** | Real-time auction: bid requests sent to 5–10 DSPs; bids received; second-price auction resolves |
| **T=550ms** | Winning creative URLs retrieved; MediaTailor begins manifest rewrite |
| **T=550–750ms** | HLS manifest rewritten with `EXT-X-DISCONTINUITY` + ad segment URLs |
| **T=750ms** | Stitched manifest available at SSAI endpoint; CDN begins serving updated manifest |
| **T=274ms–30s** | Ad plays on viewer device; beacon events sent at 25%, 50%, 75%, 100% |
| **T=30s+30ms** | Ad complete beacon received by CMXS PoD oracle |
| **T=30s+1s** | PoD oracle verifies ECDSA signature; submits Base L2 transaction |
| **T=30s+3s** | On-chain receipt minted; node operator reward accrued; content partner notified |

Total verified impression cycle: **under 35 seconds**, fully automated, no human in the loop.

***

## Part IX: Platform Launch Roadmap

### Phase 0 — Infrastructure Foundation (Months 1–3, Pre-TGE)

**Objective**: Establish core technical infrastructure and generate first real PoD receipts on testnet.

- Deploy CMXS video ingest cluster (AWS MediaLive + MediaPackage in us-east-1 and us-west-2)
- Build Custom SSP (OpenRTB 2.6) and integrate first 3 DSP demand partners
- Deploy `DeliveryTracke.sol` on Base Sepolia testnet; generate 10,000 synthetic PoD receipts with measurable latency data
- Launch Roku BrightScript SDK app (Roku Developer Dashboard preview channel)
- Launch Amazon Fire TV app (Appstore Developer Preview)
- Integrate first content partner (target: regional sports rights holder or college sports conference)
- Deploy CMXS Node Service as background process in Roku app — first node operator dashboard

**Milestone**: First real verified PoD receipt on Base mainnet with real ad revenue flowing.

### Phase 1 — MVP Live (Months 3–9)

**Objective**: Launch on Roku and Fire TV; onboard 2–3 content partners; activate TGE.

- Launch branded Roku SDK channel (full certification, 4–12 weeks)
- Launch Amazon Fire TV app with TIF/CDF catalog integration
- Integrate LIV Golf or DAZN as first marquee content partner
- Activate CMXS node rewards (CMXS token TGE on Base)
- Enable x302 shoppable commerce overlay on Roku and Fire TV
- Connect CMXS exchange to Roku Exchange via Magnite SSP
- Target: 50 EchoStar tower sites as registered Phase 1 DEPIN nodes
- Target: 10,000 viewer-node contributors earning CMXS rewards
- Target: $3M monthly ad revenue at $35 average CPM (requires ~85,000 daily active viewers)

### Phase 2 — Scale (Months 9–18)

**Objective**: Full platform maturity; Apple TV; Samsung/LG; international expansion.

- Launch Apple TV Channel (full Apple Channel partnership, 16+ weeks process)
- Submit Samsung Tizen and LG webOS apps
- Expand to 10+ content partners across 3+ FAST platforms
- Activate PoD API licensing (DAZN, TNT Sports, regional leagues pay per-impression API fee)
- Expand EchoStar node integration to 500+ tower sites
- Launch CBRS radio node program (Phase 2 DePIN)
- Begin Canada, UK, Germany expansion (DAZN's existing markets)
- Target: $23.1M annual revenue, 50 active sports channels

### Phase 3 — Protocol Maturity (Months 18+)

**Objective**: DAO governance; CMXS emission halving; revenue-dominated token economics.

- Transition protocol parameters to CMXS token holder DAO governance
- First CMXS token emission halving event
- Launch PoD API as a white-label B2B product for other FAST operators
- Cross-chain CMXS bridge to Ethereum, Solana, Cosmos IBC
- Target: $47.9M annual revenue at optimistic scenario; top 10 DePIN by on-chain revenue

***

## Part X: Key Risks and Mitigations

| Risk | Technical Mitigation |
|------|---------------------|
| Roku certification delay (4–12 weeks) | Launch Roku Direct Publisher channel first (2–3 weeks) as placeholder; transition to SDK app; never block revenue on certification |
| Apple TV partnership rejection | Apple TV App Store standalone app is certification-independent; pursue Channel partnership in parallel, not as dependency |
| SSAI latency exceeding 600ms | Pre-transcode all creatives to match ABR ladder before auction; MediaTailor SLA is 500ms P95[^24]; use geo-distributed SSAI endpoints |
| PoD oracle downtime | Multi-oracle architecture (3-of-5 consensus); automatic fallback to traditional impression counting if oracle SLA breached |
| CDN origin overload during live sports spikes | Auto-scaling MediaPackage CDN origin + CloudFront surge capacity + DePIN viewer nodes as overflow tier |
| CMXS token volatility disrupting node economics | Token rewards denominated in stable CPM equivalents; excess volatility triggers emission rate auto-adjustment |
| Platform policy changes (Roku/Apple ad rules) | SSAI architecture keeps ad revenue flowing through CMXS's own stack — not subject to platform RAF splits as long as CMXS runs its own ad server |
| ISP blocking of viewer node traffic | ISP partnership agreements for CMXS node traffic; classify as CDN peer caching (industry standard) not resale |
| Fake node / Sybil attacks on CMXS token | Hardware attestation (Roku/Apple/Amazon platform device IDs as root of trust) + staking requirement + KYC via Boost subscriber base |

---

## References

1. [Streaming in 2026: Roku's 5 predictions for the year ahead](https://advertising.roku.com/2026-predictions) - In 2026, we predict that FAST channels will reach a 10% share of total TV viewing. Michele Siravo Qu...

2. [How to start a Roku channel | LTN](https://ltnglobal.com/blog/how-to-start-a-roku-channel) - Learn how to start a Roku channel and monetize it with FAST strategies. Step-by-step guide for Roku ...

3. [3 Ways to Create Your Own Roku Channel ...](https://www.uscreen.tv/blog/how-to-create-roku-channel/) - We're going to cover the details of three different ways to create a Roku channel: using a no-code p...

4. [How to develop Roku channels with BrightScript and SceneGraph](https://www.linkedin.com/posts/aram-shahgeldyan-0ba153284_im-continuing-to-finalize-my-advanced-course-activity-7340697416230199296-CEBM) - I'm continuing to finalize my advanced course on getting started with Roku Development. Here are som...

5. [Roku channel creation: How to launch, manage, & monetize](https://www.amagi.com/blog/roku-channel-creation-how-to-guide) - Roku places a high priority on its specific metadata requirements. For example, the content descript...

6. [SSAI (Server-Side Ad Insertion): What Is It?](https://bitmovin.com/ssai-server-side-ad-insertion/) - As the demand for video streaming escalates, so does the cost associated with maintaining and delive...

7. [Certification criteria](https://developer.roku.com/dev/docs/certification) - Review the certification criteria for submitting apps to the Roku Streaming Store, including perform...

8. [SceneGraph "Build a Roku Channel": Core Concepts](https://www.youtube.com/watch?v=4Zfj4vJXSR8) - ## Roku Developers
##### Aug 18, 2020 (0:13:07)
This lesson reviews core concepts for Roku channel a...

9. [Roku Exchange debuts for more direct programmatic access to ...](https://www.streamtvinsider.com/advertising/roku-exchange-debuts-more-direct-programmatic-access-streaming-ad-inventory) - Roku on Wednesday introduced the Roku Exchange, which is meant to provide a direct path between prog...

10. [Roku’s Programmatic Evolution: From Manual Stitching to Real-Time Bidding](https://www.youtube.com/watch?v=WDj0ndPOdWk) - ## BeetTV
##### Mar 20, 2025 (0:05:03)
The programmatic advertising landscape has undergone a dramat...

11. [Partner onboarding requirements - Apple TV Channels](https://tvpartners.apple.com/support/3314-apple-tv-channels-partnership-requirements) - This article covers the initial partnership and technical requirements for Apple TV Channels: ... To...

12. [Apple TV App Development: How to Create a tvOS App | Oxagile](https://www.oxagile.com/article/getting-into-apple-tv-app-development/) - This website uses cookies to help improve your user experience

If you are thinking about the ways t...

13. [Apple TV App Development: Definition, Process and Costs](https://lampa.dev/blog/apple-tv-app-development) - Explore Apple TV app development: Dive into its definition, understand the process, and discover cos...

14. [How To Add A Fast Channel In Fire TV? - A Complete Guide](https://www.muvi.com/blogs/how-to-add-fast-channel-fire-tv-complete-guide/) - You'll need to use AWS Command Line Interface (CLI) commands to upload your catalog file to AWS for ...

15. [TV Input Framework on Fire TV](https://developer.amazon.com/docs/fire-tv/tv-input-framework-on-fire-tv.html) - To integrate live channels, you must provide access to the customer's channel entitlements along wit...

16. [Quick-start Guide](https://developer.samsung.com/smarttv/develop/getting-started/quick-start-guide.html) - # Quick-start Guide

This topic is an introduction to developing Web applications for Samsung TV. It...

17. [Norigin Media - White-label FAST Apps on Samsung & LG](https://noriginmedia.com/while-label-fast-apps/) - Launch your branded apps on leading CTV platforms FAST

## Linear TV / FAST

##### Linear TV and FAS...

18. [Enhancing Video Streaming with a Multi-CDN Strategy - CacheFly](https://www.cachefly.com/news/enhancing-video-streaming-experiences-with-advanced-cdn-technology/) - # Enhancing Video Streaming Experiences with Advanced CDN Technology

Post Author:

CacheFly Team

C...

19. [How to Implement a CDN for High-Performance Video ...](https://usavps.com/blog/video-streaming-cdn/) - **Introduction**

Delivering high-quality video at scale is one of the most demanding tasks for mode...

20. [SSAI (Server-Side Ad Insertion): What Is It? - Bitmovin](https://bitmovin.com/blog/ssai-server-side-ad-insertion/) - ## TL;DR
- SSAI stitches ads directly into the video stream on the server side, creating a seamless,...

21. [OpenRTB 2.6 & ads.cert: Building Verified CTV Ad Ecosystems](https://www.iabaustralia.com.au/enabling-a-flexible-verified-ctv-ads-eco-system-through-openrtb-2-6-ads-cert/) - Master the next generation of CTV advertising. Use OpenRTB 2.6 and ads.cert for a flexible, verified...

22. [OpenRTB 2.6 and Why it Matters for CTV](https://blog.bidswitch.com/openrtb-2.6-and-why-it-matters-for-ctv) - One of the most powerful features of OpenRTB 2.6 for CTV is support for dynamic pod bidding, which s...

23. [1 in 5 CTV Impressions Are Fake — Here's How to Avoid ...](https://www.peer39.com/blog/1-in-5-ctv-impressions-are-fake-heres-how-to-avoid-them) - Avoid fake CTV impressions that waste budget and damage performance. Learn how to identify and elimi...

24. [How to Do Server-Side Ad Insertion (SSAI) with ...](https://medium.com/@s.sukhbirsohal/how-to-do-server-side-ad-insertion-ssai-with-mediatailor-and-your-video-encoder-34902fc0ec53) - How to Do Server-Side Ad Insertion (SSAI) with MediaTailor and Your Video Encoder | by Sukhbir singh...

