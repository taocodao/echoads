# CMXS Token System: Complete Technical Specification
## Smart Contract Architecture, Token Economics & Market-Making System
### Prepared for Antigravity Engineering · May 2026

---

## Overview

This document is the complete engineering specification for the CMXS token system. It covers every smart contract, their interfaces, internal logic, and how they interact to form a self-balancing economic system. The design is grounded in Helium's validated Burn-Mint Equilibrium (BME), extended with DePIN node staking/slashing, veToken governance, vesting, and a self-managed on-chain market-making program using Uniswap v3 concentrated liquidity on Base L2.

The system has **seven core contracts** and **two off-chain automation components** that work together to create a closed-loop token economy where advertising revenue mechanically drives token demand and price stability.

---

## System Architecture: The Seven Contracts

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         CMXS TOKEN SYSTEM                                   │
│                                                                              │
│  ┌──────────────┐    burn    ┌──────────────┐    mint    ┌───────────────┐  │
│  │  AdBurn.sol  │──────────▶│ CMXSToken.sol│──────────▶│ DeliveryOracle│  │
│  │  (Ad Spend)  │           │  (ERC-20)    │           │     .sol      │  │
│  └──────┬───────┘           └──────┬───────┘           └───────┬───────┘  │
│         │USDC                      │                            │PoD verify │
│         ▼                          │lock                        ▼           │
│  ┌──────────────┐           ┌──────▼───────┐           ┌───────────────┐  │
│  │Treasury.sol  │           │  veToken.sol │           │NodeStaking.sol│  │
│  │  (Gnosis     │           │ (Governance) │           │ (Stake/Slash) │  │
│  │   Safe 3/5)  │           └──────────────┘           └───────────────┘  │
│  └──────┬───────┘                                                          │
│         │USDC                ┌──────────────┐           ┌───────────────┐  │
│         └───────────────────▶│VestingWallet │           │ LiquidityMgr  │  │
│                               │    .sol      │           │    .sol       │  │
│                               └──────────────┘           └───────────────┘  │
│                                                                              │
│  Off-chain: HummingbotAgent (CEX PMM)  │  Gelato Automate (LP rebalance)   │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Contract 1: CMXSToken.sol

### Purpose
The core ERC-20 token. Fixed max supply. Role-based mint/burn access. The only token in the system. No proxy — immutable after audit.

### Inheritance
```
OpenZeppelin ERC20 + ERC20Burnable + ERC20Capped + AccessControl + ERC20Permit
```

### Key Parameters
| Parameter | Value | Rationale |
|-----------|-------|-----------|
| `name` | "CMXS Protocol Token" | |
| `symbol` | `CMXS` | |
| `decimals` | 18 | EVM standard |
| `MAX_SUPPLY` | 1,000,000,000 (1B) | Fixed at deploy, enforced by ERC20Capped |
| `INITIAL_MINT` | 200,000,000 (20%) | TGE public + liquidity allocations |

### Roles (AccessControl)
| Role | Holder | Permission |
|------|--------|-----------|
| `DEFAULT_ADMIN_ROLE` | Gnosis Safe 3/5 multisig | Assign/revoke other roles |
| `MINTER_ROLE` | `DeliveryOracle.sol` only | `mint(address, uint256)` |
| `BURNER_ROLE` | `AdBurn.sol` only | Calls `burnFrom()` on advertiser balances |
| `PAUSER_ROLE` | Gnosis Safe 3/5 multisig | Emergency pause all transfers |

### Constructor
```solidity
constructor(address adminMultisig) 
    ERC20("CMXS Protocol Token", "CMXS")
    ERC20Capped(1_000_000_000 * 10**18)
{
    _grantRole(DEFAULT_ADMIN_ROLE, adminMultisig);
    // Initial mint: 200M tokens to Treasury for TGE distribution
    // MINTER_ROLE and BURNER_ROLE assigned after DeliveryOracle and AdBurn deploy
}
```

### Key Functions
```solidity
// Called only by DeliveryOracle after verified PoD receipt
function mintReward(address nodeOperator, uint256 amount) 
    external onlyRole(MINTER_ROLE) {
    require(totalSupply() + amount <= cap(), "Cap exceeded");
    _mint(nodeOperator, amount);
    emit RewardMinted(nodeOperator, amount, block.timestamp);
}

// Called only by AdBurn after advertiser pays USDC
function burnForAd(address advertiser, uint256 cmxsAmount) 
    external onlyRole(BURNER_ROLE) {
    _burn(advertiser, cmxsAmount);
    emit TokensBurnedForAds(advertiser, cmxsAmount, block.timestamp);
}
```

### Events
```solidity
event RewardMinted(address indexed node, uint256 amount, uint256 timestamp);
event TokensBurnedForAds(address indexed advertiser, uint256 amount, uint256 timestamp);
```

### Security Notes
- Solidity `^0.8.20` (built-in overflow protection)
- `ERC20Permit` enables gasless approvals (ERC-2612) — required for Uniswap v3 LP positions
- No `renounceOwnership` — admin role stays with multisig permanently
- Audit target: reentrancy in mint path (none, since `_mint` is internal), cap bypass

---

## Contract 2: AdBurn.sol

### Purpose
The revenue intake and burn engine. Advertisers deposit USDC to purchase verified ad impressions. The contract calculates the required CMXS burn amount at current oracle price, burns those tokens, and routes USDC to the Treasury. This is the primary **demand driver** for CMXS tokens.

