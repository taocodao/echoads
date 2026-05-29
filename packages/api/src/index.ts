import { Hono } from "hono";
import { cors } from "hono/cors";
import { logger } from "hono/logger";
import { auctionRouter } from "./auction/auction.route.js";
import { slaRouter } from "./sla/sla.route.js";
import { deliveryRouter } from "./delivery/delivery.route.js";
import { commerceRouter } from "./commerce/commerce.route.js";

const app = new Hono();

// ── Middleware ──────────────────────────────────────────────────────────────
app.use("*", logger());
app.use(
  "*",
  cors({
    origin: ["http://localhost:3000", "http://localhost:5173", process.env.DASHBOARD_URL ?? ""],
    allowMethods: ["GET", "POST", "OPTIONS"],
    allowHeaders: ["Content-Type", "X-PAYMENT", "X-PAYMENT-RESPONSE"],
    exposeHeaders: ["X-PAYMENT-REQUIRED"],
  })
);

// ── Health check ────────────────────────────────────────────────────────────
app.get("/health", (c) =>
  c.json({
    status: "ok",
    service: "project-clarity-api",
    version: "0.0.1",
    timestamp: new Date().toISOString(),
  })
);

// ── Routers ─────────────────────────────────────────────────────────────────
app.route("/api/auction", auctionRouter);
app.route("/api/sla", slaRouter);
app.route("/api/delivery", deliveryRouter);
app.route("/api/commerce", commerceRouter);

export default app;
