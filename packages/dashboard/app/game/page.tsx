'use client';

import { useRef, useEffect, useState } from 'react';
import { useGameEngine } from './lib/useGameEngine';
import { AD_CATALOG, GAME_META } from './lib/gameData';
import type { AdCreative } from './lib/gameData';

const VIDEO_URL = 'https://lavcma6duvpplftv.public.blob.vercel-storage.com/NFL%20video%20clips%20for%20demo.mp4';

// ── Design tokens (from arenza-sports-game HTML mockup) ────────────────────────
const T = {
  bg: '#0d0f14', surface: '#141720', surface2: '#1a1e2a',
  border: 'rgba(255,255,255,0.08)',
  text: '#f0f2ff', muted: '#8892b0', faint: '#4a5568',
  orange: '#ff6b35', teal: '#00c9b1', gold: '#ffc107',
  purple: '#7c3aed', green: '#22c55e', red: '#ef4444',
};

export default function GamePage() {
  const videoRef = useRef<HTMLVideoElement>(null);
  const [tab, setTab] = useState<'bets' | 'bingo' | 'feed' | 'profile'>('bets');
  const [videoReady, setVideoReady] = useState(false);
  const [adFormat, setAdFormat] = useState<'prediction' | 'bingo' | 'scratch' | 'moreless'>('prediction');
  const [adPaused, setAdPaused] = useState(false);
  const [scratchRevealed, setScratchRevealed] = useState<Record<number,boolean>>({});
  const [couponCode, setCouponCode] = useState<string|null>(null);
  const [mlPicks, setMlPicks] = useState<Record<number,'more'|'less'>>({});
  const [mlSubmitted, setMlSubmitted] = useState(false);
  const [copied, setCopied] = useState(false);
  const g = useGameEngine();

  const totalRevenue = AD_CATALOG
    .filter(a => a.appearsAt <= g.elapsed)
    .reduce((sum, a) => sum + a.cpm / 1000, 0);
  const adsServed = AD_CATALOG.filter(a => a.appearsAt <= g.elapsed).length;

  // ── Video: MP4 native loop ────────────────────────────────────────────────────
  useEffect(() => {
    const video = videoRef.current;
    if (!video) return;
    video.src = VIDEO_URL;
    video.load();
    const onCanPlay = () => { video.play().catch(() => {}); setVideoReady(true); };
    video.addEventListener('canplay', onCanPlay, { once: true });
    return () => video.removeEventListener('canplay', onCanPlay);
  }, []);

  // ── Interactive ad auto-cycle: 15s per format ─────────────────────────────────
  const AD_FORMATS = ['prediction', 'bingo', 'scratch', 'moreless'] as const;
  useEffect(() => {
    if (adPaused) return;
    const id = setInterval(() => {
      setAdFormat(cur => {
        const idx = (AD_FORMATS.indexOf(cur) + 1) % AD_FORMATS.length;
        return AD_FORMATS[idx];
      });
    }, 15000);
    return () => clearInterval(id);
  }, [adPaused]);

  const pauseAdCycle = (ms = 30000) => {
    setAdPaused(true);
    setTimeout(() => setAdPaused(false), ms);
  };

  // Scratch helpers
  const SCRATCH_PRIZES = [
    { code: 'DOM-SAVE30', label: '30% Off', desc: '30% off Domino\'s', pts: 300, win: true },
    { code: 'DOM-BROWNIE', label: 'FREE Brownie', desc: 'Free brownie w/ $10 order', pts: 150, win: true },
    { code: null, label: 'Try Again', desc: null, pts: 25, win: false },
  ];

  const revealScratch = (i: number) => {
    if (scratchRevealed[i]) return;
    setScratchRevealed(p => ({ ...p, [i]: true }));
    const prize = SCRATCH_PRIZES[i];
    g.points; // trigger re-render
    if (prize.win && prize.code) setCouponCode(prize.code);
    pauseAdCycle(25000);
  };

  // ML helpers
  const mlPlayers = [
    { id: 0, emoji: '🦅', name: 'J. Hurts', team: 'Eagles', stat: 'Pass TDs', line: 2.5 },
    { id: 1, emoji: '🦅', name: 'A.J. Brown', team: 'Eagles', stat: 'Rec Yards', line: 75.5 },
    { id: 2, emoji: '🐻', name: 'J. Fields', team: 'Bears', stat: 'Rush Yards', line: 35.5 },
    { id: 3, emoji: '🐻', name: 'D. Montgomery', team: 'Bears', stat: 'Carries', line: 16.5 },
  ];
  const mlPickCount = Object.keys(mlPicks).length;
  const mlMultiplier = mlPickCount >= 4 ? 6 : mlPickCount === 3 ? 3 : 1.5;
  const mlMaxWin = mlPickCount >= 2 ? Math.round(250 * mlMultiplier) : 0;

  // ── AD FORMAT DATA ────────────────────────────────────────────────────────────
  const AD_FORMAT_META = [
    { key: 'prediction', emoji: '🥤', sponsor: 'Pepsi', color: T.teal },
    { key: 'bingo',      emoji: '🍻', sponsor: 'Budweiser', color: T.gold },
    { key: 'scratch',    emoji: '🍕', sponsor: "Domino's", color: T.orange },
    { key: 'moreless',   emoji: '💪', sponsor: 'Gatorade', color: T.green },
  ] as const;

  return (
    <div style={{ height: 'calc(100dvh - 56px)', display: 'flex', flexDirection: 'column', background: T.bg, overflow: 'hidden', fontFamily: 'Inter, system-ui, sans-serif' }}>

      {/* ══ TOP 35%: Video ══════════════════════════════════════════════════ */}
      <div style={{ flex: '0 0 35%', position: 'relative', background: '#000', overflow: 'hidden' }}>
        <video ref={videoRef} style={{ width: '100%', height: '100%', objectFit: 'cover' }} playsInline muted loop preload="auto" />
        {/* Scoreboard overlay */}
        <div style={{ position: 'absolute', top: 0, left: 0, right: 0, padding: '8px 14px', background: 'linear-gradient(to bottom, rgba(0,0,0,0.85) 0%, transparent 100%)', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
            <div style={{ width: 7, height: 7, borderRadius: '50%', background: T.red, boxShadow: `0 0 6px ${T.red}`, animation: 'pulse 1.5s infinite' }} />
            <span style={{ fontSize: 10, fontWeight: 700, color: T.red, letterSpacing: '0.1em' }}>LIVE</span>
            <span style={{ fontSize: 10, color: T.muted, marginLeft: 3 }}>{GAME_META.event}</span>
          </div>
          <div style={{ display: 'flex', alignItems: 'center', gap: 12, fontFamily: 'Bebas Neue, Arial Black, sans-serif' }}>
            <div style={{ textAlign: 'center' }}>
              <div style={{ fontSize: 11, color: T.muted }}>🦅 EAGLES</div>
              <div style={{ fontSize: 26, color: T.orange, lineHeight: 1 }}>{g.homeScore}</div>
            </div>
            <div style={{ fontSize: 14, color: T.muted }}>—</div>
            <div style={{ textAlign: 'center' }}>
              <div style={{ fontSize: 11, color: T.muted }}>BEARS 🐻</div>
              <div style={{ fontSize: 26, color: T.teal, lineHeight: 1 }}>{g.awayScore}</div>
            </div>
          </div>
          <div style={{ textAlign: 'right', fontSize: 11, color: T.muted }}>
            <div>Q{g.quarter} · {g.clock}</div>
            <div style={{ fontSize: 9 }}>NFC Wild Card</div>
          </div>
        </div>
        {g.flyPoints && (
          <div style={{ position: 'absolute', top: '40%', left: '50%', transform: 'translateX(-50%)', fontFamily: 'Bebas Neue, sans-serif', fontSize: 32, color: T.gold, textShadow: `0 0 16px ${T.gold}`, animation: 'flyUp 1.5s ease forwards', pointerEvents: 'none', zIndex: 99 }}>{g.flyPoints}</div>
        )}
        {/* Glowing bottom divider */}
        <div style={{ position: 'absolute', bottom: 0, left: 0, right: 0, height: 1, background: `linear-gradient(to right, transparent, ${T.orange}66, transparent)` }} />
      </div>

      {/* ══ MIDDLE 30%: Interactive Ad Carousel ═════════════════════════════ */}
      <div style={{ flex: '0 0 30%', display: 'flex', flexDirection: 'column', overflow: 'hidden', background: T.bg }}>
        {/* Sponsor tab selector */}
        <div style={{ display: 'flex', background: T.surface, borderBottom: `1px solid ${T.border}`, flexShrink: 0 }}>
          {AD_FORMAT_META.map(({ key, emoji, sponsor, color }) => (
            <button key={key} onClick={() => { setAdFormat(key as any); pauseAdCycle(); }} style={{
              flex: 1, padding: '6px 2px', fontSize: 10, fontWeight: 600, background: 'none', border: 'none', cursor: 'pointer',
              color: adFormat === key ? color : T.faint,
              borderBottom: adFormat === key ? `2px solid ${color}` : '2px solid transparent',
              transition: 'all 0.15s',
            }}>{emoji} {sponsor}</button>
          ))}
        </div>
        {/* Ad card content */}
        <div style={{ flex: 1, overflow: 'hidden', position: 'relative' }}>
          {adFormat === 'prediction' && <WebPredictionAd g={g} onInteract={() => pauseAdCycle()} />}
          {adFormat === 'bingo' && <WebBingoAd g={g} onInteract={() => pauseAdCycle()} />}
          {adFormat === 'scratch' && <WebScratchAd scratchRevealed={scratchRevealed} revealScratch={revealScratch} couponCode={couponCode} copied={copied} setCopied={setCopied} onInteract={() => pauseAdCycle()} />}
          {adFormat === 'moreless' && <WebMoreLessAd mlPlayers={mlPlayers} mlPicks={mlPicks} setMlPicks={setMlPicks} mlSubmitted={mlSubmitted} setMlSubmitted={setMlSubmitted} mlMaxWin={mlMaxWin} mlMultiplier={mlMultiplier} onInteract={() => pauseAdCycle()} />}
        </div>
        {/* Page dots + status */}
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '4px 12px', background: T.surface, borderTop: `1px solid ${T.border}`, flexShrink: 0 }}>
          <div style={{ display: 'flex', gap: 5 }}>
            {AD_FORMAT_META.map(({ key, color }) => (
              <div key={key} onClick={() => { setAdFormat(key as any); pauseAdCycle(); }} style={{
                width: adFormat === key ? 10 : 6, height: adFormat === key ? 10 : 6,
                borderRadius: '50%', background: adFormat === key ? color : 'rgba(255,255,255,0.2)',
                cursor: 'pointer', transition: 'all 0.3s',
              }} />
            ))}
          </div>
          <span style={{ fontSize: 9, color: T.faint }}>{adPaused ? '✋ Paused' : '↻ Auto'}</span>
        </div>
        {/* Glowing bottom divider */}
        <div style={{ height: 1, background: `linear-gradient(to right, transparent, ${T.teal}55, transparent)` }} />
      </div>

      {/* ══ BOTTOM 35%: Game Tabs ═══════════════════════════════════════════ */}
      <div style={{ flex: '0 0 35%', display: 'flex', flexDirection: 'column', overflow: 'hidden' }}>

        {/* Tab bar */}
        <div style={{ display: 'flex', background: T.surface, borderBottom: `1px solid ${T.border}`, flexShrink: 0 }}>
          {([
            { key: 'bets', label: '🎯 Bets', },
            { key: 'bingo', label: '🎲 Bingo' },
            { key: 'feed', label: '🏆 Live Feed' },
            { key: 'profile', label: '👤 Profile' },
          ] as const).map(({ key, label }) => (
            <button key={key} onClick={() => setTab(key)} style={{
              flex: 1, padding: '10px 4px', fontSize: 12, fontWeight: 600,
              color: tab === key ? T.orange : T.muted,
              background: 'none', border: 'none', cursor: 'pointer',
              borderBottom: tab === key ? `2px solid ${T.orange}` : '2px solid transparent',
              transition: 'all 0.15s',
            }}>{label}</button>
          ))}
          {/* Points badge */}
          <div style={{ display: 'flex', alignItems: 'center', padding: '0 12px', fontSize: 12, fontWeight: 700, color: T.gold, flexShrink: 0 }}>
            ⭐ {g.points.toLocaleString()}
          </div>
        </div>

        {/* Tab content */}
        <div style={{ flex: 1, overflowY: 'auto', padding: '12px 16px' }}>

          {/* ── BETS TAB ───────────────────────────────────────────────── */}
          {tab === 'bets' && (
            <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
              {g.activePrediction ? (
                <PredictionCard
                  pred={g.activePrediction}
                  timer={g.predictionTimer}
                  userPick={g.userPick}
                  resolved={g.predictionResolved}
                  onPick={g.handlePredictionPick}
                />
              ) : (
                <div style={{ textAlign: 'center', padding: '24px 0', color: T.muted, fontSize: 13 }}>
                  ⏳ Next prediction incoming...
                </div>
              )}
              {/* Upcoming predictions */}
              <div style={{ fontSize: 11, color: T.faint, textTransform: 'uppercase', letterSpacing: '0.06em', marginTop: 4 }}>Upcoming Props</div>
              {[...new Set(AD_CATALOG.map(a => a.brand))].map(brand => (
                <div key={brand} style={{ padding: '8px 12px', background: T.surface2, borderRadius: 8, border: `1px solid ${T.border}`, fontSize: 12, color: T.muted }}>
                  🎯 Sponsored prediction by <span style={{ color: T.orange }}>{brand}</span> — arriving soon
                </div>
              ))}
            </div>
          )}

          {/* ── BINGO TAB ──────────────────────────────────────────────── */}
          {tab === 'bingo' && (
            <BingoGrid board={g.bingoBoard} lines={g.bingoLines} onCellClick={g.handleBingoClick} />
          )}

          {/* ── LIVE FEED TAB ──────────────────────────────────────────── */}
          {tab === 'feed' && (
            <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
              {g.feed.length === 0 && (
                <div style={{ textAlign: 'center', padding: '24px 0', color: T.faint, fontSize: 13 }}>
                  Waiting for game events...
                </div>
              )}
              {g.feed.map(entry => (
                <div key={entry.id} style={{
                  display: 'flex', gap: 10, alignItems: 'flex-start',
                  padding: '8px 10px', borderRadius: 8,
                  background: entry.type === 'ad' ? `${T.orange}11` : entry.type === 'prediction' ? `${T.teal}11` : T.surface2,
                  border: `1px solid ${entry.type === 'ad' ? `${T.orange}33` : entry.type === 'pod' ? `${T.green}33` : T.border}`,
                  fontSize: 12,
                }}>
                  <span style={{ fontSize: 16, flexShrink: 0 }}>{entry.emoji}</span>
                  <div style={{ flex: 1 }}>
                    <div style={{ color: T.text }}>{entry.text}</div>
                    {entry.detail && <div style={{ color: T.muted, fontSize: 10, marginTop: 2 }}>{entry.detail}</div>}
                  </div>
                  <span style={{ color: T.faint, fontSize: 10, flexShrink: 0 }}>{entry.timestamp}</span>
                </div>
              ))}
            </div>
          )}

          {/* ── PROFILE TAB ────────────────────────────────────────────── */}
          {tab === 'profile' && (
            <ProfileTab lastAd={g.lastAd} adsServed={adsServed} revenue={totalRevenue} points={g.points} elapsed={g.elapsed} />
          )}
        </div>
      </div>

      <style>{`
        @import url('https://fonts.googleapis.com/css2?family=Bebas+Neue&family=Inter:wght@400;600;700&family=JetBrains+Mono:wght@400;600&display=swap');
        @keyframes pulse { 0%,100%{opacity:1} 50%{opacity:0.4} }
        @keyframes flyUp { 0%{opacity:1;transform:translateX(-50%) translateY(0) scale(1)} 100%{opacity:0;transform:translateX(-50%) translateY(-60px) scale(1.4)} }
        @keyframes slideIn { from{opacity:0;transform:translateY(6px)} to{opacity:1;transform:translateY(0)} }
      `}</style>
    </div>
  );
}

