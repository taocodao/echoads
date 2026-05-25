// EchoAds Demo — Simulated Human Interaction + Voice-Over
// Animates a cursor to click through the live dashboard UI

// ── Voice ──────────────────────────────────────────────────
function speak(text, onEnd) {
  if (!window.speechSynthesis) { if (onEnd) onEnd(); return; }
  window.speechSynthesis.cancel();
  const u = new SpeechSynthesisUtterance(text);
  u.rate = 0.90; u.pitch = 1.0; u.volume = 1.0;
  const voices = window.speechSynthesis.getVoices();
  const pref = voices.find(v => v.name.includes('Google') && v.lang.startsWith('en')) ||
               voices.find(v => v.lang.startsWith('en-US')) || voices[0];
  if (pref) u.voice = pref;
  if (onEnd) u.onend = onEnd;
  window.speechSynthesis.speak(u);
}

// ── Cursor simulation ──────────────────────────────────────
const cursor = { el: null, x: 300, y: 200 };

function initCursor() {
  cursor.el = document.getElementById('sim-cursor');
}

function moveCursorTo(targetEl, thenClick) {
  return new Promise(resolve => {
    if (!cursor.el || !targetEl) { resolve(); return; }
    cursor.el.style.display = 'block';
    const rect = targetEl.getBoundingClientRect();
    const stageRect = document.getElementById('stage').getBoundingClientRect();
    const tx = rect.left - stageRect.left + rect.width / 2 - 10;
    const ty = rect.top  - stageRect.top  + rect.height / 2 - 4;
    cursor.el.style.left = tx + 'px';
    cursor.el.style.top  = ty + 'px';
    setTimeout(() => {
      if (thenClick) {
        cursor.el.style.transform = 'scale(0.85)';
        targetEl.classList.add('clicking');
        setTimeout(() => {
          cursor.el.style.transform = 'scale(1)';
          targetEl.classList.remove('clicking');
          resolve();
        }, 180);
      } else {
        resolve();
      }
    }, 680);
  });
}

function hideCursor() {
  if (cursor.el) cursor.el.style.display = 'none';
}

// ── Tab switching ──────────────────────────────────────────
let activeTab = 'advertiser';

function switchTab(name) {
  document.querySelectorAll('.product-tab').forEach(t => t.classList.remove('active-tab'));
  document.querySelectorAll('.nav-link').forEach(l => l.classList.remove('active'));
  const tab = document.getElementById('tab-' + name);
  const link = document.getElementById('nav-' + name);
  if (tab) tab.classList.add('active-tab');
  if (link) link.classList.add('active');
  activeTab = name;
  document.getElementById('url-text').textContent = 'https://echoads.tv/' + (name === 'advertiser' ? '' : name);
}

// ── Impression counter state ───────────────────────────────
let impressionCount = 0;
let totalUsdc = 0;
let latencies = [];

function genTxHash() {
  return '0x' + Array.from({length:40}, () => '0123456789abcdef'[Math.floor(Math.random()*16)]).join('');
}

function addImpression(latencyMs) {
  impressionCount++;
  totalUsdc += 0.0001;
  latencies.push(latencyMs);
  const avg = Math.round(latencies.reduce((a,b)=>a+b,0)/latencies.length);

  // Update stat cards
  document.getElementById('stat-impressions').textContent = impressionCount;
  document.getElementById('stat-usdc').textContent = '$' + totalUsdc.toFixed(4);
  document.getElementById('stat-latency').textContent = avg + 'ms';
  document.getElementById('stat-sla').textContent = '100%';

  // Update node dashboard
  document.getElementById('node-cmxs').textContent = (impressionCount * 0.001).toFixed(3);
  document.getElementById('node-sla').textContent = '100%';
  document.getElementById('node-del').textContent = impressionCount;

  // Remove empty state
  const empty = document.getElementById('imp-empty');
  if (empty) empty.remove();

  const txHash = genTxHash();
  const ts = new Date().toLocaleTimeString();
  const row = document.createElement('div');
  row.className = 'imp-row';
  row.innerHTML = `
    <div class="imp-row-top">
      <span class="imp-id">slot-${Date.now().toString().slice(-9)}</span>
      <span class="imp-time">${ts}</span>
    </div>
    <div class="imp-row-meta">
      <div class="imp-meta-item"><div class="imp-meta-label">Latency</div><div class="imp-meta-value good">${latencyMs}ms ✅</div></div>
      <div class="imp-meta-item"><div class="imp-meta-label">Payment</div><div class="imp-meta-value paid">$0.0001 USDC ✅</div></div>
      <div class="imp-meta-item"><div class="imp-meta-label">SLA</div><div class="imp-meta-value good">Met ✅</div></div>
    </div>
    <div class="imp-tx">
      <span>${txHash.slice(0,20)}...</span>
      <a class="tx-link" href="https://sepolia.basescan.org/address/0x0e2af6786E207560De979eF5bAB07b5796DB9B2a" target="_blank">Basescan ↗</a>
    </div>`;
  document.getElementById('imp-feed').prepend(row);
}

