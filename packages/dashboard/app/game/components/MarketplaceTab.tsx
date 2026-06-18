'use client';
/**
 * MarketplaceTab.tsx — Local business discovery (Dual-Screen Plan Sec 7)
 * Shows sortable/filterable business cards.
 */
import { useState } from 'react';
import type { BusinessListing, BusinessCategory } from '../lib/sharedTypes';
import { DEMO_BUSINESSES } from '../lib/businessData';
import { LocalAdCard } from './LocalAdCard';

const T = {
  surface: '#141720', surface2: '#1a1e2a',
  border: 'rgba(255,255,255,0.08)', text: '#f0f2ff', muted: '#8892b0',
  faint: '#4a5568', orange: '#ff6b35', green: '#22c55e',
};

const CATEGORIES: { key: BusinessCategory | 'all'; label: string; emoji: string }[] = [
  { key: 'all',        label: 'All',        emoji: '🏙' },
  { key: 'pizza',      label: 'Pizza',      emoji: '🍕' },
  { key: 'sports_bar', label: 'Sports Bar', emoji: '🍺' },
  { key: 'diner',      label: 'Diner',      emoji: '🍳' },
  { key: 'coffee',     label: 'Coffee',     emoji: '☕' },
  { key: 'seafood',    label: 'Seafood',    emoji: '🦞' },
  { key: 'gym',        label: 'Gym',        emoji: '💪' },
];

interface MarketplaceTabProps {
  onCouponClaim: (b: BusinessListing) => void;
  onJoinClub: (b: BusinessListing) => void;
}

export function MarketplaceTab({ onCouponClaim, onJoinClub }: MarketplaceTabProps) {
  const [categoryFilter, setCategoryFilter] = useState<BusinessCategory | 'all'>('all');
  const [sort, setSort] = useState<'distance' | 'rating' | 'offers'>('distance');
  const [expandedId, setExpandedId] = useState<string | null>(null);

  const filtered = DEMO_BUSINESSES
    .filter(b => categoryFilter === 'all' || b.category === categoryFilter)
    .sort((a, b) => {
      if (sort === 'distance') return (a.distanceMiles ?? 99) - (b.distanceMiles ?? 99);
      if (sort === 'rating')   return b.rating - a.rating;
      // offers: businesses with active offers first
      return (b.activeOffer ? 1 : 0) - (a.activeOffer ? 1 : 0);
    });

  return (
    <div style={{ height: '100%', overflowY: 'auto', display: 'flex', flexDirection: 'column', gap: 10 }}>

      {/* Header */}
      <div style={{ fontSize: 11, fontWeight: 700, color: T.orange, textTransform: 'uppercase', letterSpacing: '.08em' }}>
        📍 Nearby · Atlantic Beach, NY
      </div>

      {/* Category filter pills */}
      <div style={{ display: 'flex', gap: 5, overflowX: 'auto', paddingBottom: 2, scrollbarWidth: 'none' }}>
        {CATEGORIES.map(c => (
          <button key={c.key} onClick={() => setCategoryFilter(c.key)} style={{
            padding: '4px 10px', borderRadius: 99, fontSize: 9, fontWeight: 700, whiteSpace: 'nowrap',
            border: `1px solid ${categoryFilter === c.key ? T.orange : T.border}`,
            background: categoryFilter === c.key ? `${T.orange}22` : 'transparent',
            color: categoryFilter === c.key ? T.orange : T.muted,
            cursor: 'pointer', flexShrink: 0,
          }}>
            {c.emoji} {c.label}
          </button>
        ))}
      </div>

      {/* Sort controls */}
      <div style={{ display: 'flex', gap: 4, alignItems: 'center' }}>
        <span style={{ fontSize: 9, color: T.muted, marginRight: 4 }}>Sort:</span>
        {(['distance', 'rating', 'offers'] as const).map(s => (
          <button key={s} onClick={() => setSort(s)} style={{
            padding: '3px 8px', borderRadius: 99, fontSize: 9, fontWeight: 600,
            border: `1px solid ${sort === s ? T.green : T.border}`,
            background: sort === s ? `${T.green}18` : 'transparent',
            color: sort === s ? T.green : T.muted, cursor: 'pointer',
          }}>
            {s === 'distance' ? '📍 Nearest' : s === 'rating' ? '⭐ Rating' : '🎯 Offers'}
          </button>
        ))}
      </div>

      {/* Result count */}
      <div style={{ fontSize: 9, color: T.faint }}>
        {filtered.length} businesses nearby
      </div>

      {/* Business list */}
      <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
        {filtered.map(b => (
          <LocalAdCard
            key={b.id}
            business={b}
            onCouponClaim={onCouponClaim}
            onJoinClub={onJoinClub}
            expanded={expandedId === b.id}
            onExpand={() => setExpandedId(expandedId === b.id ? null : b.id)}
          />
        ))}
      </div>
    </div>
  );
}
