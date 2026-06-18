/**
 * ab.route.ts — Phase 4.4
 * A/B Testing Framework for AI model variants.
 * Manages experiments, assigns viewers to variants, and records outcomes.
 *
 * POST /api/ai/ab/experiment      — create experiment
 * GET  /api/ai/ab/experiments     — list active experiments
 * POST /api/ai/ab/assign          — assign viewer to a variant
 * POST /api/ai/ab/outcome         — record an outcome event
 * GET  /api/ai/ab/results/:id     — get experiment results with statistical significance
 */

import { Hono } from "hono";
import { pool } from "../database/db.js";

export const abRouter = new Hono();

// ── Types ─────────────────────────────────────────────────────────────────────

interface Experiment {
  id: string;
  name: string;
  module: string;        // e.g. "segmenter", "churn", "commentary"
  variants: Variant[];
  status: "active" | "paused" | "concluded";
  createdAt: string;
  targetSegments?: string[];
}

interface Variant {
  id: string;
  name: string;
  description: string;
  weight: number;        // 0–1, sum of all variants must = 1
}

// In-memory store (swap for DB table in production)
const experiments = new Map<string, Experiment>();

// ── Deterministic variant assignment (hash-based, no DB write needed) ─────────
function assignVariant(viewerToken: string, experimentId: string, variants: Variant[]): string {
  // Simple deterministic hash: FNV-1a 32bit
  const seed = `${viewerToken}:${experimentId}`;
  let hash = 2166136261;
  for (let i = 0; i < seed.length; i++) {
    hash ^= seed.charCodeAt(i);
    hash = (hash * 16777619) >>> 0;
  }
  const roll = (hash % 10000) / 10000; // 0–0.9999

  let cumulative = 0;
  for (const v of variants) {
    cumulative += v.weight;
    if (roll < cumulative) return v.id;
  }
  return variants[variants.length - 1].id;
}

// ── Statistical significance (two-proportion z-test) ─────────────────────────
function zTest(controlN: number, controlConv: number, treatN: number, treatConv: number): {
  controlRate: number;
  treatmentRate: number;
  zScore: number;
  pValue: number;
  significant: boolean;
  lift: string;
} {
  const p1 = controlN > 0 ? controlConv / controlN : 0;
  const p2 = treatN > 0 ? treatConv / treatN : 0;
  const pooled = (controlConv + treatConv) / Math.max(1, controlN + treatN);
  const se = Math.sqrt(pooled * (1 - pooled) * (1 / Math.max(1, controlN) + 1 / Math.max(1, treatN)));
  const z = se > 0 ? (p2 - p1) / se : 0;
  // Two-tailed p-value approximation
  const pValue = 2 * (1 - normalCDF(Math.abs(z)));
  const lift = p1 > 0 ? `${((p2 - p1) / p1 * 100).toFixed(1)}%` : 'N/A';
  return { controlRate: p1, treatmentRate: p2, zScore: z, pValue, significant: pValue < 0.05, lift };
}

function normalCDF(x: number): number {
  const a1=0.254829592, a2=-0.284496736, a3=1.421413741, a4=-1.453152027, a5=1.061405429, p=0.3275911;
  const sign = x < 0 ? -1 : 1;
  x = Math.abs(x) / Math.sqrt(2);
  const t = 1 / (1 + p * x);
  const y = 1 - (((((a5*t+a4)*t)+a3)*t+a2)*t+a1)*t*Math.exp(-x*x);
  return 0.5 * (1 + sign * y);
}

// ── Routes ───────────────────────────────────────────────────────────────────

// Create experiment
abRouter.post("/experiment", async (c) => {
  const body = await c.req.json<Omit<Experiment, "id" | "createdAt" | "status">>();
  if (!body.name || !body.module || !body.variants?.length) {
    return c.json({ error: "name, module, and variants required" }, 400);
  }
  const weightSum = body.variants.reduce((s, v) => s + v.weight, 0);
  if (Math.abs(weightSum - 1) > 0.01) {
    return c.json({ error: `Variant weights must sum to 1 (got ${weightSum.toFixed(2)})` }, 400);
  }

  const id = `exp_${Date.now()}_${Math.random().toString(36).slice(2, 6)}`;
  const experiment: Experiment = {
    id, name: body.name, module: body.module,
    variants: body.variants, status: "active",
    createdAt: new Date().toISOString(),
    targetSegments: body.targetSegments,
  };
  experiments.set(id, experiment);

  return c.json({ status: "created", experiment }, 201);
});

