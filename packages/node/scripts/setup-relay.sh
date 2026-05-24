#!/usr/bin/env bash
# =============================================================
# Project Clarity — moq-rs relay setup for WSL2/Ubuntu 24.04
# Run this once to build the relay and generate TLS certs.
# =============================================================

set -euo pipefail

echo "=================================================="
echo "Project Clarity — moq-rs Relay Setup"
echo "=================================================="

# ----- Prerequisites -----
sudo apt-get update -qq
sudo apt-get install -y build-essential pkg-config libssl-dev cmake curl

# Install Rust if not present
if ! command -v cargo &> /dev/null; then
    echo "[1/5] Installing Rust..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source "$HOME/.cargo/env"
else
    echo "[1/5] Rust already installed: $(rustc --version)"
fi

# ----- Clone and build moq-rs -----
REPO_DIR="$HOME/moq-rs"
if [ -d "$REPO_DIR" ]; then
    echo "[2/5] moq-rs already cloned at $REPO_DIR — pulling latest..."
    git -C "$REPO_DIR" pull
else
    echo "[2/5] Cloning kixelated/moq-rs..."
    git clone https://github.com/kixelated/moq-rs.git "$REPO_DIR"
fi

echo "[3/5] Building moq-rs (this takes ~5 minutes on first run)..."
cd "$REPO_DIR"
cargo build --release

echo "[4/5] moq-rs binaries built:"
ls -la target/release/moq-{relay,pub,certgen} 2>/dev/null || ls -la target/release/moq-*

# ----- Generate TLS certificate -----
CERTS_DIR="$(pwd)/certs"
mkdir -p "$CERTS_DIR"

if [ ! -f "$CERTS_DIR/cert.pem" ]; then
    echo "[5/5] Generating self-signed TLS certificate for QUIC..."
    # moq-certgen outputs: cert.pem, key.pem, and the cert fingerprint
    cargo run --bin moq-certgen -- \
        --host localhost \
        --output "$CERTS_DIR/"
    echo "✅ Certs generated at $CERTS_DIR/"
    echo ""
    echo "⚠️  IMPORTANT: Copy the certificate fingerprint above."
    echo "   Add it to your .env as: MOQ_CERT_FINGERPRINT=<fingerprint>"
else
    echo "[5/5] TLS certs already exist at $CERTS_DIR/ — skipping."
fi

echo ""
echo "=================================================="
echo "✅ Setup complete!"
echo ""
echo "To start the relay:"
echo "  cd $REPO_DIR"
echo "  ./target/release/moq-relay \\"
echo "    --listen \"[::]:4443\" \\"
echo "    --tls-cert $CERTS_DIR/cert.pem \\"
echo "    --tls-key  $CERTS_DIR/key.pem"
echo ""
echo "To publish a test video:"
echo "  ffmpeg -re -stream_loop -1 -i /path/to/video.mp4 \\"
echo "    -c:v libx264 -preset ultrafast -tune zerolatency \\"
echo "    -c:a aac -b:a 128k \\"
echo "    -f mp4 -movflags cmaf+dash+delay_moov+skip_sidx \\"
echo "    pipe:1 | \\"
echo "  ./target/release/moq-pub \\"
echo "    --url https://localhost:4443 \\"
echo "    --tls-disable-verify \\"
echo "    --name sling/live/content -"
echo ""
echo "Windows firewall rule (run in PowerShell as admin on Windows host):"
echo "  See: packages/node/scripts/setup-windows-firewall.ps1"
echo "=================================================="
