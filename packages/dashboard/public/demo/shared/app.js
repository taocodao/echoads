// shared/app.js — EchoAds demo shared logic
// Loaded by both live/index.html and presentation/index.html

(function () {
  'use strict';

  // ── State ────────────────────────────────────────────
  let impressionCount = 0;
  let totalUsdc = 0;
  let latencies = [];
  let blackInterval = null;
  let isBreakRunning = false;

  // ── Helpers ──────────────────────────────────────────
  function $(id) { return document.getElementById(id); }

  function genTxHash() {
    return '0x' + Array.from({ length: 40 }, () =>
      '0123456789abcdef'[Math.floor(Math.random() * 16)]
    ).join('');
  }

  // ── Tab switching ────────────────────────────────────
  function switchTab(name) {
    document.querySelectorAll('.product-tab').forEach(function(t) { t.classList.remove('active-tab'); });
    document.querySelectorAll('.nav-link').forEach(function(l) { l.classList.remove('active'); });
    var tab = $('tab-' + name);
    if (tab) tab.classList.add('active-tab');
    // Support both /live/ (nav-{name}) and /presentation/ (nav-{name}-pres) ID patterns
    var link = $('nav-' + name) || $('nav-' + name + '-pres');
    if (link) link.classList.add('active');
    if (name === 'benchmark') {
      setTimeout(animateBenchmarkBars, 300);
    }
  }

  // ── Impression feed ──────────────────────────────────
  function addImpression(latencyMs) {
    impressionCount++;
    totalUsdc += 0.0001;
    latencies.push(latencyMs);
    const avg = Math.round(latencies.reduce((a, b) => a + b, 0) / latencies.length);

    // Stat cards
    if ($('stat-impressions')) $('stat-impressions').textContent = impressionCount;
    if ($('stat-usdc')) $('stat-usdc').textContent = '$' + totalUsdc.toFixed(4);
    if ($('stat-latency')) $('stat-latency').textContent = avg + 'ms';
    if ($('stat-sla')) $('stat-sla').textContent = '100%';

    // Node tab
    if ($('node-cmxs')) $('node-cmxs').textContent = (impressionCount * 0.01).toFixed(3);
    if ($('node-sla')) $('node-sla').textContent = '100%';
    if ($('node-del')) $('node-del').textContent = impressionCount;

    // Remove empty state
    const empty = $('imp-empty');
    if (empty) empty.remove();

    // Add row
    const txHash = genTxHash();
    const ts = new Date().toLocaleTimeString();
    const slotId = 'slot-' + Date.now().toString().slice(-9);
    const row = document.createElement('div');
    row.className = 'imp-row';
    row.innerHTML =
      '<div class="imp-row-top">' +
        '<span class="imp-id">' + slotId + '</span>' +
        '<span class="imp-time">' + ts + '</span>' +
      '</div>' +
      '<div class="imp-meta">' +
        '<div><div class="imp-meta-label">Latency</div><div class="imp-meta-value good">' + latencyMs + 'ms ✅</div></div>' +
        '<div><div class="imp-meta-label">Payment</div><div class="imp-meta-value paid">$0.0001 USDC ✅</div></div>' +
        '<div><div class="imp-meta-label">SLA</div><div class="imp-meta-value good">Met ✅</div></div>' +
      '</div>' +
      '<div class="imp-tx">' +
        '<span>' + txHash.slice(0, 18) + '...</span>' +
        '<a class="tx-link" href="https://sepolia.basescan.org/address/0x0e2af6786E207560De979eF5bAB07b5796DB9B2a" target="_blank" rel="noopener">Basescan ↗</a>' +
      '</div>';
    const feed = $('imp-feed');
    if (feed) feed.prepend(row);
  }

  // ── Ad break animation ───────────────────────────────
  function triggerAdBreak() {
    if (isBreakRunning) return Promise.resolve();
    isBreakRunning = true;

    return new Promise(function (resolve) {
      const hlsBlack = $('hls-black');
      const moqAd    = $('moq-ad');
      const hlsBadge = $('hls-badge');
      const moqBadge = $('moq-badge');
      const hlsTimer = $('hls-timer');

      // Show overlays
      if (hlsBlack) hlsBlack.classList.remove('hidden');
      if (moqAd)    moqAd.classList.remove('hidden');
      if (hlsBadge) hlsBadge.classList.remove('show');
      if (moqBadge) moqBadge.classList.remove('show');

      // MOQ shows immediately
      if (moqBadge) setTimeout(() => moqBadge.classList.add('show'), 350);

      let elapsed = 0;
      clearInterval(blackInterval);
      blackInterval = setInterval(function () {
        elapsed += 80;
        if (hlsTimer) hlsTimer.textContent = (elapsed / 1000).toFixed(3) + 's';
        if (elapsed >= 3847) {
          clearInterval(blackInterval);
          if (hlsBlack) hlsBlack.classList.add('hidden');
          if (hlsBadge) hlsBadge.classList.add('show');
          setTimeout(function () {
            addImpression(287);
            isBreakRunning = false;
            resolve();
          }, 500);
        }
      }, 80);
    });
  }

  function resetPlayers() {
    isBreakRunning = false;
    clearInterval(blackInterval);
    ['hls-black', 'hls-badge', 'moq-ad', 'moq-badge'].forEach(function (id) {
      const el = $(id);
      if (!el) return;
      el.classList.add('hidden');
      el.classList.remove('show');
    });
  }

  // ── Benchmark ────────────────────────────────────────
  var BENCH_DATA = [
    { p: 'P50 (Median)',        moq: '243ms',     hls: '3,200ms', mw: 24,  hw: 100 },
    { p: 'P95 (95th Pct) ✅',   moq: '312ms',     hls: '4,100ms', mw: 31,  hw: 100 },
    { p: 'P99 (99th Pct)',      moq: '487ms',     hls: '7,800ms', mw: 48,  hw: 100 }
  ];

  function buildBenchmarkHTML() {
    const container = $('benchmark-chart');
    if (!container) return;
    var html = '';
    BENCH_DATA.forEach(function (r) {
      html +=
        '<div class="bench-row">' +
          '<span class="bench-label-name">' + r.p + '</span>' +
          '<div class="bench-cols">' +
            '<div>' +
              '<div class="bench-col-label moq">EchoAds MOQ/QUIC</div>' +
              '<div class="bench-bar-wrap"><div class="bench-bar moq-bar" data-w="' + r.mw + '">' + r.moq + '</div></div>' +
            '</div>' +
            '<div>' +
              '<div class="bench-col-label hls">Current Sling HLS</div>' +
              '<div class="bench-bar-wrap"><div class="bench-bar hls-bar" data-w="' + r.hw + '">' + r.hls + '</div></div>' +
            '</div>' +
          '</div>' +
        '</div>';
    });
    container.innerHTML = html;
  }

  function animateBenchmarkBars() {
    document.querySelectorAll('.bench-bar').forEach(function (b) {
      b.style.width = (b.dataset.w || 0) + '%';
    });
  }

  // ── Full reset ───────────────────────────────────────
  function resetAll() {
    impressionCount = 0;
    totalUsdc = 0;
    latencies = [];
    resetPlayers();
    ['stat-impressions','stat-usdc','stat-latency','stat-sla'].forEach(function(id) {
      var el = $(id);
      if (el) el.textContent = (id === 'stat-impressions' ? '0' : id === 'stat-usdc' ? '$0.0000' : '—');
    });
    if ($('node-cmxs')) $('node-cmxs').textContent = '0.000';
    if ($('node-sla'))  $('node-sla').textContent = '—';
    if ($('node-del'))  $('node-del').textContent = '0';
    var feed = $('imp-feed');
    if (feed) feed.innerHTML = '<div class="imp-empty" id="imp-empty">Waiting for first impression…</div>';
    document.querySelectorAll('.bench-bar').forEach(function(b) { b.style.width = '0%'; });
    switchTab('advertiser');
  }

  // ── Expose globally ──────────────────────────────────
  window.EchoApp = {
    switchTab: switchTab,
    triggerAdBreak: triggerAdBreak,
    addImpression: addImpression,
    resetAll: resetAll,
    buildBenchmarkHTML: buildBenchmarkHTML,
    animateBenchmarkBars: animateBenchmarkBars,
    genTxHash: genTxHash
  };

})();
