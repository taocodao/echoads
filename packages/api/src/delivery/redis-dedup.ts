/**
 * redis-dedup.ts
 * ─────────────────────────────────────────────────────────────────────────────
 * Redis-backed impression deduplication for the PoD Relay Service.
 *
 * Uses Upstash Redis (REST SDK) which works in both serverless (Vercel) and
 * long-running Node.js (EC2) environments without a persistent TCP connection.
 *
 * Fallback: if UPSTASH_REDIS_REST_URL is not set, uses an in-process Map
 * with TTL eviction — suitable for local dev and single-instance deployments.
 *
 * TTL: 5 minutes (REPLAY_WINDOW from DeliveryOracleV2) — impressions older
 * than this are rejected by the contract anyway, so no dedup needed.
 */

const DEDUP_TTL_SECONDS = 300; // 5 minutes — matches DeliveryOracleV2.REPLAY_WINDOW

// ── Upstash REST client (optional) ───────────────────────────────────────────

interface UpstashClient {
  set(key: string, value: string, opts: { ex: number }): Promise<unknown>;
  get(key: string): Promise<string | null>;
}

function buildUpstashClient(): UpstashClient | null {
  const url   = process.env["UPSTASH_REDIS_REST_URL"];
  const token = process.env["UPSTASH_REDIS_REST_TOKEN"];
  if (!url || !token) return null;

  const headers = {
    Authorization: `Bearer ${token}`,
    "Content-Type": "application/json",
  };

  return {
    async set(key: string, value: string, opts: { ex: number }): Promise<unknown> {
      const res = await fetch(`${url}/set/${encodeURIComponent(key)}/${encodeURIComponent(value)}?EX=${opts.ex}`, {
        method: "POST",
        headers,
      });
      return res.json();
    },
    async get(key: string): Promise<string | null> {
      const res  = await fetch(`${url}/get/${encodeURIComponent(key)}`, { headers });
      const body = await res.json() as { result: string | null };
      return body.result;
    },
  };
}

// ── In-process fallback ───────────────────────────────────────────────────────

interface MapEntry { value: string; expiresAt: number }
const localMap = new Map<string, MapEntry>();

function localSet(key: string, value: string, ttlSeconds: number): void {
  localMap.set(key, { value, expiresAt: Date.now() + ttlSeconds * 1000 });
}

function localGet(key: string): string | null {
  const entry = localMap.get(key);
  if (!entry) return null;
  if (Date.now() > entry.expiresAt) {
    localMap.delete(key);
    return null;
  }
  return entry.value;
}

// Prune expired entries every 2 minutes
setInterval(() => {
  const now = Date.now();
  for (const [k, v] of localMap) {
    if (now > v.expiresAt) localMap.delete(k);
  }
}, 120_000);

// ── Public API ────────────────────────────────────────────────────────────────

const upstash = buildUpstashClient();

if (upstash) {
  console.log("[redis-dedup] Using Upstash Redis for impression deduplication.");
} else {
  console.warn("[redis-dedup] UPSTASH_REDIS_REST_URL not set — using in-process Map (single-node only).");
}

/**
 * Mark an impression ID as seen. Returns true if it was newly inserted,
 * false if it was already present (duplicate — reject this receipt).
 */
export async function markSeen(impressionId: string): Promise<boolean> {
  const key = `pod:dedup:${impressionId}`;

  if (upstash) {
    const existing = await upstash.get(key);
    if (existing !== null) return false; // duplicate
    await upstash.set(key, "1", { ex: DEDUP_TTL_SECONDS });
    return true;
  }

  // Fallback
  if (localGet(key) !== null) return false; // duplicate
  localSet(key, "1", DEDUP_TTL_SECONDS);
  return true;
}

/**
 * Check if an impression ID has already been seen (without marking).
 */
export async function isSeen(impressionId: string): Promise<boolean> {
  const key = `pod:dedup:${impressionId}`;
  if (upstash) return (await upstash.get(key)) !== null;
  return localGet(key) !== null;
}

/**
 * Returns the current size of the local fallback map (for monitoring).
 */
export function localMapSize(): number {
  return localMap.size;
}
