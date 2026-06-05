// ═══════════════════════════════════════════
//  ARENZA DEMO — App Logic
// ═══════════════════════════════════════════

const TOTAL_SLIDES = 8;
let currentSlide = 0;
let autoplayTimer = null;
let isPlaying = false;
let pipelineRunning = false;
let currentAudio = null;

const NARRATIONS = [
  "Welcome to Arenza. We deliver cryptographically verified ad impressions on live sports streams — moving local TV stations from a $10–25 unverified CPM tier to a $45–65 verified tier. Zero upfront cost. 85% revenue share. On-chain proof every 35 seconds.",
  "The problem is clear. Ad fraud costs $84 billion annually. Nielsen abandoned 137 US markets in 2026. Standard FAST channels earn $10–25 CPM because advertisers cannot verify delivery. Roku taxes stations 30%. Arenza eliminates all three pain points simultaneously.",
  "Our solution is five integrated layers: MoQ delivery over 5,800 EchoStar edge nodes, OpenRTB 2.6 real-time auction, blockchain Proof-of-Delivery on Base L2, SGAI interactive commerce overlay, and the CMXS token burn-mint equilibrium. No competitor provides all five under a single contract.",
  "Watch the live 35-second cycle. A SCTE-35 cue triggers an OpenRTB auction. Five DSPs bid simultaneously. The winner's creative is stitched into the stream. When the ad completes, the viewer's device signs an ECDSA receipt. DeliveryOracle dot sol mints an immutable record on Base L2. Click Run Demo Cycle to see it live.",
  "Unit economics for a single channel with 500,000 monthly viewers: 4 million impressions at $45 verified CPM generates $180,000 gross monthly revenue. The station partner keeps 85% — that's $153,000 per month, or $1.8 million annually — from a channel that requires zero additional staff and zero capital expenditure.",
  "The CMXS token is not speculative. Every dollar of ad spend triggers AdBurn dot sol to non-discretionarily burn tokens. Supply deflates. Price appreciates. Higher token value attracts more node operators. More nodes attract more broadcasters, increasing ad spend. The cycle is mechanical, verifiable on Basescan, and structurally mirrors Helium's proven DePIN model.",
  "Our go-to-market targets local TV stations — the highest-leverage first market. A 90-day cold start needs just 3 to 5 EchoStar tower nodes in the pilot DMA, a Roku FAST channel, and two local direct advertisers. Phase 1 goal: 100,000 real verified impressions and $50,000 in USDC ad revenue on mainnet.",
  "The ask is simple: a 90-day pilot. Zero technology cost to the station. You bring your content feed and local ad relationships. We bring the full stack. At 90 days, you receive a verified CPM report, auditable on-chain records, and a revenue check. If we don't beat your current FAST CPM, we part ways. We're confident we will."
];

const AUTOPLAY_DURATION = 18000; // ms per slide

// ── SLIDE NAVIGATION ──────────────────────
function goSlide(n) {
  if (n < 0 || n >= TOTAL_SLIDES) return;
  const prev = document.getElementById('slide-' + currentSlide);
  prev.classList.remove('active');
  prev.classList.add('exit-left');
  setTimeout(() => prev.classList.remove('exit-left'), 600);

  currentSlide = n;
  const next = document.getElementById('slide-' + currentSlide);
  next.classList.add('active');

  // pills
  document.querySelectorAll('.pill').forEach((p, i) => {
    p.classList.toggle('active', i === currentSlide);
  });

  // progress
  const pct = ((currentSlide) / (TOTAL_SLIDES - 1)) * 100;
  document.getElementById('progressFill').style.width = pct + '%';

  // narration
  document.getElementById('narrationText').textContent = NARRATIONS[currentSlide];

  playNarration(currentSlide);

  // slide-specific triggers
  if (currentSlide === 3 && isPlaying) setTimeout(() => runPipeline(), 1000);
  if (currentSlide === 4) triggerRevBar();
  if (currentSlide === 5) triggerBME();
}

function playNarration(index) {
  if (currentAudio) {
    currentAudio.pause();
    currentAudio.currentTime = 0;
  }
  const fileNum = String(index + 1).padStart(2, '0');
  currentAudio = new Audio(`audio/ar${fileNum}.mp3`);
  
  if (isPlaying) {
    currentAudio.play().catch(err => console.log('Audio autoplay blocked by browser', err));
    currentAudio.onended = () => {
      if (isPlaying) {
        // Pause briefly before advancing
        setTimeout(() => {
          const next = (currentSlide + 1) % TOTAL_SLIDES;
          goSlide(next);
        }, 1500);
      }
    };
  }
}

