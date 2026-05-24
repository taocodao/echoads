import { CoinbaseWalletSDK } from "@coinbase/wallet-sdk";
import { createWalletClient, custom, http } from "viem";
import { baseSepolia } from "viem/chains";
import { privateKeyToAccount } from "viem/accounts";
import type { WalletClient } from "viem";

/**
 * Wallet initialization for Project Clarity player.
 *
 * Two modes:
 *   1. DEMO_MODE=false (default) — Coinbase Smart Wallet with passkey flow
 *      Best for real deployments. No browser extension required.
 *
 *   2. DEMO_MODE=true — Private key wallet (viem privateKeyToAccount)
 *      For boardroom demos — eliminates passkey popup interruptions.
 *      Set VITE_DEMO_MODE=true and VITE_DEMO_WALLET_PRIVATE_KEY in env.
 */

const DEMO_MODE = import.meta.env["VITE_DEMO_MODE"] === "true";
const DEMO_PRIVATE_KEY = import.meta.env["VITE_DEMO_WALLET_PRIVATE_KEY"] as `0x${string}` | undefined;

export async function initWallet(): Promise<{ walletClient: WalletClient; address: string }> {
  if (DEMO_MODE && DEMO_PRIVATE_KEY) {
    return initDemoWallet(DEMO_PRIVATE_KEY);
  }
  return initSmartWallet();
}

/** Passkey-based Coinbase Smart Wallet (production mode) */
async function initSmartWallet(): Promise<{ walletClient: WalletClient; address: string }> {
  const sdk = new CoinbaseWalletSDK({
    appName: "Project Clarity",
    appLogoUrl: `${window.location.origin}/logo.png`,
    appChainIds: [baseSepolia.id], // 84532
  });

  // makeWeb3Provider: no browser extension required
  // Falls back to passkey flow (WebAuthn) if no Coinbase Wallet extension installed
  const provider = sdk.makeWeb3Provider();

  // Trigger wallet connection (shows passkey prompt or extension)
  const accounts = await provider.request({ method: "eth_requestAccounts" }) as string[];

  const walletClient = createWalletClient({
    account: accounts[0] as `0x${string}`,
    chain: baseSepolia,
    transport: custom(provider),
  });

  console.log(`[wallet] Smart Wallet connected: ${accounts[0]}`);
  return { walletClient, address: accounts[0] as string };
}

/** Private key wallet for boardroom demos — no passkey prompts */
function initDemoWallet(privateKey: `0x${string}`): { walletClient: WalletClient; address: string } {
  const account = privateKeyToAccount(privateKey);

  const walletClient = createWalletClient({
    account,
    chain: baseSepolia,
    transport: http(import.meta.env["VITE_BASE_SEPOLIA_RPC_URL"] ?? "https://sepolia.base.org"),
  });

  console.log(`[wallet] Demo wallet loaded: ${account.address}`);
  console.warn("[wallet] ⚠️  DEMO MODE — never use a real-funds private key here.");
  return { walletClient, address: account.address };
}
