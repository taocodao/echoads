// server.js — MatchSim (ArenzaTV Demo Backend)
// Deterministic match timeline server that pushes scripted game events
// over WebSocket at the correct timestamps. REST endpoints serve
// trivia packs, sponsor quizzes, and EPG data.
//
// Usage: npm start (defaults to port 3001)

const express = require('express');
const http = require('http');
const WebSocket = require('ws');
const cors = require('cors');
const fs = require('fs');
const path = require('path');

const PORT = process.env.PORT || 3001;

// ── Express App ────────────────────────────────────────────────────

const app = express();
app.use(cors());
app.use(express.json());

const server = http.createServer(app);
const wss = new WebSocket.Server({ server });

// ── Load JSON data files ───────────────────────────────────────────

function loadJSON(relativePath) {
  const fullPath = path.join(__dirname, relativePath);
  if (!fs.existsSync(fullPath)) return null;
  return JSON.parse(fs.readFileSync(fullPath, 'utf8'));
}

const timeline = loadJSON('timelines/eagles-bears.json') || getDefaultTimeline();
const triviaPacks = {
  eagles: loadJSON('trivia/eagles.json'),
  bears: loadJSON('trivia/bears.json'),
};
const sponsorQuizzes = {
  pepsi: loadJSON('sponsors/pepsi-quiz.json'),
  dominos: loadJSON('sponsors/dominos-quiz.json'),
};

// ── REST Endpoints ─────────────────────────────────────────────────

// EPG (channel guide)
app.get('/api/epg', (_req, res) => {
  res.json({
    channels: [
      {
        id: 'arenza-1',
        name: 'ArenzaTV Sports',
        sport: 'NFL',
        currentProgram: 'Eagles vs Bears — LIVE',
        isLive: true,
        viewerCount: 12400,
        matchId: 'eagles-bears-demo',
      },
    ],
  });
});

// Trivia packs
app.get('/api/trivia/:teamId', (req, res) => {
  const pack = triviaPacks[req.params.teamId];
  if (pack) return res.json(pack);
  res.status(404).json({ error: 'Trivia pack not found' });
});

// Sponsor quiz
app.get('/api/sponsor/:sponsorId/quiz', (req, res) => {
  const quiz = sponsorQuizzes[req.params.sponsorId];
  if (quiz) return res.json(quiz);
  res.status(404).json({ error: 'Sponsor quiz not found' });
});

// Prediction submit (stub — logs and returns)
app.post('/api/prediction/submit', (req, res) => {
  console.log(`[MatchSim] Prediction received:`, req.body);
  res.json({ status: 'pending', receivedAt: Date.now() });
});

// Timeline info
app.get('/api/timeline', (_req, res) => {
  res.json(timeline);
});

// Health check
app.get('/health', (_req, res) => {
  res.json({ status: 'ok', uptime: process.uptime(), connections: wss.clients.size });
});

// ── WebSocket: Timeline Replay ─────────────────────────────────────

wss.on('connection', (ws, req) => {
  const matchId = req.url.replace('/ws/match/', '');
  console.log(`[MatchSim] Client connected for match: ${matchId}`);

  // Send timeline metadata first
  ws.send(JSON.stringify({
    type: 'timeline_info',
    matchId: timeline.matchId,
    sport: timeline.sport,
    homeTeam: timeline.homeTeam,
    awayTeam: timeline.awayTeam,
    durationSeconds: timeline.durationSeconds,
    totalEvents: timeline.events.length,
  }));

  // Sort events by timestamp
  const sorted = [...timeline.events].sort((a, b) => a.at - b.at);
  let eventIndex = 0;
  let elapsed = 0;

  // Replay loop — fires events at their scripted timestamps
  const interval = setInterval(() => {
    if (ws.readyState !== WebSocket.OPEN) {
      clearInterval(interval);
      return;
    }

    elapsed++;

    // Fire all events at this timestamp
    while (eventIndex < sorted.length && sorted[eventIndex].at <= elapsed) {
      const event = sorted[eventIndex];
      ws.send(JSON.stringify(event));
      console.log(`[MatchSim] t=${elapsed}s → ${event.type}: ${event.data?.description || event.data?.question || event.data?.sponsorId || ''}`);
      eventIndex++;
    }

    // Send clock tick every 5 seconds
    if (elapsed % 5 === 0) {
      ws.send(JSON.stringify({
        type: 'clock',
        elapsed,
        remaining: timeline.durationSeconds - elapsed,
      }));
    }

    // Loop timeline for continuous demo
    if (elapsed >= timeline.durationSeconds) {
      elapsed = 0;
      eventIndex = 0;
      console.log('[MatchSim] Timeline loop — restarting from 0s');
    }
  }, 1000);

  ws.on('close', () => {
    clearInterval(interval);
    console.log(`[MatchSim] Client disconnected`);
  });
});

