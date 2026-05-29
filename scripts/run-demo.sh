#!/bin/bash
set -e
echo "=== AntiGravity CMXS Demo ==="

# 1. Start docker stack
docker compose -f infra/docker-compose.yml up -d

# 2. Wait for services
echo "Waiting for services..."
sleep 10

# Initialize schema
echo "Initializing DB schema..."
docker compose -f infra/docker-compose.yml exec -T postgres psql -U clarity -d echoads < packages/api/src/database/schema.sql

echo "Seed wallets and nodes via JS scripts..."
node scripts/seed-wallets.js || true
node scripts/register-nodes.js || true

# 6. Trigger ad auction
SLOT_ID=$(node -e "console.log(crypto.randomUUID())")
echo "Triggering Auction for $SLOT_ID..."
curl -s -X GET "http://localhost:3001/api/auction/$SLOT_ID?channel=sling/live"

# 7. Simulate viewer PoD
echo "Simulating PoD..."
node scripts/simulate-viewer-pod.js --slotId $SLOT_ID || true

echo "Demo Ready."
echo "Dashboard: http://localhost:3000"
