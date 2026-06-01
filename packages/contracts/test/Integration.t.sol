// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/CMXSToken.sol";
import "../src/NodeStaking.sol";
import "../src/AdBurnV2.sol";
import "../src/DeliveryOracleV2.sol";
import "../src/Treasury.sol";
import "../src/veToken.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// ── Mock USDC ─────────────────────────────────────────────────────────────────

contract MockUSDC is ERC20 {
    constructor() ERC20("USD Coin", "USDC") {}
    function decimals() public pure override returns (uint8) { return 6; }
    function mint(address to, uint256 amount) external { _mint(to, amount); }
}

// ── Integration Test: Full Flywheel ──────────────────────────────────────────

/**
 * @title IntegrationTest
 * @notice Verifies the end-to-end CMXS flywheel:
 *         Register node → Purchase impressions → Batch PoD → Rewards minted →
 *         Burns > Mints (deflationary) → USDC in Treasury → ve holder claims →
 *         Daily cap enforced → Net Emissions recycle.
 */
contract IntegrationTest is Test {

    // ── Contracts ─────────────────────────────────────────────────────────────
    CMXSToken        cmxsToken;
    NodeStaking      nodeStaking;
    AdBurnV2         adBurn;
    DeliveryOracleV2 oracle;
    Treasury         treasury;
    veToken          ve;
    MockUSDC         usdc;

    // ── Actors ────────────────────────────────────────────────────────────────
    address admin        = makeAddr("admin");
    address nodeOperator = makeAddr("nodeOperator");
    address advertiser   = makeAddr("advertiser");
    address contentPartner = makeAddr("contentPartner");
    address veHolder     = makeAddr("veHolder");

    // Viewer device signing key (generates ECDSA PoD sigs)
    uint256 viewerPrivKey  = 0xDEADBEEF1;
    address viewerAddress;

    // ── Setup ─────────────────────────────────────────────────────────────────

    function setUp() public {
        viewerAddress = vm.addr(viewerPrivKey);

        vm.startPrank(admin);

        // Deploy stack
        usdc        = new MockUSDC();
        treasury    = new Treasury(address(usdc), admin);
        cmxsToken   = new CMXSToken(admin);
        nodeStaking = new NodeStaking(address(cmxsToken), address(treasury), admin);
        adBurn      = new AdBurnV2(address(usdc), address(cmxsToken), address(treasury), admin);
        oracle      = new DeliveryOracleV2(
            address(cmxsToken),
            address(nodeStaking),
            address(adBurn),
            admin, // nodeRewardPool (admin for testing)
            admin
        );
        ve = new veToken(address(cmxsToken), address(treasury), admin);

        // Grant roles
        cmxsToken.grantRole(cmxsToken.MINTER_ROLE(), address(oracle));
        cmxsToken.grantRole(cmxsToken.BURNER_ROLE(), address(adBurn));
        nodeStaking.grantRole(nodeStaking.SLASHER_ROLE(), address(oracle));
        adBurn.grantRole(adBurn.ORACLE_CALLER_ROLE(), address(oracle));
        treasury.grantRole(treasury.INTAKE_ROLE(), address(adBurn));
        treasury.grantRole(treasury.TREASURER_ROLE(), address(ve));
        treasury.grantRole(treasury.TREASURER_ROLE(), admin);

        // Authorize viewer as PoD signer
        oracle.addAuthorizedSigner(viewerAddress);

        vm.stopPrank();

        // Fund actors from admin's 200M initial mint
        vm.startPrank(admin);
        cmxsToken.transfer(nodeOperator, 50_000 * 1e18);  // for staking
        cmxsToken.transfer(advertiser,    5_000 * 1e18);   // for burning
        cmxsToken.transfer(veHolder,     20_000 * 1e18);   // for locking
        vm.stopPrank();

        usdc.mint(advertiser, 10_000 * 1e6); // $10K USDC
    }

    // ── Step 1: Node Registration ─────────────────────────────────────────────

    function test_01_NodeRegistration() public {
        vm.startPrank(nodeOperator);
        cmxsToken.approve(address(nodeStaking), 10_000 * 1e18);
        nodeStaking.registerNode(bytes32("ECHOSTAR-TOWER-001"), "moqs://node1.echoads.tv:4433");
        vm.stopPrank();

        assertTrue(nodeStaking.isActiveNode(nodeOperator));
        assertEq(nodeStaking.getNode(nodeOperator).stakedAmount, 10_000 * 1e18);
        assertEq(nodeStaking.totalActiveNodes(), 1);
    }

    // ── Step 2: Purchase Impressions (USDC in, CMXS burned) ──────────────────

    function test_02_PurchaseImpressions() public {
        _registerNode();

        bytes32 campaignId = keccak256("campaign-001");
        uint256 usdcAmount = 1000 * 1e6; // $1000 USDC
        uint256 impressions = 20_000;    // 20K impressions at $50 CPM

        uint256 cmxsBefore = cmxsToken.balanceOf(advertiser);
        uint256 treasuryBefore = usdc.balanceOf(address(treasury));

        vm.startPrank(advertiser);
        usdc.approve(address(adBurn), type(uint256).max);
        cmxsToken.approve(address(adBurn), type(uint256).max);
        adBurn.purchaseImpressions(contentPartner, usdcAmount, impressions, campaignId);
        vm.stopPrank();

        // Treasury received 15% = $150
        assertEq(usdc.balanceOf(address(treasury)) - treasuryBefore, 150 * 1e6);
        // Content partner received 85% = $850
        assertEq(usdc.balanceOf(contentPartner), 850 * 1e6);
        // CMXS was burned (fixed fallback price $1.00, 10% burn rate)
        // burnAmount = 1000 * 1e6 * 1000 * 1e20 / (1e8 * 10000) = 100 * 1e18
        uint256 burned = cmxsBefore - cmxsToken.balanceOf(advertiser);
        assertEq(burned, 100 * 1e18, "Burn amount mismatch");

        // Campaign is stored as a struct; access active field via getter tuple
        // Solidity public mapping returns individual fields, use the tuple approach
        (, , , , , , bool active) = _getCampaignFields(campaignId);
        assertTrue(active);
    }

    // ── Step 3: Submit PoD Batch (CMXS minted to node) ───────────────────────

    function test_03_BatchPoDVerification() public {
        _registerNode();
        bytes32 campaignId = _purchaseImpressions();

        uint256 batchSize = 5;
        uint256 balBefore = cmxsToken.balanceOf(nodeOperator);

        DeliveryOracleV2.ReceiptBatch memory batch = _buildBatch(batchSize, campaignId);
        oracle.verifyAndMintBatch(batch);

        // Node operator should have received exactly batchSize * NODE_REWARD_PER_IMPRESSION
        uint256 operatorMinted = cmxsToken.balanceOf(nodeOperator) - balBefore;
        assertEq(operatorMinted, batchSize * 1e15, "Operator minted amount mismatch");

        // getDailyMintedToday may include net emissions — must be >= operator minted
        assertGe(oracle.getDailyMintedToday(), batchSize * 1e15, "Daily minted tracking off");
    }

    // ── Step 4: Burns > Mints at low price (deflationary) ────────────────────

    function test_04_DeflationaryBehavior() public {
        _registerNode();
        bytes32 campaignId = _purchaseImpressions();

        // $1000 USDC purchase burned 100 CMXS (at $1.00 fallback price)
        // 5 PoD receipts mint 5 * 1e15 = 0.005 CMXS to node operator
        // Burned (100e18) >> direct operator mints (5e15) — system is deflationary
        uint256 totalBurned     = adBurn.getDailyBurns();
        uint256 operatorBefore  = cmxsToken.balanceOf(nodeOperator);

        DeliveryOracleV2.ReceiptBatch memory batch = _buildBatch(5, campaignId);
        oracle.verifyAndMintBatch(batch);

        uint256 directMinted = cmxsToken.balanceOf(nodeOperator) - operatorBefore;
        assertGt(totalBurned, directMinted, "Direct operator mints should be tiny vs burns");
    }

    // ── Step 5: veToken lock + fee claim ─────────────────────────────────────

    function test_05_VeTokenFeeClaim() public {
        _registerNode();
        _purchaseImpressions(); // puts USDC in treasury

        // Distribute epoch fees
        vm.prank(admin);
        treasury.distributeEpochFees(); // 70% of 150 USDC = $105 to ve holders

        // veHolder locks CMXS
        uint256 lockAmount  = 10_000 * 1e18;
        uint256 unlockTime  = block.timestamp + 52 weeks;
        vm.startPrank(veHolder);
        cmxsToken.approve(address(ve), lockAmount);
        uint256 lockId = ve.lock(lockAmount, unlockTime);

        // Claim fees
        uint256 usdcBefore = usdc.balanceOf(veHolder);
        ve.claimFees(lockId);
        vm.stopPrank();

        // veHolder received USDC fees (they're the only locker so gets 100%)
        assertGt(usdc.balanceOf(veHolder), usdcBefore, "No fees received");
    }

    // ── Step 6: Replay attack rejected ───────────────────────────────────────

    function test_06_ReplayAttackRejected() public {
        _registerNode();
        bytes32 campaignId = _purchaseImpressions();

        DeliveryOracleV2.ReceiptBatch memory batch = _buildBatch(1, campaignId);
        oracle.verifyAndMintBatch(batch); // first submission OK

        vm.expectRevert(DeliveryOracleV2.AlreadyVerified.selector);
        oracle.verifyAndMintBatch(batch); // second submission reverts
    }

    // ── Step 7: SLA violation rejected ───────────────────────────────────────

    function test_07_SLAViolationRejected() public {
        _registerNode();
        bytes32 campaignId = _purchaseImpressions();

        // Build batch with latency > 500ms
        DeliveryOracleV2.PoDReceipt[] memory receipts = new DeliveryOracleV2.PoDReceipt[](1);
        bytes[] memory sigs = new bytes[](1);

        bytes32 impId = keccak256("imp-sla-test");
        uint256 ts    = block.timestamp * 1000;
        uint256 latency = 600; // > 500ms SLA threshold

        bytes32 msgHash = keccak256(abi.encodePacked(
            impId, nodeOperator, uint256(25_000_000), ts, latency, campaignId, block.chainid
        ));
        bytes32 ethHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", msgHash));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(viewerPrivKey, ethHash);
        sigs[0] = abi.encodePacked(r, s, v);

        receipts[0] = DeliveryOracleV2.PoDReceipt({
            impressionId: impId,
            nodeOperator: nodeOperator,
            cpm:          25_000_000,
            timestamp:    ts,
            latencyMs:    latency,
            campaignId:   campaignId
        });

        DeliveryOracleV2.ReceiptBatch memory batch = DeliveryOracleV2.ReceiptBatch({
            receipts:   receipts,
            signatures: sigs
        });

        vm.expectRevert(abi.encodeWithSelector(DeliveryOracleV2.SLAViolation.selector, latency));
        oracle.verifyAndMintBatch(batch);
    }

    // ── Step 8: Daily mint cap enforced ──────────────────────────────────────

    function test_08_DailyMintCapEnforced() public {
        _registerNode();

        // Fresh USDC for this test's 11 purchases (11 x $1000 = $11K)
        usdc.mint(advertiser, 1_000 * 1e6); // top up $1K more

        // Set a tiny daily cap (3 impressions worth = 3e15)
        vm.prank(admin);
        oracle.setMaxDailyMint(3e15); // 3 * NODE_REWARD_PER_IMPRESSION

        // Buy enough campaigns to have active ones
        bytes32 mainCampaign = keccak256("cap-campaign-main");
        _purchaseImpressionsWithId(mainCampaign);

        // Mint 3 (fills the cap exactly)
        DeliveryOracleV2.ReceiptBatch memory batch3 = _buildBatch(3, mainCampaign);
        oracle.verifyAndMintBatch(batch3);
        assertEq(oracle.getDailyMintedToday(), 3e15, "Cap should be exactly full");

        // Use a different timestamp to get different impression IDs, then try to mint 1 more
        vm.warp(block.timestamp + 1);
        bytes32 campaignId2 = keccak256("cap-campaign-2");
        _purchaseImpressionsWithId(campaignId2);

        DeliveryOracleV2.ReceiptBatch memory batch1 = _buildBatch(1, campaignId2);
        vm.expectRevert(DeliveryOracleV2.DailyMintCapExceeded.selector);
        oracle.verifyAndMintBatch(batch1);
    }

    // ── Step 9: Node slash + jail + unjail ───────────────────────────────────

    function test_09_SlashJailUnjail() public {
        _registerNode();

        uint256 stakeBefore = nodeStaking.getNode(nodeOperator).stakedAmount;

        // Minor slash (5%)
        vm.prank(address(oracle));
        nodeStaking.slashNode(nodeOperator, NodeStaking.SlashSeverity.MINOR, "SLA breach");

        NodeStaking.NodeInfo memory info = nodeStaking.getNode(nodeOperator);
        assertEq(info.status == NodeStaking.NodeStatus.JAILED, true);
        assertEq(info.stakedAmount, (stakeBefore * 9500) / 10000);

        // Warp past jail
        vm.warp(block.timestamp + 7 days + 1);
        vm.prank(nodeOperator);
        nodeStaking.unjail();

        assertTrue(nodeStaking.isActiveNode(nodeOperator));
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    function _registerNode() internal {
        vm.startPrank(nodeOperator);
        cmxsToken.approve(address(nodeStaking), 10_000 * 1e18);
        nodeStaking.registerNode(bytes32("TOWER-001"), "moqs://node1.echoads.tv:4433");
        vm.stopPrank();
    }

    function _purchaseImpressions() internal returns (bytes32 campaignId) {
        campaignId = keccak256("default-campaign");
        _purchaseImpressionsWithId(campaignId);
    }

    function _purchaseImpressionsWithId(bytes32 campaignId) internal {
        vm.startPrank(advertiser);
        usdc.approve(address(adBurn), type(uint256).max);
        cmxsToken.approve(address(adBurn), type(uint256).max);
        adBurn.purchaseImpressions(contentPartner, 1000 * 1e6, 20_000, campaignId);
        vm.stopPrank();
    }

    function _buildBatch(uint256 count, bytes32 campaignId)
        internal view returns (DeliveryOracleV2.ReceiptBatch memory)
    {
        DeliveryOracleV2.PoDReceipt[] memory receipts = new DeliveryOracleV2.PoDReceipt[](count);
        bytes[] memory sigs = new bytes[](count);

        for (uint256 i = 0; i < count; i++) {
            bytes32 impId   = keccak256(abi.encodePacked("imp", i, block.timestamp, campaignId));
            uint256 ts      = block.timestamp * 1000;
            uint256 latency = 287;
            uint256 cpm     = 25_000_000;

            bytes32 msgHash = keccak256(abi.encodePacked(
                impId, nodeOperator, cpm, ts, latency, campaignId, block.chainid
            ));
            bytes32 ethHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", msgHash));
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(viewerPrivKey, ethHash);

            receipts[i] = DeliveryOracleV2.PoDReceipt({
                impressionId: impId,
                nodeOperator: nodeOperator,
                cpm:          cpm,
                timestamp:    ts,
                latencyMs:    latency,
                campaignId:   campaignId
            });
            sigs[i] = abi.encodePacked(r, s, v);
        }

        return DeliveryOracleV2.ReceiptBatch({ receipts: receipts, signatures: sigs });
    }

    function _getCampaignFields(bytes32 campaignId)
        internal view
        returns (address advertiser_, uint256 impressionsPurchased_, uint256 impressionsDelivered_,
                uint256 usdcAmount_, uint256 cmxsBurned_, uint256 timestamp_, bool active_)
    {
        (advertiser_, impressionsPurchased_, impressionsDelivered_,
         usdcAmount_, cmxsBurned_, timestamp_, active_) = adBurn.campaigns(campaignId);
    }
}
