/**
 * business.ts — Shared business data model
 * Used by: web simulator AdCards, API business.route.ts, iOS AdCardView (future)
 */

export type BusinessCategory =
  | 'restaurant' | 'bar' | 'sports_bar' | 'coffee' | 'pizza'
  | 'gym' | 'nail_salon' | 'diner' | 'seafood';

export type DealType = 'coupon' | 'bogo' | 'percent_off' | 'free_item';

export interface BusinessOffer {
  headline: string;         // e.g. "Buy 1 Slice Get 1 Free"
  dealType: DealType;
  dealValue: string;        // e.g. "$5 off", "Free Slice", "20% off"
  expiresAt: string;        // ISO 8601
  promoCode?: string;
}

export interface BusinessMembership {
  enabled: boolean;
  cardName: string;         // e.g. "Rocco's Club"
  stampsRequired?: number;  // for stamp cards
  reward: string;           // e.g. "Free pizza after 10 stamps"
  perks: string[];          // e.g. ["10% off always", "Free birthday slice"]
}

export interface BusinessListing {
  id: string;
  name: string;
  category: BusinessCategory;
  tagline: string;
  address: string;
  city: string;
  state: string;
  zip: string;
  lat: number;
  lng: number;
  phone: string;
  rating: number;           // 0–5
  reviewCount: number;
  distanceMiles?: number;   // computed client-side from user location
  primaryColor: string;     // hex, for card theming
  emoji: string;
  logoUrl?: string;
  heroImageUrl?: string;
  hours: Record<string, string>; // { mon: "11:00-22:00", ... }
  activeOffer?: BusinessOffer;
  membership?: BusinessMembership;
  orderEnabled: boolean;
  orderUrl?: string;
  arenzaPointsAccepted: boolean;
  /** Targeting: which viewer tiers see this business's ads */
  targetTiers?: string[];
}

/** Arenza Points economy — from Dual-Screen Build Plan Sec 4.3 */
export interface PointsTransaction {
  id: string;
  viewerToken: string;
  action: PointsAction;
  points: number;
  businessId?: string;
  createdAt: string;
}

export type PointsAction =
  | 'prediction_correct'
  | 'perfect_quarter'
  | 'first_visit'
  | 'referral'
  | 'review_written'
  | 'daily_login'
  | 'bingo_line'
  | 'scratch_win'
  | 'ad_watched';

export const POINTS_EARN: Record<PointsAction, number> = {
  prediction_correct: 100,
  perfect_quarter:    500,
  first_visit:        200,
  referral:           300,
  review_written:      50,
  daily_login:         25,
  bingo_line:         150,
  scratch_win:         75,
  ad_watched:          10,
};

/** Redemption catalog item */
export interface RedemptionItem {
  id: string;
  title: string;
  description: string;
  pointsCost: number;
  emoji: string;
  businessId?: string;  // null = any sponsor business
}

export const REDEMPTION_CATALOG: RedemptionItem[] = [
  { id: 'r1', title: '$1 Off',           description: '$1 off at any sponsor restaurant', pointsCost: 500,  emoji: '🎟' },
  { id: 'r2', title: 'Free Drink',       description: 'Free drink at any sponsor bar',    pointsCost: 1000, emoji: '🍺' },
  { id: 'r3', title: 'Free Dessert',     description: 'Free dessert or appetizer',        pointsCost: 1500, emoji: '🍰' },
  { id: 'r4', title: 'VIP Upgrade',      description: 'VIP membership at any sponsor',   pointsCost: 5000, emoji: '⭐' },
  { id: 'r5', title: '20% Off',          description: '20% off your next order',          pointsCost: 800,  emoji: '💸' },
  { id: 'r6', title: 'Free Appetizer',   description: 'Free app with $20+ order',         pointsCost: 1200, emoji: '🧆' },
];
