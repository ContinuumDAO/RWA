// SPDX-License-Identifier: BSL-1.1

pragma solidity 0.8.27;

import { ICTMRWA1 } from "../core/ICTMRWA1.sol";
import { ICTMRWAMap } from "../shared/ICTMRWAMap.sol";
import { ICTMRWA1X } from "../crosschain/ICTMRWA1X.sol";
import { CTMRWAErrorParam } from "../utils/CTMRWAUtils.sol";
import { ICTMRWAERC20 } from "./ICTMRWAERC20.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title AssetX Multi-chain Semi-Fungible-Token for Real-World-Assets (RWAs)
 * @author @Selqui ContinuumDAO
 *
 * This contract is an ERC20. The required interface functions are directly linked to various
 * functions in CTMRWA1. This contract is deployed by deployERC20() in the contract CTMRWAERC20Deployer
 * which uses CREATE2.
 */
contract CTMRWAERC20 is ICTMRWAERC20, ReentrancyGuard, ERC20 {
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
    string public ctmRwaName;

    /// @dev The symbol of this ERC20
    string ctmRwaSymbol;

    /// @dev The decimals of this ERC20 are the same as for the CTMRWA1
    uint8 ctmRwaDecimals;

    /// @dev The address of the CTMRWAMap contract
    address ctmRwaMap;

    /// @dev The address of the CTMRWA1 contract that called this
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
        RWA_TYPE = _rwaType;
        VERSION = _version;
        slot = _slot;
        string memory slotStr = string.concat("slot ", Strings.toString(slot), "| ");
        ctmRwaName = string.concat(slotStr, _name);
        ctmRwaSymbol = string.concat(_symbol, Strings.toString(slot));
        ctmRwaMap = _ctmRwaMap;

        bool ok;

        (ok, ctmRwaToken) = ICTMRWAMap(ctmRwaMap).getTokenContract(ID, _rwaType, _version);
        if (!ok) {
            revert CTMRWAERC20_InvalidContract(CTMRWAErrorParam.Token);
        }

        if (!ICTMRWA1(ctmRwaToken).slotExists(slot)) {
            revert CTMRWAERC20_NonExistentSlot(slot);
        }

        slotName = ICTMRWA1(ctmRwaToken).slotName(slot);
        ctmRwaDecimals = ICTMRWA1(ctmRwaToken).valueDecimals();
    }

    /**
     * @notice The ERC20 name returns the input name, pre-pended with the slot
     * @return ctmRwaName The name of the ERC20
     */
    function name() public view override(ERC20, ICTMRWAERC20) returns (string memory) {
        return ctmRwaName;
    }

    /**
     * @notice The ERC20 symbol
     * @return symbol The symbol of the ERC20
     */
    function symbol() public view override(ERC20, ICTMRWAERC20) returns (string memory) {
        return ctmRwaSymbol;
    }

    /**
     * @notice The ERC20 decimals. This is not part of the official ERC20 interface, but is added here
     * for convenience
     * @return decimals The decimals of the ERC20
     */
    function decimals() public view override(ERC20, ICTMRWAERC20) returns (uint8) {
        return ctmRwaDecimals;
    }

    /**
     * @notice The ERC20 totalSupply. This is derived from the CTMRWA1 and is the
     * total fungible balance summed over all tokenIds in the slot of this ERC20
     * @return total The total supply of the ERC20
     */
    function totalSupply() public view override(ERC20, IERC20) returns (uint256) {
        uint256 total = ICTMRWA1(ctmRwaToken).totalSupplyInSlot(slot);
        return total;
    }

    /**
     * @notice The ERC20 balanceOf. This is derived from the CTMRWA1 and is the sum of
     * the fungible balances of approved tokenIds in this slot for this _account
     * @param _account The wallet address of the balanceOf being sought
     * @return bal The balance of the _account from approved tokenIds only
     */
    function balanceOf(address _account) public view override(ERC20, IERC20) returns (uint256) {
        // Calculate total balance from all tokenIds owned by the account in this slot
        uint256 totalBalance = 0;
        uint256 tokenCount = ICTMRWA1(ctmRwaToken).balanceOf(_account);
        
        for (uint256 i = 0; i < tokenCount; i++) {
            uint256 tokenId = ICTMRWA1(ctmRwaToken).tokenOfOwnerByIndex(_account, i);
            uint256 tokenSlot = ICTMRWA1(ctmRwaToken).slotOf(tokenId);
            if (tokenSlot == slot) {
                totalBalance += ICTMRWA1(ctmRwaToken).balanceOf(tokenId);
            }
        }
        
        return totalBalance;
    }

    function balanceOfApproved(address _account) public view returns (uint256) {
        // Get the array of approved tokenIds for this owner and slot
        uint256[] memory approvedTokenIds = ICTMRWA1(ctmRwaToken).getErc20Approvals(_account, slot);
        uint256 len = approvedTokenIds.length;
        
        uint256 approvedBalance = 0;
        for (uint256 i = 0; i < len; i++) {
            uint256 tokenId = approvedTokenIds[i];
            // Verify the tokenId is still approved for this ERC20 contract
            if (ICTMRWA1(ctmRwaToken).getApproved(tokenId) == address(this)) {
                approvedBalance += ICTMRWA1(ctmRwaToken).balanceOf(tokenId);
            }
        }
        
        return approvedBalance;
    }

    /**
     * @notice Returns the ERC20 allowance of _spender on behalf of _owner
     * @param _owner The owner of the tokenIds who is granting approval to the spender
     * @param _spender The recipient, who is being granted approval to spend on behalf of _owner
     * @return The allowance of _spender on behalf of _owner
     */
    function allowance(address _owner, address _spender) public view override(ERC20, IERC20) returns (uint256) {
        return super.allowance(_owner, _spender);
    }

    /**
     * @notice Grant approval to a spender to spend a fungible value from the slot
     * @param _spender The wallet address being granted approval to spend value
     * @param _value The fungible value being approved to spend by the spender
     * @return success True if the approval was successful, false otherwise.
     */
    function approve(address _spender, uint256 _value) public override(ERC20, IERC20) returns (bool) {
        _approve(msg.sender, _spender, _value, true);
        return true;
    }

    /**
     * @notice Transfer a fungible value to another wallet from the caller's balance
     * @param _to The recipient of the transfer
     * @param _value The fungible amount being transferred.
     * NOTE The _value is taken from the first tokenId owned by the caller and if this is not
     * sufficient, the balance is taken from the second owned tokenId etc.
     * @return success True if the transfer was successful, false otherwise.
     */
    function transfer(address _to, uint256 _value) public override(ERC20, IERC20) nonReentrant returns (bool) {
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
     * @return success True if the transfer was successful, false otherwise.
     */
    function transferFrom(address _from, address _to, uint256 _value)
        public
        override(ERC20, IERC20)
        nonReentrant
        returns (bool)
    {
        _spendAllowance(_from, msg.sender, _value);
        _transfer(_from, _to, _value);

        return true;
    }

    /// @dev Low level function to approve spending
    function _approve(address _owner, address _spender, uint256 _value, bool _emitEvent) internal override {
        if (_spender == address(0)) {
            revert CTMRWAERC20_IsZeroAddress(CTMRWAErrorParam.Spender);
        }
        super._approve(_owner, _spender, _value, _emitEvent);
    }

    /**
     * @dev Low level function calling transferFrom in CTMRWA1 to adjust the balances
     * of both the _from tokenIds and creating a new tokenId for the _to wallet
     */
    function _update(address _from, address _to, uint256 _value) internal override {
        // Get the array of approved tokenIds for this owner and slot
        uint256[] memory approvedTokenIds = ICTMRWA1(ctmRwaToken).getErc20Approvals(_from, slot);
        uint256 len = approvedTokenIds.length;

        if (len == 0) {
            revert ERC20InsufficientBalance(_from, 0, _value);
        }

        // Calculate the total balance from approved tokenIds only
        uint256 approvedBalance = balanceOfApproved(_from);

        if (approvedBalance < _value) {
            revert ERC20InsufficientBalance(_from, approvedBalance, _value);
        }

        uint256 tokenId;
        uint256 tokenIdBal;
        uint256 valRemaining = _value;

        for (uint256 i = 0; i < len; i++) {
            tokenId = approvedTokenIds[i];
            
            // Verify the tokenId is still approved for this ERC20 contract
            if (ICTMRWA1(ctmRwaToken).getApproved(tokenId) == address(this)) {
                tokenIdBal = ICTMRWA1(ctmRwaToken).balanceOf(tokenId);

                uint256 newTokenId = ICTMRWA1X(ICTMRWA1(ctmRwaToken).ctmRwa1X()).mintFromXForERC20(ID, VERSION, _to, slot, slotName, 0);

                if (tokenIdBal >= valRemaining) {
                    ICTMRWA1(ctmRwaToken).transferFrom(tokenId, newTokenId, valRemaining);
                       ICTMRWA1(ctmRwaToken).clearApprovedValuesFromERC20(tokenId);
                    emit Transfer(_from, _to, _value);
                    return;
                } else {
                    ICTMRWA1(ctmRwaToken).transferFrom(tokenId, newTokenId, tokenIdBal);
                    valRemaining -= tokenIdBal;
                    if (valRemaining == 0) {
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
            if (currentAllowance < _value) {
                revert ERC20InsufficientAllowance(_spender, currentAllowance, _value);
            }
            unchecked {
                _approve(_owner, _spender, currentAllowance - _value, false);
            }
        }
    }
}
