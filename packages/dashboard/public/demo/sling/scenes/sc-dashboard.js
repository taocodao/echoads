window.SlingScenes = window.SlingScenes || {};
window.SlingScenes['sc-dashboard'] = function() {
  setTimeout(() => {
    document.getElementById('browser-url-text').textContent = 'https://echoads.tv/dashboard/advertiser';
  }, 10);
  
  return `
    <div class="sling-scene" style="padding:24px;">
      <div class="scene-strip" style="margin-bottom:18px">
        <span class="scene-badge">Phase 7</span>
        <span class="scene-title">Advertiser Dashboard</span>
      </div>
      
      <div class="product-inner" style="background:var(--bg);padding:16px;border-radius:12px;border:1px solid var(--border);">
        <div class="stat-row" style="margin-bottom:16px;">
          <div class="stat-card"><div class="stat-label">Total Impressions</div><div class="stat-val" id="stat-impressions">3</div></div>
          <div class="stat-card"><div class="stat-label">USDC Settled</div><div class="stat-val" id="stat-usdc">$0.0003</div></div>
          <div class="stat-card"><div class="stat-label">Avg Latency</div><div class="stat-val" id="stat-latency">289ms</div></div>
          <div class="stat-card"><div class="stat-label">SLA Pass Rate</div><div class="stat-val" id="stat-sla">100%</div></div>
        </div>
        
        <div class="dashboard-grid">
          <div style="flex:1;">
            <div class="feed-label">On-Chain Impression Feed</div>
            <div class="imp-feed" id="imp-feed" style="max-height:240px;overflow:hidden;">
              <div class="imp-row">
                <div class="imp-row-top">
                  <span class="imp-id">slot-2983719</span>
                  <span class="imp-time">Just now</span>
                </div>
                <div class="imp-meta">
                  <div><div class="imp-meta-label">Latency</div><div class="imp-meta-value good">291ms ✅</div></div>
                  <div><div class="imp-meta-label">Payment</div><div class="imp-meta-value paid">$0.0001 USDC ✅</div></div>
                  <div><div class="imp-meta-label">SLA</div><div class="imp-meta-value good">Met ✅</div></div>
                </div>
                <div class="imp-tx">
                  <span>0x3b8f2...</span>
                  <a class="tx-link" href="#" style="pointer-events:none;">Basescan ↗</a>
                </div>
              </div>
              <div class="imp-row">
                <div class="imp-row-top">
                  <span class="imp-id">slot-9928312</span>
                  <span class="imp-time">1 min ago</span>
                </div>
                <div class="imp-meta">
                  <div><div class="imp-meta-label">Latency</div><div class="imp-meta-value good">284ms ✅</div></div>
                  <div><div class="imp-meta-label">Payment</div><div class="imp-meta-value paid">$0.0001 USDC ✅</div></div>
                  <div><div class="imp-meta-label">SLA</div><div class="imp-meta-value good">Met ✅</div></div>
                </div>
                <div class="imp-tx">
                  <span>0x9c2a1...</span>
                  <a class="tx-link" href="#" style="pointer-events:none;">Basescan ↗</a>
                </div>
              </div>
              <div class="imp-row">
                <div class="imp-row-top">
                  <span class="imp-id">slot-4412998</span>
                  <span class="imp-time">3 mins ago</span>
                </div>
                <div class="imp-meta">
                  <div><div class="imp-meta-label">Latency</div><div class="imp-meta-value good">292ms ✅</div></div>
                  <div><div class="imp-meta-label">Payment</div><div class="imp-meta-value paid">$0.0001 USDC ✅</div></div>
                  <div><div class="imp-meta-label">SLA</div><div class="imp-meta-value good">Met ✅</div></div>
                </div>
                <div class="imp-tx">
                  <span>0x1f7b8...</span>
                  <a class="tx-link" href="#" style="pointer-events:none;">Basescan ↗</a>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  `;
};
