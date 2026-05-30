// simulation.js — AntiGravity demo shared simulation engine
// Produces identical outputs to real contract calls — no network required

(function () {
  'use strict';

  // ── DSP Profiles ─────────────────────────────────────────────────────────
  var DSP_PROFILES = [
    { id: 'dsp-sports',     name: 'SportsPremium DSP',  color: '#f59e0b', baseMulti: 1.9, sportsBias: 0.6 },
    { id: 'dsp-brand',      name: 'BrandSafe DSP',      color: '#3b82f6', baseMulti: 1.3, sportsBias: 0.0 },
    { id: 'dsp-retarget',   name: 'Retargeting DSP',    color: '#8b5cf6', baseMulti: 1.6, sportsBias: 0.2 },
    { id: 'dsp-local',      name: 'Local Advertiser',   color: '#10b981', baseMulti: 1.1, sportsBias: 0.0 },
    { id: 'dsp-programmatic',name: 'ProgrammaticIO',    color: '#06b6d4', baseMulti: 1.25, sportsBias: 0.1 }
  ];

  // ── Utility ───────────────────────────────────────────────────────────────
  function rand(min, max) { return Math.random() * (max - min) + min; }
  function randInt(min, max) { return Math.floor(rand(min, max + 1)); }
  function fmt2(n) { return n.toFixed(2); }

  function genHash(len) {
    len = len || 64;
    var h = '0x';
    var chars = '0123456789abcdef';
    for (var i = 0; i < len; i++) h += chars[Math.floor(Math.random() * 16)];
    return h;
  }

  function genImpressionId() {
    return '0x' + Date.now().toString(16).padStart(16, '0') +
      Math.floor(Math.random() * 0xffffffff).toString(16).padStart(8, '0') +
      Math.floor(Math.random() * 0xffffffff).toString(16).padStart(8, '0');
  }

  function wait(ms) { return new Promise(function (r) { setTimeout(r, ms); }); }

  // ── Step 1: Generate DSP Bids ─────────────────────────────────────────────
  function generateBids(opts) {
    opts = opts || {};
    var floorCpm  = opts.floorCpm  || 15.00;
    var channel   = opts.channel   || 'sports/live';
    var isSports  = channel.indexOf('sports') !== -1 || channel.indexOf('live') !== -1;
    var auctionMs = randInt(45, 85);

    var bids = DSP_PROFILES.map(function (dsp) {
      var bias = isSports ? dsp.sportsBias : 0;
      var multi = dsp.baseMulti + bias + rand(-0.15, 0.15);
      var price = parseFloat(fmt2(floorCpm * multi));
      var won   = false;
      return {
        dspId:       dsp.id,
        dspName:     dsp.name,
        color:       dsp.color,
        price:       price,
        aboveFloor:  price >= floorCpm,
        adId:        'creative-' + dsp.id.split('-')[1] + '-001',
        advertiserId: genHash(40)
      };
    });

    return { bids: bids, floorCpm: floorCpm, auctionLatencyMs: auctionMs };
  }

  // ── Step 2: Run Second-Price Auction ──────────────────────────────────────
  function runAuction(bids, floorCpm) {
    var eligible = bids.filter(function (b) { return b.aboveFloor; });
    eligible.sort(function (a, b) { return b.price - a.price; });
    if (eligible.length === 0) return null;

    var winner     = eligible[0];
    var clearPrice = eligible.length > 1
      ? parseFloat(fmt2(eligible[1].price + 0.01))
      : parseFloat(fmt2(floorCpm + 0.01));

    return {
      winner:        winner,
      clearPrice:    clearPrice,
      allBids:       eligible,
      slotId:        'slot-' + Date.now().toString().slice(-9),
      impressionId:  genImpressionId()
    };
  }

  // ── Step 3: Simulate MoQ Delivery ─────────────────────────────────────────
  var LATENCY_DIST = [
    { p: 0.50, moq: 243, hls: 3200 },
    { p: 0.95, moq: 312, hls: 4100 },
    { p: 0.99, moq: 487, hls: 7800 }
  ];

  function simulateDelivery() {
    var r = Math.random();
    var bucket = r < 0.50 ? 0 : r < 0.95 ? 1 : 2;
    var d = LATENCY_DIST[bucket];
    var moqMs = randInt(d.moq - 20, d.moq + 20);
    var hlsMs = randInt(d.hls - 200, d.hls + 400);
    return {
      moqLatencyMs:  moqMs,
      hlsLatencyMs:  hlsMs,
      slaMet:        moqMs < 500,
      percentile:    bucket === 0 ? 'P50' : bucket === 1 ? 'P95' : 'P99',
      nodeId:        'relay-echostar-us-east-1',
      nodeAddress:   '0x' + 'EchoNode'.split('').map(function(c){return c.charCodeAt(0).toString(16)}).join('').padEnd(40,'0')
    };
  }

  // ── Step 4: Ad Watch ──────────────────────────────────────────────────────
  function simulateAdWatch() {
    var viewDuration = randInt(25000, 31000);
    var completed    = viewDuration >= 30000;
    var interacted   = Math.random() > 0.6;
    return { viewDurationMs: viewDuration, completed: completed, interacted: interacted };
  }

  // ── Step 5: PoD Signing ───────────────────────────────────────────────────
  function signPoD(impressionId, nodeAddr, cpmPaid) {
    var msgHash  = genHash(64);
    var signature = genHash(130);
    return {
      impressionId: impressionId,
      nodeAddr:     nodeAddr,
      cpmPaid:      cpmPaid,
      msgHash:      msgHash,
      signature:    signature,
      viewerAddr:   genHash(40)
    };
  }

  // ── Step 6: Oracle Verification + Mint ───────────────────────────────────
  function verifyAndMint(podData) {
    var podHash    = genHash(64);
    var txHash     = genHash(64);
    var cmxs       = 0.001;
    return {
      podHash:       podHash,
      txHash:        txHash,
      cmxsRewarded:  cmxs,
      basescanUrl:   'https://sepolia.basescan.org/tx/' + txHash,
      checks: {
        signatureValid:   true,
        replayProtection: true,
        latencySla:       true
      }
    };
  }

  // ── Step 7: CMXS Burn ────────────────────────────────────────────────────
  function burnForAdSpend(clearPrice, state) {
    // clearPrice is CPM. Per-impression cost = clearPrice / 1000
    var usdcAmount   = parseFloat((clearPrice / 1000).toFixed(6));
    // 1 CMXS per $0.10 USDC → burnAmount = usdcAmount * 10
    var burnAmount   = parseFloat((usdcAmount * 10).toFixed(4));
    var publisherPct = 0.85;
    var platformPct  = 0.15;

    state.totalMinted  = (state.totalMinted  || 0) + 0.001;
    state.totalBurned  = (state.totalBurned  || 0) + burnAmount;
    var ratio = state.totalMinted > 0
      ? (state.totalBurned / (state.totalMinted + state.totalBurned) * 100)
      : 50;

    return {
      usdcAmount:       usdcAmount,
      burnAmount:       burnAmount,
      publisherShare:   parseFloat((usdcAmount * publisherPct).toFixed(6)),
      platformShare:    parseFloat((usdcAmount * platformPct).toFixed(6)),
      totalMinted:      state.totalMinted,
      totalBurned:      state.totalBurned,
      burnRatioPct:     parseFloat(ratio.toFixed(1)),
      isDeflationary:   ratio > 50
    };
  }

  // ── Full Cycle ────────────────────────────────────────────────────────────
  async function runFullCycle(opts, hooks, state) {
    opts  = opts  || {};
    hooks = hooks || {};
    state = state || { totalMinted: 0, totalBurned: 0, cycleCount: 0 };
    state.cycleCount = (state.cycleCount || 0) + 1;

    function emit(name, data) {
      if (hooks[name]) hooks[name](data);
    }

    // Step 1
    var bidsResult = generateBids(opts);
    emit('onBids', bidsResult);
    await wait(opts.stepDelay || 1200);

    // Step 2
    var auctionResult = runAuction(bidsResult.bids, bidsResult.floorCpm);
    if (!auctionResult) { emit('onError', { msg: 'No eligible bids' }); return; }
    emit('onAuction', auctionResult);
    await wait(opts.stepDelay || 1200);

    // Step 3
    var deliveryResult = simulateDelivery();
    emit('onDelivery', deliveryResult);
    await wait(opts.stepDelay || 1200);

    // Step 4
    var watchResult = simulateAdWatch();
    emit('onWatch', watchResult);
    await wait(opts.stepDelay || 1200);

    // Step 5
    var podSig = signPoD(
      auctionResult.impressionId,
      deliveryResult.nodeAddress,
      auctionResult.clearPrice
    );
    emit('onPoD', podSig);
    await wait(opts.stepDelay || 1200);

    // Step 6
    var mintResult = verifyAndMint(podSig);
    emit('onMint', mintResult);
    await wait(opts.stepDelay || 1200);

    // Step 7
    var burnResult = burnForAdSpend(auctionResult.clearPrice, state);
    emit('onBurn', burnResult);
    await wait(opts.stepDelay || 800);

    emit('onCycleComplete', {
      bids:     bidsResult,
      auction:  auctionResult,
      delivery: deliveryResult,
      watch:    watchResult,
      pod:      podSig,
      mint:     mintResult,
      burn:     burnResult,
      state:    state
    });

    return { bids: bidsResult, auction: auctionResult, delivery: deliveryResult,
             watch: watchResult, pod: podSig, mint: mintResult, burn: burnResult };
  }

  // ── Expose ────────────────────────────────────────────────────────────────
  window.AgSim = {
    generateBids:    generateBids,
    runAuction:      runAuction,
    simulateDelivery:simulateDelivery,
    simulateAdWatch: simulateAdWatch,
    signPoD:         signPoD,
    verifyAndMint:   verifyAndMint,
    burnForAdSpend:  burnForAdSpend,
    runFullCycle:    runFullCycle,
    DSP_PROFILES:    DSP_PROFILES,
    wait:            wait,
    genHash:         genHash
  };

})();
