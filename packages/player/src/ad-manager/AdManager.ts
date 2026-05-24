import { OpenSourceMoqTransport } from "@clarity/shared";
import type { MoqTransport, MoqSubscription } from "@clarity/shared";
import type { WalletClient } from "viem";
import { wrapFetch } from "@x402/fetch";
import { evm } from "@x402/evm";
import { SLA_LATENCY_THRESHOLD_MS, MOQ_NAMESPACE, MOQ_CONTENT_TRACK } from "@clarity/shared";
import type { AdReceipt } from "@clarity/shared";

const API_BASE = import.meta.env["VITE_API_URL"] ?? "http://localhost:3001";

interface AdManagerConfig {
  relayUrl: string;
  walletClient: WalletClient;
  certFingerprint?: string;
  onAdReceipt?: (receipt: AdReceipt) => void;
  onLatencyMeasured?: (latencyMs: number, slaMet: boolean) => void;
}

/**
 * ProjectClarityAdManager
 *
 * Manages the full ad break lifecycle:
 *   1. Receive ad cue
 *   2. Pay for ad slot via x402 (HTTP layer)
 *   3. Switch MOQ track (QUIC layer) — subscribe-before-unsubscribe pattern
 *   4. Measure track-switch latency
 *   5. Beacon latency back to API for SLA recording
 *   6. Return to content track after ad duration
 *
 * Uses MoqTransport interface — swap OpenSourceMoqTransport for CatonC3Transport
 * when C3 SDK is available. Zero changes to this class needed.
 */
export class ProjectClarityAdManager {
  private transport: MoqTransport;
  private x402Fetch: typeof fetch;
  private currentSub: MoqSubscription | null = null;
  private config: AdManagerConfig;
  private onSegment: ((segment: any) => void) | null = null;

  constructor(config: AdManagerConfig) {
    this.config = config;
    this.transport = new OpenSourceMoqTransport();
    this.x402Fetch = wrapFetch(fetch, {
      evm,
      wallet: config.walletClient as any,
    });
  }

  /** Connect to the MOQ relay and subscribe to the content track */
  async init(): Promise<void> {
    await this.transport.connect(this.config.relayUrl, {
      certFingerprint: this.config.certFingerprint as string | undefined,
    });

    this.currentSub = await this.transport.subscribe(MOQ_NAMESPACE, MOQ_CONTENT_TRACK);
    console.log("[AdManager] Connected. Streaming content via MOQ/QUIC.");
  }

  /** Register a callback to receive MOQ video segments for rendering */
  onVideoSegment(callback: (segment: any) => void): void {
    this.onSegment = callback;
    this._startSegmentLoop();
  }

  private async _startSegmentLoop(): Promise<void> {
    if (!this.currentSub || !this.onSegment) return;
    for await (const segment of this.currentSub.segments) {
      this.onSegment(segment);
    }
  }

  /**
   * Trigger an ad break:
   * 1. Pay for the slot via x402 → get adTrackName
   * 2. Switch MOQ track (measure latency)
   * 3. Return to content after ad duration
   */
  async triggerAdBreak(slotId: string): Promise<AdReceipt | null> {
    console.log(`[AdManager] Ad break triggered: ${slotId}`);
    const t0 = performance.now();

    try {
      // Step 1: HTTP auction with automatic x402 payment
      // @x402/fetch handles: initial GET → 402 response → sign → retry → 200
      const response = await this.x402Fetch(
        `${API_BASE}/api/auction/${slotId}?channel=${MOQ_NAMESPACE}`
      );

      if (!response.ok) {
        console.error("[AdManager] Auction failed:", response.status);
        return null;
      }

      const data = await response.json() as {
        adId: string;
        adNamespace: string;
        adTrackName: string;
        durationMs: number;
        txHash?: string;
      };

      // Step 2: Switch to ad track (measure switch latency)
      const switchStart = performance.now();

      if (!this.currentSub) throw new Error("No active subscription");

      // Subscribe-before-unsubscribe: overlap eliminates black frames
      const adSub = await this.transport.switchTrack(
        this.currentSub,
        data.adNamespace,
        data.adTrackName
      );
      this.currentSub = adSub;

      const switchLatencyMs = performance.now() - switchStart;
      const slaMet = switchLatencyMs < SLA_LATENCY_THRESHOLD_MS;

      console.log(
        `[AdManager] Track switch: ${switchLatencyMs.toFixed(1)}ms (SLA: ${slaMet ? "✅ MET" : "❌ MISSED"})`
      );

      // Step 3: Beacon latency back to API
      if (data.txHash) {
        void this._beaconLatency(data.txHash, switchLatencyMs);
      }

      const receipt: AdReceipt = {
        adId: data.adId,
        slotId,
        txHash: data.txHash ?? "",
        switchLatencyMs,
        slaTargetMs: SLA_LATENCY_THRESHOLD_MS,
        slaMet,
        deliveredAt: Date.now(),
      };

      this.config.onAdReceipt?.(receipt);
      this.config.onLatencyMeasured?.(switchLatencyMs, slaMet);

      // Step 4: Return to content after ad duration
      setTimeout(() => void this._returnToContent(), data.durationMs);

      return receipt;
    } catch (err) {
      console.error("[AdManager] Ad break failed — staying on content:", err);
      return null;
    }
  }

  private async _returnToContent(): Promise<void> {
    if (!this.currentSub) return;
    console.log("[AdManager] Returning to content track...");
    this.currentSub = await this.transport.switchTrack(
      this.currentSub,
      MOQ_NAMESPACE,
      MOQ_CONTENT_TRACK
    );
    console.log("[AdManager] ✅ Content track restored.");
  }

  private async _beaconLatency(txHash: string, switchLatencyMs: number): Promise<void> {
    try {
      await fetch(`${API_BASE}/api/delivery/beacon`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ txHash, switchLatencyMs }),
      });
    } catch (err) {
      console.warn("[AdManager] Latency beacon failed (non-critical):", err);
    }
  }

  disconnect(): void {
    this.currentSub?.unsubscribe();
    this.transport.disconnect();
  }
}
