// ============================================================
// Delivery proof and SLA types
// ============================================================

/** A single ad delivery record — stored in Supabase, submitted to oracle */
export interface DeliveryRecord {
  deliveryId: string;     // keccak256(txHash + nodeId + timestamp)
  nodeAddress: string;    // 0x-prefixed node operator wallet
  slotId: string;
  adId: string;
  txHash: string;         // x402 payment tx hash
  segmentCount: number;   // number of MOQ segments delivered
  switchLatencyMs: number;
  deliveredAt: number;    // Unix ms
  slaTarget: 500;         // always 500ms in Phase 0
  slaMet: boolean;
  oracleSubmitted: boolean;
  oracleTxHash?: string;  // set after oracle contract tx confirms
}

/** Batch of proofs prepared for on-chain submission */
export interface DeliveryBatch {
  batchId: string;
  deliveries: DeliveryRecord[];
  /** Merkle root of deliveryIds (for future upgrade) */
  merkleRoot: string;
  createdAt: number;
}

/** SLA telemetry metrics for a given time window */
export interface SLAMetrics {
  windowStart: number;
  windowEnd: number;
  totalDeliveries: number;
  slaPassCount: number;
  slaFailCount: number;
  p50LatencyMs: number;
  p95LatencyMs: number;
  p99LatencyMs: number;
  cmxsMinted: bigint;
}
