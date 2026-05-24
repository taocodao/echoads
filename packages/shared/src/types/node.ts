// ============================================================
// Node operator types
// ============================================================

export type NodeStatus = "active" | "inactive" | "slashed";

export interface NodeInfo {
  address: string;        // 0x-prefixed wallet address
  endpoint: string;       // MOQ relay endpoint URL
  stakedAmount: bigint;   // CMXS tokens staked (in wei)
  status: NodeStatus;
  registeredAt: number;   // Unix ms
  totalDeliveries: number;
  slaPassRate: number;    // 0–1
  cmxsBalance: bigint;    // Current CMXS token balance
}

/** Stats shown on node operator dashboard */
export interface NodeDashboardStats {
  node: NodeInfo;
  deliveriesToday: number;
  deliveriesThisWeek: number;
  estimatedMonthlyRewardCmxs: bigint;
  recentDeliveries: Array<{
    deliveryId: string;
    slotId: string;
    latencyMs: number;
    slaMet: boolean;
    cmxsEarned: bigint;
    timestamp: number;
  }>;
}
