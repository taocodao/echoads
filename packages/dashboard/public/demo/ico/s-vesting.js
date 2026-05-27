(function() {
  window.Sections = window.Sections || {};
  window.Sections['sec-vesting'] = `
    <div class="section-container">
      <div class="section-header text-center">
        <h2>Vesting Timeline</h2>
        <p class="section-subtitle">A transparent 48-month token unlock schedule ensuring long-term alignment.</p>
      </div>

      <div class="gantt-chart-container mt-5">
        <div class="gantt-chart">
          
          <div class="gantt-axis">
            <div class="gantt-tick" style="left: 0%;">0</div>
            <div class="gantt-tick" style="left: 10%;">6</div>
            <div class="gantt-tick" style="left: 20%;">12</div>
            <div class="gantt-tick" style="left: 30%;">18</div>
            <div class="gantt-tick" style="left: 40%;">24</div>
            <div class="gantt-tick" style="left: 50%;">30</div>
            <div class="gantt-tick" style="left: 60%;">36</div>
            <div class="gantt-tick" style="left: 70%;">42</div>
            <div class="gantt-tick" style="left: 80%;">48</div>
            <div class="gantt-tick" style="left: 90%;">54</div>
            <div class="gantt-tick" style="left: 100%;">60</div>
            <div class="gantt-axis-label">Months from TGE</div>
          </div>

          <div class="gantt-milestones">
            <div class="gantt-milestone ms-green" style="left: 0%;">
              <div class="ms-line"></div>
              <div class="ms-label">Month 0: TGE — 15% circulating</div>
            </div>
            <div class="gantt-milestone ms-purple" style="left: 10%;">
              <div class="ms-line"></div>
              <div class="ms-label">Month 6: Foundation begins vesting</div>
            </div>
            <div class="gantt-milestone ms-red" style="left: 20%;">
              <div class="ms-line"></div>
              <div class="ms-label">Month 12: Team cliff ends</div>
            </div>
            <div class="gantt-milestone ms-orange" style="left: 60%;">
              <div class="ms-line"></div>
              <div class="ms-label">Month 36: Seed/Strategic fully vested</div>
            </div>
            <div class="gantt-milestone ms-purple" style="left: 80%;">
              <div class="ms-line"></div>
              <div class="ms-label">Month 48: Foundation fully vested</div>
            </div>
            <div class="gantt-milestone ms-gray" style="left: 100%;">
              <div class="ms-line"></div>
              <div class="ms-label">Month 60: Team fully vested</div>
            </div>
          </div>

          <div class="gantt-rows">
            <!-- Liquidity Provision (2%) - Unlocked TGE -->
            <div class="gantt-row">
              <div class="gantt-label">Liquidity Provision (2%)</div>
              <div class="gantt-track">
                <div class="gantt-bar gb-teal" style="left: 0%; width: 2%;" data-target-width="2%"></div>
              </div>
            </div>

            <!-- Public ICO (10%) - 20% TGE, 12m linear -->
            <div class="gantt-row">
              <div class="gantt-label">Public ICO (10%)</div>
              <div class="gantt-track">
                <div class="gantt-bar gb-red tge-block" style="left: 0%; width: 0%;" data-target-width="20%"></div>
                <div class="gantt-bar gb-red" style="left: 0%; width: 0%;" data-target-width="20%"></div>
              </div>
            </div>

            <!-- Foundation Treasury (20%) - 6m cliff, 24m linear -->
            <div class="gantt-row">
              <div class="gantt-label">Foundation Treasury (20%)</div>
              <div class="gantt-track">
                <div class="gantt-bar gb-purple" style="left: 10%; width: 0%;" data-target-width="40%"></div>
              </div>
            </div>

            <!-- Seed / Strategic Round (10%) - 12m cliff, 36m linear -->
            <div class="gantt-row">
              <div class="gantt-label">Seed / Strategic (10%)</div>
              <div class="gantt-track">
                <div class="gantt-bar gb-orange" style="left: 20%; width: 0%;" data-target-width="60%"></div>
              </div>
            </div>

            <!-- Ecosystem Grants (15%) - 12m cliff, 36m linear -->
            <div class="gantt-row">
              <div class="gantt-label">Ecosystem Grants (15%)</div>
              <div class="gantt-track">
                <div class="gantt-bar gb-green" style="left: 20%; width: 0%;" data-target-width="60%"></div>
              </div>
            </div>

            <!-- Team & Advisors (8%) - 12m cliff, 48m linear -->
            <div class="gantt-row">
              <div class="gantt-label">Team & Advisors (8%)</div>
              <div class="gantt-track">
                <div class="gantt-bar gb-gray" style="left: 20%; width: 0%;" data-target-width="80%"></div>
              </div>
            </div>

            <!-- Node Rewards (35%) - On demand -->
            <div class="gantt-row">
              <div class="gantt-label">Node Rewards (35%)</div>
              <div class="gantt-track">
                <div class="gantt-bar gb-blue dashed" style="left: 0%; width: 100%;">
                  <span class="bar-note">On-demand mint only. No vesting schedule. Daily cap enforced.</span>
                </div>
              </div>
            </div>
          </div>
          
        </div>
      </div>
    </div>
  `;
})();