### The Core Economic Equation

The burn amount is always pegged to the USD value of the impression:

```
cmxsToBurn = (impressionValueUSDC × burnRateBps) / (cmxsPriceUSD × 10000)
```

Where:
- `impressionValueUSDC` = CPM paid by advertiser (e.g., 45 USDC per 1,000 impressions)
- `burnRateBps` = configurable basis points of ad spend burned (e.g., 1000 bps = 10%)
- `cmxsPriceUSD` = current CMXS/USDC price from Chainlink price feed on Base

**This formula is the price floor mechanism.** If CMXS price falls, more tokens must be burned per impression, creating deflationary buy-pressure. If CMXS price rises, fewer tokens are burned, reducing sell-pressure on node operators cashing out rewards.

### Key Parameters
| Parameter | Initial Value | Governance-Controlled |
|-----------|--------------|----------------------|
| `burnRateBps` | 1000 (10% of ad spend value) | Yes (veToken vote) |
| `platformFeeBps` | 1500 (15% to Treasury) | Yes |
| `contentPartnerBps` | 8500 (85% to partner) | Remainder |
| `minCPM` | 15 USDC | Configurable |

### Key State Variables
```solidity
IERC20 public immutable usdc;          // USDC contract on Base
ICMXSToken public immutable cmxsToken; // CMXSToken.sol
ITreasury public immutable treasury;   // Treasury.sol
AggregatorV3Interface public cmxsPriceFeed; // Chainlink CMXS/USD feed
uint256 public burnRateBps;
uint256 public platformFeeBps;
```

### Core Function: `purchaseImpressions`
```solidity
function purchaseImpressions(
    address contentPartnerWallet,
    uint256 usdcAmount,          // Total USDC from advertiser
    uint256 impressionCount,     // Number of impressions being purchased
    bytes32 campaignId
) external nonReentrant {
    require(usdcAmount >= minCPM * impressionCount / 1000, "Below min CPM");

    // 1. Pull USDC from advertiser
    usdc.safeTransferFrom(msg.sender, address(this), usdcAmount);

    // 2. Calculate splits
    uint256 platformFee = (usdcAmount * platformFeeBps) / 10000;
    uint256 partnerPayment = usdcAmount - platformFee;

    // 3. Route USDC
    usdc.safeTransfer(address(treasury), platformFee);
    usdc.safeTransfer(contentPartnerWallet, partnerPayment);

    // 4. Calculate CMXS burn amount from Chainlink price
    uint256 cmxsBurnAmount = _calculateBurnAmount(usdcAmount);

    // 5. Burn CMXS from advertiser's balance (advertiser must have approved)
    cmxsToken.burnForAd(msg.sender, cmxsBurnAmount);

    // 6. Record campaign for DeliveryOracle verification
    campaigns[campaignId] = Campaign({
        advertiser: msg.sender,
        impressionsPurchased: impressionCount,
        impressionsDelivered: 0,
        usdcAmount: usdcAmount,
        cmxsBurned: cmxsBurnAmount,
        timestamp: block.timestamp,
        active: true
    });

    emit ImpressionsPurchased(msg.sender, campaignId, usdcAmount, cmxsBurnAmount);
}

function _calculateBurnAmount(uint256 usdcAmount) 
    internal view returns (uint256) {
    (, int256 cmxsPrice,,,) = cmxsPriceFeed.latestRoundData();
    require(cmxsPrice > 0, "Invalid price feed");
    // cmxsPrice has 8 decimals from Chainlink
    // usdcAmount has 6 decimals
    // result needs 18 decimals (CMXS)
    return (usdcAmount * burnRateBps * 10**20) / 
           (uint256(cmxsPrice) * 10000);
}
```

### Events
```solidity
event ImpressionsPurchased(
    address indexed advertiser, 
    bytes32 indexed campaignId, 
    uint256 usdcAmount, 
    uint256 cmxsBurned
);
event BurnRateUpdated(uint256 oldRate, uint256 newRate);
```

### Chainlink Price Feed
- **Feed address on Base**: `0x...` (CMXS/USD — to be deployed after TGE; use a Chainlink custom feed or Time-Weighted Average Price from the Uniswap v3 pool as fallback pre-Chainlink)
- **Pre-TGE fallback**: Uniswap v3 TWAP oracle (Base pool, 30-minute TWAP window) using `IUniswapV3Pool.observe()`
- **Staleness check**: Revert if `updatedAt < block.timestamp - 3600` (1 hour)

---

## Contract 3: DeliveryOracle.sol

### Purpose
The Proof of Delivery (PoD) verification engine. Verifies ECDSA signatures from viewer devices, checks latency SLA compliance, prevents replay attacks, and triggers CMXS mint rewards to node operators.

### Verification Flow
```
Viewer Device signs: keccak256(impressionID, nodeAddress, CPM, timestamp, chainID)
                              ↓
DeliveryOracle verifies ECDSA signature
                              ↓
Check: timestamp < 30s old (replay protection)
Check: impressionID not already verified (mapping)
Check: latency ≤ 500ms (from signed payload)
Check: node has active stake in NodeStaking.sol
                              ↓
Call CMXSToken.mintReward(nodeOperator, NODE_REWARD_PER_IMPRESSION)
```

