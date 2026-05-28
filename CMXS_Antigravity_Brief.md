# CMXS ICO Website — Comprehensive Developer Brief for Antigravity
## Version 1.0 | May 2026 | Prepared by CMXS Foundation

---

> **HOW TO USE THIS DOCUMENT**
> This brief is the single source of truth for building the CMXS ICO website at `echoads.tv/demo/ico` and its permanent home at `cmxs.network/ico`. Every section contains exact wording, data, and UX specifications. Do not paraphrase token economics or legal notices — use the text as written.

---

## PART A — VERIFICATION: FOUR-STAGE RAISE CONFIRMATION

**CONFIRMED:** The ICO target of **USD 18M–33M** across four stages is correct and consistent across all source documents (V4 White Paper Section 14.3, Chinese-language coin issuance plan).

| Stage | Round Name | Target Raise | Token Price | Implied FDV | Vesting |
|-------|-----------|-------------|------------|------------|---------|
| 0 | Angel / SAFE | USD 1M–2M | N/A (converts at Seed) | N/A | 20% discount to Seed price |
| 1 | Seed Reg D 506(c) | USD 3M–5M | USD 0.02 / CMXS | USD 20M | 12-month cliff + 36-month linear |
| 2 | Strategic / IEO | USD 8M–15M | USD 0.05–0.08 / CMXS | USD 50M–80M | 20% at TGE + 12-month linear |
| 3 | Public IDO (LBP) | USD 6M–11M | USD 0.10 / CMXS | USD 100M | 20% at TGE + 12-month linear |
| **TOTAL** | | **USD 18M–33M** | | **USD 100M FDV at TGE** | |

---

## PART B — CONTENT AUDIT: MISSING SECTIONS

The current `echoads.tv/demo/ico` page is missing the following critical sections:

| Missing Section | Severity | Impact |
|----------------|---------|--------|
| "How the Blockchain Works" plain-language explainer | CRITICAL | Non-crypto investors (streaming executives, family offices) cannot evaluate without this |
| Proof-of-Delivery (PoD) explanation | CRITICAL | PoD is the core differentiator vs. Helium, Render, Livepeer — without it, no narrative anchor |
| Token allocation donut chart | HIGH | Investors need visual distribution to assess dump risk; table alone insufficient |
| Staking mechanics with APY context | HIGH | Institutional DePIN investors require staking mechanics + lock terms |
| 48-month vesting timeline visual | HIGH | Without this, sophisticated investors flag project as non-transparent |
| Regulatory compliance summary | MEDIUM | US institutional investors will not participate without clear legal basis statement |
| Four-stage raise funnel (visual) | MEDIUM | Current table needs visual progress bar showing "I am here" on the raise |

---

## PART C — FOUR-STAGE RAISE: COMPONENT SPECS

### Component: `<RaiseFunnel />`
Layout: Horizontal stepper on desktop, vertical accordion on mobile.

**Stage 0 — Angel / SAFE (STATUS: ACTIVE)**
```
Badge: "OPEN NOW" (amber)
Heading: Angel Round / Strategic Partners Only
Amount: USD 1M – 2M
Instrument: SAFE (Simple Agreement for Future Tokens)
Discount: 20% discount to Seed price
Who: 5–10 broadcast + DePIN strategic investors
KYC: Full KYC · Jumio · Accredited investors only
CTA: "Apply to Participate →" → mailto:angel@cmxs.network
```

**Stage 1 — Seed Round (STATUS: UPCOMING)**
```
Badge: "OPENS MONTH 3" (blue)
Heading: Seed Round / Reg D 506(c) · Accredited Investors
Amount: USD 3M – 5M
Token Price: USD 0.02 / CMXS · Implied FDV: USD 20M
Vesting: 12-month cliff, then 36 months linear
Minimum ticket: USD 250,000
KYC: Via CoinList
CTA: "Join Waitlist →" → /whitelist
```

**Stage 2 — IEO (STATUS: UPCOMING)**
```
Badge: "OPENS MONTH 5" (purple)
Heading: Strategic / IEO Round / Exchange-Hosted
Amount: USD 8M – 15M
Token Price: USD 0.05–0.08 / CMXS · FDV: USD 50M–80M
Vesting: 20% at TGE, 12 months linear
Exchange: Binance Launchpad / Coinbase Ventures / Kraken Ventures
CTA: "Notify Me →" → /notify
```

