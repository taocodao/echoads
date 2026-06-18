'use client';
/**
 * LocalAdCard.tsx — Hyperlocal Business Ad Card (Restaurant Template)
 * Implements the Dual-Screen Build Plan Section 3.1 card design.
 * Three CTAs: Coupon Claim | Join Club | Order Now
 */
import { useState } from 'react';
import type { BusinessListing } from '../lib/sharedTypes';

const T = {
  bg: '#0d0f14', surface: '#141720', surface2: '#1a1e2a',
  border: 'rgba(255,255,255,0.08)', text: '#f0f2ff', muted: '#8892b0',
  faint: '#4a5568', green: '#22c55e', orange: '#ff6b35',
};

interface LocalAdCardProps {
  business: BusinessListing;
  onCouponClaim: (b: BusinessListing) => void;
  onJoinClub: (b: BusinessListing) => void;
  expanded?: boolean;
  onExpand?: () => void;
}

function StarRating({ rating }: { rating: number }) {
  const full = Math.floor(rating);
  const half = rating % 1 >= 0.5;
  return (
    <span style={{ fontSize: 10, color: '#fbbf24', letterSpacing: '0.05em' }}>
      {'★'.repeat(full)}{half ? '½' : ''}{'☆'.repeat(5 - full - (half ? 1 : 0))}
      <span style={{ color: T.muted, marginLeft: 4 }}>{rating}</span>
    </span>
  );
}

function CountdownBadge({ expiresAt }: { expiresAt: string }) {
  const ms = new Date(expiresAt).getTime() - Date.now();
  const h = Math.floor(ms / 3600000);
  const m = Math.floor((ms % 3600000) / 60000);
  return (
    <span style={{ fontSize: 9, color: '#fbbf24', fontWeight: 700 }}>
      ⏱ Expires in {h}h {m}m
    </span>
  );
}

