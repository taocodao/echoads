(function() {
  window.Sections = window.Sections || {};
  window.Sections['sec-ico'] = `
    <div class="section-container">
      <div class="section-header text-center">
        <h2>Four-Stage Capital Raise</h2>
        <p class="section-subtitle">A strategic fundraising funnel to establish institutional credibility before public access.</p>
      </div>

      <div class="ico-stages-container">
        <div class="ico-stage-card stage-active">
          <div class="stage-header">
            <span class="status-badge status-amber">OPEN NOW</span>
            <h3>Stage 0 — Angel / SAFE</h3>
          </div>
          <div class="stage-body">
            <h4 class="stage-subhead">Angel Round / Strategic Partners Only</h4>
            <div class="stage-details">
              <div class="detail-row"><span class="detail-label">Amount:</span> <span class="detail-val">USD 1M – 2M</span></div>
              <div class="detail-row"><span class="detail-label">Instrument:</span> <span class="detail-val">SAFE (Simple Agreement for Future Tokens)</span></div>
              <div class="detail-row"><span class="detail-label">Discount:</span> <span class="detail-val">20% discount to Seed price</span></div>
              <div class="detail-row"><span class="detail-label">Who:</span> <span class="detail-val">5–10 broadcast + DePIN strategic investors</span></div>
              <div class="detail-row"><span class="detail-label">KYC:</span> <span class="detail-val">Full KYC &middot; Jumio &middot; Accredited investors only</span></div>
            </div>
            <button class="btn-ico accent full-width mt-3" onclick="window.location.href='mailto:angel@cmxs.network'">Apply to Participate &rarr;</button>
          </div>
        </div>

        <div class="ico-stage-card">
          <div class="stage-header">
            <span class="status-badge status-blue">OPENS MONTH 3</span>
            <h3>Stage 1 — Seed Round</h3>
          </div>
          <div class="stage-body">
            <h4 class="stage-subhead">Seed Round / Reg D 506(c) &middot; Accredited Investors</h4>
            <div class="stage-details">
              <div class="detail-row"><span class="detail-label">Amount:</span> <span class="detail-val">USD 3M – 5M</span></div>
              <div class="detail-row"><span class="detail-label">Token Price:</span> <span class="detail-val">USD 0.02 / CMXS &middot; Implied FDV: USD 20M</span></div>
              <div class="detail-row"><span class="detail-label">Vesting:</span> <span class="detail-val">12-month cliff, then 36 months linear</span></div>
              <div class="detail-row"><span class="detail-label">Minimum ticket:</span> <span class="detail-val">USD 250,000</span></div>
              <div class="detail-row"><span class="detail-label">KYC:</span> <span class="detail-val">Via CoinList</span></div>
            </div>
            <button class="btn-ico outline full-width mt-3" onclick="window.location.href='/whitelist'">Join Waitlist &rarr;</button>
          </div>
        </div>

        <div class="ico-stage-card">
          <div class="stage-header">
            <span class="status-badge status-purple">OPENS MONTH 5</span>
            <h3>Stage 2 — IEO</h3>
          </div>
          <div class="stage-body">
            <h4 class="stage-subhead">Strategic / IEO Round / Exchange-Hosted</h4>
            <div class="stage-details">
              <div class="detail-row"><span class="detail-label">Amount:</span> <span class="detail-val">USD 8M – 15M</span></div>
              <div class="detail-row"><span class="detail-label">Token Price:</span> <span class="detail-val">USD 0.05–0.08 / CMXS &middot; FDV: USD 50M–80M</span></div>
              <div class="detail-row"><span class="detail-label">Vesting:</span> <span class="detail-val">20% at TGE, 12 months linear</span></div>
              <div class="detail-row"><span class="detail-label">Exchange:</span> <span class="detail-val">Binance Launchpad / Coinbase / Kraken</span></div>
            </div>
            <button class="btn-ico outline full-width mt-3" onclick="window.location.href='/notify'">Notify Me &rarr;</button>
          </div>
        </div>

        <div class="ico-stage-card">
          <div class="stage-header">
            <span class="status-badge status-green">OPENS MONTH 7 &middot; TGE</span>
            <h3>Stage 3 — Public IDO</h3>
          </div>
          <div class="stage-body">
            <h4 class="stage-subhead">Public IDO — Token Generation Event</h4>
            <div class="stage-details">
              <div class="detail-row"><span class="detail-label">Amount:</span> <span class="detail-val">USD 6M – 11M</span></div>
              <div class="detail-row"><span class="detail-label">Token Price:</span> <span class="detail-val">USD 0.10 (LBP start USD 0.15)</span></div>
              <div class="detail-row"><span class="detail-label">FDV:</span> <span class="detail-val">USD 100M</span></div>
              <div class="detail-row"><span class="detail-label">Venue:</span> <span class="detail-val">Fjord Foundry LBP + Uniswap v4 + 1–2 CEX</span></div>
              <div class="detail-row"><span class="detail-label">Vesting:</span> <span class="detail-val">20% immediate &middot; 80% over 12 months</span></div>
            </div>
            <button class="btn-ico outline full-width mt-3" onclick="window.location.href='/ido-register'">Register Interest &rarr;</button>
          </div>
        </div>
      </div>

      <div class="ico-summary-banner mt-5">
        <div class="summary-item">Total Target Raise: <strong>USD 18M – 33M</strong></div>
        <div class="summary-item">Initial FDV at TGE: <strong>USD 100M</strong></div>
        <div class="summary-item">Token Supply: <strong>1,000,000,000 CMXS</strong> (fixed, no additional minting)</div>
      </div>

      <div class="price-ladder-container mt-5">
        <h3 class="text-center" style="margin-bottom: 2rem;">Price Discovery Ladder</h3>
        <div class="price-ladder">
          <div class="pl-step">
            <div class="pl-price">$0.02</div>
            <div class="pl-label">Seed</div>
          </div>
          <div class="pl-arrow">➔</div>
          <div class="pl-step">
            <div class="pl-price">$0.05</div>
            <div class="pl-label">IEO (Floor)</div>
          </div>
          <div class="pl-arrow">➔</div>
          <div class="pl-step">
            <div class="pl-price">$0.08</div>
            <div class="pl-label">IEO (Cap)</div>
          </div>
          <div class="pl-arrow">➔</div>
          <div class="pl-step highlight">
            <div class="pl-price">$0.10</div>
            <div class="pl-label">Public IDO</div>
            <div class="pl-multiplier">5x from Seed</div>
          </div>
        </div>
      </div>

      <div class="proceeds-container mt-5">
        <h3 class="text-center" style="margin-bottom: 2rem;">Use of Proceeds (USD 25M Midpoint)</h3>
        <div class="proceeds-bar">
          <div class="pb-segment" style="width: 35%; background: #3B82F6;" data-label="Tech Dev 35%"><span>Tech Dev 35%</span></div>
          <div class="pb-segment" style="width: 25%; background: #8B5CF6;" data-label="Node Infra 25%"><span>Node Infra 25%</span></div>
          <div class="pb-segment" style="width: 15%; background: #10B981;" data-label="Legal 15%"><span>Legal 15%</span></div>
          <div class="pb-segment" style="width: 15%; background: #F59E0B;" data-label="Marketing 15%"><span>Marketing 15%</span></div>
          <div class="pb-segment" style="width: 10%; background: #6B7280;" data-label="Reserve 10%"><span>Reserve 10%</span></div>
        </div>
      </div>

    </div>
  `;
})();
