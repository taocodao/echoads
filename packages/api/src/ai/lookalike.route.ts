/**
 * lookalike.route.ts — Phase 4.2 (Module 10)
 * Lookalike Audience Expansion — finds viewers similar to your seed segment
 * using cosine similarity on engagement feature vectors.
 * LiveRamp-compatible CSV export endpoint included.
 *
 * POST /api/ai/lookalike/build    — build lookalike from seed segment
 * GET  /api/ai/lookalike/export   — export as LiveRamp-compatible CSV
 * GET  /api/ai/lookalike/stats    — segment size and quality stats
 */

import { Hono } from "hono";
import { pool } from "../database/db.js";

export const lookalikeRouter = new Hono();

// ── Feature Vector ────────────────────────────────────────────────────────────
// 6-dimensional feature vector per viewer profile.
// In production: replace with a trained embedding model on T1–T3 profiles.

interface FeatureVector {
  viewer_token: string;
  segment_id: string;
  features: number[]; // [engagement, adCompletion, predictionRate, sessionFreq, watchHours, sportScore]
}

function buildFeatureVector(row: any): FeatureVector {
  const sportScore = Object.values(row.sport_affinities ?? {})
    .reduce((sum: number, v: any) => sum + Number(v), 0) as number;

  return {
    viewer_token: row.viewer_token,
    segment_id: row.segment_id,
    features: [
      Math.min(1, row.engagement_depth / 100),
      Math.min(1, row.ad_completion_rate),
      Math.min(1, row.prediction_rate),
      Math.min(1, row.session_frequency / 10),
      Math.min(1, row.total_watch_hours / 50),
      Math.min(1, sportScore / 3),
    ],
  };
}

function cosineSimilarity(a: number[], b: number[]): number {
  const dot = a.reduce((sum, ai, i) => sum + ai * (b[i] ?? 0), 0);
  const magA = Math.sqrt(a.reduce((sum, ai) => sum + ai * ai, 0));
  const magB = Math.sqrt(b.reduce((sum, bi) => sum + bi * bi, 0));
  return magA && magB ? dot / (magA * magB) : 0;
}

function meanVector(vectors: FeatureVector[]): number[] {
  if (!vectors.length) return [0, 0, 0, 0, 0, 0];
  const n = vectors.length;
  return vectors[0].features.map((_, i) =>
    vectors.reduce((sum, v) => sum + (v.features[i] ?? 0), 0) / n
  );
}

// ── Build Lookalike Audience ──────────────────────────────────────────────────

lookalikeRouter.post("/build", async (c) => {
  const body = await c.req.json<{
    seedSegment: string;    // e.g. "T1" or "T2"
    targetSize?: number;    // max lookalike audience size
    minSimilarity?: number; // 0–1 cosine similarity threshold
  }>();

  if (!body.seedSegment) {
    return c.json({ error: "seedSegment required (e.g. 'T1')" }, 400);
  }

  const targetSize   = Math.min(10_000, body.targetSize ?? 1000);
  const minSimilarity = body.minSimilarity ?? 0.75;

  try {
    // 1. Load all profiles
    const { rows } = await pool.query(
      `SELECT viewer_token, segment_id, engagement_depth, ad_completion_rate,
              prediction_rate, session_frequency, total_watch_hours, sport_affinities
       FROM viewer_profiles`
    );

    if (rows.length < 10) {
      return c.json({
        error: "Insufficient profiles for lookalike modeling (need ≥10)",
        profileCount: rows.length,
      }, 400);
    }

    const allVectors = rows.map(buildFeatureVector);

    // 2. Compute seed centroid
    const seedVectors = allVectors.filter(v => v.segment_id === body.seedSegment);
    if (!seedVectors.length) {
      return c.json({ error: `No viewers found for seed segment ${body.seedSegment}` }, 404);
    }
    const centroid = meanVector(seedVectors);

    // 3. Score all non-seed viewers
    const candidates = allVectors
      .filter(v => v.segment_id !== body.seedSegment)
      .map(v => ({
        viewer_token: v.viewer_token,
        segment_id: v.segment_id,
        similarity: cosineSimilarity(centroid, v.features),
      }))
      .filter(v => v.similarity >= minSimilarity)
      .sort((a, b) => b.similarity - a.similarity)
      .slice(0, targetSize);

    const avgSimilarity = candidates.length
      ? candidates.reduce((s, c) => s + c.similarity, 0) / candidates.length
      : 0;

    return c.json({
      seedSegment: body.seedSegment,
      seedSize: seedVectors.length,
      lookalikeSize: candidates.length,
      targetSize,
      minSimilarity,
      avgSimilarity: Math.round(avgSimilarity * 1000) / 1000,
      topMatches: candidates.slice(0, 10).map(c => ({
        viewer_token: c.viewer_token.slice(0, 12) + '…',
        segment: c.segment_id,
        similarity: Math.round(c.similarity * 1000) / 1000,
      })),
      exportUrl: `/api/ai/lookalike/export?seed=${body.seedSegment}&min=${minSimilarity}&limit=${targetSize}`,
      modelVersion: 'cosine-similarity-v1 (embedding model pending)',
    });
  } catch (err: any) {
    return c.json({ error: err.message }, 500);
  }
});

