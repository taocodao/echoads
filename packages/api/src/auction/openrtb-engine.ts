/**
 * openrtb-engine.ts
 * ─────────────────────────────────────────────────────────────────────────────
 * OpenRTB 2.6 bid request builder and second-price auction resolver.
 *
 * Implements:
 *   - Structured pod bidding (OpenRTB 2.6 §4.2.5)
 *   - Second-price Vickrey auction per slot
 *   - Competitive separation (no duplicate IAB top-level categories)
 *   - Floor price enforcement
 *   - Auction result persistence to PostgreSQL
 */

import { randomUUID } from "crypto";
import { fanOutBids, DSP_CONFIGS } from "./simulated-dsps.js";
import { type AdCreativeName } from "../ssai/s3-media.js";
import { pool } from "../database/db.js";

// ── OpenRTB 2.6 Type Definitions ─────────────────────────────────────────────

export interface OpenRTBVideo {
  mimes: string[];
  minduration: number;
  maxduration: number;
  protocols: number[];   // 2=VAST2, 3=VAST3, 5=VAST4, 6=VAST4.1
  w: number;
  h: number;
  linearity: number;     // 1=linear/in-stream
  podid?: string;
  podseq?: number;
  slotinpod?: number;
  mincpmpersec?: number;
}

export interface OpenRTBImp {
  id: string;
  video: OpenRTBVideo;
  bidfloor?: number;
  bidfloorcur?: string;
}

export interface BidRequest {
  id: string;
  imp: OpenRTBImp[];
  site?: {
    content?: {
      id: string;
      title: string;
      genre?: string;
      cat?: string[];
    };
    ext?: {
      channel?: { name: string };
      network?: { name: string };
    };
  };
  device?: {
    devicetype: number;   // 3 = Connected TV
    ifa?: string;
  };
  at?: number;            // auction type: 2 = second price
  tmax?: number;          // timeout in ms
}

export interface BidEntry {
  id: string;
  impid: string;
  price: number;
  adid: string;
  crid: string;
  adomain: string[];
  cat?: string[];
  w?: number;
  h?: number;
  ext?: {
    dspId: string;
    dspName: string;
    creativeKey: AdCreativeName;
    advertiser: string;
    product: string;
    price: string;
    latencyMs: number;
  };
}

export interface SeatBid {
  bid: BidEntry[];
  seat: string;
  group?: number;
}

export interface BidResponse {
  id: string;
  seatbid: SeatBid[];
  bidid: string;
  cur: string;
  nbr?: number;           // no-bid reason code
}

// ── Break Type Configuration ──────────────────────────────────────────────────

export type BreakType = "pre-game" | "halftime" | "between-plays" | "end-game" | "dynamic";

interface PodConfig {
  numSlots: number;
  slotDurationSeconds: number;
  floorCpmPerSec: number;
}

const BREAK_TYPE_CONFIG: Record<BreakType, PodConfig> = {
  "pre-game":       { numSlots: 2, slotDurationSeconds: 30, floorCpmPerSec: 1.17 },  // $35 CPM floor
  "halftime":       { numSlots: 2, slotDurationSeconds: 30, floorCpmPerSec: 1.33 },  // $40 CPM floor
  "between-plays":  { numSlots: 2, slotDurationSeconds: 15, floorCpmPerSec: 1.00 },  // $30 CPM floor
  "end-game":       { numSlots: 3, slotDurationSeconds: 30, floorCpmPerSec: 1.17 },
  "dynamic":        { numSlots: 4, slotDurationSeconds: 30, floorCpmPerSec: 1.00 },
};

// ── Auction Input/Output ──────────────────────────────────────────────────────

export interface AuctionInput {
  breakType: BreakType;
  contentId: string;
  contentGenre: string;
  sessionId: string;
  campaignId?: string;
  deviceType?: string;
  resolution?: string;
  numSlots?: number;         // override default pod slot count
}

