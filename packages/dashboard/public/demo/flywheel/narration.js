// narration.js — Audio-first engine + 15 act scripts
(function(){
'use strict';

var AUDIO_BASE = 'audio/';

window.FW_ACT_TITLES = {
  1:'The Network', 2:'The Inventory', 3:'The Auction', 4:'The Delivery',
  5:'The Receipt', 6:'The Settlement', 7:'The Economics', 8:'The Opportunity',
  9:'The Flywheel', 10:'The Market', 11:'Channel-as-a-Service',
  12:'The Verified Premium', 13:'The Revenue Model',
  14:'Beyond Advertising', 15:'The Decision'
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
  10:"Free ad-supported streaming now reaches over one hundred thirty-one million US viewers — more than half of all connected TV households — growing at forty-three percent year over year. More than seventy percent of all net new streaming subscriptions added since 2023 went to ad-supported plans rather than paid tiers. The consumer has already voted. Sports sits at the center of this shift. Sports channels on free streaming platforms doubled in the second half of 2025. Live sports inventory commands the highest advertising rates in all of connected TV, and sports audiences spend significantly more, carry higher purchase intent, and deliver measurably stronger results for every advertiser. EchoStar's existing relationships, content depth, and audience equity in live sports make it one of the best-positioned media organizations in the country to lead this category.",
  11:"CMXS is a fully managed Channel-as-a-Service platform built for this moment. EchoStar brings the brand and the content rights. CMXS delivers everything else. Channel packaging. Distribution across Roku, Apple TV, Amazon Fire TV, and Samsung TV. A full real-time programmatic advertising auction. Cryptographic verified delivery that unlocks premium CPM rates two to three times above unverified inventory. And an interactive commerce layer that lets viewers act on what they watch without ever leaving the content. The entire stack runs on EchoStar's existing infrastructure. No new capital investment is required. The step from prototype to a branded EchoStar channel on Roku is an operational milestone, not a technical one.",
  12:"Every impression carries a cryptographic delivery receipt — and that receipt is precisely what unlocks the premium advertising tier that general FAST platforms cannot reach. Live sports inventory on unverified platforms earns fifteen to twenty-five dollars CPM. The same inventory, delivered through CMXS with proof of verified delivery, commands forty-five to sixty-five dollars CPM. The audience is identical. The content is identical. The ad break is identical. The difference is infrastructure. No competitor combines all five layers in a single managed service: distribution, real-time auction, verified delivery, interactive commerce, and incentivized delivery infrastructure. EchoStar retains eighty to eighty-five percent of all verified gross advertising revenue from day one, with no upfront cost and no integration fee.",
  13:"A single branded FAST sports channel at launch, at five hundred thousand monthly viewers, projects more than one-point-eight million dollars per year in EchoStar advertising revenue — before accounting for interactive commerce conversions at three to eight percent engagement rates. Scaled to a portfolio, the three-year outlook: in the conservative case, five million monthly viewers generate seven-point-two million annually. In the base case, twelve million viewers generate twenty-three-point-one million annually. In the optimistic case, twenty-five million viewers generate sixty-eight-point-nine million annually. The base case requires capturing less than one-tenth of one percent of the US connected TV programmatic market.",
  14:"The interactive commerce layer does more than drive product purchases. It establishes a direct, real-time financial connection between what a viewer is watching and what they choose to do with their money in that moment. The US sports betting market reached one hundred and two billion dollars in 2026 and is projected to grow to over two hundred and five billion by 2032. Twenty percent of US adults placed a sports bet in 2025 — up from twelve percent just two years prior. The CMXS interactive layer positions EchoStar to become the direct point of activation for this audience. A viewer watching a live game can be connected to a betting action, a merchandise purchase, or a tailored financial product in a single remote-control interaction. This is a proprietary commerce network built on EchoStar's own content that no third-party platform can replicate.",
  15:"The proposed first step is a ninety-day pilot on Roku — the largest free streaming platform in the US, with ninety-seven-point-three million viewers — launching one branded EchoStar sports FAST channel using existing content rights. First impressions, first verified CPMs, and first revenue within the quarter. No long-term commitment required beyond the pilot. The market has moved. The technology is proven and running on Base Sepolia right now. The audience is waiting. The infrastructure is already in the ground. The only remaining decision is whether EchoStar captures this revenue on its own terms — or watches a competitor build the same platform on someone else's towers."
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
