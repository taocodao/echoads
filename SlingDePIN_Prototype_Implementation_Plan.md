# SlingDePIN Prototype Implementation Plan
### Project Clarity — Phase 0 Technical Blueprint for Antigravity

**Version 1.0 | May 2026 | Confidential**

---

## Executive Summary

This document is the complete implementation blueprint for **Project Clarity Phase 0**: a working prototype that demonstrates the core value proposition of the SlingDePIN stack. The prototype proves four things that no pitch deck alone can:

1. **C3/MOQ transport delivers sub-500ms ad segment insertion** — eliminating Sling TV's documented black-screen and latency problem
2. **x402 micropayment fires per ad impression** — creating an immutable on-chain delivery receipt where none currently exists
3. **On-chain SLA proof is generated and verifiable** — advertisers can audit every impression in real time
4. **Node operator earns CMXS tokens for verified delivery** — the DePIN flywheel turns from day one

The prototype is not a toy demo. It is a minimal but production-pathway implementation built on real open standards: IETF MoQ (draft-ietf-moq-transport), Coinbase x402, and ERC-20 token mechanics. Every component maps directly to a production system.

Target build time: **8–10 weeks** for a 2-engineer team using Antigravity as the primary coding environment.

---

## Part 1: The Problem Being Solved

### 1.1 Sling TV's Documented Ad Infrastructure Failures

Sling TV's current ad delivery architecture is built on HLS-based Server-Side Ad Insertion (SSAI). This creates five verifiable, compounding problems:

**Problem 1 — Black Screen / Transition Latency**
HLS segments are 2–10 seconds long. When a live SSAI decision must be made mid-segment, the player must wait for the current segment to finish, then buffer the ad segment, then stitch and play. This creates documented 2–10 second black screen windows at every ad break. Sling's own support page acknowledges black screen as a known issue. Nearly 80% of viewers found ad-load latency annoying enough to influence their perception of the program. The root cause is TCP-based HLS — not a bug, but a structural limitation of the protocol.

**Problem 2 — No Delivery Verification**
There is no on-chain or even cryptographically verifiable record that a specific ad impression was delivered to a specific device at a specific time. Advertisers pay CPMs of $18–30 on the honor system. CTV fraud is rampant: at peak, fraudsters spoofed 20+ million connected TVs per day to deceive advertisers into paying for fake impressions. Morgan Stanley estimates 30% more CTV inventory is sold than actually watched. The IAB Tech Lab and DoubleVerify both flag CTV verification as the #1 advertiser trust gap in 2026.

**Problem 3 — Frequency Abuse**
Without impression-level receipts, frequency capping is advisory, not enforced. Dish Media's SVP Kevin Arrix publicly admitted "over frequency in-pod" as an unresolved FAST problem. Advertisers see the same household receive the same 30-second spot eight times in a single session — directly degrading brand perception.

**Problem 4 — HLS Latency Locks Out Sports Betting**
HLS end-to-end latency is 5–30 seconds. In-play sports betting infrastructure requires sub-500ms stream-to-bet synchronization to be legal and viable. The global in-play sports betting market is $45.9 billion. Sling cannot participate in this market at all with its current transport layer.

**Problem 5 — Low Fill Rate / Revenue Leakage**
FAST platforms routinely run 40–65% fill rates. Every unfilled slot is pure revenue destruction. Without sub-second ad decisioning, Sling cannot support the real-time bidding speeds needed to fill the long tail of inventory.

### 1.2 The Technology Stack That Fixes All Five

| Problem | Root Cause | Fix | Component |
|---------|-----------|-----|-----------|
| Black screen | HLS 2–10s segments over TCP | Object-based media delivery over QUIC | Caton C3 / MOQ |
| No delivery proof | No cryptographic receipt | Per-impression x402 payment + on-chain SLA | x402 + ERC-8004 smart contract |
| Frequency abuse | No impression-level ledger | Immutable on-chain impression log | CMXS token contract |
| Sports betting lockout | >5s HLS latency | Sub-500ms QUIC transport | Caton C3 CVP |
| Low fill rate | Slow decisioning | Sub-100ms ad auction via MOQ relay | MOQ relay + ad decisioning engine |

---

## Part 2: Architecture Overview

### 2.1 The Three-Layer Stack

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  LAYER 3 — CONSUMER SURFACE                                                 │
│  Sling TV App (Fire TV / Apple TV / Android TV / Web)                       │
│  Modified player: MOQ WebTransport client + x402 wallet + receipt display   │
└──────────────────────────────┬──────────────────────────────────────────────┘
                               │ QUIC / WebTransport (sub-500ms)
┌──────────────────────────────▼──────────────────────────────────────────────┐
│  LAYER 2 — C3 TRANSPORT + AD DECISIONING                                    │
│  Caton Enhanced MoQ Relay  →  Ad Auction Engine  →  x402 Payment Gateway   │
│  NetScope Telemetry        →  SLA Oracle         →  CMXS Smart Contract     │
└──────────────────────────────┬──────────────────────────────────────────────┘
                               │ Fiber / 5G backhaul
