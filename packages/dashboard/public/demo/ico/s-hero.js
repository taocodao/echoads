(function() {
  window.Sections = window.Sections || {};
  window.Sections['sec-hero'] = `
    <div class="hero-content">
      <div class="hero-badge animate-fade-in-up" style="animation-delay: 0.1s;">
        <span class="badge-text">CMXS Foundation · ICO 2026 · Base L2</span>
      </div>
      <h1 class="hero-title animate-fade-in-up" style="animation-delay: 0.2s;">The First DePIN With Pre-Built Infrastructure</h1>
      <p class="hero-subtitle animate-fade-in-up" style="animation-delay: 0.3s;">
        While others build infrastructure from scratch, CMXS launches with 5,800 existing EchoStar broadcast towers — transforming real-world assets into a cryptographically verified delivery network for the $40B connected TV market.
      </p>
      
      <div class="hero-stats-strip">
        <div class="hero-stat-card glow-pulse animate-fade-in-up" style="animation-delay: 0.4s;">
          <div class="stat-value">$100M</div>
          <div class="stat-label">Initial FDV at TGE</div>
        </div>
        <div class="hero-stat-card animate-fade-in-up" style="animation-delay: 0.5s;">
          <div class="stat-value">1,000,000,000</div>
          <div class="stat-label">Total CMXS Supply</div>
        </div>
        <div class="hero-stat-card animate-fade-in-up" style="animation-delay: 0.6s;">
          <div class="stat-value">$18M–$33M</div>
          <div class="stat-label">Target Raise</div>
        </div>
        <div class="hero-stat-card animate-fade-in-up" style="animation-delay: 0.7s;">
          <div class="stat-value">&lt;500ms</div>
          <div class="stat-label">Delivery SLA</div>
        </div>
      </div>

      <div class="hero-actions animate-fade-in-up" style="animation-delay: 0.8s;">
        <button class="btn-ico primary large" onclick="window.location.href='/whitelist'">Join the Waitlist &rarr;</button>
        <button class="btn-ico outline large" onclick="document.getElementById('sec-legal').scrollIntoView({behavior: 'smooth'})">Smart Contracts &nearr;</button>
        <button class="btn-ico accent large" onclick="if(window.startTour) window.startTour()">Narrated Tour &#9654;</button>
      </div>

      <div class="hero-bottom-line animate-fade-in-up" style="animation-delay: 0.9s;">
        <span class="status-dot green"></span> Phase 0 Complete &middot; 287ms P50 &middot; 312ms P95
      </div>
    </div>
  `;
})();
