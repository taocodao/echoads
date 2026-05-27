// ico.js — Animations, interactions, counters, donut chart, narration

// ── Particle Network Background ─────────────────────────
(function initParticles() {
  var c = document.getElementById('particle-canvas');
  if (!c) return;
  var ctx = c.getContext('2d');
  var particles = [];
  var PARTICLE_COUNT = 60;

  function resize() { c.width = window.innerWidth; c.height = window.innerHeight; }
  resize();
  window.addEventListener('resize', resize);

  for (var i = 0; i < PARTICLE_COUNT; i++) {
    particles.push({
      x: Math.random() * c.width,
      y: Math.random() * c.height,
      vx: (Math.random() - 0.5) * 0.4,
      vy: (Math.random() - 0.5) * 0.4,
      r: Math.random() * 2 + 0.5
    });
  }

  function draw() {
    ctx.clearRect(0, 0, c.width, c.height);
    for (var i = 0; i < particles.length; i++) {
      var p = particles[i];
      p.x += p.vx; p.y += p.vy;
      if (p.x < 0) p.x = c.width;
      if (p.x > c.width) p.x = 0;
      if (p.y < 0) p.y = c.height;
      if (p.y > c.height) p.y = 0;
      ctx.beginPath();
      ctx.arc(p.x, p.y, p.r, 0, Math.PI * 2);
      ctx.fillStyle = 'rgba(0,212,255,0.4)';
      ctx.fill();
      for (var j = i + 1; j < particles.length; j++) {
        var q = particles[j];
        var dx = p.x - q.x, dy = p.y - q.y;
        var dist = Math.sqrt(dx * dx + dy * dy);
        if (dist < 140) {
          ctx.beginPath();
          ctx.moveTo(p.x, p.y);
          ctx.lineTo(q.x, q.y);
          ctx.strokeStyle = 'rgba(0,212,255,' + (0.12 * (1 - dist / 140)) + ')';
          ctx.lineWidth = 0.5;
          ctx.stroke();
        }
      }
    }
    requestAnimationFrame(draw);
  }
  draw();
})();

// ── Scroll-reveal sections ──────────────────────────────
(function initScrollReveal() {
  var sections = document.querySelectorAll('.ico-section');
  var observer = new IntersectionObserver(function (entries) {
    entries.forEach(function (e) {
      if (e.isIntersecting) {
        e.target.classList.add('visible');
        // Trigger counters inside this section
        e.target.querySelectorAll('.counter[data-target]').forEach(animateCounter);
        // Trigger proceeds bar
        if (e.target.querySelector('.proceeds-seg')) animateProceeds();
      }
    });
  }, { threshold: 0.15 });
  sections.forEach(function (s) { observer.observe(s); });
})();

// ── Animated counters ───────────────────────────────────
function animateCounter(el) {
  if (el.dataset.animated) return;
  el.dataset.animated = '1';
  var target = el.dataset.target;
  var prefix = el.dataset.prefix || '';
  var suffix = el.dataset.suffix || '';
  var isDecimal = target.indexOf('.') !== -1;
  var end = parseFloat(target);
  var duration = 1800;
  var start = performance.now();

  function step(now) {
    var p = Math.min((now - start) / duration, 1);
    var ease = 1 - Math.pow(1 - p, 3);
    var val = ease * end;
    if (isDecimal) {
      el.textContent = prefix + val.toFixed(1) + suffix;
    } else if (end >= 1000000) {
      el.textContent = prefix + (val / 1000000).toFixed(1) + 'M' + suffix;
    } else if (end >= 1000) {
      el.textContent = prefix + (val / 1000).toFixed(0) + 'K' + suffix;
    } else {
      el.textContent = prefix + Math.round(val) + suffix;
    }
    if (p < 1) requestAnimationFrame(step);
    else el.textContent = prefix + target + suffix;
  }
  requestAnimationFrame(step);
}

// ── Proceeds bar animation ──────────────────────────────
function animateProceeds() {
  document.querySelectorAll('.proceeds-seg').forEach(function (seg) {
    seg.style.flex = seg.dataset.pct;
  });
}

// ── Architecture layer expand ───────────────────────────
document.querySelectorAll('.arch-layer').forEach(function (layer) {
  layer.addEventListener('click', function () {
    var wasExpanded = layer.classList.contains('expanded');
    document.querySelectorAll('.arch-layer').forEach(function (l) { l.classList.remove('expanded'); });
    if (!wasExpanded) layer.classList.add('expanded');
  });
});

