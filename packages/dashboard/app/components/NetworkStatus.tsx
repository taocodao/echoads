"use client";

import { useEffect, useState } from "react";

export function NetworkStatus() {
  const [nodes, setNodes] = useState([
    { id: "relay-1", status: "online", latency: 24, load: "45%" },
    { id: "relay-2", status: "online", latency: 31, load: "62%" },
    { id: "relay-3", status: "pending", latency: "-", load: "-" },
  ]);

  return (
    <div className="glass-card">
      <h2 style={{ marginTop: 0, borderBottom: '1px solid rgba(255,255,255,0.1)', paddingBottom: '0.5rem' }}>MoQ Network Status</h2>
      <div style={{ display: 'flex', flexDirection: 'column', gap: '1rem', marginTop: '1rem' }}>
        {nodes.map(n => (
          <div key={n.id} style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', background: 'rgba(0,0,0,0.2)', padding: '0.75rem', borderRadius: '8px' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
              <div style={{ width: '10px', height: '10px', borderRadius: '50%', background: n.status === 'online' ? '#10b981' : '#f59e0b' }} />
              <strong>{n.id}</strong>
            </div>
            <div style={{ fontSize: '0.9rem', color: '#cbd5e1', display: 'flex', gap: '1.5rem' }}>
              <span>Lat: {n.latency}{n.latency !== "-" ? "ms" : ""}</span>
              <span>Load: {n.load}</span>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
