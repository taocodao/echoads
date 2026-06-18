/**
 * ivt.route.ts — IVT Fraud Scoring (Module 7)
 * POST /api/ai/ivt/score  — score a delivery for invalid traffic
 * GET  /api/ai/ivt/flagged — list flagged deliveries
 * GET  /api/ai/ivt/stats   — IVT stats summary
 */
import { Hono } from "hono";
import { pool } from "../database/db.js";

export const ivtRouter = new Hono();

interface CompletionFeatures {
  completionTimeMs: number;    // how fast they completed the ad
  completionPercent: number;   // 0–1
  tapCount: number;            // behavioral interactions during ad
  deviceSeen24h: number;       // how many times same device seen today
  geoMismatch: boolean;        // IP geo vs stated geo mismatch
}

// Isolation Forest-style rule-based scorer (Phase 3 stub; replace with ML model in Phase 4)
function scoreIVT(features: CompletionFeatures): number {
  let score = 0;

  // Impossibly fast completion
  if (features.completionTimeMs < 500) score += 0.40;
  else if (features.completionTimeMs < 2000) score += 0.15;

  // Low completion rate suggests ad stacking
  if (features.completionPercent < 0.25) score += 0.25;

  // No behavioral signals during playback — bot indicator
  if (features.tapCount === 0 && features.completionPercent > 0.9) score += 0.20;

  // Click farm — same device seen many times
  if (features.deviceSeen24h > 20) score += 0.35;
  else if (features.deviceSeen24h > 10) score += 0.15;

  // Geo mismatch
  if (features.geoMismatch) score += 0.20;

  return Math.min(1.0, score);
}

// Score a delivery
ivtRouter.post("/score", async (c) => {
  const body = await c.req.json<{
    deliveryId: string;
    features: CompletionFeatures;
  }>();

  if (!body.deliveryId) return c.json({ error: "deliveryId required" }, 400);

  const ivtScore = scoreIVT(body.features);
  const isFlagged = ivtScore > 0.8;

  try {
    await pool.query(
      `INSERT INTO ivt_scores (delivery_id, ivt_score, features)
       VALUES ($1, $2, $3)
       ON CONFLICT DO NOTHING`,
      [body.deliveryId, ivtScore, JSON.stringify(body.features)]
    );

    // Flag the delivery in the deliveries table if suspect
    if (isFlagged) {
      await pool.query(
        "UPDATE deliveries SET oracle_submitted=FALSE WHERE delivery_id=$1",
        [body.deliveryId]
      );
    }

    return c.json({ deliveryId: body.deliveryId, ivtScore, isFlagged });
  } catch (err: any) {
    return c.json({ error: err.message }, 500);
  }
});

// List flagged deliveries
ivtRouter.get("/flagged", async (c) => {
  try {
    const r = await pool.query(
      `SELECT iv.*, d.delivered_at, d.amount_usdc
       FROM ivt_scores iv
       JOIN deliveries d ON d.delivery_id = iv.delivery_id
       WHERE iv.is_flagged = TRUE
       ORDER BY iv.scored_at DESC LIMIT 50`
    );
    return c.json(r.rows);
  } catch (err: any) {
    return c.json({ error: err.message }, 500);
  }
});

// IVT stats
ivtRouter.get("/stats", async (c) => {
  try {
    const r = await pool.query(
      `SELECT
         COUNT(*) as total_scored,
         COUNT(*) FILTER (WHERE is_flagged=TRUE) as flagged,
         AVG(ivt_score) as avg_score,
         MAX(ivt_score) as max_score
       FROM ivt_scores`
    );
    const row = r.rows[0];
    const total = Number(row.total_scored);
    const flagged = Number(row.flagged);
    return c.json({
      total_scored:      total,
      flagged:           flagged,
      verified_rate:     total > 0 ? ((total - flagged) / total) : 1,
      avg_ivt_score:     Number(row.avg_score).toFixed(3),
    });
  } catch (err: any) {
    return c.json({ error: err.message }, 500);
  }
});
