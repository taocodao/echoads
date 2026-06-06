/**
 * compile-and-deploy.cjs
 * Compiles CMXS.sol + DeliveryOracle.sol using solc npm package,
 * then deploys both to Base Sepolia using ethers v6.
 *
 * Usage:
 *   node scripts/deploy-env/compile-and-deploy.cjs
 *
 * Requires:
 *   - DEPLOYER_PRIVATE_KEY env var (or uses the hardcoded demo key below)
 *   - Internet access to Base Sepolia RPC
 */

'use strict';

const solc    = require('./node_modules/solc');
const ethers  = require('./node_modules/ethers');
const fs      = require('fs');
const path    = require('path');

// ── Configuration ─────────────────────────────────────────────────────────────
const RPC_URL     = process.env.BASE_SEPOLIA_RPC_URL || 'https://sepolia.base.org';
// Demo-only deployer key — NEVER use a real-funds wallet
const DEPLOYER_PK = process.env.DEPLOYER_PRIVATE_KEY
  || '0x69e7579b34393a3d461de80d7f39edcd4fa04f556159bb46ee475cd839aaf016';

const CONTRACTS_DIR = path.resolve(__dirname, '../../packages/contracts/src');
const OZ_DIR        = path.resolve(__dirname, '../../packages/contracts/lib/openzeppelin-contracts/contracts');

// ── Read source files ─────────────────────────────────────────────────────────
function readSol(filePath) {
  return fs.readFileSync(filePath, 'utf8');
}

// ── Resolve @openzeppelin imports ─────────────────────────────────────────────
function findImports(importPath) {
  // Handle @openzeppelin/contracts/... imports
  if (importPath.startsWith('@openzeppelin/contracts/')) {
    const relative = importPath.replace('@openzeppelin/contracts/', '');
    const fullPath = path.join(OZ_DIR, relative);
    if (fs.existsSync(fullPath)) {
      return { contents: fs.readFileSync(fullPath, 'utf8') };
    }
  }
  // Handle relative imports
  const resolved = path.resolve(CONTRACTS_DIR, importPath);
  if (fs.existsSync(resolved)) {
    return { contents: fs.readFileSync(resolved, 'utf8') };
  }
  return { error: `File not found: ${importPath}` };
}

// ── Compile a contract ────────────────────────────────────────────────────────
function compile(name, fileName) {
  console.log(`[compile] Compiling ${name}...`);
  const source = readSol(path.join(CONTRACTS_DIR, fileName));

  const input = {
    language: 'Solidity',
    sources: { [fileName]: { content: source } },
    settings: {
      outputSelection: { '*': { '*': ['abi', 'evm.bytecode.object'] } },
      optimizer: { enabled: true, runs: 200 }
    }
  };

  const output = JSON.parse(solc.compile(JSON.stringify(input), { import: findImports }));

  if (output.errors) {
    const errors = output.errors.filter(e => e.severity === 'error');
    if (errors.length > 0) {
      errors.forEach(e => console.error('[compile] ERROR:', e.formattedMessage));
      throw new Error(`Compilation failed for ${name}`);
    }
    // Print warnings only
    output.errors.filter(e => e.severity === 'warning').slice(0, 3).forEach(w =>
      console.warn('[compile] WARN:', w.message.split('\n')[0])
    );
  }

  const contractOutput = output.contracts[fileName][name];
  if (!contractOutput) throw new Error(`Contract ${name} not found in output`);

  const abi      = contractOutput.abi;
  const bytecode = '0x' + contractOutput.evm.bytecode.object;
  console.log(`[compile] ✅ ${name} compiled (abi: ${abi.length} entries, bytecode: ${Math.round(bytecode.length/2)} bytes)`);
  return { abi, bytecode };
}

