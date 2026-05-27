// s-proj.js — Financial projections + DePIN comparables
window.Sections = window.Sections || {};
window.Sections.proj = function() { return `
<p class="section-tag">Return Path</p>
<h2 class="section-title">Financial Projections & DePIN Comparables</h2>
<p class="section-sub">Year 3 implied network value of $840M–$1.44B represents an 8.4–14.4× return on the $100M initial FDV — consistent with Helium and Render precedents from comparable initial valuations, but with pre-existing infrastructure that neither had at launch.</p>
<table class="proj-table">
  <thead>
    <tr>
      <th>Metric</th>
      <th style="color:var(--muted)">Year 1</th>
      <th style="color:var(--blue)">Year 2</th>
      <th style="color:var(--green)">Year 3</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td style="font-family:var(--font-sans,Inter),sans-serif;font-weight:600;color:var(--text)">Active Nodes</td>
      <td>50–500</td>
      <td style="color:var(--blue)">2,000</td>
      <td style="color:var(--green)">10,000</td>
    </tr>
    <tr>
      <td style="font-family:var(--font-sans,Inter),sans-serif;font-weight:600;color:var(--text)">Daily Verified Deliveries</td>
      <td>72K–720K</td>
      <td style="color:var(--blue)">2.88M</td>
      <td style="color:var(--green)">14.4M</td>
    </tr>
    <tr>
      <td style="font-family:var(--font-sans,Inter),sans-serif;font-weight:600;color:var(--text)">Annual CMXS Minted (PoD)</td>
      <td>26M–263M</td>
      <td style="color:var(--blue)">Daily cap active</td>
      <td style="color:var(--green)">Daily cap active</td>
    </tr>
    <tr>
      <td style="font-family:var(--font-sans,Inter),sans-serif;font-weight:600;color:var(--text)">Gross Service Revenue</td>
      <td>$2.4M–$8M</td>
      <td style="color:var(--blue)">$42M–$84M</td>
      <td style="color:var(--green)">$84M–$144M</td>
    </tr>
    <tr>
      <td style="font-family:var(--font-sans,Inter),sans-serif;font-weight:600;color:var(--text)">Implied Network Value (10×)</td>
      <td>$24M–$80M</td>
      <td style="color:var(--blue)">$420M–$840M</td>
      <td style="color:var(--green);font-weight:900">$840M–$1.44B</td>
    </tr>
  </tbody>
</table>
<div style="font-size:11px;font-weight:700;color:var(--muted);text-transform:uppercase;letter-spacing:1px;margin-bottom:12px;margin-top:28px">DePIN Comparable Peak Returns</div>
<div class="comp-grid">
  <div class="comp-card">
    <div class="comp-name">Helium (HNT)</div>
    <div class="comp-fdv">Initial FDV: $16M</div>
    <div class="comp-peak">$5.1B</div>
    <div class="comp-mult">319× peak</div>
  </div>
  <div class="comp-card">
    <div class="comp-name">Render (RNDR)</div>
    <div class="comp-fdv">Initial FDV: $18M</div>
    <div class="comp-peak">$4.2B</div>
    <div class="comp-mult">233× peak</div>
  </div>
  <div class="comp-card">
    <div class="comp-name">Hivemapper</div>
    <div class="comp-fdv">Initial FDV: $45M</div>
    <div class="comp-peak">$420M</div>
    <div class="comp-mult">9.3× peak</div>
  </div>
  <div class="comp-card">
    <div class="comp-name">DIMO</div>
    <div class="comp-fdv">Initial FDV: $9M</div>
    <div class="comp-peak">$200M</div>
    <div class="comp-mult">22× peak</div>
  </div>
  <div class="comp-card cmxs">
    <div class="comp-name" style="color:var(--green)">CMXS</div>
    <div class="comp-fdv">Initial FDV: $100M</div>
    <div class="comp-peak" style="color:var(--green)">TBD</div>
    <div class="comp-mult" style="color:var(--muted)">8.4–14.4× Y3 model</div>
  </div>
</div>
<div style="margin-top:16px;padding:14px 18px;background:rgba(0,170,255,.05);border:1px solid rgba(0,170,255,.15);border-radius:10px;font-size:12px;color:var(--muted)">
  ⚠ <strong style="color:var(--amber)">Forward-looking statements.</strong> Financial projections are estimates only. Past DePIN performance does not guarantee future results. Token value may decrease to zero. All participants must consult independent legal, financial, and tax counsel.
</div>
`; };
document.addEventListener('DOMContentLoaded', function() {
  var el = document.getElementById('sec-proj');
  if (el) el.innerHTML = window.Sections.proj();
});