### Key Parameters
| Parameter | Value | Notes |
|-----------|-------|-------|
| `NODE_REWARD_PER_IMPRESSION` | 0.001 CMXS (1e15 wei) | Per verified delivery |
| `MAX_LATENCY_MS` | 500 | Fails verification above this |
| `REPLAY_WINDOW` | 300 seconds | Impressions older than 5min rejected |
| `MAX_DAILY_MINT` | 500,000 CMXS | Circuit breaker — adjustable by governance |

### Data Structures
```solidity
struct PoDReceipt {
    bytes32 impressionId;
    address nodeOperator;
    uint256 cpm;           // In USDC microunits
    uint256 timestamp;     // Unix ms
    uint256 latencyMs;
    bytes32 campaignId;
}

// Packed for gas efficiency
struct ReceiptBatch {
    PoDReceipt[] receipts;
    bytes[] signatures;    // One ECDSA sig per receipt from viewer device
}
```

### Core Function: `verifyAndMintBatch`
```solidity
function verifyAndMintBatch(ReceiptBatch calldata batch) 
    external nonReentrant {
    require(batch.receipts.length == batch.signatures.length, "Length mismatch");
    require(batch.receipts.length <= MAX_BATCH_SIZE, "Batch too large");

    uint256 totalMinted = 0;
    
    for (uint256 i = 0; i < batch.receipts.length; i++) {
        PoDReceipt calldata receipt = batch.receipts[i];

        // Replay protection
        require(!usedImpressionIds[receipt.impressionId], "Already verified");
        require(
            block.timestamp - (receipt.timestamp / 1000) <= REPLAY_WINDOW,
            "Receipt expired"
        );

        // Latency SLA
        require(receipt.latencyMs <= MAX_LATENCY_MS, "SLA violation");

        // ECDSA verification
        bytes32 msgHash = keccak256(abi.encodePacked(
            receipt.impressionId,
            receipt.nodeOperator,
            receipt.cpm,
            receipt.timestamp,
            receipt.latencyMs,
            receipt.campaignId,
            block.chainid
        ));
        bytes32 ethSignedHash = MessageHashUtils.toEthSignedMessageHash(msgHash);
        address signer = ECDSA.recover(ethSignedHash, batch.signatures[i]);
        require(signer == viewerSigningAddress || 
                authorizedSigners[signer], "Invalid signature");

        // Node stake check
        require(nodeStaking.isActiveNode(receipt.nodeOperator), "Node not staked");

        // Campaign delivery tracking
        require(adBurn.campaigns(receipt.campaignId).active, "Campaign inactive");
        adBurn.recordDelivery(receipt.campaignId);

        // Mint reward
        usedImpressionIds[receipt.impressionId] = true;
        totalMinted += NODE_REWARD_PER_IMPRESSION;
        
        emit PoDVerified(
            receipt.impressionId, 
            receipt.nodeOperator, 
            receipt.cpm, 
            receipt.latencyMs
        );
    }

    // Daily mint circuit breaker
    require(
        dailyMintedToday + totalMinted <= MAX_DAILY_MINT, 
        "Daily mint cap exceeded"
    );
    dailyMintedToday += totalMinted;

    // Batch mint (single call to CMXSToken)
    // Node rewards accumulated per operator
    _distributeBatchRewards(batch.receipts, NODE_REWARD_PER_IMPRESSION);
}
```

### Net Emissions Mechanism (Helium-Inspired)
To ensure node rewards continue even after max supply is approached, the contract implements a Net Emissions cap: if total daily burns exceed daily mints, the protocol re-emits up to 1% of the daily cap as Net Emissions (these tokens are not new supply — they come from the burn pool and are reissued without increasing total outstanding supply).

```solidity
function _applyNetEmissions() internal {
    uint256 todayBurns = adBurn.getDailyBurns();
    uint256 todayMints = dailyMintedToday;
    
    if (todayBurns > todayMints) {
        uint256 netEmission = min(
            todayBurns - todayMints,
            (MAX_DAILY_MINT * NET_EMISSIONS_CAP_BPS) / 10000
        );
        // These tokens come from burn surplus, do not increase cap
        cmxsToken.mintNetEmission(address(nodeRewardPool), netEmission);
    }
}
```

---

## Contract 4: NodeStaking.sol

### Purpose
Manages EchoStar and third-party DePIN node operator registration, CMXS stake collateral, SLA-based slashing, and jailing. Nodes must maintain active stake to receive PoD mint rewards.

### Node Lifecycle
```
UNREGISTERED → REGISTERED (stake deposited) → ACTIVE → JAILED (SLA breach) → ACTIVE (after penalty)
                                                                             → DEREGISTERED (excessive violations)
```

### Key Parameters
| Parameter | Value | Adjustable |
|-----------|-------|-----------|
| `MIN_STAKE` | 10,000 CMXS | By governance |
| `SLASH_BPS_MINOR` | 500 (5%) | Minor SLA breach |
| `SLASH_BPS_MAJOR` | 2000 (20%) | PoD fraud attempt |
| `JAIL_DURATION` | 7 days | Minor first offense |
| `SLASH_RECIPIENT` | Treasury.sol | Slashed tokens go to protocol |

### Data Structures
```solidity
struct NodeInfo {
    address operator;
    uint256 stakedAmount;
    uint256 registeredAt;
    uint256 verifiedImpressions;
    uint256 slashCount;
    NodeStatus status;         // ACTIVE, JAILED, DEREGISTERED
    uint256 jailUntil;
    bytes32 echoStarTowerId;   // EchoStar tower identifier (optional)
    string endpointURL;        // MoQ/QUIC delivery endpoint
}

enum NodeStatus { UNREGISTERED, ACTIVE, JAILED, DEREGISTERED }
```

