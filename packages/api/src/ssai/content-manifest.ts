/**
 * content-manifest.ts
 * ─────────────────────────────────────────────────────────────────────────────
 * Fetches the base content manifest from S3/CloudFront and parses it into a
 * structured representation that the manifest rewriter can work with.
 *
 * The base manifest (master_scte35.m3u8) contains:
 *   - Regular content segments (#EXTINF + URL)
 *   - SCTE-35 ad break markers (##SSAI_PLACEHOLDER_START / _END)
 *
 * This module also provides a lightweight in-memory cache of the fetched
 * manifest (60s TTL) to avoid hammering CloudFront on every player session.
 */

import { getContentManifestUrl, type Resolution } from "./s3-media.js";

// ── Types ─────────────────────────────────────────────────────────────────────

export interface ContentSegment {
  type: "segment";
  duration: number;       // seconds (from #EXTINF)
  url: string;
}

export interface AdBreakPlaceholder {
  type: "adbreak";
  durationSeconds: number;  // from #EXT-X-CUE-OUT:DURATION=N
  campaignIdTemplate: string; // e.g., "__CAMPAIGN_ID__"
  lineIndex: number;        // position in manifest for rewriter
}

export type ManifestEntry = ContentSegment | AdBreakPlaceholder;

export interface ParsedManifest {
  version: number;
  targetDuration: number;
  entries: ManifestEntry[];
  rawLines: string[];       // original lines for reconstructing the manifest
  fetchedAt: number;
}

// ── In-Memory Cache ───────────────────────────────────────────────────────────

const manifestCache = new Map<Resolution, ParsedManifest>();
const CACHE_TTL_MS = 60_000; // 60 seconds

// ── Fetcher ───────────────────────────────────────────────────────────────────

/**
 * Fetch and parse the base content manifest from S3/CloudFront.
 * Returns a cached copy if fresh (within 60s).
 */
export async function fetchContentManifest(resolution: Resolution = "1080p"): Promise<ParsedManifest> {
  const cached = manifestCache.get(resolution);
  if (cached && Date.now() - cached.fetchedAt < CACHE_TTL_MS) {
    return cached;
  }

  const url = getContentManifestUrl(resolution);

  let rawText: string;
  try {
    const res = await fetch(url);
    if (!res.ok) {
      throw new Error(`HTTP ${res.status} fetching manifest from ${url}`);
    }
    rawText = await res.text();
  } catch (err) {
    // If S3 not configured, return a synthetic manifest for local dev
    console.warn("[content-manifest] CloudFront unavailable — using synthetic manifest");
    rawText = generateSyntheticManifest();
  }

  const parsed = parseManifest(rawText);
  manifestCache.set(resolution, parsed);
  return parsed;
}

// ── Parser ────────────────────────────────────────────────────────────────────

function parseManifest(raw: string): ParsedManifest {
  const lines = raw.split("\n").map((l) => l.trim()).filter(Boolean);
  const entries: ManifestEntry[] = [];
  let version = 3;
  let targetDuration = 6;

  let i = 0;
  while (i < lines.length) {
    const line = lines[i]!;

    if (line.startsWith("#EXT-X-VERSION:")) {
      version = parseInt(line.split(":")[1] ?? "3");
    } else if (line.startsWith("#EXT-X-TARGETDURATION:")) {
      targetDuration = parseInt(line.split(":")[1] ?? "6");
    } else if (line.startsWith("#EXTINF:")) {
      // Regular content segment
      const duration = parseFloat(line.split(":")[1]?.split(",")[0] ?? "6");
      const url = lines[i + 1] ?? "";
      if (!url.startsWith("#")) {
        entries.push({ type: "segment", duration, url });
        i += 2;
        continue;
      }
    } else if (line.includes("SSAI_PLACEHOLDER_START")) {
      // Ad break placeholder — parse duration from #EXT-X-CUE-OUT above
      const cueOutLine = lines[i - 1] ?? "";
      const durationMatch = cueOutLine.match(/DURATION=(\d+)/);
      const duration = durationMatch ? parseInt(durationMatch[1]!) : 30;

      const campaignMatch = line.match(/campaignId=(\S+)/);
      const campaignIdTemplate = campaignMatch ? campaignMatch[1]! : "__CAMPAIGN_ID__";

      entries.push({
        type: "adbreak",
        durationSeconds: duration,
        campaignIdTemplate,
        lineIndex: i,
      });

      // Skip to SSAI_PLACEHOLDER_END
      while (i < lines.length && !lines[i]!.includes("SSAI_PLACEHOLDER_END")) {
        i++;
      }
    }
    i++;
  }

  return { version, targetDuration, entries, rawLines: lines, fetchedAt: Date.now() };
}

// ── Synthetic manifest for local dev ─────────────────────────────────────────

function generateSyntheticManifest(): string {
  const segments: string[] = [];
  // 4 content segments before ad break (24s of content)
  for (let i = 1; i <= 4; i++) {
    segments.push(`#EXTINF:6.0,`);
    segments.push(`https://example.cloudfront.net/content/sports_1080p/seg_${String(i).padStart(3,"0")}.ts`);
  }

  // Ad break placeholder
  segments.push(`#EXT-X-DISCONTINUITY`);
  segments.push(`#EXT-X-CUE-OUT:DURATION=30`);
  segments.push(`## SSAI_PLACEHOLDER_START campaignId=__CAMPAIGN_ID__ duration=30`);
  segments.push(`## SSAI_PLACEHOLDER_END`);
  segments.push(`#EXT-X-CUE-IN`);
  segments.push(`#EXT-X-DISCONTINUITY`);

  // 4 more content segments after ad break
  for (let i = 5; i <= 8; i++) {
    segments.push(`#EXTINF:6.0,`);
    segments.push(`https://example.cloudfront.net/content/sports_1080p/seg_${String(i).padStart(3,"0")}.ts`);
  }

  return [
    `#EXTM3U`,
    `#EXT-X-VERSION:3`,
    `#EXT-X-TARGETDURATION:6`,
    ``,
    ...segments,
    ``,
    `#EXT-X-ENDLIST`,
  ].join("\n");
}

/**
 * Clear the manifest cache (useful for testing or after S3 upload).
 */
export function clearManifestCache(): void {
  manifestCache.clear();
}
