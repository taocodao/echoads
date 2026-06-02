'use client';

/**
 * /auction/page.tsx
 * Live auction log — shows real-time bid history from /api/auction/history
 * and DSP stats from /api/auction/stats
 */

import { useState, useEffect } from 'react';

const API = process.env.NEXT_PUBLIC_API_URL ?? 'http://localhost:3001';

interface AuctionResult {
  auctionId: string;
  sessionId: string;
  totalLatencyMs: number;
  breakType: string;
  slots: Array<{
    slotIndex: number;
    dspName: string;
    advertiser: string;
    winningCpm: number;
    clearingCpm: number;
    duration: number;
  }>;
  fillRate: number;
  bidsReceived: number;
  bidsTimedOut: number;
  timestamp: string;
}

interface AuctionStats {
  totalAuctions: number;
  avgLatencyMs: number;
  avgCpm: number;
  avgFillRate: number;
  dspBreakdown: Array<{ dspId: string; dspName: string; wins: number }>;
}

export default function AuctionPage() {
  const [auctions, setAuctions] = useState<AuctionResult[]>([]);
  const [stats, setStats] = useState<AuctionStats | null>(null);
  const [loading, setLoading] = useState(true);

  const refresh = async () => {
    try {
      const [histRes, statsRes] = await Promise.all([
        fetch(`${API}/api/auction/history?limit=20`),
        fetch(`${API}/api/auction/stats`),
      ]);
      if (histRes.ok) {
        const d = await histRes.json() as { auctions: AuctionResult[] };
        setAuctions(d.auctions);
      }
      if (statsRes.ok) setStats(await statsRes.json() as AuctionStats);
    } catch { /* API offline */ }
    setLoading(false);
  };

  const runTestAuction = async () => {
    await fetch(`${API}/api/auction/run`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ breakType: 'halftime', sessionId: `manual-${Date.now()}` }),
    });
    await refresh();
  };

  useEffect(() => { refresh(); const t = setInterval(refresh, 5000); return () => clearInterval(t); }, []);

  return (
    <div style={{ maxWidth: 1200 }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1.5rem' }}>
        <div>
          <h1 style={{ margin: 0, fontSize: '1.4rem', fontWeight: 700, color: '#f8fafc' }}>⚡ Auction Engine</h1>
          <p style={{ margin: '0.3rem 0 0', fontSize: '0.82rem', color: '#64748b' }}>OpenRTB 2.6 · 5 simulated DSPs · Second-price Vickrey</p>
        </div>
        <button onClick={runTestAuction} style={{
          padding: '0.6rem 1.25rem', background: 'linear-gradient(135deg,#3B82F6,#8B5CF6)',
          border: 'none', borderRadius: 8, color: '#fff', fontWeight: 600, cursor: 'pointer', fontSize: '0.85rem',
        }}>
          ▶ Run Test Auction
        </button>
      </div>

      {/* Stats row */}
      {stats && (
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4,1fr)', gap: '1rem', marginBottom: '1.5rem' }}>
          {[
            { label: 'Total Auctions', value: stats.totalAuctions },
            { label: 'Avg Latency', value: `${stats.avgLatencyMs}ms`, color: stats.avgLatencyMs < 500 ? '#22c55e' : '#f59e0b' },
            { label: 'Avg CPM', value: `$${stats.avgCpm}`, color: '#3B82F6' },
            { label: 'Avg Fill Rate', value: `${(stats.avgFillRate * 100).toFixed(0)}%`, color: '#8B5CF6' },
          ].map(({ label, value, color }) => (
            <div key={label} style={{ background: 'rgba(30,41,59,0.7)', border: '1px solid rgba(255,255,255,0.08)', borderRadius: 10, padding: '1rem' }}>
              <div style={{ fontSize: '0.75rem', color: '#64748b', marginBottom: '0.4rem' }}>{label}</div>
              <div style={{ fontSize: '1.5rem', fontWeight: 700, color: color ?? '#f8fafc' }}>{value}</div>
            </div>
          ))}
        </div>
      )}

      {/* DSP breakdown */}
      {stats?.dspBreakdown && (
        <div style={{ background: 'rgba(30,41,59,0.6)', border: '1px solid rgba(255,255,255,0.08)', borderRadius: 10, padding: '1rem', marginBottom: '1.5rem' }}>
          <div style={{ fontSize: '0.78rem', color: '#64748b', marginBottom: '0.75rem', textTransform: 'uppercase', letterSpacing: '0.06em' }}>DSP Win Distribution</div>
          <div style={{ display: 'flex', gap: '1rem', flexWrap: 'wrap' }}>
            {stats.dspBreakdown.map((dsp) => (
              <div key={dsp.dspId} style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                <div style={{ width: 8, height: 8, borderRadius: '50%', background: '#3B82F6' }} />
                <span style={{ fontSize: '0.82rem', color: '#94a3b8' }}>{dsp.dspName}</span>
                <span style={{ fontSize: '0.82rem', fontWeight: 700, color: '#f8fafc' }}>{dsp.wins}W</span>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Auction log */}
      <div style={{ background: 'rgba(15,23,42,0.7)', border: '1px solid rgba(255,255,255,0.08)', borderRadius: 12, overflow: 'hidden' }}>
        <div style={{ padding: '0.85rem 1.25rem', borderBottom: '1px solid rgba(255,255,255,0.06)', display: 'flex', justifyContent: 'space-between' }}>
          <span style={{ fontSize: '0.82rem', color: '#64748b', fontWeight: 600 }}>Recent Auctions (auto-refresh 5s)</span>
          <span style={{ fontSize: '0.75rem', color: '#334155' }}>{auctions.length} results</span>
        </div>
        {loading ? (
          <div style={{ padding: '2rem', textAlign: 'center', color: '#475569' }}>Loading…</div>
        ) : auctions.length === 0 ? (
          <div style={{ padding: '2rem', textAlign: 'center', color: '#475569', fontSize: '0.85rem' }}>No auctions yet — click "Run Test Auction" above</div>
        ) : (
          <table style={{ width: '100%', borderCollapse: 'collapse', fontSize: '0.8rem' }}>
            <thead>
              <tr style={{ borderBottom: '1px solid rgba(255,255,255,0.06)' }}>
                {['Auction ID','Break','DSP Winner','CPM Bid','Clears At','Latency','Fill','Time'].map(h => (
                  <th key={h} style={{ padding: '0.65rem 1rem', textAlign: 'left', color: '#475569', fontWeight: 500 }}>{h}</th>
                ))}
              </tr>
            </thead>
            <tbody>
              {auctions.map((a) => {
                const slot0 = a.slots[0];
                return (
                  <tr key={a.auctionId} style={{ borderBottom: '1px solid rgba(255,255,255,0.04)' }}>
                    <td style={{ padding: '0.65rem 1rem', color: '#94a3b8', fontFamily: 'monospace' }}>{a.auctionId.slice(0,12)}…</td>
                    <td style={{ padding: '0.65rem 1rem', color: '#f8fafc' }}>{a.breakType}</td>
                    <td style={{ padding: '0.65rem 1rem', color: '#3B82F6' }}>{slot0?.dspName ?? '—'}</td>
                    <td style={{ padding: '0.65rem 1rem', color: '#22c55e', fontWeight: 700 }}>${slot0?.winningCpm?.toFixed(2) ?? '—'}</td>
                    <td style={{ padding: '0.65rem 1rem', color: '#94a3b8' }}>${slot0?.clearingCpm?.toFixed(2) ?? '—'}</td>
                    <td style={{ padding: '0.65rem 1rem', color: a.totalLatencyMs < 400 ? '#22c55e' : '#f59e0b' }}>{a.totalLatencyMs}ms</td>
                    <td style={{ padding: '0.65rem 1rem', color: '#94a3b8' }}>{(a.fillRate * 100).toFixed(0)}%</td>
                    <td style={{ padding: '0.65rem 1rem', color: '#475569' }}>{new Date(a.timestamp).toLocaleTimeString()}</td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        )}
      </div>
    </div>
  );
}
