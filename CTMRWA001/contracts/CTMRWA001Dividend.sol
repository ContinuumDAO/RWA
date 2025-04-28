// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.19;

import "forge-std/console.sol";

import {ICTMRWA001} from "./interfaces/ICTMRWA001.sol";
import {ICTMRWAMap} from "./interfaces/ICTMRWAMap.sol";
import {ICTMRWA001Dividend} from "./interfaces/ICTMRWA001Dividend.sol";
import {Context} from "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title AssetX Multi-chain Semi-Fungible-Token for Real-World-Assets (RWAs)
 * @author @Selqui ContinuumDAO
 *
 * @notice This contract manages the dividend distribution to holders of tokenIds in a CTMRWA001
 * contract. It stores the funds deposited here by the tokenAdmin (Issuer) and allows holders to
 * claim their dividends.
 *
 * This contract is deployed by CTMRWADeployer on each chain once for every CTMRWA001 contract.
 * Its ID matches the ID in CTMRWA001. There are no cross-chain functions in this contract.
 */

contract CTMRWA001Dividend is Context {
    using SafeERC20 for IERC20;

    /// @dev The ERC20 token contract address used to distribute dividends
    address public dividendToken;

    /// @dev The CTMRWA001 contract address linked to this contract
    address public tokenAddr;

    /// @dev The tokenAdmin (Issuer) address. Same as in CTMRWA001
    address public tokenAdmin;

    /// @dev The CTMRWAMap address
    address ctmRwa001Map;

    /// @dev The ID for this contract. Same as in the linked CTMRWA001
    uint256 public ID;

    /// @dev rwaType is the RWA type defining CTMRWA001
    uint256 rwaType;

    /// @dev version is the single integer version of this RWA type
    uint256 version;

    event NewDividendToken(address newToken, address currentAdmin);
    event ChangeDividendRate(uint256 slot, uint256 newDividend, address currentAdmin);
    event FundDividend(uint256 dividendPayable, address dividendToken, address currentAdmin);
    event ClaimDividend(address claimant, uint256 dividend, address dividendToken);

    modifier onlyTokenAdmin() {
        require(_msgSender() == tokenAdmin, "CTMRWA001Dividend: onlyTokenAdmin function");
        _;
    }

    constructor(
        uint256 _ID,
        address _tokenAddr,
        uint256 _rwaType,
        uint256 _version,
        address _map
    ) {
        tokenAddr = _tokenAddr;
        tokenAdmin = ICTMRWA001(tokenAddr).tokenAdmin();
        ctmRwa001Map = _map;
        ID = _ID;
        rwaType = _rwaType;
        version = _version;
    }

    /// @dev wallet of holder of a tokenId(s) in CTMRWA001 => unclaimed dividend
    mapping(address => uint256) public unclaimedDividend;

    /**
     * @notice Change the ERC20 dividend token used to pay holders
     * @param _dividendToken The address of the ERC20 token used to fund/pay for dividends
     * NOTE This can only be called if their are no outstanding unclaimed dividends.
     * NOTE this function can only be called by the tokenAdmin (Issuer).
     */
    function setDividendToken(address _dividendToken) external onlyTokenAdmin returns(bool) {
       
        if(dividendToken != address(0)) {
            require(IERC20(dividendToken).balanceOf(address(this)) == 0, "CTMRWA001Dividend: Cannot change dividend token address whilst there is unclaimed dividend");
        }

        dividendToken = _dividendToken;

        emit NewDividendToken(_dividendToken, tokenAdmin);
        return(true);
    }

    /**
     * @notice Set a new dividend rate for an Asset Class (slot) in the RWA
     * @param _slot The Asset Class (slot)
     * @param _dividend The new dividend rate
     * NOTE This is a tokenAdmin only function.
     * NOTE This is NOT a cross-chain transaction. This function must be called on each chain
     * separately.
     */
    function changeDividendRate(uint256 _slot, uint256 _dividend) external onlyTokenAdmin returns(bool) {
        ICTMRWA001(tokenAddr).changeDividendRate(_slot, _dividend);

        emit ChangeDividendRate(_slot, _dividend, tokenAdmin);
        return(true);
    }

    /**
     * @notice Get the dividend rate an Asset Class (slot) in the RWA
     * @param _slot The Asset Class (slot).
     */
    function getDividendRateBySlot(uint256 _slot) public view returns(uint256) {
        return(ICTMRWA001(tokenAddr).getDividendRateBySlot(_slot));
    }

    /**
     * @notice Get the total dividend to be paid out for an Asset Class (slot) to all holders
     * @param _slot The Asset Class (slot)
     */
    function getTotalDividendBySlot(uint256 _slot) public view returns(uint256) {
        uint256 len = ICTMRWA001(tokenAddr).tokenSupplyInSlot(_slot);
        uint256 dividendPayable;
        uint256 tokenId;

        uint256 slotRate = getDividendRateBySlot(_slot);

        for(uint256 i=0; i<len; i++) {
            tokenId = ICTMRWA001(tokenAddr).tokenInSlotByIndex(_slot, i);
            dividendPayable += ICTMRWA001(tokenAddr).balanceOf(tokenId)*slotRate;
        }

        return(dividendPayable);
    }

    /**
     * @notice Get the total dividend payable for all Asset Classes (slots) in the RWA
     */
    function getTotalDividend() public view returns(uint256) {
        uint256 nSlots = ICTMRWA001(tokenAddr).slotCount();
        uint256 dividendPayable;
        uint256 slot;

        for(uint256 i=0; i<nSlots; i++) {
            slot = ICTMRWA001(tokenAddr).slotByIndex(i);
            dividendPayable += getTotalDividendBySlot(slot);
        }

        return(dividendPayable);
    }

    /**
     * @notice This function calculates how much dividend the tokenAdmin needs to transfer
     * to this contract to pay all holders of tokenIds in the RWA. It the takes payment in 
     * the current dividend token. Afterwards, the funds will then be available to claim.
     * NOTE This is a tokenAdmin only function.
     * NOTE This is not a cross-chain function. The fundDividend must be called by tokenAdnin
     * on ALL chains in the RWA separately. This is to prevent a malicious actor seeing the funding
     * on one chain and then acquiring the tokens on another chain in the RWA before a cross-chain
     * transaction had happened (a few minutes). The function fundDividend should be called with
     * MultiCall on all chains simultaneously by the frontend to prevent such an exploit.
     */
    function fundDividend() public payable onlyTokenAdmin returns(uint256) {
        uint256 dividendPayable = getTotalDividend();

        require(IERC20(dividendToken).transferFrom(_msgSender(), address(this), dividendPayable), "CTMRWA001Dividend: Did not fund the dividend");
    
        uint256 tokenId;
        address holder;
        uint256 dividend;
        uint256 totalDividend;

        for(uint256 i=0; i<ICTMRWA001(tokenAddr).totalSupply(); i++) {
            tokenId = ICTMRWA001(tokenAddr).tokenByIndex(i);
            holder = ICTMRWA001(tokenAddr).ownerOf(tokenId);
            dividend = _getDividendByToken(tokenId);
            unclaimedDividend[holder] += dividend;
            totalDividend += dividend;
        }

        require(dividendPayable == totalDividend, "CTMRWA001Dividend: Dividend to be paid not equal to dividend to be funded");
        emit FundDividend(dividendPayable, dividendToken, _msgSender());

        return(totalDividend);
    }

    /**
     * @notice This allows a holder of tokenIds to claim all of their unclaimed dividends
     * NOTE The holder can see the token address using the dividendToken() function
     */
    function claimDividend() public returns(bool) {
        uint256 dividend = unclaimedDividend[_msgSender()];
        require(IERC20(dividendToken).balanceOf(address(this)) >= dividend, "CTMRWA001Dividend: Dividend contract has not been supplied with enough tokens to claim the dividend");
    
        unclaimedDividend[_msgSender()] = 0;
        IERC20(dividendToken).transfer(_msgSender(), dividend);

        emit ClaimDividend(_msgSender(), dividend, dividendToken);
        return true;
    }

    /// @dev This function returns how much dividend is payable for an individual tokenId
    function _getDividendByToken(uint256 _tokenId) internal view returns(uint256) {
        uint256 slot = ICTMRWA001(tokenAddr).slotOf(_tokenId);
        return(ICTMRWA001(tokenAddr).getDividendRateBySlot(slot) * ICTMRWA001(tokenAddr).balanceOf(_tokenId));
    }
        
}