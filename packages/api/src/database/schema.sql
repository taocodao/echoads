-- Project Clarity Phase 0 — PostgreSQL Schema
-- Run this in Supabase SQL Editor after creating your project.
-- Dashboard: https://supabase.com/dashboard

-- ============================================================
-- deliveries — one row per ad impression
-- ============================================================
CREATE TABLE IF NOT EXISTS deliveries (
    id                  BIGSERIAL PRIMARY KEY,
    delivery_id         TEXT        NOT NULL UNIQUE,    -- keccak256(txHash + timestamp)
    slot_id             TEXT        NOT NULL,            -- ad slot identifier
    tx_hash             TEXT        NOT NULL,            -- x402 payment tx hash
    payer_address       TEXT        NOT NULL,            -- advertiser wallet
    amount_usdc         TEXT        NOT NULL,            -- payment amount (string, no float)
    switch_latency_ms   FLOAT,                           -- null until player beacons back
    sla_met             BOOLEAN     GENERATED ALWAYS AS (switch_latency_ms < 500) STORED,
    segment_count       INTEGER     NOT NULL DEFAULT 1,
    oracle_submitted    BOOLEAN     NOT NULL DEFAULT FALSE,
    oracle_tx_hash      TEXT,                            -- set after oracle contract tx
    delivered_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes for dashboard queries
CREATE INDEX IF NOT EXISTS idx_deliveries_delivered_at ON deliveries (delivered_at DESC);
CREATE INDEX IF NOT EXISTS idx_deliveries_oracle_submitted ON deliveries (oracle_submitted) WHERE oracle_submitted = FALSE;
CREATE INDEX IF NOT EXISTS idx_deliveries_tx_hash ON deliveries (tx_hash);
CREATE INDEX IF NOT EXISTS idx_deliveries_sla_met ON deliveries (sla_met);

-- ============================================================
-- nodes — registered edge node operators
-- ============================================================
CREATE TABLE IF NOT EXISTS nodes (
    id                  BIGSERIAL PRIMARY KEY,
    address             TEXT        NOT NULL UNIQUE,     -- 0x wallet address
    endpoint            TEXT        NOT NULL,            -- moqs:// relay endpoint
    staked_amount       TEXT        NOT NULL DEFAULT '0', -- wei as string
    status              TEXT        NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'slashed')),
    registered_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- latency_benchmarks — 100-trial benchmark results
-- ============================================================
CREATE TABLE IF NOT EXISTS latency_benchmarks (
    id                  BIGSERIAL PRIMARY KEY,
    trial_number        INTEGER     NOT NULL,
    transport           TEXT        NOT NULL CHECK (transport IN ('moq', 'hls')),
    switch_latency_ms   FLOAT       NOT NULL,
    is_key_frame        BOOLEAN,
    recorded_at         TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- Row Level Security (open for Phase 0 — lock down for Phase 1)
-- ============================================================
ALTER TABLE deliveries ENABLE ROW LEVEL SECURITY;
ALTER TABLE nodes ENABLE ROW LEVEL SECURITY;
ALTER TABLE latency_benchmarks ENABLE ROW LEVEL SECURITY;

-- Allow service role full access (API uses service role key)
CREATE POLICY "service_role_all" ON deliveries FOR ALL USING (true);
CREATE POLICY "service_role_all" ON nodes FOR ALL USING (true);
CREATE POLICY "service_role_all" ON latency_benchmarks FOR ALL USING (true);

-- ============================================================
-- Realtime subscription (for dashboard live feed)
-- ============================================================
ALTER PUBLICATION supabase_realtime ADD TABLE deliveries;

CREATE TABLE IF NOT EXISTS auctions (
    id BIGSERIAL PRIMARY KEY,
    slot_id TEXT NOT NULL UNIQUE,
    floor_cpm NUMERIC NOT NULL,
    winner_address TEXT NOT NULL,
    winning_cpm NUMERIC NOT NULL,
    ad_id TEXT,
    pod_verified BOOLEAN DEFAULT FALSE,
    pod_hash TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS engagements (
    id BIGSERIAL PRIMARY KEY,
    impression_id TEXT NOT NULL,
    ctv_ad_id TEXT,
    email TEXT,
    purchase_url TEXT,
    engaged_at TIMESTAMPTZ DEFAULT NOW()
);
