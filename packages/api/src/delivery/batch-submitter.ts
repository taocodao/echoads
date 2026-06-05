/**
 * batch-submitter.ts
 * ─────────────────────────────────────────────────────────────────────────────
 * On-chain batch submission to DeliveryOracleV2.verifyAndMintBatch().
 *
 * Each PoDReceipt is signed off-chain by the PoD relay's oracle signer key.
 * The contract verifies the signer is in authorizedSigners and then mints
 * CMXS rewards per verified impression.
 *
 * Architecture:
 *   1. Receipts accumulate in the PodRelayService queue (in-process or Redis)
 *   2. This module is called when batch is full (50) or timer fires (60s)
 *   3. Signs each receipt with the oracle signer
 *   4. Submits the ReceiptBatch struct to DeliveryOracleV2
 *   5. Updates PostgreSQL to mark deliveries as oracle-submitted
 *   6. Retries on gas spikes with exponential backoff
 */

import {
  createWalletClient,
  createPublicClient,
  http,
  keccak256,
  encodePacked,
  type Hex,
} from "viem";
import { privateKeyToAccount } from "viem/accounts";
import { baseSepolia, base } from "viem/chains";
import { markDeliverySubmitted } from "./delivery.service.js";

// ── Contract ABI (DeliveryOracleV2) ──────────────────────────────────────────

// abitype does not support multi-line tuple ABI strings — use explicit ABI object
const ORACLE_V2_ABI = [
  {
    type: "function",
    name: "verifyAndMintBatch",
    stateMutability: "nonpayable",
    inputs: [
      {
        name: "batch",
        type: "tuple",
        components: [
          {
            name: "receipts",
            type: "tuple[]",
            components: [
              { name: "impressionId", type: "bytes32" },
              { name: "nodeOperator",  type: "address" },
              { name: "cpm",           type: "uint256" },
              { name: "timestamp",     type: "uint256" },
              { name: "latencyMs",     type: "uint256" },
              { name: "campaignId",    type: "bytes32" },
            ],
          },
          { name: "signatures", type: "bytes[]" },
        ],
      },
    ],
    outputs: [],
  },
  {
    type: "event",
    name: "BatchProcessed",
    inputs: [
      { name: "count",        type: "uint256", indexed: false },
      { name: "totalMinted",  type: "uint256", indexed: false },
    ],
  },
  {
    type: "event",
    name: "PoDVerified",
    inputs: [
      { name: "impressionId",  type: "bytes32", indexed: true },
      { name: "nodeOperator",  type: "address", indexed: true },
      { name: "cpm",           type: "uint256", indexed: false },
      { name: "latencyMs",     type: "uint256", indexed: false },
    ],
  },
] as const;

// ── Types ─────────────────────────────────────────────────────────────────────

export interface PoDReceiptParams {
  deliveryId: string;           // off-chain DB delivery ID (for markDeliverySubmitted)
  impressionId: Hex;            // bytes32 — unique impression identifier
  nodeOperator: Hex;            // node's ethereum address
  cpm: bigint;                  // USDC microunits (6 dec)
  timestampMs: number;          // Unix ms (viewer device time)
  latencyMs: number;            // measured track-switch latency
  campaignId: Hex;              // bytes32 — links to AdBurnV2 campaign
}

export interface BatchResult {
  txHash: Hex;
  impressionsSubmitted: number;
  totalMintedWei: bigint;
  basescanUrl: string;
}

// ── Signer setup ──────────────────────────────────────────────────────────────

const ORACLE_PRIVATE_KEY = (process.env["ORACLE_PRIVATE_KEY"] as Hex | undefined);
const IS_MAINNET = process.env["CHAIN"] === "base-mainnet";
const chain = IS_MAINNET ? base : baseSepolia;
const RPC_URL = IS_MAINNET
  ? process.env["BASE_MAINNET_RPC_URL"]
  : process.env["BASE_SEPOLIA_RPC_URL"];

const ORACLE_V2_ADDRESS = (
  IS_MAINNET
    ? process.env["DELIVERY_ORACLE_V2_ADDRESS_MAINNET"]
    : process.env["DELIVERY_ORACLE_V2_ADDRESS_SEPOLIA"]
) as Hex;

// Use a safe zero-padded placeholder when key not set — crashes only on actual submission
const SAFE_ORACLE_KEY: Hex = ORACLE_PRIVATE_KEY && ORACLE_PRIVATE_KEY !== "0x"
  ? ORACLE_PRIVATE_KEY
  : "0x0000000000000000000000000000000000000000000000000000000000000001";

if (!ORACLE_PRIVATE_KEY || ORACLE_PRIVATE_KEY === "0x") {
  console.warn("[batch-submitter] ORACLE_PRIVATE_KEY not set — batch submission will fail.");
}

const signerAccount = privateKeyToAccount(SAFE_ORACLE_KEY);

const walletClient = createWalletClient({
  account: signerAccount,
  chain,
  transport: http(RPC_URL),
});

const publicClient = createPublicClient({
  chain,
  transport: http(RPC_URL),
});

console.log(`[batch-submitter] Signer: ${signerAccount.address}`);
console.log(`[batch-submitter] Oracle V2: ${ORACLE_V2_ADDRESS ?? "(not configured)"}`);
console.log(`[batch-submitter] Chain: ${IS_MAINNET ? "Base Mainnet" : "Base Sepolia"}`);