// ── PILL CLICKS ───────────────────────────
document.querySelectorAll('.pill[data-slide]').forEach(btn => {
  btn.addEventListener('click', () => goSlide(parseInt(btn.dataset.slide)));
});

// ── KEYBOARD ──────────────────────────────
document.addEventListener('keydown', e => {
  if (e.key === 'ArrowRight' || e.key === 'ArrowDown') goSlide(currentSlide + 1);
  if (e.key === 'ArrowLeft'  || e.key === 'ArrowUp')   goSlide(currentSlide - 1);
});

// ── AUTOPLAY ──────────────────────────────
function toggleAutoplay() {
  isPlaying = !isPlaying;
  document.getElementById('playBtn').textContent = isPlaying ? '⏸ Pause' : '▶ Auto-Play';
  if (isPlaying) {
    playNarration(currentSlide);
  } else {
    if (currentAudio) currentAudio.pause();
  }
}

// ── PIPELINE DEMO ─────────────────────────
const LOG_EVENTS = [
  { delay: 200,   node: 0, line: -1, msg: '📡 [T=0ms]    SRT ingest: live sports signal received' },
  { delay: 800,   node: 0, line: 0,  msg: '⚡ [T=50ms]   MoQ encoder: signal chunked into QUIC objects' },
  { delay: 1400,  node: 1, line: 1,  msg: '🏗️ [T=150ms]  EchoStar edge node: relay fan-out initiated' },
  { delay: 2000,  node: 2, line: 2,  msg: '📺 [T=287ms]  Viewer device: WebTransport stream open' },
  { delay: 2600,  node: 3, line: -1, msg: '✅ [T=287ms]  Glass-to-glass: <300ms latency confirmed' },
  { delay: 3200,  node: 4, line: 3,  msg: '🔔 [T=0ms]    SCTE-35 ad break cue detected in manifest' },
  { delay: 4000,  node: 4, line: 4,  msg: '🏦 [T=100ms]  SSP: OpenRTB 2.6 bid request assembled' },
  { delay: 4500,  dsp: true,          msg: '⚡ [T=200ms]  The Trade Desk, DV360, Amazon DSP bidding…' },
  { delay: 6000,  node: 5, line: 5,  msg: '🎬 [T=550ms]  Auction winner: $47.50 CPM — creative stitched' },
  { delay: 6800,  node: 6, line: -1, msg: '▶ [T=0s]     30-second ad playing to viewer…' },
  { delay: 9000,  node: 6, line: -1, msg: '📊 [T=25%]    Beacon event: 25% view-through confirmed' },
  { delay: 10500, node: 6, line: -1, msg: '📊 [T=50%]    Beacon event: 50% view-through confirmed' },
  { delay: 12000, node: 6, line: -1, msg: '📊 [T=75%]    Beacon event: 75% view-through confirmed' },
  { delay: 13500, node: 6, line: -1, msg: '📊 [T=100%]   Ad completed — viewer device signing ECDSA…' },
  { delay: 14500, node: 7, line: -1, msg: '🔗 [T=31s]    PoD Oracle: ECDSA signature verified on-chain' },
  { delay: 15500, node: 7, line: -1, msg: '✅ [T=35s]    DeliveryOracle.sol: receipt minted on Base L2' },
];

const DSP_DATA = [
  { name: 'Trade Desk', color: '#6366f1', maxPct: 85, bid: '$47.50', winner: true },
  { name: 'Google DV360', color: '#8b5cf6', maxPct: 72, bid: '$43.20', winner: false },
  { name: 'Amazon DSP', color: '#06b6d4', maxPct: 60, bid: '$39.80', winner: false },
  { name: 'Magnite', color: '#10b981', maxPct: 45, bid: '$35.10', winner: false },
  { name: 'PubMatic', color: '#f59e0b', maxPct: 38, bid: '$32.40', winner: false },
];

function buildDSPBars() {
  const container = document.getElementById('dspBars');
  container.innerHTML = '';
  DSP_DATA.forEach((d, i) => {
    const row = document.createElement('div');
    row.className = 'dsp-bar-row';
    row.innerHTML = `
      <div class="dsp-name">${d.name}</div>
      <div class="dsp-track">
        <div class="dsp-fill" id="dspFill${i}" style="background:${d.color}40;border-right:2px solid ${d.color}"></div>
      </div>
      <div class="dsp-bid" id="dspBid${i}">—</div>
    `;
    container.appendChild(row);
  });
}

