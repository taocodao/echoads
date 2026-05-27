// s-contracts.js — Smart contracts + legal disclaimer + footer
window.Sections = window.Sections || {};
window.Sections.contracts = function() { return `
<p class="section-tag">Trust Layer</p>
<h2 class="section-title">Smart Contracts — Publicly Verifiable Now</h2>
<p class="section-sub">Every contract in the CMXS protocol suite is deployed on Base Sepolia and auditable on Basescan. No trust required — verify on-chain.</p>
<div class="contract-grid">
  <div class="contract-card">
    <div class="contract-name">CMXS.sol</div>
    <div class="contract-purpose">ERC-20 token with controlled mint/burn, daily cap (2.88M/day), Burn-and-Mint Equilibrium tracking. No team mint capability post-TGE. Mint authority: DeliveryOracle.sol only.</div>
    <div class="contract-fns">
      <span class="contract-fn">rewardNode()</span>
      <span class="contract-fn">burn()</span>
      <span class="contract-fn">bmeNetInflation()</span>
    </div>
    <a href="https://sepolia.basescan.org/address/0x9fEf4679BB07aa1B28a4e33330e1e38ADcfb7819" target="_blank" class="contract-link">View on Basescan ↗</a>
  </div>
  <div class="contract-card">
    <div class="contract-name">DeliveryOracle.sol</div>
    <div class="contract-purpose">Phase 0: trusted-signer ECDSA oracle. Verifies delivery proofs, checks latency SLA (&lt;500ms), prevents replay attacks via nonce mapping. Migration path: updateTrustedSigner(chainlinkCREAddress).</div>
    <div class="contract-fns">
      <span class="contract-fn">submitDeliveryProof()</span>
      <span class="contract-fn">updateTrustedSigner()</span>
    </div>
    <a href="https://sepolia.basescan.org/address/0x0e2af6786E207560De979eF5bAB07b5796DB9B2a" target="_blank" class="contract-link">View on Basescan ↗</a>
  </div>
  <div class="contract-card">
    <div class="contract-name">NodeRegistry.sol</div>
    <div class="contract-purpose">Node registration, minimum stake management (1,000 CMXS), slash logic (10% on 3 failed proofs in 24h), 7-day unstake delay. Sybil protection for the PoD reward mechanism.</div>
    <div class="contract-fns">
      <span class="contract-fn">registerNode()</span>
      <span class="contract-fn">slash()</span>
      <span class="contract-fn">unstake()</span>
    </div>
    <a href="https://sepolia.basescan.org/address/0x9fEf4679BB07aa1B28a4e33330e1e38ADcfb7819" target="_blank" class="contract-link">View on Basescan ↗</a>
  </div>
  <div class="contract-card">
    <div class="contract-name">VestingVault.sol</div>
    <div class="contract-purpose">Cliff + linear vesting for team, investor, and ecosystem grant allocations. All team tokens: 12-month cliff, 48-month linear. All investor tokens: 12-month cliff, 36-month linear. On-chain enforced.</div>
    <div class="contract-fns">
      <span class="contract-fn">createSchedule()</span>
      <span class="contract-fn">claim()</span>
    </div>
    <a href="https://sepolia.basescan.org/address/0x0e2af6786E207560De979eF5bAB07b5796DB9B2a" target="_blank" class="contract-link">View on Basescan ↗</a>
  </div>
</div>
<div style="margin-top:20px;display:flex;gap:12px;flex-wrap:wrap">
  <a href="/demo/presentation/" class="btn-ico secondary">🎬 Live Tech Demo (EchoStar)</a>
  <a href="https://sepolia.basescan.org/address/0x9fEf4679BB07aa1B28a4e33330e1e38ADcfb7819" target="_blank" class="btn-ico secondary">🔗 CMXS on Basescan</a>
  <a href="/demo/" class="btn-ico secondary">← Demo Hub</a>
</div>
<div class="legal-box">
  <strong>Legal Disclaimer</strong><br>
  This page is published by CMXS Foundation Ltd. for informational purposes only. It does not constitute an offer or solicitation to sell securities or any regulated financial instrument. <strong>CMXS tokens are utility tokens</strong> designed for functional use within the CMXS DePIN network. <strong>United States:</strong> CMXS tokens are offered only to accredited investors in the Angel and Seed rounds under SEC Regulation D 506(c). Public IDO participation is not available to U.S. retail investors. <strong>No Guarantee of Value:</strong> Token purchasers may lose their entire investment. Forward-looking statements in this demo are estimates only. Actual results may differ materially. All participants must consult independent legal, financial, and tax counsel before participating.
</div>
<div class="ico-footer">
  <div style="margin-bottom:8px">
    <a href="https://sepolia.basescan.org/address/0x9fEf4679BB07aa1B28a4e33330e1e38ADcfb7819" target="_blank">CMXS Contract</a> ·
    <a href="https://sepolia.basescan.org/address/0x0e2af6786E207560De979eF5bAB07b5796DB9B2a" target="_blank">DeliveryOracle</a> ·
    <a href="/demo/">Demo Hub</a> ·
    <a href="/demo/presentation/">EchoStar Demo</a>
  </div>
  CMXS Foundation Ltd. · Grand Cayman · CMXS Labs Inc. · Delaware, USA<br>
  White Paper Version 2.0 · May 2026 · Base Sepolia Chain ID 84532
</div>
`; };
document.addEventListener('DOMContentLoaded', function() {
  var el = document.getElementById('sec-contracts');
  if (el) el.innerHTML = window.Sections.contracts();
});
