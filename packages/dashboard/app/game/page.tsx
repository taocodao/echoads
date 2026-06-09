'use client';

import { useRef, useEffect, useState } from 'react';
import { useGameEngine } from './lib/useGameEngine';
import { AD_CATALOG, GAME_META } from './lib/gameData';
import type { AdCreative } from './lib/gameData';

const HLS_URL = '/streams/game.m3u8';

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
  const g = useGameEngine();

  // Total session revenue from ads served
  const totalRevenue = AD_CATALOG
    .filter(a => a.appearsAt <= g.elapsed)
    .reduce((sum, a) => sum + a.cpm / 1000, 0);
  const adsServed = AD_CATALOG.filter(a => a.appearsAt <= g.elapsed).length;

  // ── HLS.js setup ─────────────────────────────────────────────────────────────
  useEffect(() => {
    const video = videoRef.current;
    if (!video) return;
    let hls: any;
    (async () => {
      const Hls = (await import('hls.js')).default;
      if (Hls.isSupported()) {
        hls = new Hls({ enableWorker: true });
        hls.loadSource(HLS_URL);
        hls.attachMedia(video);
        hls.on(Hls.Events.MANIFEST_PARSED, () => {
          video.play().catch(() => {});
          setVideoReady(true);
        });
        // Loop at end
        hls.on(Hls.Events.BUFFER_EOS, () => {
          hls.stopLoad();
          video.currentTime = 0;
          hls.startLoad();
          video.play().catch(() => {});
        });
      } else if (video.canPlayType('application/vnd.apple.mpegurl')) {
        video.src = HLS_URL;
        video.play().catch(() => {});
        setVideoReady(true);
      }
    })();
    return () => hls?.destroy();
  }, []);

  return (
    <div style={{ height: 'calc(100dvh - 56px)', display: 'flex', flexDirection: 'column', background: T.bg, overflow: 'hidden', fontFamily: 'Inter, system-ui, sans-serif' }}>

      {/* ── TOP HALF: Video ──────────────────────────────────────────────── */}
      <div style={{ flex: '0 0 50%', position: 'relative', background: '#000', overflow: 'hidden' }}>
        <video ref={videoRef} style={{ width: '100%', height: '100%', objectFit: 'cover' }} playsInline muted loop />

        {/* Scoreboard overlay */}
        <div style={{ position: 'absolute', top: 0, left: 0, right: 0, padding: '10px 16px', background: 'linear-gradient(to bottom, rgba(0,0,0,0.8) 0%, transparent 100%)', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
            <div style={{ width: 8, height: 8, borderRadius: '50%', background: T.red, boxShadow: `0 0 8px ${T.red}`, animation: 'pulse 1.5s infinite' }} />
            <span style={{ fontSize: 11, fontWeight: 700, color: T.red, letterSpacing: '0.1em' }}>LIVE</span>
            <span style={{ fontSize: 11, color: T.muted, marginLeft: 4 }}>{GAME_META.event}</span>
          </div>
          <div style={{ display: 'flex', alignItems: 'center', gap: 16, fontFamily: 'Bebas Neue, Arial Black, sans-serif' }}>
            <div style={{ textAlign: 'center' }}>
              <div style={{ fontSize: 13, color: T.muted }}>🦅 EAGLES</div>
              <div style={{ fontSize: 32, color: T.orange, lineHeight: 1 }}>{g.homeScore}</div>
            </div>
            <div style={{ fontSize: 18, color: T.muted }}>—</div>
            <div style={{ textAlign: 'center' }}>
              <div style={{ fontSize: 13, color: T.muted }}>BEARS 🐻</div>
              <div style={{ fontSize: 32, color: T.teal, lineHeight: 1 }}>{g.awayScore}</div>
            </div>
          </div>
          <div style={{ textAlign: 'right', fontSize: 12, color: T.muted }}>
            <div>Q{g.quarter} · {g.clock}</div>
            <div style={{ fontSize: 10 }}>NFC Wild Card</div>
          </div>
        </div>

        {/* Active ad overlay (L-bar) */}
        {g.activeAd && (
          <div style={{ position: 'absolute', bottom: 0, left: 0, right: 0, background: 'linear-gradient(to top, rgba(0,0,0,0.92) 0%, transparent 100%)', padding: '12px 16px', display: 'flex', alignItems: 'center', gap: 12, borderTop: `1px solid ${g.activeAd.color}33` }}>
            <div style={{ fontSize: 28 }}>{g.activeAd.emoji}</div>
            <div style={{ flex: 1 }}>
              <div style={{ fontSize: 10, color: T.muted, textTransform: 'uppercase', letterSpacing: '0.08em' }}>SPONSORED</div>
              <div style={{ fontSize: 15, fontWeight: 700, color: T.text }}>{g.activeAd.brand} — {g.activeAd.tagline}</div>
              <div style={{ fontSize: 10, color: T.muted }}>${g.activeAd.cpm} CPM · {g.activeAd.targetSegment}</div>
            </div>
            <div style={{ textAlign: 'right' }}>
              <div style={{ fontSize: 10, color: T.green }}>✅ PoD Verified</div>
              <div style={{ height: 4, width: 80, background: 'rgba(255,255,255,0.15)', borderRadius: 4, marginTop: 4 }}>
                <div style={{ height: '100%', width: `${(g.adTimer / g.activeAd.durationSec) * 100}%`, background: g.activeAd.color, borderRadius: 4, transition: 'width 1s linear' }} />
              </div>
            </div>
          </div>
        )}

        {/* Points fly-up */}
        {g.flyPoints && (
          <div style={{ position: 'absolute', top: '40%', left: '50%', transform: 'translateX(-50%)', fontFamily: 'Bebas Neue, sans-serif', fontSize: 36, color: T.gold, textShadow: `0 0 20px ${T.gold}`, animation: 'flyUp 1.5s ease forwards', pointerEvents: 'none', zIndex: 99 }}>
            {g.flyPoints}
          </div>
        )}
      </div>

      {/* ── BOTTOM HALF: Game Tabs ───────────────────────────────────────── */}
      <div style={{ flex: '0 0 50%', display: 'flex', flexDirection: 'column', overflow: 'hidden' }}>

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
          {lastAd.whyChosen.map((reason, i) => (
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
