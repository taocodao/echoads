# Arenza Play-to-Earn Engagement Model: Gamified Prediction vs. Profile-Targeted Advertising
## Strategy, Market Research & Combined Implementation Plan for Antigravity
---
## Executive Summary
Two models exist for monetizing live sports audiences on mobile and CTV. The first — **behavioral profile targeting** — builds a dossier on each viewer and sells access to that profile to advertisers. The second — **play-to-earn gamification** — invites the viewer to predict outcomes, earn points, and redeem sponsor-funded rewards without any invasive data collection. The research is unambiguous: these are not competing strategies but **complementary layers of the same flywheel**. Samsung GameBreaks produced a 53% lift in unaided brand recall and 89% of viewers preferred it to traditional ad breaks. Monumental Sports Network's gamified streaming app launched in February 2025 and has already "been pleasantly surprised by the level of interactions," opening new revenue streams beyond linear ad sales. The fan engagement market reached $7.2 billion in 2025 and is projected to grow at 18% CAGR to $44.7 billion by 2036. The second-screen market stands at $9.32 billion in 2026, growing to $26.18 billion by 2034. The Arenza platform — already architected with SGAI overlays, Secure Enclave PoD, and MoQ delivery — is positioned to combine both models into a single product that generates **three concurrent revenue streams**: verified programmatic CPMs, sponsor-funded prediction game rewards, and affiliate/commerce conversion from coupon redemption.[^1][^2][^3][^4][^5]

***
## Part 1: The Two Business Models — Deep Comparison
### 1.1 Profile-Based Targeted Advertising (Existing Arenza Architecture)
The existing Arenza plan, as documented in the attached implementation plan, deploys an on-device Core ML `ViewerClassifier.mlmodel` to assign each viewer to one of 12 audience segments based on viewing behavior, content preferences, and (with ATT consent) device signals. The segment ID — an integer, not a raw profile — is sent with each OpenRTB bid request. Advertisers bid higher for verified segments. The Secure Enclave ECDSA PoD receipt proves delivery on Base L2. Combined with SGAI overlays, this unlocks the $45–65 verified CPM tier.

**Strengths of the profile model:**
- Direct integration with the $36 billion US CTV programmatic market[^6]
- Highest revenue ceiling: $45–65 CPM for PoD-verified sports impressions
- Passive for viewers — no behavior change required
- Scales linearly with viewer count

**Weaknesses:**
- Requires ATT consent for full signal fidelity; post-iOS 14.5 opt-in rates are approximately 25–30%
- Does not increase viewer engagement or session length
- Commodity risk: every major CTV platform runs some version of audience targeting
- Ad fatigue is measurable: fill rates average 5% for live sports streams, CPMs are depressed by fraud (20.6% of programmatic traffic is invalid)[^6]
- Does not differentiate Arenza from Tubi, Peacock, or DAZN
### 1.2 Play-to-Earn Gamification Model (Proposed New Layer)
The gamification model replaces the passive ad-viewing relationship with an active participation contract: the viewer makes predictions about game outcomes, earns points for accuracy, and redeems those points for sponsor-funded rewards — discount coupons, free product offers, or experiential prizes. No personal data profiling is required. The viewer's identity is only their prediction accuracy score.

**The core mechanic:**
1. Before/during a live sports broadcast, Arenza surfaces a prediction overlay: *"Who scores next?" / "Will this drive result in a TD?" / "Final score: predict within 3 points"*
2. The viewer taps a choice on-screen — no disruption to viewing
3. Points accumulate in a `RewardsWallet`
4. At threshold points levels, the viewer unlocks sponsor coupons: *"You earned a Domino's 20% off code"*, *"Your DraftKings free bet is ready"*
5. Sponsors pay per coupon activation — a performance marketing model, not a CPM model

**Why this is structurally superior for the current market moment:**
- No ATT consent requirement — prediction participation is explicit, consensual, and first-party
- Creates a **reason to watch live** — the prediction only has value during the game, driving appointment viewing and session length
- **Prize indemnity insurance** caps sponsor exposure for large prizes at 3–15% of prize value, making even significant rewards affordable[^7][^8]
- Operates in all 50 US states because it is a **skill-based free-to-play game**, not wagering (no money changes hands, no house edge, no monetary entry fee)[^9]
- Generates **first-party behavioral data** that actually improves targeting accuracy — predicting sports outcomes reveals far more about a viewer's team loyalty, knowledge depth, and purchasing intent than passive viewing data

***
## Part 2: Market Research — What the Industry Is Already Doing
### 2.1 Samsung GameBreaks — The Definitive Proof of Gamified CTV Advertising
Samsung Ads launched GameBreaks in March 2025 in the US and Canada, then expanded to the UK in June 2025. GameBreaks transforms the first ad slot of each commercial break into a short remote-controlled game — trivia, challenges, interactive storytelling — branded by the advertiser.[^10][^11]

**Measured results (independent MediaScience research):**
- **53% lift** in unaided brand recall vs. standard video ads[^12][^5]
- **1.5× boost** in brand recall over standard video[^1]
- **89% of viewers** preferred GameBreaks to traditional commercial breaks[^12]
- Samsung planned 8+ game formats through 2025; by December 2025 had 7 turnkey formats available programmatically[^13]

**Key lesson for Arenza:** Samsung's model keeps the game inside the ad break. Arenza's opportunity is the inverse — games run *during* the live content (during timeouts, halftimes, natural pauses), with sponsor reward delivery happening at break time. This is more natural, more immersive, and does not require the viewer to stop watching to play.
### 2.2 Monumental Sports Network — Live Betting + Gamification Integration
Monumental Sports Network launched "Monumental Game Center" in February 2025 as the first local media rights holder to offer integrated live sports betting odds and gamification features outside Las Vegas. The features include: in-game betting prompts (via BetMGM), live player stats, advanced game stats, league standings, in-game polls, predictions, and trivia questions.[^14][^15]

