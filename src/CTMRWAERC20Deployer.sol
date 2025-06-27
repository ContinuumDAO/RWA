// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.19;

import {Context} from "@openzeppelin/contracts/utils/Context.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import {ICTMRWA001} from "./interfaces/ICTMRWA001.sol";
import {ICTMRWA001X} from "./interfaces/ICTMRWA001X.sol";
import {ICTMRWAMap} from "./interfaces/ICTMRWAMap.sol";
import {IFeeManager, FeeType, IERC20Extended} from "./interfaces/IFeeManager.sol";

/**
 * @title AssetX Multi-chain Semi-Fungible-Token for Real-World-Assets (RWAs)
 * @author @Selqui ContinuumDAO
 *
 * @notice This contract manages the deployment of an ERC20 token that is an interface to the 
 * underlying CTMRWA001 token. It allows the tokenAdmin (Issuer) to deploy a unique ERC20 representing
 * a single Asset Class (slot).
 *
 * Whereas anyone could call deployERC20() in this contract, there is no point, since it has to be
 * called by CTMRWA001 to be valid and linked to the CTMRWA001.
 *
 * This contract is only deployed ONCE on each chain and manages all CTMRWA001Dividend contract 
 * deployments.
 */

contract CTMRWAERC20Deployer is ReentrancyGuard, Context {
    using Strings for *;

    /// @dev Address of the CTMRWAMap contract
    address public ctmRwaMap;

    /// @dev Address of the FeeManager contract
    address public feeManager;

    /// @dev String representation of the local chainID
    string cIDStr;

    constructor(
        address _ctmRwaMap,
        address _feeManager
    ) {
        require(_ctmRwaMap != address(0), "CTMRWAERC20: ctmRwaMap set to 0");
        require(_feeManager != address(0), "CTMRWAERC20: feeManager set to 0");

        ctmRwaMap = _ctmRwaMap;
        feeManager = _feeManager;

        cIDStr = block.chainid.toString();
    }

    /**
     * @notice Deploy a new ERC20 contract linked to a CTMRWA001 with ID, for ONE slot
     * @param _ID The unique ID number for the CTMRWA001
     * @param _slot The slot number selected for this ERC20.
     * @param _name The name for the ERC20. This will be pre-pended with "slot X | ", where X is
     * the slot number
     * @param  _symbol The symbol to use for the ERC20
     * @param  _feeToken The fee token address to pay. The contract address must be 
     * in the return from feeTokenList() in FeeManager
     * NOTE The resulting ERC20 is only valid if this function is called from a CTMRWA001 contract
     * otherwise it will not be linked to it.
     */
    function deployERC20(
        uint256 _ID,
        uint256 _rwaType,
        uint256 _version,
        uint256 _slot,
        string memory _name, 
        string memory _symbol, 
        address _feeToken
    ) external returns(address) {

        (bool ok, address ctmRwaToken) = ICTMRWAMap(ctmRwaMap).getTokenContract(_ID, _rwaType, _version);
        require(ok, "CTMRWAERC20: the ID does not link to a valid CTMRWA001");
        require(_msgSender() == ctmRwaToken, "CTMRWAERC20: Deployer is not CTMRWA001");

        _payFee(FeeType.ERC20, _feeToken);

        bytes32 salt = keccak256(abi.encode(_ID, _rwaType, _version, _slot));
        
        CTMRWAERC20 newErc20 = new CTMRWAERC20 {
            salt: salt 
        }(
            _ID,
            _rwaType,
            _version,
            _slot,
            _name, 
            _symbol,
            ctmRwaMap
        );

        return(address(newErc20));
    }

    /// @dev Pay the fee for deploying the ERC20
    function _payFee(
        FeeType _feeType, 
        address _feeToken
    ) internal nonReentrant returns(bool) {
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

    /// @dev Convert an individual string to an array with a single value
    function _stringToArray(string memory _string) internal pure returns(string[] memory) {
        string[] memory strArray = new string[](1);
        strArray[0] = _string;
        return(strArray);
    }
}

/**
 * This contract is an ERC20. The required interface functions are directly linked to various
 * functions in CTMRWA001. This contract is deployed by deployERC20() in the contract CTMRWAERC20Deployer
 * which uses CREATE2. 
 */
contract CTMRWAERC20 is ReentrancyGuard, Context, ERC20 {

    /// @dev The ID of the CTMRWA001 that created this ERC20 is stored here
    uint256 public ID;

    /// @dev rwaType is the type of RWA token contract, e.g. CTMRWA001 has rwaType == 1
    uint256 rwaType;

    /// @dev version is the version of the rwaType
    uint256 version;

    /// @dev The slot number that this ERC20 relates to. Each ERC20 relates to ONE slot
    uint256 public slot;

    /// @dev The corresponding slot name
    string slotName;

    /// @dev The name of this ERC20 
    string ctmRwaName;

    /// @dev The symbol of this ERC20
    string ctmRwaSymbol;

    /// @dev The decimals of this ERC20 are the same as for the CTMRWA001
    uint8 ctmRwaDecimals;

    /// @dev The address of the CTMRWAMap contract
    address ctmRwaMap;

    /// @dev The address of the CTMRWA001 contract that called this
    address ctmRwaToken;

    constructor(
        uint256 _ID,
        uint256 _rwaType,
        uint256 _version,
        uint256 _slot,
        string memory _name, 
        string memory _symbol,
        address _ctmRwaMap
    ) ERC20(_name, _symbol) {
        ID = _ID;
        rwaType = _rwaType;
        version = _version;
        slot = _slot;
        string memory slotStr = string.concat("slot ", Strings.toString(slot), "| ");
        ctmRwaName = string.concat(slotStr, _name);
        ctmRwaSymbol = _symbol;
        ctmRwaMap = _ctmRwaMap;

        bool ok;

        (ok, ctmRwaToken) = ICTMRWAMap(ctmRwaMap).getTokenContract(ID, rwaType, version);
        require(ok, "CTMRWAERC20: There is no CTMRWA001 contract backing this ID");

        require(ICTMRWA001(ctmRwaToken).slotExists(slot), "CTMRWAERC20: Slot does not exist");

        slotName = ICTMRWA001(ctmRwaToken).slotName(slot);
        ctmRwaDecimals = ICTMRWA001(ctmRwaToken).valueDecimals();
    }

    /**
     * @notice The ERC20 name returns the input name, pre-pended with the slot 
     */
    function name() public view override returns (string memory) {
        return ctmRwaName;
    }

    /**
     * @notice The ERC20 symbol
     */
    function symbol() public view override returns (string memory) {
        return ctmRwaSymbol;
    }

    /**
     * @notice The ERC20 decimals. This is not part of the official ERC20 interface, but is added here 
     * for convenience
     */
    function decimals() public view override returns (uint8) {
        return ctmRwaDecimals;
    }

    /**
     * @notice The ERC20 totalSupply. This is derived from the CTMRWA001 and is the 
     * total fungible balance summed over all tokenIds in the slot of this ERC20
     */
    function totalSupply() public view override returns (uint256) {

        uint256 total = ICTMRWA001(ctmRwaToken).totalSupplyInSlot(slot);
        return total;
    }

    /**
     * @notice The ERC20 balanceOf. This is derived from the CTMRWA001 and is the sum of
     * the fungible balances of all tokenIds in this slot for this _account
     * @param _account The wallet address of the balanceOf being sought
     */
    function balanceOf(address _account) public view override returns (uint256) {
        uint256 bal = ICTMRWA001(ctmRwaToken).balanceOf(_account, slot);
        return (bal);
    }

    /**
     * @notice Returns the ERC20 allowance of _spender on behalf of _owner
     * @param _owner The owner of the tokenIds who is granting approval to the spender
     * @param _spender The recipient, who is being granted approval to spend on behalf of _owner
     */
    function allowance(address _owner, address _spender) public view override returns (uint256) {
        return super.allowance(_owner, _spender);
    }

    /**
     * @notice Grant approval to a spender to spend a fungible value from the slot
     * @param _spender The wallet address being granted approval to spend value
     * @param _value The fungible value being approved to spend by the spender
     */
    function approve(address _spender, uint256 _value) public override returns (bool) {
        _approve(_msgSender(), _spender, _value, true);
        return true;
    }

    /**
     * @notice Transfer a fungible value to another wallet from the caller's balance
     * @param _to The recipient of the transfer
     * @param _value The fungible amount being transferred.
     * NOTE The _value is taken from the first tokenId owned by the caller and if this is not
     * sufficient, the balance is taken from the second owned tokenId etc.
     */
    function transfer(address _to, uint256 _value) public override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, _to, _value);
        return true;
    }

    /**
     * @notice The caller transfers _value from the wallet _from to the wallet _to.
     * @param _from The wallet being debited
     * @param _to The wallet being credited
     * @param _value The fungible amount being transfered
     * NOTE The caller must have sufficient allowance granted to it by the _from wallet
     * NOTE The _value is taken from the first tokenId owned by the caller and if this is not
     * sufficient, the balance is taken from the second owned tokenId etc.
     */
    function transferFrom(address _from, address _to, uint256 _value) public override returns (bool) {
        _spendAllowance(_from, _msgSender(), _value);
        _transfer(_from, _to, _value);

        return true;
    }

    /// @dev Low level function to approve spending
    function _approve(address _owner, address _spender, uint256 _value, bool _emitEvent) internal override {
        require(_spender != address(0), "CTMRWAERC20: spender is zero address");
        super._approve(_owner, _spender, _value, _emitEvent);
    }


    /**
     * @dev Low level function calling transferFrom in CTMRWA001 to adjust the balances
     * of both the _from tokenIds and creating a new tokenId for the _to wallet
     */
    function _update(address _from, address _to, uint256 _value) internal override {
        uint256 fromBalance = ICTMRWA001(ctmRwaToken).balanceOf(_from, slot);

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
                    ICTMRWA001(ctmRwaToken).clearApprovedValuesErc20(tokenId);
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

    /// @dev Low level function granting approval IF the spender has enough allowance from _owner
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
