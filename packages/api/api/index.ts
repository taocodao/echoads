import { handle } from "hono/vercel";
import app from "../src/index.js";

/**
 * Vercel serverless entry point for the Project Clarity API.
 * Uses Hono's built-in Vercel adapter (no extra package needed — part of hono itself).
 * All routes defined in src/index.ts are served through this single function.
 *
 * Vercel routes all requests to this file via vercel.json rewrites.
 */
export const runtime = "nodejs20.x";

export default handle(app);