// ── Donut chart (SVG) ───────────────────────────────────
function initDonut() {
  var svg = document.getElementById('donut-svg');
  if (!svg) return;
  var tooltip = document.getElementById('donut-tooltip');
  var allocations = [
    { pct: 35, label: 'Node Rewards (PoD)', color: '#00e87a', vest: 'Minted on-demand via Proof-of-Delivery; daily safety cap applies' },
    { pct: 20, label: 'Foundation Treasury', color: '#00aaff', vest: '6-month cliff; 24-month linear' },
    { pct: 15, label: 'Ecosystem Grants', color: '#00d4ff', vest: '12-month cliff; 36-month linear' },
    { pct: 10, label: 'Seed / Strategic', color: '#ffaa00', vest: '12-month cliff; 36-month linear' },
    { pct: 10, label: 'Public ICO', color: '#c084fc', vest: '20% at TGE; 80% over 12 months linear' },
    { pct: 8,  label: 'Team & Advisors', color: '#ff6080', vest: '12-month cliff; 48-month linear' },
    { pct: 2,  label: 'Liquidity Provision', color: '#e8edf5', vest: '100% unlocked at TGE for DEX/CEX seeding' }
  ];

  var cx = 110, cy = 110, r = 85, gap = 1.5;
  var total = allocations.reduce(function (s, a) { return s + a.pct; }, 0);
  var circumference = 2 * Math.PI * r;
  var offset = -90; // start from top

  allocations.forEach(function (a, i) {
    var pctAngle = (a.pct / total) * 360;
    var dashLen = (a.pct / total) * circumference - gap;
    var dashGap = circumference - dashLen;
    var rotation = offset;

    var circle = document.createElementNS('http://www.w3.org/2000/svg', 'circle');
    circle.setAttribute('cx', cx);
    circle.setAttribute('cy', cy);
    circle.setAttribute('r', r);
    circle.setAttribute('fill', 'none');
    circle.setAttribute('stroke', a.color);
    circle.setAttribute('stroke-width', '28');
    circle.setAttribute('stroke-dasharray', '0 ' + circumference);
    circle.setAttribute('stroke-dashoffset', '0');
    circle.setAttribute('transform', 'rotate(' + rotation + ' ' + cx + ' ' + cy + ')');
    circle.style.transition = 'stroke-dasharray 1.2s cubic-bezier(.4,.2,.2,1) ' + (i * 0.12) + 's';
    circle.style.cursor = 'pointer';
    circle.dataset.idx = i;
    svg.appendChild(circle);

    // Animate in after a tick
    setTimeout(function () {
      circle.setAttribute('stroke-dasharray', dashLen + ' ' + dashGap);
    }, 100);

    // Tooltip
    circle.addEventListener('mouseenter', function (e) {
      tooltip.innerHTML = '<strong style="color:' + a.color + '">' + a.label + '</strong><br>' +
        '<span style="font-family:var(--mono);font-size:16px;font-weight:900">' + a.pct + '%</span> — ' +
        (a.pct * 10).toLocaleString() + 'M CMXS<br>' +
        '<span style="color:var(--muted)">' + a.vest + '</span>';
      tooltip.classList.add('show');
    });
    circle.addEventListener('mousemove', function (e) {
      tooltip.style.left = (e.clientX + 14) + 'px';
      tooltip.style.top = (e.clientY - 60) + 'px';
    });
    circle.addEventListener('mouseleave', function () {
      tooltip.classList.remove('show');
    });

    offset += pctAngle;
  });

  // Legend
  var legend = document.getElementById('donut-legend');
  if (legend) {
    allocations.forEach(function (a) {
      var item = document.createElement('div');
      item.className = 'donut-legend-item';
      item.innerHTML = '<div class="donut-swatch" style="background:' + a.color + '"></div>' +
        '<span class="donut-legend-pct">' + a.pct + '%</span>' +
        '<span class="donut-legend-label">' + a.label + '</span>';
      legend.appendChild(item);
    });
  }
}

// ── BME Flywheel Animation ──────────────────────────────
function initBME() {
  var nodes = document.querySelectorAll('.bme-node');
  var arrows = document.querySelectorAll('.bme-arrow');
  if (nodes.length === 0) return;
  var idx = 0;
  setInterval(function () {
    nodes.forEach(function (n) { n.classList.remove('active'); });
    arrows.forEach(function (a) { a.classList.remove('active'); });
    nodes[idx].classList.add('active');
    if (arrows[idx]) arrows[idx].classList.add('active');
    idx = (idx + 1) % nodes.length;
  }, 1200);
}

// ── Narration Controller ────────────────────────────────
var NARRATION_AUDIO = {
  n01: '/demo/audio/n01.mp3',
  n02: '/demo/audio/n02.mp3',
  n03: '/demo/audio/n03.mp3',
  n04: '/demo/audio/n04.mp3',
  n05: '/demo/audio/n05.mp3',
  n06: '/demo/audio/n06.mp3',
  n07: '/demo/audio/n07.mp3',
  n08: '/demo/audio/n08.mp3',
  n09: '/demo/audio/n09.mp3',
  n10: '/demo/audio/n10.mp3'
};