┌──────────────────────────────▼──────────────────────────────────────────────┐
│  LAYER 1 — PHYSICAL NODE LAYER (EchoStar Towers / JV TowerCos)              │
│  EchoStar Node (Raspberry Pi 5 in Phase 0) running:                         │
│  - MOQ Relay daemon   - x402 Facilitator   - CMXS staking contract          │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 2.2 Data Flow: One Ad Impression, End-to-End

```
1. Sling stream is playing. Player receives MOQ SUBSCRIBE for next ad slot.
2. MOQ relay at edge node receives ad auction request (< 20ms round trip).
3. Ad decisioning engine runs auction. Winner returned in < 80ms.
4. Ad creative is delivered as MOQ Objects over QUIC — no HLS segment wait.
5. Player stitches ad at frame boundary. Zero black-screen window.
6. x402 HTTP 402 fires: advertiser wallet pays per-impression USDC.
7. x402 Facilitator confirms payment on-chain. Receipt hash written.
8. SLA Oracle checks: was latency < 500ms? Was impression verified? 
9. If SLA met → EchoStar Node earns CMXS tokens.
10. Advertiser dashboard shows cryptographic proof of delivery in real time.
```

### 2.3 Prototype Scope (Phase 0)

The Phase 0 prototype simulates this flow with:
- **1 simulated EchoStar edge node** (local machine or cloud VM)
- **1 Sling-style player** (HLS.js replaced with custom MOQ WebTransport client)
- **1 ad auction stub** (returns winner in <80ms, real DSP integration in Phase 1)
- **x402 on Base Sepolia testnet** (USDC on testnet, not real money)
- **CMXS ERC-20 on Base Sepolia** (token minting to node on verified delivery)
- **SLA Oracle** (Chainlink Functions call checking delivery timestamp vs. threshold)
- **Advertiser dashboard** (real-time impression log with on-chain tx hashes)

---

## Part 3: Complete Tech Stack

### 3.1 Transport Layer

| Component | Technology | Version / Spec | Purpose |
|-----------|-----------|----------------|---------|
| Transport protocol | QUIC | RFC 9000 | Replaces TCP for media delivery |
| Media protocol | Media over QUIC (MoQ) | draft-ietf-moq-transport-08 | Object-based media delivery |
| Enhanced MoQ | Caton Enhanced MoQ (CE-MoQ) | Caton C3 SDK | Sub-500ms guaranteed delivery |
| WebTransport bridge | WebTransport API | W3C WD | Browser/player QUIC access |
| Player SDK | moq-js | github.com/kixelated/moq-rs | MoQ reference player (Rust/WASM) |
| Fallback | LL-HLS | Apple HLS spec | <2s fallback for non-QUIC devices |
| Ingest | RTMP → MoQ transcoder | FFmpeg + moq-rs ingest | Convert Sling live feed to MoQ objects |

**Why MOQ over WebRTC:** MOQ supports fan-out to millions of subscribers natively. WebRTC is peer-to-peer, not CDN-scale. MoQ relays act as a publish/subscribe CDN with sub-frame granularity, making it ideal for both the live stream and the ad segment insertion point.

**Key MOQ Concepts for Implementation:**

```
Track  → One logical stream (e.g., "sling/nfl/live" or "sling/ad/slot-3")
Group  → One GOP (Group of Pictures) — the unit of seeking
Object → One encoded frame or frame group — the unit of delivery
```

The ad insertion point is simply a new Track subscription. The player unsubscribes from the content Track and subscribes to the ad Track at the MOQ relay level — no segment boundary wait, no TCP buffer flush.

### 3.2 Payment Layer

| Component | Technology | Spec | Purpose |
|-----------|-----------|------|---------|
| Payment protocol | x402 | Coinbase x402 v1.0 (May 2025) | Per-impression HTTP-native payment |
| Settlement token | USDC | ERC-20 on Base | Stablecoin per-impression payment |
| Facilitator | Coinbase x402 Facilitator | REST API | Payment verification + on-chain settlement |
| Chain | Base (L2) | Coinbase/OP Stack | Sub-cent gas fees for per-impression payments |
| Testnet | Base Sepolia | Alchemy RPC | Phase 0 development environment |
| Wallet (node) | ethers.js v6 | npm | Node operator wallet management |
| Wallet (advertiser) | Coinbase Smart Wallet | EIP-4337 | Gasless advertiser experience |

**x402 Flow in Code (simplified):**

```typescript
// Node-side x402 middleware (Express/Fastify)
app.get('/ad/segment/:id', x402Middleware({
  price: '0.0001',           // $0.0001 USDC per segment delivery
  token: USDC_BASE_ADDRESS,
  facilitatorUrl: 'https://x402.org/facilitator',
  onSuccess: async (receipt) => {
    await writeSLAProof(receipt.txHash, segmentId, Date.now());
    await mintCMXSReward(nodeOperatorAddress, REWARD_PER_DELIVERY);
  }
}));
```

**Why x402 over alternatives:**
- No user account required — payment is in the HTTP header
- Works with AI agents natively (autonomous per-impression bidding in Phase 3)
- Instant settlement on Base L2 — gas ~$0.0001, confirming in <2 seconds
- Open standard (Coinbase + Cloudflare + community) — not a vendor lock-in

