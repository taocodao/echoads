// autopilot.js — Cursor animation + audio + 15-step orchestration

// ── Vercel Blob Audio URLs ─────────────────────────────────
var AUDIO = {
  s01: "/demo/audio/s01.mp3",
  s02: "/demo/audio/s02.mp3",
  s03: "/demo/audio/s03.mp3",
  s04: "/demo/audio/s04.mp3",
  s05: "/demo/audio/s05.mp3",
  s06: "/demo/audio/s06.mp3",
  s07: "/demo/audio/s07.mp3",
  s08: "/demo/audio/s08.mp3",
  s09: "/demo/audio/s09.mp3",
  s10: "/demo/audio/s10.mp3",
  s11: "/demo/audio/s11.mp3",
  s12: "/demo/audio/s12.mp3",
  s13: "/demo/audio/s13.mp3",
  s14: "/demo/audio/s14.mp3",
  s15: "/demo/audio/s15.mp3"
};

// ── Voice transcripts ──────────────────────────────────────
var TRANSCRIPTS = {
  s01: "What you are looking at is the EchoAds live dashboard — running right now on AWS infrastructure, connected to the Base Sepolia blockchain. Before we demonstrate the technology, let me give you the financial context. The global digital advertising industry lost an estimated 84 billion dollars to fraud between 2023 and 2025, according to the Association of National Advertisers. Connected TV carries the highest fraud rate of any digital channel. And EchoStar's Sling platform — by design of its current architecture — cannot prove to a single advertiser that a single ad was actually watched. That is the problem EchoAds was built to solve. Let us show you how.",
  s02: "On the left is HLS — the protocol Sling TV uses today. On the right is EchoAds, running over MOQ and QUIC, connected live to our relay node at port 4443. Both are streaming the same UEFA Champions League content simultaneously. The critical difference is not what you see playing — it is what gets recorded when an ad is delivered. Watch what happens when we trigger an ad break.",
  s03: "I am clicking Force Ad Break now. The same signal fires on both sides at the same millisecond. Watch the left panel.",
  s04: "The left side just went black. For EchoStar's current urban subscribers with good broadband, this HLS reconnect delay runs 1.5 to 3 seconds — frustrating but not a crisis. The more important story is the direction EchoStar is expanding: rural markets and satellite broadband through Hughes Network Systems. On high-latency satellite links, this same structural delay runs 8 to 12 seconds, every single ad break — because it is a TCP architectural limitation, not a software bug, and no amount of engineering can eliminate it at the protocol level. EchoAds, on the right, switched in 287 milliseconds — over any network, including satellite. For the rural expansion strategy, this is not an improvement. It is the difference between a service that functions and one that does not.",
  s05: "Now look at the impression feed. Within 2 seconds of that ad playing, an immutable record appeared on the Base blockchain. It contains the ad slot ID, the exact delivery timestamp, latency confirmed at 287 milliseconds, and a USDC payment receipt. Click the Basescan link and any advertiser — on their phone right now — can independently verify that specific delivery. This is not EchoStar reporting its own numbers. This is a cryptographic fact written to a public blockchain that no one can alter after the fact. In 2025, Procter and Gamble, Unilever, and General Motors publicly announced they are concentrating their 2026 CTV budgets on platforms with verifiable delivery proof. Morgan Stanley estimates 30 percent of CTV inventory is never seen by a real viewer. PubMatic and Magnite data shows verified inventory commands 45 to 65 dollars CPM. Unverified inventory — which is what Sling Freestream sells today — commands 18 to 30 dollars. Same viewers. Same content. The difference is proof.",
  s06: "Now let me switch to the Node Operator dashboard. This shows what the infrastructure side looks like — specifically what happens to the EchoStar sites that relay these ads.",
  s07: "The node just earned 0.01 CMXS — the EchoAds network reward token, currently valued at approximately 1 dollar per token, so roughly one cent per delivery — automatically, instantly, with no invoice or manual step. At 1,440 verified deliveries per day, each EchoStar site earns approximately 432 CMXS per month — around 432 dollars. Scaled to 5,800 sites, approximately 2.5 million CMXS flows to infrastructure operators every month — that is roughly 2.5 million dollars per month, or 30 million dollars per year — distributed automatically, triggered by cryptographic delivery proof, with no human in the loop. EchoStar's sites carry the ads today and earn nothing from them. This is the software layer that changes that.",
  s08: "These are 100 consecutive ad insertion trials on AWS us-east-1. EchoAds at the 95th percentile: 312 milliseconds. Sling TV's current HLS system at the 95th percentile: 4,100 milliseconds. Thirteen times faster. But the more important number is this: 312 milliseconds clears the 500 millisecond regulatory threshold required by New Jersey and Pennsylvania gaming commissions for real-time in-play sports betting synchronization. Sling TV HLS runs 5 to 30 seconds behind live. EchoStar is categorically disqualified from the approximately 45 billion dollar US in-play sports betting wager market — not because of a business decision, but because of a protocol limitation. EchoAds removes that disqualification.",
  s09: "That was the live demonstration. Every number you just saw is real, on-chain, and publicly verifiable right now. Let me walk through what these results mean for EchoStar's four most urgent financial problems — and why solving them represents over a billion dollars in recoverable revenue.",
  s10: "Let us start with the crisis happening this quarter in EchoStar's programmatic trading relationships. The Association of National Advertisers estimated global digital ad fraud at 84 billion dollars across 2023 to 2025, with connected TV carrying the highest fraud rate of any digital channel. DoubleVerify's annual benchmarks document 30 to 70 percent year-over-year growth in CTV fraud rates, driven primarily by streaming app spoofing and bot traffic. Morgan Stanley estimates 30 percent of CTV ad inventory sold is never seen by a real viewer. For EchoStar specifically, Sling Freestream's programmatic inventory runs through open exchanges — The Trade Desk, Magnite, AppNexus. Ad verification is optional and rarely enforced. This means for every dollar an advertiser pays EchoStar, an estimated 25 to 35 cents corresponds to an impression that was never watched. When major advertisers confirm this — and they are confirming it right now, this year — platforms without verifiable delivery face systematic CPM deflation. The ones with proof capture a premium that independent research from PubMatic confirms at 2.1 to 2.8 times the unverified rate.",
  s11: "The IAB Tech Lab published its CTV Signal Integrity Framework in October 2025, explicitly calling for cryptographic delivery credentials — exactly what EchoAds generates automatically for every impression. This is an industry standards body actively requesting a solution we have already built and demonstrated live in this session. The financial impact is direct: verified inventory commands 45 to 65 dollars CPM. Unverified inventory — Sling Freestream today — commands 18 to 30 dollars. At one billion impressions per month, the difference between 25 and 55 dollar average CPMs is 30 million dollars per month — 360 million dollars per year — from inventory EchoStar already owns and sells today. No new subscribers. No new content rights. Just proof of delivery that any advertiser can verify independently.",
  s12: "The second financial crisis is one EchoStar's own advertising leadership has acknowledged publicly in trade press. The over-frequency and fill rate deficiency problem at Sling Freestream is documented across industry sources. eMarketer and Magnite's 2024 CTV Marketplace Report both cite average FAST channel fill rates of 38 to 42 percent. Any channel running below 70 percent fill is flagged by programmatic buying algorithms as diluted inventory — actively pulling down the CPM floor for the entire platform. Sling Freestream operates 600 channels. Estimates suggest 350 to 400 are in zombie status — existing but not profitable. The daily math: 600 channels, 4 ad slots per hour, 24 hours, 62 percent unfilled. That is 3.55 million wasted ad impressions per day. At a 5 dollar floor CPM, this is 650 million dollars per year in inventory that exists but cannot be monetized. EchoAds addresses this by building per-impression auction settlement into the protocol itself — eliminating the minimum commitment thresholds that currently lock out the majority of potential CTV advertisers.",
  s13: "EchoStar operates 5,800 or more owned broadcast and ground station sites. These sites carry the video that contains the ads that generate the revenue — and today they earn nothing from those ads. They receive a flat infrastructure fee regardless of how many ads flow through them or how much revenue those ads generate. EchoAds builds the revenue participation directly into the protocol. Every verified ad delivery automatically triggers a 0.01 CMXS reward — approximately one cent, in a token valued at around one dollar — to the node that relayed it. At 1,440 deliveries per day per site, each EchoStar node earns roughly 432 CMXS per month — about 432 dollars. Scaled to 5,800 sites, that is approximately 2.5 million CMXS per month — roughly 2.5 million dollars — flowing automatically to infrastructure operators every month, with no human process involved. Helium Network proved this model works, growing to nearly one million independently operated hotspots at its 2022 peak with zero company-owned nodes. EchoStar starts from a position no DePIN network has ever had: 5,800 sites already deployed, already operating, already carrying the streams.",
  s14: "The fourth opportunity is the largest single greenfield market available to EchoStar in 2026. The US in-play sports betting market represents approximately 45 billion dollars in annual wagers. New Jersey and Pennsylvania gaming commissions — governing two of the largest legal sports betting markets in the US — require real-time odds synchronization within 500 milliseconds of live action. Sling TV's HLS stream runs 5 to 30 seconds behind live. This is not a minor gap — it is a categorical disqualification. EchoStar cannot qualify as a B2B infrastructure partner for any major US sports betting operator today, regardless of content rights or subscriber scale. EchoAds at 312 milliseconds at the 95th percentile clears the regulatory threshold. The moment EchoAds deploys at scale, EchoStar becomes technically qualified — overnight — to partner with every major betting operator as a verified low-latency delivery infrastructure provider. EchoStar's current share of this market is zero. The cost to access it is a software layer on infrastructure that already exists.",
  s15: "EchoAds is not asking EchoStar to make a technology bet on a promise. Here is the summary. Four financial problems. One protocol layer. First: the ad fraud and trust crisis — Morgan Stanley's 30 percent unverified figure, the 2.1 times CPM premium for verified inventory, 360 million dollars per year in recoverable revenue from existing impressions. Second: 650 million dollars per year in zombie FAST inventory that cannot be monetized because the current infrastructure has no per-impression settlement mechanism. Third: 5,800 infrastructure sites earning zero from the advertising economy they enable — 30 million dollars per year in new revenue once EchoAds connects the delivery proof to the token reward. Fourth: a 45 billion dollar sports betting wager market EchoStar is currently 100 percent absent from due to a protocol latency limitation that EchoAds eliminates. The infrastructure is live on AWS right now. Both smart contracts are deployed on the Base blockchain and are publicly verifiable by anyone in this room. The question for EchoStar leadership is not whether this technology works. The question is whether EchoStar captures this revenue — or watches a competitor build the same system on someone else's towers."
};

