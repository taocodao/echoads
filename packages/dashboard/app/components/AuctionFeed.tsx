"use client";

import { useEffect, useState } from "react";

export function AuctionFeed() {
  const [auctions, setAuctions] = useState<any[]>([]);

  useEffect(() => {
    const fetchAuctions = async () => {
      try {
        const res = await fetch("http://localhost:3001/api/auction/recent");
        const data = await res.json();
        if (data.auctions) setAuctions(data.auctions);
      } catch (err) {
        console.error(err);
      }
    };
    fetchAuctions();
    const interval = setInterval(fetchAuctions, 5000);
    return () => clearInterval(interval);
  }, []);

  return (
    <div className="glass-card">
      <h2 style={{ marginTop: 0, borderBottom: '1px solid rgba(255,255,255,0.1)', paddingBottom: '0.5rem' }}>Live Auctions</h2>
      <div style={{ maxHeight: '300px', overflowY: 'auto', marginTop: '1rem', display: 'flex', flexDirection: 'column', gap: '0.5rem' }}>
        {auctions.length === 0 ? <div style={{ color: '#94a3b8' }}>Waiting for auctions...</div> : null}
        {auctions.map(a => (
          <div key={a.id} style={{ fontSize: '0.85rem', background: 'rgba(0,0,0,0.2)', padding: '0.5rem', borderRadius: '6px' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '0.25rem' }}>
              <span style={{ color: '#3b82f6' }}>{a.slot_id.substring(0, 8)}...</span>
              <strong style={{ color: '#10b981' }}>${(Number(a.winning_cpm) / 100).toFixed(2)} CPM</strong>
            </div>
            <div style={{ color: '#94a3b8' }}>Winner: {a.winner_address.substring(0, 10)}...</div>
          </div>
        ))}
      </div>
    </div>
  );
}
