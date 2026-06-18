// commentaryGenerator.js — MatchSim (Phase 2: LLM Commentary Module 8)
// Generates commentary text for game events.
// Uses OpenAI GPT-4o-mini if OPENAI_API_KEY is set; falls back to curated strings.

'use strict';

const FALLBACK_COMMENTARY = {
  score: [
    '🏈 Surgical precision — a 6-point statement by the offense.',
    '🔥 TOUCHDOWN! The crowd erupts. Elite execution on this drive.',
    '💥 That\'s as clean a red zone execution as you\'ll see all season.',
  ],
  sponsor_quiz: [
    '🎯 Sponsor challenge time! How well do you know your brands?',
    '💡 Brand knowledge quiz — earn AZT and show what you know!',
  ],
  timeout: [
    '⏸️ Timeout on the field — coaching staff making adjustments.',
    '🧊 Strategic timeout. Every second counts here.',
  ],
  trivia: [
    '🎓 Time to test your football IQ! Trivia incoming.',
    '📚 Team history challenge — true fans will know this one.',
  ],
  prediction: [
    '🔮 Prediction window is open — what happens next?',
    '🎯 Lock in your prediction before the play clock runs out!',
  ],
  play: [
    '📍 The chains are moving. Momentum building on this drive.',
    '💨 Another chunk play. This offense is clicking tonight.',
    '🔒 Dominant defensive play — keeping the opponent off the scoreboard.',
  ],
  quarter_change: [
    '🏟️ Quarter change. Time to regroup and reset.',
    '⏱️ End of the quarter. How will the momentum shift?',
  ],
  default: [
    '🏈 Great action on the field tonight.',
    '📺 ArenzaTV — Watch, Earn, Shop.',
  ],
};

async function generateCommentary(event) {
  const apiKey = process.env.OPENAI_API_KEY;
  
  // Try OpenAI first if key is available
  if (apiKey) {
    try {
      const prompt = buildPrompt(event);
      const response = await fetch('https://api.openai.com/v1/chat/completions', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${apiKey}`,
        },
        body: JSON.stringify({
          model: 'gpt-4o-mini',
          temperature: 0.7,
          max_tokens: 80,
          messages: [
            { role: 'system', content: 'You are a concise, energetic sports broadcaster. Generate 1 sentence of commentary (max 20 words) for the given NFL game event. Be vivid and enthusiastic. Include an appropriate emoji at the start.' },
            { role: 'user', content: prompt },
          ],
        }),
      });
      if (response.ok) {
        const json = await response.json();
        const text = json.choices?.[0]?.message?.content?.trim();
        if (text) return text;
      }
    } catch (err) {
      console.warn('[Commentary] OpenAI fallback:', err.message);
    }
  }
  
  // Fallback to curated strings
  const pool = FALLBACK_COMMENTARY[event.type] || FALLBACK_COMMENTARY.default;
  return pool[Math.floor(Math.random() * pool.length)];
}

function buildPrompt(event) {
  const desc = event.data?.description || event.type;
  const score = event.data?.homeScoreDelta || event.data?.awayScoreDelta;
  if (score) return `NFL score event: ${desc}. Generate exciting commentary.`;
  return `NFL game event (${event.type}): ${desc}. Generate brief, energetic commentary.`;
}

module.exports = { generateCommentary };
