// SPDX-License-Identifier: BSL-1.1

pragma solidity 0.8.27;

import { ICTMRWA } from "./ICTMRWA.sol";
import { Address, Uint } from "../CTMRWAUtils.sol";

/**
 * @title CTMRWA1 Semi-Fungible Token Standard
 * @dev See https://docs.continuumdao.org
 * Note: the ERC-165 identifier for this interface is 0xd5358140.
 */
struct TokenContract {
    string chainIdStr;
    string contractStr;
}

struct SlotData {
    uint256 slot;
    string slotName;
    uint256 dividendRate; // per unit of this slot
    uint256[] slotTokens;
}

interface ITokenContract {
    function tokenContract() external returns (TokenContract[] memory);
    function tokenChainIdStrs() external returns (string[] memory);
}

interface ICTMRWA1 is ICTMRWA {
    event Approval(address from, address to, uint256 tokenId);
    event ApprovalForAll(address owner, address operator, bool approved);
    event Transfer(address from, address to, uint256 tokenId);

    /**
     * @dev MUST emit when value of a token is transferred to another token with the same slot,
     *  including zero value transfers (_value == 0) as well as transfers when tokens are created
     *  (`_fromTokenId` == 0) or destroyed (`_toTokenId` == 0).
     * @param fromTokenId The token id to transfer value from
     * @param toTokenId The token id to transfer value to
     * @param value The transferred value
     */
    event TransferValue(uint256 indexed fromTokenId, uint256 indexed toTokenId, uint256 value);

    /**
     * @dev MUST emits when the approval value of a token is set or changed.
     * @param tokenId The token to approve
     * @param operator The operator to approve for
     * @param value The maximum value that `_operator` is allowed to manage
     */
    event ApprovalValue(uint256 indexed tokenId, address indexed operator, uint256 value);

    /**
     * @dev MUST emit when the slot of a token is set or changed.
     * @param tokenId The token of which slot is set or changed
     * @param oldSlot The previous slot of the token
     * @param newSlot The updated slot of the token
     */
    event SlotChanged(uint256 indexed tokenId, uint256 indexed oldSlot, uint256 indexed newSlot);

    /// @dev Auth errors
    error CTMRWA1_Unauthorized(Address addr, Address unauth); // `addr` cannot be `unauth`
    error CTMRWA1_OnlyAuthorized(Address addr, Address auth); // `addr` must be `auth`

    /// @dev Address errors
    error CTMRWA1_IsZeroAddress(Address);
    error CTMRWA1_NotZeroAddress(Address);

    /// @dev Uint errors
    error CTMRWA1_IsZeroUint(Uint);
    error CTMRWA1_NonZeroUint(Uint);
    error CTMRWA1_LengthMismatch(Uint);
    error CTMRWA1_InsufficientBalance();
    error CTMRWA1_InsufficientAllowance();
    error CTMRWA1_OutOfBounds();
    error CTMRWA1_NameTooLong();

    /// @dev Existence errors
    error CTMRWA1_IDNonExistent(uint256 tokenId);
    error CTMRWA1_IDExists(uint256 _tokenId);
    error CTMRWA1_InvalidSlot(uint256 _slot);

    /// @dev Transfer errors
    error CTMRWA1_ReceiverRejected();
    error CTMRWA1_WhiteListRejected(address _addr);

    function ID() external view returns (uint256);
    function tokenAdmin() external returns (address);
    function pause() external;
    function unpause() external;
    function isPaused() external view returns (bool);
    function setOverrideWallet(address overrideWallet) external;
    function overrideWallet() external returns (address);
    function ctmRwa1X() external returns (address);
    function changeAdmin(address _admin) external returns (bool);
    function attachId(uint256 nextID, address tokenAdmin) external returns (bool);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function valueDecimals() external view returns (uint8);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function getTokenInfo(uint256 tokenId)
        external
        view
        returns (uint256 id, uint256 bal, address owner, uint256 slot, string memory slotName, address admin);
    function slotNameOf(uint256 _tokenId) external view returns (string memory);
    function balanceOf(uint256 _tokenId) external view returns (uint256);
    function balanceOf(address owner) external view returns (uint256);
    function balanceOf(address owner, uint256 slot) external view returns (uint256);

    function baseURI() external view returns (string memory);
    function getErc20(uint256 _slot) external view returns (address);

    function tokenOfOwnerByIndex(address owner, uint256 index_) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function tokenInSlotByIndex(uint256 slot, uint256 index_) external view returns (uint256);
    function tokenSupplyInSlot(uint256 slot) external view returns (uint256);
    function tokenByIndex(uint256 index_) external view returns (uint256);
    function exists(uint256 tokenId) external view returns (bool);

    function createSlotX(uint256 _slot, string memory _slotName) external;
    function getAllSlots() external view returns (uint256[] memory, string[] memory);
    function getSlotInfoByIndex(uint256 _indx) external view returns (SlotData memory);
    function slotCount() external view returns (uint256);
    function slotExists(uint256 slot_) external view returns (bool);
    function slotName(uint256 _slot) external view returns (string memory);
    function slotByIndex(uint256 index_) external view returns (uint256);
    function initializeSlotData(uint256[] memory _slotNumbers, string[] memory _slotNames) external;
    function totalSupplyInSlot(uint256 _slot) external view returns (uint256);

    function approveFromX(address to_, uint256 tokenId_) external;
    function clearApprovedValues(uint256 tokenId_) external;
    function clearApprovedValuesErc20(uint256 tokenId_) external;
    function removeTokenFromOwnerEnumeration(address from, uint256 tokenId) external;

    function burn(uint256 tokenId) external;

    function burnValueX(uint256 fromTokenId, uint256 value) external returns (bool);
    function mintValueX(uint256 toTokenId, uint256 slot, uint256 value) external returns (bool);
    function mintFromX(address to, uint256 slot, string memory slotName, uint256 value)
        external
        returns (uint256 tokenId);
    function mintFromX(address to, uint256 tokenId, uint256 slot, string memory slotName, uint256 value) external;

    function spendAllowance(address operator, uint256 tokenId, uint256 value) external;
    function isApprovedOrOwner(address operator, uint256 tokenId) external view returns (bool);
    function getApproved(uint256 tokenId) external view returns (address);

    function dividendAddr() external view returns (address);
    function storageAddr() external view returns (address);
    function getDividendRateBySlot(uint256 _slot) external view returns (uint256);
    function changeDividendRate(uint256 slot, uint256 dividend) external returns (bool);

    function createOriginalTokenId() external returns (uint256);

    function deployErc20(uint256 _slot, string memory _erc20Name, address _feeToken) external;

    function slotOf(uint256 tokenId) external view returns (uint256);

    function approve(uint256 tokenId, address operator, uint256 value) external payable;

    function approve(address to, uint256 tokenId) external;

    function allowance(uint256 tokenId, address operator) external view returns (uint256);

    function transferFrom(uint256 fromTokenId, uint256 toTokenId, uint256 value) external returns (address);

    function transferFrom(uint256 fromTokenId, address to, uint256 value) external returns (uint256);

    function transferFrom(address fromAddr, address toAddr, uint256 fromTokenId) external;
    function forceTransfer(address from, address to, uint256 tokenId) external returns (bool);
}