**Stage 3 — Public IDO / TGE (STATUS: UPCOMING)**
```
Badge: "OPENS MONTH 7 · TGE" (green)
Heading: Public IDO — Token Generation Event
Amount: USD 6M – 11M
Token Price: USD 0.10 (LBP start USD 0.15, 72-hr price discovery)
FDV: USD 100M
Venue: Fjord Foundry LBP + Uniswap v4 + 1–2 CEX listings
Vesting: 20% immediate · 80% over 12 months
CTA: "Register Interest →" → /ido-register
```

**Banner below all cards:**
```
Total Target Raise: USD 18M – 33M
Initial FDV at TGE: USD 100M
Token Supply: 1,000,000,000 CMXS (fixed, no additional minting)
```

---

## PART D — EXACT COPY: "HOW THE BLOCKCHAIN WORKS"

Section heading: **How the Blockchain Makes Delivery Trustless**
Subheading: *You don't need to understand crypto to understand why this matters. Here's what the CMXS blockchain actually does — in plain language.*

### Card 1: The Problem with Trusting the Platform
When you buy digital advertising — or any time-critical delivery service — today, you pay the platform, and the platform tells you it worked. There is no independent proof. The platform's own software reports whether your content was delivered. Industry figures: USD 84 billion in ad fraud annually. 30% more inventory sold than actually delivered. The IAB calls this "an honour system."

### Card 2: What a Blockchain Actually Does
A blockchain is a digital ledger that nobody controls. Think of it as a public noticeboard: once something is written on it, it can never be erased, altered, or disputed — not by us, not by the buyer, not by anyone. Every time a CMXS network node delivers content, a cryptographic receipt is written to the Base blockchain — permanently. The receipt includes: exactly what was delivered, to which device, at what time, and how fast. This isn't a report from the platform. It's an immutable mathematical proof, created automatically, that anyone can verify on Basescan.etherscan.io.

### Card 3: Why We Use the Base Blockchain
We chose Base (built by Coinbase) because it: (1) Costs USD 0.0001 per transaction — cheap enough to record every single delivery event. (2) Settles in 2 seconds — fast enough for real-time verification. (3) Supports "x402" payments — the new Coinbase standard for machine-to-machine micropayments. (4) Is backed by Coinbase — the largest US regulated crypto exchange.

### "Five Things the Blockchain Guarantees" (numbered list, animated checkmarks)
```
1. Every delivery is recorded — a proof is written on-chain the moment content reaches a device.
2. Every payment is on-chain — linked to the delivery proof. You can't have a reward without a real payment.
3. Node rewards are automatic — smart contracts pay node operators automatically when delivery is verified.
4. Token supply is controlled by code — no CMXS team member can create new tokens.
5. Everything is auditable — every transaction is publicly visible on Basescan.
```

### FAQ Accordion
```
Q: Do I need to understand crypto to use CMXS or invest?
A: No. Service buyers pay in USDC (a USD-pegged stablecoin). Node operators receive CMXS automatically. The blockchain is infrastructure — like the internet protocol behind a website.

Q: What is a "smart contract"?
A: Software code that runs on the blockchain and executes automatically when conditions are met — like a vending machine. Our contracts are open-source, publicly auditable, and cannot be modified by the CMXS team after deployment.

Q: Can the CMXS team change the token supply or rules?
A: No. Post-TGE, the CMXS token contract's mint authority belongs exclusively to the DeliveryOracle.sol smart contract. No team wallet, no admin key can trigger a direct mint. Protocol changes require a veCMXS governance vote with a 66% supermajority.
```

---

## PART E — EXACT COPY: "PROOF-OF-DELIVERY" EXPLAINER

Section heading: **Proof-of-Delivery (PoD) — The Consensus Mechanism That Powers CMXS**

### Introduction
Every blockchain needs a way to decide: "Did real work happen? Does the network deserve to be paid?" Bitcoin uses Proof-of-Work: computers compete to solve pointless mathematical puzzles. Ethereum uses Proof-of-Stake: the richest token holders get to validate transactions. **CMXS uses Proof-of-Delivery: nodes get paid for doing exactly what the network needs — delivering verified content to real devices, on time, fast.**

