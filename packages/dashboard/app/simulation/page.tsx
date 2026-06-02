'use client';

/**
 * /simulation/page.tsx
 * Full-screen 9-scene CMXS flywheel demo viewer.
 *
 * Connects to GET /api/sim/events (SSE) and renders each scene
 * as it fires with timeline progress, metrics panel, and log feed.
 */

import { useState, useEffect, useRef, useCallback } from 'react';

const API = process.env.NEXT_PUBLIC_API_URL ?? 'http://localhost:3001';
const DEMO_API = `${API}/api/demo`;

// ── Types ─────────────────────────────────────────────────────────────────────

type SceneStatus = 'pending' | 'running' | 'complete' | 'skipped';

interface SceneEntry {
  scene: number;
  title: string;
  status: SceneStatus;
}

interface SceneEvent {
  scene: number;
  title: string;
  status: SceneStatus;
  data?: Record<string, unknown>;
  elapsedMs: number;
  timestamp: string;
}

interface DemoMetrics {
  impressionsProcessed: number;
  cmxsBurned: number;
  cmxsMinted: number;
  netDeflation: number;
  usdcRevenue: number;
  treasuryUsdc: number;
  activeNodes: number;
  auctionLatencyMs: number;
  podConfirmedOnChain: boolean;
  txHash: string | null;
}

interface DemoState {
  running: boolean;
  currentScene: number;
  scenes: SceneEntry[];
  metrics: DemoMetrics;
}

// ── Constants ─────────────────────────────────────────────────────────────────

const SCENE_ICONS: Record<number, string> = {
  1: '🚀', 2: '💰', 3: '📡', 4: '⚡', 5: '📺',
  6: '🔗', 7: '🏛️', 8: '🔥', 9: '🏆',
};

const STATUS_COLORS: Record<SceneStatus, string> = {
  pending: '#334155',
  running: '#f59e0b',
  complete: '#22c55e',
  skipped: '#ef4444',
};

// ── Component ─────────────────────────────────────────────────────────────────

