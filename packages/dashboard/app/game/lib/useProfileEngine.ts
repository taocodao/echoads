'use client';
/**
 * useProfileEngine.ts — Web Simulator Profile Engine (Phase 1.3)
 * Mirrors iOS ProfileEngine.swift using shared ViewerTier definitions.
 * Signals feed the 12-tier classifier, churn predictor, and sport affinity map.
 *
 * Shared types imported from @echoads/shared/ai/segments & features.
 * All field names match iOS ViewerFeatureVector for cross-platform parity.
 */
import { useState, useCallback, useRef, useEffect } from 'react';
import {
  type ViewerTier,
  type TierMeta,
  TIER_DEFINITIONS,
  classifyTier,
  computeCPM,
} from './sharedTypes';

// ── Signal Store (all counters in this session) ────────────────────────────────
// Field names align with iOS ViewerFeatureVector / SignalCollector

interface SessionSignals {
  // Prediction
  predictionsPlayed: number;
  predictionsCorrect: number;
  // Bingo
  bingoTilesMarked: number;
  bingoLinesCompleted: number;
  // Scratch & ML
  scratchesRevealed: number;
  scratchWins: number;
  mlPicksSubmitted: number;
  // Ads
  adsWatched: number;
  adInteractions: number;
  // Commerce / local intent (iOS: commerceInteractionCount)
  sponsorInteractions: number;
  // Betting overlay (iOS: bettingOverlayTaps)
  bettingOverlayTaps: number;
  // Navigation
  tabsVisited: Set<string>;
  // Session
  sessionElapsedSeconds: number;
  // Derived / enriched
  bingoLinesEver: number;   // cumulative for live-vs-VOD proxy
}

// ── Engagement Score ───────────────────────────────────────────────────────────

function computeEngagementScore(s: SessionSignals): number {
  let score = 0;
  // Predictions (max 30)
  score += Math.min(s.predictionsPlayed * 8, 20);
  if (s.predictionsPlayed > 0)
    score += (s.predictionsCorrect / s.predictionsPlayed) * 10;
  // Bingo (max 20)
  score += Math.min(s.bingoTilesMarked * 2, 12);
  score += Math.min(s.bingoLinesCompleted * 4, 8);
  // Scratch & ML (max 15)
  score += Math.min(s.scratchesRevealed * 3, 9);
  score += Math.min(s.mlPicksSubmitted * 3, 6);
  // Ads (max 15)
  score += Math.min(s.adsWatched * 4, 12);
  score += Math.min(s.adInteractions * 3, 3);
  // Tab variety (max 9)
  score += Math.min(s.tabsVisited.size * 1.5, 9);
  // Session time (max 11)
  score += Math.min(s.sessionElapsedSeconds / 8, 11);
  // Commerce / betting bonus (mirrors iOS RuleBasedViewerClassifier)
  score += Math.min(s.sponsorInteractions * 2, 6);
  score += Math.min(s.bettingOverlayTaps * 2, 4);
  return Math.min(100, Math.round(score));
}

// ── Churn Risk ─────────────────────────────────────────────────────────────────
// Mirrors iOS ChurnPredictor.predict()

function computeChurnRisk(s: SessionSignals): number {
  let risk = 0.55;
  if (s.predictionsPlayed > 0)   risk -= 0.15;
  if (s.bingoTilesMarked > 3)    risk -= 0.10;
  if (s.adsWatched > 1)          risk -= 0.10;
  if (s.mlPicksSubmitted > 0)    risk -= 0.08;
  if (s.tabsVisited.size > 2)    risk -= 0.07;
  if (s.sponsorInteractions > 0) risk -= 0.05;
  // Passive long session = possible churn signal
  if (s.sessionElapsedSeconds > 60 && s.predictionsPlayed === 0) risk += 0.12;
  return Math.max(0.02, Math.min(0.98, risk));
}

// ── Sport Affinities ───────────────────────────────────────────────────────────
// Mirrors iOS ProfileEngine.buildSportAffinities()

function computeAffinities(s: SessionSignals): Record<string, number> {
  const a: Record<string, number> = { Football: 0.5 };
  a.Football = Math.min(1, a.Football + s.predictionsPlayed * 0.07 +
    (s.bingoTilesMarked > 0 ? 0.1 : 0));
  if (s.sponsorInteractions > 0)
    a['Sports Commerce'] = Math.min(1, s.sponsorInteractions * 0.25);
  if (s.mlPicksSubmitted > 0)
    a['Player Stats']    = Math.min(1, s.mlPicksSubmitted * 0.18);
  if (s.adsWatched > 0)
    a['Live Sports']     = Math.min(1, 0.4 + s.adsWatched * 0.1);
  if (s.bettingOverlayTaps > 0)
    a['Betting']         = Math.min(1, s.bettingOverlayTaps * 0.15);
  return a;
}