// ── Prediction Card ────────────────────────────────────────────────────────────
import type { Prediction } from './lib/gameData';
function PredictionCard({ pred, timer, userPick, resolved, onPick }: {
  pred: Prediction; timer: number; userPick: number | null;
  resolved: boolean; onPick: (i: number) => void;
}) {
  return (
    <div style={{ background: T.surface2, border: `1px solid ${T.border}`, borderRadius: 12, padding: 14, animation: 'slideIn 0.3s ease' }}>
      {pred.sponsor && (
        <div style={{ fontSize: 10, color: T.orange, marginBottom: 6 }}>🎯 Sponsored by {pred.sponsor}</div>
      )}
      <div style={{ fontSize: 14, fontWeight: 600, color: T.text, marginBottom: 10 }}>{pred.question}</div>
      <div style={{ display: 'flex', gap: 8, marginBottom: 10, flexWrap: 'wrap' }}>
        {pred.options.map((opt: any, i: number) => {
          const isCorrect = resolved && i === pred.correctIndex;
          const isWrong = resolved && userPick === i && i !== pred.correctIndex;
          const isPicked = userPick === i;
          return (
            <button key={i} onClick={() => onPick(i)} disabled={userPick !== null} style={{
              flex: 1, minWidth: 80, padding: '8px 12px', borderRadius: 8, fontSize: 13, fontWeight: 600, cursor: userPick === null ? 'pointer' : 'default',
              background: isCorrect ? `${T.green}22` : isWrong ? `${T.red}15` : isPicked ? `${T.orange}22` : T.bg,
              border: `1px solid ${isCorrect ? T.green : isWrong ? T.red : isPicked ? T.orange : T.border}`,
              color: isCorrect ? T.green : isWrong ? T.red : isPicked ? T.orange : T.muted,
              transition: 'all 0.15s',
            }}>
              {opt.emoji} {opt.label}<br />
              <span style={{ fontSize: 11, fontWeight: 400 }}>{opt.odds}</span>
            </button>
          );
        })}
      </div>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', fontSize: 11, color: T.muted }}>
        <span>⏱ Locks in {timer}s</span>
        <span style={{ color: T.gold }}>🎖 +{pred.pointReward} pts</span>
      </div>
      <div style={{ height: 3, background: T.border, borderRadius: 4, marginTop: 8 }}>
        <div style={{ height: '100%', background: timer > 5 ? T.teal : T.red, borderRadius: 4, width: `${(timer / pred.durationSec) * 100}%`, transition: 'width 1s linear' }} />
      </div>
    </div>
  );
}

