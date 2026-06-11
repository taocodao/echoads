# Arenza Interactive Ad System — Implementation Plan for Antigravity

**Document Version:** 1.0  
**Date:** June 9, 2026  
**Prepared for:** Antigravity Development Team  
**Project:** Arenza Fan Engagement & Sponsored Ad Engine  

---

## Executive Summary

This document is the complete technical and product implementation blueprint for the **Arenza Interactive Ad System** — a real-time, gamified fan engagement platform that runs alongside live sports broadcasts. The system combines four interactive ad formats (Live Prediction, Bingo Card, Scratch & Win, More or Less) with a points economy, coupon tracking wallet, and B2B sponsor dashboard.

The design is informed by three industry benchmarks:
- **Monterosa / Interaction Cloud** — real-time SDK overlay, first-party data capture
- **SQWAD** — QR-triggered gamification, 78% opt-in rate, 98% email open rates
- **PrizePicks** — binary "More or Less" mechanic, 20M users, frictionless entry

The four ad demos (delivered as `arenza-interactive-ads.html`) serve as interactive mockups and reference implementations for the production build.

---

## 1. System Architecture Overview

### 1.1 High-Level Components

```
┌──────────────────────────────────────────────────────────────┐
│                    ARENZA PLATFORM                           │
├──────────────┬───────────────┬──────────────┬───────────────┤
│  Fan-Facing  │  Game Engine  │  Sponsor CMS │  Data Layer   │
│  Web App     │  (WebSocket)  │  Dashboard   │  (Analytics)  │
├──────────────┴───────────────┴──────────────┴───────────────┤
│              CDN / Edge Network (Cloudflare)                 │
└──────────────────────────────────────────────────────────────┘
```

### 1.2 Tech Stack (Recommended)

| Layer | Technology | Rationale |
|---|---|---|
| **Frontend** | React 19 + TypeScript | Component reuse across 4 ad formats |
| **Styling** | CSS Modules + design tokens | Matches the token system in demo HTML |
| **Real-time** | Supabase Realtime / Pusher | WebSocket for bingo auto-update, live polls |
| **Backend API** | Node.js + Fastify | Low-latency, high-concurrency |
| **Database** | PostgreSQL (Supabase) | Points ledger, coupon codes, game state |
| **Cache** | Redis | Game session state, leaderboard |
| **Queue** | BullMQ | Coupon code generation, email delivery |
| **Auth** | Supabase Auth | Phone/email magic link, guest mode |
| **CDN** | Cloudflare | Edge caching, DDoS protection |
| **Analytics** | PostHog | First-party behavioral events |
| **Hosting** | Fly.io or Railway | Fast global deployment |

---

## 2. The Four Interactive Ad Formats

### 2.1 Ad Format 1 — Live Prediction Banner

**Concept:** A countdown-gated question tied to a live game moment. Fan selects an outcome, locks in before timer expires, gets points when correct.

**Inspired by:** Monterosa Interaction Cloud's live polls that "build a sense of community between fans and brands."

#### Component Spec

```
PredictionAd
├── LiveHeader (game clock, sponsor logo)
├── QuestionDisplay (text + highlighted team names)
├── OptionGrid (2–4 buttons with % fill bars)
│   └── OptionButton (selectable, locked state, winner highlight)
├── PredictionFooter
│   ├── TimerCountdown (animated, red when <10s)
│   ├── PointsLabel (+250 pts sponsor prize)
│   └── LockInButton (disabled until selection)
└── ResultBanner (correct / incorrect + points delta)
```

#### State Machine

```
IDLE → QUESTION_ACTIVE → SELECTION_MADE → LOCKED → RESULT_SHOWN → RESET
```

- `QUESTION_ACTIVE`: Timer running. Options are clickable.
- `SELECTION_MADE`: User picked. Lock-In button enabled.
- `LOCKED`: API call fired. All options frozen. Timer cleared.
- `RESULT_SHOWN`: Correct/incorrect displayed. Points awarded via ledger API.

#### API Contracts

```typescript
// POST /api/games/{gameId}/predictions
interface LockPredictionRequest {
  userId: string;
  questionId: string;
  selectedOptionId: string;
  lockedAt: string; // ISO timestamp — must be before deadline
}

interface LockPredictionResponse {
  success: boolean;
  pointsEarned: number; // 0 if after deadline
  newBalance: number;
  couponUnlocked?: CouponCode;
}
```

