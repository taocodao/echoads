/**
 * PodClient.ts
 * ─────────────────────────────────────────────────────────────────────────────
 * Browser-side PoD (Proof-of-Delivery) receipt submitter.
 * Constructs a receipt from ad completion data and POSTs to /api/delivery/pod.
 *
 * The server-side batch-submitter.ts handles ECDSA signing + on-chain submission,
 * so this client just delivers the raw receipt data over HTTPS.
 *
 * Also maintains a local receipt log for the live PoD feed panel.
 */

const API_BASE = process.env["NEXT_PUBLIC_API_URL"] ?? "http://localhost:3001";

export interface PoDReceiptInput {
  impressionId: string;     // hex string, unique per impression
  nodeOperator: string;     // 0x address of the delivery node
  cpm: number;              // winning CPM in USD (e.g., 42.50)
  campaignId: string;       // bytes32 hex campaign ID
  latencyMs: number;        // measured ad delivery latency
  advertiser: string;       // display name for feed
  product?: string;         // for x302 overlay tracking
}

export interface PoDReceiptStatus {
  impressionId: string;
  status: "queued" | "confirmed" | "failed";
  queueDepth?: number;
  txHash?: string;
  error?: string;
  submittedAt: number;
}

// ── Local receipt log (ring buffer — 50 most recent) ─────────────────────────
const MAX_LOG = 50;
const receiptLog: PoDReceiptStatus[] = [];
const logListeners: Array<(log: PoDReceiptStatus[]) => void> = [];

function appendToLog(entry: PoDReceiptStatus): void {
  receiptLog.unshift(entry);
  if (receiptLog.length > MAX_LOG) receiptLog.pop();
  logListeners.forEach((cb) => cb([...receiptLog]));
}

export function subscribeToReceiptLog(
  cb: (log: PoDReceiptStatus[]) => void
): () => void {
  logListeners.push(cb);
  cb([...receiptLog]); // immediate snapshot
  return () => {
    const idx = logListeners.indexOf(cb);
    if (idx !== -1) logListeners.splice(idx, 1);
  };
}

export function getReceiptLog(): PoDReceiptStatus[] {
  return [...receiptLog];
}

// ── Main Submitter ────────────────────────────────────────────────────────────

/**
 * Submit a PoD receipt to the API relay service.
 * The relay handles deduplication (Redis), batching, and on-chain submission.
 *
 * @returns receipt status (queued immediately, confirmed async)
 */
export async function submitPoD(input: PoDReceiptInput): Promise<PoDReceiptStatus> {
  const submittedAt = Date.now();

  // Optimistically log as "queued"
  const entry: PoDReceiptStatus = {
    impressionId: input.impressionId,
    status: "queued",
    submittedAt,
  };
  appendToLog(entry);

  try {
    const res = await fetch(`${API_BASE}/api/delivery/pod`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        impressionId: input.impressionId,
        nodeOperator: input.nodeOperator,
        cpm: Math.round(input.cpm * 1_000_000), // convert to USDC microunits
        timestampMs: submittedAt,
        latencyMs: Math.round(input.latencyMs),
        campaignId: input.campaignId,
      }),
    });

    const data = await res.json() as { status?: string; queueDepth?: number; error?: string };

    const updated: PoDReceiptStatus = {
      ...entry,
      status: res.ok ? "queued" : "failed",
      ...(data.queueDepth !== undefined ? { queueDepth: data.queueDepth } : {}),
      ...(data.error !== undefined ? { error: data.error } : {}),
    };
    // Update in log
    const idx = receiptLog.findIndex((r) => r.impressionId === input.impressionId);
    if (idx !== -1) receiptLog[idx] = updated;
    logListeners.forEach((cb) => cb([...receiptLog]));

    return updated;
  } catch (err) {
    const failed: PoDReceiptStatus = {
      ...entry,
      status: "failed",
      error: err instanceof Error ? err.message : "Network error",
    };
    const idx = receiptLog.findIndex((r) => r.impressionId === input.impressionId);
    if (idx !== -1) receiptLog[idx] = failed;
    logListeners.forEach((cb) => cb([...receiptLog]));
    return failed;
  }
}

// ── Poll for on-chain confirmation ───────────────────────────────────────────

/**
 * Poll relay status to detect when a queued receipt gets confirmed on-chain.
 * Updates the local log entry when txHash is seen.
 */
export async function pollForConfirmation(
  impressionId: string,
  intervalMs = 5000,
  maxAttempts = 12
): Promise<string | null> {
  for (let i = 0; i < maxAttempts; i++) {
    await new Promise((r) => setTimeout(r, intervalMs));
    try {
      const res = await fetch(`${API_BASE}/api/delivery/relay-status`);
      if (!res.ok) continue;
      const data = await res.json() as { recentBatches?: Array<{ txHash: string; impressionIds: string[] }> };

      const batch = data.recentBatches?.find((b) =>
        b.impressionIds?.includes(impressionId)
      );
      if (batch?.txHash) {
        const idx = receiptLog.findIndex((r) => r.impressionId === impressionId);
        if (idx !== -1) {
          receiptLog[idx] = { ...receiptLog[idx]!, status: "confirmed", txHash: batch.txHash };
          logListeners.forEach((cb) => cb([...receiptLog]));
        }
        return batch.txHash;
      }
    } catch { /* retry */ }
  }
  return null;
}