// ── Default Timeline (inline fallback) ─────────────────────────────

function getDefaultTimeline() {
  return {
    matchId: 'eagles-bears-demo',
    sport: 'NFL',
    homeTeam: { id: 'PHI', name: 'Eagles', emoji: '🦅', startingScore: 14 },
    awayTeam: { id: 'CHI', name: 'Bears', emoji: '🐻', startingScore: 10 },
    durationSeconds: 600,
    events: [
      { at: 15,  type: 'play',         data: { description: 'Eagles convert on 3rd & 5 — First Down!', emoji: '📍', bingoLabel: 'First Down' }},
      { at: 20,  type: 'prediction',   data: { question: 'Next play: Pass or Rush?', options: ['Pass', 'Rush'], correctIndex: 0, pointReward: 75, sponsor: 'Nike', durationSec: 18 }},
      { at: 35,  type: 'play',         data: { description: 'Eagles RB breaks for 12 yards', emoji: '💨' }},
      { at: 50,  type: 'ad_break',     data: { sponsor: 'nike', adDuration: 12 }},
      { at: 65,  type: 'trivia',       data: { triviaPack: 'eagles_history', questionIndex: 0 }},
      { at: 70,  type: 'play',         data: { description: 'Flag — Holding, Bears #72', emoji: '🚩', bingoLabel: 'Penalty Flag' }},
      { at: 105, type: 'score',        data: { description: 'TOUCHDOWN EAGLES! AJ Brown 28-yd strike!', emoji: '🏈', bingoLabel: 'Touchdown', homeScoreDelta: 7 }},
      { at: 155, type: 'sponsor_quiz', data: { sponsorId: 'pepsi' }},
      { at: 175, type: 'play',         data: { description: 'SACK! Eagles #99 Sweat drops Fields', emoji: '💥', bingoLabel: 'Sack' }},
      { at: 210, type: 'score',        data: { description: 'Bears FG — Cairo Santos 52 yards!', emoji: '🥅', bingoLabel: 'Field Goal', awayScoreDelta: 3 }},
      { at: 235, type: 'play',         data: { description: 'Eagles call timeout — 2 remaining', emoji: '⏸️', bingoLabel: 'Timeout Called' }},
      { at: 285, type: 'prediction',   data: { question: 'Next play outcome?', options: ['1st Down', 'Incomplete', 'Penalty'], correctIndex: 2, pointReward: 100, durationSec: 15 }},
      { at: 330, type: 'play',         data: { description: 'INTERCEPTION! Eagles Slay picks off Fields!', emoji: '🙌', bingoLabel: 'Interception' }},
      { at: 350, type: 'trivia',       data: { triviaPack: 'bears_history', questionIndex: 0 }},
      { at: 360, type: 'score',        data: { description: 'TOUCHDOWN! Eagles Smith 6-yd TD grab', emoji: '🏈', bingoLabel: 'Touchdown', homeScoreDelta: 7 }},
      { at: 390, type: 'quarter_change', data: { description: 'END OF Q3', emoji: '🏟️', newQuarter: 4 }},
      { at: 440, type: 'prediction',   data: { question: 'Eagles score before end of Q3?', options: ['Yes', 'No'], correctIndex: 0, pointReward: 175, durationSec: 20 }},
      { at: 470, type: 'sponsor_quiz', data: { sponsorId: 'dominos' }},
      { at: 490, type: 'play',         data: { description: 'Hurts scrambles for 18 yards!', emoji: '🏃', bingoLabel: 'QB Scramble' }},
      { at: 510, type: 'score',        data: { description: 'TOUCHDOWN! Hurts sneaks from the 1!', emoji: '🏈', bingoLabel: 'Touchdown', homeScoreDelta: 7 }},
      { at: 565, type: 'score',        data: { description: 'Bears TD — garbage time score', emoji: '🏈', bingoLabel: 'Touchdown', awayScoreDelta: 7 }},
      { at: 590, type: 'play',         data: { description: 'FINAL: Eagles 35 — Bears 20', emoji: '🎉' }},
    ],
  };
}

// ── Start Server ───────────────────────────────────────────────────

server.listen(PORT, () => {
  console.log(`
╔══════════════════════════════════════════════════╗
║  MatchSim — ArenzaTV Demo Backend               ║
║  HTTP: http://localhost:${PORT}                    ║
║  WS:   ws://localhost:${PORT}/ws/match/{matchId}   ║
║                                                  ║
║  Timeline: ${timeline.matchId}                    
║  Events:   ${timeline.events.length} scripted                       ║
║  Duration: ${timeline.durationSeconds}s (loops)                     ║
╚══════════════════════════════════════════════════╝
  `);
});
