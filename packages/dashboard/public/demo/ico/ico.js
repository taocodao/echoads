// ico.js — Animations, interactions, counters, donut chart, narration v2

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
      ctx.fillStyle = 'rgba(6,182,212,0.4)';
      ctx.fill();
      for (var j = i + 1; j < particles.length; j++) {
        var q = particles[j];
        var dx = p.x - q.x, dy = p.y - q.y;
        var dist = Math.sqrt(dx * dx + dy * dy);
        if (dist < 140) {
          ctx.beginPath();
          ctx.moveTo(p.x, p.y);
          ctx.lineTo(q.x, q.y);
          ctx.strokeStyle = 'rgba(6,182,212,' + (0.15 * (1 - dist / 140)) + ')';
          ctx.lineWidth = 0.5;
          ctx.stroke();
        }
      }
    }
    requestAnimationFrame(draw);
  }
  draw();
})();

// ── Scroll-reveal sections and intersection triggers ────
(function initScrollReveal() {
  var sections = document.querySelectorAll('.ico-section');
  var observer = new IntersectionObserver(function (entries) {
    entries.forEach(function (e) {
      if (e.isIntersecting) {
        e.target.classList.add('visible');
        
        // Trigger counters
        e.target.querySelectorAll('.counter[data-target]').forEach(animateCounter);
        
        // Trigger proceeds bar
        if (e.target.querySelector('.proceeds-seg')) animateProceeds();
        
        // Trigger checkmarks
        e.target.querySelectorAll('.check-animate').forEach(function(el, i) {
          setTimeout(function() { el.classList.add('bounce'); }, i * 150);
        });

        // Trigger Gantt chart bars
        e.target.querySelectorAll('.gantt-bar').forEach(function(bar, i) {
          setTimeout(function() { bar.style.width = bar.dataset.targetWidth; }, 300 + (i * 100));
        });

        // Trigger Gantt milestones
        e.target.querySelectorAll('.gantt-milestone').forEach(function(ms, i) {
          setTimeout(function() { ms.classList.add('visible'); }, 800 + (i * 150));
        });
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
  document.querySelectorAll('.pb-segment').forEach(function (seg) {
    seg.style.width = seg.dataset.label ? seg.dataset.label.split(' ')[1] : '0%';
  });
}

// ── FAQ Accordion ───────────────────────────────────────
document.addEventListener('click', function(e) {
  if (e.target.matches('.faq-q')) {
    var item = e.target.closest('.faq-item');
    var isActive = item.classList.contains('active');
    // Close all
    document.querySelectorAll('.faq-item').forEach(function(i) { i.classList.remove('active'); });
    // Toggle clicked
    if (!isActive) {
      item.classList.add('active');
    }
  }
});

// ── PoD Flow Auto-Cycle ─────────────────────────────────
function initPodFlow() {
  var steps = document.querySelectorAll('.pod-step');
  if (steps.length === 0) return;
  var currentStep = 0;
  
  // Initial reveal based on scroll is handled by CSS mostly, but we can cycle active class
  setInterval(function() {
    steps.forEach(function(s) { s.classList.remove('active'); });
    steps[currentStep].classList.add('active');
    currentStep = (currentStep + 1) % steps.length;
  }, 2000);
}

// ── Legal Collapsible ───────────────────────────────────
var legalToggle = document.getElementById('legal-toggle-btn');
if (legalToggle) {
  legalToggle.addEventListener('click', function() {
    var collapse = this.closest('.legal-collapse');
    collapse.classList.toggle('open');
  });
}

// ── Donut chart (SVG) ───────────────────────────────────
function initDonut() {
  var svg = document.querySelector('.donut-svg');
  if (!svg) {
    var wrapper = document.getElementById('donut-chart-container');
    if (!wrapper) return;
    svg = document.createElementNS('http://www.w3.org/2000/svg', 'svg');
    svg.setAttribute('class', 'donut-svg');
    svg.setAttribute('viewBox', '0 0 220 220');
    wrapper.appendChild(svg);
  }

  var tooltip = document.getElementById('donut-tooltip');
  if (!tooltip) {
    tooltip = document.createElement('div');
    tooltip.id = 'donut-tooltip';
    tooltip.className = 'donut-tooltip';
    document.body.appendChild(tooltip);
  }

  var allocations = [
    { pct: 35, label: 'Node Rewards (PoD)', color: '#3B82F6', vest: 'Minted on-demand only when delivery verified. Daily cap: 2,880,000 CMXS', tokens: '350,000,000', tge: '0%' },
    { pct: 20, label: 'Foundation Treasury', color: '#8B5CF6', vest: '6-month cliff, 24-month linear', tokens: '200,000,000', tge: '0%' },
    { pct: 15, label: 'Ecosystem Grants', color: '#10B981', vest: '12-month cliff, 36-month linear', tokens: '150,000,000', tge: '0%' },
    { pct: 10, label: 'Seed / Strategic Round', color: '#F59E0B', vest: '12-month cliff, 36-month linear', tokens: '100,000,000', tge: '0%' },
    { pct: 10, label: 'Public ICO', color: '#EF4444', vest: '20% at TGE, 80% over 12 months linear', tokens: '100,000,000', tge: '20%' },
    { pct: 8,  label: 'Team & Advisors', color: '#6B7280', vest: '12-month cliff, 48-month linear', tokens: '80,000,000', tge: '0%' },
    { pct: 2,  label: 'Liquidity Provision', color: '#14B8A6', vest: 'Unlocked at TGE for DEX/CEX seeding', tokens: '20,000,000', tge: '100%' }
  ];

  var cx = 110, cy = 110, r = 85, gap = 1.5;
  var total = 100;
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
    circle.setAttribute('class', 'donut-segment');
    circle.style.transitionDelay = (i * 0.1) + 's';
    
    svg.appendChild(circle);

    // Animate in after a tick
    setTimeout(function () {
      circle.setAttribute('stroke-dasharray', dashLen + ' ' + dashGap);
    }, 100);

    // Tooltip
    circle.addEventListener('mouseenter', function (e) {
      tooltip.innerHTML = '<strong style="color:' + a.color + '">' + a.label + '</strong><br>' +
        '<span style="font-family:var(--mono);font-size:16px;font-weight:900">' + a.pct + '%</span> — ' + a.tokens + ' CMXS<br>' +
        '<span style="color:var(--muted);font-size:11px;">TGE Unlock: ' + a.tge + '</span><br>' +
        '<span style="color:var(--muted);font-size:11px;">' + a.vest + '</span>';
      tooltip.classList.add('show');
    });
    circle.addEventListener('mousemove', function (e) {
      tooltip.style.left = (e.pageX + 14) + 'px';
      tooltip.style.top = (e.pageY - 60) + 'px';
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
      item.className = 'dl-item';
      item.innerHTML = '<div class="dl-color" style="background:' + a.color + '"></div>' +
        '<div class="dl-pct">' + a.pct + '%</div>' +
        '<div class="dl-label">' + a.label + '</div>';
      legend.appendChild(item);
    });
  }
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
  n01: "CMXS is the first Decentralised Physical Infrastructure Network to launch with pre-existing physical infrastructure at scale. While Helium started from zero hotspots and took four years to reach one million, CMXS launches with five thousand eight hundred EchoStar broadcast towers already in the ground, already operating, already carrying the video streams that generate billions of dollars in advertising revenue. The CMXS token is the settlement and incentive layer that turns this infrastructure into a cryptographically verified delivery network, starting with the forty billion dollar connected TV advertising market. Initial fully diluted valuation: one hundred million dollars. Total raise target: eighteen to thirty-three million across four stages.",
  n02: "This section is for investors who are not crypto-native. When you buy digital advertising today, or any time-critical delivery service, you pay the platform, and the platform tells you it worked. There is no independent proof. The platform's own software reports whether your content was delivered. The result: eighty-four billion dollars in ad fraud annually, and thirty percent more inventory sold than actually delivered. A blockchain changes this. It is a public digital ledger that nobody controls. Once something is written on it, it cannot be erased, altered, or disputed, not by us, not by the buyer, not by anyone. Every time a CMXS network node delivers content, a cryptographic receipt is written to the Base blockchain permanently. We chose Base, built by Coinbase, because it costs just one hundredth of a cent per transaction, settles in two seconds, and supports x402, the new Coinbase standard for machine-to-machine micropayments.",
  n03: "Every blockchain needs a way to decide: did real work happen? Does the network deserve to be paid? Bitcoin uses Proof-of-Work, where computers compete to solve pointless mathematical puzzles. Ethereum uses Proof-of-Stake, where the richest token holders validate transactions. CMXS uses Proof-of-Delivery: nodes get paid for doing exactly what the network needs, delivering verified content to real devices, on time, fast. Here is what happens in under two seconds. A viewer's device requests content. The nearest CMXS node delivers it over QUIC in under five hundred milliseconds. The viewer's device automatically signs a cryptographic delivery receipt, a mathematical fingerprint that cannot be forged. The service buyer's wallet sends a micro-payment via x402. The Delivery Oracle smart contract verifies the receipt, confirms the payment, checks the speed, and if everything passes, it automatically mints zero point zero zero one CMXS to the node operator's wallet. No invoice. No approval. No delay. An immutable proof record is written to Base, auditable forever.",
  n04: "The raise is structured across four stages with a total target of eighteen to thirty-three million dollars. Stage Zero, the Angel round, is open now. One to two million dollars via SAFE instruments for five to ten strategic investors in broadcast and DePIN infrastructure. Stage One is the Seed round under SEC Regulation D at two cents per token, implying a twenty million dollar fully diluted valuation. Minimum ticket: two hundred fifty thousand dollars. Accredited investors only. Stage Two is the Strategic IEO round at five to eight cents per token via a Tier-1 exchange, targeting eight to fifteen million dollars. Stage Three is the Public IDO and Token Generation Event at ten cents per token via Fjord Foundry Liquidity Bootstrapping Pool plus Uniswap v4 on Base, targeting six to eleven million. Early participants in the Seed round at two cents benefit from a five-times price appreciation to the public listing price.",
  n05: "CMXS is a fixed-supply ERC-20 on Base L2 with a total supply of one billion tokens. There is no team mint capability. The only way new CMXS enters circulation is through the Proof-of-Delivery mechanism. The allocation is structured to align incentives. Thirty-five percent for node rewards, minted on demand as work is performed. Twenty percent for the Foundation Treasury. Fifteen percent for ecosystem grants. Ten percent for seed and strategic investors with a twelve-month cliff. Ten percent for the public ICO with twenty percent unlocked at TGE. Eight percent for team and advisors with a twelve-month cliff and forty-eight month linear vesting, the longest in the DePIN industry. And two percent for liquidity provision at TGE. Initial fully diluted valuation: one hundred million dollars. TGE circulating supply: one hundred fifty million tokens, or fifteen percent. Daily mint cap: two million eight hundred eighty thousand CMXS, hardcoded in the smart contract.",
  n06: "CMXS staking has three distinct tiers, each serving a different network function. Tier one is for node operators. Stake a minimum of one thousand CMXS, approximately one hundred dollars at initial FDV, to activate your node's Proof-of-Delivery eligibility. For every verified delivery under five hundred milliseconds, you automatically receive zero point zero zero one CMXS. At a one hundred dollar CMXS price, that is one dollar forty-four per node per day. Hardware payback on a three hundred twenty-nine dollar Raspberry Pi: approximately two hundred thirty days. Tier two is for service buyers. Pre-commit USDC for discounted burns and priority routing. Ten thousand dollars gets five percent burn discount. Two hundred fifty thousand gets twenty percent discount and guaranteed premium slots. Tier three is for governance. Lock CMXS for one to four years to receive vote-escrowed CMXS. Four-year lockers get full voting weight and full protocol fee share, paid in USDC. This is the Curve Finance model, proven at over five billion dollars in total value locked.",
  n07: "The vesting schedule is designed for maximum investor confidence. At TGE, only fifteen percent of tokens are circulating, primarily the two percent liquidity provision and twenty percent of the public ICO allocation. The Foundation Treasury begins vesting at month six. Team tokens have a full twelve-month cliff before a single token vests, then linear over forty-eight months, the longest lock-up in the DePIN industry. Seed and strategic investors vest over thirty-six months after a twelve-month cliff. Node rewards are not pre-allocated at all. They are minted on demand only when verified deliveries occur, with a daily cap hardcoded in the smart contract.",
  n08: "CMXS is designed to comply with 2026 US, EU, and international token offering frameworks from day one. The token is filed under the SEC's March 2026 Safe Harbor 2.0 framework as a utility token with a three-year non-registration window. US Angel and Seed rounds operate under Regulation D 506(c), verified accredited investors only. In the EU, CMXS qualifies as a MiCA Article 4 utility token, with the white paper filed before any public offering. All smart contracts undergo a mandatory Trail of Bits audit before TGE, the same firm that audited Ethereum 2.0. KYC is enforced via Jumio on all Angel and Seed participants, with OFAC wallet screening by Chainalysis. The corporate structure mirrors the proven dual-entity model used by Helium, Filecoin, and Render: a Cayman Foundation for token issuance and a Delaware corporation for technology development.",
  n09: "Every contract in the CMXS protocol suite is deployed on Base Sepolia and publicly auditable on Basescan right now. CMXS dot sol is the ERC-20 token with controlled mint, public burn, and daily cap logic. Delivery Oracle dot sol handles Proof-of-Delivery verification. Node Registry dot sol manages node registration, staking, and slashing. Service Buyer Escrow dot sol holds USDC and manages burn discount tiers. Governance Staking dot sol manages veCMXS lock-up and voting weight. Treasury dot sol handles Foundation treasury and ecosystem grant distribution. And Vesting Vault dot sol enforces cliff plus linear vesting for all allocations. Seven contracts. All open-source. All auditable before you invest a dollar.",
  n10: "The CMXS network is not a promise. The infrastructure is live. The smart contracts are deployed. The benchmark data is public: two hundred eighty-seven milliseconds median, three hundred twelve milliseconds at the ninety-fifth percentile. The initial commercial use case, verified CTV advertising delivery, addresses a forty billion dollar market with documented structural failures and documented willingness-to-pay for the exact solution this protocol provides. The Angel round is open now. The question for potential participants is straightforward: CMXS at two cents per token in the Seed round, or CMXS at ten cents at the public listing, or waiting until the first commercial campaigns are running and the market sets the price. Every DePIN project that launched with pre-existing infrastructure has outperformed. CMXS is the first to launch with five thousand eight hundred."
};

var NARRATION_SECTIONS = [
  'sec-hero',        // n01
  'sec-blockchain',  // n02
  'sec-pod',         // n03
  'sec-ico',         // n04
  'sec-tokenomics',  // n05
  'sec-staking',     // n06
  'sec-vesting',     // n07
  'sec-regulatory',  // n08
  'sec-legal',       // n09
  'sec-legal'        // n10
];

var narrationRunning = false;
var narrationAudio = null;
var narrationAbort = false;

function narrationWait(ms) { return new Promise(function (r) { setTimeout(r, ms); }); }

function playNarration(key) {
  var url = NARRATION_AUDIO[key];
  var text = NARRATION_TRANSCRIPTS[key] || '';
  var barText = document.getElementById('narration-bar-text');
  if (barText) barText.textContent = text;

  return new Promise(function (resolve) {
    if (!url) { resolve(); return; }
    narrationAudio = new Audio(url);
    narrationAudio.onended = function () { narrationAudio = null; resolve(); };
    narrationAudio.onerror = function () { narrationAudio = null; resolve(); };
    narrationAudio.play().catch(function () { resolve(); });
  });
}

function stopNarration() {
  narrationAbort = true;
  if (narrationAudio) { narrationAudio.pause(); narrationAudio = null; }
  narrationRunning = false;
  var bar = document.getElementById('narration-bar');
  if (bar) bar.classList.remove('show');
}

window.startTour = async function() {
  if (narrationRunning) { stopNarration(); return; }
  
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
}

// ── Init ────────────────────────────────────────────────
document.addEventListener('DOMContentLoaded', function () {
  // Init features
  initDonut();
  initPodFlow();

  // Force-show any sections already in viewport
  document.querySelectorAll('.ico-section').forEach(function(s) {
    var rect = s.getBoundingClientRect();
    if (rect.top < window.innerHeight && rect.bottom > 0) {
      s.classList.add('visible');
    }
  });
});
