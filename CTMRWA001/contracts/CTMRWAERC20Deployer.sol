// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.19;

import {Context} from "@openzeppelin/contracts/utils/Context.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {ICTMRWA001} from "./interfaces/ICTMRWA001.sol";
import {ICTMRWA001X} from "./interfaces/ICTMRWA001X.sol";
import {ICTMRWAMap} from "./interfaces/ICTMRWAMap.sol";
import {IFeeManager, FeeType, IERC20Extended} from "./interfaces/IFeeManager.sol";

contract CTMRWAERC20Deployer is Context {
    using Strings for *;

    address public ctmRwa001X;
    address public ctmRwaMap;
    address public feeManager;
    string cIDStr;

    constructor(
        address _ctmRwa001X,
        address _ctmRwaMap,
        address _feeManager
    ) {
        ctmRwa001X = _ctmRwa001X;
        ctmRwaMap = _ctmRwaMap;
        feeManager = _feeManager;

         cIDStr = block.chainid.toString();
    }

    

    function deployERC20(
        uint256 _ID,
        uint256 _slot,
        string memory _name, 
        string memory _symbol, 
        uint8 _decimals,
        address _feeToken
    ) external returns(address) {

        _payFee(FeeType.ERC20, _feeToken);
        
        CTMRWAERC20 newErc20 = new CTMRWAERC20(
            _ID,
            _slot,
            _name, 
            _symbol,
            _decimals,
            ctmRwa001X,
            ctmRwaMap
        );

        return(address(newErc20));
        
    }

    function _payFee(
        FeeType _feeType, 
        address _feeToken
    ) internal returns(bool) {
        string memory feeTokenStr = _feeToken.toHexString();
        uint256 fee = IFeeManager(feeManager).getXChainFee(_stringToArray(cIDStr), false, _feeType, feeTokenStr);
        
        // TODO Remove hardcoded multiplier 10**2

        if(fee>0) {
            uint256 feeWei = fee*10**(IERC20Extended(_feeToken).decimals()-2);

            IERC20(_feeToken).transferFrom(_msgSender(), address(this), feeWei);
            
            IERC20(_feeToken).approve(feeManager, feeWei);
            IFeeManager(feeManager).payFee(feeWei, feeTokenStr);
        }
        return(true);
    }

    function _stringToArray(string memory _string) internal pure returns(string[] memory) {
        string[] memory strArray = new string[](1);
        strArray[0] = _string;
        return(strArray);
    }
}

