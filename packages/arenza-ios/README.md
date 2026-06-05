# Arenza iOS App — Setup Guide

## What's been built for you

All Swift source files are in `packages/arenza-ios/`. They are ready to drop into Xcode.

| File | Purpose |
|---|---|
| `ArenzaApp.swift` | `@main` entry point, bootstraps Secure Enclave + background task |
| `AppEnvironment.swift` | Dependency injection container, deep-link router |
| `ContentView.swift` | Root `NavigationStack` shell |
| `HomeView.swift` | Channel grid + live spotlight |
| `HomeViewModel.swift` | Demo channel data + `Constants` (MoQ URL, contract addresses) |
| `PlayerView.swift` | Full-screen player with SGAI overlay + PoD toast |
| `PlayerViewModel.swift` | MoQ resolution, SCTE-35 orchestration, PoD signing |
| `SCTE35Detector.swift` | `AVPlayerItemMetadataOutputPushDelegate` |
| `SecureEnclaveManager.swift` | Hardware ECDSA key (software fallback for Simulator) |
| `OracleSubmitter.swift` | Builds + signs PoD receipt; submits to oracle |
| `CMXSAPIClient.swift` | URLSession REST client |
| `WalletView.swift` | CMXS balance, earnings stats, PoD history |
| `NodeService.swift` | `BGProcessingTask` heartbeat |
| `Models.swift` | All shared data models |

---

## Part A — Things you must do manually (one-time setup)

### A1. Create the Xcode Project
You must do this on a Mac with Xcode 15+.

1. Open **Xcode → File → New → Project**
2. Choose **iOS → App**
3. Settings:
   - Product Name: `Arenza`
   - Bundle Identifier: `com.cmxs.arenza`
   - Interface: **SwiftUI**
   - Language: **Swift**
   - Minimum Deployments: **iOS 17.0**
4. Click **Create** — save it somewhere, then **delete** the auto-generated `ContentView.swift`.
5. Drag all `.swift` files from `packages/arenza-ios/` into the Xcode project navigator.

### A2. Add Swift Package Dependencies
In Xcode → Project Navigator → Package Dependencies → `+`:

| Package | URL | Version |
|---|---|---|
| Caton C3CVP MoQ SDK | `https://github.com/caton-network/c3cvp-ios-sdk` | from `3.0.0` |
| web3swift | `https://github.com/web3swift-team/web3swift` | from `3.1.0` |

> **Note:** The Caton SDK requires a Caton API key (`C3_API_KEY`) for production use. For the initial demo, the player automatically falls back to a reliable Apple HLS stream. You can test the MoQ stream live in a browser at: `https://moq-demo.caton.cloud/moq-demo/?server=https://us-west.moq-demo.liveviewing.com:4444/anon`

### A3. Add Capabilities in Xcode
Go to **Target → Signing & Capabilities → + Capability**:
- ✅ Push Notifications
- ✅ Background Modes → check: **Audio**, **Background fetch**, **Background processing**, **Remote notifications**
- ✅ Associated Domains (add: `applinks:arenza.cmxs.io`)

### A4. Info.plist additions
Add these keys in **Target → Info**:

| Key | Value |
|---|---|
| `NSFaceIDUsageDescription` | Arenza uses Face ID to protect your Proof-of-Delivery signing key. |
| `BGTaskSchedulerPermittedIdentifiers` | Array → `com.cmxs.arenza.node-contribution` |
| `CFBundleURLTypes` → `CFBundleURLSchemes` | `arenza` |

---

## Part B — Contract Deployment (I will finish this once ethers is available)

### B1. Build the Solidity contracts first (requires Foundry)

```powershell
# Install Foundry on Windows (WSL recommended)
curl -L https://foundry.paradigm.xyz | bash
foundryup

# Build contracts
cd packages/contracts
forge build
```

### B2. Fund a deployer wallet
Get free testnet ETH from: https://faucet.quicknode.com/base/sepolia

### B3. Fill in `.env` at the repo root
```
DEPLOYER_PRIVATE_KEY=0x<your-dev-key>
TREASURY_ADDRESS=0x<your-wallet>
BASE_SEPOLIA_RPC_URL=https://sepolia.base.org
USDC_BASE_SEPOLIA=0x036CbD53842c5426634e7929541eC2318f3dCF7e
```

### B4. Run the deploy script
```powershell
cd d:\Projects\echoads
npm install ethers
node scripts/deploy-contracts.mjs
```

The script will print the deployed addresses and tell you exactly what to paste into `HomeViewModel.swift`.

---

## Part C — Run on Simulator

1. In Xcode, select **iPhone 15 Pro** simulator
2. `Cmd+R` to build and run
3. The app will:
   - Show the channel grid
   - On tapping a channel → full-screen player with Apple sample HLS stream
   - After **10 seconds** → first simulated ad break fires
   - At **T+20s** of ad break → SGAI overlay appears (golf driver card)
   - At **T+30s** → Secure Enclave (software fallback on Sim) signs PoD receipt
   - Green **"On-Chain PoD Minted"** toast appears top-right with mock txHash

## Part D — Run on Real iPhone (recommended)

Real iPhone adds:
- True Secure Enclave signing (Face ID)
- Real BGProcessingTask node heartbeats

Connect iPhone → select it in Xcode device selector → `Cmd+R`.

---

## MoQ Stream Status
The live Caton MoQ demo stream is publicly available at:
```
https://us-west.moq-demo.liveviewing.com:4444/anon
```
Test it in browser first: https://moq-demo.caton.cloud/moq-demo/?server=https://us-west.moq-demo.liveviewing.com:4444/anon

To enable it in the app, uncomment the C3CVP SDK lines in `PlayerViewModel.swift` after adding your Caton API key.
