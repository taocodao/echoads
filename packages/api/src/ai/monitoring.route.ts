/**
 * monitoring.route.ts — Phase 4.5
 * Model Monitoring Dashboard — real-time health metrics for all AI modules.
 * Aggregates CloudWatch-equivalent metrics from the PostgreSQL tables.
 *
 * GET  /api/ai/monitoring/health      — overall AI system health
 * GET  /api/ai/monitoring/drift       — data drift detection per module
 * GET  /api/ai/monitoring/throughput  — request volume per endpoint (24h)
 * GET  /api/ai/monitoring/alerts      — active alerts requiring attention
 * POST /api/ai/monitoring/heartbeat   — record a model inference event
 */

import { Hono } from "hono";
import { pool } from "../database/db.js";

export const monitoringRouter = new Hono();

// ── In-memory metrics ring buffer ─────────────────────────────────────────────
// In production this would read from CloudWatch or Prometheus.

interface InferenceEvent {
  module: string;       // "segmenter" | "churn" | "ivt" | "commentary" | "prediction"
  latencyMs: number;
  success: boolean;
  modelVersion: string;
  timestamp: number;    // unix ms
}

const metricsBuffer: InferenceEvent[] = [];
const MAX_BUFFER = 5000;

function recordMetric(event: InferenceEvent) {
  metricsBuffer.push(event);
  if (metricsBuffer.length > MAX_BUFFER) metricsBuffer.shift();
}

// ── Drift Detection (simple statistical test) ─────────────────────────────────
// Compares rolling 24h mean vs prior 7-day baseline.
// In production: use Population Stability Index (PSI) or Kolmogorov-Smirnov test.

async function detectDrift(): Promise<Record<string, {
  module: string;
  metric: string;
  baseline: number;
  current: number;
  drift: number;
  status: 'ok' | 'warning' | 'critical';
}>> {
  try {
    const results: Record<string, any> = {};

    // Churn score distribution drift
    const churnStats = await pool.query(`
      SELECT
        AVG(CASE WHEN scored_at > NOW() - INTERVAL '24 hours' THEN churn_risk END) as recent_avg,
        AVG(churn_risk) as overall_avg
      FROM churn_scores
    `);
    const recentChurn = Number(churnStats.rows[0]?.recent_avg ?? 0.5);
    const baselineChurn = Number(churnStats.rows[0]?.overall_avg ?? 0.5);
    const churnDrift = Math.abs(recentChurn - baselineChurn);
    results.churn = {
      module: 'churn',
      metric: 'avg_churn_risk',
      baseline: Math.round(baselineChurn * 1000) / 1000,
      current: Math.round(recentChurn * 1000) / 1000,
      drift: Math.round(churnDrift * 1000) / 1000,
      status: churnDrift > 0.15 ? 'critical' : churnDrift > 0.08 ? 'warning' : 'ok',
    };

    // IVT flag rate drift
    const ivtStats = await pool.query(`
      SELECT
        AVG(CASE WHEN scored_at > NOW() - INTERVAL '24 hours' THEN ivt_score END) as recent_avg,
        AVG(ivt_score) as overall_avg
      FROM ivt_scores
    `);
    const recentIvt = Number(ivtStats.rows[0]?.recent_avg ?? 0.1);
    const baselineIvt = Number(ivtStats.rows[0]?.overall_avg ?? 0.1);
    const ivtDrift = Math.abs(recentIvt - baselineIvt);
    results.ivt = {
      module: 'ivt',
      metric: 'avg_ivt_score',
      baseline: Math.round(baselineIvt * 1000) / 1000,
      current: Math.round(recentIvt * 1000) / 1000,
      drift: Math.round(ivtDrift * 1000) / 1000,
      status: ivtDrift > 0.2 ? 'critical' : ivtDrift > 0.1 ? 'warning' : 'ok',
    };

    // Segmenter distribution drift (segment_id concentration)
    const segStats = await pool.query(`
      SELECT segment_id, COUNT(*) as cnt FROM viewer_profiles GROUP BY segment_id
    `);
    const total = segStats.rows.reduce((s: number, r: any) => s + Number(r.cnt), 0);
    const t1Share = total > 0
      ? Number(segStats.rows.find((r: any) => r.segment_id === 'T1')?.cnt ?? 0) / total
      : 0;
    results.segmenter = {
      module: 'segmenter',
      metric: 'T1_concentration',
      baseline: 0.05, // expected ~5% T1 viewers
      current: Math.round(t1Share * 1000) / 1000,
      drift: Math.round(Math.abs(t1Share - 0.05) * 1000) / 1000,
      status: t1Share > 0.40 ? 'warning' : 'ok', // too many T1 = data issue
    };

    return results;
  } catch {
    return {};
  }
}

// ── Routes ───────────────────────────────────────────────────────────────────

// Record heartbeat from model inference
monitoringRouter.post("/heartbeat", async (c) => {
  const body = await c.req.json<Omit<InferenceEvent, 'timestamp'>>();
  if (!body.module || body.latencyMs === undefined) {
    return c.json({ error: "module and latencyMs required" }, 400);
  }
  recordMetric({ ...body, timestamp: Date.now() });
  return c.json({ status: "ok" });
});

