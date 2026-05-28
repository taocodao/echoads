// sling.js — Animation controller, narration, timeline for Sling Pipeline Demo

// ── Vercel Blob Audio URLs ─────────────────────────────────
var SLING_AUDIO = {
  's01': '/demo/audio/sling-01.mp3',
  's02': '/demo/audio/sling-02.mp3',
  's03': '/demo/audio/sling-03.mp3',
  's04': '/demo/audio/sling-04.mp3',
  's05': '/demo/audio/sling-05.mp3',
  's06': '/demo/audio/sling-06.mp3',
  's07': '/demo/audio/sling-07.mp3',
  's08': '/demo/audio/sling-08.mp3'
};

var SLING_SCENES = [
  'sc-problem',    // s01
  'sc-pipeline',   // s02
  'sc-scte35',     // s03
  'sc-auction',    // s04
  'sc-delivery',   // s05
  'sc-proof',      // s06
  'sc-dashboard',  // s07
  'sc-scale'       // s08
];

var TIMELINE = [
  { num: 1, label: 'The Problem',           icon: '⚠' },
  { num: 2, label: 'The Pipeline',          icon: '🔄' },
  { num: 3, label: 'SCTE-35 Detection',     icon: '📡' },
  { num: 4, label: 'Real-Time Auction',     icon: '⚡' },
  { num: 5, label: 'MoQ Delivery',          icon: '🚀' },
  { num: 6, label: 'On-Chain Proof',        icon: '⛓' },
  { num: 7, label: 'Advertiser Dashboard',  icon: '📊' },
  { num: 8, label: 'Scale & Revenue',       icon: '💰' }
];