#### Real-time Event (WebSocket)

```typescript
// Server → Client via Supabase channel: game:${gameId}
interface PredictionResultEvent {
  type: 'PREDICTION_RESULT';
  questionId: string;
  correctOptionId: string;
  totalResponses: number;
  distribution: Record<string, number>; // optionId → % of votes
}
```

#### Key Implementation Rules
- Timer must be **server-authoritative**. Client countdown is display-only.
- Deadline validation happens server-side. Reject any lock received after `question.deadline`.
- `distribution` percentages update live via WebSocket as fans vote (like Monterosa).
- Point award is idempotent: same `userId + questionId` pair never awards twice.

---

### 2.2 Ad Format 2 — Auto-Updating Bingo Card

**Concept:** Fan receives a unique 5×5 bingo board. As game events happen (broadcast-triggered), cells auto-mark. First to complete a line wins a sponsor prize.

**Inspired by:** SQWAD Bingo — "fans scan a QR code and receive auto-updating bingo boards" — winner of Fan Engagement and Sponsor ROI industry award.

#### Component Spec

```
BingoAd
├── BingoHeader (sponsor, game clock)
├── BingoBoard
│   ├── ColumnHeaders [B, I, N, G, O]
│   └── CellGrid (25 cells, unique per user)
│       └── BingoCell (states: default, marked, win-line, free)
├── BingoSidebar
│   ├── PrizeTierList (1-line, 2-line, full card, blackout)
│   ├── QRShareCard (unique board URL)
│   └── WinBanner (hidden until BINGO)
└── AutoMarkIndicator (live event fired)
```

#### Board Generation Algorithm

```typescript
function generateBingoBoard(userId: string, gameId: string): BingoBoard {
  // Deterministic shuffle: same user+game always gets same board
  const seed = hashString(`${userId}:${gameId}`);
  const allCells = GAME_CELLS_POOL[gameId]; // 60+ cells per game type
  const shuffled = seededShuffle(allCells, seed);
  const board = shuffled.slice(0, 24); // 25th is FREE center
  board.splice(12, 0, { id: 'FREE', label: 'FREE SPACE', autoMark: true });
  return board;
}
```

#### Auto-Mark Flow

```
[Broadcast Producer triggers event] 
    → POST /api/admin/games/{gameId}/events { eventType: 'THREE_POINTER' }
    → Server looks up all users with that cell type
    → Marks cells in DB
    → Broadcasts via WebSocket: { type: 'CELL_MARKED', cellId: 'THREE_POINTER' }
    → Each client checks own board, animates matching cell
    → Server checks for bingo (all lines), awards prizes
```

#### Critical Rules
- Each user's board is **unique** (seeded shuffle). No two fans get identical boards — prevents simultaneous group BINGO, preserves prize scarcity.
- Free cell (index 12) is always pre-marked.
- Bingo line check runs **server-side**. Client animation is cosmetic only.
- QR share URL: `arenza.app/b/{boardToken}` where `boardToken` is a signed JWT of `userId+gameId`.

#### WebSocket Events

```typescript
// Server → Client
type BingoEvent =
  | { type: 'CELL_AUTO_MARKED'; cellTypes: string[] }
  | { type: 'BINGO_DETECTED'; userId: string; lineType: 'row'|'col'|'diag'; pts: number }
  | { type: 'BLACKOUT_WINNER'; userId: string; prize: PrizeTier }
```

---

### 2.3 Ad Format 3 — Scratch & Win Coupon

**Concept:** Fan earns scratch cards by hitting score thresholds or watching a sponsor segment. Each card reveals a real discount code that auto-saves to their coupon wallet.

**Inspired by:** SQWAD's scratch card activations which achieved 3.2× higher coupon redemption via behavioral segmentation.

#### Component Spec

