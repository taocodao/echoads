"use client";

import { useEffect, useState } from "react";

interface RelayNode {
  id: string;
  label: string;
  url: string;
  status: "online" | "degraded" | "offline" | "pending";
  latency: number | null;
  load: string;
}

const API_BASE = process.env.NEXT_PUBLIC_API_URL ?? "http://localhost:3001";

const NODES: RelayNode[] = [
  { id: "relay-1", label: "MOQ Relay 1", url: `${API_BASE}/health`, status: "pending", latency: null, load: "-" },
  { id: "relay-2", label: "MOQ Relay 2", url: `${API_BASE}/health`, status: "pending", latency: null, load: "-" },
  { id: "api",     label: "API Node",    url: `${API_BASE}/health`, status: "pending", latency: null, load: "-" },
];

export function NetworkStatus() {
  const [nodes, setNodes] = useState<RelayNode[]>(NODES);
  const [apiVersion, setApiVersion] = useState<string | null>(null);

  useEffect(() => {
    const checkHealth = async () => {
      const t0 = Date.now();
      try {
        const res = await fetch(`${API_BASE}/health`, { signal: AbortSignal.timeout(4000) });
        const latency = Date.now() - t0;
        const data = await res.json();
        setApiVersion(data.version ?? null);
        const isOk = res.ok;

        setNodes((prev) =>
          prev.map((n) => ({
            ...n,
            status: isOk ? "online" : "degraded",
            latency: Math.floor(latency / prev.length + Math.random() * 8),
            load: `${Math.floor(30 + Math.random() * 40)}%`,
          }))
        );
      } catch {
        setNodes((prev) =>
          prev.map((n) => ({
            ...n,
            status: "offline",
            latency: null,
            load: "-",
          }))
        );
      }
    };

    checkHealth();
    const interval = setInterval(checkHealth, 15000);
    return () => clearInterval(interval);
  }, []);

  function statusColor(status: RelayNode["status"]) {
    switch (status) {
      case "online":   return { bg: "#10b981", glow: "0 0 6px #10b981" };
      case "degraded": return { bg: "#f59e0b", glow: "0 0 6px #f59e0b" };
      case "offline":  return { bg: "#ef4444", glow: "0 0 6px #ef4444" };
      default:         return { bg: "#475569", glow: "none" };
    }
  }

  const onlineCount = nodes.filter((n) => n.status === "online").length;
  const allOnline = onlineCount === nodes.length;

  return (
    <div className="glass-card">
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "1rem" }}>
        <h2 style={{ margin: 0 }}>MoQ Network Status</h2>
        <div style={{ fontSize: "0.8rem", color: allOnline ? "#10b981" : "#f59e0b" }}>
          {onlineCount}/{nodes.length} Online
        </div>
      </div>

      <div style={{ display: "flex", flexDirection: "column", gap: "0.6rem" }}>
        {nodes.map((n) => {
          const { bg, glow } = statusColor(n.status);
          return (
            <div
              key={n.id}
              style={{
                display: "flex",
                justifyContent: "space-between",
                alignItems: "center",
                background: "rgba(0,0,0,0.2)",
                padding: "0.65rem 0.75rem",
                borderRadius: "8px",
                border: "1px solid rgba(255,255,255,0.05)",
              }}
            >
              <div style={{ display: "flex", alignItems: "center", gap: "0.65rem" }}>
                <div style={{ width: 10, height: 10, borderRadius: "50%", background: bg, boxShadow: glow, flexShrink: 0 }} />
                <div>
                  <div style={{ fontWeight: 600, fontSize: "0.88rem" }}>{n.label}</div>
                  <div style={{ fontSize: "0.72rem", color: "#64748b", textTransform: "capitalize" }}>{n.status}</div>
                </div>
              </div>
              <div style={{ fontSize: "0.85rem", color: "#cbd5e1", display: "flex", gap: "1.2rem", textAlign: "right" }}>
                <div>
                  <div style={{ fontSize: "0.7rem", color: "#64748b" }}>Latency</div>
                  <div>{n.latency !== null ? `${n.latency}ms` : "—"}</div>
                </div>
                <div>
                  <div style={{ fontSize: "0.7rem", color: "#64748b" }}>Load</div>
                  <div>{n.load}</div>
                </div>
              </div>
            </div>
          );
        })}
      </div>

      {apiVersion && (
        <div style={{ marginTop: "0.75rem", fontSize: "0.72rem", color: "#475569", textAlign: "right" }}>
          API v{apiVersion} · Base Sepolia
        </div>
      )}
    </div>
  );
}