var TRANSCRIPTS = {
  s01: "Every time a Sling Freestream viewer sees an ad break, here is what actually happens today. The player requests an ad from an open exchange. The exchange reports the ad was delivered. But there is no independent proof. No cryptographic receipt. No verifiable timestamp. The platform's own software is the only witness. The result is eighty-four billion dollars in annual ad fraud globally. Thirty percent of CTV inventory is never seen by a real viewer. And every time the player switches from content to ad, the screen goes black for three to five seconds while HLS over TCP reconnects. EchoAds fixes all three problems with one protocol layer.",
  s02: "Here is the complete EchoAds pipeline. It runs as transparent middleware between the Sling Freestream origin and the viewer's device. Step one: the proxy detects an SCTE-35 ad break marker in the HLS manifest. Step two: it triggers an OpenRTB two point six real-time auction across registered demand partners, completing in under one hundred milliseconds. Step three: the winning advertiser's VAST four point x creative is fetched and validated. Step four: the ad segments are delivered over MoQ, Media over QUIC, in under five hundred milliseconds with zero black screen. Step five: the viewer's device signs a cryptographic delivery receipt. Step six: the receipt is written to the Base blockchain as an immutable proof of delivery. Step seven: the node operator automatically receives zero point zero zero one CMXS as a reward. Seven steps. Under two seconds. Every ad break.",
  s03: "This is what the CMXS proxy sees when an ad break is about to happen. The HLS manifest is a text file listing video segments. When Sling Freestream's ad server decides to insert a commercial break, it adds an SCTE-35 CUE-OUT tag to the manifest. The CMXS middleware proxy detects this tag within two hundred milliseconds. It extracts the break duration, typically thirty seconds, and immediately triggers a real-time auction. The viewer never knows the proxy is there. The stream continues uninterrupted. But now every ad that plays has a verifiable delivery chain.",
  s04: "The auction runs the OpenRTB two point six protocol, the same standard used by The Trade Desk, Magnite, and every major programmatic exchange. The proxy constructs a bid request with the break duration, content category, device type, and a fifteen dollar CPM floor. It fans out to all registered demand partners simultaneously with an eighty millisecond timeout. In this demonstration, three advertisers compete. DraftKings bids fifty-eight dollars and forty cents CPM. Nike bids forty-seven twenty. Pepsi bids forty-one thirty. DraftKings wins, but pays only forty-seven twenty-one, the second-highest bid plus one cent. This is a Vickrey auction, second-price, the industry standard. Total auction latency: eighty-seven milliseconds.",
  s05: "This is where EchoAds is fundamentally different from every other ad-tech platform. Instead of delivering the ad segments over HLS, which uses TCP and requires a full reconnection cycle, EchoAds delivers over MoQ, Media over QUIC. QUIC is a next-generation internet protocol developed by Google. It eliminates the TCP handshake entirely. The result: the ad appears on screen in two hundred eighty-seven milliseconds. No black screen. No buffering. No viewer frustration. The benchmark data is public. One hundred consecutive trials. Median: two hundred eighty-seven milliseconds. Ninety-fifth percentile: three hundred twelve. That is thirteen times faster than current Sling HLS at P95, and well under the five hundred millisecond threshold required for sports betting regulatory compliance.",
  s06: "The moment the ad finishes playing, the CMXS Delivery Oracle submits a transaction to the Base blockchain. This is what that transaction looks like on Basescan, the public block explorer. Every field is verifiable by anyone. The break ID, the advertiser, the CPM, the duration, the completion percentage. The ad delivered event is an immutable log entry. It cannot be altered, disputed, or deleted. Not by us. Not by the advertiser. Not by anyone. The gas cost is eight hundredths of a cent. This is the receipt that makes CMXS inventory fundamentally different from every other CTV platform. It is not EchoStar reporting its own numbers. It is cryptographic fact on a public ledger.",
  s07: "This is the advertiser's real-time view. Every impression appears the moment the on-chain transaction confirms. Each row shows the slot ID, the delivery latency, the USDC payment amount, and a direct link to the blockchain proof on Basescan. The advertiser does not need to trust EchoStar's reporting. They verify independently. The SLA pass rate is one hundred percent. Every delivery under five hundred milliseconds. Every payment confirmed. Every proof permanent. This is what verified CTV inventory looks like. And verified inventory commands two to three times higher CPMs than unverified, according to PubMatic's twenty twenty-five benchmark.",
  s08: "Let us put this together. EchoStar operates five thousand eight hundred broadcast and ground station sites. Today, these sites earn zero dollars from advertising. With EchoAds, each verified delivery earns zero point zero zero one CMXS for the node operator. At scale, that is approximately thirty million dollars per year in new tower revenue. But the bigger number is the CPM uplift. Sling Freestream's current unverified inventory averages eighteen to thirty dollars CPM. Verified inventory with on-chain proof commands forty-five to sixty-five dollars. Same impressions. Same viewers. Same content. Just proof. That is three hundred sixty million dollars per year in additional revenue from inventory EchoStar already owns. Plus, at three hundred twelve milliseconds P95, EchoStar becomes technically qualified to participate in the forty-five billion dollar US in-play sports betting market, where its current revenue is zero. Four problems. One protocol layer. Over one billion dollars in recoverable revenue."
};

window.SlingScenes = window.SlingScenes || {};

// ── State ──────────────────────────────────────────────────
var currentStep = -1;
var isRunning = false;
var abortFlag = false;
var narrationAudio = null;

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

function playNarration(stepKey) {
  var url = SLING_AUDIO[stepKey];
  var text = TRANSCRIPTS[stepKey] || '';
  var el = document.getElementById('narration-text');
  if (el) el.textContent = text;

  if (url) {
    return new Promise(function (resolve) {
      narrationAudio = new Audio(url);
      narrationAudio.onended = function () { narrationAudio = null; resolve(); };
      narrationAudio.onerror = function () {
        narrationAudio = null;
        speakBrowserTTS(text).then(resolve);
      };
      
      // Setup timeupdate hooks for specific scenes (like pipeline)
      narrationAudio.addEventListener('timeupdate', function() {
        if (typeof window.onSlingAudioTimeUpdate === 'function') {
          window.onSlingAudioTimeUpdate(narrationAudio.currentTime, stepKey);
        }
      });
      
      narrationAudio.play().catch(function () {
        speakBrowserTTS(text).then(resolve);
      });
    });
  } else {
    return speakBrowserTTS(text);
  }
}

function stopNarration() {
  if (narrationAudio) { narrationAudio.pause(); narrationAudio = null; }
  if (window.speechSynthesis) window.speechSynthesis.cancel();
}

