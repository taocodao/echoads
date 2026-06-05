#!/bin/bash
# ============================================================
# setup-aws-mac.sh — Arenza iOS Prototype Setup on AWS EC2 Mac
# ============================================================
# Run this script ONCE after SSH-ing into a fresh aws mac2.metal instance.
# Usage: bash setup-aws-mac.sh
# Time: ~10–15 minutes (mostly Homebrew + Xcode CLI tools install)
# ============================================================

set -e  # exit on error

echo ""
echo "=================================================="
echo "  Arenza iOS — AWS EC2 Mac Setup Script"
echo "  CMXS Network · Project Clarity"
echo "=================================================="
echo ""

# ── 1. Verify macOS + Xcode ────────────────────────────────────────────────
echo "▶ Checking Xcode..."
if ! xcode-select -p &>/dev/null; then
    echo "  Installing Xcode Command Line Tools..."
    xcode-select --install
    echo "  ⚠️  If a dialog appeared, click Install, then re-run this script."
    exit 1
fi

XCODE_VERSION=$(xcodebuild -version 2>/dev/null | head -1 || echo "Not found")
echo "  ✅ $XCODE_VERSION"

# Accept Xcode license (required for first run)
echo "▶ Accepting Xcode license..."
sudo xcodebuild -license accept 2>/dev/null || true

# ── 2. Install Homebrew ────────────────────────────────────────────────────
echo "▶ Checking Homebrew..."
if ! command -v brew &>/dev/null; then
    echo "  Installing Homebrew..."
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    # Add brew to PATH for Apple Silicon
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi
echo "  ✅ Homebrew $(brew --version | head -1)"

# ── 3. Install XcodeGen ───────────────────────────────────────────────────
echo "▶ Installing XcodeGen..."
if ! command -v xcodegen &>/dev/null; then
    brew install xcodegen
fi
echo "  ✅ XcodeGen $(xcodegen --version)"

# ── 4. Install xcbeautify (pretty build output) ───────────────────────────
echo "▶ Installing xcbeautify..."
brew install xcbeautify 2>/dev/null || true

# ── 5. Clone / update repo ────────────────────────────────────────────────
REPO_DIR="$HOME/echoads"
echo "▶ Setting up repository..."

if [ -d "$REPO_DIR" ]; then
    echo "  Pulling latest changes..."
    git -C "$REPO_DIR" pull --rebase
else
    echo "  ⚠️  Repository not found at $REPO_DIR"
    echo "  Please clone it first:"
    echo "    git clone <YOUR_REPO_URL> ~/echoads"
    echo "  Then re-run this script."
    exit 1
fi

IOS_DIR="$REPO_DIR/packages/arenza-ios"
if [ ! -d "$IOS_DIR" ]; then
    echo "  ❌ iOS package not found at $IOS_DIR"
    exit 1
fi
echo "  ✅ Repository ready at $IOS_DIR"

# ── 6. Generate Xcode Project ─────────────────────────────────────────────
echo "▶ Generating Xcode project with XcodeGen..."
cd "$IOS_DIR"
xcodegen generate --spec project.yml
echo "  ✅ Arenza.xcodeproj generated"

# ── 7. Resolve Swift Package Dependencies ────────────────────────────────
echo "▶ Resolving Swift package dependencies..."
xcodebuild -resolvePackageDependencies \
    -project Arenza.xcodeproj \
    -scheme Arenza \
    2>&1 | grep -E "(Resolved|error:|warning:|Fetch)" || true
echo "  ✅ Dependencies resolved"

# ── 8. Build for iOS Simulator ────────────────────────────────────────────
echo ""
echo "▶ Building Arenza for iPhone 16 Simulator..."
echo "  (This takes 2–5 minutes on first build)"
echo ""

SIMULATOR="platform=iOS Simulator,name=iPhone 16,OS=latest"

set -o pipefail
xcodebuild build-for-testing \
    -project Arenza.xcodeproj \
    -scheme Arenza \
    -destination "$SIMULATOR" \
    -configuration Debug \
    CODE_SIGNING_ALLOWED=NO \
    2>&1 | xcbeautify

echo ""
echo "  ✅ Build succeeded!"

# ── 9. Run Unit Tests ─────────────────────────────────────────────────────
echo ""
echo "▶ Running unit tests on iPhone 16 Simulator..."
echo ""

xcodebuild test-without-building \
    -project Arenza.xcodeproj \
    -scheme Arenza \
    -destination "$SIMULATOR" \
    -configuration Debug \
    CODE_SIGNING_ALLOWED=NO \
    2>&1 | xcbeautify

echo ""
echo "  ✅ Tests passed!"

# ── 10. Boot Simulator + Run App ─────────────────────────────────────────
echo ""
echo "▶ Booting iPhone 16 Simulator..."
DEVICE_UDID=$(xcrun simctl list devices available | grep "iPhone 16" | grep -v "Plus\|Pro\|Max" | head -1 | grep -o '[A-F0-9-]\{36\}')

if [ -z "$DEVICE_UDID" ]; then
    echo "  ⚠️  iPhone 16 simulator not found. Creating one..."
    DEVICE_UDID=$(xcrun simctl create "iPhone 16" "com.apple.CoreSimulator.SimDeviceType.iPhone-16" "com.apple.CoreSimulator.SimRuntime.iOS-18-0")
fi

echo "  Device UDID: $DEVICE_UDID"
xcrun simctl boot "$DEVICE_UDID" 2>/dev/null || true
open -a Simulator

echo "▶ Installing app on simulator..."
APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData -name "Arenza.app" -path "*/Debug-iphonesimulator/*" 2>/dev/null | head -1)

if [ -n "$APP_PATH" ]; then
    xcrun simctl install "$DEVICE_UDID" "$APP_PATH"
    xcrun simctl launch "$DEVICE_UDID" com.cmxs.arenza
    echo "  ✅ Arenza is running on iPhone 16 Simulator!"
    echo "  ℹ️  Note: Secure Enclave uses software fallback on Simulator."
    echo "      For hardware SE testing, install on real iPhone via AltStore."
else
    echo "  ⚠️  App binary not found. Run 'xcodebuild build' first."
fi

echo ""
echo "=================================================="
echo "  ✅ Setup Complete!"
echo "=================================================="
echo ""
echo "  Next steps:"
echo "  1. Open in Xcode (for development):"
echo "     open $IOS_DIR/Arenza.xcodeproj"
echo ""
echo "  2. Start the backend (in another terminal):"
echo "     cd $REPO_DIR && pnpm install && pnpm dev"
echo ""
echo "  3. For real iPhone testing (Secure Enclave):"
echo "     → Export .ipa from Xcode → install via AltStore on Windows PC"
echo ""
echo "  4. View Simulator (via VNC/Screen Sharing):"
echo "     Enable Screen Sharing on this Mac instance in AWS console"
echo ""
