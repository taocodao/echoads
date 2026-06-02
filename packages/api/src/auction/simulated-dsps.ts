/**
 * simulated-dsps.ts
 * ─────────────────────────────────────────────────────────────────────────────
 * Five simulated Demand-Side Platforms (DSPs) for the OpenRTB 2.6 auction.
 * Each DSP has a realistic bid CPM range, response latency, and specialty.
 *
 * In production these would be replaced by real DSP integrations via
 * HTTP POST to their OpenRTB endpoints. The interface matches OpenRTB 2.6.
 */

import type { BidRequest, BidResponse, OpenRTBImp } from "./openrtb-engine.js";
import { type AdCreativeName, getAllAdCreatives } from "../ssai/s3-media.js";

// ── Types ─────────────────────────────────────────────────────────────────────

export interface DSPConfig {
  id: string;
  name: string;
  displayName: string;
  /** Min CPM this DSP bids at (USD) */
  minCpm: number;
  /** Max CPM this DSP bids at (USD) */
  maxCpm: number;
  /** Base response latency in ms */
  baseLatencyMs: number;
  /** Jitter added to latency (±) */
  latencyJitterMs: number;
  /** Probability of submitting a bid (0-1) */
  fillRate: number;
  /** Probability of timing out (0-1) */
  timeoutRate: number;
  /** IAB categories this DSP specializes in */
  specialtyCategories: string[];
  /** CPM multiplier for specialty content */
  specialtyMultiplier: number;
  /** Creative keys this DSP can serve */
  creativePool: AdCreativeName[];
}

// ── DSP Registry ──────────────────────────────────────────────────────────────

export const DSP_CONFIGS: DSPConfig[] = [
  {
    id: "ttd",
    name: "TradeDesk Sim",
    displayName: "The Trade Desk",
    minCpm: 38,
    maxCpm: 45,
    baseLatencyMs: 110,
    latencyJitterMs: 40,
    fillRate: 0.85,
    timeoutRate: 0.03,
    specialtyCategories: ["IAB17", "IAB17-18", "IAB17-15"], // Sports
    specialtyMultiplier: 1.2,
    creativePool: ["callaway_30s", "rolex_30s", "bmw_30s"],
  },
  {
    id: "dv360",
    name: "DV360 Sim",
    displayName: "Google DV360",
    minCpm: 32,
    maxCpm: 40,
    baseLatencyMs: 190,
    latencyJitterMs: 60,
    fillRate: 0.80,
    timeoutRate: 0.05,
    specialtyCategories: ["IAB1", "IAB2", "IAB18"], // Broad reach
    specialtyMultiplier: 1.0,
    creativePool: ["bmw_30s", "nike_15s", "taylormade_15s"],
  },
  {
    id: "amzn",
    name: "Amazon DSP Sim",
    displayName: "Amazon DSP",
    minCpm: 35,
    maxCpm: 42,
    baseLatencyMs: 140,
    latencyJitterMs: 50,
    fillRate: 0.82,
    timeoutRate: 0.04,
    specialtyCategories: ["IAB17", "IAB18-5", "IAB2-1"], // Commerce intent
    specialtyMultiplier: 1.15,
    creativePool: ["nike_15s", "callaway_30s", "taylormade_15s"],
  },
  {
    id: "magnite",
    name: "Magnite Sim",
    displayName: "Magnite / Roku Exchange",
    minCpm: 30,
    maxCpm: 38,
    baseLatencyMs: 170,
    latencyJitterMs: 50,
    fillRate: 0.75,
    timeoutRate: 0.06,
    specialtyCategories: ["IAB17", "IAB1-5"], // Programmatic fill
    specialtyMultiplier: 1.0,
    creativePool: ["taylormade_15s", "nike_15s"],
  },
  {
    id: "directdeal",
    name: "DirectDeal Sim",
    displayName: "LIV Golf Direct Deal",
    minCpm: 48,
    maxCpm: 55,
    baseLatencyMs: 35,
    latencyJitterMs: 15,
    fillRate: 0.92,
    timeoutRate: 0.01,
    specialtyCategories: ["IAB17-18"], // Golf only
    specialtyMultiplier: 1.3,
    creativePool: ["callaway_30s", "rolex_30s"],
  },
];

