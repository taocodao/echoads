// s-roadmap.js — Development roadmap timeline
window.Sections = window.Sections || {};
window.Sections.roadmap = function() { return `
<p class="section-tag">Execution</p>
<h2 class="section-title">From Phase 0 to 10,000 Nodes</h2>
<p class="section-sub">Phase 0 is not a roadmap promise — it is already complete. The relay is live on AWS. Smart contracts are deployed and publicly verifiable. Click any phase for details.</p>
<div class="road-timeline">
  <div class="road-phase complete">
    <div class="road-dot"></div>
    <div class="road-phase-tag">✅ Phase 0 — Q2 2026 — COMPLETE</div>
    <div class="road-phase-title">Proof of Concept — Live Now</div>
    <div class="road-phase-desc">
      AWS-hosted MoQ relay with Caton CE-MoQ integration · x402 settlement on Base Sepolia (USDC testnet) · CMXS ERC-20 on Base Sepolia with PoD minting · Benchmark achieved: <strong style="color:var(--green)">287ms P50, 312ms P95</strong> delivery latency · Advertiser dashboard with real-time on-chain impression log · NodeRegistry + VestingVault deployed.
    </div>
  </div>
  <div class="road-phase">
    <div class="road-dot"></div>
    <div class="road-phase-tag">Phase 1 — Q3–Q4 2026</div>
    <div class="road-phase-title">Production Launch — 500 Nodes</div>
    <div class="road-phase-desc">
      500 physical nodes from EchoStar tower JV initial cohort · x402 live on Base mainnet (real USDC) · First commercial campaigns at $45 CPM verified floor · Chainlink CRE replacing trusted-signer oracle (full decentralisation) · veCMXS governance contract deployed.
    </div>
  </div>
  <div class="road-phase">
    <div class="road-dot"></div>
    <div class="road-phase-tag">Phase 2 — 2027</div>
    <div class="road-phase-title">Scale — 2,000 Nodes — $42M–$84M ARR</div>
    <div class="road-phase-desc">
      2,000 nodes (EchoStar + independent TowerCo partners) · Live sports betting B2B licensing pilot (3–5 licensed US operators) · Multi-use-case protocol expansion: PPV, live auction streams · First DAO governance proposal. Implied FDV: $420M–$840M at 10× revenue multiple.
    </div>
  </div>
  <div class="road-phase">
    <div class="road-dot"></div>
    <div class="road-phase-tag">Phase 3 — 2028</div>
    <div class="road-phase-title">Protocol Generalisation — 10,000 Nodes</div>
    <div class="road-phase-desc">
      10,000 nodes nationwide · AI agent per-delivery bidding (autonomous DSP via x402) · Full DAO governance transition (Foundation veto dissolved) · IoT telemetry and AI data feed delivery use cases live · $84M–$144M ARR target · Implied network value: <strong style="color:var(--green)">$840M–$1.44B</strong>.
    </div>
  </div>
</div>
<div style="margin-top:20px;padding:16px 20px;background:var(--surface);border:1px solid var(--border);border-radius:12px;font-size:12px;color:var(--muted)">
  <strong style="color:var(--text)">ICO Timeline:</strong> Angel close M2 → Seed opens M3 → IEO M6 → TGE/Public IDO M7 → Phase 1 nodes M8 → Governance launch M12
</div>
`; };
document.addEventListener('DOMContentLoaded', function() {
  var el = document.getElementById('sec-roadmap');
  if (el) el.innerHTML = window.Sections.roadmap();
});
