// flywheel.js — Main orchestrator
(function(){
'use strict';

var API = 'http://localhost:3001';
var running = false;
var currentAct = 0;
var aborted = false;
var sseData = {};

function $(id){return document.getElementById(id);}
function wait(ms){return new Promise(function(r){if(aborted)return r();setTimeout(r,ms);});}

function showStage(act){
  document.querySelectorAll('.fw-stage-inner').forEach(function(el){el.classList.remove('active');});
  var target = $('stage-'+(act||'idle'));
  if(target) target.classList.add('active');
}

function updateDots(act, status){
  var dots = document.querySelectorAll('.fw-dot');
  dots.forEach(function(d){
    var a = parseInt(d.dataset.act);
    if(a < act) { d.className='fw-dot complete'; }
    else if(a === act) { d.className='fw-dot '+(status==='complete'?'complete':'active'); }
    else { d.className='fw-dot'; }
  });
  var label = $('fw-act-label');
  if(label && act > 0){
    var title = window.FW_ACT_TITLES[act] || ('Act '+act);
    label.textContent = 'Act '+act+'/9 — '+title;
  }
}

function setMetric(id, val){
  var el = $(id);
  if(el){var v=el.querySelector('.fw-metric-val');if(v)v.textContent=val;}
}

function updateMetrics(data){
  if(!data) return;
  sseData = Object.assign(sseData, data);
  if(data.activeNodes !== undefined || sseData.nodesRegistered) setMetric('m-nodes', (data.activeNodes||sseData.nodesRegistered||5)+'');
  if(data.clearingCpm || data.winningCpm) setMetric('m-cpm', '$'+(data.clearingCpm||data.winningCpm||45).toFixed||'$45.00');
  if(data.totalLatencyMs) setMetric('m-latency', data.totalLatencyMs+'ms');
  if(sseData.cmxsBurned !== undefined) setMetric('m-burned', (sseData.cmxsBurned||0)+' CMXS');
  if(sseData.cmxsMinted !== undefined) setMetric('m-minted', (sseData.cmxsMinted||0).toFixed?sseData.cmxsMinted.toFixed(4)+' CMXS':'0 CMXS');
  if(sseData.usdcRevenue !== undefined) setMetric('m-revenue', '$'+(sseData.usdcRevenue||0));
}

// ── SSE Connection ──────────────────────────────────────────────────────
function connectSSE(){
  try{
    var es = new EventSource(API+'/api/demo/events');
    es.addEventListener('scene', function(e){
      try{
        var ev = JSON.parse(e.data);
        if(ev.data) updateMetrics(ev.data);
      }catch(err){}
    });
    es.onerror = function(){es.close();};
  }catch(err){}
}

// ── Act Runner ──────────────────────────────────────────────────────────
function runAct(act){
  if(aborted) return Promise.resolve();
  currentAct = act;
  updateDots(act, 'running');
  showStage(act);

  // Build stage
  var builder = window['FW_buildStage'+act];
  var container = $('stage-'+act);
  if(builder && container) builder(container, sseData);

  // Speak narration (concurrent with animation)
  return window.FW_speak(act).then(function(){
    if(!aborted) updateDots(act, 'complete');
  });
}

function runAllActs(){
  running = true;
  aborted = false;
  sseData = {};
  currentAct = 0;
  $('fw-start-btn').style.display='none';
  $('fw-stop-btn').style.display='';

  // Try to trigger backend
  fetch(API+'/api/demo/start',{method:'POST'}).catch(function(){});
  connectSSE();

  // Set default metrics
  setMetric('m-nodes','—');setMetric('m-cpm','—');setMetric('m-latency','—');
  setMetric('m-burned','—');setMetric('m-minted','—');setMetric('m-revenue','—');

  return runAct(1)
    .then(function(){if(!aborted){updateMetrics({activeNodes:5});setMetric('m-nodes','5');return wait(500);}})
    .then(function(){if(!aborted)return runAct(2);})
    .then(function(){if(!aborted)return wait(500);})
    .then(function(){if(!aborted)return runAct(3);})
    .then(function(){if(!aborted){setMetric('m-cpm','$45.20');setMetric('m-latency','312ms');return wait(500);}})
    .then(function(){if(!aborted)return runAct(4);})
    .then(function(){if(!aborted)return wait(500);})
    .then(function(){if(!aborted)return runAct(5);})
    .then(function(){if(!aborted)return wait(500);})
    .then(function(){if(!aborted)return runAct(6);})
    .then(function(){if(!aborted){setMetric('m-minted','0.005 CMXS');return wait(500);}})
    .then(function(){if(!aborted)return runAct(7);})
    .then(function(){if(!aborted){setMetric('m-burned','100 CMXS');setMetric('m-revenue','$1,000');return wait(500);}})
    .then(function(){if(!aborted)return runAct(8);})
    .then(function(){if(!aborted)return wait(500);})
    .then(function(){if(!aborted)return runAct(9);})
    .then(function(){
      running=false;
      $('fw-start-btn').style.display='';
      $('fw-stop-btn').style.display='none';
      $('fw-act-label').textContent='Demo Complete ✅';
    });
}

function stopDemo(){
  aborted=true;
  running=false;
  window.FW_stopSpeech();
  $('fw-start-btn').style.display='';
  $('fw-stop-btn').style.display='none';
  $('fw-act-label').textContent='Stopped';
  showStage(null);
  fetch(API+'/api/demo/stop',{method:'POST'}).catch(function(){});
}

function jumpToAct(n){
  if(n<1||n>9) return;
  if(running){ window.FW_stopSpeech(); }
  aborted=false;
  currentAct=n;
  updateDots(n,'running');
  showStage(n);
  var builder=window['FW_buildStage'+n];
  var container=$('stage-'+n);
  if(builder&&container) builder(container, sseData);
  window.FW_speak(n).then(function(){updateDots(n,'complete');});
}

// ── Event Listeners ─────────────────────────────────────────────────────
$('fw-start-btn').addEventListener('click', function(){if(!running) runAllActs();});
$('fw-stop-btn').addEventListener('click', stopDemo);
$('fw-mute-btn').addEventListener('click', function(){window.FW_toggleMute();});
$('fw-fs-btn').addEventListener('click', function(){
  var el=$('fw-layout');
  if(!document.fullscreenElement){el.requestFullscreen().catch(function(){});}
  else{document.exitFullscreen();}
});

// Keyboard shortcuts
document.addEventListener('keydown', function(e){
  if(e.target.tagName==='INPUT'||e.target.tagName==='TEXTAREA') return;
  switch(e.code){
    case 'Space': e.preventDefault(); if(running) stopDemo(); else runAllActs(); break;
    case 'ArrowRight': e.preventDefault(); if(currentAct<9) jumpToAct(currentAct+1); break;
    case 'ArrowLeft': e.preventDefault(); if(currentAct>1) jumpToAct(currentAct-1); break;
    case 'KeyF': e.preventDefault(); $('fw-fs-btn').click(); break;
    case 'KeyM': e.preventDefault(); window.FW_toggleMute(); break;
    case 'Escape': e.preventDefault(); if(running) stopDemo(); break;
    default:
      var num=parseInt(e.key);
      if(num>=1&&num<=9){e.preventDefault();jumpToAct(num);}
  }
});

// Dot click → jump
document.querySelectorAll('.fw-dot').forEach(function(d){
  d.style.cursor='pointer';
  d.addEventListener('click', function(){jumpToAct(parseInt(d.dataset.act));});
});

// Autoplay
if(window.location.search.indexOf('autoplay=1')>=0){
  setTimeout(runAllActs, 1000);
}

})();
