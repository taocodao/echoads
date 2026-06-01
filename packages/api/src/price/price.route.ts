/**
 * price.route.ts
 * ─────────────────────────────────────────────────────────────────────────────
 * GET /api/price/cmxs
 * Returns the 30-minute Uniswap v3 TWAP price for CMXS/USDC.
 * Used by HummingbotAgent as its CEX price reference to prevent
 * on-chain/off-chain price divergence.
 *
 * Pre-TGE: returns the AdBurnV2 fallback price from the contract.
 * Post-TGE: reads from the Uniswap v3 pool TWAP oracle.
 */

import { Hono } from "hono";
import { createPublicClient, http, parseAbi, type Address } from "viem";
import { baseSepolia, base } from "viem/chains";

export const priceRouter = new Hono();

const IS_MAINNET = process.env["CHAIN"] === "base-mainnet";
const chain      = IS_MAINNET ? base : baseSepolia;
const RPC_URL    = IS_MAINNET ? process.env["BASE_MAINNET_RPC_URL"] : process.env["BASE_SEPOLIA_RPC_URL"];

const publicClient = createPublicClient({ chain, transport: http(RPC_URL) });

// Uniswap v3 Pool ABI — observe() for TWAP
const POOL_ABI = parseAbi([
  "function observe(uint32[] calldata secondsAgos) external view returns (int56[] memory tickCumulatives, uint160[] memory secondsPerLiquidityCumulativeX128s)",
  "function slot0() external view returns (uint160 sqrtPriceX96, int24 tick, uint16, uint16, uint16, uint8, bool)",
]);

const POOL_ADDRESS = process.env["UNISWAP_V3_POOL_ADDRESS"] as Address | undefined;
const FALLBACK_PRICE = Number(process.env["CMXS_FALLBACK_PRICE_USD"] ?? "1.00");

// Cache price for 60 seconds to avoid hammering RPC
let cachedPrice: { value: number; fetchedAt: number } | null = null;
const CACHE_TTL_MS = 60_000;

/**
 * Compute TWAP from Uniswap v3 tick cumulative values.
 * Formula: price = 1.0001^tick (price of token1 in terms of token0)
 */
function tickToPrice(tick: bigint): number {
  return Math.pow(1.0001, Number(tick));
}

async function getTwapPrice(): Promise<number> {
  if (!POOL_ADDRESS) {
    return FALLBACK_PRICE;
  }

  // Return cached if fresh
  if (cachedPrice && Date.now() - cachedPrice.fetchedAt < CACHE_TTL_MS) {
    return cachedPrice.value;
  }

  try {
    // Request tick cumulatives at t=0 and t=1800 (30 min ago)
    const TWAP_PERIOD = 1800; // 30 minutes
    const [tickCumulatives] = await publicClient.readContract({
      address: POOL_ADDRESS,
      abi:     POOL_ABI,
      functionName: "observe",
      args:    [[TWAP_PERIOD, 0]],
    });

    // Average tick over the period
    const tickDiff     = (tickCumulatives[1] ?? 0n) - (tickCumulatives[0] ?? 0n);
    const avgTick      = tickDiff / BigInt(TWAP_PERIOD);
    const price        = tickToPrice(avgTick);

    cachedPrice = { value: price, fetchedAt: Date.now() };
    return price;
  } catch (err) {
    console.warn("[price] TWAP fetch failed, using fallback:", err);
    return FALLBACK_PRICE;
  }
}

/**
 * GET /api/price/cmxs
 * Response: { "price": "1.234567", "source": "twap" | "fallback", "timestamp": "..." }
 */
priceRouter.get("/cmxs", async (c) => {
  const price  = await getTwapPrice();
  const source = POOL_ADDRESS && !Number.isNaN(price) ? "twap" : "fallback";

  c.header("Cache-Control", "public, max-age=60");

  return c.json({
    price:     price.toFixed(6),
    source,
    pool:      POOL_ADDRESS ?? "not configured",
    timestamp: new Date().toISOString(),
  });
});

/**
 * GET /api/price/cmxs/health
 * Quick liveness check for monitoring.
 */
priceRouter.get("/cmxs/health", async (c) => {
  const price = await getTwapPrice();
  return c.json({
    ok:    price > 0,
    price: price.toFixed(6),
  });
});