```
ScratchAd
├── ScratchHeader (sponsor, remaining cards count)
├── ScratchCardGrid (1–3 cards)
│   └── ScratchCard (states: covered, reveal-animating, revealed-win, revealed-loss)
│       ├── ScratchCover (tap target)
│       └── ScratchReveal (prize label, coupon code, pts)
└── CouponWalletPreview
    ├── CouponCode (monospace, dashed border)
    ├── CopyButton
    └── ExpiryTimer (countdown)
```

#### Scratch Card Reveal Animation

```css
/* Phase 1: Cover scales + rotates away (0→500ms) */
.scratch-cover {
  transition: transform 0.5s cubic-bezier(0.16,1,0.3,1), opacity 0.4s ease;
}
.scratch-card.revealed .scratch-cover {
  transform: scale(1.2) rotate(8deg);
  opacity: 0;
}

/* Phase 2: Reveal fades in after 300ms delay */
.scratch-reveal {
  opacity: 0;
  transform: scale(0.85);
  transition: opacity 0.4s ease 0.3s, transform 0.5s cubic-bezier(0.16,1,0.3,1) 0.3s;
}
.scratch-card.revealed .scratch-reveal {
  opacity: 1;
  transform: scale(1);
}
```

#### Coupon Code Generation (Backend)

```typescript
// BullMQ job: triggered when fan earns a scratch card
async function generateCouponCode(job: ScratchJob) {
  const { userId, sponsorId, tierId } = job.data;
  const code = `${SPONSOR_PREFIX[sponsorId]}-${nanoid(8).toUpperCase()}`;
  
  await db.coupons.insert({
    userId, sponsorId, tierId,
    code,
    value: PRIZE_TIERS[tierId].value,
    expiresAt: addHours(new Date(), 48),
    status: 'UNREVEALED'
  });

  // Notify client: show scratch card
  await pusher.trigger(`user-${userId}`, 'scratch-card-ready', { cardId });
}
```

#### Coupon Wallet Schema

```sql
CREATE TABLE coupons (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID NOT NULL REFERENCES users(id),
  sponsor_id  UUID NOT NULL REFERENCES sponsors(id),
  code        TEXT NOT NULL UNIQUE,
  tier        TEXT NOT NULL, -- 'LOSS' | 'SMALL' | 'MEDIUM' | 'JACKPOT'
  value       JSONB,         -- { type: 'percent', amount: 30 } | { type: 'free_item', item: 'brownie' }
  status      TEXT NOT NULL DEFAULT 'UNREVEALED', -- UNREVEALED | REVEALED | CLAIMED | EXPIRED
  revealed_at TIMESTAMPTZ,
  claimed_at  TIMESTAMPTZ,
  expires_at  TIMESTAMPTZ NOT NULL,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX ON coupons(user_id, status);
CREATE INDEX ON coupons(code);
```

#### Attribution Tracking

Every coupon code embeds a sponsor-readable attribution token so the B2B dashboard can show the full chain:

```
Fan watches game → earns scratch card → reveals COUPON_CODE → redeems at Domino's
         ↓                                                              ↓
   [interaction_event]                                    [redemption_webhook]
         └──────────── sponsor ROI report ←─────────────────────────────┘
```

---

### 2.4 Ad Format 4 — More or Less Player Props

**Concept:** Fan picks whether a player will score More or Less than a stated line on a stat (points, rebounds, assists, 3-pointers). Free-to-play with Arenza points. Pick 2+ for a multiplier.

**Inspired by:** PrizePicks' binary mechanic used by 20 million fans. The simplest possible prediction format.

#### Component Spec

```
MoreLessAd
├── Header (sponsor, game type)
├── PlayerCardGrid (2–6 cards)
│   └── PlayerCard
│       ├── PlayerInfo (avatar, name, team)
│       ├── StatLine (large number, context text)
│       └── PickButtons [MORE ↑] [LESS ↓]
├── EntryFooter
│   ├── PickCounter (N / max)
│   ├── MultiplierIndicator (1×, 2×, 4×)
│   └── SubmitEntryButton
└── LeaderboardWidget (live rank)
```

#### Multiplier Table

| Correct Picks | Multiplier | Points |
|---|---|---|
| 2 of 2 | 1.5× | +375 pts |
| 3 of 3 | 3× | +750 pts |
| 4 of 4 | 6× | +1,500 pts |
| 5 of 5 | 10× | +2,500 pts |
| 6 of 6 | 25× | +6,250 pts |