// ── State ──────────────────────────────────────────────────
var currentStep = -1;
var isRunning = false;
var abortFlag = false;
var currentAudio = null;

// ── Cursor ─────────────────────────────────────────────────
var cursorEl = null;
var stageEl  = null;

function initCursor() {
  cursorEl = document.getElementById('sim-cursor');
  stageEl  = document.getElementById('pres-stage');
}

function moveCursor(targetId) {
  return new Promise(function (resolve) {
    var target = document.getElementById(targetId);
    if (!cursorEl || !target || !stageEl) { resolve(); return; }
    cursorEl.style.display = 'block';
    var tr = target.getBoundingClientRect();
    var sr = stageEl.getBoundingClientRect();
    cursorEl.style.left = (tr.left - sr.left + tr.width / 2 - 10) + 'px';
    cursorEl.style.top  = (tr.top  - sr.top  + tr.height / 2 - 4) + 'px';
    setTimeout(resolve, 700);
  });
}

function clickElement(targetId) {
  return moveCursor(targetId).then(function () {
    return new Promise(function (resolve) {
      if (cursorEl) { cursorEl.style.transform = 'scale(0.82)'; }
      var target = document.getElementById(targetId);
      if (target) target.classList.add('clicking');
      setTimeout(function () {
        if (cursorEl) cursorEl.style.transform = 'scale(1)';
        if (target) target.classList.remove('clicking');
        resolve();
      }, 200);
    });
  });
}

