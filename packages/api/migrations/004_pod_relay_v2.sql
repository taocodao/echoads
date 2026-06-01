-- Migration: 004_pod_relay_v2.sql
-- Creates the dead_letters table for PoD receipts that failed after 3 batch submission retries.
-- Also adds oracle_v2_tx_hash to deliveries for tracking which V2 batch a delivery ended up in.

-- Dead letters: impressions that failed all 3 batch submission retries
CREATE TABLE IF NOT EXISTS dead_letters (
    id              BIGSERIAL PRIMARY KEY,
    impression_id   TEXT UNIQUE NOT NULL,           -- bytes32 hex
    node_operator   TEXT NOT NULL,                  -- address hex
    campaign_id     TEXT NOT NULL,                  -- bytes32 hex
    cpm             TEXT NOT NULL,                  -- USDC microunits as string (bigint safe)
    timestamp_ms    BIGINT NOT NULL,                -- Unix ms from viewer device
    latency_ms      INTEGER NOT NULL,               -- measured latency
    failed_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    retry_count     INTEGER NOT NULL DEFAULT 3,
    error_message   TEXT,
    resolved        BOOLEAN NOT NULL DEFAULT FALSE, -- set true after manual re-submission
    resolved_tx     TEXT                            -- on-chain tx hash from manual retry
);

CREATE INDEX IF NOT EXISTS idx_dead_letters_failed_at ON dead_letters (failed_at DESC);
CREATE INDEX IF NOT EXISTS idx_dead_letters_resolved  ON dead_letters (resolved) WHERE NOT resolved;

-- Add V2 oracle tx hash column to existing deliveries table
ALTER TABLE deliveries
    ADD COLUMN IF NOT EXISTS oracle_v2_tx_hash TEXT,
    ADD COLUMN IF NOT EXISTS oracle_v2_batch_id TEXT; -- for grouping batch submissions

COMMENT ON TABLE dead_letters IS
    'PoD receipts that failed all 3 batch submission retries to DeliveryOracleV2. Requires manual investigation.';

COMMENT ON COLUMN dead_letters.impression_id IS
    'bytes32 impression ID — matches DeliveryOracleV2.usedImpressionIds key';