#### Entry Submission Flow

```typescript
async function submitMLEntry(req: SubmitMLRequest): Promise<MLEntryResponse> {
  const { userId, picks } = req; // picks: { playerId, stat, direction: 'more'|'less' }[]
  
  // 1. Validate all lines are still open (game not started)
  const validLines = await db.statLines.findAll({ 
    where: { id: { in: picks.map(p => p.lineId) }, status: 'OPEN' }
  });
  if (validLines.length !== picks.length) throw new Error('Some lines are closed');
  
  // 2. Deduct entry cost (0 points — free to play)
  // 3. Create entry record
  const entry = await db.entries.create({ userId, picks, status: 'PENDING', multiplier: calcMultiplier(picks.length) });
  
  // 4. Return entry receipt
  return { entryId: entry.id, maxWin: BASE_POINTS * entry.multiplier, picks: entry.picks };
}
```

#### Result Resolution (Automated)

```typescript
// Scheduled job: runs after each game ends
async function resolveMLEntries(gameId: string) {
  const finalStats = await fetchFinalStats(gameId); // from sports data API
  const entries = await db.entries.findAll({ where: { gameId, status: 'PENDING' } });

  for (const entry of entries) {
    const correct = entry.picks.filter(p => {
      const actual = finalStats[p.playerId][p.stat];
      return p.direction === 'more' ? actual > p.line : actual < p.line;
    });
    const allCorrect = correct.length === entry.picks.length;
    const ptsEarned = allCorrect ? BASE_POINTS * entry.multiplier : 0;
    
    await db.entries.update(entry.id, { status: allCorrect ? 'WON' : 'LOST', ptsEarned });
    if (allCorrect) await awardPoints(entry.userId, ptsEarned, `ML Entry Win - ${entry.id}`);
  }
}
```

---

## 3. Points Economy & Ledger

### 3.1 Earning Rules

| Action | Points | Cadence |
|---|---|---|
| Correct prediction | +250 | Per question |
| Bingo cell marked | +50 | Per cell |
| Bingo line completed | +500 | Per line |
| Bingo blackout | +2,000 | Per game |
| Scratch card win (small) | +150 | Per card |
| Scratch card win (big) | +500 | Per card |
| Any scratch card (loss) | +25 | Per card |
| ML entry — all correct | up to +6,250 | Per entry |
| Daily login bonus | +50 | Once/day |
| First prediction of day | +25 | Once/day |
| Trivia correct | +100 | Per question |
| Refer a friend | +500 | Per new user |

### 3.2 Ledger Schema

```sql
CREATE TABLE points_ledger (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID NOT NULL REFERENCES users(id),
  delta       INTEGER NOT NULL,       -- positive = earned, negative = spent
  balance     INTEGER NOT NULL,       -- running total
  reason      TEXT NOT NULL,          -- human-readable audit label
  source_type TEXT NOT NULL,          -- 'PREDICTION' | 'BINGO' | 'SCRATCH' | 'ML' | 'REDEMPTION'
  source_id   UUID,                   -- FK to prediction/bingo/entry
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- Prevent negative balances at DB level
CREATE OR REPLACE FUNCTION check_balance() RETURNS TRIGGER AS $$
BEGIN
  IF NEW.balance < 0 THEN
    RAISE EXCEPTION 'Insufficient points balance';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER enforce_positive_balance
  BEFORE INSERT ON points_ledger
  FOR EACH ROW EXECUTE FUNCTION check_balance();
```

### 3.3 Redemption Flow (Points → Prize)

```
Fan browses Prize Shop → clicks item (requires X pts)
    → POST /api/shop/redeem { itemId, userId }
    → Server: check balance, check item stock, atomic debit
    → Generate order token + coupon code
    → Decrement ledger (negative delta)
    → Push CouponCode to wallet
    → Notify sponsor fulfillment webhook
```

---

## 4. Coupon Wallet — Full Feature Spec

### 4.1 Wallet UI Components