export function LocalAdCard({ business: b, onCouponClaim, onJoinClub, expanded, onExpand }: LocalAdCardProps) {
  const [couponClaimed, setCouponClaimed] = useState(false);
  const [clubJoined, setClubJoined] = useState(false);

  const handleCoupon = (e: React.MouseEvent) => {
    e.stopPropagation();
    setCouponClaimed(true);
    onCouponClaim(b);
  };

  const handleJoin = (e: React.MouseEvent) => {
    e.stopPropagation();
    setClubJoined(true);
    onJoinClub(b);
  };

  return (
    <div
      onClick={onExpand}
      style={{
        background: T.surface,
        border: `1px solid ${b.primaryColor}33`,
        borderRadius: 14,
        overflow: 'hidden',
        cursor: onExpand ? 'pointer' : 'default',
        transition: 'transform 0.15s, border-color 0.15s',
        boxShadow: `0 2px 16px ${b.primaryColor}11`,
      }}
    >
      {/* ── Header bar ── */}
      <div style={{
        padding: '10px 12px 8px',
        background: `linear-gradient(135deg, ${b.primaryColor}22, ${T.surface2})`,
        borderBottom: `1px solid ${T.border}`,
        display: 'flex', alignItems: 'center', gap: 10,
      }}>
        <span style={{ fontSize: 28, lineHeight: 1 }}>{b.emoji}</span>
        <div style={{ flex: 1 }}>
          <div style={{ fontSize: 13, fontWeight: 800, color: T.text }}>{b.name}</div>
          <StarRating rating={b.rating} />
          <span style={{ fontSize: 9, color: T.muted, marginLeft: 4 }}>
            ({b.reviewCount} reviews)
          </span>
        </div>
        <div style={{ textAlign: 'right' }}>
          <div style={{ fontSize: 10, fontWeight: 700, color: b.primaryColor }}>
            {b.distanceMiles != null ? `${b.distanceMiles} mi` : ''}
          </div>
          <div style={{ fontSize: 9, color: T.muted }}>{b.city}</div>
        </div>
      </div>

      {/* ── Offer strip ── */}
      {b.activeOffer && (
        <div style={{ padding: '8px 12px', borderBottom: `1px solid ${T.border}` }}>
          <div style={{ fontSize: 11, fontWeight: 700, color: T.text, marginBottom: 3 }}>
            🎯 {b.activeOffer.headline}
          </div>
          {b.activeOffer.expiresAt && <CountdownBadge expiresAt={b.activeOffer.expiresAt} />}
        </div>
      )}

      {/* ── Three CTAs ── */}
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: 6, padding: '8px 10px 10px' }}>
        {/* Coupon */}
        {b.activeOffer && (
          <button
            onClick={handleCoupon}
            style={{
              padding: '7px 4px', borderRadius: 8, fontSize: 9, fontWeight: 700,
              border: `1px solid ${couponClaimed ? T.green : b.primaryColor}55`,
              background: couponClaimed ? `${T.green}18` : `${b.primaryColor}18`,
              color: couponClaimed ? T.green : b.primaryColor,
              cursor: 'pointer', transition: 'all 0.2s',
              display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 2,
            }}
          >
            <span style={{ fontSize: 14 }}>{couponClaimed ? '✅' : '🎟'}</span>
            {couponClaimed ? 'Claimed!' : 'COUPON'}
          </button>
        )}

        {/* Join Club */}
        {b.membership?.enabled && (
          <button
            onClick={handleJoin}
            style={{
              padding: '7px 4px', borderRadius: 8, fontSize: 9, fontWeight: 700,
              border: `1px solid ${clubJoined ? T.green : '#7c3aed'}55`,
              background: clubJoined ? `${T.green}18` : '#7c3aed18',
              color: clubJoined ? T.green : '#7c3aed',
              cursor: 'pointer', transition: 'all 0.2s',
              display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 2,
            }}
          >
            <span style={{ fontSize: 14 }}>{clubJoined ? '⭐' : '🪪'}</span>
            {clubJoined ? 'Joined!' : 'JOIN CLUB'}
          </button>
        )}

        {/* Order */}
        {b.orderEnabled && (
          <a
            href={b.orderUrl ?? '#'}
            target="_blank"
            rel="noopener noreferrer"
            onClick={e => e.stopPropagation()}
            style={{
              padding: '7px 4px', borderRadius: 8, fontSize: 9, fontWeight: 700,
              border: '1px solid #22c55e55', background: '#22c55e18',
              color: T.green, cursor: 'pointer', textDecoration: 'none',
              display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 2,
              transition: 'all 0.2s',
            }}
          >
            <span style={{ fontSize: 14 }}>🛒</span>
            ORDER NOW
          </a>
        )}
      </div>

      {/* ── Membership perks (expanded) ── */}
      {expanded && b.membership?.enabled && (
        <div style={{ padding: '8px 12px 10px', borderTop: `1px solid ${T.border}` }}>
          <div style={{ fontSize: 9, color: T.muted, textTransform: 'uppercase', letterSpacing: '0.06em', marginBottom: 6 }}>
            {b.membership.cardName} Perks
          </div>
          {b.membership.perks.map((p, i) => (
            <div key={i} style={{ fontSize: 10, color: T.text, marginBottom: 2 }}>
              ✓ {p}
            </div>
          ))}
          {b.membership.stampsRequired && (
            <div style={{ fontSize: 9, color: T.muted, marginTop: 4 }}>
              🎯 {b.membership.reward} (after {b.membership.stampsRequired} visits)
            </div>
          )}
        </div>
      )}

      {/* ── Arenza Points badge ── */}
      {b.arenzaPointsAccepted && (
        <div style={{
          padding: '4px 12px', background: `${T.orange}11`,
          borderTop: `1px solid ${T.orange}22`,
          fontSize: 9, color: T.orange, fontWeight: 600,
        }}>
          🏆 Arenza Points accepted here
        </div>
      )}
    </div>
  );
}
