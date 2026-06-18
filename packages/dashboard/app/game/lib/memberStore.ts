/**
 * memberStore.ts — In-memory member database (demo)
 * Simulates Firebase Firestore for the demo.
 * In production: replace with actual Firestore reads/writes.
 *
 * Persisted to localStorage so data survives page reload.
 */

export interface MemberRecord {
  userId: string;
  displayName: string;
  joinedAt: number;
  // Per-business data
  businesses: Record<string, BusinessMembership>;
}

export interface BusinessMembership {
  businessId: string;
  businessName: string;
  stamps: number;
  stampsRequired: number;
  pointsBalance: number;
  memberTier: 'Guest' | 'Regular' | 'VIP' | 'Founding Member';
  visitCount: number;
  lastVisit?: number;
  activeCoupons: ActiveCoupon[];
  purchaseHistory: PurchaseRecord[];
}

export interface ActiveCoupon {
  id: string;
  offer: string;
  value: string;
  claimedAt: number;
  expiresAt: number;
  redeemed: boolean;
  redeemedAt?: number;
}

export interface PurchaseRecord {
  id: string;
  amount?: number;
  description: string;
  pointsEarned: number;
  timestamp: number;
  staffNote?: string;
}

const STORE_KEY = 'arenza_member_store';

function loadStore(): Record<string, MemberRecord> {
  if (typeof window === 'undefined') return {};
  try {
    const raw = localStorage.getItem(STORE_KEY);
    return raw ? JSON.parse(raw) : {};
  } catch {
    return {};
  }
}

function saveStore(store: Record<string, MemberRecord>): void {
  if (typeof window === 'undefined') return;
  localStorage.setItem(STORE_KEY, JSON.stringify(store));
}

// ── Business catalog (matches our ad partners) ─────────────────────────────────
export const BUSINESS_CATALOG: Record<string, { name: string; stampsRequired: number; emoji: string }> = {
  'ajward':    { name: 'AJ.Ward',                  stampsRequired: 9, emoji: '🍽️' },
  'bonsai':    { name: 'Bonsai Cafe',               stampsRequired: 9, emoji: '🍜' },
  'roccos':    { name: "Rocco's Bar & Restaurant",  stampsRequired: 9, emoji: '🍸' },
  'rooftop':   { name: 'Rooftop Gardens',           stampsRequired: 9, emoji: '🌿' },
  'oldram':    { name: 'Old Ram Coaching Inn',      stampsRequired: 9, emoji: '🍺' },
};

// ── Public API ─────────────────────────────────────────────────────────────────

export function getMember(userId: string): MemberRecord {
  const store = loadStore();
  if (!store[userId]) {
    store[userId] = {
      userId,
      displayName: `Member ${userId.slice(1, 5)}`,
      joinedAt: Date.now(),
      businesses: {},
    };
    saveStore(store);
  }
  return store[userId];
}

export function getOrCreateMembership(userId: string, businessId: string): BusinessMembership {
  const store = loadStore();
  const member = store[userId] ?? getMember(userId);
  const biz = BUSINESS_CATALOG[businessId];

  if (!member.businesses[businessId]) {
    member.businesses[businessId] = {
      businessId,
      businessName: biz?.name ?? businessId,
      stamps: 0,
      stampsRequired: biz?.stampsRequired ?? 9,
      pointsBalance: 0,
      memberTier: 'Guest',
      visitCount: 0,
      activeCoupons: [],
      purchaseHistory: [],
    };
    store[userId] = member;
    saveStore(store);
  }
  return member.businesses[businessId];
}

export function addStamp(userId: string, businessId: string): { membership: BusinessMembership; rewardUnlocked: boolean } {
  const store = loadStore();
  const member = getMember(userId);
  const biz = getOrCreateMembership(userId, businessId);

  biz.stamps += 1;
  biz.visitCount += 1;
  biz.lastVisit = Date.now();
  biz.pointsBalance += 25; // 25 pts per stamp

  // Stamp card complete → reset + unlock reward
  let rewardUnlocked = false;
  if (biz.stamps >= biz.stampsRequired) {
    biz.stamps = 0;
    rewardUnlocked = true;
    biz.activeCoupons.push({
      id: `reward-${Date.now()}`,
      offer: 'Free Reward',
      value: 'Free item — loyalty reward',
      claimedAt: Date.now(),
      expiresAt: Date.now() + 7 * 24 * 60 * 60 * 1000, // 7 days
      redeemed: false,
    });
  }

  // Tier upgrade
  if (biz.visitCount >= 12) biz.memberTier = 'VIP';
  else if (biz.visitCount >= 6) biz.memberTier = 'Regular';

  member.businesses[businessId] = biz;
  store[userId] = member;
  saveStore(store);
  return { membership: biz, rewardUnlocked };
}

export function redeemCoupon(userId: string, businessId: string, couponId: string): {
  success: boolean; coupon?: ActiveCoupon; error?: string;
} {
  const store = loadStore();
  const member = getMember(userId);
  const biz = member.businesses[businessId];
  if (!biz) return { success: false, error: 'No membership found' };

  const coupon = biz.activeCoupons.find(c => c.id === couponId && !c.redeemed);
  if (!coupon) return { success: false, error: 'Coupon not found or already used' };
  if (Date.now() > coupon.expiresAt) return { success: false, error: 'Coupon expired' };

  coupon.redeemed = true;
  coupon.redeemedAt = Date.now();
  store[userId] = member;
  saveStore(store);
  return { success: true, coupon };
}

export function recordPurchase(userId: string, businessId: string, description: string, amount?: number): BusinessMembership {
  const store = loadStore();
  const member = getMember(userId);
  const biz = getOrCreateMembership(userId, businessId);

  const pointsEarned = amount ? Math.floor(amount * 10) : 50; // 10 pts per $1
  biz.pointsBalance += pointsEarned;
  biz.visitCount += 1;
  biz.lastVisit = Date.now();
  biz.purchaseHistory.push({
    id: `p-${Date.now()}`,
    ...(amount !== undefined ? { amount } : {}),
    description,
    pointsEarned,
    timestamp: Date.now(),
  });

  member.businesses[businessId] = biz;
  store[userId] = member;
  saveStore(store);
  return biz;
}

/** Add a coupon to member's account (called when user taps Claim in ad) */
export function addCoupon(userId: string, businessId: string, offer: string, value: string, expiryHours = 24): void {
  const store = loadStore();
  const member = getMember(userId);
  const biz = getOrCreateMembership(userId, businessId);

  // Don't duplicate
  if (biz.activeCoupons.some(c => c.offer === offer && !c.redeemed)) return;

  biz.activeCoupons.push({
    id: `c-${Date.now()}`,
    offer,
    value,
    claimedAt: Date.now(),
    expiresAt: Date.now() + expiryHours * 60 * 60 * 1000,
    redeemed: false,
  });

  member.businesses[businessId] = biz;
  store[userId] = member;
  saveStore(store);
}
