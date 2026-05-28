# CMXS Token White Paper
## CatonMX Settlement Token — Decentralised Physical Infrastructure Network

**Version 2.0 | May 2026**
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
2. The DePIN Market Opportunity
3. The Problem: Unverified, Centralised Delivery Infrastructure
4. The CMXS Network Architecture
5. Transport Layer: QUIC / MoQ Protocol
6. Payment Layer: x402 Per-Delivery Micropayment Protocol
7. Proof-of-Delivery (PoD) Consensus Mechanism
8. CMXS Token Design and Optimised Structure
9. Burn-and-Mint Equilibrium (BME) Model
10. Token Allocation and Vesting Schedule
11. Staking Architecture
12. Smart Contract Reference Implementation
13. Governance: veToken Model
14. ICO Framework and Capital Raise Structure
15. Use of Proceeds
16. Network Expansion and Use Case Roadmap
17. Competitive Benchmarking
18. Financial Projections
19. Regulatory Compliance Framework
20. Corporate Structure
21. Development Roadmap
22. Risk Factors
23. Legal Disclaimer

---

## 1. Executive Summary

CMXS is a Decentralised Physical Infrastructure Network (DePIN) token that coordinates a global network of edge nodes delivering time-critical digital content — beginning with the verified delivery of digital advertising over broadcast-grade transport infrastructure. The CMXS token (ticker: **CMXS**) is the settlement and incentive layer of this network: node operators earn CMXS for verified delivery; service buyers burn CMXS to access premium, auditable delivery slots; and token holders govern network parameters through a vote-escrowed (veToken) model.

The network is underpinned by three open-standard technologies operating in combination for the first time at commercial scale:

- **Caton C3 / QUIC / MoQ transport** — delivering content at sub-500ms end-to-end latency, eliminating the structural black-screen delays inherent in legacy TCP/HLS infrastructure, as validated at the 2024 Paris Olympics (16 HD feeds, 17 days, zero errors).
- **x402 HTTP-native micropayment protocol** (Coinbase, May 2025) — enabling per-delivery USDC settlement at USD 0.0001 per transaction on Base L2, creating an immutable, on-chain receipt for every delivery.
- **ERC-8004-derivative on-chain SLA proofs** — writing a cryptographic proof-of-delivery to Base L2 for every verified delivery event, providing first-ever cryptographic audit trail for digital content delivery.

The network launches with a significant structural advantage over all prior DePIN projects: **pre-existing physical infrastructure**. The initial node layer is anchored by a joint venture converting a portion of **5,800 existing EchoStar broadcast towers** into CMXS-earning edge nodes — eliminating the cold-start infrastructure problem that required Helium and Hivemapper to bootstrap supply from zero.

The initial commercial use case is **verified digital advertising delivery** for connected TV (CTV) and streaming platforms — a USD 40.2 billion market with documented, structural failures in delivery verification, latency, and fraud prevention. This use case is one of multiple planned applications of the CMXS protocol; the same infrastructure, transport stack, and token settlement layer apply to any time-critical, verifiable content delivery scenario including live sports betting infrastructure, pay-per-view content, IoT telemetry, and real-time AI agent data feeds.

**ICO Target: USD 18M–33M** across four structured stages, with an initial fully diluted valuation (FDV) of USD 100M at Token Generation Event (TGE).

---

## 2. The DePIN Market Opportunity

### 2.1 What is DePIN?

Decentralised Physical Infrastructure Networks (DePIN) use blockchain token incentives to coordinate the deployment and operation of real, physical infrastructure — replacing centralised cloud providers and CDN operators with a distributed network of independently operated nodes.

The key distinction from pure software blockchain projects: DePIN tokens are backed by **real-world physical work**. A DePIN token is earned by operating hardware that performs a measurable, verifiable service — not by staking capital or solving abstract mathematical puzzles. This alignment of token rewards with physical work is why DePIN has emerged as the most institutionally credible category of crypto infrastructure in 2025–2026.

### 2.2 Market Scale

| Metric | Value | Source |
|---|---|---|
| Global DePIN market size (2026) | USD 3.5B | Intel Market Research |
| Global DePIN market projection (2033) | USD 145.9B | Intel Market Research |
| DePIN ICO fundraising (Q1 2025 alone) | USD 4.8B | Industry data |
| Average DePIN ICO raise | USD 14.7M | CoinLaw / MEXC 2026 |
| DePIN ICOs outperform general ICO average | 3× per-project | Blockchain App Factory 2026 |

DePIN is raising 3× more per project than the overall ICO average because institutional investors have learned from Helium, Render, and Hivemapper that physical infrastructure provides a valuation floor that pure-software tokens lack: if the token price drops below the economic value of the work the network performs, rational operators exit — and if enough exit, the network contracts. This self-regulating property makes DePIN tokenomics structurally more defensible than software tokens.

### 2.3 The Verified Delivery Gap

The specific opportunity CMXS addresses is the **complete absence of cryptographic proof-of-delivery** in digital content infrastructure. Today:

- Digital advertising is bought and sold on self-reported metrics with no independent audit trail.
- Content delivery networks (CDNs) provide service-level agreements (SLAs) in contractual form only — there is no on-chain, tamper-proof record of delivery.
- The consequence: Morgan Stanley estimates 30% more digital ad inventory is sold than is actually delivered; DoubleVerify's 2025 Global Insights Report documented a 140% surge in connected TV ad fraud; the IAB Tech Lab's CTV Signal Integrity Framework (October 2025) explicitly calls for cryptographic delivery receipts as the long-term industry solution.

CMXS is the first DePIN protocol designed specifically to address this gap — making every delivery event an immutable on-chain fact.

---

## 3. The Problem: Unverified, Centralised Delivery Infrastructure

The digital delivery infrastructure underpinning streaming, advertising, live events, and real-time data services has three compounding structural failures:

### 3.1 The Latency Problem

Legacy content delivery relies on HLS (HTTP Live Streaming) over TCP (Transmission Control Protocol). HLS delivers content in segments of 2–10 seconds each. Every time a delivery decision must be made mid-stream — inserting an ad, switching to a different content source, or handling a pay-per-view gate — the TCP connection must tear down, reconnect, and buffer a new segment. This creates mandatory delays of 1.5–10 seconds that are not software bugs but **structural limitations of the TCP/HLS protocol combination**.

The consequence extends beyond viewer experience: any application requiring sub-500ms end-to-end synchronisation — including live sports betting infrastructure, real-time financial data feeds, and autonomous AI agent decision-making — is structurally excluded from HLS-based platforms.

### 3.2 The Proof Problem

No current CDN or content delivery infrastructure provides cryptographic proof that a specific piece of content was delivered to a specific device at a specific time. Buyers of digital advertising, pay-per-view access, or data delivery pay based on platform-reported metrics — fundamentally an honour system.

This creates a USD 84 billion annual global ad fraud problem (Business of Apps, 2026) and a complete inability to command the 2× CPM premium that verified delivery commands in programmatic markets (USD 45–65 CPM verified vs. USD 18–30 CPM unverified, per PubMatic / Magnite 2025 CTV Marketplace Reports).

### 3.3 The Revenue Distribution Problem

In today's centralised CDN model, the operators of physical infrastructure — tower owners, co-location facility operators, fibre network providers — receive flat lease income regardless of how much revenue flows through their infrastructure. The economic value created by their hardware accrues entirely to the platform layer above them.

This misalignment has two consequences:
1. Infrastructure operators have no incentive to upgrade, expand, or optimise beyond the minimum required by their lease contract.
2. The total addressable market for infrastructure-layer participation in the digital economy is effectively zero for physical asset owners.

CMXS resolves all three failures simultaneously through the combination of QUIC/MoQ transport (latency), x402 per-delivery micropayment + ERC-8004 SLA proofs (proof), and the Proof-of-Delivery (PoD) token reward mechanism (revenue distribution).

---

## 4. The CMXS Network Architecture

The CMXS network operates as a three-layer stack. Each layer is defined by open standards with no proprietary lock-in at any layer except the Caton C3 transport enhancement:

```
╔══════════════════════════════════════════════════════════════════╗
║  LAYER 3 — APPLICATION / CLIENT SURFACE                         ║
║  Any QUIC-capable consumer device                               ║
║  Chrome / Edge / Safari (WebTransport)                          ║
║  Smart TV, Mobile App, Set-Top Box                              ║
║  Player SDK: MoQ WebTransport client (moq-js / moq-rs)          ║
║  Payment client: x402fetch + Coinbase Smart Wallet (EIP-4337)   ║
╠══════════════════════════════════════════════════════════════════╣
║  LAYER 2 — CMXS PROTOCOL MIDDLEWARE                             ║
║  Caton Enhanced MoQ (CE-MoQ) Relay                              ║
║  Per-delivery Auction Engine (sub-100ms decisioning)            ║
║  x402 Payment Gateway (Coinbase x402 v1.0)                      ║
║  NetScope Telemetry + SLA Oracle                                ║
║  CMXS Smart Contracts on Base L2                                ║
║  Chainlink CRE oracle (Phase 1+)                                ║
╠══════════════════════════════════════════════════════════════════╣
║  LAYER 1 — PHYSICAL NODE LAYER                                  ║
║  5,800 EchoStar broadcast towers (JV — initial anchor)          ║
║  + Independent TowerCo partners (Phase 1+)                      ║
║  + Cloud VM nodes (Phase 0 / developer nodes)                   ║
║  Each node runs:                                                ║
║    — CE-MoQ Relay daemon                                        ║
║    — x402 Facilitator                                           ║
║    — CMXS NodeRegistry staking contract interaction             ║
╚══════════════════════════════════════════════════════════════════╝
```

