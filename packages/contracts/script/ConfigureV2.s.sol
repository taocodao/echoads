// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "../src/CMXSToken.sol";
import "../src/NodeStaking.sol";
import "../src/AdBurnV2.sol";
import "../src/DeliveryOracleV2.sol";
import "../src/Treasury.sol";
import "../src/veToken.sol";

/**
 * @title ConfigureV2
 * @notice Post-deploy role grant script. Run via Gnosis Safe transaction builder
 *         AFTER DeployV2.s.sol has completed and all contract addresses are known.
 *
 * Usage (single deployer for testnet):
 *   forge script script/ConfigureV2.s.sol \
 *     --rpc-url $BASE_SEPOLIA_RPC_URL \
 *     --broadcast \
 *     --private-key $DEPLOYER_PRIVATE_KEY
 *
 * Usage (Gnosis Safe — mainnet):
 *   1. Run with --simulate to generate calldata for each grantRole call
 *   2. Paste calldata into Gnosis Safe Transaction Builder
 *   3. Collect 3/5 signatures and execute
 *
 * Required env vars (all set from DeployV2 output):
 *   ADMIN_MULTISIG
 *   CMXS_TOKEN_ADDRESS
 *   NODE_STAKING_ADDRESS
 *   AD_BURN_V2_ADDRESS
 *   DELIVERY_ORACLE_V2_ADDRESS_SEPOLIA (or _MAINNET)
 *   TREASURY_ADDRESS
 *   VE_TOKEN_ADDRESS
 *   ORACLE_SIGNER_ADDRESS
 */
contract ConfigureV2 is Script {
    function run() external {
        uint256 deployerKey   = vm.envUint("DEPLOYER_PRIVATE_KEY");
        address adminMultisig = vm.envAddress("ADMIN_MULTISIG");
        address oracleSigner  = vm.envAddress("ORACLE_SIGNER_ADDRESS");

        bool isMainnet = keccak256(bytes(vm.envOr("CHAIN", string("base-sepolia"))))
            == keccak256(bytes("base-mainnet"));

        address cmxsAddress    = vm.envAddress("CMXS_TOKEN_ADDRESS");
        address stakingAddress = vm.envAddress("NODE_STAKING_ADDRESS");
        address adBurnAddress  = vm.envAddress("AD_BURN_V2_ADDRESS");
        address oracleAddress  = isMainnet
            ? vm.envAddress("DELIVERY_ORACLE_V2_ADDRESS_MAINNET")
            : vm.envAddress("DELIVERY_ORACLE_V2_ADDRESS_SEPOLIA");
        address treasuryAddress = vm.envAddress("TREASURY_ADDRESS");
        address veTokenAddress  = vm.envAddress("VE_TOKEN_ADDRESS");

        CMXSToken        cmxs     = CMXSToken(cmxsAddress);
        NodeStaking      staking  = NodeStaking(stakingAddress);
        AdBurnV2         adBurn   = AdBurnV2(adBurnAddress);
        DeliveryOracleV2 oracle   = DeliveryOracleV2(oracleAddress);
        Treasury         treasury = Treasury(treasuryAddress);

        vm.startBroadcast(deployerKey);

        // ── CMXSToken Role Grants ─────────────────────────────────────────────
        // MINTER_ROLE: DeliveryOracleV2 — mints rewards per verified PoD
        cmxs.grantRole(cmxs.MINTER_ROLE(), oracleAddress);
        console.log("[configure] MINTER_ROLE granted to DeliveryOracleV2:", oracleAddress);

        // BURNER_ROLE: AdBurnV2 — burns CMXS on ad spend
        cmxs.grantRole(cmxs.BURNER_ROLE(), adBurnAddress);
        console.log("[configure] BURNER_ROLE granted to AdBurnV2:", adBurnAddress);

        // ── NodeStaking Role Grants ───────────────────────────────────────────
        // SLASHER_ROLE: DeliveryOracleV2 — can slash nodes + record impressions
        staking.grantRole(staking.SLASHER_ROLE(), oracleAddress);
        console.log("[configure] SLASHER_ROLE granted to DeliveryOracleV2:", oracleAddress);

        // ── AdBurnV2 Role Grants ──────────────────────────────────────────────
        // ORACLE_CALLER_ROLE: DeliveryOracleV2 — calls recordDelivery() on campaigns
        adBurn.grantRole(adBurn.ORACLE_CALLER_ROLE(), oracleAddress);
        console.log("[configure] ORACLE_CALLER_ROLE granted to DeliveryOracleV2:", oracleAddress);

        // ── Treasury Role Grants ──────────────────────────────────────────────
        // INTAKE_ROLE: AdBurnV2 — calls recordPlatformFeeIncome()
        treasury.grantRole(treasury.INTAKE_ROLE(), adBurnAddress);
        console.log("[configure] INTAKE_ROLE granted to AdBurnV2:", adBurnAddress);

        // TREASURER_ROLE: veToken — calls disburseFees() and distributeEpochFees()
        treasury.grantRole(treasury.TREASURER_ROLE(), veTokenAddress);
        console.log("[configure] TREASURER_ROLE granted to veToken:", veTokenAddress);

        // ── DeliveryOracleV2 Signer ───────────────────────────────────────────
        // Authorize the off-chain PoD relay signing key
        oracle.addAuthorizedSigner(oracleSigner);
        console.log("[configure] Oracle signer authorized:", oracleSigner);

        vm.stopBroadcast();

        // ── Verification Summary ──────────────────────────────────────────────
        console.log("\n======================================================");
        console.log("CONFIGURATION COMPLETE");
        console.log("======================================================");
        console.log("Verify on Basescan:");
        console.log("  CMXSToken MINTER_ROLE  =>", oracleAddress);
        console.log("  CMXSToken BURNER_ROLE  =>", adBurnAddress);
        console.log("  NodeStaking SLASHER    =>", oracleAddress);
        console.log("  AdBurnV2 ORACLE_CALLER =>", oracleAddress);
        console.log("  Treasury INTAKE        =>", adBurnAddress);
        console.log("  Treasury TREASURER     =>", veTokenAddress);
        console.log("  Oracle Signer          =>", oracleSigner);
        console.log("======================================================");
        console.log("REMAINING MANUAL STEPS (Gnosis Safe):");
        console.log("  1. CMXSToken.renounceRole(DEFAULT_ADMIN_ROLE, deployer)");
        console.log("     -- Only after confirming adminMultisig has DEFAULT_ADMIN_ROLE");
        console.log("  2. Create Uniswap v3 CMXS/USDC pool (1% fee)");
        console.log("  3. Deploy LiquidityManager with pool address");
        console.log("  4. Configure Gelato Automate tasks (see gelato-setup.md)");
        console.log("  5. Register initial nodes via NodeStaking.registerNode()");
        console.log("======================================================");
        console.log("Admin Multisig:", adminMultisig);
        console.log("Chain:", isMainnet ? "Base Mainnet" : "Base Sepolia");
    }
}
