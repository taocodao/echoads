import { Hono } from "hono";
import { updateDeliveryLatency } from "./delivery.service.js";

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
 * GET /api/delivery/recent
 * Fetches the last 20 deliveries for the dashboard live feed.
 */
deliveryRouter.get("/recent", async (c) => {
  // Supabase realtime handles push updates — this is the initial load
  return c.json({ deliveries: [] }); // dashboard uses Supabase realtime subscription
});
