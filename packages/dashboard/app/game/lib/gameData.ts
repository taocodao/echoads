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
  durationSec: number;
  videoUrl?: string;
  /** Brand website — Button 1: Visit Website */
  websiteUrl?: string;
  /** Menu deep-link — Button 2: See Menu */
  menuUrl?: string;
  /** Order deep-link — Button 3: Order Now */
  orderUrl?: string;
  /** AI-generated coupon headline shown on claim */
  offerHeadline?: string;
  /** Coupon value displayed on the claim card, e.g. "20% off" */
  offerValue?: string;
}


export interface CommercialBreak {
  id: string;
  triggerAt: number;   // game-clock seconds to fire the break
  label: string;       // e.g. "Commercial Break · Timeout"
  ads: AdCreative[];
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

// ── Ad Creatives — Local Restaurant & Bar Partners ──────────────────────────────────
const AD_AJWARD: AdCreative = {
  id: 'ad-ajward', brand: 'AJ.Ward', tagline: 'Fine dining, unforgettable moments', emoji: '🍽️', cpm: 45,
  targetSegment: 'Foodies · Local Diners 25–54',
  whyChosen: ['Fine dining affinity', 'Local geo-match', 'Won OpenRTB at $45 CPM'],
  color: '#1a1a2e', durationSec: 31,
  videoUrl: 'https://lavcma6duvpplftv.public.blob.vercel-storage.com/AJ.WARD.mp4',
  websiteUrl: 'https://www.ajrestaurant.co.uk/',
  menuUrl: 'https://www.ajrestaurant.co.uk/',
  orderUrl: 'https://www.ajrestaurant.co.uk/',
  offerHeadline: 'Game Day — 15% Off Dining',
  offerValue: '15% off',
};
const AD_BONSAI: AdCreative = {
  id: 'ad-bonsai', brand: 'Bonsai Cafe', tagline: 'Where food meets art', emoji: '🍜', cpm: 38,
  targetSegment: 'Health-Conscious · Cafe Culture 18–44',
  whyChosen: ['Cafe culture match', 'Asian cuisine affinity signal', 'Won at $38 CPM'],
  color: '#2d6a4f', durationSec: 34,
  videoUrl: 'https://lavcma6duvpplftv.public.blob.vercel-storage.com/Bonsai%20Cafe.mp4',
  websiteUrl: 'https://thedojonorwich.co.uk/bonsai-cafe/',
  menuUrl: 'https://thedojonorwich.co.uk/bonsai-cafe/',
  orderUrl: 'https://thedojonorwich.co.uk/bonsai-cafe/',
  offerHeadline: 'Free Miso Soup on $25+',
  offerValue: 'Free miso soup',
};
const AD_ROCCOS_1: AdCreative = {
  id: 'ad-roccos-1', brand: "Rocco's Bar & Restaurant", tagline: 'Live it up at Rocco\'s', emoji: '🍸', cpm: 42,
  targetSegment: 'Nightlife & Dining · 21–45',
  whyChosen: ['Sports bar affinity', 'Game-day dining context', 'Won at $42 CPM'],
  color: '#e63946', durationSec: 31,
  videoUrl: 'https://lavcma6duvpplftv.public.blob.vercel-storage.com/ROCCOS%20BAR%20%26%20RESTURANT%201.mp4',
  websiteUrl: 'http://www.roccos.com',
  menuUrl: 'http://www.roccos.com',
  orderUrl: 'http://www.roccos.com',
  offerHeadline: '$5 Draft Beer — Game Day Special',
  offerValue: '$5 drafts',
};
const AD_ROCCOS_2: AdCreative = {
  id: 'ad-roccos-2', brand: "Rocco's Bar & Restaurant", tagline: 'Great food, great times', emoji: '🍕', cpm: 42,
  targetSegment: 'Nightlife & Dining · 21–45',
  whyChosen: ['Sports bar affinity', 'Return viewer creative rotation', 'Won at $42 CPM'],
  color: '#c1121f', durationSec: 34,
  videoUrl: 'https://lavcma6duvpplftv.public.blob.vercel-storage.com/ROCCOS%20BAR%20%26%20RESTURANT%202.mp4',
  websiteUrl: 'http://www.roccos.com',
  menuUrl: 'http://www.roccos.com',
  orderUrl: 'http://www.roccos.com',
  offerHeadline: 'Free Garlic Bread with Pizza',
  offerValue: 'Free garlic bread',
};
const AD_ROOFTOP_1: AdCreative = {
  id: 'ad-rooftop-1', brand: 'Rooftop Gardens', tagline: 'Elevated dining, stunning views', emoji: '🌿', cpm: 52,
  targetSegment: 'Premium Diners · Date Night 25–54',
  whyChosen: ['Premium viewer match', 'Rooftop/experience affinity', 'Won at $52 CPM'],
  color: '#588157', durationSec: 17,
  videoUrl: 'https://lavcma6duvpplftv.public.blob.vercel-storage.com/Rooftop%20Gardens%202.mp4',
  websiteUrl: 'https://rooftopgardens.co.uk/',
  menuUrl: 'https://rooftopgardens.co.uk/',
  orderUrl: 'https://rooftopgardens.co.uk/',
  offerHeadline: 'Rooftop Happy Hour — 20% Off',
  offerValue: '20% off drinks',
};
const AD_ROOFTOP_2: AdCreative = {
  id: 'ad-rooftop-2', brand: 'Rooftop Gardens', tagline: 'Drinks with a view', emoji: '🍹', cpm: 52,
  targetSegment: 'Premium Diners · Date Night 25–54',
  whyChosen: ['Premium viewer match', 'Creative rotation — second exposure', 'Won at $52 CPM'],
  color: '#3a5a40', durationSec: 34,
  videoUrl: 'https://lavcma6duvpplftv.public.blob.vercel-storage.com/Rooftop%20Gardens%203.mp4',
  websiteUrl: 'https://rooftopgardens.co.uk/',
  menuUrl: 'https://rooftopgardens.co.uk/',
  orderUrl: 'https://rooftopgardens.co.uk/',
  offerHeadline: 'Reserve a Rooftop Table Tonight',
  offerValue: 'Priority seating',
};
const AD_OLDRAM: AdCreative = {
  id: 'ad-oldram', brand: 'Old Ram Coaching Inn', tagline: 'History, charm & great ales', emoji: '🍺', cpm: 35,
  targetSegment: 'Pub & Inn Lovers · All Ages',
  whyChosen: ['Traditional pub affinity', 'Local heritage match', 'Won at $35 CPM'],
  color: '#7c5c3e', durationSec: 29,
  videoUrl: 'https://lavcma6duvpplftv.public.blob.vercel-storage.com/Old%20Ram%20Coaching%20Inn%20.mp4',
  websiteUrl: 'https://theoldramfreehouse.com/',
  menuUrl: 'https://theoldramfreehouse.com/',
  orderUrl: 'https://theoldramfreehouse.com/',
  offerHeadline: 'First Pint on Us — Join the Inn',
  offerValue: 'Free first pint',
};

export const AD_CATALOG: AdCreative[] = [
  AD_AJWARD, AD_BONSAI, AD_ROCCOS_1, AD_ROCCOS_2,
  AD_ROOFTOP_1, AD_ROOFTOP_2, AD_OLDRAM,
];

// ── Commercial Breaks ─────────────────────────────────────────────────────────────────
// All ads are short (17–34s), so we space them ~40s apart for frequent demo visibility.
// Loop is 300s. Guard in page.tsx prevents overlap if a break is still playing.
//
//  t=15  → Rooftop Gardens short (17s)  — quick first impression
//  t=50  → AJ.Ward (31s)
//  t=95  → Rocco's #1 (31s)
//  t=140 → Bonsai Cafe (34s)
//  t=190 → Old Ram (29s)
//  t=235 → Rooftop Gardens long (34s)
//  t=280 → Rocco's #2 (34s)
//
export const COMMERCIAL_BREAKS: CommercialBreak[] = [
  { id: 'break-1', triggerAt: 15,  label: 'Commercial Break', ads: [AD_ROOFTOP_1] },
  { id: 'break-2', triggerAt: 50,  label: 'Commercial Break', ads: [AD_AJWARD]    },
  { id: 'break-3', triggerAt: 95,  label: 'Commercial Break', ads: [AD_ROCCOS_1]  },
  { id: 'break-4', triggerAt: 140, label: 'Commercial Break', ads: [AD_BONSAI]    },
  { id: 'break-5', triggerAt: 190, label: 'Commercial Break', ads: [AD_OLDRAM]    },
  { id: 'break-6', triggerAt: 235, label: 'Commercial Break', ads: [AD_ROOFTOP_2] },
  { id: 'break-7', triggerAt: 280, label: 'Commercial Break', ads: [AD_ROCCOS_2]  },
];


// ── Game Events (auto-trigger bingo + feed) ───────────────────────────────────

export const GAME_EVENTS: GameEvent[] = [
  { at: 8,   type: 'firstdown',    description: 'Eagles convert on 3rd & 7 — First Down!', team: 'home', bingoCell: 'First Down' },
  { at: 18,  type: 'touchdown',    description: 'TOUCHDOWN EAGLES! #11 Brown — 34-yard strike!', team: 'home', scoreDelta: { home: 6, away: 0 }, bingoCell: 'Touchdown' },
  // Break 1 at t=25 (Coca-Cola)
  { at: 45,  type: 'penalty',      description: 'Flag on the play — Holding, Bears #72', team: 'away', bingoCell: 'Penalty Flag' },
  { at: 55,  type: 'sack',         description: 'SACK! Eagles #99 — Bears QB down for -8 yards', team: 'home', bingoCell: 'Sack' },
  // Break 2 at t=65 (FIFA)
  { at: 85,  type: 'interception', description: 'INTERCEPTION! Eagles #24 picks it off at midfield!', team: 'home', bingoCell: 'Interception' },
  { at: 95,  type: 'fieldgoal',    description: 'Bears kick a 47-yard field goal — 3 points!', team: 'away', scoreDelta: { home: 0, away: 3 }, bingoCell: 'Field Goal' },
  // Break 3 at t=110 (TV Take)
  { at: 130, type: 'touchdown',    description: 'TOUCHDOWN EAGLES! #82 Smith — 12-yard grab!', team: 'home', scoreDelta: { home: 6, away: 0 }, bingoCell: 'Touchdown' },
  { at: 142, type: 'timeout',      description: '⏸️ Eagles call timeout', team: 'home', bingoCell: 'Timeout Called' },
  // Break 4 at t=155 (iPhone)
  { at: 175, type: 'fieldgoal',    description: 'Eagles kick a 38-yard FG to seal it!', team: 'home', scoreDelta: { home: 3, away: 0 }, bingoCell: 'Field Goal' },
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