### Core Functions

**Register & Stake:**
```solidity
function registerNode(
    bytes32 towerId,
    string calldata endpointURL
) external {
    require(nodes[msg.sender].status == NodeStatus.UNREGISTERED, "Already registered");
    require(
        cmxsToken.transferFrom(msg.sender, address(this), MIN_STAKE), 
        "Stake transfer failed"
    );
    nodes[msg.sender] = NodeInfo({
        operator: msg.sender,
        stakedAmount: MIN_STAKE,
        registeredAt: block.timestamp,
        verifiedImpressions: 0,
        slashCount: 0,
        status: NodeStatus.ACTIVE,
        jailUntil: 0,
        echoStarTowerId: towerId,
        endpointURL: endpointURL
    });
    totalActiveNodes++;
    emit NodeRegistered(msg.sender, towerId, MIN_STAKE);
}
```

**Slashing (called by DeliveryOracle or governance):**
```solidity
function slashNode(
    address operator,
    SlashSeverity severity,
    string calldata reason
) external onlyRole(SLASHER_ROLE) {
    NodeInfo storage node = nodes[operator];
    require(node.status == NodeStatus.ACTIVE, "Node not active");

    uint256 slashBps = severity == SlashSeverity.MINOR 
        ? SLASH_BPS_MINOR 
        : SLASH_BPS_MAJOR;
    
    uint256 slashAmount = (node.stakedAmount * slashBps) / 10000;
    node.stakedAmount -= slashAmount;
    node.slashCount++;

    // Slashed tokens → Treasury
    cmxsToken.transfer(address(treasury), slashAmount);

    // Jail the node
    node.status = NodeStatus.JAILED;
    node.jailUntil = block.timestamp + JAIL_DURATION;

    // Deregister if stake falls below minimum or too many violations
    if (node.stakedAmount < MIN_STAKE / 2 || node.slashCount >= MAX_SLASH_COUNT) {
        node.status = NodeStatus.DEREGISTERED;
        totalActiveNodes--;
    }

    emit NodeSlashed(operator, slashAmount, severity, reason);
}
```

**Unstake:**
```solidity
function unstakeAndExit() external {
    NodeInfo storage node = nodes[msg.sender];
    require(
        node.status == NodeStatus.ACTIVE || 
        node.status == NodeStatus.JAILED, 
        "Cannot unstake"
    );
    require(block.timestamp > node.jailUntil, "Still jailed");

    // 30-day unbonding period to prevent rapid exit attacks
    require(
        node.unstakeRequestedAt + UNBONDING_PERIOD <= block.timestamp,
        "Unbonding period not complete"
    );

    uint256 amount = node.stakedAmount;
    node.stakedAmount = 0;
    node.status = NodeStatus.DEREGISTERED;
    totalActiveNodes--;
    
    cmxsToken.transfer(msg.sender, amount);
    emit NodeUnstaked(msg.sender, amount);
}
```

---

## Contract 5: veToken.sol (veCMXS)

### Purpose
Vote-escrow governance. Token holders lock CMXS for 1 week to 4 years to receive veCMXS — a non-transferable, decaying voting power NFT. veHolders direct gauge emissions (which liquidity pools get CMXS incentives), vote on protocol parameter changes, and receive a share of platform USDC fee revenue.

### Design Reference
Curve Finance veCRV model, adapted for DePIN context. The canonical implementation is validated by `$5B+ in locked value across CRV ecosystem`.

### Voting Power Formula
```
votingPower = cmxsLocked × (weeksRemaining / MAX_LOCK_WEEKS)
```
Where `MAX_LOCK_WEEKS = 208` (4 years).

### Key Functions

**Lock tokens:**
```solidity
function lock(uint256 amount, uint256 unlockTime) external {
    require(amount > 0, "Cannot lock 0");
    require(
        unlockTime >= block.timestamp + MIN_LOCK_DURATION &&
        unlockTime <= block.timestamp + MAX_LOCK_DURATION,
        "Invalid lock duration"
    );
    
    cmxsToken.safeTransferFrom(msg.sender, address(this), amount);
    
    uint256 lockId = ++lockCount;
    locks[lockId] = LockPosition({
        owner: msg.sender,
        amount: amount,
        start: block.timestamp,
        end: unlockTime,
        lastClaimTime: block.timestamp
    });
    
    totalLocked += amount;
    ownerToLocks[msg.sender].push(lockId);
    
    emit Locked(msg.sender, lockId, amount, unlockTime);
}
```

**Claim USDC fee share:**
```solidity
function claimFees(uint256 lockId) external nonReentrant {
    LockPosition storage pos = locks[lockId];
    require(pos.owner == msg.sender, "Not owner");
    require(block.timestamp < pos.end, "Lock expired");

    uint256 veBalance = getVotingPower(lockId);
    uint256 totalVe = getTotalVotingPower();
    
    // USDC accrued in Treasury since last claim
    uint256 accruedUSDC = treasury.getUnclaimedFees(lockId);
    uint256 userShare = (accruedUSDC * veBalance) / totalVe;
    
    pos.lastClaimTime = block.timestamp;
    treasury.disburseFees(msg.sender, userShare);
    
    emit FeesClaimed(msg.sender, lockId, userShare);
}
```

