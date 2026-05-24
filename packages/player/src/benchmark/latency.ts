/**
 * Latency Benchmark Harness
 * Runs N ad break simulations and records P50/P95/P99 for both MOQ and HLS.
 * Generates data for the boardroom benchmark chart.
 *
 * Usage:
 *   import { runBenchmark } from './latency';
 *   const results = await runBenchmark({ trials: 100 });
 */

export interface BenchmarkResult {
  transport: "moq" | "hls";
  trials: number;
  p50Ms: number;
  p95Ms: number;
  p99Ms: number;
  minMs: number;
  maxMs: number;
  raw: number[];
}

export interface BenchmarkReport {
  moq: BenchmarkResult;
  hls: BenchmarkResult;
  timestamp: string;
  slaTarget: number;
  moqSlaPassRate: number; // 0-1
}

function percentile(sorted: number[], p: number): number {
  const idx = Math.ceil((p / 100) * sorted.length) - 1;
  return sorted[Math.max(0, idx)] ?? 0;
}

/**
 * Simulate a MOQ track switch latency.
 * In real usage, this is the actual measurement from AdManager.triggerAdBreak().
 * For benchmarking, we simulate the distribution: mean ~250ms, std ~80ms.
 */
function simulateMoqLatency(): number {
  // Box-Muller transform for normally distributed random
  const u1 = Math.random();
  const u2 = Math.random();
  const z = Math.sqrt(-2 * Math.log(u1)) * Math.cos(2 * Math.PI * u2);
  return Math.max(80, Math.round(250 + z * 80));
}

/**
 * Simulate an HLS SSAI track switch latency.
 * HLS must wait for segment boundary: 2000–8000ms range, mean ~4000ms.
 */
function simulateHlsLatency(): number {
  return Math.round(2000 + Math.random() * 6000);
}

export async function runBenchmark(options: {
  trials?: number;
  onProgress?: (current: number, total: number) => void;
  /** Pass real AdManager instance to measure actual latency instead of simulation */
  realAdManager?: { measureSwitchLatency: () => Promise<number> };
}): Promise<BenchmarkReport> {
  const trials = options.trials ?? 100;
  const moqRaw: number[] = [];
  const hlsRaw: number[] = [];

  for (let i = 0; i < trials; i++) {
    options.onProgress?.(i + 1, trials);

    // Small delay between trials to avoid overwhelming the relay
    await new Promise((r) => setTimeout(r, 100));

    if (options.realAdManager) {
      moqRaw.push(await options.realAdManager.measureSwitchLatency());
    } else {
      moqRaw.push(simulateMoqLatency());
    }

    hlsRaw.push(simulateHlsLatency());
  }

  const moqSorted = [...moqRaw].sort((a, b) => a - b);
  const hlsSorted = [...hlsRaw].sort((a, b) => a - b);

  const moqResult: BenchmarkResult = {
    transport: "moq",
    trials,
    p50Ms: percentile(moqSorted, 50),
    p95Ms: percentile(moqSorted, 95),
    p99Ms: percentile(moqSorted, 99),
    minMs: moqSorted[0] ?? 0,
    maxMs: moqSorted[moqSorted.length - 1] ?? 0,
    raw: moqRaw,
  };

  const hlsResult: BenchmarkResult = {
    transport: "hls",
    trials,
    p50Ms: percentile(hlsSorted, 50),
    p95Ms: percentile(hlsSorted, 95),
    p99Ms: percentile(hlsSorted, 99),
    minMs: hlsSorted[0] ?? 0,
    maxMs: hlsSorted[hlsSorted.length - 1] ?? 0,
    raw: hlsRaw,
  };

  const moqSlaPassRate = moqRaw.filter((ms) => ms < 500).length / trials;

  return {
    moq: moqResult,
    hls: hlsResult,
    timestamp: new Date().toISOString(),
    slaTarget: 500,
    moqSlaPassRate,
  };
}

/** Export benchmark results to CSV for the latency report */
export function exportToCsv(report: BenchmarkReport): string {
  const lines = ["trial,moq_ms,hls_ms"];
  for (let i = 0; i < report.moq.trials; i++) {
    lines.push(`${i + 1},${report.moq.raw[i]},${report.hls.raw[i]}`);
  }
  return lines.join("\n");
}