```
CouponWallet
├── WalletHeader (count badge, filter tabs: Active | Used | Expired)
├── CouponList
│   └── CouponCard
│       ├── SponsorLogo
│       ├── CouponTitle (e.g. "30% off Domino's")
│       ├── CouponCode (monospace, tap-to-copy)
│       ├── ExpiryBadge (days remaining, red when <24h)
│       ├── BarcodeMock (for in-store use)
│       └── CopyButton / Use Now Button
└── EmptyState (with CTA to play more)
```

### 4.2 Code Copy & Auto-Apply Rules

- **Mobile:** Tap code → copy to clipboard + haptic feedback + toast confirmation.
- **Web:** Click → copy + toast.
- **Auto-apply:** If fan navigates to sponsor's URL from within Arenza app, code is injected into the checkout session via URL parameter (`?promo=DOM-SAVE30`) or a postMessage to an embedded checkout iframe.
- **In-store:** Barcode (Code-128) generated client-side using `jsbarcode` library. No server call needed.

### 4.3 Expiry Handling

```typescript
// Scheduled job: every hour
async function expireCoupons() {
  const expired = await db.coupons.findAll({
    where: { status: 'REVEALED', expires_at: { lt: new Date() } }
  });
  await db.coupons.bulkUpdate(expired.map(c => c.id), { status: 'EXPIRED' });
  // Push push notification to users with expiring-soon coupons (< 2h)
  const expiringSoon = await db.coupons.findAll({
    where: { status: 'REVEALED', expires_at: { lt: addHours(new Date(), 2), gt: new Date() } }
  });
  await sendPushBatch(expiringSoon.map(c => ({ userId: c.userId, msg: `Your ${c.sponsor} coupon expires in 2 hours!` })));
}
```

---

## 5. Sponsor B2B Dashboard

### 5.1 Dashboard Pages

| Page | Key Metrics |
|---|---|
| **Campaign Overview** | Total impressions, interactions, opt-in rate, avg session time |
| **Engagement Funnel** | Views → Plays → Correct → Coupon Revealed → Coupon Redeemed |
| **Fan Segments** | Age bracket, engagement score, behavioral tags (e.g. "High food buyer") |
| **Coupon Performance** | Codes issued / revealed / redeemed, redemption rate, revenue attributed |
| **Real-time Monitor** | Live interaction count, current active users, live leaderboard |

### 5.2 Sponsor Campaign Setup (CMS)

The sponsor CMS allows non-technical brand managers to configure a campaign in 5 steps:

**Step 1 — Brand Assets**
- Upload logo (SVG/PNG, auto-optimized)
- Set brand primary color (used for ad accent)
- Input brand tagline (max 60 chars)

**Step 2 — Choose Ad Format**
- Prediction Banner / Bingo Card / Scratch & Win / More or Less
- Configure prize tiers (value, quantity, expiry duration)
- Set coupon code prefix (e.g. `PEPSI`, `DOM`, `BUD`)

**Step 3 — Game Targeting**
- Select sport / league / game date
- Choose trigger moments (halftime, Q3 start, kickoff, etc.)
- Set prediction questions (or use AI-suggested questions from game data)

**Step 4 — Points Budget**
- Allocate points budget (sponsor pays per correct predictor)
- Set max winners per game

**Step 5 — Fulfillment Setup**
- Redemption webhook URL (Arenza calls this when fan redeems)
- POS integration option (Shopify / custom API)
- Contact email for winner notifications

### 5.3 Webhook Payload (Sponsor Fulfillment)

```typescript
// Arenza → Sponsor system when coupon is redeemed
interface RedemptionWebhook {
  event: 'coupon.redeemed';
  timestamp: string;
  data: {
    orderId: string;
    couponCode: string;
    sponsorId: string;
    campaignId: string;
    fan: {
      anonymousId: string;       // hashed, never PII
      ageRange: '18-24' | '25-34' | '35-44' | '45+';
      engagementTier: 'casual' | 'active' | 'superfan';
    };
    prize: {
      type: 'percent' | 'fixed' | 'free_item';
      value: number | string;
    };
    gameContext: {
      sport: string;
      team: string;
      gameId: string;
    };
  };
}
```

---

## 6. Real-time Infrastructure

### 6.1 WebSocket Channel Architecture

