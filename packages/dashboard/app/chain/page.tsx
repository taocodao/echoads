'use client';

/**
 * /chain/page.tsx
 * On-chain explorer — shows recent DeliveryOracleV2 events with Basescan links.
 */

import { useState, useEffect } from 'react';

const API = process.env.NEXT_PUBLIC_API_URL ?? 'http://localhost:3001';
const BASESCAN_BASE = 'https://sepolia.basescan.org';

interface RelayStatus {
  queueDepth: number;
  processedTotal: number;
  recentBatches?: Array<{
    txHash: string;
    impressionCount: number;
    timestamp: string;
    mintedCmxs?: string;
  }>;
}

interface ChainInfo {
  cmxsAddress?: string | undefined;
  oracleAddress?: string | undefined;
  chainId: number;
}

export default function ChainPage() {
  const [relay, setRelay] = useState<RelayStatus | null>(null);
  const [chainInfo] = useState<ChainInfo>({
    cmxsAddress: process.env.NEXT_PUBLIC_CMXS_CONTRACT_ADDRESS,
    oracleAddress: process.env.NEXT_PUBLIC_ORACLE_CONTRACT_ADDRESS,
    chainId: parseInt(process.env.NEXT_PUBLIC_CHAIN_ID ?? '84532'),
  });

  useEffect(() => {
    const fetch_ = async () => {
      try {
        const r = await fetch(`${API}/api/delivery/relay-status`);
        if (r.ok) setRelay(await r.json() as RelayStatus);
      } catch { /* offline */ }
    };
    fetch_();
    const t = setInterval(fetch_, 8_000);
    return () => clearInterval(t);
  }, []);

  return (
    <div style={{ maxWidth: 1000 }}>
      <h1 style={{ margin: '0 0 0.4rem', fontSize: '1.4rem', fontWeight: 700, color: '#f8fafc' }}>🔗 On-Chain Explorer</h1>
      <p style={{ margin: '0 0 1.5rem', fontSize: '0.82rem', color: '#64748b' }}>Base Sepolia · DeliveryOracleV2 · CMXS Token · Real-time PoD confirmations</p>

      {/* Contract addresses */}
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1rem', marginBottom: '1.5rem' }}>
        {[
          { label: 'CMXS Token', address: chainInfo.cmxsAddress, path: 'token' },
          { label: 'DeliveryOracleV2', address: chainInfo.oracleAddress, path: 'address' },
        ].map(({ label, address, path }) => (
          <div key={label} style={{ background: 'rgba(30,41,59,0.7)', border: '1px solid rgba(255,255,255,0.08)', borderRadius: 10, padding: '1rem 1.25rem' }}>
            <div style={{ fontSize: '0.75rem', color: '#64748b', marginBottom: '0.4rem', textTransform: 'uppercase', letterSpacing: '0.06em' }}>{label}</div>
            {address ? (
              <a
                href={`${BASESCAN_BASE}/${path}/${address}`}
                target="_blank" rel="noopener noreferrer"
                style={{ fontSize: '0.82rem', color: '#3B82F6', fontFamily: 'monospace', textDecoration: 'none' }}
              >
                {address.slice(0, 12)}…{address.slice(-8)} ↗
              </a>
            ) : (
              <span style={{ fontSize: '0.82rem', color: '#334155' }}>Not configured (add to .env)</span>
            )}
          </div>
        ))}
      </div>

      {/* PoD relay stats */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3,1fr)', gap: '1rem', marginBottom: '1.5rem' }}>
        {[
          { label: 'Queue Depth', value: relay?.queueDepth ?? 0, color: relay?.queueDepth && relay.queueDepth > 400 ? '#ef4444' : '#22c55e', suffix: '/ 500' },
          { label: 'Processed Total', value: relay?.processedTotal ?? 0, color: '#3B82F6' },
          { label: 'Recent Batches', value: relay?.recentBatches?.length ?? 0, color: '#8B5CF6' },
        ].map(({ label, value, color, suffix }) => (
          <div key={label} style={{ background: 'rgba(30,41,59,0.7)', border: '1px solid rgba(255,255,255,0.08)', borderRadius: 10, padding: '1rem' }}>
            <div style={{ fontSize: '0.75rem', color: '#64748b', marginBottom: '0.4rem' }}>{label}</div>
            <div style={{ fontSize: '1.5rem', fontWeight: 700, color }}>
              {value} {suffix && <span style={{ fontSize: '0.9rem', color: '#475569' }}>{suffix}</span>}
            </div>
          </div>
        ))}
      </div>

      {/* Recent on-chain batches */}
      <div style={{ background: 'rgba(15,23,42,0.8)', border: '1px solid rgba(255,255,255,0.08)', borderRadius: 12, overflow: 'hidden' }}>
        <div style={{ padding: '0.85rem 1.25rem', borderBottom: '1px solid rgba(255,255,255,0.06)' }}>
          <span style={{ fontSize: '0.82rem', color: '#64748b', fontWeight: 600 }}>Recent PoD Batches (auto-refresh 8s)</span>
        </div>
        {!relay?.recentBatches || relay.recentBatches.length === 0 ? (
          <div style={{ padding: '2.5rem', textAlign: 'center', color: '#334155', fontSize: '0.85rem' }}>
            No on-chain batches yet.<br />Start the simulator and play a stream to generate PoD receipts.
          </div>
        ) : (
          <table style={{ width: '100%', borderCollapse: 'collapse', fontSize: '0.8rem' }}>
            <thead>
              <tr style={{ borderBottom: '1px solid rgba(255,255,255,0.06)' }}>
                {['Tx Hash', 'Impressions', 'CMXS Minted', 'Time', 'Basescan'].map(h => (
                  <th key={h} style={{ padding: '0.65rem 1.25rem', textAlign: 'left', color: '#475569', fontWeight: 500 }}>{h}</th>
                ))}
              </tr>
            </thead>
            <tbody>
              {relay.recentBatches.map((batch) => (
                <tr key={batch.txHash} style={{ borderBottom: '1px solid rgba(255,255,255,0.04)' }}>
                  <td style={{ padding: '0.65rem 1.25rem', color: '#94a3b8', fontFamily: 'monospace' }}>{batch.txHash.slice(0, 14)}…</td>
                  <td style={{ padding: '0.65rem 1.25rem', color: '#3B82F6', fontWeight: 700 }}>{batch.impressionCount}</td>
                  <td style={{ padding: '0.65rem 1.25rem', color: '#8B5CF6' }}>{batch.mintedCmxs ?? '—'}</td>
                  <td style={{ padding: '0.65rem 1.25rem', color: '#475569' }}>{new Date(batch.timestamp).toLocaleTimeString()}</td>
                  <td style={{ padding: '0.65rem 1.25rem' }}>
                    <a
                      href={`${BASESCAN_BASE}/tx/${batch.txHash}`}
                      target="_blank" rel="noopener noreferrer"
                      style={{ color: '#3B82F6', fontSize: '0.75rem', textDecoration: 'none' }}
                    >
                      View ↗
                    </a>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>
    </div>
  );
}
