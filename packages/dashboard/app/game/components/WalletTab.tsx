'use client';
/**
 * WalletTab.tsx — Arenza Points wallet + QR member card
 * iOS equivalent: WalletView + QRCodeView (SwiftUI)
 */
import { useState } from 'react';
import { REDEMPTION_CATALOG, type RedemptionItem } from '../lib/sharedTypes';
import { MemberQRCard } from './MemberQRCard';

const T = {
  bg: '#0d0f14', surface: '#141720', surface2: '#1a1e2a',
  border: 'rgba(255,255,255,0.08)', text: '#f0f2ff', muted: '#8892b0',
  faint: '#4a5568', orange: '#ff6b35', teal: '#00c9b1',
  gold: '#ffc107', green: '#22c55e', purple: '#7c3aed',
};

interface WalletTabProps {
  points: number;
  claimedCoupons: { businessName: string; offer: string; code?: string; claimedAt: number }[];
  joinedClubs: { businessName: string; cardName: string; emoji: string; joinedAt: number }[];
}

const SECTIONS = [
  { key: 'qr' as const,      label: '📲 My QR'    },
  { key: 'points' as const,  label: '🎟 Redeem'   },
  { key: 'coupons' as const, label: '🏷 Coupons'  },
  { key: 'cards' as const,   label: '🪪 Cards'    },
];
type Section = typeof SECTIONS[number]['key'];