export interface WonSlot {
  slotIndex: number;
  creativeKey: AdCreativeName;
  winningCpm: number;        // bid price (gross)
  clearingCpm: number;       // second price paid (clearing price)
  dspName: string;
  dspId: string;
  advertiser: string;
  product: string;
  price: string;             // display price for x302
  duration: number;
  category: string;
  latencyMs: number;
}

export interface AuctionResult {
  auctionId: string;
  sessionId: string;
  totalLatencyMs: number;
  breakType: BreakType;
  slots: WonSlot[];
  fillRate: number;
  bidsReceived: number;
  bidsTimedOut: number;
  bidsNoBid: number;
  timestamp: string;
}

// ── Main Auction Engine ───────────────────────────────────────────────────────

const AUCTION_TIMEOUT_MS = 500;

export async function runOpenRTBAuction(input: AuctionInput): Promise<AuctionResult> {
  const start = Date.now();
  const auctionId = `auction-${randomUUID().slice(0, 8)}`;
  const podConfig = BREAK_TYPE_CONFIG[input.breakType];
  const numSlots = input.numSlots ?? podConfig.numSlots;

  // Build OpenRTB 2.6 BidRequest with pod structure
  const bidRequest: BidRequest = {
    id: auctionId,
    at: 2, // second price
    tmax: AUCTION_TIMEOUT_MS,
    imp: Array.from({ length: numSlots }, (_, i) => ({
      id: String(i + 1),
      video: {
        mimes: ["video/mp4"],
        minduration: 10,
        maxduration: podConfig.slotDurationSeconds,
        protocols: [2, 3, 5, 6],
        w: 1920,
        h: 1080,
        linearity: 1,
        podid: `${input.breakType}_pod`,
        podseq: 1,
        slotinpod: i + 1,
        mincpmpersec: podConfig.floorCpmPerSec,
      },
      bidfloor: podConfig.floorCpmPerSec * podConfig.slotDurationSeconds,
      bidfloorcur: "USD",
    })),
    site: {
      content: {
        id: input.contentId,
        title: "CMXS LIV Golf — Round 2",
        genre: input.contentGenre,
        cat: ["IAB17", "IAB17-18"],
      },
      ext: {
        channel: { name: "CMXS LIV Golf" },
        network: { name: "CMXS Sports" },
      },
    },
    device: {
      devicetype: 3, // Connected TV
    },
  };

  // Fan out to all DSPs
  const dspResults = await fanOutBids(bidRequest, AUCTION_TIMEOUT_MS);

  // Stats
  const bidsReceived = dspResults.filter(
    (r) => r.response && r.response.seatbid.length > 0
  ).length;
  const bidsTimedOut = dspResults.filter(
    (r) => r.latencyMs >= AUCTION_TIMEOUT_MS
  ).length;
  const bidsNoBid = dspResults.length - bidsReceived - bidsTimedOut;

  // Resolve each slot via second-price auction
  const wonSlots: WonSlot[] = [];
  const usedCategories = new Set<string>();
  const usedCreatives = new Set<string>();

  for (let slotIdx = 0; slotIdx < numSlots; slotIdx++) {
    const slotId = String(slotIdx + 1);
    const floorCpm = podConfig.floorCpmPerSec * podConfig.slotDurationSeconds;

    // Collect all bids for this slot
    const candidateBids: Array<{
      bid: BidEntry;
      dspId: string;
      dspName: string;
      latencyMs: number;
    }> = [];

    for (const { dsp, response, latencyMs } of dspResults) {
      if (!response || response.seatbid.length === 0) continue;
      const seatBid = response.seatbid[0];
      if (!seatBid) continue;
      const bid = seatBid.bid.find((b) => b.impid === slotId);
      if (!bid) continue;
      if (bid.price < floorCpm) continue; // below floor
      if (usedCreatives.has(bid.crid)) continue; // frequency cap

      // Competitive separation: block same IAB top-level category in same pod
      const topCat = (bid.cat?.[0] ?? "").split("-")[0];
      if (topCat && usedCategories.has(topCat)) continue;

      candidateBids.push({ bid, dspId: dsp.id, dspName: dsp.displayName, latencyMs });
    }

    if (candidateBids.length === 0) continue; // no fill for this slot

    // Sort by price descending, break ties by latency ascending
    candidateBids.sort((a, b) =>
      b.bid.price !== a.bid.price
        ? b.bid.price - a.bid.price
        : a.latencyMs - b.latencyMs
    );

    const winner = candidateBids[0]!;
    const second = candidateBids[1];
    const clearingCpm = second ? second.bid.price : floorCpm;

    const ext = winner.bid.ext!;
    const topCat = (winner.bid.cat?.[0] ?? "IAB17").split("-")[0]!;

    usedCategories.add(topCat);
    usedCreatives.add(winner.bid.crid);

    wonSlots.push({
      slotIndex: slotIdx,
      creativeKey: ext.creativeKey,
      winningCpm: winner.bid.price,
      clearingCpm: parseFloat(Math.max(clearingCpm, floorCpm).toFixed(2)),
      dspName: winner.dspName,
      dspId: winner.dspId,
      advertiser: ext.advertiser,
      product: ext.product,
      price: ext.price,
      duration: podConfig.slotDurationSeconds,
      category: winner.bid.cat?.[0] ?? "IAB17",
      latencyMs: winner.latencyMs,
    });
  }

  const result: AuctionResult = {
    auctionId,
    sessionId: input.sessionId,
    totalLatencyMs: Date.now() - start,
    breakType: input.breakType,
    slots: wonSlots,
    fillRate: wonSlots.length / numSlots,
    bidsReceived,
    bidsTimedOut,
    bidsNoBid,
    timestamp: new Date().toISOString(),
  };

  // Persist to database (non-blocking)
  persistAuction(result).catch((err) =>
    console.warn("[auction] Failed to persist auction result:", err)
  );

  return result;
}

