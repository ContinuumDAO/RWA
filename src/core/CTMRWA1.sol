// SPDX-License-Identifier: MIT

pragma solidity 0.8.27;

import { ICTMRWA1X } from "../crosschain/ICTMRWA1X.sol";
import { ICTMRWADeployer } from "../deployment/ICTMRWADeployer.sol";
import { ICTMRWAERC20Deployer } from "../deployment/ICTMRWAERC20Deployer.sol";
import { ICTMRWA1Sentry } from "../sentry/ICTMRWA1Sentry.sol";
import { ICTMRWA1Storage } from "../storage/ICTMRWA1Storage.sol";
import { Address, Uint } from "../utils/CTMRWAUtils.sol";
import { ICTMRWA1, SlotData } from "./ICTMRWA1.sol";
import { ICTMRWA1Receiver } from "./ICTMRWA1Receiver.sol";
import { Pausable } from "@openzeppelin/contracts/utils/Pausable.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import {Checkpoints} from "@openzeppelin/contracts/utils/structs/Checkpoints.sol";

/**
 * @title AssetX Multi-chain Semi-Fungible-Token for Real-World-Assets (RWAs)
 * @author @Selqui ContinuumDAO
 *
 * @notice The basic functionality relating to the Semi Fungible Token is derived from ERC3525
 *  https://eips.ethereum.org/EIPS/eip-3525
 *
 * CTMRWA1 is NOT ERC3525 compliant
 *
 * This token can be deployed many times and on multiple chains from CTMRWA1X
 */