export function WalletTab({ points, claimedCoupons, joinedClubs }: WalletTabProps) {
  const [redeemedIds, setRedeemedIds] = useState<Set<string>>(new Set());
  const [activeSection, setActiveSection] = useState<Section>('qr');

  const handleRedeem = (item: RedemptionItem) => {
    if (points < item.pointsCost || redeemedIds.has(item.id)) return;
    setRedeemedIds(prev => new Set([...prev, item.id]));
  };

  return (
    <div style={{ height: '100%', overflowY: 'auto', display: 'flex', flexDirection: 'column', gap: 10 }}>

      {/* Header */}
      <div style={{ fontSize: 11, fontWeight: 700, color: T.orange, textTransform: 'uppercase', letterSpacing: '.08em' }}>
        💳 Wallet & Points
      </div>

      {/* Points balance card */}
      <div style={{
        padding: '14px 16px',
        background: `linear-gradient(135deg, ${T.orange}22, ${T.purple}22)`,
        border: `1px solid ${T.orange}44`, borderRadius: 14,
        display: 'flex', justifyContent: 'space-between', alignItems: 'center',
      }}>
        <div>
          <div style={{ fontSize: 9, color: T.muted, textTransform: 'uppercase', letterSpacing: '0.08em', marginBottom: 4 }}>
            Arenza Points
          </div>
          <div style={{ fontFamily: 'JetBrains Mono, monospace', fontSize: 34, fontWeight: 900, color: T.gold, lineHeight: 1 }}>
            {points.toLocaleString()}
          </div>
          <div style={{ fontSize: 9, color: T.muted, marginTop: 4 }}>
            Redeemable at {joinedClubs.length || 6} sponsor locations
          </div>
        </div>
        <div style={{ textAlign: 'center' }}>
          <div style={{ fontSize: 32 }}>🏆</div>
          <div style={{ fontSize: 9, color: T.muted }}>Points Balance</div>
        </div>
      </div>

      {/* Section tabs */}
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr 1fr', gap: 4 }}>
        {SECTIONS.map(s => (
          <button key={s.key} onClick={() => setActiveSection(s.key)} style={{
            padding: '6px 2px', borderRadius: 8, fontSize: 9, fontWeight: 700,
            border: `1px solid ${activeSection === s.key ? T.orange : T.border}`,
            background: activeSection === s.key ? `${T.orange}18` : 'transparent',
            color: activeSection === s.key ? T.orange : T.muted, cursor: 'pointer',
          }}>{s.label}</button>
        ))}
      </div>

      {/* ── QR Member Card ── */}
      {activeSection === 'qr' && (
        <div>
          <MemberQRCard points={points} />
          <div style={{ marginTop: 12, textAlign: 'center' }}>
            <div style={{ fontSize: 9, color: T.faint, marginBottom: 6 }}>Business staff?</div>
            <a href="/scanner" target="_blank" rel="noopener noreferrer" style={{
              display: 'inline-flex', alignItems: 'center', gap: 6,
              padding: '7px 14px', borderRadius: 8, fontSize: 10, fontWeight: 700,
              border: `1px solid ${T.teal}44`, color: T.teal, textDecoration: 'none',
              background: `${T.teal}11`,
            }}>
              📷 Open Business Scanner →
            </a>
          </div>
        </div>
      )}

      {/* ── Redemption catalog ── */}
      {activeSection === 'points' && (
        <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
          <div style={{ fontSize: 9, color: T.muted, textTransform: 'uppercase', letterSpacing: '0.06em' }}>
            Redemption Catalog
          </div>
          {REDEMPTION_CATALOG.map(item => {
            const canAfford = points >= item.pointsCost;
            const redeemed = redeemedIds.has(item.id);
            return (
              <div key={item.id} style={{
                padding: '10px 12px', background: T.surface,
                border: `1px solid ${redeemed ? T.green : canAfford ? T.orange : T.border}33`,
                borderRadius: 10, display: 'flex', alignItems: 'center', gap: 10,
                opacity: canAfford || redeemed ? 1 : 0.55,
              }}>
                <span style={{ fontSize: 22 }}>{item.emoji}</span>
                <div style={{ flex: 1 }}>
                  <div style={{ fontSize: 11, fontWeight: 700, color: T.text }}>{item.title}</div>
                  <div style={{ fontSize: 9, color: T.muted }}>{item.description}</div>
                </div>
                <button onClick={() => handleRedeem(item)} disabled={!canAfford || redeemed} style={{
                  padding: '5px 10px', borderRadius: 99, fontSize: 9, fontWeight: 700, border: 'none',
                  cursor: canAfford && !redeemed ? 'pointer' : 'default',
                  background: redeemed ? `${T.green}22` : canAfford ? T.orange : T.surface2,
                  color: redeemed ? T.green : canAfford ? '#fff' : T.faint,
                  transition: 'all 0.2s', whiteSpace: 'nowrap',
                }}>
                  {redeemed ? '✅ Used' : `${item.pointsCost.toLocaleString()} pts`}
                </button>
              </div>
            );
          })}
        </div>
      )}

      {/* ── Claimed coupons ── */}
      {activeSection === 'coupons' && (
        <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
          {claimedCoupons.length === 0 ? (
            <div style={{ textAlign: 'center', padding: '30px 0', color: T.muted }}>
              <div style={{ fontSize: 28, marginBottom: 8 }}>🎟</div>
              <div style={{ fontSize: 11 }}>No coupons claimed yet</div>
              <div style={{ fontSize: 9, color: T.faint, marginTop: 4 }}>Claim deals from ad cards to see them here</div>
            </div>
          ) : claimedCoupons.map((c, i) => (
            <div key={i} style={{ padding: '10px 12px', background: T.surface, border: `1px solid ${T.green}33`, borderRadius: 10 }}>
              <div style={{ fontSize: 11, fontWeight: 700, color: T.text }}>{c.businessName}</div>
              <div style={{ fontSize: 10, color: T.muted, marginBottom: 6 }}>{c.offer}</div>
              {c.code && (
                <div style={{
                  display: 'inline-block', padding: '3px 10px',
                  background: `${T.green}18`, border: `1px solid ${T.green}44`,
                  borderRadius: 99, fontFamily: 'JetBrains Mono, monospace',
                  fontSize: 10, fontWeight: 700, color: T.green,
                }}>{c.code}</div>
              )}
              <div style={{ fontSize: 8, color: T.faint, marginTop: 4 }}>
                📲 Show QR at counter — staff scans to redeem
              </div>
            </div>
          ))}
        </div>
      )}

      {/* ── Loyalty cards ── */}
      {activeSection === 'cards' && (
        <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
          {joinedClubs.length === 0 ? (
            <div style={{ textAlign: 'center', padding: '30px 0', color: T.muted }}>
              <div style={{ fontSize: 28, marginBottom: 8 }}>🪪</div>
              <div style={{ fontSize: 11 }}>No loyalty cards yet</div>
              <div style={{ fontSize: 9, color: T.faint, marginTop: 4 }}>Join business clubs to earn stamps and perks</div>
            </div>
          ) : joinedClubs.map((c, i) => (
            <div key={i} style={{
              padding: '12px 14px',
              background: `linear-gradient(135deg, ${T.purple}22, ${T.surface2})`,
              border: `1px solid ${T.purple}44`, borderRadius: 12,
            }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 8 }}>
                <span style={{ fontSize: 22 }}>{c.emoji}</span>
                <div>
                  <div style={{ fontSize: 12, fontWeight: 700, color: T.text }}>{c.cardName}</div>
                  <div style={{ fontSize: 9, color: T.muted }}>{c.businessName} · Member</div>
                </div>
                <span style={{ marginLeft: 'auto', fontSize: 16 }}>⭐</span>
              </div>
              <div style={{ fontSize: 9, color: T.faint }}>
                📲 Show QR at {c.businessName} to earn stamps & perks
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
