// ═══════════════════════════════════════════
//  ArenzaTV iPhone Mockup — Demo State Machine
// ═══════════════════════════════════════════

const GAME_SCREENS = [
  { id:'epg',        label:'Channel Guide' },
  { id:'fullscreen', label:'Full-Screen Video' },
  { id:'split-score',label:'Split View — Score' },
  { id:'trivia',     label:'Team History Trivia' },
  { id:'prediction', label:'Outcome Prediction' },
  { id:'sponsor',    label:'Sponsor Quiz' },
  { id:'bingo',      label:'Live Bingo' },
  { id:'shop',       label:'Prize Shop' },
  { id:'wallet',     label:'QR Wallet' },
  { id:'profile',    label:'Profile Reveal' },
  { id:'dashboard',  label:'Sponsor Dashboard' },
];

const GAME_NARRATIONS = [
  "Launch ArenzaTV. The channel guide shows live and upcoming games. Tap the featured <strong>Eagles vs. Bears</strong> game to begin.",
  "The game plays <strong>full-screen</strong>. Notice the grabber handle pulsing at the bottom — drag up to reveal the companion panel.",
  "The <strong>split view</strong> reveals live score data. Score, clock, and play-by-play are all driven by the MatchSim backend in real-time.",
  "<strong>Eagles History Quiz</strong> fires — three questions about the team currently playing. Each correct answer earns AZT points. +75 AZT total.",
  "<strong>Prediction time</strong> — will the Eagles score on this drive? Correct! +150 AZT with a streak multiplier. Points accumulate in the unified wallet.",
  "<strong>Sponsor quiz</strong> — viewers learn about Pinecrest Pizza while earning points. Brand recall through gameplay, not passive pre-roll. +45 AZT + coupon.",
  "<strong>Bingo tiles</strong> auto-mark from live game events. A line completes — BINGO! 500 AZT bonus with confetti burst.",
  "The <strong>prize shop</strong> — spend accumulated AZT on real rewards. Redeem 250 AZT for a free side at Pinecrest Pizza.",
  "Your <strong>QR wallet</strong> holds all earned coupons. Each has a unique code, expiry timer, and Apple Wallet export. Every redemption is attributable.",
  "<strong>Profile reveal</strong> — AI classifies you as 'Sports Scholar, Engaged Local Superfan.' All profiling happens on-device. Only the segment ID leaves.",
  "<strong>Sponsor dashboard</strong>: 6 ads served, 87% engagement, 3 coupons generated, 1 POS redemption. Full attribution chain, cryptographically verified on Base L2."
];

let gameScreen = 0;
let aztBalance = 0;

function initGameMockup() {
  buildStepIndicator();
  renderGameScreen(0);
}

function buildStepIndicator() {
  const panel = document.getElementById('stepIndicator');
  if (!panel) return;
  panel.innerHTML = '';
  GAME_SCREENS.forEach((s, i) => {
    const row = document.createElement('div');
    row.className = 'step-dot-row' + (i === 0 ? ' active' : '');
    row.id = 'step-' + i;
    row.innerHTML = `<div class="step-dot"></div><span>${i+1}. ${s.label}</span>`;
    row.onclick = () => goGameScreen(i);
    panel.appendChild(row);
  });
}

function goGameScreen(n) {
  if (n < 0 || n >= GAME_SCREENS.length) return;
  // Hide current
  const cur = document.getElementById('gs-' + GAME_SCREENS[gameScreen].id);
  if (cur) { cur.classList.remove('active'); }
  
  gameScreen = n;
  
  // Show new
  const next = document.getElementById('gs-' + GAME_SCREENS[gameScreen].id);
  if (next) { next.classList.add('active'); }
  
  // Update step indicators
  document.querySelectorAll('.step-dot-row').forEach((r, i) => {
    r.className = 'step-dot-row' + (i === n ? ' active' : i < n ? ' done' : '');
  });
  
  // Update narration
  const narr = document.getElementById('gameNarration');
  if (narr) narr.innerHTML = GAME_NARRATIONS[n];
  
  // Update nav buttons
  const prevBtn = document.getElementById('gamePrevBtn');
  const nextBtn = document.getElementById('gameNextBtn');
  if (prevBtn) prevBtn.disabled = n === 0;
  if (nextBtn) {
    nextBtn.disabled = n === GAME_SCREENS.length - 1;
    nextBtn.textContent = n === GAME_SCREENS.length - 1 ? 'Demo Complete ✓' : 'Next Step →';
  }
  
  // Update AZT balance display based on screen
  updateAztForScreen(n);
}