### 3.3 Blockchain / Smart Contract Layer

| Component | Technology | Language | Purpose |
|-----------|-----------|----------|---------|
| CMXS Token | ERC-20 | Solidity 0.8.x | Node reward token |
| SLA Contract | Custom ERC-8004 derivative | Solidity | On-chain SLA proof |
| Node Registry | Custom registry contract | Solidity | Node operator registration + staking |
| Oracle | Chainlink Functions | JavaScript | Off-chain SLA data → on-chain proof |
| Dev framework | Foundry | Rust | Smart contract testing + deployment |
| Chain | Base Sepolia (testnet) → Base mainnet | — | L2 with <$0.001 gas |
| IPFS | Pinata | REST API | Ad creative storage (content-addressed) |

**CMXS Token Contract (core logic):**

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CMXS is ERC20, Ownable {
    uint256 public constant MAX_SUPPLY = 1_000_000_000 * 10**18; // 1B tokens
    uint256 public constant REWARD_PER_VERIFIED_DELIVERY = 1 * 10**15; // 0.001 CMXS
    
    address public slaOracle;
    mapping(address => uint256) public nodeStake;
    mapping(bytes32 => bool) public deliveryProofUsed;
    
    event DeliveryRewarded(address node, bytes32 proofHash, uint256 amount);
    event SLAProofWritten(bytes32 deliveryId, address node, uint256 latencyMs, bool slamet);
    
    constructor(address _slaOracle) ERC20("CometX Streaming Token", "CMXS") Ownable(msg.sender) {
        slaOracle = _slaOracle;
        _mint(address(this), MAX_SUPPLY * 35 / 100); // 35% node rewards pool
    }
    
    function rewardNode(
        address nodeOperator,
        bytes32 deliveryProofHash,
        uint256 latencyMs,
        bytes calldata oracleSignature
    ) external {
        require(msg.sender == slaOracle, "Only oracle");
        require(!deliveryProofUsed[deliveryProofHash], "Proof already used");
        require(latencyMs < 500, "SLA not met: latency exceeded 500ms");
        
        deliveryProofUsed[deliveryProofHash] = true;
        emit SLAProofWritten(deliveryProofHash, nodeOperator, latencyMs, true);
        
        _transfer(address(this), nodeOperator, REWARD_PER_VERIFIED_DELIVERY);
        emit DeliveryRewarded(nodeOperator, deliveryProofHash, REWARD_PER_VERIFIED_DELIVERY);
    }
    
    function burnForPremiumSlot(uint256 amount) external {
        _burn(msg.sender, amount); // burn-and-mint equilibrium
    }
}
```

**SLA Oracle (Chainlink Functions source):**

```javascript
// Chainlink Functions source — runs off-chain, writes proof on-chain
const deliveryId = args[0];
const nodeAddress = args[1];

// Fetch delivery telemetry from NetScope (Caton's telemetry layer)
const response = await Functions.makeHttpRequest({
  url: `https://netscope.catontechnology.com/delivery/${deliveryId}`,
  headers: { 'Authorization': `Bearer ${secrets.NETSCOPE_API_KEY}` }
});

const { latencyMs, timestamp, x402TxHash, segmentHash } = response.data;

// Verify x402 payment on Base
const paymentVerified = await Functions.makeHttpRequest({
  url: `https://base-sepolia.g.alchemy.com/v2/${secrets.ALCHEMY_KEY}`,
  method: 'POST',
  data: { method: 'eth_getTransactionReceipt', params: [x402TxHash] }
});

const slaMetric = {
  latencyMs,
  paymentConfirmed: paymentVerified.data.result?.status === '0x1',
  deliveryTimestamp: timestamp
};

// Return ABI-encoded result to smart contract
return Functions.encodeString(JSON.stringify(slaMetric));
```

### 3.4 Edge Node Software

| Component | Technology | Notes |
|-----------|-----------|-------|
| OS | Ubuntu 24.04 LTS | ARM64 or x86_64 |
| Hardware (Phase 0) | Raspberry Pi 5 (8GB) or cloud t3.medium | $80 device or $0.04/hr |
| MOQ Relay daemon | moq-rs (Rust) | github.com/kixelated/moq-rs |
| C3 SDK | Caton C3 Node SDK | NDA/partner license required |
| Node manager | Node.js 22 LTS | TypeScript backend |
| x402 Facilitator client | @coinbase/x402-node | npm package |
| Wallet | ethers.js v6 | Hot wallet for reward receipt |
| Metrics | Prometheus + Grafana | Latency, throughput, SLA tracking |
| Containerization | Docker Compose | Single-command node startup |
| Auto-update | Watchtower | Rolling updates to node software |

**Node startup (docker-compose.yml structure):**

```yaml
services:
  moq-relay:
    image: kixelated/moq-rs:latest
    ports: ["4433:4433/udp"]  # QUIC port
    volumes: ["./certs:/certs"]
    environment:
      - MOQ_BIND=0.0.0.0:4433
      - MOQ_CERT=/certs/cert.pem
      
  c3-agent:
    image: catontechnology/c3-node:latest  # requires partner license
    depends_on: [moq-relay]
    environment:
      - C3_RELAY_ENDPOINT=moq-relay:4433
      - C3_NETSCOPE_KEY=${NETSCOPE_KEY}
      
  x402-gateway:
    image: node:22-alpine
    command: ["node", "x402-gateway.js"]
    depends_on: [c3-agent]
    environment:
      - WALLET_PRIVATE_KEY=${NODE_WALLET_KEY}
      - CMXS_CONTRACT=${CMXS_ADDRESS}
      - BASE_RPC=${ALCHEMY_BASE_URL}
      
  node-dashboard:
    image: grafana/grafana:latest
    ports: ["3000:3000"]
