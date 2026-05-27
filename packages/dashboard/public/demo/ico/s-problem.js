// s-problem.js — Problem section (3 flip cards)
window.Sections = window.Sections || {};
window.Sections.problem = function() { return `
<p class="section-tag">The Opportunity</p>
<h2 class="section-title">Three Structural Failures.<br>One Protocol Fix.</h2>
<p class="section-sub">The $84B+ opportunity exists because today's content delivery infrastructure has three compounding failures that cannot be patched at the software level — they require a new protocol stack. Hover each card to see the CMXS solution.</p>
<div class="problem-grid">
  <div class="flip-card">
    <div class="flip-inner">
      <div class="flip-front">
        <div class="flip-icon">⏱</div>
        <div class="flip-title" style="color:var(--red)">The Latency Problem</div>
        <div class="flip-stat" style="color:var(--red)">1.5–10s</div>
        <div class="flip-desc">Every ad insertion on HLS/TCP requires a full connection teardown and rebuild — a structural limitation of TCP, not a software bug. Affects every CTV platform including Sling TV, Peacock, and Pluto. On satellite broadband: 8–12 seconds every single ad break.</div>
        <div class="flip-hint">Hover for solution →</div>
      </div>
      <div class="flip-back">
        <div class="flip-icon">⚡</div>
        <div class="flip-title">CMXS: QUIC/MoQ Transport</div>
        <div class="flip-stat" style="color:var(--green)">287ms</div>
        <div class="flip-desc">QUIC multiplexed streams eliminate connection teardown entirely. Content and ad share one open connection. Switching is a new SUBSCRIBE message — not a reconnect. Validated at the 2024 Paris Olympics: 16 HD feeds, 17 days, zero errors.</div>
        <div style="margin-top:auto">
          <span class="arch-badge green">RFC 9000 QUIC</span>
          <span class="arch-badge green">MoQ IETF Draft-08</span>
        </div>
      </div>
    </div>
  </div>
  <div class="flip-card">
    <div class="flip-inner">
      <div class="flip-front">
        <div class="flip-icon">🚫</div>
        <div class="flip-title" style="color:var(--red)">The Proof Problem</div>
        <div class="flip-stat" style="color:var(--red)">$84B</div>
        <div class="flip-desc">Global ad fraud 2023–2025 (ANA). Morgan Stanley: 30% of CTV inventory never seen by a real viewer. DoubleVerify: 30–70% YoY growth in CTV fraud rates. The industry runs on an honour system — platforms report their own delivery numbers with zero independent audit trail.</div>
        <div class="flip-hint">Hover for solution →</div>
      </div>
      <div class="flip-back">
        <div class="flip-icon">🔗</div>
        <div class="flip-title">CMXS: On-Chain Delivery Proof</div>
        <div class="flip-stat" style="color:var(--green)">100%</div>
        <div class="flip-desc">Every delivery writes an immutable ERC-8004 SLA proof to Base L2 — timestamp, node ID, latency, USDC payment receipt. Any advertiser verifies on Basescan in real time. Not platform-reported metrics. Cryptographic fact. IAB Tech Lab CTV Signal Integrity Framework (Oct 2025) explicitly calls for this.</div>
        <div style="margin-top:auto">
          <span class="arch-badge blue">ERC-8004</span>
          <span class="arch-badge blue">Base L2</span>
        </div>
      </div>
    </div>
  </div>
  <div class="flip-card">
    <div class="flip-inner">
      <div class="flip-front">
        <div class="flip-icon">🏗</div>
        <div class="flip-title" style="color:var(--red)">The Revenue Gap</div>
        <div class="flip-stat" style="color:var(--red)">$0</div>
        <div class="flip-desc">Infrastructure operators — tower owners, facility operators, CDN edge node providers — receive flat lease income regardless of how much advertising revenue flows through their hardware. 5,800 EchoStar towers carry billions in ad delivery value and earn zero from it.</div>
        <div class="flip-hint">Hover for solution →</div>
      </div>
      <div class="flip-back">
        <div class="flip-icon">💎</div>
        <div class="flip-title">CMXS: Proof-of-Delivery Rewards</div>
        <div class="flip-stat" style="color:var(--green)">0.01 CMXS</div>
        <div class="flip-desc">Every verified delivery automatically mints 0.01 CMXS to the node that relayed it — no invoice, no human in the loop. At 1,440 deliveries/day, each site earns ~432 CMXS/month (~$432). Scaled to 5,800 sites: ~$2.5M/month, $30M/year — distributed algorithmically.</div>
        <div style="margin-top:auto">
          <span class="arch-badge green">DePIN PoD</span>
          <span class="arch-badge green">x402 USDC</span>
        </div>
      </div>
    </div>
  </div>
</div>
`; };
(function() {
  var el = document.getElementById('sec-problem');
  if (el) el.innerHTML = window.Sections.problem();
})();
