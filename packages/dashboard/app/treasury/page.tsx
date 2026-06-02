'use client';

/**
 * /treasury/page.tsx
 * Treasury balance, epoch distributions, and veToken holder claims.
 */

import { useState, useEffect } from 'react';

const API = process.env.NEXT_PUBLIC_API_URL ?? 'http://localhost:3001';

interface TreasuryData {
  usdcBalance?: string;
  epochNumber?: number;
  lastDistribution?: { usdc: string; timestamp: string } | undefined;
  totalBurned?: string;
  totalMinted?: string;
  netDeflation?: string;
}

export default function TreasuryPage() {
  const [data, setData] = useState<TreasuryData>({});
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    // Treasury data comes from on-chain reads or the simulation state.
    // For the prototype, we poll /api/sim/nodes/status and /api/delivery/relay-status
    const fetch_ = async () => {
      try {
        const [simRes, relayRes] = await Promise.all([
          fetch(`${API}/api/sim/nodes/status`),
          fetch(`${API}/api/delivery/relay-status`),
        ]);
        const sim = simRes.ok ? await simRes.json() as { totalImpressions: number; totalRewards: number } : null;
        const relay = relayRes.ok ? await relayRes.json() as { queueDepth: number; processedTotal: number } : null;

        // Simulated treasury calculations
        const impressions = sim?.totalImpressions ?? 0;
        const rewards = sim?.totalRewards ?? 0;
        // Assume $42 avg CPM, 15% treasury take, campaign $1000 USDC → 100 CMXS burned
        const usdcRevenue = (impressions * 42) / 1000 * 1.5; // simplified
        const treasuryShare = usdcRevenue * 0.15;

        setData({
          usdcBalance: treasuryShare.toFixed(2),
          epochNumber: Math.floor(impressions / 50) + 1,
          lastDistribution: impressions > 0 ? { usdc: (treasuryShare * 0.7).toFixed(2), timestamp: new Date().toISOString() } : undefined,
          totalBurned: '100.000',
          totalMinted: rewards.toFixed(6),
          netDeflation: (100 - rewards).toFixed(6),
        });
      } catch { /* API offline */ }
      setLoading(false);
    };
    fetch_();
    const t = setInterval(fetch_, 10_000);
    return () => clearInterval(t);
  }, []);

  return (
    <div style={{ maxWidth: 900 }}>
      <h1 style={{ margin: '0 0 0.4rem', fontSize: '1.4rem', fontWeight: 700, color: '#f8fafc' }}>💰 Treasury</h1>
      <p style={{ margin: '0 0 1.5rem', fontSize: '0.82rem', color: '#64748b' }}>Protocol fee accumulation, epoch distributions, and deflationary proof</p>

      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(2,1fr)', gap: '1.25rem', marginBottom: '1.5rem' }}>
        {/* USDC Balance */}
        <div style={{ background: 'linear-gradient(135deg, rgba(59,130,246,0.12), rgba(139,92,246,0.08))', border: '1px solid rgba(59,130,246,0.2)', borderRadius: 12, padding: '1.5rem' }}>
          <div style={{ fontSize: '0.78rem', color: '#64748b', marginBottom: '0.5rem', textTransform: 'uppercase', letterSpacing: '0.06em' }}>Treasury USDC Balance</div>
          <div style={{ fontSize: '2.5rem', fontWeight: 800, color: '#3B82F6' }}>${data.usdcBalance ?? '—'}</div>
          <div style={{ fontSize: '0.78rem', color: '#64748b', marginTop: '0.5rem' }}>Epoch {data.epochNumber ?? 1} · 15% of ad revenue</div>
        </div>

        {/* Epoch distribution */}
        <div style={{ background: 'rgba(30,41,59,0.7)', border: '1px solid rgba(255,255,255,0.08)', borderRadius: 12, padding: '1.5rem' }}>
          <div style={{ fontSize: '0.78rem', color: '#64748b', marginBottom: '0.5rem', textTransform: 'uppercase', letterSpacing: '0.06em' }}>Last Epoch Distribution</div>
          {data.lastDistribution ? (
            <>
              <div style={{ fontSize: '2rem', fontWeight: 800, color: '#8B5CF6' }}>${data.lastDistribution.usdc}</div>
              <div style={{ fontSize: '0.78rem', color: '#64748b', marginTop: '0.5rem' }}>→ veToken holders (70% of treasury)</div>
              <div style={{ fontSize: '0.72rem', color: '#334155', marginTop: '0.3rem' }}>{new Date(data.lastDistribution.timestamp).toLocaleString()}</div>
            </>
          ) : (
            <div style={{ fontSize: '0.85rem', color: '#475569' }}>No distributions yet</div>
          )}
        </div>
      </div>

      {/* Deflationary proof */}
      <div style={{ background: 'rgba(15,23,42,0.8)', border: '1px solid rgba(255,255,255,0.08)', borderRadius: 12, padding: '1.5rem', marginBottom: '1.5rem' }}>
        <div style={{ fontSize: '0.82rem', color: '#64748b', marginBottom: '1rem', textTransform: 'uppercase', letterSpacing: '0.06em', fontWeight: 600 }}>🔥 CMXS Deflationary Proof</div>
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3,1fr)', gap: '1rem' }}>
          {[
            { label: 'Total Burned', value: `${data.totalBurned ?? '0'} CMXS`, color: '#ef4444', icon: '🔥' },
            { label: 'Total Minted', value: `${data.totalMinted ?? '0'} CMXS`, color: '#22c55e', icon: '⛏️' },
            { label: 'Net Deflation', value: `−${data.netDeflation ?? '0'} CMXS`, color: '#8B5CF6', icon: '📉' },
          ].map(({ label, value, color, icon }) => (
            <div key={label} style={{ background: 'rgba(30,41,59,0.5)', border: '1px solid rgba(255,255,255,0.06)', borderRadius: 10, padding: '1rem', textAlign: 'center' }}>
              <div style={{ fontSize: '1.75rem', marginBottom: '0.5rem' }}>{icon}</div>
              <div style={{ fontSize: '0.75rem', color: '#64748b', marginBottom: '0.4rem' }}>{label}</div>
              <div style={{ fontSize: '1rem', fontWeight: 700, color }}>{value}</div>
            </div>
          ))}
        </div>
        <p style={{ margin: '1rem 0 0', fontSize: '0.78rem', color: '#475569', textAlign: 'center' }}>
          Burns always exceed mints — every ad campaign is deflationary by design.
        </p>
      </div>

      {/* Revenue waterfall */}
      <div style={{ background: 'rgba(30,41,59,0.6)', border: '1px solid rgba(255,255,255,0.08)', borderRadius: 12, padding: '1.5rem' }}>
        <div style={{ fontSize: '0.82rem', color: '#64748b', marginBottom: '1rem', fontWeight: 600 }}>Campaign Revenue Waterfall ($1,000 USDC example)</div>
        {[
          { label: 'Gross Ad Revenue',     pct: 100, value: '$1,000', color: '#3B82F6' },
          { label: '→ Content Partner',    pct: 85,  value: '$850',   color: '#22c55e' },
          { label: '→ Protocol Treasury',  pct: 15,  value: '$150',   color: '#8B5CF6' },
          { label: '  → veToken Holders',  pct: 10,  value: '$105',   color: '#a78bfa' },
          { label: '  → Node Rewards',     pct: 5,   value: '$45',    color: '#34d399' },
          { label: 'CMXS Burned (100)',     pct: null, value: '−100 CMXS', color: '#ef4444' },
        ].map(({ label, pct, value, color }) => (
          <div key={label} style={{ display: 'flex', alignItems: 'center', gap: '1rem', marginBottom: '0.65rem' }}>
            <div style={{ width: 180, fontSize: '0.8rem', color: '#94a3b8', flexShrink: 0 }}>{label}</div>
            {pct !== null && (
              <div style={{ flex: 1, height: 6, background: 'rgba(255,255,255,0.06)', borderRadius: 3, overflow: 'hidden' }}>
                <div style={{ width: `${pct}%`, height: '100%', background: color, borderRadius: 3, transition: 'width 1s' }} />
              </div>
            )}
            <div style={{ fontSize: '0.82rem', fontWeight: 700, color, width: 90, textAlign: 'right' }}>{value}</div>
          </div>
        ))}
      </div>
    </div>
  );
}