```

### 3.5 Player / Client Layer

| Component | Technology | Purpose |
|-----------|-----------|---------|
| Base player | Video.js 8 + custom MOQ plugin | Main stream playback |
| MOQ client | moq-js (WASM) | WebTransport-based track subscription |
| Ad insertion | Custom AdManager class | Track switch logic at ad break |
| x402 wallet | Coinbase Smart Wallet SDK | Browser-native payment signing |
| Receipt display | Custom React overlay | Real-time "Ad delivered + verified" UX |
| Fallback | LL-HLS via hls.js | Non-QUIC browser fallback |
| Analytics | Custom beacon | Latency telemetry back to NetScope |

**Player Ad Break Logic (TypeScript):**

```typescript
class ProjectClarityAdManager {
  private moqClient: MoQClient;
  private x402Wallet: CoinbaseWallet;
  private contentTrack: string = 'sling/live/content';
  
  async handleAdBreak(adSlotId: string, durationMs: number): Promise<AdReceipt> {
    const startTime = performance.now();
    
    // 1. Request ad from auction engine via x402
    const adResponse = await fetch(`/ad/auction/${adSlotId}`, {
      headers: await this.x402Wallet.getPaymentHeader(AD_PRICE_USDC)
    });
    
    if (adResponse.status === 402) {
      // Standard x402 flow: sign payment, retry
      const paymentDetails = await adResponse.json();
      const signedPayment = await this.x402Wallet.sign(paymentDetails);
      const paidResponse = await fetch(`/ad/auction/${adSlotId}`, {
        headers: { 'X-PAYMENT': signedPayment }
      });
      return this.playAd(paidResponse, startTime);
    }
    
    return this.playAd(adResponse, startTime);
  }
  
  private async playAd(response: Response, startTime: number): Promise<AdReceipt> {
    const { adTrack, txHash, creativeCID } = await response.json();
    
    // 2. Atomic track switch — no black screen
    await this.moqClient.unsubscribe(this.contentTrack);
    await this.moqClient.subscribe(adTrack);  // QUIC: no TCP buffer drain
    
    const switchLatency = performance.now() - startTime;
    console.log(`Ad track switch: ${switchLatency.toFixed(1)}ms`);
    // Target: <500ms. HLS baseline: 2000-10000ms.
    
    // 3. Beacon latency back to NetScope for SLA verification
    await this.reportToNetScope({ txHash, latencyMs: switchLatency, adTrack });
    
    return { txHash, latencyMs: switchLatency, slaTarget: 500 };
  }
}
```

### 3.6 Backend Services

| Service | Technology | Deployment | Purpose |
|---------|-----------|------------|---------|
| API Gateway | Fastify 5 (Node.js 22) | Docker / Fly.io | Routing, auth, rate limiting |
| Ad Auction Stub | TypeScript + Redis | Co-located with gateway | <80ms mock DSP response |
| x402 Middleware | @coinbase/x402-express | npm | Payment verification at API layer |
| NetScope Bridge | REST → WebSocket adapter | Node.js | Caton telemetry → dashboard feed |
| SLA Aggregator | TypeScript cron | Node.js | Batch SLA proofs → Chainlink Functions |
| Advertiser Dashboard | Next.js 15 + Wagmi v2 | Vercel | Real-time impression proof UI |
| Node Registry API | Fastify + Postgres | Fly.io | Node registration + staking management |
| Database | PostgreSQL 17 | Supabase | Off-chain delivery log + analytics |
| Cache | Redis 7 | Upstash | Ad auction results + frequency cap state |

---

## Part 4: Implementation Instructions

### 4.1 Repository Structure

```
project-clarity/
├── packages/
│   ├── contracts/          # Solidity smart contracts (Foundry)
│   │   ├── src/
│   │   │   ├── CMXS.sol
│   │   │   ├── SLAOracle.sol
│   │   │   └── NodeRegistry.sol
│   │   ├── test/
│   │   ├── script/         # Deployment scripts
│   │   └── foundry.toml
│   │
│   ├── node/               # Edge node software
│   │   ├── src/
│   │   │   ├── moq-relay/  # MOQ relay configuration
│   │   │   ├── x402-gateway/
│   │   │   └── metrics/
│   │   ├── docker-compose.yml
│   │   └── package.json
│   │
│   ├── player/             # Modified Sling-style player
│   │   ├── src/
│   │   │   ├── moq-client/
│   │   │   ├── ad-manager/
│   │   │   └── x402-wallet/
│   │   └── package.json
│   │
│   ├── api/                # Backend API services
│   │   ├── src/
│   │   │   ├── auction/
│   │   │   ├── x402-middleware/
│   │   │   ├── sla-aggregator/
│   │   │   └── node-registry/
│   │   └── package.json
│   │
│   └── dashboard/          # Advertiser + operator dashboard
│       ├── app/            # Next.js 15 App Router
│       └── package.json
│
├── infra/
│   ├── terraform/          # Cloud infrastructure (optional Phase 0)
│   └── k8s/               # Kubernetes manifests (Phase 1+)
│
├── docs/
│   ├── architecture.md
│   └── node-setup-guide.md
│
├── pnpm-workspace.yaml
└── README.md
```

### 4.2 Sprint Plan (8 Weeks)

#### Sprint 1 (Week 1–2): Foundation & Transport

**Goal:** MOQ relay running. Player can subscribe to a live stream via WebTransport. No ads yet, no blockchain.

**Tasks:**

1. **Set up moq-rs relay**
   ```bash
   git clone https://github.com/kixelated/moq-rs
   cd moq-rs
   cargo build --release
   # Generate self-signed cert for QUIC (QUIC requires TLS)
   openssl req -x509 -newkey rsa:2048 -keyout key.pem -out cert.pem -days 365 -nodes
   # Start relay
   ./target/release/moq-relay --bind 0.0.0.0:4433 --tls-cert cert.pem --tls-key key.pem
   ```

2. **Build MOQ ingest pipeline**
   - FFmpeg → RTMP → moq-pub (publisher) that ingests and splits into Tracks/Groups/Objects
   - Test with a local video file first: `ffmpeg -re -i test.mp4 -f mpegts - | moq-pub --url moqs://localhost:4433/sling/live/content`

