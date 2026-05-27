(function() {
  window.Sections = window.Sections || {};
  window.Sections['sec-pod'] = `
    <div class="section-container">
      <div class="section-header text-center">
        <h2>Proof-of-Delivery (PoD) — The Consensus Mechanism That Powers CMXS</h2>
        <p class="section-subtitle" style="text-align: left;">Every blockchain needs a way to decide: "Did real work happen? Does the network deserve to be paid?" Bitcoin uses Proof-of-Work: computers compete to solve pointless mathematical puzzles. Ethereum uses Proof-of-Stake: the richest token holders get to validate transactions. <strong>CMXS uses Proof-of-Delivery: nodes get paid for doing exactly what the network needs — delivering verified content to real devices, on time, fast.</strong></p>
      </div>

      <div class="pod-flow-container">
        <h3 class="text-center" style="margin-bottom: 2rem;">One PoD Event — What Happens in Under 2 Seconds</h3>
        <div class="pod-flow">
          <div class="pod-line"></div>
          
          <div class="pod-step">
            <div class="pod-step-num">1</div>
            <div class="pod-step-content">
              <div class="pod-step-header">
                <h4>REQUEST</h4>
                <span class="pod-badge">0ms</span>
              </div>
              <p>A viewer's device requests content via the CMXS network.</p>
            </div>
          </div>

          <div class="pod-step">
            <div class="pod-step-num">2</div>
            <div class="pod-step-content">
              <div class="pod-step-header">
                <h4>DELIVERY</h4>
                <span class="pod-badge">~287ms measured average</span>
              </div>
              <p>The nearest CMXS node delivers the content over QUIC — a next-generation internet protocol that eliminates buffering delays. Content arrives in under 500ms.</p>
            </div>
          </div>

          <div class="pod-step">
            <div class="pod-step-num">3</div>
            <div class="pod-step-content">
              <div class="pod-step-header">
                <h4>RECEIPT</h4>
                <span class="pod-badge">~50ms to generate</span>
              </div>
              <p>The viewer's device automatically signs a cryptographic "delivery receipt" — a mathematical fingerprint proving: this exact content, to this device, at this time, at this speed. This receipt cannot be forged.</p>
            </div>
          </div>

          <div class="pod-step">
            <div class="pod-step-num">4</div>
            <div class="pod-step-content">
              <div class="pod-step-header">
                <h4>PAYMENT</h4>
                <span class="pod-badge">~2 seconds to settle</span>
              </div>
              <p>The service buyer's wallet automatically sends a micro-payment (fractions of a cent in USDC) via the x402 protocol, recorded on the Base blockchain.</p>
            </div>
          </div>

          <div class="pod-step">
            <div class="pod-step-num">5</div>
            <div class="pod-step-content">
              <div class="pod-step-header">
                <h4>VERIFICATION</h4>
                <span class="pod-badge">~100ms</span>
              </div>
              <p>The Delivery Oracle smart contract checks: Was the receipt valid? Was the payment confirmed? Was the speed under 500ms?</p>
            </div>
          </div>

          <div class="pod-step">
            <div class="pod-step-num">6</div>
            <div class="pod-step-content">
              <div class="pod-step-header">
                <h4>REWARD</h4>
                <span class="pod-badge">automatic, immediate</span>
              </div>
              <p>The DeliveryOracle.sol smart contract automatically mints 0.001 CMXS to the node operator's wallet. No invoice. No approval. No delay.</p>
            </div>
          </div>

          <div class="pod-step">
            <div class="pod-step-num">7</div>
            <div class="pod-step-content">
              <div class="pod-step-header">
                <h4>PERMANENT PROOF</h4>
                <span class="pod-badge">permanent</span>
              </div>
              <p>An immutable SLA proof record is written to Base. The service buyer receives a transaction hash — a permanent, publicly verifiable link proving delivery occurred. Auditable forever.</p>
            </div>
          </div>
        </div>
      </div>

      <div class="pod-comparison mt-5">
        <h3 class="text-center" style="margin-bottom: 2rem;">Consensus Comparison</h3>
        <div class="table-responsive">
          <table class="ico-table pod-table">
            <thead>
              <tr>
                <th>Mechanism</th>
                <th>What gets rewarded</th>
                <th>Energy use</th>
                <th>Useful for CMXS?</th>
              </tr>
            </thead>
            <tbody>
              <tr class="row-pow">
                <td><strong>Proof-of-Work</strong> (Bitcoin)</td>
                <td>Computer power solving puzzles</td>
                <td>Enormous (~700kWh per transaction)</td>
                <td>❌ The puzzle has nothing to do with content delivery</td>
              </tr>
              <tr class="row-pos">
                <td><strong>Proof-of-Stake</strong> (Ethereum)</td>
                <td>Token holdings</td>
                <td>Low</td>
                <td>❌ Rich validators earn more; infrastructure quality irrelevant</td>
              </tr>
              <tr class="row-pod">
                <td><strong>Proof-of-Delivery</strong> (CMXS)</td>
                <td>Delivering verified content under 500ms</td>
                <td>Minimal (no computational waste)</td>
                <td>✅ Every reward = proven delivery. No delivery = no reward.</td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>

      <div class="pod-security mt-5">
        <h3 class="text-center" style="margin-bottom: 2rem;">How Does PoD Prevent Cheating?</h3>
        <div class="pod-cards-grid">
          <div class="flip-card">
            <div class="flip-card-inner">
              <div class="flip-card-front">
                <h4>Can a node fake a delivery?</h4>
                <div class="flip-icon">🛡️</div>
                <div class="flip-instruction">Hover to reveal</div>
              </div>
              <div class="flip-card-back">
                <p>No. The delivery receipt must be signed by the VIEWER'S wallet. A node cannot forge the viewer's signature. The x402 payment provides an independent second confirmation on a completely separate cryptographic path.</p>
              </div>
            </div>
          </div>

          <div class="flip-card">
            <div class="flip-card-inner">
              <div class="flip-card-front">
                <h4>Can a node claim the same reward twice?</h4>
                <div class="flip-icon">🔄</div>
                <div class="flip-instruction">Hover to reveal</div>
              </div>
              <div class="flip-card-back">
                <p>No. Every delivery receipt has a unique ID. The smart contract stores every ID it has seen. A second submission is rejected with "Proof already used."</p>
              </div>
            </div>
          </div>

          <div class="flip-card">
            <div class="flip-card-inner">
              <div class="flip-card-front">
                <h4>What if someone hacks the oracle?</h4>
                <div class="flip-icon">🔐</div>
                <div class="flip-instruction">Hover to reveal</div>
              </div>
              <div class="flip-card-back">
                <p>The daily mint cap is hardcoded at 2,880,000 CMXS/day. Even a complete oracle compromise cannot produce more than 0.288% of total supply in 24 hours. In Phase 1, the oracle migrates to Chainlink (decentralised), eliminating this risk.</p>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  `;
})();
