'use client';
import { useEffect, useRef } from 'react';
import type { ViewerProfile } from '../lib/useProfileEngine';

interface Props {
  profile: ViewerProfile;
  hidden?: boolean; // hide during ad break (so it doesn't clash with AD badge)
}

export function AudienceTierBadge({ profile, hidden }: Props) {
  const prevTier = useRef(profile.tier);
  const badgeRef = useRef<HTMLDivElement>(null);

  // Flash the badge when the tier changes
  useEffect(() => {
    if (prevTier.current !== profile.tier && badgeRef.current) {
      badgeRef.current.animate(
        [
          { boxShadow: `0 0 0 0 ${profile.tierMeta.color}`, transform: 'scale(1)' },
          { boxShadow: `0 0 14px 4px ${profile.tierMeta.color}88`, transform: 'scale(1.08)' },
          { boxShadow: `0 0 0 0 ${profile.tierMeta.color}`, transform: 'scale(1)' },
        ],
        { duration: 700, easing: 'ease-out' }
      );
      prevTier.current = profile.tier;
    }
  }, [profile.tier, profile.tierMeta.color]);

  if (hidden) return null;

  return (
    <div
      ref={badgeRef}
      title={`${profile.tierMeta.description} · Engagement: ${profile.engagementScore}/100`}
      style={{
        position: 'absolute',
        top: 10, left: 10,
        zIndex: 32,
        display: 'flex',
        alignItems: 'center',
        gap: 5,
        background: 'rgba(0,0,0,0.65)',
        backdropFilter: 'blur(8px)',
        border: `1px solid ${profile.tierMeta.color}55`,
        borderRadius: 6,
        padding: '3px 8px',
        cursor: 'default',
        pointerEvents: 'all',
      }}
    >
      {/* Tier pill */}
      <div style={{
        background: profile.tierMeta.color,
        color: '#fff',
        fontSize: 8,
        fontWeight: 900,
        padding: '1px 5px',
        borderRadius: 4,
        letterSpacing: '0.05em',
      }}>
        {profile.tier}
      </div>
      {/* Label + CPM */}
      <div style={{ display: 'flex', flexDirection: 'column', lineHeight: 1.1 }}>
        <span style={{ fontSize: 8, fontWeight: 700, color: 'rgba(255,255,255,0.9)', letterSpacing: '0.04em' }}>
          {profile.tierMeta.label}
        </span>
        <span style={{ fontSize: 7, color: profile.tierMeta.color, fontWeight: 600 }}>
          ~${profile.currentCPM} CPM
        </span>
      </div>
      {/* Engagement bar */}
      <div style={{ width: 28, height: 3, background: 'rgba(255,255,255,0.1)', borderRadius: 2, overflow: 'hidden' }}>
        <div style={{
          height: '100%',
          width: `${profile.engagementScore}%`,
          background: profile.tierMeta.color,
          borderRadius: 2,
          transition: 'width 0.6s ease',
        }} />
      </div>
    </div>
  );
}
