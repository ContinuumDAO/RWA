// SPDX-License-Identifier: BSL-1.1

pragma solidity 0.8.27;

import { IERC20, SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { ICTMRWA1Dividend } from "./ICTMRWA1Dividend.sol";
import { ICTMRWA1 } from "../core/ICTMRWA1.sol";
import { ICTMRWAMap } from "../shared/ICTMRWAMap.sol";
import { Address, Uint } from "../CTMRWAUtils.sol";

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
contract CTMRWA1Dividend is ICTMRWA1Dividend {
    using SafeERC20 for IERC20;

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

    event NewDividendToken(address newToken, address currentAdmin);
    event ChangeDividendRate(uint256 slot, uint256 newDividend, address currentAdmin);
    event FundDividend(uint256 dividendPayable, address dividendToken, address currentAdmin);
    event ClaimDividend(address claimant, uint256 dividend, address dividendToken);

    modifier onlyTokenAdmin() {
        if (msg.sender != tokenAdmin && msg.sender != ctmRwa1X) {
            revert CTMRWA1Dividend_Unauthorized(Address.Sender);
        }
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

    /// @dev wallet of holder of a tokenId(s) in CTMRWA1 => unclaimed dividend
    mapping(address => uint256) public unclaimedDividend;

    /// @dev unclaimed dividend for a tokenId. This is used by escrow, or staking contracts
    /// @dev to allow claiming of dividends by the owner, whilst the tokenId is locked
    mapping(uint256 => uint256) public dividendByTokenId;

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
     * NOTE This can only be called if their are no outstanding unclaimed dividends.
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
     */
    function changeDividendRate(uint256 _slot, uint256 _dividend) external onlyTokenAdmin returns (bool) {
        ICTMRWA1(tokenAddr).changeDividendRate(_slot, _dividend);

        emit ChangeDividendRate(_slot, _dividend, tokenAdmin);
        return (true);
    }

    /**
     * @notice Get the dividend rate an Asset Class (slot) in the RWA
     * @param _slot The Asset Class (slot).
     */
    function getDividendRateBySlot(uint256 _slot) public view returns (uint256) {
        return (ICTMRWA1(tokenAddr).getDividendRateBySlot(_slot));
    }

    /**
     * @notice Get the total dividend to be paid out for an Asset Class (slot) to all holders
     * @param _slot The Asset Class (slot)
     */
    function getTotalDividendBySlot(uint256 _slot) public view returns (uint256) {
        uint256 totalSupply = ICTMRWA1(tokenAddr).totalSupplyInSlot(_slot);

        uint256 slotRate = getDividendRateBySlot(_slot);

        return (totalSupply * slotRate);
    }

    /**
     * @notice Get the total dividend payable for all Asset Classes (slots) in the RWA
     */
    function getTotalDividend() public view returns (uint256) {
        uint256 nSlots = ICTMRWA1(tokenAddr).slotCount();
        uint256 dividendPayable;
        uint256 slot;

        for (uint256 i = 0; i < nSlots; i++) {
            slot = ICTMRWA1(tokenAddr).slotByIndex(i);
            dividendPayable += getTotalDividendBySlot(slot);
        }

        return (dividendPayable);
    }

    /**
     * @notice This function calculates how much dividend the tokenAdmin needs to transfer
     * to this contract to pay all holders of tokenIds in the RWA. It takes payment in
     * the current dividend token. Afterwards, the funds will then be available to claim.
     * NOTE This is a tokenAdmin only function.
     * NOTE This is not a cross-chain function. The fundDividend must be called by tokenAdnin
     * on ALL chains in the RWA separately. This is to prevent a malicious actor seeing the funding
     * on one chain and then acquiring the tokens on another chain in the RWA before a cross-chain
     * transaction had happened (a few minutes). The function fundDividend should be called with
     * MultiCall on all chains simultaneously by the frontend to prevent such an exploit.
     */
    function fundDividend() public onlyTokenAdmin returns (uint256) {
        uint256 dividendPayable = getTotalDividend();

        // NOTE: ?
        // uint8 decimals = ICTMRWA1(tokenAddr).valueDecimals();

        if (!IERC20(dividendToken).transferFrom(msg.sender, address(this), dividendPayable)) {
            revert CTMRWA1Dividend_FailedTransaction();
        }

        uint256 tokenId;
        address holder;
        uint256 dividend;
        uint256 totalDividend;

        for (uint256 i = 0; i < ICTMRWA1(tokenAddr).totalSupply(); i++) {
            tokenId = ICTMRWA1(tokenAddr).tokenByIndex(i);
            holder = ICTMRWA1(tokenAddr).ownerOf(tokenId);
            dividend = _getDividendByToken(tokenId);
            unclaimedDividend[holder] += dividend;
            dividendByTokenId[tokenId] += dividend;
            totalDividend += dividend;
        }

        if (dividendPayable != totalDividend) {
            revert CTMRWA1Dividend_InvalidDividend(Uint.Payable);
        }
        emit FundDividend(dividendPayable, dividendToken, msg.sender);

        return (totalDividend);
    }

    /**
     * @notice This allows a holder of tokenIds to claim all of their unclaimed dividends
     * NOTE The holder can see the token address using the dividendToken() function
     */
    function claimDividend() public returns (bool) {
        uint256 dividend = unclaimedDividend[msg.sender];
        if (IERC20(dividendToken).balanceOf(address(this)) < dividend) {
            revert CTMRWA1Dividend_InvalidDividend(Uint.Balance);
        }

        unclaimedDividend[msg.sender] = 0;
        IERC20(dividendToken).transfer(msg.sender, dividend);

        emit ClaimDividend(msg.sender, dividend, dividendToken);
        return true;
    }

    /// @dev This function allows the owner of a tokenId to reset the outstanding
    /// @dev unclaimed dividend balance to zero. It is intended to assist
    /// @dev escrow or staking contracts to account for and allow dividend payments
    /// @dev to the beneficial holders of a tokenId, whilst it is technically owned by
    /// @dev the staking contract
    function resetDividendByToken(uint256 _tokenId) external {
        address owner = ICTMRWA1(tokenAddr).ownerOf(_tokenId);
        if (msg.sender != owner) {
            revert CTMRWA1Dividend_Unauthorized(Address.Sender);
        }

        dividendByTokenId[_tokenId] = 0;
    }

    /// @dev This function returns how much dividend is payable for an individual tokenId
    function _getDividendByToken(uint256 _tokenId) internal view returns (uint256) {
        uint256 slot = ICTMRWA1(tokenAddr).slotOf(_tokenId);
        return (ICTMRWA1(tokenAddr).getDividendRateBySlot(slot) * ICTMRWA1(tokenAddr).balanceOf(_tokenId));
    }
}