// ── Main deploy ───────────────────────────────────────────────────────────────
async function main() {
  const provider = new ethers.JsonRpcProvider(RPC_URL);
  const wallet   = new ethers.Wallet(DEPLOYER_PK, provider);

  let balance;
  try {
    balance = await provider.getBalance(wallet.address);
  } catch (e) {
    console.error('[deploy] Cannot connect to Base Sepolia RPC:', e.message);
    process.exit(1);
  }

  console.log('\n[deploy] ════════════════════════════════════════');
  console.log('[deploy] Deployer:', wallet.address);
  console.log('[deploy] Balance: ', ethers.formatEther(balance), 'ETH');
  console.log('[deploy] Network:  Base Sepolia (84532)');
  console.log('[deploy] ════════════════════════════════════════\n');

  if (balance === 0n) {
    console.error('[deploy] ❌ Wallet has 0 ETH on Base Sepolia.');
    console.error('[deploy]    Fund it here: https://faucet.quicknode.com/base/sepolia');
    console.error('[deploy]    Address:', wallet.address);
    console.error('\n[deploy] Saving deployer address to deployments.json for reference...');

    const stub = {
      status: 'PENDING_FUNDS',
      network: 'base-sepolia',
      deployer: wallet.address,
      fundingUrl: 'https://faucet.quicknode.com/base/sepolia',
      instruction: `Send at least 0.05 ETH to ${wallet.address} on Base Sepolia, then re-run this script.`,
      contracts: { CMXS: null, DeliveryOracle: null, AdBurn: null }
    };
    fs.writeFileSync(path.resolve(__dirname, '../../deployments.json'), JSON.stringify(stub, null, 2));
    process.exit(0);
  }

  // 1. Compile
  const cmxs   = compile('CMXS', 'CMXS.sol');
  const oracle  = compile('DeliveryOracle', 'DeliveryOracle.sol');
  const adBurn  = compile('AdBurn', 'AdBurn.sol');

  // 2. Deploy CMXS
  console.log('\n[deploy] Deploying CMXS Token...');
  const CMXSFactory = new ethers.ContractFactory(cmxs.abi, cmxs.bytecode, wallet);
  const cmxsContract = await CMXSFactory.deploy(wallet.address);
  await cmxsContract.waitForDeployment();
  const cmxsAddr = await cmxsContract.getAddress();
  console.log('[deploy] ✅ CMXS Token:', cmxsAddr);

  // 3. Deploy DeliveryOracle
  console.log('[deploy] Deploying DeliveryOracle...');
  const OracleFactory = new ethers.ContractFactory(oracle.abi, oracle.bytecode, wallet);
  const oracleContract = await OracleFactory.deploy(wallet.address, cmxsAddr);
  await oracleContract.waitForDeployment();
  const oracleAddr = await oracleContract.getAddress();
  console.log('[deploy] ✅ DeliveryOracle:', oracleAddr);

  // 4. Grant MINTER_ROLE
  console.log('[deploy] Granting MINTER_ROLE to oracle...');
  const minterRole = ethers.keccak256(ethers.toUtf8Bytes('MINTER_ROLE'));
  const grantTx = await cmxsContract.grantRole(minterRole, oracleAddr);
  await grantTx.wait();
  console.log('[deploy] ✅ MINTER_ROLE granted');

  // 5. Deploy AdBurn
  const USDC_SEPOLIA = '0x036CbD53842c5426634e7929541eC2318f3dCF7e';
  console.log('[deploy] Deploying AdBurn...');
  const AdBurnFactory = new ethers.ContractFactory(adBurn.abi, adBurn.bytecode, wallet);
  const adBurnContract = await AdBurnFactory.deploy(USDC_SEPOLIA, cmxsAddr, wallet.address, 1500);
  await adBurnContract.waitForDeployment();
  const adBurnAddr = await adBurnContract.getAddress();
  console.log('[deploy] ✅ AdBurn:', adBurnAddr);

  // 6. Save output
  const result = {
    status: 'DEPLOYED',
    network: 'base-sepolia',
    chainId: 84532,
    deployer: wallet.address,
    deployedAt: new Date().toISOString(),
    contracts: {
      CMXS: cmxsAddr,
      DeliveryOracle: oracleAddr,
      AdBurn: adBurnAddr
    }
  };

  const outPath = path.resolve(__dirname, '../../deployments.json');
  fs.writeFileSync(outPath, JSON.stringify(result, null, 2));

  console.log('\n[deploy] ════════════════════════════════════════');
  console.log('[deploy] DEPLOYMENT COMPLETE');
  console.log('[deploy] ════════════════════════════════════════');
  console.log('[deploy] CMXS Token:     ', cmxsAddr);
  console.log('[deploy] DeliveryOracle: ', oracleAddr);
  console.log('[deploy] AdBurn:         ', adBurnAddr);
  console.log('[deploy]');
  console.log('[deploy] View on Basescan:');
  console.log(`[deploy]   https://sepolia.basescan.org/address/${cmxsAddr}`);
  console.log(`[deploy]   https://sepolia.basescan.org/address/${oracleAddr}`);
  console.log('[deploy]');
  console.log('[deploy] Paste into packages/arenza-ios/HomeViewModel.swift:');
  console.log(`[deploy]   static let cmxsTokenAddress = "${cmxsAddr}"`);
  console.log(`[deploy]   static let oracleAddress    = "${oracleAddr}"`);
  console.log('[deploy] ════════════════════════════════════════\n');
}

main().catch(err => {
  console.error('[deploy] Fatal:', err.message);
  process.exit(1);
});
