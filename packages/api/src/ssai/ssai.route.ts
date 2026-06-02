/**
 * ssai.route.ts
 * ─────────────────────────────────────────────────────────────────────────────
 * SSAI (Server-Side Ad Insertion) Hono router.
 *
 * Endpoints:
 *   GET  /api/ssai/manifest/:sessionId   — Return stitched HLS manifest
 *   POST /api/ssai/session               — Create a new session (pre-warms auction)
 *   GET  /api/ssai/session/:sessionId    — Get session metadata + pod info
 *   GET  /api/ssai/health                — Liveness check
 *
 * Flow:
 *   1. POST /api/ssai/session  →  run auction, stitch manifest, store in memory
 *   2. GET  /api/ssai/manifest/:sessionId  →  serve text/vnd.apple.mpegurl
 *   3. Player detects ad breaks via EXT-X-DISCONTINUITY / EXT-X-SESSION-DATA
 *   4. Player fires PoD beacons to /api/delivery/pod when ads complete
 */

import { Hono } from "hono";
import { z } from "zod";
import { randomBytes, createHash } from "crypto";
import { fetchContentManifest } from "./content-manifest.js";
import {
  rewriteManifest,
  storeManifest,
  getStoredManifest,
  getActiveSessionCount,
  type AdSlot,
} from "./manifest-rewriter.js";
import { getAllAdCreatives, type AdCreativeName } from "./s3-media.js";

export const ssaiRouter = new Hono();

// ── Helpers ────────────────────────────────────────────────────────────────

type Resolution = "1080p" | "720p" | "360p";

function generateSessionId(): string {
  return `sess-${randomBytes(6).toString("hex")}`;
}

function generateImpressionId(sessionId: string, slotIndex: number): string {
  return `0x${createHash("sha256")
    .update(`${sessionId}-${slotIndex}-${Date.now()}`)
    .digest("hex")
    .slice(0, 64)}`;
}

/**
 * Lightweight auction shim — calls the auction engine if available,
 * falls back to deterministic simulated winners for local dev.
 */
async function resolveAds(
  contentId: string,
  campaignId: string,
  sessionId: string,
  numBreaks: number
): Promise<AdSlot[]> {
  // Try to call the OpenRTB engine (Phase 2 — will be wired when built)
  try {
    const res = await fetch(`http://localhost:${process.env["PORT"] ?? 3001}/api/auction/run`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        breakType: "halftime",
        contentId,
        contentGenre: "Sports",
        sessionId,
        deviceType: "ctv",
        resolution: "1080p",
        numSlots: numBreaks,
      }),
      signal: AbortSignal.timeout(600), // 600ms max
    });
    if (res.ok) {
      const data = await res.json() as any;
      return (data.slots ?? []).map((slot: any, i: number) => ({
        creativeKey: (slot.creativeKey ?? "callaway_30s") as AdCreativeName,
        winningCpm: slot.winningCpm ?? 38,
        dspName: slot.dspName ?? "Simulated DSP",
        advertiser: slot.advertiser ?? "CMXS Demo",
        campaignId,
        impressionId: generateImpressionId(sessionId, i),
      }));
    }
  } catch {
    // Auction engine not yet running — use Phase 1 fallback
  }

  // Phase 1 fallback: deterministic creative rotation
  const creatives = getAllAdCreatives();
  return Array.from({ length: numBreaks }, (_, i) => {
    const creative = creatives[i % creatives.length]!;
    return {
      creativeKey: creative.name,
      winningCpm: 35 + Math.random() * 15, // $35-$50 CPM range
      dspName: "SimDSP-Fallback",
      advertiser: creative.advertiser,
      campaignId,
      impressionId: generateImpressionId(sessionId, i),
    };
  });
}

// ── POST /api/ssai/session — Create session ───────────────────────────────

const CreateSessionSchema = z.object({
  campaignId: z.string().default("0xdeadbeef00000000000000000000000000000000000000000000000000000000"),
  nodeOperator: z.string().regex(/^0x[0-9a-fA-F]{40}$/).default("0x0000000000000000000000000000000000000001"),
  resolution: z.enum(["1080p", "720p", "360p"]).default("1080p"),
  contentId: z.string().default("cmxs_liv_golf_round2"),
});

