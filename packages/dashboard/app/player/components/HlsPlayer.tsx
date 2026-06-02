'use client';

/**
 * HlsPlayer.tsx
 * ─────────────────────────────────────────────────────────────────────────────
 * HLS.js-powered video player with SCTE-35 ad break detection.
 *
 * Key behaviors:
 * - Loads SSAI-stitched manifest from /api/ssai/manifest/:sessionId
 * - Detects ad boundaries via EXT-X-DISCONTINUITY + EXT-X-SESSION-DATA tags
 * - Fires quartile beacons via BeaconTracker
 * - Shows x302 commerce overlay at ad T+20s
 * - Submits PoD receipts on ad completion via PodClient
 * - Live PoD feed panel on the right side
 *
 * Uses dynamic import for hls.js to avoid SSR issues (Next.js).
 */

import { useEffect, useRef, useState, useCallback } from 'react';
import { AdOverlay } from './AdOverlay';
import { BeaconTracker } from './BeaconTracker';
import { submitPoD, subscribeToReceiptLog, type PoDReceiptStatus } from './PodClient';

const API_BASE = process.env['NEXT_PUBLIC_API_URL'] ?? 'http://localhost:3001';

// ── Types ─────────────────────────────────────────────────────────────────────

interface PodMetadata {
  impressionId: string;
  campaignId: string;
  nodeOperator: string;
  cpm: number;
  advertiser: string;
  product: string;
  price: string;
  startOffsetSeconds: number;
  durationSeconds: number;
}

interface SessionData {
  sessionId: string;
  manifestUrl: string;
  podMetadata: PodMetadata[];
  adBreaks: number;
}

interface AdState {
  active: boolean;
  slotIndex: number;
  metadata: PodMetadata | null;
  /** Time (seconds into ad) at which overlay appears */
  overlayThreshold: number;
  showOverlay: boolean;
}

// ── Component ─────────────────────────────────────────────────────────────────

interface HlsPlayerProps {
  nodeOperator?: string;
  campaignId?: string;
  autoStart?: boolean;
}

