#!/usr/bin/env bash
# =============================================================================
# deploy-prototype.sh — CMXS FAST Platform Prototype Deployment
# =============================================================================
# Usage:
#   ./scripts/deploy-prototype.sh [--api-only | --dashboard-only | --aws-only]
#
# Deploys:
#   1. AWS: S3 bucket + CloudFront distribution (media CDN)
#   2. Vercel: API (Hono/Node.js) at /api/*
#   3. Vercel: Dashboard (Next.js 15) at /
#
# Prerequisites:
#   - AWS CLI configured (aws configure)
#   - Vercel CLI installed (npm i -g vercel) and logged in
#   - .env file in repo root with required variables
#   - pnpm installed (npm i -g pnpm)
#
# Environment variables required (set in .env or Vercel dashboard):
#   AWS_ACCESS_KEY_ID        — AWS IAM key with S3+CloudFront permissions
#   AWS_SECRET_ACCESS_KEY    — AWS IAM secret
#   AWS_REGION               — e.g. us-east-1
#   S3_MEDIA_BUCKET          — e.g. cmxs-media-prototype
#   DATABASE_URL             — PostgreSQL connection string
#   REDIS_URL                — Upstash Redis URL
#   SELLER_WALLET_ADDRESS    — 0x address for x402 payments
#   NEXT_PUBLIC_API_URL      — Deployed API URL (set after API deploy)
#   NEXT_PUBLIC_CHAIN_ID     — 84532 (Base Sepolia)
# =============================================================================

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# ── Colors ────────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

print_header() { echo -e "\n${BOLD}${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"; echo -e "${BOLD}${CYAN} $1${NC}"; echo -e "${BOLD}${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"; }
print_ok()   { echo -e "  ${GREEN}✅ $1${NC}"; }
print_warn() { echo -e "  ${YELLOW}⚠️  $1${NC}"; }
print_err()  { echo -e "  ${RED}❌ $1${NC}"; }
print_step() { echo -e "  ${CYAN}→ $1${NC}"; }

# ── Parse flags ───────────────────────────────────────────────────────────────
DEPLOY_AWS=true
DEPLOY_API=true
DEPLOY_DASHBOARD=true

for arg in "$@"; do
  case $arg in
    --api-only)       DEPLOY_AWS=false; DEPLOY_DASHBOARD=false ;;
    --dashboard-only) DEPLOY_AWS=false; DEPLOY_API=false ;;
    --aws-only)       DEPLOY_API=false; DEPLOY_DASHBOARD=false ;;
  esac
done

# ── Load .env ─────────────────────────────────────────────────────────────────
if [[ -f "${REPO_ROOT}/.env" ]]; then
  # shellcheck disable=SC2046
  export $(grep -v '^#' "${REPO_ROOT}/.env" | xargs)
  print_ok "Loaded .env"
else
  print_warn ".env not found — using existing environment variables"
fi

# ── Check required env vars ───────────────────────────────────────────────────
MISSING_VARS=()
for var in DATABASE_URL SELLER_WALLET_ADDRESS; do
  [[ -z "${!var:-}" ]] && MISSING_VARS+=("$var")
done

