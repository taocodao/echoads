'use client';

/**
 * /nodes/page.tsx
 * DePIN Node Fleet dashboard — shows all simulated nodes with status,
 * stake, rewards, and device type. Start/Stop simulator controls.
 * Auto-refreshes via SSE event stream from /api/sim/events.
 */

import { useState, useEffect, useRef } from 'react';

const API = process.env.NEXT_PUBLIC_API_URL ?? 'http://localhost:3001';

interface SimNode {
  index: number;
  nodeId: string;
  address: string;
  deviceType: string;
  status: 'ACTIVE' | 'JAILED' | 'OFFLINE' | 'PENDING';
  stakedCmxs: number;
  rewardsCmxs: number;
  impressionsServed: number;
  slashCount: number;
}

interface SimStatus {
  running: boolean;
  nodeCount: number;
  activeNodes: number;
  jailedNodes: number;
  totalImpressions: number;
  totalRewards: number;
}

const STATUS_COLORS: Record<string, string> = {
  ACTIVE: '#22c55e', JAILED: '#ef4444', OFFLINE: '#94a3b8', PENDING: '#f59e0b',
};
const STATUS_ICONS: Record<string, string> = {
  ACTIVE: '🟢', JAILED: '🔴', OFFLINE: '⚫', PENDING: '🟡',
};
const DEVICE_ICONS: Record<string, string> = {
  'Tower': '📡', 'Roku Ultra': '📺', 'Fire TV Cube': '🔥', 'Apple TV 4K': '🍎',
  'Home Broadband': '🏠', 'CBRS Radio': '📶',
};

