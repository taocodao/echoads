# TableSpin: Restaurant Loyalty Game — iOS App Development Plan
### For Antigravity Development Team

---

## 1. EXECUTIVE SUMMARY

**Product:** TableSpin — a gamified restaurant loyalty platform that combines time-limited spin-to-win mechanics with a QR-based member identity card and a tiered spending loyalty program.

**Target Market:** Independent restaurants, QSR chains, and dining groups seeking to increase visit frequency, basket size, and customer data capture beyond basic punch-card programs.

**Core Loop:** Diner scans QR → plays spin (daily limit) → wins reward → QR code generated → server scans at POS → reward applied automatically → loyalty tier updated.

---

## 2. MARKET OPPORTUNITY

| Segment | 2025 Value | CAGR | Notes |
|---|---|---|---|
| Global Loyalty Programs Market | $93.8B | 15.9% YoY | Fastest-growing CRM category |
| U.S. Loyalty Programs | $27.3B | 15.7% YoY | Restaurant sector leads |
| Gamification Market | $26–29B | 17% | Enterprise + consumer combined |
| Restaurant Tech (POS/Loyalty) | ~$6B | ~12% | High fragmentation → acquisition targets |

**Why this model fits restaurants specifically:**
- Restaurants have the highest return-visit incentive of any retail category (avg. 4–6x/month for loyalists)
- Game mechanics increase daily app opens even on non-visit days
- Time-limited rewards drive urgency ("come in by Thursday") unlike passive point accumulation
- QR-based membership eliminates physical card costs and integrates natively with existing POS barcode scanners
- Gift card / threshold tiers (spend $100 → unlock 10% tier) create known margin-safe discount structures

**Adjacent business fits:** Coffee shops, fast-casual chains, food halls, hotel F&B, sports venue concessions, bar programs.

---

## 3. PRODUCT ARCHITECTURE

### 3.1 Core System Components

```
┌─────────────────────────────────────────────────────┐
│                    iOS App (Swift/SwiftUI)            │
│  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐ │
│  │  Spin Game   │ │ QR Name Card │ │ Loyalty Wallet│ │
│  │  (SpriteKit) │ │  + Rewards   │ │  + Tiers     │ │
│  └──────────────┘ └──────────────┘ └──────────────┘ │
└─────────────────────────────────────────────────────┘
           ↕ REST API / GraphQL
┌─────────────────────────────────────────────────────┐
│                 Backend (Node.js / FastAPI)           │
│  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐ │
│  │  Game Engine │ │  Reward Engine│ │  POS Bridge  │ │
│  │  (odds/limits│ │  (QR tokens) │ │  (webhook)   │ │
│  └──────────────┘ └──────────────┘ └──────────────┘ │
└─────────────────────────────────────────────────────┘
           ↕
┌─────────────────────────────────────────────────────┐
│              Restaurant Operator App (iOS/Android)    │
│  POS scan · member lookup · reward redemption        │
└─────────────────────────────────────────────────────┘
```

### 3.2 Data Models

**Member**
```json
{
  "member_id": "MBR-A3F2-9X71",
  "name": "Alex Rivera",
  "email": "alex@email.com",
  "phone": "+1-XXX-XXX-XXXX",
  "tier": "regular",
  "total_spend": 47.00,
  "total_points": 2340,
  "created_at": "2025-06-01T00:00:00Z",
  "daily_plays": { "date": "2026-06-10", "used": 1, "max": 3 },
  "active_rewards": [],
  "claimed_rewards": []
}
```

**Reward Token**
```json
{
  "reward_id": "RWD-A3F2-9X71-1718025600",
  "member_id": "MBR-A3F2-9X71",
  "reward_type": "10_pct_off",
  "reward_label": "10% OFF",
  "status": "active",
  "created_at": "2026-06-10T18:30:00Z",
  "expires_at": "2026-06-10T18:35:00Z",
  "claimed_at": null,
  "pos_terminal_id": null,
  "session_token": "jwt-signed-payload"
}
```

**Play Session**
```json
{
  "session_id": "SES-XYZ-123",
  "member_id": "MBR-A3F2-9X71",
  "restaurant_id": "copper-grill-nyc",
  "date": "2026-06-10",
  "spins_used": 1,
  "spins_max": 3,
  "outcomes": ["10_pct_off"],
  "session_start": "2026-06-10T18:29:00Z",
  "session_end": null,
  "status": "active"
}
```

---

## 4. iOS APP — SCREEN-BY-SCREEN SPECIFICATION

### Tab 1: 🎰 Spin Screen
**Purpose:** Primary engagement loop. Time-limited daily game.

**Components:**
- Restaurant identity badge (pulled from QR scan or deep link on arrival)
- Play counter with pip indicators (●●● → ●●○ → ●○○ → ○○○)
- Animated SpriteKit wheel (8 reward segments, physics-based deceleration)
- SPIN button → disabled while spinning, post-win, or plays exhausted
- Session timer bar: 5-minute countdown after a win, reward expires if unclaimed
- Loyalty progress card (current spend → next tier threshold)