if [[ ${#MISSING_VARS[@]} -gt 0 ]]; then
  print_err "Missing required environment variables:"
  for v in "${MISSING_VARS[@]}"; do echo "    $v"; done
  echo ""
  echo "Set them in .env or export them before running this script."
  exit 1
fi

print_header "CMXS FAST Platform — Prototype Deployment"
echo "  AWS:       ${DEPLOY_AWS}"
echo "  API:       ${DEPLOY_API}"
echo "  Dashboard: ${DEPLOY_DASHBOARD}"

# ═══════════════════════════════════════════════════════════════════
# STEP 1: AWS Media Infrastructure
# ═══════════════════════════════════════════════════════════════════

if [[ "$DEPLOY_AWS" == "true" ]]; then
  print_header "Step 1: AWS Media CDN (S3 + CloudFront)"

  # Check AWS CLI
  if ! command -v aws &>/dev/null; then
    print_err "AWS CLI not found. Install: https://aws.amazon.com/cli/"
    exit 1
  fi

  AWS_REGION="${AWS_REGION:-us-east-1}"
  S3_BUCKET="${S3_MEDIA_BUCKET:-cmxs-media-prototype-$(date +%s)}"

  # Run the S3 setup script
  print_step "Running S3 + CloudFront setup..."
  if [[ -f "${SCRIPT_DIR}/setup-s3-media.sh" ]]; then
    bash "${SCRIPT_DIR}/setup-s3-media.sh" "${S3_BUCKET}" "${AWS_REGION}"
    print_ok "S3 bucket: s3://${S3_BUCKET}"
  else
    print_warn "setup-s3-media.sh not found — skipping S3 setup"
  fi

  # Generate test HLS content if FFmpeg available
  if command -v ffmpeg &>/dev/null && [[ -f "${SCRIPT_DIR}/generate-test-hls.sh" ]]; then
    print_step "Generating synthetic HLS segments..."
    bash "${SCRIPT_DIR}/generate-test-hls.sh" "${S3_BUCKET}"
    print_ok "HLS segments uploaded to S3"
  else
    print_warn "FFmpeg not found — skipping HLS generation (using synthetic fallback)"
  fi

  # Get CloudFront domain
  CLOUDFRONT_DOMAIN=$(aws cloudfront list-distributions \
    --query "DistributionList.Items[?Comment=='cmxs-media-cdn'].DomainName | [0]" \
    --output text 2>/dev/null || echo "")

  if [[ -n "$CLOUDFRONT_DOMAIN" && "$CLOUDFRONT_DOMAIN" != "None" ]]; then
    print_ok "CloudFront: https://${CLOUDFRONT_DOMAIN}"
    export CLOUDFRONT_DOMAIN
  else
    print_warn "CloudFront distribution not found — will use S3 direct URLs"
  fi
fi

# ═══════════════════════════════════════════════════════════════════
# STEP 2: Build packages
# ═══════════════════════════════════════════════════════════════════

print_header "Step 2: Build Packages"

cd "${REPO_ROOT}"

print_step "Installing dependencies..."
pnpm install --frozen-lockfile 2>/dev/null || pnpm install
print_ok "Dependencies installed"

print_step "Type-checking API..."
cd "${REPO_ROOT}/packages/api"
npm run build
print_ok "API TypeScript: clean"

print_step "Building dashboard..."
cd "${REPO_ROOT}/packages/dashboard"
npm run build
print_ok "Dashboard Next.js: compiled"

# ═══════════════════════════════════════════════════════════════════
# STEP 3: Deploy API to Vercel
# ═══════════════════════════════════════════════════════════════════

if [[ "$DEPLOY_API" == "true" ]]; then
  print_header "Step 3: Deploy API → Vercel"

  if ! command -v vercel &>/dev/null; then
    print_err "Vercel CLI not found. Install: npm i -g vercel"
    exit 1
  fi

  cd "${REPO_ROOT}/packages/api"

  print_step "Deploying API to production..."
  API_URL=$(vercel deploy --prod --yes \
    -e DATABASE_URL="${DATABASE_URL}" \
    -e REDIS_URL="${REDIS_URL:-}" \
    -e SELLER_WALLET_ADDRESS="${SELLER_WALLET_ADDRESS}" \
    -e CLOUDFRONT_DOMAIN="${CLOUDFRONT_DOMAIN:-}" \
    -e S3_MEDIA_BUCKET="${S3_BUCKET:-}" \
    -e AWS_REGION="${AWS_REGION:-us-east-1}" \
    2>&1 | grep "https://" | tail -1)

  if [[ -n "$API_URL" ]]; then
    print_ok "API deployed: ${API_URL}"
    export NEXT_PUBLIC_API_URL="$API_URL"
  else
    print_warn "Could not auto-detect API URL — set NEXT_PUBLIC_API_URL manually"
  fi
fi

# ═══════════════════════════════════════════════════════════════════
# STEP 4: Deploy Dashboard to Vercel
# ═══════════════════════════════════════════════════════════════════

if [[ "$DEPLOY_DASHBOARD" == "true" ]]; then
  print_header "Step 4: Deploy Dashboard → Vercel"

  cd "${REPO_ROOT}/packages/dashboard"

  print_step "Deploying dashboard to production..."
  DASHBOARD_URL=$(vercel deploy --prod --yes \
    -e NEXT_PUBLIC_API_URL="${NEXT_PUBLIC_API_URL:-http://localhost:3001}" \
    -e NEXT_PUBLIC_CHAIN_ID="${NEXT_PUBLIC_CHAIN_ID:-84532}" \
    -e NEXT_PUBLIC_CMXS_CONTRACT_ADDRESS="${NEXT_PUBLIC_CMXS_CONTRACT_ADDRESS:-}" \
    -e NEXT_PUBLIC_ORACLE_CONTRACT_ADDRESS="${NEXT_PUBLIC_ORACLE_CONTRACT_ADDRESS:-}" \
    -e NEXT_PUBLIC_DEFAULT_NODE="${NEXT_PUBLIC_DEFAULT_NODE:-0x0000000000000000000000000000000000000001}" \
    2>&1 | grep "https://" | tail -1)

  if [[ -n "$DASHBOARD_URL" ]]; then
    print_ok "Dashboard deployed: ${DASHBOARD_URL}"
  else
    print_warn "Could not auto-detect dashboard URL"
  fi
fi

# ═══════════════════════════════════════════════════════════════════
# DEPLOYMENT SUMMARY
# ═══════════════════════════════════════════════════════════════════

print_header "🏆 Deployment Complete"

echo -e "  ${BOLD}API Endpoints:${NC}"
echo "    POST ${NEXT_PUBLIC_API_URL:-[API_URL]}/api/ssai/session     → SSAI session"
echo "    POST ${NEXT_PUBLIC_API_URL:-[API_URL]}/api/auction/run      → OpenRTB auction"
echo "    POST ${NEXT_PUBLIC_API_URL:-[API_URL]}/api/demo/start       → 9-scene demo"
echo "    GET  ${NEXT_PUBLIC_API_URL:-[API_URL]}/api/demo/events      → SSE stream"
echo "    POST ${NEXT_PUBLIC_API_URL:-[API_URL]}/api/sim/nodes/start  → Node fleet"
echo ""
echo -e "  ${BOLD}Dashboard:${NC}"
echo "    ${DASHBOARD_URL:-[DASHBOARD_URL]}/               → Overview"
echo "    ${DASHBOARD_URL:-[DASHBOARD_URL]}/player          → Live HLS Player"
echo "    ${DASHBOARD_URL:-[DASHBOARD_URL]}/simulation      → 9-Scene Demo"
echo "    ${DASHBOARD_URL:-[DASHBOARD_URL]}/auction         → OpenRTB History"
echo "    ${DASHBOARD_URL:-[DASHBOARD_URL]}/nodes           → DePIN Fleet"
echo "    ${DASHBOARD_URL:-[DASHBOARD_URL]}/treasury        → CMXS Treasury"
echo "    ${DASHBOARD_URL:-[DASHBOARD_URL]}/chain           → On-Chain Explorer"
echo ""
echo -e "  ${BOLD}Quick Demo:${NC}"
echo "    curl -X POST ${NEXT_PUBLIC_API_URL:-http://localhost:3001}/api/demo/start"
echo "    curl -N ${NEXT_PUBLIC_API_URL:-http://localhost:3001}/api/demo/events"
echo ""
echo -e "  ${GREEN}${BOLD}All 5 phases complete. Flywheel is live! 🚀${NC}"
echo ""
