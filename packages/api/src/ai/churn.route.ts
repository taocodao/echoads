/**
 * churn.route.ts — Churn Scoring & Push Triggers (Module 4)
 * POST /api/ai/churn/score  — batch score all viewer profiles
 * GET  /api/ai/churn/high   — list high-risk viewers pending push
 * POST /api/ai/churn/push   — mark push sent for a viewer
 */
import { Hono } from "hono";
import { pool } from "../database/db.js";

export const churnRouter = new Hono();

// Rule-based churn scoring (mirrors ChurnPredictor.swift)
function scoreChurnRisk(profile: {
  session_frequency: number;
  ad_completion_rate: number;
  engagement_depth: number;
  last_active_at: string;
}): { risk: number; tier: "low" | "low_med" | "medium" | "high" } {
  let score = 0.5;

  // Days since last active
  const daysSince = (Date.now() - new Date(profile.last_active_at).getTime()) / 86400000;
  if (daysSince > 14) score += 0.30;
  else if (daysSince > 7) score += 0.15;
  else if (daysSince > 3) score += 0.08;

  // Session frequency
  if (profile.session_frequency < 1)  score += 0.20;
  else if (profile.session_frequency < 3) score += 0.08;

  // Ad completion
  if (profile.ad_completion_rate < 0.3) score += 0.15;
  else if (profile.ad_completion_rate < 0.6) score += 0.07;

  // Engagement depth
  if (profile.engagement_depth < 10) score += 0.15;
  else if (profile.engagement_depth < 30) score += 0.05;

  const risk = Math.max(0.02, Math.min(0.98, score));
  const tier: "low" | "low_med" | "medium" | "high" =
    risk >= 0.70 ? "high" :
    risk >= 0.50 ? "medium" :
    risk >= 0.30 ? "low_med" : "low";

  return { risk, tier };
}

// Batch score all profiles (triggered by cron or manually)
churnRouter.post("/score", async (c) => {
  try {
    const profiles = await pool.query(
      "SELECT viewer_token, session_frequency, ad_completion_rate, engagement_depth, last_active_at FROM viewer_profiles"
    );

    let scored = 0;
    for (const profile of profiles.rows) {
      const { risk, tier } = scoreChurnRisk(profile);
      await pool.query(
        `INSERT INTO churn_scores (viewer_token, churn_risk, risk_tier)
         VALUES ($1, $2, $3)`,
        [profile.viewer_token, risk, tier]
      );
      scored++;
    }

    return c.json({ status: "ok", scored, timestamp: new Date().toISOString() });
  } catch (err: any) {
    return c.json({ error: err.message }, 500);
  }
});

// High-risk viewers pending push notification
churnRouter.get("/high", async (c) => {
  try {
    const r = await pool.query(
      `SELECT cs.*, vp.sport_affinities, vp.segment_id
       FROM churn_scores cs
       JOIN viewer_profiles vp ON vp.viewer_token = cs.viewer_token
       WHERE cs.risk_tier = 'high' AND cs.push_sent = FALSE
       ORDER BY cs.churn_risk DESC LIMIT 100`
    );
    return c.json(r.rows);
  } catch (err: any) {
    return c.json({ error: err.message }, 500);
  }
});

// Mark push as sent
churnRouter.post("/push", async (c) => {
  const { viewerToken, pushVariant } = await c.req.json<{ viewerToken: string; pushVariant: string }>();
  if (!viewerToken) return c.json({ error: "viewerToken required" }, 400);
  try {
    await pool.query(
      `UPDATE churn_scores SET push_sent=TRUE, push_variant=$1, push_sent_at=NOW()
       WHERE viewer_token=$2 AND push_sent=FALSE`,
      [pushVariant, viewerToken]
    );
    return c.json({ status: "ok" });
  } catch (err: any) {
    return c.json({ error: err.message }, 500);
  }
});

// Churn stats summary
churnRouter.get("/stats", async (c) => {
  try {
    const r = await pool.query(
      `SELECT risk_tier, COUNT(*) as count, AVG(churn_risk) as avg_risk
       FROM churn_scores GROUP BY risk_tier`
    );
    return c.json(r.rows);
  } catch (err: any) {
    return c.json({ error: err.message }, 500);
  }
});