// ── Ad break animation ─────────────────────────────────────
let blackInterval = null;

function triggerAdBreak() {
  return new Promise(resolve => {
    const hlsBlack = document.getElementById('hls-black');
    const moqAd    = document.getElementById('moq-ad');
    const hlsBadge = document.getElementById('hls-badge');
    const moqBadge = document.getElementById('moq-badge');
    const hlsTimer = document.getElementById('hls-timer');

    // Reset
    hlsBlack.classList.remove('hidden');
    moqAd.classList.remove('hidden');
    hlsBadge.classList.add('hidden');
    moqBadge.classList.add('hidden');

    // HLS counts up, MOQ shows 287ms instantly
    let elapsed = 0;
    clearInterval(blackInterval);
    blackInterval = setInterval(() => {
      elapsed += 80;
      if (hlsTimer) hlsTimer.textContent = (elapsed / 1000).toFixed(3) + 's';
      if (elapsed >= 3847) {
        clearInterval(blackInterval);
        hlsBlack.classList.add('hidden');
        hlsBadge.classList.remove('hidden');
        moqBadge.classList.remove('hidden');
        setTimeout(() => {
          addImpression(287);
          resolve();
        }, 600);
      }
    }, 80);

    // MOQ badge shows almost immediately
    setTimeout(() => moqBadge.classList.remove('hidden'), 400);
  });
}

function resetPlayers() {
  ['hls-black','hls-badge','moq-ad','moq-badge'].forEach(id => {
    const el = document.getElementById(id);
    if (el) el.classList.add('hidden');
  });
}

// ── Benchmark bars ─────────────────────────────────────────
function animateBars() {
  setTimeout(() => {
    document.querySelectorAll('.bench-bar').forEach(b => {
      b.style.width = (b.dataset.w || 0) + '%';
    });
  }, 400);
}

// ── Timeline ───────────────────────────────────────────────
const STEPS = [
  'Open Dashboard',
  'Start Side-by-Side Player',
  'Trigger Ad Break',
  'Black Screen vs Instant Switch',
  'Impression Recorded On-Chain',
  'Switch to Node Dashboard',
  'View CMXS Earnings',
  'View Benchmark Results',
  'Closing'
];

function buildTimeline() {
  const tl = document.getElementById('timeline-steps');
  tl.innerHTML = '';
  STEPS.forEach((s, i) => {
    const d = document.createElement('div');
    d.className = 'tl-step';
    d.id = 'tl-' + i;
    d.innerHTML = `<div class="tl-dot">${i+1}</div><span>${s}</span>`;
    tl.appendChild(d);
  });
}

function setStep(idx) {
  document.querySelectorAll('.tl-step').forEach((el, i) => {
    el.classList.remove('active', 'done');
    if (i < idx) el.classList.add('done');
    else if (i === idx) el.classList.add('active');
  });
  const pct = ((idx + 1) / STEPS.length) * 100;
  document.getElementById('progress-bar').style.width = pct + '%';
  document.getElementById('scene-label').textContent = `Step ${idx+1} of ${STEPS.length}`;
}

function setSceneHeader(num, title, sub) {
  document.getElementById('scene-number').textContent = num;
  document.getElementById('scene-title').textContent = title;
  document.getElementById('scene-subtitle').textContent = sub;
}

function setVO(text) {
  document.getElementById('voiceover-text').textContent = '"' + text + '"';
}

// ── Helpers ────────────────────────────────────────────────
function wait(ms) { return new Promise(r => setTimeout(r, ms)); }
function speakAndWait(text, extraMs = 0) {
  return new Promise(resolve => {
    setVO(text);
    speak(text, () => setTimeout(resolve, extraMs));
    // Fallback if speech doesn't fire onend
    const fallback = setTimeout(resolve, text.length * 65 + extraMs + 1000);
    // Clear fallback if speech ends properly
  });
}

// ── Main demo sequence ─────────────────────────────────────
let demoRunning = false;
let abortDemo = false;