### 4.1 End-to-End Delivery Flow (One Verified Event)

The following is the complete data flow for a single verified delivery event — the atomic unit from which all CMXS network economics derive:

```
Step 1:  Client device subscribes to content Track via MoQ SUBSCRIBE message
Step 2:  Layer 2 relay receives delivery request — auction engine runs (≤80ms)
Step 3:  Content/ad object delivered as MoQ Objects over QUIC (no HLS wait)
Step 4:  Client stitches at frame boundary — zero latency gap
Step 5:  HTTP 402 fires — x402 micropayment (USDC) sent per delivery
Step 6:  x402 Facilitator (Coinbase) confirms payment on Base L2
Step 7:  NetScope telemetry records delivery timestamp + latency
Step 8:  SLA Oracle checks: was latency <500ms? Was delivery cryptographically verified?
Step 9:  If SLA met → DeliveryOracle.sol emits DeliveryProofAccepted event
Step 10: CMXS.rewardNode() mints 0.001 CMXS to the node operator's wallet
Step 11: SLA proof written on-chain (ERC-8004 derivative) — permanently auditable
Step 12: Service buyer's dashboard reflects new verified delivery + txHash
```

This 12-step flow is the CMXS Proof-of-Delivery cycle. Every step is executed by open-standard software with no centralised authority controlling any individual step.

---

## 5. Transport Layer: QUIC / MoQ Protocol

### 5.1 Why QUIC Replaces TCP for Delivery Infrastructure

QUIC (RFC 9000, standardised 2021) is a multiplexed transport protocol that operates over UDP rather than TCP. The critical difference for delivery infrastructure:

| Property | TCP (legacy) | QUIC |
|---|---|---|
| Connection setup | 1–3 RTT handshake | 0–1 RTT (0-RTT resumption) |
| Stream isolation | Head-of-line blocking | Independent streams, no blocking |
| Delivery switching | Requires connection teardown | New stream, existing connection |
| Encryption | Optional (TLS overlay) | Mandatory (TLS 1.3 integrated) |
| Black screen on switch | 1.5–10 seconds | 0ms (same-connection stream switch) |
| Sports betting synchronisation | 5–30s behind live | Sub-500ms — clears regulatory threshold |

The QUIC advantage for CMXS is specifically the **independent stream multiplexing**: a delivery switch (ad insertion, pay-per-view gate, data feed update) is a new `SUBSCRIBE` message on the same open QUIC connection — not a TCP teardown. This eliminates the structural source of delivery gaps at the protocol level, not as a software patch.

### 5.2 MoQ (Media over QUIC) Object Delivery Model

MoQ (IETF draft-ietf-moq-transport, currently draft-08) defines an object-based publish/subscribe delivery model over QUIC, replacing segment-based HLS:

| MoQ Concept | Definition | Significance for CMXS |
|---|---|---|
| **Track** | One logical stream (e.g., `cmxs/live/content` or `cmxs/live/slot-3`) | Delivery switching = new Track subscription |
| **Group** | One GOP (Group of Pictures) — the unit of seeking | Defines the minimum unit for latency measurement |
| **Object** | One encoded frame or frame group | The unit of delivery — basis for per-delivery payment |

The key insight: **delivery switching in MoQ is a Track re-subscription, not a protocol operation requiring connection teardown.** The client can have two Track subscriptions open simultaneously during a transition, ensuring zero-gap switching. This is fundamentally different from HLS, where the segment boundary is a hard synchronisation requirement.

### 5.3 Caton Enhanced MoQ (CE-MoQ)

The Caton C3 SDK augments the base MoQ specification with:

- **Multi-path AI routing (CVP — Caton Video Protocol):** Dynamically selects the lowest-latency path across available connections (fibre, 5G, satellite) in real time, achieving sub-500ms delivery even under 30% packet loss conditions.
- **CTP (Caton Transport Protocol):** Forward error correction (FEC) for packet-loss recovery — critical for maintaining delivery continuity over heterogeneous mobile and satellite backhaul.
- **NetScope telemetry:** Real-time latency measurement per delivery event — this is the raw data that feeds the SLA Oracle for CMXS PoD reward calculations.

**Paris Olympics 2024 validation:** Caton's C3 technology delivered 16 simultaneous HD feeds across 17 consecutive days at the Paris Olympics with zero delivery errors and an AI-managed average of 3,580 path switches per day. This is the most rigorous broadcast-grade transport validation available for any DePIN infrastructure project.

### 5.4 WebTransport Browser Support (May 2026)

MoQ/WebTransport is now **Baseline Widely Available** as of 2026: supported natively in Chrome 97+, Firefox 114+, Edge 97+, and Safari 18+. No browser extension or plugin is required. QUIC-based delivery is available to 98%+ of global browser users without any software installation.

---

## 6. Payment Layer: x402 Per-Delivery Micropayment Protocol

### 6.1 What is x402?

x402 (Coinbase, released May 2025) is an HTTP-native micropayment standard that repurposes the long-reserved HTTP 402 "Payment Required" status code as a machine-readable payment request:

```
1. Client requests delivery → Server returns HTTP 402 + payment requirements
2. Client wallet signs payment payload (EIP-712 structured data)
3. Client retries request with X-PAYMENT header containing signed payload
4. x402 Facilitator (Coinbase REST API) verifies + settles on Base L2
5. Server receives payment confirmation → fulfils delivery → writes SLA proof
```

The entire payment cycle completes in under 2 seconds on Base L2, at a gas cost of USD 0.0001 per transaction — making per-delivery settlement economically viable at any delivery volume above 1,000 events/day.

### 6.2 x402 Server Implementation (TypeScript Reference)

```typescript
// Node-side x402 middleware (Express / Fastify compatible)
import { paymentMiddleware } from 'x402-express';
import { evm } from 'x402-evm';

app.use(paymentMiddleware(
  NODE_OPERATOR_WALLET_ADDRESS,
  {
    '/api/delivery-request': {
      price: '0.0001',            // 0.0001 USDC per delivery event
      network: 'base',            // Base L2 mainnet
      description: 'CMXS verified delivery slot'
    },
    '/api/sla-proof': {
      price: '0.00001',           // SLA proof write (minimal)
      network: 'base',
    }
  },
  evm,
  {
    facilitatorUrl: 'https://x402.org/facilitator',
    onSuccess: async (req, res, paymentInfo) => {
      const { transaction: txHash, from: payer, amount } = paymentInfo;
      // Write SLA proof on-chain
      await writeSLAProof(txHash, req.params.deliveryId, Date.now());
      // Trigger CMXS node reward via oracle
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

### 6.3 x402 Client Implementation (TypeScript Reference)

```typescript
// Client-side automatic payment (browser or AI agent)
import { wrapFetch } from 'x402-fetch';
import { evm } from 'x402-evm';

// Initialize with Coinbase Smart Wallet (EIP-4337 — no extension required)
const x402Fetch = wrapFetch(fetch, evm, { wallet: smartWalletClient });

