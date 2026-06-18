'use client';

import { useState } from 'react';

const T = {
  surface: 'rgba(20,26,40,0.9)',
  border: 'rgba(255,255,255,0.08)',
  text: '#e2e8f0',
  muted: '#8892b0',
  faint: '#4a5568',
  orange: '#ff6b35',
  teal: '#00c9b1',
};

interface GuideStep {
  id: string;
  icon: string;
  title: string;
  desc: string;
  details: string;
  color: string;
  zone: 'video' | 'tabs' | 'general';
}

const GUIDE_STEPS: GuideStep[] = [
  {
    id: 'overview', icon: '📱', title: 'Split-Screen Layout',
    desc: 'Live video on top, interactive panel on bottom.',
    details: 'The app uses a dual-zone architecture. The top 45% is a live, uninterrupted sports broadcast. The bottom 55% is your interactive engagement zone where you earn points, play games, and redeem rewards — all without pausing the action.',
    color: '#3b82f6', zone: 'general',
  },
  {
    id: 'predict', icon: '🎯', title: 'Predict',
    desc: 'Make real-time predictions on live game events.',
    details: 'Contextual prediction cards appear based on what\'s happening in the game. Pick the correct outcome before the timer runs out to earn bonus points. Predictions are sponsored by local businesses, connecting the game to the local economy.',
    color: T.orange, zone: 'tabs',
  },
  {
    id: 'bingo', icon: '🎲', title: 'Bingo',
    desc: 'Play sports bingo as events unfold live.',
    details: 'A 5×5 bingo board is populated with possible game events — "Touchdown pass", "Penalty called", "Field goal attempt". Cells auto-mark when events occur on screen, and you can manually mark cells too. Complete a line to earn 500 bonus points!',
    color: '#f59e0b', zone: 'tabs',
  },
  {
    id: 'scratch', icon: '🎟', title: 'Scratch Cards',
    desc: 'Scratch to reveal prizes and coupon codes.',
    details: 'Sponsored scratch cards let you reveal hidden prizes from local advertisers — discount codes, free items, or bonus points. Each card has a different win rate and prize tier. Winners get coupon codes saved directly to their Wallet.',
    color: '#10b981', zone: 'tabs',
  },
  {
    id: 'moreless', icon: '📊', title: 'More or Less',
    desc: 'Predict player stat lines for multiplied rewards.',
    details: 'Pick whether key players will go OVER or UNDER their projected stat lines. The more picks you lock in, the higher your multiplier — up to 6× the base reward. Submit your picks before game time to see how you score.',
    color: '#8b5cf6', zone: 'tabs',
  },
  {
    id: 'market', icon: '📍', title: 'Local Marketplace',
    desc: 'Discover deals from nearby businesses.',
    details: 'Geo-targeted offers from restaurants, bars, and shops within a 5-mile radius. Browse menus, claim exclusive coupons, and join loyalty clubs. Each business listing includes active offers and one-tap coupon claiming.',
    color: '#06b6d4', zone: 'tabs',
  },
  {
    id: 'wallet', icon: '💳', title: 'Wallet',
    desc: 'Store earned rewards, coupons & loyalty cards.',
    details: 'Your personal vault for everything you\'ve earned. Claimed coupons show with their offer details and promo codes. Loyalty club memberships are tracked here. Rewards can be exported to Apple Wallet as dynamic PassKit passes for POS redemption.',
    color: T.teal, zone: 'tabs',
  },
  {
    id: 'board', icon: '🏆', title: 'Leaderboard',
    desc: 'Compete against other fans for the top spot.',
    details: 'Real-time leaderboard ranks all viewers by points earned during the session. Climb the ranks through predictions, bingo lines, scratch wins, and ad engagement. Top performers earn bonus multipliers and exclusive rewards.',
    color: '#fbbf24', zone: 'tabs',
  },
  {
    id: 'me', icon: '👤', title: 'Profile & AI Segments',
    desc: 'Your AI-powered fan profile and engagement tier.',
    details: 'The on-device ProfileEngine (CoreML) analyzes your watch patterns, team preferences, and interaction history to build a privacy-first profile. Your audience tier (Casual → Superfan) unlocks progressively better ad rates and rewards.',
    color: '#a855f7', zone: 'tabs',
  },
  {
    id: 'ads', icon: '📺', title: 'Ad History & PoD',
    desc: 'Blockchain-verified Proof-of-Delivery for every ad.',
    details: 'Every ad served in the bottom zone is logged with a cryptographic Proof-of-Delivery transaction. View your complete ad history, CPM rates, brand info, and on-chain verification hashes. This is the advertiser\'s auditable proof of viewership.',
    color: '#ef4444', zone: 'tabs',
  },
  {
    id: 'adbreak', icon: '🔴', title: 'Sponsored Ad Breaks',
    desc: 'Non-interruptive ads appear in the bottom zone only.',
    details: 'When a commercial break triggers, a sponsored video plays in the bottom panel while the live game continues uninterrupted on top. Each ad includes a brand card with 3 CTAs: Claim Coupon, Join Club, and Order. The video never stops — ads are additive, not disruptive.',
    color: '#dc2626', zone: 'video',
  },
];

