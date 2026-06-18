-- ArenzaTV AI/ML Schema Migration (Phase 3)
-- Adds 6 new tables to the existing echoads PostgreSQL database.
-- Run AFTER the base schema.sql migration.

-- ============================================================
-- viewer_profiles — on-device profile snapshots synced to server
-- ============================================================
CREATE TABLE IF NOT EXISTS viewer_profiles (
    id                  BIGSERIAL PRIMARY KEY,
    viewer_token        TEXT        NOT NULL UNIQUE,    -- anonymous viewer ID (no PII)
    segment_id          TEXT        NOT NULL DEFAULT 'T12',   -- T1–T12 segment
    viewer_score        FLOAT       NOT NULL DEFAULT 0.0,     -- 0.0–1.0 premium tier
    sport_affinities    JSONB       NOT NULL DEFAULT '{}',    -- {"Football": 0.92}
    engagement_depth    FLOAT       NOT NULL DEFAULT 0.0,     -- 0–100 composite score
    device_tier         TEXT        DEFAULT 'B',
    total_watch_hours   FLOAT       NOT NULL DEFAULT 0.0,
    session_frequency   FLOAT       NOT NULL DEFAULT 0.0,     -- sessions/week
    ad_completion_rate  FLOAT       NOT NULL DEFAULT 0.0,
    prediction_rate     FLOAT       NOT NULL DEFAULT 0.0,
    signals_json        JSONB       NOT NULL DEFAULT '{}',    -- full signal snapshot
    last_active_at      TIMESTAMPTZ DEFAULT NOW(),
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_viewer_profiles_segment   ON viewer_profiles (segment_id);
CREATE INDEX IF NOT EXISTS idx_viewer_profiles_score     ON viewer_profiles (viewer_score DESC);
CREATE INDEX IF NOT EXISTS idx_viewer_profiles_active    ON viewer_profiles (last_active_at DESC);

-- ============================================================
-- churn_scores — daily batch scoring output (Module 4)
-- ============================================================
CREATE TABLE IF NOT EXISTS churn_scores (
    id              BIGSERIAL PRIMARY KEY,
    viewer_token    TEXT        NOT NULL REFERENCES viewer_profiles(viewer_token) ON DELETE CASCADE,
    churn_risk      FLOAT       NOT NULL CHECK (churn_risk BETWEEN 0 AND 1),
    risk_tier       TEXT        NOT NULL CHECK (risk_tier IN ('low', 'low_med', 'medium', 'high')),
    push_sent       BOOLEAN     NOT NULL DEFAULT FALSE,
    push_variant    TEXT,
    push_sent_at    TIMESTAMPTZ,
    scored_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_churn_scores_risk    ON churn_scores (churn_risk DESC);
CREATE INDEX IF NOT EXISTS idx_churn_scores_viewer  ON churn_scores (viewer_token);
CREATE INDEX IF NOT EXISTS idx_churn_unsent_high    ON churn_scores (viewer_token) WHERE risk_tier = 'high' AND push_sent = FALSE;

-- ============================================================
-- ivt_scores — per-impression fraud scoring (Module 7)
-- ============================================================
CREATE TABLE IF NOT EXISTS ivt_scores (
    id              BIGSERIAL PRIMARY KEY,
    delivery_id     TEXT        NOT NULL REFERENCES deliveries(delivery_id) ON DELETE CASCADE,
    ivt_score       FLOAT       NOT NULL CHECK (ivt_score BETWEEN 0 AND 1),
    is_flagged      BOOLEAN     GENERATED ALWAYS AS (ivt_score > 0.8) STORED,
    features        JSONB,
    scored_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_ivt_scores_flagged ON ivt_scores (is_flagged) WHERE is_flagged = TRUE;
CREATE INDEX IF NOT EXISTS idx_ivt_scores_delivery ON ivt_scores (delivery_id);

-- ============================================================
-- ai_commentary — cached LLM commentary per game event (Module 8)
-- ============================================================
CREATE TABLE IF NOT EXISTS ai_commentary (
    id              BIGSERIAL PRIMARY KEY,
    match_id        TEXT        NOT NULL,
    event_at        INTEGER     NOT NULL,       -- seconds into match
    event_type      TEXT        NOT NULL,
    commentary_text TEXT        NOT NULL,
    model_used      TEXT        NOT NULL DEFAULT 'fallback',
    sponsor_tag     TEXT,
    generated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_commentary_match_event ON ai_commentary (match_id, event_at);

-- ============================================================
-- ai_predictions — AI-generated prediction questions (Module 5)
-- ============================================================
CREATE TABLE IF NOT EXISTS ai_predictions (
    id              BIGSERIAL PRIMARY KEY,
    match_id        TEXT        NOT NULL,
    question        TEXT        NOT NULL,
    options         JSONB       NOT NULL,   -- [{label, odds, emoji}]
    correct_index   INTEGER     NOT NULL,
    point_reward    INTEGER     NOT NULL,
    probability     FLOAT,
    sponsor         TEXT,
    appears_at      INTEGER     NOT NULL,   -- seconds into match
    model_used      TEXT        NOT NULL DEFAULT 'fallback',
    generated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- sponsor_quizzes — AI-generated sponsor quiz questions (Module 6)
-- ============================================================
CREATE TABLE IF NOT EXISTS sponsor_quizzes (
    id                  BIGSERIAL PRIMARY KEY,
    campaign_id         TEXT        NOT NULL,
    sponsor_name        TEXT        NOT NULL,
    question            TEXT        NOT NULL,
    options             JSONB       NOT NULL,   -- [string × 4]
    correct_index       INTEGER     NOT NULL,
    point_reward        INTEGER     NOT NULL DEFAULT 50,
    moderation_passed   BOOLEAN     NOT NULL DEFAULT FALSE,
    approved            BOOLEAN     NOT NULL DEFAULT FALSE,
    model_used          TEXT        NOT NULL DEFAULT 'fallback',
    generated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_sponsor_quizzes_campaign ON sponsor_quizzes (campaign_id);
CREATE INDEX IF NOT EXISTS idx_sponsor_quizzes_approved ON sponsor_quizzes (approved) WHERE approved = TRUE;

-- ============================================================
-- Policies (open for demo — tighten for production)
-- ============================================================
ALTER TABLE viewer_profiles  ENABLE ROW LEVEL SECURITY;
ALTER TABLE churn_scores      ENABLE ROW LEVEL SECURITY;
ALTER TABLE ivt_scores        ENABLE ROW LEVEL SECURITY;
ALTER TABLE ai_commentary     ENABLE ROW LEVEL SECURITY;
ALTER TABLE ai_predictions    ENABLE ROW LEVEL SECURITY;
ALTER TABLE sponsor_quizzes   ENABLE ROW LEVEL SECURITY;

CREATE POLICY "service_role_all" ON viewer_profiles  FOR ALL USING (true);
CREATE POLICY "service_role_all" ON churn_scores      FOR ALL USING (true);
CREATE POLICY "service_role_all" ON ivt_scores        FOR ALL USING (true);
CREATE POLICY "service_role_all" ON ai_commentary     FOR ALL USING (true);
CREATE POLICY "service_role_all" ON ai_predictions    FOR ALL USING (true);
CREATE POLICY "service_role_all" ON sponsor_quizzes   FOR ALL USING (true);
