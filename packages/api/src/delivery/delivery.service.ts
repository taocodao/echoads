import pg from "pg";

// Use DATABASE_URL (connection string) from environment.
// Format: postgresql://user:pass@host:5432/echoads
const pool = new pg.Pool({
  connectionString: process.env["DATABASE_URL"],
  ssl: { rejectUnauthorized: false }, // AWS RDS requires SSL
  max: 5, // keep pool small for serverless
  idleTimeoutMillis: 10000,
});

export interface PendingDelivery {
  deliveryId: string;
  slotId: string;
  txHash: string;
  payerAddress: string;
  amountUsdc: string;
  switchLatencyMs: number;
  segmentCount: number;
  deliveredAt: string;
  oracleSubmitted: boolean;
  oracleTxHash?: string;
}

/** Log a new delivery from the x402 onSuccess callback */
export async function logDelivery(params: {
  slotId: string;
  txHash: string;
  payerAddress: string;
  amountUsdc: string;
  switchLatencyMs?: number;
}): Promise<string> {
  const deliveryId = `${params.txHash}-${Date.now()}`;

  await pool.query(
    `INSERT INTO deliveries
       (delivery_id, slot_id, tx_hash, payer_address, amount_usdc,
        switch_latency_ms, segment_count, oracle_submitted, delivered_at)
     VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9)`,
    [
      deliveryId,
      params.slotId,
      params.txHash,
      params.payerAddress,
      params.amountUsdc,
      params.switchLatencyMs ?? null,
      1,
      false,
      new Date().toISOString(),
    ]
  );

  return deliveryId;
}

/** Update latency after the player beacons back */
export async function updateDeliveryLatency(
  txHash: string,
  switchLatencyMs: number
): Promise<void> {
  await pool.query(
    `UPDATE deliveries SET switch_latency_ms = $1 WHERE tx_hash = $2`,
    [switchLatencyMs, txHash]
  );
}

/** Get all deliveries pending oracle submission */
export async function getPendingDeliveries(): Promise<PendingDelivery[]> {
  const { rows } = await pool.query(
    `SELECT * FROM deliveries
     WHERE oracle_submitted = false
       AND switch_latency_ms IS NOT NULL
     ORDER BY delivered_at ASC
     LIMIT 50`
  );

  return rows.map((row: any) => ({
    deliveryId: row.delivery_id,
    slotId: row.slot_id,
    txHash: row.tx_hash,
    payerAddress: row.payer_address,
    amountUsdc: row.amount_usdc,
    switchLatencyMs: row.switch_latency_ms,
    segmentCount: row.segment_count ?? 1,
    deliveredAt: row.delivered_at,
    oracleSubmitted: row.oracle_submitted,
    oracleTxHash: row.oracle_tx_hash,
  }));
}

/** Mark a delivery as submitted to the oracle */
export async function markDeliverySubmitted(
  deliveryId: string,
  oracleTxHash: string
): Promise<void> {
  await pool.query(
    `UPDATE deliveries SET oracle_submitted = true, oracle_tx_hash = $1 WHERE delivery_id = $2`,
    [oracleTxHash, deliveryId]
  );
}

/** Write a failed receipt to the dead_letters table after all retries exhausted */
export async function writeDeadLetter(params: {
  impressionId: string;
  nodeOperator: string;
  campaignId:   string;
  cpm:          string;
  timestampMs:  number;
  latencyMs:    number;
}): Promise<void> {
  await pool.query(
    `INSERT INTO dead_letters
       (impression_id, node_operator, campaign_id, cpm, timestamp_ms, latency_ms, failed_at)
     VALUES ($1, $2, $3, $4, $5, $6, NOW())
     ON CONFLICT (impression_id) DO NOTHING`,
    [
      params.impressionId,
      params.nodeOperator,
      params.campaignId,
      params.cpm,
      params.timestampMs,
      params.latencyMs,
    ]
  );
}
