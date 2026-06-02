/**
 * db.ts
 * Shared PostgreSQL connection pool for the API service.
 * Uses the pg library (already in package.json).
 */
import pg from "pg";
const { Pool } = pg;

export const pool = new Pool({
  connectionString: process.env["DATABASE_URL"],
  max: 10,
  idleTimeoutMillis: 30_000,
  connectionTimeoutMillis: 5_000,
  ssl: process.env["DATABASE_URL"]?.includes("localhost")
    ? false
    : { rejectUnauthorized: false },
});

pool.on("error", (err) => {
  console.error("[db] Unexpected pool error:", err.message);
});
