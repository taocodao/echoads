# Gelato Automate — CMXS System Setup

## Overview

Two Gelato tasks are required for the CMXS system:

| Task | Trigger | Action | Gas |
|------|---------|--------|-----|
| LP Rebalancer | `checkRebalanceNeeded()` returns true | `LiquidityManager.rebalance()` | ~$0.10-0.50 |
| Epoch Distributor | Time-based: every Monday 00:00 UTC | `Treasury.distributeEpochFees()` | ~$0.02 |

---

## Task 1: Uniswap v3 LP Rebalancer

### Setup at app.gelato.network

1. Go to [app.gelato.network](https://app.gelato.network) → **Create Task**
2. Select **Automated → Resolver (on-chain condition)**
3. Configure:
   ```
   Chain:           Base Mainnet (8453)
   Resolver Contract: LiquidityManager address
   Resolver Function: checkRebalanceNeeded() → returns bool
   Task Contract:   LiquidityManager address
   Task Function:   rebalance()
   Task Name:       CMXS/USDC LP Rebalancer
   ```
4. Fund the Gelato treasury:
   - Deposit minimum 0.05 ETH on Base to the Gelato treasury
   - Each rebalance costs ~$0.10-0.50 in gas at standard Base fees

5. Set `automationKeeper` in LiquidityManager:
   ```bash
   # Get Gelato dedicated msg.sender for your task (shown in Gelato UI after creation)
   cast send $LIQUIDITY_MANAGER_ADDRESS \
     "setAutomationKeeper(address)" \
     $GELATO_DEDICATED_SENDER \
     --rpc-url $BASE_MAINNET_RPC_URL \
     --private-key $DEPLOYER_PRIVATE_KEY
   ```

### Via Gelato SDK (programmatic)

```typescript
import { GelatoRelay } from "@gelatonetwork/relay-sdk";

const relay = new GelatoRelay();

// Create resolver task
const task = await relay.createTask({
  chainId:          8453n,
  target:           LIQUIDITY_MANAGER_ADDRESS,
  data:             encodeFunctionData({ abi: LM_ABI, functionName: "rebalance" }),
  isPrivate:        true,  // use Flashbots Protect RPC — prevents sandwich attacks
  resolverAddress:  LIQUIDITY_MANAGER_ADDRESS,
  resolverData:     encodeFunctionData({ abi: LM_ABI, functionName: "checkRebalanceNeeded" }),
});

console.log("Task ID:", task.taskId);
```

> [!IMPORTANT]
> Set `isPrivate: true` so rebalance transactions go through Flashbots Protect RPC.
> This prevents MEV bots from sandwiching the LP position change.

---

## Task 2: Weekly Epoch Fee Distributor

1. Go to [app.gelato.network](https://app.gelato.network) → **Create Task**
2. Select **Automated → Time-based**
3. Configure:
   ```
   Chain:          Base Mainnet (8453)
   Target Contract: Treasury address
   Function:       distributeEpochFees()
   Schedule:       0 0 * * 1   (every Monday at 00:00 UTC)
   Task Name:      CMXS Weekly Fee Distribution
   ```

4. The Treasury `TREASURER_ROLE` must be granted to the Gelato automate contract:
   ```bash
   # Get Gelato automate contract address for Base:
   # 0x2A6C106ae13B558BB9E2Ec64Bd2f1f7BEFF3A5E0 (check docs for latest)
   cast send $TREASURY_ADDRESS \
     "grantRole(bytes32,address)" \
     $(cast keccak "TREASURER_ROLE") \
     0x2A6C106ae13B558BB9E2Ec64Bd2f1f7BEFF3A5E0 \
     --rpc-url $BASE_MAINNET_RPC_URL \
     --private-key $DEPLOYER_PRIVATE_KEY
   ```

---

## Monitoring

After setup, Gelato tasks appear in the dashboard at [app.gelato.network/tasks](https://app.gelato.network/tasks).

Key metrics to watch:
- **Execution history**: confirm rebalances triggered correctly after price moves
- **Gas spend**: alert if >$1.00 per rebalance (indicates very active market)
- **Treasury balance**: keep >0.05 ETH to avoid task stalling

### Prometheus Alert (add to alerts.yml)

```yaml
groups:
  - name: gelato
    rules:
      - alert: GelatoTreasuryLow
        expr: gelato_treasury_eth_balance < 0.05
        for: 5m
        annotations:
          summary: "Gelato treasury below 0.05 ETH — tasks may stall"
```
