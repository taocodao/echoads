/**
 * segments.ts — Shared viewer segment definitions
 * Single source of truth for BOTH the web simulator and iOS app.
 * Web: imported into useProfileEngine.ts
 * iOS: mirrored in ViewerSegment.swift (same IDs, same CPM ranges)
 *
 * Naming: T1–T12 (numeric tiers) map 1-to-1 to SEG-01..SEG-12 on iOS.
 */

export type ViewerTier =
  | 'T1' | 'T2' | 'T3' | 'T4' | 'T5' | 'T6'
  | 'T7' | 'T8' | 'T9' | 'T10' | 'T11' | 'T12';

/** iOS: ViewerSegment enum rawValue matches segmentId */
export type SegmentId =
  | 'SEG-01' | 'SEG-02' | 'SEG-03' | 'SEG-04' | 'SEG-05' | 'SEG-06'
  | 'SEG-07' | 'SEG-08' | 'SEG-09' | 'SEG-10' | 'SEG-11' | 'SEG-12';

export interface TierMeta {
  /** Numeric tier label shown in UI */
  tier: ViewerTier;
  /** iOS segmentId — matches ViewerSegment.rawValue */
  segmentId: SegmentId;
  /** Human-readable segment name (matches iOS ViewerSegment.label) */
  label: string;
  /** Secondary description shown in profile tab */
  description: string;
  /** CPM floor for this tier (USD) */
  cpmMin: number;
  /** CPM ceiling for this tier (USD) */
  cpmMax: number;
  /** Hex color for UI rendering */
  color: string;
  /** Engagement score floor (0–100) */
  engagementMin: number;
  /** Engagement score ceiling (0–100) */
  engagementMax: number;
  /** Viewerscore equivalent on iOS (0.0–1.0) */
  viewerScore: number;
}

export const TIER_DEFINITIONS: Record<ViewerTier, TierMeta> = {
  T1:  {
    tier: 'T1', segmentId: 'SEG-01',
    label: 'Premium Sports Fanatic',
    description: 'Daily viewer, high engagement, ad interactor, prediction winner',
    cpmMin: 45, cpmMax: 50, color: '#ff6b35',
    engagementMin: 85, engagementMax: 100, viewerScore: 0.95,
  },
  T2:  {
    tier: 'T2', segmentId: 'SEG-02',
    label: 'Live Event Enthusiast',
    description: 'Primarily live content, bingo player, frequency viewer',
    cpmMin: 38, cpmMax: 44, color: '#f97316',
    engagementMin: 70, engagementMax: 84, viewerScore: 0.85,
  },
  T3:  {
    tier: 'T3', segmentId: 'SEG-03',
    label: 'Sports Bettor',
    description: 'Prediction-focused, ML picks, high sports affinity',
    cpmMin: 30, cpmMax: 37, color: '#fbbf24',
    engagementMin: 55, engagementMax: 69, viewerScore: 0.75,
  },
  T4:  {
    tier: 'T4', segmentId: 'SEG-04',
    label: 'Sports Commerce Buyer',
    description: 'Coupon redeemer, sponsor quiz participant, local ad clicker',
    cpmMin: 22, cpmMax: 29, color: '#22c55e',
    engagementMin: 40, engagementMax: 54, viewerScore: 0.65,
  },
  T5:  {
    tier: 'T5', segmentId: 'SEG-05',
    label: 'Casual Sports Fan',
    description: 'Weekend game day viewer, occasional interaction',
    cpmMin: 18, cpmMax: 21, color: '#00c9b1',
    engagementMin: 32, engagementMax: 39, viewerScore: 0.55,
  },
  T6:  {
    tier: 'T6', segmentId: 'SEG-06',
    label: 'Multi-Sport Viewer',
    description: 'Watches 3+ sports, moderate session frequency',
    cpmMin: 16, cpmMax: 17, color: '#3b82f6',
    engagementMin: 25, engagementMax: 31, viewerScore: 0.45,
  },
  T7:  {
    tier: 'T7', segmentId: 'SEG-07',
    label: 'Young Fan 18–34',
    description: 'High ad engagement rate, short sessions, mobile-first',
    cpmMin: 14, cpmMax: 15, color: '#8b5cf6',
    engagementMin: 20, engagementMax: 24, viewerScore: 0.38,
  },
  T8:  {
    tier: 'T8', segmentId: 'SEG-08',
    label: 'Household Decision Maker',
    description: 'Prime-time viewer, high ad completion, frequent sessions',
    cpmMin: 13, cpmMax: 13, color: '#94a3b8',
    engagementMin: 15, engagementMax: 19, viewerScore: 0.32,
  },
  T9:  {
    tier: 'T9', segmentId: 'SEG-09',
    label: 'Affluent Sports Viewer',
    description: 'High ad completion, commerce interactions, premium content',
    cpmMin: 12, cpmMax: 12, color: '#64748b',
    engagementMin: 10, engagementMax: 14, viewerScore: 0.26,
  },
  T10: {
    tier: 'T10', segmentId: 'SEG-10',
    label: 'Sports Travel Intender',
    description: 'Long sessions, diverse sports, travel ad responsive',
    cpmMin: 12, cpmMax: 12, color: '#475569',
    engagementMin: 7, engagementMax: 9, viewerScore: 0.20,
  },
  T11: {
    tier: 'T11', segmentId: 'SEG-11',
    label: 'Re-engaged Viewer',
    description: 'Returning after lapse, moderate current frequency',
    cpmMin: 11, cpmMax: 11, color: '#334155',
    engagementMin: 4, engagementMax: 6, viewerScore: 0.15,
  },
  T12: {
    tier: 'T12', segmentId: 'SEG-12',
    label: 'New Viewer',
    description: 'Insufficient signal — onboarding phase',
    cpmMin: 11, cpmMax: 11, color: '#1e293b',
    engagementMin: 0, engagementMax: 3, viewerScore: 0.10,
  },
};

/** Map engagement score (0–100) to ViewerTier */
export function classifyTier(engagementScore: number): ViewerTier {
  if (engagementScore >= 85) return 'T1';
  if (engagementScore >= 70) return 'T2';
  if (engagementScore >= 55) return 'T3';
  if (engagementScore >= 40) return 'T4';
  if (engagementScore >= 32) return 'T5';
  if (engagementScore >= 25) return 'T6';
  if (engagementScore >= 20) return 'T7';
  if (engagementScore >= 15) return 'T8';
  if (engagementScore >= 10) return 'T9';
  if (engagementScore >= 7)  return 'T10';
  if (engagementScore >= 4)  return 'T11';
  return 'T12';
}

/** Compute live CPM within tier range based on engagement position */
export function computeCPM(tier: ViewerTier, engagementScore: number): number {
  const meta = TIER_DEFINITIONS[tier];
  const ratio = Math.max(0, (engagementScore - meta.engagementMin) /
    Math.max(1, meta.engagementMax - meta.engagementMin));
  return Math.round((meta.cpmMin + ratio * (meta.cpmMax - meta.cpmMin)) * 10) / 10;
}
