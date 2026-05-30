"use client";

import { useEffect, useState, useRef } from "react";
import { createPublicClient, http, parseAbi, formatEther } from "viem";
import { baseSepolia } from "viem/chains";

const CMXS_ABI = parseAbi([
  "event TokensMinted(address indexed node, uint256 amount, bytes32 indexed podHash)",
  "event TokensBurned(address indexed advertiser, uint256 amount, uint256 usdcSpent)",
]);

interface BurnMintEvent {
  id: string;
  type: "mint" | "burn";
  address: string;
  amount: string;
  label: string;
  tx: string;
  ts: number;
}

const MAX_ITEMS = 15;

export function BurnMintFeed() {
  const [events, setEvents] = useState<BurnMintEvent[]>([]);
  const [totals, setTotals] = useState({ minted: 0, burned: 0 });
  const [connected, setConnected] = useState(false);
  const unwatchRef = useRef<(() => void) | null>(null);

  useEffect(() => {
    const cmxsAddress = process.env.NEXT_PUBLIC_CMXS_CONTRACT_ADDRESS as `0x${string}` | undefined;
    if (!cmxsAddress) { startSimulation(); return; }

    const publicClient = createPublicClient({
      chain: baseSepolia,
      transport: http(process.env.NEXT_PUBLIC_BASE_SEPOLIA_RPC_URL ?? "https://sepolia.base.org"),
    });

    try {
      const unwatchMint = publicClient.watchContractEvent({
        address: cmxsAddress, abi: CMXS_ABI, eventName: "TokensMinted",
        onLogs(logs) {
          setConnected(true);
          const evs: BurnMintEvent[] = logs.map((log) => {
            const amt = Number(formatEther((log.args.amount as bigint) ?? 0n));
            setTotals((t) => ({ ...t, minted: t.minted + amt }));
            return { id: `${log.transactionHash}-mint`, type: "mint", address: (log.args.node as string) ?? "0x", amount: amt.toFixed(4), label: "Node Reward", tx: log.transactionHash ?? "", ts: Date.now() };
          });
          setEvents((prev) => [...evs, ...prev].slice(0, MAX_ITEMS));
        },
      });

      const unwatchBurn = publicClient.watchContractEvent({
        address: cmxsAddress, abi: CMXS_ABI, eventName: "TokensBurned",
        onLogs(logs) {
          setConnected(true);
          const evs: BurnMintEvent[] = logs.map((log) => {
            const amt = Number(formatEther((log.args.amount as bigint) ?? 0n));
            setTotals((t) => ({ ...t, burned: t.burned + amt }));
            return { id: `${log.transactionHash}-burn`, type: "burn", address: (log.args.advertiser as string) ?? "0x", amount: amt.toFixed(2), label: "Ad Spend", tx: log.transactionHash ?? "", ts: Date.now() };
          });
          setEvents((prev) => [...evs, ...prev].slice(0, MAX_ITEMS));
        },
      });

      setConnected(true);
      unwatchRef.current = () => { unwatchMint(); unwatchBurn(); };
    } catch (err) {
      console.error("[BurnMintFeed] watcher failed:", err);
      startSimulation();
    }

    return () => unwatchRef.current?.();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  function startSimulation() {
    const ADDRS = ["0xNode0000000000000000000000000000000001", "0xAdv00000000000000000000000000000000001"];
    const push = () => {
      const isMint = Math.random() > 0.4;
      const amt = isMint ? 0.001 : +(Math.random() * 5 + 1).toFixed(3);
      const ev: BurnMintEvent = { id: `sim-${Date.now()}-${Math.random()}`, type: isMint ? "mint" : "burn", address: ADDRS[Math.floor(Math.random() * ADDRS.length)]!, amount: amt.toFixed(isMint ? 4 : 2), label: isMint ? "Node Reward" : "Ad Spend", tx: `0x${"0".repeat(64)}`, ts: Date.now() };
      setTotals((t) => ({ minted: isMint ? t.minted + amt : t.minted, burned: !isMint ? t.burned + amt : t.burned }));
      setEvents((prev) => [ev, ...prev].slice(0, MAX_ITEMS));
    };
    for (let i = 0; i < 4; i++) setTimeout(push, i * 400);
    const id = setInterval(push, 6000);
    unwatchRef.current = () => clearInterval(id);
  }

  function shortAddr(a: string) { return `${a.slice(0, 6)}…${a.slice(-4)}`; }

  const totalFlow = totals.minted + totals.burned;
  const mintPct = totalFlow > 0 ? (totals.minted / totalFlow) * 100 : 50;

  return (
    <div className="glass-card">
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "1rem" }}>
        <h2 style={{ margin: 0 }}>Burn / Mint Events</h2>
        <span style={{ display: "flex", alignItems: "center", gap: "0.4rem", fontSize: "0.8rem", color: "#94a3b8" }}>
          <span style={{ width: 8, height: 8, borderRadius: "50%", background: connected ? "#10b981" : "#f59e0b", display: "inline-block", boxShadow: connected ? "0 0 6px #10b981" : "0 0 6px #f59e0b" }} />
          {connected ? "Live" : "Simulated"}
        </span>
      </div>

      {/* Flow bar */}
      <div style={{ marginBottom: "1rem" }}>
        <div style={{ display: "flex", justifyContent: "space-between", fontSize: "0.75rem", color: "#94a3b8", marginBottom: 4 }}>
          <span>🟢 Minted: <strong style={{ color: "#10b981" }}>{totals.minted.toFixed(3)} CMXS</strong></span>
          <span>🔴 Burned: <strong style={{ color: "#ef4444" }}>{totals.burned.toFixed(3)} CMXS</strong></span>
        </div>
        <div style={{ height: 6, borderRadius: 99, background: "rgba(255,255,255,0.08)", overflow: "hidden" }}>
          <div style={{ height: "100%", width: `${mintPct}%`, background: "linear-gradient(90deg, #10b981, #3b82f6)", borderRadius: 99, transition: "width 0.6s ease" }} />
        </div>
      </div>

      <div style={{ maxHeight: "240px", overflowY: "auto", display: "flex", flexDirection: "column", gap: "0.4rem" }}>
        {events.length === 0 ? (
          <div style={{ color: "#94a3b8", fontStyle: "italic", padding: "1rem 0", textAlign: "center" }}>Listening for CMXS Transfer events…</div>
        ) : events.map((ev, i) => (
          <div key={ev.id} style={{ display: "flex", alignItems: "center", gap: "0.6rem", padding: "0.45rem 0.6rem", borderRadius: 6, background: ev.type === "mint" ? "rgba(16,185,129,0.07)" : "rgba(239,68,68,0.07)", border: `1px solid ${ev.type === "mint" ? "rgba(16,185,129,0.2)" : "rgba(239,68,68,0.2)"}`, fontSize: "0.8rem", animation: i === 0 ? "fadeIn 0.4s ease" : undefined }}>
            <span style={{ fontSize: "1rem" }}>{ev.type === "mint" ? "🪙" : "🔥"}</span>
            <div style={{ flex: 1 }}>
              <div style={{ display: "flex", justifyContent: "space-between" }}>
                <span style={{ color: ev.type === "mint" ? "#10b981" : "#ef4444", fontWeight: 600 }}>{ev.type === "mint" ? "+" : "-"}{ev.amount} CMXS</span>
                <span style={{ color: "#64748b", fontSize: "0.72rem" }}>{new Date(ev.ts).toLocaleTimeString()}</span>
              </div>
              <div style={{ color: "#64748b", fontSize: "0.75rem" }}>{ev.label} · {shortAddr(ev.address)}</div>
            </div>
          </div>
        ))}
      </div>
      <style>{`@keyframes fadeIn { from { opacity:0; transform:translateY(-5px); } to { opacity:1; transform:translateY(0); } }`}</style>
    </div>
  );
}
