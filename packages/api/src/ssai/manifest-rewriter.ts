/**
 * manifest-rewriter.ts
 * ─────────────────────────────────────────────────────────────────────────────
 * The SSAI manifest rewriter. Takes the parsed base content manifest and
 * splices auction-winning ad creative segments into the SSAI_PLACEHOLDER
 * positions, producing a per-session stitched HLS manifest.
 *
 * Output format:
 *   - Standard HLS (EXT-X-VERSION:3)
 *   - EXT-X-DISCONTINUITY tags at content/ad boundaries
 *   - EXT-X-SESSION-DATA carrying PoD metadata (impressionId, campaignId, CPM)
 *   - Each viewer session gets a unique manifest URL (no shared caching of ad slots)
 */

import type { ParsedManifest, ManifestEntry } from "./content-manifest.js";
import { getAdCreativeInfo, type AdCreativeName } from "./s3-media.js";

// ── Types ─────────────────────────────────────────────────────────────────────

export interface AdSlot {
  creativeKey: AdCreativeName;
  winningCpm: number;          // actual CPM paid (clearing price)
  dspName: string;
  advertiser: string;
  campaignId: string;          // hex bytes32 for DeliveryOracleV2
  impressionId: string;        // per-impression unique ID (hex)
}

export interface RewriteResult {
  manifest: string;            // full stitched HLS manifest text
  sessionId: string;
  adSlots: AdSlot[];
  durationSeconds: number;     // total manifest duration (content + ads)
  contentSeconds: number;
  adsSeconds: number;
  podMetadata: PodMetadata[];  // for embedding in manifest + sending to PoD client
}

export interface PodMetadata {
  impressionId: string;
  campaignId: string;
  nodeOperator: string;
  cpm: number;
  advertiser: string;
  product: string;
  price: string;               // display price for x302 overlay
  startOffsetSeconds: number;  // offset in the manifest where this ad starts
  durationSeconds: number;
}

// ── Rewriter ─────────────────────────────────────────────────────────────────

/**
 * Build a session-specific stitched HLS manifest.
 *
 * @param manifest     Parsed base content manifest with SSAI placeholders
 * @param adSlots      Auction-resolved ad slots (one per ad break)
 * @param sessionId    Unique viewer session ID
 * @param nodeOperator Ethereum address of the delivery node for this session
 */
export function rewriteManifest(
  manifest: ParsedManifest,
  adSlots: AdSlot[],
  sessionId: string,
  nodeOperator: string
): RewriteResult {
  const lines: string[] = [
    "#EXTM3U",
    `#EXT-X-VERSION:3`,
    `#EXT-X-TARGETDURATION:${manifest.targetDuration}`,
    `#EXT-X-PROGRAM-DATE-TIME:${new Date().toISOString()}`,
    "",
  ];

  let adBreakIndex = 0;
  let durationSeconds = 0;
  let contentSeconds = 0;
  let adsSeconds = 0;
  const podMetadata: PodMetadata[] = [];

  for (const entry of manifest.entries) {
    if (entry.type === "segment") {
      // Regular content segment
      lines.push(`#EXTINF:${entry.duration.toFixed(3)},`);
      lines.push(entry.url);
      durationSeconds += entry.duration;
      contentSeconds += entry.duration;

    } else if (entry.type === "adbreak") {
      // Ad break — splice in winning creative
      const slot = adSlots[adBreakIndex];
      adBreakIndex++;

      if (!slot) {
        // No ad won this slot — use house ad fallback or skip
        lines.push(`## Ad break skipped — no fill`);
        continue;
      }

      const creative = getAdCreativeInfo(slot.creativeKey);
      const adStartOffset = durationSeconds;

      // Embed PoD metadata as EXT-X-SESSION-DATA for the player to read
      lines.push(`#EXT-X-SESSION-DATA:DATA-ID="com.cmxs.pod.impressionId",VALUE="${slot.impressionId}"`);
      lines.push(`#EXT-X-SESSION-DATA:DATA-ID="com.cmxs.pod.campaignId",VALUE="${slot.campaignId}"`);
      lines.push(`#EXT-X-SESSION-DATA:DATA-ID="com.cmxs.pod.cpm",VALUE="${slot.winningCpm}"`);
      lines.push(`#EXT-X-SESSION-DATA:DATA-ID="com.cmxs.pod.advertiser",VALUE="${slot.advertiser}"`);
      lines.push(`#EXT-X-SESSION-DATA:DATA-ID="com.cmxs.pod.nodeOperator",VALUE="${nodeOperator}"`);
      lines.push(``);

      // Ad break boundary
      lines.push(`#EXT-X-DISCONTINUITY`);
      lines.push(`#EXT-X-CUE-OUT:DURATION=${creative.durationSeconds}`);
      lines.push(`## CMXS-AD-SLOT: ${slot.advertiser} | ${slot.winningCpm} CPM | ${slot.dspName}`);
      lines.push(``);

      // Ad segments
      for (const segUrl of creative.segmentUrls) {
        lines.push(`#EXTINF:6.000,`);
        lines.push(segUrl);
        durationSeconds += 6;
        adsSeconds += 6;
      }

      lines.push(``);
      lines.push(`#EXT-X-CUE-IN`);
      lines.push(`#EXT-X-DISCONTINUITY`);
      lines.push(``);

      // Track pod metadata for PoD client
      podMetadata.push({
        impressionId: slot.impressionId,
        campaignId: slot.campaignId,
        nodeOperator,
        cpm: slot.winningCpm,
        advertiser: slot.advertiser,
        product: creative.product,
        price: creative.price,
        startOffsetSeconds: adStartOffset,
        durationSeconds: creative.durationSeconds,
      });
    }
  }

  lines.push(`#EXT-X-ENDLIST`);

  return {
    manifest: lines.join("\n"),
    sessionId,
    adSlots,
    durationSeconds,
    contentSeconds,
    adsSeconds,
    podMetadata,
  };
}

// ── Manifest Store (in-memory per-session) ────────────────────────────────────

/**
 * In-memory store for stitched manifests.
 * Key: sessionId
 * TTL: 4 hours (viewer session max)
 */
const manifestStore = new Map<string, { result: RewriteResult; expiresAt: number }>();
const SESSION_TTL_MS = 4 * 60 * 60 * 1000; // 4 hours

export function storeManifest(sessionId: string, result: RewriteResult): void {
  manifestStore.set(sessionId, {
    result,
    expiresAt: Date.now() + SESSION_TTL_MS,
  });
}

export function getStoredManifest(sessionId: string): RewriteResult | null {
  const entry = manifestStore.get(sessionId);
  if (!entry) return null;
  if (Date.now() > entry.expiresAt) {
    manifestStore.delete(sessionId);
    return null;
  }
  return entry.result;
}

// Prune expired sessions every 30 minutes
setInterval(() => {
  const now = Date.now();
  for (const [k, v] of manifestStore) {
    if (now > v.expiresAt) manifestStore.delete(k);
  }
}, 30 * 60 * 1000);

export function getActiveSessionCount(): number {
  return manifestStore.size;
}
