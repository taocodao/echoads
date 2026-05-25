// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "../src/CMXS.sol";
import "../src/DeliveryOracle.sol";
import "../src/NodeRegistry.sol";

/**
 * @title Deploy — Project Clarity Phase 0 deployment script
 * @notice Deploys CMXS, DeliveryOracle, and NodeRegistry to Base Sepolia.
 *
 * Usage:
 *   forge script script/Deploy.s.sol:Deploy \
 *     --rpc-url base_sepolia \
 *     --broadcast \
 *     --private-key $DEPLOYER_PRIVATE_KEY \
 *     --verify \
 *     --etherscan-api-key $BASESCAN_API_KEY \
 *     -vvvv
 *
 * Required env vars:
 *   DEPLOYER_PRIVATE_KEY   — deployer wallet (fund from faucet, dev only)
 *   ORACLE_SIGNER_ADDRESS  — backend signing key address (cast wallet new)
 *   BASESCAN_API_KEY       — from basescan.org/register
 *   BASE_SEPOLIA_RPC_URL   — https://sepolia.base.org or Alchemy
 */
contract Deploy is Script {
    function run() external {
        // Load config from env
        uint256 deployerKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        address oracleSigner = vm.envAddress("ORACLE_SIGNER_ADDRESS");

        vm.startBroadcast(deployerKey);

        // 1. Deploy DeliveryOracle with a placeholder CMXS address
        //    We'll update it after deploying CMXS.
        DeliveryOracle oracle = new DeliveryOracle(oracleSigner, address(1));

        // 2. Deploy CMXS — awards oracle contract as the authorized caller
        CMXS cmxs = new CMXS(address(oracle));

        // 3. Update oracle's CMXS reference to the real contract
        oracle.setCmxsToken(address(cmxs));

        // 4. Deploy NodeRegistry
        NodeRegistry registry = new NodeRegistry();

        vm.stopBroadcast();

        // Output deployed addresses
        console.log("======================================");
        console.log("Project Clarity - Deployed Contracts");
        console.log("======================================");
        console.log("DeliveryOracle:  ", address(oracle));
        console.log("CMXS Token:      ", address(cmxs));
        console.log("NodeRegistry:    ", address(registry));
        console.log("Oracle Signer:   ", oracleSigner);
        console.log("Chain ID:        ", block.chainid);
        console.log("======================================");
        console.log("Add these to your .env:");
        console.log("ORACLE_CONTRACT_ADDRESS=", address(oracle));
        console.log("CMXS_CONTRACT_ADDRESS=", address(cmxs));
        console.log("NODE_REGISTRY_ADDRESS=", address(registry));
    }
}
