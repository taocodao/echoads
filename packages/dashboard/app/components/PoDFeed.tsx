"use client";

import { useEffect, useState, useRef } from "react";
import { createPublicClient, http, parseAbi } from "viem";
import { baseSepolia } from "viem/chains";

const ORACLE_ABI = parseAbi([
  "event ProofOfDeliveryRecorded(bytes32 indexed podHash, address indexed viewer, address indexed node, uint256 cpmPaid, uint256 timestamp)",
]);

interface PoDEvent {
  podHash: string;
  viewer: string;
  node: string;
  cpmPaid: string;
  timestamp: number;
  tx: string;
}

const MAX_ITEMS = 20;

export function PoDFeed() {
  const [pods, setPods] = useState<PoDEvent[]>([]);
  const [connected, setConnected] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const unwatchRef = useRef<(() => void) | null>(null);

  useEffect(() => {
    const oracleAddress = process.env.NEXT_PUBLIC_ORACLE_CONTRACT_ADDRESS as `0x${string}` | undefined;
    if (!oracleAddress) {
      setError("NEXT_PUBLIC_ORACLE_CONTRACT_ADDRESS not set — showing simulated events.");
      startSimulation();
      return;
    }

    const publicClient = createPublicClient({
      chain: baseSepolia,
      transport: http(process.env.NEXT_PUBLIC_BASE_SEPOLIA_RPC_URL ?? "https://sepolia.base.org"),
    });

    try {
      const unwatch = publicClient.watchContractEvent({
        address: oracleAddress,
        abi: ORACLE_ABI,
        eventName: "ProofOfDeliveryRecorded",
        onLogs(logs) {
          setConnected(true);
          const newPods: PoDEvent[] = logs.map((log) => ({
            podHash: (log.args.podHash as string) ?? "0x",
            viewer: (log.args.viewer as string) ?? "0x",
            node: (log.args.node as string) ?? "0x",
            cpmPaid: formatCpm(log.args.cpmPaid as bigint),
            timestamp: Number(log.args.timestamp ?? 0),
            tx: log.transactionHash ?? "",
          }));
          setPods((prev) => [...newPods, ...prev].slice(0, MAX_ITEMS));
        },
        onError(err) {
          console.error("[PoDFeed] watchContractEvent error:", err);
          setConnected(false);
          setError("RPC connection lost — reconnecting...");
        },
      });
      unwatchRef.current = unwatch;
      setConnected(true);
    } catch (err) {
      console.error("[PoDFeed] Failed to start watcher:", err);
      setError("Could not connect to chain — showing simulated events.");
      startSimulation();
    }

    return () => {
      unwatchRef.current?.();
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  // Fallback: inject synthetic events when no contract is configured
  function startSimulation() {
    const SAMPLE_NODES = [
      "0xRelay000000000000000000000000000000001",
      "0xRelay000000000000000000000000000000002",
    ];
    const SAMPLE_VIEWERS = [
      "0xViewer00000000000000000000000000000001",
      "0xViewer00000000000000000000000000000002",
    ];
    const pushSimulated = () => {
      const node = SAMPLE_NODES[Math.floor(Math.random() * SAMPLE_NODES.length)]!;
      const viewer = SAMPLE_VIEWERS[Math.floor(Math.random() * SAMPLE_VIEWERS.length)]!;
      const fakePod: PoDEvent = {
        podHash: `0x${Math.random().toString(16).substring(2).padEnd(64, "0")}`,
        viewer,
        node,
        cpmPaid: (15 + Math.random() * 10).toFixed(2),
        timestamp: Math.floor(Date.now() / 1000),
        tx: `0x${Math.random().toString(16).substring(2).padEnd(64, "0")}`,
      };
      setPods((prev) => [fakePod, ...prev].slice(0, MAX_ITEMS));
    };
    // Initial batch
    for (let i = 0; i < 3; i++) setTimeout(pushSimulated, i * 600);
    const id = setInterval(pushSimulated, 8000);
    unwatchRef.current = () => clearInterval(id);
  }

  function formatCpm(cpmPaid: bigint | undefined): string {
    if (!cpmPaid) return "0.00";
    // cpmPaid is in USDC micro-units (6 decimals) or raw integer CPM×100
    return (Number(cpmPaid) / 100).toFixed(2);
  }

  function shortAddr(addr: string) {
    return `${addr.slice(0, 6)}…${addr.slice(-4)}`;
  }

  function shortHash(hash: string) {
    return `${hash.slice(0, 10)}…`;
  }

  return (
    <div className="glass-card">
      {/* Header */}
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "0.5rem" }}>
        <h2 style={{ margin: 0 }}>On-Chain PoD Feed</h2>
        <div style={{ display: "flex", alignItems: "center", gap: "0.5rem", fontSize: "0.8rem" }}>
          <span
            style={{
              width: 8,
              height: 8,
              borderRadius: "50%",
              background: connected ? "#10b981" : "#f59e0b",
              display: "inline-block",
              boxShadow: connected ? "0 0 6px #10b981" : "0 0 6px #f59e0b",
            }}
          />
          <span style={{ color: "#94a3b8" }}>{connected ? "Live" : "Connecting…"}</span>
        </div>
      </div>

      {error && (
        <div style={{ fontSize: "0.75rem", color: "#f59e0b", marginBottom: "0.75rem", fontStyle: "italic" }}>
          ⚠ {error}
        </div>
      )}

      <div
        style={{
          maxHeight: "320px",
          overflowY: "auto",
          display: "flex",
          flexDirection: "column",
          gap: "0.5rem",
          marginTop: "0.5rem",
        }}
      >
        {pods.length === 0 ? (
          <div style={{ color: "#94a3b8", fontStyle: "italic", padding: "1rem 0", textAlign: "center" }}>
            <span style={{ fontSize: "1.2rem" }}>🔍</span>
            <div style={{ marginTop: "0.5rem" }}>Listening for PoD events on Base Sepolia…</div>
          </div>
        ) : (
          pods.map((p, i) => (
            <div
              key={`${p.podHash}-${i}`}
              style={{
                fontSize: "0.82rem",
                background: "rgba(139, 92, 246, 0.08)",
                border: "1px solid rgba(139, 92, 246, 0.2)",
                padding: "0.6rem 0.75rem",
                borderRadius: "8px",
                animation: i === 0 ? "fadeIn 0.4s ease" : undefined,
              }}
            >
              <div style={{ display: "flex", justifyContent: "space-between", marginBottom: "0.3rem" }}>
                <span>
                  <strong style={{ color: "#8b5cf6" }}>PoD</strong>{" "}
                  <span style={{ color: "#e2e8f0", fontFamily: "monospace" }}>{shortHash(p.podHash)}</span>
                </span>
                <strong style={{ color: "#10b981" }}>${p.cpmPaid} CPM</strong>
              </div>
              <div style={{ color: "#94a3b8", display: "flex", gap: "1rem", flexWrap: "wrap" }}>
                <span>Node: <span style={{ color: "#cbd5e1" }}>{shortAddr(p.node)}</span></span>
                <span>Viewer: <span style={{ color: "#cbd5e1" }}>{shortAddr(p.viewer)}</span></span>
              </div>
              <div style={{ marginTop: "0.3rem", display: "flex", justifyContent: "space-between" }}>
                <span style={{ color: "#64748b", fontSize: "0.75rem" }}>
                  {new Date(p.timestamp * 1000).toLocaleTimeString()}
                </span>
                {p.tx && p.tx !== `0x${"0".repeat(64)}` && (
                  <a
                    href={`https://sepolia.basescan.org/tx/${p.tx}`}
                    target="_blank"
                    rel="noreferrer"
                    style={{ color: "#3b82f6", fontSize: "0.75rem", textDecoration: "underline" }}
                  >
                    View Tx ↗
                  </a>
                )}
              </div>
            </div>
          ))
        )}
      </div>

      <style>{`
        @keyframes fadeIn {
          from { opacity: 0; transform: translateY(-6px); }
          to   { opacity: 1; transform: translateY(0); }
        }
      `}</style>
    </div>
  );
}