export function HlsPlayer({
  nodeOperator = '0x0000000000000000000000000000000000000001',
  campaignId = '0xdeadbeef00000000000000000000000000000000000000000000000000000000',
  autoStart = false,
}: HlsPlayerProps) {
  const videoRef = useRef<HTMLVideoElement>(null);
  const hlsRef = useRef<any>(null);
  const beaconRef = useRef(new BeaconTracker());
  const adStartTimeRef = useRef<number>(0);

  const [session, setSession] = useState<SessionData | null>(null);
  const [playerState, setPlayerState] = useState<'idle' | 'loading' | 'playing' | 'error'>('idle');
  const [adState, setAdState] = useState<AdState>({
    active: false,
    slotIndex: 0,
    metadata: null,
    overlayThreshold: 20,
    showOverlay: false,
  });
  const [podLog, setPodLog] = useState<PoDReceiptStatus[]>([]);
  const [auctionLatencyMs, setAuctionLatencyMs] = useState<number | null>(null);
  const [currentCpm, setCurrentCpm] = useState<number | null>(null);

  // Subscribe to PoD receipt log
  useEffect(() => {
    return subscribeToReceiptLog(setPodLog);
  }, []);

  // Beacon tracker subscriptions
  useEffect(() => {
    const tracker = beaconRef.current;
    return tracker.onBeacon(async (event) => {
      console.log(`[beacon] ${event.quartile} → ${event.impressionId.slice(0, 12)}...`);

      if (event.quartile === 'complete') {
        const meta = adState.metadata;
        if (!meta) return;
        await submitPoD({
          impressionId: meta.impressionId,
          nodeOperator: meta.nodeOperator,
          cpm: meta.cpm,
          campaignId: meta.campaignId,
          latencyMs: Date.now() - adStartTimeRef.current,
          advertiser: meta.advertiser,
          product: meta.product,
        });
      }
    });
  }, [adState.metadata]);

  // ── Create SSAI session ────────────────────────────────────────────────────

  const createSession = useCallback(async () => {
    setPlayerState('loading');
    try {
      const res = await fetch(`${API_BASE}/api/ssai/session`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ campaignId, nodeOperator, resolution: '1080p' }),
      });
      const data = await res.json() as SessionData & { auctionLatencyMs?: number };
      setSession(data);
      setAuctionLatencyMs(data.auctionLatencyMs ?? null);
      return data;
    } catch (err) {
      console.error('[player] Session creation failed:', err);
      setPlayerState('error');
      return null;
    }
  }, [campaignId, nodeOperator]);

  // ── Initialize HLS.js ────────────────────────────────────────────────────

  const startPlayback = useCallback(async (sess: SessionData) => {
    const video = videoRef.current;
    if (!video) return;

    // Dynamic import to avoid SSR errors
    const Hls = (await import('hls.js')).default;
    if (!Hls.isSupported()) {
      // Native HLS (Safari) — just set src directly
      video.src = `${API_BASE}${sess.manifestUrl}`;
      setPlayerState('playing');
      return;
    }

    // Destroy existing instance
    if (hlsRef.current) {
      hlsRef.current.destroy();
    }

    const hls = new Hls({
      enableWorker: true,
      lowLatencyMode: false,
      backBufferLength: 30,
    });
    hlsRef.current = hls;

    hls.loadSource(`${API_BASE}${sess.manifestUrl}`);
    hls.attachMedia(video);

    hls.on(Hls.Events.MANIFEST_PARSED, () => {
      setPlayerState('playing');
      video.play().catch(() => {});
    });

    // Detect ad/content boundaries via fragment changes
    let prevDiscontinuitySeq = -1;
    let adSlotIndex = 0;

    hls.on(Hls.Events.FRAG_CHANGED, (_event: any, data: any) => {
      const frag = data.frag;
      const discSeq = frag.cc ?? 0; // continuity counter — changes at EXT-X-DISCONTINUITY

      if (discSeq !== prevDiscontinuitySeq) {
        const wasInAd = adState.active;
        const nowInAd = discSeq % 2 === 1; // odd = ad, even = content (heuristic)

        if (!wasInAd && nowInAd) {
          // Entered ad break
          const meta = sess.podMetadata[adSlotIndex] ?? null;
          adStartTimeRef.current = Date.now();

          setAdState({
            active: true,
            slotIndex: adSlotIndex,
            metadata: meta,
            overlayThreshold: 20,
            showOverlay: false,
          });
          setCurrentCpm(meta?.cpm ?? null);

          if (meta) {
            beaconRef.current.startAd(meta.impressionId, meta.durationSeconds);
          }
        } else if (wasInAd && !nowInAd) {
          // Exited ad break
          adSlotIndex++;
          beaconRef.current.stopAd();
          setAdState((prev) => ({ ...prev, active: false, showOverlay: false }));
          setCurrentCpm(null);
        }
        prevDiscontinuitySeq = discSeq;
      }
    });

    // Track currentTime for overlay timing and beacon updates
    video.addEventListener('timeupdate', () => {
      if (!adState.active || !adState.metadata) return;
      const elapsed = video.currentTime - (adState.metadata.startOffsetSeconds + adState.metadata.durationSeconds - adState.metadata.durationSeconds);
      beaconRef.current.updatePosition(elapsed);

      // Show overlay at T+20s for 30s ads, T+10s for 15s ads
      const threshold = adState.metadata.durationSeconds >= 30 ? 20 : 10;
      if (elapsed >= threshold && !adState.showOverlay) {
        setAdState((prev) => ({ ...prev, showOverlay: true }));
      }
    });

    hls.on(Hls.Events.ERROR, (_event: any, data: any) => {
      if (data.fatal) {
        console.error('[hls] Fatal error:', data);
        setPlayerState('error');
      }
    });
  }, [adState.active, adState.metadata, adState.showOverlay]);

  // Auto-start on mount if requested
  useEffect(() => {
    if (autoStart) {
      createSession().then((sess) => { if (sess) startPlayback(sess); });
    }
    return () => { hlsRef.current?.destroy(); };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const handleStart = async () => {
    const sess = await createSession();
    if (sess) await startPlayback(sess);
  };

  // ── Render ────────────────────────────────────────────────────────────────

  return (
    <div style={{ display: 'grid', gridTemplateColumns: '1fr 320px', gap: '1.5rem', alignItems: 'start' }}>

      {/* ── Left: Video player ── */}
      <div style={{ display: 'flex', flexDirection: 'column', gap: '0.75rem' }}>
        {/* Player shell */}
        <div style={{
          position: 'relative',
          background: '#000',
          borderRadius: 12,
          overflow: 'hidden',
          aspectRatio: '16/9',
          border: '1px solid rgba(255,255,255,0.1)',
          boxShadow: '0 0 40px rgba(59,130,246,0.15)',
        }}>
          {/* Video element */}
          <video
            ref={videoRef}
            style={{ width: '100%', height: '100%', objectFit: 'cover' }}
            controls={playerState === 'playing'}
            playsInline
            muted // muted allows autoplay in browsers
          />

          {/* Idle / loading overlay */}
          {playerState !== 'playing' && (
            <div style={{
              position: 'absolute', inset: 0,
              display: 'flex', flexDirection: 'column',
              alignItems: 'center', justifyContent: 'center',
              background: 'linear-gradient(135deg, rgba(15,23,42,0.95), rgba(30,41,59,0.95))',
              gap: '1.5rem',
            }}>
              {/* CMXS Logo */}
              <div style={{ textAlign: 'center' }}>
                <div style={{
                  fontSize: '3rem', fontWeight: 800,
                  background: 'linear-gradient(135deg, #3B82F6, #8B5CF6)',
                  WebkitBackgroundClip: 'text', WebkitTextFillColor: 'transparent',
                  letterSpacing: '-0.04em',
                }}>
                  CMXS
                </div>
                <div style={{ fontSize: '0.9rem', color: '#64748b', marginTop: 4 }}>
                  Sports FAST Channel — LIV Golf Round 2
                </div>
              </div>

              {playerState === 'loading' ? (
                <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem', color: '#94a3b8' }}>
                  <div style={{
                    width: 20, height: 20, borderRadius: '50%',
                    border: '2px solid rgba(59,130,246,0.3)',
                    borderTopColor: '#3B82F6',
                    animation: 'spin 0.8s linear infinite',
                  }} />
                  <span style={{ fontSize: '0.9rem' }}>
                    Running OpenRTB auction{auctionLatencyMs ? ` (${auctionLatencyMs}ms)` : '...'}
                  </span>
                </div>
              ) : playerState === 'error' ? (
                <div style={{ color: '#ef4444', fontSize: '0.9rem' }}>
                  ⚠️ Stream unavailable — check API connection
                </div>
              ) : (
                <button
                  onClick={handleStart}
                  style={{
                    padding: '0.9rem 2.5rem',
                    background: 'linear-gradient(135deg, #3B82F6, #8B5CF6)',
                    border: 'none', borderRadius: 12,
                    color: '#fff', fontWeight: 700, fontSize: '1rem',
                    cursor: 'pointer',
                    boxShadow: '0 0 30px rgba(59,130,246,0.4)',
                    transition: 'transform 0.15s, box-shadow 0.15s',
                  }}
                >
                  ▶ Start Live Stream
                </button>
              )}
            </div>
          )}

          {/* Ad break indicator (top bar) */}
          {adState.active && (
            <div style={{
              position: 'absolute', top: 12, left: 12,
              background: 'rgba(0,0,0,0.75)', backdropFilter: 'blur(8px)',
              border: '1px solid rgba(255,165,0,0.4)',
              borderRadius: 6, padding: '0.3rem 0.75rem',
              display: 'flex', alignItems: 'center', gap: '0.5rem',
            }}>
              <div style={{
                width: 7, height: 7, borderRadius: '50%',
                background: '#f59e0b', boxShadow: '0 0 6px #f59e0b',
                animation: 'pulse 1s infinite',
              }} />
              <span style={{ fontSize: '0.75rem', color: '#fcd34d', fontWeight: 600 }}>
                AD {adState.slotIndex + 1} · {adState.metadata?.advertiser ?? 'Sponsor'}
              </span>
              {currentCpm && (
                <span style={{ fontSize: '0.7rem', color: '#94a3b8' }}>
                  · ${currentCpm.toFixed(0)} CPM
                </span>
              )}
            </div>
          )}

          {/* x302 commerce overlay */}
          <AdOverlay
            visible={adState.showOverlay}
            adInfo={adState.metadata ? {
              advertiser: adState.metadata.advertiser,
              product: adState.metadata.product,
              price: adState.metadata.price,
              impressionId: adState.metadata.impressionId,
            } : null}
            onBuyNow={(impressionId) => {
              console.log('[x302] Commerce click:', impressionId);
            }}
            onDismiss={() => setAdState((prev) => ({ ...prev, showOverlay: false }))}
          />
        </div>

        {/* Session meta bar */}
        {session && (
          <div style={{
            display: 'flex', gap: '1rem', flexWrap: 'wrap',
            padding: '0.65rem 1rem',
            background: 'rgba(30,41,59,0.6)',
            border: '1px solid rgba(255,255,255,0.08)',
            borderRadius: 8, fontSize: '0.78rem', color: '#64748b',
          }}>
            <span>📡 Session: <span style={{ color: '#94a3b8' }}>{session.sessionId}</span></span>
            <span>🎯 Ad Breaks: <span style={{ color: '#94a3b8' }}>{session.adBreaks}</span></span>
            {auctionLatencyMs && (
              <span>⚡ Auction: <span style={{ color: '#22c55e' }}>{auctionLatencyMs}ms</span></span>
            )}
            <span>🏗️ Node: <span style={{ color: '#94a3b8' }}>{nodeOperator.slice(0, 8)}…</span></span>
          </div>
        )}
      </div>

      {/* ── Right: Live PoD feed ── */}
      <div style={{
        background: 'rgba(15,23,42,0.7)',
        border: '1px solid rgba(255,255,255,0.08)',
        borderRadius: 12, padding: '1rem',
        height: 'fit-content',
        maxHeight: '520px',
        overflow: 'hidden',
        display: 'flex', flexDirection: 'column',
        gap: '0.75rem',
      }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <h3 style={{ margin: 0, fontSize: '0.85rem', color: '#94a3b8', fontWeight: 600, letterSpacing: '0.06em', textTransform: 'uppercase' }}>
            Live PoD Feed
          </h3>
          <div style={{
            fontSize: '0.7rem', color: '#22c55e',
            display: 'flex', alignItems: 'center', gap: '0.35rem',
          }}>
            <div style={{
              width: 6, height: 6, borderRadius: '50%',
              background: '#22c55e', boxShadow: '0 0 6px #22c55e',
            }} />
            Live
          </div>
        </div>

        {/* Queue depth */}
        <div style={{
          background: 'rgba(59,130,246,0.08)',
          border: '1px solid rgba(59,130,246,0.2)',
          borderRadius: 8, padding: '0.5rem 0.75rem',
          display: 'flex', justifyContent: 'space-between', fontSize: '0.78rem',
        }}>
          <span style={{ color: '#64748b' }}>Queue Depth</span>
          <span style={{ color: '#3B82F6', fontWeight: 700 }}>
            {podLog.filter(r => r.status === 'queued').length} / 500
          </span>
        </div>

        {/* Receipt log */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: '0.5rem', overflowY: 'auto', flex: 1 }}>
          {podLog.length === 0 ? (
            <div style={{ color: '#334155', fontSize: '0.8rem', textAlign: 'center', padding: '1.5rem 0' }}>
              Waiting for ad completions…
            </div>
          ) : (
            podLog.map((receipt) => (
              <div key={receipt.impressionId} style={{
                padding: '0.6rem 0.75rem',
                background: 'rgba(30,41,59,0.5)',
                border: `1px solid ${receipt.status === 'confirmed' ? 'rgba(34,197,94,0.2)' : receipt.status === 'failed' ? 'rgba(239,68,68,0.2)' : 'rgba(255,255,255,0.06)'}`,
                borderRadius: 8, fontSize: '0.75rem',
              }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 4 }}>
                  <span style={{
                    color: receipt.status === 'confirmed' ? '#22c55e' : receipt.status === 'failed' ? '#ef4444' : '#f59e0b',
                    fontWeight: 600,
                  }}>
                    {receipt.status === 'confirmed' ? '✅' : receipt.status === 'failed' ? '❌' : '⏳'}{' '}
                    {receipt.impressionId.slice(0, 10)}…
                  </span>
                  <span style={{ color: '#475569' }}>
                    {new Date(receipt.submittedAt).toLocaleTimeString()}
                  </span>
                </div>
                {receipt.txHash && (
                  <div style={{ color: '#475569' }}>
                    tx: {receipt.txHash.slice(0, 12)}…
                  </div>
                )}
                {receipt.error && (
                  <div style={{ color: '#ef4444' }}>{receipt.error}</div>
                )}
              </div>
            ))
          )}
        </div>
      </div>

      {/* CSS keyframes for spinner and pulse */}
      <style>{`
        @keyframes spin { to { transform: rotate(360deg); } }
        @keyframes pulse { 0%, 100% { opacity: 1; } 50% { opacity: 0.4; } }
      `}</style>
    </div>
  );
}
