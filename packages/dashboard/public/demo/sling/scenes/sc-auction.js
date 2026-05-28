window.SlingScenes = window.SlingScenes || {};
window.SlingScenes['sc-auction'] = function() {
  setTimeout(() => {
    document.getElementById('browser-url-text').textContent = 'https://echoads.tv/auction/openrtb';
    
    // Animation sequence
    const cards = document.querySelectorAll('.bid-card');
    const result = document.getElementById('auction-result-panel');
    
    // Slide in cards
    cards.forEach((card, i) => {
      setTimeout(() => {
        card.style.opacity = '1';
        card.style.transform = 'translateY(0)';
      }, 500 + (i * 200));
    });
    
    // Animate numbers and pick winner
    setTimeout(() => {
      const bidEls = [
        document.getElementById('bid-1'),
        document.getElementById('bid-2'),
        document.getElementById('bid-3')
      ];
      
      const targets = [47.20, 58.40, 41.30];
      
      let iters = 0;
      const iv = setInterval(() => {
        iters++;
        bidEls[0].textContent = '$' + (Math.random() * 47).toFixed(2);
        bidEls[1].textContent = '$' + (Math.random() * 58).toFixed(2);
        bidEls[2].textContent = '$' + (Math.random() * 41).toFixed(2);
        
        if (iters > 15) {
          clearInterval(iv);
          bidEls[0].textContent = '$47.20';
          bidEls[1].textContent = '$58.40';
          bidEls[2].textContent = '$41.30';
          
          // Mark winner
          setTimeout(() => {
            cards[0].classList.add('loser');
            cards[2].classList.add('loser');
            
            cards[1].classList.add('winner');
            document.getElementById('status-1').textContent = '❌ Outbid';
            document.getElementById('status-2').innerHTML = '✅ Winner';
            document.getElementById('status-2').style.color = 'var(--green)';
            document.getElementById('status-3').textContent = '❌ Outbid';
            
            // Show result panel
            setTimeout(() => {
              result.style.opacity = '1';
              result.style.transform = 'translateY(0)';
              
              // Animate latency
              let lat = 0;
              const latIv = setInterval(() => {
                lat += 7;
                if (lat >= 87) {
                  lat = 87;
                  clearInterval(latIv);
                }
                document.getElementById('auc-lat').textContent = lat + 'ms';
              }, 30);
            }, 800);
          }, 400);
        }
      }, 50);
    }, 1500);
  }, 10);
  
  return `
    <div class="sling-scene" style="padding:24px;">
      <div class="scene-strip" style="margin-bottom:18px">
        <span class="scene-badge">Phase 4</span>
        <span class="scene-title">Real-Time Auction</span>
      </div>
      
      <div class="auction-cards">
        <div class="bid-card" style="opacity:0; transform:translateY(20px);">
          <div style="font-size:24px;margin-bottom:8px;">🏃</div>
          <div style="font-weight:700;">Nike Sports</div>
          <div style="font-size:10px;color:var(--muted);margin-bottom:12px;">Base CPM: $45</div>
          <div class="bid-amount" id="bid-1">$0.00</div>
          <div style="font-size:11px;color:var(--muted);font-weight:700;" id="status-1">Bidding...</div>
        </div>
        
        <div class="bid-card" style="opacity:0; transform:translateY(20px);">
          <div style="font-size:24px;margin-bottom:8px;">🎰</div>
          <div style="font-weight:700;">DraftKings</div>
          <div style="font-size:10px;color:var(--muted);margin-bottom:12px;">Base CPM: $62</div>
          <div class="bid-amount" id="bid-2">$0.00</div>
          <div style="font-size:11px;color:var(--muted);font-weight:700;" id="status-2">Bidding...</div>
        </div>
        
        <div class="bid-card" style="opacity:0; transform:translateY(20px);">
          <div style="font-size:24px;margin-bottom:8px;">🥤</div>
          <div style="font-weight:700;">Pepsi</div>
          <div style="font-size:10px;color:var(--muted);margin-bottom:12px;">Base CPM: $38</div>
          <div class="bid-amount" id="bid-3">$0.00</div>
          <div style="font-size:11px;color:var(--muted);font-weight:700;" id="status-3">Bidding...</div>
        </div>
      </div>
      
      <div class="auction-result" id="auction-result-panel" style="opacity:0; transform:translateY(20px); transition:all 0.5s ease;">
        <div style="display:flex;justify-content:space-between;align-items:center;">
          <div style="text-align:left;">
            <div style="font-size:11px;color:var(--muted);">Clearing Price</div>
            <div style="font-size:20px;font-weight:900;font-family:var(--mono);">$47.21</div>
            <div style="font-size:10px;color:var(--muted);">Second-price + $0.01</div>
          </div>
          <div style="text-align:center;">
            <div style="font-size:11px;color:var(--muted);">Auction Latency</div>
            <div style="font-size:20px;font-weight:900;font-family:var(--mono);color:var(--green);" id="auc-lat">0ms</div>
            <div style="font-size:10px;color:var(--muted);">OpenRTB 2.6</div>
          </div>
          <div style="text-align:right;">
            <div style="font-size:11px;color:var(--muted);">VAST Creative</div>
            <div style="font-size:12px;font-weight:700;font-family:var(--mono);color:var(--cyan);margin-top:4px;">dk_pre_001.xml</div>
            <div style="font-size:10px;color:var(--muted);">Stitched into manifest</div>
          </div>
        </div>
      </div>
    </div>
  `;
};
