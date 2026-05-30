/** @type {import('next').NextConfig} */
const nextConfig = {
  // Allow builds to succeed even if NEXT_PUBLIC_* env vars are unset at build time
  // (they are injected at runtime by Vercel).
  env: {
    NEXT_PUBLIC_API_URL: process.env.NEXT_PUBLIC_API_URL ?? "",
    NEXT_PUBLIC_CMXS_CONTRACT_ADDRESS: process.env.NEXT_PUBLIC_CMXS_CONTRACT_ADDRESS ?? "",
    NEXT_PUBLIC_ORACLE_CONTRACT_ADDRESS: process.env.NEXT_PUBLIC_ORACLE_CONTRACT_ADDRESS ?? "",
    NEXT_PUBLIC_BASE_SEPOLIA_RPC_URL: process.env.NEXT_PUBLIC_BASE_SEPOLIA_RPC_URL ?? "https://sepolia.base.org",
    NEXT_PUBLIC_CHAIN_ID: process.env.NEXT_PUBLIC_CHAIN_ID ?? "84532",
  },
};

module.exports = nextConfig;
