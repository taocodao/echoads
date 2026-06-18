// aiPredictionGenerator.js — MatchSim (Phase 2: Module 5 AI Predictions)
// Generates contextual prediction questions from game state.
// Uses OpenAI GPT-4o-mini if key is available; falls back to curated question bank.

'use strict';

const QUESTION_BANK = {
  score: [
    { question: 'Will the scoring team convert the extra point?', options: [{ label:'Yes', odds:'1.1x', emoji:'✅' },{ label:'No (2-pt attempt)', odds:'8.0x', emoji:'🎯' }], correctIndex: 0, pointReward: 25, probability: 0.94 },
    { question: 'Next possession result?', options: [{ label:'Field Goal', odds:'2.5x', emoji:'🥅' },{ label:'Punt', odds:'1.8x', emoji:'💨' },{ label:'Turnover', odds:'4.0x', emoji:'😤' }], correctIndex: 1, pointReward: 75, probability: 0.40 },
  ],
  play: [
    { question: 'Next play: Pass or Rush?', options: [{ label:'Pass', odds:'1.6x', emoji:'🏈' },{ label:'Rush', odds:'2.4x', emoji:'🏃' }], correctIndex: 0, pointReward: 50, probability: 0.62 },
    { question: 'Next play result?', options: [{ label:'1st Down', odds:'1.7x', emoji:'📍' },{ label:'Incomplete', odds:'2.2x', emoji:'💨' },{ label:'Penalty', odds:'5.0x', emoji:'🚩' }], correctIndex: 0, pointReward: 75, probability: 0.50 },
  ],
  timeout: [
    { question: 'Will the next drive result in points?', options: [{ label:'Yes — TD', odds:'2.1x', emoji:'✅' },{ label:'Yes — FG', odds:'3.2x', emoji:'🥅' },{ label:'No Score', odds:'1.9x', emoji:'❌' }], correctIndex: 0, pointReward: 100, probability: 0.55 },
  ],
  quarter_change: [
    { question: 'Who scores first in the new quarter?', options: [{ label:'Eagles', odds:'1.8x', emoji:'🦅' },{ label:'Bears', odds:'2.2x', emoji:'🐻' },{ label:'No score', odds:'2.5x', emoji:'🛡️' }], correctIndex: 0, pointReward: 125, probability: 0.45 },
  ],
};

async function generatePrediction(event, gameState) {
  const apiKey = process.env.OPENAI_API_KEY;
  
  if (apiKey) {
    try {
      const prompt = buildPredictionPrompt(event, gameState);
      const response = await fetch('https://api.openai.com/v1/chat/completions', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${apiKey}`,
        },
        body: JSON.stringify({
          model: 'gpt-4o-mini',
          temperature: 0.6,
          max_tokens: 200,
          messages: [
            {
              role: 'system',
              content: `You generate NFL prediction questions for a sports app. Return ONLY valid JSON: {"question":"...","options":[{"label":"...","odds":"1.5x","emoji":"🏈"}],"correctIndex":0,"pointReward":75,"probability":0.62}. Use 2-3 options. pointReward: 25-175 based on difficulty. probability: 0.0-1.0 of correctIndex being right.`
            },
            { role: 'user', content: prompt },
          ],
        }),
      });
      if (response.ok) {
        const json = await response.json();
        const text = json.choices?.[0]?.message?.content?.trim();
        if (text) {
          const parsed = JSON.parse(text);
          if (parsed.question && parsed.options) return parsed;
        }
      }
    } catch (err) {
      console.warn('[Predictions] OpenAI fallback:', err.message);
    }
  }
  
  // Fallback to question bank
  const pool = QUESTION_BANK[event.type] || QUESTION_BANK.play;
  const q = pool[Math.floor(Math.random() * pool.length)];
  return { ...q, sponsor: pickSponsor() };
}

function buildPredictionPrompt(event, gameState) {
  const desc = event.data?.description || '';
  const home = gameState?.homeScore ?? 14;
  const away = gameState?.awayScore ?? 10;
  return `NFL game event: "${desc}". Current score: Eagles ${home} - Bears ${away}. Generate a contextual fan prediction question about what happens next.`;
}

function pickSponsor() {
  const sponsors = ['Nike', 'DraftKings', null, null]; // null = no sponsor
  return sponsors[Math.floor(Math.random() * sponsors.length)];
}

module.exports = { generatePrediction };
