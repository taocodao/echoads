import type { AdBid, SlotContext } from "@clarity/shared";
import { buildAdTrackName } from "@clarity/shared";
import { simulateDSPBids } from "./dsp-simulator.js";
import { createWalletClient, http, parseAbi } from "viem";
import { privateKeyToAccount } from "viem/accounts";
import { baseSepolia } from "viem/chains";
import pg from "pg";

const pool = new pg.Pool({
  connectionString: process.env["DATABASE_URL"],
  ssl: { rejectUnauthorized: false },
});

const AUCTION_ABI = parseAbi([
  "function recordWinner(bytes32 slotId, uint256 floorCPM, address winner, uint256 winningCPM) external",
]);
const AUCTION_CONTRACT = (process.env["AUCTION_CONTRACT_ADDRESS"] ?? "0x") as `0x${string}`;

const deployerAccount = privateKeyToAccount(
  (process.env["ORACLE_PRIVATE_KEY"] ?? "0x0000000000000000000000000000000000000000000000000000000000000001") as `0x${string}`
);

const walletClient = createWalletClient({
  account: deployerAccount,
  chain: baseSepolia,
  transport: http(process.env["BASE_SEPOLIA_RPC_URL"]),
});

let previousPoDVerified = false;

export async function runAuction(slotId: string, context: Partial<SlotContext>): Promise<AdBid & { clearPrice: number }> {
  let floorCpm = 15.00;
  
  if (previousPoDVerified) {
    floorCpm *= 1.3;
  }

  const dspResponses = simulateDSPBids({
    slotId,
    floorCpm,
    channel: context.channel ?? "general"
  });

  const allBids = dspResponses.flatMap(r => r.seatbid[0]!.bid).sort((a, b) => b.price - a.price);

  if (allBids.length === 0) {
    throw new Error("No bids received");
  }

  const winningBid = allBids[0]!;
  
  let clearPrice = winningBid.price;
  if (allBids.length > 1) {
    clearPrice = allBids[1]!.price + 0.01;
  }

  try {
    await pool.query(
      `INSERT INTO auctions (slot_id, floor_cpm, winner_address, winning_cpm, ad_id)
       VALUES ($1, $2, $3, $4, $5)`,
      [slotId, floorCpm, winningBid.advertiserId, clearPrice, winningBid.adid]
    );
  } catch (err) {
    console.error("[auction] DB insert failed:", err);
  }

  if (AUCTION_CONTRACT !== "0x") {
    const slotBytes32 = slotId.length <= 32 
      ? `0x${Buffer.from(slotId).toString("hex").padEnd(64, "0")}` as `0x${string}`
      : `0x${Buffer.from(slotId.substring(0, 32)).toString("hex")}` as `0x${string}`;

    walletClient.writeContract({
      address: AUCTION_CONTRACT,
      abi: AUCTION_ABI,
      functionName: "recordWinner",
      args: [
        slotBytes32,
        BigInt(Math.floor(floorCpm * 100)),
        winningBid.advertiserId as `0x${string}`,
        BigInt(Math.floor(clearPrice * 100))
      ]
    }).catch(err => console.error("[auction] On-chain record failed:", err));
  }

  previousPoDVerified = Math.random() > 0.5;

  return {
    adId: winningBid.adid,
    adTrackName: buildAdTrackName(winningBid.adid),
    adNamespace: "sling/ads",
    creativePath: `./assets/ads/${winningBid.adid}.mp4`,
    durationMs: 30_000,
    priceUsdc: (clearPrice / 1000).toFixed(4),
    advertiserId: winningBid.advertiserId,
    expiresAt: Date.now() + 5_000,
    clearPrice
  };
}

export async function getRecentAuctions() {
  const { rows } = await pool.query(`SELECT * FROM auctions ORDER BY created_at DESC LIMIT 20`);
  return rows;
}