// ── Signing ───────────────────────────────────────────────────────────────────

/**
 * Sign a single PoD receipt for submission to DeliveryOracleV2.
 * Message format MUST match the contract:
 *   keccak256(abi.encodePacked(impressionId, nodeOperator, cpm, timestamp, latencyMs, campaignId, chainId))
 */
async function signReceipt(r: PoDReceiptParams): Promise<Hex> {
  const chainId = BigInt(IS_MAINNET ? 8453 : 84532);

  const msgHash = keccak256(
    encodePacked(
      ["bytes32", "address", "uint256", "uint256", "uint256", "bytes32", "uint256"],
      [
        r.impressionId,
        r.nodeOperator,
        r.cpm,
        BigInt(r.timestampMs),
        BigInt(r.latencyMs),
        r.campaignId,
        chainId,
      ]
    )
  );

  // signMessage applies EIP-191 prefix — matches MessageHashUtils.toEthSignedMessageHash()
  return signerAccount.signMessage({ message: { raw: msgHash } });
}

// ── Batch Submission ──────────────────────────────────────────────────────────

const MAX_RETRIES    = 3;
const RETRY_DELAY_MS = 2000;

/**
 * Sign and submit a batch of PoD receipts to DeliveryOracleV2.verifyAndMintBatch().
 *
 * @param receipts Up to 50 receipts (MAX_BATCH_SIZE from contract)
 * @returns BatchResult with txHash and counts
 */
export async function submitBatch(receipts: PoDReceiptParams[]): Promise<BatchResult> {
  if (receipts.length === 0) throw new Error("Empty batch");
  if (receipts.length > 50)  throw new Error("Batch exceeds MAX_BATCH_SIZE (50)");
  if (!ORACLE_V2_ADDRESS)    throw new Error("DELIVERY_ORACLE_V2_ADDRESS not configured");

  console.log(`[batch-submitter] Signing ${receipts.length} receipts...`);

  // Sign all receipts in parallel
  const signatures = await Promise.all(receipts.map(signReceipt));

  // Build the ReceiptBatch struct
  const batch = {
    receipts: receipts.map((r) => ({
      impressionId: r.impressionId,
      nodeOperator: r.nodeOperator,
      cpm:          r.cpm,
      timestamp:    BigInt(r.timestampMs),
      latencyMs:    BigInt(r.latencyMs),
      campaignId:   r.campaignId,
    })),
    signatures,
  };

  // Submit with retry on gas spike / nonce collision
  let lastErr: unknown;
  for (let attempt = 1; attempt <= MAX_RETRIES; attempt++) {
    try {
      console.log(`[batch-submitter] Submitting batch (attempt ${attempt}/${MAX_RETRIES})...`);

      const txHash = await walletClient.writeContract({
        address: ORACLE_V2_ADDRESS,
        abi:     ORACLE_V2_ABI,
        functionName: "verifyAndMintBatch",
        args:    [batch],
      });

      console.log(`[batch-submitter] Tx sent: ${txHash} — waiting for receipt...`);

      const receipt = await publicClient.waitForTransactionReceipt({
        hash:    txHash,
        timeout: 60_000,
      });

      if (receipt.status === "reverted") {
        throw new Error(`Tx reverted: ${txHash}`);
      }

      // Parse BatchProcessed event for totalMinted
      let totalMintedWei = 0n;
      for (const log of receipt.logs) {
        if (log.address.toLowerCase() === ORACLE_V2_ADDRESS.toLowerCase()) {
          // BatchProcessed(uint256 count, uint256 totalMinted)
          // topic[0] = event selector, data = abi-encoded count + totalMinted
          if (log.data && log.data.length >= 130) {
            // Decode: first 32 bytes = count, next 32 = totalMinted
            totalMintedWei = BigInt("0x" + log.data.slice(66, 130));
          }
        }
      }

      const basescanBase = IS_MAINNET
        ? "https://basescan.org"
        : "https://sepolia.basescan.org";

      console.log(`[batch-submitter] ✅ Batch confirmed: ${receipt.transactionHash} (${receipts.length} proofs, ${totalMintedWei / BigInt(1e15)} mCMXS minted)`);

      // Mark all as oracle-submitted in PostgreSQL
      await Promise.all(
        receipts.map((r) => markDeliverySubmitted(r.deliveryId, receipt.transactionHash))
      );

      return {
        txHash:               receipt.transactionHash,
        impressionsSubmitted: receipts.length,
        totalMintedWei,
        basescanUrl:          `${basescanBase}/tx/${receipt.transactionHash}`,
      };
    } catch (err) {
      lastErr = err;
      console.error(`[batch-submitter] ❌ Attempt ${attempt} failed:`, err);
      if (attempt < MAX_RETRIES) {
        const delay = RETRY_DELAY_MS * Math.pow(2, attempt - 1); // exponential backoff
        console.log(`[batch-submitter] Retrying in ${delay}ms...`);
        await new Promise((res) => setTimeout(res, delay));
      }
    }
  }

  throw lastErr ?? new Error("Batch submission failed after all retries");
}
