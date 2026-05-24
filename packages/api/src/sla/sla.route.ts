import { Hono } from "hono";
import { runSlaBatch } from "./aggregator.service.js";

export const slaRouter = new Hono();

/**
 * POST /api/sla/trigger
 * Manually trigger a SLA batch submission.
 * Used during demo to show real-time on-chain proof writing.
 * Protected by a simple admin token in production.
 */
slaRouter.post("/trigger", async (c) => {
  const adminToken = c.req.header("X-Admin-Token");
  if (adminToken !== process.env["ADMIN_TOKEN"] && process.env["NODE_ENV"] === "production") {
    return c.json({ error: "Unauthorized" }, 401);
  }

  console.log("[sla-route] Manual batch trigger received");
  const result = await runSlaBatch();

  return c.json({
    success: true,
    message: `SLA batch complete`,
    submitted: result.submitted,
    failed: result.failed,
    timestamp: new Date().toISOString(),
  });
});

/** GET /api/sla/status — current batch queue depth */
slaRouter.get("/status", async (c) => {
  return c.json({
    status: "ok",
    oracleContract: process.env["ORACLE_CONTRACT_ADDRESS"] ?? "not deployed",
    cmxsContract: process.env["CMXS_CONTRACT_ADDRESS"] ?? "not deployed",
  });
});