// Single call handles the complete 402→sign→retry flow
const response = await x402Fetch(
  'https://cmxs-node.network/api/delivery-request',
  { method: 'GET', headers: { 'X-Delivery-Session': sessionId } }
);
// If 402: wallet signs, payment settles on-chain, request retried automatically
const { deliveryTrack, txHash } = await response.json();
```

### 6.4 Why x402 Is the Optimal Payment Layer for CMXS

| Property | x402 | Lightning Network | Stripe / Fiat | Custom Smart Contract |
|---|---|---|---|---|
| Per-delivery granularity | ✅ Native | ✅ Native | ❌ Batch only | ✅ Possible |
| AI agent native | ✅ HTTP-native | ⚠️ Requires node | ❌ API keys | ⚠️ ABI calls |
| No account required | ✅ Wallet only | ⚠️ Channel setup | ❌ Account required | ✅ Wallet only |
| Instant settlement | ✅ 2s Base L2 | ✅ Off-chain instant | ❌ T+1 or T+2 | ✅ On-chain |
| Gas cost per tx | USD 0.0001 | ~USD 0.00001 | N/A | USD 0.001–1 |
| Coinbase ecosystem | ✅ Native | ❌ | ❌ | ⚠️ Partial |
| Open standard | ✅ Coinbase + Cloudflare | ✅ | ❌ Proprietary | ❌ |

x402 is chosen because it is **AI-agent native** — autonomous software agents (Phase 3 CMXS use case) can participate in per-delivery auctions without human intervention, simply by having an x402-capable wallet. This is not possible with traditional payment rails.

---

## 7. Proof-of-Delivery (PoD) Consensus Mechanism

### 7.1 Why PoD, Not PoW or PoS

The CMXS network requires a consensus mechanism that rewards nodes for **performing the actual work the network needs** — not for burning energy on irrelevant computations (PoW) or for having accumulated capital (PoS). The comparison:

| Mechanism | How Rewards Are Earned | Fit for CMXS |
|---|---|---|
| **Proof-of-Work (PoW)** | Solving cryptographic puzzles — irrelevant to delivery | ❌ Energy waste; no delivery benefit |
| **Proof-of-Stake (PoS)** | Holding/staking tokens — rewards capital, not work | ❌ Rich-get-richer; misaligned with infrastructure |
| **Proof-of-Delivery (PoD)** | Completing verified deliveries below latency SLA | ✅ Rewards nodes for the exact work the network needs |

PoD is the DePIN-standard consensus approach: Helium uses Proof-of-Coverage (radio coverage verified by peers), Hivemapper uses Proof-of-Drive (map coverage verified by GPS + image analysis), DIMO uses Proof-of-Contribution (vehicle telemetry verified by on-board devices). CMXS uses **Proof-of-Delivery**: content delivery verified by cryptographic receipt, on-chain payment, and latency measurement.

### 7.2 The PoD Cycle in Detail

```
┌─────────────────────────────────────────────────────────────┐
│  PROOF-OF-DELIVERY CYCLE — ONE DELIVERY EVENT               │
│                                                             │
│  1. NODE delivers content object via QUIC/MoQ               │
│     └→ Latency measured by NetScope: T_delivery             │
│                                                             │
│  2. CLIENT generates Delivery Receipt                       │
│     └→ { segmentHash, T_delivery, playerWallet, latencyMs } │
│     └→ Signed by player wallet (unforgeable)                │
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

### 7.3 PoD Security Properties

The PoD design must resist three attack vectors:

**Attack 1: Fake Delivery (Sybil)**
*Attack:* Node claims to have delivered content it did not deliver.
*Defense:* Delivery receipt must be signed by the **client wallet** (not the node). A node cannot forge a client signature. The x402 payment on-chain provides an independent second confirmation that a delivery request was received and paid for.

**Attack 2: Replay Attack**
*Attack:* Node resubmits the same valid delivery proof multiple times to claim multiple rewards.
*Defense:* Every `deliveryId` is stored in a `mapping(bytes32 => bool) public usedNonces` mapping in `DeliveryOracle.sol`. A resubmitted `deliveryId` is rejected with `"Proof already used"`.

**Attack 3: Oracle Compromise**
*Attack:* Attacker compromises the trusted-signer oracle key and mints CMXS without real deliveries.
*Defense:* Hardcoded `MAX_DAILY_MINT = 2,880,000 CMXS/day` in the token contract. Even a complete oracle compromise cannot mint more than **0.288% of total supply** in any 24-hour window. Migration path to Chainlink CRE (Phase 1) eliminates the trusted-signer dependency entirely.

**Attack 4: Latency Spoofing**
*Attack:* Node reports false latency measurements below the 500ms threshold.
*Defense:* Latency is measured independently by NetScope telemetry on the client side and cross-referenced with the x402 payment timestamp. Both measurements must be consistent within a tolerance window. Client-side measurement cannot be manipulated by the node.

### 7.4 PoD vs. Comparable DePIN Mechanisms

| Network | Mechanism | Verification Method | CMXS Equivalent |
|---|---|---|---|
| Helium | Proof-of-Coverage | Peer radio challenge/response | Cryptographic delivery receipt |
| Hivemapper | Proof-of-Drive | GPS track + image hash | x402 payment + latency timestamp |
| DIMO | Proof-of-Contribution | OBD telemetry + device attestation | NetScope telemetry + oracle signature |
| **CMXS** | **Proof-of-Delivery** | **Client ECDSA receipt + x402 + latency oracle** | — |

---

## 8. CMXS Token Design and Optimised Structure

### 8.1 Design Principles

The CMXS token design is optimised against four criteria, derived from post-mortems of all major DePIN token launches (Helium, Filecoin, Render, Hivemapper, DIMO, Akash):

1. **Token utility must precede token speculation.** CMXS has functional use (earning delivery rewards, burning for delivery priority, governance staking) before, during, and independent of any price appreciation.
2. **Supply must be algorithmically self-regulating.** No discretionary mint authority. Supply is controlled entirely by the Proof-of-Delivery rate (real network activity) and the burn rate (real service demand).
3. **Team and investor incentives must be structurally aligned with network health.** Long cliff periods and linear vesting ensure team tokens vest only as the network grows.
4. **Regulatory clarity.** Post-March 2026 SEC taxonomy, CMXS is designed as a "digital tool" — a functional access credential and work-reward instrument, with rewards determined by protocol rules rather than managerial discretion.

### 8.2 Complete Token Specification

| Parameter | Value | Rationale |
|---|---|---|
| Token Name | CatonMX Settlement Token | Full name for regulatory filings |
| Ticker | CMXS | Short, memorable, exchange-compliant |
| Token Standard | ERC-20 on Base L2 | USD 0.0001/tx gas; x402 native; Coinbase ecosystem |
| Total Supply | **1,000,000,000** (1 billion) fixed | Fixed cap; sufficient for 10+ years of PoD rewards at max scale |
| Decimals | 18 | ERC-20 standard |
| Initial Circulating Supply | 150,000,000 (15%) | Industry best practice: limit float at TGE to control price discovery |
| Mint Authority | `DeliveryOracle.sol` only | No team mint capability post-TGE; verified by audit |
| Burn Authority | Public (`burn()` callable by any holder) | Transparent; verifiable on-chain |
| Max Daily Mint Rate | 2,880,000 CMXS/day | Safety cap: 2,000 nodes × 1,440 deliveries/day × 0.001 CMXS |
| PoD Reward Rate | 0.001 CMXS per verified delivery | Calibrated to USD ~0.10/day per node at USD 100 token price |
| Blockchain | Base L2 (Coinbase / OP Stack) | x402 native; gasless advertiser experience (EIP-4337); Coinbase institutional relationships |
| Contract Framework | Foundry + OpenZeppelin v5 | Industry-standard security framework |
| Audit Requirement | Trail of Bits or CertiK (pre-TGE mandatory) | Institutional investor requirement |

### 8.3 Why Base L2 Is the Optimal Chain

The choice of Base L2 is not arbitrary — it is determined by the x402 protocol dependency:

- **x402 is Coinbase-native.** The x402 facilitator (`https://x402.org/facilitator`) is a Coinbase-operated REST endpoint. Using Base L2 means the payment settlement and the token reward are on the same chain with the same gas economics.
- **USD 0.0001 gas per transaction** makes per-delivery settlement economically viable at any delivery volume. On Ethereum mainnet (USD 3–50/tx), per-delivery settlement is economically impossible.
- **EIP-4337 Smart Wallet** (Coinbase Smart Wallet) allows advertisers and service buyers to interact with CMXS contracts **without holding ETH for gas** — a critical onboarding requirement for non-crypto-native enterprise buyers.
- **Coinbase institutional relationships** — Base L2 positions CMXS for Coinbase Ventures partnership and Coinbase Exchange listing, both critical for institutional ICO credibility.

---

## 9. Burn-and-Mint Equilibrium (BME) Model

### 9.1 The BME Mechanism

