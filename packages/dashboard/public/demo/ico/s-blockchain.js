(function() {
  window.Sections = window.Sections || {};
  window.Sections['sec-blockchain'] = `
    <div class="section-container">
      <div class="section-header text-center">
        <h2>How the Blockchain Makes Delivery Trustless</h2>
        <p class="section-subtitle">You don't need to understand crypto to understand why this matters. Here's what the CMXS blockchain actually does — in plain language.</p>
      </div>

      <div class="blockchain-cards-grid">
        <div class="bc-card bc-red">
          <div class="bc-icon">🏢</div>
          <h3>The Problem with Trusting the Platform</h3>
          <p>When you buy digital advertising — or any time-critical delivery service — today, you pay the platform, and the platform tells you it worked. There is no independent proof. The platform's own software reports whether your content was delivered. Industry figures: USD 84 billion in ad fraud annually. 30% more inventory sold than actually delivered. The IAB calls this "an honour system."</p>
        </div>
        
        <div class="bc-card bc-blue">
          <div class="bc-icon">🔗</div>
          <h3>What a Blockchain Actually Does</h3>
          <p>A blockchain is a digital ledger that nobody controls. Think of it as a public noticeboard: once something is written on it, it can never be erased, altered, or disputed — not by us, not by the buyer, not by anyone. Every time a CMXS network node delivers content, a cryptographic receipt is written to the Base blockchain — permanently. The receipt includes: exactly what was delivered, to which device, at what time, and how fast. This isn't a report from the platform. It's an immutable mathematical proof, created automatically, that anyone can verify on Basescan.etherscan.io.</p>
        </div>

        <div class="bc-card bc-green">
          <div class="bc-icon">⛓</div>
          <h3>Why We Use the Base Blockchain</h3>
          <p>We chose Base (built by Coinbase) because it: (1) Costs USD 0.0001 per transaction — cheap enough to record every single delivery event. (2) Settles in 2 seconds — fast enough for real-time verification. (3) Supports "x402" payments — the new Coinbase standard for machine-to-machine micropayments. (4) Is backed by Coinbase — the largest US regulated crypto exchange.</p>
        </div>
      </div>

      <div class="blockchain-guarantees">
        <h3>Five Things the Blockchain Guarantees</h3>
        <ul class="guarantee-list">
          <li><span class="check-animate">✅</span> 1. Every delivery is recorded — a proof is written on-chain the moment content reaches a device.</li>
          <li><span class="check-animate">✅</span> 2. Every payment is on-chain — linked to the delivery proof. You can't have a reward without a real payment.</li>
          <li><span class="check-animate">✅</span> 3. Node rewards are automatic — smart contracts pay node operators automatically when delivery is verified.</li>
          <li><span class="check-animate">✅</span> 4. Token supply is controlled by code — no CMXS team member can create new tokens.</li>
          <li><span class="check-animate">✅</span> 5. Everything is auditable — every transaction is publicly visible on Basescan.</li>
        </ul>
      </div>

      <div class="faq-accordion">
        <div class="faq-item">
          <button class="faq-q">Q: Do I need to understand crypto to use CMXS or invest?</button>
          <div class="faq-a"><p>A: No. Service buyers pay in USDC (a USD-pegged stablecoin). Node operators receive CMXS automatically. The blockchain is infrastructure — like the internet protocol behind a website.</p></div>
        </div>
        <div class="faq-item">
          <button class="faq-q">Q: What is a "smart contract"?</button>
          <div class="faq-a"><p>A: Software code that runs on the blockchain and executes automatically when conditions are met — like a vending machine. Our contracts are open-source, publicly auditable, and cannot be modified by the CMXS team after deployment.</p></div>
        </div>
        <div class="faq-item">
          <button class="faq-q">Q: Can the CMXS team change the token supply or rules?</button>
          <div class="faq-a"><p>A: No. Post-TGE, the CMXS token contract's mint authority belongs exclusively to the DeliveryOracle.sol smart contract. No team wallet, no admin key can trigger a direct mint. Protocol changes require a veCMXS governance vote with a 66% supermajority.</p></div>
        </div>
      </div>
    </div>
  `;
})();
