// SPDX-License-Identifier: BSL-1.1

pragma solidity 0.8.27;

import { ICTMRWA1 } from "../core/ICTMRWA1.sol";

import { ICTMRWA1InvestWithTimeLock } from "../deployment/ICTMRWA1InvestWithTimeLock.sol";
import { ICTMRWAMap } from "../shared/ICTMRWAMap.sol";
import { Address, Uint } from "../utils/CTMRWAUtils.sol";
import { ICTMRWA1Dividend } from "./ICTMRWA1Dividend.sol";
import { Checkpoints } from "@openzeppelin/contracts/utils/structs/Checkpoints.sol";
import { IERC20, SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import { Pausable } from "@openzeppelin/contracts/utils/Pausable.sol";

/**
 * @title AssetX Multi-chain Semi-Fungible-Token for Real-World-Assets (RWAs)
 * @author @Selqui ContinuumDAO
 *
 * @notice This contract manages the dividend distribution to holders of tokenIds in a CTMRWA1
 * contract. It stores the funds deposited here by the tokenAdmin (Issuer) and allows holders to
 * claim their dividends.
 *
 * This contract is deployed by CTMRWADeployer on each chain once for every CTMRWA1 contract.
 * Its ID matches the ID in CTMRWA1. There are no cross-chain functions in this contract.
 */
contract CTMRWA1Dividend is ICTMRWA1Dividend, ReentrancyGuard, Pausable {
    using SafeERC20 for IERC20;
    using Checkpoints for Checkpoints.Trace208;

    uint48 public constant ONE_DAY = 1 days;

    /// @dev The ERC20 token contract address used to distribute dividends
    address public dividendToken;

    /// @dev The CTMRWA1 contract address linked to this contract
    address public tokenAddr;

    /// @dev The tokenAdmin (Issuer) address. Same as in CTMRWA1
    address public tokenAdmin;

    /// @dev The address of the CTMRWA1X contract
    address public ctmRwa1X;

    /// @dev The CTMRWAMap address
    address ctmRwa1Map;

    /// @dev The ID for this contract. Same as in the linked CTMRWA1
    uint256 public ID;

    /// @dev rwaType is the RWA type defining CTMRWA1
    uint256 public immutable RWA_TYPE;

    /// @dev version is the single integer version of this RWA type
    uint256 public immutable VERSION;

    /// @notice Tracks the dividend fundings for each slot
    struct DividendFunding {
        uint256 slot;
        uint48 fundingTime;
    }
    DividendFunding[] public dividendFundings;

    /// @notice Tracks the last claimed index for each holder and slot
    mapping(uint256 => mapping(address => uint256)) public lastClaimedIndex;

    /// @dev slot => dividend rate
    mapping (uint256 => Checkpoints.Trace208) internal _dividendRate;

    event NewDividendToken(address newToken, address currentAdmin);
    event ChangeDividendRate(uint256 slot, uint256 newDividend, address currentAdmin);
    event FundDividend(uint256 dividendPayable, address dividendToken, address currentAdmin);
    event ClaimDividend(address claimant, uint256 dividend, address dividendToken);

    modifier onlyTokenAdmin() {
        if (msg.sender != tokenAdmin && msg.sender != ctmRwa1X) {
            revert CTMRWA1Dividend_OnlyAuthorized(Address.Sender, Address.TokenAdmin);
        }
        _;
    }

    modifier whenDividendNotPaused() {
        if (paused()) revert CTMRWA1Dividend_EnforcedPause();
        _;
    }

    constructor(uint256 _ID, address _tokenAddr, uint256 _rwaType, uint256 _version, address _map) {
        tokenAddr = _tokenAddr;
        tokenAdmin = ICTMRWA1(tokenAddr).tokenAdmin();
        ctmRwa1X = ICTMRWA1(tokenAddr).ctmRwa1X();
        ctmRwa1Map = _map;
        ID = _ID;
        RWA_TYPE = _rwaType;
        VERSION = _version;
    }


    /**
     * @notice Change the tokenAdmin address
     * NOTE This function can only be called by CTMRWA1X, or the existing tokenAdmin
     */
    function setTokenAdmin(address _tokenAdmin) external onlyTokenAdmin returns (bool) {
        tokenAdmin = _tokenAdmin;
        return (true);
    }

    /**
     * @notice Change the ERC20 dividend token used to pay holders
     * @param _dividendToken The address of the ERC20 token used to fund/pay for dividends
     * NOTE This can only be called if there are no outstanding unclaimed dividends.
     * NOTE this function can only be called by the tokenAdmin (Issuer).
     */
    function setDividendToken(address _dividendToken) external onlyTokenAdmin returns (bool) {
        if (dividendToken != address(0)) {
            if (IERC20(dividendToken).balanceOf(address(this)) != 0) {
                revert CTMRWA1Dividend_InvalidDividend(Uint.Balance);
            }
        }

        dividendToken = _dividendToken;

        emit NewDividendToken(_dividendToken, tokenAdmin);
        return (true);
    }

    /**
     * @notice Set a new dividend rate for an Asset Class (slot) in the RWA
     * @param _slot The Asset Class (slot)
     * @param _dividend The new dividend rate
     * NOTE This is a tokenAdmin only function.
     * NOTE This is NOT a cross-chain transaction. This function must be called on each chain
     * separately.
     * @dev Lower level function, called from CTMRWA1Dividend to change the dividend rate for a slot
     * @param _slot The slot number in this CTMRWA1
     * @param _dividend The dividend rate per unit of this slot that can be claimed by holders
     * @return success True if the dividend rate was changed, false otherwise
     */
    function changeDividendRate(uint256 _slot, uint256 _dividend) external onlyTokenAdmin returns (bool) {
        if (!ICTMRWA1(tokenAddr).slotExists(_slot)) {
            revert CTMRWA1Dividend_InvalidSlot(_slot);
        }
        uint256 slotIndex = ICTMRWA1(tokenAddr).allSlotsIndex(_slot);
        _dividendRate[slotIndex].push(uint48(block.timestamp), uint208(_dividend));
        emit ChangeDividendRate(_slot, _dividend, tokenAdmin);
        return (true);
    }

    /**
     * @notice Returns the dividend rate for a slot in this CTMRWA1
     * @param _slot The slot number in this CTMRWA1
     * @return The dividend rate for the slot
     */
    function getDividendRateBySlotAt(uint256 _slot, uint48 _timestamp) public view returns (uint256) {
        if (!ICTMRWA1(tokenAddr).slotExists(_slot)) {
            revert CTMRWA1Dividend_InvalidSlot(_slot);
        }
        uint256 slotIndex = ICTMRWA1(tokenAddr).allSlotsIndex(_slot);
        return uint256(_dividendRate[slotIndex].upperLookupRecent(_timestamp));
    }

    function getDividendRateBySlot(uint256 _slot) public view returns (uint256) {
        if (!ICTMRWA1(tokenAddr).slotExists(_slot)) {
            revert CTMRWA1Dividend_InvalidSlot(_slot);
        }
        uint256 slotIndex = ICTMRWA1(tokenAddr).allSlotsIndex(_slot);
        return uint256(_dividendRate[slotIndex].latest());
    }

    /**
     * @notice Get the dividend to be paid out for an Asset Class (slot) to a holder since the last claim
     * @param _slot The Asset Class (slot)
     * @param _holder The holder of the tokenId
     * @return The dividend to be paid out
     */
    function getDividendPayableBySlot(uint256 _slot, address _holder) public view returns (uint256) {
        uint256 start = lastClaimedIndex[_slot][_holder];
        uint256 sum = 0;
        uint256 n = dividendFundings.length;
        for (uint256 i = start; i < n; i++) {
            DividendFunding storage funding = dividendFundings[i];
            if (funding.slot == _slot) {
                uint256 bal = ICTMRWA1(tokenAddr).balanceOfAt(_holder, _slot, funding.fundingTime);
                uint256 dividendRate = getDividendRateBySlotAt(_slot, funding.fundingTime);
                sum += dividendRate * bal;
            }
        }
        return sum;
    }

    /**
     * @notice Get the total dividend payable for all Asset Classes (slots) in the RWA
     * @param _holder The holder of the tokenId
     * @return dividendPayable The total dividend payable
     */
    function getDividendPayable(address _holder) public view returns (uint256) {
        uint256 nSlots = ICTMRWA1(tokenAddr).slotCount();
        uint256 dividendPayable;
        uint256 slot;

        for (uint256 i = 0; i < nSlots; i++) {
            slot = ICTMRWA1(tokenAddr).slotByIndex(i);
            dividendPayable += getDividendPayableBySlot(slot, _holder);
        }

        return (dividendPayable);
    }

    /**
     * @notice Add a new checkpoint for claiming dividends for an Asset Class (slot).
     * The function then calculates how much dividend is needed to transfer to this contract to pay the dividends
     * and then transfers the funds to this contract ready for claiming by all holders of tokenIds in 
     * the RWA token. It takes payment in the current dividend token.
     * @param _slot The Asset Class (slot) to add dividends for
     * @param _fundingTime The time to use to calculate the dividend
     * NOTE The actual funding time is calculated to be at midnight prior to _fundingTime.
     * The actual funding time must be a time after the previous time (dividendFundedAt).
     * NOTE This is not a cross-chain function. It must be called on each chain in the RWA. Use Multicall
     * with the same _fundingTime to prevent arbitrage.
     */
    function fundDividend(
        uint256 _slot,
        uint256 _fundingTime
    ) public onlyTokenAdmin nonReentrant returns (uint256) {
        if (dividendToken == address(0)) {
            revert CTMRWA1Dividend_FundTokenNotSet();
        }
        uint48 midnight = _midnightBefore(_fundingTime);
        // Ensure _fundingTime is greater than the last time it was called for this slot and less than block.timestamp
        uint48 lastFunding = lastFundingBySlot(_slot);
        if (lastFunding != 0) {
            if (!(midnight > lastFunding)) {
                revert CTMRWA1Dividend_FundingTimeLow();
            }
            if (midnight < lastFunding + 30 days) {
                revert CTMRWA1Dividend_FundingTooFrequent();
            }
        }
        if (!(_fundingTime < block.timestamp)) {
            revert CTMRWA1Dividend_FundingTimeFuture();
        }

        uint256 supplyInSlot;
        uint256 supplyInInvestContract;
       
        (bool investContractExists, address ctmRwaInvest) =
            ICTMRWAMap(ctmRwa1Map).getInvestContract(ID, RWA_TYPE, VERSION);

    
        uint256 totalSupplyInSlot = ICTMRWA1(tokenAddr).totalSupplyInSlotAt(_slot, midnight);

        if (investContractExists) {
            supplyInInvestContract = ICTMRWA1(tokenAddr).balanceOfAt(ctmRwaInvest, _slot, midnight);
        }

        // If ctmRwaInvest did not exist at time midnight, then supplyInInvestContract == 0
        supplyInSlot = totalSupplyInSlot - supplyInInvestContract;

        uint256 dividendPayable = supplyInSlot * getDividendRateBySlot(_slot);
        if (dividendPayable == 0) {
            return (0);
        }

        if (!IERC20(dividendToken).transferFrom(msg.sender, address(this), dividendPayable)) {
            revert CTMRWA1Dividend_FailedTransaction();
        }

        dividendFundings.push(DividendFunding({slot: _slot, fundingTime: midnight}));

        emit FundDividend(dividendPayable, dividendToken, tokenAdmin);

        return (dividendPayable);
    }

    /**
     * @notice This allows a holder to claim all of their unclaimed dividends
     * @return dividend The amount of dividend claimed
     * NOTE The holder can see the dividendtoken address using the dividendToken() function
     */
    function claimDividend() public nonReentrant whenDividendNotPaused returns (uint256) {

        uint256 dividend = getDividendPayable(msg.sender);

        // Update lastClaimedIndex for all slots
        uint256 nSlots = ICTMRWA1(tokenAddr).slotCount();
        for (uint256 i = 0; i < nSlots; i++) {
            uint256 slot = ICTMRWA1(tokenAddr).slotByIndex(i);
            lastClaimedIndex[slot][msg.sender] = dividendFundings.length;
        }

        if (dividend == 0) {
            return (0);
        }

        if (IERC20(dividendToken).balanceOf(address(this)) < dividend) {
            revert CTMRWA1Dividend_InvalidDividend(Uint.Balance);
        }

        IERC20(dividendToken).transfer(msg.sender, dividend);

        emit ClaimDividend(msg.sender, dividend, dividendToken);
        return (dividend);
    }

    /// @notice Returns the last funding timestamp for a given slot
    /// @param _slot The slot to get the last funding timestamp for
    function lastFundingBySlot(uint256 _slot) public view returns (uint48) {
        uint256 n = dividendFundings.length;
        for (uint256 i = n; i > 0; i--) {
            if (dividendFundings[i - 1].slot == _slot) {
                return dividendFundings[i - 1].fundingTime;
            }
        }
        return 0;
    }

   
    function _addDividendSnapshot(uint256 slot) internal {
   
    }

    /**
     * @notice Pause the contract. Only callable by tokenAdmin.
     */
    function pause() external onlyTokenAdmin {
        _pause();
    }

    /**
     * @notice Unpause the contract. Only callable by tokenAdmin.
     */
    function unpause() external onlyTokenAdmin {
        _unpause();
    }

    /// @dev Returns the timestamp of midnight (00:00:00 UTC) before the input timestamp
    function _midnightBefore(uint256 _timestamp) internal pure returns (uint48) {
        return uint48((_timestamp / 1 days) * 1 days);
    }
}
