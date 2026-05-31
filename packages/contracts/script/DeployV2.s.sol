// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "../src/CMXSToken.sol";
import "../src/NodeStaking.sol";
import "../src/AdBurnV2.sol";
import "../src/DeliveryOracleV2.sol";
import "../src/Treasury.sol";
import "../src/veToken.sol";
import "../src/VestingWallet.sol";

/**
 * @title DeployV2
 * @notice Deploys the full CMXS Token System in the exact dependency order.
 *
 * Required env vars:
 *   DEPLOYER_PRIVATE_KEY      — deployer wallet (funds gas)
 *   ADMIN_MULTISIG            — Gnosis Safe 3/5 address (receives admin roles)
 *   ORACLE_SIGNER_ADDRESS     — off-chain PoD relay signing key address
 *   USDC_ADDRESS              — USDC on Base (0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913 mainnet)
 *   TGE_TIMESTAMP             — Unix timestamp of TGE (for VestingFactory)
 *
 * Optional (Phase 2 — set after TGE):
 *   UNISWAP_V3_POOL           — CMXS/USDC 1% pool address
 *   UNISWAP_POSITION_MANAGER  — NonfungiblePositionManager on Base
 *
 * Deployment order (CRITICAL — role dependency chain):
 *   1. Treasury
 *   2. CMXSToken   (needs Treasury as initial mint recipient)
 *   3. NodeStaking (needs CMXSToken)
 *   4. AdBurnV2    (needs CMXSToken, Treasury)
 *   5. DeliveryOracleV2 (needs CMXSToken, NodeStaking, AdBurnV2)
 *   6. veToken     (needs CMXSToken, Treasury)
 *   7. VestingFactory (needs CMXSToken)
 *   --- then run Configure.s.sol via Gnosis Safe ---
 */
contract DeployV2 is Script {
    function run() external {
        uint256 deployerKey   = vm.envUint("DEPLOYER_PRIVATE_KEY");
        address adminMultisig = vm.envAddress("ADMIN_MULTISIG");
        address oracleSigner  = vm.envAddress("ORACLE_SIGNER_ADDRESS");
        address usdcAddress   = vm.envAddress("USDC_ADDRESS");
        uint256 tgeTimestamp  = vm.envOr("TGE_TIMESTAMP", block.timestamp);

        require(adminMultisig != address(0), "ADMIN_MULTISIG not set");
        require(usdcAddress   != address(0), "USDC_ADDRESS not set");

        vm.startBroadcast(deployerKey);

        // ── 1. Treasury ───────────────────────────────────────────────────────
        Treasury treasury = new Treasury(usdcAddress, adminMultisig);
        console.log("Treasury:          ", address(treasury));

        // ── 2. CMXSToken ──────────────────────────────────────────────────────
        // adminMultisig receives DEFAULT_ADMIN_ROLE, PAUSER_ROLE,
        // and the 200M initial mint.
        CMXSToken cmxsToken = new CMXSToken(adminMultisig);
        console.log("CMXSToken:         ", address(cmxsToken));

        // ── 3. NodeStaking ────────────────────────────────────────────────────
        NodeStaking nodeStaking = new NodeStaking(
            address(cmxsToken),
            address(treasury),
            adminMultisig
        );
        console.log("NodeStaking:       ", address(nodeStaking));

        // ── 4. AdBurnV2 ───────────────────────────────────────────────────────
        AdBurnV2 adBurn = new AdBurnV2(
            usdcAddress,
            address(cmxsToken),
            address(treasury),
            adminMultisig
        );
        console.log("AdBurnV2:          ", address(adBurn));

        // ── 5. DeliveryOracleV2 ───────────────────────────────────────────────
        // adBurn and nodeRewardPool can be set later; pass now for immediate use.
        DeliveryOracleV2 oracle = new DeliveryOracleV2(
            address(cmxsToken),
            address(nodeStaking),
            address(adBurn),
            adminMultisig, // nodeRewardPool — update to dedicated pool later
            adminMultisig
        );
        console.log("DeliveryOracleV2:  ", address(oracle));

        // ── 6. veToken ────────────────────────────────────────────────────────
        veToken veTokenContract = new veToken(
            address(cmxsToken),
            address(treasury),
            adminMultisig
        );
        console.log("veToken:           ", address(veTokenContract));

        // ── 7. VestingFactory ─────────────────────────────────────────────────
        VestingFactory vestingFactory = new VestingFactory(
            address(cmxsToken),
            tgeTimestamp,
            adminMultisig
        );
        console.log("VestingFactory:    ", address(vestingFactory));

        vm.stopBroadcast();

        // ── Post-Deploy Instructions ──────────────────────────────────────────
        console.log("\n======================================================");
        console.log("NEXT STEPS - Execute via Gnosis Safe (Configure.s.sol)");
        console.log("======================================================");
        console.log("CMXSToken.grantRole(MINTER_ROLE,  DeliveryOracleV2)");
        console.log("CMXSToken.grantRole(BURNER_ROLE,  AdBurnV2)");
        console.log("NodeStaking.grantRole(SLASHER_ROLE, DeliveryOracleV2)");
        console.log("AdBurnV2.grantRole(ORACLE_CALLER_ROLE, DeliveryOracleV2)");
        console.log("Treasury.grantRole(INTAKE_ROLE, AdBurnV2)");
        console.log("Treasury.grantRole(TREASURER_ROLE, veToken)");
        console.log("DeliveryOracleV2.addAuthorizedSigner(", oracleSigner, ")");
        console.log("======================================================");
        console.log("Oracle Signer:     ", oracleSigner);
        console.log("Admin Multisig:    ", adminMultisig);
        console.log("USDC:              ", usdcAddress);
    }
}
