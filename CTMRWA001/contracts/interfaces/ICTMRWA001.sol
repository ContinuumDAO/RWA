// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {ICTMRWA001SlotApprovable} from "../extensions/ICTMRWA001SlotApprovable.sol";

/**
 * @title CTMRWA001 Semi-Fungible Token Standard
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
    uint256 dividendRate;  // per unit of this slot
    uint256[] slotTokens;
}

interface ITokenContract {
    function tokenContract() external returns(TokenContract[] memory);
    function tokenChainIdStrs() external returns(string[] memory);
}

interface ICTMRWA001 is ICTMRWA001SlotApprovable {

    function ID() external view returns(uint256);
    function tokenAdmin() external returns(address);
    function rwaType() external returns(uint256);
    function version() external returns(uint256);
    function ctmRwa001X() external returns(address);
    function changeAdmin(address _admin) external returns(bool);
    function attachId(uint256 nextID, address tokenAdmin) external returns(bool);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function valueDecimals() external view returns (uint8);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function getTokenInfo(uint256 tokenId) external view returns(
        uint256 id,
        uint256 bal,
        address owner,
        uint256 slot,
        string memory slotName,
        address admin
    );
    function slotNameOf(uint256 _tokenId) external view returns(string memory);
    function balanceOf(uint256 _tokenId) external view returns (uint256);
   
    function baseURI() external view returns(string memory);
    function getErc20(uint256 _slot) external view returns(address);
    
    function balanceOf(address user) external view returns (uint256);
    // function dividendUnclaimedOf(uint256 tokenId) external view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index_) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function tokenInSlotByIndex(uint256 slot, uint256 index_) external view returns (uint256);
    function tokenSupplyInSlot(uint256 slot) external view returns(uint256);
    function tokenByIndex(uint256 index_) external view returns (uint256);

    function createSlotX(uint256 _slot, string memory _slotName) external;
    function getAllSlots() external view returns(uint256[] memory, string[] memory);
    function getSlotInfoByIndex(uint256 _indx) external view returns(SlotData memory);
    function slotCount() external view returns (uint256);
    function slotExists(uint256 slot_) external view returns (bool);
    function slotName(uint256 _slot) external view returns (string memory);
    function slotByIndex(uint256 index_) external view returns (uint256);
    function initializeSlotData(uint256[] memory _slotNumbers, string[] memory _slotNames) external;
    function totalSupplyInSlot(uint256 _slot) external view returns (uint256);
   

    function approveFromX(address to_, uint256 tokenId_) external;
    function clearApprovedValues(uint256 tokenId_) external;
    function setApprovalForSlot(
        address owner,
        uint256 slot,
        address operator,
        bool approved
    ) external;
    function removeTokenFromOwnerEnumeration(address from, uint256 tokenId) external;

    function burn(uint256 tokenId) external;

    function burnValueX(uint256 fromTokenId, uint256 value) external returns(bool);
    function mintValueX(uint256 toTokenId, uint256 slot, uint256 value) external returns(bool);
    function mintFromX(address to, uint256 slot, string memory slotName, uint256 value) external returns (uint256 tokenId);
    function mintFromX(address to, uint256 tokenId, uint256 slot, string memory slotName, uint256 value) external;

    function spendAllowance(address operator, uint256 tokenId, uint256 value) external;
    function requireMinted(uint256 tokenId) external view returns(bool);
    function isApprovedOrOwner(address operator, uint256 tokenId) external view returns(bool);
    function getApproved(uint256 tokenId) external view returns (address);
    // function setApprovalForAll(address operator_, bool approved_) external;

   
    function dividendAddr() external view returns(address);
    function storageAddr() external view returns(address);
    function getDividendRateBySlot(uint256 _slot) external view returns(uint256);
    function changeDividendRate(uint256 slot, uint256 dividend) external returns(bool);
    // function incrementDividend(uint256 tokenId, uint256 dividend) external returns(uint256);
    // function decrementDividend(uint256 tokenId, uint256 dividend) external returns(uint256);

    function createOriginalTokenId() external returns(uint256);

    function deployErc20(
        uint256 _slot,
        string memory _erc20Name,
        address _feeToken
    ) external;


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

    /**
     * @notice Get the number of decimals the token uses for value - e.g. 6, means the user
     *  representation of the value of a token can be calculated by dividing it by 1,000,000.
     *  Considering the compatibility with third-party wallets, this function is defined as
     *  `valueDecimals()` instead of `decimals()` to avoid conflict with ERC20 tokens.
     * @return The number of decimals for value
     */

    /**
     * @notice Get the value of a token.
     * @param tokenId The token for which to query the balance
     * @return The value of `_tokenId`
     */

    /**
     * @notice Get the slot of a token.
     * @param tokenId The identifier for a token
     * @return The slot of the token
     */
    function slotOf(uint256 tokenId) external view returns (uint256);

    /**
     * @notice Allow an operator to manage the value of a token, up to the `_value` amount.
     * @dev MUST revert unless caller is the current owner, an authorized operator, or the approved
     *  address for `_tokenId`.
     *  MUST emit ApprovalValue event.
     * @param tokenId The token to approve
     * @param operator The operator to be approved
     * @param value The maximum value of `_toTokenId` that `_operator` is allowed to manage
     */
    function approve(
        uint256 tokenId,
        address operator,
        uint256 value
    ) external payable;

    function approve(address to, uint256 tokenId) external;

    /**
     * @notice Get the maximum value of a token that an operator is allowed to manage.
     * @param tokenId The token for which to query the allowance
     * @param operator The address of an operator
     * @return The current approval value of `_tokenId` that `_operator` is allowed to manage
     */
    function allowance(uint256 tokenId, address operator) external view returns (uint256);

    /**
     * @notice Transfer value from a specified token to another specified token with the same slot.
     * @dev Caller MUST be the current owner, an authorized operator or an operator who has been
     *  approved the whole `_fromTokenId` or part of it.
     *  MUST revert if `_fromTokenId` or `_toTokenId` is zero token id or does not exist.
     *  MUST revert if slots of `_fromTokenId` and `_toTokenId` do not match.
     *  MUST revert if `_value` exceeds the balance of `_fromTokenId` or its allowance to the
     *  operator.
     *  MUST emit `TransferValue` event.
     * @param fromTokenId The token to transfer value from
     * @param toTokenId The token to transfer value to
     * @param value The transferred value
     */
    function transferFrom(
        uint256 fromTokenId,
        uint256 toTokenId,
        uint256 value
    ) external returns(address);

    /**
     * @notice Transfer value from a specified token to an address. The caller should confirm that
     *  `_to` is capable of receiving CTMRWA001 tokens.
     * @dev This function MUST create a new CTMRWA001 token with the same slot for `_to` to receive
     *  the transferred value.
     *  MUST revert if `_fromTokenId` is zero token id or does not exist.
     *  MUST revert if `_to` is zero address.
     *  MUST revert if `_value` exceeds the balance of `_fromTokenId` or its allowance to the
     *  operator.
     *  MUST emit `Transfer` and `TransferValue` events.
     * @param fromTokenId The token to transfer value from
     * @param to The address to transfer value to
     * @param value The transferred value
     * @return ID of the new token created for `_to` which receives the transferred value
     */
    function transferFrom(
        uint256 fromTokenId,
        address to,
        uint256 value
    ) external returns (uint256);

    function transferFrom(address fromAddr, address toAddr,  uint256 fromTokenId) external;
    
}

