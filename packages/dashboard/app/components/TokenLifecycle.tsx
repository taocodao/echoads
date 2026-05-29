"use client";

import { useEffect, useState } from "react";
import { createPublicClient, http, parseAbi, formatEther } from "viem";
import { baseSepolia } from "viem/chains";

const CMXS_ABI = parseAbi([
  "function totalSupply() external view returns (uint256)",
  "function dailyMinted() external view returns (uint256)",
  "function totalBurned() external view returns (uint256)",
  "function totalMinted() external view returns (uint256)",
  "function burnRatio() external view returns (uint256)"
]);

const publicClient = createPublicClient({
  chain: baseSepolia,
  transport: http(process.env.NEXT_PUBLIC_BASE_SEPOLIA_RPC_URL ?? "https://sepolia.base.org")
});

export function TokenLifecycle() {
  const [stats, setStats] = useState({
    supply: "1000000000",
    dailyMinted: "0",
    totalBurned: "0",
    circulating: "200000000",
    burnRatio: "0"
  });

  const cmxsAddress = process.env.NEXT_PUBLIC_CMXS_CONTRACT_ADDRESS as `0x${string}`;

  useEffect(() => {
    if (!cmxsAddress) return;
    const fetchStats = async () => {
      try {
        const [supply, daily, burned, circulating, ratio] = await Promise.all([
          publicClient.readContract({ address: cmxsAddress, abi: CMXS_ABI, functionName: "totalSupply" }),
          publicClient.readContract({ address: cmxsAddress, abi: CMXS_ABI, functionName: "dailyMinted" }),
          publicClient.readContract({ address: cmxsAddress, abi: CMXS_ABI, functionName: "totalBurned" }),
          publicClient.readContract({ address: cmxsAddress, abi: CMXS_ABI, functionName: "totalSupply" }), // fallback
          publicClient.readContract({ address: cmxsAddress, abi: CMXS_ABI, functionName: "burnRatio" })
        ]);

        setStats({
          supply: formatEther(supply as bigint),
          dailyMinted: formatEther(daily as bigint),
          totalBurned: formatEther(burned as bigint),
          circulating: formatEther(circulating as bigint),
          burnRatio: ((Number(ratio) / 10000) * 100).toFixed(2)
        });
      } catch (err) {
        console.error("Failed to fetch CMXS stats:", err);
      }
    };
    
    fetchStats();
    const interval = setInterval(fetchStats, 10000);
    return () => clearInterval(interval);
  }, [cmxsAddress]);

  return (
    <div className="glass-card">
      <h2 style={{ marginTop: 0, borderBottom: '1px solid rgba(255,255,255,0.1)', paddingBottom: '0.5rem' }}>Token Lifecycle (BME)</h2>
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1rem', marginTop: '1rem' }}>
        <div>
          <div style={{ fontSize: '0.8rem', color: '#94a3b8' }}>Total Supply</div>
          <div style={{ fontSize: '1.2rem', fontWeight: 'bold' }}>{Number(stats.supply).toLocaleString()} CMXS</div>
        </div>
        <div>
          <div style={{ fontSize: '0.8rem', color: '#94a3b8' }}>Minted Today</div>
          <div style={{ fontSize: '1.2rem', fontWeight: 'bold', color: '#10b981' }}>{Number(stats.dailyMinted).toLocaleString()} CMXS</div>
        </div>
        <div>
          <div style={{ fontSize: '0.8rem', color: '#94a3b8' }}>Total Burned</div>
          <div style={{ fontSize: '1.2rem', fontWeight: 'bold', color: '#ef4444' }}>{Number(stats.totalBurned).toLocaleString()} CMXS</div>
        </div>
        <div>
          <div style={{ fontSize: '0.8rem', color: '#94a3b8' }}>Burn Ratio</div>
          <div style={{ fontSize: '1.2rem', fontWeight: 'bold' }}>{stats.burnRatio}%</div>
        </div>
      </div>
    </div>
  );
}
