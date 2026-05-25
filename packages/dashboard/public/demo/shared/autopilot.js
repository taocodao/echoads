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
  s01: "Welcome to EchoAds Phase Zero. What you are seeing is the live advertiser dashboard, running right now at echoads dot TV. This is not a mock-up. The relay node is live on AWS. Both smart contracts are deployed on the Base Sepolia blockchain. Notice the impression counter is at zero. This is the baseline before a single ad has run.",
  s02: "On the left is HLS running over TCP — the protocol that Sling TV uses today. On the right is EchoAds — connected live to our QUIC relay node at port 4443. Both sides are streaming the same UEFA Champions League highlights simultaneously. Same content. Same moment in time. Different transport layers. Watch what happens when we trigger an ad break.",
  s03: "I am now clicking Force Ad Break. The same ad signal fires on both sides at exactly the same moment. Watch the left panel carefully.",
  s04: "The left side has gone completely black. This is what every Sling TV subscriber sees every time an ad plays. TCP must tear down the connection, negotiate a new one with the ad server, then download and buffer the entire ad segment. 3 to 7 seconds. Every single time. Structurally. Meanwhile the right side — EchoAds — switched in 287 milliseconds. Not because we wrote better software. Because QUIC is multiplexed. The content and the ad share the same connection simultaneously. There is no black screen because there is no reconnection.",
  s05: "Within 2 seconds of that ad playing, a record appeared automatically. It shows the ad slot ID, delivery latency confirmed at 287 milliseconds, a USDC micropayment settled on the Base blockchain, and a transaction hash. That link opens Basescan — the public blockchain explorer. Anyone in this room can verify that transaction right now on their phone. This is the first cryptographic proof of delivery in the history of connected TV advertising.",
  s06: "Now switching to the Node Operator dashboard. This shows the perspective of whoever owns the infrastructure that just delivered that ad.",
  s07: "The node just earned 0.001 CMXS tokens — automatically, instantly, with no invoice or manual step. Now replace this AWS instance with an EchoStar tower. EchoStar has 60,000 towers. At 1,440 deliveries per day per node, each tower earns approximately 43 CMXS per month. Across all 60,000 towers, 2.6 million CMXS circulates monthly — automatically. EchoStar's towers carry the ads today. They earn nothing from them. EchoAds changes that.",
  s08: "This is not one lucky result. 100 consecutive trials. EchoAds at the 95th percentile: 312 milliseconds. Sling TV's current system at the 95th percentile: 4,100 milliseconds. 13 times faster. And 312 milliseconds clears the 500 millisecond regulatory threshold for live sports betting — a 45 billion dollar market Sling TV is currently 100 percent locked out of.",
  s09: "That was the live demonstration. Everything you just saw is running in production right now. Now let us talk about what it means for EchoStar.",
  s10: "Every time Sling TV inserts an ad today, HLS tears down the existing TCP connection and rebuilds a new one. This is not a software bug — it is a structural limitation of TCP that cannot be patched. Nearly 80 percent of connected TV viewers report that ad loading delays significantly damage their perception of the advertised brand. EchoAds eliminates this at the protocol level. 287 milliseconds. Zero black screen.",
  s11: "Today, the entire connected TV advertising industry operates on an honor system. Advertisers pay based entirely on data the platform itself reports. There is no independent proof. Global digital advertising fraud reached 84 billion dollars in 2026, with connected TV carrying the highest fraud rate. Morgan Stanley estimates 30 percent of CTV inventory is never seen by a real viewer. EchoAds generates an immutable on-chain receipt for every single impression — mathematically guaranteed proof of delivery that no one can alter after the fact.",
  s12: "Sling Freestream operates 600 channels. Industry data shows FAST channels run at roughly 38 percent fill rates on average. A channel under 70 percent fill is zombie inventory — pulling down the pricing floor for the entire platform. EchoAds builds per-impression auction settlement directly into the protocol. Combined with on-chain frequency caps enforced by smart contract, both fill rate and targeting precision improve structurally.",
  s13: "EchoStar's 60,000 towers carry the video that contains the ads that generate the revenue — and earn nothing from those ads today. EchoAds builds the revenue-sharing mechanism directly into the protocol. Every node operator earns 0.001 CMXS automatically per verified delivery. More infrastructure leads to better delivery. Better delivery attracts more advertisers. More advertisers increase token value. Higher token value incentivizes more operators to join. This is the DePIN flywheel — and EchoStar's towers are already in the ground.",
  s14: "The 312 millisecond latency EchoAds achieves does not just fix the black screen. It unlocks a market Sling TV is 100 percent locked out of today. The regulatory threshold for real-time odds updates in live sports betting is under 500 milliseconds. Sling TV HLS streams run 5 to 30 seconds behind live action. EchoAds, at 312 milliseconds at P95, clears the threshold. The US in-play sports betting market exceeds 45.9 billion dollars annually. Simultaneously, cryptographic delivery proof enables a verified CPM premium — from 18 to 30 dollars today, to 45 to 65 dollars with on-chain proof. Same inventory. Same viewers. Revenue roughly doubles — without adding a single new subscriber.",
  s15: "EchoAds is not asking EchoStar to make a technology bet on a promise. Everything you just saw is running in production right now. The relay node is live on AWS. Both smart contracts are deployed and independently verifiable on the Base blockchain. The question for EchoStar is straightforward: do you want to capture the verified-impression premium, the sports betting synchronization market, and the DePIN node reward economy? Or do those opportunities go to a competitor building the same system on someone else's towers?"
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
  if (el) el.textContent = '\u201c' + text + '\u201d';
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
  setSceneBadge('Slide 1 — Problem: Black Screen');
  await playAudio('s10');
  await wait(600);
}

async function step_11() {
  showSlide('s11');
  setSceneBadge('Slide 2 — Problem: No Proof');
  await playAudio('s11');
  await wait(600);
}

async function step_12() {
  showSlide('s12');
  setSceneBadge('Slide 3 — Problem: Fill Rates');
  await playAudio('s12');
  await wait(600);
}

async function step_13() {
  showSlide('s13');
  setSceneBadge('Slide 4 — Problem: DePIN');
  await playAudio('s13');
  await wait(600);
}

async function step_14() {
  showSlide('s14');
  setSceneBadge('Slide 5 — Sports Betting + CPM');
  await playAudio('s14');
  await wait(600);
}

async function step_15() {
  showSlide('s15');
  setSceneBadge('Slide 6 — Scale + Closing');
  await playAudio('s15');
  await wait(800);
}

var STEPS = [
  { label: 'Dashboard Overview',      fn: step_01 },
  { label: 'Player Introduction',     fn: step_02 },
  { label: 'Trigger Ad Break',        fn: step_03 },
  { label: 'Black Screen vs QUIC',    fn: step_04 },
  { label: 'On-Chain Receipt',        fn: step_05 },
  { label: 'Node Dashboard',          fn: step_06 },
  { label: 'CMXS Earnings',           fn: step_07 },
  { label: 'Benchmark Results',       fn: step_08 },
  { label: 'Transition to Slides',    fn: step_09 },
  { label: 'Problem 1: Black Screen', fn: step_10 },
  { label: 'Problem 2: No Proof',     fn: step_11 },
  { label: 'Problem 3: Fill Rates',   fn: step_12 },
  { label: 'Problem 4: DePIN',        fn: step_13 },
  { label: 'Sports Betting + CPM',    fn: step_14 },
  { label: 'Scale + Closing',         fn: step_15 }
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
