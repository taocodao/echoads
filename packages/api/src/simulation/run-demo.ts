/**
 * run-demo.ts
 * ─────────────────────────────────────────────────────────────────────────────
 * 9-Scene CMXS Flywheel Demo Orchestrator.
 *
 * Runs the complete end-to-end demonstration in ~90 seconds, emitting
 * structured events to the SSE stream so the dashboard updates in real-time.
 *
 * Scene sequence:
 *   1  (T=0s)   Infrastructure Boot
 *   2  (T=15s)  Campaign Purchase
 *   3  (T=25s)  Live Stream + SCTE-35 Break Detected
 *   4  (T=30s)  OpenRTB 2.6 Auction
 *   5  (T=32s)  Ad Delivery + x302 Overlay
 *   6  (T=62s)  PoD Verification + On-Chain Settlement
 *   7  (T=72s)  Treasury Distribution
 *   8  (T=82s)  Deflationary Proof
 *   9  (T=90s)  Summary
 */

import { createHash, randomBytes } from 'crypto';
import { startSimulator, getNodes, slashNode } from '../node-sim/node-simulator.js';
import { runOpenRTBAuction } from '../auction/openrtb-engine.js';

// ── Types ─────────────────────────────────────────────────────────────────────

export type SceneStatus = 'pending' | 'running' | 'complete' | 'skipped';

export interface SceneEvent {
  scene: number;
  title: string;
  status: SceneStatus;
  data?: Record<string, unknown> | undefined;
  elapsedMs: number;
  timestamp: string;
}

export interface DemoMetrics {
  impressionsProcessed: number;
  cmxsBurned: number;
  cmxsMinted: number;
  netDeflation: number;
  usdcRevenue: number;
  treasuryUsdc: number;
  activeNodes: number;
  auctionLatencyMs: number;
  podConfirmedOnChain: boolean;
  txHash: string | null;
}

export interface DemoState {
  running: boolean;
  startedAt: number | null;
  completedAt: number | null;
  currentScene: number;
  scenes: Array<{ scene: number; title: string; status: SceneStatus }>;
  metrics: DemoMetrics;
}

// ── State ─────────────────────────────────────────────────────────────────────

const SCENE_TITLES: Record<number, string> = {
  1: 'Infrastructure Boot',
  2: 'Campaign Purchase',
  3: 'Live Stream + SCTE-35 Break',
  4: 'OpenRTB 2.6 Auction',
  5: 'Ad Delivery + x302 Overlay',
  6: 'PoD Verification + On-Chain Settlement',
  7: 'Treasury Distribution',
  8: 'Deflationary Proof',
  9: 'Flywheel Complete — Summary',
};

let demoState: DemoState = buildInitialState();
let emitFn: ((event: SceneEvent) => void) | null = null;
let abortController: AbortController | null = null;

function buildInitialState(): DemoState {
  return {
    running: false,
    startedAt: null,
    completedAt: null,
    currentScene: 0,
    scenes: Object.entries(SCENE_TITLES).map(([k, title]) => ({
      scene: parseInt(k),
      title,
      status: 'pending' as SceneStatus,
    })),
    metrics: {
      impressionsProcessed: 0,
      cmxsBurned: 0,
      cmxsMinted: 0,
      netDeflation: 0,
      usdcRevenue: 0,
      treasuryUsdc: 0,
      activeNodes: 0,
      auctionLatencyMs: 0,
      podConfirmedOnChain: false,
      txHash: null,
    },
  };
}

export function getDemoState(): DemoState {
  return { ...demoState };
}

export function setEventEmitter(fn: (event: SceneEvent) => void): void {
  emitFn = fn;
}

// ── Helpers ───────────────────────────────────────────────────────────────────

function delay(ms: number): Promise<void> {
  return new Promise((resolve, reject) => {
    const timeout = setTimeout(resolve, ms);
    abortController?.signal.addEventListener('abort', () => {
      clearTimeout(timeout);
      reject(new Error('Demo aborted'));
    });
  });
}

function emit(scene: number, status: SceneStatus, data?: Record<string, unknown>): void {
  const now = Date.now();
  const event: SceneEvent = {
    scene,
    title: SCENE_TITLES[scene] ?? `Scene ${scene}`,
    status,
    data,
    elapsedMs: demoState.startedAt ? now - demoState.startedAt : 0,
    timestamp: new Date().toISOString(),
  };

  // Update local state
  const sceneEntry = demoState.scenes.find((s) => s.scene === scene);
  if (sceneEntry) sceneEntry.status = status;
  if (status === 'running') demoState.currentScene = scene;

  // Emit to SSE clients
  emitFn?.(event);
  console.log(`[demo] Scene ${scene} [${status}] ${event.title}`, data ? JSON.stringify(data) : '');
}

function fakeTxHash(): string {
  return `0x${randomBytes(32).toString('hex')}`;
}