```
Channels (Supabase Realtime / Pusher):

game:{gameId}               — All fans watching a game
  Events: QUESTION_OPEN, QUESTION_RESULT, CELL_AUTO_MARKED, BINGO_WINNER, LEADERBOARD_UPDATE

user:{userId}               — Private per-fan
  Events: POINTS_EARNED, COUPON_READY, SCRATCH_CARD_READY, BINGO_WIN

admin:{sponsorId}:game:{gameId} — Sponsor dashboard live feed
  Events: INTERACTION_COUNT, ENGAGEMENT_RATE, COUPON_ISSUED_COUNT
```

### 6.2 Scalability Targets

| Metric | Target |
|---|---|
| Concurrent fans per game | 100,000+ |
| WebSocket messages/sec | 50,000 |
| Prediction lock latency | < 200ms p99 |
| Bingo cell auto-mark fan notification | < 500ms |
| Points balance update | Real-time |
| Coupon code generation | < 1 second |

### 6.3 Horizontal Scaling

- **Redis pub/sub** for cross-instance WebSocket fan-out
- **Stateless API servers** behind load balancer (Fly.io machines)
- **PostgreSQL read replicas** for leaderboard queries
- **Edge caching** for static game assets (bingo cell pools, question banks)

---

## 7. Frontend Component Library

### 7.1 Shared Design Tokens (from demo)

```typescript
// tokens.ts — mirrors the CSS variables in arenza-interactive-ads.html
export const tokens = {
  font: {
    display: "'Barlow Condensed', sans-serif",
    body: "'Inter', sans-serif",
  },
  color: {
    accent: '#f5a623',
    accentHover: '#e09010',
    accentGlow: 'rgba(245,166,35,0.18)',
    green: '#22c55e',
    red: '#ef4444',
    blue: '#3b82f6',
    purple: '#a855f7',
  },
  radius: {
    sm: '0.375rem', md: '0.5rem', lg: '0.75rem', xl: '1rem', full: '9999px',
  },
  motion: {
    spring: 'cubic-bezier(0.16, 1, 0.3, 1)',
    duration: '180ms',
  }
};
```

### 7.2 Component Inventory

| Component | Description | Ad Formats Used In |
|---|---|---|
| `<LiveDot />` | Animated pulsing red dot | Prediction |
| `<CountdownTimer />` | Server-synced countdown, turns red <10s | Prediction |
| `<OptionButton />` | Selectable pick with % fill bar | Prediction, ML |
| `<BingoCell />` | 5 states: default/marked/win/free/auto-marking | Bingo |
| `<BingoBoard />` | 5×5 grid with BINGO headers | Bingo |
| `<ScratchCard />` | Cover/reveal animation with 2-phase transition | Scratch |
| `<CouponCode />` | Monospace code with copy button + expiry | Scratch, Wallet |
| `<PlayerCard />` | Avatar, stat line, More/Less buttons | More or Less |
| `<PointsBadge />` | Live-updating pts counter | All |
| `<ConfettiBurst />` | 40-particle win celebration | All win states |
| `<Toast />` | Slide-in notification, auto-dismiss 2.8s | All |
| `<Leaderboard />` | Top-5 ranked list, highlights current user | More or Less |
| `<SponsorStrip />` | Brand-aware header strip | All |
| `<QRShareCard />` | Mock QR + share CTA | Bingo |

### 7.3 Animation Principles (from Demo)

All animations follow these rules from the reference implementation:

```css
/* Spring easing — all interactive state transitions */
transition: all 180ms cubic-bezier(0.16, 1, 0.3, 1);

/* Entry animation — panels, banners, result reveals */
@keyframes fadeUp {
  from { opacity: 0; transform: translateY(12px); }
  to   { opacity: 1; transform: translateY(0); }
}

/* Win celebration — cells, cards */
@keyframes cell-pop {
  0%   { transform: scale(1); }
  50%  { transform: scale(1.15); }
  100% { transform: scale(1); }
}

/* Live indicator */
@keyframes pulse-dot {
  0%,100% { box-shadow: 0 0 0 0 rgba(239,68,68,0.5); }
  50%     { box-shadow: 0 0 0 6px rgba(239,68,68,0); }
}
```

