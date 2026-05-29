"use client";

export function BurnMintFeed() {
  return (
    <div className="glass-card">
      <h2 style={{ marginTop: 0, borderBottom: '1px solid rgba(255,255,255,0.1)', paddingBottom: '0.5rem' }}>Burn / Mint Events</h2>
      <div style={{ color: '#94a3b8', marginTop: '1rem', fontStyle: 'italic' }}>
        Listening for CMXS Transfer events...
      </div>
    </div>
  );
}
