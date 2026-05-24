// ============================================================
// MoqTransport — interface that abstracts kixelated/moq-rs (Phase 0)
// and Caton C3 SDK (Phase 1). All player/API code uses this interface.
// To plug in C3: implement CatonC3Transport and swap it at the call site.
// ============================================================

/** A live subscription to a single MOQ track */
export interface MoqSubscription {
  /** The full track path: namespace + "/" + name */
  trackPath: string;
  /** Async iterable of raw segment data */
  segments: AsyncIterable<MoqSegment>;
  /** Unsubscribe and close the QUIC stream */
  unsubscribe(): void;
}

/** A single MOQ segment (one frame or group of frames) */
export interface MoqSegment {
  data: Uint8Array;
  isKeyFrame: boolean;
  timestampMs: number;
  sequenceNumber: number;
}

/** The transport interface. Phase 0: OpenSourceMoqTransport. Phase 1: CatonC3Transport. */
export interface MoqTransport {
  /** Connect to the MOQ relay. Must be called before subscribe/publish. */
  connect(relayUrl: string, options?: MoqConnectOptions): Promise<void>;

  /** Subscribe to a named track. Returns immediately; segments arrive async. */
  subscribe(namespace: string, name: string): Promise<MoqSubscription>;

  /**
   * Subscribe to a new track before unsubscribing the current one.
   * This is the "overlap" pattern that eliminates black frames.
   * Both subscriptions are briefly active during the transition.
   */
  switchTrack(
    currentSub: MoqSubscription,
    newNamespace: string,
    newName: string
  ): Promise<MoqSubscription>;

  /** Publish a readable stream as a MOQ track */
  publish(namespace: string, name: string, source: ReadableStream<Uint8Array>): Promise<void>;

  /** Returns the round-trip latency to the relay in ms */
  getPingMs(): Promise<number>;

  /** Disconnect from the relay */
  disconnect(): void;
}

export interface MoqConnectOptions {
  /**
   * TLS certificate fingerprint for self-signed certs (local dev only).
   * Get this from the moq-certgen output or: openssl x509 -fingerprint -sha256 -in cert.pem
   */
  certFingerprint?: string;
  /** Connection timeout in ms. Default: 5000 */
  timeoutMs?: number;
}