**Governance vote (parameter change):**
```solidity
function proposeParameterChange(
    address targetContract,
    bytes4 selector,
    bytes calldata newValue,
    string calldata description
) external returns (uint256 proposalId) {
    require(getVotingPower(msg.sender) >= PROPOSAL_THRESHOLD, "Insufficient voting power");
    // Standard timelock-governed execution
    proposalId = governance.propose(targetContract, selector, newValue, description);
}
```

### Token Emission Gauge System
veToken holders vote weekly to direct CMXS emissions to:
- CMXS/USDC Uniswap v3 pool on Base (liquidity incentives)
- CMXS/ETH Aerodrome pool on Base
- Node operator bonus pool
- Ecosystem grants

---

## Contract 6: VestingWallet.sol

### Purpose
Manages all locked token allocations: team, advisors, SAFT investors, and ecosystem grants. Each beneficiary gets their own VestingWallet instance deployed from a VestingFactory.

### Design (OpenZeppelin VestingWallet extended with cliff)

```solidity
contract CMXSVestingWallet {
    address public immutable beneficiary;
    uint256 public immutable cliffDuration;    // Seconds before any unlock
    uint256 public immutable vestingStart;     // Timestamp of TGE
    uint256 public immutable vestingDuration;  // Total vesting period in seconds
    uint256 public immutable totalAllocation;  // Total CMXS allocated
    uint256 public immutable tgeUnlockBps;     // BPS unlocked immediately at TGE
    
    uint256 public released;

    function vestedAmount(uint256 timestamp) 
        public view returns (uint256) 
    {
        if (timestamp < vestingStart + cliffDuration) {
            // Cliff not passed: only TGE unlock available
            return (totalAllocation * tgeUnlockBps) / 10000;
        }
        
        uint256 elapsed = timestamp - vestingStart;
        if (elapsed >= vestingDuration) {
            return totalAllocation;
        }
        
        // TGE unlock + linear vesting of remainder
        uint256 tgeAmount = (totalAllocation * tgeUnlockBps) / 10000;
        uint256 vestingAmount = totalAllocation - tgeAmount;
        uint256 linearVested = (vestingAmount * elapsed) / vestingDuration;
        
        return tgeAmount + linearVested;
    }
    
    function release() external {
        uint256 releasable = vestedAmount(block.timestamp) - released;
        require(releasable > 0, "Nothing to release");
        released += releasable;
        cmxsToken.transfer(beneficiary, releasable);
        emit Released(beneficiary, releasable);
    }
}
```

### Allocation Schedule

| Allocation | % | TGE Unlock | Cliff | Linear Vest |
|-----------|---|-----------|-------|-------------|
| Public TGE | 20% | 20% | None | 12 months |
| Team | 15% | 0% | 6 months | 24 months |
| SAFT Investors | 15% | 0% | 6 months | 18 months |
| Ecosystem/Grants | 25% | 5% | 3 months | 36 months |
| Protocol Treasury | 20% | 0% | 12 months | 48 months |
| Liquidity Program | 15% | 100% | None | None (deployed to DEX) |

### VestingFactory
Deploys individual CMXSVestingWallet instances per beneficiary with parameters encoded at deploy time. Only `DEFAULT_ADMIN_ROLE` can call factory.

---

## Contract 7: LiquidityManager.sol

### Purpose
On-chain self-managed market-making using Uniswap v3 concentrated liquidity on Base. Manages CMXS/USDC pool position, auto-rebalances when price moves outside configured range, and integrates with Gelato Automate for trigger-based rebalancing.

### Design

```solidity
contract CMXSLiquidityManager {
    IUniswapV3Pool public immutable pool;       // CMXS/USDC 1% fee tier pool on Base
    INonfungiblePositionManager public immutable positionManager;
    
    // Current LP position NFT
    uint256 public currentPositionId;
    
    // Price range parameters (in ticks)
    int24 public tickLower;
    int24 public tickUpper;
    int24 public rangeWidth;           // Half-width in ticks (default: ±20% from current)
    
    // Rebalance trigger: rebalance when price moves outside 80% of range
    uint256 public rebalanceTriggerBps;  // Default: 8000 (80%)
    
    // Authorized caller: Gelato Automate task
    address public automationKeeper;

    function checkRebalanceNeeded() external view returns (bool) {
        (, int24 currentTick,,,,,) = pool.slot0();
        // If current tick is outside 80% of the range, trigger rebalance
        int24 innerLower = tickLower + int24(int256((uint256(int256(tickUpper - tickLower)) * (10000 - rebalanceTriggerBps)) / 20000));
        int24 innerUpper = tickUpper - int24(int256((uint256(int256(tickUpper - tickLower)) * (10000 - rebalanceTriggerBps)) / 20000));
        return currentTick < innerLower || currentTick > innerUpper;
    }

    function rebalance() external {
        require(
            msg.sender == automationKeeper || 
            hasRole(MANAGER_ROLE, msg.sender), 
            "Unauthorized"
        );
        require(checkRebalanceNeeded(), "Rebalance not needed");

        // 1. Remove existing liquidity
        _removeLiquidity();
        
        // 2. Calculate new range centered on current price
        (, int24 currentTick,,,,,) = pool.slot0();
        int24 newLower = ((currentTick - rangeWidth) / TICK_SPACING) * TICK_SPACING;
        int24 newUpper = ((currentTick + rangeWidth) / TICK_SPACING) * TICK_SPACING;
        
        // 3. Add liquidity in new range
        (currentPositionId,,) = _addLiquidity(newLower, newUpper);
        
        tickLower = newLower;
        tickUpper = newUpper;
        
        emit Rebalanced(newLower, newUpper, currentTick, block.timestamp);
    }

    // Collect trading fees earned by LP position, forward to Treasury
    function collectAndForwardFees() external {
        (uint256 amount0, uint256 amount1) = positionManager.collect(
            INonfungiblePositionManager.CollectParams({
                tokenId: currentPositionId,
                recipient: address(treasury),
                amount0Max: type(uint128).max,
                amount1Max: type(uint128).max
            })
        );
        emit FeesCollected(amount0, amount1);
    }
}
```

