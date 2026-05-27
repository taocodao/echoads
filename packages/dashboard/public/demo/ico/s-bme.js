// s-bme.js — Burn-and-Mint Equilibrium flywheel
window.Sections = window.Sections || {};
window.Sections.bme = function() { return `
<p class="section-tag">Tokenomics</p>
<h2 class="section-title">Burn-and-Mint Equilibrium</h2>
<p class="section-sub">Pioneered by Helium, confirmed as the DePIN tokenomics standard by Frontiers in Blockchain peer-reviewed research (2025). CMXS has four independent demand engines — any single one is sufficient for sustainable utility. Together they create compounding demand pressure.</p>
<div class="bme-flywheel" id="bme-flywheel">
  <div class="bme-node burn" id="bme-0">
    <div class="bme-node-icon">🔥</div>
    <div class="bme-node-label">Burn</div>
    <div class="bme-node-desc">Service buyers burn CMXS<br>for verified delivery priority</div>
  </div>
  <div class="bme-arrow" id="bme-arr-0">→</div>
  <div class="bme-node supply" id="bme-1">
    <div class="bme-node-icon">📉</div>
    <div class="bme-node-label">Supply ↓</div>
    <div class="bme-node-desc">Circulating supply<br>decreases</div>
  </div>
  <div class="bme-arrow" id="bme-arr-1">→</div>
  <div class="bme-node price" id="bme-2">
    <div class="bme-node-icon">📈</div>
    <div class="bme-node-label">Price ↑</div>
    <div class="bme-node-desc">Upward price pressure<br>(all else equal)</div>
  </div>
  <div class="bme-arrow" id="bme-arr-2">→</div>
  <div class="bme-node mint" id="bme-3">
    <div class="bme-node-icon">⚙️</div>
    <div class="bme-node-label">More Nodes</div>
    <div class="bme-node-desc">Higher CMXS value attracts<br>more node operators</div>
  </div>
  <div class="bme-arrow" id="bme-arr-3">→</div>
  <div class="bme-node mint" id="bme-4" style="border-color:rgba(0,232,122,.25)">
    <div class="bme-node-icon">✅</div>
    <div class="bme-node-label">Mint</div>
    <div class="bme-node-desc">More deliveries<br>mint more CMXS</div>
  </div>
</div>
<div style="display:grid;grid-template-columns:repeat(4,1fr);gap:12px;margin-top:24px">
  <div style="background:var(--surface);border:1px solid var(--border);border-radius:12px;padding:16px;text-align:center">
    <div style="font-size:13px;font-weight:800;color:var(--red);margin-bottom:6px">x402 Burn</div>
    <div style="font-size:11px;color:var(--muted);line-height:1.6">Service buyers burn CMXS to access verified delivery priority slots. More demand = more burn = supply contraction.</div>
  </div>
  <div style="background:var(--surface);border:1px solid var(--border);border-radius:12px;padding:16px;text-align:center">
    <div style="font-size:13px;font-weight:800;color:var(--green);margin-bottom:6px">PoD Rewards</div>
    <div style="font-size:11px;color:var(--muted);line-height:1.6">0.01 CMXS minted per verified delivery. Rewards nodes for exactly the work the network needs — not energy or capital.</div>
  </div>
  <div style="background:var(--surface);border:1px solid var(--border);border-radius:12px;padding:16px;text-align:center">
    <div style="font-size:13px;font-weight:800;color:var(--blue);margin-bottom:6px">SLA Staking</div>
    <div style="font-size:11px;color:var(--muted);line-height:1.6">Nodes stake CMXS for priority routing. Service buyers stake USDC for volume discounts (5–20% burn discount). Both reduce liquid supply.</div>
  </div>
  <div style="background:var(--surface);border:1px solid var(--border);border-radius:12px;padding:16px;text-align:center">
    <div style="font-size:13px;font-weight:800;color:var(--cyan);margin-bottom:6px">veToken Lock</div>
    <div style="font-size:11px;color:var(--muted);line-height:1.6">veCMXS (1–4 year lock) for governance + 50% protocol fee share. Long-term holders lock supply. Curve Finance model proven at $5B+ TVL.</div>
  </div>
</div>
`; };
(function() {
  var el = document.getElementById('sec-bme');
  if (el) {
    el.innerHTML = window.Sections.bme();
    if (typeof initBME === 'function') initBME();
  }
})();
