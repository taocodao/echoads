import { Hono } from "hono";
import { z } from "zod";
import { paymentMiddleware } from "@x402/hono";
import { evm } from "@x402/evm";
import { runAuction, getRecentAuctions } from "./auction.service.js";
import { logDelivery } from "../delivery/delivery.service.js";
import { AD_PRICE_USDC, X402_FACILITATOR_URL } from "@clarity/shared";
import { runPodAuction, getRecentAuctionResults, getAuctionStats } from "./pod-manager.js";
import type { BreakType } from "./openrtb-engine.js";

export const auctionRouter = new Hono();

const SELLER_ADDRESS = (process.env["SELLER_WALLET_ADDRESS"] ?? "") as `0x${string}`;

// ── GET /api/auction/recent  (legacy) ────────────────────────────────────────
auctionRouter.get("/recent", async (c) => {
  try {
    const auctions = await getRecentAuctions();
    return c.json({ auctions });
  } catch (err) {
    console.error("[auction] Fetch recent failed:", err);
    return c.json({ error: "Fetch failed" }, 500);
  }
});

// ── GET /api/auction/history  (OpenRTB ring buffer) ──────────────────────────
auctionRouter.get("/history", (c) => {
  const limit = Math.min(parseInt(c.req.query("limit") ?? "20"), 100);
  return c.json({ auctions: getRecentAuctionResults(limit) });
});

// ── GET /api/auction/stats ────────────────────────────────────────────────────
auctionRouter.get("/stats", (c) => {
  return c.json(getAuctionStats());
});

// ── GET /api/auction/dsps ─────────────────────────────────────────────────────
auctionRouter.get("/dsps", async (c) => {
  const { DSP_CONFIGS } = await import("./simulated-dsps.js");
  return c.json({
    dsps: DSP_CONFIGS.map((d) => ({
      id: d.id,
      name: d.displayName,
      cpmRange: `$${d.minCpm}–$${d.maxCpm}`,
      fillRate: `${Math.round(d.fillRate * 100)}%`,
      specialty: d.specialtyCategories[0],
    })),
  });
});

// ── POST /api/auction/run  (OpenRTB 2.6 engine) ───────────────────────────────
const RunAuctionSchema = z.object({
  breakType: z.enum(["pre-game", "halftime", "between-plays", "end-game", "dynamic"]).default("halftime"),
  contentId: z.string().default("cmxs_liv_golf_round2"),
  contentGenre: z.string().default("Sports"),
  sessionId: z.string().default("test-session"),
  campaignId: z.string().optional(),
  deviceType: z.string().default("ctv"),
  resolution: z.string().default("1080p"),
  numSlots: z.number().int().min(1).max(6).optional(),
});

auctionRouter.post("/run", async (c) => {
  let body: z.infer<typeof RunAuctionSchema>;
  try {
    body = RunAuctionSchema.parse(await c.req.json());
  } catch {
    body = RunAuctionSchema.parse({});
  }

  try {
    const result = await runPodAuction({
      breakType: body.breakType as BreakType,
      contentId: body.contentId,
      contentGenre: body.contentGenre,
      sessionId: body.sessionId,
      campaignId: body.campaignId ?? "0x0000000000000000000000000000000000000000000000000000000000000000",
      deviceType: body.deviceType,
      resolution: body.resolution,
      ...(body.numSlots !== undefined ? { numSlots: body.numSlots } : {}),
    });

    return c.json({
      ...result,
      // Reshape slots for SSAI rewriter compatibility
      slots: result.slots
        .filter((s) => !s.freqCapApplied)
        .map((s) => ({
          slotIndex: s.slotIndex,
          creativeKey: s.creativeKey,
          winningCpm: s.winningCpm,
          clearingCpm: s.clearingCpm,
          dspName: s.dspName,
          advertiser: s.advertiser,
          product: s.product,
          price: s.price,
          duration: s.duration,
        })),
    });
  } catch (err) {
    console.error("[auction/run] Error:", err);
    return c.json({ success: false, error: "Auction failed" }, 500);
  }
});

// ── x402 payment middleware (existing slot-based path) ───────────────────────
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


// duplicate removed — all routes are above
