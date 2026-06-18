/**
 * scheduler.route.ts — Phase 4.1 (Module 9)
 * Dynamic Content Scheduler — predicts optimal broadcast schedule using
 * a time-series model (Prophet-equivalent heuristics in TS).
 *
 * POST /api/ai/schedule/predict   — predict best content slot for next 24h
 * GET  /api/ai/schedule/slots     — get current schedule slots
 * POST /api/ai/schedule/confirm   — confirm a scheduled slot
 * GET  /api/ai/schedule/stats     — scheduler performance stats
 */

import { Hono } from "hono";
import { pool } from "../database/db.js";

export const schedulerRouter = new Hono();

// ── Time-Series Heuristic Model ───────────────────────────────────────────────
// Approximates Prophet's trend + seasonality with weighted hour-of-day scoring.
// In production: replace with a trained Prophet model via a Python sidecar.

const HOURLY_WEIGHTS: Record<number, number> = {
  0: 0.3, 1: 0.2, 2: 0.1, 3: 0.1, 4: 0.1, 5: 0.2,
  6: 0.5, 7: 0.7, 8: 0.8, 9: 0.7, 10: 0.7, 11: 0.8,
  12: 1.0, 13: 0.9, 14: 0.8, 15: 0.8, 16: 0.9, 17: 1.0,
  18: 1.2, 19: 1.5, 20: 2.0, 21: 1.8, 22: 1.5, 23: 0.8,
};

const DAY_WEIGHTS: Record<number, number> = {
  0: 2.0, // Sunday — peak NFL
  1: 1.0, 2: 0.8, 3: 0.9, 4: 0.9,
  5: 1.3, // Friday — pre-weekend
  6: 1.8, // Saturday — college sports
};

interface ContentSlot {
  startTime: string;      // ISO timestamp
  endTime: string;
  contentType: 'sports_live' | 'sports_replay' | 'sponsor_quiz' | 'ad_break' | 'halftime';
  sport?: string;
  predictedViewers: number;
  predictedCPM: number;
  confidence: number;     // 0–1
  reason: string;
}

function predictSlots(hoursAhead: number = 24): ContentSlot[] {
  const slots: ContentSlot[] = [];
  const now = new Date();

  for (let h = 0; h < hoursAhead; h++) {
    const slotTime = new Date(now.getTime() + h * 3600_000);
    const hour = slotTime.getHours();
    const day = slotTime.getDay();

    const hourW = HOURLY_WEIGHTS[hour] ?? 1.0;
    const dayW  = DAY_WEIGHTS[day]  ?? 1.0;
    const combined = hourW * dayW;

    // Classify content type by time of day
    let contentType: ContentSlot['contentType'] = 'sports_replay';
    let sport = 'NFL';
    let reason = '';

    if (combined >= 1.8) {
      contentType = 'sports_live';
      sport = day === 0 ? 'NFL' : day === 6 ? 'NCAA' : 'NBA';
      reason = 'Peak viewership window — live sports optimal';
    } else if (combined >= 1.2) {
      contentType = 'sports_live';
      reason = 'High engagement window — live content';
    } else if (combined >= 0.8) {
      contentType = 'sports_replay';
      reason = 'Moderate window — replay or highlights';
    } else if (hour >= 12 && hour <= 14) {
      contentType = 'sponsor_quiz';
      reason = 'Lunch engagement spike — interactive content';
    } else {
      contentType = 'ad_break';
      reason = 'Low viewership — ad-only fill';
    }

    const baseViewers = Math.round(12_000 * combined + Math.random() * 2000);
    const baseCPM = contentType === 'sports_live' ? 42 + combined * 8 : 18 + combined * 5;

    slots.push({
      startTime: slotTime.toISOString(),
      endTime: new Date(slotTime.getTime() + 3600_000).toISOString(),
      contentType,
      sport: contentType.includes('sports') ? sport : undefined,
      predictedViewers: baseViewers,
      predictedCPM: Math.round(baseCPM * 10) / 10,
      confidence: Math.min(0.95, 0.5 + combined * 0.15),
      reason,
    });
  }

  return slots;
}

// ── Routes ───────────────────────────────────────────────────────────────────

// Predict optimal schedule for next N hours
schedulerRouter.post("/predict", async (c) => {
  const body = await c.req.json<{ hoursAhead?: number }>().catch(() => ({}));
  const hoursAhead = Math.min(168, body?.hoursAhead ?? 24); // max 7 days
  const slots = predictSlots(hoursAhead);
  const peakSlot = [...slots].sort((a, b) => b.predictedViewers - a.predictedViewers)[0];
  return c.json({
    generated: new Date().toISOString(),
    hoursAhead,
    slots,
    recommendation: {
      peakWindow: peakSlot?.startTime,
      expectedViewers: peakSlot?.predictedViewers,
      expectedCPM: peakSlot?.predictedCPM,
      modelVersion: 'heuristic-v1 (Prophet replacement pending)',
    },
  });
});

// Get current 24h schedule
schedulerRouter.get("/slots", (c) => {
  const slots = predictSlots(24);
  return c.json({ slots, generatedAt: new Date().toISOString() });
});

// Confirm a scheduled slot (write intent to DB)
schedulerRouter.post("/confirm", async (c) => {
  const body = await c.req.json<{ startTime: string; contentType: string; sport?: string }>();
  if (!body.startTime || !body.contentType) {
    return c.json({ error: "startTime and contentType required" }, 400);
  }
  try {
    // Store confirmed slot in a generic JSONB table (reuses ai_commentary table pattern)
    await pool.query(
      `INSERT INTO ai_commentary (match_id, event_at, event_type, commentary_text, model_used)
       VALUES ($1, $2, $3, $4, 'scheduler-v1')
       ON CONFLICT (match_id, event_at) DO NOTHING`,
      ['schedule', new Date(body.startTime).getTime(), body.contentType,
       JSON.stringify({ confirmed: true, sport: body.sport })]
    );
    return c.json({ status: "confirmed", startTime: body.startTime });
  } catch (err: any) {
    return c.json({ error: err.message }, 500);
  }
});

// Scheduler performance stats
schedulerRouter.get("/stats", (c) => {
  const slots = predictSlots(168); // 7 days
  const liveSlots    = slots.filter(s => s.contentType === 'sports_live').length;
  const avgCPM       = slots.reduce((s, x) => s + x.predictedCPM, 0) / slots.length;
  const avgViewers   = slots.reduce((s, x) => s + x.predictedViewers, 0) / slots.length;
  const peakViewers  = Math.max(...slots.map(s => s.predictedViewers));
  return c.json({
    forecastWindow: '7 days',
    totalSlots: slots.length,
    liveContentSlots: liveSlots,
    avgPredictedCPM: Math.round(avgCPM * 10) / 10,
    avgPredictedViewers: Math.round(avgViewers),
    peakPredictedViewers: peakViewers,
    modelVersion: 'heuristic-v1',
    prophetUpgrade: 'Phase 4.1 — pending Python training pipeline',
  });
});