function hideCursor() { if (cursorEl) cursorEl.style.display = 'none'; }

// ── Audio playback ─────────────────────────────────────────
function wait(ms) { return new Promise(function (r) { setTimeout(r, ms); }); }

function speakBrowserTTS(text) {
  return new Promise(function (resolve) {
    if (!window.speechSynthesis) { resolve(); return; }
    window.speechSynthesis.cancel();
    var u = new SpeechSynthesisUtterance(text);
    u.rate = 0.90; u.pitch = 1.0; u.volume = 1.0;
    var voices = window.speechSynthesis.getVoices();
    var pref = voices.find(function (v) { return v.name.includes('Google') && v.lang.startsWith('en'); }) ||
               voices.find(function (v) { return v.lang.startsWith('en-US'); }) || voices[0];
    if (pref) u.voice = pref;
    var fallback = setTimeout(resolve, text.length * 62 + 1200);
    u.onend = function () { clearTimeout(fallback); resolve(); };
    u.onerror = function () { clearTimeout(fallback); resolve(); };
    window.speechSynthesis.speak(u);
  });
}

function playAudio(stepKey) {
  var url = AUDIO[stepKey];
  var text = TRANSCRIPTS[stepKey] || '';
  setNarration(text);

  if (url) {
    return new Promise(function (resolve) {
      currentAudio = new Audio(url);
      currentAudio.onended = function () { currentAudio = null; resolve(); };
      currentAudio.onerror = function () {
        currentAudio = null;
        speakBrowserTTS(text).then(resolve);
      };
      currentAudio.play().catch(function () {
        speakBrowserTTS(text).then(resolve);
      });
    });
  } else {
    return speakBrowserTTS(text);
  }
}

