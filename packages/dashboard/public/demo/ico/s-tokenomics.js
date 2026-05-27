(function() {
  window.Sections = window.Sections || {};
  window.Sections['sec-tokenomics'] = `
    <div class="section-container">
      <div class="section-header text-center">
        <h2>Token Allocation</h2>
        <p class="section-subtitle">1,000,000,000 Total Supply &middot; Fixed Cap &middot; $100M Initial FDV</p>
      </div>

      <div class="token-container">
        <!-- Donut Chart injected by ico.js -->
        <div class="donut-chart-wrapper" id="donut-chart-container"></div>
        <div class="donut-legend" id="donut-legend"></div>
      </div>

      <div class="token-stats-grid mt-5">
        <div class="t-stat-box">
          <div class="t-stat-val">1,000,000,000 CMXS</div>
          <div class="t-stat-label">Total Supply — Fixed cap. No additional minting.</div>
        </div>
        <div class="t-stat-box">
          <div class="t-stat-val">150,000,000 CMXS (15%)</div>
          <div class="t-stat-label">TGE Circulating — Prevents price manipulation at launch</div>
        </div>
        <div class="t-stat-box">
          <div class="t-stat-val">12-month cliff — 48-month vest</div>
          <div class="t-stat-label">Team Lock-up — Longest in DePIN industry</div>
        </div>
        <div class="t-stat-box">
          <div class="t-stat-val">35% of supply</div>
          <div class="t-stat-label">Node Rewards — Only minted when verified delivery happens</div>
        </div>
        <div class="t-stat-box">
          <div class="t-stat-val">2,880,000 CMXS</div>
          <div class="t-stat-label">Daily Mint Cap — Hardcoded safety limit</div>
        </div>
        <div class="t-stat-box">
          <div class="t-stat-val">USD 100,000,000</div>
          <div class="t-stat-label">Initial FDV — At USD 0.10 IDO price</div>
        </div>
      </div>

    </div>
  `;
})();