Burn-and-Mint Equilibrium (pioneered by Helium's HNT token, confirmed as the DePIN tokenomics standard by Frontiers in Blockchain peer-reviewed research, 2025) creates a self-regulating token supply tied algorithmically to real network activity.

**BURN SIDE — Demand Creates Scarcity:**
```
Service buyer requests verified delivery slot
  → Pays USDC via x402 micropayment
  → x402 Facilitator routes fee to CMXS Foundation treasury
  → Treasury burns CMXS proportional to payment value
  → More service demand → more CMXS burned → circulating supply ↓
  → Reduced supply → upward price pressure (all else equal)
```

**MINT SIDE — Work Creates Supply:**
```
Node operator completes verified delivery (latency <500ms)
  → DeliveryOracle.sol calls CMXS.rewardNode()
  → 0.001 CMXS minted to node operator wallet
  → More deliveries → more CMXS minted → circulating supply ↑
```

**EQUILIBRIUM:**
```
burn rate > mint rate  →  supply ↓  →  price ↑
  → more nodes join (attracted by higher CMXS value)
  → mint rate ↑  →  equilibrium restores

mint rate > burn rate  →  supply ↑  →  price ↓
  → marginal nodes exit (economics no longer justify hardware)
  → mint rate ↓  →  equilibrium restores
```

### 9.2 Four Independent Demand Engines

A key structural advantage of CMXS over single-use-case DePIN tokens: CMXS has **four independent mechanisms** generating token demand. Any one is sufficient for sustainable utility; together they create compounding demand pressure.

| Demand Engine | Token Mechanism | Economic Driver |
|---|---|---|
| **PoD Node Rewards** | 0.001 CMXS minted per verified delivery | Network growth → need for burns to fund expanding rewards |
| **x402 Burn** | Service buyers burn CMXS to access verified delivery priority | Service demand growth = direct token burn |
| **SLA Staking Premium** | Nodes stake CMXS for priority routing and premium delivery slots | Staking reduces circulating supply |
| **veToken Governance** | veCMXS (locked CMXS) required for governance participation | Long-term holders lock supply for 1–4 years |

### 9.3 BME Stability Properties

The BME model has three properties that make it uniquely stable compared to fixed-supply or inflationary token models:

1. **Anti-fragile to demand growth.** Rising service demand burns more tokens, which supports price, which attracts more node operators, which increases service quality, which attracts more demand. This is a positive feedback loop.

2. **Self-correcting against supply inflation.** If too many nodes join simultaneously (oversupply), CMXS price falls, marginal nodes exit, and the mint rate naturally decreases without any manual intervention.

3. **No discretionary authority.** The BME parameters (reward rate, burn rate, daily mint cap) are set in immutable smart contracts. No team, foundation, or DAO vote can trigger an emergency mint. The DAO can vote to *change parameters going forward*, but cannot retroactively mint tokens.

---

## 10. Token Allocation and Vesting Schedule

### 10.1 Full Token Distribution Table

| Category | Allocation | Tokens (CMXS) | TGE Unlock | Vesting |
|---|---|---|---|---|
| **Node Rewards Pool (PoD)** | 35% | 350,000,000 | 0% | Minted on-demand via PoD; daily safety cap applies |
| **Foundation Treasury** | 20% | 200,000,000 | 0% | 6-month cliff; 24-month linear |
| **Ecosystem Grants** | 15% | 150,000,000 | 0% | 12-month cliff; 36-month linear |
| **Seed / Strategic Round** | 10% | 100,000,000 | 0% | 12-month cliff; 36-month linear |
| **Public ICO** | 10% | 100,000,000 | 20% | 80% over 12 months linear |
| **Team & Advisors** | 8% | 80,000,000 | 0% | 12-month cliff; 48-month linear |
| **Liquidity Provision** | 2% | 20,000,000 | 100% | Unlocked at TGE for DEX/CEX seeding |
| **TOTAL** | **100%** | **1,000,000,000** | — | — |

### 10.2 Vesting Rationale

**35% Node Rewards Pool:** Matches Helium's proportional node reward commitment — the industry benchmark for infrastructure-first DePIN tokens. Minted on-demand rather than pre-allocated ensures rewards are not dilutive before work is performed.

**12-month cliff + 48-month linear for Team/Advisors:** The 2026 institutional investor standard. Any cliff shorter than 12 months is a known red flag in DePIN due diligence — it signals low team conviction and creates dump pressure at listing.

**12-month cliff + 36-month linear for Investors:** Ensures seed investors cannot exit at TGE, aligning their interests with Phase 1 network growth.

**20% TGE for Public ICO participants:** Provides immediate liquidity for public participants while preventing dump pressure through 80% 12-month linear.

**2% Liquidity Provision unlocked at TGE:** Minimum required to seed Uniswap v4 pool and one CEX pair. This is deliberately constrained — larger liquidity unlocks at TGE have historically led to immediate arbitrage selling.

### 10.3 Infrastructure JV Vesting (EchoStar Tower Operators)

Tower infrastructure operators contributing physical nodes to the CMXS network receive Ecosystem Grant CMXS on a milestone-based schedule designed to align incentives with network health:

| Milestone | % of JV Allocation Unlocked | Condition |
|---|---|---|
| M1 — Node installation | 25% | Node registered and verified on-chain via `NodeRegistry.sol` |
| M2 — First 50 deliveries | 25% | 50 PoD events logged with `slaMet = true` |
| M3 — 12-month uptime | 25% | >95% uptime over 12 consecutive months |
| M4 — 36-month participation | 25% | Node active and staked at 36-month mark |

---

## 11. Staking Architecture

CMXS staking has three distinct tiers, each serving a different network function:

### 11.1 Tier 1 — Node Operator Bond (Sybil Protection)

Every node must stake a minimum CMXS amount to activate PoD reward eligibility. This stake is the node's economic commitment to honest behaviour — losing it through slashing is the cost of cheating.

| Parameter | Value | Rationale |
|---|---|---|
| Minimum stake per node | 1,000 CMXS | ~USD 100 at initial FDV — low enough not to exclude small operators |
| Slash condition | 3 failed delivery proofs in 24 hours | Three-strike rule prevents accidental slashing from network issues |
| Slash penalty | 10% of staked amount | Meaningful deterrent without catastrophic punishment |
| Unstake delay | 7 days | Prevents hit-and-run attacks; gives oracle time to detect fraud |
| Stake contract | `NodeRegistry.sol` | All stake/slash logic in audited, public contract |

**Rationale:** Identical to Helium's validator stake mechanism and Akash Network's provider stake requirement. The 7-day unstake delay has proven effective in both networks for preventing gaming behaviours while remaining acceptable to legitimate operators.

### 11.2 Tier 2 — Service Buyer Prepayment Escrow

Service buyers (advertisers, platform operators, betting infrastructure operators) who commit to volume engagements stake USDC into an escrow contract in exchange for discounted CMXS burn rates. Staked USDC is released to nodes as deliveries are confirmed.

| Volume Tier | USDC Staked | CMXS Burn Discount | Routing Priority |
|---|---|---|---|
| Standard | USD 0–9,999 | 0% | Best effort |
| Tier 1 | USD 10,000 | 5% burn discount | Standard priority |
| Tier 2 | USD 50,000 | 12% burn discount | High priority routing |
| Tier 3 | USD 250,000 | 20% burn discount | Guaranteed premium slots |

This mechanism creates **predictable, committed demand** — large buyers are incentivised to pre-commit, giving the network revenue visibility analogous to a subscription model and providing a floor against BME mint-rate volatility.

### 11.3 Tier 3 — veToken Governance Staking (Curve Finance Model)

Token holders who want governance rights lock CMXS for 1–4 years to receive veCMXS (vote-escrowed CMXS). The longer the lock, the more governance power — preventing short-term token holders from dominating protocol decisions.

| Lock Duration | veCMXS per 1 CMXS | Governance Weight | Protocol Fee Share |
|---|---|---|---|
| 1 year | 0.25 veCMXS | 25% | 25% of fee allocation |
| 2 years | 0.50 veCMXS | 50% | 50% of fee allocation |
| 4 years | 1.00 veCMXS | Full (1:1) | Full allocation |

**veCMXS rights include:**
- Vote on all network parameter changes (PoD reward rate, slash conditions, daily mint cap, burn fee rate)
- Receive 50% of protocol fees collected from x402 burn transactions
- Priority access to new node operator geography allocations
- Propose and vote on Ecosystem Grant distributions from the 15% grant pool

**veCMXS governance staking contract (`GovernanceStaking.sol`) key functions:**

```solidity
// Lock CMXS for veCMXS governance rights
function lockCMXS(uint256 amount, uint256 lockDurationYears) external;

// Unlock after lock period expires (tokens returned, veCMXS destroyed)
function unlock() external;

// Cast vote on an active governance proposal
function vote(uint256 proposalId, bool support) external;

// Claim accumulated protocol fee share
function claimFees() external returns (uint256 usdcAmount);
```

---

## 12. Smart Contract Reference Implementation

### 12.1 Full Contract Suite

All contracts are deployed on Base L2 using Foundry for development, testing, and deployment. All contracts use OpenZeppelin v5 as the security base library.

| Contract | Purpose | Key Roles |
|---|---|---|
| `CMXS.sol` | ERC-20 token with controlled mint/burn, daily cap, BME tracking | MINTER_ROLE (oracle only), BURNER_ROLE (public) |
| `DeliveryOracle.sol` | Trusted-signer oracle (Phase 0); Chainlink CRE (Phase 1+) | Oracle signer, upgradeable |
| `NodeRegistry.sol` | Node registration, stake management, slash logic | Node operators, admin |
| `ServiceBuyerEscrow.sol` | USDC escrow + burn discount tier management | Service buyers |
| `GovernanceStaking.sol` | veCMXS lock/unlock, voting weight, fee distribution | Any CMXS holder |
| `Treasury.sol` | Foundation treasury; Ecosystem Grant distribution | DAO (veCMXS governance) |
| `VestingVault.sol` | Team/investor cliff + linear vesting | Beneficiaries |

### 12.2 CMXS.sol — Full Reference Implementation

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

    uint256 public constant MAX_SUPPLY       = 1_000_000_000 * 1e18; // 1B fixed cap
    uint256 public constant MAX_DAILY_MINT   = 2_880_000    * 1e18; // Safety cap
    uint256 public constant REWARD_PER_DELIVERY = 1e15;             // 0.001 CMXS

    // BME tracking (public, readable by anyone)
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
        // NOTE: No tokens minted to team/admin here.
        // Initial allocations (Treasury, Liquidity, VestingVault)
        // are minted separately via initialise() after audit completion.
    }

    /**
     * @notice Reward a node operator for a verified delivery event
     * @dev Only callable by DeliveryOracle.sol (MINTER_ROLE)
     * @param nodeOperator Address of the rewarded node operator
     * @param deliveryId   Unique hash of the delivery event (replay protection in Oracle)
     * @param amount       CMXS to mint (typically REWARD_PER_DELIVERY)
     */
    function rewardNode(
        address nodeOperator,
        bytes32 deliveryId,
        uint256 amount
    ) external onlyRole(MINTER_ROLE) whenNotPaused {
        require(totalSupply() + amount <= MAX_SUPPLY,   "Max supply exceeded");
        _enforceDailyMintCap(amount);
        _mint(nodeOperator, amount);
        totalMinted += amount;
        emit DeliveryRewarded(nodeOperator, deliveryId, amount, totalMinted);
    }

    /**
     * @notice Burn CMXS tokens (service buyer burn-for-priority or governance)
     * @param amount  Tokens to burn
     * @param reason  Human-readable reason (logged in event for BME analytics)
     */
    function burn(uint256 amount, string calldata reason) external {
        _burn(msg.sender, amount);
        totalBurned += amount;
        emit TokensBurned(msg.sender, amount, reason, totalBurned);
    }

    /**
     * @notice BME health check — net supply change since genesis
     * @return netInflation Positive = more minted than burned; Negative = deflationary
     */
    function bmeNetInflation() external view returns (int256) {
        return int256(totalMinted) - int256(totalBurned);
    }

    // Internal daily mint cap enforcement
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