3. **Build MOQ WebTransport player**
   - Fork or use moq-js reference implementation
   - Verify browser can subscribe to `sling/live/content` track and play video
   - Measure baseline track-switch latency (this is the number that proves the demo)

4. **Latency benchmark harness**
   - Write a test that measures time from `unsubscribe(contentTrack)` to first frame of `subscribe(adTrack)`
   - Log results to CSV. Target: <500ms. Document baseline vs. HLS (typically 2000–8000ms).

**Acceptance Criteria:**
- [ ] MOQ relay running locally
- [ ] Browser player streams live video via WebTransport
- [ ] Track switch latency measured and logged
- [ ] Latency delta vs. HLS baseline documented

---

#### Sprint 2 (Week 3–4): Ad Insertion + x402 Payment

**Goal:** Ad break fires. x402 payment executes. Advertiser pays per impression.

**Tasks:**

1. **Ad Auction Stub**
   ```typescript
   // api/src/auction/auction.service.ts
   export async function runAuction(slotId: string, context: SlotContext): Promise<AdBid> {
     // Phase 0: stub with hardcoded response. Phase 1: real DSP integration.
     await new Promise(r => setTimeout(r, 50)); // simulate 50ms DSP round-trip
     return {
       adTrack: `sling/ad/${slotId}/winner`,
       creativeCID: 'bafybeig...', // IPFS CID of ad creative
       price: '0.0001',            // $0.0001 USDC per impression
       advertiserId: '0x...',
       ttl: 5000
     };
   }
   ```

2. **x402 Middleware Integration**
   ```typescript
   // api/src/main.ts
   import { x402Middleware } from '@coinbase/x402-express';
   
   app.get('/ad/auction/:slotId', 
     x402Middleware({
       price: '0.0001',
       token: 'USDC',
       network: 'base-sepolia',
       facilitatorUrl: 'https://x402.org/facilitator'
     }),
     auctionController.handleRequest
   );
   ```

3. **Player Ad Break Integration**
   - Wire AdManager into player at simulated ad cue points (every 5 minutes in Phase 0)
   - Implement full x402 payment flow in browser (Coinbase Smart Wallet)
   - Log: slot ID, ad track, payment tx hash, switch latency

4. **Ad Creative Storage**
   - Upload test ad creative to IPFS via Pinata
   - Deliver via MOQ object (ad creative as a single MOQ Object in a dedicated Track)

**Acceptance Criteria:**
- [ ] Ad break fires at scheduled cue points
- [ ] x402 payment completes on Base Sepolia testnet
- [ ] Transaction hash logged per impression
- [ ] Ad plays without black screen (measured <500ms switch time)

---

#### Sprint 3 (Week 5–6): Smart Contracts + SLA Oracle

**Goal:** On-chain delivery proof generated. Node earns CMXS. Advertiser can verify on Basescan.

**Tasks:**

1. **Deploy CMXS + SLA contracts**
   ```bash
   # Using Foundry
   cd packages/contracts
   forge install OpenZeppelin/openzeppelin-contracts
   forge test  # All tests must pass before deploy
   forge script script/Deploy.s.sol --rpc-url base-sepolia --broadcast
   ```