function stopAudio() {
  if (currentAudio) { currentAudio.pause(); currentAudio = null; }
  if (window.speechSynthesis) window.speechSynthesis.cancel();
}

// ── Sidebar helpers ────────────────────────────────────────
function setNarration(text) {
  var el = document.getElementById('narration-text');
  if (el) el.textContent = text;
}

function setProgress(idx) {
  var total = 15;
  var pct = Math.round(((idx + 1) / total) * 100);
  var bar = document.getElementById('pres-progress');
  if (bar) bar.style.width = pct + '%';
  var label = document.getElementById('pres-step-label');
  if (label) label.textContent = 'Step ' + (idx + 1) + ' of ' + total;
}

function updateTimeline(idx) {
  document.querySelectorAll('.tl-step').forEach(function (el, i) {
    el.classList.remove('active', 'done');
    if (i < idx) el.classList.add('done');
    else if (i === idx) el.classList.add('active');
  });
}

function setSceneBadge(text) {
  var el = document.getElementById('pres-scene-badge');
  if (el) el.textContent = text;
}

// ── Dashboard / Slide toggle ───────────────────────────────
function showDashboard() {
  var db = document.getElementById('dashboard-area');
  var sl = document.getElementById('slide-area');
  if (db) db.classList.remove('hidden');
  if (sl) { sl.classList.add('hidden'); sl.innerHTML = ''; }
  var urlEl = document.getElementById('browser-url-text');
  if (urlEl) urlEl.textContent = 'https://echoads.tv';
}

