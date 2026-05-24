// ============================================================
// Project Clarity — Shared Constants
// ============================================================

// ----- SLA Configuration -----
/** Maximum allowed ad track-switch latency in ms. Deliveries above this fail SLA. */
export const SLA_LATENCY_THRESHOLD_MS = 500;

/** CMXS reward per verified delivery (0.001 CMXS in wei) */
export const CMXS_REWARD_PER_DELIVERY = BigInt("1000000000000000"); // 1e15 wei = 0.001 CMXS

/** CMXS max total supply (1 billion tokens) */
export const CMXS_MAX_SUPPLY = BigInt("1000000000") * BigInt(10 ** 18);

// ----- Blockchain -----
/** Base Sepolia chain ID */
export const BASE_SEPOLIA_CHAIN_ID = 84532;

/** CAIP-2 identifier for Base Sepolia */
export const BASE_SEPOLIA_CAIP2 = "eip155:84532";

/** USDC contract address on Base Sepolia (official Circle deployment) */
export const USDC_BASE_SEPOLIA = "0x036CbD53842c5426634e7929541eC2318f3dCF7e" as const;

// ----- x402 Payment -----
/** Ad impression price in USDC (string to avoid float precision loss) */
export const AD_PRICE_USDC = "0.0001";

/** x402 free testnet facilitator — no API key required */
export const X402_FACILITATOR_URL = "https://x402.org/facilitator";

// ----- MOQ Track Naming -----
/** Namespace for all Project Clarity tracks */
export const MOQ_NAMESPACE = "sling/live" as const;

/** Content track name */
export const MOQ_CONTENT_TRACK = "content" as const;

/** Ad track name prefix — appended with ad ID */
export const MOQ_AD_TRACK_PREFIX = "sling/ads/" as const;

/** Helper: build a MOQ ad track name from an ad ID */
export function buildAdTrackName(adId: string): string {
  return `${MOQ_AD_TRACK_PREFIX}${adId}`;
}

// ----- Demo -----
/** Ad break interval for Phase 0 demo (every 5 minutes) */
export const DEMO_AD_BREAK_INTERVAL_MS = 5 * 60 * 1000;

/** SLA batch submission interval (every 60 seconds) */
export const SLA_BATCH_INTERVAL_MS = 60 * 1000;

/** Proof expiry window — proofs must be submitted within this time */
export const PROOF_EXPIRY_SECONDS = 3600; // 1 hour
