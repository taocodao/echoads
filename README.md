# Project Clarity — SlingDePIN Phase 0

**Sub-500ms MOQ ad insertion · x402 micropayments · On-chain SLA proofs · CMXS node rewards**

---

## What This Proves

| Proof Point | Technology | Target |
|-------------|-----------|--------|
| Sub-500ms ad insertion | QUIC/MOQ track switch | P95 < 500ms (vs HLS P95 > 3000ms) |
| Per-impression payment | x402 on Base Sepolia | < 2s settlement |
| On-chain delivery receipt | DeliveryOracle.sol (Base Sepolia) | 100% of verified deliveries |
| Node operator reward | CMXS ERC-20 | 0.001 CMXS per verified delivery |

---

## Quick Start

### Prerequisites
- Node.js 22+ and pnpm 9+
- Rust (for moq-rs) — WSL2 on Windows
- Foundry (for smart contracts)
- A funded Base Sepolia wallet (see Setup section)

### 1. Clone and install
```bash
git clone <repo-url> project-clarity
cd project-clarity
cp .env.example .env        # Fill in your values
pnpm install
```

### 2. Set up smart contracts
```bash
# Install Foundry
curl -L https://foundry.paradigm.xyz | bash && foundryup

# Install OpenZeppelin v5
cd packages/contracts
forge install OpenZeppelin/openzeppelin-contracts@v5.1.0 --no-commit

# Run tests
forge test -vv

# Deploy to Base Sepolia (fund wallet first — see Setup)
forge script script/Deploy.s.sol:Deploy \
  --rpc-url base_sepolia \
  --broadcast \
  --private-key $DEPLOYER_PRIVATE_KEY \
  --verify \
  --etherscan-api-key $BASESCAN_API_KEY
```

### 3. Set up MOQ relay (WSL2)
```bash
# In WSL2 terminal:
bash packages/node/scripts/setup-relay.sh

# In PowerShell (Admin) on Windows host:
.\packages\node\scripts\setup-windows-firewall.ps1
```

### 4. Start the API and dashboard
```bash
pnpm dev
# API:       http://localhost:3001
# Dashboard: http://localhost:3000
```

### 5. Open the player
```bash
cd packages/player && pnpm dev
# Player: http://localhost:5173
```

---

## Setup: Get Testnet Accounts (~30 min)

| Item | Where | Time |
|------|-------|------|
| Base Sepolia ETH | https://www.alchemy.com/faucets/base-sepolia | 5 min |
| Testnet USDC | https://faucet.circle.com → Base Sepolia | 5 min |
| Alchemy API key | https://alchemy.com → new app | 5 min |
| Basescan API key | https://basescan.org/register | 5 min |
| Supabase project | https://supabase.com | 10 min |
| Deployer wallet | `cast wallet new` (dev only — no real funds) | 2 min |

---

## Architecture

```
HTTP (x402)    →  Ad Auction API  →  { adTrackName, txHash }
                                          ↓
QUIC (MOQ)     →  Track Switch    →  Zero black-screen ad play
                                          ↓
On-chain       →  DeliveryOracle  →  CMXS reward to node
```

See [docs/architecture.md](docs/architecture.md) for the full 12-step flow.

---

## Package Structure

| Package | Purpose |
|---------|---------|
| `@clarity/shared` | Types, MoqTransport interface, constants |
| `@clarity/contracts` | Solidity: CMXS, DeliveryOracle, NodeRegistry |
| `@clarity/api` | Hono server: auction, x402, SLA aggregator |
| `@clarity/player` | Browser: MOQ player, AdManager, wallet |
| `@clarity/dashboard` | Next.js 15: advertiser + node dashboards |

---

## Caton C3 Integration (Phase 1)

All MOQ relay calls go through the `MoqTransport` interface in `@clarity/shared`.
Phase 0 uses `OpenSourceMoqTransport` (kixelated/moq-rs).
When the Caton C3 SDK is available:

1. Implement `CatonC3Transport` in `packages/shared/src/transport/CatonC3Transport.ts`
2. Change one line in the player: `new CatonC3Transport()` instead of `new OpenSourceMoqTransport()`
3. No other changes needed — AdManager, API, and dashboard are unaffected.

---

## Demo Script (5 minutes)

See [docs/demo-script.md](docs/demo-script.md) for the full boardroom demo walkthrough.
