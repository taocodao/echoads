# CMXS Token White Paper
## CatonMX Settlement Token — Decentralised Physical Infrastructure Network

**Version 3.0 | May 2026**
**Classification: Public — For ICO Distribution**

*Issued by: CMXS Foundation Ltd. (Cayman Islands Exempted Company)*
*Protocol Developer: CMXS Labs Inc. (Delaware, USA)*
*Smart Contracts: Base L2 (Coinbase / OP Stack)*

---

> **IMPORTANT NOTICE**
>
> This White Paper is an informational document describing the CMXS decentralised protocol and associated token sale. It does not constitute an offer of securities, investment advice, or a solicitation to purchase any regulated financial instrument. CMXS is a utility token designed exclusively for use within the CMXS DePIN network. Potential participants must consult independent legal, financial, and tax counsel. United States participants must qualify as accredited investors under SEC Regulation D 506(c). This document is filed in support of the CMXS Foundation's Token Disclosure Document under the SEC Safe Harbor 2.0 framework (March 2026).

---

## Table of Contents

1. Executive Summary
2. What Is a Blockchain? A Plain-Language Primer
3. What Is DePIN? The New Infrastructure Paradigm
4. The Problem: Unverified, Centralised Delivery Infrastructure
5. The CMXS Network Architecture
6. Transport Layer: QUIC / MoQ Protocol
7. Payment Layer: x402 Per-Delivery Micropayment Protocol
8. Proof-of-Delivery (PoD) — The Core Consensus Mechanism
9. CMXS Token Design and Optimised Structure
10. Burn-and-Mint Equilibrium (BME) — The Economic Engine
11. Token Allocation and Vesting Schedule
12. Staking Architecture
13. Smart Contract Reference Implementation
14. Governance: veToken Model
15. ICO Framework and Four-Stage Capital Raise
16. Use of Proceeds
17. Network Expansion and Use Case Roadmap
18. Competitive Benchmarking
19. Financial Projections
20. Regulatory Compliance Framework
21. Corporate Structure
22. Development Roadmap
23. Risk Factors
24. Legal Disclaimer

---

## 1. Executive Summary

CMXS is a Decentralised Physical Infrastructure Network (DePIN) token that coordinates a global network of edge nodes delivering time-critical digital content. The CMXS token (ticker: **CMXS**) is the settlement and incentive layer of this network: node operators earn CMXS for verified delivery; service buyers burn CMXS to access premium, cryptographically auditable delivery capacity; and token holders govern network parameters through a vote-escrowed (veToken) model.

The network launches with a decisive structural advantage over every prior DePIN project: **pre-existing physical infrastructure at scale**. The initial node layer is anchored by a joint venture converting a portion of **5,800 existing EchoStar broadcast towers** into CMXS-earning edge nodes — eliminating the "cold start" infrastructure problem that forced Helium to bootstrap supply from zero over four years.

The initial commercial deployment targets **verified digital content delivery** — a market with USD 84 billion in annual fraud losses and zero existing cryptographic proof-of-delivery infrastructure. This is one of multiple planned applications; the same protocol stack applies to live sports betting, pay-per-view content, AI agent data feeds, IoT telemetry, and live commerce without any protocol modification.

### Key Parameters at a Glance

| Parameter | Value |
|-----------|-------|
| Token Name | CatonMX Settlement Token |
| Ticker | CMXS |
| Standard | ERC-20 on Base L2 |
| Total Supply | 1,000,000,000 (fixed) |
| Consensus Mechanism | Proof-of-Delivery (PoD) |
| ICO Target | USD 18M–33M |
| Initial FDV at TGE | USD 100M |
| ICO Structure | 4 stages: Angel → Seed → IEO → Public IDO |
| Blockchain | Base L2 (Coinbase / OP Stack) |
| Audit | Trail of Bits or CertiK (pre-TGE mandatory) |

---

## 2. What Is a Blockchain? A Plain-Language Primer

*This section is written for investors and participants who are not crypto-native. Technical readers may proceed to Section 3.*

### 2.1 The Core Idea

A blockchain is a **shared digital record book that nobody controls and nobody can alter**. 

Imagine a public noticeboard in a town square. Anyone can read it. Thousands of copies exist simultaneously across thousands of computers worldwide. Once something is written on it, it is mathematically impossible to erase or change without everyone in the network immediately detecting the fraud.

That is what a blockchain does — it makes facts permanent and publicly verifiable without requiring any central authority to maintain them.

### 2.2 How a Block Is Added

Every transaction on a blockchain — every delivery proof, every token reward, every payment — is bundled into a "block." Before the block is added to the chain:

1. The block's contents are converted into a unique mathematical fingerprint (a "hash")
2. Thousands of computers across the network independently verify the block is legitimate
3. The block is linked to the previous block using its fingerprint — creating a "chain"
4. Any attempt to alter a past block would change its fingerprint, breaking every subsequent link, and would be instantly detected by every computer in the network

This means: **if it is on the blockchain, it happened. If it is not on the blockchain, it cannot be claimed to have happened.**

### 2.3 What the CMXS Blockchain Does Specifically