var NARRATION_TRANSCRIPTS = {
  n01: "CMXS is the first Decentralised Physical Infrastructure Network to launch with pre-existing physical infrastructure. While Helium started from zero hotspots and took four years to reach one million, CMXS launches with 5,800 EchoStar broadcast towers already in the ground, already operating, already carrying the video streams that generate billions of dollars in advertising revenue. The CMXS token is the settlement and incentive layer that turns this infrastructure into a cryptographically verified delivery network — starting with the 40 billion dollar connected TV advertising market.",
  n02: "Three structural failures create an 84 billion dollar opportunity. First: latency. Legacy HLS over TCP creates mandatory 1.5 to 10 second black screens every time an ad is inserted — a protocol limitation, not a software bug. Second: proof. No current content delivery network provides cryptographic proof that content was actually delivered. Morgan Stanley estimates 30 percent of CTV ad inventory is never seen by a real viewer. Third: revenue distribution. The operators of physical infrastructure — tower owners, facility operators — receive flat lease income regardless of the advertising revenue flowing through their hardware. CMXS resolves all three simultaneously.",
  n03: "The CMXS network is a three-layer open-standard stack. At the bottom, Layer 1 is the physical node layer — 5,800 EchoStar broadcast towers plus independent tower partners and cloud developer nodes. Layer 2 is the CMXS protocol middleware — the Caton Enhanced MoQ relay for sub-500 millisecond delivery, the x402 micropayment gateway from Coinbase for per-delivery USDC settlement, and the SLA Oracle that writes cryptographic delivery proofs to the Base blockchain. Layer 3 is the application surface — any QUIC-capable device, which as of 2026 includes 98 percent of global browsers with zero plugins required. This stack was validated at the 2024 Paris Olympics: 16 simultaneous HD feeds, 17 consecutive days, zero delivery errors.",
  n04: "CMXS is a fixed-supply ERC-20 on Base L2 with a total supply of one billion tokens. There is no team mint capability — the only way new CMXS enters circulation is through the Proof-of-Delivery mechanism, where nodes earn tokens for verified deliveries. The allocation is structured to align incentives: 35 percent for node rewards, 20 percent for Foundation Treasury, 15 percent for ecosystem grants, 10 percent for seed and strategic investors, 10 percent for the public ICO, 8 percent for team and advisors with a 12-month cliff and 48-month linear vesting, and 2 percent for liquidity provision.",
  n05: "The Burn-and-Mint Equilibrium model — pioneered by Helium and confirmed as the DePIN tokenomics standard — makes CMXS self-regulating. On the burn side, service buyers pay USDC via x402, and a proportional amount of CMXS is burned — reducing circulating supply and creating upward price pressure. On the mint side, nodes earn CMXS for verified deliveries — increasing supply. These two forces naturally converge toward equilibrium. CMXS has four independent demand engines: Proof-of-Delivery rewards, x402 burn, SLA staking premium, and vote-escrowed governance locking.",
  n06: "The raise is structured across four stages with a total target of 18 to 33 million dollars. Stage 0 is the Angel round at one to two million. Stage 1 is the Seed round under SEC Regulation D at two cents per token — a 20 million dollar fully diluted valuation. Stage 2 is the Strategic IEO round at five to eight cents per token via a Tier-1 exchange. Stage 3 is the Public IDO at ten cents per token via Fjord Foundry Liquidity Bootstrapping Pool plus Uniswap v4 on Base. Early participants at two cents benefit from a five-times price appreciation to the public listing price.",
  n07: "Network growth projections show a clear value trajectory. Year 1: 50 to 500 active nodes, gross service revenue of 2.4 to 8 million dollars. Year 2: 2,000 nodes, 42 to 84 million in gross revenue. Year 3: 10,000 nodes, 84 to 144 million in revenue, implying a network value of 840 million to 1.44 billion dollars. Helium reached a peak fully diluted valuation of 5.1 billion from a 16 million dollar initial FDV — a 319 times multiple. Render reached 4.2 billion from 18 million — 233 times.",
  n08: "Phase 0 is already complete. The relay is live on AWS. Both smart contracts are deployed on Base Sepolia and publicly verifiable. The benchmark: 287 milliseconds median, 312 milliseconds at the 95th percentile. Phase 1 targets 500 physical nodes from the EchoStar joint venture, with the first commercial campaigns at a 45 dollar verified CPM floor. Phase 2 in 2027: 2,000 nodes and 42 to 84 million dollars in annual recurring revenue. Phase 3 in 2028: 10,000 nodes and an implied network value approaching 1.4 billion dollars.",
  n09: "Every contract in the CMXS protocol suite is deployed on Base Sepolia and publicly auditable on Basescan right now. CMXS dot sol is the ERC-20 token. DeliveryOracle dot sol handles Proof-of-Delivery verification. NodeRegistry dot sol manages node staking. VestingVault dot sol enforces cliff and linear vesting for all allocations. A mandatory Trail of Bits audit is planned before Token Generation Event.",
  n10: "The CMXS network is not a promise. The infrastructure is live. The smart contracts are deployed. The benchmark data is public. The initial commercial use case addresses a 40 billion dollar market with documented structural failures and documented willingness to pay for the exact solution this protocol provides. The question for potential participants is straightforward: CMXS at two cents per token in the Seed round, or CMXS at ten cents at the public listing — or waiting until the first commercial campaigns are running and the market sets the price. Every DePIN project that launched with pre-existing infrastructure has outperformed. CMXS is the first to launch with 5,800."
};

