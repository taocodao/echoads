import { OpenSourceMoqTransport } from "@clarity/shared";
import type { MoqTransport, MoqSubscription } from "@clarity/shared";
import type { WalletClient } from "viem";
import { wrapFetch } from "@x402/fetch";
import { evm } from "@x402/evm";
import { SLA_LATENCY_THRESHOLD_MS, MOQ_NAMESPACE, MOQ_CONTENT_TRACK } from "@clarity/shared";
import type { AdReceipt } from "@clarity/shared";
import { PoDClient } from "../pod/PoDClient.js";
import { toHex, padHex } from "viem";

const API_BASE = import.meta.env["VITE_API_URL"] ?? "http://localhost:3001";

interface AdManagerConfig {
  relayUrl: string;
  walletClient: WalletClient;
  certFingerprint?: string;
  onAdReceipt?: (receipt: AdReceipt) => void;
  onLatencyMeasured?: (latencyMs: number, slaMet: boolean) => void;
}

export class ProjectClarityAdManager {
  private transport: MoqTransport;
  private x402Fetch: typeof fetch;
  private currentSub: MoqSubscription | null = null;
  private config: AdManagerConfig;
  private onSegment: ((segment: any) => void) | null = null;
  private podClient: PoDClient;

  constructor(config: AdManagerConfig) {
    this.config = config;
    this.transport = new OpenSourceMoqTransport();
    this.x402Fetch = wrapFetch(fetch, {
      evm,
      wallet: config.walletClient as any,
    });
    this.podClient = new PoDClient(
      config.walletClient,
      import.meta.env["VITE_ORACLE_CONTRACT_ADDRESS"] ?? "0x"
    );
  }

  async init(): Promise<void> {
    await this.transport.connect(this.config.relayUrl, {
      ...(this.config.certFingerprint ? { certFingerprint: this.config.certFingerprint } : {})
    });

    this.currentSub = await this.transport.subscribe(MOQ_NAMESPACE, MOQ_CONTENT_TRACK);
    console.log("[AdManager] Connected. Streaming content via MOQ/QUIC.");
  }

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

  async triggerAdBreak(slotId: string): Promise<AdReceipt | null> {
    console.log(`[AdManager] Ad break triggered: ${slotId}`);
    const t0 = performance.now();

    try {
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
        clearPrice?: number;
      };

      const switchStart = performance.now();

      if (!this.currentSub) throw new Error("No active subscription");

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

      if (data.txHash) {
        void this._beaconLatency(data.txHash, switchLatencyMs);
      }

      // Submit PoD on-chain
      if (data.txHash && data.clearPrice) {
        try {
          const cpmWei = BigInt(Math.floor(data.clearPrice * 100)); 
          const impressionId = padHex(toHex(slotId), { size: 32 });
          const nodeAddr = (import.meta.env["VITE_NODE_ADDRESS"] ?? "0x0000000000000000000000000000000000000000") as `0x${string}`;

          const podResult = await this.podClient.submitProofOfDelivery(impressionId, nodeAddr, cpmWei);
          console.log(`[AdManager] PoD submitted on-chain: ${podResult.basescanUrl}`);
        } catch (err) {
          console.error("[AdManager] PoD submission failed:", err);
        }
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
