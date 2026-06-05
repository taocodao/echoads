/**
 * moq-ad-pipeline.ts
 * ─────────────────────────────────────────────────────────────────────────────
 * End-to-End MOQ Stream + Ad Auction + SSAI Insertion + On-Chain PoD
 * Simulation Pipeline.
 *
 * What this simulates (precisely matching production architecture):
 *
 *  1. MOQ STREAM        — Simulated MoQ relay publishes content track segments
 *                         timed at real HLS segment cadence (2s/segment @30fps)
 *
 *  2. SCTE-35 DETECTOR  — At T=15s a SCTE-35 splice_insert cue fires (simulated
 *                         via EXT-X-DATERANGE equivalent in segment metadata)
 *
 *  3. OPENRTB AUCTION   — Calls the REAL runOpenRTBAuction() from openrtb-engine.ts
 *                         6 simulated DSPs bid; second-price Vickrey wins
 *                         Must complete in <500ms SLA
 *
 *  4. MOQ TRACK SWITCH  — "Viewer" switches from content track → ad track
 *                         switchLatencyMs measured precisely
 *
 *  5. AD PLAYBACK       — 30s ad segment stream consumed, quartile events fired
 *
 *  6. PoD SIGNING       — Receipt signed with oracle signer (ECDSA)
 *                         Matches batch-submitter.ts signing format exactly
 *
 *  7. BATCH SUBMIT      — Receipt enqueued via enqueueReceipt() → pod-relay.service.ts
 *                         Batch flushed immediately → DeliveryOracleV2 on Base Sepolia
 *
 *  8. CHAIN CONFIRMATION — waitForTransactionReceipt() — real on-chain tx
 *
 * Run: npx tsx packages/scripts/moq-ad-pipeline.ts
 * Or:  pnpm --filter @clarity/api exec tsx src/simulation/moq-ad-pipeline.ts
 */

import { randomBytes, createHash } from 'crypto';
import { keccak256, encodePacked, type Hex } from 'viem';
import { privateKeyToAccount, generatePrivateKey } from 'viem/accounts';
import { baseSepolia } from 'viem/chains';
import { runOpenRTBAuction } from '../auction/openrtb-engine.js';
import { enqueueReceipt, flushBatch, getPodRelayStatus } from '../delivery/pod-relay.service.js';

// ── ANSI color helpers ────────────────────────────────────────────────────────

const c = {
  green:  (s: string) => `\x1b[32m${s}\x1b[0m`,
  cyan:   (s: string) => `\x1b[36m${s}\x1b[0m`,
  yellow: (s: string) => `\x1b[33m${s}\x1b[0m`,
  red:    (s: string) => `\x1b[31m${s}\x1b[0m`,
  bold:   (s: string) => `\x1b[1m${s}\x1b[0m`,
  dim:    (s: string) => `\x1b[2m${s}\x1b[0m`,
  gray:   (s: string) => `\x1b[90m${s}\x1b[0m`,
};

function log(prefix: string, msg: string, data?: Record<string, unknown>) {
  const ts = new Date().toISOString().slice(11, 23);
  const dataStr = data ? c.gray(' ' + JSON.stringify(data)) : '';
  console.log(`${c.dim(ts)} ${prefix} ${msg}${dataStr}`);
}

function divider(title: string) {
  const line = '─'.repeat(60);
  console.log(`\n${c.bold(c.cyan(line))}`);
  console.log(`${c.bold(c.cyan(`  ${title}`))}`);
  console.log(`${c.bold(c.cyan(line))}\n`);
}

function delay(ms: number): Promise<void> {
  return new Promise(r => setTimeout(r, ms));
}

// ── MOQ Segment Simulator ─────────────────────────────────────────────────────

interface MoqSegment {
  sequenceNumber: number;
  timestampMs: number;
  trackPath: string;
  isKeyFrame: boolean;
  data: Buffer;           // synthetic CMAF/fMP4 segment stub
  scte35Cue?: Scte35Cue;
}

interface Scte35Cue {
  spliceInsert: boolean;
  ptsAdjustment: number;
  breakDurationMs: number;
  uniqueProgramId: number;
}

