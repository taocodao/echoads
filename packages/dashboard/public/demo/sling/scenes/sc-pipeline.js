window.SlingScenes = window.SlingScenes || {};
window.SlingScenes['sc-pipeline'] = function() {
  setTimeout(() => {
    document.getElementById('browser-url-text').textContent = 'https://echoads.tv/architecture';
    
    // Animation logic synced with audio (or auto-play if no audio)
    window.onSlingAudioTimeUpdate = function(time, key) {
      if (key !== 's02') return;
      
      const steps = document.querySelectorAll('.pipeline-step');
      const lines = document.querySelectorAll('.pipeline-line-fill');
      
      const timings = [
        8.5,  // Step 1: SCTE-35 Detection
        13.5, // Step 2: Auction
        19.0, // Step 3: VAST Fetch
        23.5, // Step 4: MoQ Delivery
        29.0, // Step 5: PoD Receipt
        32.5, // Step 6: On-Chain Proof
        37.5  // Step 7: CMXS Reward
      ];
      
      for (let i = 0; i < steps.length; i++) {
        if (time > timings[i]) {
          steps[i].classList.add('active');
          if (i > 0) lines[i-1].style.width = '100%';
        }
      }
    };
  }, 10);
  
  return `
    <div class="sling-scene" style="padding:24px;">
      <div class="scene-strip" style="margin-bottom:18px">
        <span class="scene-badge">Phase 2</span>
        <span class="scene-title">The Pipeline</span>
      </div>
      
      <div style="font-size:14px;color:var(--muted);margin-bottom:40px;text-align:center;">
        EchoAds runs as transparent middleware between the Sling Freestream origin and the viewer's device.
      </div>
      
      <div class="pipeline-flow">
        <div class="pipeline-line">
          <div class="pipeline-line-fill" style="width:0%;"></div>
        </div>
        
        <div class="pipeline-step" id="pl-step-1">
          <div class="pipeline-icon">📡</div>
          <div class="pipeline-title">SCTE-35<br>Detection</div>
        </div>
        <div class="pipeline-step" id="pl-step-2">
          <div class="pipeline-icon">⚡</div>
          <div class="pipeline-title">OpenRTB<br>Auction</div>
        </div>
        <div class="pipeline-step" id="pl-step-3">
          <div class="pipeline-icon">📄</div>
          <div class="pipeline-title">VAST<br>Fetch</div>
        </div>
        <div class="pipeline-step" id="pl-step-4">
          <div class="pipeline-icon">🚀</div>
          <div class="pipeline-title">MoQ<br>Delivery</div>
        </div>
        <div class="pipeline-step" id="pl-step-5">
          <div class="pipeline-icon">🔐</div>
          <div class="pipeline-title">PoD<br>Receipt</div>
        </div>
        <div class="pipeline-step" id="pl-step-6">
          <div class="pipeline-icon">⛓</div>
          <div class="pipeline-title">On-Chain<br>Proof</div>
        </div>
        <div class="pipeline-step" id="pl-step-7">
          <div class="pipeline-icon">💎</div>
          <div class="pipeline-title">CMXS<br>Reward</div>
        </div>
      </div>
      
      <div style="display:grid;grid-template-columns:1fr 1fr;gap:20px;margin-top:50px;">
        <div style="background:var(--surface);border:1px solid var(--border);border-radius:8px;padding:16px;">
          <div style="font-size:12px;font-weight:700;color:var(--cyan);margin-bottom:8px;">Middleware Proxy</div>
          <div style="font-size:11px;color:var(--muted);">Intercepts HLS manifest, detects SCTE-35 tags, and triggers real-time auction before the ad segment plays.</div>
        </div>
        <div style="background:var(--surface);border:1px solid var(--border);border-radius:8px;padding:16px;">
          <div style="font-size:12px;font-weight:700;color:var(--green);margin-bottom:8px;">Delivery Oracle</div>
          <div style="font-size:11px;color:var(--muted);">Verifies cryptographic receipt and submits transaction to Base L2, triggering node reward automatically.</div>
        </div>
      </div>
    </div>
  `;
};