// ── Bid Simulator ─────────────────────────────────────────────────────────────

/**
 * Simulates a single DSP's response to an OpenRTB BidRequest.
 * Returns null on no-bid or timeout.
 */
export async function simulateDSPBid(
  dsp: DSPConfig,
  request: BidRequest,
  timeoutMs: number = 500
): Promise<BidResponse | null> {
  // Simulate network latency
  const latency = dsp.baseLatencyMs + (Math.random() * 2 - 1) * dsp.latencyJitterMs;

  // Check for timeout
  if (dsp.timeoutRate > Math.random()) {
    // This DSP will timeout — simulate it
    await new Promise((r) => setTimeout(r, timeoutMs + 10));
    return null;
  }

  await new Promise((r) => setTimeout(r, Math.max(0, latency)));

  // Check fill rate (no-bid)
  if (Math.random() > dsp.fillRate) {
    return { id: request.id, seatbid: [], bidid: dsp.id, cur: "USD" };
  }

  // Calculate CPM — boost if content matches specialty
  const isSpecialty = request.imp.some((imp) =>
    request.site?.content?.cat?.some((cat) =>
      dsp.specialtyCategories.some((s) => cat.startsWith(s))
    )
  );
  const multiplier = isSpecialty ? dsp.specialtyMultiplier : 1.0;
  const cpm = (dsp.minCpm + Math.random() * (dsp.maxCpm - dsp.minCpm)) * multiplier;

  // Select a creative from DSP's pool that matches slot duration
  const imp = request.imp[0]!;
  const maxDuration = imp.video?.maxduration ?? 30;
  const allCreatives = getAllAdCreatives();
  const eligible = dsp.creativePool
    .map((key) => allCreatives.find((c) => c.name === key))
    .filter((c): c is NonNullable<typeof c> => c != null && c.durationSeconds <= maxDuration);

  if (eligible.length === 0) {
    return { id: request.id, seatbid: [], bidid: dsp.id, cur: "USD" };
  }

  const creative = eligible[Math.floor(Math.random() * eligible.length)]!;

  return {
    id: request.id,
    seatbid: [{
      bid: [{
        id: `${dsp.id}-bid-${Date.now()}`,
        impid: imp.id,
        price: parseFloat(cpm.toFixed(2)),
        adid: creative.name,
        crid: `${dsp.id}-${creative.name}`,
        adomain: [dspDomain(dsp.id)],
        cat: request.site?.content?.cat ?? ["IAB17"],
        w: imp.video?.w ?? 1920,
        h: imp.video?.h ?? 1080,
        ext: {
          dspId: dsp.id,
          dspName: dsp.displayName,
          creativeKey: creative.name,
          advertiser: creative.advertiser,
          product: creative.product,
          price: creative.price,
          latencyMs: Math.round(latency),
        },
      }],
      seat: dsp.id,
      group: 0,
    }],
    bidid: dsp.id,
    cur: "USD",
  };
}

function dspDomain(dspId: string): string {
  const domains: Record<string, string> = {
    ttd: "thetradedesk.com",
    dv360: "doubleclick.net",
    amzn: "amazon.com",
    magnite: "magnite.com",
    directdeal: "cmxs.io",
  };
  return domains[dspId] ?? "unknown.com";
}

/**
 * Fan out bid requests to all DSPs in parallel, respecting the timeout.
 * Returns all successful responses (no-bid or valid bid).
 */
export async function fanOutBids(
  request: BidRequest,
  timeoutMs: number = 500
): Promise<Array<{ dsp: DSPConfig; response: BidResponse | null; latencyMs: number }>> {
  const results = await Promise.allSettled(
    DSP_CONFIGS.map(async (dsp) => {
      const start = Date.now();
      const response = await Promise.race([
        simulateDSPBid(dsp, request, timeoutMs),
        new Promise<null>((r) => setTimeout(() => r(null), timeoutMs)),
      ]);
      return { dsp, response, latencyMs: Date.now() - start };
    })
  );

  return results
    .filter((r): r is PromiseFulfilledResult<any> => r.status === "fulfilled")
    .map((r) => r.value);
}