**Key Logic:**
1. Check `daily_plays.date` vs. today → reset if stale
2. Check `daily_plays.used` < `daily_plays.max` → allow spin
3. Call `/api/spin` → server-authoritative outcome (never trust client odds)
4. If win: generate signed JWT reward token → render QR
5. Start 300-second expiry countdown on device
6. If claim: POST `/api/rewards/{id}/claim` with `pos_terminal_id`
7. If expires: PATCH reward status to `expired`, unlock remaining spins

**Anti-abuse rules (server-side):**
- Rate limit: max 1 spin per 8 seconds per member
- IP + device fingerprint secondary check
- Reward token is single-use, signed (HMAC-SHA256), and short-lived (5 min TTL)
- Daily reset: midnight local time per restaurant timezone

---

### Tab 2: 🪪 My Card Screen
**Purpose:** Persistent member identity. QR for POS membership lookup and reward redemption.

**Layout:**
- Premium dark membership card (like a credit card visual)
  - Restaurant branding (top-left logo)
  - Tier badge (Newcomer → Regular → VIP → Diamond)
  - Scannable QR code encoding member_id + HMAC signature
  - Member name + masked ID
  - Points total
  - Valid-thru date
- Saved Rewards list: scrollable, shows active + claimed history
  - Each row: reward emoji + name + code + date + status pill
  - Tap active reward → re-opens QR redemption modal

**QR Content (encrypted):**
```
{
  "v": 1,
  "mid": "MBR-A3F2-9X71",
  "sig": "hmac-sha256-signature",
  "ts": 1718025600
}
```
Member card QR is **long-lived** (rotates weekly). Reward QR tokens are **short-lived** (5 min).

---

### Tab 3: 📊 Dashboard Screen (Restaurant Operator View)
**Access:** Protected behind restaurant login (different role from diner)

**KPI Row:**
- Daily Active Players (DAU)
- Total Spins Today
- Win Rate (configurable per restaurant, default 35%)
- Rewards Claimed

**Charts:**
- 7-day DAU line chart
- Reward distribution donut chart

**Session table:**
- Recent 20 sessions: player alias, time, spins used, win/loss, reward type

**Operator Controls:**
- Configure daily spin limit (1–5)
- Configure win probability per reward tier
- Set reward expiry window (1–10 minutes)
- Toggle individual rewards on/off
- Export CSV report

---

## 5. LOYALTY TIERS & ECONOMICS

| Tier | Spend Threshold | Benefit | Margin Impact |
|---|---|---|---|
| 🌱 Newcomer | $0+ | Play access | None |
| 🔥 Regular | $50+ total | 5% off any visit | ~3.5% net (upsell offset) |
| ⭐ VIP | $150+ | 10% off + priority spin | ~6% net |
| 💎 Diamond | $500+ | 15% off + free item/month | ~9% net (high LTV offset) |

**Gift Card Integration:**
- Customer purchases $50 gift card via app (or at counter with barcode)
- Restaurant operator scans barcode → system ties card to member profile
- Spend tracked automatically via POS webhook
- Threshold promotions: "Load $100, get 500 bonus points"

---

## 6. TECHNICAL STACK RECOMMENDATION

### iOS App
| Component | Technology |
|---|---|
| Language | Swift 6.0 |
| UI Framework | SwiftUI (primary) + UIKit where needed |
| Game Engine | SpriteKit (wheel animation, confetti) |
| QR Generation | CoreImage (CIQRCodeGenerator) — no 3rd party needed |
| QR Scanning | AVFoundation (for member lookup at POS) |
| Networking | Async/Await + URLSession |
| Auth | Sign in with Apple + phone OTP |
| Local Storage | SwiftData (CoreData successor) |
| Analytics | Mixpanel or Amplitude |
| Push Notifications | APNs (reward about to expire warning) |

### Backend
| Component | Technology |
|---|---|
| Runtime | Node.js 22 + TypeScript, or Python FastAPI |
| Database | PostgreSQL (primary) + Redis (session/rate limit) |
| Queue | BullMQ (reward expiry jobs) |
| Auth | JWT (HS256 for reward tokens, RS256 for user auth) |
| POS Webhook | REST endpoint + HMAC signature verification |
| Hosting | Railway / Fly.io (prototype), AWS ECS (production) |
| CDN | Cloudflare (QR image caching) |

### POS Integration Strategy
- Phase 1: Manual scan via restaurant operator iOS app (AVFoundation scanner)
- Phase 2: REST webhook POST to major POS systems (Toast, Square, Clover)
- Phase 3: Native SDK plugins for Toast POS and Square Terminal

---

## 7. API ENDPOINTS