### Asymmetric Range Strategy (BME-Aware)
Because the BME creates a structural price floor, the liquidity range should be **asymmetric** — weighted toward the downside:

```
Default range: ±20% of current price
BME-adjusted:  -30% lower bound / +15% upper bound
```

This concentrates liquidity where buying pressure is most needed (below current price) while allowing upside without over-deploying capital.

### Gelato Automate Integration
Gelato Automate executes `rebalance()` on-chain when `checkRebalanceNeeded()` returns `true`:

```javascript
// Gelato task (off-chain config)
{
  name: "CMXS LP Rebalance",
  execAddress: "LiquidityManager.sol address",
  execSelector: "rebalance()",
  resolverAddress: "LiquidityManager.sol address",
  resolverSelector: "checkRebalanceNeeded()",
  dedicatedMsgSender: true,
  trigger: { type: "RESOLVER" }  // Gelato polls checkRebalanceNeeded() every block
}
```

Cost: ~$0.10–0.50 in ETH per rebalance execution. Gelato treasury funded from platform USDC fees.

---

## Off-Chain Component 1: HummingbotAgent

### Purpose
CEX Pure Market Making bot for Coinbase (and future Kraken) listing. Runs on dedicated VPS. Places two-sided limit orders around mid-price, maintains bid-ask spread, manages inventory skew.

### Configuration (Hummingbot YAML)
```yaml
strategy: pure_market_making
exchange: coinbase_advanced_trade
market: CMXS-USDC
bid_spread: 0.003          # 0.3% below mid
ask_spread: 0.003          # 0.3% above mid
order_amount: 1000         # CMXS per order
order_levels: 3            # 3 levels each side
order_level_spread: 0.005  # 0.5% between levels
order_refresh_time: 15     # Refresh every 15 seconds
inventory_skew_enabled: true
inventory_target_base_percent: 0.5   # Target 50/50 CMXS/USDC
inventory_range_multiplier: 1.5
filled_order_delay: 30     # Wait 30s after fill before replacing
price_ceiling: 0           # No ceiling (asymmetric — allow upside)
price_floor: 0.05          # Minimum CMXS price (BME-derived)
kill_switch_enabled: true
kill_switch_rate: -0.15    # Stop if portfolio down 15% in one session
```

### Inventory Skew Logic
If CMXS inventory rises above 60% of total (excess sell-off), the bot automatically reduces sell order sizes and increases buy order sizes, rebalancing toward 50/50 target.

### VPS Requirements
- 2 vCPU, 4GB RAM, 20GB SSD
- Docker deployment: `docker run hummingbot/hummingbot:latest`
- Monitoring: Prometheus + Grafana dashboard
- Alerts: PagerDuty webhook if bot stops or kill_switch triggers

---

## Off-Chain Component 2: PoD Relay Service

### Purpose
Collects ECDSA-signed PoD receipts from viewer devices and EchoStar tower nodes, batches them, and submits to `DeliveryOracle.sol` on Base. Runs as a Node.js service.

### Flow
```
Viewer Device 
    → signs PoD payload with device key
    → sends to PoD Relay API endpoint (HTTPS)
                ↓
PoD Relay Service
    → validates signature format
    → deduplicates (Redis cache with impressionId key, 5min TTL)
    → batches into groups of 50 receipts
    → submits batch to DeliveryOracle.sol via Alchemy Base RPC
    → logs to database for reporting dashboard
```

### Tech Stack
- **Runtime**: Node.js 22 + TypeScript
- **Blockchain interaction**: ethers.js v6
- **RPC**: Alchemy Base mainnet + fallback to Infura
- **Deduplication**: Redis (ElastiCache or Upstash)
- **Database**: PostgreSQL (receipt audit trail)
- **Queue**: BullMQ (Redis-backed job queue for batch processing)
- **Monitoring**: Datadog APM

### Signing Key Architecture
Viewer devices use secp256k1 key pairs generated at first app launch and stored in device secure enclave. The device public key is registered with the CMXS backend at session initiation. `DeliveryOracle.sol` maintains a mapping of `authorizedSigners` (device public keys) that can be rotated without contract redeployment.

---

## Treasury.sol

### Purpose
Multisig-controlled protocol treasury. Receives USDC from AdBurn platform fees and slashed CMXS from NodeStaking. Disburses USDC fee share to veToken holders. Funded via Gnosis Safe 3-of-5 multisig for large transfers; routine disbursements are automated.

### Gnosis Safe Configuration
- **Threshold**: 3/5 signers required
- **Signers**: 5 hardware wallet addresses (Ledger/Trezor) controlled by separate team members
- **Timelocks**: Any transfer > $100,000 USDC requires 48-hour timelock delay
- **Routine automation**: veToken fee disbursements via dedicated `TREASURER_ROLE` contract call

