/**
 * Local development server — uses @hono/node-server.
 * NOT used on Vercel (Vercel uses api/index.ts instead).
 * Run: pnpm dev (from packages/api)
 */
import { serve } from "@hono/node-server";
import app from "./index.js";
import { startSlaBatchLoop } from "./sla/aggregator.service.js";

const PORT = parseInt(process.env["API_PORT"] ?? "3001");
const HOST = process.env["API_HOST"] ?? "0.0.0.0";

serve({ fetch: app.fetch, port: PORT, hostname: HOST }, (info) => {
  console.log(`\n🚀 Project Clarity API (local dev) running on http://${HOST}:${info.port}`);
  console.log(`   Health:  http://localhost:${info.port}/health`);
  console.log(`   Auction: http://localhost:${info.port}/api/auction/:slotId`);
  console.log(`   Chain:   Base Sepolia (${process.env["CHAIN_ID"] ?? "84532"})\n`);
  // Start SLA batch loop in local dev mode
  startSlaBatchLoop();
});