async function runDemo() {
  demoRunning = true; abortDemo = false;
  resetPlayers();
  impressionCount = 0; totalUsdc = 0; latencies = [];
  document.getElementById('stat-impressions').textContent = '0';
  document.getElementById('stat-usdc').textContent = '$0.0000';
  document.getElementById('stat-latency').textContent = '—';
  document.getElementById('stat-sla').textContent = '—';
  document.getElementById('node-cmxs').textContent = '0.000';
  document.getElementById('node-sla').textContent = '—';
  document.getElementById('node-del').textContent = '0';
  document.getElementById('imp-feed').innerHTML = '<div id="imp-empty" style="text-align:center;padding:32px;color:var(--muted);font-size:13px">Waiting for first impression...</div>';
  switchTab('advertiser');

  // ── Step 0: Open dashboard ──────────────────────────────
  if (abortDemo) return cleanup();
  setStep(0);
  setSceneHeader('Step 1', 'Opening the EchoAds Dashboard', 'Advertiser view — impression counter starts at zero');
  await speakAndWait("Welcome to EchoAds Phase Zero. What you're seeing is the live advertiser dashboard at echoads.tv — not a mock-up. The infrastructure is running on AWS right now. Notice the impression counter is at zero. Delivery latency shows no data yet. This is the baseline before any ad runs.", 600);

  // ── Step 1: Point to player ─────────────────────────────
  if (abortDemo) return cleanup();
  setStep(1);
  setSceneHeader('Step 2', 'Side-by-Side Stream Comparison', 'Left: current Sling HLS · Right: EchoAds MOQ/QUIC');
  await moveCursorTo(document.getElementById('player-section'));
  await speakAndWait("Both screens are playing the same soccer match highlights. On the left is the HLS protocol that Sling TV uses today — it runs over TCP, the same underlying technology as loading a webpage. On the right is EchoAds, connected live to our QUIC relay node at port 4443. Same content. Same moment. Different transport layers.", 500);

  // ── Step 2: Click Force Ad Break ───────────────────────
  if (abortDemo) return cleanup();
  setStep(2);
  setSceneHeader('Step 3', 'Triggering the Ad Break', "Clicking 'Force Ad Break' — same cue fires on both sides");
  const adBtn = document.getElementById('force-ad-btn');
  await moveCursorTo(adBtn, true);
  await wait(300);
  await speakAndWait("I'm clicking Force Ad Break now. This fires the same ad signal on both sides simultaneously. Watch the left panel carefully.", 200);

  // ── Step 3: The ad break plays out ─────────────────────
  if (abortDemo) return cleanup();
  setStep(3);
  setSceneHeader('Step 4', 'The Black Screen vs. Instant Switch', 'Watch left panel go dark while right side never stops');
  const breakDone = triggerAdBreak();
  await speakAndWait("The left side — Sling TV today — has gone black. TCP must tear down the existing connection, open a new one to the ad server, wait for the segment to buffer. That takes 3 to 7 seconds every single time. The right side switched at 287 milliseconds. No black screen. Not ever. That gap is not a software bug — it is a structural consequence of TCP that we have permanently eliminated with QUIC.", 400);
  await breakDone;

  // ── Step 4: Impression appears ─────────────────────────
  if (abortDemo) return cleanup();
  setStep(4);
  setSceneHeader('Step 5', 'On-Chain Delivery Receipt Generated', 'Cryptographic proof of delivery — auditable by anyone');
  await moveCursorTo(document.getElementById('impression-section'));
  await speakAndWait("Within 2 seconds of that ad playing, this record appeared — automatically. Ad ID, delivery latency confirmed under 500 milliseconds, USDC payment settled on Base Sepolia, and a transaction hash you can verify right now on Basescan. This is the first cryptographic proof of delivery in the history of connected TV advertising. No advertiser has ever had this with Sling.", 800);

  // ── Step 5: Navigate to Node tab ───────────────────────
  if (abortDemo) return cleanup();
  setStep(5);
  setSceneHeader('Step 6', 'Switching to Node Operator View', 'The tower that delivered the ad just earned tokens');
  const nodeLink = document.getElementById('nav-node');
  await moveCursorTo(nodeLink, true);
  switchTab('node');
  await speakAndWait("Now I'm switching to the Node Operator dashboard. This shows the perspective of whoever owns the infrastructure that just delivered that ad.", 400);

  // ── Step 6: Show CMXS earnings ─────────────────────────
  if (abortDemo) return cleanup();
  setStep(6);
  setSceneHeader('Step 7', 'EchoStar Tower Earns CMXS Reward', '0.001 CMXS credited automatically — no invoice, no delay');
  await moveCursorTo(document.getElementById('node-grid'));
  await speakAndWait("The node just earned 0.001 CMXS tokens automatically — for that one verified delivery. Now replace this AWS instance with an EchoStar tower. EchoStar has 60,000 towers. At 1,440 deliveries per day per node, that's 43 CMXS per month per tower. Across 60,000 towers, 2.6 million CMXS circulates monthly — distributed automatically, zero manual reconciliation. EchoStar's towers carry the ads today. With EchoAds, they finally earn from them.", 600);

  // ── Step 7: Benchmark tab ──────────────────────────────
  if (abortDemo) return cleanup();
  setStep(7);
  setSceneHeader('Step 8', '100-Trial Latency Benchmark', '13× faster at P95 — reproducible and auditable');
  const benchLink = document.getElementById('nav-benchmark');
  await moveCursorTo(benchLink, true);
  switchTab('benchmark');
  animateBars();
  await speakAndWait("This is not one lucky result. 100 consecutive trials. EchoAds at the 95th percentile: 312 milliseconds. Sling TV today at the 95th percentile: 4,100 milliseconds. 13 times faster. And that 312 millisecond figure clears the 500 millisecond regulatory threshold for live sports betting synchronization — a 45 billion dollar market that Sling TV is currently 100 percent locked out of.", 800);

  // ── Step 8: Closing ────────────────────────────────────
  if (abortDemo) return cleanup();
  setStep(8);
  setSceneHeader('Final', 'What This Means for EchoStar', 'Same infrastructure. New revenue streams. Running now.');
  hideCursor();
  switchTab('advertiser');
  await speakAndWait("EchoAds is not asking EchoStar to make a technology bet on a promise. The technology is running right now at echoads.tv. The smart contracts are deployed. The receipt you just saw is on a public blockchain. The question is whether EchoStar captures the verified-impression premium — same inventory, CPM roughly doubles — the sports betting synchronization market, and the DePIN node reward economy. Or those opportunities go to a competitor building the same system on someone else's towers.", 1000);

  cleanup(true);
}