// ── Bingo Grid ─────────────────────────────────────────────────────────────────
function BingoGrid({ board, lines, onCellClick }: { board: any[]; lines: number; onCellClick: (i: number) => void }) {
  return (
    <div>
      <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 10 }}>
        <div style={{ fontFamily: 'Bebas Neue, sans-serif', fontSize: 13, letterSpacing: '0.3em', color: T.orange }}>B &nbsp; I &nbsp; N &nbsp; G &nbsp; O</div>
        <div style={{ fontSize: 12, color: T.gold }}>🏆 Lines: {lines} · +500 pts per BINGO!</div>
      </div>
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(5, 1fr)', gap: 5 }}>
        {board.map((cell, i) => (
          <button key={i} onClick={() => onCellClick(i)} style={{
            aspectRatio: '1', padding: 4, borderRadius: 6, fontSize: 9, textAlign: 'center', lineHeight: 1.2, cursor: cell.free ? 'default' : 'pointer',
            background: cell.free ? `linear-gradient(135deg, ${T.orange}, ${T.teal})` : cell.marked ? `${T.orange}33` : T.surface2,
            border: `1px solid ${cell.free ? 'transparent' : cell.marked ? T.orange : T.border}`,
            color: cell.free ? '#fff' : cell.marked ? T.text : T.muted,
            fontWeight: cell.free || cell.marked ? 700 : 400,
            transition: 'all 0.15s',
          }}>
            {cell.free ? 'FREE' : cell.label}
            {cell.marked && !cell.free && <div style={{ color: T.teal, fontSize: 8 }}>✓</div>}
          </button>
        ))}
      </div>
      <div style={{ fontSize: 11, color: T.faint, marginTop: 10 }}>Click any cell to mark it (+25 pts). Game events auto-mark cells.</div>
    </div>
  );
}