ssaiRouter.post("/session", async (c) => {
  const auctionStart = Date.now();

  let body: z.infer<typeof CreateSessionSchema>;
  try {
    body = CreateSessionSchema.parse(await c.req.json());
  } catch (err) {
    body = CreateSessionSchema.parse({});
  }

  try {
    const sessionId = generateSessionId();
    const baseManifest = await fetchContentManifest(body.resolution as Resolution);

    // Count ad breaks in the manifest
    const numBreaks = baseManifest.entries.filter((e) => e.type === "adbreak").length;

    // Resolve ads via auction engine
    const adSlots = await resolveAds(body.contentId, body.campaignId, sessionId, numBreaks);

    // Stitch manifest
    const result = rewriteManifest(baseManifest, adSlots, sessionId, body.nodeOperator);
    storeManifest(sessionId, result);

    const auctionLatencyMs = Date.now() - auctionStart;

    return c.json({
      sessionId,
      manifestUrl: `/api/ssai/manifest/${sessionId}`,
      auctionLatencyMs,
      adBreaks: numBreaks,
      totalDurationSeconds: result.durationSeconds,
      podMetadata: result.podMetadata,
      adSlots: result.adSlots.map((s) => ({
        impressionId: s.impressionId,
        advertiser: s.advertiser,
        cpm: s.winningCpm,
        dspName: s.dspName,
      })),
    });
  } catch (err) {
    console.error("[ssai] Session creation failed:", err);
    return c.json({ error: "Failed to create SSAI session" }, 500);
  }
});

// ── GET /api/ssai/manifest/:sessionId — Serve manifest ────────────────────

ssaiRouter.get("/manifest/:sessionId", async (c) => {
  const sessionId = c.req.param("sessionId");

  // Handle "test-001" shortcut for Phase 1 verification
  if (sessionId === "test-001") {
    try {
      const baseManifest = await fetchContentManifest("1080p");
      const numBreaks = baseManifest.entries.filter((e) => e.type === "adbreak").length;
      const adSlots = await resolveAds("test", "0xtest", sessionId, Math.max(numBreaks, 1));
      const result = rewriteManifest(
        baseManifest,
        adSlots,
        sessionId,
        "0x0000000000000000000000000000000000000001"
      );
      storeManifest(sessionId, result);
    } catch (err) {
      console.error("[ssai] test-001 generation failed:", err);
    }
  }

  const session = getStoredManifest(sessionId);
  if (!session) {
    return c.json({ error: "Session not found or expired" }, 404);
  }

  return new Response(session.manifest, {
    headers: {
      "Content-Type": "application/vnd.apple.mpegurl",
      "Cache-Control": "no-cache, no-store",
      "Access-Control-Allow-Origin": "*",
      "X-CMXS-Session": sessionId,
      "X-CMXS-Ad-Breaks": String(session.adSlots.length),
      "X-CMXS-Auction-Ms": "0", // already ran at session creation
    },
  });
});

// ── GET /api/ssai/session/:sessionId — Session metadata ──────────────────

ssaiRouter.get("/session/:sessionId", (c) => {
  const sessionId = c.req.param("sessionId");
  const session = getStoredManifest(sessionId);

  if (!session) {
    return c.json({ error: "Session not found" }, 404);
  }

  return c.json({
    sessionId,
    adSlots: session.adSlots.length,
    podMetadata: session.podMetadata,
    durationSeconds: session.durationSeconds,
    contentSeconds: session.contentSeconds,
    adsSeconds: session.adsSeconds,
  });
});

// ── GET /api/ssai/health ──────────────────────────────────────────────────

ssaiRouter.get("/health", async (c) => {
  let s3Reachable = false;
  try {
    const manifest = await fetchContentManifest("1080p");
    s3Reachable = manifest.entries.length > 0;
  } catch {
    s3Reachable = false;
  }

  return c.json({
    ok: true,
    activeSessions: getActiveSessionCount(),
    s3Reachable,
    cloudFrontConfigured: !!process.env["CLOUDFRONT_DOMAIN"],
    timestamp: new Date().toISOString(),
  });
});
