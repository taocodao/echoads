'use client';

import { useRef, useEffect, useState, useCallback } from 'react';
import { useGameEngine } from './lib/useGameEngine';
import { AD_CATALOG, COMMERCIAL_BREAKS } from './lib/gameData';
import type { AdCreative } from './lib/gameData';
import { IPhoneFrame } from './components/IPhoneFrame';
import { IOSTabBar, type TabKey } from './components/IOSTabBar';
import { useProfileEngine } from './lib/useProfileEngine';
import { useGameMomentClassifier, type ActiveMoment } from './lib/useGameMomentClassifier';
import { CommentaryOverlay } from './components/CommentaryOverlay';
import { AudienceTierBadge } from './components/AudienceTierBadge';
import { MarketplaceTab } from './components/MarketplaceTab';
import { WalletTab } from './components/WalletTab';
import { LeaderboardTab } from './components/LeaderboardTab';
import { OnboardingFlow, type OnboardingProfile } from './components/OnboardingFlow';
import { PostGameRecap } from './components/PostGameRecap';
import { generateCoupon, buildGameContext } from './lib/couponEngine';
import { usePersistedState } from './lib/usePersistence';
import type { BusinessListing } from './lib/sharedTypes';

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
  const [tab, setTab] = useState<TabKey>('predict');
  const [videoReady, setVideoReady] = useState(false);
  const [isFullscreen, setIsFullscreen] = useState(false);
  const [shareToast, setShareToast] = useState(false);
  const [tabUserInteracted, setTabUserInteracted] = useState(false);
  const videoContainerRef = useRef<HTMLDivElement>(null);
  const [scratchRevealed, setScratchRevealed] = useState<Record<number,boolean>>({});
  const [couponCode, setCouponCode] = useState<string|null>(null);
  const [mlPicks, setMlPicks] = useState<Record<number,'more'|'less'>>({});
  const [mlSubmitted, setMlSubmitted] = useState(false);
  const [copied, setCopied] = useState(false);
  const [isMuted, setIsMuted] = useState(true);
  const [currentAdBreak, setCurrentAdBreak] = useState<AdCreative | null>(null);
  const [adProgress, setAdProgress] = useState(0);
  const [podToast, setPodToast] = useState<{brand: string; cpm: number; txHash: string} | null>(null);
  const adVideoRef = useRef<HTMLVideoElement>(null);
  const adTimerRef = useRef<ReturnType<typeof setInterval> | null>(null);

  // ── Persistent state (survives reload) ────────────────────────────────────────
  const [adHistory, setAdHistory] = usePersistedState<{ad: AdCreative; txHash: string; verified: boolean; momentCode?: string; momentMultiplier?: number}[]>('adHistory', []);
  const [claimedCoupons, setClaimedCoupons] = usePersistedState<{businessName:string;offer:string;code?:string;claimedAt:number}[]>('claimedCoupons', []);
  const [joinedClubs, setJoinedClubs] = usePersistedState<{businessName:string;cardName:string;emoji:string;joinedAt:number}[]>('joinedClubs', []);
  const [onboardingProfile, setOnboardingProfile] = usePersistedState<OnboardingProfile | null>('onboardingProfile', null);
  const [totalPredictions, setTotalPredictions] = usePersistedState<number>('totalPredictions', 0);
  const [correctPredictions, setCorrectPredictions] = usePersistedState<number>('correctPredictions', 0);

  const lastAdIdRef = useRef<string | null>(null);

  // ── Ephemeral UI state ────────────────────────────────────────────────────────
  const [showOnboarding, setShowOnboarding] = useState(false);
  const [walletToast, setWalletToast] = useState<string | null>(null);
  const [couponClaimToast, setCouponClaimToast] = useState<{brand: string; offer: string} | null>(null);
  const [showRecap, setShowRecap] = useState(false);
  // Show onboarding on first visit
  useEffect(() => {
    if (!onboardingProfile) {
      const t = setTimeout(() => setShowOnboarding(true), 800);
      return () => clearTimeout(t);
    }
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const g = useGameEngine();
  const { liveMode, socketStatus } = g;
  const profileEngine = useProfileEngine(g.elapsed);
  const momentClassifier = useGameMomentClassifier(g.elapsed);
  const { profile } = profileEngine;
  const { moment, commentaryVisible } = momentClassifier;

  const totalRevenue = adHistory.reduce((sum, h) => sum + h.ad.cpm / 1000, 0);
  const adsServed = adHistory.length;

  // ── Wallet callbacks ─────────────────────────────────────────────────────────
  const handleCouponClaim = (b: BusinessListing) => {
    if (claimedCoupons.find(c => c.businessName === b.name)) return;
    const code = b.activeOffer?.promoCode;
    const offer = b.activeOffer?.headline ?? 'Special Offer';
    setClaimedCoupons(prev => [...prev, {
      businessName: b.name, offer,
      ...(code ? { code } : {}),
      claimedAt: Date.now(),
    }]);
    profileEngine.recordSponsor();
    setCouponClaimToast({ brand: b.name, offer });
    setTimeout(() => setCouponClaimToast(null), 3000);
    setTab('wallet');
    setTabUserInteracted(true);
    setTimeout(() => setTabUserInteracted(false), 60000);
  };

  const handleJoinClub = (b: BusinessListing) => {
    if (joinedClubs.find(c => c.businessName === b.name)) return;
    setJoinedClubs(prev => [...prev, {
      businessName: b.name,
      cardName: b.membership?.cardName ?? `${b.name} Club`,
      emoji: b.emoji,
      joinedAt: Date.now(),
    }]);
    profileEngine.recordSponsor();
    setWalletToast(`✅ Joined ${b.name} Club!`);
    setTimeout(() => setWalletToast(null), 2500);
  };

  /** Claim coupon directly from the bottom-zone ad card */
  const handleAdCouponClaim = useCallback((ad: AdCreative) => {
    if (claimedCoupons.find(c => c.businessName === ad.brand)) return;
    const offer = ad.offerHeadline ?? ad.tagline;
    setClaimedCoupons(prev => [...prev, {
      businessName: ad.brand, offer, claimedAt: Date.now(),
    }]);
    profileEngine.recordAdInteraction();
    profileEngine.recordSponsor();
    setCouponClaimToast({ brand: ad.brand, offer });
    setTimeout(() => setCouponClaimToast(null), 3000);
  }, [claimedCoupons, profileEngine]);

  /** Join membership club directly from the bottom-zone ad card */
  const handleAdJoinClub = useCallback((ad: AdCreative) => {
    if (joinedClubs.find(c => c.businessName === ad.brand)) return;
    setJoinedClubs(prev => [...prev, {
      businessName: ad.brand,
      cardName: `${ad.brand} Club`,
      emoji: ad.emoji,
      joinedAt: Date.now(),
    }]);
    profileEngine.recordSponsor();
    setWalletToast(`🎉 Joined ${ad.brand} Club! Check your Wallet.`);
    setTimeout(() => setWalletToast(null), 2500);
  }, [joinedClubs, profileEngine]);

  /** Track prediction results for post-game recap */
  const handlePredictionResult = useCallback((correct: boolean) => {
    setTotalPredictions(n => n + 1);
    if (correct) setCorrectPredictions(n => n + 1);
  }, [setTotalPredictions, setCorrectPredictions]);



  // ── Top video: autoplay with sound ────────────────────────────────────────────
  // Strategy: start muted (satisfies browser autoplay policy), then
  // immediately call .click() on the video element to register a user gesture
  // and unmute. This gives sound-on from first frame without any visible button.
  useEffect(() => {
    const v = videoRef.current;
    if (!v) return;
    v.muted = true;
    v.volume = 1.0;
    v.playsInline = true;

    const tryUnmute = () => {
      v.muted = false;
      v.volume = 1.0;
    };

    const startPlay = () => {
      v.play()
        .then(() => {
          // Play succeeded muted — now unmute immediately
          tryUnmute();
        })
        .catch(() => {
          // Autoplay blocked — wait for any user interaction
          const onInteract = () => {
            v.muted = false;
            v.volume = 1.0;
            v.play().catch(() => {});
            document.removeEventListener('click', onInteract);
            document.removeEventListener('touchstart', onInteract);
            document.removeEventListener('keydown', onInteract);
          };
          document.addEventListener('click', onInteract, { once: true });
          document.addEventListener('touchstart', onInteract, { once: true });
          document.addEventListener('keydown', onInteract, { once: true });
        });
    };

    v.addEventListener('loadeddata', startPlay, { once: true });
    v.addEventListener('canplay', startPlay, { once: true });
    startPlay();

    // Watchdog: re-check every 2s in case the video paused
    const id = setInterval(() => {
      if (v.paused) { v.play().catch(() => {}); }
      if (v.muted) { v.muted = false; v.volume = 1.0; }
    }, 2000);

    return () => {
      v.removeEventListener('loadeddata', startPlay);
      v.removeEventListener('canplay', startPlay);
      clearInterval(id);
    };
  }, []);

  const handleUnmute = () => {
    const v = videoRef.current;
    if (v) { v.muted = false; v.volume = 1.0; }
    const av = adVideoRef.current;
    if (av) { av.muted = false; av.volume = 1.0; }
    setIsMuted(false);
  };


  // Fullscreen API
  useEffect(() => {
    const onFsChange = () => setIsFullscreen(!!document.fullscreenElement);
    document.addEventListener('fullscreenchange', onFsChange);
    return () => document.removeEventListener('fullscreenchange', onFsChange);
  }, []);

  const toggleFullscreen = () => {
    const el = videoContainerRef.current;
    if (!document.fullscreenElement) { el?.requestFullscreen(); setIsFullscreen(true); }
    else { document.exitFullscreen(); setIsFullscreen(false); }
  };

  const shareGame = async () => {
    const shareData = { title: 'Arenza', text: "I'm watching Eagles vs Bears LIVE on Arenza! Join me and earn 500 bonus pts ????", url: 'https://arenza.tv/join?ref=demo-user' };
    if (navigator.share) { await navigator.share(shareData).catch(() => {}); }
    else { navigator.clipboard.writeText(shareData.url).catch(() => {}); setShareToast(true); setTimeout(() => setShareToast(false), 2000); }
  };

  // ── Smart switching logic ────────────────────────────────────────────────────
  //
  // Rule 1 — Tab auto-cycle (demo mode only, no user interaction):
  //   Rotates every 25s BUT skips if the user is "busy":
  //   - A prediction is live (they might be mid-vote)
  //   - The scratch card hasn’t been revealed yet
  //   - ML picks exist but haven’t been submitted
  //   Once tabUserInteracted = true (user tapped a tab), auto-cycle stops for
  //   60s then resumes. If they tap again the 60s resets.
  //
  // Rule 2 — Ad breaks (courtesy delay):
  //   When a break fires, we first check if the user is "busy".
  //   If busy, we wait up to 15s for them to finish before forcing the ad.
  //   This means: finishing a prediction vote, completing a scratch, etc.
  //   won’t be interrupted mid-action.

  /** Returns true when the user is mid-interaction and shouldn’t be interrupted */
  const isUserBusy = useCallback(() => {
    if (tab === 'predict' && g.activePrediction && g.userPick === null) return true;   // prediction live, not yet voted
    if (tab === 'scratch' && Object.keys(scratchRevealed).length === 0) return true;   // scratch not started
    if (tab === 'moreless' && Object.keys(mlPicks).length > 0 && !mlSubmitted) return true; // picks made, not submitted
    return false;
  }, [tab, g.activePrediction, g.userPick, scratchRevealed, mlPicks, mlSubmitted]);

  // Tab auto-cycle
  useEffect(() => {
    if (tabUserInteracted) return;
    const cycle = ['predict','bingo','scratch','moreless','market'] as const;
    const id = setInterval(() => {
      if (isUserBusy()) return; // skip this tick — user is busy
      setTab(cur => { const i = cycle.indexOf(cur as any); return i >= 0 ? cycle[(i+1)%cycle.length] : cur; });
    }, 25000);
    return () => clearInterval(id);
  }, [tabUserInteracted, isUserBusy]);

  // ── Ad break queue with courtesy delay ───────────────────────────────────────
  const firedBreakIds = useRef(new Set<string>());
  const adQueueRef = useRef<typeof AD_CATALOG>([]);
  const isBreakActive = useRef(false);
  const adPendingBreak = useRef<typeof COMMERCIAL_BREAKS[0] | null>(null);
  const adCourtesyTimer = useRef<ReturnType<typeof setTimeout> | null>(null);

  const playNextAd = useCallback(() => {
    if (adQueueRef.current.length === 0) {
      isBreakActive.current = false;
      setCurrentAdBreak(null);
      setAdProgress(0);
      return;
    }
    const ad = adQueueRef.current.shift()!;
    setCurrentAdBreak(ad);
    setAdProgress(0);

    const updateProgress = () => {
      const v = adVideoRef.current;
      if (!v || !v.duration) return;
      setAdProgress((v.currentTime / v.duration) * 100);
    };
    const onEnded = () => {
      const v = adVideoRef.current;
      if (v) { v.removeEventListener('timeupdate', updateProgress); v.removeEventListener('ended', onEnded); }
      setAdProgress(100);
      const txHash = '0x' + Array.from({length:16}, ()=>Math.floor(Math.random()*16).toString(16)).join('');
      setAdHistory(prev => [...prev, { ad, txHash, verified: true, momentCode: moment.code, momentMultiplier: moment.meta.multiplier }]);
      profileEngine.recordAdWatched();
      setPodToast({ brand: ad.brand, cpm: ad.cpm, txHash });
      setTimeout(() => { setPodToast(null); playNextAd(); }, 1200);
    };
    setTimeout(() => {
      const v = adVideoRef.current;
      if (!v) return;
      v.addEventListener('timeupdate', updateProgress);
      v.addEventListener('ended', onEnded);
      v.muted = true;
      v.volume = 0;
      v.play().catch(() => { v.play().catch(() => {}); });
    }, 80);
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [moment.code, moment.meta.multiplier, profileEngine]);

  /** Actually start the queued break */
  const startPendingBreak = useCallback(() => {
    const brk = adPendingBreak.current;
    if (!brk || isBreakActive.current) return;
    adPendingBreak.current = null;
    if (adCourtesyTimer.current) { clearTimeout(adCourtesyTimer.current); adCourtesyTimer.current = null; }
    isBreakActive.current = true;
    adQueueRef.current = [...brk.ads];
    playNextAd();
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  /** Schedule a break: wait if busy, force after 15s grace window */
  const scheduleBreak = useCallback((brk: typeof COMMERCIAL_BREAKS[0]) => {
    if (isBreakActive.current) return;
    adPendingBreak.current = brk;
    if (!isUserBusy()) {
      // User is idle — start immediately
      startPendingBreak();
    } else {
      // User is busy — poll every 2s, force after 15s
      let waited = 0;
      const poll = setInterval(() => {
        waited += 2;
        if (!isUserBusy() || waited >= 15) {
          clearInterval(poll);
          startPendingBreak();
        }
      }, 2000);
      // Safety: clear poll if break fires by other means
      adCourtesyTimer.current = setTimeout(() => clearInterval(poll), 16000);
    }
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [isUserBusy, startPendingBreak]);

  useEffect(() => {
    if (g.elapsed <= 3 && !isBreakActive.current) firedBreakIds.current = new Set();
    if (isBreakActive.current) return;
    const brk = COMMERCIAL_BREAKS.find(
      b => g.elapsed === b.triggerAt && !firedBreakIds.current.has(b.id)
    );
    if (!brk) return;
    firedBreakIds.current.add(brk.id);
    scheduleBreak(brk);
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [g.elapsed]);


  // Wire game events to moment classifier
  useEffect(() => {
    const lastEvent = g.feed.find(f => f.type === 'game');
    if (lastEvent && lastEvent.id !== lastEventIdRef.current) {
      lastEventIdRef.current = lastEvent.id;
    }
  }, [g.feed]);

  const lastEventIdRef = useRef<string | null>(null);

  const onTabClick = (t: TabKey) => {
    setTab(t);
    setTabUserInteracted(true);
    profileEngine.recordTabVisit(t);
    setTimeout(() => setTabUserInteracted(false), 30000);
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
    setTabUserInteracted(true);
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



  return (
    <div style={{ display: 'flex', flexDirection: 'row', alignItems: 'flex-start', gap: '2.5rem', padding: '0 0 4rem', justifyContent: 'center', flexWrap: 'wrap' }}>

      {/* ── iPhone App Preview ─────────────────────────────────────────────── */}
      <IPhoneFrame points={g.points}>
      <div
        onClick={() => {
          if (videoRef.current) {
            videoRef.current.muted = false;
            videoRef.current.volume = 1.0;
            videoRef.current.play().catch(()=>{});
          }
        }}
        style={{ flex: 1, display: 'flex', flexDirection: 'column', background: T.bg, overflow: 'hidden', fontFamily: 'Inter, system-ui, sans-serif', position: 'relative' }}
      >


      {/* ══ TOP 45%: Video ══════════════════════ */}
      <div style={{ flex: '0 0 45%', position: 'relative', background: '#000', overflow: 'hidden' }}>

        {/* Top screen: NFL video ONLY — ads never appear here */}
        <video
          ref={videoRef}
          src={VIDEO_URL}
          autoPlay
          playsInline
          loop
          muted
          style={{ width: '100%', height: '100%', objectFit: 'cover' }}
        />


        {/* ArenzaTV logo — network branding watermark */}
        <div style={{ position: 'absolute', top: 0, left: 0, padding: '20px 0 0 10px', pointerEvents: 'none', zIndex: 31 }}>
          <img src="/arenza-logo-real.png" alt="ArenzaTV" style={{ height: 40, objectFit: 'contain' }} />
        </div>









        {/* Flypoints */}
        {g.flyPoints && (
          <div style={{ position: 'absolute', top: '40%', left: '50%', transform: 'translateX(-50%)', fontFamily: 'Bebas Neue, sans-serif', fontSize: 32, color: T.gold, textShadow: `0 0 16px ${T.gold}`, animation: 'flyUp 1.5s ease forwards', pointerEvents: 'none', zIndex: 99 }}>{g.flyPoints}</div>
        )}

        {/* Fullscreen toggle */}
        <button onClick={toggleFullscreen} style={{ position: 'absolute', bottom: 10, right: 10, width: 32, height: 32, borderRadius: '50%', background: 'rgba(0,0,0,0.6)', border: '1px solid rgba(255,255,255,0.2)', color: '#fff', fontSize: 14, cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 36 }}>
          {isFullscreen ? '⤡' : '⤢'}
        </button>

        {/* Glowing bottom divider — always visible, TV never interrupted */}
        <div style={{ position: 'absolute', bottom: 0, left: 0, right: 0, height: 1, background: `linear-gradient(to right, transparent, ${T.orange}66, transparent)` }} />
      </div>

      {/* ══ BOTTOM: Ad Zone (L-band) or Interactive Tabs ══════════════════ */}
      <div style={{ flex: '1 1 55%', display: 'flex', flexDirection: 'column', overflow: 'hidden' }}>

        {/* Share toast */}
        {shareToast && (
          <div style={{ position: 'fixed', top: 70, left: '50%', transform: 'translateX(-50%)', background: T.green, color: '#fff', padding: '8px 18px', borderRadius: 999, fontSize: 13, fontWeight: 700, zIndex: 999 }}>
            🔗 Link copied!
          </div>
        )}

        {/* ── INLINE AD UNIT (website-style, bottom zone only) ────────────── */}
        {currentAdBreak ? (
          <div style={{ flex: 1, display: 'flex', flexDirection: 'column', overflow: 'hidden', background: T.bg }}>

            {/* Ad header bar */}
            <div style={{ display: 'flex', alignItems: 'center', gap: 8, padding: '6px 14px 4px', background: T.surface, borderBottom: `1px solid ${T.border}` }}>
              <div style={{ width: 6, height: 6, borderRadius: '50%', background: '#ff4444', animation: 'pulse 1.2s infinite', flexShrink: 0 }} />
              <span style={{ fontSize: 9, fontWeight: 800, color: 'rgba(255,255,255,0.6)', letterSpacing: '0.12em', textTransform: 'uppercase' }}>
                Sponsored Ad
              </span>
              <span style={{ marginLeft: 'auto', fontSize: 9, color: T.muted }}>
                ${currentAdBreak.cpm} CPM · {currentAdBreak.durationSec}s
              </span>
            </div>

            {/* Progress bar */}
            <div style={{ height: 3, background: 'rgba(255,255,255,0.08)' }}>
              <div style={{ height: '100%', width: `${adProgress}%`, background: currentAdBreak.color, transition: 'width 0.25s linear' }} />
            </div>

            {/* Ad video player — centered in bottom zone */}
            <div style={{ flex: 1, display: 'flex', flexDirection: 'column', overflow: 'hidden', position: 'relative' }}>
              <video
                ref={adVideoRef}
                key={currentAdBreak.id}
                src={currentAdBreak.videoUrl}
                playsInline
                muted
                controls={false}
                style={{ width: '100%', flex: 1, objectFit: 'contain', background: '#000', display: 'block' }}
              />

              {/* PoD verified overlay — appears for 2s after ad ends */}
              {podToast && (
                <div style={{
                  position: 'absolute', inset: 0, zIndex: 20,
                  display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center',
                  background: 'rgba(0,0,0,0.82)', backdropFilter: 'blur(6px)',
                  animation: 'fadeIn 0.3s ease',
                }}>
                  <div style={{ fontSize: 36, marginBottom: 8 }}>✅</div>
                  <div style={{ fontSize: 14, fontWeight: 800, color: '#22c55e', marginBottom: 6 }}>Proof-of-Delivery Verified</div>
                  <div style={{ fontSize: 11, color: 'rgba(255,255,255,0.7)', marginBottom: 4 }}>{podToast.brand} · ${podToast.cpm} CPM</div>
                  <div style={{ fontSize: 9, fontFamily: 'JetBrains Mono, monospace', color: '#00c9b1', letterSpacing: '0.05em' }}>{podToast.txHash}</div>
                  <div style={{ marginTop: 10, fontSize: 9, color: T.muted }}>+10 Arenza Points earned</div>
                </div>
              )}
            </div>

            {/* Brand info card + CTA button */}
            <div style={{ padding: '8px 14px 12px', background: T.surface, borderTop: `1px solid ${T.border}` }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 10 }}>
                <div style={{ width: 36, height: 36, borderRadius: 8, background: `${currentAdBreak.color}22`, border: `1px solid ${currentAdBreak.color}44`, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 20, flexShrink: 0 }}>
                  {currentAdBreak.emoji}
                </div>
                <div style={{ flex: 1 }}>
                  <div style={{ fontSize: 13, fontWeight: 800, color: T.text }}>{currentAdBreak.brand}</div>
                  <div style={{ fontSize: 10, color: T.muted }}>{currentAdBreak.tagline}</div>
                </div>
                <div style={{ textAlign: 'right', fontSize: 9, color: T.faint }}>
                  <div>📍 Personalized for you</div>
                  <div style={{ color: T.muted }}>{profile.tier} · {profile.tierMeta.label}</div>
                </div>
              </div>

              {/* ── 3-Button Ad Card CTA ─────────────────────────────────────── */}
              {/* Button layout: [🎟 Claim Offer] [🍽 See Menu] [🛒 Order Now] */}
              <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>

                {/* Offer headline (from AI coupon engine) */}
                {currentAdBreak.offerHeadline && (
                  <div style={{
                    background: `${currentAdBreak.color}18`,
                    border: `1px solid ${currentAdBreak.color}44`,
                    borderRadius: 8, padding: '6px 10px',
                    display: 'flex', alignItems: 'center', gap: 8,
                  }}>
                    <span style={{ fontSize: 14 }}>🎁</span>
                    <div>
                      <div style={{ fontSize: 11, fontWeight: 700, color: T.text }}>{currentAdBreak.offerHeadline}</div>
                      {currentAdBreak.offerValue && (
                        <div style={{ fontSize: 9, color: T.muted }}>{currentAdBreak.offerValue} · Tap Claim to save to Wallet</div>
                      )}
                    </div>
                  </div>
                )}

                {/* Row of 3 CTA buttons */}
                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: 6 }}>

                  {/* Button 1 — Claim Coupon */}
                  <button
                    onClick={() => handleAdCouponClaim(currentAdBreak)}
                    style={{
                      padding: '9px 4px', borderRadius: 10, border: 'none', cursor: 'pointer',
                      background: claimedCoupons.find(c => c.businessName === currentAdBreak.brand)
                        ? `${T.green}22` : `linear-gradient(135deg, ${currentAdBreak.color}, ${currentAdBreak.color}bb)`,
                      color: '#fff', fontWeight: 800, fontSize: 10,
                      boxShadow: `0 3px 12px ${currentAdBreak.color}44`,
                      transition: 'all 0.15s', display: 'flex', flexDirection: 'column',
                      alignItems: 'center', gap: 2,
                    }}
                  >
                    <span style={{ fontSize: 16 }}>{claimedCoupons.find(c => c.businessName === currentAdBreak.brand) ? '✅' : '🎟'}</span>
                    <span>{claimedCoupons.find(c => c.businessName === currentAdBreak.brand) ? 'Claimed' : 'Claim'}</span>
                  </button>

                  {/* Button 2 — Join Club */}
                  <button
                    onClick={() => handleAdJoinClub(currentAdBreak)}
                    style={{
                      padding: '9px 4px', borderRadius: 10, cursor: 'pointer',
                      background: joinedClubs.find(c => c.businessName === currentAdBreak.brand)
                        ? `${T.teal}22` : T.surface2,
                      border: `1px solid ${joinedClubs.find(c => c.businessName === currentAdBreak.brand) ? T.teal : T.border}`,
                      color: joinedClubs.find(c => c.businessName === currentAdBreak.brand) ? T.teal : T.muted,
                      fontWeight: 800, fontSize: 10, transition: 'all 0.15s',
                      display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 2,
                    }}
                  >
                    <span style={{ fontSize: 16 }}>{joinedClubs.find(c => c.businessName === currentAdBreak.brand) ? '⭐' : '🤝'}</span>
                    <span>{joinedClubs.find(c => c.businessName === currentAdBreak.brand) ? 'Member' : 'Join'}</span>
                  </button>

                  {/* Button 3 — Order / Visit */}
                  <a
                    href={currentAdBreak.orderUrl ?? currentAdBreak.websiteUrl ?? '#'}
                    target="_blank" rel="noopener noreferrer"
                    onClick={() => profileEngine.recordAdInteraction()}
                    style={{
                      padding: '9px 4px', borderRadius: 10, cursor: 'pointer',
                      background: T.surface2, border: `1px solid ${T.border}`,
                      color: T.muted, fontWeight: 800, fontSize: 10,
                      textDecoration: 'none', transition: 'all 0.15s',
                      display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 2,
                    }}
                  >
                    <span style={{ fontSize: 16 }}>🛒</span>
                    <span>Order</span>
                  </a>
                </div>
              </div>
            </div>
          </div>
        ) : (
          /* ── INTERACTIVE TABS (shown when no ad is playing) ─────────────── */
          <>
            <div style={{ flex: 1, overflowY: 'auto', padding: '10px 14px' }}>
              {tab === 'predict'  && <WebPredictionAd g={g} onInteract={() => { setTabUserInteracted(true); }} onPredictionPick={(correct: boolean) => profileEngine.recordPredictionPick(correct)} />}
              {tab === 'bingo'    && <WebBingoAd g={g} onInteract={() => { setTabUserInteracted(true); profileEngine.recordBingoMark(g.bingoLines); }} />}
              {tab === 'scratch'  && <WebScratchAd scratchRevealed={scratchRevealed} revealScratch={revealScratch} couponCode={couponCode} copied={copied} setCopied={setCopied} onInteract={(win: boolean) => { setTabUserInteracted(true); profileEngine.recordScratch(win); }} />}
              {tab === 'moreless' && <WebMoreLessAd mlPlayers={mlPlayers} mlPicks={mlPicks} setMlPicks={setMlPicks} mlSubmitted={mlSubmitted} setMlSubmitted={setMlSubmitted} mlMaxWin={mlMaxWin} mlMultiplier={mlMultiplier} onInteract={() => { setTabUserInteracted(true); profileEngine.recordMlSubmit(); profileEngine.recordBettingTap(); }} />}
              {tab === 'market'   && <MarketplaceTab onCouponClaim={handleCouponClaim} onJoinClub={handleJoinClub} />}
              {tab === 'wallet'   && <WalletTab points={g.points} claimedCoupons={claimedCoupons} joinedClubs={joinedClubs} />}
              {tab === 'board'    && <LeaderboardTab userPoints={g.points} />}
              {tab === 'me'       && <ProfileTab profile={profile} />}
              {tab === 'ads'      && <AdsHistoryTab adHistory={adHistory} adsServed={adsServed} revenue={totalRevenue} currentMoment={moment} />}
            </div>
          </>
        )}

        {/* Tab bar — ALWAYS visible, even during ad playback */}
        <IOSTabBar
          active={tab}
          onChange={onTabClick}
          walletBadge={claimedCoupons.length + joinedClubs.length}
        />

      </div>

      {/* ── Onboarding overlay ─────────────────────────────────────────────── */}
      {showOnboarding && (
        <OnboardingFlow onComplete={(p) => {
          setOnboardingProfile(p);
          setShowOnboarding(false);
        }} />
      )}

      {/* ── Post-game recap overlay ────────────────────────────────────────── */}
      {showRecap && (
        <div style={{
          position: 'fixed', inset: 0, zIndex: 190, background: 'rgba(0,0,0,0.85)',
          backdropFilter: 'blur(8px)', display: 'flex', flexDirection: 'column',
          alignItems: 'center', justifyContent: 'center', padding: 16,
        }}>
          <div style={{ width: '100%', maxWidth: 390, maxHeight: '90vh', overflowY: 'auto',
            background: T.surface, border: `1px solid ${T.border}`, borderRadius: 20 }}>
            <PostGameRecap
              points={g.points}
              correctPredictions={correctPredictions}
              totalPredictions={totalPredictions}
              adsWatched={adHistory.length}
              couponsClaimedCount={claimedCoupons.length}
              homeScore={g.homeScore}
              awayScore={g.awayScore}
              onClose={() => setShowRecap(false)}
            />
          </div>
        </div>
      )}

      {/* ── Coupon claim toast ─────────────────────────────────────────────── */}
      {couponClaimToast && (
        <div style={{
          position: 'fixed', bottom: 90, left: '50%', transform: 'translateX(-50%)',
          background: `linear-gradient(135deg, ${T.orange}, ${T.gold})`,
          color: '#fff', borderRadius: 14, padding: '12px 18px', zIndex: 300,
          fontFamily: 'Inter, system-ui, sans-serif', boxShadow: `0 8px 32px ${T.orange}66`,
          display: 'flex', alignItems: 'center', gap: 10, whiteSpace: 'nowrap',
          animation: 'slideIn 0.3s ease',
        }}>
          <span style={{ fontSize: 22 }}>🎟</span>
          <div>
            <div style={{ fontWeight: 800, fontSize: 13 }}>Coupon Saved to Wallet!</div>
            <div style={{ fontSize: 10, opacity: 0.85 }}>{couponClaimToast.offer} — {couponClaimToast.brand}</div>
          </div>
        </div>
      )}

      {/* ── Wallet join toast ──────────────────────────────────────────────── */}
      {walletToast && (
        <div style={{
          position: 'fixed', bottom: 90, left: '50%', transform: 'translateX(-50%)',
          background: `linear-gradient(135deg, ${T.teal}, #00a896)`,
          color: '#fff', borderRadius: 14, padding: '12px 18px', zIndex: 300,
          fontFamily: 'Inter, system-ui, sans-serif', boxShadow: `0 8px 32px ${T.teal}66`,
          display: 'flex', alignItems: 'center', gap: 10, whiteSpace: 'nowrap',
          animation: 'slideIn 0.3s ease',
        }}>
          <span style={{ fontSize: 22 }}>🤝</span>
          <div style={{ fontWeight: 800, fontSize: 13 }}>{walletToast}</div>
        </div>
      )}

      {/* TV commercial simulation lives in the video container above */}

      <style>{`
        @import url('https://fonts.googleapis.com/css2?family=Bebas+Neue&family=Inter:wght@400;600;700&family=JetBrains+Mono:wght@400;600&display=swap');
        @keyframes pulse { 0%,100%{opacity:1} 50%{opacity:0.4} }
        @keyframes flyUp { 0%{opacity:1;transform:translateX(-50%) translateY(0) scale(1)} 100%{opacity:0;transform:translateX(-50%) translateY(-60px) scale(1.4)} }
        @keyframes slideIn { from{opacity:0;transform:translateY(6px)} to{opacity:1;transform:translateY(0)} }
        @keyframes fadeIn { from{opacity:0} to{opacity:1} }
      `}</style>
    </div>
    </IPhoneFrame>

      {/* ── CTA Side Panel ─────────────────────────────────────────────────── */}
      <div style={{ display: 'flex', flexDirection: 'column', gap: '1.25rem', maxWidth: 340, width: '100%', alignSelf: 'center' }}>

        {/* Try on your iPhone */}
        <div style={{ background: 'rgba(20,26,40,0.9)', border: '1px solid rgba(0,201,177,0.3)', borderRadius: 20, padding: '1.75rem', boxShadow: '0 8px 32px rgba(0,201,177,0.08)' }}>
          <div style={{ fontSize: 28, marginBottom: '0.75rem' }}>📲</div>
          <div style={{ fontSize: '1.05rem', fontWeight: 800, color: '#e2e8f0', marginBottom: '0.6rem', lineHeight: 1.3 }}>
            Experience It on Your iPhone
          </div>
          <div style={{ fontSize: '0.85rem', color: '#8892b0', lineHeight: 1.6, marginBottom: '1.1rem' }}>
            Want to try the real Arenza app on your own device? Send us your Apple ID (email address) and we&apos;ll add you to our TestFlight beta — complete with installation instructions.
          </div>
          <a
            href="mailto:eric@arenza.tv?subject=TestFlight%20Access%20Request&body=Hi%2C%20I'd%20like%20to%20test%20the%20Arenza%20app%20on%20my%20iPhone.%20My%20Apple%20ID%20is%3A%20"
            style={{ display: 'block', background: 'linear-gradient(135deg, #00c9b1, #00a896)', color: '#000', fontWeight: 800, fontSize: '0.88rem', padding: '0.75rem 1.25rem', borderRadius: 12, textDecoration: 'none', textAlign: 'center', letterSpacing: '0.02em' }}
          >
            Request TestFlight Access →
          </a>
          <div style={{ fontSize: '0.75rem', color: '#4a5568', marginTop: '0.75rem', textAlign: 'center' }}>
            eric@arenza.tv · iOS only · Free beta
          </div>
        </div>

        {/* General contact */}
        <div style={{ background: 'rgba(20,26,40,0.9)', border: '1px solid rgba(139,92,246,0.3)', borderRadius: 20, padding: '1.75rem', boxShadow: '0 8px 32px rgba(139,92,246,0.06)' }}>
          <div style={{ fontSize: 28, marginBottom: '0.75rem' }}>💬</div>
          <div style={{ fontSize: '1.05rem', fontWeight: 800, color: '#e2e8f0', marginBottom: '0.6rem', lineHeight: 1.3 }}>
            Questions & Investment Inquiries
          </div>
          <div style={{ fontSize: '0.85rem', color: '#8892b0', lineHeight: 1.6, marginBottom: '1.1rem' }}>
            Have questions, product suggestions, or interested in investing in Arenza? We&apos;d love to hear from you.
          </div>
          <a
            href="mailto:eric@arenza.tv?subject=Arenza%20Inquiry"
            style={{ display: 'block', background: 'linear-gradient(135deg, #7c3aed, #6d28d9)', color: '#fff', fontWeight: 800, fontSize: '0.88rem', padding: '0.75rem 1.25rem', borderRadius: 12, textDecoration: 'none', textAlign: 'center', letterSpacing: '0.02em' }}
          >
            Get in Touch →
          </a>
          <div style={{ fontSize: '0.75rem', color: '#4a5568', marginTop: '0.75rem', textAlign: 'center' }}>
            eric@arenza.tv
          </div>
        </div>

      </div>

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

// Old ProfileTab removed — replaced by AI-powered ProfileTab at bottom of file

// ── Web Ad Card: Prediction ─────────────────────────────────────────────────────
function WebPredictionAd({ g, onInteract, onPredictionPick }: { g: any; onInteract: () => void; onPredictionPick?: (correct: boolean) => void }) {
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
        /* ── Waiting state: fill the space while next prediction loads ── */
        <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>

          {/* Incoming alert */}
          <div style={{
            display: 'flex', alignItems: 'center', gap: 10,
            background: `${T.teal}11`, border: `1px solid ${T.teal}33`,
            borderRadius: 12, padding: '12px 14px',
          }}>
            <div style={{ fontSize: 28, animation: 'pulse 1.4s infinite' }}>🔮</div>
            <div>
              <div style={{ fontSize: 13, fontWeight: 800, color: T.teal }}>Next Prediction Incoming</div>
              <div style={{ fontSize: 10, color: T.muted }}>Get ready — question drops any moment</div>
              <div style={{ fontSize: 9, color: T.faint, marginTop: 2 }}>🥤 Sponsored by Pepsi</div>
            </div>
            <div style={{ marginLeft: 'auto', display: 'flex', gap: 4 }}>
              {[0,1,2].map(i => (
                <div key={i} style={{
                  width: 6, height: 6, borderRadius: '50%', background: T.teal,
                  opacity: 0.3 + i * 0.35,
                  animation: `pulse ${0.8 + i * 0.2}s infinite`,
                }} />
              ))}
            </div>
          </div>

          {/* Live scoreboard */}
          <div style={{ background: T.surface, border: `1px solid ${T.border}`, borderRadius: 12, padding: '10px 14px' }}>
            <div style={{ fontSize: 9, color: T.muted, textTransform: 'uppercase', letterSpacing: '0.08em', marginBottom: 8 }}>Live Score</div>
            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
              <div style={{ textAlign: 'center' }}>
                <div style={{ fontSize: 18 }}>🦅</div>
                <div style={{ fontSize: 11, fontWeight: 800, color: T.text }}>Eagles</div>
                <div style={{ fontSize: 22, fontWeight: 900, color: T.orange, fontFamily: 'Bebas Neue, sans-serif' }}>{g.score?.home ?? 7}</div>
              </div>
              <div style={{ textAlign: 'center' }}>
                <div style={{ fontSize: 10, color: T.muted, marginBottom: 2 }}>Q{g.quarter} · {g.clock}</div>
                <div style={{ fontSize: 12, fontWeight: 700, color: T.faint }}>VS</div>
                <div style={{ fontSize: 10, color: T.faint, marginTop: 2 }}>2nd & 4</div>
              </div>
              <div style={{ textAlign: 'center' }}>
                <div style={{ fontSize: 18 }}>🐻</div>
                <div style={{ fontSize: 11, fontWeight: 800, color: T.text }}>Bears</div>
                <div style={{ fontSize: 22, fontWeight: 900, color: T.teal, fontFamily: 'Bebas Neue, sans-serif' }}>{g.score?.away ?? 10}</div>
              </div>
            </div>
          </div>

          {/* Your prediction stats */}
          <div style={{ background: T.surface, border: `1px solid ${T.border}`, borderRadius: 12, padding: '10px 14px' }}>
            <div style={{ fontSize: 9, color: T.muted, textTransform: 'uppercase', letterSpacing: '0.08em', marginBottom: 8 }}>Your Picks This Game</div>
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: 6 }}>
              {[
                { label: 'Picks Made', value: g.totalPredictions ?? 0, emoji: '🎯', color: T.orange },
                { label: 'Correct',    value: g.correctPredictions ?? 0, emoji: '✅', color: T.green },
                { label: 'Pts Earned', value: g.points ?? 0, emoji: '🏆', color: T.gold },
              ].map(stat => (
                <div key={stat.label} style={{
                  background: T.surface2, borderRadius: 8, padding: '8px 6px', textAlign: 'center',
                }}>
                  <div style={{ fontSize: 16 }}>{stat.emoji}</div>
                  <div style={{ fontSize: 16, fontWeight: 900, color: stat.color, fontFamily: 'Bebas Neue, sans-serif', lineHeight: 1.1 }}>
                    {stat.value}
                  </div>
                  <div style={{ fontSize: 8, color: T.faint, marginTop: 2 }}>{stat.label}</div>
                </div>
              ))}
            </div>
          </div>

          {/* What to watch for */}
          <div style={{ background: T.surface, border: `1px solid ${T.border}`, borderRadius: 12, padding: '10px 14px' }}>
            <div style={{ fontSize: 9, color: T.muted, textTransform: 'uppercase', letterSpacing: '0.08em', marginBottom: 8 }}>📋 Watch For</div>
            {[
              { icon: '🏈', text: 'Eagles driving — watch for a TD or FG attempt' },
              { icon: '⚡', text: "Hurts has 2 rushing TDs this season in short-yardage" },
              { icon: '🛡', text: "Bears D allowing 24 pts/game — Eagles offense is hot" },
            ].map((tip, i) => (
              <div key={i} style={{ display: 'flex', gap: 8, alignItems: 'flex-start', marginBottom: i < 2 ? 8 : 0 }}>
                <span style={{ fontSize: 14, flexShrink: 0 }}>{tip.icon}</span>
                <span style={{ fontSize: 10, color: T.text, lineHeight: 1.4 }}>{tip.text}</span>
              </div>
            ))}
          </div>

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
        {(g.bingoBoard || []).map((cell: any, idx: number) => (
          <div key={idx} onClick={() => { g.markBingoCell?.(cell.id); onInteract(); }} style={{
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

// ── Ads History Tab (Moment-Aware) ──────────────────────────────────────────────
function AdsHistoryTab({ adHistory, adsServed, revenue, currentMoment }: {
  adHistory: {ad: AdCreative; txHash: string; verified: boolean; momentCode?: string; momentMultiplier?: number}[];
  adsServed: number; revenue: number; currentMoment: ActiveMoment;
}) {
  const momentAdjustedRevenue = adHistory.reduce((sum, e) => sum + (e.ad.cpm * (e.momentMultiplier ?? 1.0)) / 1000, 0);
  return (
    <div style={{ height:'100%', overflowY:'auto', padding:'8px 12px', display:'flex', flexDirection:'column', gap:8 }}>
      <div style={{ fontSize:11, fontWeight:700, color:T.orange, textTransform:'uppercase', letterSpacing:'.08em' }}>📺 Ad Delivery · PoD · Context</div>

      {/* Active moment banner */}
      <div style={{ padding:'8px 10px', background:`${currentMoment.meta.color}18`, border:`1px solid ${currentMoment.meta.color}44`, borderRadius:10, display:'flex', justifyContent:'space-between', alignItems:'center' }}>
        <div>
          <div style={{ fontSize:9, color:T.muted, letterSpacing:'0.06em', textTransform:'uppercase', marginBottom:2 }}>Live Game Moment</div>
          <div style={{ fontSize:11, fontWeight:700, color:currentMoment.meta.color }}>{currentMoment.meta.label}</div>
          <div style={{ fontSize:9, color:T.muted }}>{currentMoment.code}</div>
        </div>
        <div style={{ textAlign:'center' }}>
          <div style={{ fontFamily:'JetBrains Mono,monospace', fontSize:22, fontWeight:800, color:currentMoment.meta.color }}>{currentMoment.meta.multiplier}×</div>
          <div style={{ fontSize:9, color:T.muted }}>CPM Multiplier</div>
        </div>
      </div>

      {/* Session stats */}
      <div style={{ display:'grid', gridTemplateColumns:'repeat(3,1fr)', gap:6, textAlign:'center', padding:10, background:T.surface2, border:`1px solid ${T.border}`, borderRadius:10 }}>
        {[
          ['Ads', String(adsServed), T.orange],
          ['Base Rev', `$${revenue.toFixed(3)}`, T.green],
          ['Adj Rev', `$${momentAdjustedRevenue.toFixed(3)}`, T.teal],
        ].map(([l,v,c]) => (
          <div key={l as string}>
            <div style={{ fontFamily:'JetBrains Mono,monospace', fontSize:14, fontWeight:700, color:c as string }}>{v}</div>
            <div style={{ fontSize:9, color:T.muted }}>{l}</div>
          </div>
        ))}
      </div>

      {/* Receipt list */}
      {adHistory.length === 0 ? (
        <div style={{ flex:1, display:'flex', flexDirection:'column', alignItems:'center', justifyContent:'center', gap:6, color:T.muted }}>
          <div style={{ fontSize:24 }}>📺</div>
          <div style={{ fontSize:12 }}>No ads delivered yet</div>
          <div style={{ fontSize:10, color:T.faint }}>Ads will appear during the game</div>
        </div>
      ) : (
        adHistory.map((entry, i) => (
          <div key={i} style={{ padding:10, background:`${entry.ad.color}11`, border:`1px solid ${entry.ad.color}33`, borderRadius:10 }}>
            <div style={{ display:'flex', alignItems:'center', gap:8, marginBottom:4 }}>
              <span style={{ fontSize:18 }}>{entry.ad.emoji}</span>
              <div style={{ flex:1 }}>
                <div style={{ fontSize:12, fontWeight:700, color:T.text }}>{entry.ad.brand}</div>
                <div style={{ fontSize:10, color:entry.ad.color }}>${entry.ad.cpm} CPM base</div>
              </div>
              {entry.momentCode && (
                <div style={{ textAlign:'right' }}>
                  <div style={{ fontSize:9, color:T.muted }}>{entry.momentCode}</div>
                  <div style={{ fontSize:11, fontWeight:800, color:T.gold }}>{entry.momentMultiplier}×</div>
                </div>
              )}
              <span style={{ fontSize:10, color:T.green, fontWeight:700 }}>✅</span>
            </div>
            <div style={{ display:'flex', justifyContent:'space-between', marginBottom:3 }}>
              <span style={{ fontSize:9, color:T.muted }}>IVT Score</span>
              <span style={{ fontSize:9, fontWeight:700, color:T.green }}>0.03 ✅ Clean</span>
            </div>
            <div style={{ fontSize:9, color:T.muted, fontFamily:'JetBrains Mono,monospace', wordBreak:'break-all' }}>
              PoD: {entry.txHash}
            </div>
          </div>
        ))
      )}
    </div>
  );
}

// ── AI-Powered Profile Tab ───────────────────────────────────────────────────────
import type { ViewerProfile } from './lib/useProfileEngine';

function ProfileTab({ profile }: { profile: ViewerProfile }) {
  const churnColor = profile.churnRisk > 0.6 ? T.red : profile.churnRisk > 0.4 ? T.gold : T.green;
  const churnLabel = profile.churnRisk > 0.6 ? 'High Risk' : profile.churnRisk > 0.4 ? 'Medium' : 'Low Risk';

  return (
    <div style={{ height:'100%', overflowY:'auto', display:'flex', flexDirection:'column', gap:10 }}>
      <div style={{ fontSize:11, fontWeight:700, color:T.orange, textTransform:'uppercase', letterSpacing:'.08em' }}>🤖 AI Viewer Profile</div>

      {/* Tier card */}
      <div style={{ padding:12, background:`${profile.tierMeta.color}18`, border:`2px solid ${profile.tierMeta.color}55`, borderRadius:14, display:'flex', justifyContent:'space-between', alignItems:'center' }}>
        <div>
          <div style={{ fontSize:9, color:T.muted, letterSpacing:'0.06em', textTransform:'uppercase', marginBottom:2 }}>Audience Segment</div>
          <div style={{ fontSize:22, fontWeight:900, color:profile.tierMeta.color }}>{profile.tier}</div>
          <div style={{ fontSize:12, fontWeight:700, color:T.text }}>{profile.tierMeta.label}</div>
          <div style={{ fontSize:9, color:T.muted, marginTop:2 }}>{profile.tierMeta.description}</div>
        </div>
        <div style={{ textAlign:'center' }}>
          <div style={{ fontSize:9, color:T.muted, marginBottom:2 }}>Live CPM</div>
          <div style={{ fontFamily:'JetBrains Mono,monospace', fontSize:26, fontWeight:900, color:T.gold }}>${profile.currentCPM}</div>
          <div style={{ fontSize:9, color:T.muted }}>${profile.tierMeta.cpmMin}–${profile.tierMeta.cpmMax} range</div>
        </div>
      </div>

      {/* Engagement score */}
      <div style={{ padding:10, background:T.surface2, border:`1px solid ${T.border}`, borderRadius:10 }}>
        <div style={{ display:'flex', justifyContent:'space-between', marginBottom:6 }}>
          <span style={{ fontSize:10, fontWeight:600, color:T.text }}>Engagement Score</span>
          <span style={{ fontFamily:'JetBrains Mono,monospace', fontSize:14, fontWeight:800, color:profile.tierMeta.color }}>{profile.engagementScore}/100</span>
        </div>
        <div style={{ height:8, background:T.border, borderRadius:99 }}>
          <div style={{ height:'100%', width:`${profile.engagementScore}%`, background:`linear-gradient(to right, ${profile.tierMeta.color}88, ${profile.tierMeta.color})`, borderRadius:99, transition:'width 0.8s ease' }} />
        </div>
        <div style={{ display:'grid', gridTemplateColumns:'repeat(4,1fr)', gap:4, marginTop:8, textAlign:'center' }}>
          {[['Preds', profile.signals.predictionsPlayed],['Bingo', profile.signals.bingoTilesMarked],['Scratch', profile.signals.scratchesRevealed],['Ads', profile.signals.adsWatched]].map(([l,v]) => (
            <div key={l as string} style={{ background:T.surface, borderRadius:6, padding:'4px 0' }}>
              <div style={{ fontSize:14, fontWeight:800, color:T.text }}>{v}</div>
              <div style={{ fontSize:8, color:T.faint }}>{l}</div>
            </div>
          ))}
        </div>
      </div>

      {/* Sport affinities */}
      <div style={{ padding:10, background:T.surface2, border:`1px solid ${T.border}`, borderRadius:10 }}>
        <div style={{ fontSize:9, fontWeight:700, color:T.muted, textTransform:'uppercase', letterSpacing:'0.06em', marginBottom:8 }}>Sport Affinities</div>
        {Object.entries(profile.sportAffinities).map(([sport, val]) => (
          <div key={sport} style={{ marginBottom:6 }}>
            <div style={{ display:'flex', justifyContent:'space-between', marginBottom:3 }}>
              <span style={{ fontSize:10, color:T.text }}>{sport}</span>
              <span style={{ fontSize:10, fontWeight:700, color:T.teal }}>{Math.round((val as number) * 100)}%</span>
            </div>
            <div style={{ height:4, background:T.border, borderRadius:99 }}>
              <div style={{ height:'100%', width:`${(val as number) * 100}%`, background:T.teal, borderRadius:99, transition:'width 0.6s ease' }} />
            </div>
          </div>
        ))}
      </div>

      {/* Churn risk */}
      <div style={{ padding:10, background:T.surface2, border:`1px solid ${churnColor}44`, borderRadius:10, display:'flex', justifyContent:'space-between', alignItems:'center' }}>
        <div>
          <div style={{ fontSize:9, color:T.muted, textTransform:'uppercase', letterSpacing:'0.06em', marginBottom:2 }}>30-Day Churn Risk</div>
          <div style={{ fontSize:14, fontWeight:800, color:churnColor }}>{churnLabel}</div>
          <div style={{ fontSize:9, color:T.muted }}>Score: {(profile.churnRisk * 100).toFixed(0)}%</div>
        </div>
        <div style={{ width:46, height:46, borderRadius:'50%', border:`3px solid ${churnColor}`, display:'flex', alignItems:'center', justifyContent:'center' }}>
          <span style={{ fontSize:18 }}>{profile.churnRisk < 0.4 ? '😄' : profile.churnRisk < 0.6 ? '😐' : '😟'}</span>
        </div>
      </div>

      {/* Signals collected */}
      <div style={{ padding:10, background:T.surface2, border:`1px solid ${T.border}`, borderRadius:10 }}>
        <div style={{ fontSize:9, color:T.muted, textTransform:'uppercase', letterSpacing:'0.06em', marginBottom:6 }}>Zero-Party Signal Collection</div>
        <div style={{ display:'flex', flexWrap:'wrap', gap:4 }}>
          {profile.signals.tabsVisited.map(t => (
            <span key={t} style={{ background:`${T.orange}22`, border:`1px solid ${T.orange}44`, borderRadius:99, padding:'2px 8px', fontSize:9, color:T.orange, fontWeight:600 }}>{t}</span>
          ))}
          {profile.signals.tabsVisited.length === 0 && <span style={{ fontSize:9, color:T.faint }}>Interact with tabs to collect signals</span>}
        </div>
      </div>
    </div>
  );
}

