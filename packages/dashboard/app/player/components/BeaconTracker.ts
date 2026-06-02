/**
 * BeaconTracker.ts
 * ─────────────────────────────────────────────────────────────────────────────
 * Fires VAST 4.1-spec quartile completion beacons during ad playback.
 * Tracks elapsed time per ad slot and triggers callbacks at:
 *   start (0%), firstQuartile (25%), midpoint (50%), thirdQuartile (75%), complete (100%)
 *
 * The `complete` event is the trigger for PoD receipt signing.
 */

export type QuartileEvent = "start" | "firstQuartile" | "midpoint" | "thirdQuartile" | "complete";

export interface BeaconEvent {
  quartile: QuartileEvent;
  impressionId: string;
  elapsedMs: number;
  adDurationMs: number;
  timestamp: number;
}

export type BeaconCallback = (event: BeaconEvent) => void;

interface TrackedAd {
  impressionId: string;
  durationMs: number;
  startedAt: number;
  fired: Set<QuartileEvent>;
}

const QUARTILE_THRESHOLDS: Array<{ quartile: QuartileEvent; pct: number }> = [
  { quartile: "start",          pct: 0   },
  { quartile: "firstQuartile",  pct: 0.25 },
  { quartile: "midpoint",       pct: 0.50 },
  { quartile: "thirdQuartile",  pct: 0.75 },
  { quartile: "complete",       pct: 1.00 },
];

export class BeaconTracker {
  private current: TrackedAd | null = null;
  private tickerId: ReturnType<typeof setInterval> | null = null;
  private callbacks: BeaconCallback[] = [];

  onBeacon(cb: BeaconCallback): () => void {
    this.callbacks.push(cb);
    return () => { this.callbacks = this.callbacks.filter((c) => c !== cb); };
  }

  /**
   * Start tracking a new ad slot.
   * Fires the "start" beacon immediately.
   */
  startAd(impressionId: string, durationSeconds: number): void {
    this.stopAd(); // clean up any previous
    this.current = {
      impressionId,
      durationMs: durationSeconds * 1000,
      startedAt: Date.now(),
      fired: new Set(),
    };

    // Tick every 250ms to check quartile thresholds
    this.tickerId = setInterval(() => this.tick(), 250);
    this.fireQuartile("start");
  }

  /**
   * Manually advance to a specific playback position (e.g., from HLS.js currentTime).
   * Call this whenever the video's currentTime updates.
   */
  updatePosition(currentTimeSeconds: number): void {
    if (!this.current) return;
    const elapsedMs = currentTimeSeconds * 1000;
    this.checkThresholds(elapsedMs);
  }

  stopAd(): void {
    if (this.tickerId !== null) {
      clearInterval(this.tickerId);
      this.tickerId = null;
    }
    this.current = null;
  }

  private tick(): void {
    if (!this.current) return;
    const elapsedMs = Date.now() - this.current.startedAt;
    this.checkThresholds(elapsedMs);
  }

  private checkThresholds(elapsedMs: number): void {
    if (!this.current) return;
    const pct = elapsedMs / this.current.durationMs;

    for (const { quartile, pct: threshold } of QUARTILE_THRESHOLDS) {
      if (quartile === "start") continue; // fired at startAd()
      if (!this.current.fired.has(quartile) && pct >= threshold) {
        this.fireQuartile(quartile);
        if (quartile === "complete") {
          this.stopAd();
          return;
        }
      }
    }
  }

  private fireQuartile(quartile: QuartileEvent): void {
    if (!this.current) return;
    this.current.fired.add(quartile);
    const event: BeaconEvent = {
      quartile,
      impressionId: this.current.impressionId,
      elapsedMs: Date.now() - this.current.startedAt,
      adDurationMs: this.current.durationMs,
      timestamp: Date.now(),
    };
    for (const cb of this.callbacks) {
      try { cb(event); } catch { /* swallow */ }
    }
  }

  getCurrentProgress(): number {
    if (!this.current) return 0;
    return Math.min((Date.now() - this.current.startedAt) / this.current.durationMs, 1);
  }

  isTracking(): boolean {
    return this.current !== null;
  }
}