### Visual Flow: "One PoD Event — What Happens in Under 2 Seconds"
```
STEP 1 — REQUEST (0ms)
A viewer's device requests content via the CMXS network.

STEP 2 — DELIVERY (~287ms measured average)
The nearest CMXS node delivers the content over QUIC — a next-generation
internet protocol that eliminates buffering delays. Content arrives in under 500ms.

STEP 3 — RECEIPT (~50ms to generate)
The viewer's device automatically signs a cryptographic "delivery receipt" —
a mathematical fingerprint proving: this exact content, to this device,
at this time, at this speed. This receipt cannot be forged.

STEP 4 — PAYMENT (~2 seconds to settle)
The service buyer's wallet automatically sends a micro-payment (fractions
of a cent in USDC) via the x402 protocol, recorded on the Base blockchain.

STEP 5 — VERIFICATION (~100ms)
The Delivery Oracle smart contract checks: Was the receipt valid?
Was the payment confirmed? Was the speed under 500ms?

STEP 6 — REWARD (automatic, immediate)
The DeliveryOracle.sol smart contract automatically mints 0.001 CMXS
to the node operator's wallet. No invoice. No approval. No delay.

STEP 7 — PERMANENT PROOF
An immutable SLA proof record is written to Base. The service buyer
receives a transaction hash — a permanent, publicly verifiable link
proving delivery occurred. Auditable forever.
```

### PoW vs PoS vs PoD Comparison Table
```
Proof-of-Work (Bitcoin)
What gets rewarded: Computer power solving puzzles
Energy use: Enormous (~700kWh per Bitcoin transaction)
Useful for CMXS?: ❌ The puzzle has nothing to do with content delivery

Proof-of-Stake (Ethereum)
What gets rewarded: Token holdings
Energy use: Low
Useful for CMXS?: ❌ Rich validators earn more; infrastructure quality irrelevant

Proof-of-Delivery (CMXS) ✓
What gets rewarded: Delivering verified content under 500ms
Energy use: Minimal (no computational waste)
Useful for CMXS?: ✅ Every reward = proven delivery. No delivery = no reward.
```

### "How Does PoD Prevent Cheating?" Cards
```
Can a node fake a delivery?
No. The delivery receipt must be signed by the VIEWER'S wallet. A node cannot forge
the viewer's signature. The x402 payment provides an independent second confirmation
on a completely separate cryptographic path.

Can a node claim the same reward twice?
No. Every delivery receipt has a unique ID. The smart contract stores every ID it has
seen. A second submission is rejected with "Proof already used."

What if someone hacks the oracle?
The daily mint cap is hardcoded at 2,880,000 CMXS/day. Even a complete oracle
compromise cannot produce more than 0.288% of total supply in 24 hours. In Phase 1,
the oracle migrates to Chainlink (decentralised), eliminating this risk.
```

---

## PART F — TOKEN ALLOCATION CHART DATA

```javascript
const tokenAllocation = [
  { label: "Node Rewards (PoD)", percentage: 35, color: "#3B82F6",
    tokens: "350,000,000", tgeUnlock: "0%",
    vesting: "Minted on-demand only when delivery verified. Daily cap: 2,880,000 CMXS" },
  { label: "Foundation Treasury", percentage: 20, color: "#8B5CF6",
    tokens: "200,000,000", tgeUnlock: "0%",
    vesting: "6-month cliff, 24-month linear" },
  { label: "Ecosystem Grants", percentage: 15, color: "#10B981",
    tokens: "150,000,000", tgeUnlock: "0%",
    vesting: "12-month cliff, 36-month linear (milestone-based for JV partners)" },
  { label: "Seed / Strategic Round", percentage: 10, color: "#F59E0B",
    tokens: "100,000,000", tgeUnlock: "0%",
    vesting: "12-month cliff, 36-month linear" },
  { label: "Public ICO", percentage: 10, color: "#EF4444",
    tokens: "100,000,000", tgeUnlock: "20%",
    vesting: "20% at TGE, 80% over 12 months linear" },
  { label: "Team & Advisors", percentage: 8, color: "#6B7280",
    tokens: "80,000,000", tgeUnlock: "0%",
    vesting: "12-month cliff, 48-month linear" },
  { label: "Liquidity Provision", percentage: 2, color: "#14B8A6",
    tokens: "20,000,000", tgeUnlock: "100%",
    vesting: "Unlocked at TGE for DEX/CEX initial liquidity seeding only" },
];
// TOTAL: 1,000,000,000 CMXS
```

### Stat boxes below chart (3 per row):
```
Total Supply: 1,000,000,000 CMXS — Fixed cap. No additional minting.
TGE Circulating: 150,000,000 CMXS (15%) — Prevents price manipulation at launch
Team Lock-up: 12-month cliff — 48-month vest (longest in DePIN industry)
Node Rewards: 35% of supply — Only minted when verified delivery happens
Daily Mint Cap: 2,880,000 CMXS — Hardcoded safety limit
Initial FDV: USD 100,000,000 — At USD 0.10 IDO price
```