function fakeImpressionId(): string {
  return `0x${createHash('sha256').update(`${Date.now()}-${Math.random()}`).digest('hex')}`;
}

// ── Scene Implementations ─────────────────────────────────────────────────────

async function scene1_Boot(signal: AbortSignal): Promise<void> {
  emit(1, 'running');

  // Start node simulator
  const nodes = await startSimulator(5);
  demoState.metrics.activeNodes = nodes.filter((n) => n.status === 'ACTIVE').length;

  emit(1, 'complete', {
    nodesRegistered: nodes.length,
    nodeIds: nodes.map((n) => n.nodeId),
    advertiserFunded: true,
    contractsVerified: true,
  });
}

async function scene2_Campaign(): Promise<void> {
  emit(2, 'running');
  await delay(2000); // simulate contract call time

  const usdcSpend = 1000;
  const contentPartnerShare = usdcSpend * 0.85;
  const treasuryShare = usdcSpend * 0.15;
  const cmxsBurned = 100; // $1000 / $10 per CMXS = 100 burned

  demoState.metrics.usdcRevenue = usdcSpend;
  demoState.metrics.treasuryUsdc = treasuryShare;
  demoState.metrics.cmxsBurned = cmxsBurned;

  emit(2, 'complete', {
    campaignId: `0x${createHash('sha256').update('demo-campaign-001').digest('hex')}`,
    usdcSpend,
    contentPartnerShare,
    treasuryShare,
    cmxsBurned,
    impressionsPurchased: 20_000,
  });
}

async function scene3_Stream(): Promise<void> {
  emit(3, 'running');
  await delay(2000); // simulate manifest load time

  emit(3, 'complete', {
    sessionId: `sess-${randomBytes(4).toString('hex')}`,
    resolution: '1080p',
    contentId: 'cmxs_liv_golf_round2',
    scte35Detected: true,
    adBreakDuration: 30,
    manifestLoadMs: 180,
  });
}

async function scene4_Auction(): Promise<void> {
  emit(4, 'running');

  // Actually run the OpenRTB engine
  const result = await runOpenRTBAuction({
    breakType: 'halftime',
    contentId: 'cmxs_liv_golf_round2',
    contentGenre: 'Sports',
    sessionId: `demo-${Date.now()}`,
  });

  demoState.metrics.auctionLatencyMs = result.totalLatencyMs;
  const winner = result.slots[0];

  emit(4, 'complete', {
    auctionId: result.auctionId,
    totalLatencyMs: result.totalLatencyMs,
    winner: winner?.dspName ?? 'DirectDeal Sim',
    winningCpm: winner?.winningCpm ?? 48,
    clearingCpm: winner?.clearingCpm ?? 45,
    advertiser: winner?.advertiser ?? 'Callaway Golf',
    bidsReceived: result.bidsReceived,
    bidsTimedOut: result.bidsTimedOut,
    fillRate: result.fillRate,
  });
}

async function scene5_AdDelivery(): Promise<void> {
  emit(5, 'running');

  // Simulate 30s of ad playback compressed into 5 status updates
  for (const quartile of [25, 50, 75, 100] as const) {
    await delay(500);
    emit(5, 'running', {
      quartile: `${quartile}%`,
      commerceOverlay: quartile >= 67, // overlay appears at 20/30s ≈ 67%
    });
  }

  emit(5, 'complete', {
    adDurationSeconds: 30,
    quartilesComplete: ['start', '25%', '50%', '75%', '100%'],
    commerceClicks: 0,
    x302OverlayShown: true,
    overlayProduct: 'Callaway Paradym Ai Smoke Driver',
    overlayPrice: '$549',
  });
}

async function scene6_PoD(): Promise<void> {
  emit(6, 'running');

  const nodes = getNodes();
  const targetNode = nodes.find((n) => n.status === 'ACTIVE') ?? nodes[0];

  // Simulate 5 impression receipts being signed and submitted
  const impressions = Array.from({ length: 5 }, (_, i) => ({
    impressionId: fakeImpressionId(),
    nodeOperator: targetNode?.address ?? '0x0000000000000000000000000000000000000001',
    cpm: 45_000_000, // $45 USDC in microunits
    slotIndex: i,
  }));

  emit(6, 'running', { step: 'receipts_signed', count: 5 });
  await delay(800);

  emit(6, 'running', { step: 'redis_dedup', duplicates: 0, new: 5 });
  await delay(600);

  emit(6, 'running', { step: 'batch_submitted', batchSize: 5 });
  await delay(1500); // simulate tx confirmation time

  // Simulate on-chain mint: 0.001 CMXS per impression × 5
  const mintedCmxs = 0.005;
  const txHash = fakeTxHash();
  demoState.metrics.cmxsMinted = mintedCmxs;
  demoState.metrics.netDeflation = demoState.metrics.cmxsBurned - mintedCmxs;
  demoState.metrics.impressionsProcessed = 5;
  demoState.metrics.podConfirmedOnChain = true;
  demoState.metrics.txHash = txHash;

  emit(6, 'complete', {
    impressionsVerified: 5,
    nodeOperator: targetNode?.nodeId ?? 'ECHOSTAR-TOWER-001',
    mintedCmxs,
    txHash,
    basescanUrl: `https://sepolia.basescan.org/tx/${txHash}`,
    gasUsedGwei: '0.42',
  });
}