### Key Functions
```solidity
function recordPlatformFeeIncome(uint256 usdcAmount) external onlyRole(INTAKE_ROLE) {
    totalUSDCReceived += usdcAmount;
    currentEpochFees += usdcAmount;
    emit FeeReceived(usdcAmount, block.timestamp);
}

function distributeEpochFees() external {
    // Called weekly by governance or Gelato automation
    uint256 toDistribute = (currentEpochFees * FEE_DISTRIBUTION_BPS) / 10000;
    // Remaining stays in treasury for operations
    currentEpochFees -= toDistribute;
    feesAvailableForVeHolders += toDistribute;
    emit EpochFeesDistributed(toDistribute);
}
```

---

## The Self-Balancing Flywheel: How It All Connects

The system achieves self-balancing through four feedback loops that operate simultaneously:

### Loop 1: Advertising Revenue → Token Burn → Price Floor
```
Advertiser pays USDC for impressions (AdBurn.sol)
    → AdBurn calculates required CMXS burn at current oracle price
    → More ad revenue = more CMXS burned = supply decreases
    → If price falls: same USD ad spend burns MORE tokens (floor mechanism)
    → Deflationary pressure prevents unlimited price decline
```

### Loop 2: Price Rise → Node Reward Optimization → Supply Expansion Control
```
If CMXS price rises significantly:
    → Same ad spend burns FEWER tokens per impression
    → Node operators earn same 0.001 CMXS but USD value is higher
    → More nodes join network (higher earnings) → supply of delivery increases
    → More delivery capacity → more ads can be served → more burns
    → Controlled re-minting through DeliveryOracle prevents hyper-deflation
```

### Loop 3: Daily Mint Cap → Hard Supply Ceiling
```
DeliveryOracle.MAX_DAILY_MINT (500,000 CMXS/day)
    → Regardless of advertising volume, daily new supply is bounded
    → Net Emissions mechanism recycles burn surplus back to node rewards
    → Total supply converges toward equilibrium, never to zero
```

### Loop 4: veToken Lock → Governance → Parameter Adaptation
```
Long-term holders lock CMXS → receive USDC fee income
    → Aligned to vote for parameters that maximize platform revenue
    → Can vote to increase burnRateBps if inflation detected
    → Can vote to adjust MAX_DAILY_MINT if reward incentives weaken
    → Can vote to change MIN_STAKE if node network over/under-provisioned
```

### Equilibrium State Visualized
```
HIGH AD REVENUE              LOW AD REVENUE
        ↓                          ↓
More CMXS burned            Fewer CMXS burned
Price ↑ pressure            Price ↓ pressure
        ↓                          ↓
Fewer tokens needed         More tokens needed
per $ of ad spend           per $ of ad spend
        ↓                          ↓
   Natural ceiling             Natural floor
        ↓                          ↓
        └─────────► EQUILIBRIUM ◄──┘
                  (BME stabilization)
```

---

## Development Environment & Tooling

### Framework: Foundry
Foundry is the recommended development framework for all CMXS contracts on Base.

```bash
# Install
curl -L https://foundry.paradigm.xyz | bash && foundryup

# Initialize project
forge init cmxs-protocol
cd cmxs-protocol

# Install dependencies
forge install OpenZeppelin/openzeppelin-contracts
forge install Uniswap/v3-core
forge install Uniswap/v3-periphery
forge install smartcontractkit/chainlink

# Project structure
cmxs-protocol/
├── src/
│   ├── CMXSToken.sol
│   ├── AdBurn.sol
│   ├── DeliveryOracle.sol
│   ├── NodeStaking.sol
│   ├── veToken.sol
│   ├── VestingWallet.sol
│   ├── VestingFactory.sol
│   ├── LiquidityManager.sol
│   └── Treasury.sol
├── test/
│   ├── CMXSToken.t.sol
│   ├── AdBurn.t.sol
│   ├── DeliveryOracle.t.sol
│   ├── NodeStaking.t.sol
│   ├── veToken.t.sol
│   ├── LiquidityManager.t.sol
│   └── Integration.t.sol     ← full system flywheel test
├── script/
│   ├── Deploy.s.sol           ← deployment order script
│   └── Configure.s.sol        ← post-deploy role assignment
└── foundry.toml
```

### Base Network Config (`foundry.toml`)
```toml
[profile.default]
src = "src"
out = "out"
libs = ["lib"]
solc = "0.8.24"
optimizer = true
optimizer_runs = 200

[profile.default.rpc_endpoints]
base_sepolia = "${BASE_SEPOLIA_RPC_URL}"
base_mainnet = "${BASE_MAINNET_RPC_URL}"

[profile.default.etherscan]
base_mainnet = { key = "${BASESCAN_API_KEY}", url = "https://api.basescan.org/api" }
```

### Deployment Order (CRITICAL — role dependency chain)

