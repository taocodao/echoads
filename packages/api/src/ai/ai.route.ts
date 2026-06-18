/**
 * ai.route.ts — AI/ML API Routes (Phases 3 & 4)
 * All server-side ML services on the existing Hono API / PostgreSQL instance.
 * Registered under /api/ai/* in index.ts
 */
import { Hono } from "hono";
import { pool } from "../database/db.js";

// ── Sub-routers ──────────────────────────────────────────────────────────────
import { profileRouter }    from "./profile.route.js";
import { churnRouter }      from "./churn.route.js";
import { ivtRouter }        from "./ivt.route.js";
import { segmenterRouter }  from "./segmenter.route.js";
import { commentaryRouter } from "./commentary.route.js";
import { schedulerRouter }  from "./scheduler.route.js";   // Phase 4.1
import { lookalikeRouter }  from "./lookalike.route.js";   // Phase 4.2
import { abRouter }         from "./ab.route.js";           // Phase 4.4
import { monitoringRouter } from "./monitoring.route.js";  // Phase 4.5

export const aiRouter = new Hono();

// ── Mount sub-routers ────────────────────────────────────────────────────────
aiRouter.route("/profile",    profileRouter);
aiRouter.route("/churn",      churnRouter);
aiRouter.route("/ivt",        ivtRouter);
aiRouter.route("/segment",    segmenterRouter);
aiRouter.route("/commentary", commentaryRouter);
aiRouter.route("/schedule",   schedulerRouter);   // Phase 4.1
aiRouter.route("/lookalike",  lookalikeRouter);   // Phase 4.2
aiRouter.route("/ab",         abRouter);          // Phase 4.4
aiRouter.route("/monitoring", monitoringRouter);  // Phase 4.5

// ── Health / stats summary ───────────────────────────────────────────────────
aiRouter.get("/stats", async (c) => {
  try {
    const [profiles, churnHigh, ivtFlagged, commentary, predictions, quizzes] =
      await Promise.all([
        pool.query("SELECT COUNT(*) FROM viewer_profiles"),
        pool.query("SELECT COUNT(*) FROM churn_scores WHERE risk_tier='high' AND push_sent=FALSE"),
        pool.query("SELECT COUNT(*) FROM ivt_scores WHERE is_flagged=TRUE"),
        pool.query("SELECT COUNT(*) FROM ai_commentary WHERE model_used != 'ab-framework-v1'"),
        pool.query("SELECT COUNT(*) FROM ai_predictions"),
        pool.query("SELECT COUNT(*) FROM sponsor_quizzes WHERE approved=TRUE"),
      ]);
    return c.json({
      viewer_profiles:    Number(profiles.rows[0].count),
      high_churn_unsent:  Number(churnHigh.rows[0].count),
      ivt_flagged:        Number(ivtFlagged.rows[0].count),
      commentary_cached:  Number(commentary.rows[0].count),
      ai_predictions:     Number(predictions.rows[0].count),
      approved_quizzes:   Number(quizzes.rows[0].count),
      routes: [
        '/api/ai/profile', '/api/ai/churn', '/api/ai/ivt', '/api/ai/segment',
        '/api/ai/commentary', '/api/ai/schedule', '/api/ai/lookalike',
        '/api/ai/ab', '/api/ai/monitoring',
      ],
    });
  } catch (err: any) {
    return c.json({ error: err.message }, 500);
  }
});