export default function SimulationPage() {
  const [state, setState] = useState<DemoState | null>(null);
  const [events, setEvents] = useState<SceneEvent[]>([]);
  const [connected, setConnected] = useState(false);
  const [activeEvent, setActiveEvent] = useState<SceneEvent | null>(null);
  const esRef = useRef<EventSource | null>(null);
  const logRef = useRef<HTMLDivElement>(null);

  const connectSSE = useCallback(() => {
    if (esRef.current) esRef.current.close();
    const es = new EventSource(`${DEMO_API}/events`);
    esRef.current = es;

    es.addEventListener('state', (e) => {
      setState(JSON.parse(e.data) as DemoState);
      setConnected(true);
    });

    es.addEventListener('scene', (e) => {
      const event = JSON.parse(e.data) as SceneEvent;
      setActiveEvent(event);
      setEvents((prev) => [event, ...prev].slice(0, 50));

      // Update state scenes
      setState((prev) => {
        if (!prev) return prev;
        const scenes = prev.scenes.map((s) =>
          s.scene === event.scene ? { ...s, status: event.status } : s
        );
        return {
          ...prev,
          running: event.status !== 'complete' || event.scene < 9,
          currentScene: event.scene,
          scenes,
        };
      });
    });

    es.onerror = () => {
      setConnected(false);
      setTimeout(connectSSE, 3000);
    };
  }, []);

  useEffect(() => {
    connectSSE();
    // Fetch initial status
    fetch(`${DEMO_API}/status`)
      .then((r) => r.ok ? r.json() as Promise<DemoState> : null)
      .then((d) => { if (d) setState(d); })
      .catch(() => {});
    return () => esRef.current?.close();
  }, [connectSSE]);

  // Scroll event log to top on new events
  useEffect(() => {
    logRef.current?.scrollTo({ top: 0, behavior: 'smooth' });
  }, [events.length]);

  const startDemo = async () => {
    await fetch(`${DEMO_API}/start`, { method: 'POST' });
  };

  const stopDemo = async () => {
    await fetch(`${DEMO_API}/stop`, { method: 'POST' });
  };

  const jumpToScene = async (scene: number) => {
    await fetch(`${DEMO_API}/step/${scene}`, { method: 'POST' });
  };

  const m = state?.metrics;

  return (
    <div style={{ maxWidth: 1400, display: 'grid', gridTemplateColumns: '320px 1fr 300px', gap: '1.5rem', minHeight: 'calc(100vh - 120px)' }}>

      {/* ── Left: Scene Timeline ── */}
      <div style={{ display: 'flex', flexDirection: 'column', gap: '0.75rem' }}>
        {/* Header + controls */}
        <div style={{ background: 'rgba(30,41,59,0.7)', border: '1px solid rgba(255,255,255,0.08)', borderRadius: 12, padding: '1rem' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', marginBottom: '0.75rem' }}>
            <div style={{
              width: 8, height: 8, borderRadius: '50%',
              background: connected ? '#22c55e' : '#ef4444',
              boxShadow: `0 0 8px ${connected ? '#22c55e' : '#ef4444'}`,
            }} />
            <span style={{ fontSize: '0.78rem', color: connected ? '#22c55e' : '#ef4444' }}>
              {connected ? 'SSE Connected' : 'Reconnecting…'}
            </span>
          </div>

          <div style={{ display: 'flex', gap: '0.5rem', flexWrap: 'wrap' }}>
            {state?.running ? (
              <button onClick={stopDemo} style={{
                flex: 1, padding: '0.6rem', background: 'rgba(239,68,68,0.12)',
                border: '1px solid rgba(239,68,68,0.3)', borderRadius: 8,
                color: '#ef4444', cursor: 'pointer', fontSize: '0.82rem', fontWeight: 600,
              }}>
                ⏹ Stop
              </button>
            ) : (
              <button onClick={startDemo} style={{
                flex: 1, padding: '0.6rem',
                background: 'linear-gradient(135deg,#3B82F6,#8B5CF6)',
                border: 'none', borderRadius: 8, color: '#fff', cursor: 'pointer',
                fontSize: '0.82rem', fontWeight: 600,
                boxShadow: '0 0 20px rgba(59,130,246,0.3)',
              }}>
                ▶ Run Full Demo
              </button>
            )}
          </div>
        </div>

        {/* Scene list */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: '0.4rem' }}>
          {(state?.scenes ?? Array.from({ length: 9 }, (_, i) => ({ scene: i + 1, title: `Scene ${i + 1}`, status: 'pending' as SceneStatus }))).map((s) => (
            <button
              key={s.scene}
              onClick={() => jumpToScene(s.scene)}
              style={{
                display: 'flex', alignItems: 'center', gap: '0.75rem',
                padding: '0.75rem 1rem',
                background: s.status === 'running'
                  ? 'rgba(245,158,11,0.08)'
                  : s.status === 'complete'
                  ? 'rgba(34,197,94,0.06)'
                  : 'rgba(30,41,59,0.5)',
                border: `1px solid ${STATUS_COLORS[s.status]}22`,
                borderLeft: `3px solid ${STATUS_COLORS[s.status]}`,
                borderRadius: 8, cursor: 'pointer', textAlign: 'left', width: '100%',
                transition: 'all 0.2s',
              }}
            >
              <span style={{ fontSize: '1.1rem', flexShrink: 0 }}>{SCENE_ICONS[s.scene]}</span>
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ fontSize: '0.78rem', fontWeight: 600, color: s.status === 'complete' ? '#22c55e' : s.status === 'running' ? '#f59e0b' : '#94a3b8', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>
                  {s.title}
                </div>
                <div style={{ fontSize: '0.68rem', color: '#475569', marginTop: 2, textTransform: 'uppercase', letterSpacing: '0.04em' }}>
                  Scene {s.scene} · {s.status}
                </div>
              </div>
              {s.status === 'running' && (
                <div style={{ width: 6, height: 6, borderRadius: '50%', background: '#f59e0b', animation: 'pulse 1s infinite', flexShrink: 0 }} />
              )}
            </button>
          ))}
        </div>
      </div>

      {/* ── Center: Active Scene ── */}
      <div style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
        {/* Active scene card */}
        {activeEvent ? (
          <div style={{
            background: 'linear-gradient(135deg, rgba(15,23,42,0.95), rgba(30,41,59,0.9))',
            border: '1px solid rgba(59,130,246,0.2)',
            borderRadius: 16, padding: '2rem',
            boxShadow: '0 0 60px rgba(59,130,246,0.08)',
            minHeight: 280,
          }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: '1rem', marginBottom: '1.5rem' }}>
              <div style={{ fontSize: '2.5rem' }}>{SCENE_ICONS[activeEvent.scene]}</div>
              <div>
                <div style={{ fontSize: '0.75rem', color: '#64748b', textTransform: 'uppercase', letterSpacing: '0.08em' }}>
                  Scene {activeEvent.scene} · {activeEvent.elapsedMs}ms elapsed
                </div>
                <h2 style={{ margin: '0.25rem 0 0', fontSize: '1.4rem', fontWeight: 700, color: '#f8fafc' }}>
                  {activeEvent.title}
                </h2>
                <div style={{
                  display: 'inline-flex', alignItems: 'center', gap: '0.4rem',
                  padding: '0.25rem 0.75rem', marginTop: '0.5rem',
                  borderRadius: 20, fontSize: '0.75rem', fontWeight: 700,
                  background: `${STATUS_COLORS[activeEvent.status]}15`,
                  border: `1px solid ${STATUS_COLORS[activeEvent.status]}30`,
                  color: STATUS_COLORS[activeEvent.status],
                }}>
                  {activeEvent.status === 'running' && <span style={{ animation: 'spin 1s linear infinite', display: 'inline-block' }}>⟳</span>}
                  {activeEvent.status.toUpperCase()}
                </div>
              </div>
            </div>

            {/* Scene data */}
            {activeEvent.data && Object.keys(activeEvent.data).length > 0 && (
              <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(180px, 1fr))', gap: '0.75rem' }}>
                {Object.entries(activeEvent.data).map(([key, val]) => (
                  typeof val !== 'object' ? (
                    <div key={key} style={{ background: 'rgba(30,41,59,0.6)', border: '1px solid rgba(255,255,255,0.06)', borderRadius: 8, padding: '0.7rem' }}>
                      <div style={{ fontSize: '0.68rem', color: '#475569', textTransform: 'uppercase', letterSpacing: '0.06em', marginBottom: 4 }}>
                        {key.replace(/([A-Z])/g, ' $1').trim()}
                      </div>
                      <div style={{ fontSize: '0.88rem', fontWeight: 600, color: '#e2e8f0', wordBreak: 'break-all' }}>
                        {String(val)}
                      </div>
                    </div>
                  ) : null
                ))}
              </div>
            )}
          </div>
        ) : (
          <div style={{
            background: 'rgba(15,23,42,0.7)', border: '1px dashed rgba(255,255,255,0.08)',
            borderRadius: 16, padding: '3rem', textAlign: 'center', minHeight: 280,
            display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', gap: '1rem',
          }}>
            <div style={{ fontSize: '3rem' }}>🎬</div>
            <div style={{ fontSize: '1.1rem', fontWeight: 600, color: '#475569' }}>Ready to Demo</div>
            <div style={{ fontSize: '0.85rem', color: '#334155' }}>Click "Run Full Demo" to start the 9-scene flywheel</div>
          </div>
        )}

        {/* Metrics grid */}
        {m && (
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4,1fr)', gap: '0.75rem' }}>
            {[
              { label: 'USDC Revenue', value: `$${m.usdcRevenue.toFixed(0)}`, color: '#3B82F6' },
              { label: 'CMXS Burned', value: `${m.cmxsBurned}`, color: '#ef4444', suffix: 'CMXS' },
              { label: 'CMXS Minted', value: m.cmxsMinted.toFixed(4), color: '#22c55e', suffix: 'CMXS' },
              { label: 'Auction Latency', value: `${m.auctionLatencyMs}`, color: '#8B5CF6', suffix: 'ms' },
              { label: 'Impressions', value: m.impressionsProcessed.toString(), color: '#06b6d4' },
              { label: 'Active Nodes', value: m.activeNodes.toString(), color: '#22c55e' },
              { label: 'Treasury USDC', value: `$${m.treasuryUsdc.toFixed(0)}`, color: '#f59e0b' },
              { label: 'Net Deflation', value: `−${m.netDeflation.toFixed(3)}`, color: '#a78bfa', suffix: 'CMXS' },
            ].map(({ label, value, color, suffix }) => (
              <div key={label} style={{ background: 'rgba(15,23,42,0.7)', border: '1px solid rgba(255,255,255,0.06)', borderRadius: 10, padding: '0.8rem' }}>
                <div style={{ fontSize: '0.68rem', color: '#475569', marginBottom: 4 }}>{label}</div>
                <div style={{ fontSize: '1.1rem', fontWeight: 700, color }}>
                  {value} {suffix && <span style={{ fontSize: '0.72rem', color: '#64748b' }}>{suffix}</span>}
                </div>
              </div>
            ))}
          </div>
        )}

        {/* On-chain confirmation */}
        {m?.podConfirmedOnChain && m.txHash && (
          <div style={{ background: 'rgba(34,197,94,0.06)', border: '1px solid rgba(34,197,94,0.2)', borderRadius: 10, padding: '0.85rem 1.1rem', display: 'flex', alignItems: 'center', gap: '1rem' }}>
            <span style={{ fontSize: '1.25rem' }}>✅</span>
            <div>
              <div style={{ fontSize: '0.82rem', fontWeight: 600, color: '#22c55e' }}>PoD Confirmed On-Chain</div>
              <a href={`https://sepolia.basescan.org/tx/${m.txHash}`} target="_blank" rel="noopener noreferrer"
                style={{ fontSize: '0.72rem', color: '#3B82F6', fontFamily: 'monospace', textDecoration: 'none' }}>
                {m.txHash.slice(0, 18)}… ↗
              </a>
            </div>
          </div>
        )}
      </div>

      {/* ── Right: Live Event Log ── */}
      <div style={{ display: 'flex', flexDirection: 'column', gap: '0.75rem' }}>
        <div style={{ background: 'rgba(15,23,42,0.7)', border: '1px solid rgba(255,255,255,0.08)', borderRadius: 12, padding: '0.85rem', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <span style={{ fontSize: '0.78rem', color: '#64748b', fontWeight: 600, textTransform: 'uppercase', letterSpacing: '0.06em' }}>Event Log</span>
          <span style={{ fontSize: '0.72rem', color: '#334155' }}>{events.length} events</span>
        </div>

        <div ref={logRef} style={{ display: 'flex', flexDirection: 'column', gap: '0.4rem', overflow: 'auto', maxHeight: 'calc(100vh - 200px)' }}>
          {events.length === 0 ? (
            <div style={{ color: '#334155', fontSize: '0.78rem', textAlign: 'center', padding: '2rem 0' }}>
              Events will appear here…
            </div>
          ) : events.map((ev, i) => (
            <div key={i} style={{
              padding: '0.6rem 0.85rem',
              background: `${STATUS_COLORS[ev.status]}08`,
              border: `1px solid ${STATUS_COLORS[ev.status]}18`,
              borderLeft: `2px solid ${STATUS_COLORS[ev.status]}`,
              borderRadius: 7, fontSize: '0.75rem',
            }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 3 }}>
                <span style={{ color: STATUS_COLORS[ev.status], fontWeight: 600 }}>
                  {SCENE_ICONS[ev.scene]} S{ev.scene} {ev.status}
                </span>
                <span style={{ color: '#334155' }}>{ev.elapsedMs}ms</span>
              </div>
              <div style={{ color: '#64748b', lineHeight: 1.4 }}>{ev.title}</div>
              {ev.data && Object.keys(ev.data).length > 0 && (
                <div style={{ marginTop: 4, color: '#475569', fontSize: '0.68rem', fontFamily: 'monospace', wordBreak: 'break-all' }}>
                  {Object.entries(ev.data)
                    .filter(([, v]) => typeof v !== 'object')
                    .slice(0, 3)
                    .map(([k, v]) => `${k}: ${v}`)
                    .join(' · ')}
                </div>
              )}
            </div>
          ))}
        </div>
      </div>

      <style>{`
        @keyframes spin { to { transform: rotate(360deg); } }
        @keyframes pulse { 0%, 100% { opacity: 1; } 50% { opacity: 0.3; } }
      `}</style>
    </div>
  );
}
