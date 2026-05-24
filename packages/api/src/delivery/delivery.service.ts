import { createClient } from "@supabase/supabase-js";

const supabase = createClient(
  process.env["SUPABASE_URL"] ?? "",
  process.env["SUPABASE_SERVICE_ROLE_KEY"] ?? ""
);

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

  const { error } = await supabase.from("deliveries").insert({
    delivery_id: deliveryId,
    slot_id: params.slotId,
    tx_hash: params.txHash,
    payer_address: params.payerAddress,
    amount_usdc: params.amountUsdc,
    switch_latency_ms: params.switchLatencyMs ?? null,
    segment_count: 1,
    oracle_submitted: false,
    delivered_at: new Date().toISOString(),
  });

  if (error) {
    console.error("[delivery-service] Failed to log delivery:", error);
    throw error;
  }

  return deliveryId;
}

/** Update latency after the player beacons back */
export async function updateDeliveryLatency(
  txHash: string,
  switchLatencyMs: number
): Promise<void> {
  const slaMet = switchLatencyMs < 500;
  const { error } = await supabase
    .from("deliveries")
    .update({ switch_latency_ms: switchLatencyMs, sla_met: slaMet })
    .eq("tx_hash", txHash);

  if (error) console.error("[delivery-service] Failed to update latency:", error);
}

/** Get all deliveries pending oracle submission */
export async function getPendingDeliveries(): Promise<PendingDelivery[]> {
  const { data, error } = await supabase
    .from("deliveries")
    .select("*")
    .eq("oracle_submitted", false)
    .not("switch_latency_ms", "is", null)
    .order("delivered_at", { ascending: true })
    .limit(50);

  if (error) {
    console.error("[delivery-service] Failed to fetch pending:", error);
    return [];
  }

  return (data ?? []).map((row: any) => ({
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
  const { error } = await supabase
    .from("deliveries")
    .update({ oracle_submitted: true, oracle_tx_hash: oracleTxHash })
    .eq("delivery_id", deliveryId);

  if (error) console.error("[delivery-service] Failed to mark submitted:", error);
}
