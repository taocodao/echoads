/**
 * node-simulator.ts
 * ─────────────────────────────────────────────────────────────────────────────
 * Spawns N virtual DePIN viewer nodes, registers them on NodeStaking,
 * and continuously feeds them as nodeOperator addresses in PoD receipts.
 *
 * Each virtual node:
 *   1. Has a deterministic wallet (HD path m/44'/60'/0'/0/n)
 *   2. Registers on NodeStaking with a tower/device ID
 *   3. Receives round-robin PoD receipt assignments
 *   4. Earns simulated CMXS rewards on each batch confirmation
 *
 * Emits SSE events used by the dashboard's live node grid.
 */

import { createHash, randomBytes } from 'crypto';

// ── Node Definitions ──────────────────────────────────────────────────────────

export type NodeStatus = 'ACTIVE' | 'JAILED' | 'OFFLINE' | 'PENDING';
export type DeviceType = 'Tower' | 'Roku Ultra' | 'Fire TV Cube' | 'Apple TV 4K' | 'Home Broadband' | 'CBRS Radio';

export interface SimulatedNode {
  index: number;
  nodeId: string;              // e.g., ECHOSTAR-TOWER-001
  address: string;             // deterministic 0x address
  endpoint: string;
  deviceType: DeviceType;
  status: NodeStatus;
  stakedCmxs: number;          // simulated stake amount
  rewardsCmxs: number;         // accumulated rewards
  impressionsServed: number;
  slashCount: number;
  registeredAt: number;
  lastActivityAt: number;
}

const NODE_TEMPLATES: Array<{
  nodeId: string;
  endpoint: string;
  deviceType: DeviceType;
  stakeAmount: number;
}> = [
  { nodeId: 'ECHOSTAR-TOWER-001', endpoint: 'moqs://tower001.echoads.tv:4443', deviceType: 'Tower',           stakeAmount: 10_000 },
  { nodeId: 'ECHOSTAR-TOWER-002', endpoint: 'moqs://tower002.echoads.tv:4443', deviceType: 'Tower',           stakeAmount: 10_000 },
  { nodeId: 'ECHOSTAR-TOWER-003', endpoint: 'moqs://tower003.echoads.tv:4443', deviceType: 'Tower',           stakeAmount: 10_000 },
  { nodeId: 'ROKU-NODE-004',      endpoint: 'p2p://roku004.local:8080',        deviceType: 'Roku Ultra',      stakeAmount: 5_000  },
  { nodeId: 'FIRETV-NODE-005',    endpoint: 'p2p://firetv005.local:8080',      deviceType: 'Fire TV Cube',    stakeAmount: 5_000  },
  { nodeId: 'APPLETV-NODE-006',   endpoint: 'p2p://appletv006.local:8080',     deviceType: 'Apple TV 4K',     stakeAmount: 5_000  },
  { nodeId: 'HOME-NODE-007',      endpoint: 'p2p://home007.local:8080',        deviceType: 'Home Broadband',  stakeAmount: 2_500  },
  { nodeId: 'ECHOSTAR-TOWER-008', endpoint: 'moqs://tower008.echoads.tv:4443', deviceType: 'Tower',           stakeAmount: 10_000 },
  { nodeId: 'ROKU-NODE-009',      endpoint: 'p2p://roku009.local:8080',        deviceType: 'Roku Ultra',      stakeAmount: 5_000  },
  { nodeId: 'CBRS-NODE-010',      endpoint: 'cbrs://cbrs010.echoads.tv:3550',  deviceType: 'CBRS Radio',      stakeAmount: 7_500  },
];

// ── Deterministic address generator ──────────────────────────────────────────

function deriveAddress(index: number): string {
  const seed = createHash('sha256').update(`cmxs-node-seed-${index}`).digest();
  return `0x${seed.slice(0, 20).toString('hex')}`;
}

// ── Simulator State ───────────────────────────────────────────────────────────

let nodes: SimulatedNode[] = [];
let isRunning = false;
let podTickInterval: ReturnType<typeof setInterval> | null = null;
let currentRoundRobin = 0;

// SSE event emitter
type SimEvent = {
  type: 'node_registered' | 'node_slashed' | 'node_unjailed' | 'pod_assigned' | 'reward_accrued' | 'sim_started' | 'sim_stopped';
  data: Record<string, unknown>;
  timestamp: number;
};

const eventListeners: Array<(event: SimEvent) => void> = [];

export function subscribeToSimEvents(cb: (event: SimEvent) => void): () => void {
  eventListeners.push(cb);
  return () => {
    const idx = eventListeners.indexOf(cb);
    if (idx !== -1) eventListeners.splice(idx, 1);
  };
}

function emit(type: SimEvent['type'], data: Record<string, unknown>): void {
  const event: SimEvent = { type, data, timestamp: Date.now() };
  for (const cb of eventListeners) {
    try { cb(event); } catch { /* swallow */ }
  }
}

