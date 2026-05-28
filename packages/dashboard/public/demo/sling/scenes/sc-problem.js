window.SlingScenes = window.SlingScenes || {};
window.SlingScenes['sc-problem'] = function() {
  setTimeout(() => {
    document.getElementById('browser-url-text').textContent = 'https://sling.com/freestream';
  }, 10);
  
  return `
    <div class="sling-scene" style="padding:24px;">
      <div class="scene-strip" style="margin-bottom:18px">
        <span class="scene-badge">Phase 1</span>
        <span class="scene-title">The Problem</span>
      </div>
      
      <div class="slide-cols">
        <div class="slide-problem">
          <div style="font-size:14px;font-weight:700;color:var(--text);margin-bottom:16px;">What Happens Today (HLS/TCP)</div>
          
          <div style="background:rgba(255,59,92,.08);border-radius:8px;padding:16px;margin-bottom:12px;text-align:center;">
            <div class="stat-large red">$84B</div>
            <div style="font-size:12px;color:var(--muted)">Annual ad fraud globally (ANA 2025)</div>
          </div>
          
          <div style="background:rgba(255,59,92,.08);border-radius:8px;padding:16px;margin-bottom:12px;text-align:center;">
            <div class="stat-large red">30%</div>
            <div style="font-size:12px;color:var(--muted)">CTV inventory never seen by real viewer<br><span style="color:var(--amber)">— Morgan Stanley</span></div>
          </div>
          
          <div style="background:rgba(255,170,0,.08);border-radius:8px;padding:16px;margin-bottom:16px;text-align:center;">
            <div class="stat-large amber">3.8 seconds</div>
            <div style="font-size:12px;color:var(--muted)">Average black screen during ad breaks</div>
          </div>
          
          <div style="font-size:12px;color:var(--muted);line-height:1.6;padding:12px;background:var(--surface);border:1px solid var(--border);border-radius:8px;">
            Sling Freestream runs 600 FAST channels through open exchanges. No cryptographic delivery proof. Advertisers pay for impressions they cannot verify.
          </div>
        </div>
        
        <div class="slide-solution">
          <div style="font-size:14px;font-weight:700;color:var(--text);margin-bottom:16px;">What EchoAds Changes</div>
          
          <div style="background:rgba(0,232,122,.08);border-radius:8px;padding:16px;margin-bottom:12px;text-align:center;">
            <div class="stat-large green">287ms</div>
            <div style="font-size:12px;color:var(--muted)">Ad switch via MoQ/QUIC — zero black screen</div>
          </div>
          
          <div style="background:rgba(0,232,122,.08);border-radius:8px;padding:16px;margin-bottom:12px;text-align:center;">
            <div class="stat-large green">100%</div>
            <div style="font-size:12px;color:var(--muted)">Impressions with on-chain cryptographic receipt</div>
          </div>
          
          <div style="background:rgba(6,182,212,.08);border-radius:8px;padding:16px;margin-bottom:16px;text-align:center;">
            <div class="stat-large cyan">$0.0001</div>
            <div style="font-size:12px;color:var(--muted)">Per-transaction cost on Base L2</div>
          </div>
          
          <div style="font-size:12px;color:var(--muted);line-height:1.6;padding:12px;background:var(--surface);border:1px solid var(--border);border-radius:8px;">
            Every ad delivery generates an immutable blockchain receipt. Not self-reported. Cryptographic fact.
          </div>
        </div>
      </div>
    </div>
  `;
};
