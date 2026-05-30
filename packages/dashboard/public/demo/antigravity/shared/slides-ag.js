// slides-ag.js — Business-value slides for scenes ag10-ag18

window.SlidesAG = {

  ag10: function () {
    return '<div class="ag-slide">' +
      '<div class="ag-slide-header">' +
        '<span class="ag-scene-badge">Problem 1</span>' +
        '<h2 class="ag-slide-title">$84B Ad Fraud — And No Platform Can Prove Delivery</h2>' +
      '</div>' +
      '<div class="ag-slide-cols">' +
        '<div class="ag-slide-col">' +
          '<div class="ag-card" style="border-color:rgba(255,59,92,0.3)">' +
            '<div class="ag-stat-desc" style="margin-bottom:10px;color:var(--red);font-weight:700;text-transform:uppercase;font-size:10px;letter-spacing:1px">The Financial Exposure</div>' +
            '<div class="grid-2" style="margin-bottom:12px">' +
              '<div class="ag-kpi-card"><div class="ag-kpi-val" style="color:var(--red)">$84B</div><div class="ag-kpi-label">Global ad fraud 2023–25 (ANA)</div></div>' +
              '<div class="ag-kpi-card"><div class="ag-kpi-val" style="color:var(--red)">30%</div><div class="ag-kpi-label">CTV inventory never seen (Morgan Stanley)</div></div>' +
            '</div>' +
            '<div class="ag-info-box red">140% YoY growth in CTV ad fraud — DoubleVerify 2025. Sling Freestream runs through open exchanges where verification is <strong style="color:var(--text)">optional and rarely enforced.</strong></div>' +
          '</div>' +
          '<div class="ag-info-box amber" style="margin-top:0">⚠ P&G, Unilever & GM publicly announced 2025 budget concentration to <strong style="color:var(--text)">verified-only CTV inventory</strong>.</div>' +
        '</div>' +
        '<div class="ag-slide-col">' +
          '<div class="ag-card" style="border-color:rgba(0,212,255,0.2)">' +
            '<div class="ag-stat-desc" style="margin-bottom:10px;color:var(--cyan);font-weight:700;text-transform:uppercase;font-size:10px;letter-spacing:1px">EchoAds Solution</div>' +
            '<div class="ag-stat-desc" style="margin-bottom:12px">Every impression generates an immutable on-chain receipt: timestamp, node ID, latency, USDC payment — written to the Base blockchain. Any advertiser verifies on Basescan in real time. <strong class="ag-highlight">Not a platform report. Cryptographic fact.</strong></div>' +
            '<table class="ag-table">' +
              '<thead><tr><th>Inventory Type</th><th>CPM Range</th></tr></thead>' +
              '<tbody>' +
                '<tr><td>Unverified open exchange (today)</td><td class="val-red">$18–30</td></tr>' +
                '<tr><td>EchoAds verified on-chain</td><td class="val-green">$45–65</td></tr>' +
              '</tbody>' +
            '</table>' +
          '</div>' +
          '<div class="ag-info-box green">✅ IAB Tech Lab CTV Signal Integrity Framework (Oct 2025) explicitly calls for cryptographic delivery credentials — exactly what EchoAds generates for every impression.</div>' +
        '</div>' +
      '</div>' +
    '</div>';
  },

  ag11: function () {
    return '<div class="ag-slide">' +
      '<div class="ag-slide-header">' +
        '<span class="ag-scene-badge">Revenue Math</span>' +
        '<h2 class="ag-slide-title">Same Inventory. Same Viewers. +$360M Per Year.</h2>' +
      '</div>' +
      '<div class="grid-2" style="margin-bottom:16px">' +
        '<div class="ag-kpi-card" style="border-color:rgba(255,59,92,0.3);background:rgba(255,59,92,0.04)">' +
          '<div style="font-size:10px;color:var(--red);font-weight:800;text-transform:uppercase;letter-spacing:1px;margin-bottom:8px">Sling Freestream Today</div>' +
          '<div class="ag-stat-big red">$25M</div>' +
          '<div class="ag-kpi-label" style="margin-top:6px">1B impressions/month × $25 avg CPM (unverified)</div>' +
        '</div>' +
        '<div class="ag-kpi-card" style="border-color:rgba(0,255,136,0.3);background:rgba(0,255,136,0.04)">' +
          '<div style="font-size:10px;color:var(--green);font-weight:800;text-transform:uppercase;letter-spacing:1px;margin-bottom:8px">With EchoAds Verification</div>' +
          '<div class="ag-stat-big green">$55M</div>' +
          '<div class="ag-kpi-label" style="margin-top:6px">1B impressions/month × $55 avg CPM (verified)</div>' +
        '</div>' +
      '</div>' +
      '<div class="ag-card" style="text-align:center;background:linear-gradient(135deg,rgba(0,170,255,0.06),rgba(0,255,136,0.06));border-color:rgba(0,212,255,0.2)">' +
        '<div class="ag-stat-big cyan">+$360M / year</div>' +
        '<div class="ag-stat-desc" style="margin-top:8px">From inventory EchoStar already owns and sells today.<br><strong class="ag-highlight">No new subscribers. No new content rights. Just proof.</strong></div>' +
        '<div class="ag-stat-desc" style="margin-top:8px;font-size:10px">Source: PubMatic 2025 — verified inventory commands 2.1–2.8× premium over unverified of equivalent audience quality</div>' +
      '</div>' +
    '</div>';
  },

  ag12: function () {
    return '<div class="ag-slide">' +
      '<div class="ag-slide-header">' +
        '<span class="ag-scene-badge">Problem 2</span>' +
        '<h2 class="ag-slide-title">$45B Market — EchoStar Revenue: $0</h2>' +
      '</div>' +
      '<div class="ag-slide-cols">' +
        '<div class="ag-slide-col">' +
          '<div class="ag-card" style="border-color:rgba(255,59,92,0.3)">' +
            '<div class="ag-stat-desc" style="color:var(--red);font-weight:700;text-transform:uppercase;font-size:10px;letter-spacing:1px;margin-bottom:8px">Why EchoStar Is Locked Out</div>' +
            '<div class="ag-stat-big red" style="font-size:36px">5–30s</div>' +
            '<div class="ag-kpi-label" style="margin-bottom:12px">Sling TV HLS delay behind live action</div>' +
            '<div class="ag-stat-desc">NJ & PA gaming commissions require <strong class="ag-highlight">sub-500ms signal synchronization</strong> for in-play betting. Sling TV\'s HLS stream runs 5–30 seconds behind live. This is not a gap — it is a <strong style="color:var(--red)">categorical disqualification.</strong></div>' +
          '</div>' +
          '<div class="ag-kpi-card" style="border-color:rgba(255,59,92,0.3)">' +
            '<div class="ag-stat-big red">$0</div>' +
            '<div class="ag-kpi-label">EchoStar share of $45B in-play betting market</div>' +
          '</div>' +
        '</div>' +
        '<div class="ag-slide-col">' +
          '<div class="ag-card" style="border-color:rgba(0,255,136,0.3)">' +
            '<div class="ag-stat-desc" style="color:var(--green);font-weight:700;text-transform:uppercase;font-size:10px;letter-spacing:1px;margin-bottom:8px">EchoAds Unlocks This Market</div>' +
            '<div class="ag-stat-big green" style="font-size:36px">312ms</div>' +
            '<div class="ag-kpi-label" style="color:var(--green);margin-bottom:12px">P95 · Clears 500ms threshold ✅</div>' +
            '<div class="ag-stat-desc">The moment EchoAds deploys at scale, EchoStar becomes technically qualified overnight to partner with every major US betting operator as verified low-latency delivery infrastructure.</div>' +
          '</div>' +
          '<div class="ag-kpi-card" style="border-color:rgba(0,255,136,0.3)">' +
            '<div class="ag-stat-big green">$45B</div>' +
            '<div class="ag-kpi-label">US in-play sports betting — total annual wagers</div>' +
          '</div>' +
        '</div>' +
      '</div>' +
    '</div>';
  },

  ag13: function () {
    return '<div class="ag-slide">' +
      '<div class="ag-slide-header">' +
        '<span class="ag-scene-badge">Benchmark</span>' +
        '<h2 class="ag-slide-title">100 Trials. 13× Faster. Regulatory Threshold Cleared.</h2>' +
      '</div>' +
      '<div class="ag-slide-col" style="gap:12px">' +
        '<div class="ag-card">' +
          '<div class="ag-latency-wrap">' +
            '<div class="ag-lat-row">' +
              '<div class="ag-lat-label"><span style="color:var(--cyan)">EchoAds MOQ/QUIC — P95</span><span style="color:var(--green);font-weight:700">312ms ✅</span></div>' +
              '<div class="ag-lat-track"><div class="ag-lat-fill moq" id="lat-moq" style="width:7.6%"></div><div class="ag-lat-threshold"></div></div>' +
            '</div>' +
            '<div class="ag-lat-row">' +
              '<div class="ag-lat-label"><span style="color:var(--muted)">Sling TV HLS — P95</span><span style="color:var(--red);font-weight:700">4,100ms ❌</span></div>' +
              '<div class="ag-lat-track"><div class="ag-lat-fill hls" id="lat-hls" style="width:100%"></div></div>' +
            '</div>' +
          '</div>' +
        '</div>' +
        '<div class="grid-3">' +
          '<div class="ag-kpi-card"><div class="ag-kpi-val" style="color:var(--cyan)">243ms</div><div class="ag-kpi-label">MOQ P50 Median</div></div>' +
          '<div class="ag-kpi-card"><div class="ag-kpi-val" style="color:var(--green)">312ms</div><div class="ag-kpi-label">MOQ P95 ✅ SLA Met</div></div>' +
          '<div class="ag-kpi-card"><div class="ag-kpi-val" style="color:var(--purple)">13×</div><div class="ag-kpi-label">Faster than HLS at P95</div></div>' +
        '</div>' +
        '<div class="ag-info-box cyan">100 consecutive trials · AWS us-east-1 · Recorded May 2026.<br>312ms clears the 500ms gaming regulatory threshold by <strong class="ag-highlight">188ms</strong>.</div>' +
      '</div>' +
    '</div>';
  },

  ag14: function () {
    return '<div class="ag-slide">' +
      '<div class="ag-slide-header">' +
        '<span class="ag-scene-badge">Token Economics</span>' +
        '<h2 class="ag-slide-title">Burn-and-Mint Equilibrium — Self-Regulating Supply</h2>' +
      '</div>' +
      '<div class="ag-slide-cols">' +
        '<div class="ag-slide-col">' +
          '<div class="ag-card" style="border-color:rgba(255,59,92,0.2)">' +
            '<div style="font-size:10px;font-weight:800;text-transform:uppercase;letter-spacing:1px;color:var(--red);margin-bottom:10px">🔥 Burn Side — Demand Creates Scarcity</div>' +
            '<div class="ag-stat-desc">Service buyer pays USDC → AdBurn contract burns CMXS proportionally.<br><br><strong style="color:var(--text)">More ad spend → more CMXS burned → supply ↓ → price pressure ↑</strong></div>' +
          '</div>' +
          '<div class="ag-card" style="border-color:rgba(0,255,136,0.2)">' +
            '<div style="font-size:10px;font-weight:800;text-transform:uppercase;letter-spacing:1px;color:var(--green);margin-bottom:10px">🪙 Mint Side — Work Creates Supply</div>' +
            '<div class="ag-stat-desc">Node delivers content → Oracle verifies → 0.001 CMXS minted.<br><br><strong style="color:var(--text)">More deliveries → more CMXS minted → rewards node operators</strong></div>' +
          '</div>' +
        '</div>' +
        '<div class="ag-slide-col">' +
          '<div class="ag-card">' +
            '<div style="font-size:10px;font-weight:800;text-transform:uppercase;letter-spacing:1px;color:var(--muted);margin-bottom:12px">Equilibrium Safety Parameters</div>' +
            '<table class="ag-table">' +
              '<tbody>' +
                '<tr><td>PoD Reward Rate</td><td class="val-cyan">0.001 CMXS/delivery</td></tr>' +
                '<tr><td>Burn Rate</td><td class="val-red">1 CMXS per $0.10 USDC</td></tr>' +
                '<tr><td>Daily Mint Cap</td><td class="val-amber">2,880,000 CMXS</td></tr>' +
                '<tr><td>Max Supply</td><td class="val-cyan">1,000,000,000 CMXS</td></tr>' +
                '<tr><td>Mint Authority</td><td class="val-green">Oracle only (no team key)</td></tr>' +
              '</tbody>' +
            '</table>' +
          '</div>' +
          '<div class="ag-info-box cyan">Daily cap = 2,000 nodes × 1,440 deliveries × 0.001 CMXS. Even a full oracle compromise cannot produce more than <strong class="ag-highlight">0.288%</strong> of supply in 24 hours.</div>' +
        '</div>' +
      '</div>' +
    '</div>';
  },

  ag15: function () {
    return '<div class="ag-slide">' +
      '<div class="ag-slide-header">' +
        '<span class="ag-scene-badge">Consensus</span>' +
        '<h2 class="ag-slide-title">PoD vs PoW vs PoS — Why Proof-of-Delivery Wins</h2>' +
      '</div>' +
      '<div class="ag-card" style="margin-bottom:16px">' +
        '<table class="ag-table">' +
          '<thead><tr><th>Mechanism</th><th>What Gets Rewarded</th><th>Energy</th><th>Fit for CMXS</th></tr></thead>' +
          '<tbody>' +
            '<tr><td><strong>Proof-of-Work</strong> (Bitcoin)</td><td>Solving pointless puzzles</td><td style="color:var(--red)">Enormous</td><td class="val-red">❌ No delivery benefit</td></tr>' +
            '<tr><td><strong>Proof-of-Stake</strong> (Ethereum)</td><td>Holding tokens — rewards capital</td><td style="color:var(--green)">Low</td><td class="val-red">❌ Rich-get-richer</td></tr>' +
            '<tr style="background:rgba(0,212,255,0.05)"><td><strong style="color:var(--cyan)">Proof-of-Delivery (CMXS) ✓</strong></td><td>Delivering verified content &lt;500ms</td><td style="color:var(--green)">Minimal</td><td class="val-green">✅ Rewards real work</td></tr>' +
          '</tbody>' +
        '</table>' +
      '</div>' +
      '<div class="ag-slide-cols">' +
        '<div class="ag-info-box cyan">' +
          '<strong class="ag-highlight">Dual-Signal Verification:</strong><br>' +
          'PoD requires BOTH a viewer ECDSA receipt AND an independent x402 on-chain payment. Two separate cryptographic systems must both be defeated simultaneously — computationally infeasible.' +
        '</div>' +
        '<div class="ag-info-box green">' +
          '<strong class="ag-highlight">Anti-Replay Protection:</strong><br>' +
          'Every delivery ID stored in <code style="color:var(--cyan)">usedHashes</code> mapping. Resubmitting the same proof is rejected with "Proof already used" — no double-reward possible.' +
        '</div>' +
      '</div>' +
    '</div>';
  },

  ag16: function () {
    return '<div class="ag-slide">' +
      '<div class="ag-slide-header">' +
        '<span class="ag-scene-badge">DePIN Revenue</span>' +
        '<h2 class="ag-slide-title">5,800 Sites That Earn $0 From Advertising — Until Now</h2>' +
      '</div>' +
      '<div class="ag-slide-cols">' +
        '<div class="ag-slide-col">' +
          '<div class="ag-card" style="border-color:rgba(255,59,92,0.2)">' +
            '<div class="ag-stat-big red">$0</div>' +
            '<div class="ag-stat-desc" style="margin-top:8px">EchoStar\'s 5,800+ broadcast sites carry the video that contains the ads that generate the revenue — and earn <strong style="color:var(--red)">nothing</strong> from advertising. Flat lease fee only.</div>' +
          '</div>' +
        '</div>' +
        '<div class="ag-slide-col">' +
          '<div class="ag-card" style="border-color:rgba(0,255,136,0.2)">' +
            '<div class="ag-stat-desc" style="color:var(--green);font-weight:700;text-transform:uppercase;font-size:10px;letter-spacing:1px;margin-bottom:10px">With CMXS PoD Rewards</div>' +
            '<div class="grid-2" style="margin-bottom:12px">' +
              '<div class="ag-kpi-card"><div class="ag-kpi-val" style="color:var(--green)">432</div><div class="ag-kpi-label">CMXS/site/month (~$432)</div></div>' +
              '<div class="ag-kpi-card"><div class="ag-kpi-val" style="color:var(--cyan)">$30M</div><div class="ag-kpi-label">Annual network revenue</div></div>' +
            '</div>' +
            '<div class="ag-stat-desc">5,800 sites × 1,440 deliveries/day × 0.001 CMXS = <strong class="ag-highlight">2.5M CMXS/month</strong> flowing automatically to tower operators. No invoice. No approval.</div>' +
          '</div>' +
        '</div>' +
      '</div>' +
      '<div class="ag-info-box amber" style="margin-top:12px">Helium Network proved this model: ~1 million independently operated hotspots at peak (2022), zero company-owned. <strong class="ag-highlight">EchoStar starts with 5,800 sites already in the ground.</strong></div>' +
    '</div>';
  },

  ag17: function () {
    return '<div class="ag-slide">' +
      '<div class="ag-slide-header">' +
        '<span class="ag-scene-badge">Flywheel</span>' +
        '<h2 class="ag-slide-title">Four Independent Demand Engines — Any One Is Sufficient</h2>' +
      '</div>' +
      '<div class="grid-2" style="margin-bottom:14px">' +
        '<div class="ag-kpi-card" style="border-color:rgba(0,212,255,0.3);text-align:left;padding:14px">' +
          '<div class="ag-tag cyan" style="margin-bottom:8px">Engine 1</div>' +
          '<div style="font-size:13px;font-weight:800;margin-bottom:6px">PoD Node Rewards</div>' +
          '<div class="ag-stat-desc">0.001 CMXS per verified delivery — directly aligns token value with network performance and delivery quality.</div>' +
        '</div>' +
        '<div class="ag-kpi-card" style="border-color:rgba(255,59,92,0.3);text-align:left;padding:14px">' +
          '<div class="ag-tag red" style="margin-bottom:8px">Engine 2</div>' +
          '<div style="font-size:13px;font-weight:800;margin-bottom:6px">x402 Ad Spend Burns</div>' +
          '<div class="ag-stat-desc">Every dollar of ad spend burns CMXS — ties token demand directly to platform revenue growth.</div>' +
        '</div>' +
        '<div class="ag-kpi-card" style="border-color:rgba(0,255,136,0.3);text-align:left;padding:14px">' +
          '<div class="ag-tag green" style="margin-bottom:8px">Engine 3</div>' +
          '<div style="font-size:13px;font-weight:800;margin-bottom:6px">SLA Staking</div>' +
          '<div class="ag-stat-desc">Nodes stake CMXS for premium routing slots — permanently removes circulating supply from the market.</div>' +
        '</div>' +
        '<div class="ag-kpi-card" style="border-color:rgba(168,85,247,0.3);text-align:left;padding:14px">' +
          '<div class="ag-tag purple" style="margin-bottom:8px">Engine 4</div>' +
          '<div style="font-size:13px;font-weight:800;margin-bottom:6px">veToken Governance</div>' +
          '<div class="ag-stat-desc">Lock CMXS 1–4 years for voting rights and USDC protocol fee income — aligns long-term holders with network health.</div>' +
        '</div>' +
      '</div>' +
      '<div class="ag-info-box cyan">Flywheel: more demand burns tokens → higher value attracts nodes → better coverage attracts buyers → more demand. <strong class="ag-highlight">Each cycle reinforces the next.</strong></div>' +
    '</div>';
  },

  ag18: function () {
    return '<div class="ag-slide">' +
      '<div class="ag-slide-header">' +
        '<span class="ag-scene-badge">Summary</span>' +
        '<h2 class="ag-slide-title">Four Problems. One Protocol. Over $1B in Recoverable Revenue.</h2>' +
      '</div>' +
      '<div class="ag-card" style="margin-bottom:14px">' +
        '<table class="ag-table">' +
          '<thead><tr><th>Problem</th><th>Current State</th><th>EchoAds Solution</th></tr></thead>' +
          '<tbody>' +
            '<tr><td>Ad fraud / no delivery proof</td><td class="val-red">30% unseen · CPM $18–30</td><td class="val-green">On-chain receipt · +$360M/yr ✅</td></tr>' +
            '<tr><td>Sports betting locked out</td><td class="val-red">$45B market · EchoStar $0</td><td class="val-green">312ms P95 clears threshold ✅</td></tr>' +
            '<tr><td>5,800 sites earn $0 from ads</td><td class="val-red">Flat lease only</td><td class="val-green">432 CMXS/site/month · $30M/yr ✅</td></tr>' +
            '<tr><td>Single-source token demand</td><td class="val-red">Speculation only</td><td class="val-green">4 independent demand engines ✅</td></tr>' +
          '</tbody>' +
        '</table>' +
      '</div>' +
      '<div class="ag-card" style="text-align:center;background:linear-gradient(135deg,rgba(0,170,255,0.07),rgba(168,85,247,0.07));border-color:rgba(0,212,255,0.25)">' +
        '<div style="font-size:15px;font-weight:700;line-height:1.8;max-width:600px;margin:0 auto;color:var(--text)">' +
          'The infrastructure is live.<br>' +
          'Both contracts are on Base Sepolia — verifiable by anyone right now.<br>' +
          '<span style="color:var(--cyan)">The question is not whether this technology works.</span><br>' +
          'The question is whether EchoStar captures this revenue —<br>' +
          '<span style="color:var(--green)">or watches a competitor build the same system on someone else\'s towers.</span>' +
        '</div>' +
        '<div style="margin-top:14px;font-size:11px;color:var(--muted)">Infrastructure live on AWS · Both contracts on Base Sepolia · May 2026</div>' +
      '</div>' +
    '</div>';
  }
};
