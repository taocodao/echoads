'use client';
/**
 * couponEngine.ts — Phase 3.1 (web implementation)
 * Dynamic coupon generation based on user profile, business config, and game context.
 * Mirrors the Python FastAPI spec from the vision document §7.3.
 */

import type { ViewerProfile } from './useProfileEngine';
import type { BusinessListing } from './sharedTypes';
import type { GameMomentCode } from './useGameMomentClassifier';

// ── Context types ──────────────────────────────────────────────────────────────

export type TimeOfDay = 'breakfast' | 'lunch' | 'dinner' | 'late_night';
export type WeatherCondition = 'clear' | 'rain' | 'snow' | 'cloudy';
export type CouponType =
  | 'reactivation'
  | 'game_moment'
  | 'vip_perk'
  | 'delivery_waiver'
  | 'slow_day'
  | 'membership_invite'
  | 'awareness';

export interface GameContext {
  momentCode: GameMomentCode;
  timeOfDay: TimeOfDay;
  dayOfWeek: number;           // 0=Sunday
  weather: WeatherCondition;
  teamWinning: boolean;        // home team winning
  isHalftime: boolean;
  isPostGame: boolean;
}

export interface CouponOffer {
  headline: string;            // max 40 chars
  subline: string;             // max 80 chars
  discountPct?: number;
  freeItem?: string;
  couponType: CouponType;
  expiryHours: number;
  deliveryMethod: 'wallet_push' | 'bottom_card' | 'both';
  urgencyLabel?: string;       // e.g., "Halftime offer — expires in 30 min"
  ctaLabel: string;            // text for the claim button
  badgeLabel?: string;         // small badge, e.g., "Game Day Deal"
}

// ── Time helpers ───────────────────────────────────────────────────────────────

function getTimeOfDay(): TimeOfDay {
  const h = new Date().getHours();
  if (h >= 6  && h < 11) return 'breakfast';
  if (h >= 11 && h < 16) return 'lunch';
  if (h >= 16 && h < 22) return 'dinner';
  return 'late_night';
}

function getWeather(): WeatherCondition {
  // Stub: rotate based on day of week for demo variety
  const day = new Date().getDay();
  return (['clear', 'rain', 'clear', 'cloudy', 'clear', 'clear', 'rain'] as WeatherCondition[])[day];
}

export function buildGameContext(
  momentCode: GameMomentCode,
  homeScore: number,
  awayScore: number,
  overrides?: Partial<GameContext>
): GameContext {
  return {
    momentCode,
    timeOfDay: getTimeOfDay(),
    dayOfWeek: new Date().getDay(),
    weather: getWeather(),
    teamWinning: homeScore > awayScore,
    isHalftime: momentCode === 'GMS_HALFTIME',
    isPostGame: false,
    ...overrides,
  };
}

// ── Coupon generation engine ───────────────────────────────────────────────────

export function generateCoupon(
  profile: ViewerProfile,
  business: BusinessListing,
  context: GameContext
): CouponOffer {
  const tierNum = parseInt(profile.tier.replace('T', ''));
  const isMember = false; // TODO: check against joinedClubs when backend exists
  const isSlowDay = [2, 3, 4].includes(context.dayOfWeek); // Tue/Wed/Thu

  // ── Priority 1: VIP high-tier + halftime + dinner window ──────────────────
  if (tierNum <= 3 && context.isHalftime && context.timeOfDay === 'dinner') {
    return {
      headline: `VIP Offer — 25% Off Tonight`,
      subline: `Halftime special at ${business.name}. Table waiting for you?`,
      couponType: 'vip_perk',
      discountPct: 25,
      expiryHours: 3,
      deliveryMethod: 'both',
      urgencyLabel: 'Halftime offer — expires in 30 min',
      ctaLabel: '🎟 Claim VIP Offer',
      badgeLabel: 'VIP Halftime',
    };
  }

  // ── Priority 2: Score event + membership upsell ───────────────────────────
  if (
    ['GMS_SCORE', 'GMS_CLUTCH'].includes(context.momentCode) &&
    !isMember
  ) {
    return {
      headline: context.teamWinning
        ? `Victory Round — Join & Save 15%`
        : `Consolation Deal — 15% Off`,
      subline: context.teamWinning
        ? `Celebrate at ${business.name}! Join the club for a game-day discount.`
        : `Come commiserate at ${business.name}. Join & get 15% off tonight.`,
      couponType: 'membership_invite',
      discountPct: 15,
      expiryHours: 4,
      deliveryMethod: 'bottom_card',
      urgencyLabel: 'Score moment deal — limited time',
      ctaLabel: '🍺 Join & Claim',
      badgeLabel: context.teamWinning ? '🏆 Victory Deal' : '💪 Comeback Deal',
    };
  }

  // ── Priority 3: Rain + delivery ───────────────────────────────────────────
  if (context.weather === 'rain' && business.orderEnabled) {
    return {
      headline: `Rainy Night? Free Delivery`,
      subline: `Orders over $30 at ${business.name} — delivered to your door tonight.`,
      couponType: 'delivery_waiver',
      expiryHours: 5,
      deliveryMethod: 'bottom_card',
      freeItem: 'Free delivery on $30+',
      urgencyLabel: 'Tonight only',
      ctaLabel: '🌧 Order Now — Free Delivery',
      badgeLabel: '🌧 Rainy Night',
    };
  }

  // ── Priority 4: Slow day fill ─────────────────────────────────────────────
  if (isSlowDay && context.timeOfDay === 'dinner') {
    return {
      headline: `Slow Night Special — 20% Off`,
      subline: `${business.name} is quieter tonight. Great time to visit — 20% off your whole order.`,
      couponType: 'slow_day',
      discountPct: 20,
      expiryHours: 4,
      deliveryMethod: 'bottom_card',
      urgencyLabel: 'Tonight only — dine-in',
      ctaLabel: '🎟 Claim 20% Off',
      badgeLabel: '📅 Mid-Week Deal',
    };
  }

  // ── Priority 5: Post-game offer ───────────────────────────────────────────
  if (context.isPostGame) {
    return {
      headline: context.teamWinning ? `Game Over — Come Celebrate!` : `Post-Game Pint — 10% Off`,
      subline: `${business.name} is ready for you. Show up and mention Arenza.`,
      couponType: 'game_moment',
      discountPct: 10,
      expiryHours: 2,
      deliveryMethod: 'both',
      urgencyLabel: 'Expires in 2 hours',
      ctaLabel: context.teamWinning ? '🏆 Celebrate at the Bar' : '🍺 Claim Post-Game Deal',
      badgeLabel: '🏁 Post-Game',
    };
  }

  // ── Default: awareness card ───────────────────────────────────────────────
  return {
    headline: business.activeOffer?.headline ?? `${business.name} — Game Day Offer`,
    subline: business.activeOffer?.dealValue
      ? `${business.activeOffer.dealValue} — valid today`
      : `Visit ${business.name} and earn Arenza Points on every order.`,
    couponType: 'awareness',
    expiryHours: 24,
    deliveryMethod: 'bottom_card',
    ctaLabel: '🌐 See Offer',
  };
}
