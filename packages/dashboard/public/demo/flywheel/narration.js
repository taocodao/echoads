// narration.js — Audio-first engine + 15 act scripts
(function(){
'use strict';

var AUDIO_BASE = 'audio/';

window.FW_ACT_TITLES = {
  1:'The Network', 2:'The Inventory', 3:'The Auction', 4:'The Delivery',
  5:'The Receipt', 6:'The Settlement', 7:'The Economics', 8:'The Opportunity',
  9:'The Flywheel', 10:'Executive Summary', 11:'MoQ+ CDN & FAST Stack',
  12:'Revenue Engines', 13:'Revenue Model',
  14:'Financial Value', 15:'First Step'
};

window.FW_SCRIPTS = {
  1:"What you are looking at is not a simulation. This is the CMXS Sports FAST Channel platform running live on the Base Sepolia test network, with real smart contract transactions confirmed on the blockchain in real time. Five delivery nodes are registering right now — each one staking CMXS tokens and joining the verified delivery network. Sports FAST is the fastest-growing segment in connected TV, projected to reach thirty-three billion dollars by 2027. Every node you see online is one more proof point that the infrastructure works — not in theory, but right now.",
  2:"A live sports broadcast has started. LIV Golf, Round 2. This content is now being packaged and distributed across Roku, Apple TV, Amazon Fire TV, and Samsung TV simultaneously — all from a single managed platform. Sports content commands the highest advertising rates in all of connected TV: thirty-five to forty-five dollars per thousand impressions, versus twelve to eighteen for entertainment. Sports viewers have higher purchase intent, higher household income, and measurably stronger advertising response. This is the inventory that brands compete for.",
  3:"An ad break just opened. Watch what happens in the next half second. Five demand partners — Trade Desk, Google DV360, Amazon DSP, Magnite, and a direct brand deal from Callaway Golf — are submitting competing bids for this thirty-second slot right now. The clearing price you see — forty-five dollars CPM — is nearly double what the same inventory would earn on an unverified platform. That premium is a market rate that verified sports inventory has already proven it can command. The auction resolved in three hundred and twelve milliseconds. That timestamp is recorded on Base Sepolia.",
  4:"The winning ad is playing now. No black screen. No buffer. The viewer experience is identical to the content. At the twenty-second mark, an interactive commerce overlay appears. The viewer can purchase the advertised product with one click on their remote, without leaving the game. This x302 commerce layer is a revenue stream that does not exist on any other FAST platform today. Three to five percent of viewers who see the overlay convert. At sixty to one hundred twenty dollars average purchase value, that converts directly into revenue independent of advertising CPMs.",
  5:"This is what changes everything. The viewer's device just generated a cryptographic delivery receipt — proof, on the blockchain, that this specific ad was watched on this specific device at this exact time. This is a live transaction on Base Sepolia — you can verify it right now on Basescan. The Association of National Advertisers estimates eighty-four billion dollars in verified ad spend sitting on the sideline because brands cannot trust delivery data. Procter and Gamble, Unilever, and General Motors all announced in 2025 they are moving their connected TV budgets exclusively to verified inventory. CMXS generates that verification automatically, for every impression.",
  6:"Settlement just completed. The verified receipt was deduplicated, batched, and confirmed on Base Sepolia — total time, under three seconds. The node operator earned CMXS tokens automatically, with no invoice, no payment approval, and no thirty-day cycle. Advertisers receive proof. Publishers receive payment. Node operators receive rewards. The entire chain settles in real time, and the record is permanently on-chain and independently auditable by anyone.",
  7:"The protocol treasury just collected fifteen percent of this campaign's revenue. Seventy percent flows automatically to long-term token holders. Thirty percent goes to node operators. The number that matters most: one hundred CMXS tokens were burned for this single campaign. Only zero-point-zero-zero-five were minted as node rewards. Burns permanently exceed mints. Every dollar of advertising demand destroys CMXS supply. At scale — one billion impressions per month — that is thirty million dollars per year in systematic, demand-driven buy pressure on the token. This is deflationary by design, not by promise.",
  8:"Three independent revenue streams. First: the CPM premium — verified sports inventory commands forty-five to sixty-five dollar CPMs versus eighteen to thirty for unverified. Same audience, same content, same ad break. At one billion monthly impressions, that gap is three hundred sixty million dollars per year. Second: a forty-five billion dollar sports betting infrastructure market that requires sub-five-hundred-millisecond broadcast latency — our system runs at three hundred twelve milliseconds. EchoStar currently earns zero from this market. Third: thirty million dollars per year in new node revenue flowing to five thousand eight hundred infrastructure sites that today earn nothing from advertising.",
  9:"Four demand engines drive the CMXS flywheel and each one reinforces the others. Proof-of-Delivery rewards align every node operator's income with network performance. Campaign burns tie the token's value directly to advertising revenue growth. SLA staking locks supply off the market in exchange for premium routing access. And veToken governance gives long-term holders protocol yield paid in USDC plus voting rights. More advertising demand burns tokens. Higher token value attracts more nodes. More nodes improve coverage and reliability. Better coverage attracts more content partners. Which burns more tokens. The infrastructure you just watched running on Base Sepolia is not a concept. The question is who captures the revenue it generates.",
  10:"Following recent spectrum and business realignments, EchoStar's Boost 5G network and tower companies have left thousands of newly built, premium edge computing shelters under-utilized — or tied up in legal disputes over unfulfilled ten-year lease commitments. Simultaneously, free ad-supported streaming now reaches one hundred thirty-one million US viewers, fifty-four percent of all connected TV households, growing at forty-three percent year over year. Live sports FAST channels doubled in the second half of 2025. Verified CPMs are reaching forty-five to sixty-five dollars, versus ten to twenty on unverified stacks. These two realities — stranded infrastructure and untapped audience equity — form the foundation of a genuinely differentiated opportunity. A working prototype has been built and validated end to end, confirming broadcast-grade delivery and a full thirty-five-second auction-to-settlement cycle. The step to a live branded EchoStar channel is operational, not technical.",
  11:"Our platform delivers a ready-to-deploy MoQ-compatible CDN fabric instantiated across existing telecom shelters, combined with a fully managed channel revenue layer on top. The infrastructure layer delivers sub-one-hundred-fifty-millisecond latency globally, ninety-nine-point-nine-nine-nine-nine percent SLA through AI-powered smart routing, thirty percent bandwidth efficiency gains, and broadcast-grade synchronization — all using existing three to five kilowatt telecom power and cooling shells that are already built and paid for. On top of that infrastructure sits a complete white-label channel distribution stack across Roku, Apple TV, Amazon Fire TV, and Samsung TV. A full OpenRTB 2.6 real-time programmatic auction connected to all major demand-side platforms. Cryptographic Proof-of-Delivery verification that unlocks forty-five to sixty-five dollar verified CPMs. An interactive remote-control commerce layer with proven three to eight percent viewer conversion rates. EchoStar brings the brand and the content rights. We deliver everything else. EchoStar retains eighty to eighty-five percent of all verified gross advertising revenue from day one, at zero upfront cost.",
  12:"The platform generates revenue across three independent engines on a single infrastructure investment. First: MoQ+ CDN delivery — serving DISH, Sling TV, live sports broadcasters, sports betting operators, and interactive gaming platforms with real-time media transport and premium OTT delivery. Second: the verified FAST ad platform — serving sports rights holders, OTT platforms, and content partners, generating a fifteen to twenty percent platform fee on all verified gross CPM revenue. Third: the interactive commerce and sports betting layer — serving sportsbook operators, retailers, and fantasy platforms, generating a one-point-five percent transaction fee on purchases plus a revenue share on in-play betting. All three engines run on the same infrastructure. The CDN is CapEx-light, deploying through established telecom power and cooling shells already engineered for five-G demands. The infrastructure is already built. No new capital expenditure is required.",
  13:"A single branded FAST sports channel at launch projects more than one-point-eight million dollars per year in EchoStar advertising revenue from five hundred thousand monthly viewers, before interactive commerce fees. EchoStar's upfront cost is zero. Revenue share begins on the first verified impression. The three-year portfolio outlook has three scenarios, all modeled from independently sourced market data. In the conservative case, five million monthly active viewers generate seven-point-two million dollars annually. In the base case, twelve million monthly active viewers generate twenty-three-point-one million dollars annually. In the optimistic case, twenty-five million monthly active viewers generate sixty-eight-point-nine million dollars annually. MoQ+ CDN running beneath the verified ad and commerce stack directly addresses the reliability and latency limitations that have driven audiences toward larger OTT competitors. Every viewer on a Sling-branded FAST channel generates premium advertising revenue at verified CPMs and can transact through the interactive commerce layer, with no subscription required.",
  14:"The US sports betting market reached one hundred and two billion dollars in 2026 and is projected to grow to over two hundred and five billion by 2032, at a compound annual growth rate above twelve percent. In-play betting requires sub-second synchronization — the fastest-growing segment, and the one our MoQ+ delivery infrastructure is uniquely positioned to power at scale. This positions EchoStar at the convergence of live sports, real-time advertising, and transactional commerce — forming a durable, high-margin financial activation network that compounds in value as the audience grows. Financially, this proposal converts distressed telecom lease exposure into equity ownership in a next-generation MoQ CDN network, transforming balance sheet liabilities into recurring, software-defined infrastructure revenue commanding superior SaaS and IaaS valuation multiples. While traditional cloud hyperscalers sell centralized compute volume, our platform commercializes compute proximity and network velocity. EchoStar's existing edge footprint represents a structural head start measured in years, not months.",
  15:"The proposed first step is a ninety-day pilot activating one branded EchoStar sports FAST channel on Roku — the largest free streaming platform in the US with ninety-seven-point-three million viewers — using existing content rights. The full ad stack will run over a MoQ+ delivery node at a single existing telecom shelter. First verified impressions, first premium CPM data, and first revenue within the quarter. No long-term commitment is required beyond the pilot. No license fee. No integration cost. No capital commitment from EchoStar. Revenue share begins on the first verified impression. A working prototype has been built and validated end to end. The infrastructure exists. The technology is proven. The audience is ready. The question is not whether this market will be built. It is who builds it first."
};

// ── Audio Engine (MP3-first, TTS fallback) ─────────────────────────────
var muted = false;
var currentAudio = null;
var currentUtt = null;
var resolvePlay = null;

function getBestVoice(){
  var voices = speechSynthesis.getVoices();
  var prefs = ['Google US English','Daniel','Samantha','Alex'];
  for(var i=0;i<prefs.length;i++){
    var v = voices.find(function(vo){return vo.name.indexOf(prefs[i])>=0;});
    if(v) return v;
  }
  return voices.find(function(vo){return vo.lang.indexOf('en')===0;})||voices[0]||null;
}
if(speechSynthesis.onvoiceschanged!==undefined) speechSynthesis.onvoiceschanged=getBestVoice;

function startCaption(text){
  var el = document.getElementById('fw-caption-text');
  if(!el) return;
  var words = text.split(/\s+/);
  el.innerHTML = words.map(function(w,i){
    return '<span class="word" data-idx="'+i+'">'+w+' </span>';
  }).join('');
}

function highlightWord(idx){
  var el = document.getElementById('fw-caption-text');
  if(!el) return;
  var spans = el.querySelectorAll('.word');
  spans.forEach(function(s,i){
    s.classList.remove('current');
    if(i<idx) s.classList.add('spoken');
  });
  if(spans[idx]) spans[idx].classList.add('current');
}

function setSpeaking(on){
  var mic = document.getElementById('fw-mic');
  var wave = document.getElementById('fw-wave');
  if(mic) mic.classList.toggle('speaking', on);
  if(wave) wave.classList.toggle('active', on);
}

window.FW_speak = function(actNum){
  var text = window.FW_SCRIPTS[actNum]||'';
  return new Promise(function(resolve){
    resolvePlay = resolve;
    startCaption(text);

    if(muted){
      // Show captions, wait estimated duration, resolve
      var estMs = Math.max(4000, (text.length/14)*1000);
      setTimeout(resolve, estMs);
      return;
    }

    // Try MP3 first
    var audio = new Audio(AUDIO_BASE+'fw'+String(actNum).padStart(2,'0')+'.mp3');
    currentAudio = audio;

    var wordCount = text.split(/\s+/).length;
    audio.addEventListener('loadedmetadata', function(){
      setSpeaking(true);
      var totalMs = audio.duration * 1000;
      var msPerWord = totalMs / wordCount;
      var wordIdx = 0;
      var ticker = setInterval(function(){
        if(wordIdx<wordCount){ highlightWord(wordIdx); wordIdx++; }
        else clearInterval(ticker);
      }, msPerWord);
    });

    audio.onended = function(){
      setSpeaking(false); currentAudio=null;
      if(resolvePlay){resolvePlay();resolvePlay=null;}
    };
    audio.onerror = function(){
      // Fallback to TTS
      currentAudio=null;
      speakTTS(text, resolve);
    };
    audio.play().catch(function(){ speakTTS(text, resolve); });
  });
};

function speakTTS(text, resolve){
  speechSynthesis.cancel();
  var utt = new SpeechSynthesisUtterance(text);
  utt.rate=0.88; utt.pitch=1.0; utt.volume=1.0;
  var voice=getBestVoice();
  if(voice) utt.voice=voice;
  currentUtt=utt;
  setSpeaking(true);
  var wIdx=0;
  utt.onboundary=function(e){ if(e.name==='word'){highlightWord(wIdx);wIdx++;} };
  utt.onend=function(){ setSpeaking(false); currentUtt=null; resolve(); };
  utt.onerror=function(){ setSpeaking(false); currentUtt=null; resolve(); };
  speechSynthesis.speak(utt);
}

window.FW_stopSpeech = function(){
  if(currentAudio){ currentAudio.pause(); currentAudio=null; }
  speechSynthesis.cancel();
  setSpeaking(false);
  if(resolvePlay){resolvePlay();resolvePlay=null;}
};

window.FW_toggleMute = function(){
  muted=!muted;
  var btn=document.getElementById('fw-mute-btn');
  if(btn) btn.textContent=muted?'🔇':'🔊';
  if(muted){
    if(currentAudio){currentAudio.pause();currentAudio=null;}
    speechSynthesis.cancel();
  }
};

window.FW_isMuted=function(){return muted;};

})();
