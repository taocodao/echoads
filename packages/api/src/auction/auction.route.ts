import { Hono } from "hono";
import { paymentMiddleware } from "@x402/hono";
import { evm } from "@x402/evm";
import { runAuction } from "./auction.service.js";
import { logDelivery } from "../delivery/delivery.service.js";
import { AD_PRICE_USDC, X402_FACILITATOR_URL } from "@clarity/shared";

export const auctionRouter = new Hono();

const SELLER_ADDRESS = (process.env["SELLER_WALLET_ADDRESS"] ?? "") as `0x${string}`;

// ── x402 payment middleware ─────────────────────────────────────────────────
// Protects all /api/auction/* routes with a per-impression USDC payment.
// The @x402/hono middleware handles the full 402 → sign → verify flow.
auctionRouter.use(
  "/*",
  paymentMiddleware(
    SELLER_ADDRESS,
    {
      // Price per ad auction request (one impression)
      "/:slotId": {
        price: `$${AD_PRICE_USDC}`,
        network: "base-sepolia",
        config: { description: "Project Clarity — Ad impression payment" },
      },
    },
    {
      facilitatorUrl: X402_FACILITATOR_URL,
      evm,
      onSuccess: async (req: any, _res: any, paymentInfo: any) => {
        // Log the payment immediately on settlement
        const slotId = req.param("slotId");
        console.log(`[x402] Payment settled:`, {
          slotId,
          txHash: paymentInfo.transaction,
          payer: paymentInfo.from,
          amount: paymentInfo.amount,
        });
        // Record the pending delivery (will be updated with latency after player beacons back)
        await logDelivery({
          slotId: slotId ?? "unknown",
          txHash: paymentInfo.transaction as string,
          payerAddress: paymentInfo.from as string,
          amountUsdc: paymentInfo.amount?.toString() ?? AD_PRICE_USDC,
        });
      },
    }
  )
);

// ── GET /api/auction/:slotId ────────────────────────────────────────────────
auctionRouter.get("/:slotId", async (c) => {
  const slotId = c.req.param("slotId");
  const auctionStart = Date.now();

  try {
    const bid = await runAuction(slotId, {
      slotId,
      channel: c.req.query("channel") ?? "sling/live",
      positionMs: parseInt(c.req.query("positionMs") ?? "0"),
      deviceType: "web",
    });

    const auctionLatencyMs = Date.now() - auctionStart;

    return c.json({
      success: true,
      slotId,
      adId: bid.adId,
      adNamespace: bid.adNamespace,
      adTrackName: bid.adTrackName,
      durationMs: bid.durationMs,
      auctionLatencyMs,
      expiresAt: bid.expiresAt,
    });
  } catch (err) {
    console.error("[auction] Error:", err);
    return c.json({ success: false, error: "Auction failed" }, 500);
  }
});