**Rules:**
- No `display: none` → `display: block` without transition. Always animate opacity + transform together.
- Confetti burst: 40 pieces, 6 colors, `animation-duration: 0.8s–1.8s` randomized.
- Points counter: animate from current to target over 600ms with `setInterval` steps.
- Card hover: `translateY(-2px)` + shadow upgrade. Never scale on hover (feels broken on grid items).

---

## 8. Mobile-First Responsive Rules

All four ad formats must render correctly at:
- **375px** (iPhone SE) — minimum width
- **390px** (iPhone 14)
- **768px** (iPad)
- **1024px+** (desktop)

### 8.1 Responsive Breakpoints

```css
/* Prediction: options stack 1-col below 480px */
@media (max-width: 480px) {
  .pred-options { grid-template-columns: 1fr 1fr; }
}

/* Bingo: sidebar moves below board on mobile */
@media (max-width: 768px) {
  .bingo-ad { grid-template-columns: 1fr; }
  .bingo-sidebar { border-left: none; border-top: 1px solid var(--border); }
}

/* Scratch: 1 column on narrow screens */
@media (max-width: 480px) {
  .scratch-cards { grid-template-columns: 1fr; }
}

/* More/Less: single column card grid on mobile */
@media (max-width: 480px) {
  .moreless-grid { grid-template-columns: 1fr; }
}
```

### 8.2 Touch Targets
- All clickable cells / buttons: minimum **44×44px** tap area
- Bingo cells: `aspect-ratio: 1` with minimum `60px × 60px`
- OptionButtons: minimum `48px` height
- ML pick buttons: `padding: 12px` minimum

---

## 9. Accessibility Requirements

| Requirement | Implementation |
|---|---|
| WCAG AA contrast | All text on surfaces tested ≥ 4.5:1 |
| Keyboard navigation | Tab order: header → nav → game area → footer |
| Focus rings | `:focus-visible` outline: 2px accent, offset 3px |
| Screen reader | All icon-only buttons have `aria-label` |
| Live regions | Score updates use `aria-live="polite"` |
| Reduced motion | All animations respect `prefers-reduced-motion` |
| Timer | Screen reader announces timer with `aria-label="X seconds remaining"` |
| Bingo cell | Each cell has `aria-pressed` state |

---

## 10. Build Phases & Sprint Plan

### Phase 1 — Foundation (Weeks 1–3)

**Goal:** Auth, design system, points ledger, WebSocket infrastructure

- [ ] Set up Supabase project (auth, DB, realtime)
- [ ] Build design token CSS file (matches `arenza-interactive-ads.html` tokens)
- [ ] Implement shared component library: `PointsBadge`, `Toast`, `ConfettiBurst`, `SponsorStrip`
- [ ] Points ledger schema + API (earn, spend, balance)
- [ ] WebSocket channel setup (game channel, user private channel)
- [ ] Auth: phone magic link + guest mode (no-login bingo/prediction)
- [ ] **Deliverable:** Design system preview page + auth flow

### Phase 2 — Ad Format 1 & 2 (Weeks 4–7)

**Goal:** Prediction Banner + Bingo Card, production-ready

- [ ] `PredictionAd` component (all states, server-authoritative timer)
- [ ] Admin: question creation CMS, trigger scheduling
- [ ] Bingo board generator (seeded shuffle, 25-cell)
- [ ] `BingoAd` component (click-to-mark, auto-mark via WS)
- [ ] Bingo win detection (server-side line check)
- [ ] QR share card with signed board URL
- [ ] **Deliverable:** Both ad formats embeddable via `<script>` tag (like Monterosa SDK)

### Phase 3 — Ad Format 3 & 4 (Weeks 8–11)

**Goal:** Scratch & Win + More or Less

- [ ] Coupon code generation worker (BullMQ)
- [ ] `ScratchCard` component + reveal animation
- [ ] Coupon Wallet page (list, copy, expiry, barcode)
- [ ] `PlayerCard` + `MoreLessAd` component
- [ ] ML entry submission + multiplier logic
- [ ] Result resolution job (post-game stat fetcher)
- [ ] **Deliverable:** All 4 ad formats live, coupon wallet functional

### Phase 4 — Sponsor CMS & B2B Dashboard (Weeks 12–15)

**Goal:** Self-serve sponsor onboarding + ROI dashboard

