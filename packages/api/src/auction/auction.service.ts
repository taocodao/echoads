import type { AdBid, SlotContext } from "@clarity/shared";
import { buildAdTrackName } from "@clarity/shared";

/**
 * Phase 0 ad auction stub.
 * Simulates a 50ms DSP round-trip and returns a hardcoded winning bid.
 * Phase 1: Replace with real DSP integration (Google Ad Manager DAI API, etc.)
 */

const TEST_ADS: AdBid[] = [
  {
    adId: "spot-clarity-001",
    adTrackName: buildAdTrackName("spot-clarity-001"),
    adNamespace: "sling/ads",
    creativePath: "./assets/ads/ad-001.mp4",
    durationMs: 30_000,
    priceUsdc: "0.0001",
    advertiserId: "0xDemo000000000000000000000000000000000001",
    expiresAt: Date.now() + 5_000, // refreshed per request below
  },
  {
    adId: "spot-clarity-002",
    adTrackName: buildAdTrackName("spot-clarity-002"),
    adNamespace: "sling/ads",
    creativePath: "./assets/ads/ad-002.mp4",
    durationMs: 15_000,
    priceUsdc: "0.0001",
    advertiserId: "0xDemo000000000000000000000000000000000002",
    expiresAt: Date.now() + 5_000,
  },
  {
    adId: "spot-clarity-003",
    adTrackName: buildAdTrackName("spot-clarity-003"),
    adNamespace: "sling/ads",
    creativePath: "./assets/ads/ad-003.mp4",
    durationMs: 30_000,
    priceUsdc: "0.0001",
    advertiserId: "0xDemo000000000000000000000000000000000003",
    expiresAt: Date.now() + 5_000,
  },
];

let adIndex = 0;

export async function runAuction(slotId: string, _context: Partial<SlotContext>): Promise<AdBid> {
  // Simulate DSP round-trip latency (~50ms)
  await new Promise((r) => setTimeout(r, 50));

  // Round-robin through test ads for demo variety
  const ad = TEST_ADS[adIndex % TEST_ADS.length]!;
  adIndex++;

  return {
    ...ad,
    // Refresh TTL for each auction response
    expiresAt: Date.now() + 5_000,
  };
}