CMXS uses the **Base L2 blockchain** (built by Coinbase, operating on Ethereum's security layer). For the CMXS protocol, the blockchain performs five functions:

| Function | What It Means in Practice |
|----------|--------------------------|
| Delivery proof storage | Every verified delivery is recorded permanently — tamper-proof, publicly auditable |
| Automatic token rewards | Smart contracts pay node operators automatically — no invoices, no delays |
| Burn ledger | Every CMXS token burned by service buyers is permanently recorded and publicly verifiable |
| Governance voting | Token holders vote on protocol changes using on-chain weighted votes |
| Vesting enforcement | Team and investor token locks are enforced by smart contract code — not by trust |

### 2.4 What Is a Smart Contract?

A smart contract is **software code that runs on the blockchain and executes automatically when conditions are met** — like a vending machine: insert payment, receive product, no human intervention required.

CMXS uses seven smart contracts. None of them require trust in any human. The code is open-source, publicly auditable before TGE, and cannot be modified after deployment except through a governance vote:

- **CMXS.sol** — the token itself: mint, burn, and daily cap logic
- **DeliveryOracle.sol** — verifies delivery proofs and triggers rewards
- **NodeRegistry.sol** — manages node registration, staking, and slashing
- **ServiceBuyerEscrow.sol** — holds service buyer USDC and manages burn discounts
- **GovernanceStaking.sol** — manages veCMXS lock-up and voting weight
- **Treasury.sol** — Foundation treasury and ecosystem grant distribution
- **VestingVault.sol** — enforces cliff and linear vesting for all allocations

### 2.5 Why Base L2 (Not Bitcoin, Not Ethereum Mainnet)

Base L2 is not a choice made for marketing reasons. It is determined by the x402 payment protocol dependency (Section 7). The critical advantages:

- **USD 0.0001 per transaction** — cheap enough to record every single delivery event on-chain. On Ethereum mainnet (USD 3–50 per transaction), this is economically impossible.
- **2-second settlement** — fast enough for real-time delivery verification and reward distribution
- **Native x402 support** — the micropayment protocol powering CMXS is Coinbase-native and Base-native
- **Coinbase institutional relationships** — Base L2 positions CMXS for Coinbase exchange listing and Coinbase Ventures partnership

---

## 3. What Is DePIN? The New Infrastructure Paradigm

### 3.1 Definition

**DePIN (Decentralised Physical Infrastructure Network)** is a category of blockchain protocol that uses token incentives to coordinate the deployment and operation of real, physical hardware — replacing centralised corporations with a distributed network of independently operated nodes.

The critical distinction from pure software tokens: **DePIN tokens are backed by real-world physical work.** A CMXS token is earned by a tower or server that delivers verified content to a real device at sub-500ms speed. It cannot be earned by guessing numbers (Proof-of-Work) or by holding existing tokens (Proof-of-Stake).

This alignment of token rewards with physical, measurable work is the reason DePIN has become the most institutionally credible category of crypto infrastructure in 2025–2026.

### 3.2 The DePIN Flywheel

Every DePIN network runs the same self-reinforcing economic cycle:

```
Physical infrastructure deployed
         ↓
Verified contribution proven on-chain
         ↓
Token rewards distributed to operators
         ↓
Higher rewards attract more operators
         ↓
More operators → better service coverage
         ↓
Better coverage attracts more service buyers
         ↓
More service buyers → more token demand (burns)
         ↓
More demand → higher token value
         ↓
Higher value → more operators → [cycle repeats]
```

CMXS is designed to enter this flywheel at a significantly more advanced position than any prior DePIN project, because the initial infrastructure (5,800 EchoStar broadcast towers) and initial demand (existing streaming platform relationships) are pre-existing.

### 3.3 DePIN Market Scale

| Metric | Value | Source |
|--------|-------|--------|
| Global DePIN market size (2026) | USD 3.5B | Intel Market Research |
| Global DePIN market projection (2033) | USD 145.9B | Intel Market Research |
| DePIN total market cap (May 2026) | USD 9–10B | CoinMarketCap / CoinGecko |
| DePIN ICO fundraising (Q1 2025 alone) | USD 4.8B | Industry data |
| Average DePIN ICO raise | USD 14.7M | CoinLaw / MEXC 2026 |
| DePIN ICOs outperform general ICO average | 3× per-project | Blockchain App Factory 2026 |

DePIN is raising 3× more per project than the overall ICO average because institutional investors have learned from Helium, Render, and Hivemapper that physical infrastructure provides a **valuation floor** that pure-software tokens lack: if the token price drops below the economic value of the work the network performs, rational operators exit and the network self-corrects.

---

## 4. The Problem: Unverified, Centralised Delivery Infrastructure

The digital delivery infrastructure underpinning streaming, advertising, live events, and real-time data services has three compounding structural failures. CMXS is designed to resolve all three simultaneously.

### 4.1 The Latency Problem

Legacy content delivery relies on HLS (HTTP Live Streaming) over TCP (Transmission Control Protocol). HLS delivers content in segments of 2–10 seconds each. Every delivery decision requiring a mid-stream switch — inserting an ad, changing a content source, handling a pay-per-view gate — requires the TCP connection to tear down, reconnect, and buffer a new segment. This creates mandatory delays of **1.5–10 seconds that are not software bugs but structural limitations** of the TCP/HLS protocol combination.

The consequence extends beyond viewer experience: any application requiring sub-500ms synchronisation — live sports betting, real-time financial data feeds, AI agent decision-making — is **structurally excluded** from HLS-based platforms.

### 4.2 The Proof Problem

No current CDN or content delivery infrastructure provides cryptographic proof that specific content was delivered to a specific device at a specific time. Buyers of digital advertising, pay-per-view access, or data delivery pay based on **platform-reported metrics — fundamentally an honour system.**

This creates:
- USD 84 billion annual global ad fraud (Business of Apps, 2026)
- 140% surge in connected TV ad fraud (DoubleVerify Global Insights Report, 2025)
- 30% more digital ad inventory sold than actually delivered (Morgan Stanley)
- Zero ability to command the 2× CPM premium that cryptographically verified delivery commands (USD 45–65 CPM verified vs. USD 18–30 CPM unverified — PubMatic / Magnite CTV Marketplace Reports, 2025)

The IAB Tech Lab's CTV Signal Integrity Framework (October 2025) explicitly calls for **cryptographic delivery receipts** as the long-term industry solution. CMXS is the first DePIN protocol to provide them.

### 4.3 The Revenue Distribution Problem

In today's centralised CDN model, operators of physical infrastructure — tower owners, co-location facilities, fibre network providers — receive flat lease income regardless of how much revenue flows through their hardware. The economic value created by their infrastructure accrues entirely to the platform layer.

This creates two problems:
1. Infrastructure operators have no incentive to upgrade beyond the minimum contractual requirement
2. Physical asset owners have zero participation in the digital economy their hardware enables

CMXS resolves this by making every delivery event a direct economic transfer from service buyer to node operator — without any intermediary.

---

## 5. The CMXS Network Architecture

The CMXS network operates as a three-layer stack. Each layer is defined by open standards with no proprietary lock-in except the Caton C3 transport enhancement:

```
╔══════════════════════════════════════════════════════════════════╗
║  LAYER 3 — APPLICATION / CLIENT SURFACE                         ║
║  Any QUIC-capable consumer device                                ║
║  Chrome / Edge / Firefox / Safari (WebTransport, Baseline 2026) ║
║  Smart TV · Mobile App · Set-Top Box · AI Agent                 ║
║  Player SDK: MoQ WebTransport client (moq-js / moq-rs)          ║
║  Payment client: x402fetch + Coinbase Smart Wallet (EIP-4337)   ║
╠══════════════════════════════════════════════════════════════════╣
║  LAYER 2 — CMXS PROTOCOL MIDDLEWARE                             ║
║  Caton Enhanced MoQ (CE-MoQ) Relay                              ║
║  Per-delivery Auction Engine (sub-100ms decisioning)            ║
║  x402 Payment Gateway (Coinbase x402 v1.0)                      ║
║  NetScope Telemetry + SLA Oracle                                 ║
║  CMXS Smart Contracts on Base L2                                 ║
║  Chainlink CRE oracle (Phase 1+)                                 ║
╠══════════════════════════════════════════════════════════════════╣
║  LAYER 1 — PHYSICAL NODE LAYER                                   ║
║  5,800 EchoStar broadcast towers (JV — initial anchor)           ║
║  + Independent TowerCo partners (Phase 1+)                       ║
║  + Cloud VM nodes (Phase 0 / developer nodes)                    ║
║  Each node runs:                                                  ║
║   — CE-MoQ Relay daemon                                          ║
║   — x402 Facilitator                                             ║
║   — CMXS NodeRegistry staking contract interaction               ║
╚══════════════════════════════════════════════════════════════════╝
```

### 5.1 End-to-End Delivery Flow (One Verified Event)

The following is the complete data flow for a single verified delivery event — the atomic unit from which all CMXS network economics derive:

```
Step 1:  Client device subscribes to content Track via MoQ SUBSCRIBE message
Step 2:  Layer 2 relay receives delivery request — auction engine runs (≤80ms)
Step 3:  Content object delivered as MoQ Objects over QUIC (no HLS buffer wait)
Step 4:  Client stitches at frame boundary — zero latency gap
Step 5:  HTTP 402 fires — x402 micropayment (USDC) sent per delivery event
Step 6:  x402 Facilitator (Coinbase) confirms payment on Base L2 (~2 seconds)
Step 7:  NetScope telemetry records delivery timestamp + latency measurement
Step 8:  SLA Oracle checks: was latency <500ms? Was delivery cryptographically verified?
Step 9:  If SLA met → DeliveryOracle.sol emits DeliveryProofAccepted event on Base L2
Step 10: CMXS.rewardNode() mints 0.001 CMXS to the node operator's wallet
Step 11: SLA proof written on-chain (ERC-8004 derivative) — permanently auditable
Step 12: Service buyer's dashboard reflects new verified delivery + txHash
```

**Total time from content request to on-chain reward: under 5 seconds.**
**Delivery latency benchmark (Q2 2026 Phase 0): P50: 287ms · P95: 312ms**

---

## 6. Transport Layer: QUIC / MoQ Protocol

### 6.1 Why QUIC Replaces TCP

QUIC (RFC 9000, standardised 2021) is a multiplexed transport protocol over UDP rather than TCP. The difference that matters for delivery infrastructure:

| Property | TCP (Legacy) | QUIC |
|----------|-------------|------|
| Connection setup | 1–3 RTT handshake | 0–1 RTT (0-RTT resumption) |
| Stream isolation | Head-of-line blocking | Independent streams, no blocking |
| Delivery switching | Requires connection teardown | New stream, same connection |
| Encryption | Optional (TLS overlay) | Mandatory (TLS 1.3 integrated) |
| Black screen on switch | 1.5–10 seconds | 0ms (same-connection stream switch) |
| Sports betting sync | 5–30s behind live | Sub-500ms — clears regulatory threshold |

The QUIC advantage for CMXS: a delivery switch is a new SUBSCRIBE message on the **same open QUIC connection** — not a TCP teardown. This eliminates the structural source of delivery gaps at the protocol level, not as a software patch.

### 6.2 MoQ (Media over QUIC)

MoQ (IETF draft-ietf-moq-transport, currently draft-08) defines an object-based publish/subscribe delivery model over QUIC, replacing segment-based HLS:

| MoQ Concept | Definition | Significance for CMXS |
|------------|-----------|----------------------|
| **Track** | One logical stream (e.g., `cmxs/live/content`) | Delivery switching = new Track subscription |
| **Group** | One GOP (Group of Pictures) | Minimum unit for latency measurement |
| **Object** | One encoded frame or frame group | Unit of delivery — basis for per-delivery payment |

**Key insight:** Delivery switching in MoQ is a Track re-subscription, not a connection teardown. The client can hold two Track subscriptions simultaneously during transition — zero-gap switching.

### 6.3 Caton Enhanced MoQ (CE-MoQ)

The Caton C3 SDK augments base MoQ with:
- **Multi-path AI routing (CVP):** Selects lowest-latency path across fibre/5G/satellite in real time — sub-500ms even under 30% packet loss
- **CTP (Caton Transport Protocol):** Forward error correction for packet-loss recovery
- **NetScope telemetry:** Real-time per-delivery latency measurement — feeds the SLA Oracle

**Paris Olympics 2024 validation:** 16 simultaneous HD feeds · 17 consecutive days · Zero errors · 3,580 AI path switches per day — the most rigorous broadcast-grade transport validation available for any DePIN project.

### 6.4 Browser Support

MoQ/WebTransport is **Baseline Widely Available** as of 2026: Chrome 97+ · Firefox 114+ · Edge 97+ · Safari 18+. QUIC delivery reaches 98%+ of global browser users with zero installation required.

---

## 7. Payment Layer: x402 Per-Delivery Micropayment Protocol

### 7.1 What Is x402?

x402 (Coinbase, released May 2025) is an HTTP-native micropayment standard that repurposes the long-reserved HTTP 402 "Payment Required" status code as a machine-readable payment trigger:

```
1. Client requests delivery → Server returns HTTP 402 + payment requirements
2. Client wallet signs payment payload (EIP-712 structured data)
3. Client retries request with X-PAYMENT header containing signed payload
4. x402 Facilitator (Coinbase REST API) verifies + settles on Base L2
5. Server receives payment confirmation → fulfils delivery → writes SLA proof
```

The entire cycle completes in under 2 seconds on Base L2, at USD 0.0001 gas per transaction — making per-delivery settlement economically viable at any volume above 1,000 events/day.

### 7.2 x402 Server Implementation (TypeScript Reference)

```typescript
// Node-side x402 middleware (Express / Fastify compatible)
import { paymentMiddleware } from 'x402-express';
import { evm } from 'x402-evm';

app.use(paymentMiddleware(
  NODE_OPERATOR_WALLET_ADDRESS,
  {
    '/api/delivery-request': {
      price: '0.0001',        // 0.0001 USDC per delivery event
      network: 'base',        // Base L2 mainnet
      description: 'CMXS verified delivery slot'
    },
    '/api/sla-proof': {
      price: '0.00001',       // SLA proof write (minimal)
      network: 'base',
    }
  },
  evm,
  {
    facilitatorUrl: 'https://x402.org/facilitator',
    onSuccess: async (req, res, paymentInfo) => {
      const { transaction: txHash, from: payer, amount } = paymentInfo;
      await writeSLAProof(txHash, req.params.deliveryId, Date.now());
      await notifyDeliveryOracle({
        nodeOperator: NODE_OPERATOR_ADDRESS,
        deliveryId: req.params.deliveryId,
        txHash,
        latencyMs: req.headers['x-delivery-latency']
      });
    }
  }
));
```

### 7.3 x402 Client Implementation (TypeScript Reference)

```typescript
// Client-side automatic payment (browser or AI agent)
import { wrapFetch } from 'x402-fetch';
import { evm } from 'x402-evm';

// Initialize with Coinbase Smart Wallet (EIP-4337 — no browser extension required)
const x402Fetch = wrapFetch(fetch, evm, { wallet: smartWalletClient });

// Single call handles the complete 402→sign→retry flow automatically
const response = await x402Fetch(
  'https://cmxs-node.network/api/delivery-request',
  { method: 'GET', headers: { 'X-Delivery-Session': sessionId } }
);
// If 402: wallet signs, payment settles on-chain, request retried automatically
const { deliveryTrack, txHash } = await response.json();
```

### 7.4 Why x402 Is Optimal for CMXS

| Property | x402 | Lightning Network | Stripe / Fiat | Custom Smart Contract |
|----------|------|-----------------|--------------|----------------------|
| Per-delivery granularity | ✅ Native | ✅ Native | ❌ Batch only | ✅ Possible |
| AI agent native | ✅ HTTP-native | ⚠️ Requires node | ❌ API keys | ⚠️ ABI calls |
| No account required | ✅ Wallet only | ⚠️ Channel setup | ❌ Account | ✅ Wallet only |
| Instant settlement | ✅ 2s Base L2 | ✅ Off-chain | ❌ T+1/T+2 | ✅ On-chain |
| Gas cost per tx | USD 0.0001 | ~USD 0.00001 | N/A | USD 0.001–1 |
| Coinbase ecosystem | ✅ Native | ❌ | ❌ | ⚠️ Partial |
| Open standard | ✅ Coinbase + Cloudflare | ✅ | ❌ Proprietary | ❌ |

x402 is chosen primarily because it is **AI-agent native** — autonomous software agents can participate in per-delivery auctions without human intervention by having an x402-capable wallet. This is the architectural requirement for the CMXS Phase 3 AI agent use case.

---

## 8. Proof-of-Delivery (PoD) — The Core Consensus Mechanism

### 8.1 Why PoD: The Consensus Mechanism Comparison

Every blockchain needs a way to decide: *Did real work happen? Does the network deserve to be paid?*

| Mechanism | How Rewards Are Earned | Energy Use | Fit for CMXS |
|----------|----------------------|-----------|-------------|
| **Proof-of-Work (PoW)** | Solving cryptographic puzzles irrelevant to delivery | Enormous | ❌ Waste; no delivery benefit |
| **Proof-of-Stake (PoS)** | Holding/staking tokens — rewards capital, not work | Low | ❌ Rich-get-richer; misaligned |
| **Proof-of-Delivery (PoD)** | Completing verified deliveries below latency SLA | Minimal | ✅ Rewards exactly the work needed |

PoD is the DePIN-standard consensus approach: Helium uses Proof-of-Coverage (radio coverage verified by peers); Hivemapper uses Proof-of-Drive (map coverage via GPS + image analysis); DIMO uses Proof-of-Contribution (vehicle telemetry verified by on-board devices). CMXS uses **Proof-of-Delivery**: content delivery verified by cryptographic receipt, on-chain payment, and latency measurement.

### 8.2 The PoD Cycle — Step by Step

```
┌─────────────────────────────────────────────────────────────┐
│         PROOF-OF-DELIVERY CYCLE — ONE DELIVERY EVENT        │
│                                                             │
│  1. NODE delivers content object via QUIC/MoQ               │
│     └→ Latency measured by NetScope: T_delivery             │
│                                                             │
│  2. CLIENT generates Delivery Receipt                       │
│     └→ { segmentHash, T_delivery, playerWallet, latencyMs } │
│     └→ Signed by player wallet — cryptographically unforgeable│
│                                                             │
│  3. RECEIPT submitted to DeliveryOracle.sol on Base L2      │
│     └→ Oracle verifies ECDSA signature                      │
│     └→ Checks: latencyMs < 500ms threshold                  │
│     └→ Checks: deliveryId not previously used (replay guard)│
│                                                             │
│  4. ORACLE emits DeliveryProofAccepted event                │
│     └→ Event includes: deliveryId, nodeOperator, latencyMs  │
│                                                             │
│  5. CMXS.rewardNode() mints 0.001 CMXS → node wallet       │
│     └→ Subject to MAX_DAILY_MINT safety cap                 │
│     └→ Subject to MAX_SUPPLY ceiling check                  │
│                                                             │
│  6. SLA PROOF written on-chain (ERC-8004 derivative)        │
│     └→ deliveryId + txHash + latencyMs + slaMet (bool)      │
│     └→ Permanently auditable on Basescan                    │
└─────────────────────────────────────────────────────────────┘
```

### 8.3 PoD Security — Four Attack Vectors Defeated

**Attack 1: Fake Delivery (Sybil Attack)**
- *What an attacker tries:* A node claims to have delivered content it did not deliver
- *Defence:* The delivery receipt must be signed by **the viewer's wallet** — not the node. A node cannot forge a viewer's cryptographic signature. The x402 payment on-chain provides an independent second verification signal from a completely separate cryptographic path

**Attack 2: Replay Attack**
- *What an attacker tries:* Node resubmits the same valid delivery proof multiple times to claim multiple rewards
- *Defence:* Every `deliveryId` is stored in `mapping(bytes32 => bool) public usedNonces` in DeliveryOracle.sol. A resubmitted `deliveryId` is rejected with "Proof already used"

**Attack 3: Oracle Compromise**
- *What an attacker tries:* Attacker compromises the oracle signing key and mints CMXS without real deliveries
- *Defence:* `MAX_DAILY_MINT = 2,880,000 CMXS/day` is hardcoded in the token contract. Even a complete oracle compromise cannot mint more than **0.288% of total supply** in any 24-hour window. Phase 1 migration to Chainlink CRE eliminates the trusted-signer dependency entirely

**Attack 4: Latency Spoofing**
- *What an attacker tries:* Node reports false latency measurements below the 500ms threshold
- *Defence:* Latency is measured independently by NetScope telemetry on the **client side** and cross-referenced with the x402 payment timestamp. Both measurements must be consistent within a tolerance window. Client-side measurement cannot be manipulated by the node

### 8.4 PoD vs. Comparable DePIN Mechanisms

| Network | Mechanism | Verification Method | CMXS Equivalent |
|---------|----------|--------------------|--------------------|
| Helium | Proof-of-Coverage | Peer radio challenge/response | Cryptographic delivery receipt |
| Hivemapper | Proof-of-Drive | GPS track + image hash | x402 payment + latency timestamp |
| DIMO | Proof-of-Contribution | OBD telemetry + device attestation | NetScope telemetry + oracle signature |
| **CMXS** | **Proof-of-Delivery** | **Client ECDSA receipt + x402 + latency oracle** | — |

CMXS is the only DePIN mechanism using **dual-signal verification** — an independent cryptographic receipt AND an independent on-chain payment — for each delivery event. Single-signal mechanisms can be gamed; dual-signal mechanisms require simultaneously defeating two independent cryptographic systems.

---

## 9. CMXS Token Design and Optimised Structure

### 9.1 Design Principles

The CMXS token design is optimised against four criteria derived from post-mortems of all major DePIN token launches (Helium, Filecoin, Render, Hivemapper, DIMO, Akash):

1. **Token utility must precede token speculation.** CMXS has functional use (earning delivery rewards, burning for delivery priority, governance staking) before, during, and independent of any price appreciation.

2. **Supply must be algorithmically self-regulating.** No discretionary mint authority. Supply is controlled entirely by the Proof-of-Delivery rate (real network activity) and the burn rate (real service demand).

3. **Team and investor incentives must be structurally aligned with network health.** Long cliff periods and linear vesting ensure team tokens vest only as the network grows.

4. **Regulatory clarity from the first day.** Post-March 2026 SEC taxonomy, CMXS is designed as a "digital tool" — a functional work-reward instrument with rewards determined by protocol rules rather than managerial discretion.

### 9.2 Complete Token Specification

| Parameter | Value | Rationale |
|-----------|-------|-----------|
| Token Name | CatonMX Settlement Token | Full name for regulatory filings |
| Ticker | CMXS | Short, memorable, exchange-compliant |
| Token Standard | ERC-20 on Base L2 | USD 0.0001/tx gas; x402 native; Coinbase ecosystem |
| **Total Supply** | **1,000,000,000 (fixed)** | No inflation. Sufficient for 10+ years at max scale |
| Decimals | 18 | ERC-20 standard |
| Initial Circulating Supply | 150,000,000 (15%) | Best practice: limit float at TGE for price discovery |
| Mint Authority | DeliveryOracle.sol only | No team mint capability post-TGE; verified by audit |
| Burn Authority | Public — `burn()` callable by any holder | Transparent; verifiable on-chain |
| Max Daily Mint Rate | 2,880,000 CMXS/day | Safety cap: 2,000 nodes × 1,440 deliveries × 0.001 CMXS |
| PoD Reward Rate | 0.001 CMXS per verified delivery | ~USD 0.10/day per node at USD 100 token price |
| Blockchain | Base L2 (Coinbase / OP Stack) | x402 native; gasless experience (EIP-4337); Coinbase relationships |
| Contract Framework | Foundry + OpenZeppelin v5 | Industry-standard security |
| Audit Requirement | Trail of Bits or CertiK | Pre-TGE mandatory; institutional investor standard |

---

## 10. Burn-and-Mint Equilibrium (BME) — The Economic Engine

### 10.1 The BME Mechanism

Burn-and-Mint Equilibrium (BME), pioneered by Helium's HNT token and confirmed as the DePIN tokenomics standard by Frontiers in Blockchain peer-reviewed research (2025), creates a self-regulating token supply tied algorithmically to real network activity.

**BURN SIDE — Demand Creates Scarcity:**
```
Service buyer requests verified delivery slot
→ Pays USDC via x402 micropayment
→ x402 Facilitator routes fee to CMXS Foundation treasury
→ Treasury burns CMXS proportional to payment value
→ More service demand → more CMXS burned → circulating supply ↓
→ Reduced supply → upward price pressure (ceteris paribus)
```

**MINT SIDE — Work Creates Supply:**
```
Node operator completes verified delivery (latency <500ms)
→ DeliveryOracle.sol calls CMXS.rewardNode()
→ 0.001 CMXS minted to node operator wallet
→ More deliveries → more CMXS minted → circulating supply ↑
```

**EQUILIBRIUM DYNAMICS:**
```
burn rate > mint rate → supply ↓ → price ↑
→ More nodes join (attracted by higher CMXS value)
→ Mint rate ↑ → equilibrium restores

mint rate > burn rate → supply ↑ → price ↓
→ Marginal nodes exit (economics no longer justify hardware)
→ Mint rate ↓ → equilibrium restores
```

### 10.2 Four Independent Demand Engines

A key structural advantage of CMXS over single-use-case DePIN tokens: CMXS has **four independent mechanisms** generating token demand. Any one is sufficient for sustainable utility; together they create compounding demand pressure.

| Demand Engine | Token Mechanism | Economic Driver |
|--------------|----------------|----------------|
| **PoD Node Rewards** | 0.001 CMXS minted per verified delivery | Network growth drives expanding reward pool |
| **x402 Burn** | Service buyers burn CMXS for delivery priority access | Service demand growth = direct token burn |
| **SLA Staking Premium** | Nodes stake CMXS for priority routing + premium slots | Staking removes circulating supply |
| **veToken Governance** | veCMXS (locked CMXS) for governance participation | Long-term holders lock supply for 1–4 years |

### 10.3 BME Stability Properties

1. **Anti-fragile to demand growth.** Rising service demand burns more tokens → price support → more nodes join → better service quality → more demand. Positive feedback loop.

2. **Self-correcting against supply inflation.** If node growth outpaces service demand, CMXS price falls, marginal nodes exit, and the mint rate decreases automatically — without any manual intervention.

3. **No discretionary authority.** BME parameters (reward rate, burn rate, daily mint cap) are set in immutable smart contracts. No team, no foundation, no DAO vote can trigger an emergency mint. Protocol parameters can be changed going forward through governance, but past minting cannot be retroactively altered.

---

## 11. Token Allocation and Vesting Schedule

### 11.1 Full Token Distribution

| Category | Allocation | Tokens (CMXS) | TGE Unlock | Vesting |
|----------|-----------|--------------|------------|---------|
| **Node Rewards Pool (PoD)** | 35% | 350,000,000 | 0% | Minted on-demand via PoD only; daily cap applies |
| **Foundation Treasury** | 20% | 200,000,000 | 0% | 6-month cliff; 24-month linear |
| **Ecosystem Grants** | 15% | 150,000,000 | 0% | 12-month cliff; 36-month linear |
| **Seed / Strategic Round** | 10% | 100,000,000 | 0% | 12-month cliff; 36-month linear |
| **Public ICO** | 10% | 100,000,000 | 20% | 80% over 12 months linear |
| **Team & Advisors** | 8% | 80,000,000 | 0% | 12-month cliff; 48-month linear |
| **Liquidity Provision** | 2% | 20,000,000 | 100% | Unlocked at TGE for DEX/CEX seeding only |
| **TOTAL** | **100%** | **1,000,000,000** | — | — |

### 11.2 Vesting Rationale

**35% Node Rewards Pool:** Matches Helium's proportional node reward commitment — the DePIN industry benchmark. Minted on-demand (not pre-allocated) ensures rewards are not dilutive before work is performed. The 2,880,000 CMXS/day daily cap prevents inflation even at full network scale.

**12-month cliff + 48-month linear for Team/Advisors:** The 2026 institutional investor standard. Cliff shorter than 12 months is a known DePIN due diligence red flag — signals low team conviction and creates dump pressure at listing.

**12-month cliff + 36-month linear for Seed/Strategic:** Ensures seed investors cannot exit at TGE, structurally aligning their interests with Phase 1 network growth milestones.

**20% TGE for Public ICO participants:** Provides immediate liquidity for public participants while preventing dump pressure through 80% 12-month linear.

**2% Liquidity Provision unlocked at TGE:** Deliberately constrained minimum to seed Uniswap v4 pool and one CEX pair. Larger liquidity unlocks at TGE historically lead to immediate arbitrage selling.

### 11.3 Infrastructure JV Vesting (Tower Operators)

Tower infrastructure operators contributing physical nodes receive Ecosystem Grant CMXS on a milestone-based schedule:

| Milestone | % Unlocked | Condition |
|----------|-----------|-----------|
| M1 — Node installation | 25% | Node registered and verified on-chain via NodeRegistry.sol |
| M2 — First 50 deliveries | 25% | 50 PoD events logged with `slaMet = true` |
| M3 — 12-month uptime | 25% | >95% uptime over 12 consecutive months |
| M4 — 36-month participation | 25% | Node active and staked at 36-month mark |

---

## 12. Staking Architecture

CMXS staking has three distinct tiers, each serving a different network function:

### 12.1 Tier 1 — Node Operator Bond (Sybil Protection)

Every node must stake a minimum CMXS amount to activate PoD reward eligibility. This stake is the node's economic commitment to honest behaviour — forfeiting it through slashing is the cost of cheating.

| Parameter | Value | Rationale |
|-----------|-------|-----------|
| Minimum stake per node | 1,000 CMXS | ~USD 100 at initial FDV — accessible to small operators |
| Slash condition | 3 failed delivery proofs in 24 hours | Three-strike rule prevents accidental slashing |
| Slash penalty | 10% of staked amount | Meaningful deterrent without catastrophic punishment |
| Unstake delay | 7 days | Prevents hit-and-run attacks |
| Contract | NodeRegistry.sol | All stake/slash logic in audited, public contract |

### 12.2 Tier 2 — Service Buyer Prepayment Escrow

Service buyers who commit to volume receive discounted CMXS burn rates:

| Volume Tier | USDC Staked | CMXS Burn Discount | Routing Priority |
|------------|------------|-------------------|----------------|
| Standard | USD 0–9,999 | 0% | Best effort |
| Tier 1 | USD 10,000 | 5% burn discount | Standard priority |
| Tier 2 | USD 50,000 | 12% burn discount | High priority routing |
| Tier 3 | USD 250,000 | 20% burn discount | Guaranteed premium slots |

### 12.3 Tier 3 — veToken Governance Staking (Curve Finance Model)

Token holders lock CMXS for 1–4 years to receive veCMXS (vote-escrowed CMXS):

| Lock Duration | veCMXS per 1 CMXS | Governance Weight | Protocol Fee Share |
|-------------|-----------------|-----------------|------------------|
| 1 year | 0.25 veCMXS | 25% | 25% of fee allocation |
| 2 years | 0.50 veCMXS | 50% | 50% of fee allocation |
| 4 years | 1.00 veCMXS | Full (1:1) | Full allocation |

**veCMXS rights include:**
- Vote on all network parameters (reward rate, slash conditions, daily mint cap, burn fee rate)
- Receive 50% of protocol fees collected from x402 burn transactions (paid in USDC)
- Priority access to new node operator geography allocations
- Propose and vote on Ecosystem Grant distributions from the 15% grant pool

---

## 13. Smart Contract Reference Implementation

### 13.1 Full Contract Suite

| Contract | Purpose | Key Roles |
|----------|---------|-----------|
| `CMXS.sol` | ERC-20 token with controlled mint/burn, daily cap, BME tracking | MINTER_ROLE (oracle only), BURNER_ROLE (public) |
| `DeliveryOracle.sol` | Trusted-signer oracle (Phase 0); Chainlink CRE (Phase 1+) | Oracle signer, upgradeable |
| `NodeRegistry.sol` | Node registration, stake management, slash logic | Node operators, admin |
| `ServiceBuyerEscrow.sol` | USDC escrow + burn discount tier management | Service buyers |
| `GovernanceStaking.sol` | veCMXS lock/unlock, voting weight, fee distribution | Any CMXS holder |
| `Treasury.sol` | Foundation treasury; Ecosystem Grant distribution | DAO (veCMXS governance) |
| `VestingVault.sol` | Team/investor cliff + linear vesting | Beneficiaries |

### 13.2 CMXS.sol — Full Reference Implementation

```solidity
// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

/**
 * @title CMXS — CatonMX Settlement Token
 * @notice ERC-20 DePIN utility token with Burn-and-Mint Equilibrium
 * @dev Mint authority restricted to DeliveryOracle.sol (MINTER_ROLE)
 *      No team or admin can mint tokens directly post-deployment
 */
contract CMXS is ERC20, AccessControl, Pausable {

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    uint256 public constant MAX_SUPPLY = 1_000_000_000 * 1e18;   // 1B fixed cap
    uint256 public constant MAX_DAILY_MINT = 2_880_000 * 1e18;   // Safety cap
    uint256 public constant REWARD_PER_DELIVERY = 1e15;           // 0.001 CMXS

    // BME tracking — public, readable by anyone including regulators and auditors
    uint256 public totalBurned;
    uint256 public totalMinted;

    // Daily mint cap enforcement
    uint256 public dailyMintedToday;
    uint256 public mintResetTimestamp;

    event DeliveryRewarded(
        address indexed nodeOperator,
        bytes32 indexed deliveryId,
        uint256 amount,
        uint256 cumulativeMinted
    );

    event TokensBurned(
        address indexed burner,
        uint256 amount,
        string reason,
        uint256 cumulativeBurned
    );

    constructor() ERC20("CatonMX Settlement Token", "CMXS") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        // NOTE: No tokens minted to team/admin at construction.
        // All initial allocations are minted via initialise() after audit.
    }

    /**
     * @notice Reward a node operator for a verified delivery event
     * @dev Only callable by DeliveryOracle.sol (MINTER_ROLE)
     */
    function rewardNode(
        address nodeOperator,
        bytes32 deliveryId,
        uint256 amount
    ) external onlyRole(MINTER_ROLE) whenNotPaused {
        require(totalSupply() + amount <= MAX_SUPPLY, "Max supply exceeded");
        _enforceDailyMintCap(amount);
        _mint(nodeOperator, amount);
        totalMinted += amount;
        emit DeliveryRewarded(nodeOperator, deliveryId, amount, totalMinted);
    }

    /**
     * @notice Burn CMXS tokens (service buyer burn-for-priority or governance)
     */
    function burn(uint256 amount, string calldata reason) external {
        _burn(msg.sender, amount);
        totalBurned += amount;
        emit TokensBurned(msg.sender, amount, reason, totalBurned);
    }

    /**
     * @notice BME health check — net supply change since genesis
     * @return netInflation Positive = inflationary; Negative = deflationary
     */
    function bmeNetInflation() external view returns (int256) {
        return int256(totalMinted) - int256(totalBurned);
    }

    function _enforceDailyMintCap(uint256 amount) internal {
        if (block.timestamp > mintResetTimestamp + 1 days) {
            dailyMintedToday = 0;
            mintResetTimestamp = block.timestamp;
        }
        require(
            dailyMintedToday + amount <= MAX_DAILY_MINT,
            "Daily mint cap exceeded"
        );
        dailyMintedToday += amount;
    }
}
```

### 13.3 DeliveryOracle.sol — Phase 0 Trusted-Signer Implementation

```solidity
// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

/**
 * @title DeliveryOracle
 * @notice Phase 0: trusted-signer ECDSA oracle
 * @dev Migration path: updateTrustedSigner(chainlinkCREAddress) upgrades
 *      to decentralised oracle with zero contract rewrite required
 */
contract DeliveryOracle is Ownable {
    using ECDSA for bytes32;
    using MessageHashUtils for bytes32;

    address public trustedSigner;    // Backend server key (Phase 0) / Chainlink CRE (Phase 1+)
    ICMXS public cmxsToken;
    uint256 public slaThresholdMs = 500;    // Default 500ms SLA threshold

    mapping(bytes32 => bool) public usedNonces;    // Replay attack protection

    event DeliveryProofAccepted(
        bytes32 indexed deliveryId,
        address indexed nodeOperator,
        uint256 latencyMs,
        uint256 rewardAmount,
        uint256 timestamp
    );

    constructor(address _trustedSigner, address _cmxsToken) Ownable(msg.sender) {
        trustedSigner = _trustedSigner;
        cmxsToken = ICMXS(_cmxsToken);
    }

    /**
     * @notice Submit a signed delivery proof and claim node reward
     * @param deliveryId      keccak256(txHash + nodeId + sessionId) — unique per event
     * @param nodeOperator    Node wallet claiming the reward
     * @param latencyMs       Measured delivery latency in milliseconds
     * @param rewardAmount    CMXS to mint (validated against REWARD_PER_DELIVERY)
     * @param expiry          Proof expires at this block.timestamp
     * @param signature       ECDSA signature from trustedSigner over all params + chainId
     */
    function submitDeliveryProof(
        bytes32 deliveryId,
        address nodeOperator,
        uint256 latencyMs,
        uint256 rewardAmount,
        uint256 expiry,
        bytes calldata signature
    ) external {
        require(block.timestamp <= expiry, "Proof expired");
        require(!usedNonces[deliveryId], "Proof already used");
        require(latencyMs <= slaThresholdMs, "SLA not met: latency exceeded");
        require(rewardAmount == cmxsToken.REWARD_PER_DELIVERY(), "Invalid reward amount");

        bytes32 messageHash = keccak256(abi.encodePacked(
            deliveryId,
            nodeOperator,
            latencyMs,
            rewardAmount,
            expiry,
            block.chainid    // Prevents cross-chain replay attacks
        ));

        address recovered = messageHash
            .toEthSignedMessageHash()
            .recover(signature);
        require(recovered == trustedSigner, "Invalid oracle signature");

        usedNonces[deliveryId] = true;    // Replay protection
        cmxsToken.rewardNode(nodeOperator, deliveryId, rewardAmount);

        emit DeliveryProofAccepted(
            deliveryId, nodeOperator, latencyMs, rewardAmount, block.timestamp
        );
    }

    /** @notice Migrate to Chainlink CRE: updateTrustedSigner(chainlinkCREAddress) */
    function updateTrustedSigner(address newSigner) external onlyOwner {
        trustedSigner = newSigner;
    }
}
```

### 13.4 Backend Oracle Signing (TypeScript Reference)

```typescript
// Backend service: signs delivery proofs for DeliveryOracle.sol
import { keccak256, encodePacked } from 'viem';
import { privateKeyToAccount } from 'viem/accounts';

const oracleAccount = privateKeyToAccount(
  process.env.ORACLE_PRIVATE_KEY as `0x${string}`
);

export async function signDeliveryProof(params: {
  deliveryId: `0x${string}`;
  nodeOperator: `0x${string}`;
  latencyMs: bigint;
  rewardAmount: bigint;
  expiry: bigint;
}): Promise<`0x${string}`> {
  const messageHash = keccak256(encodePacked(
    ['bytes32', 'address', 'uint256', 'uint256', 'uint256', 'uint256'],
    [
      params.deliveryId,
      params.nodeOperator,
      params.latencyMs,
      params.rewardAmount,
      params.expiry,
      BigInt(8453)    // Base mainnet chainId — prevents cross-chain replay
    ]
  ));

  // EIP-191 personal_sign — matches toEthSignedMessageHash() in Solidity
  return oracleAccount.signMessage({ message: { raw: messageHash } });
}
```

### 13.5 VestingVault.sol — Cliff + Linear Vesting

```solidity
// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract VestingVault is Ownable {

    struct VestingSchedule {
        address beneficiary;
        uint256 totalAmount;
        uint256 cliffTimestamp;      // Tokens locked until this time
        uint256 startTimestamp;      // Linear vesting begins here
        uint256 endTimestamp;        // Fully vested at this time
        uint256 claimedAmount;
    }

    IERC20 public cmxsToken;
    mapping(address => VestingSchedule) public schedules;

    event TokensClaimed(address indexed beneficiary, uint256 amount);

    constructor(address _cmxsToken) Ownable(msg.sender) {
        cmxsToken = IERC20(_cmxsToken);
    }

    function createSchedule(
        address beneficiary,
        uint256 totalAmount,
        uint256 cliffMonths,
        uint256 vestingMonths
    ) external onlyOwner {
        uint256 cliffTs = block.timestamp + (cliffMonths * 30 days);
        uint256 endTs = cliffTs + (vestingMonths * 30 days);
        schedules[beneficiary] = VestingSchedule({
            beneficiary: beneficiary,
            totalAmount: totalAmount,
            cliffTimestamp: cliffTs,
            startTimestamp: cliffTs,
            endTimestamp: endTs,
            claimedAmount: 0
        });
    }

    function claim() external {
        VestingSchedule storage s = schedules[msg.sender];
        require(s.totalAmount > 0, "No schedule found");
        require(block.timestamp >= s.cliffTimestamp, "Cliff not reached");
        uint256 vested = _vestedAmount(s);
        uint256 claimable = vested - s.claimedAmount;
        require(claimable > 0, "Nothing to claim");
        s.claimedAmount += claimable;
        cmxsToken.transfer(msg.sender, claimable);
        emit TokensClaimed(msg.sender, claimable);
    }

    function _vestedAmount(VestingSchedule memory s) internal view returns (uint256) {
        if (block.timestamp < s.cliffTimestamp) return 0;
        if (block.timestamp >= s.endTimestamp) return s.totalAmount;
        uint256 elapsed = block.timestamp - s.startTimestamp;
        uint256 duration = s.endTimestamp - s.startTimestamp;
        return (s.totalAmount * elapsed) / duration;
    }
}
```

---

## 14. Governance: veToken Model

### 14.1 Governance Architecture

CMXS governance is implemented via the Curve Finance veToken model — proven in production across USD 5B+ TVL protocols with no governance exploits in 5+ years of operation.

**Governance lifecycle:**
1. Any wallet with ≥100,000 veCMXS submits proposal to governance forum
2. 7-day community discussion period (off-chain Snapshot + on-chain staging)
3. 5-day on-chain voting period (GovernanceStaking.sol)
4. Quorum requirement: ≥10% of total veCMXS must vote
5. Approval threshold: ≥66% supermajority FOR
6. 48-hour timelock before execution (security buffer)
7. Execution via Treasury.sol or parameter update call

### 14.2 Governable Parameters

| Parameter | Current Default | Who Can Change |
|-----------|----------------|----------------|
| PoD reward rate (CMXS per delivery) | 0.001 CMXS | veCMXS DAO (66% supermajority) |
| Daily mint safety cap | 2,880,000 CMXS | veCMXS DAO (66% supermajority) |
| SLA latency threshold | 500ms | veCMXS DAO (66% supermajority) |
| Slash penalty percentage | 10% | veCMXS DAO (66% supermajority) |
| Protocol fee on burn transactions | 5% | veCMXS DAO (66% supermajority) |
| Ecosystem Grant allocation | Per proposal | veCMXS DAO (simple majority) |

### 14.3 Progressive Decentralisation Schedule

| Phase | Period | Governance Status | Foundation Role |
|-------|--------|-----------------|----------------|
| Phase 0 | Months 1–12 | Foundation-controlled | Full control (regulatory flexibility) |
| Phase 1 | Months 12–36 | veCMXS DAO activated | Foundation retains compliance veto only |
| Phase 2 | Month 36+ | Full DAO governance | Foundation veto dissolved |

The SEC Safe Harbor 2.0 (March 2026) defines "network maturity" as the point at which no single entity controls >50% of transaction validation. CMXS Foundation targets this by Month 24.

---

## 15. ICO Framework and Four-Stage Capital Raise

### 15.1 Strategic Rationale for a Four-Stage Raise

A staged capital raise de-risks the ICO by:
1. Establishing institutional credibility (Angel/Seed) before public access
2. Using exchange-hosted KYC (IEO) to satisfy regulatory requirements at scale
3. Discovering the market-clearing token price via Liquidity Bootstrapping Pool rather than an arbitrary fixed price
4. Creating multiple price discovery points (USD 0.02 → USD 0.10) that reward early conviction with the DePIN-standard pricing ladder

### 15.2 Four-Stage Capital Raise

**Stage 0 — Angel / SAFE Round (Months 1–2)**

| Parameter | Detail |
|-----------|--------|
| Target Raise | USD 1M–2M |
| Instrument | SAFE (Simple Agreement for Future Tokens) |
| Conversion | 20% discount to Seed round token price |
| Investors | 5–10 strategic angels (streaming, DePIN, broadcast infrastructure) |
| Token Price | Not set (converts at Seed) |
| Use of Funds | Cayman entity setup, audit deposit, Caton C3 SDK licensing, Phase 0 infra |
| KYC | Full KYC via Jumio; accredited investor verification |

**Stage 1 — Seed Round Reg D 506(c) (Months 3–4)**

| Parameter | Detail |
|-----------|--------|
| Target Raise | USD 3M–5M |
| Token Price | USD 0.02 / CMXS |
| Implied FDV | USD 20M |
| Allocation | 50,000,000 CMXS (5% of total supply) |
| Vesting | 12-month cliff; 36-month linear |
| Minimum Ticket | USD 250,000 |
| Investor Type | US accredited investors + crypto-native VCs (Multicoin, Paradigm, a16z crypto) |
| Legal Basis | SEC Regulation D 506(c) — filed within 15 days of first close |
| KYC Platform | CoinList or Republic Crypto |

**Stage 2 — Strategic / IEO Round (Months 5–6)**

| Parameter | Detail |
|-----------|--------|
| Target Raise | USD 8M–15M |
| Venue | Tier-1 IEO: Binance Launchpad, Coinbase Ventures, or Kraken Ventures |
| Token Price | USD 0.05–0.08 / CMXS |
| Implied FDV | USD 50M–80M |
| Allocation | 50,000,000 CMXS (from Public ICO pool) |
| Vesting | 20% at TGE; 80% over 12 months linear |
| Why IEO | Exchange-hosted IEOs complete at 3× the rate of direct ICOs (2026 data) |

**Stage 3 — Public IDO / Token Generation Event (Month 7)**

| Parameter | Detail |
|-----------|--------|
| Target Raise | USD 6M–11M |
| Venue | Fjord Foundry LBP + Uniswap v4 on Base L2 + 1–2 CEX listings |
| Token Price | USD 0.10 / CMXS (LBP start: USD 0.15; 72-hour price discovery) |
| Implied FDV | **USD 100M** |
| Allocation | 20,000,000 CMXS (2% Liquidity Provision + remaining Public ICO) |
| LBP Mechanics | Price starts at USD 0.15, declines to market-clearing price — prevents whale sniping |
| Geographic Restrictions | No US retail (accredited only); no OFAC-sanctioned jurisdictions |
| TGE Unlock | 20% of public allocation; 80% over 12 months linear |

### 15.3 Complete Raise Summary — CONFIRMED

| Stage | Raise | Token Price | Implied FDV | Vesting |
|-------|-------|------------|------------|---------|
| Angel / SAFE | USD 1M–2M | N/A | N/A | Converts at Seed |
| Seed Reg D | USD 3M–5M | USD 0.02 | USD 20M | 12M cliff + 36M linear |
| Strategic / IEO | USD 8M–15M | USD 0.05–0.08 | USD 50M–80M | 20% TGE + 12M linear |
| Public IDO | USD 6M–11M | USD 0.10 | USD 100M | 20% TGE + 12M linear |
| **TOTAL** | **USD 18M–33M** | — | — | — |

---

## 16. Use of Proceeds

| Category | % | Amount (USD 25M midpoint) | Specific Use |
|----------|---|--------------------------|-------------|
| Technology Development | 35% | USD 8.75M | CE-MoQ relay, x402 integration, CMXS contract suite, oracle, dashboard, player SDK |
| Physical Node Infrastructure | 25% | USD 6.25M | Tower JV setup costs, Phase 1 hardware (500 nodes), Phase 0 AWS edge infra |
| Legal & Compliance | 15% | USD 3.75M | Cayman Foundation setup, Reg D filings, Trail of Bits audit, ongoing legal counsel |
| Marketing & Community | 15% | USD 3.75M | KOL campaigns, Discord/Telegram, exchange listing fees, PR, developer grants |
| Operations & Reserve | 10% | USD 2.5M | Team salaries (Months 1–12), insurance, emergency reserve, audit remediation |

---

## 17. Network Expansion and Use Case Roadmap

CMXS is a general-purpose verified-delivery DePIN protocol. The initial commercial deployment is one of multiple planned applications; the same infrastructure, transport stack, and token settlement layer support multiple verticals **without any protocol modification**.

### 17.1 Use Case Expansion Map

| Use Case | CMXS Application | Market Size | Timeline |
|----------|-----------------|------------|---------|
| **Verified digital content delivery (CTV/FAST)** | x402 per-impression burn + PoD node rewards | USD 40.2B (2026) | **Phase 0–1 (live)** |
| **Live sports betting infrastructure** | Sub-500ms latency service (B2B licensing) | USD 45.9B TAM | Phase 1–2 |
| **Pay-per-view content** | x402 per-view micropayment + delivery proof | USD 8B (live sports PPV) | Phase 2 |
| **AI agent data feed delivery** | Autonomous x402 agent-to-agent payments | Emerging (2026+) | Phase 3 |
| **IoT telemetry delivery** | PoD for sensor data; sub-500ms telemetry | USD 145.9B DePIN TAM (2033) | Phase 3+ |
| **Live auction / shopping streams** | Low-latency + payment settlement combo | USD 32B (live commerce) | Phase 2–3 |

### 17.2 The Protocol Generalisation Principle

Every use case uses the **same four-component stack**:
1. QUIC/MoQ transport (sub-500ms delivery)
2. x402 micropayment (per-delivery USDC settlement)
3. PoD oracle (verified delivery proof)
4. CMXS token (node reward + governance)

No protocol modification is required to expand to a new use case — only new application-layer software connecting to the existing CMXS network. This is what makes CMXS a **protocol token** (network-wide value accrual) rather than an **application token** (value limited to one use case).

---

## 18. Competitive Benchmarking

### 18.1 DePIN Network Comparison

| Network | Physical Infrastructure | Verification | Delivery SLA | Token Model | Initial FDV |
|---------|------------------------|-------------|-------------|------------|-------------|
| **CMXS** | **5,800 EchoStar towers (JV anchor)** | **PoD — ECDSA receipt + x402 + oracle** | **<500ms guaranteed** | **BME** | **USD 100M** |
| Helium (HNT) | Crowdsourced LoRaWAN hotspots | Proof-of-Coverage (radio challenge) | Coverage-based | BME | USD 16M |
| Render (RNDR) | Crowdsourced GPU nodes | Proof-of-Render (job completion hash) | GPU job-based | BME | USD 18M |
| Hivemapper (HONEY) | Crowdsourced dashcam devices | Proof-of-Drive (GPS + image hash) | Map coverage | Work token | USD 45M |
| Livepeer (LPT) | ~100 transcoding orchestrators | Work verification (transcoding hash) | Best effort | Work token | USD 5M |
| Theta (THETA) | P2P relay nodes | Staking + relay | Best effort | PoS hybrid | USD 20M |
| Aethir (ATH) | GPU compute nodes | Proof-of-Render | GPU job-based | Work token | USD 760M |

**CMXS structural advantages:**
1. **Pre-existing supply:** 5,800 EchoStar towers — no DePIN project has ever launched with comparable pre-existing physical infrastructure
2. **Pre-existing demand:** Initial commercial use case deploys against existing streaming platform ad inventory — not a cold-start market
3. **Dual-layer proof:** Cryptographic delivery receipt AND x402 payment settlement as independent signals — more robust than all single-signal comparables
4. **Multiple use cases at launch:** Same protocol supports multiple verticals simultaneously — no comparable project has multi-vertical deployment at launch

### 18.2 Peak FDV Benchmarks for DePIN

| Project | Initial FDV | Peak FDV | Peak Multiple | Mechanism |
|---------|------------|---------|--------------|---------|
| Helium (HNT) | USD 16M | USD 5.1B | 319× | Proof-of-Coverage |
| Render (RNDR) | USD 18M | USD 4.2B | 233× | Proof-of-Render |
| Hivemapper (HONEY) | USD 45M | USD 420M | 9.3× | Proof-of-Drive |
| DIMO | USD 9M | USD 200M | 22× | Proof-of-Contribution |
| **CMXS (target)** | **USD 100M** | **TBD** | — | **Proof-of-Delivery** |

The CMXS initial FDV of USD 100M is set conservatively relative to Helium's USD 16M and Render's USD 18M — reflecting the additional value of pre-existing infrastructure and documented commercial demand at launch.

---

## 19. Financial Projections

### 19.1 Revenue Per Node Per Day

| Token Price | Deliveries/Day | Revenue/Node/Day | Hardware Payback (USD 329 node) |
|------------|---------------|----------------|-------------------------------|
| USD 100 | 1,440 | USD 1.44 | ~229 days |
| USD 250 | 1,440 | USD 3.60 | ~91 days |
| USD 500 | 1,440 | USD 7.20 | ~46 days |

### 19.2 Network Growth Projections

| Metric | Year 1 | Year 2 | Year 3 |
|--------|--------|--------|--------|
| Active Nodes | 50–500 | 2,000 | 10,000 |
| Daily Verified Deliveries | 72K–720K | 2.88M | 14.4M |
| Gross Service Revenue | USD 2.4M–8M | USD 42M–84M | USD 84M–144M |
| Implied Network Value (10× revenue) | USD 24M–80M | USD 420M–840M | USD 840M–1.44B |

**Year 3 implied network value of USD 840M–1.44B** represents an 8.4×–14.4× return on the USD 100M initial FDV — consistent with historical DePIN precedents at comparable initial valuations.

---

## 20. Regulatory Compliance Framework

### 20.1 SEC Classification — United States

The SEC's March 17, 2026 interpretive release (Release No. 2026-30) established a five-category non-security taxonomy. CMXS is designed to qualify as a **"digital tool"** — a functional work-reward instrument.

**Howey Test Analysis:**

| Element | Analysis | Conclusion |
|---------|---------|------------|
| Investment of money | Yes — purchasers pay USDC/fiat | Satisfied |
| Common enterprise | Partially — network participants share infrastructure benefit | Partially satisfied |
| Expectation of profits | PoD rewards = compensation for work performed, not passive return | **Not satisfied for node operators** |
| From efforts of others | Rewards determined by smart contract, not managerial decisions | **Not satisfied** |

Under the March 2026 guidance, protocol staking/mining activities (where rewards derive from protocol rules rather than managerial efforts) **do not constitute the offer and sale of securities.**

### 20.2 Safe Harbor 2.0 Compliance

| Requirement | CMXS Compliance Plan |
|------------|---------------------|
| Token Disclosure Document (TDD) filed before TGE | Filed Month 2; published at cmxs.network/tdd |
| Tokenomics fully disclosed | This White Paper constitutes the disclosure |
| US retail limited to accredited investors for 12 months | Enforced via Reg D 506(c) + geo-block at IDO |
| Network maturity plan documented | Progressive decentralisation schedule (Section 14.3) |
| No single entity controls >50% of validation at Year 3 | PoD distribution by design; monitored monthly |

### 20.3 EU / MiCA Compliance

Under MiCA (fully applicable January 2025), CMXS qualifies as a **utility token** under Article 4. Pre-TGE requirements:
- White Paper filed with relevant National Competent Authority (NCA) ≥20 working days before public offering
- No EU marketing implying investment returns
- CMXS Foundation to engage a MiCA-registered EU distribution entity

### 20.4 GENIUS Act (US, 2025)

CMXS is not a payment stablecoin and is not subject to GENIUS Act stablecoin provisions. The x402 payment layer uses USDC (a GENIUS Act-compliant stablecoin operated by Circle), insulating CMXS from stablecoin regulatory risk entirely.

### 20.5 KYC / AML Framework

| Participant Type | KYC Level | Vendor | Legal Basis |
|-----------------|---------|--------|------------|
| Angel / Seed investors | Full KYC + accredited verification | Jumio | Reg D 506(c) |
| IEO participants | Exchange-standard KYC | Binance/Coinbase platform | Exchange compliance |
| Public IDO participants | Wallet geo-block + OFAC screen | Chainalysis | Regulation S |
| Node operators (global) | Wallet verification + sanctions screen | Synaps | Smart contract agreement |

### 20.6 Mandatory Legal Documents Before TGE

1. Token Disclosure Document (TDD) — SEC Safe Harbor 2.0 required filing
2. Regulation D 506(c) filing — within 15 days of first Seed close
3. SAFT (Simple Agreement for Future Tokens) — for Angel and Seed investors
4. Terms of Token Sale — governs public IDO participation
5. Node Operator Agreement — smart contract terms, incorporated by reference
6. DAO Governance Charter — documents veCMXS voting rights and procedures

---

## 21. Corporate Structure

### 21.1 Dual-Entity Structure

| Entity | Jurisdiction | Role |
|--------|-------------|------|
| **CMXS Foundation Ltd.** | Cayman Islands (Exempted Company) | Token issuer; holds Foundation Treasury; publishes TDD; manages ICO |
| **CMXS Labs Inc.** | Delaware, USA | Technology developer; employs engineering team; receives development grants |
| **Node Operator Agreement** | Base L2 smart contract | On-chain binding terms for all node participants |

This structure mirrors the proven dual-entity model used by **Helium** (Helium Foundation + Nova Labs), **Filecoin** (Filecoin Foundation + Protocol Labs), and **Render Network** (Render Foundation + OTOY Inc.).

### 21.2 Recommended Legal Counsel

- **Cayman entity:** Ogier or Carey Olsen (DePIN-experienced, Cayman-based)
- **US securities:** Perkins Coie or Cooley (active crypto/DePIN practices)
- **Smart contract audit:** Trail of Bits (6-week minimum engagement for full suite)

---

## 22. Development Roadmap

### 22.1 ICO Implementation Timeline

| Month | Milestone | Deliverable |
|-------|----------|------------|
| M1 | Legal entity formation | Cayman Foundation registered; Delaware Inc. formed |
| M1 | Smart contract audit engaged | Trail of Bits or CertiK engagement signed |
| M2 | Token Disclosure Document | TDD filed with SEC Safe Harbor; published at cmxs.network/tdd |
| M2 | Angel round close | USD 1M–2M SAFE closed |
| M3 | Seed round opens | Reg D 506(c) filing; CoinList KYC portal live |
| M4 | Seed round closes | USD 3M–5M; Base mainnet contracts deployed |
| M4 | Phase 0 demo published | Benchmark data: <500ms delivery, x402 settlement, PoD minting live |
| M5 | IEO application submitted | Applications to Binance Launchpad, Coinbase Ventures, Kraken |
| M6 | IEO launch | USD 8M–15M strategic round via partner exchange |
| M6 | CMXS mainnet launch | All contracts deployed; vesting vaults funded |
| M7 | TGE / Public IDO | Fjord Foundry LBP + Uniswap v4 + CEX listing |
| M8 | Phase 1: 500 nodes | Tower JV initial nodes activated; first commercial campaigns |
| M12 | Governance launch | veCMXS voting activated; first DAO proposal |

### 22.2 Product Development Phases

**Phase 0 (Complete — Q2 2026): Proof of Concept**
- AWS-hosted MoQ relay + CE-MoQ integration
- x402 settlement on Base Sepolia testnet
- CMXS ERC-20 on Base Sepolia with PoD minting
- Benchmark achieved: **287ms P50, 312ms P95** delivery latency
- Dashboard with real-time on-chain delivery log

**Phase 1 (Q3–Q4 2026): Production Launch**
- 500 physical nodes (tower JV initial cohort)
- x402 live on Base mainnet (real USDC)
- First commercial campaigns at USD 45 CPM verified floor
- Chainlink CRE replacing trusted-signer oracle
- veCMXS governance contract deployed

**Phase 2 (2027): Scale**
- 2,000 nodes (tower JV + independent TowerCo partners)
- Live sports betting B2B licensing pilot (3–5 licensed operators)
- Multi-use-case protocol expansion (PPV, live auction streams)
- USD 42M–84M ARR target
- Implied FDV: USD 420M–840M (at 10× revenue multiple)

**Phase 3 (2028): Protocol Generalisation**
- 10,000 nodes nationwide
- AI agent per-delivery bidding (autonomous DSP via x402)
- Full DAO governance transition (Foundation veto dissolved)
- IoT telemetry and AI data feed delivery use cases live
- USD 84M–144M ARR target

---

## 23. Risk Factors

### 23.1 Technology Risks
- **MoQ Standardisation:** IETF draft-ietf-moq-transport is not yet an RFC. Breaking changes in final standardisation could require protocol updates
- **Caton C3 Dependency:** CMXS's sub-500ms guarantee depends on licensing Caton's C3/CVP SDK. A licensing failure could affect the transport layer
- **Smart Contract Vulnerability:** Despite audits, undiscovered vulnerabilities may exist. Daily mint cap limits catastrophic exposure to 0.288% of supply per 24 hours
- **Oracle Centralisation (Phase 0):** Trusted-signer oracle is a single point of failure until Chainlink CRE migration in Phase 1
- **Chainlink CRE Adoption:** Chainlink CRE is newly production-launched (November 2025). Enterprise-scale adoption is early-stage

### 23.2 Market Risks
- **Token Price Volatility:** CMXS is subject to extreme price volatility. Tokens may lose all value
- **DePIN Competition:** Well-funded new DePIN video delivery projects may emerge. Existing players (Livepeer, Theta) could pivot toward verified delivery
- **Ad Spend Cyclicality:** Digital advertising is cyclical. A macroeconomic recession reduces ad volumes and CMXS burn rate
- **BME Imbalance:** If node growth significantly outpaces service demand, mint rate may temporarily exceed burn rate, creating downward price pressure

### 23.3 Regulatory Risks
- **SEC Reclassification:** The March 2026 interpretive release could be reversed or modified. CMXS could be reclassified as a security, requiring registration
- **MiCA Enforcement:** EU MiCA enforcement could impose additional compliance costs or restrict EU distribution
- **Tax Treatment Changes:** IRS reclassification of PoD rewards could affect node operator economics

### 23.4 Operational Risks
- **Infrastructure JV Execution:** The tower conversion JV is a commercial negotiation. Failure to close would require CMXS Labs to deploy independent node hardware at higher cost and longer timeline
- **Node Operator Adoption:** Insufficient node operators would prevent BME equilibrium
- **Key Personnel Concentration:** Loss of key team members could delay development milestones
- **x402 Protocol Risk:** x402 is recently released. Adoption requires maturing wallet infrastructure

---

## 24. Legal Disclaimer

This White Paper is published by CMXS Foundation Ltd. for informational purposes only. It does not constitute: (a) an offer or solicitation to sell securities or any other regulated financial instrument; (b) investment advice; (c) a prospectus or offering memorandum; or (d) legal, tax, or financial advice.

**CMXS tokens are utility tokens** designed for functional use within the CMXS DePIN network. They are not designed or intended to constitute a security, commodity, or regulated investment product in any jurisdiction.

**Forward-looking statements** in this document are based on current expectations and assumptions. Actual results, performance, or events may differ materially from those expressed or implied.

**United States:** CMXS tokens are offered only to accredited investors in the Angel and Seed rounds under SEC Regulation D Rule 506(c). Public IDO participation is not available to U.S. retail investors. Nothing herein constitutes investment advice or a solicitation of investment.

**European Union:** This White Paper will be filed with the relevant National Competent Authority under MiCA before any public offering in EU member states. No representations are made regarding investment returns.

**OFAC Compliance:** CMXS Foundation will not sell tokens to individuals, entities, or wallets associated with OFAC-sanctioned jurisdictions.

**No Guarantee of Value:** CMXS Foundation makes no representation regarding the future value of CMXS tokens. Token purchasers may lose their entire investment. Cryptocurrency markets are highly volatile.

**Intellectual Property:** The CMXS protocol and smart contracts are the intellectual property of CMXS Labs Inc. Smart contracts are open-source (MIT License). The Caton C3 transport technology is proprietary to Caton Technology Group and licensed to CMXS Labs Inc.

---

*CMXS Foundation Ltd. | Grand Cayman, Cayman Islands*
*CMXS Labs Inc. | Delaware, USA*
*White Paper Version 3.0 | May 2026*
*Token Disclosure Document: Filed under SEC Safe Harbor 2.0 (pending)*
*Smart Contract Audit: Trail of Bits engagement (pending)*
*Exchange Listing Applications: Binance Launchpad, Coinbase Ventures, Kraken Ventures (pending)*

*© 2026 CMXS Foundation Ltd. This document may be freely distributed with attribution.*