// ── Differential Privacy (mirrors iOS DifferentialPrivacy helper) ──────────────

function addLaplaceNoise(value: number, scale: number = 0.05): number {
  const u = Math.random() - 0.5;
  const noise = -scale * Math.sign(u) * Math.log(1 - 2 * Math.abs(u));
  return Math.max(0, Math.min(1, value + noise));
}

// ── ViewerProfile shape ────────────────────────────────────────────────────────

export interface ViewerProfile {
  tier: ViewerTier;
  tierMeta: TierMeta;
  engagementScore: number;                // 0–100
  sportAffinities: Record<string, number>;
  churnRisk: number;                      // 0–1
  currentCPM: number;
  /** viewerScore maps to iOS ProfileEngine.viewerScore (0.0–1.0) */
  viewerScore: number;
  signals: Omit<SessionSignals, 'tabsVisited'> & { tabsVisited: string[] };
}

// ── Hook ───────────────────────────────────────────────────────────────────────

export function useProfileEngine(elapsed: number) {
  const sig = useRef<SessionSignals>({
    predictionsPlayed: 0, predictionsCorrect: 0,
    bingoTilesMarked: 0,  bingoLinesCompleted: 0,
    scratchesRevealed: 0, scratchWins: 0,
    mlPicksSubmitted: 0,  adsWatched: 0,
    adInteractions: 0,    sponsorInteractions: 0,
    bettingOverlayTaps: 0,
    tabsVisited: new Set<string>(),
    sessionElapsedSeconds: 0,
    bingoLinesEver: 0,
  });

  const [profile, setProfile] = useState<ViewerProfile>(() => build(sig.current));

  function build(s: SessionSignals): ViewerProfile {
    const eng     = computeEngagementScore(s);
    const tier    = classifyTier(eng);
    const meta    = TIER_DEFINITIONS[tier];
    const cpm     = computeCPM(tier, eng);
    // viewerScore with Laplace noise (mirrors iOS differential privacy upload)
    const rawScore = meta.viewerScore;
    const viewerScore = addLaplaceNoise(rawScore, 0.03);
    return {
      tier, tierMeta: meta,
      engagementScore: eng,
      sportAffinities: computeAffinities(s),
      churnRisk: computeChurnRisk(s),
      currentCPM: cpm,
      viewerScore,
      signals: { ...s, tabsVisited: Array.from(s.tabsVisited) },
    };
  }

  const refresh = useCallback(() => setProfile(build(sig.current)), []);

  // Sync session elapsed each tick
  useEffect(() => {
    sig.current.sessionElapsedSeconds = elapsed;
    refresh();
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [elapsed]);

  // ── Public signal API ── matches iOS SignalCollector event methods ────────────

  const recordTabVisit = useCallback((tab: string) => {
    sig.current.tabsVisited.add(tab);
    refresh();
  }, [refresh]);

  const recordPredictionPick = useCallback((correct: boolean) => {
    sig.current.predictionsPlayed++;
    if (correct) sig.current.predictionsCorrect++;
    refresh();
  }, [refresh]);

  const recordBingoMark = useCallback((lines?: number) => {
    sig.current.bingoTilesMarked++;
    if (lines && lines > sig.current.bingoLinesCompleted) {
      sig.current.bingoLinesCompleted = lines;
      sig.current.bingoLinesEver = Math.max(sig.current.bingoLinesEver, lines);
    }
    refresh();
  }, [refresh]);

  const recordScratch = useCallback((win: boolean) => {
    sig.current.scratchesRevealed++;
    if (win) sig.current.scratchWins++;
    refresh();
  }, [refresh]);

  const recordMlSubmit = useCallback(() => {
    sig.current.mlPicksSubmitted++;
    refresh();
  }, [refresh]);

  const recordAdWatched = useCallback(() => {
    sig.current.adsWatched++;
    refresh();
  }, [refresh]);

  const recordAdInteraction = useCallback(() => {
    sig.current.adInteractions++;
    refresh();
  }, [refresh]);

  const recordSponsor = useCallback(() => {
    sig.current.sponsorInteractions++;
    refresh();
  }, [refresh]);

  /** iOS: bettingOverlayTaps — triggered when user taps More/Less odds */
  const recordBettingTap = useCallback(() => {
    sig.current.bettingOverlayTaps++;
    refresh();
  }, [refresh]);

  return {
    profile,
    recordTabVisit,
    recordPredictionPick,
    recordBingoMark,
    recordScratch,
    recordMlSubmit,
    recordAdWatched,
    recordAdInteraction,
    recordSponsor,
    recordBettingTap,
  };
}
