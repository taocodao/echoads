// ============================================================
// Ad auction types
// ============================================================

/** Context provided to the auction engine for a given ad slot */
export interface SlotContext {
  slotId: string;
  channel: string;       // e.g., "espn", "freestream"
  positionMs: number;    // stream position when ad break fires
  deviceType: "web" | "ctv" | "mobile";
  viewerRegion?: string; // ISO 3166-1 alpha-2
}

/** Winning bid returned by the auction service */
export interface AdBid {
  adId: string;
  /** MOQ track name — e.g., "sling/ads/spot-abc123" */
  adTrackName: string;
  /** MOQ namespace */
  adNamespace: string;
  /** Local path or URL to the ad creative */
  creativePath: string;
  /** Duration in milliseconds */
  durationMs: number;
  /** Price in USDC (string to avoid float precision issues) */
  priceUsdc: string;
  advertiserId: string;
  /** Unix ms timestamp when this bid expires */
  expiresAt: number;
}

/** Receipt returned to the player after a successful ad play */
export interface AdReceipt {
  adId: string;
  slotId: string;
  /** x402 on-chain transaction hash */
  txHash: string;
  /** Actual measured track-switch latency in ms */
  switchLatencyMs: number;
  /** SLA target — always 500ms */
  slaTargetMs: number;
  /** Whether the SLA was met */
  slaMet: boolean;
  deliveredAt: number; // Unix ms
}
