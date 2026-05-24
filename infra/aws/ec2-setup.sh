#!/usr/bin/env bash
# =============================================================
# Project Clarity — EC2 Initial Setup Script
# Run once on a fresh Ubuntu 24.04 EC2 instance.
# Usage: curl -sSL https://raw.githubusercontent.com/your-org/project-clarity/main/infra/aws/ec2-setup.sh | bash
# =============================================================

set -euo pipefail

echo "=================================================="
echo "Project Clarity — EC2 Node Setup"
echo "Ubuntu $(lsb_release -rs) | $(uname -m)"
echo "=================================================="

# ----- System updates -----
echo "[1/7] Updating system packages..."
sudo apt-get update -qq
sudo apt-get upgrade -y -qq
sudo apt-get install -y curl git openssl unzip build-essential pkg-config libssl-dev

# ----- Docker -----
echo "[2/7] Installing Docker..."
if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com | sh
    sudo usermod -aG docker ubuntu
    sudo systemctl enable docker
    sudo systemctl start docker
    echo "✅ Docker installed: $(docker --version)"
else
    echo "✅ Docker already installed: $(docker --version)"
fi

# Docker Compose plugin
if ! docker compose version &> /dev/null; then
    sudo apt-get install -y docker-compose-plugin
fi
echo "✅ Docker Compose: $(docker compose version)"

# ----- Rust (for moq-rs) -----
echo "[3/7] Installing Rust..."
if ! command -v cargo &> /dev/null; then
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source "$HOME/.cargo/env"
else
    echo "✅ Rust already installed: $(rustc --version)"
fi

# ----- Build moq-rs -----
echo "[4/7] Building moq-relay from kixelated/moq-rs..."
MOQ_DIR="$HOME/moq-rs"
if [ ! -d "$MOQ_DIR" ]; then
    git clone https://github.com/kixelated/moq-rs.git "$MOQ_DIR"
fi
cd "$MOQ_DIR"
git pull
cargo build --release

# ----- Generate TLS certificate -----
echo "[5/7] Generating TLS certificate for QUIC..."
CERTS_DIR="/home/ubuntu/project-clarity/certs"
mkdir -p "$CERTS_DIR"

if [ ! -f "$CERTS_DIR/cert.pem" ]; then
    # Get public IP for the cert
    PUBLIC_IP=$(curl -s http://checkip.amazonaws.com)
    
    "$MOQ_DIR/target/release/moq-certgen" \
        --host "$PUBLIC_IP" \
        --host "localhost" \
        --output "$CERTS_DIR/"
    
    echo "✅ Certs generated for IP: $PUBLIC_IP"
    echo ""
    echo "⚠️  IMPORTANT: Note the certificate fingerprint above."
    echo "   Set NEXT_PUBLIC_MOQ_CERT_FINGERPRINT=<fingerprint> in Vercel dashboard."
else
    echo "✅ Certs already exist — skipping."
fi

# ----- Set up project directory -----
echo "[6/7] Setting up project directory..."
mkdir -p /home/ubuntu/project-clarity/{packages/node,certs,logs}

# Create symlink for moq-relay binary
sudo ln -sf "$MOQ_DIR/target/release/moq-relay" /usr/local/bin/moq-relay
sudo ln -sf "$MOQ_DIR/target/release/moq-pub" /usr/local/bin/moq-pub

# ----- UFW firewall -----
echo "[7/7] Configuring UFW firewall..."
sudo ufw allow 22/tcp    comment "SSH"
sudo ufw allow 4443/udp  comment "MOQ QUIC"
sudo ufw allow 4443/tcp  comment "MOQ TLS"
sudo ufw allow 80/tcp    comment "HTTP"
sudo ufw allow 443/tcp   comment "HTTPS"
sudo ufw --force enable

PUBLIC_IP=$(curl -s http://checkip.amazonaws.com)

echo ""
echo "=================================================="
echo "✅ EC2 Setup Complete!"
echo ""
echo "Public IP: $PUBLIC_IP"
echo "MOQ Relay URL: moqs://$PUBLIC_IP:4443"
echo ""
echo "Next steps:"
echo "  1. GitHub will auto-deploy the Docker services on next push"
echo "  2. Set in Vercel dashboard:"
echo "     NEXT_PUBLIC_MOQ_RELAY_URL=https://$PUBLIC_IP:4443"
echo "  3. Register node on-chain:"
echo "     cast send \$NODE_REGISTRY_ADDRESS \"registerNode(string)\" \"moqs://$PUBLIC_IP:4443\" --value 0.01ether ..."
echo "=================================================="
