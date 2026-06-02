#!/usr/bin/env bash
# =============================================================================
# start-local.sh — Local development quick-start
# =============================================================================
# Starts API (port 3001) + Dashboard (port 3000) in parallel.
# Automatically opens the simulation page in your browser.
#
# Usage: ./scripts/start-local.sh
# =============================================================================

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Load .env if present
[[ -f "${REPO_ROOT}/.env" ]] && export $(grep -v '^#' "${REPO_ROOT}/.env" | xargs)

echo ""
echo "  🚀 CMXS FAST Platform — Local Dev"
echo "  ─────────────────────────────────────"
echo "  API:        http://localhost:3001"
echo "  Dashboard:  http://localhost:3000"
echo "  Demo:       http://localhost:3000/simulation"
echo ""

# Start API
echo "  → Starting API (port 3001)..."
cd "${REPO_ROOT}/packages/api"
npm run dev &
API_PID=$!

# Start Dashboard
echo "  → Starting Dashboard (port 3000)..."
cd "${REPO_ROOT}/packages/dashboard"
npm run dev &
DASH_PID=$!

# Wait for both to be ready
sleep 4

# Open browser on simulation page
if command -v open &>/dev/null; then
  open "http://localhost:3000/simulation"
elif command -v xdg-open &>/dev/null; then
  xdg-open "http://localhost:3000/simulation"
elif command -v start &>/dev/null; then
  start "http://localhost:3000/simulation"
fi

echo ""
echo "  ✅ Running! Press Ctrl+C to stop all processes."
echo ""

# Wait for Ctrl+C and kill both
trap "echo ''; echo '  Stopping...'; kill $API_PID $DASH_PID 2>/dev/null; exit 0" SIGINT SIGTERM
wait $API_PID $DASH_PID
