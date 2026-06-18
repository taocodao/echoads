/**
 * push.service.ts — Phase 3.2 (Module 4)
 * APNs push notification service for churn re-engagement.
 * Uses the Node.js `apn` library (npm install apn).
 * Falls back to a console-log stub when credentials are not configured.
 *
 * Environment variables required for production:
 *   APNS_KEY_ID       — 10-char Key ID from Apple Developer Portal
 *   APNS_TEAM_ID      — 10-char Team ID
 *   APNS_KEY_PATH     — path to .p8 AuthKey file
 *   APNS_BUNDLE_ID    — e.g. com.arenza.app
 *   APNS_PRODUCTION   — "true" for production gateway, else sandbox
 */

import type { Pool } from "pg";

// ── Push Payload Templates ────────────────────────────────────────────────────
// GPT-4o-mini would generate these in production. Hardcoded variants for now.

const PUSH_VARIANTS: Record<string, { title: string; body: string; badge: number }> = {
  high_sport: {
    title: "The game's on! 🏈",
    body: "Big play just happened on ArenzaTV. Catch the highlights + earn rewards.",
    badge: 1,
  },
  high_reward: {
    title: "You have unclaimed rewards 🎖",
    body: "Open ArenzaTV to collect your points before they expire.",
    badge: 2,
  },
  medium_quiz: {
    title: "Quick question for you 🔮",
    body: "A new prediction is live. Answer now and earn bonus AXT points.",
    badge: 1,
  },
  low_med_fomo: {
    title: "Eagles game is LIVE 🦅",
    body: "Don't miss the action. Watch. Predict. Earn.",
    badge: 1,
  },
};

// ── APNs Client (lazy-loaded to avoid hard dep at startup) ────────────────────

let apnProvider: any = null;

async function getApnProvider() {
  if (apnProvider) return apnProvider;

  const keyId   = process.env.APNS_KEY_ID;
  const teamId  = process.env.APNS_TEAM_ID;
  const keyPath = process.env.APNS_KEY_PATH;

  if (!keyId || !teamId || !keyPath) {
    console.warn('[Push] APNs credentials not configured — running in stub mode');
    return null;
  }

  try {
    const apn = await import('apn');
    apnProvider = new apn.Provider({
      token: { key: keyPath, keyId, teamId },
      production: process.env.APNS_PRODUCTION === 'true',
    });
    return apnProvider;
  } catch {
    console.warn('[Push] apn package not installed — running in stub mode');
    return null;
  }
}

// ── Send a single push notification ─────────────────────────────────────────

export async function sendPush(
  deviceToken: string,
  variant: keyof typeof PUSH_VARIANTS
): Promise<{ sent: boolean; variant: string; stub?: boolean }> {
  const payload = PUSH_VARIANTS[variant] ?? PUSH_VARIANTS.high_sport;
  const provider = await getApnProvider();

  if (!provider) {
    // Stub mode — log and return success for demo purposes
    console.info(`[Push STUB] → ${deviceToken.slice(0, 12)}… | "${payload.title}"`);
    return { sent: true, variant, stub: true };
  }

  try {
    const { default: apn } = await import('apn');
    const note = new apn.Notification();
    note.expiry = Math.floor(Date.now() / 1000) + 3600;
    note.badge = payload.badge;
    note.alert = { title: payload.title, body: payload.body };
    note.topic = process.env.APNS_BUNDLE_ID ?? 'com.arenza.app';
    note.payload = { variant };

    const result = await provider.send(note, deviceToken);
    const sent = result.failed.length === 0;

    if (!sent) {
      console.error('[Push] APNs error:', result.failed[0]?.error);
    }

    return { sent, variant };
  } catch (err: any) {
    console.error('[Push] Send error:', err.message);
    return { sent: false, variant };
  }
}

// ── Batch Re-engagement Campaign ──────────────────────────────────────────────
// Called by the churn endpoint or a cron trigger.

export async function runReEngagementCampaign(pool: Pool): Promise<{
  attempted: number;
  sent: number;
  errors: number;
}> {
  // Fetch high-risk viewers with a device token who haven't been pushed yet
  const { rows } = await pool.query<{
    viewer_token: string;
    risk_tier: string;
    sport_affinities: Record<string, number>;
    apns_device_token: string | null;
  }>(`
    SELECT cs.viewer_token, cs.risk_tier, vp.sport_affinities,
           vp.signals_json->>'apnsDeviceToken' AS apns_device_token
    FROM churn_scores cs
    JOIN viewer_profiles vp ON vp.viewer_token = cs.viewer_token
    WHERE cs.push_sent = FALSE
      AND cs.risk_tier IN ('high', 'medium')
    ORDER BY cs.churn_risk DESC
    LIMIT 200
  `);

  let attempted = 0, sent = 0, errors = 0;

  for (const row of rows) {
    if (!row.apns_device_token) continue;
    attempted++;

    // Choose variant based on tier + top sport affinity
    const topSport = Object.entries(row.sport_affinities || {})
      .sort((a, b) => b[1] - a[1])[0]?.[0];

    const variant: keyof typeof PUSH_VARIANTS =
      row.risk_tier === 'high'
        ? topSport ? 'high_sport' : 'high_reward'
        : 'medium_quiz';

    const result = await sendPush(row.apns_device_token, variant);

    if (result.sent) {
      sent++;
      await pool.query(
        `UPDATE churn_scores
         SET push_sent=TRUE, push_variant=$1, push_sent_at=NOW()
         WHERE viewer_token=$2 AND push_sent=FALSE`,
        [variant, row.viewer_token]
      );
    } else {
      errors++;
    }
  }

  console.info(`[Push] Campaign done — attempted:${attempted} sent:${sent} errors:${errors}`);
  return { attempted, sent, errors };
}