export function AppGuide() {
  const [expandedId, setExpandedId] = useState<string | null>('overview');

  const toggle = (id: string) => {
    setExpandedId(prev => prev === id ? null : id);
  };

  return (
    <div style={{ maxWidth: 340, width: '100%', display: 'flex', flexDirection: 'column', gap: 0 }}>

      {/* Header */}
      <div style={{ background: T.surface, borderRadius: '20px 20px 0 0', border: `1px solid ${T.border}`, borderBottom: 'none', padding: '1.5rem 1.5rem 1rem' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 8 }}>
          <div style={{ width: 36, height: 36, borderRadius: 10, background: `linear-gradient(135deg, ${T.orange}, ${T.teal})`, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 18 }}>📖</div>
          <div>
            <div style={{ fontSize: '1.05rem', fontWeight: 800, color: T.text, letterSpacing: '-0.3px' }}>Interactive Guide</div>
            <div style={{ fontSize: '0.72rem', color: T.faint }}>Tap any feature to learn more</div>
          </div>
        </div>
      </div>

      {/* Guide Items */}
      <div style={{ background: T.surface, borderRadius: '0 0 20px 20px', border: `1px solid ${T.border}`, borderTop: `1px solid rgba(255,255,255,0.04)`, maxHeight: '72vh', overflowY: 'auto', scrollbarWidth: 'thin', scrollbarColor: '#333 transparent' }}>
        {GUIDE_STEPS.map((step, i) => {
          const isOpen = expandedId === step.id;
          const isLast = i === GUIDE_STEPS.length - 1;

          return (
            <div key={step.id}>
              {/* Clickable header */}
              <button
                onClick={() => toggle(step.id)}
                style={{
                  width: '100%', display: 'flex', alignItems: 'center', gap: 12,
                  padding: '12px 18px', background: isOpen ? `${step.color}0a` : 'transparent',
                  border: 'none', borderLeft: isOpen ? `3px solid ${step.color}` : '3px solid transparent',
                  cursor: 'pointer', textAlign: 'left', transition: 'all 0.2s',
                }}
              >
                <div style={{
                  width: 34, height: 34, borderRadius: 9, flexShrink: 0,
                  background: isOpen ? `${step.color}22` : 'rgba(255,255,255,0.04)',
                  border: `1px solid ${isOpen ? step.color + '55' : T.border}`,
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                  fontSize: 17, transition: 'all 0.2s',
                }}>
                  {step.icon}
                </div>
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div style={{ fontSize: '0.82rem', fontWeight: 700, color: isOpen ? '#fff' : T.text, lineHeight: 1.3 }}>
                    {step.title}
                  </div>
                  <div style={{ fontSize: '0.7rem', color: T.muted, lineHeight: 1.3, marginTop: 2 }}>
                    {step.desc}
                  </div>
                </div>
                <div style={{
                  fontSize: 12, color: T.faint, transition: 'transform 0.2s',
                  transform: isOpen ? 'rotate(90deg)' : 'rotate(0deg)',
                }}>
                  ▸
                </div>
              </button>

              {/* Expanded details */}
              {isOpen && (
                <div style={{
                  padding: '0 18px 14px 67px',
                  animation: 'fadeIn 0.25s ease',
                }}>
                  <div style={{
                    fontSize: '0.78rem', color: '#b0bec5', lineHeight: 1.65,
                    borderLeft: `2px solid ${step.color}33`, paddingLeft: 12,
                  }}>
                    {step.details}
                  </div>
                  {step.zone === 'tabs' && (
                    <div style={{
                      marginTop: 10, display: 'inline-flex', alignItems: 'center', gap: 6,
                      background: `${step.color}15`, border: `1px solid ${step.color}33`,
                      borderRadius: 8, padding: '4px 10px', fontSize: '0.68rem',
                      color: step.color, fontWeight: 600,
                    }}>
                      {step.icon} Bottom tab bar → <span style={{ fontWeight: 800 }}>{step.title}</span>
                    </div>
                  )}
                  {step.zone === 'video' && (
                    <div style={{
                      marginTop: 10, display: 'inline-flex', alignItems: 'center', gap: 6,
                      background: 'rgba(220,38,38,0.1)', border: '1px solid rgba(220,38,38,0.3)',
                      borderRadius: 8, padding: '4px 10px', fontSize: '0.68rem',
                      color: '#ef4444', fontWeight: 600,
                    }}>
                      🔴 Triggers automatically during game
                    </div>
                  )}
                </div>
              )}

              {/* Divider */}
              {!isLast && (
                <div style={{ height: 1, background: 'rgba(255,255,255,0.04)', marginLeft: 67, marginRight: 18 }} />
              )}
            </div>
          );
        })}
      </div>

      <style>{`@keyframes fadeIn { from{opacity:0;transform:translateY(-4px)} to{opacity:1;transform:translateY(0)} }`}</style>
    </div>
  );
}