```
POST   /api/auth/register          → create member profile
POST   /api/auth/otp               → phone verification
GET    /api/members/:id            → member profile + play status
POST   /api/sessions/start         → create play session for restaurant
POST   /api/spin                   → server-authoritative spin outcome
GET    /api/rewards/:id            → reward token status
POST   /api/rewards/:id/claim      → POS redemption (operator-only)
GET    /api/members/:id/rewards    → reward history
POST   /api/giftcards/scan         → link gift card to member
GET    /api/dashboard              → operator analytics (auth required)
GET    /api/dashboard/export       → CSV export
PATCH  /api/restaurants/:id/config → update spin config (operator)
```

---

## 8. GAME MECHANICS SPECIFICATIONS

### Spin Wheel
- **Segments:** 8 (configurable by operator)
- **Animation:** Physics-based deceleration curve (ease-in-out cubic), minimum 4 full rotations
- **Duration:** 4–6 seconds (feels authentic, not instant)
- **Outcome:** Server-authoritative (POST /api/spin → server picks outcome based on current odds config → returns result → app animates to matching segment)

### Daily Play Limits
- Default: 3 spins/day per member per restaurant
- Reset: midnight in restaurant's local timezone
- Configurable: operators set 1–5 max
- "Bonus spin" unlock: triggered by spending over tier threshold that day

### Reward Probability Config (operator-adjustable)
```
No reward:    ~28% (try again + better luck)
5% off:       20%
10% off:      20%
Free drink:   8%
Free appetizer: 12%
Dessert:      7%
Mystery reward: 5%
```

### Session Expiry Rules
1. Reward generated → 5-minute countdown begins
2. At 1:00 remaining → push notification: "Your reward expires soon!"
3. At 0:00 → token status → `expired`, spin slot reopens (if plays remain)
4. Claimed token → immediately invalidated at POS

---

## 9. DEVELOPMENT PHASES

### Phase 1 — MVP (8 weeks, 2 developers)
**Week 1–2:** Backend API scaffold (auth, member, spin engine, reward token system)
**Week 3–4:** iOS diner app (spin screen + QR modal + loyalty card)
**Week 5–6:** iOS operator app (scan + claim flow)
**Week 7:** POS mock integration + end-to-end test
**Week 8:** TestFlight beta, restaurant pilot (1 location)

**Deliverables:** Working spin-to-win game, QR member card, reward claim at mock POS.

### Phase 2 — Growth (6 weeks)
- Dashboard with analytics
- Gift card / threshold loyalty tiers
- Apple/Google Wallet pass for member QR card
- Push notification flows (expiry alerts, bonus spin unlocks)
- Multi-restaurant support + operator onboarding

### Phase 3 — Scale (8 weeks)
- Toast POS native webhook integration
- Square Terminal integration
- White-label branding per restaurant
- Scratch card alternative mechanic
- Enterprise analytics (cohort, LTV, churn prediction)

---

## 10. MONETIZATION MODEL

| Revenue Stream | Model | Rate |
|---|---|---|
| SaaS subscription | Per-location/month | $79–$299/mo |
| Transaction fee | Per reward claimed | $0.05/redemption |
| Gift card processing | Interchange | 1.5% |
| White-label | Enterprise | Custom |
| Data insights | Aggregate opt-in | Upsell tier |

**Unit Economics (per restaurant/month):**
- 200 daily active users × 2.5 avg spins × 30 days = 15,000 spins/month
- 35% win rate = 5,250 rewards generated
- 85% claim rate = 4,462 redemptions × $0.05 = $223 transaction revenue
- Plus subscription: $199 → **total ~$422/location/month**

---

## 11. SECURITY & COMPLIANCE

- **Reward token security:** HMAC-SHA256 signed JWTs, 5-min TTL, single-use
- **Anti-fraud:** Device fingerprinting, rate limiting, replay attack prevention (nonce in token)
- **PII:** Minimal collection, CCPA/GDPR compliant, phone-based auth avoids email dependency
- **Age verification:** Restaurant can flag alcohol rewards for 21+ gate
- **Apple App Store compliance:** Rewards tied to real-world purchase, not in-app purchase → not gambling under Apple guidelines (matches Starbucks Stars, McDonald's Monopoly model)

---

## 12. DEMO SCRIPT (for investor/restaurant pitch)

1. Open app → see "The Copper Grill" (deeplinked from table QR)
2. Show 3 play pips — "You have 3 spins today"
3. Tap SPIN → animated wheel → lands on "10% OFF"
4. QR code appears with 5-min countdown
5. Demo: server scans QR on operator app → "Reward Applied ✅"
6. Switch to My Card tab → QR membership card, saved rewards
7. Switch to Dashboard → show DAU, win rate, session table
8. Show loyalty progress: "$47 of $100 spent → unlock Regular tier discount"

**Key talking points:**
- "This is how Starbucks built $6.8B in gift card float — we bring that mechanic to independent restaurants"
- "Every spin is a push notification reason that doesn't feel like marketing"
- "The QR card replaces the loyalty stamp card, the gift card, and the discount coupon — one scan does all three"

---

*Document prepared for Antigravity development team · TableSpin v1.0 · June 2026*
