// s-tokenomics.js — Token specs + animated donut chart
window.Sections = window.Sections || {};
window.Sections.tokenomics = function() { return `
<p class="section-tag">Token Design</p>
<h2 class="section-title">CMXS Token — Engineered for Utility</h2>
<p class="section-sub">Fixed supply. No discretionary mint. Rewards determined entirely by smart contract protocol rules — not managerial decisions. Four independent demand engines. Hover the allocation chart segments to see vesting schedules.</p>
<div class="token-layout">
  <div>
    <table class="token-table">
      <tr><td>Token Name</td><td>CatonMX Settlement Token</td></tr>
      <tr><td>Ticker</td><td style="color:var(--cyan)">CMXS</td></tr>
      <tr><td>Standard</td><td>ERC-20 · Base L2</td></tr>
      <tr><td>Total Supply</td><td>1,000,000,000 (fixed)</td></tr>
      <tr><td>Decimals</td><td>18</td></tr>
      <tr><td>Initial FDV</td><td style="color:var(--green)">$100,000,000</td></tr>
      <tr><td>Initial Circulating</td><td>150,000,000 (15%)</td></tr>
      <tr><td>Mint Authority</td><td style="color:var(--green)">DeliveryOracle.sol only</td></tr>
      <tr><td>Max Daily Mint</td><td>2,880,000 CMXS</td></tr>
      <tr><td>PoD Reward Rate</td><td>0.01 CMXS / verified delivery</td></tr>
      <tr><td>Blockchain</td><td>Base L2 (Coinbase / OP Stack)</td></tr>
      <tr><td>Audit</td><td style="color:var(--amber)">Trail of Bits (pre-TGE)</td></tr>
    </table>
    <div style="margin-top:14px;padding:12px 16px;background:rgba(0,232,122,.06);border:1px solid rgba(0,232,122,.2);border-radius:10px;font-size:12px;color:var(--muted)">
      ✅ <strong style="color:var(--green)">No team mint capability post-TGE.</strong> The only new CMXS entering circulation is minted by <code style="color:var(--green)">DeliveryOracle.sol</code> upon verified delivery events — verified by audit.
    </div>
  </div>
  <div>
    <div style="font-size:11px;font-weight:700;color:var(--muted);text-transform:uppercase;letter-spacing:1px;margin-bottom:12px">Token Allocation (hover segments)</div>
    <div class="donut-wrap">
      <svg id="donut-svg" class="donut-svg" viewBox="0 0 220 220"></svg>
      <div id="donut-legend" class="donut-legend"></div>
    </div>
  </div>
</div>
`; };
document.addEventListener('DOMContentLoaded', function() {
  var el = document.getElementById('sec-tokenomics');
  if (el) { el.innerHTML = window.Sections.tokenomics(); }
  // Init donut after render (ico.js initDonut reads #donut-svg)
  if (typeof initDonut === 'function') initDonut();
});
