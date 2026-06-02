// flywheel.js — 15-act orchestrator (audio-first, no SSE dependency)
(function(){
'use strict';

var TOTAL_ACTS = 15;
var running = false;
var currentAct = 0;
var aborted = false;

function $(id){return document.getElementById(id);}
function wait(ms){return new Promise(function(r){if(aborted)return r();setTimeout(r,ms);});}

// ── UI helpers ──────────────────────────────────────────────────────────
function showStage(act){
  document.querySelectorAll('.fw-stage-inner').forEach(function(el){el.classList.remove('active');});
  var target = $('stage-'+(act||'idle'));
  if(target) target.classList.add('active');
  // Show/hide metrics row based on section
  var metrics = $('fw-metrics');
  if(metrics) metrics.style.display = (act && act <= 9) ? '' : 'none';
}

function updateDots(act, status){
  document.querySelectorAll('.fw-dot').forEach(function(d){
    var a=parseInt(d.dataset.act);
    if(!a) return;
    if(a < act)      d.className='fw-dot '+(a<=9?'demo':'pres')+' complete';
    else if(a===act) d.className='fw-dot '+(a<=9?'demo':'pres')+' '+(status==='complete'?'complete':'active');
    else             d.className='fw-dot '+(a<=9?'demo':'pres');
  });
  var label=$('fw-act-label');
  var badge=$('fw-section-badge');
  if(act>0){
    var title=window.FW_ACT_TITLES[act]||('Act '+act);
    if(label) label.textContent='Act '+act+'/'+TOTAL_ACTS+' — '+title;
    if(badge){
      badge.textContent = act<=9 ? '⛓ LIVE DEMO' : '📊 PRESENTATION';
      badge.className = 'fw-section-badge '+(act<=9?'demo':'pres');
    }
  }
}

function setMetric(id, val){
  var el=$(id);
  if(el){var v=el.querySelector('.fw-metric-val');if(v)v.textContent=val;}
}

// ── Act runner ──────────────────────────────────────────────────────────
function runAct(act){
  if(aborted) return Promise.resolve();
  currentAct=act;
  updateDots(act,'running');
  showStage(act);
  var builder=window['FW_buildStage'+act];
  var container=$('stage-'+act);
  if(builder && container) builder(container, {});
  return window.FW_speak(act).then(function(){
    if(!aborted) updateDots(act,'complete');
  });
}

// ── Metric updates per act ──────────────────────────────────────────────
var metricSteps = {
  1: function(){ setMetric('m-nodes','5'); },
  3: function(){ setMetric('m-cpm','$45.20'); setMetric('m-latency','312ms'); },
  6: function(){ setMetric('m-minted','0.005 CMXS'); },
  7: function(){ setMetric('m-burned','100 CMXS'); }
};

function resetMetrics(){
  ['m-nodes','m-cpm','m-latency','m-burned','m-minted'].forEach(function(id){setMetric(id,'—');});
  setMetric('m-chain','Base Sepolia');
}

// ── Run full demo ───────────────────────────────────────────────────────
function runAllActs(){
  running=true; aborted=false; currentAct=0;
  $('fw-start-btn').style.display='none';
  $('fw-stop-btn').style.display='';
  resetMetrics();

  var chain = Promise.resolve();
  for(var i=1;i<=TOTAL_ACTS;i++){
    (function(act){
      chain = chain.then(function(){
        if(aborted) return;
        return runAct(act).then(function(){
          if(metricSteps[act]) metricSteps[act]();
          return wait(400);
        });
      });
    })(i);
  }
  chain.then(function(){
    running=false;
    $('fw-start-btn').style.display='';
    $('fw-stop-btn').style.display='none';
    var label=$('fw-act-label');
    if(label) label.textContent='Complete ✅';
  });
}

function stopDemo(){
  aborted=true; running=false;
  window.FW_stopSpeech();
  $('fw-start-btn').style.display='';
  $('fw-stop-btn').style.display='none';
  var label=$('fw-act-label');
  if(label) label.textContent='Stopped';
  showStage(null);
}

function jumpToAct(n){
  if(n<1||n>TOTAL_ACTS) return;
  if(running) window.FW_stopSpeech();
  aborted=false;
  currentAct=n;
  updateDots(n,'running');
  showStage(n);
  var builder=window['FW_buildStage'+n];
  var container=$('stage-'+n);
  if(builder && container) builder(container, {});
  window.FW_speak(n).then(function(){ if(!aborted) updateDots(n,'complete'); });
}

// ── Controls ────────────────────────────────────────────────────────────
$('fw-start-btn').addEventListener('click',function(){if(!running)runAllActs();});
$('fw-stop-btn').addEventListener('click',stopDemo);
$('fw-mute-btn').addEventListener('click',function(){window.FW_toggleMute();});
$('fw-fs-btn').addEventListener('click',function(){
  var el=$('fw-layout');
  if(!document.fullscreenElement) el.requestFullscreen().catch(function(){});
  else document.exitFullscreen();
});

document.addEventListener('keydown',function(e){
  if(e.target.tagName==='INPUT'||e.target.tagName==='TEXTAREA') return;
  switch(e.code){
    case 'Space':      e.preventDefault(); if(running) stopDemo(); else runAllActs(); break;
    case 'ArrowRight': e.preventDefault(); if(currentAct<TOTAL_ACTS) jumpToAct(currentAct+1); break;
    case 'ArrowLeft':  e.preventDefault(); if(currentAct>1) jumpToAct(currentAct-1); break;
    case 'KeyF':       e.preventDefault(); $('fw-fs-btn').click(); break;
    case 'KeyM':       e.preventDefault(); window.FW_toggleMute(); break;
    case 'Escape':     e.preventDefault(); if(running) stopDemo(); break;
    default:
      // 1-9 → acts 1-9; Digit0+1–6 not easily handled, dots are clickable
      var num=parseInt(e.key);
      if(num>=1&&num<=9){e.preventDefault();jumpToAct(num);}
  }
});

document.querySelectorAll('.fw-dot[data-act]').forEach(function(d){
  d.style.cursor='pointer';
  d.addEventListener('click',function(){jumpToAct(parseInt(d.dataset.act));});
});

if(window.location.search.indexOf('autoplay=1')>=0){
  setTimeout(runAllActs,800);
}

})();
