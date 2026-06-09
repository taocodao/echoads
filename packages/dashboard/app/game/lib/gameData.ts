// lib/gameData.ts — scripted game events, predictions, ad catalog, chat

export interface Prediction {
  id: string;
  question: string;
  options: { label: string; odds: string; emoji: string }[];
  pointReward: number;
  durationSec: number;
  appearsAt: number; // seconds into game clock
  correctIndex: number;
  sponsor?: string;
}

export interface AdCreative {
  id: string;
  brand: string;
  tagline: string;
  emoji: string;
  cpm: number;
  targetSegment: string;
  whyChosen: string[];
  color: string;
  appearsAt: number; // seconds into game clock
  durationSec: number;
}

export interface GameEvent {
  at: number;
  type: 'touchdown' | 'fieldgoal' | 'interception' | 'sack' | 'penalty' | 'firstdown' | 'timeout';
  description: string;
  team: 'home' | 'away';
  scoreDelta?: { home: number; away: number };
  bingoCell?: string;
}

export interface ChatMessage {
  at: number;
  user: string;
  avatar: string;
  text: string;
  type: 'fan' | 'system';
}

// ── Scoreboard ────────────────────────────────────────────────────────────────

export const GAME_META = {
  homeTeam: '🦅 EAGLES',
  awayTeam: '🐻 BEARS',
  homeScore: 14,
  awayScore: 10,
  quarter: 3,
  clock: '8:44',
  event: 'NFC Wild Card · Arenza Sports Network',
};

// ── Predictions (prop bets) ───────────────────────────────────────────────────

export const PREDICTIONS: Prediction[] = [
  {
    id: 'p1',
    question: 'Next play: Pass or Rush?',
    options: [
      { label: 'Pass', odds: '1.6x', emoji: '🏈' },
      { label: 'Rush', odds: '2.4x', emoji: '🏃' },
    ],
    pointReward: 75,
    durationSec: 15,
    appearsAt: 5,
    correctIndex: 0,
    sponsor: 'Nike',
  },
  {
    id: 'p2',
    question: 'Will Eagles score this drive?',
    options: [
      { label: 'Yes — TD', odds: '2.1x', emoji: '✅' },
      { label: 'Yes — FG', odds: '3.0x', emoji: '🥅' },
      { label: 'No Score', odds: '1.8x', emoji: '❌' },
    ],
    pointReward: 125,
    durationSec: 18,
    appearsAt: 25,
    correctIndex: 0,
  },
  {
    id: 'p3',
    question: 'Next play outcome?',
    options: [
      { label: '1st Down', odds: '1.7x', emoji: '📍' },
      { label: 'Incomplete', odds: '2.2x', emoji: '💨' },
      { label: 'Penalty', odds: '4.0x', emoji: '🚩' },
    ],
    pointReward: 100,
    durationSec: 12,
    appearsAt: 48,
    correctIndex: 1,
    sponsor: 'DraftKings',
  },
  {
    id: 'p4',
    question: 'Eagles score before end of Q3?',
    options: [
      { label: 'Yes', odds: '1.9x', emoji: '🎯' },
      { label: 'No', odds: '2.0x', emoji: '🛡️' },
    ],
    pointReward: 150,
    durationSec: 20,
    appearsAt: 62,
    correctIndex: 0,
  },
];

// ── Ad Catalog ────────────────────────────────────────────────────────────────

export const AD_CATALOG: AdCreative[] = [
  {
    id: 'ad-nike',
    brand: 'Nike',
    tagline: 'Just Do It',
    emoji: '👟',
    cpm: 55,
    targetSegment: 'Sports Enthusiast · M 25–34',
    whyChosen: [
      'High sports engagement score (87/100)',
      'Male 25–34 demographic match',
      'Football affinity: 92%',
      'Won OpenRTB auction at $55 CPM',
    ],
    color: '#ff6b35',
    appearsAt: 10,
    durationSec: 8,
  },
  {
    id: 'ad-pepsi',
    brand: 'Pepsi',
    tagline: 'Game Day Fuel',
    emoji: '🥤',
    cpm: 42,
    targetSegment: 'Mass Market · All Adults 18+',
    whyChosen: [
      'Game-day context match',
      'Food & beverage affinity',
      'High reach campaign (all segments)',
      'Won OpenRTB auction at $42 CPM',
    ],
    color: '#00c9b1',
    appearsAt: 32,
    durationSec: 8,
  },
  {
    id: 'ad-draftkings',
    brand: 'DraftKings',
    tagline: 'Bet on the Action',
    emoji: '🎯',
    cpm: 68,
    targetSegment: 'High-Engagement Bettors · 21+',
    whyChosen: [
      'Active prediction player (3 bets placed)',
      'Betting affinity signal detected',
      '21+ verified via age gate',
      'Won OpenRTB auction at $68 CPM — highest bidder',
    ],
    color: '#7c3aed',
    appearsAt: 55,
    durationSec: 8,
  },
  {
    id: 'ad-statefarm',
    brand: 'State Farm',
    tagline: 'Like a Good Neighbor',
    emoji: '🏠',
    cpm: 38,
    targetSegment: 'Homeowners · 30–50',
    whyChosen: [
      'Homeowner demographic signal',
      'Premium content viewer (loyalty score: A)',
      'Timeout moment — attention peak',
      'Won OpenRTB auction at $38 CPM',
    ],
    color: '#ffc107',
    appearsAt: 70,
    durationSec: 8,
  },
];

