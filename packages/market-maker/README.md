# CMXS Market Maker — HummingbotAgent

## Overview

The HummingbotAgent maintains CMXS/USDC liquidity on Coinbase Advanced Trade using a `pure_market_making` strategy. It works alongside the on-chain `LiquidityManager` (Uniswap v3) to ensure consistent price discovery across both CEX and DEX venues.

### Architecture

```
[Uniswap v3 Pool] ←─ LiquidityManager ─→ [Gelato Automate]
        ↕
   TWAP Oracle
        ↕
[HummingbotAgent] ←─────────────────────→ [Coinbase Advanced Trade]
```

The Hummingbot instance reads the Uniswap v3 TWAP via the API price endpoint and posts orders on Coinbase within ±0.75% of that fair value.

---

## Infrastructure

- **Server**: Dedicated EC2 `t3.small` (2 vCPU, 2GB RAM) — separate from MOQ relay
- **OS**: Ubuntu 22.04 LTS
- **Storage**: 20GB SSD (logs + trade data)
- **Region**: us-east-1 (same as Coinbase servers for lowest latency)

---

## Setup

### 1. Provision EC2

```bash
# Launch t3.small Ubuntu 22.04
aws ec2 run-instances \
  --image-id ami-0866a3c8686eaeeba \
  --instance-type t3.small \
  --key-name your-key \
  --security-groups cmxs-mm-sg \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=cmxs-market-maker}]'

# Security group: allow SSH (22), Grafana (3000), Prometheus (9090)
# Block all inbound except those ports + outbound HTTPS for Coinbase API
```

### 2. Install Docker

```bash
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker ubuntu
```

### 3. Deploy

```bash
git clone https://github.com/your-org/echoads
cd packages/market-maker

cp .env.example .env
# Fill in: COINBASE_API_KEY, COINBASE_API_SECRET, HUMMINGBOT_CONFIG_PASSWORD

docker compose up -d
```

### 4. Initialize Hummingbot

```bash
docker exec -it cmxs-hummingbot bash
# Inside container:
hummingbot
# > create --script cmxs_usdc_mm.yml
# > start
```

---

## Strategy Parameters

| Parameter | Value | Rationale |
|-----------|-------|-----------|
| Bid/Ask spread | 0.75% each | Covers Coinbase 0.4% taker fee + profit |
| Order levels | 3 per side | Depth without excessive inventory risk |
| Inventory target | 50% CMXS | BME creates natural buy pressure |
| Kill switch | -15% drawdown | Automatic shutdown on catastrophic loss |
| Price source | Uniswap v3 TWAP | Prevents CEX manipulation of on-chain price |
| Price floor | $0.10 | Never bid below this (anti-crash) |
| Price ceiling | $5.00 | Never ask below this (anti-dump) |
| Refresh | 30s | Balance responsiveness vs. gas-equivalent fees |

---

## Kill Switch & Alerts

The `-15%` portfolio kill switch stops all orders automatically. After kill switch fires:

1. PagerDuty alert sent (configure `PAGERDUTY_API_KEY`)
2. All open orders cancelled on Coinbase
3. Hummingbot enters `STOPPED` state
4. Manual review required before restart

### Restart after kill switch

```bash
docker exec -it cmxs-hummingbot hummingbot
# > start  (after reviewing logs)
```

---

## Monitoring

Access Grafana at `http://YOUR_EC2_IP:3000` (admin/password from .env).

Key dashboards:
- **PnL**: cumulative realized + unrealized
- **Inventory**: CMXS vs USDC balance over time
- **Spread**: actual spread achieved vs. target
- **Fill rate**: % of orders filled per epoch

---

## Connecting to On-Chain Price Source

The `PRICE_SOURCE_URL` in `.env` must return:
```json
{"price": "1.2345"}
```

Add this endpoint to the API (reads from Uniswap v3 TWAP via public RPC):

```typescript
// packages/api/src/price/price.route.ts
app.get("/api/price/cmxs", async (c) => {
  const twap = await getTwapPrice(); // reads pool.observe([1800, 0])
  return c.json({ price: twap.toFixed(6) });
});
```

---

## Security

- API keys stored in `.env` (never in Docker image or git)
- EC2 instance has no public IP — SSH via AWS Session Manager only
- Security group: restrict Grafana to your office IP range
- Rotate Coinbase API keys every 90 days
