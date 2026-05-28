window.SlingScenes = window.SlingScenes || {};
window.SlingScenes['sc-scte35'] = function() {
  setTimeout(() => {
    document.getElementById('browser-url-text').textContent = 'https://echoads.tv/proxy/manifest.m3u8';
    
    // Typewriter effect
    const lines = document.querySelectorAll('.code-line');
    let delay = 0;
    lines.forEach((line, i) => {
      setTimeout(() => {
        line.style.display = 'block';
        if (line.classList.contains('code-highlight')) {
          line.style.animation = 'glow-pulse 1s';
        }
      }, delay);
      delay += (i > 5 && i < 10) ? 600 : 150; // Pause around SCTE-35 markers
    });
    
    // Counter animation for detection latency
    setTimeout(() => {
      const el = document.getElementById('detect-latency');
      if (el) {
        let count = 0;
        const iv = setInterval(() => {
          count += 13;
          if (count >= 147) {
            count = 147;
            clearInterval(iv);
          }
          el.textContent = count + 'ms';
        }, 50);
      }
    }, 4000);
  }, 10);
  
  return `
    <div class="sling-scene">
      <div class="scene-strip" style="margin-bottom:18px;display:flex;align-items:center;gap:10px;">
        <span class="scene-badge">Phase 3</span>
        <span class="scene-title">SCTE-35 Interception</span>
      </div>
      
      <div class="code-viewer">
        <span class="code-line" style="display:none;">#EXTM3U</span>
        <span class="code-line" style="display:none;">#EXT-X-VERSION:7</span>
        <span class="code-line" style="display:none;">#EXT-X-TARGETDURATION:6</span>
        <span class="code-line" style="display:none;">#EXTINF:6.000,</span>
        <span class="code-line" style="display:none;">segment_1047.ts</span>
        <span class="code-line" style="display:none;">#EXTINF:6.000,</span>
        <span class="code-line" style="display:none;">segment_1048.ts</span>
        <span class="code-line code-highlight" style="display:none;">#EXT-X-CUE-OUT:DURATION=30.0     <span style="color:var(--green)">← DETECTED</span></span>
        <span class="code-line code-highlight" style="display:none;">#EXT-X-DATERANGE:SCTE35-OUT=0xFC...</span>
        <span class="code-line" style="display:none;">#EXTINF:6.000,</span>
        <span class="code-line" style="display:none;">ad_segment_001.ts                <span style="color:var(--cyan)">← CMXS AUCTION TRIGGERED</span></span>
        <span class="code-line" style="display:none;">#EXT-X-CUE-IN                    <span style="color:var(--muted)">← RETURN TO CONTENT</span></span>
        <span class="code-line" style="display:none;">#EXTINF:6.000,</span>
        <span class="code-line" style="display:none;">segment_1049.ts</span>
      </div>
      
      <div style="font-size:12px;color:var(--muted);line-height:1.6;padding:12px;background:var(--surface);border:1px solid var(--border);border-radius:8px;margin-top:16px;">
        The CMXS middleware proxy intercepts the HLS manifest, detects SCTE-35 <code>CUE-OUT</code> markers, and triggers a real-time auction before the ad segment needs to play.
      </div>
      
      <div class="detection-stat">
        <div>
          <div style="color:var(--cyan);font-weight:700;" id="detect-latency">0ms</div>
          <div style="color:var(--muted);font-size:10px;">Detection Latency</div>
        </div>
        <div>
          <div style="color:var(--text);font-weight:700;">splice_insert (0x05)</div>
          <div style="color:var(--muted);font-size:10px;">SCTE-35 Command</div>
        </div>
        <div>
          <div style="color:var(--text);font-weight:700;">30 seconds</div>
          <div style="color:var(--muted);font-size:10px;">Break Duration</div>
        </div>
      </div>
    </div>
  `;
};