2. **Write comprehensive Foundry tests**
   ```solidity
   // contracts/test/CMXS.t.sol
   function test_RewardNode_ValidDelivery() public {
     vm.prank(slaOracle);
     cmxs.rewardNode(nodeOperator, proofHash, 250, oracleSig); // 250ms < 500ms SLA
     assertEq(cmxs.balanceOf(nodeOperator), REWARD_PER_VERIFIED_DELIVERY);
   }
   
   function test_RejectNode_SLAViolation() public {
     vm.prank(slaOracle);
     vm.expectRevert("SLA not met: latency exceeded 500ms");
     cmxs.rewardNode(nodeOperator, proofHash, 750, oracleSig); // 750ms > 500ms
   }
   
   function test_RejectDouble_Spend() public {
     // First call succeeds
     vm.prank(slaOracle);
     cmxs.rewardNode(nodeOperator, proofHash, 200, oracleSig);
     // Second call with same proof should fail
     vm.expectRevert("Proof already used");
     cmxs.rewardNode(nodeOperator, proofHash, 200, oracleSig);
   }
   ```

3. **SLA Aggregator Service**
   - Batch delivery logs from PostgreSQL every 60 seconds
   - For each batch: compute Merkle root of delivery proofs
   - Submit to Chainlink Functions for verification
   - Write verified proofs to CMXS contract

4. **NetScope Integration (Caton API)**
   - Connect to Caton NetScope telemetry API (requires C3 partner key)
   - Pull per-delivery latency measurements
   - Feed into SLA aggregator

**Acceptance Criteria:**
- [ ] All Foundry tests passing (aim for >95% coverage)
- [ ] CMXS contract deployed to Base Sepolia
- [ ] SLA proofs written on-chain after each delivery batch
- [ ] Node operator wallet balance increases after verified deliveries
- [ ] Failed SLA deliveries correctly rejected (no reward)

---

#### Sprint 4 (Week 7–8): Dashboard + Demo Polish

**Goal:** A boardroom-ready 5-minute demo showing all four proof points live.

**Tasks:**

1. **Advertiser Dashboard (Next.js 15)**
   - Real-time impression feed (WebSocket from API → dashboard)
   - Per-impression: timestamp, ad ID, latency, x402 tx hash, Basescan link
   - Running totals: total impressions, verified %, average latency, CMXS minted
   - Key visual: latency histogram (show 95th percentile <500ms vs. HLS 2000–8000ms)

2. **Node Operator Dashboard**
   - CMXS balance (reads from contract via Wagmi)
   - Deliveries today / this week
   - SLA pass rate
   - Estimated monthly CMXS earnings at current rate

3. **Demo Script Implementation**
   - Pre-load a 30-minute test stream (football highlights works well)
   - Program 3 ad breaks at minutes 2, 8, and 15
   - Each break: plays a different 30-second test ad
   - After each break: impression appears in advertiser dashboard with tx hash

4. **Side-by-Side Comparison Mode**
   - Split screen: left = HLS-based stream (baseline Sling), right = MOQ+C3 stream
   - Both hit the same ad cue point simultaneously
   - Visual proof: right side switches to ad with no black screen; left side shows the gap
   - Timestamp overlay shows exact milliseconds

5. **Latency Benchmarking Report**
   - Run 100 ad break simulations
   - Record switch latency for each
   - Generate chart: P50, P95, P99 latency for both HLS and MOQ
   - Target: MOQ P95 < 500ms vs. HLS P95 > 3000ms

**Acceptance Criteria:**
- [ ] Advertiser dashboard shows live impression feed with on-chain proof links
- [ ] Node operator sees CMXS balance updating in real time
- [ ] Side-by-side demo visually demonstrates zero black screen
- [ ] Latency benchmark report generated (100 trials)
- [ ] Full 5-minute demo script rehearsed and functional

---

## Part 5: Key Dependencies & Procurement

### 5.1 Required Licenses / APIs

| Item | Source | Timeline | Notes |
|------|--------|----------|-------|
| Caton C3 SDK | Caton Technology (partnership) | 2–4 weeks | NDA + technical evaluation required |
| Caton NetScope API key | Caton Technology | Same as above | Telemetry data for SLA oracle |
| Alchemy Base Sepolia RPC | alchemy.com | Immediate | Free tier sufficient for Phase 0 |
| Coinbase x402 Facilitator | x402.org | Immediate | Open source, testnet available now |
| Chainlink Functions subscription | chain.link | Immediate | LINK tokens needed (~$20 for testing) |
| Pinata IPFS | pinata.cloud | Immediate | Free tier: 1GB storage |
| Coinbase Smart Wallet SDK | developers.coinbase.com | Immediate | Open source |
| Supabase (Postgres) | supabase.com | Immediate | Free tier sufficient |
| Fly.io (API hosting) | fly.io | Immediate | $5/mo for Phase 0 |

### 5.2 Hardware (for physical demo)

| Item | Quantity | Cost | Purpose |
|------|----------|------|---------|
| Raspberry Pi 5 (8GB) | 2 | $80 each | Simulate EchoStar edge nodes |
| PoE HAT | 2 | $20 each | Clean power for node demo |
| 4K display | 1 | Existing | Side-by-side demo screen |
| Apple TV 4K (3rd gen) | 1 | $129 | Target deployment platform demo |

