// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "../src/CMXS.sol";
import "../src/DeliveryOracle.sol";
import "../src/NodeRegistry.sol";
import "../src/AdBurn.sol";
import "../src/CPMAuction.sol";

contract Deploy is Script {
    function run() external {
        uint256 deployerKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        address oracleSigner = vm.envAddress("ORACLE_SIGNER_ADDRESS");
        address treasury = vm.envAddress("TREASURY_ADDRESS");
        address usdcAddress = vm.envAddress("USDC_ADDRESS");
        uint256 platformFeeBps = vm.envOr("PLATFORM_FEE_BPS", uint256(1500));

        vm.startBroadcast(deployerKey);

        // 1. Deploy CMXS
        CMXS cmxs = new CMXS(treasury);

        // 2. Deploy DeliveryOracle
        DeliveryOracle oracle = new DeliveryOracle(oracleSigner, address(cmxs));

        // 3. Grant MINTER_ROLE to DeliveryOracle
        cmxs.grantRole(cmxs.MINTER_ROLE(), address(oracle));

        // 4. Deploy AdBurn
        AdBurn adBurn = new AdBurn(usdcAddress, address(cmxs), treasury, platformFeeBps);

        // 5. Grant BURNER_ROLE to AdBurn
        cmxs.grantRole(cmxs.BURNER_ROLE(), address(adBurn));

        // 6. Deploy CPMAuction
        CPMAuction auction = new CPMAuction();

        // 7. Deploy NodeRegistry
        NodeRegistry registry = new NodeRegistry();

        vm.stopBroadcast();

        console.log("======================================");
        console.log("Deployed Contracts");
        console.log("======================================");
        console.log("CMXS Token:      ", address(cmxs));
        console.log("DeliveryOracle:  ", address(oracle));
        console.log("AdBurn:          ", address(adBurn));
        console.log("CPMAuction:      ", address(auction));
        console.log("NodeRegistry:    ", address(registry));
        console.log("Oracle Signer:   ", oracleSigner);
        console.log("Treasury:        ", treasury);
    }
}
