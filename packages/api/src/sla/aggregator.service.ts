import { createPublicClient, createWalletClient, http, parseAbi } from "viem";
import { privateKeyToAccount } from "viem/accounts";
import { baseSepolia } from "viem/chains";
import { signDeliveryProof } from "./oracle.service.js";
import { getPendingDeliveries, markDeliverySubmitted } from "../delivery/delivery.service.js";
import { SLA_LATENCY_THRESHOLD_MS, SLA_BATCH_INTERVAL_MS, PROOF_EXPIRY_SECONDS } from "@clarity/shared";
import { keccak256, encodePacked } from "viem";

const ORACLE_ABI = parseAbi([
  "function submitDeliveryProof(bytes32 deliveryId, address nodeOperator, uint256 segmentCount, uint256 latencyMs, uint256 expiry, bytes calldata signature) external",
]);

const deployerAccount = privateKeyToAccount(
  (process.env["ORACLE_PRIVATE_KEY"] ?? "0x0") as `0x${string}`
);

const publicClient = createPublicClient({
  chain: baseSepolia,
  transport: http(process.env["BASE_SEPOLIA_RPC_URL"]),
});

const walletClient = createWalletClient({
  account: deployerAccount,
  chain: baseSepolia,
  transport: http(process.env["BASE_SEPOLIA_RPC_URL"]),
});

const ORACLE_CONTRACT = (process.env["ORACLE_CONTRACT_ADDRESS"] ?? "0x") as `0x${string}`;
const NODE_ADDRESS = (process.env["NODE_WALLET_ADDRESS"] ?? "0x") as `0x${string}`;

/**
 * Submit a batch of pending delivery proofs to the oracle contract.
 * Called automatically every SLA_BATCH_INTERVAL_MS (60 seconds),
 * or manually via POST /api/sla/trigger (for demo purposes).
 */
export async function runSlaBatch(): Promise<{ submitted: number; failed: number }> {
  const pending = await getPendingDeliveries();

  if (pending.length === 0) {
    console.log("[sla-aggregator] No pending deliveries to submit.");
    return { submitted: 0, failed: 0 };
  }

  console.log(`[sla-aggregator] Processing ${pending.length} pending deliveries...`);

  let submitted = 0;
  let failed = 0;

  for (const delivery of pending) {
    try {
      // Only submit if SLA was met (latency < 500ms)
      // The oracle contract trusts our signature — we enforce SLA here off-chain
      if (delivery.switchLatencyMs >= SLA_LATENCY_THRESHOLD_MS) {
        console.log(`[sla-aggregator] Skipping ${delivery.deliveryId} — SLA not met (${delivery.switchLatencyMs}ms)`);
        continue;
      }

      const expiry = BigInt(Math.floor(Date.now() / 1000) + PROOF_EXPIRY_SECONDS);

      const deliveryId = keccak256(
        encodePacked(["string", "string"], [delivery.txHash, delivery.deliveryId])
      );

      const signature = await signDeliveryProof({
        deliveryId,
        nodeOperator: NODE_ADDRESS,
        segmentCount: BigInt(delivery.segmentCount ?? 1),
        latencyMs: BigInt(Math.round(delivery.switchLatencyMs)),
        expiry,
      });

      const txHash = await walletClient.writeContract({
        address: ORACLE_CONTRACT,
        abi: ORACLE_ABI,
        functionName: "submitDeliveryProof",
        args: [
          deliveryId,
          NODE_ADDRESS,
          BigInt(delivery.segmentCount ?? 1),
          BigInt(Math.round(delivery.switchLatencyMs)),
          expiry,
          signature,
        ],
      });

      await publicClient.waitForTransactionReceipt({ hash: txHash });
      await markDeliverySubmitted(delivery.deliveryId, txHash);

      console.log(`[sla-aggregator] ✅ Proof submitted: ${delivery.deliveryId} → ${txHash}`);
      submitted++;
    } catch (err) {
      console.error(`[sla-aggregator] ❌ Failed for ${delivery.deliveryId}:`, err);
      failed++;
    }
  }

  return { submitted, failed };
}

/** Start the automatic 60-second batch loop */
export function startSlaBatchLoop(): void {
  console.log(`[sla-aggregator] Starting batch loop every ${SLA_BATCH_INTERVAL_MS / 1000}s`);
  setInterval(async () => {
    const result = await runSlaBatch();
    console.log(`[sla-aggregator] Batch complete:`, result);
  }, SLA_BATCH_INTERVAL_MS);
}
