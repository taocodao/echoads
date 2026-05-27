(function() {
  window.Sections = window.Sections || {};
  window.Sections['sec-legal'] = `
    <div class="section-container">
      <div class="section-header text-center">
        <h2>Open Source Smart Contracts</h2>
        <p class="section-subtitle">The complete protocol suite is deployed on Base Sepolia. Don't trust us. Read the code.</p>
      </div>

      <div class="contracts-grid mt-5">
        <div class="contract-item">
          <div class="c-icon">📄</div>
          <div class="c-info">
            <div class="c-name">CMXS.sol</div>
            <div class="c-desc">ERC-20 token with controlled mint/burn and daily cap</div>
          </div>
          <a href="#" class="c-link">View on Basescan ↗</a>
        </div>
        
        <div class="contract-item">
          <div class="c-icon">⚖️</div>
          <div class="c-info">
            <div class="c-name">DeliveryOracle.sol</div>
            <div class="c-desc">Verifies Proof-of-Delivery SLA receipts</div>
          </div>
          <a href="#" class="c-link">View on Basescan ↗</a>
        </div>
        
        <div class="contract-item">
          <div class="c-icon">🖥️</div>
          <div class="c-info">
            <div class="c-name">NodeRegistry.sol</div>
            <div class="c-desc">Node registration, stake management, slash logic</div>
          </div>
          <a href="#" class="c-link">View on Basescan ↗</a>
        </div>
        
        <div class="contract-item">
          <div class="c-icon">💵</div>
          <div class="c-info">
            <div class="c-name">ServiceBuyerEscrow.sol</div>
            <div class="c-desc">USDC escrow + burn discount tier management</div>
          </div>
          <a href="#" class="c-link">View on Basescan ↗</a>
        </div>
        
        <div class="contract-item">
          <div class="c-icon">🗳️</div>
          <div class="c-info">
            <div class="c-name">GovernanceStaking.sol</div>
            <div class="c-desc">veCMXS lock/unlock, voting weight, fee distribution</div>
          </div>
          <a href="#" class="c-link">View on Basescan ↗</a>
        </div>
        
        <div class="contract-item">
          <div class="c-icon">🏦</div>
          <div class="c-info">
            <div class="c-name">Treasury.sol</div>
            <div class="c-desc">Foundation treasury; Ecosystem Grant distribution</div>
          </div>
          <a href="#" class="c-link">View on Basescan ↗</a>
        </div>

        <div class="contract-item">
          <div class="c-icon">⏳</div>
          <div class="c-info">
            <div class="c-name">VestingVault.sol</div>
            <div class="c-desc">Team/investor cliff + linear vesting enforcement</div>
          </div>
          <a href="#" class="c-link">View on Basescan ↗</a>
        </div>
      </div>

      <div class="legal-collapse mt-5">
        <button class="legal-toggle" id="legal-toggle-btn">
          <span>IMPORTANT LEGAL NOTICE</span>
          <span class="legal-arrow">▼</span>
        </button>
        <div class="legal-content" id="legal-content-body">
          <p>This website is published by CMXS Foundation Ltd. (Cayman Islands Exempted Company) for informational purposes only.</p>
          <p>CMXS tokens are utility tokens designed for functional use within the CMXS Decentralised Physical Infrastructure Network (DePIN). They are not designed or intended to constitute a security, commodity, or regulated investment product in any jurisdiction.</p>
          <p>UNITED STATES: CMXS tokens are offered only to verified accredited investors during Angel and Seed rounds under SEC Regulation D Rule 506(c). Public IDO participation is not available to US retail investors.</p>
          <p>EUROPEAN UNION: This token offering will be filed with the relevant National Competent Authority under MiCA before any public offering to EU residents.</p>
          <p>OFAC COMPLIANCE: CMXS Foundation will not sell tokens to individuals, entities, or wallets associated with OFAC-sanctioned jurisdictions.</p>
          <p>NO GUARANTEE OF VALUE: Token purchasers may lose their entire investment. Cryptocurrency markets are highly volatile. Past performance is not indicative of future results.</p>
          <p class="copyright">© 2026 CMXS Foundation Ltd. All rights reserved.</p>
        </div>
      </div>
    </div>
  `;
})();
