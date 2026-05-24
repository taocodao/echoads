import type { MoqTransport, MoqSubscription, MoqConnectOptions } from "./MoqTransport.js";

/**
 * Phase 1: Caton C3 Transport implementation.
 * Drop-in replacement for OpenSourceMoqTransport — same MoqTransport interface.
 *
 * TODO: Implement when Caton C3 SDK license is obtained.
 * Integration steps:
 *   1. npm install @caton/c3-node-sdk (package name TBD — confirm with Caton)
 *   2. Replace the throw statements below with actual C3 SDK calls
 *   3. Map C3 delivery metrics to MoqSegment (latencyMs → segment.timestampMs)
 *   4. Connect C3 NetScope telemetry to the SLA aggregator service
 *
 * The MoqTransport interface guarantees zero changes to AdManager, player, or API.
 */
export class CatonC3Transport implements MoqTransport {
  private c3Client: any = null;

  async connect(_relayUrl: string, _options?: MoqConnectOptions): Promise<void> {
    // TODO: const { C3Client } = await import('@caton/c3-node-sdk');
    // TODO: this.c3Client = new C3Client({ apiKey: process.env.C3_API_KEY, ... });
    // TODO: await this.c3Client.connect(_relayUrl);
    throw new Error(
      "[CatonC3Transport] Not yet implemented. " +
      "Caton C3 SDK license required. " +
      "Use OpenSourceMoqTransport for Phase 0."
    );
  }

  async subscribe(_namespace: string, _name: string): Promise<MoqSubscription> {
    throw new Error("[CatonC3Transport] Not yet implemented.");
  }

  async switchTrack(
    _currentSub: MoqSubscription,
    _newNamespace: string,
    _newName: string
  ): Promise<MoqSubscription> {
    // C3 provides native sub-frame track switching via CE-MoQ
    // This will replace the manual overlap pattern used in OpenSourceMoqTransport
    throw new Error("[CatonC3Transport] Not yet implemented.");
  }

  async publish(
    _namespace: string,
    _name: string,
    _source: ReadableStream<Uint8Array>
  ): Promise<void> {
    throw new Error("[CatonC3Transport] Not yet implemented.");
  }

  async getPingMs(): Promise<number> {
    // C3 NetScope provides real measured delivery latency
    // TODO: return this.c3Client.getNetScopeLatency();
    throw new Error("[CatonC3Transport] Not yet implemented.");
  }

  disconnect(): void {
    this.c3Client?.disconnect?.();
    this.c3Client = null;
  }
}