### 12.3 DeliveryOracle.sol — Trusted-Signer Implementation (Phase 0)

```solidity
// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

/**
 * @title DeliveryOracle
 * @notice Phase 0: trusted-signer ECDSA oracle
 * @dev Migration path: updateTrustedSigner(chainlinkCREContractAddress)
 *      upgrades to decentralised oracle with zero contract rewrite
 */
contract DeliveryOracle is Ownable {
    using ECDSA for bytes32;
    using MessageHashUtils for bytes32;

    address public trustedSigner;      // Backend server signing key (Phase 0)
                                       // Chainlink CRE contract address (Phase 1+)
    ICMXS   public cmxsToken;          // CMXS token contract interface
    uint256 public slaThresholdMs = 500; // Default 500ms SLA threshold

    mapping(bytes32 => bool) public usedNonces; // Replay attack protection

    event DeliveryProofAccepted(
        bytes32 indexed deliveryId,
        address indexed nodeOperator,
        uint256 latencyMs,
        uint256 rewardAmount,
        uint256 timestamp
    );

    event SLAThresholdUpdated(uint256 oldThreshold, uint256 newThreshold);

    constructor(address _trustedSigner, address _cmxsToken)
        Ownable(msg.sender)
    {
        trustedSigner = _trustedSigner;
        cmxsToken = ICMXS(_cmxsToken);
    }

    /**
     * @notice Submit a signed delivery proof and claim node reward
     * @param deliveryId    keccak256(txHash + nodeId + sessionId) — unique per event
     * @param nodeOperator  Node wallet claiming the reward
     * @param latencyMs     Measured delivery latency in milliseconds
     * @param rewardAmount  CMXS to mint (validated against REWARD_PER_DELIVERY constant)
     * @param expiry        Proof expires at this block.timestamp (prevents stale proofs)
     * @param signature     ECDSA signature from trustedSigner over all params + chainId
     */
    function submitDeliveryProof(
        bytes32 deliveryId,
        address nodeOperator,
        uint256 latencyMs,
        uint256 rewardAmount,
        uint256 expiry,
        bytes calldata signature
    ) external {
        require(block.timestamp <= expiry,          "Proof expired");
        require(!usedNonces[deliveryId],            "Proof already used");
        require(latencyMs <= slaThresholdMs,        "SLA not met: latency exceeded");
        require(rewardAmount == cmxsToken.REWARD_PER_DELIVERY(), "Invalid reward amount");

        // Reconstruct the signed message hash
        bytes32 messageHash = keccak256(abi.encodePacked(
            deliveryId,
            nodeOperator,
            latencyMs,
            rewardAmount,
            expiry,
            block.chainid    // Prevents cross-chain replay
        ));

        // Verify the trusted signer (or Chainlink CRE) produced this signature
        address recovered = messageHash
            .toEthSignedMessageHash()
            .recover(signature);
        require(recovered == trustedSigner, "Invalid oracle signature");

        // Mark nonce used (replay protection)
        usedNonces[deliveryId] = true;

        // Mint reward via CMXS token contract
        cmxsToken.rewardNode(nodeOperator, deliveryId, rewardAmount);

        emit DeliveryProofAccepted(
            deliveryId,
            nodeOperator,
            latencyMs,
            rewardAmount,
            block.timestamp
        );
    }

    /**
     * @notice Update trusted signer — used for Phase 1 migration to Chainlink CRE
     * @dev Setting to Chainlink CRE contract address decentralises oracle entirely
     */
    function updateTrustedSigner(address newSigner) external onlyOwner {
        trustedSigner = newSigner;
    }

    function updateSLAThreshold(uint256 newThresholdMs) external onlyOwner {
        emit SLAThresholdUpdated(slaThresholdMs, newThresholdMs);
        slaThresholdMs = newThresholdMs;
    }
}
```

### 12.4 Backend Oracle Signing (TypeScript Reference)

```typescript
// Backend service: signs delivery proofs for DeliveryOracle.sol
import {
  createWalletClient,
  http,
  keccak256,
  encodePacked,
  parseAbi
} from 'viem';
import { privateKeyToAccount } from 'viem/accounts';
import { base } from 'viem/chains';

const oracleAccount = privateKeyToAccount(
  process.env.ORACLE_PRIVATE_KEY as `0x${string}`
);

export async function signDeliveryProof(params: {
  deliveryId:    `0x${string}`;
  nodeOperator:  `0x${string}`;
  latencyMs:     bigint;
  rewardAmount:  bigint;
  expiry:        bigint;
}): Promise<`0x${string}`> {
  // Reconstruct message hash (must match DeliveryOracle.sol exactly)
  const messageHash = keccak256(encodePacked(
    ['bytes32', 'address', 'uint256', 'uint256', 'uint256', 'uint256'],
    [
      params.deliveryId,
      params.nodeOperator,
      params.latencyMs,
      params.rewardAmount,
      params.expiry,
      BigInt(8453)        // Base mainnet chainId
    ]
  ));

  // EIP-191 personal_sign wrapper (matches toEthSignedMessageHash in Solidity)
  return oracleAccount.signMessage({ message: { raw: messageHash } });
}
```

### 12.5 VestingVault.sol — Cliff + Linear Vesting

```solidity
// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title VestingVault
 * @notice Cliff + linear vesting for team, investors, and ecosystem grants
 */
contract VestingVault is Ownable {

    struct VestingSchedule {
        address beneficiary;
        uint256 totalAmount;
        uint256 cliffTimestamp;    // Tokens locked until this time
        uint256 startTimestamp;    // Linear vesting begins here (= cliff end)
        uint256 endTimestamp;      // Fully vested at this time
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
        uint256 endTs   = cliffTs + (vestingMonths * 30 days);
        schedules[beneficiary] = VestingSchedule({
            beneficiary:    beneficiary,
            totalAmount:    totalAmount,
            cliffTimestamp: cliffTs,
            startTimestamp: cliffTs,
            endTimestamp:   endTs,
            claimedAmount:  0
        });
    }

    function claim() external {
        VestingSchedule storage s = schedules[msg.sender];
        require(s.totalAmount > 0,                  "No schedule found");
        require(block.timestamp >= s.cliffTimestamp,"Cliff not reached");
        uint256 vested = _vestedAmount(s);
        uint256 claimable = vested - s.claimedAmount;
        require(claimable > 0,                      "Nothing to claim");
        s.claimedAmount += claimable;
        cmxsToken.transfer(msg.sender, claimable);
        emit TokensClaimed(msg.sender, claimable);
    }

    function _vestedAmount(VestingSchedule memory s)
        internal view returns (uint256)
    {
        if (block.timestamp < s.cliffTimestamp) return 0;
        if (block.timestamp >= s.endTimestamp)  return s.totalAmount;
        uint256 elapsed  = block.timestamp - s.startTimestamp;
        uint256 duration = s.endTimestamp - s.startTimestamp;
        return (s.totalAmount * elapsed) / duration;
    }
}
```

