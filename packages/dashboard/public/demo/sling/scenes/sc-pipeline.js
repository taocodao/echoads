window.SlingScenes = window.SlingScenes || {};
window.SlingScenes['sc-pipeline'] = function() {
  // Cancel any previous pipeline timer
  if (window._pipelineTimer) clearInterval(window._pipelineTimer);

  setTimeout(() => {
    var urlEl = document.getElementById('browser-url-text');
    if (urlEl) urlEl.textContent = 'https://echoads.tv/architecture';

    var steps = document.querySelectorAll('.pipeline-step');
    var lineFill = document.querySelector('.pipeline-line-fill');

    // Step timing in seconds — calibrated to sling-02.mp3 narration:
    var TIMESTAMPS = [
      9.6,   // Step 1: "Step one: the proxy detects..."
      17.7,  // Step 2: "Step two: it triggers..."
      28.2,  // Step 3: "Step three: the winning..."
      35.2,  // Step 4: "Step four: the ad segments..."
      46.3,  // Step 5: "Step five: the viewer's device..."
      51.8,  // Step 6: "Step six: the receipt is written..."
      58.3   // Step 7: "Step seven: the node operator..."
    ];

    var subtitles = [
      'Proxy detects SCTE-35 CUE-OUT marker in HLS manifest',
      'OpenRTB 2.6 bid request fanned out to DSPs — <100ms',
      "Winner's VAST 4.x creative fetched and validated",
      'Ad segments stitched and delivered via MoQ/QUIC — 287ms',
      'Viewer device signs cryptographic delivery receipt',
      'Receipt submitted to Base L2 blockchain — immutable',
      'Node operator receives 0.001 CMXS — automatic reward'
    ];

    var subtitleEl = document.getElementById('pipeline-subtitle');
    var lastActive = -1;

    function activateStep(i) {
      if (i === lastActive) return;
      lastActive = i;
      // Mark all previous as done
      for (var j = 0; j < i; j++) {
        if (steps[j]) { steps[j].classList.remove('active'); steps[j].classList.add('done'); }
      }
      // Activate current
      if (steps[i]) { steps[i].classList.add('active'); steps[i].classList.remove('done'); }

      // Advance the fill line proportionally
      if (lineFill) {
        var pct = Math.round((i / (steps.length - 1)) * 100);
        lineFill.style.width = pct + '%';
      }

      // Update subtitle
      if (subtitleEl && subtitles[i]) subtitleEl.textContent = subtitles[i];
    }

    // Audio-driven sync
    window.onSlingAudioTimeUpdate = function(time, stepKey) {
      if (stepKey !== 's02') return;
      var activeIdx = -1;
      for (var i = 0; i < TIMESTAMPS.length; i++) {
        if (time >= TIMESTAMPS[i]) activeIdx = i;
      }
      if (activeIdx >= 0) activateStep(activeIdx);

      if (time >= 65) {
        steps.forEach(function(s) { s.classList.remove('active'); s.classList.add('done'); });
        if (lineFill) lineFill.style.width = '100%';
        if (subtitleEl) subtitleEl.textContent = 'Pipeline complete — cryptographic proof on-chain ✅';
      }
    };

    // Fallback timer for TTS (where timeupdate isn't fired by audio element)
    var startTime = Date.now();
    window._pipelineTimer = setInterval(function() {
      // If native audio is playing, narrationAudio exists, so skip manual fallback
      if (window.narrationAudio) return; 
      var time = (Date.now() - startTime) / 1000;
      // TTS is usually faster, compress time slightly
      window.onSlingAudioTimeUpdate(time * 1.15, 's02'); 
    }, 200);

  }, 50);

  return `
    <div class="sling-scene">
      <div class="scene-strip" style="margin-bottom:18px;display:flex;align-items:center;gap:10px;">
        <span class="scene-badge">Phase 2</span>
        <span class="scene-title">The Pipeline</span>
      </div>

      <p style="font-size:13px;color:var(--muted);margin-bottom:32px;line-height:1.6;">
        EchoAds runs as transparent middleware between the Sling Freestream origin and the viewer's device.
      </p>

      <!-- Pipeline diagram -->
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

      <!-- Step subtitle -->
      <div style="text-align:center;margin-top:24px;min-height:36px;">
        <span id="pipeline-subtitle" style="font-size:13px;color:var(--cyan);font-weight:600;transition:opacity .3s ease;">
          Waiting for pipeline to start…
        </span>
      </div>

      <!-- Info boxes -->
      <div style="display:grid;grid-template-columns:1fr 1fr;gap:16px;margin-top:24px;">
        <div style="background:var(--surface);border:1px solid rgba(0,212,255,.25);border-radius:8px;padding:16px;">
          <div style="font-size:12px;font-weight:700;color:var(--cyan);margin-bottom:8px;">Middleware Proxy</div>
          <div style="font-size:11px;color:var(--muted);line-height:1.6;">Intercepts HLS manifest, detects SCTE-35 tags, and triggers real-time auction before the ad segment plays.</div>
        </div>
        <div style="background:var(--surface);border:1px solid rgba(0,232,122,.25);border-radius:8px;padding:16px;">
          <div style="font-size:12px;font-weight:700;color:var(--green);margin-bottom:8px;">Delivery Oracle</div>
          <div style="font-size:11px;color:var(--muted);line-height:1.6;">Verifies cryptographic receipt and submits transaction to Base L2, triggering node reward automatically.</div>
        </div>
      </div>
    </div>
  `;
};
