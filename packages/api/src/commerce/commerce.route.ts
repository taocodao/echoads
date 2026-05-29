import { Hono } from "hono";
import { paymentMiddleware } from "@x402/hono";
import { evm } from "@x402/evm";
import { X402_FACILITATOR_URL } from "@clarity/shared";
import pg from "pg";

const pool = new pg.Pool({
  connectionString: process.env["DATABASE_URL"],
  ssl: { rejectUnauthorized: false },
});

export const commerceRouter = new Hono();

commerceRouter.post("/engage", async (c) => {
  const body = await c.req.json<{ impressionId: string; advertiserId: string; channelId: string }>();
  
  const token = `buy-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;
  const purchaseUrl = `http://localhost:3000/shop/${token}`;
  
  try {
    await pool.query(
      `INSERT INTO engagements (impression_id, ctv_ad_id, purchase_url) VALUES ($1, $2, $3)`,
      [body.impressionId, body.advertiserId, purchaseUrl]
    );
  } catch (err) {
    console.error("[commerce] Failed to record engagement", err);
  }
  
  return c.json({ status: "engaged", purchaseUrl, deliveredInMs: 120 });
});

const SELLER_ADDRESS = (process.env["SELLER_WALLET_ADDRESS"] ?? "") as `0x${string}`;

commerceRouter.get(
  "/shop/:token",
  paymentMiddleware(
    SELLER_ADDRESS,
    {
      "/:token": {
        price: "$0.50",
        network: "base-sepolia",
        config: { description: "Premium Product Purchase" },
      },
    },
    { facilitatorUrl: X402_FACILITATOR_URL, evm }
  ),
  async (c) => {
    return c.json({
      success: true,
      product: "Premium Widget",
      message: "Payment successful via x402. Order confirmed."
    });
  }
);