// ── Public API ────────────────────────────────────────────────────────────────

/**
 * Start the node simulator.
 * Registers `count` nodes (max 10) with deterministic addresses.
 * Starts the PoD tick loop that assigns PoD receipts round-robin.
 */
export async function startSimulator(count: number = 10): Promise<SimulatedNode[]> {
  if (isRunning) return nodes;

  const n = Math.min(count, NODE_TEMPLATES.length);
  nodes = NODE_TEMPLATES.slice(0, n).map((tmpl, i) => ({
    index: i,
    nodeId: tmpl.nodeId,
    address: deriveAddress(i),
    endpoint: tmpl.endpoint,
    deviceType: tmpl.deviceType,
    status: 'PENDING' as NodeStatus,
    stakedCmxs: tmpl.stakeAmount,
    rewardsCmxs: 0,
    impressionsServed: 0,
    slashCount: 0,
    registeredAt: Date.now(),
    lastActivityAt: Date.now(),
  }));

  // Simulate registration delay (300ms per node staggered)
  for (const node of nodes) {
    await new Promise((r) => setTimeout(r, 300));
    node.status = 'ACTIVE';
    emit('node_registered', {
      nodeId: node.nodeId,
      address: node.address,
      deviceType: node.deviceType,
      stake: node.stakedCmxs,
    });
  }

  isRunning = true;
  emit('sim_started', { nodeCount: nodes.length });

  // Start PoD tick — every 15s assign a batch of PoD receipts
  podTickInterval = setInterval(() => podTick(), 15_000);

  return nodes;
}

/**
 * Stop the simulator and clear all state.
 */
export function stopSimulator(): void {
  if (podTickInterval) clearInterval(podTickInterval);
  podTickInterval = null;
  isRunning = false;
  nodes = [];
  emit('sim_stopped', {});
}

/**
 * Get current node list.
 */
export function getNodes(): SimulatedNode[] {
  return nodes;
}

export function getSimStatus() {
  return {
    running: isRunning,
    nodeCount: nodes.length,
    activeNodes: nodes.filter((n) => n.status === 'ACTIVE').length,
    jailedNodes: nodes.filter((n) => n.status === 'JAILED').length,
    totalImpressions: nodes.reduce((s, n) => s + n.impressionsServed, 0),
    totalRewards: parseFloat(nodes.reduce((s, n) => s + n.rewardsCmxs, 0).toFixed(6)),
  };
}

/**
 * Slash a specific node (for demo purposes).
 */
export function slashNode(nodeId: string, severity: 'MINOR' | 'MAJOR' = 'MINOR'): boolean {
  const node = nodes.find((n) => n.nodeId === nodeId);
  if (!node || node.status !== 'ACTIVE') return false;

  const penalty = severity === 'MINOR' ? 500 : 2_000;
  node.status = 'JAILED';
  node.stakedCmxs = Math.max(0, node.stakedCmxs - penalty);
  node.slashCount++;

  emit('node_slashed', { nodeId, severity, penalty, remaining: node.stakedCmxs });

  // Auto-unjail after 30s (accelerated from 7 days)
  setTimeout(() => {
    if (node.status === 'JAILED') {
      node.status = 'ACTIVE';
      emit('node_unjailed', { nodeId });
    }
  }, 30_000);

  return true;
}

/**
 * Get the next node address in round-robin rotation (for PoD receipt assignment).
 */
export function getNextNodeAddress(): { address: string; nodeId: string } | null {
  const active = nodes.filter((n) => n.status === 'ACTIVE');
  if (active.length === 0) return null;

  const node = active[currentRoundRobin % active.length]!;
  currentRoundRobin++;
  return { address: node.address, nodeId: node.nodeId };
}

// ── Background PoD Tick ───────────────────────────────────────────────────────

function podTick(): void {
  const active = nodes.filter((n) => n.status === 'ACTIVE');
  if (active.length === 0) return;

  // Assign 3-8 impressions randomly distributed across active nodes
  const batchSize = 3 + Math.floor(Math.random() * 6);
  for (let i = 0; i < batchSize; i++) {
    const node = active[i % active.length]!;
    node.impressionsServed++;
    // Simulated reward: 0.001 CMXS per impression
    node.rewardsCmxs += 0.001;
    node.lastActivityAt = Date.now();

    emit('pod_assigned', {
      nodeId: node.nodeId,
      address: node.address,
      impressionIndex: node.impressionsServed,
    });
  }

  // Simulate reward accrual for all active nodes
  for (const node of active) {
    emit('reward_accrued', {
      nodeId: node.nodeId,
      rewardDelta: 0.001 * batchSize / active.length,
      totalRewards: node.rewardsCmxs,
      totalImpressions: node.impressionsServed,
    });
  }
}
