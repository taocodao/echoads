/**
 * segmenter.route.ts — Audience Segmentation (Module 2)
 * POST /api/ai/segment/classify — classify a viewer into T1–T12
 * GET  /api/ai/segment/breakdown — segment distribution stats
 */
import { Hono } from "hono";
import { pool } from "../database/db.js";

export const segmenterRouter = new Hono();

// Mirror of client-side tier definitions
const TIER_THRESHOLDS: { tier: string; min: number; cpmMin: number; cpmMax: number }[] = [
  { tier: "T1",  min: 85, cpmMin: 45, cpmMax: 50 },
  { tier: "T2",  min: 70, cpmMin: 38, cpmMax: 44 },
  { tier: "T3",  min: 55, cpmMin: 30, cpmMax: 37 },
  { tier: "T4",  min: 40, cpmMin: 22, cpmMax: 29 },
  { tier: "T5",  min: 32, cpmMin: 18, cpmMax: 21 },
  { tier: "T6",  min: 25, cpmMin: 16, cpmMax: 17 },
  { tier: "T7",  min: 20, cpmMin: 14, cpmMax: 15 },
  { tier: "T8",  min: 15, cpmMin: 13, cpmMax: 13 },
  { tier: "T9",  min: 10, cpmMin: 12, cpmMax: 12 },
  { tier: "T10", min: 7,  cpmMin: 12, cpmMax: 12 },
  { tier: "T11", min: 4,  cpmMin: 11, cpmMax: 11 },
  { tier: "T12", min: 0,  cpmMin: 11, cpmMax: 11 },
];

function classifyTier(engagementScore: number) {
  return TIER_THRESHOLDS.find(t => engagementScore >= t.min) || TIER_THRESHOLDS[TIER_THRESHOLDS.length - 1];
}

// Classify viewer
segmenterRouter.post("/classify", async (c) => {
  const { viewerToken, engagementScore } = await c.req.json<{
    viewerToken: string; engagementScore: number;
  }>();

  if (!viewerToken || engagementScore === undefined) {
    return c.json({ error: "viewerToken and engagementScore required" }, 400);
  }

  const tier = classifyTier(engagementScore);
  const cpmRange = tier.cpmMax - tier.cpmMin;
  const engRatio = Math.max(0, Math.min(1, (engagementScore - tier.min) / Math.max(1, 15)));
  const currentCPM = Math.round((tier.cpmMin + engRatio * cpmRange) * 10) / 10;

  try {
    // Update segment in viewer_profiles
    await pool.query(
      `UPDATE viewer_profiles SET segment_id=$1, viewer_score=$2, updated_at=NOW()
       WHERE viewer_token=$3`,
      [tier.tier, engagementScore / 100, viewerToken]
    );
  } catch {
    // Profile may not exist yet — that's fine
  }

  return c.json({ tier: tier.tier, currentCPM, cpmRange: `$${tier.cpmMin}–$${tier.cpmMax}` });
});

// Segment distribution for advertiser dashboard
segmenterRouter.get("/breakdown", async (c) => {
  try {
    const r = await pool.query(
      `SELECT segment_id as tier, COUNT(*) as viewer_count,
              ROUND(AVG(viewer_score)::numeric, 3) as avg_score
       FROM viewer_profiles
       GROUP BY segment_id ORDER BY segment_id`
    );
    return c.json(r.rows);
  } catch (err: any) {
    return c.json({ error: err.message }, 500);
  }
});
