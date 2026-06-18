/**
 * qrToken.ts — Secure QR token generation & validation
 * Tokens are time-windowed (5-min), tamper-detectable via FNV-1a checksum.
 * No external crypto dependency — pure TS, works in browser + server.
 */

// ── FNV-1a 32-bit hash (fast, no deps) ────────────────────────────────────────
function fnv1a(str: string): number {
  let hash = 2166136261;
  for (let i = 0; i < str.length; i++) {
    hash ^= str.charCodeAt(i);
    hash = Math.imul(hash, 16777619);
  }
  return hash >>> 0; // unsigned 32-bit
}

function toBase36(n: number): string {
  return Math.abs(n).toString(36).toUpperCase();
}

// ── Token format: ARZ-{userId}-{bizId}-{window}-{checksum} ────────────────────
// window = 5-minute epoch bucket (changes every 5 min)
// checksum = FNV hash of all other parts (detects tampering)

const SECRET_SALT = 'ARENZA_DEMO_SALT_2026';

export function generateToken(userId: string, businessId = 'ALL'): string {
  const window5 = Math.floor(Date.now() / (5 * 60 * 1000));
  const windowStr = toBase36(window5);
  const raw = `${userId}|${businessId}|${windowStr}|${SECRET_SALT}`;
  const checksum = toBase36(fnv1a(raw)).slice(0, 6).padStart(6, '0');
  return `ARZ-${userId}-${businessId}-${windowStr}-${checksum}`;
}

export interface TokenPayload {
  valid: boolean;
  userId?: string;
  businessId?: string;
  error?: string;
}

export function validateToken(token: string): TokenPayload {
  if (!token || !token.startsWith('ARZ-')) {
    return { valid: false, error: 'Invalid token format' };
  }

  const parts = token.split('-');
  // ARZ - userId - businessId - window - checksum
  // userId may contain hyphens so we reconstruct from the end
  if (parts.length < 5) return { valid: false, error: 'Malformed token' };

  const checksum = parts[parts.length - 1];
  const windowStr = parts[parts.length - 2];
  const businessId = parts[parts.length - 3];
  const userId = parts.slice(1, parts.length - 3).join('-');

  // Verify time window (accept current ±2 windows = 10 min grace)
  const window5 = parseInt(windowStr, 36);
  const current5 = Math.floor(Date.now() / (5 * 60 * 1000));
  if (Math.abs(current5 - window5) > 2) {
    return { valid: false, error: 'Token expired — please refresh QR' };
  }

  // Verify checksum
  const raw = `${userId}|${businessId}|${windowStr}|${SECRET_SALT}`;
  const expected = toBase36(fnv1a(raw)).slice(0, 6).padStart(6, '0');
  if (checksum !== expected) {
    return { valid: false, error: 'Invalid token — cannot verify' };
  }

  return { valid: true, userId, businessId };
}

/** Generate a stable, unique user ID for this device (stored in localStorage) */
export function getOrCreateUserId(): string {
  if (typeof window === 'undefined') return 'server';
  const key = 'arenza_user_id';
  let id = localStorage.getItem(key);
  if (!id) {
    // 8-char random alphanumeric
    id = 'U' + Math.random().toString(36).slice(2, 9).toUpperCase();
    localStorage.setItem(key, id);
  }
  return id;
}
