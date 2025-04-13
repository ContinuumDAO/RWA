// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.19;

import "forge-std/console.sol";

import {ICTMRWA001} from "./interfaces/ICTMRWA001.sol";
import {ICTMRWAMap} from "./interfaces/ICTMRWAMap.sol";
import {ICTMRWA001Dividend} from "./interfaces/ICTMRWA001Dividend.sol";
import {Context} from "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract CTMRWA001Dividend is Context {
    using SafeERC20 for IERC20;

    address public dividendToken;
    address public tokenAddr;
    address public tokenAdmin;
    address ctmRwa001Map;
    uint256 public ID;
    uint256 rwaType;
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

    mapping(address => uint256) public unclaimedDividend; // address => dividend


    function setDividendToken(address _dividendToken) external onlyTokenAdmin returns(bool) {
       
        if(dividendToken != address(0)) {
            require(IERC20(dividendToken).balanceOf(address(this)) == 0, "CTMRWA001Dividend: Cannot change dividend token address whilst there is unclaimed dividend");
        }

        dividendToken = _dividendToken;

        emit NewDividendToken(_dividendToken, tokenAdmin);
        return(true);
    }

    function changeDividendRate(uint256 _slot, uint256 _dividend) external onlyTokenAdmin returns(bool) {
        ICTMRWA001(tokenAddr).changeDividendRate(_slot, _dividend);

        emit ChangeDividendRate(_slot, _dividend, tokenAdmin);
        return(true);
    }

    function getDividendRateBySlot(uint256 _slot) public view returns(uint256) {
        return(ICTMRWA001(tokenAddr).getDividendRateBySlot(_slot));
    }

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

    function claimDividend() public returns(bool) {
        uint256 dividend = unclaimedDividend[_msgSender()];
        require(IERC20(dividendToken).balanceOf(address(this)) >= dividend, "CTMRWA001Dividend: Dividend contract has not been supplied with enough tokens to claim the dividend");
    
        unclaimedDividend[_msgSender()] = 0;
        IERC20(dividendToken).transfer(_msgSender(), dividend);

        emit ClaimDividend(_msgSender(), dividend, dividendToken);
        return true;
    }

    function _getDividendByToken(uint256 _tokenId) internal view returns(uint256) {
        uint256 slot = ICTMRWA001(tokenAddr).slotOf(_tokenId);
        return(ICTMRWA001(tokenAddr).getDividendRateBySlot(slot) * ICTMRWA001(tokenAddr).balanceOf(_tokenId));
    }
        
}