// ── Export as LiveRamp-compatible CSV ─────────────────────────────────────────

lookalikeRouter.get("/export", async (c) => {
  const seed          = c.req.query('seed') ?? 'T1';
  const minSimilarity = parseFloat(c.req.query('min') ?? '0.75');
  const limit         = parseInt(c.req.query('limit') ?? '1000');

  try {
    const { rows } = await pool.query(
      `SELECT viewer_token, segment_id, engagement_depth, ad_completion_rate,
              prediction_rate, session_frequency, total_watch_hours, sport_affinities
       FROM viewer_profiles`
    );

    const allVectors = rows.map(buildFeatureVector);
    const seedVectors = allVectors.filter(v => v.segment_id === seed);
    if (!seedVectors.length) {
      return c.json({ error: `Seed segment ${seed} not found` }, 404);
    }

    const centroid = meanVector(seedVectors);
    const candidates = allVectors
      .filter(v => v.segment_id !== seed)
      .map(v => ({ ...v, similarity: cosineSimilarity(centroid, v.features) }))
      .filter(v => v.similarity >= minSimilarity)
      .sort((a, b) => b.similarity - a.similarity)
      .slice(0, limit);

    // LiveRamp expects: hashed_email OR device_id, segment_name, score
    const csvLines = [
      'viewer_token_hashed,segment_name,lookalike_score,matched_from',
      ...candidates.map(c =>
        [
          // SHA-256 hash of token (simulated with base64)
          Buffer.from(c.viewer_token).toString('base64').slice(0, 32),
          `ArenzaTV_Lookalike_${seed}`,
          c.similarity.toFixed(4),
          seed,
        ].join(',')
      ),
    ].join('\n');

    return new Response(csvLines, {
      headers: {
        'Content-Type': 'text/csv',
        'Content-Disposition': `attachment; filename="arenzatv_lookalike_${seed}_${Date.now()}.csv"`,
      },
    });
  } catch (err: any) {
    return c.json({ error: err.message }, 500);
  }
});

// ── Segment Stats ─────────────────────────────────────────────────────────────

lookalikeRouter.get("/stats", async (c) => {
  try {
    const { rows } = await pool.query(
      `SELECT segment_id, COUNT(*) as count,
              AVG(engagement_depth) as avg_engagement,
              AVG(ad_completion_rate) as avg_ad_completion,
              AVG(total_watch_hours) as avg_watch_hours
       FROM viewer_profiles
       GROUP BY segment_id
       ORDER BY segment_id`
    );
    return c.json({
      segments: rows.map(r => ({
        segment: r.segment_id,
        count: Number(r.count),
        avgEngagement: Math.round(Number(r.avg_engagement) * 10) / 10,
        avgAdCompletion: Math.round(Number(r.avg_ad_completion) * 100) / 100,
        avgWatchHours: Math.round(Number(r.avg_watch_hours) * 10) / 10,
      })),
      modelVersion: 'cosine-similarity-v1',
      embeddingUpgrade: 'Phase 4.2 — requires T1–T3 training corpus ≥5K profiles',
    });
  } catch (err: any) {
    return c.json({ error: err.message }, 500);
  }
});