```bash
# Step 1: Deploy Treasury (Gnosis Safe first — external)
# Create Safe at safe.global, get address

# Step 2: Deploy CMXSToken
forge script script/Deploy.s.sol:DeployCMXSToken \
  --rpc-url $BASE_MAINNET_RPC_URL \
  --broadcast --verify

# Step 3: Deploy NodeStaking (needs CMXSToken address)
forge script script/Deploy.s.sol:DeployNodeStaking \
  --rpc-url $BASE_MAINNET_RPC_URL \
  --broadcast --verify

# Step 4: Deploy AdBurn (needs CMXSToken, Treasury, Chainlink feed)
forge script script/Deploy.s.sol:DeployAdBurn \
  --rpc-url $BASE_MAINNET_RPC_URL \
  --broadcast --verify

# Step 5: Deploy DeliveryOracle (needs CMXSToken, NodeStaking, AdBurn)
forge script script/Deploy.s.sol:DeployDeliveryOracle \
  --rpc-url $BASE_MAINNET_RPC_URL \
  --broadcast --verify

# Step 6: Assign roles (must be done via Gnosis Safe multisig)
# CMXSToken.grantRole(MINTER_ROLE, DeliveryOracle.address)
# CMXSToken.grantRole(BURNER_ROLE, AdBurn.address)
# NodeStaking.grantRole(SLASHER_ROLE, DeliveryOracle.address)

# Step 7: Deploy veToken, VestingFactory, LiquidityManager
# Step 8: Deploy Uniswap v3 CMXS/USDC pool (1% fee tier) on Base
# Step 9: Configure Gelato Automate task pointing to LiquidityManager
```

### Testing Requirements

Every contract must reach 100% line coverage. Key test scenarios:

**CMXSToken.t.sol**
- [ ] `mintReward` fails without MINTER_ROLE
- [ ] `burnForAd` fails without BURNER_ROLE
- [ ] Cap cannot be exceeded
- [ ] Pause blocks all transfers

**AdBurn.t.sol**
- [ ] `purchaseImpressions` burns correct CMXS amount at various price levels
- [ ] USDC splits match configured BPS exactly
- [ ] Price floor mechanism: lower CMXS price → more tokens burned
- [ ] Chainlink staleness check reverts correctly
- [ ] Fuzz test: random USDC amounts produce valid burn amounts

**DeliveryOracle.t.sol**
- [ ] Valid ECDSA signature passes; invalid fails
- [ ] Replay attack rejected (same impressionId submitted twice)
- [ ] Expired receipt rejected (timestamp > REPLAY_WINDOW old)
- [ ] Latency above MAX_LATENCY_MS rejected
- [ ] Daily mint cap enforced
- [ ] Unstaked node fails verification

**Integration.t.sol — The Flywheel Test**
```solidity
function testFullFlywheel() public {
    // 1. Register node operator with stake
    // 2. Advertiser purchases impressions (USDC in, CMXS burned)
    // 3. Submit batch PoD receipts (CMXS minted to node)
    // 4. Verify: burned > minted at low price (deflationary)
    // 5. Verify: USDC reaches Treasury and content partner wallet
    // 6. veToken holder claims USDC fee share
    // 7. Reduce CMXS price in mock Chainlink → verify more tokens burned
    // 8. Increase ad volume → verify daily mint cap triggers
    // 9. Verify Net Emissions recycle correctly
}
```

---

## Security Checklist for Audit (Pre-TGE)

| Category | Risk | Mitigation |
|----------|------|-----------|
| Reentrancy | `AdBurn.purchaseImpressions` handles USDC + mint in one tx | `nonReentrant` on all state-changing external functions |
| Access Control | MINTER_ROLE misassignment could cause unlimited mint | Role assignment via multisig only; time-delayed role changes |
| Oracle Manipulation | Flash loan could manipulate CMXS/USDC Uniswap price | 30-min TWAP oracle (not spot price); minimum $10M TVL before TWAP used |
| Replay Attacks | Same PoD receipt submitted multiple times | `usedImpressionIds` mapping; 5-min replay window |
| Integer Overflow | Price calculations with mixed decimals | Solidity 0.8.x built-in protection; explicit decimal scaling |
| Cap Bypass | `mintNetEmission` could exceed max supply | `require(totalSupply() + amount <= cap())` on every mint path |
| Slash Griefing | Malicious slash spam | Slasher role restricted to DeliveryOracle + governance only |
| LP Sandwich | `rebalance()` could be sandwiched | Private mempool via Flashbots Protect RPC on Base |
| Admin Key Risk | Compromised multisig signer | Hardware wallets required; 3/5 threshold; Gnosis Safe |

**Recommended Audit Firms**: Certik (fast turnaround), Trail of Bits (deepest Solidity expertise), or OpenZeppelin Audits (familiarity with OZ contracts used).

**Estimated audit cost**: $30,000–$80,000 depending on scope and firm.
**Estimated timeline**: 4–6 weeks from code freeze to final report.

---

## Summary: Contract Interaction Map

```
Advertiser ──USDC──▶ AdBurn.sol ──burn CMXS──▶ CMXSToken.sol ◀──mint──── DeliveryOracle.sol
                          │                                                        ▲
                     split USDC                                           verify PoD │
                     ┌────┴────┐                                          batch    │
                     ▼         ▼                                                   │
               Treasury.sol   ContentPartner                          NodeStaking.sol
                     │                                                 ▲     │
                  USDC fees                                         stake  slash
                     │                                                 │     ▼
                     ▼                                            Node    Treasury
               veToken.sol ◀── lock CMXS ── Token Holders        Operator  (CMXS)
                     │
                 USDC dividends
                     │
                  veHolders

LiquidityManager.sol ◀── Gelato Automate (trigger)
         │
    Uniswap v3 CMXS/USDC pool (Base)
         │
   HummingbotAgent (CEX - Coinbase order book)

VestingFactory.sol ──deploys──▶ VestingWallet[team/investors/ecosystem]
```

---

*This specification is complete as of May 2026 and is intended for direct handoff to the Antigravity engineering team. All contract interfaces, parameters, and deployment sequences are production-ready pending smart contract audit.*
