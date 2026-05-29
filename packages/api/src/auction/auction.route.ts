import { Hono } from "hono";
import { paymentMiddleware } from "@x402/hono";
import { evm } from "@x402/evm";
import { runAuction, getRecentAuctions } from "./auction.service.js";
import { logDelivery } from "../delivery/delivery.service.js";
import { AD_PRICE_USDC, X402_FACILITATOR_URL } from "@clarity/shared";

export const auctionRouter = new Hono();

const SELLER_ADDRESS = (process.env["SELLER_WALLET_ADDRESS"] ?? "") as `0x${string}`;

auctionRouter.get("/recent", async (c) => {
  try {
    const auctions = await getRecentAuctions();
    return c.json({ auctions });
  } catch (err) {
    console.error("[auction] Fetch recent failed:", err);
    return c.json({ error: "Fetch failed" }, 500);
  }
});

auctionRouter.use(
  "/:slotId",
  paymentMiddleware(
    SELLER_ADDRESS,
    {
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
        const slotId = req.param("slotId");
        console.log(`[x402] Payment settled:`, {
          slotId,
          txHash: paymentInfo.transaction,
          payer: paymentInfo.from,
          amount: paymentInfo.amount,
        });
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
      clearPrice: bid.clearPrice
    });
  } catch (err) {
    console.error("[auction] Error:", err);
    return c.json({ success: false, error: "Auction failed" }, 500);
  }
});
