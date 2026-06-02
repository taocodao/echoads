/**
 * sim.route.ts
 * ─────────────────────────────────────────────────────────────────────────────
 * Hono router for the end-to-end simulation controller.
 *
 * Endpoints:
 *   POST /api/sim/start         — Start the 9-scene flywheel demo
 *   POST /api/sim/stop          — Abort the running demo
 *   POST /api/sim/step/:scene   — Jump to a specific scene (presentation mode)
 *   GET  /api/sim/status        — Current demo state + metrics snapshot
 *   GET  /api/sim/events        — SSE stream of real-time scene events
 *   POST /api/sim/reset         — Reset demo state to idle
 */

import { Hono } from 'hono';
import { stream } from 'hono/streaming';
import {
  runFullDemo,
  abortDemo,
  jumpToScene,
  getDemoState,
  type SceneEvent,
} from './run-demo.js';

export const simRouter = new Hono();

// ── SSE client registry ───────────────────────────────────────────────────────

const sseClients = new Set<(event: SceneEvent) => void>();

function broadcastEvent(event: SceneEvent): void {
  for (const cb of sseClients) {
    try { cb(event); } catch { sseClients.delete(cb); }
  }
}

// ── POST /api/sim/start ───────────────────────────────────────────────────────

simRouter.post('/start', async (c) => {
  const state = getDemoState();
  if (state.running) {
    return c.json({ error: 'Demo already running', currentScene: state.currentScene }, 409);
  }

  // Start demo in background — events stream to SSE clients
  runFullDemo(broadcastEvent).catch((err) => {
    if (err?.message !== 'Demo aborted') {
      console.error('[sim] Demo failed:', err);
      broadcastEvent({
        scene: 0,
        title: 'Error',
        status: 'skipped',
        data: { error: err?.message ?? 'Unknown error' },
        elapsedMs: 0,
        timestamp: new Date().toISOString(),
      });
    }
  });

  return c.json({
    success: true,
    message: 'Demo started — connect to GET /api/sim/events for live updates',
    estimatedDurationSeconds: 45,
  });
});

// ── POST /api/sim/stop ────────────────────────────────────────────────────────

simRouter.post('/stop', (c) => {
  abortDemo();
  broadcastEvent({
    scene: 0,
    title: 'Demo Aborted',
    status: 'skipped',
    data: { abortedAt: new Date().toISOString() },
    elapsedMs: getDemoState().startedAt ? Date.now() - getDemoState().startedAt! : 0,
    timestamp: new Date().toISOString(),
  });
  return c.json({ success: true, message: 'Demo aborted' });
});

// ── POST /api/sim/step/:scene ─────────────────────────────────────────────────

simRouter.post('/step/:scene', async (c) => {
  const sceneNum = parseInt(c.req.param('scene'));
  if (isNaN(sceneNum) || sceneNum < 1 || sceneNum > 9) {
    return c.json({ error: 'Scene must be 1-9' }, 400);
  }

  try {
    await jumpToScene(sceneNum, broadcastEvent);
    return c.json({ success: true, scene: sceneNum });
  } catch (err) {
    return c.json({ error: (err as Error).message }, 500);
  }
});

// ── GET /api/sim/status ───────────────────────────────────────────────────────

simRouter.get('/status', (c) => {
  return c.json(getDemoState());
});

// ── POST /api/sim/reset ───────────────────────────────────────────────────────

simRouter.post('/reset', (c) => {
  abortDemo();
  // getDemoState() will return initial state after next runFullDemo call
  return c.json({ success: true, message: 'Demo state reset' });
});

// ── GET /api/sim/events — SSE event stream ────────────────────────────────────

simRouter.get('/events', (c) => {
  c.header('Content-Type', 'text/event-stream');
  c.header('Cache-Control', 'no-cache');
  c.header('Connection', 'keep-alive');
  c.header('Access-Control-Allow-Origin', '*');

  return stream(c, async (s) => {
    // Send initial state snapshot
    await s.write(`event: state\ndata: ${JSON.stringify(getDemoState())}\n\n`);

    // Register SSE client
    const clientCb = async (event: SceneEvent) => {
      try {
        await s.write(`event: scene\ndata: ${JSON.stringify(event)}\nid: ${Date.now()}\n\n`);
      } catch {
        sseClients.delete(clientCb);
      }
    };
    sseClients.add(clientCb);

    // Keep-alive ping every 20s
    const pingInterval = setInterval(async () => {
      try {
        await s.write(`: ping\n\n`);
      } catch {
        clearInterval(pingInterval);
        sseClients.delete(clientCb);
      }
    }, 20_000);

    // Cleanup on disconnect
    s.onAbort(() => {
      clearInterval(pingInterval);
      sseClients.delete(clientCb);
    });

    await new Promise<void>((resolve) => s.onAbort(resolve));
  });
});