// ── Profile / Targeting Tab ────────────────────────────────────────────────────
function ProfileTab({ lastAd, adsServed, revenue, points, elapsed }: {
  lastAd: AdCreative | null; adsServed: number; revenue: number; points: number; elapsed: number;
}) {
  const interests = [
    { label: 'Football', pct: 92, color: T.orange },
    { label: 'Basketball', pct: 68, color: T.teal },
    { label: 'Baseball', pct: 41, color: T.purple },
    { label: 'Soccer', pct: 35, color: T.gold },
  ];
  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
      {/* Viewer segment */}
      <div style={{ padding: 12, background: T.surface2, border: `1px solid ${T.border}`, borderRadius: 10 }}>
        <div style={{ fontSize: 10, color: T.muted, textTransform: 'uppercase', letterSpacing: '0.06em', marginBottom: 6 }}>👤 Viewer Profile</div>
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 8 }}>
          {[
            ['Segment', 'Sports Enthusiast'],
            ['Demo', 'M · 25–34'],
            ['Engagement', '87/100'],
            ['Watch Time', `${Math.floor(elapsed / 60)}m ${elapsed % 60}s`],
          ].map(([k, v]) => (
            <div key={k} style={{ fontSize: 11 }}>
              <div style={{ color: T.faint }}>{k}</div>
              <div style={{ color: T.text, fontWeight: 600 }}>{v}</div>
            </div>
          ))}
        </div>
      </div>

      {/* Interest signals */}
      <div style={{ padding: 12, background: T.surface2, border: `1px solid ${T.border}`, borderRadius: 10 }}>
        <div style={{ fontSize: 10, color: T.muted, textTransform: 'uppercase', letterSpacing: '0.06em', marginBottom: 8 }}>📊 Interest Signals</div>
        {interests.map(({ label, pct, color }) => (
          <div key={label} style={{ marginBottom: 6 }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: 11, marginBottom: 3 }}>
              <span style={{ color: T.text }}>{label}</span>
              <span style={{ color, fontWeight: 700 }}>{pct}%</span>
            </div>
            <div style={{ height: 4, background: T.border, borderRadius: 4 }}>
              <div style={{ height: '100%', width: `${pct}%`, background: color, borderRadius: 4 }} />
            </div>
          </div>
        ))}
      </div>

      {/* Why this ad */}
      {lastAd && (
        <div style={{ padding: 12, background: `${lastAd.color}11`, border: `1px solid ${lastAd.color}44`, borderRadius: 10 }}>
          <div style={{ fontSize: 10, color: T.muted, textTransform: 'uppercase', letterSpacing: '0.06em', marginBottom: 6 }}>🎯 Why {lastAd.brand} was served</div>
          <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 8 }}>
            <span style={{ fontSize: 20 }}>{lastAd.emoji}</span>
            <div>
              <div style={{ fontSize: 13, fontWeight: 700, color: T.text }}>{lastAd.brand} — {lastAd.tagline}</div>
              <div style={{ fontSize: 11, color: lastAd.color }}>${lastAd.cpm} CPM · Won OpenRTB auction</div>
            </div>
          </div>
          {lastAd.whyChosen.map((reason: string, i: number) => (
            <div key={i} style={{ fontSize: 11, color: T.muted, padding: '3px 0', borderBottom: `1px solid ${T.border}`, display: 'flex', gap: 6 }}>
              <span style={{ color: T.green }}>✓</span> {reason}
            </div>
          ))}
        </div>
      )}

      {/* Session revenue */}
      <div style={{ padding: 12, background: T.surface2, border: `1px solid ${T.border}`, borderRadius: 10 }}>
        <div style={{ fontSize: 10, color: T.muted, textTransform: 'uppercase', letterSpacing: '0.06em', marginBottom: 8 }}>💰 Session Revenue</div>
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 8, textAlign: 'center' }}>
          {[
            ['Ads Served', String(adsServed), T.orange],
            ['Revenue', `$${revenue.toFixed(3)}`, T.green],
            ['Avg CPM', adsServed > 0 ? `$${(revenue * 1000 / adsServed).toFixed(0)}` : '—', T.teal],
          ].map(([label, val, color]) => (
            <div key={label}>
              <div style={{ fontFamily: 'JetBrains Mono, monospace', fontSize: 18, fontWeight: 700, color }}>{val}</div>
              <div style={{ fontSize: 10, color: T.faint }}>{label}</div>
            </div>
          ))}
        </div>
      </div>

      {/* Points summary */}
      <div style={{ padding: 10, background: `${T.gold}11`, border: `1px solid ${T.gold}33`, borderRadius: 10, display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <div>
          <div style={{ fontSize: 10, color: T.muted }}>Your Points</div>
          <div style={{ fontFamily: 'Bebas Neue, sans-serif', fontSize: 28, color: T.gold, lineHeight: 1 }}>{points.toLocaleString()}</div>
        </div>
        <div style={{ fontSize: 11, color: T.muted, textAlign: 'right' }}>
          <div>≈ ${(points / 200).toFixed(2)} prize value</div>
          <div style={{ color: T.teal, marginTop: 2 }}>Top 12% this game</div>
        </div>
      </div>
    </div>
  );
}

