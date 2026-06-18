'use client';
/**
 * LeaderboardTab.tsx — Arenza Points leaderboard
 * Dual-Screen Build Plan Section 6.4 — Weekly, Neighborhood, Friends
 */
import { useState } from 'react';

const T = {
  bg: '#0d0f14', surface: '#141720', surface2: '#1a1e2a',
  border: 'rgba(255,255,255,0.08)', text: '#f0f2ff', muted: '#8892b0',
  faint: '#4a5568', orange: '#ff6b35', gold: '#ffc107', green: '#22c55e',
  teal: '#00c9b1',
};

interface LeaderboardEntry {
  rank: number;
  username: string;
  avatar: string;
  points: number;
  tier: string;
  isMe?: boolean;
}

// Fictional demo leaderboard data
const WEEKLY_BOARD: LeaderboardEntry[] = [
  { rank: 1, username: 'EaglesFan23',   avatar: '🦅', points: 4850, tier: 'T1' },
  { rank: 2, username: 'SportsBetKing', avatar: '🎯', points: 4120, tier: 'T1' },
  { rank: 3, username: 'NFLNerd42',     avatar: '🏈', points: 3670, tier: 'T2' },
  { rank: 4, username: 'ChiTownBear',   avatar: '🐻', points: 3240, tier: 'T2' },
  { rank: 5, username: 'You',           avatar: '👤', points: 0,    tier: 'T12', isMe: true },
  { rank: 6, username: 'GridironGuru',  avatar: '🏟', points: 2810, tier: 'T3' },
  { rank: 7, username: 'TDKing99',      avatar: '⚡', points: 2440, tier: 'T3' },
  { rank: 8, username: 'LongBeachFan',  avatar: '🌊', points: 2100, tier: 'T4' },
  { rank: 9, username: 'AtlanticMike',  avatar: '🎽', points: 1890, tier: 'T4' },
  { rank: 10, username: 'SundayFanatic',avatar: '📺', points: 1650, tier: 'T5' },
];

const NEIGHBORHOOD_BOARD: LeaderboardEntry[] = [
  { rank: 1, username: 'AtlanticMike',  avatar: '🎽', points: 1890, tier: 'T4' },
  { rank: 2, username: 'LongBeachFan',  avatar: '🌊', points: 2100, tier: 'T4' },
  { rank: 3, username: 'You',           avatar: '👤', points: 0,    tier: 'T12', isMe: true },
  { rank: 4, username: 'BeachBettor',   avatar: '🏖', points: 980,  tier: 'T5' },
  { rank: 5, username: 'ShoreFan11',    avatar: '🦀', points: 750,  tier: 'T6' },
];

const MEDALS = ['🥇', '🥈', '🥉'];

interface LeaderboardTabProps {
  userPoints: number;
}

export function LeaderboardTab({ userPoints }: LeaderboardTabProps) {
  const [view, setView] = useState<'weekly' | 'neighborhood'>('weekly');

  // Inject real user points into the leaderboard
  const board = (view === 'weekly' ? WEEKLY_BOARD : NEIGHBORHOOD_BOARD).map(e =>
    e.isMe ? { ...e, points: userPoints } : e
  ).sort((a, b) => b.points - a.points).map((e, i) => ({ ...e, rank: i + 1 }));

  return (
    <div style={{ height: '100%', overflowY: 'auto', display: 'flex', flexDirection: 'column', gap: 10 }}>

      {/* Header */}
      <div style={{ fontSize: 11, fontWeight: 700, color: T.orange, textTransform: 'uppercase', letterSpacing: '.08em' }}>
        🏆 Leaderboard
      </div>

      {/* Toggle */}
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 4 }}>
        {(['weekly', 'neighborhood'] as const).map(v => (
          <button key={v} onClick={() => setView(v)} style={{
            padding: '6px 0', borderRadius: 8, fontSize: 10, fontWeight: 700,
            border: `1px solid ${view === v ? T.orange : T.border}`,
            background: view === v ? `${T.orange}18` : 'transparent',
            color: view === v ? T.orange : T.muted,
            cursor: 'pointer',
          }}>
            {v === 'weekly' ? '📅 This Week' : '📍 Neighborhood'}
          </button>
        ))}
      </div>

      {/* Top 3 podium */}
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1.2fr 1fr', gap: 6, alignItems: 'flex-end', margin: '4px 0' }}>
        {[board[1], board[0], board[2]].map((e, col) => e && (
          <div key={e.rank} style={{
            textAlign: 'center', padding: col === 1 ? '14px 8px' : '10px 8px',
            background: col === 1 ? `${T.gold}18` : T.surface,
            border: `1px solid ${col === 1 ? T.gold : T.border}44`,
            borderRadius: 12,
          }}>
            <div style={{ fontSize: col === 1 ? 26 : 20 }}>{e.avatar}</div>
            <div style={{ fontSize: 14 }}>{MEDALS[col === 0 ? 1 : col === 1 ? 0 : 2]}</div>
            <div style={{ fontSize: 9, fontWeight: 700, color: e.isMe ? T.teal : T.text, marginTop: 4 }}>
              {e.isMe ? 'YOU' : e.username}
            </div>
            <div style={{ fontSize: 11, fontWeight: 800, color: T.gold }}>
              {e.points.toLocaleString()}
            </div>
          </div>
        ))}
      </div>

      {/* Full ranking list */}
      <div style={{ display: 'flex', flexDirection: 'column', gap: 4 }}>
        {board.map(e => (
          <div key={e.rank} style={{
            padding: '8px 12px',
            background: e.isMe ? `${T.teal}11` : T.surface,
            border: `1px solid ${e.isMe ? T.teal : T.border}${e.isMe ? '44' : ''}`,
            borderRadius: 10,
            display: 'flex', alignItems: 'center', gap: 10,
          }}>
            <div style={{
              width: 24, textAlign: 'center', fontSize: e.rank <= 3 ? 16 : 11,
              fontWeight: 800, color: e.rank <= 3 ? T.gold : T.muted,
            }}>
              {e.rank <= 3 ? MEDALS[e.rank - 1] : e.rank}
            </div>
            <span style={{ fontSize: 18 }}>{e.avatar}</span>
            <div style={{ flex: 1 }}>
              <div style={{ fontSize: 11, fontWeight: e.isMe ? 800 : 600, color: e.isMe ? T.teal : T.text }}>
                {e.isMe ? '👤 You' : e.username}
              </div>
              <div style={{ fontSize: 8, color: T.faint }}>{e.tier}</div>
            </div>
            <div style={{ fontFamily: 'JetBrains Mono, monospace', fontSize: 12, fontWeight: 800, color: e.isMe ? T.teal : T.gold }}>
              {e.points.toLocaleString()}
            </div>
          </div>
        ))}
      </div>

      {/* Earn more CTA */}
      <div style={{
        padding: '10px 14px', background: `${T.orange}11`,
        border: `1px solid ${T.orange}33`, borderRadius: 10, textAlign: 'center',
      }}>
        <div style={{ fontSize: 10, fontWeight: 700, color: T.orange, marginBottom: 4 }}>
          Earn More Points
        </div>
        <div style={{ fontSize: 9, color: T.muted }}>
          🎯 Correct Pick +100 · 🎲 Bingo Line +150 · 📺 Ad Watch +10 · 🏪 First Visit +200
        </div>
      </div>
    </div>
  );
}
