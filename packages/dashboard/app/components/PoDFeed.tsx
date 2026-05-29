"use client";

import { useEffect, useState } from "react";

export function PoDFeed() {
  const [pods, setPods] = useState<any[]>([]);

  return (
    <div className="glass-card">
      <h2 style={{ marginTop: 0, borderBottom: '1px solid rgba(255,255,255,0.1)', paddingBottom: '0.5rem' }}>On-Chain PoD Feed</h2>
      <div style={{ maxHeight: '300px', overflowY: 'auto', marginTop: '1rem', display: 'flex', flexDirection: 'column', gap: '0.5rem' }}>
        {pods.length === 0 ? <div style={{ color: '#94a3b8' }}>Listening for PoD events...</div> : null}
        {pods.map((p, i) => (
          <div key={i} style={{ fontSize: '0.85rem', background: 'rgba(0,0,0,0.2)', padding: '0.5rem', borderRadius: '6px' }}>
            <div><strong style={{ color: '#8b5cf6' }}>Hash:</strong> {p.hash}</div>
            <div style={{ color: '#94a3b8', display: 'flex', justifyContent: 'space-between', marginTop: '0.25rem' }}>
              <span>Node: {p.node}</span>
              <a href={`https://sepolia.basescan.org/tx/${p.tx}`} target="_blank" style={{ color: '#3b82f6', textDecoration: 'underline' }}>View Tx</a>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
