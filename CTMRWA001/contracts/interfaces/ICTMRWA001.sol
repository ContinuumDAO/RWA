// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

// import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
// import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
//import {ICTMRWA001Metadata} from "../extensions/ICTMRWA001Metadata.sol";
import {ICTMRWA001SlotEnumerable} from "../extensions/ICTMRWA001SlotEnumerable.sol";
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

// SLOT ENUMERABLE
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

interface ICTMRWA001 is ICTMRWA001SlotEnumerable, ICTMRWA001SlotApprovable {

    function ID() external view returns(uint256);
    function tokenAdmin() external returns(address);
    function ctmRwa001X() external returns(address);
    function changeAdmin(address _admin) external returns(bool);
    function attachId(uint256 nextID, address tokenAdmin) external returns(bool);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function valueDecimals() external view returns (uint8);
    
    function getTokenInfo(uint256 tokenId_) external view returns(uint256 id,uint256 bal,address owner,uint256 slot, string memory slotName);
    function slotNameOf(uint256 _tokenId) external view returns(string memory);
    function balanceOf(uint256 _tokenId) external view returns (uint256);
   
    function baseURI() external view returns(string memory);
    
    function balanceOf(address user) external view returns (uint256);
    function dividendUnclaimedOf(uint256 tokenId) external view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index_) external view returns (uint256);
    function tokenInSlotByIndex(uint256 slot, uint256 index_) external view returns (uint256);
    function tokenSupplyInSlot(uint256 slot) external view returns(uint256);
    function totalSupplyInSlot(uint256 _slot) external view returns (uint256);

    function createSlotX(uint256 _slot, string memory _slotName) external;
    function getAllSlots() external view returns(SlotData[] memory);
    function slotCount() external view returns (uint256);
    function slotExists(uint256 slot_) external view returns (bool);
    function slotName(uint256 _slot) external view returns (string memory);
    function slotByIndex(uint256 index_) external view returns (uint256);
    function setAllSlotData(SlotData[] memory _slotData) external;
   

    function approveFromX(address to_, uint256 tokenId_) external;
    function clearApprovedValues(uint256 tokenId_) external;
    function removeTokenFromOwnerEnumeration(address from_, uint256 tokenId_) external;

    function burnValueX(uint256 fromTokenId, uint256 value_) external returns(bool);
    function mintValueX(uint256 toTokenId, uint256 slot_, uint256 value_) external returns(bool);
    function mintFromX(address to, uint256 slot_, string memory slotName, uint256 value_) external returns (uint256 tokenId);
    function mintFromX(address to, uint256 tokenId, uint256 slot, string memory slotName, uint256 value) external;

    function spendAllowance(address operator, uint256 tokenId, uint256 value_) external;
    function requireMinted(uint256 tokenId) external view returns(bool);
    function isApprovedOrOwner(address operator, uint256 tokenId) external view returns(bool);
    

   
    function dividendAddr() external view returns(address);
    function storageAddr() external view returns(address);
    function getDividendRateBySlot(uint256 _slot) external view returns(uint256);
    function changeDividendRate(uint256 slot, uint256 dividend) external returns(bool);
    function incrementDividend(uint256 tokenId, uint256 dividend) external returns(uint256);
    function decrementDividend(uint256 tokenId, uint256 dividend) external returns(uint256);

    /**
     * @dev MUST emit when value of a token is transferred to another token with the same slot,
     *  including zero value transfers (_value == 0) as well as transfers when tokens are created
     *  (`_fromTokenId` == 0) or destroyed (`_toTokenId` == 0).
     * @param _fromTokenId The token id to transfer value from
     * @param _toTokenId The token id to transfer value to
     * @param _value The transferred value
     */
    event TransferValue(uint256 indexed _fromTokenId, uint256 indexed _toTokenId, uint256 _value);

    /**
     * @dev MUST emits when the approval value of a token is set or changed.
     * @param _tokenId The token to approve
     * @param _operator The operator to approve for
     * @param _value The maximum value that `_operator` is allowed to manage
     */
    event ApprovalValue(uint256 indexed _tokenId, address indexed _operator, uint256 _value);

    /**
     * @dev MUST emit when the slot of a token is set or changed.
     * @param _tokenId The token of which slot is set or changed
     * @param _oldSlot The previous slot of the token
     * @param _newSlot The updated slot of the token
     */ 
    event SlotChanged(uint256 indexed _tokenId, uint256 indexed _oldSlot, uint256 indexed _newSlot);

    /**
     * @notice Get the number of decimals the token uses for value - e.g. 6, means the user
     *  representation of the value of a token can be calculated by dividing it by 1,000,000.
     *  Considering the compatibility with third-party wallets, this function is defined as
     *  `valueDecimals()` instead of `decimals()` to avoid conflict with ERC20 tokens.
     * @return The number of decimals for value
     */

    /**
     * @notice Get the value of a token.
     * @param _tokenId The token for which to query the balance
     * @return The value of `_tokenId`
     */

    /**
     * @notice Get the slot of a token.
     * @param _tokenId The identifier for a token
     * @return The slot of the token
     */
    function slotOf(uint256 _tokenId) external view returns (uint256);

    /**
     * @notice Allow an operator to manage the value of a token, up to the `_value` amount.
     * @dev MUST revert unless caller is the current owner, an authorized operator, or the approved
     *  address for `_tokenId`.
     *  MUST emit ApprovalValue event.
     * @param _tokenId The token to approve
     * @param _operator The operator to be approved
     * @param _value The maximum value of `_toTokenId` that `_operator` is allowed to manage
     */
    function approve(
        uint256 _tokenId,
        address _operator,
        uint256 _value
    ) external payable;

    /**
     * @notice Get the maximum value of a token that an operator is allowed to manage.
     * @param _tokenId The token for which to query the allowance
     * @param _operator The address of an operator
     * @return The current approval value of `_tokenId` that `_operator` is allowed to manage
     */
    function allowance(uint256 _tokenId, address _operator) external view returns (uint256);

    /**
     * @notice Transfer value from a specified token to another specified token with the same slot.
     * @dev Caller MUST be the current owner, an authorized operator or an operator who has been
     *  approved the whole `_fromTokenId` or part of it.
     *  MUST revert if `_fromTokenId` or `_toTokenId` is zero token id or does not exist.
     *  MUST revert if slots of `_fromTokenId` and `_toTokenId` do not match.
     *  MUST revert if `_value` exceeds the balance of `_fromTokenId` or its allowance to the
     *  operator.
     *  MUST emit `TransferValue` event.
     * @param _fromTokenId The token to transfer value from
     * @param _toTokenId The token to transfer value to
     * @param _value The transferred value
     */
    function transferFrom(
        uint256 _fromTokenId,
        uint256 _toTokenId,
        uint256 _value
    ) external payable;

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
     * @param _fromTokenId The token to transfer value from
     * @param _to The address to transfer value to
     * @param _value The transferred value
     * @return ID of the new token created for `_to` which receives the transferred value
     */
    function transferFrom(
        uint256 _fromTokenId,
        address _to,
        uint256 _value
    ) external payable returns (uint256);
}