function showSlide(key) {
  hideCursor();
  var db = document.getElementById('dashboard-area');
  var sl = document.getElementById('slide-area');
  if (db) db.classList.add('hidden');
  if (sl) {
    sl.classList.remove('hidden');
    sl.innerHTML = window.Slides[key]();
  }
}

// ── Step actions ───────────────────────────────────────────
function checkAbort() { return abortFlag; }

async function step_01() {
  showDashboard();
  EchoApp.switchTab('advertiser');
  await moveCursor('stat-impressions');
  await playAudio('s01');
  await wait(400);
}

async function step_02() {
  await moveCursor('player-section');
  await playAudio('s02');
  await wait(300);
}

async function step_03() {
  setSceneBadge('Step 3 — Triggering Ad Break');
  await clickElement('force-ad-btn-pres');
  var breakPromise = EchoApp.triggerAdBreak();
  await playAudio('s03');
  return breakPromise;
}

async function step_04() {
  setSceneBadge('Step 4 — Black Screen vs. 287ms');
  await playAudio('s04');
  await wait(500);
}

async function step_05() {
  setSceneBadge('Step 5 — On-Chain Receipt');
  await moveCursor('imp-feed');
  var urlEl = document.getElementById('browser-url-text');
  if (urlEl) urlEl.textContent = 'https://echoads.tv/impressions';
  await playAudio('s05');
  await wait(400);
}

async function step_06() {
  setSceneBadge('Step 6 — Node Dashboard');
  await clickElement('nav-node-pres');
  EchoApp.switchTab('node');
  var urlEl = document.getElementById('browser-url-text');
  if (urlEl) urlEl.textContent = 'https://echoads.tv/node';
  await playAudio('s06');
  await wait(300);
}

async function step_07() {
  setSceneBadge('Step 7 — CMXS Earnings');
  await moveCursor('node-cmxs');
  await playAudio('s07');
  await wait(400);
}

async function step_08() {
  setSceneBadge('Step 8 — Benchmark');
  await clickElement('nav-benchmark-pres');
  EchoApp.switchTab('benchmark');
  var urlEl = document.getElementById('browser-url-text');
  if (urlEl) urlEl.textContent = 'https://echoads.tv/benchmark';
  await playAudio('s08');
  await wait(400);
}

async function step_09() {
  setSceneBadge('Step 9 — Transition to Slides');
  hideCursor();
  await playAudio('s09');
  await wait(600);
}

async function step_10() {
  showSlide('s10');
  setSceneBadge('Slide 1 — Problem #1: Ad Fraud & Trust Crisis');
  await playAudio('s10');
  await wait(600);
}

async function step_11() {
  showSlide('s11');
  setSceneBadge('Slide 2 — Verified CPM Premium');
  await playAudio('s11');
  await wait(600);
}

async function step_12() {
  showSlide('s12');
  setSceneBadge('Slide 3 — Problem #2: $650M Zombie Inventory');
  await playAudio('s12');
  await wait(600);
}

async function step_13() {
  showSlide('s13');
  setSceneBadge('Slide 4 — Problem #3: Towers Earn $0');
  await playAudio('s13');
  await wait(600);
}

async function step_14() {
  showSlide('s14');
  setSceneBadge('Slide 5 — Problem #4: $45B Sports Betting');
  await playAudio('s14');
  await wait(600);
}

async function step_15() {
  showSlide('s15');
  setSceneBadge('Slide 6 — The One-Sentence Summary');
  await playAudio('s15');
  await wait(800);
}