export default function NodesPage() {
  const [nodes, setNodes] = useState<SimNode[]>([]);
  const [status, setStatus] = useState<SimStatus | null>(null);
  const [nodeCount, setNodeCount] = useState(10);
  const esRef = useRef<EventSource | null>(null);

  const connectSSE = () => {
    if (esRef.current) esRef.current.close();
    const es = new EventSource(`${API}/api/sim/events`);
    esRef.current = es;

    es.addEventListener('snapshot', (e) => {
      const d = JSON.parse(e.data) as { status: SimStatus; nodes: SimNode[] };
      setStatus(d.status); setNodes(d.nodes);
    });
    es.addEventListener('node_registered', () => fetchNodes());
    es.addEventListener('node_slashed', () => fetchNodes());
    es.addEventListener('node_unjailed', () => fetchNodes());
    es.addEventListener('reward_accrued', () => fetchNodes());
    es.addEventListener('sim_started', () => fetchNodes());
    es.addEventListener('sim_stopped', () => { setNodes([]); setStatus(null); });
    es.onerror = () => { es.close(); setTimeout(connectSSE, 3000); };
  };

  const fetchNodes = async () => {
    try {
      const [n, s] = await Promise.all([
        fetch(`${API}/api/sim/nodes/list`).then(r => r.ok ? r.json() as Promise<{ nodes: SimNode[] }> : null),
        fetch(`${API}/api/sim/nodes/status`).then(r => r.ok ? r.json() as Promise<SimStatus> : null),
      ]);
      if (n) setNodes(n.nodes);
      if (s) setStatus(s);
    } catch { /* API offline */ }
  };

  useEffect(() => { fetchNodes(); connectSSE(); return () => esRef.current?.close(); }, []);

  const startSim = async () => {
    await fetch(`${API}/api/sim/nodes/start`, {
      method: 'POST', headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ count: nodeCount }),
    });
  };

  const stopSim = async () => {
    await fetch(`${API}/api/sim/nodes/stop`, { method: 'POST' });
    setNodes([]); setStatus(null);
  };

  const slashNode = async (nodeId: string) => {
    await fetch(`${API}/api/sim/nodes/slash/${nodeId}`, { method: 'POST' });
    await fetchNodes();
  };

  return (
    <div>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1.5rem' }}>
        <div>
          <h1 style={{ margin: 0, fontSize: '1.4rem', fontWeight: 700, color: '#f8fafc' }}>🏗️ DePIN Node Fleet</h1>
          <p style={{ margin: '0.3rem 0 0', fontSize: '0.82rem', color: '#64748b' }}>
            {status ? `${status.activeNodes} active · ${status.jailedNodes} jailed · ${status.totalImpressions} impressions served` : 'Simulator offline'}
          </p>
        </div>
        <div style={{ display: 'flex', gap: '0.75rem', alignItems: 'center' }}>
          <select
            value={nodeCount}
            onChange={(e) => setNodeCount(parseInt(e.target.value))}
            style={{ padding: '0.5rem', background: 'rgba(30,41,59,0.8)', border: '1px solid rgba(255,255,255,0.1)', borderRadius: 6, color: '#94a3b8', fontSize: '0.82rem' }}
          >
            {[5, 8, 10].map(n => <option key={n} value={n}>{n} nodes</option>)}
          </select>
          {status?.running ? (
            <button onClick={stopSim} style={{ padding: '0.55rem 1.1rem', background: 'rgba(239,68,68,0.15)', border: '1px solid rgba(239,68,68,0.3)', borderRadius: 8, color: '#ef4444', cursor: 'pointer', fontSize: '0.82rem', fontWeight: 600 }}>
              ⏹ Stop Sim
            </button>
          ) : (
            <button onClick={startSim} style={{ padding: '0.55rem 1.1rem', background: 'linear-gradient(135deg,#3B82F6,#8B5CF6)', border: 'none', borderRadius: 8, color: '#fff', cursor: 'pointer', fontSize: '0.82rem', fontWeight: 600 }}>
              ▶ Start Sim
            </button>
          )}
        </div>
      </div>

      {/* Summary stat cards */}
      {status && (
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4,1fr)', gap: '1rem', marginBottom: '1.5rem' }}>
          {[
            { label: 'Total Nodes', value: status.nodeCount },
            { label: 'Active', value: status.activeNodes, color: '#22c55e' },
            { label: 'Jailed', value: status.jailedNodes, color: '#ef4444' },
            { label: 'Total Rewards', value: `${status.totalRewards.toFixed(4)} CMXS`, color: '#8B5CF6' },
          ].map(({ label, value, color }) => (
            <div key={label} style={{ background: 'rgba(30,41,59,0.7)', border: '1px solid rgba(255,255,255,0.08)', borderRadius: 10, padding: '1rem' }}>
              <div style={{ fontSize: '0.75rem', color: '#64748b', marginBottom: '0.4rem' }}>{label}</div>
              <div style={{ fontSize: '1.5rem', fontWeight: 700, color: color ?? '#f8fafc' }}>{value}</div>
            </div>
          ))}
        </div>
      )}

      {/* Node grid */}
      {nodes.length === 0 ? (
        <div style={{ textAlign: 'center', padding: '3rem', color: '#475569', fontSize: '0.9rem', background: 'rgba(15,23,42,0.5)', borderRadius: 12, border: '1px dashed rgba(255,255,255,0.06)' }}>
          No nodes running. Click &quot;Start Sim&quot; to spawn the DePIN fleet.
        </div>
      ) : (
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(280px, 1fr))', gap: '1rem' }}>
          {nodes.map((node) => (
            <div key={node.nodeId} style={{
              background: 'rgba(15,23,42,0.8)',
              border: `1px solid ${node.status === 'JAILED' ? 'rgba(239,68,68,0.3)' : node.status === 'ACTIVE' ? 'rgba(34,197,94,0.15)' : 'rgba(255,255,255,0.06)'}`,
              borderRadius: 12, padding: '1.1rem',
              transition: 'border-color 0.3s',
            }}>
              {/* Node header */}
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: '0.85rem' }}>
                <div>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', marginBottom: '0.25rem' }}>
                    <span style={{ fontSize: '1.1rem' }}>{DEVICE_ICONS[node.deviceType] ?? '📡'}</span>
                    <span style={{ fontSize: '0.82rem', fontWeight: 700, color: '#e2e8f0' }}>{node.nodeId}</span>
                  </div>
                  <div style={{ fontSize: '0.72rem', color: '#475569', fontFamily: 'monospace' }}>
                    {node.address.slice(0, 10)}…{node.address.slice(-6)}
                  </div>
                </div>
                <div style={{
                  display: 'flex', alignItems: 'center', gap: '0.35rem',
                  padding: '0.3rem 0.65rem',
                  background: `${STATUS_COLORS[node.status] ?? '#94a3b8'}15`,
                  border: `1px solid ${STATUS_COLORS[node.status] ?? '#94a3b8'}30`,
                  borderRadius: 20, fontSize: '0.72rem', fontWeight: 700,
                  color: STATUS_COLORS[node.status] ?? '#94a3b8',
                }}>
                  {STATUS_ICONS[node.status]} {node.status}
                </div>
              </div>

              {/* Metrics */}
              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '0.5rem', marginBottom: '0.85rem' }}>
                {[
                  { label: 'Staked', value: `${node.stakedCmxs.toLocaleString()} CMXS` },
                  { label: 'Rewards', value: `${node.rewardsCmxs.toFixed(4)} CMXS`, color: '#8B5CF6' },
                  { label: 'Impressions', value: node.impressionsServed.toString(), color: '#3B82F6' },
                  { label: 'Slashes', value: node.slashCount.toString(), color: node.slashCount > 0 ? '#ef4444' : '#475569' },
                ].map(({ label, value, color }) => (
                  <div key={label} style={{ background: 'rgba(30,41,59,0.5)', borderRadius: 7, padding: '0.5rem 0.65rem' }}>
                    <div style={{ fontSize: '0.68rem', color: '#475569' }}>{label}</div>
                    <div style={{ fontSize: '0.82rem', fontWeight: 600, color: color ?? '#94a3b8', marginTop: 2 }}>{value}</div>
                  </div>
                ))}
              </div>

              {/* Slash button */}
              {node.status === 'ACTIVE' && (
                <button
                  onClick={() => slashNode(node.nodeId)}
                  style={{
                    width: '100%', padding: '0.45rem',
                    background: 'rgba(239,68,68,0.08)',
                    border: '1px solid rgba(239,68,68,0.2)',
                    borderRadius: 7, color: '#f87171', fontSize: '0.75rem', cursor: 'pointer',
                  }}
                >
                  ⚡ Simulate SLA Breach (Slash MINOR)
                </button>
              )}
              {node.status === 'JAILED' && (
                <div style={{ padding: '0.45rem', textAlign: 'center', fontSize: '0.75rem', color: '#ef4444' }}>
                  ⏳ Jailed — auto-unjail in 30s
                </div>
              )}
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
