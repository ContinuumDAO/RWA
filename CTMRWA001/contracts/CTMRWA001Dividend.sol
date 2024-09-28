// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.20;

import {ICTMRWA001Dividend} from "./ICTMRWA001Dividend.sol";

contract CTMRWA001Dividend {

    function setDividendToken(address _dividendToken) external onlyTokenAdmin returns(bool) {
        for(uint256 i=1; i<=this.totalSupply(); i++) {
            if(this.dividendUnclaimedOf(i) > 0) {
                revert("CTMRWA001: Cannot change dividend token address whilst there is unclaimed dividend");
            }
        }

        dividendToken = _dividendToken;

        emit NewDividendToken(_dividendToken, tokenAdmin);
        return(true);
    }

    function changeDividendRate(uint256 _slot, uint256 _dividend) external onlyTokenAdmin returns(bool) {
        require(_slotExists(_slot), "CTMRWA001: in changeDividend, slot does not exist");
        _allSlots[_allSlotsIndex[_slot]].dividendRate = _dividend;

        emit ChangeDividendRate(_slot, _dividend, tokenAdmin);
        return(true);
    }

    function getDividendRateBySlot(uint256 _slot) external view returns(uint256) {
        require(_slotExists(_slot), "CTMRWA001: in getDividendBySlot, slot does not exist");
        return(_allSlots[_allSlotsIndex[_slot]].dividendRate);
    }

    function getDividendByToken(uint256 _tokenId) external view returns(uint256) {
        require(this.requireMinted(_tokenId), "CTMRWA001: TokenId does not exist");
        uint256 slot = slotOf(_tokenId);
        return(_allSlots[_allSlotsIndex[slot]].dividendRate * balanceOf(_tokenId));
    }

    function getTotalDividendBySlot(uint256 _slot) external view returns(uint256) {
        uint256 len = this.tokenSupplyInSlot(_slot);
        uint256 dividendPayable;
        uint256 tokenId;

        uint256 slotRate = this.getDividendRateBySlot(_slot);

        for(uint256 i=0; i<len; i++) {
            tokenId = tokenInSlotByIndex(_slot, i);
            dividendPayable += balanceOf(tokenId)*slotRate;
        }

        return(dividendPayable);
    }

    function getTotalDividend() external view returns(uint256) {
        uint256 nSlots = slotCount();
        uint256 dividendPayable;
        uint256 slot;

        for(uint256 i=0; i<nSlots; i++) {
            slot = slotByIndex(i);
            dividendPayable += this.getTotalDividendBySlot(slot);
        }

        return(dividendPayable);
    }

    function fundDividend(uint256 _dividendPayable) external payable onlyTokenAdmin returns(uint256) {
        require(IERC20(dividendToken).transferFrom(_msgSender(), address(this), _dividendPayable), "CTMRWA001: Did not fund the dividend");
        uint256 unclaimedDividend;
        uint256 tokenId;

        for(uint256 i=0; i<this.totalSupply(); i++) {
            tokenId = tokenByIndex(i);
            unclaimedDividend += incrementDividend(tokenId, this.getDividendByToken(tokenId));
        }

        emit FundDividend(_dividendPayable, unclaimedDividend, dividendToken, _msgSender());

        return(unclaimedDividend);
    }

    function claimDividend(uint256 _tokenId) external returns(bool) {
        require(ownerOf(_tokenId) == _msgSender(), "CTMRWA001: Cannot claim dividend, since not owner");
        uint256 dividend = this.dividendUnclaimedOf(_tokenId);
        decrementDividend(_tokenId, dividend);
        IERC20(dividendToken).transferFrom(address(this), _msgSender(), dividend);

        emit ClaimDividend(_tokenId, dividend, dividendToken);

        return(true);
    }
    
}