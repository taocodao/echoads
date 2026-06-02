import type { Metadata } from 'next';
import { HlsPlayer } from './components/HlsPlayer';

export const metadata: Metadata = {
  title: 'CMXS Live Player — Sports FAST Channel',
  description: 'Live SSAI sports stream with programmatic ad delivery and on-chain PoD verification',
};

export default function PlayerPage() {
  return (
    <div style={{ maxWidth: 1300, margin: '0 auto', padding: '1.5rem 0' }}>
      {/* Header */}
      <div style={{ marginBottom: '1.5rem' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem', marginBottom: '0.4rem' }}>
          <div style={{
            width: 10, height: 10, borderRadius: '50%',
            background: '#ef4444', boxShadow: '0 0 10px #ef4444',
            animation: 'pulse 1.5s infinite',
          }} />
          <span style={{ fontSize: '0.8rem', color: '#ef4444', fontWeight: 700, letterSpacing: '0.1em', textTransform: 'uppercase' }}>
            Live
          </span>
        </div>
        <h1 style={{ margin: 0, fontSize: '1.5rem', fontWeight: 700, color: '#f8fafc' }}>
          LIV Golf — Round 2 · CMXS Sports Channel
        </h1>
        <p style={{ margin: '0.4rem 0 0', fontSize: '0.85rem', color: '#64748b' }}>
          SSAI-stitched stream · OpenRTB 2.6 · PoD verified on Base Sepolia
        </p>
      </div>

      {/* Player */}
      <HlsPlayer
        nodeOperator={process.env.NEXT_PUBLIC_DEFAULT_NODE ?? '0x0000000000000000000000000000000000000001'}
        campaignId={process.env.NEXT_PUBLIC_DEFAULT_CAMPAIGN ?? '0xdeadbeef00000000000000000000000000000000000000000000000000000000'}
      />

      {/* Info cards */}
      <div style={{
        display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)',
        gap: '1rem', marginTop: '1.5rem',
      }}>
        {[
          {
            icon: '📡',
            title: 'SSAI Stitching',
            desc: 'Ad creatives spliced server-side via HLS EXT-X-DISCONTINUITY. No client-side ad calls — immune to ad blockers.',
          },
          {
            icon: '⚡',
            title: 'OpenRTB 2.6 Auction',
            desc: '5 DSPs bid per pod slot. Second-price Vickrey auction resolves in <500ms before stream loads.',
          },
          {
            icon: '🔗',
            title: 'On-Chain PoD',
            desc: 'Each completed impression fires a PoD receipt to DeliveryOracleV2 on Base Sepolia. Burns verify deliveries.',
          },
        ].map(({ icon, title, desc }) => (
          <div key={title} style={{
            background: 'rgba(30,41,59,0.6)',
            border: '1px solid rgba(255,255,255,0.08)',
            borderRadius: 10, padding: '1rem 1.25rem',
          }}>
            <div style={{ fontSize: '1.5rem', marginBottom: '0.5rem' }}>{icon}</div>
            <div style={{ fontWeight: 600, color: '#e2e8f0', marginBottom: '0.35rem', fontSize: '0.9rem' }}>{title}</div>
            <div style={{ fontSize: '0.78rem', color: '#64748b', lineHeight: 1.6 }}>{desc}</div>
          </div>
        ))}
      </div>

      <style>{`
        @keyframes pulse { 0%, 100% { opacity: 1; } 50% { opacity: 0.3; } }
      `}</style>
    </div>
  );
}