// ── Game Events (auto-trigger bingo + feed) ───────────────────────────────────

export const GAME_EVENTS: GameEvent[] = [
  { at: 8,  type: 'firstdown',    description: 'Eagles convert on 3rd & 7 — First Down!', team: 'home', bingoCell: 'First Down' },
  { at: 22, type: 'touchdown',    description: 'TOUCHDOWN EAGLES! #11 Brown — 34-yard strike!', team: 'home', scoreDelta: { home: 6, away: 0 }, bingoCell: 'Touchdown' },
  { at: 30, type: 'penalty',      description: 'Flag on the play — Holding, Bears #72', team: 'away', bingoCell: 'Penalty Flag' },
  { at: 42, type: 'sack',         description: 'SACK! Eagles #99 — Bears QB down for -8 yards', team: 'home', bingoCell: 'Sack' },
  { at: 50, type: 'interception', description: 'INTERCEPTION! Eagles #24 picks it off at midfield!', team: 'home', bingoCell: 'Interception' },
  { at: 60, type: 'fieldgoal',    description: 'Bears kick a 47-yard field goal — 3 points!', team: 'away', scoreDelta: { home: 0, away: 3 }, bingoCell: 'Field Goal' },
  { at: 68, type: 'timeout',      description: 'Bears call timeout — 2 remaining in Q3', team: 'away', bingoCell: 'Timeout Called' },
  { at: 75, type: 'touchdown',    description: 'TOUCHDOWN EAGLES! #82 Smith — 12-yard grab!', team: 'home', scoreDelta: { home: 6, away: 0 }, bingoCell: 'Touchdown' },
];

// ── Sports Bingo Cells ────────────────────────────────────────────────────────

export const BINGO_CELLS = [
  'Touchdown', 'Field Goal', 'Interception', 'Sack', 'Penalty Flag',
  'First Down', 'Timeout Called', 'Challenge Flag', '2-Point Conv.', 'False Start',
  'Fumble', 'Big Hit', 'FREE', 'Long Pass', 'No Gain',
  'Touchdown', '3rd Down Conv.', 'Punt', 'QB Scramble', 'Red Zone',
  'Holding Call', 'Incomplete Pass', 'Safety', '4th Down', 'Pick-6',
];

// ── Chat Messages ─────────────────────────────────────────────────────────────

export const CHAT_MESSAGES: ChatMessage[] = [
  { at: 0,  user: 'EaglesFan23',   avatar: '🦅', text: "Let's gooo Eagles!! 🔥🔥🔥", type: 'fan' },
  { at: 3,  user: 'SportsBetKing', avatar: '🎯', text: 'Picked PASS — feels right', type: 'fan' },
  { at: 9,  user: 'ChiTownBear',   avatar: '🐻', text: 'Bears D needs to step up fr', type: 'fan' },
  { at: 15, user: 'NFLNerd42',     avatar: '🏈', text: 'That first down conversion was clutch', type: 'fan' },
  { at: 23, user: 'EaglesFan23',   avatar: '🦅', text: 'YESSS TOUCHDOWN!!! 🎉🎉🎉', type: 'fan' },
  { at: 24, user: 'ArenzaGame',    avatar: '⚡', text: '🏆 EaglesFan23 predicted correctly! +75 pts', type: 'system' },
  { at: 31, user: 'RefWatch',      avatar: '🚩', text: 'Another holding call lmao', type: 'fan' },
  { at: 38, user: 'SportsBetKing', avatar: '🎯', text: 'DraftKings line is moving fast on this game', type: 'fan' },
  { at: 43, user: 'ChiTownBear',   avatar: '🐻', text: 'Come on Bears O-line 😤', type: 'fan' },
  { at: 51, user: 'NFLNerd42',     avatar: '🏈', text: 'INTERCEPTION! Game might be over 💀', type: 'fan' },
  { at: 61, user: 'ChiTownBear',   avatar: '🐻', text: 'At least we got 3. Build on it', type: 'fan' },
  { at: 69, user: 'EaglesFan23',   avatar: '🦅', text: "That timeout won't save them lol", type: 'fan' },
  { at: 76, user: 'ArenzaGame',    avatar: '⚡', text: '🏆 BINGO ACHIEVED — SportsBetKing +500 pts!', type: 'system' },
  { at: 77, user: 'SportsBetKing', avatar: '🎯', text: 'BINGO!! Cashing out 🔥', type: 'fan' },
];
