"use client";

import { useEffect, useState } from "react";

interface AuctionRow {
  id: string | number;
  slot_id: string;
  winning_cpm: number | string;
  winner_address: string;
  created_at?: string;
}

const API_BASE = process.env.NEXT_PUBLIC_API_URL ?? "http://localhost:3001";

export function AuctionFeed() {
  const [auctions, setAuctions] = useState<AuctionRow[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const fetchAuctions = async () => {
      try {
        const res = await fetch(`${API_BASE}/api/auction/recent`);
        if (!res.ok) throw new Error(`HTTP ${res.status}`);
        const data = await res.json();
        if (data.auctions) {
          setAuctions(data.auctions);
          setError(null);
        }
      } catch (err) {
        console.error("[AuctionFeed]", err);
        setError("API unavailable — showing cached data.");
      } finally {
        setLoading(false);
      }
    };

    fetchAuctions();
    const interval = setInterval(fetchAuctions, 5000);
    return () => clearInterval(interval);
  }, []);

  function shortAddr(addr: string) {
    if (!addr || addr.length < 10) return addr;
    return `${addr.slice(0, 8)}…${addr.slice(-4)}`;
  }

  function formatCpm(cpm: number | string) {
    return (Number(cpm) / 100).toFixed(2);
  }

  function timeAgo(iso?: string) {
    if (!iso) return "";
    const diff = Math.floor((Date.now() - new Date(iso).getTime()) / 1000);
    if (diff < 60) return `${diff}s ago`;
    return `${Math.floor(diff / 60)}m ago`;
  }

  return (
    <div className="glass-card">
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "0.5rem" }}>
        <h2 style={{ margin: 0 }}>Live Auctions</h2>
        <div style={{ display: "flex", alignItems: "center", gap: "0.5rem", fontSize: "0.8rem" }}>
          <span
            style={{
              width: 8, height: 8, borderRadius: "50%",
              background: error ? "#ef4444" : "#10b981",
              display: "inline-block",
              boxShadow: error ? "0 0 6px #ef4444" : "0 0 6px #10b981",
            }}
          />
          <span style={{ color: "#94a3b8" }}>{error ? "Offline" : "Polling 5s"}</span>
        </div>
      </div>

      {error && (
        <div style={{ fontSize: "0.75rem", color: "#f59e0b", marginBottom: "0.75rem" }}>⚠ {error}</div>
      )}

      <div style={{ maxHeight: "320px", overflowY: "auto", display: "flex", flexDirection: "column", gap: "0.5rem", marginTop: "0.75rem" }}>
        {loading && auctions.length === 0 ? (
          <div style={{ color: "#94a3b8", fontStyle: "italic", textAlign: "center", padding: "1rem 0" }}>Loading auctions…</div>
        ) : auctions.length === 0 ? (
          <div style={{ color: "#94a3b8", fontStyle: "italic", textAlign: "center", padding: "1rem 0" }}>
            <span style={{ fontSize: "1.2rem" }}>⚡</span>
            <div style={{ marginTop: "0.5rem" }}>Waiting for first auction…</div>
          </div>
        ) : (
          auctions.map((a) => (
            <div
              key={a.id}
              style={{
                fontSize: "0.85rem",
                background: "rgba(59, 130, 246, 0.07)",
                border: "1px solid rgba(59,130,246,0.2)",
                padding: "0.55rem 0.75rem",
                borderRadius: "8px",
              }}
            >
              <div style={{ display: "flex", justifyContent: "space-between", marginBottom: "0.25rem" }}>
                <span style={{ color: "#3b82f6", fontFamily: "monospace" }}>
                  {typeof a.slot_id === "string" ? a.slot_id.substring(0, 10) : a.slot_id}…
                </span>
                <strong style={{ color: "#10b981" }}>${formatCpm(a.winning_cpm)} CPM</strong>
              </div>
              <div style={{ display: "flex", justifyContent: "space-between", color: "#94a3b8", fontSize: "0.78rem" }}>
                <span>Winner: <span style={{ color: "#cbd5e1" }}>{shortAddr(a.winner_address)}</span></span>
                {a.created_at && <span>{timeAgo(a.created_at)}</span>}
              </div>
            </div>
          ))
        )}
      </div>
    </div>
  );
}
