/**
 * pod-manager.ts
 * ─────────────────────────────────────────────────────────────────────────────
 * Ad pod assembly manager — wraps the OpenRTB engine and provides
 * frequency capping, session-level deduplication, and stats tracking.
 */

import {
  runOpenRTBAuction,
  recordAuction,
  getRecentAuctionResults,
  getAuctionStats,
  type AuctionInput,
  type AuctionResult,
  type WonSlot,
} from "./openrtb-engine.js";

// ── Session-Level Frequency Caps ──────────────────────────────────────────────

/** Track how many times each advertiser has appeared per session */
const sessionCreativeCounts = new Map<string, Map<string, number>>();
const MAX_CREATIVE_PER_SESSION = 2;
const SESSION_TTL_MS = 4 * 60 * 60 * 1000;
const sessionExpiry = new Map<string, number>();

function getSessionCounts(sessionId: string): Map<string, number> {
  if (!sessionCreativeCounts.has(sessionId)) {
    sessionCreativeCounts.set(sessionId, new Map());
    sessionExpiry.set(sessionId, Date.now() + SESSION_TTL_MS);
  }
  return sessionCreativeCounts.get(sessionId)!;
}

function incrementCreativeCount(sessionId: string, creativeKey: string): void {
  const counts = getSessionCounts(sessionId);
  counts.set(creativeKey, (counts.get(creativeKey) ?? 0) + 1);
}

function isCreativeFreqCapped(sessionId: string, creativeKey: string): boolean {
  const counts = getSessionCounts(sessionId);
  return (counts.get(creativeKey) ?? 0) >= MAX_CREATIVE_PER_SESSION;
}

// Prune expired sessions
setInterval(() => {
  const now = Date.now();
  for (const [id, exp] of sessionExpiry) {
    if (now > exp) {
      sessionCreativeCounts.delete(id);
      sessionExpiry.delete(id);
    }
  }
}, 30 * 60 * 1000);

// ── Main Pod Manager ──────────────────────────────────────────────────────────

export interface PodAuctionInput extends AuctionInput {
  sessionId: string;
}

export interface PodAuctionResult {
  auctionId: string;
  totalLatencyMs: number;
  slots: Array<WonSlot & { freqCapApplied: boolean }>;
  fillRate: number;
  bidsReceived: number;
  bidsTimedOut: number;
  bidsNoBid: number;
  timestamp: string;
  breakType: string;
}

/**
 * Run a complete pod auction with session-level frequency capping.
 * This is the primary entry point for SSAI and the simulation runner.
 */
export async function runPodAuction(input: PodAuctionInput): Promise<PodAuctionResult> {
  const result: AuctionResult = await runOpenRTBAuction(input);

  // Apply session-level frequency caps and increment counters
  const slotsWithCap = result.slots.map((slot) => {
    const freqCapApplied = isCreativeFreqCapped(input.sessionId, slot.creativeKey);
    if (!freqCapApplied) {
      incrementCreativeCount(input.sessionId, slot.creativeKey);
    }
    return { ...slot, freqCapApplied };
  });

  // Filter out freq-capped slots (they're "unfilled" for this pod)
  const activeSlots = slotsWithCap.filter((s) => !s.freqCapApplied);

  // Record in ring buffer for dashboard
  const finalResult: AuctionResult = { ...result, slots: activeSlots };
  recordAuction(finalResult);

  return {
    auctionId: result.auctionId,
    totalLatencyMs: result.totalLatencyMs,
    slots: slotsWithCap,
    fillRate: activeSlots.length / Math.max(result.slots.length, 1),
    bidsReceived: result.bidsReceived,
    bidsTimedOut: result.bidsTimedOut,
    bidsNoBid: result.bidsNoBid,
    timestamp: result.timestamp,
    breakType: result.breakType,
  };
}

// ── Re-exports for routes ─────────────────────────────────────────────────────

export { getRecentAuctionResults, getAuctionStats };