**Key learnings from MNMT:**
- Opt-in design is essential: betting features are shown only to viewers who explicitly opt in; age verification (21+) is required for wagering features[^16]
- **Non-betting gamification (polls, predictions, trivia) is available to all users** regardless of jurisdiction or age — no licensing required
- The platform was extended to WNBA in June 2025, becoming the first interactive experience in women's professional sports[^16]
- MNMT confirmed: "we have been pleasantly surprised by the level of interactions" and described it as "opening additional revenue streams"[^4]
- Community leaderboards and prize-giving are the **next planned features** — exactly the model Arenza should build[^4]

**Key lesson for Arenza:** MNMT proves the local rights holder model works. Arenza's local TV station partners (from the CMXS network) are the exact analog. The leaderboard + prize-giving feature MNMT is still planning is what Arenza should launch with Day 1.
### 2.3 Genius Sports — Free-to-Play Games as Fan Engagement Infrastructure
Genius Sports explicitly markets gamification — Pick'em, Predictor, Fantasy Lite, Trivia, Brackets — as tools to "capture valuable user insights and drive on-platform engagement" and to "monetize your database with commercial partners". Their PointsInPlay product deploys sports trivia during broadcasts, directly tying brand sponsorship to knowledge engagement.[^17]

**The revenue architecture Genius Sports uses:**
- Brands pay for sponsored prediction questions: *"Predict the first scorer in the next drive — brought to you by [Brand]"*
- Correct prediction earns points; points redeem for brand-sponsored rewards
- Prediction data is the most valuable first-party signal a sports broadcaster can collect
- This data is then used to improve programmatic ad targeting — the gamification and targeting models explicitly feed each other
### 2.4 Snipp / Gambit / Scuti — Sponsor Coupon Infrastructure
The brand-funded rewards ecosystem is mature and well-tested. Snipp's sports marketing platform already operates pre-game, in-game, and post-game promotion mechanics for CPG brands during live sports. Their documented game types include: Prediction (pick the winner), Bingo (in-game moment matching), Pick 3 (simplified fantasy), and Intuition (fast Q&A). Gambit Rewards partnered with Scuti to allow players to convert brand-sponsored reward points into free bets — a direct crypto-adjacent model that aligns with CMXS's token architecture.[^18][^19]

**Key lesson for Arenza:** The sponsor coupon infrastructure already exists. The CMXS `RewardsWallet` does not need to be built from scratch — it needs to integrate with existing promotion APIs (Snipp, Vouchery, Talon.One) and add the prediction accuracy scoring layer on top.
### 2.5 Vinfotech World Cup 2026 Playbook — The Definitive F2P Prediction Model
Vinfotech's May 2026 World Cup strategy document explicitly documents the full play-to-earn coupon reward model: "Winners receive brand-sponsored rewards (coupons, store credits, limited freebies) in a Rewards Wallet. The variety keeps fans engaged between matches". Their documented best practices:[^20]

- **Outcome-linked rewards**: "If your five-match Pick'em lands during the group stage, your jersey is on us (50% off)"
- **Capped exposure via prize indemnity insurance** for large prizes; routine coupons from a pre-set pool
- **Community rewards**: "If your club wins, double wallet credits" — linking team outcome to sponsor activation
- Phase 1: Unified data + rewards backend; Phase 2: Predictor + Pick'em + Trivia per league with coupon API and affiliate tracking integration

**Key lesson for Arenza:** This is the exact architecture for Arenza's `PredictionEngine`. Arenza already has the SGAI overlay infrastructure and the `RewardsWallet` concept. The Vinfotech model is the business logic layer that sits on top.
### 2.6 Free-to-Play Legal Status — Why This Is the Safe Path
In the US, free-to-play prediction games that involve no monetary entry fee, no monetary prize, and skill-based scoring (not pure chance) are legal in all 50 states. The legal distinction is critical:[^9][^21]

| Model | Legal Status | Licensing Required |
|---|---|---|
| Sports wagering (FanDuel, DraftKings) | Legal in 33 states + DC[^22] | Yes — state gaming license |
| Paid-entry DFS (Boom Fantasy, PrizePicks) | Legal in 26 states (skill-based exemption)[^23] | Yes — varies by state |
| Free-to-play prediction (no money in/out) | Legal in all 50 states | No |
| Prediction markets (Kalshi) | Under CFTC litigation 2025–2026[^21] | CFTC registration |
| Sponsor coupon rewards (non-cash) | Legal in all 50 states | No |

Arenza's model — predict for free, earn points, redeem sponsor coupons — is the only model with zero legal exposure and zero licensing cost across all 50 states. This is why it should be the foundation layer before any real-money betting integration is considered.