---

## PART G — STAKING COPY

### Card 1 — Node Operators (Blue #3B82F6)
**Badge:** INFRASTRUCTURE LAYER | **Heading:** Run a Node

*Stake CMXS to operate a delivery node*

Stake a minimum of 1,000 CMXS (~USD 100 at initial FDV) to activate your node's Proof-of-Delivery eligibility. Your node delivers content via the QUIC/MoQ protocol to end devices in your coverage area. For every verified delivery under 500ms, you automatically receive 0.001 CMXS — directly to your wallet.

**Earnings at USD 100 CMXS price:**
→ USD 1.44/node/day (1,440 deliveries × USD 0.001 × 100)
→ USD 43.20/node/month
→ Hardware payback: ~230 days (USD 329 Raspberry Pi 5)

**Slash protection:** 3 failed deliveries in 24 hours triggers 10% stake slash. 7-day unstake delay prevents gaming.

**Who is this for?** Tower operators · Broadcast infrastructure owners · Data centre operators · Home lab operators

### Card 2 — Service Buyers (Purple #8B5CF6)
**Badge:** DEMAND LAYER | **Heading:** Buy Verified Delivery

*Pre-commit USDC for discounted burns and priority routing*

Standard (USD 0–9,999): Best effort routing — 0% burn discount
Tier 1 (USD 10,000): Standard priority routing — 5% CMXS burn discount
Tier 2 (USD 50,000): High priority routing — 12% CMXS burn discount
Tier 3 (USD 250,000): Guaranteed premium slots — 20% CMXS burn discount

**Your benefit:** Verified delivery at 2× market CPM (USD 45–65 vs. USD 18–30 unverified). On-chain proof of every delivery — audit-ready, fraud-proof.

**Who is this for?** Streaming platforms · Ad networks · Live sports operators · Pay-per-view platforms

### Card 3 — Token Holders (Green #10B981)
**Badge:** GOVERNANCE LAYER | **Heading:** Govern the Protocol

*Lock CMXS for veCMXS governance rights and protocol fee income*

Lock 1 year → 0.25 veCMXS per CMXS (25% voting weight)
Lock 2 years → 0.50 veCMXS per CMXS (50% voting weight)
Lock 4 years → 1.00 veCMXS per CMXS (Full voting weight + full fee share)

**Your rights:** Vote on all network parameters. Receive 50% of protocol fee income (paid in USDC). Priority access to new node geography allocations. Propose Ecosystem Grant distributions.

**Who is this for?** Long-term token holders · Crypto funds · DePIN investors · Strategic partners

---

## PART H — VESTING TIMELINE DATA

```javascript
const vestingData = [
  { label: "Liquidity Provision", pct: 2, color: "#14B8A6",
    cliffMonths: 0, startMonth: 0, endMonth: 0, tgeUnlock: 100 },
  { label: "Public ICO", pct: 10, color: "#EF4444",
    cliffMonths: 0, startMonth: 0, endMonth: 12, tgeUnlock: 20 },
  { label: "Foundation Treasury", pct: 20, color: "#8B5CF6",
    cliffMonths: 6, startMonth: 6, endMonth: 30, tgeUnlock: 0 },
  { label: "Seed / Strategic Round", pct: 10, color: "#F59E0B",
    cliffMonths: 12, startMonth: 12, endMonth: 48, tgeUnlock: 0 },
  { label: "Ecosystem Grants", pct: 15, color: "#10B981",
    cliffMonths: 12, startMonth: 12, endMonth: 48, tgeUnlock: 0 },
  { label: "Team & Advisors", pct: 8, color: "#6B7280",
    cliffMonths: 12, startMonth: 12, endMonth: 60, tgeUnlock: 0 },
  { label: "Node Rewards (PoD)", pct: 35, color: "#3B82F6",
    note: "On-demand mint only. No vesting schedule. Daily cap enforced." }
];
```

**Key timeline milestones:**
- Month 0: TGE — 15% circulating supply unlocked
- Month 6: Foundation Treasury begins vesting
- Month 12: Team cliff ends — first team tokens vest
- Month 36: Seed/Strategic fully vested
- Month 48: Foundation Treasury fully vested
- Month 60: Team & Advisors fully vested

---

## PART I — REGULATORY COMPLIANCE BADGES

**Heading:** Built to Regulatory Standards
**Subheading:** CMXS is designed to comply with 2026 US, EU, and international token offering frameworks from day one.