- [ ] Sponsor campaign creation wizard (5-step CMS)
- [ ] Real-time analytics dashboard (engagement funnel, coupon metrics)
- [ ] Redemption webhook system
- [ ] Sponsor attribution reports (CSV export)
- [ ] Pricing tier access control (Starter / Season / Enterprise)
- [ ] **Deliverable:** B2B dashboard demo-ready for sales calls

### Phase 5 — Polish, Scale, Launch (Weeks 16–18)

**Goal:** Load testing, accessibility audit, production launch

- [ ] Load test: 100K concurrent users on bingo auto-mark
- [ ] Accessibility audit (WCAG AA)
- [ ] Core Web Vitals: LCP < 2.0s, INP < 200ms
- [ ] Push notification integration (FCM for mobile PWA)
- [ ] Sponsor onboarding documentation
- [ ] **Deliverable:** Public launch + first 3 sponsor campaigns live

---

## 11. Key Technical Gotchas & Decisions

| Issue | Decision | Rationale |
|---|---|---|
| **Timer synchronization** | Server-authoritative UTC timestamps; client display only | Prevents cheating by manipulating client clock |
| **Bingo board uniqueness** | Seeded shuffle with `userId+gameId` as seed | Same board across page refreshes; unique per user |
| **Points atomicity** | All point transactions use DB transactions with balance trigger | Prevents negative balances, prevents double-awards |
| **Coupon code collision** | `nanoid(8)` + sponsor prefix = ~280 trillion combos | Collision probability negligible at scale |
| **No localStorage** | All state in Supabase / Redis, guest sessions use URL token | iframe sandbox environments block localStorage |
| **Free-to-play compliance** | Points have no cash redemption path; prizes are sponsor goods | No gambling license required in any US state |
| **WebSocket fan-out** | Redis pub/sub behind Supabase Realtime | Single game event → 100K client notifications in <500ms |
| **Responsive bingo cells** | `aspect-ratio: 1` + `minmax(0, 1fr)` grid | Cells scale proportionally at any viewport width |

---

## 12. Environment Variables

```bash
# Database
DATABASE_URL=postgresql://...
REDIS_URL=redis://...

# Auth
SUPABASE_URL=https://xxx.supabase.co
SUPABASE_ANON_KEY=xxx
SUPABASE_SERVICE_ROLE_KEY=xxx

# Real-time (choose Supabase Realtime or Pusher)
PUSHER_APP_ID=xxx
PUSHER_KEY=xxx
PUSHER_SECRET=xxx
PUSHER_CLUSTER=us3

# Sports Data API (for ML result resolution)
SPORTS_DATA_API_KEY=xxx
SPORTS_DATA_BASE_URL=https://api.sportsdata.io/v3

# Notifications
FCM_SERVER_KEY=xxx
SENDGRID_API_KEY=xxx

# Security
JWT_SECRET=xxx
COUPON_SIGNING_SECRET=xxx
WEBHOOK_SIGNING_SECRET=xxx

# Feature Flags
ENABLE_AUTO_BINGO_MARK=true
ENABLE_ML_MULTIPLIER=true
ML_MAX_PICKS=6
SCRATCH_CARDS_PER_HALFTIME=3
```

---

## 13. Testing Strategy

### Unit Tests
- Points ledger: award, spend, balance trigger, idempotency
- Bingo win detection: all 12 line configurations
- Coupon expiry: status transitions
- ML multiplier calculation table

### Integration Tests
- Full prediction flow: question open → fan selects → locks → result resolves → points awarded
- Bingo auto-mark: admin fires event → WebSocket delivers → cell marked → win detected
- Scratch card: card earned → BullMQ job → code generated → wallet updated

### E2E Tests (Playwright)
- Fan joins game, makes prediction, sees result, checks points balance
- Fan gets bingo on simulated plays
- Fan scratches card, copies coupon code
- Fan makes ML entry, submits, wins

### Load Tests (k6)
- 100K concurrent WebSocket connections to game channel
- 10K simultaneous prediction lock submissions
- Bingo fan-out: 1 event → 50K client updates in <500ms

---

*Document prepared for Antigravity. Reference HTML demo: `arenza-interactive-ads.html`. All components in the demo are directly portable to the production React component library.*