contract CTMRWAERC20 is Context, ERC20 {

    uint256 public ID;
    uint256 public slot;
    string slotName;
    string ctmRwaName;
    string ctmRwaSymbol;
    uint8 ctmRwaDecimals;
    address ctmRwa001X;
    address ctmRwaMap;
    address ctmRwaToken;
    uint256 rwaType = 1;
    uint256 version = 1;

    constructor(
        uint256 _ID,
        uint256 _slot,
        string memory _name, 
        string memory _symbol,
        uint8 _decimals,
        address _ctmRwa001X,
        address _ctmRwaMap
    ) ERC20(_name, _symbol) {
        ID = _ID;
        slot = _slot;
        string memory slotStr = string.concat("slot ", Strings.toString(slot), "| ");
        ctmRwaName = string.concat(slotStr, _name);
        ctmRwaSymbol = _symbol;
        ctmRwaDecimals = _decimals;
        ctmRwa001X = _ctmRwa001X;
        ctmRwaMap = _ctmRwaMap;

        bool ok;

        (ok, ctmRwaToken) = ICTMRWAMap(ctmRwaMap).getTokenContract(ID, rwaType, version);
        require(ok, "CTMRWAERC20: There is no CTMRWA001 contract backing this ID");

        require(ICTMRWA001(ctmRwaToken).slotExists(slot), "CTMRWAERC20: Slot does not exist");

        slotName = ICTMRWA001(ctmRwaToken).slotName(slot);
    }

    function name() public view override returns (string memory) {
        return ctmRwaName;
    }

     function symbol() public view override returns (string memory) {
        return ctmRwaSymbol;
    }

    function decimals() public view override returns (uint8) {
        return ctmRwaDecimals;
    }

    function totalSupply() public view override returns (uint256) {

        uint256 total;
        uint256 tokenId;

        uint256 len = ICTMRWA001(ctmRwaToken).tokenSupplyInSlot(slot);

        for(uint256 i=0; i<len; i++) {
            tokenId = ICTMRWA001(ctmRwaToken).tokenInSlotByIndex(slot, i);
            total += ICTMRWA001(ctmRwaToken).balanceOf(tokenId);
        }

        return total;
    }

    function balanceOf(address _account) public view override returns (uint256) {
        return _balance(_account);
    }

    function allowance(address _owner, address _spender) public view override returns (uint256) {
        return super.allowance(_owner, _spender);
    }

    function approve(address _spender, uint256 _value) public override returns (bool) {
        _approve(_msgSender(), _spender, _value, true);
        return true;
    }

    function transfer(address _to, uint256 _value) public override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public override returns (bool) {
        _spendAllowance(_from, _msgSender(), _value);
        _transfer(_from, _to, _value);

        return true;
    }

    function _approve(address _owner, address _spender, uint256 _value, bool _emitEvent) internal override {
        super._approve(_owner, _spender, _value, _emitEvent);
    }


    function _balance(address _account) internal view returns(uint256) {
        uint256 balance;
        uint256 tokenId;

        uint256 len = ICTMRWA001(ctmRwaToken).balanceOf(_account);

        for(uint256 i=0; i<len; i++) {
            tokenId = ICTMRWA001(ctmRwaToken).tokenOfOwnerByIndex(_account, i);
            if(ICTMRWA001(ctmRwaToken).slotOf(tokenId) == slot) {
                balance += ICTMRWA001(ctmRwaToken).balanceOf(tokenId);
            }
        }

        return balance;
    }

    function _update(address _from, address _to, uint256 _value) internal override {
        uint256 fromBalance = _balance(_from);
        if (fromBalance < _value) {
            revert ERC20InsufficientBalance(_from, fromBalance, _value);
        }

        uint256 tokenId;
        uint256 tokenIdBal;
        uint256 valRemaining = _value;

        uint256 len = ICTMRWA001(ctmRwaToken).balanceOf(_from);

        for(uint256 i=0; i<len; i++) {
            tokenId = ICTMRWA001(ctmRwaToken).tokenOfOwnerByIndex(_from, i);

            if(ICTMRWA001(ctmRwaToken).slotOf(tokenId) == slot) {
                tokenIdBal = ICTMRWA001(ctmRwaToken).balanceOf(tokenId);

                uint256 newTokenId = ICTMRWA001(ctmRwaToken).mintFromX(_to, slot, slotName, 0);

                if(tokenIdBal >= valRemaining) {
                    ICTMRWA001(ctmRwaToken).approve(tokenId, _to, valRemaining);
                    ICTMRWA001(ctmRwaToken).transferFrom(tokenId, newTokenId, valRemaining);
                    ICTMRWA001(ctmRwaToken).clearApprovedValues(tokenId);
                    emit Transfer(_from, _to, _value);
                    return;
                } else {
                    ICTMRWA001(ctmRwaToken).approve(tokenId, _to, tokenIdBal);
                    ICTMRWA001(ctmRwaToken).transferFrom(tokenId, newTokenId, tokenIdBal);
                    valRemaining -= tokenIdBal;
                    if(valRemaining == 0) {
                        emit Transfer(_from, _to, _value);
                        return;
                    }
                }
            }
        }
    }

    function _spendAllowance(address _owner, address _spender, uint256 _value) internal override {
        uint256 currentAllowance = allowance(_owner, _spender);
        
        if (currentAllowance != type(uint256).max) {
            if(currentAllowance < _value) {
                revert ERC20InsufficientAllowance(_spender, currentAllowance, _value);
            }
            unchecked {
                _approve(_owner, _spender, currentAllowance - _value, false);
            }
        }
    }

}