// ── Sidebar helpers ────────────────────────────────────────
function setProgress(idx) {
  var total = TIMELINE.length;
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

// ── Scene management ───────────────────────────────────────
function showScene(idx) {
  var sl = document.getElementById('slide-area');
  if (sl) {
    var sceneId = SLING_SCENES[idx];
    if (window.SlingScenes[sceneId]) {
      sl.innerHTML = window.SlingScenes[sceneId]();
    } else {
      sl.innerHTML = '<div style="padding:40px;color:#fff;">Scene ' + sceneId + ' not found.</div>';
    }
  }
}

// ── Step orchestrator ───────────────────────────────────────
async function runStep(idx) {
  currentStep = idx;
  setProgress(idx);
  updateTimeline(idx);
  setSceneBadge('Scene ' + (idx + 1) + ' — ' + TIMELINE[idx].label);
  
  showScene(idx);
  
  // Custom scene logic triggers
  if (idx === 4) { // MoQ Delivery (sc-delivery)
    var urlEl = document.getElementById('browser-url-text');
    if (urlEl) urlEl.textContent = 'https://echoads.tv/delivery/compare';
    if (window.EchoApp) {
       setTimeout(() => EchoApp.triggerAdBreak(), 500);
    }
  } else if (idx === 6) { // Advertiser Dashboard (sc-dashboard)
    if (window.EchoApp) {
      setTimeout(() => EchoApp.addImpression(287), 1000);
      setTimeout(() => EchoApp.addImpression(295), 3000);
    }
  }
  
  var audioKey = 's0' + (idx + 1);
  await playNarration(audioKey);
  await wait(600);
}

// ── Main orchestrator ──────────────────────────────────────
async function startTour() {
  isRunning = true;
  abortFlag = false;
  if (window.EchoApp) EchoApp.resetAll();

  for (var i = 0; i < TIMELINE.length; i++) {
    if (abortFlag) break;
    try { await runStep(i); } catch (e) { console.warn('Step error', e); }
    if (abortFlag) break;
  }
  endTour(!abortFlag);
}

function endTour(completed) {
  isRunning = false;
  stopNarration();
  var btn = document.getElementById('pres-ctrl-btn');
  if (btn) { btn.textContent = completed ? '\u21ba Replay' : '\u25b6 Start Demo'; btn.classList.remove('stop'); }
  var label = document.getElementById('pres-step-label');
  if (label) label.textContent = completed ? 'Demo Complete' : 'Stopped';
  if (completed) {
    updateTimeline(TIMELINE.length);
    document.getElementById('pres-progress').style.width = '100%';
  }
}

function stopTour() {
  abortFlag = true;
  stopNarration();
  isRunning = false;
  var btn = document.getElementById('pres-ctrl-btn');
  if (btn) { btn.textContent = '\u25b6 Start Demo'; btn.classList.remove('stop'); }
}

// ── Timeline builder ───────────────────────────────────────
function buildTimeline() {
  var tl = document.getElementById('timeline-list');
  if (!tl) return;
  tl.innerHTML = '';
  TIMELINE.forEach(function (s, i) {
    var div = document.createElement('div');
    div.className = 'tl-step';
    div.id = 'tl-' + i;
    div.innerHTML = '<div class="tl-dot">' + s.icon + '</div><span>' + s.label + '</span>';
    tl.appendChild(div);
  });
}

// ── Init ───────────────────────────────────────────────────
document.addEventListener('DOMContentLoaded', function () {
  buildTimeline();

  if (window.speechSynthesis) {
    window.speechSynthesis.getVoices();
    window.speechSynthesis.addEventListener('voiceschanged', function () {
      window.speechSynthesis.getVoices();
    });
  }

  var ctrlBtn = document.getElementById('pres-ctrl-btn');
  if (ctrlBtn) {
    ctrlBtn.addEventListener('click', function () {
      if (isRunning) {
        stopTour();
      } else {
        ctrlBtn.textContent = '\u23f9 Stop';
        ctrlBtn.classList.add('stop');
        startTour();
      }
    });
  }
  
  // Show first scene as preview
  showScene(0);
});
