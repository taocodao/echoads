/**
 * s3-media.ts
 * ─────────────────────────────────────────────────────────────────────────────
 * Builds CloudFront CDN URLs for HLS segments and ad creatives stored in S3.
 * All media is served via CloudFront (not directly from S3) for:
 *   - HTTPS enforcement
 *   - Global edge caching
 *   - Correct cache headers per segment type
 */

const CLOUDFRONT_DOMAIN = process.env["CLOUDFRONT_DOMAIN"] ?? "";
const S3_BUCKET = process.env["S3_MEDIA_BUCKET"] ?? "cmxs-media-prototype";
const AWS_REGION = process.env["AWS_REGION"] ?? "us-east-1";

// Fallback: use S3 direct URL if CloudFront not configured (dev mode)
const BASE_URL = CLOUDFRONT_DOMAIN
  ? `https://${CLOUDFRONT_DOMAIN}`
  : `https://${S3_BUCKET}.s3.${AWS_REGION}.amazonaws.com`;

// ── Content URLs ──────────────────────────────────────────────────────────────

export type Resolution = "1080p" | "720p" | "360p";

/**
 * Returns the master SCTE-35-annotated HLS manifest URL for the content stream.
 * This manifest contains the ##SSAI_PLACEHOLDER markers that the rewriter replaces.
 */
export function getContentManifestUrl(resolution: Resolution = "1080p"): string {
  // The SCTE-35-annotated manifest is at master_scte35.m3u8 for 1080p.
  // Lower resolutions use the plain stream.m3u8 (SSAI rewrites based on 1080p).
  const filename = resolution === "1080p" ? "master_scte35.m3u8" : "stream.m3u8";
  return `${BASE_URL}/content/sports_${resolution}/${filename}`;
}

/**
 * Returns the URL for a specific content segment.
 * Used when building stitched manifests to preserve absolute segment URLs.
 */
export function getContentSegmentUrl(resolution: Resolution, segmentName: string): string {
  return `${BASE_URL}/content/sports_${resolution}/${segmentName}`;
}

// ── Ad Creative URLs ──────────────────────────────────────────────────────────

export type AdCreativeName =
  | "callaway_30s"
  | "bmw_30s"
  | "nike_15s"
  | "taylormade_15s"
  | "rolex_30s";

interface AdCreativeInfo {
  name: AdCreativeName;
  advertiser: string;
  durationSeconds: number;
  category: string;        // IAB category
  product: string;         // Display name for x302 overlay
  price: string;           // Display price for x302 overlay
  manifestUrl: string;
  segmentUrls: string[];   // Pre-built segment URLs (6s each)
}

const AD_CREATIVE_MAP: Record<AdCreativeName, Omit<AdCreativeInfo, "manifestUrl" | "segmentUrls">> = {
  "callaway_30s": {
    name: "callaway_30s",
    advertiser: "Callaway Golf",
    durationSeconds: 30,
    category: "IAB17-18",
    product: "Paradym Ai Smoke Driver",
    price: "$549",
  },
  "bmw_30s": {
    name: "bmw_30s",
    advertiser: "BMW",
    durationSeconds: 30,
    category: "IAB2-1",
    product: "M4 Competition",
    price: "$74,900",
  },
  "nike_15s": {
    name: "nike_15s",
    advertiser: "Nike",
    durationSeconds: 15,
    category: "IAB18-5",
    product: "Air Max 270",
    price: "$150",
  },
  "taylormade_15s": {
    name: "taylormade_15s",
    advertiser: "TaylorMade Golf",
    durationSeconds: 15,
    category: "IAB17-18",
    product: "Stealth 2 Driver",
    price: "$599",
  },
  "rolex_30s": {
    name: "rolex_30s",
    advertiser: "Rolex",
    durationSeconds: 30,
    category: "IAB18-3",
    product: "Oyster Perpetual",
    price: "$6,500",
  },
};

/**
 * Returns the full AdCreativeInfo for a given creative name, including
 * the CloudFront manifest URL and pre-built segment URLs.
 */
export function getAdCreativeInfo(name: AdCreativeName): AdCreativeInfo {
  const meta = AD_CREATIVE_MAP[name];
  const folderName = `${name}_1080p`;
  const numSegments = Math.ceil(meta.durationSeconds / 6);

  const segmentUrls = Array.from({ length: numSegments }, (_, i) => {
    const idx = String(i).padStart(3, "0");
    return `${BASE_URL}/ads/${folderName}/ad_seg_${idx}.ts`;
  });

  return {
    ...meta,
    manifestUrl: `${BASE_URL}/ads/${folderName}/ad.m3u8`,
    segmentUrls,
  };
}

/**
 * Returns all ad creatives as an array (for pod assembly / auction).
 */
export function getAllAdCreatives(): AdCreativeInfo[] {
  return (Object.keys(AD_CREATIVE_MAP) as AdCreativeName[]).map(getAdCreativeInfo);
}

/**
 * Returns the ad creative whose duration matches the slot requirement.
 * Prefers 30s slots for premium placement.
 */
export function selectCreativeForDuration(
  durationSeconds: number,
  exclude: AdCreativeName[] = []
): AdCreativeInfo | null {
  const candidates = getAllAdCreatives().filter(
    (c) => c.durationSeconds <= durationSeconds && !exclude.includes(c.name)
  );
  if (candidates.length === 0) return null;
  // Prefer exact duration match
  const exact = candidates.find((c) => c.durationSeconds === durationSeconds);
  return exact ?? candidates[0]!;
}

// ── Utility ───────────────────────────────────────────────────────────────────

export function isConfigured(): boolean {
  return !!CLOUDFRONT_DOMAIN;
}

export function getBaseUrl(): string {
  return BASE_URL;
}