Total hardware cost for demo: ~$329.

### 5.3 Cloud Cost Estimate (8-week development)

| Service | Monthly Cost | Notes |
|---------|-------------|-------|
| Fly.io API | $15 | 2× instances |
| Supabase | $0 | Free tier |
| Alchemy | $0 | Free tier (330M compute units/mo) |
| Vercel Dashboard | $0 | Hobby tier |
| Chainlink LINK | ~$20 one-time | For oracle function calls |
| Total | ~$35/month | |

---

## Part 6: Antigravity-Specific Implementation Notes

### 6.1 Monorepo Setup

```bash
# Initialize with pnpm workspaces
pnpm init
pnpm add -w -D typescript @types/node tsx
echo "packages:\n  - 'packages/*'" > pnpm-workspace.yaml

# Create all packages
mkdir -p packages/{contracts,node,player,api,dashboard}

# TypeScript config (tsconfig.base.json)
# Use "moduleResolution": "bundler" for all packages
# Use "target": "ES2022" minimum
```

### 6.2 Environment Variables Structure

```bash
# .env.example (commit this, not .env)

# Blockchain
PRIVATE_KEY=                    # Node operator wallet (never commit real key)
ALCHEMY_BASE_SEPOLIA_URL=       # https://base-sepolia.g.alchemy.com/v2/...
CMXS_CONTRACT_ADDRESS=          # After deployment
SLA_CONTRACT_ADDRESS=           # After deployment
CHAINLINK_SUBSCRIPTION_ID=      # After creating Chainlink Functions subscription

# Caton C3
C3_API_KEY=                     # From Caton Technology partnership
NETSCOPE_API_KEY=               # From Caton Technology partnership
C3_RELAY_ENDPOINT=              # moqs://your-relay:4433

# x402
X402_FACILITATOR_URL=https://x402.org/facilitator
AD_PRICE_USDC=0.0001

# Storage
PINATA_JWT=                     # IPFS ad creative storage
SUPABASE_URL=                   # PostgreSQL connection
SUPABASE_ANON_KEY=
```

### 6.3 TypeScript Strict Mode Configuration

```json
// tsconfig.base.json
{
  "compilerOptions": {
    "strict": true,
    "noUncheckedIndexedAccess": true,
    "exactOptionalPropertyTypes": true,
    "target": "ES2022",
    "module": "ESNext",
    "moduleResolution": "bundler",
    "esModuleInterop": true,
    "skipLibCheck": true,
    "baseUrl": ".",
    "paths": {
      "@clarity/*": ["packages/*/src"]
    }
  }
}
```

### 6.4 Critical Integration Points

**MOQ + x402 Integration:**
The key architectural challenge is that x402 is an HTTP protocol and MOQ is a QUIC protocol. The integration point is:
- Ad **auction** runs over HTTP with x402 payment (TCP, standard web stack)
- Ad **delivery** runs over QUIC/MOQ (the improvement that eliminates black screens)
- The x402 `txHash` becomes the receipt that ties the HTTP auction to the QUIC delivery

This separation is correct and intentional. Do NOT try to run x402 over QUIC — it is designed for HTTP.

**MOQ Track Naming Convention:**
```
sling/{channel}/{type}/{id}

Examples:
sling/espn/live/content          → Live content track
sling/espn/ad/slot-20260524-001  → Ad creative track
sling/freestream/ad/break-1234   → FAST channel ad
```

**SLA Oracle Timing:**
Chainlink Functions has a ~30 second execution time. This means SLA proofs are batched, not per-impression real-time. For the demo, pre-batch 10 deliveries and trigger the oracle manually to show the on-chain proof writing in real time.

### 6.5 Demo Script (5 Minutes)

```
[0:00] Screen 1: Advertiser dashboard — impression counter at 0
[0:15] Start Sling-style player — content stream begins via MOQ
[0:30] Show split screen: HLS (left) vs. MOQ+C3 (right) — both streaming
[1:00] Ad break fires on both sides simultaneously
[1:02] LEFT SIDE: 2–6 second black screen visible
[1:02] RIGHT SIDE: instant ad playback — zero black screen
[1:05] Overlay: "Track switch latency: 287ms" (right) vs. "3,847ms" (left)
[2:00] Ad finishes. Switch back to content. Show: RIGHT = seamless. LEFT = jitter.
[2:15] Show Advertiser Dashboard: 1 impression logged
       - Timestamp: 09:47:23
       - Ad ID: slot-20260524-001
       - Latency: 287ms ✅ SLA Met
       - x402 Tx: 0x7a3b... [click → opens Basescan]
[2:45] Basescan shows: USDC transfer $0.0001 from advertiser → x402 facilitator
[3:00] Show Node Dashboard: CMXS balance +0.001 CMXS (reward for verified delivery)
[3:30] Trigger second ad break — repeat the comparison
[4:00] Show latency histogram: 100 trials, MOQ P95 = 312ms, HLS P95 = 4,100ms
[4:30] "Every impression is a cryptographic fact. Every delivery proves the SLA."
[5:00] Q&A
```

