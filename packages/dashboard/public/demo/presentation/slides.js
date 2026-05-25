// presentation/slides.js — HTML content for scenes 10–15

window.Slides = {

  s10: function () {
    return '<div style="padding:24px;animation:fadeInUp .5s ease">' +
      '<div class="scene-strip" style="margin-bottom:20px">' +
        '<span class="scene-badge">Problem 1 of 4</span>' +
        '<span class="scene-title">The Black Screen</span>' +
      '</div>' +
      '<div class="slide-cols">' +
        '<div class="slide-problem">' +
          '<div class="slide-box-label">The Problem Today</div>' +
          '<div class="slide-stat-big red">3–7s</div>' +
          '<div class="slide-stat-desc">Every time Sling TV inserts an ad, HLS tears down the existing TCP connection and rebuilds a new one. This structural reconnect takes 1.5 to 7 seconds and produces the black screen viewers experience — every single ad break, every single viewer.</div>' +
          '<div style="margin-top:14px;padding:12px;background:rgba(255,59,92,.08);border-radius:8px;font-size:12px;color:var(--muted)">' +
            '⚠ <strong style="color:var(--text)">Not a software bug.</strong> It is a structural limitation of TCP that HLS cannot overcome. Nearly 80% of CTV viewers report ad loading delays significantly damage brand perception.' +
          '</div>' +
        '</div>' +
        '<div class="slide-solution">' +
          '<div class="slide-box-label">EchoAds Solution</div>' +
          '<div class="slide-stat-big green">287ms</div>' +
          '<div class="slide-stat-desc">QUIC is multiplexed — content and ad streams share the same connection simultaneously. Switching ad tracks requires only one protocol message, not a full reconnection. <strong style="color:var(--green)">Zero black screen. Ever.</strong></div>' +
          '<div style="margin-top:14px;padding:12px;background:rgba(0,232,122,.08);border-radius:8px;font-size:12px;color:var(--muted)">' +
            '✅ Demonstrated live in this session. 100-trial P95: <strong style="color:var(--green)">312ms</strong>.' +
          '</div>' +
        '</div>' +
      '</div>' +
    '</div>';
  },

  s11: function () {
    return '<div style="padding:24px;animation:fadeInUp .5s ease">' +
      '<div class="scene-strip" style="margin-bottom:20px">' +
        '<span class="scene-badge">Problem 2 of 4</span>' +
        '<span class="scene-title">No Proof of Delivery — A $84B Trust Crisis</span>' +
      '</div>' +
      '<div style="display:grid;grid-template-columns:repeat(3,1fr);gap:12px;margin-bottom:18px">' +
        '<div class="slide-problem"><div class="slide-box-label">Global Ad Fraud</div><div class="slide-stat-big red" style="font-size:38px">$84B</div><div class="slide-stat-desc" style="font-size:11px">Lost to digital ad fraud globally in 2026</div></div>' +
        '<div class="slide-problem"><div class="slide-box-label">CTV Fraud Rate</div><div class="slide-stat-big amber" style="font-size:38px">65%</div><div class="slide-stat-desc" style="font-size:11px">Of all CTV fraud originates from bot traffic</div></div>' +
        '<div class="slide-problem"><div class="slide-box-label">Unverified Inventory</div><div class="slide-stat-big amber" style="font-size:38px">30%</div><div class="slide-stat-desc" style="font-size:11px">Of CTV inventory never seen by a real viewer (Morgan Stanley)</div></div>' +
      '</div>' +
      '<div class="slide-solution">' +
        '<div class="slide-box-label">EchoAds Solution — Cryptographic Proof</div>' +
        '<div style="font-size:13px;color:var(--muted);line-height:1.7">Every single ad delivery generates an immutable record on the Base blockchain — a permanent, tamper-proof entry including timestamp, delivery node, latency confirmation, and USDC payment receipt. Advertisers click directly to Basescan and verify every individual ad in real time. <strong style="color:var(--green)">This is the first time in the history of connected TV advertising that every impression has a cryptographic receipt.</strong></div>' +
        '<div style="margin-top:12px;font-family:var(--mono);font-size:11px;color:var(--cyan)">DeliveryOracle: 0x0e2af6786E207560De979eF5bAB07b5796DB9B2a</div>' +
      '</div>' +
    '</div>';
  },

  s12: function () {
    return '<div style="padding:24px;animation:fadeInUp .5s ease">' +
      '<div class="scene-strip" style="margin-bottom:20px">' +
        '<span class="scene-badge">Problem 3 of 4</span>' +
        '<span class="scene-title">Low Fill Rates — Zombie Inventory</span>' +
      '</div>' +
      '<div class="slide-cols">' +
        '<div class="slide-problem">' +
          '<div class="slide-box-label">The Problem Today</div>' +
          '<div class="slide-stat-big amber">38%</div>' +
          '<div class="slide-stat-desc">Average fill rate for FAST channels. Sling Freestream operates 600 channels — the majority running below the 70% fill threshold. A channel under 70% fill is zombie inventory: not profitable, actively depressing the platform CPM floor. DISH leadership has acknowledged a serious over-frequency problem where the same ads repeat because diverse demand cannot fill slots.</div>' +
        '</div>' +
        '<div class="slide-solution">' +
          '<div class="slide-box-label">EchoAds Solution</div>' +
          '<div class="slide-stat-big green" style="font-size:36px">Per-impression auction</div>' +
          '<div class="slide-stat-desc">The x402 micropayment protocol allows ad bidding at the individual impression level — one ad, one viewer, one payment, settled automatically on-chain. Combined with on-chain frequency caps enforced by smart contract, both fill rate and targeting precision improve structurally. Every impression in the feed you saw was settled automatically, with zero manual steps.</div>' +
        '</div>' +
      '</div>' +
    '</div>';
  },

  s13: function () {
    return '<div style="padding:24px;animation:fadeInUp .5s ease">' +
      '<div class="scene-strip" style="margin-bottom:20px">' +
        '<span class="scene-badge">Problem 4 of 4</span>' +
        '<span class="scene-title">Infrastructure Operators Earn Nothing — The DePIN Flywheel</span>' +
      '</div>' +
      '<div class="slide-cols">' +
        '<div class="slide-problem">' +
          '<div class="slide-box-label">The Problem Today</div>' +
          '<div class="slide-stat-big red">$0</div>' +
          '<div class="slide-stat-desc">Tower operators like EchoStar provide the physical infrastructure but receive no direct share of the advertising revenue their infrastructure generates. EchoStar has 60,000 towers that carry the video containing the ads generating the revenue — and earn nothing from those ads. They receive a flat lease fee, regardless of ad volume.</div>' +
        '</div>' +
        '<div class="slide-solution">' +
          '<div class="slide-box-label">EchoAds DePIN Flywheel</div>' +
          '<div style="display:grid;grid-template-columns:1fr 1fr;gap:10px;margin-bottom:12px">' +
            '<div style="background:rgba(0,232,122,.08);border:1px solid rgba(0,232,122,.2);border-radius:8px;padding:12px;text-align:center">' +
              '<div style="font-size:22px;font-weight:900;color:var(--green);font-family:var(--mono)">0.001</div>' +
              '<div style="font-size:10px;color:var(--muted);margin-top:4px">CMXS per verified delivery</div>' +
            '</div>' +
            '<div style="background:rgba(0,170,255,.08);border:1px solid rgba(0,170,255,.2);border-radius:8px;padding:12px;text-align:center">' +
              '<div style="font-size:22px;font-weight:900;color:var(--blue);font-family:var(--mono)">2.6M</div>' +
              '<div style="font-size:10px;color:var(--muted);margin-top:4px">CMXS/month at 60K tower scale</div>' +
            '</div>' +
          '</div>' +
          '<div style="font-size:12px;color:var(--muted);line-height:1.7">More infrastructure → better delivery → more advertisers → higher token value → more operators join. <strong style="color:var(--green)">EchoStar\'s towers are already in the ground.</strong> EchoAds is the software layer that turns them into revenue-generating participants in the advertising economy.</div>' +
        '</div>' +
      '</div>' +
    '</div>';
  },

  s14: function () {
    return '<div style="padding:24px;animation:fadeInUp .5s ease">' +
      '<div class="scene-strip" style="margin-bottom:20px">' +
        '<span class="scene-badge">Beyond Advertising</span>' +
        '<span class="scene-title">Sports Betting + Verified CPM Premium</span>' +
      '</div>' +
      '<div class="slide-cols">' +
        '<div style="background:var(--surface);border:1px solid var(--border);border-radius:12px;padding:18px">' +
          '<div class="slide-box-label" style="color:var(--blue)">Sports Betting Market Unlocked</div>' +
          '<div class="slide-stat-big blue">$45.9B</div>' +
          '<div class="slide-stat-desc">US in-play sports betting market. The regulatory threshold for real-time odds updates is under 500ms. Sling TV HLS streams run 5–30 seconds behind live. EchoAds at 312ms P95 clears the threshold. <strong style="color:var(--cyan)">EchoStar becomes a B2B infrastructure partner for every sports betting operator — the moment EchoAds deploys at scale.</strong></div>' +
        '</div>' +
        '<div style="background:var(--surface);border:1px solid var(--border);border-radius:12px;padding:18px">' +
          '<div class="slide-box-label" style="color:var(--green)">Verified CPM Premium</div>' +
          '<table class="slide-table">' +
            '<thead><tr><th>Inventory Type</th><th>CPM Range</th></tr></thead>' +
            '<tbody>' +
              '<tr><td>Unverified CTV (today)</td><td class="val-red">$18–30</td></tr>' +
              '<tr><td>Verified w/ on-chain proof</td><td class="val-green">$45–65</td></tr>' +
            '</tbody>' +
          '</table>' +
          '<div style="margin-top:12px;padding:10px;background:rgba(0,232,122,.08);border-radius:8px;font-size:12px;color:var(--green);font-weight:700">Same inventory. Same viewers. Revenue roughly doubles — without adding a single new subscriber.</div>' +
        '</div>' +
      '</div>' +
    '</div>';
  },

  s15: function () {
    return '<div style="padding:24px;animation:fadeInUp .5s ease">' +
      '<div class="scene-strip" style="margin-bottom:20px">' +
        '<span class="scene-badge">Scale of Opportunity</span>' +
        '<span class="scene-title">What EchoStar Captures</span>' +
      '</div>' +
      '<table class="slide-table" style="margin-bottom:20px">' +
        '<thead><tr><th>Industry Problem</th><th>Current State</th><th>EchoAds Solution</th></tr></thead>' +
        '<tbody>' +
          '<tr><td>Ad black screen (1.5–7s)</td><td class="val-red">~80% viewer brand damage</td><td class="val-green">287ms, zero black screen ✅</td></tr>' +
          '<tr><td>No delivery proof</td><td class="val-red">30% inventory unverified</td><td class="val-green">On-chain receipt per ad ✅</td></tr>' +
          '<tr><td>Low FAST fill rates (~38%)</td><td class="val-red">Hundreds of millions in dead inventory</td><td class="val-green">Per-impression x402 auction ✅</td></tr>' +
          '<tr><td>No infrastructure revenue share</td><td class="val-red">Towers earn flat lease only</td><td class="val-green">0.001 CMXS per delivery ✅</td></tr>' +
          '<tr><td>Sports betting market locked out</td><td class="val-red">$45.9B market inaccessible</td><td class="val-green">312ms P95 clears threshold ✅</td></tr>' +
        '</tbody>' +
      '</table>' +
      '<div style="padding:22px;background:linear-gradient(135deg,rgba(0,170,255,.08),rgba(0,232,122,.08));border:1px solid rgba(0,170,255,.2);border-radius:14px;text-align:center">' +
        '<div style="font-size:18px;font-weight:800;letter-spacing:-.3px;line-height:1.5;max-width:600px;margin:0 auto">' +
          '"Every impression is a cryptographic fact.<br>' +
          '<span style="color:var(--cyan)">Every delivery proves the SLA.</span><br>' +
          'Every node operator earns for doing it."' +
        '</div>' +
        '<div style="margin-top:16px;font-size:13px;color:var(--muted)">EchoAds Phase 0 · Live at <a href="https://echoads.tv" style="color:var(--blue)">echoads.tv</a> · May 2026</div>' +
      '</div>' +
    '</div>';
  }

};
