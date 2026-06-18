/**
 * features.ts — Shared ViewerFeatureVector
 * TypeScript mirror of iOS ViewerFeatureVector struct.
 * Used by: web useProfileEngine, API segmenter, XGBoost training script.
 *
 * All fields must match train_segmenter.py FEATURES list and
 * iOS SignalCollector.buildFeatureVector() output.
 */

export interface ViewerFeatureVector {
  // ── Watch behaviour ───────────────────────────────────────────────
  /** Cumulative hours watched (all sessions) */
  totalWatchTimeHours: number;
  /** Average minutes per session */
  avgSessionDurationMinutes: number;
  /** Sessions per week (rolling 4-week avg) */
  sessionFrequencyPerWeek: number;
  /** Live content ratio (0–1). iOS: liveVsVODRatio */
  liveVsVODRatio: number;
  /** Number of distinct sports watched */
  uniqueSportsWatched: number;
  /** Days since account created / first session */
  daysSinceFirstSession: number;

  // ── Ad engagement ─────────────────────────────────────────────────
  /** Ratio of ads watched to completion (0–1) */
  adCompletionRate: number;
  /** Ratio of ads interacted with (click/tap) vs served (0–1) */
  adEngagementRate: number;
  /** Ratio of ads skipped when skip was available (0–1) */
  skippedAdsRate: number;

  // ── Interactive engagement ────────────────────────────────────────
  /** Predictions answered / total predictions shown (0–1) */
  predictionParticipationRate: number;
  /** Bingo tiles marked (cumulative) */
  bingoTilesMarked: number;
  /** Scratch cards revealed (cumulative) */
  scratchesRevealed: number;
  /** ML (More/Less) pick submissions (cumulative) */
  mlPicksSubmitted: number;

  // ── Commerce & local intent signals ──────────────────────────────
  /** Taps on sponsor CTAs, coupon claims, marketplace items */
  commerceInteractionCount: number;
  /** Taps on betting / prediction odds overlays */
  bettingOverlayTaps: number;

  // ── Sport affinity map ────────────────────────────────────────────
  /** Normalised affinity per sport key (0–1). e.g. { "football": 0.9 } */
  sportAffinities: Record<string, number>;
}

/**
 * Compute a composite engagement score (0–100) from the feature vector.
 * Mirrors useProfileEngine.ts computeEngagementScore() and
 * is used by the XGBoost training script as a synthetic label.
 */
export function computeEngagementScore(f: ViewerFeatureVector): number {
  let score = 0;

  // Watch depth (max 25)
  score += Math.min(f.totalWatchTimeHours * 0.5, 15);
  score += Math.min(f.sessionFrequencyPerWeek * 2, 10);

  // Ad engagement (max 20)
  score += f.adCompletionRate * 12;
  score += f.adEngagementRate * 8;

  // Interactive engagement (max 30)
  score += f.predictionParticipationRate * 15;
  score += Math.min(f.bingoTilesMarked * 1.5, 8);
  score += Math.min(f.scratchesRevealed * 1.2, 4);
  score += Math.min(f.mlPicksSubmitted * 1.5, 3);

  // Commerce & local intent (max 15)
  score += Math.min(f.commerceInteractionCount * 3, 10);
  score += Math.min(f.bettingOverlayTaps * 2.5, 5);

  // Live content bonus (max 10)
  score += f.liveVsVODRatio * 10;

  return Math.min(100, Math.round(score));
}

/** Default empty feature vector — used for new viewers */
export const EMPTY_FEATURE_VECTOR: ViewerFeatureVector = {
  totalWatchTimeHours: 0,
  avgSessionDurationMinutes: 0,
  sessionFrequencyPerWeek: 0,
  liveVsVODRatio: 1.0,    // assume live viewer by default
  uniqueSportsWatched: 1,
  daysSinceFirstSession: 0,
  adCompletionRate: 0,
  adEngagementRate: 0,
  skippedAdsRate: 0,
  predictionParticipationRate: 0,
  bingoTilesMarked: 0,
  scratchesRevealed: 0,
  mlPicksSubmitted: 0,
  commerceInteractionCount: 0,
  bettingOverlayTaps: 0,
  sportAffinities: {},
};