function updateAztForScreen(n) {
  const balances = [0, 0, 0, 75, 225, 270, 770, 520, 520, 520, 520];
  aztBalance = balances[n] || 0;
  document.querySelectorAll('.azt-wallet-val').forEach(el => {
    el.textContent = aztBalance + ' AZT';
  });
}

function renderGameScreen(n) {
  goGameScreen(n);
}

// ── TRIVIA INTERACTION ──
function selectTriviaOption(btn, isCorrect) {
  const card = btn.closest('.quiz-card');
  const options = card.querySelectorAll('.quiz-option');
  if (btn.classList.contains('correct') || btn.classList.contains('wrong')) return;
  
  options.forEach(o => {
    if (o.dataset.correct === 'true') o.classList.add('correct');
    else if (o === btn && !isCorrect) o.classList.add('wrong');
  });
  
  if (isCorrect) {
    showAztFlyup(btn.closest('.ios-screen'), '+25 AZT');
  }
}

// ── PREDICTION INTERACTION ──
function selectPrediction(btn) {
  btn.classList.add('selected');
  const container = btn.closest('.predict-card');
  setTimeout(() => {
    const result = container.querySelector('.predict-result');
    if (result) {
      result.style.display = 'block';
      result.classList.add('win');
      result.textContent = '✅ CORRECT!';
    }
    const streak = container.querySelector('.streak-badge');
    if (streak) streak.style.display = 'inline-flex';
    showAztFlyup(btn.closest('.ios-screen'), '+150 AZT');
  }, 800);
}

// ── SHOP REDEEM ──
function redeemPrize(btn) {
  if (btn.classList.contains('redeemed')) return;
  btn.classList.remove('can-buy');
  btn.classList.add('redeemed');
  btn.textContent = '✓ Redeemed';
  aztBalance = 520;
  document.querySelectorAll('.azt-wallet-val').forEach(el => {
    el.textContent = '520 AZT';
  });
  showAztFlyup(btn.closest('.ios-screen'), '-250 AZT');
}

// ── AZT FLY-UP ──
function showAztFlyup(container, text) {
  const el = document.createElement('div');
  el.className = 'azt-flyup';
  el.textContent = text;
  container.appendChild(el);
  setTimeout(() => el.remove(), 1600);
}

// ── CONFETTI ──
function showConfetti(container) {
  const colors = ['#ffc107', '#ff6b35', '#00c9b1', '#6366f1', '#ef4444', '#8b5cf6'];
  const wrap = document.createElement('div');
  wrap.className = 'confetti-container';
  for (let i = 0; i < 40; i++) {
    const p = document.createElement('div');
    p.className = 'confetti-piece';
    p.style.left = Math.random() * 100 + '%';
    p.style.background = colors[Math.floor(Math.random() * colors.length)];
    p.style.animationDelay = Math.random() * 0.5 + 's';
    p.style.borderRadius = Math.random() > 0.5 ? '50%' : '2px';
    wrap.appendChild(p);
  }
  container.appendChild(wrap);
  setTimeout(() => wrap.remove(), 2500);
}

// ── BINGO AUTO-PLAY ──
function triggerBingo() {
  const cells = document.querySelectorAll('#bingo-grid .bingo-cell');
  const markOrder = [0, 6, 12, 18, 24]; // diagonal
  markOrder.forEach((idx, i) => {
    setTimeout(() => {
      if (cells[idx]) {
        cells[idx].classList.add('marked');
        if (i === markOrder.length - 1) {
          // BINGO!
          markOrder.forEach(mi => {
            if (cells[mi]) cells[mi].classList.add('bingo-line');
          });
          const screen = document.getElementById('gs-bingo');
          if (screen) {
            showConfetti(screen);
            showAztFlyup(screen, '+500 AZT');
          }
        }
      }
    }, i * 600);
  });
}

// Init on page load (deferred)
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', initGameMockup);
} else {
  initGameMockup();
}
