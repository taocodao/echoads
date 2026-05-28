window.SlingScenes = window.SlingScenes || {};
window.SlingScenes['sc-scale'] = function() {
  setTimeout(() => {
    document.getElementById('browser-url-text').textContent = 'https://echoads.tv/opportunity';
    
    // Animate table rows
    const rows = document.querySelectorAll('.slide-table tbody tr');
    rows.forEach((row, i) => {
      setTimeout(() => {
        row.style.opacity = '1';
        row.style.transform = 'translateX(0)';
      }, 500 + (i * 200));
    });
    
    // Animate revenue number
    setTimeout(() => {
      const revEl = document.getElementById('rev-num');
      if (revEl) {
        let rev = 0;
        const iv = setInterval(() => {
          rev += 15;
          if (rev >= 360) {
            rev = 360;
            clearInterval(iv);
          }
          revEl.textContent = '+$' + rev + 'M/year';
        }, 30);
      }
    }, 1500);
  }, 10);
  
  return `
    <div class="sling-scene" style="padding:24px;">
      <div class="scene-strip" style="margin-bottom:18px">
        <span class="scene-badge">Phase 8</span>
        <span class="scene-title">Scale & Revenue</span>
      </div>
      
      <table class="slide-table" style="margin-bottom:24px;width:100%;">
        <thead>
          <tr>
            <th style="text-align:left;padding-bottom:12px;border-bottom:1px solid rgba(255,255,255,0.1);">Problem</th>
            <th style="text-align:left;padding-bottom:12px;border-bottom:1px solid rgba(255,255,255,0.1);">Current State</th>
            <th style="text-align:left;padding-bottom:12px;border-bottom:1px solid rgba(255,255,255,0.1);">With EchoAds</th>
          </tr>
        </thead>
        <tbody>
          <tr style="opacity:0;transform:translateX(-20px);transition:all 0.4s ease;">
            <td style="padding:12px 0;border-bottom:1px solid rgba(255,255,255,0.05);">Ad fraud / no proof</td>
            <td style="padding:12px 0;border-bottom:1px solid rgba(255,255,255,0.05);color:var(--red);">30% unseen &middot; $18–30 CPM</td>
            <td style="padding:12px 0;border-bottom:1px solid rgba(255,255,255,0.05);color:var(--green);">On-chain receipt &middot; $45–65 CPM</td>
          </tr>
          <tr style="opacity:0;transform:translateX(-20px);transition:all 0.4s ease;">
            <td style="padding:12px 0;border-bottom:1px solid rgba(255,255,255,0.05);">FAST fill rate (~38%)</td>
            <td style="padding:12px 0;border-bottom:1px solid rgba(255,255,255,0.05);color:var(--red);">$650M/yr unmonetized</td>
            <td style="padding:12px 0;border-bottom:1px solid rgba(255,255,255,0.05);color:var(--green);">Per-impression x402 auction</td>
          </tr>
          <tr style="opacity:0;transform:translateX(-20px);transition:all 0.4s ease;">
            <td style="padding:12px 0;border-bottom:1px solid rgba(255,255,255,0.05);">5,800 sites earn $0</td>
            <td style="padding:12px 0;border-bottom:1px solid rgba(255,255,255,0.05);color:var(--red);">Flat lease only</td>
            <td style="padding:12px 0;border-bottom:1px solid rgba(255,255,255,0.05);color:var(--green);">0.001 CMXS/delivery &middot; ~$30M/yr</td>
          </tr>
          <tr style="opacity:0;transform:translateX(-20px);transition:all 0.4s ease;">
            <td style="padding:12px 0;border-bottom:1px solid rgba(255,255,255,0.05);">Sports betting locked out</td>
            <td style="padding:12px 0;border-bottom:1px solid rgba(255,255,255,0.05);color:var(--red);">$45B market &middot; $0 revenue</td>
            <td style="padding:12px 0;border-bottom:1px solid rgba(255,255,255,0.05);color:var(--green);">312ms P95 clears 500ms threshold</td>
          </tr>
        </tbody>
      </table>
      
      <div class="scale-revenue">
        <div class="scale-revenue-num" id="rev-num">+$0M/year</div>
        <div style="font-size:16px;color:var(--text);margin-top:8px;">Same inventory. Same viewers. Just proof.</div>
      </div>
      
      <div style="padding:16px;background:rgba(0,170,255,.05);border:1px solid rgba(0,170,255,.2);border-radius:12px;text-align:center;">
        <div style="font-size:14px;font-weight:700;margin-bottom:8px;color:var(--text);">Infrastructure live at echoads.tv</div>
        <div style="font-size:12px;color:var(--muted);margin-bottom:12px;">Both contracts verifiable on Base Sepolia</div>
        <div>
          <a href="#" class="btn-primary" style="text-decoration:none;font-size:11px;padding:4px 10px;margin-right:8px;display:inline-block;pointer-events:none;">DeliveryOracle ↗</a>
          <a href="#" class="btn-primary" style="text-decoration:none;font-size:11px;padding:4px 10px;display:inline-block;pointer-events:none;">CMXS Token ↗</a>
        </div>
      </div>
    </div>
  `;
};