// ── Web Ad Card: Prediction ─────────────────────────────────────────────────────
function WebPredictionAd({ g, onInteract }: { g: any; onInteract: () => void }) {
  return (
    <div style={{ height: '100%', overflowY: 'auto', padding: '8px 12px', display: 'flex', flexDirection: 'column', gap: 8 }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 5 }}>
          <div style={{ width: 6, height: 6, borderRadius: '50%', background: '#ef4444', animation: 'pulse 1.4s infinite' }} />
          <span style={{ fontSize: 9, fontWeight: 700, color: '#ef4444', letterSpacing: '0.1em' }}>LIVE · Q{g.quarter} · {g.clock}</span>
        </div>
        <span style={{ fontSize: 9, color: T.teal, fontWeight: 700 }}>🥤 Pepsi Presents</span>
      </div>
      {g.activePrediction ? (
        <>
          <div style={{ fontSize: 13, fontWeight: 700, color: T.text }}>{g.activePrediction.question}</div>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 6 }}>
            {g.activePrediction.options.map((opt: any, i: number) => (
              <button key={i} onClick={onInteract} style={{
                padding: '8px', borderRadius: 8, fontSize: 11, fontWeight: 600, cursor: 'pointer',
                background: g.userPick === i ? `${T.orange}22` : T.surface2,
                border: `1px solid ${g.userPick === i ? T.orange : T.border}`,
                color: g.userPick === i ? T.orange : T.muted, transition: 'all 0.15s',
              }}>{opt.emoji} {opt.label}</button>
            ))}
          </div>
          <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: 10, color: T.muted }}>
            <span>⏱ {g.predictionTimer}s remaining</span>
            <span style={{ color: T.gold }}>🎖 +{g.activePrediction.pointReward} pts</span>
          </div>
          <div style={{ height: 3, background: T.border, borderRadius: 3 }}>
            <div style={{ height: '100%', background: T.teal, borderRadius: 3, width: `${(g.predictionTimer / g.activePrediction.durationSec) * 100}%`, transition: 'width 1s linear' }} />
          </div>
        </>
      ) : (
        <div style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', gap: 6, color: T.muted }}>
          <div style={{ fontSize: 24 }}>🔮</div>
          <div style={{ fontSize: 12 }}>Next prediction incoming...</div>
          <div style={{ fontSize: 10, color: T.faint }}>Sponsored by Pepsi</div>
        </div>
      )}
    </div>
  );
}