***
## Part 3: Creative Approaches Found in Research — Ideas to Adopt
### 3.1 The "Correct Prediction = Sponsor Discount" Direct Link
From the Vinfotech World Cup playbook: outcome-linked discounts where the reward size is tied to prediction difficulty. A user who correctly predicts a 3-1 scoreline gets a bigger discount than one who predicted "home team wins." This creates a differentiated reward tier that incentivizes deeper engagement and gives sponsors a mechanism to offer headline prizes (50% off) with actuarially low redemption rates.[^20]
### 3.2 Community Pool Rewards — "If Your Team Wins, Everyone Gets a Coupon"
A sponsor activates a community pool: if Team A wins, all Arenza viewers who predicted Team A winning receive a Domino's coupon. This is structurally similar to a promotion, not a gambling outcome, and drives massive social sharing ("Root for the Lakers and get a free Chipotle burrito if they win"). Prize indemnity insurance makes this financially safe for the sponsor.[^7]
### 3.3 Live Moment Microgames — "What Happens on This Next Play?"
During a live timeout or between-play interval, Arenza surfaces a 15-second microgame: "Will the next play be a run or a pass?" with two large tap targets. This is resolved within 30 seconds of game action. The immediacy creates a dopamine loop tied to the live broadcast — exactly the SCTE-35 trigger moment already built into Arenza's SGAI system. The advertiser brand appears on the resolution screen ("Correct! — Brought to you by Modelo").
### 3.4 Season-Long Leaderboards with Tiered Sponsor Prizes
Weekly/monthly accuracy leaderboards where top predictors earn tiered sponsor rewards — escalating from small coupons (top 50%) to significant experiential prizes (top 1%). Prize indemnity insurance covers the top-tier prizes at 3–15% of prize value. This creates a reason to open Arenza every game day throughout a season.[^8]
### 3.5 The Samsung GameBreaks Model — Applied to Ad Breaks
During SCTE-35-triggered ad breaks, instead of a standard 30-second ad, Arenza runs a **15-second branded trivia game** followed by a 15-second sponsor message. The trivia is about the game just watched: "How many yards did that last drive cover?" The sponsor is contextually aligned (sporting goods, sports nutrition). Samsung's 53% brand recall lift becomes the selling point in Arenza's advertiser pitch deck.[^5]
### 3.6 Token-Reward Integration — CMXS Tokenomics Layer
For the CMXS DePIN token architecture, prediction points can be convertible to CMXS tokens at a fixed rate. This creates a non-financial onboarding path to the CMXS ecosystem: viewers earn tokens by watching and predicting, not by buying them. Token holders can stake for enhanced rewards or governance rights. This is structurally identical to how Helium's hotspot operators earn HNT by providing network service — the viewer's attention is the service, and the token is the reward.

***
## Part 4: The Combined Model — How Both Work Together
The critical insight from the research is that the gamification model and the profile targeting model are not alternatives — they **create a virtuous cycle**:

```
Viewer watches game
       ↓
Prediction overlay appears (SGAI trigger)
       ↓
Viewer engages with prediction
       ↓
[Revenue Event 1] SGAI overlay CPM charged to advertiser ($45–65)
       ↓
Viewer outcome resolved — points awarded
       ↓
[Revenue Event 2] Sponsor funds coupon pool (performance: cost-per-redemption)
       ↓
Viewer redeems coupon via Apple Pay / x402
       ↓
[Revenue Event 3] Commerce transaction fee (1.5% of purchase)
       ↓
Prediction data enriches Core ML viewer profile
       ↓
Next ad break: more accurate segment → higher CPM bid
       ↓
[Revenue Event 1 again — at higher CPM]
```

This flywheel means every prediction interaction simultaneously:
1. Generates direct SGAI overlay ad revenue (existing model)
2. Generates sponsor reward activation revenue (new gamification model)
3. Improves the audience profile, raising future CPM bids (multiplier effect on existing model)
### Revenue Comparison: Pure Targeting vs. Combined Model
| Revenue Stream | Pure Targeting Model | Combined Model |
|---|---|---|
| Programmatic CPM | $45 avg | $55 avg (enriched profile) |
| Monthly impressions (500K viewers) | 4,000,000 | 4,000,000 |
| Monthly gross ad revenue | $180,000 | $220,000 |
| Sponsor prediction activation fees | $0 | $30,000–$60,000 |
| Commerce/coupon transaction fees | $1,800 | $8,000–$15,000 |
| **Total monthly revenue** | **$181,800** | **$258,000–$295,000** |
| CMXS platform fee (15%) | $27,270 | $38,700–$44,250 |

The combined model generates approximately 42–62% more revenue per channel at the same audience size, while creating a measurably superior viewer experience that drives higher retention, lower churn, and longer session times.

***
## Part 5: Legal Framework — What Is Safe, What Requires Licensing
### 5.1 Free-to-Play Prediction Games
No license required in any US state. Three conditions must be maintained:
1. **No monetary entry fee** — prediction must be free to participate
2. **No monetary prize** — rewards must be non-cash (coupons, discounts, experiential prizes)
3. **Skill component** — accuracy scoring must be a genuine function of knowledge/skill, not purely random

