// autopilot-ag.js — 18-scene orchestrator for AntiGravity auto-pilot demo

(function () {
'use strict';

var AUDIO_BASE = '/demo/antigravity/audio/';
var currentAudio = null;
var isRunning = false;
var abortFlag = false;
var cursorEl = null;
var stageEl  = null;

// ── State shared across scenes ──────────────────────────────
var simState = { totalMinted: 0, totalBurned: 0, cycleCount: 0 };
var lastAuction = null;
var lastDelivery = null;

// ── Helpers ─────────────────────────────────────────────────
function $(id) { return document.getElementById(id); }
function wait(ms) { return new Promise(function(r){ setTimeout(r, ms); }); }

function setText(id, v) { var el=$(id); if(el) el.textContent = v; }
function show(id) { var el=$(id); if(el) el.style.display=''; }
function hide(id) { var el=$(id); if(el) el.style.display='none'; }
function addClass(id, c) { var el=$(id); if(el) el.classList.add(c); }
function removeClass(id, c) { var el=$(id); if(el) el.classList.remove(c); }

// ── Audio ────────────────────────────────────────────────────
// ── Audio + Narration ────────────────────────────────────────────
var wordTimers = [];

function clearWordTimers() {
  wordTimers.forEach(function(t){ clearTimeout(t); });
  wordTimers = [];
}

function buildWordHighlight(text) {
  var el = document.getElementById('ag-narration-text');
  if (!el) return;
  var words = text.split(' ');
  el.innerHTML = words.map(function(w, i) {
    return '<span class="nar-word" id="nar-w-'+i+'">' + w + ' </span>';
  }).join('');
}

function animateWords(text, durationMs) {
  clearWordTimers();
  buildWordHighlight(text);
  var words = text.split(' ');
  var msPerWord = Math.max(120, durationMs / words.length);
  words.forEach(function(w, i) {
    // Mark previous as spoken, current as current
    wordTimers.push(setTimeout(function() {
      var prev = document.getElementById('nar-w-' + (i - 1));
      if (prev) { prev.classList.remove('current'); prev.classList.add('spoken'); }
      var cur = document.getElementById('nar-w-' + i);
      if (cur) { cur.classList.add('current'); }
    }, i * msPerWord));
  });
  // Mark last word spoken at end
  wordTimers.push(setTimeout(function() {
    var last = document.getElementById('nar-w-' + (words.length - 1));
    if (last) { last.classList.remove('current'); last.classList.add('spoken'); }
  }, words.length * msPerWord));
}

function updateSidebarNarration(text) {
  var el = document.querySelector('#ag-narration .nar-text');
  if (el) el.textContent = text;
}

function playAudio(key) {
  var text = window.AgTranscripts && window.AgTranscripts[key] || '';
  updateSidebarNarration(text);
  return new Promise(function(resolve) {
    if (currentAudio) { currentAudio.pause(); currentAudio = null; }
    clearWordTimers();
    var audio = new Audio(AUDIO_BASE + key + '.mp3');
    currentAudio = audio;
    audio.addEventListener('loadedmetadata', function() {
      animateWords(text, audio.duration * 1000);
    });
    audio.onended = function() { currentAudio = null; resolve(); };
    audio.onerror = function() {
      currentAudio = null;
      var fallbackMs = text.split(' ').length * 420 + 1000;
      animateWords(text, fallbackMs);
      speakTTS(text).then(resolve);
    };
    audio.play().catch(function() {
      var fallbackMs = text.split(' ').length * 420 + 1000;
      animateWords(text, fallbackMs);
      speakTTS(text).then(resolve);
    });
  });
}

function speakTTS(text) {
  return new Promise(function(resolve) {
    if (!window.speechSynthesis || !text) { resolve(); return; }
    window.speechSynthesis.cancel();
    var u = new SpeechSynthesisUtterance(text);
    u.rate = 0.88; u.pitch = 1.0; u.volume = 1.0;
    var voices = window.speechSynthesis.getVoices();
    var pref = voices.find(function(v){ return v.name.includes('Google') && v.lang.startsWith('en'); })
      || voices.find(function(v){ return v.lang.startsWith('en-US'); }) || voices[0];
    if (pref) u.voice = pref;
    var fb = setTimeout(resolve, text.length * 60 + 1000);
    u.onend = function() { clearTimeout(fb); resolve(); };
    u.onerror = function() { clearTimeout(fb); resolve(); };
    window.speechSynthesis.speak(u);
  });
}

function stopAudio() {
  if (currentAudio) { currentAudio.pause(); currentAudio = null; }
  if (window.speechSynthesis) window.speechSynthesis.cancel();
}

// ── Cursor ───────────────────────────────────────────────────
function initCursor() {
  cursorEl = $('ag-cursor');
  stageEl  = $('ag-stage');
}

function moveCursor(id) {
  return new Promise(function(resolve) {
    var target = $(id);
    if (!cursorEl || !target || !stageEl) { resolve(); return; }
    cursorEl.style.display = 'block';
    var tr = target.getBoundingClientRect();
    var sr = stageEl.getBoundingClientRect();
    cursorEl.style.left = (tr.left - sr.left + tr.width/2 - 10) + 'px';
    cursorEl.style.top  = (tr.top  - sr.top  + tr.height/2 - 4) + 'px';
    setTimeout(resolve, 650);
  });
}

function clickEl(id) {
  return moveCursor(id).then(function() {
    return new Promise(function(resolve) {
      if (cursorEl) cursorEl.style.transform = 'scale(0.8)';
      var el = $(id); if (el) el.classList.add('clicking');
      setTimeout(function() {
        if (cursorEl) cursorEl.style.transform = 'scale(1)';
        if (el) el.classList.remove('clicking');
        resolve();
      }, 200);
    });
  });
}

function hideCursor() { if (cursorEl) cursorEl.style.display = 'none'; }

// ── Spotlight: highlight which panel to watch ───────────────────────
function clearSpotlights() {
  document.querySelectorAll('.spotlight').forEach(function(el) {
    el.classList.remove('spotlight');
  });
}
function spotlight(id) {
  clearSpotlights();
  var el = $(id);
  if (el) el.classList.add('spotlight');
}

// ── Dashboard / Slide toggle ──────────────────────────────
function showDashboard() {
  var db = $('ag-dashboard-area');
  var sl = $('ag-slide-area');
  if (db) db.classList.remove('hidden');
  if (sl) { sl.classList.remove('visible'); sl.innerHTML = ''; }
}

function showSlide(key) {
  hideCursor();
  var db = $('ag-dashboard-area');
  var sl = $('ag-slide-area');
  if (db) db.classList.add('hidden');
  if (sl && window.SlidesAG && window.SlidesAG[key]) {
    sl.innerHTML = window.SlidesAG[key]();
    sl.classList.add('visible');
  }
}

// ── Pipeline step highlight ───────────────────────────────────
var PIPE_STEPS = ['bid','auction','deliver','watch','pod','mint','burn'];

function setPipeStep(active) {
  PIPE_STEPS.forEach(function(s, i) {
    var el = $('pipe-'+s);
    if (!el) return;
    el.classList.remove('active','done');
    if (i < active) el.classList.add('done');
    else if (i === active) el.classList.add('active');
  });
}

// ── Particle burst ─────────────────────────────────────────────
function burst(anchorId, color, count) {
  var anchor = $(anchorId);
  var stage  = $('ag-stage');
  if (!anchor || !stage) return;
  var r = anchor.getBoundingClientRect();
  var sr = stage.getBoundingClientRect();
  var cx = r.left - sr.left + r.width/2;
  var cy = r.top  - sr.top  + r.height/2;
  for (var i = 0; i < (count||12); i++) {
    var p = document.createElement('div');
    p.className = 'ag-particle';
    var angle = Math.random() * Math.PI * 2;
    var dist  = 30 + Math.random() * 50;
    p.style.cssText = [
      'width:4px','height:4px',
      'background:'+color,
      'left:'+(cx-2)+'px','top:'+(cy-2)+'px',
      '--dx:'+Math.cos(angle)*dist+'px',
      '--dy:'+Math.sin(angle)*dist+'px',
      'animation-duration:'+(0.6+Math.random()*0.4)+'s'
    ].join(';');
    stage.appendChild(p);
    setTimeout(function(pp){ pp.remove(); }, 1200, p);
  }
}

// ── Bid board renderer ─────────────────────────────────────────
function renderBids(bidsResult) {
  var el = $('ag-bid-board');
  if (!el) return;
  el.innerHTML = '';
  var sorted = bidsResult.bids.slice().sort(function(a,b){ return b.price-a.price; });
  sorted.forEach(function(b, i) {
    var row = document.createElement('div');
    row.className = 'ag-bid-row' + (b.aboveFloor ? '' : ' below-floor');
    row.style.animationDelay = (i*0.12)+'s';
    row.innerHTML =
      '<div class="ag-bid-dot" style="background:'+b.color+'"></div>' +
      '<span class="ag-bid-name">'+b.dspName+'</span>' +
      '<span class="ag-bid-price" style="color:'+b.color+'">$'+b.price.toFixed(2)+' CPM</span>' +
      '<span class="ag-bid-badge'+(b.aboveFloor?'':' floor-fail')+'">'+
        (b.aboveFloor?'Eligible':'Below Floor')+'</span>';
    el.appendChild(row);
  });
  setText('ag-floor-val', '$'+bidsResult.floorCpm.toFixed(2));
  setText('ag-auction-ms', bidsResult.auctionLatencyMs+'ms');
}

// ── Auction result renderer ────────────────────────────────────
function renderAuction(result) {
  var el = $('ag-bid-board');
  if (!el) return;
  Array.from(el.querySelectorAll('.ag-bid-row')).forEach(function(row) {
    var nameEl = row.querySelector('.ag-bid-name');
    if (nameEl && nameEl.textContent === result.winner.dspName) {
      row.classList.add('winner');
    }
  });
  setText('ag-winner-name', result.winner.dspName);
  setText('ag-clear-price', '$'+result.clearPrice.toFixed(2)+' CPM');
  setText('ag-slot-id', result.slotId);
  show('ag-auction-result');
}

// ── Latency bars ───────────────────────────────────────────────
function animateLatency(delivery) {
  setText('ag-moq-ms', delivery.moqLatencyMs+'ms '+(delivery.slaMet?'✅':'⚠'));
  setText('ag-hls-ms', delivery.hlsLatencyMs+'ms ❌');
  var maxMs = 5000;
  var moqPct = Math.min((delivery.moqLatencyMs/maxMs)*100, 100);
  var hlsPct = Math.min((delivery.hlsLatencyMs/maxMs)*100, 100);
  setTimeout(function() {
    var moqBar = $('ag-lat-moq'); if (moqBar) moqBar.style.width = moqPct+'%';
    var hlsBar = $('ag-lat-hls'); if (hlsBar) hlsBar.style.width = hlsPct+'%';
  }, 200);
}

// ── PoD signature typewriter ──────────────────────────────────
function typeHash(id, hash) {
  return new Promise(function(resolve) {
    var el = $(id); if (!el) { resolve(); return; }
    el.textContent = '';
    var i = 0;
    var interval = setInterval(function() {
      if (i >= hash.length || abortFlag) { clearInterval(interval); resolve(); return; }
      var span = document.createElement('span');
      span.className = 'ag-pod-char';
      span.textContent = hash[i++];
      el.appendChild(span);
    }, 12);
  });
}

// ── BME gauge update ──────────────────────────────────────────
function updateBME(burnResult) {
  var mintPct = 100 - burnResult.burnRatioPct;
  var bar = $('ag-bme-mint'); if (bar) bar.style.width = mintPct+'%';
  setText('ag-bme-mint-val', burnResult.totalMinted.toFixed(3)+' CMXS');
  setText('ag-bme-burn-val', burnResult.totalBurned.toFixed(4)+' CMXS');
  setText('ag-bme-status', burnResult.isDeflationary ? '🔻 Deflationary ✅' : '📈 Inflationary');
  setText('ag-bme-ratio', burnResult.burnRatioPct+'% burn');
}

// ── Timeline & progress ───────────────────────────────────────
var STEPS_META = [
  'Overview','DSP Bids','Auction','Delivery','Ad Watch','PoD Signing',
  'Oracle + Mint','CMXS Burn','Transition',
  'Ad Fraud Problem','CPM Premium','Sports Betting','312ms Benchmark',
  'BME Economics','PoD vs PoW vs PoS','Tower Revenue','Demand Flywheel','Summary'
];

function buildTimeline() {
  var tl = $('ag-timeline-vert'); if (!tl) return;
  tl.innerHTML = '';
  STEPS_META.forEach(function(label, i) {
    var row = document.createElement('div');
    row.className = 'tl-dot-v';
    row.id = 'tl-' + i;
    var num = document.createElement('div');
    num.className = 'tl-dot-v-num';
    num.textContent = (i + 1);
    var lbl = document.createElement('div');
    lbl.className = 'tl-dot-v-label';
    lbl.textContent = label;
    row.appendChild(num);
    row.appendChild(lbl);
    tl.appendChild(row);
  });
}

function setProgress(idx) {
  var pct = Math.round(((idx+1)/18)*100);
  var bar = $('ag-progress-bar'); if (bar) bar.style.width = pct+'%';
  setText('ag-progress-label', 'Step '+(idx+1)+' of 18');
  // Update sidebar status
  var dot = document.querySelector('.ag-status-dot');
  var lbl = document.querySelector('.ag-status-label');
  if (dot) { dot.className = 'ag-status-dot running'; }
  if (lbl) lbl.textContent = 'Scene ' + (idx+1) + ' of 18';
  // Update vertical timeline dots
  document.querySelectorAll('.tl-dot-v').forEach(function(el, i) {
    el.classList.remove('active','done');
    if (i < idx) el.classList.add('done');
    else if (i === idx) el.classList.add('active');
  });
  var active = $('tl-'+idx);
  if (active) active.scrollIntoView({ behavior:'smooth', block:'nearest' });
}

// ── Scene Focus System ─────────────────────────────────────────
var SCENE_PANELS = {
  'overview':  { show: ['panel-kpi'],           ghost: [] },
  'bid':       { show: ['panel-bid'],           ghost: [] },
  'auction':   { show: ['panel-auction'],       ghost: ['panel-bid'] },
  'deliver':   { show: ['panel-latency'],       ghost: [] },
  'watch':     { show: ['panel-latency'],       ghost: [] },
  'pod':       { show: ['panel-pod'],           ghost: [] },
  'oracle':    { show: ['panel-oracle'],        ghost: ['panel-pod'] },
  'burn':      { show: ['panel-burn'],          ghost: ['panel-oracle'] },
  'transition':{ show: [],                      ghost: [] }
};

function setScene(name) {
  var config = SCENE_PANELS[name] || { show: [], ghost: [] };
  // Hide all panels
  document.querySelectorAll('.ag-panel').forEach(function(el) {
    el.classList.remove('active', 'ghost');
    el.style.display = 'none';
  });
  // Show active panels
  config.show.forEach(function(id) {
    var el = $(id);
    if (el) { el.style.display = 'flex'; el.classList.add('active'); }
  });
  // Show ghost panels
  config.ghost.forEach(function(id) {
    var el = $(id);
    if (el) { el.style.display = 'flex'; el.classList.add('ghost'); }
  });
}

// ── Individual scene functions ────────────────────────────────
async function scene01() {
  setScene('overview');
  showDashboard(); setPipeStep(-1); clearSpotlights();
  spotlight('ag-stat-impressions-card');
  await moveCursor('ag-stat-impressions');
  await playAudio('ag01');
}

async function scene02() {
  setScene('bid');
  setPipeStep(0);
  var bidsResult = AgSim.generateBids({ floorCpm:15, channel:'sports/live' });
  lastAuction = bidsResult;
  renderBids(bidsResult);
  spotlight('ag-bid-board');
  await moveCursor('ag-bid-board');
  await playAudio('ag02');
}

async function scene03() {
  setScene('auction');
  setPipeStep(1);
  var result = AgSim.runAuction(lastAuction.bids, lastAuction.floorCpm);
  if (result) { lastAuction.result = result; renderAuction(result); }
  spotlight('ag-auction-result');
  await clickEl('ag-run-auction-btn');
  await playAudio('ag03');
}

async function scene04() {
  setScene('deliver');
  setPipeStep(2);
  var delivery = AgSim.simulateDelivery();
  lastDelivery = delivery;
  animateLatency(delivery);
  burst('ag-moq-ms', 'var(--cyan)', 10);
  setText('ag-chrome-url', 'https://echoads.tv/delivery-live');
  spotlight('ag-lat-moq');
  await playAudio('ag04');
}

async function scene05() {
  setScene('watch');
  setPipeStep(3); clearSpotlights();
  setText('ag-watch-timer', '30s');
  await playAudio('ag05');
}

async function scene06() {
  setScene('pod');
  setPipeStep(4);
  var imp  = lastAuction.result ? lastAuction.result.impressionId : AgSim.genHash(64);
  var node = lastDelivery ? lastDelivery.nodeAddress : '0x' + 'node'.padEnd(40,'0');
  var cpm  = lastAuction.result ? lastAuction.result.clearPrice : 15;
  var pod  = AgSim.signPoD(imp, node, cpm);
  setText('ag-pod-impression', imp.slice(0,18)+'…');
  setText('ag-pod-node', node.slice(0,18)+'…');
  setText('ag-pod-cpm', '$'+cpm.toFixed(2));
  var sigPromise = typeHash('ag-pod-signature', pod.signature);
  spotlight('ag-pod-signature');
  await playAudio('ag06');
  await sigPromise;
}

async function scene07() {
  setScene('oracle');
  setPipeStep(5);
  spotlight('ag-oracle-check1');
  setText('ag-oracle-check1', 'Verifying ECDSA signature…');
  await wait(600);
  setText('ag-oracle-check1', '✅ ECDSA signature verified');
  setText('ag-oracle-check2', 'Checking replay protection…');
  await wait(600);
  setText('ag-oracle-check2', '✅ Impression ID unique — accepted');
  setText('ag-oracle-check3', 'Confirming latency SLA…');
  await wait(600);
  setText('ag-oracle-check3', '✅ '+( lastDelivery ? lastDelivery.moqLatencyMs : 287 )+'ms < 500ms threshold');
  await wait(400);
  var mint = AgSim.verifyAndMint({});
  simState.totalMinted += 0.001;
  setText('ag-mint-amount', '+0.001 CMXS');
  burst('ag-mint-amount', '#00ff88', 16);
  spotlight('ag-mint-amount');
  setText('ag-pod-hash', mint.podHash.slice(0,18)+'…');
  setText('ag-basescan-link', 'View on Basescan ↗');
  var link = $('ag-basescan-link');
  if (link) link.href = mint.basescanUrl;
  await playAudio('ag07');
}

async function scene08() {
  setScene('burn');
  setPipeStep(6);
  var cpm = lastAuction.result ? lastAuction.result.clearPrice : 15;
  var burnResult = AgSim.burnForAdSpend(cpm, simState);
  setText('ag-burn-usdc',   '$'+burnResult.usdcAmount.toFixed(6)+' USDC');
  setText('ag-burn-amount', burnResult.burnAmount.toFixed(4)+' CMXS');
  burst('ag-burn-amount', '#ff3b5c', 14);
  updateBME(burnResult);
  spotlight('ag-burn-amount');
  await playAudio('ag08');
}

async function scene09() {
  setScene('transition');
  hideCursor(); clearSpotlights();
  await playAudio('ag09');
  await wait(500);
}

async function makeSlideScene(key) {
  showSlide(key);
  await wait(300);
  animateSlideNumbers();

  // Move cursor to the first big stat and "click" it
  var firstStat = document.querySelector('#ag-slide-area .ag-stat-big');
  if (firstStat && firstStat.id) await moveCursor(firstStat.id);

  // Start narration immediately
  var audioPromise = playAudio(key);

  // --- Continuous in-slide animation loop ---
  // 1. Flash table rows one by one
  var rows = Array.from(document.querySelectorAll('#ag-slide-area .ag-table tbody tr'));
  rows.forEach(function(row, i) {
    setTimeout(function() {
      row.classList.add('row-flash');
      setTimeout(function() { row.classList.remove('row-flash'); }, 950);
    }, 700 + i * 1100);
  });

  // 2. Pulse each KPI card sequentially
  var cards = Array.from(document.querySelectorAll('#ag-slide-area .ag-kpi-card, #ag-slide-area .ag-kpi-card'));
  cards.forEach(function(card, i) {
    setTimeout(function() {
      card.classList.add('card-pulse');
      setTimeout(function() { card.classList.remove('card-pulse'); }, 1050);
    }, 500 + i * 1400);
  });

  // 3. Pop each big stat value mid-narration
  var stats = Array.from(document.querySelectorAll('#ag-slide-area .ag-stat-big, #ag-slide-area .ag-kpi-val'));
  stats.forEach(function(el, i) {
    setTimeout(function() {
      el.classList.add('stat-pop');
      if (el.id) moveCursor(el.id);
      setTimeout(function() { el.classList.remove('stat-pop'); }, 550);
    }, 1200 + i * 1600);
  });

  // 4. Click on info-boxes (visual only)
  var boxes = Array.from(document.querySelectorAll('#ag-slide-area .ag-info-box'));
  boxes.forEach(function(box, i) {
    setTimeout(function() {
      if (!box.id) box.id = 'slide-box-' + i;
      clickEl(box.id);
    }, 2000 + i * 2000);
  });

  await audioPromise;
  await wait(400);
}

function animateSlideNumbers() {
  var vals = document.querySelectorAll('#ag-slide-area .ag-kpi-val, #ag-slide-area .ag-stat-big, #ag-slide-area .ag-mint-amount');
  vals.forEach(function(el) {
    var orig = el.textContent.trim();
    // Detect numeric prefix like $84B, 312ms, +$360M etc
    var match = orig.match(/^([^\d]*)(\d+(?:\.\d+)?)(.*)$/);
    if (!match) return;
    var prefix = match[1], num = parseFloat(match[2]), suffix = match[3];
    var start = 0, duration = 900, startTime = null;
    function step(ts) {
      if (!startTime) startTime = ts;
      var progress = Math.min((ts - startTime) / duration, 1);
      var eased = 1 - Math.pow(1 - progress, 3);
      var current = Math.round(start + (num - start) * eased * 10) / 10;
      el.textContent = prefix + (current % 1 === 0 ? Math.round(current) : current.toFixed(1)) + suffix;
      if (progress < 1) requestAnimationFrame(step);
      else el.textContent = orig;
    }
    requestAnimationFrame(step);
  });
}

// ── Steps array ───────────────────────────────────────────────
var STEPS = [
  { label:'Overview',          fn: scene01 },
  { label:'DSP Bids',          fn: scene02 },
  { label:'Auction',           fn: scene03 },
  { label:'Delivery',          fn: scene04 },
  { label:'Ad Watch',          fn: scene05 },
  { label:'PoD Signing',       fn: scene06 },
  { label:'Oracle + Mint',     fn: scene07 },
  { label:'CMXS Burn',         fn: scene08 },
  { label:'Transition',        fn: scene09 },
  { label:'Ad Fraud',          fn: function(){ return makeSlideScene('ag10'); } },
  { label:'CPM Premium',       fn: function(){ return makeSlideScene('ag11'); } },
  { label:'Sports Betting',    fn: function(){ return makeSlideScene('ag12'); } },
  { label:'312ms Benchmark',   fn: function(){ return makeSlideScene('ag13'); } },
  { label:'BME Economics',     fn: function(){ return makeSlideScene('ag14'); } },
  { label:'PoD vs PoW vs PoS', fn: function(){ return makeSlideScene('ag15'); } },
  { label:'Tower Revenue',     fn: function(){ return makeSlideScene('ag16'); } },
  { label:'Demand Flywheel',   fn: function(){ return makeSlideScene('ag17'); } },
  { label:'Summary',           fn: function(){ return makeSlideScene('ag18'); } }
];

// ── Main orchestrator ─────────────────────────────────────────
async function runPresentation() {
  isRunning = true; abortFlag = false;
  simState = { totalMinted:0, totalBurned:0, cycleCount:0 };
  lastAuction = null; lastDelivery = null;
  showDashboard(); resetDashboard();

  for (var i = 0; i < STEPS.length; i++) {
    if (abortFlag) break;
    setProgress(i);
    try { await STEPS[i].fn(); } catch(e) { console.warn('Scene error', e); }
    if (abortFlag) break;
    await wait(300);
  }
  endPresentation(!abortFlag);
}

function endPresentation(completed) {
  isRunning = false; hideCursor(); stopAudio(); clearWordTimers();
  var btn = $('ag-ctrl-btn');
  if (btn) { btn.textContent = completed ? '↺ Replay' : '▶ Start Demo'; btn.classList.remove('stop'); }
  setText('ag-progress-label', completed ? 'Demo Complete' : 'Stopped');
  // Update sidebar status
  var dot = document.querySelector('.ag-status-dot');
  var lbl = document.querySelector('.ag-status-label');
  if (dot) { dot.className = 'ag-status-dot ' + (completed ? 'done' : ''); }
  if (lbl) lbl.textContent = completed ? 'DEMO COMPLETE ✅' : 'STOPPED';
  if (completed) {
    var bar = $('ag-progress-bar'); if (bar) bar.style.width = '100%';
    document.querySelectorAll('.tl-dot-v').forEach(function(el){ el.classList.remove('active'); el.classList.add('done'); });
  }
}

function stopPresentation() {
  abortFlag = true; isRunning = false;
  stopAudio(); hideCursor();
  var btn = $('ag-ctrl-btn');
  if (btn) { btn.textContent = '▶ Start Demo'; btn.classList.remove('stop'); }
}

function resetDashboard() {
  setText('ag-stat-impressions','0');
  setText('ag-stat-usdc','$0.0000');
  setText('ag-stat-latency','—');
  setText('ag-stat-sla','—');
  var board = $('ag-bid-board'); if (board) board.innerHTML = '';
  hide('ag-auction-result');
  var moqBar = $('ag-lat-moq'); if (moqBar) moqBar.style.width = '0%';
  var hlsBar = $('ag-lat-hls'); if (hlsBar) hlsBar.style.width = '0%';
  setText('ag-pod-signature','');
  setText('ag-oracle-check1','—'); setText('ag-oracle-check2','—'); setText('ag-oracle-check3','—');
  setText('ag-mint-amount','0.000');
  var bme = $('ag-bme-mint'); if (bme) bme.style.width = '50%';
  setPipeStep(-1);
}

// ── Init ──────────────────────────────────────────────────────
document.addEventListener('DOMContentLoaded', function() {
  initCursor();
  buildTimeline();
  if (window.speechSynthesis) {
    window.speechSynthesis.getVoices();
    window.speechSynthesis.addEventListener('voiceschanged', function() {
      window.speechSynthesis.getVoices();
    });
  }
  var btn = $('ag-ctrl-btn');
  if (btn) btn.addEventListener('click', function() {
    if (isRunning) { stopPresentation(); }
    else { btn.textContent = '⏹ Stop'; btn.classList.add('stop'); runPresentation(); }
  });
});

})();