// ── Persistence ───────────────────────────────────────────────────────────────

async function persistAuction(result: AuctionResult): Promise<void> {
  try {
    await pool.query(
      `INSERT INTO auction_results
        (auction_id, session_id, break_type, fill_rate, bids_received,
         bids_timed_out, winning_cpm, total_latency_ms, created_at)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9)
       ON CONFLICT (auction_id) DO NOTHING`,
      [
        result.auctionId,
        result.sessionId,
        result.breakType,
        result.fillRate,
        result.bidsReceived,
        result.bidsTimedOut,
        result.slots[0]?.clearingCpm ?? 0,
        result.totalLatencyMs,
        result.timestamp,
      ]
    );
  } catch {
    // DB may not be set up in local dev — swallow gracefully
  }
}

// ── Recent Auctions ───────────────────────────────────────────────────────────

// In-memory ring buffer for dashboard (last 100 auctions)
const recentAuctions: AuctionResult[] = [];

export function recordAuction(result: AuctionResult): void {
  recentAuctions.unshift(result);
  if (recentAuctions.length > 100) recentAuctions.pop();
}

export function getRecentAuctionResults(limit = 20): AuctionResult[] {
  return recentAuctions.slice(0, limit);
}

// Stats for monitoring
export function getAuctionStats() {
  if (recentAuctions.length === 0) {
    return { avgLatencyMs: 0, avgCpm: 0, avgFillRate: 0, totalAuctions: 0 };
  }
  const n = recentAuctions.length;
  return {
    totalAuctions: n,
    avgLatencyMs: Math.round(recentAuctions.reduce((s, a) => s + a.totalLatencyMs, 0) / n),
    avgCpm: parseFloat((recentAuctions.reduce((s, a) => s + (a.slots[0]?.clearingCpm ?? 0), 0) / n).toFixed(2)),
    avgFillRate: parseFloat((recentAuctions.reduce((s, a) => s + a.fillRate, 0) / n).toFixed(3)),
    dspBreakdown: DSP_CONFIGS.map((dsp) => ({
      dspId: dsp.id,
      dspName: dsp.displayName,
      wins: recentAuctions.filter((a) => a.slots.some((s) => s.dspId === dsp.id)).length,
    })),
  };
}