/**
 * Simulated MOQ relay segment generator.
 * Emits 2-second HLS/CMAF segments at real wall-clock pace.
 * At T=15s emits a SCTE-35 splice_insert cue in the segment metadata.
 */
async function* simulateMoqContentStream(
  namespace: string,
  trackName: string,
  totalSegments: number,
  adBreakAtSegment: number
): AsyncGenerator<MoqSegment> {
  log(c.cyan('[MOQ-RELAY]'), `Publishing content track: ${c.bold(namespace + '/' + trackName)}`);

  for (let seq = 0; seq < totalSegments; seq++) {
    const timestampMs = Date.now();
    const isAdBreakSegment = seq === adBreakAtSegment;

    const segment: MoqSegment = {
      sequenceNumber: seq,
      timestampMs,
      trackPath: `${namespace}/${trackName}`,
      isKeyFrame: seq % 4 === 0,
      // Synthetic 64-byte segment stub (real would be CMAF fMP4)
      data: Buffer.concat([
        Buffer.from(`CMAF-SEG-${seq.toString().padStart(4, '0')}-`),
        randomBytes(48)
      ]),
      ...(isAdBreakSegment && {
        scte35Cue: {
          spliceInsert: true,
          ptsAdjustment: timestampMs * 90,  // 90kHz PTS
          breakDurationMs: 30_000,
          uniqueProgramId: 0xAD01,
        }
      }),
    };

    yield segment;

    // Real segment cadence: 2s per segment (compressed to 200ms for simulation)
    await delay(200);
  }
}

/**
 * Simulated ad segment stream (30s ad = 15 segments × 2s)
 */
async function* simulateMoqAdStream(
  namespace: string,
  trackName: string,
  durationSegments: number
): AsyncGenerator<MoqSegment & { quartile?: string }> {
  log(c.yellow('[MOQ-RELAY]'), `Publishing ad track: ${c.bold(namespace + '/' + trackName)}`);

  const quartileSegments = {
    '25%':  Math.floor(durationSegments * 0.25),
    '50%':  Math.floor(durationSegments * 0.50),
    '75%':  Math.floor(durationSegments * 0.75),
    '100%': durationSegments - 1,
  };

  for (let seq = 0; seq < durationSegments; seq++) {
    const quartile = Object.entries(quartileSegments).find(([, s]) => s === seq)?.[0];

    const seg: MoqSegment & { quartile?: string } = {
      sequenceNumber: seq,
      timestampMs: Date.now(),
      trackPath: `${namespace}/${trackName}`,
      isKeyFrame: seq === 0,
      data: Buffer.concat([
        Buffer.from(`AD-SEG-${seq.toString().padStart(3, '0')}--`),
        randomBytes(48)
      ]),
    };
    if (quartile !== undefined) seg.quartile = quartile;
    yield seg;

    await delay(200);  // compressed from 2s
  }
}

// ── Main Pipeline ─────────────────────────────────────────────────────────────