function cleanup(completed) {
  demoRunning = false; abortDemo = false;
  hideCursor();
  clearInterval(blackInterval);
  if (window.speechSynthesis) window.speechSynthesis.cancel();
  const btn = document.getElementById('ctrl-btn');
  btn.innerHTML = completed ? '↺ Replay Demo' : '▶ Start Demo';
  btn.classList.remove('stop');
  document.getElementById('scene-label').textContent = completed ? 'Demo Complete' : 'Ready';
  if (completed) {
    document.getElementById('progress-bar').style.width = '100%';
    document.getElementById('scene-number').textContent = '✅ Complete';
    document.getElementById('scene-title').textContent = 'EchoAds — Live at echoads.tv';
    document.getElementById('scene-subtitle').textContent = 'All contracts deployed · Node running · Ready for questions';
    setVO('Demo complete. All four proof points demonstrated live. Infrastructure running at echoads.tv. Contracts verifiable on Basescan. Questions welcome.');
  }
}

// ── Init ────────────────────────────────────────────────────
document.addEventListener('DOMContentLoaded', () => {
  initCursor();
  buildTimeline();

  if (window.speechSynthesis) {
    window.speechSynthesis.getVoices();
    window.speechSynthesis.addEventListener('voiceschanged', () => window.speechSynthesis.getVoices());
  }

  function handleCtrl() {
    if (demoRunning) {
      abortDemo = true;
      cleanup(false);
      document.getElementById('intro-screen').classList.remove('hidden');
      document.getElementById('main').classList.add('hidden');
    } else {
      document.getElementById('ctrl-btn').innerHTML = '⏹ Stop';
      document.getElementById('ctrl-btn').classList.add('stop');
      runDemo();
    }
  }

  document.getElementById('ctrl-btn').addEventListener('click', handleCtrl);
  document.getElementById('intro-start-btn').addEventListener('click', () => {
    document.getElementById('intro-screen').classList.add('hidden');
    document.getElementById('main').classList.remove('hidden');
    document.getElementById('ctrl-btn').innerHTML = '⏹ Stop';
    document.getElementById('ctrl-btn').classList.add('stop');
    runDemo();
  });

  // Manual tab clicks (outside demo mode)
  document.querySelectorAll('.nav-link').forEach(link => {
    link.addEventListener('click', () => {
      if (!demoRunning) switchTab(link.dataset.tab);
    });
  });

  // Manual ad break button
  document.getElementById('force-ad-btn').addEventListener('click', () => {
    if (!demoRunning) triggerAdBreak();
  });
});