// ── Web Ad Card: Bingo ──────────────────────────────────────────────────────────
function WebBingoAd({ g, onInteract }: { g: any; onInteract: () => void }) {
  const COLS = ['B','I','N','G','O'];
  return (
    <div style={{ height: '100%', overflowY: 'auto', padding: '8px 10px', display: 'flex', flexDirection: 'column', gap: 6 }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <span style={{ fontSize: 12, fontWeight: 800, color: T.gold, letterSpacing: '0.2em' }}>B · I · N · G · O</span>
        <span style={{ fontSize: 9, color: T.gold, fontWeight: 700 }}>🍻 Budweiser · Lines: {g.bingoLines}</span>
      </div>
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(5,1fr)', gap: 2 }}>
        {COLS.map(c => <div key={c} style={{ textAlign: 'center', fontSize: 10, fontWeight: 800, color: T.gold, padding: '2px 0' }}>{c}</div>)}
        {(g.bingoBoard || []).map((cell: any) => (
          <div key={cell.id} onClick={() => { g.markBingoCell?.(cell.id); onInteract(); }} style={{
            aspectRatio: '1', borderRadius: 5, display: 'flex', alignItems: 'center', justifyContent: 'center',
            fontSize: 7, textAlign: 'center', fontWeight: cell.marked ? 700 : 400, lineHeight: 1.2, cursor: 'pointer',
            background: cell.isFree ? 'linear-gradient(135deg,#ff6b35,#ffc107)' : cell.marked ? `${T.gold}22` : T.surface2,
            border: `1px solid ${cell.marked ? T.gold : T.border}`, color: cell.isFree ? '#fff' : cell.marked ? T.text : T.muted,
            transition: 'all 0.15s',
          }}>{cell.isFree ? 'FREE' : cell.label}</div>
        ))}
      </div>
      <div style={{ fontSize: 9, color: T.faint, textAlign: 'center' }}>Tap to mark · +500 pts per BINGO · +25 pts per cell</div>
    </div>
  );
}

// ── Web Ad Card: Scratch & Win ──────────────────────────────────────────────────
function WebScratchAd({ scratchRevealed, revealScratch, couponCode, copied, setCopied, onInteract }: any) {
  const prizes = [
    { label: '30% Off', win: true }, { label: 'FREE Brownie', win: true }, { label: 'Try Again', win: false }
  ];
  return (
    <div style={{ height: '100%', overflowY: 'auto', padding: '8px 12px', display: 'flex', flexDirection: 'column', gap: 8 }}>
      <div style={{ display: 'flex', justifyContent: 'space-between' }}>
        <span style={{ fontSize: 11, fontWeight: 700, color: T.orange }}>🎟️ Halftime Scratch</span>
        <span style={{ fontSize: 9, color: T.orange, fontWeight: 700 }}>🍕 Domino&apos;s</span>
      </div>
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3,1fr)', gap: 6 }}>
        {prizes.map((p, i) => (
          <div key={i} onClick={() => { revealScratch(i); onInteract(); }} style={{
            aspectRatio: '0.75', borderRadius: 10, border: `1px solid ${scratchRevealed[i] && p.win ? `${T.orange}66` : T.border}`,
            background: scratchRevealed[i] ? (p.win ? `${T.orange}11` : T.surface2) : T.surface2,
            display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', gap: 4,
            cursor: scratchRevealed[i] ? 'default' : 'pointer', transition: 'all 0.3s',
          }}>
            {scratchRevealed[i] ? (
              p.win ? (
                <>
                  <div style={{ fontSize: 18 }}>🎉</div>
                  <div style={{ fontSize: 11, fontWeight: 800, color: T.orange }}>{p.label}</div>
                </>
              ) : (
                <>
                  <div style={{ fontSize: 18 }}>😢</div>
                  <div style={{ fontSize: 10, color: T.muted }}>Try again</div>
                </>
              )
            ) : (
              <>
                <div style={{ fontSize: 20 }}>🎟️</div>
                <div style={{ fontSize: 9, color: T.muted, fontWeight: 600 }}>TAP TO SCRATCH</div>
              </>
            )}
          </div>
        ))}
      </div>
      {couponCode && (
        <div style={{ padding: '8px 10px', background: `${T.orange}11`, border: `1px solid ${T.orange}33`, borderRadius: 8 }}>
          <div style={{ fontSize: 9, color: T.faint, marginBottom: 4 }}>🎉 YOUR COUPON — saved to wallet</div>
          <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
            <span style={{ fontFamily: 'monospace', fontSize: 13, fontWeight: 800, color: T.orange, letterSpacing: '0.12em', border: `1px dashed ${T.orange}66`, padding: '3px 8px', borderRadius: 5 }}>{couponCode}</span>
            <button onClick={() => { navigator.clipboard.writeText(couponCode).catch(()=>{}); setCopied(true); setTimeout(()=>setCopied(false), 2000); }} style={{ padding: '4px 10px', borderRadius: 999, background: copied ? `${T.green}22` : T.orange, color: copied ? T.green : '#0d0f14', fontSize: 10, fontWeight: 700, border: 'none', cursor: 'pointer' }}>{copied ? '✓ Copied' : 'Copy'}</button>
          </div>
        </div>
      )}
    </div>
  );
}