function runPipeline() {
  if (pipelineRunning) return;
  pipelineRunning = true;
  document.getElementById('runPipeline').disabled = true;
  document.getElementById('runPipeline').textContent = '⏳ Running…';
  document.getElementById('podReceipt').classList.add('hidden');

  // Reset nodes
  document.querySelectorAll('.pnode').forEach(n => n.classList.remove('active','done'));
  document.querySelectorAll('.pline').forEach(l => l.classList.remove('flowing'));
  buildDSPBars();

  const log = document.getElementById('tickerLog');
  log.innerHTML = '';

  LOG_EVENTS.forEach(ev => {
    setTimeout(() => {
      // Log line
      const line = document.createElement('div');
      line.textContent = ev.msg;
      log.appendChild(line);
      log.scrollTop = log.scrollHeight;

      // Update status
      document.getElementById('tickerStatus').textContent = '● ' + ev.msg.replace(/^\S+\s+/,'');

      // Activate node
      if (ev.node !== undefined) {
        // mark previous done
        for (let i = 0; i < ev.node; i++) {
          const prev = document.getElementById('pn' + i);
          if (prev) { prev.classList.remove('active'); prev.classList.add('done'); }
        }
        const nd = document.getElementById('pn' + ev.node);
        if (nd) { nd.classList.add('active'); nd.classList.remove('done'); }
        if (ev.line >= 0) {
          const ln = document.getElementById('pl' + ev.line);
          if (ln) { ln.classList.add('flowing'); }
        }
      }

      // DSP animation
      if (ev.dsp) {
        DSP_DATA.forEach((d, i) => {
          setTimeout(() => {
            document.getElementById('dspFill' + i).style.width = d.maxPct + '%';
            document.getElementById('dspBid' + i).textContent = d.bid;
            document.getElementById('dspBid' + i).style.color = d.winner ? '#10b981' : '#94a3b8';
          }, i * 200);
        });
      }
    }, ev.delay);
  });

  // Finish: show receipt
  const finishDelay = LOG_EVENTS[LOG_EVENTS.length - 1].delay + 600;
  setTimeout(() => {
    // Mark all done
    document.querySelectorAll('.pnode').forEach(n => { n.classList.remove('active'); n.classList.add('done'); });

    const impId = '0x' + Math.random().toString(16).slice(2,10).toUpperCase();
    const txHash = '0x' + Array.from({length:16}, () => Math.floor(Math.random()*16).toString(16)).join('');
    document.getElementById('impId').textContent = impId;
    document.getElementById('cpmVal').textContent = '$47.50 CPM';
    document.getElementById('txHash').textContent = txHash.slice(0,18) + '…';
    document.getElementById('podReceipt').classList.remove('hidden');
    document.getElementById('tickerStatus').textContent = '✅ CYCLE COMPLETE — On-chain receipt minted on Base L2';

    pipelineRunning = false;
    document.getElementById('runPipeline').disabled = false;
    document.getElementById('runPipeline').textContent = '▶ Run Again';
  }, finishDelay);
}

// ── SLIDE 4 REV BAR ───────────────────────
function triggerRevBar() {
  setTimeout(() => {
    document.getElementById('revBarFill').style.width = '0.08%';
    // Animate to visible width to show 0.08% of market
    setTimeout(() => {
      document.getElementById('revBarFill').style.transition = 'width 0s';
      document.getElementById('revBarFill').style.width = '8px';
      document.getElementById('revBarFill').style.minWidth = '8px';
    }, 100);
  }, 400);
}

// ── SLIDE 5 BME ANIMATION ─────────────────
function triggerBME() {
  const nodes = document.querySelectorAll('.bme-node');
  nodes.forEach((n, i) => {
    n.style.opacity = '0.3';
    setTimeout(() => {
      n.style.transition = 'opacity .4s';
      n.style.opacity = '1';
    }, i * 400);
  });
}

// ── INIT ──────────────────────────────────
buildDSPBars();
document.getElementById('narrationText').textContent = NARRATIONS[0];

// Start pipeline demo ready
document.getElementById('tickerStatus').textContent = '● READY — Click "Run Demo Cycle" to start';
