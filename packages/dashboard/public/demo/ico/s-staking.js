(function() {
  window.Sections = window.Sections || {};
  window.Sections['sec-staking'] = `
    <div class="section-container">
      <div class="section-header text-center">
        <h2>Staking Architecture</h2>
        <p class="section-subtitle">A multi-layered staking model providing utility for operators, buyers, and token holders.</p>
      </div>

      <div class="stake-cards-container">
        <div class="stake-card sc-blue">
          <div class="stake-badge sb-blue">INFRASTRUCTURE LAYER</div>
          <h3>Run a Node</h3>
          <p class="stake-italic">Stake CMXS to operate a delivery node</p>
          <div class="stake-body">
            <p>Stake a minimum of 1,000 CMXS (~USD 100 at initial FDV) to activate your node's Proof-of-Delivery eligibility. Your node delivers content via the QUIC/MoQ protocol to end devices in your coverage area. For every verified delivery under 500ms, you automatically receive 0.001 CMXS — directly to your wallet.</p>
            <div class="stake-highlight">
              <strong>Earnings at USD 100 CMXS price:</strong><br>
              &rarr; USD 1.44/node/day (1,440 deliveries &times; USD 0.001 &times; 100)<br>
              &rarr; USD 43.20/node/month<br>
              &rarr; Hardware payback: ~230 days (USD 329 Raspberry Pi 5)
            </div>
            <p><strong>Slash protection:</strong> 3 failed deliveries in 24 hours triggers 10% stake slash. 7-day unstake delay prevents gaming.</p>
            <p class="stake-who"><strong>Who is this for?</strong> Tower operators &middot; Broadcast infrastructure owners &middot; Data centre operators &middot; Home lab operators</p>
          </div>
        </div>

        <div class="stake-card sc-purple">
          <div class="stake-badge sb-purple">DEMAND LAYER</div>
          <h3>Buy Verified Delivery</h3>
          <p class="stake-italic">Pre-commit USDC for discounted burns and priority routing</p>
          <div class="stake-body">
            <table class="stake-tier-table">
              <tr><td>Standard (USD 0–9,999)</td><td>Best effort routing — 0% burn discount</td></tr>
              <tr><td>Tier 1 (USD 10,000)</td><td>Standard priority routing — 5% CMXS burn discount</td></tr>
              <tr><td>Tier 2 (USD 50,000)</td><td>High priority routing — 12% CMXS burn discount</td></tr>
              <tr><td>Tier 3 (USD 250,000)</td><td>Guaranteed premium slots — 20% CMXS burn discount</td></tr>
            </table>
            <p class="mt-3"><strong>Your benefit:</strong> Verified delivery at 2&times; market CPM (USD 45–65 vs. USD 18–30 unverified). On-chain proof of every delivery — audit-ready, fraud-proof.</p>
            <p class="stake-who"><strong>Who is this for?</strong> Streaming platforms &middot; Ad networks &middot; Live sports operators &middot; Pay-per-view platforms</p>
          </div>
        </div>

        <div class="stake-card sc-green">
          <div class="stake-badge sb-green">GOVERNANCE LAYER</div>
          <h3>Govern the Protocol</h3>
          <p class="stake-italic">Lock CMXS for veCMXS governance rights and protocol fee income</p>
          <div class="stake-body">
            <table class="stake-tier-table">
              <tr><td>Lock 1 year</td><td>&rarr; 0.25 veCMXS per CMXS (25% voting weight)</td></tr>
              <tr><td>Lock 2 years</td><td>&rarr; 0.50 veCMXS per CMXS (50% voting weight)</td></tr>
              <tr><td>Lock 4 years</td><td>&rarr; 1.00 veCMXS per CMXS (Full voting weight + full fee share)</td></tr>
            </table>
            <p class="mt-3"><strong>Your rights:</strong> Vote on all network parameters. Receive 50% of protocol fee income (paid in USDC). Priority access to new node geography allocations. Propose Ecosystem Grant distributions.</p>
            <p class="stake-who"><strong>Who is this for?</strong> Long-term token holders &middot; Crypto funds &middot; DePIN investors &middot; Strategic partners</p>
          </div>
        </div>
      </div>
    </div>
  `;
})();