async function scene7_Treasury(): Promise<void> {
  emit(7, 'running');
  await delay(1500); // simulate epoch distribution tx

  const totalFees = demoState.metrics.treasuryUsdc;
  const veHolderShare = totalFees * 0.70;
  const nodeRewardShare = totalFees * 0.30;

  emit(7, 'complete', {
    epochNumber: 1,
    totalFeesUsdc: totalFees,
    veHolderShare,
    nodeRewardShare,
    veHolders: 1,
    claimableNow: veHolderShare,
  });
}

async function scene8_Deflation(): Promise<void> {
  emit(8, 'running');
  await delay(800);

  const { cmxsBurned, cmxsMinted, netDeflation } = demoState.metrics;

  emit(8, 'complete', {
    totalBurned: `${cmxsBurned} CMXS`,
    totalMinted: `${cmxsMinted.toFixed(6)} CMXS`,
    netDeflation: `−${netDeflation.toFixed(6)} CMXS`,
    deflationary: cmxsBurned > cmxsMinted,
    supplyChange: `-${((cmxsBurned - cmxsMinted) / 1_000_000 * 100).toFixed(8)}%`,
    conclusion: 'Every ad campaign permanently reduces CMXS supply',
  });
}

async function scene9_Summary(): Promise<void> {
  emit(9, 'running');
  await delay(500);

  emit(9, 'complete', {
    totalElapsedMs: demoState.startedAt ? Date.now() - demoState.startedAt : 0,
    flywheel: '✅ Complete',
    metrics: demoState.metrics,
    nextSteps: [
      'Deploy contracts to Base Mainnet',
      'Onboard first content partner',
      'Launch TGE via Gnosis Safe',
    ],
  });

  demoState.running = false;
  demoState.completedAt = Date.now();
}

// ── Main Entry Point ──────────────────────────────────────────────────────────

/**
 * Run the full 9-scene flywheel demo.
 * Emits SSE events to the registered emitter function throughout.
 */
export async function runFullDemo(
  onEvent: (event: SceneEvent) => void
): Promise<void> {
  if (demoState.running) {
    throw new Error('Demo already running');
  }

  // Reset state
  demoState = buildInitialState();
  demoState.running = true;
  demoState.startedAt = Date.now();
  emitFn = onEvent;
  abortController = new AbortController();

  const SCENE_DELAYS: Record<number, number> = {
    1: 0,
    2: 3_000,   // after boot
    3: 3_000,   // after campaign
    4: 2_000,   // after stream starts
    5: 2_000,   // after auction
    6: 2_000,   // after ad plays (compressed from 30s)
    7: 2_000,   // after PoD
    8: 2_000,   // after treasury
    9: 1_000,   // after deflation
  };

  try {
    await delay(SCENE_DELAYS[1]!); await scene1_Boot(abortController.signal);
    await delay(SCENE_DELAYS[2]!); await scene2_Campaign();
    await delay(SCENE_DELAYS[3]!); await scene3_Stream();
    await delay(SCENE_DELAYS[4]!); await scene4_Auction();
    await delay(SCENE_DELAYS[5]!); await scene5_AdDelivery();
    await delay(SCENE_DELAYS[6]!); await scene6_PoD();
    await delay(SCENE_DELAYS[7]!); await scene7_Treasury();
    await delay(SCENE_DELAYS[8]!); await scene8_Deflation();
    await delay(SCENE_DELAYS[9]!); await scene9_Summary();
  } catch (err: unknown) {
    if (err instanceof Error && err.message === 'Demo aborted') {
      console.log('[demo] Aborted by user');
      demoState.running = false;
    } else {
      throw err;
    }
  }
}

/**
 * Abort a running demo.
 */
export function abortDemo(): void {
  abortController?.abort();
  demoState.running = false;
}

/**
 * Jump directly to a specific scene (for manual stepping in presentations).
 */
export async function jumpToScene(
  scene: number,
  onEvent: (event: SceneEvent) => void
): Promise<void> {
  emitFn = onEvent;
  if (!demoState.startedAt) demoState.startedAt = Date.now();

  const sceneMap: Record<number, () => Promise<void>> = {
    1: () => scene1_Boot(new AbortController().signal),
    2: scene2_Campaign,
    3: scene3_Stream,
    4: scene4_Auction,
    5: scene5_AdDelivery,
    6: scene6_PoD,
    7: scene7_Treasury,
    8: scene8_Deflation,
    9: scene9_Summary,
  };

  const fn = sceneMap[scene];
  if (!fn) throw new Error(`Scene ${scene} not found`);
  await fn();
}