contract CTMRWA1 is ReentrancyGuard, Pausable, ICTMRWA1 {
    using Strings for *;
    using Checkpoints for Checkpoints.Trace208;

    /// @notice Each CTMRWA1 corresponds to a single RWA. It is deployed on each chain

    /// @dev ID is a unique identifier linking CTMRWA1 across chains - same ID on every chain
    uint256 public ID;

    /// @dev version is the single integer version of this RWA type
    uint256 public constant VERSION = 1;

    /// @dev rwaType is the RWA type defining CTMRWA1
    uint256 public constant RWA_TYPE = 1;

    /// @dev tokenAdmin is the address of the wallet controlling the RWA, also known as the Issuer
    address public tokenAdmin;

    /// @dev ctmRwaDeployer is the single contract on each chain which deploys the components of a CTMRWA1
    address public ctmRwaDeployer;

    /// @dev overrideWallet IF DEFINED by the tokenAdmin, is a wallet that can forceTransfer assets from any holder
    address public overrideWallet;

    /// @dev ctmRwaMap is the single contract which maps the multi-chain ID to the component address of each part of the
    /// CTMRWA1
    address public ctmRwaMap;

    /// @dev ctmRwa1X is the single contract on each chain responsible for deploying, minting, and transferring the
    /// CTMRWA1 and its components
    address public ctmRwa1X;

    /// @dev rwa1XFallback is the contract responsible for dealing with failed cross-chain calls from ctmRwa1X
    address public rwa1XFallback;

    /// @dev dividendAddr is the contract managing dividend payments to CTMRWA1 holders
    address public dividendAddr;

    /// @dev storageAddr is the contract managing decentralized storage of information for CTMRWA1
    address public storageAddr;

    /// @dev sentryAddr is the contract controlling access to the CTMRWA1
    address public sentryAddr;

    /// @dev tokenFactory is the contract that directly deploys this contract
    address public tokenFactory;

    /// @dev erc20Deployer is the contract which allows deployment an ERC20 representing any slot of a CTMRWA1
    address public erc20Deployer;

    /// @dev slotNumbers is an array holding the slots defined for this CTMRWA1
    uint256[] slotNumbers;
    /// @dev slotNames is an array holding the names of each slot in this CTMRWA1
    string[] slotNames;

    /// @param TokenData is the struct defining tokens in the CTMRWA1
    struct TokenData {
        uint256 id;
        uint256 slot;
        uint256 balance;
        address owner;
        address approved;
        address[] valueApprovals;
    }

    /// @param AddressData is the struct defining ownership of tokens by wallets
    struct AddressData {
        uint256[] ownedTokens;
        mapping(uint256 => uint256) ownedTokensIndex;
    }

    /// @dev slot => tokenId => index
    mapping(uint256 => mapping(uint256 => uint256)) private _slotTokensIndex;

    SlotData[] public _allSlots;

    /// @dev slot => index
    mapping(uint256 => uint256) public allSlotsIndex;

    /// @dev owner => slot => balance checkpoints
    mapping (address => mapping (uint256 => Checkpoints.Trace208)) internal _balance;

    /// @dev slot => total supply in this slot
    mapping (uint256 => Checkpoints.Trace208) internal _supplyInSlot;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     *   @dev baseURI is a string identifying how information is stored about the CTMRWA1
     *   baseURI can be set to one of "GFLD", "IPFS", or "NONE"
     */
    string public baseURI;

    uint256 private _tokenIdGenerator;

    /**
     *   @dev  id => (approval => allowance)
     *   @dev _approvedValues cannot be defined within TokenData, because struct containing mappings cannot be
     * constructed.
     */
    mapping(uint256 => mapping(address => uint256)) private _approvedValues;

    TokenData[] private _allTokens;

    /// @dev id => index within the array
    mapping(uint256 => uint256) private _allTokensIndex;

    mapping(address => AddressData) private _addressData;

    /// @dev defines which address can deploy or mint slot specific ERC20 tokens
    mapping(address => bool) private _erc20s;
    /// @dev slot number => address of the slot specific ERC20
    mapping(uint256 => address) private _erc20Slots;

    constructor(
        address _tokenAdmin,
        address _map,
        string memory tokenName_,
        string memory symbol_,
        uint8 decimals_,
        string memory baseURI_,
        address _ctmRwa1X
    ) {
        tokenAdmin = _tokenAdmin;
        ctmRwaMap = _map;
        _tokenIdGenerator = 1;
        _name = tokenName_;
        _symbol = symbol_;
        _decimals = decimals_;
        baseURI = baseURI_;
        ctmRwa1X = _ctmRwa1X;
        rwa1XFallback = ICTMRWA1X(ctmRwa1X).fallbackAddr();
        ctmRwaDeployer = ICTMRWA1X(ctmRwa1X).ctmRwaDeployer();
        tokenFactory = ICTMRWADeployer(ctmRwaDeployer).tokenFactory(RWA_TYPE, VERSION);
        erc20Deployer = ICTMRWADeployer(ctmRwaDeployer).erc20Deployer();
    }

    modifier onlyTokenAdmin() {
        if (msg.sender != tokenAdmin && msg.sender != ctmRwa1X) {
            revert CTMRWA1_OnlyAuthorized(Address.Sender, Address.TokenAdmin);
        }
        _;
    }

    function pause() external onlyTokenAdmin {
        _pause();
    }

    function unpause() external onlyTokenAdmin {
        _unpause();
    }

    function isPaused() external view returns (bool) {
        return paused();
    }

    modifier onlyErc20Deployer() {
        if (!_erc20s[msg.sender]) {
            revert CTMRWA1_OnlyAuthorized(Address.Sender, Address.ERC20Deployer);
        }
        _;
    }

    modifier onlyTokenFactory() {
        if (msg.sender != tokenFactory) {
            revert CTMRWA1_OnlyAuthorized(Address.Sender, Address.Factory);
        }
        _;
    }

    modifier onlyCtmMap() {
        if (msg.sender != ctmRwaMap) {
            revert CTMRWA1_OnlyAuthorized(Address.Sender, Address.Map);
        }
        _;
    }

    modifier onlyRwa1X() {
        if (msg.sender != ctmRwa1X && msg.sender != rwa1XFallback) {
            revert CTMRWA1_OnlyAuthorized(Address.Sender, Address.RWAX);
        }
        _;
    }

    modifier onlyMinter() {
        if (!ICTMRWA1X(ctmRwa1X).isMinter(msg.sender) && !_erc20s[msg.sender]) {
            revert CTMRWA1_OnlyAuthorized(Address.Sender, Address.Minter);
        }
        _;
    }

    modifier onlyERC20() {
        if (!_erc20s[msg.sender]) {
            revert CTMRWA1_OnlyAuthorized(Address.Sender, Address.RWAERC20);
        }
        _;
    }

    /**
     * @param _tokenAdmin is the new tokenAdmin, or Issuer for this CTMRWA1
     * @dev This function can be called by the cross-chain CTMRWA1X architecture
     * @dev The override wallet for forceTransfer is reset for safety, but can be set up by the new admin
     * @param _tokenAdmin The new tokenAdmin
     * @return success True if the admin was changed, false otherwise
     */
    function changeAdmin(address _tokenAdmin) public onlyRwa1X returns (bool) {
        tokenAdmin = _tokenAdmin;
        overrideWallet = address(0);
        return true;
    }

    /**
     * @param _overrideWallet is the wallet address that can force transfers of any wallet
     * @dev The token admin can only call this if -
     *      They have fully described the Issuer details in CTMRWA1Storage
     *      They have gained a Security License from a Regulator, with the license details stored in LICENSE
     *      They have added the Regulator's wallet address in CTMRWA1Storage, which is public.
     * @dev override wallet should be a multi-sig or MPC TSS wallet with 2 out of -
     *      The Regulator wallet address
     *      The ContinuumDAO Governor address (requires a vote to sign)
     *      A reputable law firm's signature, with the law firm described in LEGAL in CTMRWA1Storage
     */
    function setOverrideWallet(address _overrideWallet) public onlyTokenAdmin {
        if (ICTMRWA1Storage(storageAddr).regulatorWallet() == address(0)) {
            revert CTMRWA1_IsZeroAddress(Address.Regulator);
        }
        overrideWallet = _overrideWallet;
    }

    /**
     * @notice Returns the token collection name.
     * @return The name of the token collection
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @notice Returns the token collection symbol.
     * @return The symbol of the token collection
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @notice Returns the number of decimals the token uses for value.
     * @return The number of decimals the token uses for value
     */
    function valueDecimals() external view virtual returns (uint8) {
        return _decimals;
    }

    /**
     * @dev Sets the ID for this new CTMRWA1 after it has been deployed
     * @param nextID The ID for this CTMRWA1
     * @param _tokenAdmin The address requesting the setting of the ID
     * NOTE Only callable from CTMRWA1X
     * @return success True if the ID was attached, false otherwise
     */
    function attachId(uint256 nextID, address _tokenAdmin) external onlyRwa1X returns (bool) {
        if (_tokenAdmin != tokenAdmin) {
            revert CTMRWA1_OnlyAuthorized(Address.TokenAdmin, Address.TokenAdmin);
        }
        if (ID == 0) {
            // not yet attached
            ID = nextID;
            return (true);
        } else {
            return (false);
        }
    }

    /**
     * @dev Connects the CTMRWA1Dividend contract to this CTMRWA1
     * @param _dividendAddr The new CTMRWA1Dividend contract address
     * @return success True if the dividend contract was attached, false otherwise
     */
    function attachDividend(address _dividendAddr) external onlyCtmMap returns (bool) {
        if (dividendAddr != address(0)) {
            revert CTMRWA1_NotZeroAddress(Address.Dividend);
        }
        dividendAddr = _dividendAddr;
        return (true);
    }

    /**
     * @dev Connects the CTMRWA1Storage contract to this CTMRWA1
     * @param _storageAddr The new CTMRWA1Storage contract address
     * @return success True if the storage contract was attached, false otherwise
     */
    function attachStorage(address _storageAddr) external onlyCtmMap returns (bool) {
        if (storageAddr != address(0)) {
            revert CTMRWA1_NotZeroAddress(Address.Storage);
        }
        storageAddr = _storageAddr;
        return (true);
    }

    /**
     * @dev Connects the CTMRWA1Sentry contract to this CTMRWA1
     * @param _sentryAddr The new CTMRWA1Sentry contract address
     * @return success True if the sentry contract was attached, false otherwise
     */
    function attachSentry(address _sentryAddr) external onlyCtmMap returns (bool) {
        if (sentryAddr != address(0)) {
            revert CTMRWA1_NotZeroAddress(Address.Sentry);
        }
        sentryAddr = _sentryAddr;
        return (true);
    }

    /**
     * @notice Returns the id (NOT ID) of a user held token in this CTMRWA1
     * @param _tokenId The unique tokenId (instance of TokenData)
     * @return The id of the token
     */
    function idOf(uint256 _tokenId) public view virtual returns (uint256) {
        if (!_exists(_tokenId)) {
            revert CTMRWA1_IDNonExistent(_tokenId);
        }
        return _allTokens[_allTokensIndex[_tokenId]].id;
    }

    /**
     * @notice Returns the fungible balance of a user held token in this CTMRWA1
     * @param _tokenId The unique tokenId (instance of TokenData)
     * @return The fungible balance of the token
     */
    function balanceOf(uint256 _tokenId) public view virtual override returns (uint256) {
        if (!_exists(_tokenId)) {
            revert CTMRWA1_IDNonExistent(_tokenId);
        }
        return _allTokens[_allTokensIndex[_tokenId]].balance;
    }

    /**
     * @notice Returns the number of tokenIds owned by a wallet address
     * @param _owner The wallet address for which we want the balance of
     * @return The number of tokenIds owned by the wallet address
     */
    function balanceOf(address _owner) public view virtual override returns (uint256) {
        if (_owner == address(0)) {
            revert CTMRWA1_IsZeroAddress(Address.Owner);
        }
        return _addressData[_owner].ownedTokens.length;
    }

    /**
     * @notice Returns the total balance of all tokenIds owned by a wallet address in a slot
     * @param _owner The wallet address for which we want the balance of in the slot
     * @param _slot The slot number for which to find the balance
     * @return The total balance of all tokenIds owned by the wallet address in the slot
     */
    function balanceOf(address _owner, uint256 _slot) public view returns (uint256) {
        if (_owner == address(0)) {
            revert CTMRWA1_IsZeroAddress(Address.Owner);
        }

        if (!slotExists(_slot)) {
            revert CTMRWA1_InvalidSlot(_slot);
        }

        return _balance[_owner][_slot].latest();
    }

    function balanceOfAt(address _owner, uint256 _slot, uint256 _timestamp) public view returns (uint256) {
        if (_owner == address(0)) {
            revert CTMRWA1_IsZeroAddress(Address.Owner);
        }

        if (!slotExists(_slot)) {
            revert CTMRWA1_InvalidSlot(_slot);
        }

        return _balance[_owner][_slot].upperLookupRecent(uint48(_timestamp));
    }

    /**
     * @notice Returns the address of the owner of a token in this CTMRWA1
     * @param _tokenId The unique tokenId (instance of TokenData)
     * @return The address of the owner of the token
     */
    function ownerOf(uint256 _tokenId) public view virtual returns (address) {
        if (!_exists(_tokenId)) {
            revert CTMRWA1_IDNonExistent(_tokenId);
        }
        address owner = _allTokens[_allTokensIndex[_tokenId]].owner;
        if (owner == address(0)) {
            revert CTMRWA1_IsZeroAddress(Address.Owner);
        }
        return owner;
    }

    /**
     * @notice Returns the slot of a token in this CTMRWA1
     * @param _tokenId The unique tokenId (instance of TokenData)
     * @return The slot of the token
     */
    function slotOf(uint256 _tokenId) public view virtual override returns (uint256) {
        if (!_exists(_tokenId)) {
            revert CTMRWA1_IDNonExistent(_tokenId);
        }
        return _allTokens[_allTokensIndex[_tokenId]].slot;
    }

    /**
     * @notice Returns the name of a slot of a token in this CTMRWA1
     * @param _tokenId The unique tokenId (instance of TokenData)
     * @return The name of the slot of the token
     */
    function slotNameOf(uint256 _tokenId) public view virtual returns (string memory) {
        uint256 thisSlot = slotOf(_tokenId);
        return (slotName(thisSlot));
    }

    /**
     * @notice Returns an object with attributes of a token in this CTMRWA1
     * @param _tokenId The unique tokenId (instance of TokenData)
     * @return The id of the token
     * @return The balance of the token
     * @return The owner of the token
     * @return The slot of the token
     * @return The name of the slot of the token
     * @return The token admin
     */
    function getTokenInfo(uint256 _tokenId)
        external
        view
        returns (uint256, uint256, address, uint256, string memory, address)
    {
        if (!_exists(_tokenId)) {
            revert CTMRWA1_IDNonExistent(_tokenId);
        }

        uint256 slot = slotOf(_tokenId);

        return (
            _allTokens[_allTokensIndex[_tokenId]].id,
            _allTokens[_allTokensIndex[_tokenId]].balance,
            _allTokens[_allTokensIndex[_tokenId]].owner,
            slot,
            slotName(slot),
            tokenAdmin
        );
    }

    /**
     * @notice Deploy an ERC20 token that represents the fungible balance of a specific
     * slot of this CTMRWA1. It allows interaction with lending/markeplace protocols.
     * This function can only be called ONCE per slot.
     * @param _slot The slot number for which to create an ERC20
     * @param _erc20Name The name of this ERC20. It is automatically pre-pended with the slot number
     * @param _feeToken The fee token to pay for this service with. Must be configured in FeeManager
     */
    function deployErc20(uint256 _slot, string memory _erc20Name, address _feeToken) public onlyTokenAdmin {
        if (!slotExists(_slot)) {
            revert CTMRWA1_InvalidSlot(_slot);
        }

        if (_erc20Slots[_slot] != address(0)) {
            revert CTMRWA1_NotZeroAddress(Address.RWAERC20);
        }

        if (bytes(_erc20Name).length > 128) {
            revert CTMRWA1_NameTooLong();
        }

        address newErc20 = ICTMRWAERC20Deployer(erc20Deployer).deployERC20(
            ID, RWA_TYPE, VERSION, _slot, _erc20Name, _symbol, _feeToken, msg.sender
        );

        _erc20s[newErc20] = true;
        _erc20Slots[_slot] = newErc20;
    }

    /**
     * @notice Get the address of the ERC20 token representing a slot in this CTMRWA1
     * @param _slot The slot number
     * @return The address of the ERC20 token representing the slot
     */
    function getErc20(uint256 _slot) public view returns (address) {
        return (_erc20Slots[_slot]);
    }

    /**
     * @notice Approve the spending of the fungible balance of a tokenId in this CTMRWA1
     * @param _tokenId The tokenId
     * @param _to The address being given approval to spend from this tokenId
     * @param _value The fungible amount being given approval to spend by _to
     */
    function approve(uint256 _tokenId, address _to, uint256 _value) public payable virtual override {
        address owner = CTMRWA1.ownerOf(_tokenId);
        if (_to == owner) {
            revert CTMRWA1_Unauthorized(Address.To, Address.Owner);
        }

        if (!isApprovedOrOwner(msg.sender, _tokenId)) {
            revert CTMRWA1_OnlyAuthorized(Address.Sender, Address.ApprovedOrOwner);
        }

        _approveValue(_tokenId, _to, _value);
    }

    /**
     * @notice The allowance to spend from fungible balance of a tokenId by a wallet address
     * @param _tokenId The tokenId in this CTMRWA1
     * @param _operator The wallet address for which the allowance is sought
     * @return The allowance to spend from fungible balance of a tokenId by a wallet address
     */
    function allowance(uint256 _tokenId, address _operator) public view virtual override returns (uint256) {
        if (!_exists(_tokenId)) {
            revert CTMRWA1_IDNonExistent(_tokenId);
        }
        return _approvedValues[_tokenId][_operator];
    }

    /**
     * @dev This lower level function is called by CTMRWA1X to transfer from the fungible balance of
     * a tokenId to another address
     * @param _fromTokenId The tokenId that the value id being transferred from
     * @param _to The wallet address that the value is being transferred to
     * @param _value The fungible value that is being transferred
     * @return newTokenId The new tokenId that was created
     */
    function transferFrom(uint256 _fromTokenId, address _to, uint256 _value)
        public
        override
        onlyRwa1X
        whenNotPaused
        returns (uint256 newTokenId)
    {
        spendAllowance(msg.sender, _fromTokenId, _value);

        string memory thisSlotName = slotNameOf(_fromTokenId);

        newTokenId = _createOriginalTokenId();
        _mint(_to, newTokenId, CTMRWA1.slotOf(_fromTokenId), thisSlotName, 0);
        _transferValue(_fromTokenId, newTokenId, _value);
    }

    /**
     * @notice Transfer value from one tokenId to another. The caller must have a spend allowance
     * to transfer the value from the tokenId.
     * @param _fromTokenId The source tokenId
     * @param _toTokenId The desination tokenId
     * @param _value The fungible value being transferred
     * @return The owner of the destination tokenId
     */
    function transferFrom(uint256 _fromTokenId, uint256 _toTokenId, uint256 _value)
        public
        override
        nonReentrant
        whenNotPaused
        returns (address)
    {
        spendAllowance(msg.sender, _fromTokenId, _value);
        _transferValue(_fromTokenId, _toTokenId, _value);

        return (ownerOf(_toTokenId));
    }

    /**
     * @dev This lower level function is called by CTMRWA1X to transfer a tokenId from
     * one wallet addres to another. The tokenId must be approved for transfer, or owned by _from
     * @param _from The wallet address from which the tokenId is being fransferred from
     * @param _to The wallet adddress to which the tokenId is being transferred to
     * @param _tokenId The tokenId being transferred
     */
    function transferFrom(address _from, address _to, uint256 _tokenId) public onlyRwa1X whenNotPaused {
        if (!isApprovedOrOwner(msg.sender, _tokenId)) {
            revert CTMRWA1_OnlyAuthorized(Address.Sender, Address.ApprovedOrOwner);
        }
        _transferTokenId(_from, _to, _tokenId);
    }

    /**
     * @notice Allows a the overrideWallet (if set) to force a transfer of any tokenId to another wallet
     * @param _from The wallet address from which the tokenId is being fransferred from
     * @param _to The wallet adddress to which the tokenId is being transferred to
     * @param _tokenId The tokenId being transferred
     * @return success True if the transfer was successful, false otherwise
     */
    function forceTransfer(address _from, address _to, uint256 _tokenId) public returns (bool) {
        if (overrideWallet == address(0)) {
            revert CTMRWA1_IsZeroAddress(Address.Override);
        }

        if (msg.sender != overrideWallet) {
            revert CTMRWA1_OnlyAuthorized(Address.Sender, Address.Override);
        }

        _transferTokenId(_from, _to, _tokenId);

        return true;
    }

    /**
     * @notice Returns the wallet address (if any) that is approved to spend any amount from a tokenId
     * @param _tokenId The tokenId being examined
     * @return The wallet address (if any) that is approved to spend any amount from a tokenId
     */
    function getApproved(uint256 _tokenId) public view virtual returns (address) {
        if (!_exists(_tokenId)) {
            revert CTMRWA1_IDNonExistent(_tokenId);
        }
        return _allTokens[_allTokensIndex[_tokenId]].approved;
    }

    /**
     * @notice Returns the total number of tokenIds in this CTMRWA1
     * @return The total number of tokenIds in this CTMRWA1
     */
    function totalSupply() external view virtual returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @notice Returns the id (NOT ID) of a tokenId at an index for this CTMRWA1
     * @dev Deprecated
     * @return The id of the tokenId at the index
     */
    function tokenByIndex(uint256 _index) public view virtual returns (uint256) {
        if (_index >= this.totalSupply()) {
            revert CTMRWA1_OutOfBounds();
        }
        return _allTokens[_index].id;
    }

    /**
     * @notice Returns the tokenId for an index into an array of all tokenIds held by a wallet address
     * @param _owner The wallet address being axamined
     * @param _index The index into the wallet address
     * @return The tokenId for an index into an array of all tokenIds held by a wallet address
     */
    function tokenOfOwnerByIndex(address _owner, uint256 _index) external view virtual override returns (uint256) {
        if (_index >= CTMRWA1.balanceOf(_owner)) {
            revert CTMRWA1_OutOfBounds();
        }
        return _addressData[_owner].ownedTokens[_index];
    }

    /**
     * @notice An owner or a wallet that has sufficient allowance is approved to spend _value
     * @param _operator The wallet that is being given approval to spend _value
     * @param _tokenId The tokenId from which approval to spend _value is being given
     * @param _value The fungible value being given approval to spend
     */
    function spendAllowance(address _operator, uint256 _tokenId, uint256 _value) public virtual {
        if (_value == 0) {
            revert CTMRWA1_IsZeroUint(Uint.Value);
        }
        uint256 currentAllowance = CTMRWA1.allowance(_tokenId, _operator);
        if (!isApprovedOrOwner(_operator, _tokenId) && currentAllowance != type(uint256).max) {
            if (currentAllowance < _value) {
                revert CTMRWA1_InsufficientAllowance();
            }
            _approveValue(_tokenId, _operator, currentAllowance - _value);
        }
    }

    /**
     * @dev tokenId exists?
     * @param _tokenId The tokenId being checked
     * @return True if the tokenId exists, false otherwise
     */
    function _exists(uint256 _tokenId) internal view virtual returns (bool) {
        return _allTokens.length != 0 && _allTokens[_allTokensIndex[_tokenId]].id == _tokenId;
    }

    function exists(uint256 _tokenId) external view virtual returns (bool) {
        return _exists(_tokenId);
    }

    /**
     * @notice The owner of a tokenId approves an another address to spend any 'value' from it
     * @param _to The address being granted approval to spend from tokenId
     * @param _tokenId The tokenId from which spending is allowed by _to
     */
    function approve(address _to, uint256 _tokenId) public virtual {
        address owner = ownerOf(_tokenId);
        if (_to == owner) {
            revert CTMRWA1_Unauthorized(Address.To, Address.Owner);
        }

        if (msg.sender != owner) {
            revert CTMRWA1_OnlyAuthorized(Address.Sender, Address.Owner);
        }

        _approve(_to, _tokenId);
    }

    /**
     * @notice Returns whether an operator address is approved to spend from a tokenId
     * @param _operator The address being checked to see if they are approved
     * @param _tokenId The tokenId which is being checked
     * @return True if the operator is approved to spend from the tokenId, false otherwise
     */
    function isApprovedOrOwner(address _operator, uint256 _tokenId) public view virtual returns (bool) {
        if (!_exists(_tokenId)) {
            revert CTMRWA1_IDNonExistent(_tokenId);
        }
        address owner = CTMRWA1.ownerOf(_tokenId);
        return (_operator == owner || getApproved(_tokenId) == _operator || _erc20s[_operator]);
    }

    /**
     * @dev Internal function minting value to a slot creating a NEW tokenId
     * @param _to The wallet address to mint the value to
     * @param _slot The slot number to mint the value to
     * @param _slotName The name of the slot
     * @param _value The value to mint
     * @return tokenId The new tokenId that was created
     */
    function _mint(address _to, uint256 _slot, string memory _slotName, uint256 _value)
        private
        returns (uint256 tokenId)
    {
        tokenId = _createOriginalTokenId();
        _mint(_to, tokenId, _slot, _slotName, _value);
    }

    /**
     * @dev A lower level function calling _mint from CTMRWA1X, creating a NEW tokenId
     * @param _to The wallet address to mint the value to
     * @param _slot The slot number to mint the value to
     * @param _slotName The name of the slot
     * @param _value The value to mint
     * @return tokenId The new tokenId that was created
     */
    function mintFromX(address _to, uint256 _slot, string memory _slotName, uint256 _value)
        external
        onlyMinter
        whenNotPaused
        returns (uint256 tokenId)
    {
        return (_mint(_to, _slot, _slotName, _value));
    }

    /**
     * @dev Low level function to mint, being passed a new tokenId that does not already exist.
     * If whitelists are enabled, then _to is checked in CTMRWA1Sentry
     * @param _to The wallet address to mint the value to
     * @param _tokenId The tokenId to mint the value to
     * @param _slot The slot number to mint the value to
     * @param _slotName The name of the slot
     * @param _value The value to mint
     */
    function _mint(address _to, uint256 _tokenId, uint256 _slot, string memory _slotName, uint256 _value) internal {
        if (_to == address(0)) {
            revert CTMRWA1_IsZeroAddress(Address.To);
        }
        if (_tokenId == 0) {
            revert CTMRWA1_IsZeroUint(Uint.TokenId);
        }
        if (_exists(_tokenId)) {
            revert CTMRWA1_IDExists(_tokenId);
        }

        // Check for value overflow when casting to uint208
        uint256 maxUint208 = 2**208 - 1;
        if (_value > maxUint208) {
            revert CTMRWA1_ValueOverflow(_value, maxUint208);
        }

        _beforeValueTransfer(address(0), _to, 0, _tokenId, _slot, _slotName, _value);
        __mintToken(_to, _tokenId, _slot);
        __mintValue(_tokenId, _value);
        uint208 newBalance = _balance[_to][_slot].latest() + uint208(_value);
        _balance[_to][_slot].push(uint48(block.timestamp), newBalance);
        uint208 newSupplyInSlot = _supplyInSlot[_slot].latest() + uint208(_value);
        _supplyInSlot[_slot].push(uint48(block.timestamp), newSupplyInSlot);
        _afterValueTransfer(address(0), _to, 0, _tokenId, _slot, _slotName, _value);
    }

    /**
     * @dev onlyMinter version of _mint
     * @param _to The wallet address to mint the value to
     * @param _tokenId The tokenId to mint the value to
     * @param _slot The slot number to mint the value to
     * @param _slotName The name of the slot
     * @param _value The value to mint
     */
    function mintFromX(address _to, uint256 _tokenId, uint256 _slot, string memory _slotName, uint256 _value)
        external
        onlyMinter
        whenNotPaused
    {
        _mint(_to, _tokenId, _slot, _slotName, _value);
    }

    /**
     * @dev Mint value to an existing tokenId
     * @param _tokenId The tokenId to mint the value to
     * @param _value The value to mint
     */
    function _mintValue(uint256 _tokenId, uint256 _value) private {
        // Check for value overflow when casting to uint208
        uint256 maxUint208 = 2**208 - 1;
        if (_value > maxUint208) {
            revert CTMRWA1_ValueOverflow(_value, maxUint208);
        }

        address owner = CTMRWA1.ownerOf(_tokenId);
        uint256 slot = CTMRWA1.slotOf(_tokenId);
        string memory thisSlotName = CTMRWA1.slotNameOf(_tokenId);
        _beforeValueTransfer(address(0), owner, 0, _tokenId, slot, thisSlotName, _value);
        __mintValue(_tokenId, _value);
        uint208 newBalance = _balance[owner][slot].latest() + uint208(_value);
        _balance[owner][slot].push(uint48(block.timestamp), newBalance);
        uint208 newSupplyInSlot = _supplyInSlot[slot].latest() + uint208(_value);
        _supplyInSlot[slot].push(uint48(block.timestamp), newSupplyInSlot);
        _afterValueTransfer(address(0), owner, 0, _tokenId, slot, thisSlotName, _value);
    }

    /// @dev Lowest level mint function
    /// @param _tokenId The tokenId to mint the value to
    /// @param _value The value to mint
    function __mintValue(uint256 _tokenId, uint256 _value) private {
        _allTokens[_allTokensIndex[_tokenId]].balance += _value;
        emit TransferValue(0, _tokenId, _value);
    }

    /// @dev Mint a new token using a new tokenId
    /// @param _to The wallet address to mint the value to
    /// @param _tokenId The tokenId to mint the value to
    /// @param _slot The slot number to mint the value to
    function __mintToken(address _to, uint256 _tokenId, uint256 _slot) private {
        TokenData memory tokenData = TokenData({
            id: _tokenId,
            slot: _slot,
            balance: 0,
            owner: _to,
            approved: address(0),
            valueApprovals: new address[](0)
        });

        _addTokenToAllTokensEnumeration(tokenData);
        _addTokenToOwnerEnumeration(_to, _tokenId);

        emit Transfer(address(0), _to, _tokenId);
        emit SlotChanged(_tokenId, 0, _slot);
    }

    /// @dev burn a tokenId, checking permissions
    /// @param _tokenId The tokenId to burn
    function burn(uint256 _tokenId) public virtual whenNotPaused {
        if (!isApprovedOrOwner(msg.sender, _tokenId)) {
            revert CTMRWA1_OnlyAuthorized(Address.Sender, Address.ApprovedOrOwner);
        }
        _burn(_tokenId);
    }

    /// @dev Lowest level burn function
    /// @param _tokenId The tokenId to burn
    function _burn(uint256 _tokenId) private {
        if (!_exists(_tokenId)) {
            revert CTMRWA1_IDNonExistent(_tokenId);
        }

        (, uint256 bal, address owner, uint256 slot, string memory thisSlotName,) = this.getTokenInfo(_tokenId);

        _beforeValueTransfer(owner, address(0), _tokenId, 0, slot, thisSlotName, bal);

        _clearApprovedValues(_tokenId);
        _removeTokenFromOwnerEnumeration(owner, _tokenId);
        _removeTokenFromAllTokensEnumeration(_tokenId);

        uint208 newBalance = _balance[owner][slot].latest() - uint208(bal);
        _balance[owner][slot].push(uint48(block.timestamp), newBalance);
        uint208 newSupplyInSlot = _supplyInSlot[slot].latest() - uint208(bal);
        _supplyInSlot[slot].push(uint48(block.timestamp), newSupplyInSlot);

        emit TransferValue(_tokenId, 0, bal);
        emit SlotChanged(_tokenId, slot, 0);
        emit Transfer(owner, address(0), _tokenId);

        _afterValueTransfer(owner, address(0), _tokenId, 0, slot, thisSlotName, bal);
    }

    /// @dev Burn value from an existing tokenId
    /// @param _tokenId The tokenId to burn
    /// @param _value The value to burn
    function _burnValue(uint256 _tokenId, uint256 _value) internal {
        if (!_exists(_tokenId)) {
            revert CTMRWA1_IDNonExistent(_tokenId);
        }

        (, uint256 bal, address owner, uint256 slot, string memory thisSlotName,) = this.getTokenInfo(_tokenId);

        if (bal < _value) {
            revert CTMRWA1_InsufficientBalance();
        }

        _beforeValueTransfer(owner, address(0), _tokenId, 0, slot, thisSlotName, _value);

        _allTokens[_allTokensIndex[_tokenId]].balance -= _value;

        uint208 newBalance = _balance[owner][slot].latest() - uint208(_value);
        _balance[owner][slot].push(uint48(block.timestamp), newBalance);
        uint208 newSupplyInSlot = _supplyInSlot[slot].latest() - uint208(_value);
        _supplyInSlot[slot].push(uint48(block.timestamp), newSupplyInSlot);

        emit TransferValue(_tokenId, 0, _value);

        _afterValueTransfer(owner, address(0), _tokenId, 0, slot, thisSlotName, _value);
    }

    /// @dev Add new tokenId to the array of tokens held by an address
    /// @param _to The wallet address to add the tokenId to
    /// @param _tokenId The tokenId to add
    function _addTokenToOwnerEnumeration(address _to, uint256 _tokenId) private {
        _allTokens[_allTokensIndex[_tokenId]].owner = _to;

        _addressData[_to].ownedTokensIndex[_tokenId] = _addressData[_to].ownedTokens.length;
        _addressData[_to].ownedTokens.push(_tokenId);
    }

    /// @dev Remove an existing tokenId from the array of tokens held by an address
    /// @param _from The wallet address to remove the tokenId from
    /// @param _tokenId The tokenId to remove
    function _removeTokenFromOwnerEnumeration(address _from, uint256 _tokenId) private {
        _allTokens[_allTokensIndex[_tokenId]].owner = address(0);

        AddressData storage ownerData = _addressData[_from];
        uint256 lastTokenIndex = ownerData.ownedTokens.length - 1;
        uint256 lastTokenId = ownerData.ownedTokens[lastTokenIndex];
        uint256 tokenIndex = ownerData.ownedTokensIndex[_tokenId];

        ownerData.ownedTokens[tokenIndex] = lastTokenId;
        ownerData.ownedTokensIndex[lastTokenId] = tokenIndex;

        delete ownerData.ownedTokensIndex[_tokenId];
        ownerData.ownedTokens.pop();
    }

    /// @dev Call _removeTokenFromOwnerEnumeration from CTMRWA1X
    /// @param _from The wallet address to remove the tokenId from
    /// @param _tokenId The tokenId to remove
    function removeTokenFromOwnerEnumeration(address _from, uint256 _tokenId) external onlyRwa1X {
        _removeTokenFromOwnerEnumeration(_from, _tokenId);
    }

    /// @dev Add a new tokenId to the array of all tokenIds
    /// @param _tokenData The tokenData to add
    function _addTokenToAllTokensEnumeration(TokenData memory _tokenData) private {
        _allTokensIndex[_tokenData.id] = _allTokens.length;
        _allTokens.push(_tokenData);
    }

    /// @dev Remove an existing tokenId from the array of all tokenIds
    /// @param _tokenId The tokenId to remove
    function _removeTokenFromAllTokensEnumeration(uint256 _tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[_tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        TokenData memory lastTokenData = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenData; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenData.id] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[_tokenId];
        _allTokens.pop();
    }

    /// @dev Lowest level approve to spend any amount from tokenId by an address function
    /// @param _to The wallet address to approve
    /// @param _tokenId The tokenId to approve
    function _approve(address _to, uint256 _tokenId) private {
        _allTokens[_allTokensIndex[_tokenId]].approved = _to;
        emit Approval(CTMRWA1.ownerOf(_tokenId), _to, _tokenId);
    }

    /// @dev Version of _approve callable from CTMRWA1X
    /// @param _to The wallet address to approve
    /// @param _tokenId The tokenId to approve
    function approveFromX(address _to, uint256 _tokenId) external onlyRwa1X {
        _approve(_to, _tokenId);
    }

    /// @dev Low level function to approve spending value from tokenId by an address
    /// @param _tokenId The tokenId to approve
    /// @param _to The wallet address to approve
    /// @param _value The value to approve
    function _approveValue(uint256 _tokenId, address _to, uint256 _value) internal {
        if (_to == address(0)) {
            revert CTMRWA1_IsZeroAddress(Address.To);
        }

        if (!_existApproveValue(_to, _tokenId)) {
            _allTokens[_allTokensIndex[_tokenId]].valueApprovals.push(_to);
        }

        _approvedValues[_tokenId][_to] = _value;

        emit ApprovalValue(_tokenId, _to, _value);
    }

    /// @dev Remove all permissions to spend any 'value' of tokenId by any address
    /// @param _tokenId The tokenId to clear the approvals for
    function _clearApprovedValues(uint256 _tokenId) internal {
        TokenData storage tokenData = _allTokens[_allTokensIndex[_tokenId]];
        uint256 length = tokenData.valueApprovals.length;
        for (uint256 i = 0; i < length; i++) {
            address approval = tokenData.valueApprovals[i];
            delete _approvedValues[_tokenId][approval];
        }
        delete tokenData.valueApprovals;
    }

    /// @dev Version of _clearApprovedValues callable by CTMRWA1X
    /// @param _tokenId The tokenId to clear the approvals for
    function clearApprovedValues(uint256 _tokenId) external onlyRwa1X {
        _clearApprovedValues(_tokenId);
    }

    /// @dev Version of _clearApprovedValues callable by CTMRWAERC20Deployer
    /// @param _tokenId The tokenId to clear the approvals for
    function clearApprovedValuesErc20(uint256 _tokenId) external onlyErc20Deployer {
        _clearApprovedValues(_tokenId);
    }

    /// @dev Check if an address has approval to spend 'value' from a tokenId
    /// @param _to The wallet address to check the approval for
    /// @param _tokenId The tokenId to check the approval for
    function _existApproveValue(address _to, uint256 _tokenId) internal view returns (bool) {
        uint256 length = _allTokens[_allTokensIndex[_tokenId]].valueApprovals.length;
        for (uint256 i = 0; i < length; i++) {
            if (_allTokens[_allTokensIndex[_tokenId]].valueApprovals[i] == _to) {
                return true;
            }
        }
        return false;
    }

    /// @dev Low level function to transfer 'value' between two pre-existing tokenIds
    /// @param _fromTokenId The tokenId to transfer the value from
    /// @param _toTokenId The tokenId to transfer the value to
    /// @param _value The value to transfer
    function _transferValue(uint256 _fromTokenId, uint256 _toTokenId, uint256 _value) internal {
        if (!_exists(_fromTokenId)) {
            revert CTMRWA1_IDNonExistent(_fromTokenId);
        }
        if (!_exists(_toTokenId)) {
            revert CTMRWA1_IDNonExistent(_toTokenId);
        }

        TokenData storage fromTokenData = _allTokens[_allTokensIndex[_fromTokenId]];
        TokenData storage toTokenData = _allTokens[_allTokensIndex[_toTokenId]];

        uint256 slot = fromTokenData.slot;

        if (fromTokenData.balance < _value) {
            revert CTMRWA1_InsufficientBalance();
        }
        if (slot != toTokenData.slot) {
            revert CTMRWA1_InvalidSlot(toTokenData.slot);
        }

        string memory thisSlotName = slotNameOf(_fromTokenId);

        _beforeValueTransfer(
            fromTokenData.owner, toTokenData.owner, _fromTokenId, _toTokenId, slot, thisSlotName, _value
        );

        fromTokenData.balance -= _value;
        uint208 newBalanceFrom = _balance[fromTokenData.owner][slot].latest() - uint208(_value);
        _balance[fromTokenData.owner][slot].push(uint48(block.timestamp), newBalanceFrom);

        toTokenData.balance += _value;
        uint208 newBalanceTo = _balance[toTokenData.owner][slot].latest() + uint208(_value);
        _balance[toTokenData.owner][slot].push(uint48(block.timestamp), newBalanceTo);

        emit TransferValue(_fromTokenId, _toTokenId, _value);

        _afterValueTransfer(
            fromTokenData.owner, toTokenData.owner, _fromTokenId, _toTokenId, fromTokenData.slot, thisSlotName, _value
        );

        if (!_checkOnCTMRWA1Received(_fromTokenId, _toTokenId, _value, "")) {
            revert CTMRWA1_ReceiverRejected();
        }
    }

    /// @dev Burn 'value' from a pre-existing tokenId, callable by any 'Minter'
    /// @param _fromTokenId The tokenId to burn the value from
    /// @param _value The value to burn
    function burnValueX(uint256 _fromTokenId, uint256 _value) external onlyMinter whenNotPaused returns (bool) {
        if (!_exists(_fromTokenId)) {
            revert CTMRWA1_IDNonExistent(_fromTokenId);
        }

        TokenData storage fromTokenData = _allTokens[_allTokensIndex[_fromTokenId]];
        if (fromTokenData.balance < _value) {
            revert CTMRWA1_InsufficientBalance();
        }

        fromTokenData.balance -= _value;
        return (true);
    }

    /**
     * @dev Mint 'value' to an existing tokenId, providing the slot is the same and the address is
     *  whitelisted (if whitelisting is enabled). Function is callable by any Minter
     * @param _toTokenId The tokenId to mint the value to
     * @param _slot The slot number to mint the value to
     * @param _value The value to mint
     */
    function mintValueX(uint256 _toTokenId, uint256 _slot, uint256 _value)
        external
        onlyMinter
        whenNotPaused
        returns (bool)
    {
        if (!_exists(_toTokenId)) {
            revert CTMRWA1_IDNonExistent(_toTokenId);
        }
        address owner = ownerOf(_toTokenId);
        string memory toAddressStr = owner.toHexString();

        if (sentryAddr != address(0)) {
            if (!ICTMRWA1Sentry(sentryAddr).isAllowableTransfer(toAddressStr)) {
                revert CTMRWA1_WhiteListRejected(owner);
            }
        }

        TokenData storage toTokenData = _allTokens[_allTokensIndex[_toTokenId]];
        if (toTokenData.slot != _slot) {
            revert CTMRWA1_InvalidSlot(_slot);
        }

        toTokenData.balance += _value;
        return (true);
    }

    /// @dev Transfer ownership of a tokenId to another wallet
    /// @param _from The wallet address to transfer the tokenId from
    /// @param _to The wallet address to transfer the tokenId to
    /// @param _tokenId The tokenId to transfer
    function _transferTokenId(address _from, address _to, uint256 _tokenId) internal {
        if (_from != ownerOf(_tokenId)) {
            revert CTMRWA1_OnlyAuthorized(Address.From, Address.Owner);
        }
        if (_to == address(0)) {
            revert CTMRWA1_IsZeroAddress(Address.To);
        }

        uint256 slot = CTMRWA1.slotOf(_tokenId);
        uint256 value = CTMRWA1.balanceOf(_tokenId);
        string memory thisSlotName = slotNameOf(_tokenId);

        _beforeValueTransfer(_from, _to, _tokenId, _tokenId, slot, thisSlotName, value);

        _approve(address(0), _tokenId);
        _clearApprovedValues(_tokenId);

        _removeTokenFromOwnerEnumeration(_from, _tokenId);
        uint208 newBalanceFrom = _balance[_from][slot].latest() - uint208(value);
        _balance[_from][slot].push(uint48(block.timestamp), newBalanceFrom);

        _addTokenToOwnerEnumeration(_to, _tokenId);
        uint208 newBalanceTo = _balance[_to][slot].latest() + uint208(value);
        _balance[_to][slot].push(uint48(block.timestamp), newBalanceTo);

        emit Transfer(_from, _to, _tokenId);

        _afterValueTransfer(_from, _to, _tokenId, _tokenId, slot, thisSlotName, value);
    }

    /// @dev Create a new tokenId. Only callable by an ERC20 interface
    /// @return The new tokenId that was created
    function createOriginalTokenId() external onlyERC20 returns (uint256) {
        return (_createOriginalTokenId());
    }

    /// @dev A function called when _toTokenId receives some 'value'. Designed to be overriden
    /// @param _fromTokenId The tokenId that is sending the value
    /// @param _toTokenId The tokenId that is receiving the value
    /// @param _value The value being transferred
    /// @param _data The data being transferred
    /// @return True if the transfer was successful, false otherwise
    function _checkOnCTMRWA1Received(uint256 _fromTokenId, uint256 _toTokenId, uint256 _value, bytes memory _data)
        internal
        virtual
        returns (bool)
    {
        // Unused variables
        _fromTokenId;
        _toTokenId;
        _value;
        _data;

        // Placeholder
        return (true);
    }

    /// @dev Increments the tokenId counter (does NOT create a new tokenId)
    /// @return The new tokenId that was created
    function _createOriginalTokenId() internal returns (uint256) {
        return _tokenIdGenerator++;
    }

    /// @notice Return the number of slots in the CTMRWA1
    /// @return The number of slots in the CTMRWA1
    function slotCount() public view returns (uint256) {
        return _allSlots.length;
    }

    /// @notice Return arrays of all slot numbers and the corresponding slot names in this CTMRWA1
    /// @return The array of slot numbers
    /// @return The array of slot names
    function getAllSlots() public view returns (uint256[] memory, string[] memory) {
        return (slotNumbers, slotNames);
    }

    /**
     * @notice Returns the struct describing a slot in this CTMRWA1 by an index
     * @param _indx The index into the slot struct array
     * @return The slot data for the index
     */
    function getSlotInfoByIndex(uint256 _indx) public view returns (SlotData memory) {
        return (_allSlots[_indx]);
    }

    /// @dev Function is used to initialize the slot struct array on a newly deployed chain in this RWA
    /// @param _slotNumbers The array of slot numbers
    /// @param _slotNames The array of slot names
    function initializeSlotData(uint256[] memory _slotNumbers, string[] memory _slotNames) external onlyTokenFactory {
        if (_slotNumbers.length != _slotNames.length) {
            revert CTMRWA1_LengthMismatch(Uint.SlotLength);
        }

        if (_allSlots.length != 0) {
            revert CTMRWA1_NonZeroUint(Uint.SlotLength);
        }

        for (uint256 i = 0; i < _slotNumbers.length; i++) {
            _allSlots.push(SlotData(_slotNumbers[i], _slotNames[i], new uint256[](0)));
        }

        slotNumbers = _slotNumbers;
        slotNames = _slotNames;
    }

    /**
     * @notice Returns the slot name associated with a slot number
     * @param _slot The slot number being examined
     * @return The slot name for the slot number
     */
    function slotName(uint256 _slot) public view returns (string memory) {
        if (!slotExists(_slot)) {
            revert CTMRWA1_InvalidSlot(_slot);
        }
        return (_allSlots[allSlotsIndex[_slot]].slotName);
    }

    /**
     * @notice Returns the slot number at an index into the array of structs of the slots
     * @param _index The index into the struct array
     * @return The slot number at the index
     */
    function slotByIndex(uint256 _index) public view returns (uint256) {
        if (_index >= slotCount()) {
            revert CTMRWA1_OutOfBounds();
        }
        return _allSlots[_index].slot;
    }

    /**
     * @notice Returns whether a slot number exists in the array of structs of the slots
     * @param _slot The slot number being examined
     * @return True if the slot exists, false otherwise
     */
    function slotExists(uint256 _slot) public view virtual returns (bool) {
        return _allSlots.length != 0 && _allSlots[allSlotsIndex[_slot]].slot == _slot;
    }

    /**
     * @notice Returns the total number of tokenIds in a slot
     * @param _slot The slot being examined
     * @return The total number of tokenIds in the slot
     */
    function tokenSupplyInSlot(uint256 _slot) external view returns (uint256) {
        if (!slotExists(_slot)) {
            return 0;
        }
        return _allSlots[allSlotsIndex[_slot]].slotTokens.length;
    }

    /**
     * @notice Returns the total fungible balance in a slot in this CTMRWA1
     * @param _slot The slot being examined
     * @return The total fungible balance in the slot
     */
    function totalSupplyInSlot(uint256 _slot) external view returns (uint256) {
        return uint256(_supplyInSlot[_slot].latest());
    }

    function totalSupplyInSlotAt(uint256 _slot, uint256 _timestamp) external view returns (uint256) {
        return uint256(_supplyInSlot[_slot].upperLookupRecent(uint48(_timestamp)));
    }

    /**
     * @notice Returns the tokenId in a slot by an index number
     * @param _slot The slot being examined
     * @param _index The index into the slot tokens
     * @return The tokenId at the index
     */
    function tokenInSlotByIndex(uint256 _slot, uint256 _index) public view returns (uint256) {
        if (_index >= this.tokenSupplyInSlot(_slot)) {
            revert CTMRWA1_OutOfBounds();
        }
        return _allSlots[allSlotsIndex[_slot]].slotTokens[_index];
    }

    /// @dev Check if a tokenId exists in a slot
    /// @param _slot The slot being examined
    /// @param _tokenId The tokenId being examined
    /// @return True if the tokenId exists in the slot, false otherwise
    function _tokenExistsInSlot(uint256 _slot, uint256 _tokenId) private view returns (bool) {
        SlotData storage slotData = _allSlots[allSlotsIndex[_slot]];
        return slotData.slotTokens.length > 0 && slotData.slotTokens[_slotTokensIndex[_slot][_tokenId]] == _tokenId;
    }

    /// @dev Interface to _createSlot from only CTMRWA1X
    /// @param _slot The slot number to create
    /// @param _slotName The name of the slot
    function createSlotX(uint256 _slot, string memory _slotName) external onlyRwa1X {
        _createSlot(_slot, _slotName);
    }

    /// @dev Create a new slot struct and add it to the slot struct array
    /// @param _slot The slot number to create
    /// @param _slotName The name of the slot
    function _createSlot(uint256 _slot, string memory _slotName) internal {
        SlotData memory slotData =
            SlotData({ slot: _slot, slotName: _slotName, slotTokens: new uint256[](0) });
        _addSlotToAllSlotsEnumeration(slotData);
        slotNumbers.push(_slot);
        slotNames.push(_slotName);
        emit SlotChanged(0, 0, _slot);
    }

    /**
     * @dev Function that is always called before value is transferred. Checks that the address
     * being transferred to is whitelisted (if whitelisting is enabled). Also checks that the slot exists
     * @param _from The wallet address from which the tokenId is being transferred from
     * @param _to The wallet address to which the tokenId is being transferred to
     * @param _fromTokenId The tokenId that is being transferred from
     * @param _toTokenId The tokenId that is being transferred to
     * @param _slot The slot number being examined
     * @param _slotName The name of the slot
     * @param _value The value being transferred
     */
    function _beforeValueTransfer(
        address _from,
        address _to,
        uint256 _fromTokenId,
        uint256 _toTokenId,
        uint256 _slot,
        string memory _slotName,
        uint256 _value
    ) internal virtual {
        if (!slotExists(_slot)) {
            revert CTMRWA1_InvalidSlot(_slot);
        }

        if (sentryAddr != address(0)) {
            string memory toAddressStr = _to.toHexString();
            if (!ICTMRWA1Sentry(sentryAddr).isAllowableTransfer(toAddressStr)) {
                revert CTMRWA1_OnlyAuthorized(Address.To, Address.Allowable);
            }
        }

        // currently unused
        _from;
        _fromTokenId;
        _toTokenId;
        _slotName;
        _value;
    }

    /**
     * @dev Function that is always called after value is transferred. If value is being minted
     * it checks if the destination tokenId already exists, if not it adds it to the slot array.
     * Else if the tokenId is being burned, the source tokenId is removed from the slot array.
     * @param _from The wallet address from which the tokenId is being transferred from
     * @param _to The wallet address to which the tokenId is being transferred to
     * @param _fromTokenId The tokenId that is being transferred from
     * @param _toTokenId The tokenId that is being transferred to
     * @param _slot The slot number being examined
     * @param _slotName The name of the slot
     * @param _value The value being transferred
     */
    function _afterValueTransfer(
        address _from,
        address _to,
        uint256 _fromTokenId,
        uint256 _toTokenId,
        uint256 _slot,
        string memory _slotName,
        uint256 _value
    ) internal virtual {
        if (_from == address(0) && _fromTokenId == 0 && !_tokenExistsInSlot(_slot, _toTokenId)) {
            _addTokenToSlotEnumeration(_slot, _toTokenId);
        } else if (_to == address(0) && _toTokenId == 0 && _tokenExistsInSlot(_slot, _fromTokenId)) {
            _removeTokenFromSlotEnumeration(_slot, _fromTokenId);
        }

        //currently unused
        _slotName;
        _value;
    }

    /// @dev Low level function to add a slot struct to the slot array
    /// @param _slotData The slot data to add to the slot array
    function _addSlotToAllSlotsEnumeration(SlotData memory _slotData) private {
        allSlotsIndex[_slotData.slot] = _allSlots.length;
        _allSlots.push(_slotData);
    }

    /// @dev Low level function to add a tokenId to the array of tokens in a slot
    /// @param _slot The slot number to add the tokenId to
    /// @param _tokenId The tokenId to add to the slot
    function _addTokenToSlotEnumeration(uint256 _slot, uint256 _tokenId) private {
        SlotData storage slotData = _allSlots[allSlotsIndex[_slot]];
        _slotTokensIndex[_slot][_tokenId] = slotData.slotTokens.length;
        slotData.slotTokens.push(_tokenId);
    }

    /// @dev Low level function to remove a tokenId from the array of tokens in a slot
    /// @param _slot The slot number to remove the tokenId from
    /// @param _tokenId The tokenId to remove from the slot
    function _removeTokenFromSlotEnumeration(uint256 _slot, uint256 _tokenId) private {
        SlotData storage slotData = _allSlots[allSlotsIndex[_slot]];
        uint256 lastTokenIndex = slotData.slotTokens.length - 1;
        uint256 lastTokenId = slotData.slotTokens[lastTokenIndex];
        uint256 tokenIndex = _slotTokensIndex[_slot][_tokenId];

        slotData.slotTokens[tokenIndex] = lastTokenId;
        _slotTokensIndex[_slot][lastTokenId] = tokenIndex;

        delete _slotTokensIndex[_slot][_tokenId];
        slotData.slotTokens.pop();
    }
}