---

## 13. Governance: veToken Model

### 13.1 Governance Architecture

CMXS governance is implemented via the Curve Finance veToken model — proven in production across USD 5B+ TVL protocols (Curve, Balancer, Frax) with no governance exploits in 5+ years of operation.

**Governance lifecycle:**

```
1. Any wallet with ≥ 100,000 veCMXS submits proposal to governance forum
2. 7-day community discussion period (off-chain, on-chain snapshot)
3. 5-day on-chain voting period (GovernanceStaking.sol)
4. Quorum requirement: ≥ 10% of total veCMXS must vote
5. Approval threshold: ≥ 66% supermajority FOR
6. 48-hour timelock before execution (security buffer)
7. Execution via Treasury.sol or parameter update call
```

### 13.2 Governable Parameters

| Parameter | Current Default | Who Can Change |
|---|---|---|
| PoD reward rate (CMXS per delivery) | 0.001 CMXS | veCMXS DAO (66% supermajority) |
| Daily mint safety cap | 2,880,000 CMXS | veCMXS DAO (66% supermajority) |
| SLA latency threshold | 500ms | veCMXS DAO (66% supermajority) |
| Slash penalty percentage | 10% | veCMXS DAO (66% supermajority) |
| Protocol fee on burn transactions | 5% | veCMXS DAO (66% supermajority) |
| Ecosystem Grant allocation | Per proposal | veCMXS DAO (simple majority) |
| Node operator geography expansion | Per proposal | veCMXS DAO (simple majority) |

### 13.3 Progressive Decentralisation Schedule

| Phase | Period | Governance Status | Foundation Role |
|---|---|---|---|
| Phase 0 | Months 1–12 | Foundation-controlled parameters | Full control (regulatory flexibility) |
| Phase 1 | Months 12–36 | veCMXS DAO activated | Foundation retains compliance veto only |
| Phase 2 | Month 36+ | Full DAO governance | Foundation veto dissolved |

The SEC Safe Harbor 2.0 framework (March 2026) defines "network maturity" as the point at which no single entity controls >50% of transaction validation. CMXS Foundation targets achieving this by Month 24, unlocking the Safe Harbor's full 3-year non-security protection window from TGE.

---

## 14. ICO Framework and Capital Raise Structure

### 14.1 Strategic Rationale for a Four-Stage Raise

A staged capital raise de-risks the ICO by:
1. Establishing institutional credibility (Angel/Seed) before public access
2. Using exchange-hosted KYC (IEO) to satisfy regulatory requirements at scale
3. Discovering the market-clearing token price via Liquidity Bootstrapping Pool (LBP) rather than an arbitrary fixed price
4. Creating multiple price discovery points (USD 0.02 → USD 0.10) that reward early conviction with the DePIN-standard pricing ladder

### 14.2 Four-Stage Capital Raise

#### Stage 0 — Angel / SAFE Round (Months 1–2)

| Parameter | Detail |
|---|---|
| Target Raise | USD 1M–2M |
| Instrument | SAFE (Simple Agreement for Future Tokens) |
| Conversion | 20% discount to Seed round token price |
| Investors | 5–10 strategic angels (streaming industry, DePIN ecosystem, broadcast infrastructure) |
| Token Price | Not set (converts at Seed) |
| Use of Funds | Cayman entity setup, Trail of Bits audit deposit, Caton C3 SDK licensing, AWS Phase 0 infrastructure |
| KYC Requirement | Full KYC via Jumio; accredited investor verification |
| Legal Filing | SAFE documentation; Reg D filing at Seed conversion |

#### Stage 1 — Seed Round Reg D 506(c) (Months 3–4)

| Parameter | Detail |
|---|---|
| Target Raise | USD 3M–5M |
| Token Price | USD 0.02 / CMXS |
| Implied FDV | USD 20M |
| Allocation | 50,000,000 CMXS (5% of total supply) |
| Vesting | 12-month cliff; 36-month linear |
| Minimum Ticket | USD 250,000 |
| Investor Type | US accredited investors + crypto-native VCs (Multicoin, Paradigm, a16z crypto) |
| Legal Basis | SEC Regulation D 506(c) — filed within 15 days of first close |
| KYC Platform | CoinList or Republic Crypto (full accredited investor verification) |

#### Stage 2 — Strategic / IEO Round (Months 5–6)

| Parameter | Detail |
|---|---|
| Target Raise | USD 8M–15M |
| Venue | Tier-1 IEO: Binance Launchpad, Coinbase Ventures, or Kraken Ventures |
| Token Price | USD 0.05–0.08 / CMXS |
| Implied FDV | USD 50M–80M |
| Allocation | 50,000,000 CMXS (from Public ICO pool) |
| Vesting | 20% at TGE; 80% over 12 months linear |
| Why IEO | Exchange-hosted IEOs complete at 3× the rate of direct ICOs (2026 data); exchange provides KYC/AML, custody, and immediate secondary market access |

#### Stage 3 — Public IDO / Token Generation Event (Month 7)

| Parameter | Detail |
|---|---|
| Target Raise | USD 6M–11M |
| Venue | Fjord Foundry LBP + Uniswap v4 on Base L2 + 1–2 CEX listings |
| Token Price | USD 0.10 / CMXS (starting price; LBP discovers floor) |
| Implied FDV | USD 100M |
| Allocation | 20,000,000 CMXS (2% Liquidity Provision + remaining Public ICO) |
| LBP Mechanics | Price starts at USD 0.15, declines over 72 hours to market-clearing price — prevents whale sniping and ensures broad distribution |
| Geographic Restrictions | No US retail (accredited only); no OFAC-sanctioned jurisdictions |
| TGE Unlock | 20% of public allocation; 80% over 12 months linear |

### 14.3 Complete Raise Summary

| Stage | Raise | Token Price | Implied FDV | Vesting |
|---|---|---|---|---|
| Angel / SAFE | USD 1M–2M | N/A | N/A | Converts at Seed |
| Seed Reg D | USD 3M–5M | USD 0.02 | USD 20M | 12M cliff + 36M linear |
| Strategic / IEO | USD 8M–15M | USD 0.05–0.08 | USD 50M–80M | 20% TGE + 12M linear |
| Public IDO | USD 6M–11M | USD 0.10 | USD 100M | 20% TGE + 12M linear |
| **TOTAL** | **USD 18M–33M** | — | — | — |

---

## 15. Use of Proceeds

| Category | % | Amount (USD 25M midpoint) | Specific Use |
|---|---|---|---|
| Technology Development | 35% | USD 8.75M | CE-MoQ relay software, x402 integration, CMXS smart contract suite, DeliveryOracle, dashboard, player SDK |
| Physical Node Infrastructure | 25% | USD 6.25M | EchoStar JV setup costs, Phase 1 node hardware (500 nodes), AWS edge infrastructure (Phase 0) |
| Legal & Compliance | 15% | USD 3.75M | Cayman Foundation setup, Reg D filings, Trail of Bits audit, ongoing regulatory counsel (Perkins Coie or Cooley) |
| Marketing & Community | 15% | USD 3.75M | KOL campaigns, Discord/Telegram community management, exchange listing fees, PR, developer grants |
| Operations & Reserve | 10% | USD 2.5M | Team salaries (Months 1–12), insurance, emergency reserve, audit remediation |

---

## 16. Network Expansion and Use Case Roadmap

CMXS is a general-purpose verified-delivery DePIN protocol. The initial use case — verified digital advertising delivery — is the first commercial deployment; the same infrastructure, transport stack, and token settlement layer support multiple verticals without any protocol modification.

### 16.1 Use Case Expansion Map

| Use Case | CMXS Application | Market Size | Timeline |
|---|---|---|---|
| **Verified ad delivery (CTV/FAST)** | x402 per-impression burn + PoD node rewards | USD 40.2B (2026) | **Phase 0–1 (live)** |
| **Live sports betting infrastructure** | Sub-500ms latency service (B2B licensing) | USD 45.9B TAM | Phase 1–2 |
| **Pay-per-view content** | x402 per-view micropayment + delivery proof | USD 8B (live sports PPV) | Phase 2 |
| **AI agent data feed delivery** | Autonomous x402 agent-to-agent payments | Emerging (2026+) | Phase 3 |
| **IoT telemetry delivery** | PoD for sensor data; sub-500ms telemetry | USD 145.9B DePIN TAM (2033) | Phase 3+ |
| **Live auction / shopping streams** | Low-latency + payment settlement combo | USD 32B (live commerce) | Phase 2–3 |

### 16.2 The Protocol Generalisation Principle

Every use case in the table above uses the **same four-component stack**:
1. QUIC/MoQ transport (sub-500ms delivery)
2. x402 micropayment (per-delivery USDC settlement)
3. PoD oracle (verified delivery proof)
4. CMXS token (node reward + governance)