var NARRATION_SECTIONS = ['sec-hero','sec-problem','sec-arch','sec-tokenomics','sec-bme','sec-ico','sec-proj','sec-roadmap','sec-contracts','sec-contracts'];

var narrationRunning = false;
var narrationAudio = null;
var narrationAbort = false;

function narrationWait(ms) { return new Promise(function (r) { setTimeout(r, ms); }); }

function narrationSpeak(text) {
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

function playNarration(key) {
  var url = NARRATION_AUDIO[key];
  var text = NARRATION_TRANSCRIPTS[key] || '';
  var bar = document.getElementById('narration-bar');
  var barText = document.getElementById('narration-bar-text');
  if (barText) barText.textContent = text;

  if (url) {
    return new Promise(function (resolve) {
      narrationAudio = new Audio(url);
      narrationAudio.onended = function () { narrationAudio = null; resolve(); };
      narrationAudio.onerror = function () { narrationAudio = null; narrationSpeak(text).then(resolve); };
      narrationAudio.play().catch(function () { narrationSpeak(text).then(resolve); });
    });
  } else {
    return narrationSpeak(text);
  }
}

function stopNarration() {
  narrationAbort = true;
  if (narrationAudio) { narrationAudio.pause(); narrationAudio = null; }
  if (window.speechSynthesis) window.speechSynthesis.cancel();
  narrationRunning = false;
  var bar = document.getElementById('narration-bar');
  if (bar) bar.classList.remove('show');
  var btn = document.getElementById('narrate-btn');
  if (btn) { btn.textContent = '▶ Start Narrated Tour'; btn.classList.remove('stop'); }
}

async function runNarration() {
  narrationRunning = true;
  narrationAbort = false;
  var bar = document.getElementById('narration-bar');
  var barStep = document.getElementById('narration-bar-step');
  var barFill = document.getElementById('narration-bar-fill');
  if (bar) bar.classList.add('show');

  var keys = Object.keys(NARRATION_TRANSCRIPTS);
  for (var i = 0; i < keys.length; i++) {
    if (narrationAbort) break;
    var key = keys[i];
    if (barStep) barStep.textContent = 'Scene ' + (i + 1) + ' of ' + keys.length;
    if (barFill) barFill.style.width = Math.round(((i + 1) / keys.length) * 100) + '%';

    // Scroll to section
    var secId = NARRATION_SECTIONS[i];
    var secEl = document.getElementById(secId);
    if (secEl) secEl.scrollIntoView({ behavior: 'smooth', block: 'start' });
    await narrationWait(800);

    if (narrationAbort) break;
    await playNarration(key);
    await narrationWait(600);
  }

  stopNarration();
  var btn = document.getElementById('narrate-btn');
  if (btn) btn.textContent = '↺ Replay Tour';
}

// ── Init ────────────────────────────────────────────────
document.addEventListener('DOMContentLoaded', function () {
  // Narrate button
  var btn = document.getElementById('narrate-btn');
  if (btn) {
    btn.addEventListener('click', function () {
      if (narrationRunning) {
        stopNarration();
      } else {
        btn.textContent = '⏹ Stop Tour';
        btn.classList.add('stop');
        runNarration();
      }
    });
  }

  // Init donut chart and BME flywheel (called here because ico.js loads after section scripts)
  initDonut();
  initBME();

  // Force-show any sections already in viewport (IntersectionObserver fires async)
  document.querySelectorAll('.ico-section').forEach(function(s) {
    var rect = s.getBoundingClientRect();
    if (rect.top < window.innerHeight && rect.bottom > 0) {
      s.classList.add('visible');
    }
  });

  // TTS voices preload
  if (window.speechSynthesis) {
    window.speechSynthesis.getVoices();
    window.speechSynthesis.addEventListener('voiceschanged', function () {
      window.speechSynthesis.getVoices();
    });
  }
});