Arenza's prediction model meets all three criteria by design.
### 5.2 Sponsor Coupon Fulfillment
Coupon and discount redemption through a third-party merchant (Domino's, Nike, DraftKings free play) is a promotional marketing activity, not gambling, in all 50 states. The key compliance requirement is accurate prize disclosure in Terms & Conditions and compliance with CAN-SPAM / CCPA for notification of reward availability.
### 5.3 Real-Money Betting Integration (Future Phase)
If Arenza chooses to add a real-money betting layer (redirecting to a licensed sportsbook partner, similar to the Monumental Game Center / BetMGM model), this requires:[^14]
- Geofencing to restrict the betting prompt to the 33 states + DC where mobile sports betting is legal[^22]
- Age verification (21+) via the sportsbook partner's verified protocol
- Opt-in consent before any odds or betting prompts appear
- Revenue model: affiliate CPA ($50–$150 per converted bettor) or rev share (15–25% of referred betting revenue), not platform licensing

**Recommended architecture:** Launch entirely free-to-play (Phase 1). Integrate sportsbook affiliate layer as an optional opt-in overlay in Phase 2, geofenced to legal jurisdictions. Never make the betting layer visible to non-opted-in users. This mirrors MNMT's approach exactly.
### 5.4 CMXS Token as Reward (Regulatory Note)
Converting prediction points to CMXS tokens requires careful structuring under the SEC March 2026 taxonomy: tokens awarded for platform participation (watching, predicting) as "Digital Tools" for network participation are positioned outside securities classification. The key requirement: token awards must be for service rendered (attention + data provision), not investment. Legal counsel must confirm this structure before launch.

***
## Part 6: Complete Implementation Plan for Antigravity
### 6.1 New Module: `PredictionEngine`
#### Architecture Overview

```
PredictionEngine
├── PredictionFeedService       // Fetches live prediction questions from CMXS Prediction API
├── PredictionOverlayView       // SwiftUI SGAI overlay rendering (extends existing SGAIOverlayView)
├── PredictionScoringEngine     // Accuracy scoring, streak tracking, multiplier calculation
├── RewardsWallet               // Point balance, tier status, coupon inventory
├── CouponRedemptionService     // Coupon API integration (Vouchery / Talon.One)
├── LeaderboardService          // Season/weekly rankings
└── ProfileEnrichmentBridge     // Feeds prediction signals back to Core ML ViewerClassifier
```

#### Data Models

```swift
// Prediction question model
struct PredictionQuestion: Codable {
    let id: UUID
    let gameId: String
    let triggerEvent: SCTECueType       // .timeout, .halftime, .adBreak, .manual
    let questionText: String
    let options: [PredictionOption]
    let timeWindowSeconds: Int           // How long user has to answer (15–60s)
    let pointValue: Int                  // Base points for correct answer
    let difficultyMultiplier: Float      // 1.0–3.0 based on odds/difficulty
    let sponsorId: String?               // Optional sponsor branding
    let sponsorLogoURL: URL?
    let expiresAt: Date
}

struct PredictionOption: Codable, Identifiable {
    let id: String
    let label: String
    let iconURL: URL?
    let impliedProbability: Float?       // Used for difficulty multiplier
}

// User prediction record — stored locally + synced to CMXS backend
struct UserPrediction: Codable {
    let questionId: UUID
    let selectedOptionId: String
    let submittedAt: Date
    let resolvedAt: Date?
    let correct: Bool?
    let pointsEarned: Int?
    let streakMultiplierApplied: Float
}

// Rewards wallet
struct RewardsWallet: Codable {
    var totalPoints: Int
    var weeklyPoints: Int
    var seasonPoints: Int
    var currentStreak: Int               // Consecutive correct predictions
    var bestStreak: Int
    var tier: RewardsTier                // .bronze, .silver, .gold, .platinum
    var availableCoupons: [SponsorCoupon]
    var redeemedCoupons: [SponsorCoupon]
    var pendingPoints: Int               // Points from unresolved predictions
}

enum RewardsTier: String, CaseIterable, Codable {
    case bronze    // 0–499 season points
    case silver    // 500–1,999 season points
    case gold      // 2,000–4,999 season points
    case platinum  // 5,000+ season points
}

struct SponsorCoupon: Codable, Identifiable {
    let id: UUID
    let sponsorId: String
    let sponsorName: String
    let sponsorLogoURL: URL
    let description: String              // "20% off your next order"
    let couponCode: String
    let deepLinkURL: URL?                // "dominos://promo?code=ARENZA20"
    let expiresAt: Date
    let minimumPurchase: Decimal?
    let maximumDiscount: Decimal?
    let category: CouponCategory         // .food, .sports, .betting, .retail
    var redeemed: Bool
    var redeemedAt: Date?
    let pointCost: Int                   // Points required to unlock
}
```
### 6.2 SGAI Overlay — Prediction Layer Extension
The existing `SGAIOverlayView` handles four overlay types (shoppable, poll, betting, squeeze-back). Add two new types:

```swift
// Add to existing SGAIOverlayType enum
case prediction(PredictionQuestion)
case rewardUnlock(SponsorCoupon)

// PredictionOverlayView — renders during SCTE-35 timeout/halftime events
struct PredictionOverlayView: View {
    @ObservedObject var engine: PredictionEngine
    let question: PredictionQuestion
    @State private var selectedOption: String?
    @State private var timeRemaining: Int
    @State private var submitted = false
    @State private var resolved = false
    @State private var correct: Bool?

    var body: some View {
        VStack(spacing: 16) {
            // Sponsor attribution (top)
            if let sponsorLogo = question.sponsorLogoURL {
                HStack {
                    Text("Brought to you by")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    AsyncImage(url: sponsorLogo) { img in
                        img.resizable().scaledToFit().frame(height: 24)
                    } placeholder: { EmptyView() }
                }
            }

            // Question
            Text(question.questionText)
                .font(.headline)
                .multilineTextAlignment(.center)

            // Countdown timer
            CountdownRingView(seconds: timeRemaining)

            // Options (2–4 choices)
            LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 2), spacing: 12) {
                ForEach(question.options) { option in
                    PredictionOptionButton(
                        option: option,
                        isSelected: selectedOption == option.id,
                        isDisabled: submitted
                    ) {
                        selectedOption = option.id
                        if !submitted {
                            HapticEngine.impact(.medium)
                            engine.submitPrediction(questionId: question.id, optionId: option.id)
                            submitted = true
                        }
                    }
                }
            }

            // Points preview
            if !submitted {
                Text("Correct = +\(question.pointValue) pts")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(20)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .onReceive(engine.resolutionPublisher) { resolution in
            if resolution.questionId == question.id {
                correct = resolution.correct
                resolved = true
                if resolution.correct {
                    HapticEngine.notification(.success)
                    engine.checkRewardUnlock()
                }
            }
        }
    }
}

// Reward unlock notification overlay
struct RewardUnlockOverlayView: View {
    let coupon: SponsorCoupon
    let onRedeem: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "gift.fill")
                .font(.largeTitle)
                .foregroundStyle(.yellow)
                .symbolEffect(.bounce, value: true)

            Text("You earned a reward!")
                .font(.headline)

            AsyncImage(url: coupon.sponsorLogoURL) { img in
                img.resizable().scaledToFit().frame(height: 32)
            } placeholder: { EmptyView() }

            Text(coupon.description)
                .font(.subheadline)
                .multilineTextAlignment(.center)

            HStack(spacing: 12) {
                Button("Redeem Now", action: onRedeem)
                    .buttonStyle(.borderedProminent)
                Button("Save for Later", action: onDismiss)
                    .buttonStyle(.bordered)
            }
        }
        .padding(20)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
    }
}
```
### 6.3 Scoring & Rewards Engine
```swift
@MainActor
class PredictionEngine: ObservableObject {
    @Published var wallet: RewardsWallet
    @Published var activePrediction: PredictionQuestion?
    @Published var pendingUnlock: SponsorCoupon?
    @Published var leaderboardRank: LeaderboardEntry?

    let resolutionPublisher = PassthroughSubject<PredictionResolution, Never>()
    private let api: CMXSPredictionAPIClient
    private let local: PredictionLocalStore
    private let profileBridge: ProfileEnrichmentBridge
    private var cancellables = Set<AnyCancellable>()

    // SCTE-35 integration point — called by existing MetadataOutputDelegate
    func onSCTE35Cue(_ cue: SCTE35Cue) {
        guard cue.type == .timeoutStart || cue.type == .halftimeStart else { return }
        Task {
            if let question = try? await api.fetchNextQuestion(
                for: cue.channelId,
                triggerType: cue.type.predictionTrigger
            ) {
                activePrediction = question
            }
        }
    }

    func submitPrediction(questionId: UUID, optionId: String) {
        let prediction = UserPrediction(
            questionId: questionId,
            selectedOptionId: optionId,
            submittedAt: Date(),
            resolvedAt: nil,
            correct: nil,
            pointsEarned: nil,
            streakMultiplierApplied: streakMultiplier
        )
        local.save(prediction)
        Task {
            try? await api.submitPrediction(prediction)
        }
    }

    func onPredictionResolved(_ resolution: PredictionResolution) {
        resolutionPublisher.send(resolution)
        if resolution.correct {
            let multiplied = Int(Float(resolution.basePoints) * resolution.streakMultiplier)
            wallet.totalPoints += multiplied
            wallet.weeklyPoints += multiplied
            wallet.seasonPoints += multiplied
            wallet.currentStreak += 1
            wallet.bestStreak = max(wallet.bestStreak, wallet.currentStreak)
        } else {
            wallet.currentStreak = 0
        }
        profileBridge.ingestPrediction(resolution)  // Feed to Core ML
        checkRewardUnlock()
    }

    func checkRewardUnlock() {
        Task {
            if let coupon = try? await api.checkCouponUnlock(
                seasonPoints: wallet.seasonPoints,
                tier: wallet.tier,
                recentPredictions: local.recentPredictions(limit: 10)
            ) {
                pendingUnlock = coupon
                wallet.availableCoupons.append(coupon)
                // Send APNs notification
                NotificationService.sendRewardNotification(coupon: coupon)
            }
        }
    }

    var streakMultiplier: Float {
        switch wallet.currentStreak {
        case 0...2:  return 1.0
        case 3...5:  return 1.5
        case 6...9:  return 2.0
        default:     return 3.0
        }
    }
}
```
### 6.4 Profile Enrichment Bridge — Connecting Gamification to Targeting
This is the key mechanism that makes the two models synergistic, not competing:

```swift
// Feeds prediction behavior back to Core ML ViewerClassifier
class ProfileEnrichmentBridge {
    private let classifier: ViewerClassifier  // Existing Core ML model

    func ingestPrediction(_ resolution: PredictionResolution) {
        // Build feature vector from prediction behavior
        let features = PredictionFeatureExtractor.extract(
            questionType: resolution.question.category,      // Sport, team, player
            optionChosen: resolution.selectedOptionId,
            correct: resolution.correct,
            timeToAnswer: resolution.timeToAnswer,          // Fast = knowledgeable fan
            streak: resolution.currentStreak
        )

        // Update viewer segment — no PII involved
        let enrichedSegment = classifier.updateSegment(
            currentSegment: ProfileStore.shared.currentSegmentId,
            newFeatures: features
        )

        // New segment ID → higher CPM on next OpenRTB bid request
        ProfileStore.shared.currentSegmentId = enrichedSegment

        // Log enrichment event (no PII, only segment delta)
        Analytics.track(.segmentEnriched(
            from: ProfileStore.shared.currentSegmentId,
            to: enrichedSegment,
            trigger: .predictionResolution
        ))
    }
}
```
### 6.5 Coupon Redemption — Apple Pay + Deep Link Integration
```swift
class CouponRedemptionService {
    // Redemption path 1: Deep link to sponsor app
    func redeemViaDeepLink(_ coupon: SponsorCoupon) {
        guard let url = coupon.deepLinkURL,
              UIApplication.shared.canOpenURL(url) else {
            redeemViaWebView(coupon)  // Fallback
            return
        }
        UIApplication.shared.open(url)
        markRedeemed(coupon)
    }

    // Redemption path 2: In-app web view with auto-filled coupon code
    func redeemViaWebView(_ coupon: SponsorCoupon) {
        let controller = SFSafariViewController(url: coupon.sponsorWebURL)
        // Pre-copy coupon code to clipboard with UNUserNotification
        UIPasteboard.general.string = coupon.couponCode
        NotificationBanner.show("Code \(coupon.couponCode) copied — paste at checkout")
        present(controller)
        markRedeemed(coupon)
    }

    // Redemption path 3: x402 direct commerce (existing Arenza commerce layer)
    func redeemViaX402(_ coupon: SponsorCoupon) {
        let request = X402PaymentRequest(
            merchantId: coupon.sponsorId,
            amount: coupon.discountAmount,
            currency: .usdc,
            couponCode: coupon.couponCode
        )
        X402Commerce.shared.processPayment(request) { result in
            switch result {
            case .success(let receipt):
                self.markRedeemed(coupon, receipt: receipt)
                PoDBroadcastReceipt.submit(impressionId: coupon.id, type: .commerce)
            case .failure(let error):
                ErrorBanner.show("Redemption failed — try again")
            }
        }
    }

    private func markRedeemed(_ coupon: SponsorCoupon, receipt: X402Receipt? = nil) {
        // Submit commerce event to CMXS backend for sponsor billing
        Task {
            try? await CMXSCommerceAPI.shared.logRedemption(
                couponId: coupon.id,
                sponsorId: coupon.sponsorId,
                redemptionType: receipt != nil ? .x402 : .deepLink,
                receiptId: receipt?.id
            )
        }
        NotificationService.sendRedemptionConfirmation(coupon: coupon)
    }
}
```
### 6.6 Leaderboard — Community and Social Layer
```swift
struct LeaderboardView: View {
    @StateObject var vm: LeaderboardViewModel
    @State private var scope: LeaderboardScope = .weekly

    var body: some View {
        VStack {
            Picker("Scope", selection: $scope) {
                ForEach(LeaderboardScope.allCases) { s in
                    Text(s.label).tag(s)
                }
            }
            .pickerStyle(.segmented)
            .padding()

            // User's own rank (sticky top)
            if let myEntry = vm.myEntry {
                LeaderboardRowView(entry: myEntry, isMe: true)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
                    .padding()
            }

            // Top 100
            List(vm.entries.prefix(100)) { entry in
                LeaderboardRowView(entry: entry, isMe: entry.userId == AuthService.shared.userId)
            }
        }
        .navigationTitle("Prediction Rankings")
        .task { await vm.load(scope: scope) }
    }
}
```
### 6.7 Backend API Contract — New CMXS Endpoints Required
Antigravity requires CMXS to provide these new endpoints before Sprint 3:

```
GET  /v1/predictions/next
     ?channelId={id}
     &triggerType={timeout|halftime|adbreak|manual}
     → PredictionQuestion | null

POST /v1/predictions/{questionId}/answer
     body: { optionId, submittedAt, streakMultiplier }
     → { predictionId, status: "pending" }

GET  /v1/predictions/{questionId}/resolution
     → { correct: bool, correctOptionId, pointsAwarded }
     (or subscribe via WebSocket: ws://api.cmxs.io/predictions)

GET  /v1/wallet
     → RewardsWallet

GET  /v1/rewards/check-unlock
     ?seasonPoints={n}&tier={bronze|silver|gold|platinum}
     → SponsorCoupon | null

POST /v1/rewards/{couponId}/redeem
     body: { redemptionType: "deeplink|webview|x402", receiptId? }
     → { status: "redeemed", confirmedAt }

GET  /v1/leaderboard
     ?scope={weekly|monthly|season}
     &limit=100
     → [LeaderboardEntry]

GET  /v1/leaderboard/me
     ?scope={weekly|monthly|season}
     → LeaderboardEntry

// Sponsor management (CMXS admin panel)
POST /v1/admin/sponsors/{sponsorId}/coupon-pool
     body: { coupons: SponsorCoupon[], totalBudget, pointsRequired }
     → { poolId, activatedAt }
```
### 6.8 APNs Push Notification — New Prediction Templates
Add three new APNs templates to existing push infrastructure:

```swift
// Template 1: Prediction opportunity (fires on SCTE-35 timeout)
let predictionPrompt = APNSAlert(
    title: "📊 Make your prediction!",
    body: "\(channelName) timeout — predict the next play",
    sound: .default,
    badge: nil,
    category: "PREDICTION_PROMPT",
    userInfo: [
        "type": "prediction_prompt",
        "questionId": question.id.uuidString,
        "channelId": channelId,
        "deepLink": "arenza://prediction/\(question.id)"
    ]
)

// Template 2: Reward unlocked
let rewardUnlock = APNSAlert(
    title: "🎁 You earned a reward!",
    body: "Your \(coupon.sponsorName) \(coupon.description) is ready",
    sound: APNSSound(name: "reward_chime.caf"),
    badge: 1,
    category: "REWARD_UNLOCK",
    userInfo: [
        "type": "reward_unlock",
        "couponId": coupon.id.uuidString,
        "deepLink": "arenza://wallet/coupons/\(coupon.id)"
    ]
)

// Template 3: Leaderboard position change
let leaderboardAlert = APNSAlert(
    title: "📈 You moved up the rankings!",
    body: "You're now #\(newRank) for the week — keep predicting",
    sound: .default,
    badge: nil,
    category: "LEADERBOARD_UPDATE",
    userInfo: [
        "type": "leaderboard_update",
        "newRank": newRank,
        "deepLink": "arenza://leaderboard"
    ]
)
```

***
## Part 7: Sponsor Acquisition Strategy — What Antigravity Builds, What CMXS Sells
### 7.1 The Sponsor-Facing Product (CMXS Sales Team Deliverable)
Arenza presents two products to sponsors:

**Product A — Prediction Sponsorship** ($5,000–$25,000/month per channel):
- Brand name appears on every prediction question during sponsored games
- Logo on resolution screen (correct/incorrect)
- Coupon pool: sponsor provides 500–5,000 coupon codes per campaign
- Metrics delivered: impressions, engagement rate, coupon activations, redemptions
- Prize indemnity insurance: CMXS arranges (cost embedded in campaign fee)

**Product B — Community Pool Activation** ($10,000–$50,000 per event):
- "If [Team] wins, all Arenza viewers who predicted correctly get [Reward]"
- Generates pre-game social sharing, massive second-screen engagement
- Prize indemnity insurance required (and provided)
- Metrics: prediction participation rate, coupon activation rate, social share volume

**Product C — Season Leaderboard Title Sponsorship** ($50,000–$200,000/season):
- Brand name on all leaderboard screens: "[Brand] Prediction Champions"
- Prize pool for top 10 season winners (gift cards, experiences, merchandise)
- Logo on weekly recap push notifications
### 7.2 CPM Comparison for Advertiser Pitch Deck
| Format | CPM / Cost | Brand Recall Lift | Engagement Rate |
|---|---|---|---|
| Standard video ad (passive) | $10–25 CPM | Baseline | ~2% |
| PoD-verified sports CTV (Arenza existing) | $45–65 CPM | +40% vs. standard | ~8% |
| Samsung GameBreaks (gamified) | +50% premium | +53% unaided recall[^5] | 89% prefer it |
| Arenza prediction sponsorship | CPR model | +70% est. (prediction context) | 15–30% active |
| Community pool activation | Cost per activation | Very high (event-driven) | All prediction participants |

***
## Part 8: Build Sprint Plan for Antigravity
### Sprint Additions to Existing 10-Week Timeline
The base Arenza app (Sprints 1–6, existing) covers: MoQ delivery, SCTE-35 detection, Secure Enclave PoD, SGAI overlays, Core ML profile targeting, and APNs push. Add three new sprints:

**Sprint 7 (Weeks 13–14): Prediction Engine Core**
- [ ] Implement `PredictionEngine` singleton + `PredictionLocalStore`
- [ ] `PredictionOverlayView` SwiftUI component (extends existing SGAIOverlayView)
- [ ] SCTE-35 → prediction trigger hook (call `engine.onSCTE35Cue`)
- [ ] Prediction submission + resolution polling via CMXS WebSocket
- [ ] Points scoring + streak multiplier logic
- [ ] Unit tests: scoring engine (min 85% coverage)

**Sprint 8 (Weeks 15–16): Rewards Wallet + Coupon Redemption**
- [ ] `RewardsWallet` SwiftUI tab in main nav (wallet balance, coupons, tiers)
- [ ] `CouponRedemptionService` (deep link + SFSafariViewController + x402)
- [ ] APNs templates: prediction prompt, reward unlock, leaderboard update
- [ ] `ProfileEnrichmentBridge` connecting prediction data to Core ML segment
- [ ] Sponsor logo + attribution rendering in overlay
- [ ] Accessibility: VoiceOver labels for all game elements

**Sprint 9 (Weeks 17–18): Leaderboard + Social + Polish**
- [ ] `LeaderboardView` (weekly, monthly, season tabs)
- [ ] Share sheet: "I'm #12 in the Arenza Prediction League — join me"
- [ ] `RewardUnlockOverlayView` (animated, with sound)
- [ ] tvOS adaptation: Focus Engine navigation for prediction options; Siri Remote OK to submit
- [ ] End-to-end test: SCTE-35 trigger → prediction → resolution → coupon unlock → redemption
- [ ] Sponsor admin integration test with CMXS coupon pool API
### CMXS Backend Deliverables Required Before Sprint 7
1. Prediction question API (GET `/v1/predictions/next`) with question authoring tool
2. Real-time resolution via WebSocket or polling endpoint
3. Wallet + coupon pool management API
4. Sponsor admin panel for coupon pool upload
5. Prize indemnity insurance process documented (Odds On Promotions or equivalent)
6. Community pool activation API (for team-win-triggered community rewards)

***
## Part 9: Why the Combined Model Wins — Strategic Summary
Three converging forces make June 2026 the optimal moment to launch this combined model:

**1. Viewer behavior has permanently shifted.** 216.8 million US adults will use a smartphone as a second screen in 2026, representing 80.6% of the population. Over 80% of sports fans use a second screen while watching live events. Arenza does not create a new behavior — it monetizes one that already exists.[^24][^25]

**2. Profile-only targeting is commoditized.** Every CTV platform runs audience targeting. Arenza's Secure Enclave PoD signing is a temporary moat — valuable, but ultimately replicable by any platform willing to build a native app. The prediction game layer creates a **content moat**: viewers return because of the game, not because of the stream. Session length increases. Churn decreases. The platform becomes a habit, not a utility

---

## References

1. [Behind Samsung's push to gamify the CTV ad experience ...](https://www.streamtvinsider.com/advertising/behind-samsungs-push-gamify-ctv-ad-experience-gamebreaks) - And initial research by Samsung Ads and MediaScience found the GameBreaks format delivers a 53% lift...

2. [Fan Engagement Market | Global Market Analysis Report](https://www.futuremarketinsights.com/reports/fan-engagement-market) - The fan engagement market was valued at USD 7.2 billion in 2025. The market is set to reach USD 8.5 ...

3. [Second Screen Market Evolution: $9.32B to 2033 Growth](https://www.datainsightsreports.com/reports/markt-fur-second-screen-engagement-97316) - Valued at an estimated $9.32 billion in 2026, the market is projected to reach approximately $26.18 ...

4. [Innovating The Interactive Sports Fan Experience](https://www.thebroadcastbridge.com/content/entry/21164/innovating-the-interactive-sports-fan-experience-monumental-sports-networ) - The interactive experience provides a new way to monetize MNMT's sports rights and continue offering...

5. [Samsung Ads Debuts Interactive Games for Advertisers](https://www.adweek.com/convergent-tv/samsung-ads-debuts-interactive-games-for-advertisers/) - The report found that in early beta testing, there was a 53% lift in unaided brand recall with GameB...

6. [CTV Advertising for Live Sports — 2026 Market Guide](https://www.streamlayer.io/blog/ctv-advertising-live-sports-2026-guide) - CTV live sports advertising is the fastest-growing digital ad segment. Market guide covering SGAI, p...

7. [Prize Indemnity Insurance](https://www.oddsonpromotions.com/prize-indemnity-insurance) - Odds On Promotions offers A+ rated prize indemnity insurance coverage for promotions, contests, spor...

8. [Prize Indemnity Insurance Explained](https://www.investopedia.com/terms/p/prize-indemnity-insurance.asp) - Prize indemnity insurance covers the cost of major prizes in promotional events, helping sponsors av...

9. [OmadaPrize: Game Sports Picks - App Store - Apple](https://apps.apple.com/us/app/omadaprize-game-sports-picks/id6673915098) - OmadaPrize is a free-to-play game where you use virtual coins to make sports predictions and compete...

10. [Samsung Ads Launches Interactive Gaming Formats On CTV](https://www.mediapost.com/publications/article/404685/samsung-ads-launches-interactive-gaming-formats-on.html) - Samsung Ads plans to roll out over eight games for advertisers to choose from in 2025.

11. [Samsung Ads reimagines CTV advertising with interactive ...](https://martechrecord.com/press-releases/samsung-ads-reimagines-ctv-advertising-with-interactive-and-game-based-ad-format/) - Independent research from MediaScience in the US, found that GameBreaks ads deliver a 53% lift in un...

12. [Game On: Samsung Ads launches interactive game-based ...](https://newdigitalage.co/ctv/game-on-samsung-ads-launches-interactive-game-based-ctv-ad-format-in-uk/) - GameBreaks ads deliver a 53% lift in unaided brand recall, outperforming standard video ads by 1.5x....

13. [Samsung Ads announces programmatic expansion of ...](https://www.advanced-television.com/2025/12/18/samsung-ads-announces-programmatic-expansion-of-gamebreaks/) - Samsung Ads has launched two new game formats to the growing GameBreaks portfolio, bringing the tota...

14. [Monumental Sports Network to Launch Integrated ...](https://monumentalsports.com/2025/02/monumental-sports-network-to-launch-integrated-sports-betting-and-gamification-features-for-capitals-and-wizards-streams/) - Monumental+ app will become first local streaming experience outside Las Vegas to feature live sport...

15. [Monumental Sports Network to Launch Integrated ...](https://www.sportsvideo.org/2025/02/04/monumental-sports-network-to-launch-integrated-sports-betting-and-gamification-features-for-capitals-and-wizards-streams/) - Monumental+ (M+), powered by ViewLift, will feature integrated real-time sports betting odds and gam...

16. [Monumental Sports Network Pioneers Interactivity for ...](https://monumentalsports.com/2025/06/monumental-sports-network-pioneers-interactivity-for-womens-sports-by-offering-integrated-sports-betting-and-gamification-features-for-mystics-games/) - MNMT throughout the 2025 WNBA season. offer viewer interactivity including live sports betting, adva...

17. [Sports gamification | Free-to-play games](https://www.geniussports.com/engage/gamification/) - Engage and monetise sports fans with gamification solutions that capture valuable data, boost loyalt...

18. [2025 Sporting Events Marketing Calendar](https://www.snipp.com/blog/sports-event-marketing-calendar-2025) - 2025 Sporting Events Marketing Calendar: CPG Marketing, Sweepstakes Marketing, Sports Marketing, Con...

19. [Snipp's Gambit partners with Scuti, a leading brand-fueled ...](https://www.snipp.com/company/news/snipps-gambit-partners-with-scuti-a-leading-brand-fueled-rewards-platform) - The partnership provides an exchange where players can purchase items from the Scuti marketplace and...

20. [Stop Training Fans to Wait for Discounts: A World Cup ...](https://www.vinfotech.com/insights/world-cup-2026-playbook-for-football-brands) - Winners receive brand-sponsored rewards (coupons, store credits, limited freebies) in a Rewards Wall...

21. [Sports and Gaming Law 2025 Year in Review: Top Five ...](https://www.wilmerhale.com/en/insights/client-alerts/20260217-sports-and-gaming-law-2025-year-in-review) - In 2025, several states sued Kalshi, Robinhood and other operators, asserting that sports-related ev...

22. [Where Is Sports Betting Legal? Updates for All 50 States](https://www.actionnetwork.com/online-sports-betting) - We've compiled a comprehensive look at the status of sports betting in all 50 states (plus Washingto...

23. [Boom Fantasy Promo Code GRINDERS to Play $5, Get ...](https://rotogrinders.com/fantasy/boom-fantasy-promo) - The Boom Sports promo code GRINDERS yields the welcome offer of Play $5, Get $55 in Free Lineups! Th...

24. [Reimagining Fan Engagement: From Passive Viewing to ...](http://www.presidio.com/blogs/reimagining-fan-engagement-from-passive-viewing-to-immersive-sports-experiences/) - To combat attention drift and maximize engagement, sports content must be designed to be personalize...

25. [Second-Screen Engagement During Live Sports](https://www.emarketer.com/content/second-screen-engagement-during-live-sports) - Live sports viewing is increasingly a two-screen experience, with smartphones serving as the preferr...

