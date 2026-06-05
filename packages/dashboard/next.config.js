/** @type {import('next').NextConfig} */
const path = require('path');

const nextConfig = {
  // Silence the "inferred workspace root" warning in pnpm monorepos
  outputFileTracingRoot: path.join(__dirname, '../../'),
  // Allow builds to succeed even if NEXT_PUBLIC_* env vars are unset at build time
  // (they are injected at runtime by Vercel).
  env: {
    NEXT_PUBLIC_API_URL: process.env.NEXT_PUBLIC_API_URL ?? "",
    NEXT_PUBLIC_CMXS_CONTRACT_ADDRESS: process.env.NEXT_PUBLIC_CMXS_CONTRACT_ADDRESS ?? "",
    NEXT_PUBLIC_ORACLE_CONTRACT_ADDRESS: process.env.NEXT_PUBLIC_ORACLE_CONTRACT_ADDRESS ?? "",
    NEXT_PUBLIC_BASE_SEPOLIA_RPC_URL: process.env.NEXT_PUBLIC_BASE_SEPOLIA_RPC_URL ?? "https://sepolia.base.org",
    NEXT_PUBLIC_CHAIN_ID: process.env.NEXT_PUBLIC_CHAIN_ID ?? "84532",
    NEXT_PUBLIC_DEFAULT_NODE: process.env.NEXT_PUBLIC_DEFAULT_NODE ?? "0x0000000000000000000000000000000000000001",
    NEXT_PUBLIC_DEFAULT_CAMPAIGN: process.env.NEXT_PUBLIC_DEFAULT_CAMPAIGN ?? "0xdeadbeef00000000000000000000000000000000000000000000000000000000",
  },
  async redirects() {
    return [
      {
        source: '/simulation',
        destination: '/demo/arenza/index.html',
        permanent: false,
      },
    ]
  },
};

module.exports = nextConfig;