// ── Web Ad Card: More or Less ───────────────────────────────────────────────────
function WebMoreLessAd({ mlPlayers, mlPicks, setMlPicks, mlSubmitted, setMlSubmitted, mlMaxWin, mlMultiplier, onInteract }: any) {
  const pickCount = Object.keys(mlPicks).length;
  return (
    <div style={{ height: '100%', overflowY: 'auto', padding: '8px 10px', display: 'flex', flexDirection: 'column', gap: 6 }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <span style={{ fontSize: 11, fontWeight: 700, color: T.green }}>📊 More or Less</span>
        <span style={{ fontSize: 9, color: T.green, fontWeight: 700 }}>💪 Gatorade · {pickCount >= 2 ? `×${mlMultiplier}` : 'Pick 2+'}</span>
      </div>
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 5 }}>
        {mlPlayers.map((p: any) => (
          <div key={p.id} style={{ background: T.surface, border: `1px solid ${mlPicks[p.id] ? (mlPicks[p.id]==='more' ? `${T.green}55` : `${T.red}55`) : T.border}`, borderRadius: 9, overflow: 'hidden' }}>
            <div style={{ padding: '5px 8px', background: T.surface2, borderBottom: `1px solid ${T.border}`, display: 'flex', alignItems: 'center', gap: 5 }}>
              <span style={{ fontSize: 14 }}>{p.emoji}</span>
              <div>
                <div style={{ fontSize: 10, fontWeight: 700, color: T.text }}>{p.name}</div>
                <div style={{ fontSize: 9, color: T.muted }}>{p.team}</div>
              </div>
            </div>
            <div style={{ padding: '4px 8px', textAlign: 'center' }}>
              <div style={{ fontSize: 8, color: T.faint, textTransform: 'uppercase', letterSpacing: '0.08em' }}>{p.stat}</div>
              <div style={{ fontSize: 18, fontWeight: 800, color: T.green, lineHeight: 1.1 }}>{p.line}</div>
            </div>
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 3, padding: '0 5px 5px' }}>
              {(['more','less'] as const).map(dir => (
                <button key={dir} disabled={mlSubmitted} onClick={() => { const cur = {...mlPicks}; cur[p.id]===dir ? delete cur[p.id] : (cur[p.id]=dir); setMlPicks(cur); onInteract(); }} style={{
                  padding: '5px', fontSize: 9, fontWeight: 700, borderRadius: 6, cursor: mlSubmitted ? 'default' : 'pointer',
                  border: `1px solid ${mlPicks[p.id]===dir ? (dir==='more' ? T.green : T.red) : T.border}`,
                  background: mlPicks[p.id]===dir ? (dir==='more' ? `${T.green}18` : `${T.red}15`) : 'transparent',
                  color: mlPicks[p.id]===dir ? (dir==='more' ? T.green : T.red) : T.muted,
                }}>{dir==='more' ? '↑ MORE' : '↓ LESS'}</button>
              ))}
            </div>
          </div>
        ))}
      </div>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginTop: 2 }}>
        <span style={{ fontSize: 10, color: T.muted }}>Picks: {pickCount}/4 {mlMaxWin > 0 && `· Win +${mlMaxWin} pts`}</span>
        <button disabled={pickCount < 2 || mlSubmitted} onClick={() => { setMlSubmitted(true); onInteract(); setTimeout(()=>setMlSubmitted(false), 5000); }} style={{
          padding: '6px 14px', borderRadius: 999, fontSize: 11, fontWeight: 700, border: 'none', cursor: pickCount < 2 || mlSubmitted ? 'default' : 'pointer',
          background: mlSubmitted ? `${T.green}22` : pickCount >= 2 ? T.green : T.surface2,
          color: mlSubmitted ? T.green : pickCount >= 2 ? '#0d0f14' : T.faint, transition: 'all 0.2s',
        }}>{mlSubmitted ? '✅ Submitted!' : 'Submit Entry'}</button>
      </div>
    </div>
  );
}