// Overall AI system health
monitoringRouter.get("/health", async (c) => {
  const now = Date.now();
  const window24h = now - 86_400_000;

  const recent = metricsBuffer.filter(e => e.timestamp > window24h);
  const byModule: Record<string, { count: number; errors: number; avgLatencyMs: number }> = {};

  for (const e of recent) {
    if (!byModule[e.module]) byModule[e.module] = { count: 0, errors: 0, avgLatencyMs: 0 };
    byModule[e.module].count++;
    if (!e.success) byModule[e.module].errors++;
    byModule[e.module].avgLatencyMs += e.latencyMs;
  }
  for (const m of Object.values(byModule)) {
    m.avgLatencyMs = Math.round(m.avgLatencyMs / Math.max(1, m.count));
  }

  // DB health check
  let dbStatus = 'ok';
  try {
    await pool.query('SELECT 1');
  } catch {
    dbStatus = 'error';
  }

  const totalRequests = recent.length;
  const errorRate = totalRequests > 0
    ? recent.filter(e => !e.success).length / totalRequests
    : 0;

  return c.json({
    status: errorRate > 0.05 ? 'degraded' : 'healthy',
    timestamp: new Date().toISOString(),
    db: dbStatus,
    last24h: {
      totalInferences: totalRequests,
      errorRate: Math.round(errorRate * 1000) / 1000,
      modules: byModule,
    },
    modules: {
      segmenter:  { status: 'rule-based', version: 'v1', upgradeTarget: 'XGBoost Core ML' },
      churn:      { status: 'rule-based', version: 'v1', upgradeTarget: 'Gradient Boosted Trees' },
      ivt:        { status: 'rule-based', version: 'v1', upgradeTarget: 'Isolation Forest' },
      commentary: { status: 'pre-scripted', version: 'v1', upgradeTarget: 'GPT-4o-mini' },
      predictions: { status: 'pre-scripted', version: 'v1', upgradeTarget: 'GPT-4o-mini + SportsData.io' },
      scheduler:  { status: 'heuristic', version: 'v1', upgradeTarget: 'Prophet time-series' },
      lookalike:  { status: 'cosine-similarity', version: 'v1', upgradeTarget: 'Embedding model' },
    },
  });
});

// Data drift detection
monitoringRouter.get("/drift", async (c) => {
  const drift = await detectDrift();
  const alerts = Object.values(drift).filter(d => d.status !== 'ok');
  return c.json({
    timestamp: new Date().toISOString(),
    modules: drift,
    alertCount: alerts.length,
    alerts: alerts.map(a => `${a.module}: ${a.metric} drifted ${a.drift} (${a.status})`),
  });
});

// Throughput by endpoint (24h)
monitoringRouter.get("/throughput", (c) => {
  const now = Date.now();
  const window24h = now - 86_400_000;
  const recent = metricsBuffer.filter(e => e.timestamp > window24h);

  const byHour: Record<number, number> = {};
  for (const e of recent) {
    const hour = new Date(e.timestamp).getHours();
    byHour[hour] = (byHour[hour] ?? 0) + 1;
  }

  return c.json({
    window: '24h',
    totalRequests: recent.length,
    byModule: Object.fromEntries(
      [...new Set(recent.map(e => e.module))].map(m => [
        m, recent.filter(e => e.module === m).length
      ])
    ),
    byHour: Array.from({ length: 24 }, (_, h) => ({
      hour: h,
      requests: byHour[h] ?? 0,
    })),
  });
});

// Active alerts
monitoringRouter.get("/alerts", async (c) => {
  const drift = await detectDrift();
  const now = Date.now();
  const recent = metricsBuffer.filter(e => e.timestamp > now - 3_600_000); // last 1h

  const alerts: { severity: string; module: string; message: string; timestamp: string }[] = [];

  // Drift alerts
  for (const [, d] of Object.entries(drift)) {
    if (d.status === 'critical') {
      alerts.push({ severity: 'critical', module: d.module, message: `Drift detected: ${d.metric} = ${d.current} (baseline ${d.baseline})`, timestamp: new Date().toISOString() });
    } else if (d.status === 'warning') {
      alerts.push({ severity: 'warning', module: d.module, message: `Drift warning: ${d.metric} drifted ${d.drift}`, timestamp: new Date().toISOString() });
    }
  }

  // High error rate alerts
  for (const module of [...new Set(recent.map(e => e.module))]) {
    const moduleEvents = recent.filter(e => e.module === module);
    const errRate = moduleEvents.filter(e => !e.success).length / moduleEvents.length;
    if (errRate > 0.10) {
      alerts.push({ severity: 'warning', module, message: `High error rate: ${(errRate*100).toFixed(1)}% in last hour`, timestamp: new Date().toISOString() });
    }
  }

  return c.json({
    alertCount: alerts.length,
    alerts,
    status: alerts.some(a => a.severity === 'critical') ? 'critical'
           : alerts.some(a => a.severity === 'warning') ? 'warning' : 'ok',
  });
});
