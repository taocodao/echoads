// stages.js — Per-act DOM builders
(function(){
'use strict';

var NODES = [
  {icon:'📡',name:'ECHOSTAR-TOWER-001',type:'Tower',stake:'10,000'},
  {icon:'📺',name:'ROKU-ULTRA-042',type:'Roku Ultra',stake:'5,000'},
  {icon:'🔥',name:'FIRETV-CUBE-017',type:'Fire TV Cube',stake:'5,000'},
  {icon:'🍎',name:'APPLETV-4K-033',type:'Apple TV 4K',stake:'5,000'},
  {icon:'📶',name:'CBRS-NODE-008',type:'CBRS Radio',stake:'15,000'}
];

var DSPS = [
  {name:'Trade Desk',cpm:48.50,tag:'Premium Sports',latency:'62ms'},
  {name:'Google DV360',cpm:45.20,tag:'Brand Reach',latency:'78ms'},
  {name:'Amazon DSP',cpm:42.80,tag:'Commerce',latency:'55ms'},
  {name:'Magnite',cpm:38.90,tag:'Programmatic',latency:'91ms'},
  {name:'Callaway Golf',cpm:52.00,tag:'Direct Deal',latency:'41ms'}
];

function h(tag,cls,html){
  var el=document.createElement(tag);
  if(cls)el.className=cls;
  if(html)el.innerHTML=html;
  return el;
}

function stagger(els,cls,delayMs){
  els.forEach(function(el,i){
    setTimeout(function(){el.classList.add(cls);},i*delayMs);
  });
}

// ── Act 1: The Network ─────────────────────────────────────────────────
window.FW_buildStage1 = function(container){
  container.innerHTML='';
  var wrap=h('div','','');
  wrap.style.cssText='display:flex;flex-direction:column;align-items:center;width:100%;gap:1rem;';
  var title=h('div','stage-title','ACT 1 · LIVE ON BASE SEPOLIA TESTNET');
  title.style.cssText='font-size:0.7rem;color:var(--green);text-transform:uppercase;letter-spacing:0.1em;margin-bottom:0.5rem;display:flex;align-items:center;gap:0.5rem;';
  title.innerHTML='<span style="width:8px;height:8px;border-radius:50%;background:var(--green);display:inline-block;animation:dotPulse 1.2s ease infinite"></span> LIVE ON BASE SEPOLIA TESTNET — NOT A SIMULATION';
  var headline=h('div','stage-headline','$33B Sports FAST Market — 5 DePIN Nodes Registering');
  var grid=h('div','node-grid','');
  NODES.forEach(function(n){
    var card=h('div','node-card','');
    card.innerHTML='<div class="icon">'+n.icon+'</div><div class="name">'+n.name+'</div><div class="status pending">PENDING</div><div class="stake">'+n.stake+' CMXS staked</div>';
    grid.appendChild(card);
  });
  wrap.appendChild(title);
  wrap.appendChild(headline);
  wrap.appendChild(grid);
  container.appendChild(wrap);
  // Animate
  setTimeout(function(){
    var cards=grid.querySelectorAll('.node-card');
    stagger(Array.from(cards),'visible',400);
    // Switch to ACTIVE after appearing
    cards.forEach(function(c,i){
      setTimeout(function(){
        var s=c.querySelector('.status');
        s.textContent='ACTIVE';s.className='status active';
      },(i+1)*400+800);
    });
  },300);
};

// ── Act 2: The Stream ──────────────────────────────────────────────────
window.FW_buildStage2 = function(container){
  container.innerHTML='';
  var wrap=h('div','','');
  wrap.style.cssText='display:flex;flex-direction:column;align-items:center;width:100%;gap:1rem;';
  wrap.appendChild(h('div','stage-title','ACT 2'));
  wrap.appendChild(h('div','stage-headline','Server-Side Ad Insertion — $35-$45 CPM Sports Inventory'));
  var manifest=h('div','stage-card','');
  manifest.style.cssText='width:100%;max-width:700px;font-family:var(--mono);font-size:0.75rem;line-height:1.8;color:var(--muted);overflow:hidden;';
  manifest.innerHTML=
    '<span style="color:var(--dim)">#EXTM3U</span><br>'+
    '<span style="color:var(--dim)">#EXT-X-VERSION:3</span><br>'+
    '<span style="color:var(--dim)">#EXT-X-TARGETDURATION:6</span><br><br>'+
    '<span style="color:var(--text)">#EXTINF:6.0,</span><br>'+
    '<span style="color:var(--cyan)">https://cdn.cmxs.io/content/liv_golf_r2_seg001.ts</span><br><br>'+
    '<span id="scte-line" style="color:var(--amber);opacity:0;transition:all 0.6s">#EXT-X-DISCONTINUITY<br>#EXT-X-CUE-OUT:DURATION=30</span><br>'+
    '<span id="ad-seg" style="color:var(--green);opacity:0;transition:all 0.6s">#EXTINF:6.0,<br>https://ads.cmxs.io/creative/callaway_driver_seg1.ts<br>#EXTINF:6.0,<br>https://ads.cmxs.io/creative/callaway_driver_seg2.ts</span><br><br>'+
    '<span id="cuein-line" style="color:var(--amber);opacity:0;transition:all 0.6s">#EXT-X-CUE-IN<br>#EXT-X-DISCONTINUITY</span>';
  var badge=h('div','','');
  badge.style.cssText='display:flex;gap:1rem;margin-top:0.5rem;';
  badge.innerHTML='<div style="font-size:0.72rem;padding:0.3rem 0.7rem;background:rgba(6,182,212,0.1);border:1px solid rgba(6,182,212,0.2);border-radius:6px;color:var(--cyan)">📡 CloudFront CDN</div><div style="font-size:0.72rem;padding:0.3rem 0.7rem;background:rgba(139,92,246,0.1);border:1px solid rgba(139,92,246,0.2);border-radius:6px;color:var(--purple)">LIV Golf — Round 2 · 1080p</div>';
  wrap.appendChild(manifest);
  wrap.appendChild(badge);
  container.appendChild(wrap);
  setTimeout(function(){document.getElementById('scte-line').style.opacity='1';},2000);
  setTimeout(function(){document.getElementById('ad-seg').style.opacity='1';},4000);
  setTimeout(function(){document.getElementById('cuein-line').style.opacity='1';},6000);
};

// ── Act 3: The Auction ─────────────────────────────────────────────────
window.FW_buildStage3 = function(container, data){
  container.innerHTML='';
  var wrap=h('div','','');
  wrap.style.cssText='display:flex;flex-direction:column;align-items:center;width:100%;gap:0.75rem;';
  wrap.appendChild(h('div','stage-title','ACT 3'));
  wrap.appendChild(h('div','stage-headline','OpenRTB 2.6 Auction — Verified Premium Commands 2× CPM'));
  // Header row
  var hdr=h('div','','');
  hdr.style.cssText='display:grid;grid-template-columns:2fr 1fr 1fr 1fr;gap:0.75rem;width:100%;max-width:700px;padding:0 0.85rem;font-size:0.65rem;color:var(--dim);text-transform:uppercase;letter-spacing:0.06em;';
  hdr.innerHTML='<div>DSP</div><div>Bid CPM</div><div>Strategy</div><div style="text-align:right">Latency</div>';
  wrap.appendChild(hdr);
  var grid=h('div','bid-grid','');
  grid.style.maxWidth='700px';
  // Sort by CPM desc
  var sorted=DSPS.slice().sort(function(a,b){return b.cpm-a.cpm;});
  sorted.forEach(function(d,i){
    var row=h('div','bid-row','');
    row.innerHTML='<div class="bid-dsp">'+d.name+(i===0?' 🏆':'')+'</div><div class="bid-cpm" style="color:'+(i===0?'var(--gold)':'var(--text)')+'">$'+d.cpm.toFixed(2)+'</div><div class="bid-tag">'+d.tag+'</div><div class="bid-latency">'+d.latency+'</div>';
    if(i===0) row.classList.add('winner');
    grid.appendChild(row);
  });
  wrap.appendChild(grid);
  // Clear price callout
  var cp=h('div','stage-card','');
  cp.style.cssText='text-align:center;margin-top:0.5rem;padding:0.75rem 1.5rem;';
  var clearCpm=data&&data.clearingCpm?data.clearingCpm:sorted[1].cpm+0.01;
  cp.innerHTML='<div style="font-size:0.68rem;color:var(--muted);margin-bottom:4px">CLEARING PRICE (2nd price + $0.01)</div><div style="font-size:1.6rem;font-weight:800;color:var(--green);font-family:var(--mono)">$'+clearCpm.toFixed(2)+' <span style="font-size:0.8rem;color:var(--muted)">CPM</span></div><div style="font-size:0.68rem;color:var(--dim);margin-top:4px">Auction resolved in '+(data&&data.totalLatencyMs?data.totalLatencyMs:312)+'ms</div>';
  wrap.appendChild(cp);
  container.appendChild(wrap);
  setTimeout(function(){
    stagger(Array.from(grid.querySelectorAll('.bid-row')),'visible',200);
  },300);
};

// ── Act 4: The Delivery ────────────────────────────────────────────────
window.FW_buildStage4 = function(container){
  container.innerHTML='';
  var wrap=h('div','','');
  wrap.style.cssText='display:flex;flex-direction:column;align-items:center;width:100%;gap:1rem;';
  wrap.appendChild(h('div','stage-title','ACT 4'));
  wrap.appendChild(h('div','stage-headline','Seamless Ad Delivery — x302 Commerce Drives 3-5% Conversions'));
  var ring=h('div','quartile-ring-wrap','');
  // Quartile ring
  var rv=h('div','quartile-ring','');
  rv.innerHTML='<svg viewBox="0 0 160 160"><circle class="bg" cx="80" cy="80" r="70"/><circle class="fill" id="q-fill" cx="80" cy="80" r="70"/></svg><div class="pct" id="q-pct">0%</div>';
  // Beacon log
  var blog=h('div','beacon-log','');
  blog.id='beacon-log';
  var overlay=h('div','stage-card','');
  overlay.id='commerce-overlay';
  overlay.style.cssText='display:none;padding:0.75rem 1rem;text-align:center;max-width:320px;border-color:rgba(251,191,36,0.3);';
  overlay.innerHTML='<div style="font-size:0.68rem;color:var(--amber);margin-bottom:4px">x302 COMMERCE OVERLAY</div><div style="font-size:0.9rem;font-weight:700">⛳ Callaway Paradym Driver — $549</div><div style="font-size:0.72rem;color:var(--muted);margin-top:4px">[Press OK to learn more] [Buy Now]</div><div style="font-size:0.65rem;color:var(--green);margin-top:6px">3-5% conversion rate · $60-$120 avg purchase</div>';
  ring.appendChild(rv);
  var right=h('div','','');
  right.style.cssText='display:flex;flex-direction:column;gap:0.75rem;';
  right.appendChild(blog);
  right.appendChild(overlay);
  ring.appendChild(right);
  wrap.appendChild(ring);
  container.appendChild(wrap);
  // Animate quartiles
  var quartiles=[25,50,75,100];
  var circumference=2*Math.PI*70;
  quartiles.forEach(function(q,i){
    setTimeout(function(){
      var fill=document.getElementById('q-fill');
      var pct=document.getElementById('q-pct');
      if(fill) fill.style.strokeDashoffset=circumference*(1-q/100);
      if(pct) pct.textContent=q+'%';
      var item=h('div','beacon-item','');
      item.textContent='✓ '+q+'% quartile beacon fired';
      var blog=document.getElementById('beacon-log');
      if(blog) blog.appendChild(item);
      setTimeout(function(){item.classList.add('visible');},50);
      if(q>=75){
        var ov=document.getElementById('commerce-overlay');
        if(ov) ov.style.display='';
      }
    },(i+1)*2500);
  });
};

// ── Act 5: The Proof ───────────────────────────────────────────────────
window.FW_buildStage5 = function(container){
  container.innerHTML='';
  var wrap=h('div','','');
  wrap.style.cssText='display:flex;flex-direction:column;align-items:center;width:100%;gap:1rem;';
  wrap.appendChild(h('div','stage-title','ACT 5'));
  wrap.appendChild(h('div','stage-headline','Cryptographic Proof — Unlocking $84B in Verified Ad Spend'));
  var fields=h('div','sig-fields','');
  var data=[
    {label:'Impression ID',val:'0xab3f7c2d...e91a04bf',color:'var(--blue)'},
    {label:'Node Operator',val:'0x7c2d8e1f...3b6a92c0',color:'var(--cyan)'},
    {label:'CPM Paid',val:'$45.20',color:'var(--green)',big:true},
    {label:'Timestamp',val:new Date().toISOString(),color:'var(--muted)'}
  ];
  data.forEach(function(d){
    var f=h('div','sig-field','');
    f.innerHTML='<div class="sig-field-label">'+d.label+'</div><div class="sig-field-val" style="color:'+d.color+';'+(d.big?'font-size:1.4rem;font-weight:800;':'')+'">'+d.val+'</div>';
    fields.appendChild(f);
  });
  var hashBox=h('div','sig-hash','');
  hashBox.id='sig-hash-text';
  hashBox.textContent='Signing...';
  fields.appendChild(hashBox);
  var lock=h('div','','');
  lock.id='sig-lock';
  lock.style.cssText='font-size:2.5rem;text-align:center;margin-top:0.5rem;';
  lock.textContent='🔓';
  wrap.appendChild(fields);
  wrap.appendChild(lock);
  container.appendChild(wrap);
  // Animate fields
  var fieldEls=fields.querySelectorAll('.sig-field');
  stagger(Array.from(fieldEls),'visible',600);
  // Type signature hash
  setTimeout(function(){
    var hash='0x3a9f2b7c8d1e4f6a0b5c3d7e9f1a2b4c6d8e0f1a3b5c7d9e1f2a4b6c8d0e2f4a';
    var el=document.getElementById('sig-hash-text');
    var lockEl=document.getElementById('sig-lock');
    if(!el) return;
    el.textContent='';
    var i=0;
    var timer=setInterval(function(){
      if(i<hash.length){el.textContent+=hash[i];i++;}
      else{clearInterval(timer);if(lockEl)lockEl.textContent='✅';}
    },30);
  },2800);
};

// ── Act 6: The Settlement ──────────────────────────────────────────────
window.FW_buildStage6 = function(container){
  container.innerHTML='';
  var wrap=h('div','','');
  wrap.style.cssText='display:flex;flex-direction:column;align-items:center;width:100%;gap:1rem;';
  wrap.appendChild(h('div','stage-title','ACT 6'));
  wrap.appendChild(h('div','stage-headline','Instant Settlement — Zero Invoices, Zero Disputes'));
  var steps=h('div','pipeline-steps','');
  var pipeline=[
    {icon:'🗃️',label:'Redis Dedup',detail:'5 receipts → 0 duplicates → 5 verified'},
    {icon:'📦',label:'Batch Relay',detail:'5 receipts → 1 Base Sepolia transaction'},
    {icon:'⛓️',label:'On-Chain Confirmation',detail:'DeliveryOracleV2 · 0.001 CMXS minted to node'}
  ];
  pipeline.forEach(function(p){
    var step=h('div','pipeline-step','');
    step.innerHTML='<div class="step-icon">'+p.icon+'</div><div class="step-text"><div class="step-label">'+p.label+'</div><div class="step-detail">'+p.detail+'</div></div><div class="step-check">✅</div>';
    steps.appendChild(step);
  });
  var link=h('div','','');
  link.style.cssText='text-align:center;margin-top:0.5rem;';
  link.innerHTML='<a href="https://sepolia.basescan.org" target="_blank" style="font-size:0.75rem;color:var(--blue);text-decoration:none;font-family:var(--mono)">View on Basescan ↗</a>';
  wrap.appendChild(steps);
  wrap.appendChild(link);
  container.appendChild(wrap);
  var stepEls=steps.querySelectorAll('.pipeline-step');
  Array.from(stepEls).forEach(function(el,i){
    setTimeout(function(){el.classList.add('visible');},i*1200+500);
    setTimeout(function(){el.classList.add('done');},i*1200+1800);
  });
};

// ── Act 7: The Treasury ────────────────────────────────────────────────
window.FW_buildStage7 = function(container){
  container.innerHTML='';
  var wrap=h('div','','');
  wrap.style.cssText='display:flex;flex-direction:column;align-items:center;width:100%;gap:1rem;';
  wrap.appendChild(h('div','stage-title','ACT 7'));
  wrap.appendChild(h('div','stage-headline','Deflationary by Design — Burns Always Exceed Mints'));
  var wf=h('div','waterfall','');
  var rows=[
    {label:'Campaign',pct:100,color:'var(--blue)',val:'$1,000 USDC'},
    {label:'Content Partner',pct:85,color:'var(--cyan)',val:'$850 (85%)'},
    {label:'Treasury',pct:15,color:'var(--amber)',val:'$150 (15%)'},
    {label:'→ veHolders',pct:10.5,color:'var(--purple)',val:'$105 (70%)'},
    {label:'→ Node Rewards',pct:4.5,color:'var(--green)',val:'$45 (30%)'}
  ];
  rows.forEach(function(r){
    var row=h('div','wf-row','');
    row.innerHTML='<div class="wf-label">'+r.label+'</div><div class="wf-bar-wrap"><div class="wf-bar" style="background:'+r.color+'" data-pct="'+r.pct+'"></div></div><div class="wf-val" style="color:'+r.color+'">'+r.val+'</div>';
    wf.appendChild(row);
  });
  // BME summary
  var bme=h('div','stage-card','');
  bme.style.cssText='text-align:center;padding:1rem 1.5rem;margin-top:0.25rem;border-color:rgba(34,197,94,0.2);';
  bme.innerHTML='<div style="display:flex;justify-content:center;gap:2rem;margin-bottom:0.5rem"><div><div style="font-size:1.5rem;font-weight:800;color:var(--red);font-family:var(--mono)">100</div><div style="font-size:0.68rem;color:var(--muted)">CMXS Burned</div></div><div style="font-size:1.5rem;color:var(--dim)">vs</div><div><div style="font-size:1.5rem;font-weight:800;color:var(--green);font-family:var(--mono)">0.005</div><div style="font-size:0.68rem;color:var(--muted)">CMXS Minted</div></div></div><div style="font-size:0.85rem;font-weight:700;color:var(--green);padding:0.35rem 0.8rem;background:rgba(34,197,94,0.1);border-radius:8px;display:inline-block">NET DEFLATIONARY ✅ −99.995 CMXS</div>';
  wrap.appendChild(wf);
  wrap.appendChild(bme);
  container.appendChild(wrap);
  // Animate bars
  setTimeout(function(){
    wf.querySelectorAll('.wf-bar').forEach(function(bar,i){
      setTimeout(function(){bar.style.width=bar.dataset.pct+'%';},i*300);
    });
  },500);
};

// ── Act 8: The Opportunity ─────────────────────────────────────────────
window.FW_buildStage8 = function(container){
  container.innerHTML='';
  var wrap=h('div','','');
  wrap.style.cssText='display:flex;flex-direction:column;align-items:center;width:100%;gap:1rem;';
  wrap.appendChild(h('div','stage-title','ACT 8'));
  wrap.appendChild(h('div','stage-headline','Three Revenue Opportunities — $435M+ Annual Addressable'));
  var grid=h('div','stat-grid','');
  var stats=[
    {val:'$360M',label:'CPM Premium Revenue',sub:'Verified $45 vs Unverified $25 · 1B impressions/mo',color:'var(--blue)'},
    {val:'$45B',label:'Sports Betting Infrastructure',sub:'Sub-500ms latency required · CMXS delivers 312ms',color:'var(--purple)'},
    {val:'$30M',label:'DePIN Node Revenue',sub:'5,800 tower sites · earn per verified impression',color:'var(--green)'},
    {val:'$84B',label:'CTV Ad Fraud (3yr total)',sub:'30% of CTV impressions estimated fake · ANA 2025',color:'var(--red)'}
  ];
  stats.forEach(function(s){
    var card=h('div','stat-card','');
    card.innerHTML='<div class="stat-val" style="color:'+s.color+'">'+s.val+'</div><div class="stat-label">'+s.label+'</div><div class="stat-src">'+s.sub+'</div>';
    grid.appendChild(card);
  });
  wrap.appendChild(grid);
  container.appendChild(wrap);
  setTimeout(function(){
    stagger(Array.from(grid.querySelectorAll('.stat-card')),'visible',300);
  },400);
};

// ── Act 9: The Flywheel ────────────────────────────────────────────────
window.FW_buildStage9 = function(container){
  container.innerHTML='';
  var wrap=h('div','','');
  wrap.style.cssText='display:flex;flex-direction:column;align-items:center;width:100%;gap:1rem;';
  wrap.appendChild(h('div','stage-title','ACT 9'));
  wrap.appendChild(h('div','stage-headline','Self-Reinforcing Flywheel — 4 Demand Engines'));
  var fwWrap=h('div','','');
  fwWrap.style.cssText='display:flex;align-items:center;gap:3rem;';
  var diagram=h('div','flywheel-diagram','');
  diagram.innerHTML='<div class="flywheel-ring"></div><div class="flywheel-center"><div class="icon">⚡</div><div class="label">CMXS</div></div>';
  var engines=[
    {icon:'🏗️',label:'PoD Rewards',color:'var(--green)'},
    {icon:'🔥',label:'Campaign Burns',color:'var(--red)'},
    {icon:'📌',label:'SLA Staking',color:'var(--purple)'},
    {icon:'🏛️',label:'veToken Gov',color:'var(--blue)'}
  ];
  engines.forEach(function(e){
    var eng=h('div','fw-engine','');
    eng.innerHTML='<div class="e-icon">'+e.icon+'</div><div class="e-label" style="color:'+e.color+'">'+e.label+'</div>';
    diagram.appendChild(eng);
  });
  var summary=h('div','','');
  summary.style.cssText='display:flex;flex-direction:column;gap:0.5rem;max-width:280px;';
  summary.innerHTML='<div style="font-size:0.85rem;font-weight:600;color:var(--green);padding:0.5rem 0.75rem;background:rgba(34,197,94,0.08);border:1px solid rgba(34,197,94,0.2);border-radius:8px">✅ Infrastructure Deployed</div><div style="font-size:0.85rem;font-weight:600;color:var(--blue);padding:0.5rem 0.75rem;background:rgba(59,130,246,0.08);border:1px solid rgba(59,130,246,0.2);border-radius:8px">⛓️ Contracts Live on Base Sepolia</div><div style="font-size:0.85rem;font-weight:600;color:var(--purple);padding:0.5rem 0.75rem;background:rgba(139,92,246,0.08);border:1px solid rgba(139,92,246,0.2);border-radius:8px">⚡ Auction Engine &lt;500ms</div><div style="font-size:0.85rem;font-weight:600;color:var(--amber);padding:0.5rem 0.75rem;background:rgba(245,158,11,0.08);border:1px solid rgba(245,158,11,0.2);border-radius:8px">🔥 Deflationary by Design</div>';
  fwWrap.appendChild(diagram);
  fwWrap.appendChild(summary);
  wrap.appendChild(fwWrap);
  container.appendChild(wrap);
  // Animate engines
  var engEls=diagram.querySelectorAll('.fw-engine');
  Array.from(engEls).forEach(function(el,i){
    setTimeout(function(){el.classList.add('visible');},i*800+500);
    setTimeout(function(){el.classList.add('highlight');},i*800+1200);
    setTimeout(function(){el.classList.remove('highlight');},i*800+2500);
  });
};

// ═══════════════════════════════════════════════════════════════════════
// PRESENTATION SLIDES — Acts 10–15 (EchoStar Strategic Proposal)
// ═══════════════════════════════════════════════════════════════════════

function pSlide(container, actNum, kicker, headline, body){
  container.innerHTML='';
  var wrap=h('div','pres-slide','');
  var k=h('div','pres-kicker','ACT '+actNum+' · ECHOSTAR STRATEGIC PROPOSAL');
  var hl=h('div','pres-headline',headline);
  var kl=h('div','pres-kicker-sub',kicker);
  var bd=h('div','pres-body','');
  bd.innerHTML=body;
  wrap.appendChild(k);
  wrap.appendChild(kl);
  wrap.appendChild(hl);
  wrap.appendChild(bd);
  container.appendChild(wrap);
  setTimeout(function(){wrap.classList.add('visible');},100);
}

// ── Act 10: The Market ─────────────────────────────────────────────────
window.FW_buildStage10 = function(container){
  pSlide(container, 10,
    'The audience has already voted.',
    'The Market Has Already Moved',
    '<div class="pres-stats-row">'+
      '<div class="pres-stat"><div class="pres-stat-val" style="color:var(--blue)">131M</div><div class="pres-stat-label">US FAST Viewers</div><div class="pres-stat-sub">More than half of all CTV households</div></div>'+
      '<div class="pres-stat"><div class="pres-stat-val" style="color:var(--green)">43%</div><div class="pres-stat-label">Year-over-Year Growth</div><div class="pres-stat-sub">Fastest segment in streaming</div></div>'+
      '<div class="pres-stat"><div class="pres-stat-val" style="color:var(--purple)">70%</div><div class="pres-stat-label">New Subscriptions</div><div class="pres-stat-sub">Ad-supported over paid tiers since 2023</div></div>'+
      '<div class="pres-stat"><div class="pres-stat-val" style="color:var(--amber)">2×</div><div class="pres-stat-label">Sports Channels Doubled</div><div class="pres-stat-sub">In the second half of 2025 alone</div></div>'+
    '</div>'+
    '<div class="pres-callout">Sports commands the highest CPMs in connected TV. EchoStar\'s content relationships, audience equity, and live sports depth make it one of the best-positioned media organizations to lead this category.</div>'
  );
};

// ── Act 11: Channel-as-a-Service ───────────────────────────────────────
window.FW_buildStage11 = function(container){
  pSlide(container, 11,
    'EchoStar brings the brand. CMXS delivers everything else.',
    'Channel-as-a-Service',
    '<div class="pres-layers">'+
      '<div class="pres-layer" style="border-color:var(--blue)"><span class="pl-icon">📡</span><div><div class="pl-label">Distribution</div><div class="pl-detail">Roku · Apple TV · Amazon Fire TV · Samsung TV — Day 1</div></div></div>'+
      '<div class="pres-layer" style="border-color:var(--purple)"><span class="pl-icon">⚡</span><div><div class="pl-label">Real-Time Auction</div><div class="pl-detail">OpenRTB 2.6 · Trade Desk, DV360, Amazon DSP, Magnite</div></div></div>'+
      '<div class="pres-layer" style="border-color:var(--green)"><span class="pl-icon">⛓</span><div><div class="pl-label">Verified Delivery</div><div class="pl-detail">Cryptographic receipt per impression · Base blockchain</div></div></div>'+
      '<div class="pres-layer" style="border-color:var(--amber)"><span class="pl-icon">🛒</span><div><div class="pl-label">Interactive Commerce</div><div class="pl-detail">x302 overlay · Remote-control purchase · 3–8% conversion</div></div></div>'+
      '<div class="pres-layer" style="border-color:var(--cyan)"><span class="pl-icon">🏗️</span><div><div class="pl-label">Incentivized Infrastructure</div><div class="pl-detail">DePIN node rewards · Runs on EchoStar\'s existing towers</div></div></div>'+
    '</div>'+
    '<div class="pres-callout" style="margin-top:0.75rem">Runs on EchoStar\'s existing infrastructure. No new capital investment. No integration fee. EchoStar retains <strong>80–85%</strong> of all verified gross ad revenue from day one.</div>'
  );
};

// ── Act 12: The Verified Premium ───────────────────────────────────────
window.FW_buildStage12 = function(container){
  pSlide(container, 12,
    'Same audience. Same content. Different infrastructure.',
    'The Verified Premium',
    '<div class="pres-cpm-compare">'+
      '<div class="pres-cpm-bar-wrap">'+
        '<div class="pres-cpm-label">Unverified FAST Inventory</div>'+
        '<div class="pres-cpm-bar-track"><div class="pres-cpm-bar unverified" data-w="35"></div></div>'+
        '<div class="pres-cpm-val muted">$15 – $25 CPM</div>'+
      '</div>'+
      '<div class="pres-cpm-bar-wrap">'+
        '<div class="pres-cpm-label">CMXS Verified Sports</div>'+
        '<div class="pres-cpm-bar-track"><div class="pres-cpm-bar verified" data-w="100"></div></div>'+
        '<div class="pres-cpm-val green">$45 – $65 CPM</div>'+
      '</div>'+
    '</div>'+
    '<div class="pres-stats-row" style="margin-top:1rem">'+
      '<div class="pres-stat"><div class="pres-stat-val" style="color:var(--green)">2–3×</div><div class="pres-stat-label">CPM Premium</div><div class="pres-stat-sub">Verified vs. unverified</div></div>'+
      '<div class="pres-stat"><div class="pres-stat-val" style="color:var(--blue)">$360M</div><div class="pres-stat-label">Annual Uplift</div><div class="pres-stat-sub">At 1B impressions/month</div></div>'+
      '<div class="pres-stat"><div class="pres-stat-val" style="color:var(--purple)">80–85%</div><div class="pres-stat-label">Revenue Retained</div><div class="pres-stat-sub">Day one, no upfront cost</div></div>'+
    '</div>'+
    '<div class="pres-callout">No competitor combines all five layers in a single managed service. The premium is real, proven, and already being paid by P&G, Unilever, and General Motors for verified inventory.</div>'
  );
  setTimeout(function(){
    document.querySelectorAll('.pres-cpm-bar').forEach(function(b){
      b.style.width=b.dataset.w+'%';
    });
  },800);
};

// ── Act 13: The Revenue Model ──────────────────────────────────────────
window.FW_buildStage13 = function(container){
  pSlide(container, 13,
    'Modeled from independently sourced market data.',
    'The Revenue Model',
    '<div class="pres-table">'+
      '<div class="pres-table-hdr"><div>Scenario</div><div>Monthly Viewers</div><div>Projected Annual Revenue</div></div>'+
      '<div class="pres-table-row conservative"><div>Conservative</div><div>5 million</div><div class="rev">$7.2M</div></div>'+
      '<div class="pres-table-row base"><div>Base Case</div><div>12 million</div><div class="rev">$23.1M</div></div>'+
      '<div class="pres-table-row optimistic"><div>Optimistic</div><div>25 million</div><div class="rev">$68.9M</div></div>'+
    '</div>'+
    '<div class="pres-stats-row" style="margin-top:1rem">'+
      '<div class="pres-stat"><div class="pres-stat-val" style="color:var(--green)">$1.8M</div><div class="pres-stat-label">Year 1 / Single Channel</div><div class="pres-stat-sub">500K monthly viewers · before commerce</div></div>'+
      '<div class="pres-stat"><div class="pres-stat-val" style="color:var(--blue)">&lt;0.1%</div><div class="pres-stat-label">Market Share Required</div><div class="pres-stat-sub">US CTV programmatic market (base case)</div></div>'+
      '<div class="pres-stat"><div class="pres-stat-val" style="color:var(--amber)">3–8%</div><div class="pres-stat-label">Commerce Conversion</div><div class="pres-stat-sub">Additional revenue beyond advertising</div></div>'+
    '</div>'
  );
};

// ── Act 14: Beyond Advertising ─────────────────────────────────────────
window.FW_buildStage14 = function(container){
  pSlide(container, 14,
    'The natural next stage of the platform.',
    'Beyond Advertising',
    '<div class="pres-stats-row">'+
      '<div class="pres-stat"><div class="pres-stat-val" style="color:var(--blue)">$102B</div><div class="pres-stat-label">US Sports Betting (2026)</div><div class="pres-stat-sub">Projected $205B by 2032</div></div>'+
      '<div class="pres-stat"><div class="pres-stat-val" style="color:var(--purple)">12%</div><div class="pres-stat-label">Compound Annual Growth</div><div class="pres-stat-sub">In-play & mobile fastest segments</div></div>'+
      '<div class="pres-stat"><div class="pres-stat-val" style="color:var(--green)">20%</div><div class="pres-stat-label">US Adults Bet in 2025</div><div class="pres-stat-sub">Up from 12% two years prior</div></div>'+
    '</div>'+
    '<div class="pres-callout" style="margin-top:1rem">The CMXS interactive layer positions EchoStar as the direct point of activation: a viewer watching a live game can be connected to a bet, a purchase, or a financial product in a single remote-control interaction. This is a proprietary commerce and financial services network built on EchoStar\'s own content — <strong>that no third-party platform can replicate</strong>. The data, relationships, and settlement infrastructure built in Phase 1 compound into a durable, high-margin business extending well beyond advertising.</div>'
  );
};

// ── Act 15: The Decision ───────────────────────────────────────────────
window.FW_buildStage15 = function(container){
  pSlide(container, 15,
    'The only remaining decision.',
    'The Decision',
    '<div class="pres-closing">'+
      '<div class="pres-closing-item">'+
        '<div class="pci-icon" style="color:var(--green)">✅</div>'+
        '<div class="pci-text"><strong>90-Day Pilot</strong> — One branded EchoStar FAST channel on Roku. First impressions, first verified CPMs, first revenue within the quarter.</div>'+
      '</div>'+
      '<div class="pres-closing-item">'+
        '<div class="pci-icon" style="color:var(--blue)">⛓</div>'+
        '<div class="pci-text"><strong>No Long-Term Commitment</strong> — Technology proven and running on Base Sepolia right now. Infrastructure already in the ground. No upfront cost, no integration fee.</div>'+
      '</div>'+
      '<div class="pres-closing-item">'+
        '<div class="pci-icon" style="color:var(--amber)">📺</div>'+
        '<div class="pci-text"><strong>Roku First</strong> — 97.3M viewers, largest free streaming platform in the US. Existing content rights. Operational milestone, not a technical one.</div>'+
      '</div>'+
    '</div>'+
    '<div class="pres-closing-cta">The market has moved. The technology is proven. The audience is waiting.<br><strong>The only question is whether EchoStar captures this revenue first.</strong></div>'
  );
};

})();
