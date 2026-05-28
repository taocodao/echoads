window.SlingScenes = window.SlingScenes || {};
window.SlingScenes['sc-proof'] = function() {
  setTimeout(() => {
    document.getElementById('browser-url-text').textContent = 'https://sepolia.basescan.org/tx/0x7a3f8b2c4e91';
    
    // Animate status
    setTimeout(() => {
      const statusEl = document.getElementById('tx-status');
      if (statusEl) {
        statusEl.innerHTML = '✅ Success';
        statusEl.style.color = 'var(--green)';
      }
      
      // Reveal event logs
      const logs = document.querySelectorAll('.log-row');
      logs.forEach((log, i) => {
        setTimeout(() => {
          log.style.opacity = '1';
          log.style.transform = 'translateX(0)';
        }, 500 + (i * 150));
      });
      
    }, 1500);
  }, 10);
  
  return `
    <div class="sling-scene">
      <div class="scene-strip" style="margin-bottom:18px;display:flex;align-items:center;gap:10px;">
        <span class="scene-badge">Phase 6</span>
        <span class="scene-title">On-Chain Proof</span>
      </div>
      
      <div class="receipt-box">
        <div class="receipt-header">
          <div class="receipt-row">
            <div class="receipt-label">Transaction Hash:</div>
            <div class="receipt-value" style="color:var(--cyan)">0x7a3f8b2c89f1...4e91</div>
          </div>
          <div class="receipt-row">
            <div class="receipt-label">Status:</div>
            <div class="receipt-value" id="tx-status" style="color:var(--amber)">⏳ Pending</div>
          </div>
          <div class="receipt-row">
            <div class="receipt-label">Block:</div>
            <div class="receipt-value">18,247,391</div>
          </div>
          <div class="receipt-row">
            <div class="receipt-label">Timestamp:</div>
            <div class="receipt-value">Just now</div>
          </div>
          <div class="receipt-row">
            <div class="receipt-label">From:</div>
            <div class="receipt-value" style="color:var(--blue)">0x0e2af6786E207560De979eF5bAB07b5796DB9B2a (DeliveryOracle)</div>
          </div>
          <div class="receipt-row">
            <div class="receipt-label">To:</div>
            <div class="receipt-value" style="color:var(--blue)">0x9fEf4679BB07aa1B28a4e33330e1e38ADcfb7819 (CMXS Token)</div>
          </div>
          <div class="receipt-row">
            <div class="receipt-label">Value:</div>
            <div class="receipt-value">0 ETH</div>
          </div>
          <div class="receipt-row">
            <div class="receipt-label">Gas Used:</div>
            <div class="receipt-value">47,231 ($0.00008)</div>
          </div>
        </div>
        
        <div>
          <div style="font-weight:700;color:#fff;margin-bottom:12px;">Event Logs:</div>
          <div style="padding:12px;background:rgba(0,0,0,0.3);border-radius:6px;border:1px solid rgba(255,255,255,0.05);">
            <div style="color:var(--cyan);margin-bottom:8px;">AdDelivered (index_topic_1 bytes32 breakId, ...)</div>
            
            <div class="receipt-row log-row" style="opacity:0;transform:translateX(-10px);transition:all 0.3s ease;">
              <div class="receipt-label">breakId:</div>
              <div class="receipt-value">break_sling_demo_001</div>
            </div>
            <div class="receipt-row log-row" style="opacity:0;transform:translateX(-10px);transition:all 0.3s ease;">
              <div class="receipt-label">advertiserId:</div>
              <div class="receipt-value">draftkings-001</div>
            </div>
            <div class="receipt-row log-row" style="opacity:0;transform:translateX(-10px);transition:all 0.3s ease;">
              <div class="receipt-label">cpmUSDCents:</div>
              <div class="receipt-value green">4721</div>
            </div>
            <div class="receipt-row log-row" style="opacity:0;transform:translateX(-10px);transition:all 0.3s ease;">
              <div class="receipt-label">durationSec:</div>
              <div class="receipt-value">30</div>
            </div>
            <div class="receipt-row log-row" style="opacity:0;transform:translateX(-10px);transition:all 0.3s ease;">
              <div class="receipt-label">completion:</div>
              <div class="receipt-value">100%</div>
            </div>
            <div class="receipt-row log-row" style="opacity:0;transform:translateX(-10px);transition:all 0.3s ease;">
              <div class="receipt-label">cmxsBurned:</div>
              <div class="receipt-value" style="color:var(--red)">0.001415 CMXS</div>
            </div>
          </div>
        </div>
      </div>
      
      <div style="margin-top:16px;text-align:right;">
        <a href="https://sepolia.basescan.org/address/0x0e2af6786E207560De979eF5bAB07b5796DB9B2a" target="_blank" rel="noopener" class="btn-primary" style="text-decoration:none;font-size:12px;padding:6px 12px;display:inline-block;">Verify on Basescan ↗</a>
      </div>
    </div>
  `;
};
