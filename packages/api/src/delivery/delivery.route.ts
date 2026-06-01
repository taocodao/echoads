import { Hono } from "hono";
import { updateDeliveryLatency, logDelivery } from "./delivery.service.js";
import { enqueueReceipt, getPodRelayStatus } from "./pod-relay.service.js";
import type { Hex } from "viem";

export const deliveryRouter = new Hono();

/**
 * POST /api/delivery/beacon
 * Player beacons back the measured track-switch latency after an ad plays.
 * This completes the delivery record and enables SLA assessment.
 */
deliveryRouter.post("/beacon", async (c) => {
  const body = await c.req.json<{ txHash: string; switchLatencyMs: number }>();

  if (!body.txHash || typeof body.switchLatencyMs !== "number") {
    return c.json({ error: "txHash and switchLatencyMs required" }, 400);
  }

  await updateDeliveryLatency(body.txHash, body.switchLatencyMs);

  const slaMet = body.switchLatencyMs < 500;
  console.log(
    `[delivery-beacon] txHash=${body.txHash} latency=${body.switchLatencyMs}ms SLA=${slaMet ? "✅" : "❌"}`
  );

  return c.json({ success: true, slaMet, switchLatencyMs: body.switchLatencyMs });
});

/**
 * POST /api/delivery/pod
 * Viewer player submits a PoD receipt for batch processing.
 * This is the main entry point into the DeliveryOracleV2 pipeline.
 *
 * Body:
 *   impressionId  — bytes32 hex   (unique impression)
 *   nodeOperator  — address hex   (delivery node)
 *   cpm           — number        (USDC microunits, 6 dec)
 *   timestampMs   — number        (Unix ms from viewer device)
 *   latencyMs     — number        (measured track-switch latency)
 *   campaignId    — bytes32 hex   (links to AdBurnV2 campaign)
 *   slotId        — string        (for delivery.service.ts logging)
 *   txHash        — string        (x402 payment tx hash)
 *   payerAddress  — string        (advertiser wallet)
 *   amountUsdc    — string        (USDC amount paid)
 */
deliveryRouter.post("/pod", async (c) => {
  const body = await c.req.json<{
    impressionId: Hex;
    nodeOperator: Hex;
    cpm: number;
    timestampMs: number;
    latencyMs: number;
    campaignId: Hex;
    slotId?: string;
    txHash?: string;
    payerAddress?: string;
    amountUsdc?: string;
  }>();

  // Validate required fields
  if (!body.impressionId || !body.nodeOperator || !body.cpm || !body.timestampMs || !body.campaignId) {
    return c.json({ error: "Missing required fields: impressionId, nodeOperator, cpm, timestampMs, campaignId" }, 400);
  }

  // Log to PostgreSQL for audit trail
  let deliveryId = `pod-${body.impressionId}-${Date.now()}`;
  try {
    if (body.slotId && body.txHash && body.payerAddress && body.amountUsdc) {
      deliveryId = await logDelivery({
        slotId:          body.slotId,
        txHash:          body.txHash,
        payerAddress:    body.payerAddress,
        amountUsdc:      body.amountUsdc,
        switchLatencyMs: body.latencyMs,
      });
    }
  } catch (err) {
    console.warn("[delivery-pod] DB log failed (non-critical):", err);
  }

  // Enqueue for batch relay — dedup + queue
  const result = await enqueueReceipt({
    deliveryId,
    impressionId: body.impressionId,
    nodeOperator: body.nodeOperator,
    cpm:          body.cpm,
    timestampMs:  body.timestampMs,
    latencyMs:    body.latencyMs,
    campaignId:   body.campaignId,
  });

  const statusCode = result.status === "queue_full" ? 429 : 202;
  return c.json({
    status:     result.status,
    queueDepth: result.queueDepth,
    message:    result.status === "duplicate"
      ? "Impression already processed"
      : result.status === "queue_full"
      ? "Queue full — retry later"
      : "Receipt queued for batch submission",
  }, statusCode);
});

/**
 * GET /api/delivery/relay-status
 * Returns current PoD relay queue depth and config.
 * Used by Grafana dashboard and alerting.
 */
deliveryRouter.get("/relay-status", (c) => {
  return c.json(getPodRelayStatus());
});

/**
 * GET /api/delivery/recent
 * Fetches the last 20 deliveries for the dashboard live feed.
 */
deliveryRouter.get("/recent", async (c) => {
  // Supabase realtime handles push updates — this is the initial load
  return c.json({ deliveries: [] }); // dashboard uses Supabase realtime subscription
});
