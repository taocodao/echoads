// s-ico.js — ICO stages + price ladder + use of proceeds
window.Sections = window.Sections || {};
window.Sections.ico = function() { return `
<p class="section-tag">Participate</p>
<h2 class="section-title">Four-Stage Capital Raise — $18M–$33M</h2>
<p class="section-sub">Structured to reward early conviction. Seed participants at $0.02 benefit from a 5× price appreciation to the public IDO price. Each stage uses a different legal instrument appropriate to the investor type and regulatory framework.</p>
<div class="ico-timeline">
  <div class="ico-stage">
    <div class="ico-stage-num">0</div>
    <div class="ico-stage-name">Angel / SAFE</div>
    <div class="ico-stage-price">TBD</div>
    <div class="ico-stage-fdv">Converts at Seed price</div>
    <div class="ico-stage-raise">Target: $1M–$2M</div>
    <div class="ico-stage-vest">SAFE instrument · Full KYC + accredited investor verification · Jumio</div>
  </div>
  <div class="ico-stage">
    <div class="ico-stage-num">1</div>
    <div class="ico-stage-name">Seed — Reg D 506(c)</div>
    <div class="ico-stage-price">$0.02</div>
    <div class="ico-stage-fdv">FDV: $20M · 50M CMXS</div>
    <div class="ico-stage-raise">Target: $3M–$5M</div>
    <div class="ico-stage-vest">12-month cliff · 36-month linear · Min ticket $250K · US accredited only</div>
  </div>
  <div class="ico-stage">
    <div class="ico-stage-num">2</div>
    <div class="ico-stage-name">Strategic / IEO</div>
    <div class="ico-stage-price">$0.05–0.08</div>
    <div class="ico-stage-fdv">FDV: $50M–$80M · 50M CMXS</div>
    <div class="ico-stage-raise">Target: $8M–$15M</div>
    <div class="ico-stage-vest">20% at TGE · 80% over 12 months · Binance Launchpad / Coinbase / Kraken</div>
  </div>
  <div class="ico-stage">
    <div class="ico-stage-num">3</div>
    <div class="ico-stage-name">Public IDO / TGE</div>
    <div class="ico-stage-price">$0.10</div>
    <div class="ico-stage-fdv">FDV: $100M · LBP price discovery</div>
    <div class="ico-stage-raise">Target: $6M–$11M</div>
    <div class="ico-stage-vest">Fjord Foundry LBP · Uniswap v4 Base · 20% TGE · 80% 12-month linear</div>
  </div>
</div>
<div class="price-ladder">
  <div class="ladder-node"><div class="ladder-price">$0.02</div><div class="ladder-label">Seed</div></div>
  <div class="ladder-arrow">→</div>
  <div class="ladder-node"><div class="ladder-price">$0.05</div><div class="ladder-label">Strategic</div></div>
  <div class="ladder-arrow">→</div>
  <div class="ladder-node"><div class="ladder-price">$0.08</div><div class="ladder-label">IEO</div></div>
  <div class="ladder-arrow">→</div>
  <div class="ladder-node"><div class="ladder-price">$0.10</div><div class="ladder-label">Public IDO</div></div>
  <div style="text-align:center;padding:10px 14px;border-radius:8px;background:rgba(0,232,122,.1);border:1px solid rgba(0,232,122,.2)">
    <div style="font-size:22px;font-weight:900;font-family:var(--mono);color:var(--green)">5×</div>
    <div style="font-size:10px;color:var(--muted);margin-top:2px">Seed → Public</div>
  </div>
</div>
<div class="proceeds-bar-wrap">
  <div style="font-size:11px;font-weight:700;color:var(--muted);text-transform:uppercase;letter-spacing:1px;margin-bottom:10px">Use of Proceeds ($25M midpoint)</div>
  <div class="proceeds-bar">
    <div class="proceeds-seg" data-pct="35" style="background:#00e87a;flex:0">35%</div>
    <div class="proceeds-seg" data-pct="25" style="background:#00aaff;flex:0">25%</div>
    <div class="proceeds-seg" data-pct="15" style="background:#00d4ff;flex:0">15%</div>
    <div class="proceeds-seg" data-pct="15" style="background:#ffaa00;flex:0">15%</div>
    <div class="proceeds-seg" data-pct="10" style="background:#6080ff;flex:0">10%</div>
  </div>
  <div class="proceeds-legend">
    <span><span style="display:inline-block;width:10px;height:10px;background:#00e87a;border-radius:3px"></span>Tech Dev $8.75M</span>
    <span><span style="display:inline-block;width:10px;height:10px;background:#00aaff;border-radius:3px"></span>Node Infrastructure $6.25M</span>
    <span><span style="display:inline-block;width:10px;height:10px;background:#00d4ff;border-radius:3px"></span>Legal &amp; Compliance $3.75M</span>
    <span><span style="display:inline-block;width:10px;height:10px;background:#ffaa00;border-radius:3px"></span>Marketing &amp; Community $3.75M</span>
    <span><span style="display:inline-block;width:10px;height:10px;background:#6080ff;border-radius:3px"></span>Operations &amp; Reserve $2.5M</span>
  </div>
</div>
`; };
(function() {
  var el = document.getElementById('sec-ico');
  if (el) el.innerHTML = window.Sections.ico();
})();
