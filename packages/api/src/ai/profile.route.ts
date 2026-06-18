/**
 * profile.route.ts — Viewer Profile Sync
 * POST /api/ai/profile/sync  — upsert a viewer profile from the app
 * GET  /api/ai/profile/:token — retrieve profile for a viewer
 */
import { Hono } from "hono";
import { pool } from "../database/db.js";

export const profileRouter = new Hono();

// Upsert viewer profile (called from app on session end or tab switch)
profileRouter.post("/sync", async (c) => {
  const body = await c.req.json<{
    viewerToken: string;
    segmentId: string;
    viewerScore: number;
    sportAffinities: Record<string, number>;
    engagementDepth: number;
    totalWatchHours?: number;
    sessionFrequency?: number;
    adCompletionRate?: number;
    predictionRate?: number;
    signalsJson?: Record<string, unknown>;
  }>();

  if (!body.viewerToken) return c.json({ error: "viewerToken required" }, 400);

  try {
    await pool.query(
      `INSERT INTO viewer_profiles
         (viewer_token, segment_id, viewer_score, sport_affinities, engagement_depth,
          total_watch_hours, session_frequency, ad_completion_rate, prediction_rate,
          signals_json, last_active_at, updated_at)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,NOW(),NOW())
       ON CONFLICT (viewer_token) DO UPDATE SET
         segment_id       = EXCLUDED.segment_id,
         viewer_score     = EXCLUDED.viewer_score,
         sport_affinities = EXCLUDED.sport_affinities,
         engagement_depth = EXCLUDED.engagement_depth,
         total_watch_hours= EXCLUDED.total_watch_hours,
         session_frequency= EXCLUDED.session_frequency,
         ad_completion_rate=EXCLUDED.ad_completion_rate,
         prediction_rate  = EXCLUDED.prediction_rate,
         signals_json     = EXCLUDED.signals_json,
         last_active_at   = NOW(),
         updated_at       = NOW()`,
      [
        body.viewerToken, body.segmentId, body.viewerScore,
        JSON.stringify(body.sportAffinities), body.engagementDepth,
        body.totalWatchHours ?? 0, body.sessionFrequency ?? 0,
        body.adCompletionRate ?? 0, body.predictionRate ?? 0,
        JSON.stringify(body.signalsJson ?? {}),
      ]
    );
    return c.json({ status: "synced", segment: body.segmentId });
  } catch (err: any) {
    return c.json({ error: err.message }, 500);
  }
});

// Get profile
profileRouter.get("/:token", async (c) => {
  try {
    const r = await pool.query(
      "SELECT * FROM viewer_profiles WHERE viewer_token=$1", [c.req.param("token")]
    );
    if (r.rows.length === 0) return c.json({ error: "not found" }, 404);
    return c.json(r.rows[0]);
  } catch (err: any) {
    return c.json({ error: err.message }, 500);
  }
});

// Top segments breakdown (for advertiser dashboard)
profileRouter.get("/segments/breakdown", async (c) => {
  try {
    const r = await pool.query(
      `SELECT segment_id, COUNT(*) as count, AVG(viewer_score) as avg_score
       FROM viewer_profiles GROUP BY segment_id ORDER BY segment_id`
    );
    return c.json(r.rows);
  } catch (err: any) {
    return c.json({ error: err.message }, 500);
  }
});