---

## Part 7: Phase 0 → Phase 1 Upgrade Path

Phase 0 proves the concept. Phase 1 scales it. Here is the exact upgrade path for each component:

| Component | Phase 0 (Prototype) | Phase 1 (Pilot: 50–500 nodes) |
|-----------|--------------------|-----------------------------|
| Nodes | 1 Raspberry Pi / local machine | 50–500 actual EchoStar tower installs |
| MOQ Relay | moq-rs (open source) | Caton C3 production relay cluster |
| Ad Auction | Stub (50ms hardcoded) | Real DSP integration (Google Ad Manager DAI API) |
| x402 Token | USDC testnet | USDC mainnet on Base |
| CMXS Token | Base Sepolia testnet | Base mainnet, ICO presale |
| SLA Oracle | Chainlink Functions (manual trigger) | Automated Chainlink Automation |
| Player | Web browser (demo) | Apple TV app, Fire TV app, Android TV |
| Infrastructure | Developer laptops / Fly.io | AWS us-east-1 + Cloudflare Tunnels |
| Monitoring | Grafana local | Datadog + PagerDuty |
| Security | Development keys | HSM-managed keys, audit required |

### Phase 1 ICO Prerequisites (Checklist)

Before the ICO presale can open, Phase 0 must produce:
- [ ] Latency benchmark report (100+ trials, P95 < 500ms documented)
- [ ] 10+ on-chain SLA proofs on Base mainnet (real impressions, not testnet)
- [ ] CMXS tokenomics audit (Spearbit or Trail of Bits)
- [ ] Smart contract audit (same auditors)
- [ ] At least 1 real TowerCo JV term sheet signed
- [ ] At least 1 FAST/CTV publisher letter of intent for production deployment

---

## Part 8: Risk Register

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|-----------|
| Caton C3 SDK access delayed | Medium | High | Begin with open-source moq-rs; C3 enhances but does not block Phase 0 |
| QUIC blocked by enterprise firewalls | Medium | Medium | LL-HLS fallback implemented from Sprint 1 |
| Chainlink Functions latency | Low | Medium | Batch proofs every 60s; real-time UX uses off-chain log |
| Base network congestion | Low | Low | L2 gas is <$0.001; congestion rare on Base |
| x402 facilitator downtime | Low | Medium | Implement retry logic + local fallback receipt |
| Apple TV WebTransport support | Medium | Medium | Phase 0 demo on web browser; TV apps in Phase 1 |
| MOQ spec changes (IETF draft) | Medium | Low | Pin to draft-08; monitor IETF moq-wg mailing list |

---

## Part 9: Success Metrics

The prototype is a success when it can demonstrate ALL of the following in a single uninterrupted demo:

| Metric | Target | How Measured |
|--------|--------|-------------|
| Ad track switch latency (P50) | < 300ms | Instrumented player timestamp log |
| Ad track switch latency (P95) | < 500ms | Same |
| HLS baseline comparison | > 2000ms P50 | Side-by-side split screen |
| x402 payment confirmation | < 2 seconds | Block explorer confirmation time |
| On-chain impression receipt | 100% of verified deliveries | Smart contract event logs |
| CMXS reward to node | 0.001 CMXS per verified delivery | Contract balance delta |
| SLA violation rejection | 0 rewards for >500ms deliveries | Test with throttled network |
| Advertiser audit trail | Every impression linkable to Basescan tx | Dashboard click-through |

---

## Appendix A: Key Open Source Repositories

| Repo | URL | Purpose |
|------|-----|---------|
| moq-rs | github.com/kixelated/moq-rs | Rust MOQ relay + publisher |
| moq-js | github.com/kixelated/moq-js | JavaScript/WASM MOQ player |
| x402 | github.com/coinbase/x402 | x402 protocol + Node.js middleware |
| foundry | github.com/foundry-rs/foundry | Solidity testing framework |
| wagmi | github.com/wevm/wagmi | React hooks for Ethereum |
| OpenZeppelin | github.com/OpenZeppelin/openzeppelin-contracts | Audited ERC-20 base |

## Appendix B: Glossary

| Term | Definition |
|------|-----------|
| MOQ | Media over QUIC — IETF draft protocol for sub-second media delivery |
| QUIC | UDP-based transport replacing TCP for low-latency streams (RFC 9000) |
| SSAI | Server-Side Ad Insertion — current HLS-based Sling architecture |
| DAI | Dynamic Ad Insertion — ad decision at stream time |
| x402 | HTTP 402-based micropayment protocol (Coinbase, 2025) |
| CMXS | CometX Streaming Token — EchoSphere/SlingDePIN reward token |
| SLA | Service Level Agreement — here: <500ms delivery latency guarantee |
| DePIN | Decentralized Physical Infrastructure Network |
| CE-MoQ | Caton Enhanced MoQ — commercial implementation of IETF MoQ with SLA guarantees |
| ERC-8004 | Custom SLA proof smart contract standard (EchoSphere proposal) |
| TowerCo | Tower company (Crown Castle, SBA, American Tower) — JV infrastructure partners |