No protocol modification is required to expand to a new use case — only new application-layer software connecting to the existing CMXS network. This is the architecture decision that makes CMXS a **protocol token** (network-wide value accrual) rather than an application token (value limited to one use case).

---

## 17. Competitive Benchmarking

### 17.1 DePIN Network Comparison

| Network | Physical Infrastructure | Verification Mechanism | Delivery SLA | Token Model | Initial FDV |
|---|---|---|---|---|---|
| **CMXS** | 5,800 EchoStar towers (JV anchor) | PoD — ECDSA receipt + x402 + oracle | <500ms guaranteed | BME (burn/mint) | USD 100M |
| Helium (HNT) | Crowdsourced LoRaWAN hotspots | Proof-of-Coverage (radio challenge) | Coverage-based | BME | USD 16M |
| Render (RNDR) | Crowdsourced GPU nodes | Proof-of-Render (job completion hash) | GPU job-based | BME | USD 18M |
| Hivemapper (HONEY) | Crowdsourced dashcam devices | Proof-of-Drive (GPS + image hash) | Map coverage | Work token | USD 45M |
| Livepeer (LPT) | ~100 transcoding orchestrators | Work verification (transcoding hash) | Best effort | Work token | USD 5M |
| Theta (THETA) | P2P relay nodes | Staking + relay | Best effort | PoS hybrid | USD 20M |
| Aethir (ATH) | GPU compute nodes | Proof-of-Render | GPU job-based | Work token | USD 760M |

**CMXS structural advantages over all comparables:**
1. **Pre-existing supply:** 5,800 EchoStar towers provide a physical node base at launch — no DePIN project has launched with comparable pre-existing physical infrastructure.
2. **Pre-existing demand:** The initial commercial use case deploys against existing streaming platform ad inventory — not a cold-start market.
3. **Dual-layer proof:** CMXS combines cryptographic delivery receipt AND x402 payment settlement as independent verification signals — more robust than single-signal PoD mechanisms.
4. **Multiple use cases from Day 1:** The same protocol supports advertising, live betting infrastructure, and PPV simultaneously — no comparable DePIN project has multi-vertical deployment at launch.

### 17.2 Peak FDV Benchmarks

| Project | Initial FDV | Peak FDV | Peak Multiple | Mechanism |
|---|---|---|---|---|
| Helium (HNT) | USD 16M | USD 5.1B | 319× | Proof-of-Coverage |
| Render (RNDR) | USD 18M | USD 4.2B | 233× | Proof-of-Render |
| Hivemapper (HONEY) | USD 45M | USD 420M | 9.3× | Proof-of-Drive |
| DIMO | USD 9M | USD 200M | 22× | Proof-of-Contribution |
| **CMXS (target)** | **USD 100M** | **TBD** | — | **Proof-of-Delivery** |

The CMXS initial FDV of USD 100M is set conservatively relative to Helium's USD 16M and Render's USD 18M — reflecting the additional value of pre-existing infrastructure and documented commercial demand.

---

## 18. Financial Projections

### 18.1 Revenue Model

CMXS protocol generates revenue through node operator activity that triggers CMXS minting, and service buyer activity that triggers CMXS burning. The key financial metrics are:

**Revenue per node per day:**
- 1,440 verified deliveries/day (1 per minute) × USD 0.10 CMXS = **USD 1.44/node/day** at USD 100 CMXS price
- At USD 500 CMXS price (Helium-comparable): **USD 7.20/node/day**
- Payback period on USD 329 Raspberry Pi 5 node hardware: ~230 days at launch price

**CMXS burn from service demand:**
- Each USD 10 CPM ad slot = 1,000 impressions × USD 0.01 = USD 10 USDC burned → proportional CMXS burn
- At USD 45 CPM verified rate: USD 45 USDC burned per 1,000 impressions → ~0.45 CMXS burned at USD 100 CMXS price

### 18.2 Network Growth Projections

| Metric | Year 1 | Year 2 | Year 3 |
|---|---|---|---|
| Active Nodes | 50–500 | 2,000 | 10,000 |
| Daily Verified Deliveries | 72K–720K | 2.88M | 14.4M |
| Annual CMXS Minted (PoD) | 26.3M–262.8M | 1.05B cap hit | Daily cap active |
| Gross Service Revenue | USD 2.4M–8M | USD 42M–84M | USD 84M–144M |
| Annual CMXS Burned | 24K–80K | 420K–840K | 840K–1.44M |
| Implied Network Value (10× revenue) | USD 24M–80M | USD 420M–840M | USD 840M–1.44B |

**Year 3 implied network value of USD 840M–1.44B** represents an 8.4×–14.4× return on the USD 100M initial FDV — consistent with the Helium (319×) and Render (233×) precedents from comparable initial valuations.

---

## 19. Regulatory Compliance Framework

### 19.1 SEC Classification — US

The SEC's March 17, 2026 interpretive release (Release No. 2026-30) established a five-category non-security taxonomy. CMXS is designed to qualify as a **"digital tool"** — a functional access credential and work-reward instrument.

**Critical design elements supporting non-security classification:**
- Rewards are determined entirely by smart contract protocol rules — no managerial discretion
- Token utility (delivery access, node staking, governance) exists independently of any price appreciation
- CMXS Foundation makes no representation of profit from the issuer's essential managerial efforts
- Progressive decentralisation plan documented in the Token Disclosure Document

**Howey Test Analysis:**

| Element | Analysis | Conclusion |
|---|---|---|
| Investment of money | Yes — purchasers pay USDC/fiat | Satisfied |
| Common enterprise | Partially — network participants share infrastructure benefit | Partially satisfied |
| Expectation of profits | PoD rewards = compensation for work performed, not passive investment return | **Not satisfied for node operators** |
| From efforts of others | Rewards determined by smart contract, not managerial decisions | **Not satisfied** |

Under the March 2026 guidance, protocol staking/mining activities (where rewards derive from protocol rules rather than managerial efforts) explicitly **do not constitute the offer and sale of securities.**

### 19.2 Safe Harbor 2.0 Compliance Requirements

The SEC's Safe Harbor 2.0 framework (formally adopted January 2026) grants a 3-year non-registration window for token networks that comply with:

| Requirement | CMXS Compliance Plan |
|---|---|
| Token Disclosure Document (TDD) filed publicly before TGE | Filed Month 2; published at cmxs.network/tdd |
| Tokenomics fully disclosed (this White Paper) | This document constitutes the disclosure |
| US retail limited to accredited investors for first 12 months | Enforced via Reg D 506(c) + geo-block at IDO |
| Network maturity plan documented | Progressive decentralisation schedule (Section 13.3) |
| No single entity controls >50% of transaction validation at Year 3 | PoD distribution by design; monitored monthly |

### 19.3 EU / MiCA Compliance

Under MiCA (fully applicable January 2025), CMXS qualifies as a **utility token** under Article 4 — providing digital access to a service without conferring investment rights. Pre-TGE requirements:

- White Paper filed with relevant National Competent Authority (NCA) ≥20 working days before public offering
- No EU marketing implying investment returns
- CMXS Foundation to engage a MiCA-registered EU distribution entity for European participants

### 19.4 GENIUS Act (US, 2025)

CMXS is not a payment stablecoin and is not subject to the GENIUS Act's stablecoin provisions. The x402 payment layer uses USDC (a GENIUS Act-compliant stablecoin operated by Circle), insulating CMXS from stablecoin regulatory risk.

### 19.5 KYC / AML Framework

| Participant Type | KYC Level | Vendor | Legal Basis |
|---|---|---|---|
| Angel / Seed investors | Full KYC + accredited verification | Jumio | Reg D 506(c) |
| IEO participants | Exchange-standard KYC | Binance/Coinbase platform | Exchange compliance |
| Public IDO participants | Wallet geo-block + OFAC screen | Chainalysis | Regulation S |
| Node operators (global) | Wallet verification + sanctions screen | Synaps (DePIN-specialised) | Smart contract agreement |

**Mandatory legal documents before TGE:**
1. Token Disclosure Document (TDD) — SEC Safe Harbor 2.0 required filing
2. Regulation D 506(c) filing — within 15 days of first Seed close
3. SAFT (Simple Agreement for Future Tokens) — for Angel and Seed investors
4. Terms of Token Sale — governs public IDO participation
5. Node Operator Agreement — smart contract terms, incorporated by reference
6. DAO Governance Charter — documents veCMXS voting rights and procedures

### 19.6 Tax Treatment (US)

- **Node operator rewards:** Ordinary income at fair market value at time of receipt (IRS Notice 2014-21, updated 2023)
- **Burning CMXS for delivery priority:** Not a taxable event (consumption, not disposition)
- **Trading CMXS:** Capital gain/loss event for US holders
- **Foundation Treasury CMXS:** Not taxable until distributed (Cayman entity)

---

## 20. Corporate Structure

### 20.1 Dual-Entity Structure

