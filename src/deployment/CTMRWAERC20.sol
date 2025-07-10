// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.22;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

import { ICTMRWA1 } from "../core/ICTMRWA1.sol";
import { ICTMRWAMap } from "../shared/ICTMRWAMap.sol";

/**
 * This contract is an ERC20. The required interface functions are directly linked to various
 * functions in CTMRWA1. This contract is deployed by deployERC20() in the contract CTMRWAERC20Deployer
 * which uses CREATE2.
 */
contract CTMRWAERC20 is ReentrancyGuard, ERC20 {
    using Strings for string;

    /// @dev The ID of the CTMRWA1 that created this ERC20 is stored here
    uint256 public ID;

    /// @dev rwaType is the type of RWA token contract, e.g. CTMRWA1 has rwaType == 1
    uint256 public immutable RWA_TYPE;

    /// @dev version is the version of the rwaType
    uint256 public immutable VERSION;

    /// @dev The slot number that this ERC20 relates to. Each ERC20 relates to ONE slot
    uint256 public slot;

    /// @dev The corresponding slot name
    string slotName;

    /// @dev The name of this ERC20
    string ctmRwaName;

    /// @dev The symbol of this ERC20
    string ctmRwaSymbol;

    /// @dev The decimals of this ERC20 are the same as for the CTMRWA1
    uint8 ctmRwaDecimals;

    /// @dev The address of the CTMRWAMap contract
    address ctmRwaMap;

    /// @dev The address of the CTMRWA1 contract that called this
    address ctmRwaToken;

    /// @dev Max number of tokens to iterate through for balance transfers (block gas limit check)
    uint256 constant MAX_TOKENS = 100;

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
        RWA_TYPE = _rwaType;
        VERSION = _version;
        slot = _slot;
        string memory slotStr = string.concat("slot ", Strings.toString(slot), "| ");
        ctmRwaName = string.concat(slotStr, _name);
        ctmRwaSymbol = _symbol;
        ctmRwaMap = _ctmRwaMap;

        bool ok;

        (ok, ctmRwaToken) = ICTMRWAMap(ctmRwaMap).getTokenContract(ID, _rwaType, _version);
        require(ok, "CTMRWAERC20: There is no CTMRWA1 contract backing this ID");

        require(ICTMRWA1(ctmRwaToken).slotExists(slot), "CTMRWAERC20: Slot does not exist");

        slotName = ICTMRWA1(ctmRwaToken).slotName(slot);
        ctmRwaDecimals = ICTMRWA1(ctmRwaToken).valueDecimals();
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
     * @notice The ERC20 totalSupply. This is derived from the CTMRWA1 and is the
     * total fungible balance summed over all tokenIds in the slot of this ERC20
     */
    function totalSupply() public view override returns (uint256) {
        uint256 total = ICTMRWA1(ctmRwaToken).totalSupplyInSlot(slot);
        return total;
    }

    /**
     * @notice The ERC20 balanceOf. This is derived from the CTMRWA1 and is the sum of
     * the fungible balances of all tokenIds in this slot for this _account
     * @param _account The wallet address of the balanceOf being sought
     */
    function balanceOf(address _account) public view override returns (uint256) {
        uint256 bal = ICTMRWA1(ctmRwaToken).balanceOf(_account, slot);
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
        _approve(msg.sender, _spender, _value, true);
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
        address owner = msg.sender;
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
        _spendAllowance(_from, msg.sender, _value);
        _transfer(_from, _to, _value);

        return true;
    }

    /// @dev Low level function to approve spending
    function _approve(address _owner, address _spender, uint256 _value, bool _emitEvent) internal override {
        require(_spender != address(0), "CTMRWAERC20: spender is zero address");
        super._approve(_owner, _spender, _value, _emitEvent);
    }

    /**
     * @dev Low level function calling transferFrom in CTMRWA1 to adjust the balances
     * of both the _from tokenIds and creating a new tokenId for the _to wallet
     */
    function _update(address _from, address _to, uint256 _value) internal override {
        uint256 fromBalance = ICTMRWA1(ctmRwaToken).balanceOf(_from, slot);

        if (fromBalance < _value) {
            revert ERC20InsufficientBalance(_from, fromBalance, _value);
        }

        uint256 tokenId;
        uint256 tokenIdBal;
        uint256 valRemaining = _value;

        uint256 len = ICTMRWA1(ctmRwaToken).balanceOf(_from);

        for (uint256 i = 0; i < len; i++) {
            tokenId = ICTMRWA1(ctmRwaToken).tokenOfOwnerByIndex(_from, i);

            if (ICTMRWA1(ctmRwaToken).slotOf(tokenId) == slot) {
                tokenIdBal = ICTMRWA1(ctmRwaToken).balanceOf(tokenId);

                uint256 newTokenId = ICTMRWA1(ctmRwaToken).mintFromX(_to, slot, slotName, 0);

                if (tokenIdBal >= valRemaining) {
                    ICTMRWA1(ctmRwaToken).approve(tokenId, _to, valRemaining);
                    ICTMRWA1(ctmRwaToken).transferFrom(tokenId, newTokenId, valRemaining);
                    ICTMRWA1(ctmRwaToken).clearApprovedValuesErc20(tokenId);
                    emit Transfer(_from, _to, _value);
                    return;
                } else if (i < MAX_TOKENS) {
                    ICTMRWA1(ctmRwaToken).approve(tokenId, _to, tokenIdBal);
                    ICTMRWA1(ctmRwaToken).transferFrom(tokenId, newTokenId, tokenIdBal);
                    valRemaining -= tokenIdBal;
                    if (valRemaining == 0) {
                        emit Transfer(_from, _to, _value);
                        return;
                    }
                } else {
                    revert("CTMRWAERC20: Exceeded max number of tokens 100");
                }
            }
        }
    }

    /// @dev Low level function granting approval IF the spender has enough allowance from _owner
    function _spendAllowance(address _owner, address _spender, uint256 _value) internal override {
        uint256 currentAllowance = allowance(_owner, _spender);

        if (currentAllowance != type(uint256).max) {
            if (currentAllowance < _value) {
                revert ERC20InsufficientAllowance(_spender, currentAllowance, _value);
            }
            unchecked {
                _approve(_owner, _spender, currentAllowance - _value, false);
            }
        }
    }
}
