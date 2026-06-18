// sponsorQuizGenerator.js — MatchSim (Phase 2: Module 6 AI Sponsor Quiz)
// Generates brand-safe sponsor quiz questions using GPT-4o or fallback templates.

'use strict';

const FALLBACK_QUIZZES = {
  pepsi: {
    sponsor: 'Pepsi',
    questions: [
      { question: 'Which Pepsi drink is known as the "lemon-lime" alternative?', options: ['Mountain Dew', 'Sierra Mist', 'Pepsi Zero', 'Lipton Tea'], correctIndex: 1, pointReward: 50 },
      { question: 'What year was Pepsi founded?', options: ['1893', '1965', '1902', '1920'], correctIndex: 0, pointReward: 75 },
      { question: 'Which artist famously appeared in multiple Pepsi commercials?', options: ['Britney Spears', 'Taylor Swift', 'Beyoncé', 'Rihanna'], correctIndex: 0, pointReward: 50 },
    ],
  },
  dominos: {
    sponsor: 'Domino\'s',
    questions: [
      { question: 'What is Domino\'s most popular pizza topping?', options: ['Pepperoni', 'Sausage', 'Mushrooms', 'Olives'], correctIndex: 0, pointReward: 50 },
      { question: 'In what year did Domino\'s launch its famous "30-minutes or free" guarantee?', options: ['1973', '1986', '1960', '1992'], correctIndex: 0, pointReward: 75 },
      { question: 'What is Domino\'s signature dipping sauce called?', options: ['Garlic Butter', 'Ranch', 'Marinara', 'BBQ'], correctIndex: 0, pointReward: 50 },
    ],
  },
};

async function generateSponsorQuiz(sponsorId, sponsorProfile) {
  const apiKey = process.env.OPENAI_API_KEY;
  
  if (apiKey && sponsorProfile) {
    try {
      const response = await fetch('https://api.openai.com/v1/chat/completions', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${apiKey}`,
        },
        body: JSON.stringify({
          model: 'gpt-4o',
          temperature: 0.5,
          max_tokens: 600,
          messages: [
            {
              role: 'system',
              content: `You generate brand-safe, fun quiz questions for a sports app sponsor. Return ONLY valid JSON array: [{"question":"...","options":["A","B","C","D"],"correctIndex":0,"pointReward":50}]. Generate exactly 3 questions. Make questions informative and brand-positive. Never embarrass the brand.`
            },
            {
              role: 'user',
              content: `Sponsor: ${sponsorProfile.name}. Category: ${sponsorProfile.category}. Products: ${(sponsorProfile.products||[]).join(', ')}. Campaign goal: ${sponsorProfile.goal || 'brand awareness'}. Generate 3 quiz questions.`
            },
          ],
        }),
      });
      
      if (response.ok) {
        const json = await response.json();
        const text = json.choices?.[0]?.message?.content?.trim();
        if (text) {
          const questions = JSON.parse(text);
          if (Array.isArray(questions) && questions.length > 0) {
            // Run moderation check
            const modPassed = await moderateContent(questions.map(q => q.question).join(' '), apiKey);
            if (modPassed) {
              return { sponsor: sponsorProfile.name, questions, aiGenerated: true };
            }
          }
        }
      }
    } catch (err) {
      console.warn('[SponsorQuiz] OpenAI fallback:', err.message);
    }
  }
  
  // Fallback to curated quizzes
  return FALLBACK_QUIZZES[sponsorId] || null;
}

async function moderateContent(text, apiKey) {
  try {
    const response = await fetch('https://api.openai.com/v1/moderations', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${apiKey}` },
      body: JSON.stringify({ input: text }),
    });
    if (response.ok) {
      const json = await response.json();
      return !json.results?.[0]?.flagged;
    }
  } catch {}
  return true; // default allow if moderation check fails
}

module.exports = { generateSponsorQuiz };