var STEPS = [
  { label: 'Dashboard Overview',           fn: step_01 },
  { label: 'Player Introduction',           fn: step_02 },
  { label: 'Trigger Ad Break',              fn: step_03 },
  { label: 'HLS vs QUIC Comparison',        fn: step_04 },
  { label: 'On-Chain Delivery Proof',       fn: step_05 },
  { label: 'Node Dashboard',                fn: step_06 },
  { label: 'CMXS Earnings — $30M/yr',      fn: step_07 },
  { label: 'Benchmark — 13× Faster',       fn: step_08 },
  { label: 'Transition to Slides',          fn: step_09 },
  { label: 'Problem #1: Ad Fraud Crisis',   fn: step_10 },
  { label: 'Verified CPM Premium',          fn: step_11 },
  { label: 'Problem #2: $650M Inventory',   fn: step_12 },
  { label: 'Problem #3: Towers Earn $0',    fn: step_13 },
  { label: 'Problem #4: Sports Betting',    fn: step_14 },
  { label: 'The One-Sentence Summary',      fn: step_15 }
];

// ── Main orchestrator ──────────────────────────────────────
async function runPresentation() {
  isRunning = true;
  abortFlag = false;
  EchoApp.resetAll();
  showDashboard();

  for (var i = 0; i < STEPS.length; i++) {
    if (abortFlag) break;
    currentStep = i;
    setProgress(i);
    updateTimeline(i);
    setSceneBadge('Step ' + (i + 1) + ' of 15');
    try { await STEPS[i].fn(); } catch (e) { console.warn('Step error', e); }
    if (abortFlag) break;
  }
  endPresentation(!abortFlag);
}

function endPresentation(completed) {
  isRunning = false;
  hideCursor();
  stopAudio();
  var btn = document.getElementById('pres-ctrl-btn');
  if (btn) { btn.textContent = completed ? '\u21ba Replay' : '\u25b6 Start Demo'; btn.classList.remove('stop'); }
  var label = document.getElementById('pres-step-label');
  if (label) label.textContent = completed ? 'Demo Complete' : 'Stopped';
  if (completed) {
    updateTimeline(STEPS.length);
    document.getElementById('pres-progress').style.width = '100%';
  }
}

function stopPresentation() {
  abortFlag = true;
  stopAudio();
  isRunning = false;
  hideCursor();
  var btn = document.getElementById('pres-ctrl-btn');
  if (btn) { btn.textContent = '\u25b6 Start Demo'; btn.classList.remove('stop'); }
}

// ── Timeline builder ───────────────────────────────────────
function buildTimeline() {
  var tl = document.getElementById('timeline-list');
  if (!tl) return;
  tl.innerHTML = '';
  STEPS.forEach(function (s, i) {
    var div = document.createElement('div');
    div.className = 'tl-step';
    div.id = 'tl-' + i;
    div.innerHTML = '<div class="tl-dot">' + (i + 1) + '</div><span>' + s.label + '</span>';
    tl.appendChild(div);
  });
}

// ── Init ───────────────────────────────────────────────────
document.addEventListener('DOMContentLoaded', function () {
  initCursor();
  buildTimeline();
  EchoApp.buildBenchmarkHTML();

  if (window.speechSynthesis) {
    window.speechSynthesis.getVoices();
    window.speechSynthesis.addEventListener('voiceschanged', function () {
      window.speechSynthesis.getVoices();
    });
  }

  var ctrlBtn = document.getElementById('pres-ctrl-btn');
  ctrlBtn.addEventListener('click', function () {
    if (isRunning) {
      stopPresentation();
    } else {
      ctrlBtn.textContent = '\u23f9 Stop';
      ctrlBtn.classList.add('stop');
      runPresentation();
    }
  });

  // Manual nav clicks when not running
  document.querySelectorAll('.nav-link').forEach(function (link) {
    link.addEventListener('click', function () {
      if (!isRunning) EchoApp.switchTab(link.dataset.tab);
    });
  });

  // Manual ad break
  var adBtn = document.getElementById('force-ad-btn-pres');
  if (adBtn) {
    adBtn.addEventListener('click', function () {
      if (!isRunning) EchoApp.triggerAdBreak();
    });
  }
});
