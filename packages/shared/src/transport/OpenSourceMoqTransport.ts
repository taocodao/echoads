import type { MoqTransport, MoqSubscription, MoqConnectOptions } from "./MoqTransport.js";

/**
 * Phase 0 implementation using kixelated/moq-rs relay + @kixelated/moq browser client.
 * Implements MoqTransport interface so it can be swapped for CatonC3Transport in Phase 1.
 *
 * NOTE: This class uses dynamic import of @kixelated/moq because it is a browser-only
 * package (uses WebTransport API). In Node.js (API/node packages), use a mock or
 * the server-side moq-rs CLI tools directly.
 */
export class OpenSourceMoqTransport implements MoqTransport {
  private client: any = null;
  private relayUrl: string = "";

  async connect(relayUrl: string, options?: MoqConnectOptions): Promise<void> {
    this.relayUrl = relayUrl;

    // Dynamic import — browser only
    const moq = await import("@kixelated/moq");

    // @ts-ignore
    this.client = new moq.Client({
      url: relayUrl,
      // Pass cert fingerprint for local dev with self-signed certs
      ...(options?.certFingerprint && {
        fingerprint: options.certFingerprint,
      }),
    });

    await this.client.connect();
    console.log(`[MOQ] Connected to relay: ${relayUrl}`);
  }

  async subscribe(namespace: string, name: string): Promise<MoqSubscription> {
    if (!this.client) throw new Error("[MOQ] Not connected. Call connect() first.");

    const sub = await this.client.subscribe({ namespace, name });
    const trackPath = `${namespace}/${name}`;
    console.log(`[MOQ] Subscribed to track: ${trackPath}`);

    return {
      trackPath,
      segments: this._wrapSegments(sub),
      unsubscribe: () => {
        sub.close?.();
        console.log(`[MOQ] Unsubscribed from track: ${trackPath}`);
      },
    };
  }

  async switchTrack(
    currentSub: MoqSubscription,
    newNamespace: string,
    newName: string
  ): Promise<MoqSubscription> {
    // Subscribe to new track FIRST (overlap pattern — no black frame gap)
    const newSub = await this.subscribe(newNamespace, newName);

    // Now safe to drop the old subscription
    currentSub.unsubscribe();

    return newSub;
  }

  async publish(
    namespace: string,
    name: string,
    source: ReadableStream<Uint8Array>
  ): Promise<void> {
    if (!this.client) throw new Error("[MOQ] Not connected.");

    // @kixelated/moq publish API
    await this.client.publish({ namespace, name }, source);
    console.log(`[MOQ] Publishing track: ${namespace}/${name}`);
  }

  async getPingMs(): Promise<number> {
    if (!this.client) return -1;
    const start = performance.now();
    // WebTransport DATAGRAM round-trip as a ping proxy
    await this.client.ping?.();
    return Math.round(performance.now() - start);
  }

  disconnect(): void {
    this.client?.close?.();
    this.client = null;
    console.log("[MOQ] Disconnected from relay.");
  }

  private async *_wrapSegments(rawSub: any) {
    for await (const segment of rawSub) {
      yield {
        data: segment.data as Uint8Array,
        isKeyFrame: segment.keyframe ?? false,
        timestampMs: segment.timestamp ?? Date.now(),
        sequenceNumber: segment.sequence ?? 0,
      };
    }
  }
}