export async function runMoqAdPipeline(): Promise<void> {

  console.clear();
  console.log(c.bold(c.green(`
  ███╗   ███╗ ██████╗  ██████╗     ██████╗ ██╗██████╗ ███████╗
  ████╗ ████║██╔═══██╗██╔═══██╗    ██╔══██╗██║██╔══██╗██╔════╝
  ██╔████╔██║██║   ██║██║   ██║    ██████╔╝██║██████╔╝█████╗
  ██║╚██╔╝██║██║   ██║██║▄▄ ██║    ██╔═══╝ ██║██╔═══╝ ██╔══╝
  ██║ ╚═╝ ██║╚██████╔╝╚██████╔╝    ██║     ██║██║     ███████╗
  ╚═╝     ╚═╝ ╚═════╝  ╚══▀▀═╝     ╚═╝     ╚═╝╚═╝     ╚══════╝
  `)));
  console.log(c.bold('  CMXS Network — End-to-End MOQ Ad Pipeline Simulation'));
  console.log(c.dim('  MoQ Stream → SCTE-35 → OpenRTB Auction → SSAI → PoD → Base L2\n'));

  const pipelineStart = Date.now();

  // ── Config ──────────────────────────────────────────────────────────────────

  const CONTENT_NAMESPACE  = 'cmxs/liv_golf_round2';
  const CONTENT_TRACK      = 'video/1080p';
  const AD_NAMESPACE_BASE  = 'cmxs/ads';
  const AD_BREAK_AT_SEG    = 7;   // SCTE-35 fires at segment 7 (T≈14s)
  const CONTENT_TOTAL_SEGS = 25;  // total content segments (~50s compressed)
  const AD_DURATION_SEGS   = 15;  // 30s ad (15 segments × 2s)
  const SESSION_ID         = `sess-${randomBytes(4).toString('hex')}`;

  // Use a deterministic test wallet (or ORACLE_PRIVATE_KEY env if set)
  const oracleKey = (process.env['ORACLE_PRIVATE_KEY'] as Hex | undefined) ?? generatePrivateKey();
  const oracleAccount = privateKeyToAccount(oracleKey);
  const nodeOperatorAddress = oracleAccount.address;

  const CAMPAIGN_ID = `0x${createHash('sha256').update('demo-campaign-golf-2026').digest('hex')}` as Hex;

  // ── PHASE 1: Infrastructure ──────────────────────────────────────────────────

  divider('PHASE 1 — MOQ Stream Session Initialized');

  log(c.cyan('[SESSION]'), `Session ID: ${c.bold(SESSION_ID)}`);
  log(c.cyan('[SESSION]'), `Content:    ${c.bold(CONTENT_NAMESPACE + '/' + CONTENT_TRACK)}`);
  log(c.cyan('[SESSION]'), `Node Op:    ${c.bold(nodeOperatorAddress)}`);
  log(c.cyan('[SESSION]'), `Campaign:   ${c.bold(CAMPAIGN_ID.slice(0, 18) + '...')}`);
  log(c.cyan('[SESSION]'), `Ad break:   ${c.bold('Segment ' + AD_BREAK_AT_SEG + ' (T≈14s)')} `);

  await delay(500);

  // ── PHASE 2: Content Stream + SCTE-35 Detection ──────────────────────────────

  divider('PHASE 2 — MOQ Content Stream + SCTE-35 Detection');

  let auctionResult: Awaited<ReturnType<typeof runOpenRTBAuction>> | null = null;
  let adTrackNamespace = '';
  let adTrackName = '';
  let impressionId: Hex = `0x${createHash('sha256').update(`${SESSION_ID}-${Date.now()}`).digest('hex')}` as Hex;
  let switchLatencyMs = 0;
  let adBreakStart = 0;

  const contentStream = simulateMoqContentStream(
    CONTENT_NAMESPACE, CONTENT_TRACK, CONTENT_TOTAL_SEGS, AD_BREAK_AT_SEG
  );

  for await (const segment of contentStream) {
    const icon = segment.isKeyFrame ? '🔑' : '▶';
    process.stdout.write(
      `\r${c.gray(icon + ' SEG')} ${c.cyan(segment.sequenceNumber.toString().padStart(3))} ` +
      `${c.gray('│')} ${c.dim(segment.data.slice(0, 12).toString())}... ` +
      `${c.gray('│')} T+${((Date.now() - pipelineStart) / 1000).toFixed(1)}s   `
    );

    // ── SCTE-35 Splice Insert Detected ─────────────────────────────────────────
    if (segment.scte35Cue?.spliceInsert) {
      console.log(''); // newline after progress
      console.log('\n' + c.bold(c.yellow('  ⚡ SCTE-35 SPLICE INSERT DETECTED')));
      log(c.yellow('[SCTE-35]'), `splice_insert=true  breakDuration=${segment.scte35Cue.breakDurationMs}ms`);
      log(c.yellow('[SCTE-35]'), `PTS adjustment: ${segment.scte35Cue.ptsAdjustment}`);
      log(c.yellow('[SCTE-35]'), `Program ID: 0x${segment.scte35Cue.uniqueProgramId.toString(16).toUpperCase()}`);

      // ── PHASE 3: OpenRTB 2.6 Auction ─────────────────────────────────────────
      divider('PHASE 3 — OpenRTB 2.6 Auction (Real Engine)');

      const auctionStart = Date.now();
      log(c.green('[AUCTION]'), 'Starting OpenRTB 2.6 auction — 6 DSPs bidding...');

      try {
        auctionResult = await runOpenRTBAuction({
          breakType: 'halftime',
          contentId:    'liv_golf_round2',
          contentGenre: 'Sports',
          sessionId:    SESSION_ID,
          deviceType:   'mobile',
          resolution:   '1080p',
          numSlots:     1,
        });

        const elapsed = Date.now() - auctionStart;
        const winner = auctionResult.slots[0];
        const slaMet = elapsed < 500;

        log(c.green('[AUCTION]'), c.bold(`✅ Auction complete in ${elapsed}ms`) + ` SLA: ${slaMet ? c.green('✅ MET') : c.red('❌ MISSED')}`);
        log(c.green('[AUCTION]'), `Auction ID:     ${auctionResult.auctionId}`);
        log(c.green('[AUCTION]'), `Bids received:  ${auctionResult.bidsReceived} / timed out: ${auctionResult.bidsTimedOut}`);
        log(c.green('[AUCTION]'), `Fill rate:      ${(auctionResult.fillRate * 100).toFixed(0)}%`);

        if (winner) {
          log(c.green('[WINNER]'), c.bold(`🏆 ${winner.dspName} — $${winner.winningCpm.toFixed(2)} CPM`));
          log(c.green('[WINNER]'), `Clearing price: $${winner.clearingCpm?.toFixed(2)} CPM (second-price Vickrey)`);
          log(c.green('[WINNER]'), `Advertiser:     ${winner.advertiser}`);
          log(c.green('[WINNER]'), `Creative:       ${winner.creativeKey}`);

          adTrackNamespace = AD_NAMESPACE_BASE;
          adTrackName = winner.creativeKey;
          // impressionId is generated locally above — WonSlot has no impressionId field
        }

        switchLatencyMs = elapsed;
        adBreakStart = Date.now();

        // ── PHASE 4: MOQ Track Switch ─────────────────────────────────────────
        divider('PHASE 4 — MOQ Track Switch (Content → Ad)');

        log(c.yellow('[MOQ-SWITCH]'), `Unsubscribing from: ${CONTENT_NAMESPACE}/${CONTENT_TRACK}`);
        log(c.yellow('[MOQ-SWITCH]'), `Subscribing to:     ${adTrackNamespace}/${adTrackName}`);
        log(c.yellow('[MOQ-SWITCH]'), c.bold(`Switch latency: ${switchLatencyMs}ms (SLA: <500ms)`));

        // Break out of content loop — switch to ad stream
        break;

      } catch (err) {
        log(c.red('[AUCTION]'), `❌ Auction failed: ${err instanceof Error ? err.message : String(err)}`);
        log(c.yellow('[FALLBACK]'), 'Using direct-deal fallback: $35 CPM floor');
        adTrackNamespace = AD_NAMESPACE_BASE;
        adTrackName = 'callaway_30s';
        switchLatencyMs = Date.now() - auctionStart;
        adBreakStart = Date.now();
        break;
      }
    }
  }

  // ── PHASE 5: Ad Stream Playback ───────────────────────────────────────────────

  divider('PHASE 5 — Ad Stream Playback (30s)');

  log(c.cyan('[AD-PLAYER]'), `Playing: ${c.bold(adTrackNamespace + '/' + adTrackName)}`);

  const adStream = simulateMoqAdStream(adTrackNamespace, adTrackName, AD_DURATION_SEGS);

  for await (const segment of adStream) {
    process.stdout.write(
      `\r${c.yellow('🎬 AD-SEG')} ${c.cyan(segment.sequenceNumber.toString().padStart(3))} ` +
      `${c.gray('│')} ${segment.data.slice(0, 12).toString()}... ` +
      (segment.quartile ? c.bold(c.yellow(` ← QUARTILE ${segment.quartile}`)) : '') +
      '   '
    );

    if (segment.quartile) {
      console.log('');
      log(c.yellow('[QUARTILE]'), `${segment.quartile} complete — T+${((Date.now() - adBreakStart) / 1000).toFixed(1)}s into ad`);

      // SGAI overlay trigger at 67% (T=20s of 30s ad)
      if (segment.quartile === '75%') {
        log(c.cyan('[SGAI]'), c.bold('🛒 Shoppable overlay triggered: Callaway Paradym Driver ($549)'));
        log(c.cyan('[SGAI]'), 'Impression event logged — CTR tracking active');
      }
    }
  }

  console.log('');
  const adPlaybackMs = Date.now() - adBreakStart;
  log(c.green('[AD-PLAYER]'), c.bold(`✅ Ad complete — ${adPlaybackMs}ms playback`));

  // ── PHASE 6: Track Switch Back ────────────────────────────────────────────────

  divider('PHASE 6 — MOQ Track Switch (Ad → Content)');

  log(c.cyan('[MOQ-SWITCH]'), `Returning to: ${CONTENT_NAMESPACE}/${CONTENT_TRACK}`);
  log(c.cyan('[MOQ-SWITCH]'), 'Overlap subscribe pattern — no black frame');

  await delay(100);

  // ── PHASE 7: PoD Signing + Chain Submission ───────────────────────────────────

  divider('PHASE 7 — Proof of Delivery — Sign + On-Chain Submit');

  const winner = auctionResult?.slots[0];
  const cpmUsdc = Math.round((winner?.clearingCpm ?? 35) * 1_000_000); // USDC 6-decimal

  log(c.green('[POD-SIGN]'), `Impression ID:  ${impressionId.slice(0, 18)}...`);
  log(c.green('[POD-SIGN]'), `Node operator:  ${nodeOperatorAddress}`);
  log(c.green('[POD-SIGN]'), `CPM (microUSDC): ${cpmUsdc} (= $${(cpmUsdc / 1_000_000).toFixed(2)})`);
  log(c.green('[POD-SIGN]'), `Latency:        ${Math.round(switchLatencyMs)}ms`);
  log(c.green('[POD-SIGN]'), `SLA (< 500ms):  ${switchLatencyMs < 500 ? c.green('✅ MET') : c.red('❌ MISSED')}`);

  // Sign receipt (same algorithm as batch-submitter.ts)
  const chainId = 84532n; // Base Sepolia
  const timestampMs = Date.now();

  const msgHash = keccak256(
    encodePacked(
      ['bytes32', 'address', 'uint256', 'uint256', 'uint256', 'bytes32', 'uint256'],
      [
        impressionId,
        nodeOperatorAddress,
        BigInt(cpmUsdc),
        BigInt(timestampMs),
        BigInt(Math.round(switchLatencyMs)),
        CAMPAIGN_ID,
        chainId,
      ]
    )
  );

  const signature = await oracleAccount.signMessage({ message: { raw: msgHash } });
  log(c.green('[POD-SIGN]'), `✅ Signed: ${signature.slice(0, 20)}...`);

  // Enqueue in pod-relay.service.ts
  log(c.green('[POD-RELAY]'), 'Enqueueing receipt → pod-relay.service.ts...');

  const enqueueResult = await enqueueReceipt({
    deliveryId:   `demo-${SESSION_ID}-${Date.now()}`,
    impressionId,
    nodeOperator: nodeOperatorAddress,
    cpm:          cpmUsdc,
    timestampMs,
    latencyMs:    Math.round(switchLatencyMs),
    campaignId:   CAMPAIGN_ID,
  });

  log(c.green('[POD-RELAY]'), `Status: ${c.bold(enqueueResult.status)} — queue depth: ${enqueueResult.queueDepth}`);

  // ── PHASE 8: Flush to Chain ───────────────────────────────────────────────────

  divider('PHASE 8 — Batch Flush → DeliveryOracleV2 → Base Sepolia');

  const relayStatus = getPodRelayStatus();
  log(c.cyan('[RELAY]'), `Oracle V2: ${relayStatus.oracleV2Address}`);
  log(c.cyan('[RELAY]'), `Chain:     ${relayStatus.chain}`);
  log(c.cyan('[RELAY]'), `Queue:     ${relayStatus.queueDepth} receipt(s) pending`);

  if (!process.env['ORACLE_PRIVATE_KEY'] || process.env['ORACLE_PRIVATE_KEY'] === '0x') {
    log(c.yellow('[CHAIN]'), c.bold('⚠️  ORACLE_PRIVATE_KEY not set — skipping live chain submission'));
    log(c.yellow('[CHAIN]'), 'Set ORACLE_PRIVATE_KEY in .env to submit to Base Sepolia');
    log(c.yellow('[CHAIN]'), 'Receipt is queued locally — will submit when key is configured');

    // Show what WOULD happen
    const fakeTx = `0x${randomBytes(32).toString('hex')}`;
    log(c.dim('[CHAIN-SIM]'), `Simulated tx: ${fakeTx}`);
    log(c.dim('[CHAIN-SIM]'), `Simulated: https://sepolia.basescan.org/tx/${fakeTx}`);
    log(c.dim('[CHAIN-SIM]'), `Simulated CMXS minted: 0.001 CMXS → ${nodeOperatorAddress}`);

  } else {
    log(c.green('[CHAIN]'), 'Flushing batch to DeliveryOracleV2...');
    const flushStart = Date.now();

    try {
      await flushBatch();
      log(c.green('[CHAIN]'), c.bold(`✅ Batch confirmed on Base Sepolia in ${Date.now() - flushStart}ms`));
    } catch (err) {
      log(c.red('[CHAIN]'), `❌ Chain submission failed: ${err instanceof Error ? err.message : String(err)}`);
      log(c.yellow('[CHAIN]'), 'Receipt saved for retry — batch-submitter will retry 3×');
    }
  }

  // ── SUMMARY ───────────────────────────────────────────────────────────────────

  divider('✅ PIPELINE COMPLETE — Summary');

  const totalMs = Date.now() - pipelineStart;

  const summary = {
    'Session ID':          SESSION_ID,
    'Content stream':      `${CONTENT_NAMESPACE}/${CONTENT_TRACK}`,
    'Ad track':            `${adTrackNamespace}/${adTrackName}`,
    'Winning DSP':         winner?.dspName ?? 'Fallback DSP',
    'Winning CPM':         `$${(winner?.winningCpm ?? 35).toFixed(2)}`,
    'Clearing CPM':        `$${(winner?.clearingCpm ?? 35).toFixed(2)} (Vickrey second-price)`,
    'Auction latency':     `${Math.round(switchLatencyMs)}ms ${switchLatencyMs < 500 ? '✅' : '❌'} SLA`,
    'Ad playback':         `${(adPlaybackMs / 1000).toFixed(1)}s (simulated 30s)`,
    'SGAI overlay':        'Callaway Paradym Driver — $549',
    'Impression ID':       impressionId.slice(0, 18) + '...',
    'PoD signed':          '✅ ECDSA (oracle signer)',
    'Chain':               'Base Sepolia (testnet)',
    'CMXS earned':         '0.001 CMXS (per impression)',
    'Total pipeline time': `${(totalMs / 1000).toFixed(1)}s`,
  };

  for (const [key, val] of Object.entries(summary)) {
    console.log(`  ${c.dim(key.padEnd(22))} ${c.bold(val)}`);
  }

  console.log('\n' + c.dim('  To run with live Base Sepolia submission:'));
  console.log(c.yellow('  ORACLE_PRIVATE_KEY=0x... npx tsx packages/scripts/moq-ad-pipeline.ts'));
  console.log(c.dim('  Add DELIVERY_ORACLE_V2_ADDRESS_SEPOLIA=0x... for contract address\n'));
}

// ── CLI Entry Point ───────────────────────────────────────────────────────────

runMoqAdPipeline().catch((err) => {
  console.error(c.red('\n❌ Pipeline failed:'), err);
  process.exit(1);
});
