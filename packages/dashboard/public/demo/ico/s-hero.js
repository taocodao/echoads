// s-hero.js — Hero section
window.Sections = window.Sections || {};
window.Sections.hero = function() { return `
<p class="hero-tag">CMXS Foundation · ICO 2026 · Base L2</p>
<h2 class="hero-title">The First DePIN With<br><span class="accent">Pre-Built Infrastructure</span></h2>
<p class="hero-sub">5,800 EchoStar towers already in the ground. Zero cold-start problem. CMXS is the settlement and incentive layer turning existing broadcast infrastructure into a cryptographically verified delivery network — starting with the $40B connected TV advertising market.</p>
<div class="hero-stats">
  <div class="hero-stat glow-green">
    <div class="hero-stat-num">$100M</div>
    <div class="hero-stat-label">Initial FDV at TGE<br>Seed at $0.02 → Public at $0.10</div>
  </div>
  <div class="hero-stat">
    <div class="hero-stat-num">1B</div>
    <div class="hero-stat-label">Fixed token supply<br>No discretionary mint post-TGE</div>
  </div>
  <div class="hero-stat">
    <div class="hero-stat-num">$18–33M</div>
    <div class="hero-stat-label">Four-stage raise target<br>Angel → Seed → IEO → IDO</div>
  </div>
  <div class="hero-stat">
    <div class="hero-stat-num">&lt;500ms</div>
    <div class="hero-stat-label">Verified delivery SLA<br>312ms P95 · Paris Olympics validated</div>
  </div>
</div>
<div class="hero-ctas">
  <a href="#sec-ico" class="btn-ico primary">View ICO Stages ↓</a>
  <a href="https://sepolia.basescan.org/address/0x9fEf4679BB07aa1B28a4e33330e1e38ADcfb7819" target="_blank" class="btn-ico secondary">Smart Contracts ↗</a>
  <a href="/demo/presentation/" class="btn-ico secondary">Live Tech Demo ↗</a>
  <button id="narrate-btn-hero" class="btn-ico narrate" onclick="document.getElementById('narrate-btn').click()">&#9654; Narrated Tour</button>
</div>
<div style="margin-top:28px;font-size:11px;color:var(--muted);text-align:center">
  Phase 0 Complete · AWS Relay Live · Base Sepolia Deployed · Benchmark: 287ms P50, 312ms P95
</div>
`; };
document.addEventListener('DOMContentLoaded', function() {
  var el = document.getElementById('sec-hero');
  if (el) el.innerHTML = window.Sections.hero();
});
