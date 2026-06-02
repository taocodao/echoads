/**
 * node-sim.route.ts
 * ─────────────────────────────────────────────────────────────────────────────
 * Hono router for DePIN node simulator control + SSE event stream.
 *
 * Endpoints:
 *   POST /api/sim/nodes/start?count=10  — Start simulator with N nodes
 *   POST /api/sim/nodes/stop            — Stop simulator
 *   POST /api/sim/nodes/slash/:nodeId   — Slash a specific node
 *   GET  /api/sim/nodes/status          — Current simulator state snapshot
 *   GET  /api/sim/nodes/list            — Full node list with metrics
 *   GET  /api/sim/events                — SSE event stream (for dashboard)
 */

import { Hono } from 'hono';
import { stream } from 'hono/streaming';
import {
  startSimulator,
  stopSimulator,
  getNodes,
  getSimStatus,
  slashNode,
  subscribeToSimEvents,
} from './node-simulator.js';

export const nodeSimRouter = new Hono();

// ── POST /api/sim/nodes/start ─────────────────────────────────────────────────

nodeSimRouter.post('/nodes/start', async (c) => {
  let count = 10;
  try {
    const body = await c.req.json() as { count?: number };
    if (body.count && typeof body.count === 'number') count = body.count;
  } catch {
    const q = c.req.query('count');
    if (q) count = parseInt(q);
  }

  try {
    const nodes = await startSimulator(count);
    return c.json({
      success: true,
      message: `${nodes.length} nodes started`,
      nodes: nodes.map((n) => ({
        nodeId: n.nodeId,
        address: n.address,
        deviceType: n.deviceType,
        stake: n.stakedCmxs,
        status: n.status,
      })),
    });
  } catch (err) {
    console.error('[node-sim] Start failed:', err);
    return c.json({ success: false, error: 'Failed to start simulator' }, 500);
  }
});

// ── POST /api/sim/nodes/stop ──────────────────────────────────────────────────

nodeSimRouter.post('/nodes/stop', (c) => {
  stopSimulator();
  return c.json({ success: true, message: 'Simulator stopped' });
});

// ── POST /api/sim/nodes/slash/:nodeId ─────────────────────────────────────────

nodeSimRouter.post('/nodes/slash/:nodeId', async (c) => {
  const nodeId = c.req.param('nodeId');
  let severity: 'MINOR' | 'MAJOR' = 'MINOR';
  try {
    const body = await c.req.json() as { severity?: 'MINOR' | 'MAJOR' };
    if (body.severity === 'MAJOR') severity = 'MAJOR';
  } catch { /* use default */ }

  const success = slashNode(nodeId, severity);
  if (!success) {
    return c.json({ error: `Node ${nodeId} not found or not active` }, 404);
  }
  return c.json({ success: true, nodeId, severity });
});

// ── GET /api/sim/nodes/status ─────────────────────────────────────────────────

nodeSimRouter.get('/nodes/status', (c) => {
  return c.json(getSimStatus());
});

// ── GET /api/sim/nodes/list ───────────────────────────────────────────────────

nodeSimRouter.get('/nodes/list', (c) => {
  return c.json({ nodes: getNodes() });
});

// ── GET /api/sim/events — SSE event stream ────────────────────────────────────

nodeSimRouter.get('/events', (c) => {
  c.header('Content-Type', 'text/event-stream');
  c.header('Cache-Control', 'no-cache');
  c.header('Connection', 'keep-alive');
  c.header('Access-Control-Allow-Origin', '*');

  return stream(c, async (s) => {
    // Send initial snapshot
    await s.write(`event: snapshot\ndata: ${JSON.stringify({
      status: getSimStatus(),
      nodes: getNodes(),
    })}\n\n`);

    // Subscribe to sim events and stream them
    const unsubscribe = subscribeToSimEvents(async (event) => {
      try {
        await s.write(`event: ${event.type}\ndata: ${JSON.stringify(event.data)}\nid: ${event.timestamp}\n\n`);
      } catch { /* client disconnected */ }
    });

    // Keep-alive ping every 25s
    const pingInterval = setInterval(async () => {
      try {
        await s.write(`: ping\n\n`);
      } catch {
        clearInterval(pingInterval);
        unsubscribe();
      }
    }, 25_000);

    // Cleanup on stream close
    s.onAbort(() => {
      clearInterval(pingInterval);
      unsubscribe();
    });

    // Block until client disconnects
    await new Promise<void>((resolve) => {
      s.onAbort(resolve);
    });
  });
});
