// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/AdBurn.sol";
import "../src/CMXS.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockUSDC is ERC20 {
    constructor() ERC20("USDC", "USDC") {}
    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

contract AdBurnTest is Test {
    AdBurn public adBurn;
    CMXS public cmxs;
    MockUSDC public usdc;

    address public admin = makeAddr("admin");
    address public treasury = makeAddr("treasury");
    address public platform = makeAddr("platform");
    address public advertiser = makeAddr("advertiser");
    address public publisher = makeAddr("publisher");

    function setUp() public {
        vm.startPrank(admin);
        usdc = new MockUSDC();
        cmxs = new CMXS(treasury);
        adBurn = new AdBurn(address(usdc), address(cmxs), platform, 1500);
        cmxs.grantRole(cmxs.BURNER_ROLE(), address(adBurn));
        vm.stopPrank();

        usdc.mint(advertiser, 1000 * 1e6); // 1000 USDC
        
        vm.prank(treasury);
        cmxs.transfer(advertiser, 100 * 1e18); // Give adv some CMXS
    }

    function test_SettleAdPayment_Success() public {
        vm.prank(advertiser);
        usdc.approve(address(adBurn), type(uint256).max);

        uint256 usdcAmount = 10 * 1e6; // $10
        bytes32 impId = keccak256("imp-1");

        adBurn.settleAdPayment(impId, advertiser, publisher, usdcAmount);

        // platform 15% = $1.50
        assertEq(usdc.balanceOf(platform), 1.5 * 1e6);
        // publisher 85% = $8.50
        assertEq(usdc.balanceOf(publisher), 8.5 * 1e6);
        
        // burned cmxs = 10 * 10 * 1e18 = 100 CMXS
        assertEq(cmxs.balanceOf(advertiser), 0);
    }
}
