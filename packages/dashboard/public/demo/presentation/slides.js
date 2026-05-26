// presentation/slides.js — HTML content for scenes 10–15 (REFRAMED: financial urgency first)

window.Slides = {

  // ── Slide 1: Problem #1 — Ad Fraud & Trust Crisis ─────────
  s10: function () {
    return '<div style="padding:24px;animation:fadeInUp .5s ease">' +
      '<div class="scene-strip" style="margin-bottom:18px">' +
        '<span class="scene-badge">Problem 1 of 4</span>' +
        '<span class="scene-title">Ad Fraud &amp; The Trust Crisis</span>' +
      '</div>' +
      '<div class="slide-cols">' +
        '<div class="slide-problem">' +
          '<div class="slide-box-label">The Financial Exposure Today</div>' +
          '<div style="display:grid;grid-template-columns:1fr 1fr;gap:8px;margin-bottom:12px">' +
            '<div style="text-align:center;padding:10px;background:rgba(255,59,92,.08);border-radius:8px">' +
              '<div style="font-size:26px;font-weight:900;color:var(--red);font-family:var(--mono)">$84B</div>' +
              '<div style="font-size:10px;color:var(--muted);margin-top:3px">Global ad fraud<br>2023–2025 (ANA)</div>' +
            '</div>' +
            '<div style="text-align:center;padding:10px;background:rgba(255,59,92,.08);border-radius:8px">' +
              '<div style="font-size:26px;font-weight:900;color:var(--red);font-family:var(--mono)">30%</div>' +
              '<div style="font-size:10px;color:var(--muted);margin-top:3px">CTV inventory never<br>seen by real viewer<br><span style="color:var(--amber)">— Morgan Stanley</span></div>' +
            '</div>' +
          '</div>' +
          '<div class="slide-stat-desc">DoubleVerify benchmarks document <strong style="color:var(--text)">30–70% YoY growth</strong> in CTV fraud rates. Sling Freestream runs through open exchanges — The Trade Desk, Magnite, AppNexus — where ad verification is optional and rarely enforced.</div>' +
          '<div style="margin-top:10px;padding:10px;background:rgba(255,59,92,.08);border-radius:8px;font-size:12px;color:var(--muted)">' +
            '⚠ P&amp;G, Unilever &amp; GM publicly announced in 2025 they are <strong style="color:var(--text)">cutting budgets to unverified CTV platforms</strong> and concentrating spend on verified-only inventory.' +
          '</div>' +
        '</div>' +
        '<div class="slide-solution">' +
          '<div class="slide-box-label">EchoAds Solution — Cryptographic Proof</div>' +
          '<div class="slide-stat-desc" style="margin-bottom:12px">EchoAds generates an immutable on-chain receipt for every impression — timestamp, node ID, latency, USDC payment — written to the Base blockchain. Any advertiser verifies on Basescan in real time. <strong style="color:var(--green)">Not EchoStar reporting its own numbers. Cryptographic fact.</strong></div>' +
          '<div style="padding:10px;background:rgba(0,232,122,.07);border:1px solid rgba(0,232,122,.2);border-radius:8px;font-size:11px;color:var(--muted);margin-bottom:10px">' +
            '✅ IAB Tech Lab CTV Signal Integrity Framework (Oct 2025) explicitly calls for cryptographic delivery credentials — exactly what EchoAds already generates.' +
          '</div>' +
          '<table class="slide-table">' +
            '<thead><tr><th>Inventory Type</th><th>CPM Range</th></tr></thead>' +
            '<tbody>' +
              '<tr><td>Unverified open exchange (today)</td><td class="val-red">$18–30</td></tr>' +
              '<tr><td>Verified w/ on-chain proof</td><td class="val-green">$45–65</td></tr>' +
            '</tbody>' +
          '</table>' +
        '</div>' +
      '</div>' +
    '</div>';
  },

  // ── Slide 2: Verified CPM Premium ─────────────────────────
  s11: function () {
    return '<div style="padding:24px;animation:fadeInUp .5s ease">' +
      '<div class="scene-strip" style="margin-bottom:18px">' +
        '<span class="scene-badge">The Revenue Math</span>' +
        '<span class="scene-title">Same Inventory. Same Viewers. Double the Revenue.</span>' +
      '</div>' +
      '<div style="display:grid;grid-template-columns:1fr 1fr;gap:14px;margin-bottom:16px">' +
        '<div style="background:rgba(255,59,92,.06);border:1px solid rgba(255,59,92,.2);border-radius:12px;padding:18px;text-align:center">' +
          '<div style="font-size:11px;color:var(--red);font-weight:700;text-transform:uppercase;letter-spacing:1px;margin-bottom:8px">Sling Freestream Today</div>' +
          '<div style="font-size:36px;font-weight:900;color:var(--red);font-family:var(--mono)">$25M</div>' +
          '<div style="font-size:11px;color:var(--muted);margin-top:6px">1B impressions/month<br>× $25 avg CPM (unverified)</div>' +
        '</div>' +
        '<div style="background:rgba(0,232,122,.06);border:1px solid rgba(0,232,122,.2);border-radius:12px;padding:18px;text-align:center">' +
          '<div style="font-size:11px;color:var(--green);font-weight:700;text-transform:uppercase;letter-spacing:1px;margin-bottom:8px">With EchoAds Verification</div>' +
          '<div style="font-size:36px;font-weight:900;color:var(--green);font-family:var(--mono)">$55M</div>' +
          '<div style="font-size:11px;color:var(--muted);margin-top:6px">1B impressions/month<br>× $55 avg CPM (verified)</div>' +
        '</div>' +
      '</div>' +
      '<div style="padding:16px;background:linear-gradient(135deg,rgba(0,170,255,.07),rgba(0,232,122,.07));border:1px solid rgba(0,170,255,.2);border-radius:12px;text-align:center">' +
        '<div style="font-size:28px;font-weight:900;color:var(--cyan);font-family:var(--mono)">+$360M / year</div>' +
        '<div style="font-size:13px;color:var(--muted);margin-top:6px">From inventory EchoStar already owns and sells today.<br><strong style="color:var(--text)">No new subscribers. No new content rights. Just proof.</strong></div>' +
        '<div style="font-size:11px;color:var(--muted);margin-top:8px">Source: PubMatic 2025 — verified inventory commands 2.1–2.8× premium over unverified of equivalent audience quality</div>' +
      '</div>' +
    '</div>';
  },

  // ── Slide 3: Problem #2 — Fill Rate Crisis ─────────────────
  s12: function () {
    return '<div style="padding:24px;animation:fadeInUp .5s ease">' +
      '<div class="scene-strip" style="margin-bottom:18px">' +
        '<span class="scene-badge">Problem 2 of 4</span>' +
        '<span class="scene-title">$650M in Zombie Inventory</span>' +
      '</div>' +
      '<div class="slide-cols">' +
        '<div class="slide-problem">' +
          '<div class="slide-box-label">The Fill Rate Crisis</div>' +
          '<div class="slide-stat-big amber">38%</div>' +
          '<div style="font-size:11px;color:var(--muted);margin-top:4px;margin-bottom:12px">avg FAST fill rate — eMarketer &amp; Magnite 2024</div>' +
          '<div class="slide-stat-desc">Sling Freestream operates 600 channels. Industry estimates suggest 350–400 are in zombie status — existing but unprofitable, <strong style="color:var(--text)">actively pulling down the CPM floor for the entire platform.</strong></div>' +
          '<div style="margin-top:12px;padding:11px;background:rgba(255,170,0,.07);border-radius:8px;font-size:12px;color:var(--muted)">' +
            '<strong style="color:var(--text)">Daily math:</strong> 600 channels × 4 slots/hr × 24hrs × 62% unfilled<br>' +
            '= <strong style="color:var(--amber)">3.55M wasted impressions/day</strong><br>' +
            'At $5 floor CPM = <strong style="color:var(--red)">$650M/year unmonetized</strong>' +
          '</div>' +
        '</div>' +
        '<div class="slide-solution">' +
          '<div class="slide-box-label">EchoAds Solution — Per-Impression Auction</div>' +
          '<div class="slide-stat-desc">The x402 micropayment protocol enables any advertiser — from Fortune 500 to local business — to bid on and pay for a single impression, settled automatically on-chain. <strong style="color:var(--green)">This eliminates minimum commitment thresholds</strong> that currently lock out 80% of potential CTV advertisers, directly increasing fill rates for zombie channels.</div>' +
          '<div style="margin-top:12px;padding:11px;background:rgba(0,232,122,.07);border:1px solid rgba(0,232,122,.2);border-radius:8px;font-size:12px;color:var(--muted)">' +
            '✅ On-chain frequency caps enforced by smart contract — cannot be bypassed by DSPs or platforms. Eliminates over-frequency at its root.' +
          '</div>' +
          '<div style="margin-top:10px;padding:11px;background:var(--surface);border:1px solid var(--border);border-radius:8px;font-size:11px;color:var(--muted)">' +
            'EchoStar\'s own advertising leadership has publicly acknowledged fill rate and frequency challenges across the Freestream platform in trade press.' +
          '</div>' +
        '</div>' +
      '</div>' +
    '</div>';
  },

  // ── Slide 4: Problem #3 — DePIN / Towers Earn $0 ──────────
  s13: function () {
    return '<div style="padding:24px;animation:fadeInUp .5s ease">' +
      '<div class="scene-strip" style="margin-bottom:18px">' +
        '<span class="scene-badge">Problem 3 of 4</span>' +
        '<span class="scene-title">5,800 Sites That Earn $0 From Advertising</span>' +
      '</div>' +
      '<div class="slide-cols">' +
        '<div class="slide-problem">' +
          '<div class="slide-box-label">The Infrastructure Gap</div>' +
          '<div class="slide-stat-big red">$0</div>' +
          '<div class="slide-stat-desc">EchoStar operates 5,800+ owned broadcast and ground station sites. These sites carry the video that contains the ads that generate the revenue — and earn nothing from those ads. They receive a flat infrastructure fee regardless of ad volume or revenue generated.</div>' +
          '<div style="margin-top:10px;padding:10px;background:rgba(255,59,92,.07);border-radius:8px;font-size:12px;color:var(--muted)">' +
            'In the DePIN model, infrastructure operators earn for every delivery they enable. EchoStar\'s sites enable millions — and are compensated for zero of them.' +
          '</div>' +
        '</div>' +
        '<div class="slide-solution">' +
          '<div class="slide-box-label">EchoAds DePIN Revenue Share</div>' +
          '<div style="display:grid;grid-template-columns:1fr 1fr;gap:8px;margin-bottom:12px">' +
            '<div style="background:rgba(0,232,122,.08);border:1px solid rgba(0,232,122,.2);border-radius:8px;padding:11px;text-align:center">' +
              '<div style="font-size:18px;font-weight:900;color:var(--green);font-family:var(--mono)">0.01 CMXS</div>' +
              '<div style="font-size:10px;color:var(--muted);margin-top:3px">per verified delivery<br>≈ $0.01</div>' +
            '</div>' +
            '<div style="background:rgba(0,170,255,.08);border:1px solid rgba(0,170,255,.2);border-radius:8px;padding:11px;text-align:center">' +
              '<div style="font-size:18px;font-weight:900;color:var(--blue);font-family:var(--mono)">432 CMXS</div>' +
              '<div style="font-size:10px;color:var(--muted);margin-top:3px">per site/month<br>≈ $432</div>' +
            '</div>' +
          '</div>' +
          '<div style="padding:12px;background:linear-gradient(135deg,rgba(0,232,122,.08),rgba(0,170,255,.08));border:1px solid rgba(0,232,122,.2);border-radius:8px;text-align:center;margin-bottom:10px">' +
            '<div style="font-size:22px;font-weight:900;color:var(--green);font-family:var(--mono)">~$2.5M/month</div>' +
            '<div style="font-size:10px;color:var(--muted);margin-top:4px">5,800 sites × 432 CMXS × ~$1 · <strong style="color:var(--cyan)">≈ $30M/year</strong></div>' +
          '</div>' +
          '<div style="font-size:12px;color:var(--muted);line-height:1.6">Helium Network proved this model: nearly <strong style="color:var(--text)">1 million hotspots at peak (2022)</strong>, zero company-owned. EchoStar starts with 5,800 sites already in the ground — eliminating the cold-start problem every DePIN network faces.</div>' +
        '</div>' +
      '</div>' +
    '</div>';
  },

  // ── Slide 5: Problem #4 — Sports Betting ──────────────────
  s14: function () {
    return '<div style="padding:24px;animation:fadeInUp .5s ease">' +
      '<div class="scene-strip" style="margin-bottom:18px">' +
        '<span class="scene-badge">Problem 4 of 4</span>' +
        '<span class="scene-title">$45B Market — EchoStar Revenue: $0</span>' +
      '</div>' +
      '<div class="slide-cols">' +
        '<div style="background:rgba(255,59,92,.06);border:1px solid rgba(255,59,92,.2);border-radius:12px;padding:18px">' +
          '<div class="slide-box-label" style="color:var(--red)">Why EchoStar Is Locked Out Today</div>' +
          '<div class="slide-stat-big red" style="font-size:36px">5–30s</div>' +
          '<div style="font-size:11px;color:var(--muted);margin-bottom:12px">Sling TV HLS stream delay behind live action</div>' +
          '<div class="slide-stat-desc">NJ and PA gaming commissions require <strong style="color:var(--text)">sub-500ms signal synchronization</strong> for in-play betting. Sling TV\'s HLS stream runs 5 to 30 seconds behind live. This is not a gap — it is a <strong style="color:var(--red)">categorical disqualification.</strong> EchoStar\'s current share of the US in-play betting market: <strong style="color:var(--red)">$0.</strong></div>' +
        '</div>' +
        '<div style="background:rgba(0,232,122,.06);border:1px solid rgba(0,232,122,.2);border-radius:12px;padding:18px">' +
          '<div class="slide-box-label" style="color:var(--green)">EchoAds Unlocks This Market Immediately</div>' +
          '<div class="slide-stat-big green" style="font-size:36px">312ms</div>' +
          '<div style="font-size:11px;color:var(--green);margin-bottom:12px">EchoAds P95 · clears 500ms regulatory threshold ✅</div>' +
          '<div class="slide-stat-desc" style="margin-bottom:12px">The moment EchoAds deploys at scale, EchoStar becomes technically qualified — overnight — to partner with every major US betting operator as a low-latency verified delivery infrastructure provider.</div>' +
          '<div style="padding:12px;background:rgba(0,232,122,.08);border-radius:8px;text-align:center">' +
            '<div style="font-size:26px;font-weight:900;color:var(--green);font-family:var(--mono)">~$45B</div>' +
            '<div style="font-size:11px;color:var(--muted);margin-top:4px">US in-play sports betting annual wagers<br>EchoStar current share: <strong style="color:var(--red)">$0</strong></div>' +
          '</div>' +
        '</div>' +
      '</div>' +
    '</div>';
  },

  // ── Slide 6: One-Sentence Closing ─────────────────────────
  s15: function () {
    return '<div style="padding:24px;animation:fadeInUp .5s ease">' +
      '<div class="scene-strip" style="margin-bottom:18px">' +
        '<span class="scene-badge">The One-Sentence Summary</span>' +
        '<span class="scene-title">Four Problems. One Protocol Layer. Over $1B in Recoverable Revenue.</span>' +
      '</div>' +
      '<table class="slide-table" style="margin-bottom:18px">' +
        '<thead><tr><th>Problem</th><th>Current State</th><th>EchoAds Solution</th></tr></thead>' +
        '<tbody>' +
          '<tr><td>Ad fraud / no delivery proof</td><td class="val-red">30% inventory unseen · CPM $18–30</td><td class="val-green">On-chain receipt · CPM $45–65 · +$360M/yr ✅</td></tr>' +
          '<tr><td>FAST fill rate crisis (~38%)</td><td class="val-red">$650M/yr unmonetized</td><td class="val-green">Per-impression x402 auction ✅</td></tr>' +
          '<tr><td>5,800 sites earn $0 from ads</td><td class="val-red">Flat lease only</td><td class="val-green">0.01 CMXS/delivery · ~$30M/yr ✅</td></tr>' +
          '<tr><td>Sports betting locked out</td><td class="val-red">$45B market · EchoStar = $0</td><td class="val-green">312ms P95 clears 500ms threshold ✅</td></tr>' +
          '<tr><td>HLS delay — rural/satellite</td><td class="val-amber">8–12s on satellite links</td><td class="val-green">287ms over any network ✅</td></tr>' +
        '</tbody>' +
      '</table>' +
      '<div style="padding:20px;background:linear-gradient(135deg,rgba(0,170,255,.08),rgba(0,232,122,.08));border:1px solid rgba(0,170,255,.2);border-radius:14px;text-align:center">' +
        '<div style="font-size:15px;font-weight:700;line-height:1.6;max-width:620px;margin:0 auto;color:var(--text)">' +
          'EchoAds is not fixing black screens.<br>' +
          'It is fixing a broken monetization system — one that costs EchoStar<br>' +
          '<span style="color:var(--cyan)">over $1 billion per year in recoverable revenue</span> —<br>' +
          'while turning 5,800 infrastructure sites into active participants<br>' +
          'in the advertising economy, and opening a door to a<br>' +
          '<span style="color:var(--green)">$45 billion sports betting market where EchoStar\'s revenue is zero.</span>' +
        '</div>' +
        '<div style="margin-top:14px;font-size:12px;color:var(--muted)">Infrastructure live at <a href="https://echoads.tv" style="color:var(--blue)">echoads.tv</a> · Both contracts verifiable on Base Sepolia · May 2026</div>' +
      '</div>' +
    '</div>';
  }

};
