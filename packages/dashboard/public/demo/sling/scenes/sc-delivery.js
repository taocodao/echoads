window.SlingScenes = window.SlingScenes || {};
window.SlingScenes['sc-delivery'] = function() {
  // Logic is triggered from sling.js runStep via EchoApp
  
  return `
    <div class="sling-scene">
      <div class="scene-strip" style="margin-bottom:18px;display:flex;align-items:center;gap:10px;">
        <span class="scene-badge">Phase 5</span>
        <span class="scene-title">MoQ Delivery</span>
      </div>
      
      <div class="player-container" style="margin-bottom:24px;">
        <div class="player-pane hls-pane">
          <div class="player-label">⚠ HLS / TCP — Current Sling TV</div>
          <div class="player-screen">
            <div class="video-bars"></div>
            <div class="content-overlay">
              <div class="content-icon">⚽</div>
              <div class="content-title">UEFA Champions League</div>
              <div class="content-sub">HLS Stream · TCP</div>
            </div>
            <div class="black-screen hidden" id="hls-black">
              <div class="black-screen-text">BUFFERING…</div>
              <div class="black-timer" id="hls-timer">0.000s</div>
              <div style="font-size:10px;color:#444;margin-top:4px">TCP reconnect · waiting for segment</div>
            </div>
            <div class="latency-badge bad" id="hls-badge">⚠ Segment load: 3,847ms (HLS baseline)</div>
          </div>
        </div>
        
        <div class="player-pane moq-pane">
          <div class="player-label">✅ MOQ / QUIC — EchoAds</div>
          <div class="player-screen">
            <div class="video-bars green-bars"></div>
            <div class="content-overlay">
              <div class="content-icon">⚽</div>
              <div class="content-title">UEFA Champions League</div>
              <div class="content-sub">MOQ/QUIC · 54.80.47.153:4443</div>
            </div>
            <div class="ad-overlay hidden" id="moq-ad">
              <div class="ad-badge">AD PLAYING</div>
              <div style="font-size:11px;color:rgba(255,255,255,.6);margin-top:4px">Track switched · QUIC</div>
              <div class="ad-switch-time">287ms</div>
            </div>
            <div class="latency-badge good" id="moq-badge">✅ Track switch: 287ms · SLA Met</div>
          </div>
        </div>
      </div>
      
      <div class="bench-summary" style="padding:16px;background:var(--surface);border-radius:8px;border:1px solid var(--border);">
        <span style="font-size:20px;font-weight:900;color:var(--green)">13× faster</span>
        <span style="color:var(--muted);font-size:13px"> at P95 · </span>
        <span style="font-size:13px;color:var(--cyan);font-weight:600">Clears 500ms sports-betting regulatory threshold ✅</span>
      </div>
    </div>
  `;
};
