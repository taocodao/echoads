'use client';
/**
 * MemberQRCard.tsx — Member's QR identity card
 * Shown in Wallet tab and Me tab. Auto-refreshes token every 5 min.
 * Business staff scan this QR to identify the member.
 */

import { useState, useEffect, useCallback } from 'react';
import { generateToken, getOrCreateUserId } from '../lib/qrToken';
import { getMember, getOrCreateMembership, BUSINESS_CATALOG } from '../lib/memberStore';

const T = {
  bg: '#0d0f14', surface: '#141720', surface2: '#1a1e2a',
  border: 'rgba(255,255,255,0.08)',
  text: '#f0f2ff', muted: '#8892b0', faint: '#4a5568',
  orange: '#ff6b35', teal: '#00c9b1', gold: '#ffc107',
  green: '#22c55e', purple: '#7c3aed',
};

const TIER_COLOR: Record<string, string> = {
  'Guest': T.muted, 'Regular': T.teal, 'VIP': T.gold, 'Founding Member': T.orange,
};

interface Props {
  selectedBusinessId?: string;
  points?: number;
}

export function MemberQRCard({ selectedBusinessId = 'ALL', points = 0 }: Props) {
  const [userId, setUserId] = useState('');
  const [token, setToken] = useState('');
  const [timeLeft, setTimeLeft] = useState(300); // 5 min in seconds
  const [activeBiz, setActiveBiz] = useState(selectedBusinessId);
  const [membership, setMembership] = useState<ReturnType<typeof getOrCreateMembership> | null>(null);

  // QR image URL (uses qrserver.com — no npm package needed)
  const qrUrl = token
    ? `https://api.qrserver.com/v1/create-qr-code/?size=180x180&margin=10&color=f0f2ff&bgcolor=141720&data=${encodeURIComponent(token)}`
    : '';

  const refreshToken = useCallback(() => {
    const uid = getOrCreateUserId();
    setUserId(uid);
    setToken(generateToken(uid, activeBiz));
    setTimeLeft(300);
  }, [activeBiz]);

  // Init + auto-refresh every 5 min
  useEffect(() => {
    refreshToken();
    const interval = setInterval(refreshToken, 5 * 60 * 1000);
    return () => clearInterval(interval);
  }, [refreshToken]);

  // Countdown timer
  useEffect(() => {
    const tick = setInterval(() => setTimeLeft(t => Math.max(0, t - 1)), 1000);
    return () => clearInterval(tick);
  }, []);

  // Load membership data for selected business
  useEffect(() => {
    if (userId && activeBiz !== 'ALL') {
      setMembership(getOrCreateMembership(userId, activeBiz));
    } else {
      setMembership(null);
    }
  }, [userId, activeBiz]);

  const member = userId ? getMember(userId) : null;
  const totalPoints = membership?.pointsBalance ?? points;
  const tier = membership?.memberTier ?? 'Guest';
  const stamps = membership?.stamps ?? 0;
  const stampsRequired = membership?.stampsRequired ?? 9;
  const activeCoupons = membership?.activeCoupons.filter(c => !c.redeemed && Date.now() < c.expiresAt) ?? [];

  const bizList = Object.entries(BUSINESS_CATALOG);
  const bizInfo = activeBiz !== 'ALL' ? BUSINESS_CATALOG[activeBiz] : null;

  const mins = Math.floor(timeLeft / 60);
  const secs = (timeLeft % 60).toString().padStart(2, '0');

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>

      {/* Business selector */}
      <div>
        <div style={{ fontSize: 10, color: T.muted, textTransform: 'uppercase', letterSpacing: '0.08em', marginBottom: 6 }}>
          Show Card For
        </div>
        <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap' }}>
          <button
            onClick={() => setActiveBiz('ALL')}
            style={{
              padding: '4px 10px', borderRadius: 8, border: `1px solid ${activeBiz === 'ALL' ? T.orange : T.border}`,
              background: activeBiz === 'ALL' ? `${T.orange}22` : T.surface2,
              color: activeBiz === 'ALL' ? T.orange : T.muted,
              fontSize: 10, fontWeight: 700, cursor: 'pointer',
            }}
          >🌐 Universal</button>
          {bizList.map(([id, biz]) => (
            <button
              key={id}
              onClick={() => setActiveBiz(id)}
              style={{
                padding: '4px 10px', borderRadius: 8,
                border: `1px solid ${activeBiz === id ? T.teal : T.border}`,
                background: activeBiz === id ? `${T.teal}22` : T.surface2,
                color: activeBiz === id ? T.teal : T.muted,
                fontSize: 10, fontWeight: 700, cursor: 'pointer',
              }}
            >{biz.emoji} {biz.name.split(' ')[0]}</button>
          ))}
        </div>
      </div>

      {/* QR Card */}
      <div style={{
        background: `linear-gradient(145deg, ${T.surface} 0%, ${T.surface2} 100%)`,
        border: `1px solid ${T.border}`,
        borderRadius: 20, overflow: 'hidden',
      }}>
        {/* Card header */}
        <div style={{
          background: `linear-gradient(135deg, ${T.orange}22, ${T.gold}11)`,
          borderBottom: `1px solid ${T.border}`,
          padding: '12px 16px',
          display: 'flex', alignItems: 'center', gap: 12,
        }}>
          <div style={{ fontSize: 28 }}>{bizInfo?.emoji ?? '📺'}</div>
          <div style={{ flex: 1 }}>
            <div style={{ fontSize: 14, fontWeight: 900, color: T.text }}>
              {bizInfo?.name ?? 'Arenza Universal Card'}
            </div>
            <div style={{ fontSize: 10, color: T.muted }}>
              {member?.displayName ?? 'Loading...'} · ID: {userId}
            </div>
          </div>
          <div style={{
            padding: '3px 8px', borderRadius: 8,
            background: `${TIER_COLOR[tier]}22`,
            border: `1px solid ${TIER_COLOR[tier]}44`,
            fontSize: 9, fontWeight: 800, color: TIER_COLOR[tier],
          }}>
            {tier}
          </div>
        </div>

        {/* QR Code */}
        <div style={{ padding: '16px', display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 10 }}>
          <div style={{
            background: T.surface2, borderRadius: 16, padding: 8,
            border: `2px solid ${T.orange}44`,
            boxShadow: `0 0 24px ${T.orange}22`,
          }}>
            {qrUrl ? (
              <img
                src={qrUrl}
                alt="Member QR Code"
                width={180}
                height={180}
                style={{ display: 'block', borderRadius: 8 }}
              />
            ) : (
              <div style={{
                width: 180, height: 180, display: 'flex', alignItems: 'center',
                justifyContent: 'center', color: T.faint, fontSize: 12,
              }}>Loading QR…</div>
            )}
          </div>

          {/* Token display */}
          <div style={{
            fontFamily: 'JetBrains Mono, monospace', fontSize: 9,
            color: T.faint, letterSpacing: '0.04em', textAlign: 'center',
          }}>
            {token.slice(0, 32)}...
          </div>

          {/* Refresh timer */}
          <div style={{
            display: 'flex', alignItems: 'center', gap: 6,
            fontSize: 10, color: timeLeft < 60 ? T.orange : T.muted,
          }}>
            <span style={{
              width: 6, height: 6, borderRadius: '50%',
              background: timeLeft < 60 ? T.orange : T.green,
              animation: 'pulse 1.5s infinite',
              display: 'inline-block',
            }} />
            Refreshes in {mins}:{secs}
            <button
              onClick={refreshToken}
              style={{
                marginLeft: 4, background: 'none', border: `1px solid ${T.border}`,
                borderRadius: 6, padding: '2px 6px', color: T.muted,
                fontSize: 9, cursor: 'pointer',
              }}
            >↻ Now</button>
          </div>
        </div>

        {/* Stats bar */}
        <div style={{
          display: 'grid', gridTemplateColumns: '1fr 1fr 1fr',
          borderTop: `1px solid ${T.border}`,
        }}>
          {[
            { label: 'Points', value: totalPoints, emoji: '🏆' },
            { label: 'Stamps', value: `${stamps}/${stampsRequired}`, emoji: '⭐' },
            { label: 'Coupons', value: activeCoupons.length, emoji: '🎟' },
          ].map((s, i) => (
            <div key={i} style={{
              padding: '10px 8px', textAlign: 'center',
              borderRight: i < 2 ? `1px solid ${T.border}` : 'none',
            }}>
              <div style={{ fontSize: 14 }}>{s.emoji}</div>
              <div style={{ fontSize: 16, fontWeight: 900, color: T.text, fontFamily: 'Bebas Neue, sans-serif' }}>
                {s.value}
              </div>
              <div style={{ fontSize: 8, color: T.faint }}>{s.label}</div>
            </div>
          ))}
        </div>

        {/* Stamp progress bar */}
        {activeBiz !== 'ALL' && (
          <div style={{ padding: '10px 16px 14px', borderTop: `1px solid ${T.border}` }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: 9, color: T.muted, marginBottom: 6 }}>
              <span>Loyalty Stamps</span>
              <span>{stamps} / {stampsRequired} — {stampsRequired - stamps} more to free reward</span>
            </div>
            <div style={{ display: 'flex', gap: 4, flexWrap: 'wrap' }}>
              {Array.from({ length: stampsRequired }).map((_, i) => (
                <div key={i} style={{
                  width: 20, height: 20, borderRadius: 6,
                  background: i < stamps ? `linear-gradient(135deg, ${T.orange}, ${T.gold})` : T.surface2,
                  border: `1px solid ${i < stamps ? T.orange : T.border}`,
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                  fontSize: 11, transition: 'all 0.2s',
                }}>
                  {i < stamps ? '⭐' : ''}
                </div>
              ))}
            </div>
          </div>
        )}

        {/* Active coupons preview */}
        {activeCoupons.length > 0 && (
          <div style={{ borderTop: `1px solid ${T.border}`, padding: '10px 16px' }}>
            <div style={{ fontSize: 9, color: T.muted, marginBottom: 6, textTransform: 'uppercase', letterSpacing: '0.08em' }}>
              Active Coupons ({activeCoupons.length})
            </div>
            {activeCoupons.slice(0, 2).map(c => (
              <div key={c.id} style={{
                display: 'flex', alignItems: 'center', gap: 8,
                padding: '6px 8px', background: `${T.green}11`,
                border: `1px solid ${T.green}33`, borderRadius: 8, marginBottom: 4,
              }}>
                <span style={{ fontSize: 12 }}>🎟</span>
                <div style={{ flex: 1 }}>
                  <div style={{ fontSize: 11, fontWeight: 700, color: T.text }}>{c.offer}</div>
                  <div style={{ fontSize: 9, color: T.muted }}>{c.value}</div>
                </div>
                <div style={{ fontSize: 8, color: T.green }}>VALID</div>
              </div>
            ))}
          </div>
        )}

        {/* Show at counter instruction */}
        <div style={{
          background: `${T.orange}11`, borderTop: `1px solid ${T.orange}22`,
          padding: '8px 16px', textAlign: 'center',
          fontSize: 10, color: T.orange, fontWeight: 700,
        }}>
          📲 Show this QR code to staff at the counter
        </div>
      </div>
    </div>
  );
}
