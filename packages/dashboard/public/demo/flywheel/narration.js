// narration.js — All 9 act scripts + TTS caption engine
// Business-focused narration for investor/partner demo
(function () {
'use strict';

window.FW_SCRIPTS = {
  1: "CMXS is a full-stack Sports FAST channel platform — the fastest-growing segment in connected TV, projected to reach thirty-three billion dollars by 2027. What you're seeing is a live prototype. Five delivery nodes are registering on the network right now. Each represents an infrastructure partner — a tower site, a streaming device, a broadband relay — that earns revenue for every verified ad impression it delivers. This is the DePIN model that powered Helium to a billion-dollar valuation, applied to the two-hundred-billion-dollar advertising market.",

  2: "A live sports broadcast just started — LIV Golf, Round 2. Sports content commands the highest CPMs in streaming: thirty-five to forty-five dollars per thousand impressions, compared to twelve to eighteen dollars for entertainment. The key innovation here is server-side ad insertion. Ads are stitched directly into the video stream at the origin — invisible to ad blockers, zero buffering for viewers, and most importantly, every impression flows through our verification pipeline. No self-reported metrics. Every view is cryptographically provable.",

  3: "An ad break just triggered a real-time programmatic auction. Five major demand partners — Trade Desk, Google DV360, Amazon DSP, Magnite, and a direct brand deal from Callaway Golf — are competing for this premium sports inventory right now. Watch the bids arrive. The clearing price — forty-five dollars CPM — is nearly double what unverified FAST inventory commands. That premium exists because advertisers know every impression on CMXS is independently verifiable on-chain. The entire auction resolved in under five hundred milliseconds. Real-time, programmatic, at scale.",

  4: "The winning ad is now playing seamlessly in the live stream. No black screen, no buffer — the viewer experience is indistinguishable from the content itself. This is critical for sports: viewers abandon streams that buffer during live action. At the twenty-second mark, an interactive commerce overlay appears — the viewer can purchase the advertised product with one click, without leaving the stream. This x302 commerce layer drives three to five percent conversion rates and sixty to one hundred twenty dollar average purchases. That's a revenue stream that doesn't exist on any competing FAST platform today.",

  5: "This is what makes CMXS structurally different from every other ad platform. The viewer's device just generated a cryptographic receipt — independently verifiable proof that this specific ad was watched, on this specific device, at this exact time. No other FAST platform can produce this. The consequence is financial: the Association of National Advertisers estimates eighty-four billion dollars in ad fraud over three years. Procter and Gamble, Unilever, and General Motors announced in 2025 they're moving budgets exclusively to verified inventory. CMXS is the verification layer that unlocks that spend.",

  6: "Settlement just happened automatically. The verified receipt was deduplicated, batched, and confirmed on the Base blockchain — all in under three seconds. The node operator earned CMXS tokens instantly. Compare that to the industry standard: thirty to ninety day payment cycles, manual reconciliation, disputed impressions. CMXS eliminates all of it. Advertisers get proof. Publishers get paid. Node operators earn rewards. No invoices, no disputes, no human in the loop.",

  7: "Here's the token economics in action. Fifteen percent of every campaign's revenue flows to the protocol treasury — distributed automatically to token holders and node operators. But the critical number is this: one hundred CMXS tokens were burned for this campaign. Only zero-point-zero-zero-five were minted as rewards. Burns permanently exceed mints. Every dollar of advertising demand reduces the total token supply. At scale — one billion impressions per month — that's thirty million dollars per year in systematic buy-and-burn pressure. The token is deflationary by design, not by promise.",

  8: "Three revenue opportunities. First: the CPM premium. Verified sports inventory commands forty-five to sixty-five dollar CPMs versus eighteen to thirty for unverified. At one billion monthly impressions, that's three hundred sixty million dollars per year in incremental revenue — from inventory that already exists. Second: a forty-five billion dollar sports betting infrastructure market that requires sub-five-hundred-millisecond latency — which our system delivers at three hundred twelve milliseconds. Third: thirty million dollars per year in new DePIN node revenue flowing to five thousand eight hundred infrastructure sites that currently earn nothing from advertising.",

  9: "Four independent demand engines power the CMXS flywheel. Proof-of-Delivery rewards align node operators with network growth. Campaign burns tie token value directly to advertising revenue. SLA staking removes supply from circulation. And veToken governance gives long-term holders yield plus voting rights. Each engine reinforces the others — more ad demand burns tokens, higher token value attracts more nodes, better coverage attracts more advertisers. This isn't a pitch deck. The infrastructure is deployed. The contracts are live on Base. Everything you just watched was running in real time. The question is who captures this revenue first."
};

window.FW_ACT_TITLES = {
  1: 'The Channel',
  2: 'The Stream',
  3: 'The Auction',
  4: 'The Delivery',
  5: 'The Proof',
  6: 'The Settlement',
  7: 'The Treasury',
  8: 'The Opportunity',
  9: 'The Flywheel'
};

// ── TTS Engine ──────────────────────────────────────────────────────────────

var muted = false;
var currentUtterance = null;
var resolveSpeak = null;

function getVoice() {
  var voices = speechSynthesis.getVoices();
  // Prefer natural-sounding voices
  var prefs = ['Google US English', 'Google UK English Male', 'Daniel', 'Samantha', 'Alex'];
  for (var i = 0; i < prefs.length; i++) {
    var v = voices.find(function(vo) { return vo.name.indexOf(prefs[i]) >= 0; });
    if (v) return v;
  }
  // Fallback: first English voice
  return voices.find(function(vo) { return vo.lang.indexOf('en') === 0; }) || voices[0] || null;
}

window.FW_speak = function (actNum) {
  var text = window.FW_SCRIPTS[actNum];
  if (!text) return Promise.resolve();

  return new Promise(function (resolve) {
    if (muted) {
      // Still show captions, but estimate duration
      window.FW_showCaption(text);
      var estMs = Math.max(5000, (text.length / 14) * 1000);
      setTimeout(resolve, estMs);
      return;
    }

    speechSynthesis.cancel();
    var utt = new SpeechSynthesisUtterance(text);
    utt.rate = 0.88;
    utt.pitch = 1.0;
    utt.volume = 1.0;
    var voice = getVoice();
    if (voice) utt.voice = voice;

    currentUtterance = utt;
    resolveSpeak = resolve;

    window.FW_showCaption(text);
    document.getElementById('fw-mic').classList.add('speaking');
    document.getElementById('fw-wave').classList.add('active');

    // Word boundary highlighting
    var words = text.split(/\s+/);
    var wordIdx = 0;
    utt.onboundary = function (e) {
      if (e.name === 'word') {
        window.FW_highlightWord(wordIdx);
        wordIdx++;
      }
    };

    utt.onend = function () {
      document.getElementById('fw-mic').classList.remove('speaking');
      document.getElementById('fw-wave').classList.remove('active');
      currentUtterance = null;
      resolve();
    };
    utt.onerror = function () {
      document.getElementById('fw-mic').classList.remove('speaking');
      document.getElementById('fw-wave').classList.remove('active');
      currentUtterance = null;
      resolve();
    };

    speechSynthesis.speak(utt);
  });
};

window.FW_stopSpeech = function () {
  speechSynthesis.cancel();
  document.getElementById('fw-mic').classList.remove('speaking');
  document.getElementById('fw-wave').classList.remove('active');
  if (resolveSpeak) { resolveSpeak(); resolveSpeak = null; }
};

window.FW_toggleMute = function () {
  muted = !muted;
  document.getElementById('fw-mute-btn').textContent = muted ? '🔇' : '🔊';
  if (muted) speechSynthesis.cancel();
};

window.FW_isMuted = function () { return muted; };

// ── Caption System ──────────────────────────────────────────────────────────

window.FW_showCaption = function (text) {
  var el = document.getElementById('fw-caption-text');
  if (!el) return;
  var words = text.split(/\s+/);
  el.innerHTML = words.map(function (w, i) {
    return '<span class="word" data-idx="' + i + '">' + w + ' </span>';
  }).join('');
};

window.FW_highlightWord = function (idx) {
  var el = document.getElementById('fw-caption-text');
  if (!el) return;
  var spans = el.querySelectorAll('.word');
  spans.forEach(function (s, i) {
    s.classList.remove('current');
    if (i < idx) s.classList.add('spoken');
  });
  if (spans[idx]) {
    spans[idx].classList.add('current');
    // Scroll caption to keep current word visible
    spans[idx].scrollIntoView({ behavior: 'smooth', block: 'nearest', inline: 'center' });
  }
};

window.FW_clearCaption = function () {
  var el = document.getElementById('fw-caption-text');
  if (el) el.textContent = '';
};

// Pre-load voices
if (speechSynthesis.onvoiceschanged !== undefined) {
  speechSynthesis.onvoiceschanged = getVoice;
}

})();
