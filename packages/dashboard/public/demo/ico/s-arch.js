// s-arch.js — Architecture section (3 expandable layers)
window.Sections = window.Sections || {};
window.Sections.arch = function() { return `
<p class="section-tag">How It Works</p>
<h2 class="section-title">Three-Layer Open-Standard Stack</h2>
<p class="section-sub">Every layer uses open standards — no proprietary lock-in except the Caton C3 transport enhancement. Click any layer to expand details. The same stack supports advertising, live sports betting, pay-per-view, and AI agent delivery with zero protocol modification.</p>
<div class="arch-stack">
  <div class="arch-layer" onclick="this.classList.toggle('expanded')">
    <div class="arch-layer-header">
      <div class="arch-layer-num">3</div>
      <div>
        <div class="arch-layer-title">Application / Client Surface</div>
        <div class="arch-layer-sub">Chrome · Edge · Safari · Smart TV · Mobile App · AI Agent</div>
      </div>
      <div style="margin-left:auto;font-size:11px;color:var(--muted)">Click to expand</div>
    </div>
    <div class="arch-expand">
      <div class="arch-expand-inner">
        Any QUIC-capable device connects to the CMXS network with zero plugins required. MoQ/WebTransport is Baseline Widely Available as of 2026 — supported in Chrome 97+, Firefox 114+, Edge 97+, Safari 18+, covering 98%+ of global browsers. AI agents connect autonomously via x402-fetch with Coinbase Smart Wallet (EIP-4337) — no human approval required per transaction.
        <div>
          <span class="arch-badge cyan">WebTransport</span>
          <span class="arch-badge cyan">EIP-4337 Smart Wallet</span>
          <span class="arch-badge cyan">x402-fetch SDK</span>
          <span class="arch-badge cyan">moq-js player</span>
        </div>
      </div>
    </div>
  </div>
  <div class="arch-layer" onclick="this.classList.toggle('expanded')">
    <div class="arch-layer-header">
      <div class="arch-layer-num">2</div>
      <div>
        <div class="arch-layer-title">CMXS Protocol Middleware</div>
        <div class="arch-layer-sub">CE-MoQ Relay · x402 Gateway · SLA Oracle · CMXS Contracts</div>
      </div>
      <div style="margin-left:auto;font-size:11px;color:var(--muted)">Click to expand</div>
    </div>
    <div class="arch-expand">
      <div class="arch-expand-inner">
        <strong style="color:var(--text)">Caton Enhanced MoQ (CE-MoQ) Relay:</strong> Multi-path AI routing with sub-500ms delivery even under 30% packet loss. Forward error correction (FEC) for satellite backhaul.<br><br>
        <strong style="color:var(--text)">x402 Payment Gateway:</strong> HTTP-native micropayment (Coinbase, May 2025). $0.0001 USDC per delivery, settles on Base L2 in &lt;2 seconds. Per-delivery auction decisioning in ≤80ms.<br><br>
        <strong style="color:var(--text)">SLA Oracle:</strong> Phase 0: trusted-signer ECDSA. Phase 1+: Chainlink CRE. Writes ERC-8004 SLA proofs on-chain for every verified delivery.
        <div>
          <span class="arch-badge blue">Caton C3/CVP</span>
          <span class="arch-badge blue">x402 v1.0</span>
          <span class="arch-badge blue">Chainlink CRE</span>
          <span class="arch-badge blue">NetScope Telemetry</span>
        </div>
      </div>
    </div>
  </div>
  <div class="arch-layer" onclick="this.classList.toggle('expanded')">
    <div class="arch-layer-header">
      <div class="arch-layer-num">1</div>
      <div>
        <div class="arch-layer-title">Physical Node Layer</div>
        <div class="arch-layer-sub">5,800 EchoStar towers (JV anchor) · TowerCo partners · Cloud VM nodes</div>
      </div>
      <div style="margin-left:auto;font-size:11px;color:var(--muted)">Click to expand</div>
    </div>
    <div class="arch-expand">
      <div class="arch-expand-inner">
        The structural advantage no other DePIN project has had at launch. 5,800 EchoStar broadcast and ground station sites are already deployed, already operating, already carrying the video streams that generate advertising revenue. Each node runs the CE-MoQ relay daemon, x402 Facilitator, and CMXS NodeRegistry staking contract interaction. Independent node operators can join at any time with a Raspberry Pi 5 (~$329 hardware cost) and 1,000 CMXS minimum stake.
        <div>
          <span class="arch-badge green">5,800 EchoStar Sites</span>
          <span class="arch-badge green">CE-MoQ Daemon</span>
          <span class="arch-badge green">NodeRegistry.sol</span>
          <span class="arch-badge green">1,000 CMXS Stake</span>
        </div>
      </div>
    </div>
  </div>
</div>
<div style="margin-top:20px;padding:16px 20px;background:var(--surface);border:1px solid var(--border);border-radius:12px;font-size:12px;color:var(--muted);display:flex;gap:28px;flex-wrap:wrap">
  <span>🏅 <strong style="color:var(--text)">Paris Olympics 2024</strong> — 16 HD feeds · 17 days · Zero errors</span>
  <span>⚡ <strong style="color:var(--text)">$0.0001</strong> gas cost per tx on Base L2</span>
  <span>🌐 <strong style="color:var(--text)">98%+</strong> browser coverage, zero plugins</span>
  <span>🔗 <strong style="color:var(--text)">EIP-4337</strong> — AI agents transact autonomously</span>
</div>
`; };
(function() {
  var el = document.getElementById('sec-arch');
  if (el) el.innerHTML = window.Sections.arch();
})();
