// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title CMXSVestingWallet
 * @notice OZ VestingWallet extended with TGE unlock and cliff.
 *         Deployed by VestingFactory — one instance per beneficiary.
 *
 * Release schedule:
 *   t=0 (TGE):           tgeUnlockBps% is immediately claimable
 *   t=cliff:             cliff period ends, linear vesting begins
 *   t=cliff..+duration:  remaining (100% - tgeUnlockBps) vests linearly
 *   t=vestingEnd:        100% claimable
 */
contract CMXSVestingWallet is Ownable {
    using SafeERC20 for IERC20;

    IERC20 public immutable cmxsToken;

    address public immutable beneficiary;
    uint256 public immutable vestingStart;     // TGE timestamp
    uint256 public immutable cliffDuration;    // seconds before linear vesting begins
    uint256 public immutable vestingDuration;  // total vesting period (from vestingStart)
    uint256 public immutable totalAllocation;  // total CMXS for this beneficiary
    uint256 public immutable tgeUnlockBps;     // BPS unlocked immediately at TGE (0 for team)

    uint256 public released;

    event Released(address indexed beneficiary, uint256 amount);
    event Revoked(uint256 remaining);

    error NothingToRelease();
    error NotBeneficiary();

    constructor(
        address _cmxsToken,
        address _beneficiary,
        uint256 _vestingStart,
        uint256 _cliffDuration,
        uint256 _vestingDuration,
        uint256 _totalAllocation,
        uint256 _tgeUnlockBps,
        address _factory
    ) Ownable(_factory) {
        require(_beneficiary != address(0), "Zero beneficiary");
        require(_vestingDuration > 0, "Zero duration");
        require(_tgeUnlockBps <= 10000, "BPS > 100%");
        require(_cmxsToken != address(0), "Zero token");

        cmxsToken       = IERC20(_cmxsToken);
        beneficiary     = _beneficiary;
        vestingStart    = _vestingStart;
        cliffDuration   = _cliffDuration;
        vestingDuration = _vestingDuration;
        totalAllocation = _totalAllocation;
        tgeUnlockBps    = _tgeUnlockBps;
    }

    // ── Vesting Math ──────────────────────────────────────────────────────────

    /**
     * @notice Total CMXS vested at a given timestamp.
     */
    function vestedAmount(uint256 timestamp) public view returns (uint256) {
        uint256 tgeAmount = (totalAllocation * tgeUnlockBps) / 10000;

        // Before cliff: only TGE unlock
        if (timestamp < vestingStart + cliffDuration) {
            return timestamp >= vestingStart ? tgeAmount : 0;
        }

        // After full vest: everything
        uint256 elapsed = timestamp - vestingStart;
        if (elapsed >= vestingDuration) {
            return totalAllocation;
        }

        // Cliff passed: TGE unlock + linear vesting of remainder
        uint256 vestingAmount = totalAllocation - tgeAmount;
        uint256 linearVested  = (vestingAmount * elapsed) / vestingDuration;
        return tgeAmount + linearVested;
    }

    /**
     * @notice Releasable = vested - already released.
     */
    function releasable() public view returns (uint256) {
        return vestedAmount(block.timestamp) - released;
    }

    // ── Release ───────────────────────────────────────────────────────────────

    /**
     * @notice Transfer releasable CMXS to the beneficiary.
     *         Anyone can call — tokens always go to beneficiary.
     */
    function release() external {
        uint256 amount = releasable();
        if (amount == 0) revert NothingToRelease();

        released += amount;
        cmxsToken.safeTransfer(beneficiary, amount);
        emit Released(beneficiary, amount);
    }

    /**
     * @notice Emergency revoke — returns unvested tokens to factory owner (multisig).
     *         Releases vested portion to beneficiary first.
     */
    function revoke() external onlyOwner {
        uint256 vestedNow    = vestedAmount(block.timestamp);
        uint256 toRelease    = vestedNow - released;
        uint256 toReturn     = totalAllocation - vestedNow;

        released = vestedNow;

        if (toRelease > 0) {
            cmxsToken.safeTransfer(beneficiary, toRelease);
            emit Released(beneficiary, toRelease);
        }
        if (toReturn > 0) {
            cmxsToken.safeTransfer(owner(), toReturn);
            emit Revoked(toReturn);
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────

/**
 * @title VestingFactory
 * @notice Deploys CMXSVestingWallet instances per beneficiary.
 *         Only callable by DEFAULT_ADMIN_ROLE (Gnosis Safe multisig).
 *
 * Allocation schedule from spec:
 *   Public TGE:       20% — TGE 20%, 0-mo cliff, 12-mo linear
 *   Team:             15% — TGE  0%, 6-mo cliff, 24-mo linear
 *   SAFT Investors:   15% — TGE  0%, 6-mo cliff, 18-mo linear
 *   Ecosystem/Grants: 25% — TGE  5%, 3-mo cliff, 36-mo linear
 *   Protocol Treasury:20% — TGE  0%,12-mo cliff, 48-mo linear
 *   Liquidity Program:15% — TGE100%, no cliff,    no vest (deployed to DEX)
 */
contract VestingFactory is Ownable {
    using SafeERC20 for IERC20;

    IERC20 public immutable cmxsToken;
    uint256 public immutable tge; // TGE timestamp

    address[] public wallets;
    mapping(address => address) public beneficiaryToWallet;

    event WalletDeployed(
        address indexed wallet,
        address indexed beneficiary,
        uint256 totalAllocation,
        uint256 tgeUnlockBps,
        uint256 cliffDuration,
        uint256 vestingDuration
    );

    constructor(address _cmxsToken, uint256 _tgeTimestamp, address _adminMultisig)
        Ownable(_adminMultisig)
    {
        require(_cmxsToken != address(0), "Zero token");
        cmxsToken = IERC20(_cmxsToken);
        tge       = _tgeTimestamp;
    }

    /**
     * @notice Deploy a vesting wallet and fund it.
     *         Caller must have approved this factory for `totalAllocation` CMXS.
     *
     * @param beneficiary      Token recipient.
     * @param totalAllocation  Total CMXS for this beneficiary (18 dec).
     * @param tgeUnlockBps     BPS unlocked at TGE (e.g. 2000 = 20%).
     * @param cliffMonths      Months before linear vesting starts.
     * @param vestingMonths    Total vesting period in months (from TGE).
     */
    function deployWallet(
        address beneficiary,
        uint256 totalAllocation,
        uint256 tgeUnlockBps,
        uint256 cliffMonths,
        uint256 vestingMonths
    ) external onlyOwner returns (address wallet) {
        require(beneficiary != address(0), "Zero beneficiary");
        require(beneficiaryToWallet[beneficiary] == address(0), "Already deployed");

        uint256 cliffSec   = cliffMonths   * 30 days;
        uint256 vestingSec = vestingMonths  * 30 days;

        CMXSVestingWallet w = new CMXSVestingWallet(
            address(cmxsToken),
            beneficiary,
            tge,
            cliffSec,
            vestingSec,
            totalAllocation,
            tgeUnlockBps,
            address(this)
        );

        wallet = address(w);
        wallets.push(wallet);
        beneficiaryToWallet[beneficiary] = wallet;

        // Fund the wallet
        cmxsToken.safeTransferFrom(msg.sender, wallet, totalAllocation);

        emit WalletDeployed(wallet, beneficiary, totalAllocation, tgeUnlockBps, cliffSec, vestingSec);
    }

    function getWalletCount() external view returns (uint256) {
        return wallets.length;
    }
}