// List active experiments
abRouter.get("/experiments", (c) => {
  return c.json({ experiments: Array.from(experiments.values()) });
});

// Assign viewer to variant
abRouter.post("/assign", async (c) => {
  const { viewerToken, experimentId } = await c.req.json<{ viewerToken: string; experimentId: string }>();
  if (!viewerToken || !experimentId) {
    return c.json({ error: "viewerToken and experimentId required" }, 400);
  }
  const exp = experiments.get(experimentId);
  if (!exp) return c.json({ error: "Experiment not found" }, 404);
  if (exp.status !== "active") return c.json({ error: "Experiment not active" }, 400);

  const variantId = assignVariant(viewerToken, experimentId, exp.variants);
  const variant = exp.variants.find(v => v.id === variantId);

  return c.json({ experimentId, viewerToken: viewerToken.slice(0, 12) + "…", variantId, variant });
});

// Record outcome
abRouter.post("/outcome", async (c) => {
  const { viewerToken, experimentId, metric, value } = await c.req.json<{
    viewerToken: string;
    experimentId: string;
    metric: string;   // e.g. "ad_completion", "prediction_pick", "churn_avoided"
    value: number;    // 1 = positive, 0 = negative
  }>();

  if (!viewerToken || !experimentId || !metric) {
    return c.json({ error: "viewerToken, experimentId, metric required" }, 400);
  }

  const exp = experiments.get(experimentId);
  if (!exp) return c.json({ error: "Experiment not found" }, 404);

  const variantId = assignVariant(viewerToken, experimentId, exp.variants);

  try {
    // Store in ai_commentary as a lightweight outcome log (reusing existing table)
    await pool.query(
      `INSERT INTO ai_commentary (match_id, event_at, event_type, commentary_text, model_used)
       VALUES ($1, $2, $3, $4, 'ab-framework-v1')`,
      [experimentId, Date.now(), `outcome:${metric}`, JSON.stringify({ variantId, value, viewerToken })]
    );
  } catch {
    // DB not available — outcome logged to console only
    console.info(`[AB] outcome: exp=${experimentId} variant=${variantId} metric=${metric} value=${value}`);
  }

  return c.json({ status: "recorded", variantId, metric });
});

// Get experiment results with significance test
abRouter.get("/results/:id", async (c) => {
  const exp = experiments.get(c.req.param("id"));
  if (!exp) return c.json({ error: "Experiment not found" }, 404);

  try {
    const { rows } = await pool.query(
      `SELECT commentary_text FROM ai_commentary WHERE match_id=$1 AND model_used='ab-framework-v1'`,
      [exp.id]
    );

    // Tally outcomes per variant
    const tally: Record<string, { impressions: number; conversions: number }> = {};
    for (const v of exp.variants) tally[v.id] = { impressions: 0, conversions: 0 };

    for (const row of rows) {
      try {
        const d = JSON.parse(row.commentary_text);
        if (tally[d.variantId]) {
          tally[d.variantId].impressions++;
          if (d.value >= 1) tally[d.variantId].conversions++;
        }
      } catch { /* ignore */ }
    }

    // Compare first two variants
    const [control, treatment] = exp.variants;
    const stats = control && treatment
      ? zTest(
          tally[control.id].impressions, tally[control.id].conversions,
          tally[treatment.id].impressions, tally[treatment.id].conversions
        )
      : null;

    return c.json({
      experiment: exp,
      results: exp.variants.map(v => ({ ...v, ...tally[v.id] })),
      significance: stats,
      recommendation: stats?.significant
        ? `Treatment (${treatment?.name}) shows ${stats.lift} lift — recommend promoting to 100%`
        : `Insufficient data for significance (p=${stats?.pValue?.toFixed(3) ?? 'N/A'})`,
    });
  } catch (err: any) {
    return c.json({ error: err.message }, 500);
  }
});
