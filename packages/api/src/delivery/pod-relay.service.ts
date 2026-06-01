/**
 * pod-relay.service.ts
 * ─────────────────────────────────────────────────────────────────────────────
 * PoD Relay Service — the off-chain backbone of the CMXS BME flywheel.
 *
 * Pipeline:
 *   Player device  →  POST /api/delivery/pod  →  PodRelayService
 *   PodRelayService → Redis dedup check
 *   PodRelayService → Queue (in-memory buffer)
 *   PodRelayService → batch(50) or timer(60s) → batch-submitter
 *   batch-submitter → DeliveryOracleV2.verifyAndMintBatch()
 *   DeliveryOracleV2 → CMXSToken.mintReward() per node
 *
 * Deduplication:
 *   Each impressionId is checked in Redis (5-min TTL) before queuing.
 *   Duplicate submissions are rejected at this layer (no on-chain gas wasted).
 *
 * Batching:
 *   Receipts accumulate up to MAX_BATCH_SIZE (50) then flush.
 *   A 60-second timer also forces flush of partial batches to avoid stale rewards.
 *
 * Error handling:
 *   Failed batches are returned to the retry queue (max 3 attempts).
 *   After 3 failures, receipts are moved to a dead-letter store in PostgreSQL.
 */

import { markSeen } from "./redis-dedup.js";
import { submitBatch, type PoDReceiptParams } from "./batch-submitter.js";
import type { Hex } from "viem";

// ── Config ────────────────────────────────────────────────────────────────────

const MAX_BATCH_SIZE   = 50;   // matches DeliveryOracleV2.MAX_BATCH_SIZE
const FLUSH_INTERVAL_MS = 60_000; // flush partial batches every 60s
const MAX_QUEUE_SIZE    = 500;  // backpressure — reject if queue is full

// ── Queue ─────────────────────────────────────────────────────────────────────

interface QueuedReceipt {
  receipt: PoDReceiptParams;
  queuedAt: number;
  retries: number;
}

const queue: QueuedReceipt[] = [];
let flushTimer: ReturnType<typeof setInterval> | null = null;
let isFlushing = false;

// ── Public Interface ──────────────────────────────────────────────────────────

export interface EnqueueResult {
  status: "queued" | "duplicate" | "queue_full";
  queueDepth: number;
}

/**
 * Attempt to enqueue a PoD receipt from the player.
 * Returns immediately — batch submission is async.
 */
export async function enqueueReceipt(params: {
  deliveryId: string;
  impressionId: Hex;
  nodeOperator: Hex;
  cpm: number;          // USDC microunits (6 dec)
  timestampMs: number;
  latencyMs: number;
  campaignId: Hex;
}): Promise<EnqueueResult> {
  // 1. Redis dedup check
  const isNew = await markSeen(params.impressionId);
  if (!isNew) {
    console.warn(`[pod-relay] Duplicate impressionId rejected: ${params.impressionId}`);
    return { status: "duplicate", queueDepth: queue.length };
  }

  // 2. Backpressure: reject if queue is too deep
  if (queue.length >= MAX_QUEUE_SIZE) {
    console.error(`[pod-relay] Queue full (${queue.length}) — dropping receipt ${params.impressionId}`);
    return { status: "queue_full", queueDepth: queue.length };
  }

  // 3. Enqueue
  queue.push({
    receipt: {
      deliveryId:   params.deliveryId,
      impressionId: params.impressionId,
      nodeOperator: params.nodeOperator,
      cpm:          BigInt(params.cpm),
      timestampMs:  params.timestampMs,
      latencyMs:    params.latencyMs,
      campaignId:   params.campaignId,
    },
    queuedAt: Date.now(),
    retries: 0,
  });

  console.log(`[pod-relay] Queued: ${params.impressionId} (depth: ${queue.length})`);

  // 4. Flush immediately if batch is full
  if (queue.length >= MAX_BATCH_SIZE) {
    void flushBatch(); // non-blocking
  }

  return { status: "queued", queueDepth: queue.length };
}

/**
 * Flush up to MAX_BATCH_SIZE receipts from the queue and submit on-chain.
 * Idempotent — if already flushing, returns immediately.
 */
export async function flushBatch(): Promise<void> {
  if (isFlushing || queue.length === 0) return;
  isFlushing = true;

  const batch = queue.splice(0, MAX_BATCH_SIZE);
  console.log(`[pod-relay] Flushing batch of ${batch.length} receipts...`);

  try {
    const result = await submitBatch(batch.map((q) => q.receipt));
    console.log(
      `[pod-relay] ✅ Batch submitted: ${result.impressionsSubmitted} impressions, ` +
      `${result.totalMintedWei / BigInt(1e15)} mCMXS minted — ${result.basescanUrl}`
    );
  } catch (err) {
    console.error("[pod-relay] ❌ Batch submission failed:", err);

    // Re-queue with incremented retry counter
    for (const item of batch) {
      item.retries++;
      if (item.retries < 3) {
        queue.unshift(item); // push to front for next flush
        console.log(`[pod-relay] Re-queued ${item.receipt.impressionId} (retry ${item.retries}/3)`);
      } else {
        console.error(`[pod-relay] Dead-lettering ${item.receipt.impressionId} after 3 retries`);
        void _writeDeadLetter(item.receipt);
      }
    }
  } finally {
    isFlushing = false;
  }
}

// ── Lifecycle ─────────────────────────────────────────────────────────────────

/**
 * Start the 60-second timer that flushes partial batches.
 * Call once at server startup.
 */
export function startPodRelayService(): void {
  if (flushTimer) return; // already started

  flushTimer = setInterval(async () => {
    if (queue.length > 0) {
      console.log(`[pod-relay] Timer flush triggered (${queue.length} queued)`);
      await flushBatch();
    }
  }, FLUSH_INTERVAL_MS);

  console.log(`[pod-relay] Service started — batch size: ${MAX_BATCH_SIZE}, flush interval: ${FLUSH_INTERVAL_MS / 1000}s`);
}

export function stopPodRelayService(): void {
  if (flushTimer) {
    clearInterval(flushTimer);
    flushTimer = null;
  }
}

// ── Monitoring ────────────────────────────────────────────────────────────────

export interface PodRelayStatus {
  queueDepth: number;
  isFlushing: boolean;
  oracleV2Address: string;
  chain: string;
  upstashConfigured: boolean;
}

export function getPodRelayStatus(): PodRelayStatus {
  return {
    queueDepth:        queue.length,
    isFlushing,
    oracleV2Address:   process.env["DELIVERY_ORACLE_V2_ADDRESS_SEPOLIA"] ?? "(not set)",
    chain:             process.env["CHAIN"] === "base-mainnet" ? "Base Mainnet" : "Base Sepolia",
    upstashConfigured: !!(process.env["UPSTASH_REDIS_REST_URL"]),
  };
}


async function _writeDeadLetter(receipt: PoDReceiptParams): Promise<void> {
  try {
    const { writeDeadLetter } = await import("./delivery.service.js");
    await writeDeadLetter({
      impressionId: receipt.impressionId,
      nodeOperator: receipt.nodeOperator,
      campaignId:   receipt.campaignId,
      cpm:          receipt.cpm.toString(),
      timestampMs:  receipt.timestampMs,
      latencyMs:    receipt.latencyMs,
    });
  } catch {
    console.error(`[pod-relay] Dead-letter DB write failed for ${receipt.impressionId}`);
  }
}
