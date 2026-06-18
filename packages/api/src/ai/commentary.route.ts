/**
 * commentary.route.ts — AI Commentary Cache (Module 8)
 * POST /api/ai/commentary/generate — generate and cache commentary
 * GET  /api/ai/commentary/:matchId  — get all commentary for a match
 */
import { Hono } from "hono";
import { pool } from "../database/db.js";

export const commentaryRouter = new Hono();

const FALLBACK: Record<string, string[]> = {
  score:         ["🏈 Absolute surgical precision — a 6-point statement by the offense.", "🔥 TOUCHDOWN! The crowd erupts."],
  sponsor_quiz:  ["🎯 Sponsor challenge time! Earn AZT and show what you know!"],
  timeout:       ["⏸️ Timeout called — coaching staff making critical adjustments."],
  trivia:        ["🎓 Time to test your football IQ! Trivia incoming."],
  prediction:    ["🔮 Prediction window open — lock in your pick before the clock runs out!"],
  play:          ["📍 The chains are moving. Momentum building on this drive.", "💥 Dominant play. This team is clicking on all cylinders."],
  quarter_change:["🏟️ Quarter change. How will the momentum shift?"],
};

async function generateWithOpenAI(event: { type: string; data?: unknown }): Promise<string | null> {
  const apiKey = process.env.OPENAI_API_KEY;
  if (!apiKey) return null;
  try {
    const res = await fetch("https://api.openai.com/v1/chat/completions", {
      method: "POST",
      headers: { "Content-Type": "application/json", Authorization: `Bearer ${apiKey}` },
      body: JSON.stringify({
        model: "gpt-4o-mini",
        temperature: 0.7,
        max_tokens: 60,
        messages: [
          { role: "system", content: "Generate one exciting NFL broadcast commentary sentence (max 20 words) for the given event. Start with an emoji." },
          { role: "user", content: `Event type: ${event.type}. Data: ${JSON.stringify(event.data || {})}` },
        ],
      }),
    });
    if (res.ok) {
      const j = await res.json() as { choices: {message:{content:string}}[] };
      return j.choices?.[0]?.message?.content?.trim() || null;
    }
  } catch {}
  return null;
}

// Generate and cache commentary for a game event
commentaryRouter.post("/generate", async (c) => {
  const { matchId, eventAt, event } = await c.req.json<{
    matchId: string; eventAt: number; event: { type: string; data?: unknown };
  }>();

  if (!matchId || eventAt === undefined || !event) {
    return c.json({ error: "matchId, eventAt, event required" }, 400);
  }

  // Check cache first
  try {
    const cached = await pool.query(
      "SELECT commentary_text FROM ai_commentary WHERE match_id=$1 AND event_at=$2",
      [matchId, eventAt]
    );
    if (cached.rows.length > 0) {
      return c.json({ commentary: cached.rows[0].commentary_text, source: "cache" });
    }
  } catch {}

  // Generate
  let text = await generateWithOpenAI(event);
  let model = "gpt-4o-mini";
  if (!text) {
    const pool2 = FALLBACK[event.type] || FALLBACK.play;
    text = pool2[Math.floor(Math.random() * pool2.length)];
    model = "fallback";
  }

  // Cache in DB
  try {
    await pool.query(
      `INSERT INTO ai_commentary (match_id, event_at, event_type, commentary_text, model_used)
       VALUES ($1,$2,$3,$4,$5) ON CONFLICT (match_id, event_at) DO NOTHING`,
      [matchId, eventAt, event.type, text, model]
    );
  } catch {}

  return c.json({ commentary: text, source: model });
});

// Get all commentary for a match (for clients that connect late)
commentaryRouter.get("/:matchId", async (c) => {
  try {
    const r = await pool.query(
      "SELECT event_at, event_type, commentary_text, model_used FROM ai_commentary WHERE match_id=$1 ORDER BY event_at",
      [c.req.param("matchId")]
    );
    return c.json(r.rows);
  } catch (err: any) {
    return c.json({ error: err.message }, 500);
  }
});