```
Badge 1: SEC Safe Harbor 2.0
Filed under the SEC's March 2026 Safe Harbor 2.0 framework. Utility token
classification. 3-year non-registration window.

Badge 2: Regulation D 506(c)
US Angel and Seed rounds under Reg D 506(c). Verified accredited investors only.

Badge 3: MiCA Utility Token
EU MiCA Article 4 utility token classification. White Paper filed with NCA before offering.

Badge 4: Trail of Bits Audit
Smart contract audit by Trail of Bits — same firm that audited Ethereum 2.0.
Full report published before TGE.

Badge 5: KYC/AML — Jumio + Chainalysis
Full KYC via Jumio on all Angel/Seed participants. OFAC wallet screening by Chainalysis.

Badge 6: Cayman Foundation Structure
CMXS Foundation Ltd. (Cayman Islands) — same dual-entity model as Helium, Filecoin, Render.
```

---

## PART J — LEGAL DISCLAIMER (DO NOT MODIFY)

```
IMPORTANT LEGAL NOTICE

This website is published by CMXS Foundation Ltd. (Cayman Islands Exempted Company)
for informational purposes only.

CMXS tokens are utility tokens designed for functional use within the CMXS
Decentralised Physical Infrastructure Network (DePIN). They are not designed
or intended to constitute a security, commodity, or regulated investment product
in any jurisdiction.

UNITED STATES: CMXS tokens are offered only to verified accredited investors
during Angel and Seed rounds under SEC Regulation D Rule 506(c). Public IDO
participation is not available to US retail investors.

EUROPEAN UNION: This token offering will be filed with the relevant National
Competent Authority under MiCA before any public offering to EU residents.

OFAC COMPLIANCE: CMXS Foundation will not sell tokens to individuals, entities,
or wallets associated with OFAC-sanctioned jurisdictions.

NO GUARANTEE OF VALUE: Token purchasers may lose their entire investment.
Cryptocurrency markets are highly volatile. Past performance is not indicative
of future results.

© 2026 CMXS Foundation Ltd. All rights reserved.
```

---

## PART K — TECH STACK RECOMMENDATION

```
Framework: Next.js 15 (App Router)
Styling: Tailwind CSS v4
Charts: Recharts (React-compatible, tree-shakeable)
Animations: CSS custom properties + IntersectionObserver (no Framer Motion)
Wallet Connect: wagmi v2 + ConnectKit
Deployment: Vercel (auto-deploy from GitHub)
Domain: cmxs.network (prod) / echoads.tv/demo/ico (staging)
```

**Lighthouse Score Targets:**
- Performance: ≥90 | Accessibility: ≥95 | Best Practices: ≥90 | SEO: ≥95
- FCP: <1.5s | LCP: <2.5s | TBT: <200ms | CLS: <0.1

---

## PART L — ANTIGRAVITY ONE-SHOT PROMPT

```
Build a complete ICO landing page for the CMXS DePIN token using Next.js 15 + Tailwind CSS.
Follow the exact content, copy, and component specifications in the attached developer brief.

Page URL: /ico
Theme: Dark (#0F172A background, white text, blue/purple accent gradient)
Primary font: Inter (via next/font)
Hero CTA: "Join the Waitlist" → /whitelist

Required sections (in order):
1. Hero — token ticker, tagline, total raise USD 18M–33M, four-stage progress bar
2. "How the Blockchain Works" — three-card explainer (Part D)
3. "Proof-of-Delivery" — step flow + PoW/PoS/PoD comparison (Part E)
4. Four-Stage Raise Funnel — four stage cards with status (Part C)
5. Token Allocation — donut chart + vesting details (Part F)
6. Staking Architecture — three-tier staking cards (Part G)
7. Vesting Timeline — 48-month Gantt-style chart (Part H)
8. Regulatory Compliance Badges — six badge cards (Part I)
9. Legal Disclaimer — collapsible footer (Part J)

Nav: Logo (CMXS) | White Paper | Technology | Token | ICO | [Connect Wallet]

Use exact copy from brief. Do not paraphrase legal notices.
All token figures must match exactly:
- 1,000,000,000 total supply
- USD 0.10 IDO price
- USD 100M FDV at TGE
- USD 18M–33M total raise across four stages
```

---
*CMXS Foundation Ltd. | Grand Cayman, Cayman Islands*
*CMXS Labs Inc. | Delaware, USA*
*Developer Brief v1.0 | May 2026 | Prepared for Antigravity*