| Entity | Jurisdiction | Role |
|---|---|---|
| **CMXS Foundation Ltd.** | Cayman Islands (Exempted Company) | Token issuer; holds Foundation Treasury; publishes TDD; manages ICO |
| **CMXS Labs Inc.** | Delaware, USA | Technology developer; employs engineering team; receives development grants from Foundation |
| **Node Operator Agreement** | Base L2 smart contract | On-chain binding terms for all node participants; incorporated by reference |

This structure mirrors the proven dual-entity model used by **Helium** (Helium Foundation, Cayman + Nova Labs, Delaware), **Filecoin** (Filecoin Foundation, Cayman + Protocol Labs, Delaware), and **Render Network** (Render Foundation, Cayman + OTOY Inc., Delaware).

### 20.2 Why Cayman Islands Foundation

The Cayman Islands Exempted Foundation structure provides:
- No Cayman capital gains or income tax on token treasury or foundation activities
- Flexible governance structure supporting DAO transition over time
- Recognised by institutional investors as the DePIN industry standard
- CIMA (Cayman Islands Monetary Authority) regulated environment with established crypto precedent
- Clean separation between token issuance (non-US entity) and technology development (US entity)

### 20.3 Recommended Legal Counsel

- **Cayman entity:** Ogier or Carey Olsen (both DePIN-experienced, Cayman-based)
- **US securities:** Perkins Coie or Cooley (both with active crypto/DePIN practices)
- **Smart contract audit:** Trail of Bits (6-week minimum engagement for full contract suite)

---

## 21. Development Roadmap

### 21.1 ICO Implementation Timeline

| Month | Milestone | Deliverable |
|---|---|---|
| M1 | Legal entity formation | Cayman Foundation registered; Delaware Inc. formed |
| M1 | Smart contract audit engaged | Trail of Bits or CertiK engagement letter signed |
| M2 | Token Disclosure Document | TDD filed with SEC Safe Harbor; published at cmxs.network/tdd |
| M2 | Angel round close | USD 1M–2M SAFE closed |
| M3 | Seed round opens | Reg D 506(c) filing; CoinList KYC portal live |
| M4 | Seed round closes | USD 3M–5M; Base mainnet contracts deployed |
| M4 | Phase 0 demo published | Benchmark data public: sub-500ms delivery, x402 settlement, PoD minting |
| M5 | IEO application submitted | Applications to Binance Launchpad, Coinbase Ventures, Kraken |
| M5 | CEX listing negotiations | Targeting 1 Tier-1 + 2 Tier-2 exchange listings |
| M6 | IEO launch | USD 8M–15M strategic round via partner exchange |
| M6 | CMXS mainnet launch | All contracts deployed; vesting vaults funded |
| M7 | TGE / Public IDO | Fjord Foundry LBP + Uniswap v4 + CEX listing |
| M8 | Phase 1: 500 nodes | First EchoStar tower JV nodes activated; first commercial campaigns |
| M12 | Governance launch | veCMXS voting activated; first DAO proposal |

### 21.2 Product Development Phases

**Phase 0 (Complete — Q2 2026): Proof of Concept**
- AWS-hosted MoQ relay + CE-MoQ integration
- x402 settlement on Base Sepolia testnet (USDC testnet)
- CMXS ERC-20 on Base Sepolia with PoD minting
- Benchmark achieved: **287ms P50, 312ms P95** delivery latency
- Advertiser dashboard with real-time on-chain impression log

**Phase 1 (Q3–Q4 2026): Production Launch**
- 500 physical nodes (EchoStar tower JV initial cohort)
- x402 live on Base mainnet (real USDC)
- First commercial campaigns at USD 45 CPM verified floor
- Chainlink CRE replacing trusted-signer oracle
- veCMXS governance contract deployed

**Phase 2 (2027): Scale**
- 2,000 nodes (EchoStar + independent TowerCo partners)
- Live sports betting B2B licensing pilot (3–5 licensed operators)
- Multi-use-case protocol expansion (PPV, live auction streams)
- USD 42M–84M ARR target
- Implied FDV: USD 420M–840M (at 10× revenue multiple)

**Phase 3 (2028): Protocol Generalisation**
- 10,000 nodes nationwide
- AI agent per-delivery bidding (autonomous DSP via x402)
- Full DAO governance transition (Foundation veto dissolved)
- IoT telemetry and AI data feed delivery use cases live
- USD 84M–144M ARR target; implied network value USD 840M–1.44B

---

## 22. Risk Factors

### 22.1 Technology Risks

- **MoQ Standardisation Risk:** IETF draft-ietf-moq-transport is not yet an RFC. Breaking changes in final standardisation could require protocol updates.
- **Caton C3 Dependency:** CMXS's sub-500ms guarantee depends on licensing Caton's C3/CVP SDK. A licensing failure, Caton corporate change, or force majeure could affect the transport layer.
- **Smart Contract Vulnerability:** Despite audits, undiscovered vulnerabilities may exist. An exploit could result in loss of staked CMXS or unauthorised minting up to the daily mint cap.
- **Oracle Centralisation (Phase 0):** The trusted-signer oracle is a single point of failure until migrated to Chainlink CRE. The daily mint cap (2,880,000 CMXS) limits catastrophic exposure.
- **Chainlink CRE Adoption:** Chainlink CRE is newly production-launched (November 2025). Enterprise adoption at the CMXS production scale is early-stage.

### 22.2 Market Risks

- **Token Price Volatility:** CMXS price is subject to extreme volatility. Tokens may lose all value.
- **DePIN Competition:** Well-funded new DePIN video delivery projects may emerge. Existing players (Livepeer, Theta) could pivot toward verified delivery.
- **Macro / Ad Spend Cyclicality:** Digital advertising is cyclical. A macroeconomic recession reduces ad volumes and CMXS burn rate.
- **BME Imbalance:** If node growth significantly outpaces service demand, the mint rate may exceed the burn rate, creating temporary downward price pressure.

### 22.3 Regulatory Risks

- **SEC Reclassification:** The March 2026 interpretive release could be reversed or modified in future rulemaking. CMXS could be reclassified as a security, requiring registration.
- **MiCA Enforcement:** EU MiCA enforcement could impose additional compliance costs or restrict EU distribution.
- **Tax Treatment Changes:** IRS reclassification of PoD rewards from ordinary income to another category could affect node operator economics.

### 22.4 Operational Risks

- **EchoStar JV Execution Risk:** The JV converting EchoStar towers to CMXS nodes is a commercial negotiation. Failure to close could require CMXS Labs to deploy independent node hardware at higher cost and longer timeline.
- **Node Operator Adoption:** If insufficient nodes join, the BME equilibrium is not achievable and CMXS token value is not sustained.
- **Key Personnel Concentration:** The current team is small. Loss of key personnel could delay development milestones.
- **x402 Protocol Risk:** x402 is a recently released open standard. Adoption by service buyers requires wallet infrastructure that is still maturing.

---

## 23. Legal Disclaimer

This White Paper is published by CMXS Foundation Ltd. for informational purposes only. It does not constitute: (a) an offer or solicitation to sell securities or any other regulated financial instrument; (b) investment advice; (c) a prospectus or offering memorandum; or (d) legal, tax, or financial advice.

**CMXS tokens are utility tokens** designed for functional use within the CMXS DePIN network. They are not designed or intended to constitute a security, commodity, or regulated investment product in any jurisdiction.

**Forward-looking statements** in this document are based on current expectations and assumptions. Actual results, performance, or events may differ materially from those expressed or implied.

**United States:** CMXS tokens are offered only to accredited investors in the Angel and Seed rounds under SEC Regulation D Rule 506(c). Public IDO participation is not available to U.S. retail investors. Nothing herein constitutes investment advice or a solicitation of investment.

**European Union:** This White Paper will be filed with the relevant National Competent Authority under MiCA before any public offering in EU member states. No representations are made regarding investment returns.

**OFAC Compliance:** CMXS Foundation will not sell tokens to individuals, entities, or wallets associated with OFAC-sanctioned jurisdictions.

**No Guarantee of Value:** CMXS Foundation makes no representation regarding the future value of CMXS tokens. Token purchasers may lose their entire investment.

**Intellectual Property:** The CMXS protocol, smart contracts, and documentation are the intellectual property of CMXS Labs Inc. Smart contracts are open-source (MIT License) and publicly auditable. The Caton C3 transport technology is proprietary to Caton Technology Group and licensed to CMXS Labs Inc.

---

*CMXS Foundation Ltd. | Grand Cayman, Cayman Islands*
*CMXS Labs Inc. | Delaware, USA*

*White Paper Version 2.0 | May 2026*
*Token Disclosure Document: Filed under SEC Safe Harbor 2.0 (pending)*
*Smart Contract Audit: Trail of Bits engagement (pending)*
*Exchange Listing Applications: Binance Launchpad, Coinbase Ventures, Kraken Ventures (pending)*

*© 2026 CMXS Foundation Ltd. This document may be freely distributed with attribution.*

