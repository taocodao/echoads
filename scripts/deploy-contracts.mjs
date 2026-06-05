#!/usr/bin/env node
/**
 * deploy-contracts.mjs
 * Deploys CMXS + DeliveryOracle to Base Sepolia using ethers v6.
 *
 * Run:
 *   node scripts/deploy-contracts.mjs
 *
 * Prerequisites:
 *   npm install ethers   (in the repo root)
 *   .env filled with DEPLOYER_PRIVATE_KEY and BASESCAN_API_KEY
 */

import { ethers } from 'ethers';
import { readFileSync, writeFileSync } from 'fs';
import { resolve, dirname } from 'path';
import { fileURLToPath } from 'url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const ROOT = resolve(__dirname, '..');

// ── Load compiled ABIs from Foundry output ────────────────────────────────────
function loadArtifact(name) {
  const path = resolve(ROOT, `packages/contracts/out/${name}.sol/${name}.json`);
  try {
    const art = JSON.parse(readFileSync(path, 'utf8'));
    return { abi: art.abi, bytecode: art.bytecode.object };
  } catch (e) {
    throw new Error(`[deploy] Cannot load ${name} artifact — run 'forge build' first: ${e.message}`);
  }
}

async function main() {
  // ── Config ──────────────────────────────────────────────────────────────────
  const pk       = process.env.DEPLOYER_PRIVATE_KEY;
  const rpc      = process.env.BASE_SEPOLIA_RPC_URL || 'https://sepolia.base.org';
  const treasury = process.env.TREASURY_ADDRESS;
  const usdc     = process.env.USDC_BASE_SEPOLIA || '0x036CbD53842c5426634e7929541eC2318f3dCF7e';

  if (!pk)       throw new Error('DEPLOYER_PRIVATE_KEY not set in .env');
  if (!treasury) throw new Error('TREASURY_ADDRESS not set in .env');

  const provider = new ethers.JsonRpcProvider(rpc);
  const wallet   = new ethers.Wallet(pk, provider);
  const balance  = await provider.getBalance(wallet.address);

  console.log(`\n[deploy] Deployer: ${wallet.address}`);
  console.log(`[deploy] Balance:  ${ethers.formatEther(balance)} ETH`);
  console.log(`[deploy] Network:  Base Sepolia (84532)\n`);

  if (balance === 0n) {
    console.error('[deploy] ❌ Wallet has no ETH. Fund it at https://faucet.quicknode.com/base/sepolia');
    process.exit(1);
  }

  // ── Deploy CMXS Token ───────────────────────────────────────────────────────
  console.log('[deploy] Deploying CMXS Token…');
  const cmxsArt  = loadArtifact('CMXS');
  const CMXSFactory = new ethers.ContractFactory(cmxsArt.abi, cmxsArt.bytecode, wallet);
  const cmxs = await CMXSFactory.deploy(treasury);
  await cmxs.waitForDeployment();
  const cmxsAddress = await cmxs.getAddress();
  console.log(`[deploy] ✅ CMXS Token:      ${cmxsAddress}`);

  // ── Deploy DeliveryOracle ───────────────────────────────────────────────────
  console.log('[deploy] Deploying DeliveryOracle…');
  const oracleArt = loadArtifact('DeliveryOracle');
  const OracleFactory = new ethers.ContractFactory(oracleArt.abi, oracleArt.bytecode, wallet);
  const oracle = await OracleFactory.deploy(wallet.address, cmxsAddress);
  await oracle.waitForDeployment();
  const oracleAddress = await oracle.getAddress();
  console.log(`[deploy] ✅ DeliveryOracle:  ${oracleAddress}`);

  // ── Grant MINTER_ROLE to DeliveryOracle ────────────────────────────────────
  console.log('[deploy] Granting MINTER_ROLE…');
  const minterRole = await cmxs.MINTER_ROLE();
  await (await cmxs.grantRole(minterRole, oracleAddress)).wait();
  console.log('[deploy] ✅ MINTER_ROLE granted');

  // ── Deploy AdBurn ───────────────────────────────────────────────────────────
  console.log('[deploy] Deploying AdBurn…');
  const adBurnArt = loadArtifact('AdBurn');
  const AdBurnFactory = new ethers.ContractFactory(adBurnArt.abi, adBurnArt.bytecode, wallet);
  const adBurn = await AdBurnFactory.deploy(usdc, cmxsAddress, treasury, 1500);
  await adBurn.waitForDeployment();
  const adBurnAddress = await adBurn.getAddress();
  console.log(`[deploy] ✅ AdBurn:          ${adBurnAddress}`);

  // ── Save addresses ──────────────────────────────────────────────────────────
  const output = {
    network: 'base-sepolia',
    chainId: 84532,
    deployer: wallet.address,
    deployedAt: new Date().toISOString(),
    contracts: {
      CMXS: cmxsAddress,
      DeliveryOracle: oracleAddress,
      AdBurn: adBurnAddress,
    }
  };

  const outPath = resolve(ROOT, 'deployments.json');
  writeFileSync(outPath, JSON.stringify(output, null, 2));

  console.log('\n══════════════════════════════════════════════════════');
  console.log('  DEPLOYMENT COMPLETE');
  console.log('══════════════════════════════════════════════════════');
  console.log(`  CMXS Token:     ${cmxsAddress}`);
  console.log(`  DeliveryOracle: ${oracleAddress}`);
  console.log(`  AdBurn:         ${adBurnAddress}`);
  console.log(`\n  Saved to: deployments.json`);
  console.log(`\n  Verify on Basescan:`);
  console.log(`  https://sepolia.basescan.org/address/${cmxsAddress}`);
  console.log(`  https://sepolia.basescan.org/address/${oracleAddress}`);
  console.log('══════════════════════════════════════════════════════\n');

  // ── Print iOS constants to paste into HomeViewModel.swift ──────────────────
  console.log('  Paste these into packages/arenza-ios/HomeViewModel.swift:');
  console.log(`  static let cmxsTokenAddress = "${cmxsAddress}"`);
  console.log(`  static let oracleAddress    = "${oracleAddress}"`);
}

main().catch(err => { console.error(err); process.exit(1); });
