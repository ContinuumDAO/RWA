// SPDX-License-Identifier: MIT 

pragma solidity ^0.8.22;

import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

import { ICTMRWA1, SlotData, Address, Uint } from "./ICTMRWA1.sol";
import { ICTMRWA1Receiver } from "./ICTMRWA1Receiver.sol";

import { ICTMRWA1X } from "../crosschain/ICTMRWA1X.sol";
import { ICTMRWADeployer } from "../deployment/ICTMRWADeployer.sol";
import { ICTMRWAERC20Deployer } from "../deployment/ICTMRWAERC20Deployer.sol";

import { ICTMRWA1Sentry } from "../sentry/ICTMRWA1Sentry.sol";
import { ICTMRWA1Storage } from "../storage/ICTMRWA1Storage.sol";
import {Address, Uint} from "../CTMRWAUtils.sol";

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
contract CTMRWA1 is ReentrancyGuard, ICTMRWA1 {
    using Strings for *;

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
    address ctmRwaMap;

    /**
     * @dev ctmRwa1X is the single contract on each chain responsible for
     *   Initiating deployment of an CTMRWA1 and its components
     *   Changing the tokenAdmin
     *   Defining Asset Classes (slots)
     *   Minting new value to slots
     *   Transfering value cross-chain via other ctmRwa1X contracts on other chains
     */
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
    uint256[] emptyUint256;

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
    mapping(uint256 => uint256) public _allSlotsIndex;

    /// @dev owner => slot => balance
    mapping(address => mapping(uint256 => uint256)) private _balance;

    /// @dev slot => total supply in this slot
    mapping(uint256 => uint256) private _supplyInSlot;

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
        // require(msg.sender == tokenAdmin || msg.sender == ctmRwa1X, "RWA: onlyTokenAdmin");
        if (msg.sender != tokenAdmin && msg.sender != ctmRwa1X) revert CTMRWA1_Unauthorized(Address.Sender);
        _;
    }

    modifier onlyErc20Deployer() {
        // require(_erc20s[msg.sender], "RWA: Only CTMRWAERC20");
        if (!_erc20s[msg.sender]) revert CTMRWA1_Unauthorized(Address.Sender);
        _;
    }

    modifier onlyTokenFactory() {
        // require(msg.sender == tokenFactory, "RWA: Only TokenFactory");
        if (msg.sender != tokenFactory) revert CTMRWA1_Unauthorized(Address.Sender);
        _;
    }

    modifier onlyCtmMap() {
        // require(msg.sender == ctmRwaMap, "RWA: onlyCTMRWAMap");
        if (msg.sender != ctmRwaMap) revert CTMRWA1_Unauthorized(Address.Sender);
        _;
    }

    modifier onlyRwa1X() {
        // require(msg.sender == ctmRwa1X || msg.sender == rwa1XFallback, "RWA: Only CTMRWA1X");
        if (msg.sender != ctmRwa1X && msg.sender != rwa1XFallback) revert CTMRWA1_Unauthorized(Address.Sender);
        _;
    }

    modifier onlyMinter() {
        // require(ICTMRWA1X(ctmRwa1X).isMinter(msg.sender) || _erc20s[msg.sender], "RWA: onlyMinter");
        if (!ICTMRWA1X(ctmRwa1X).isMinter(msg.sender) && !_erc20s[msg.sender]) revert CTMRWA1_Unauthorized(Address.Sender);
        _;
    }

    modifier onlyDividend() {
        // require(msg.sender == dividendAddr, "RWA: onlyDividend");
        if (msg.sender != dividendAddr) revert CTMRWA1_Unauthorized(Address.Sender);
        _;
    }

    modifier onlyERC20() {
        // require(_erc20s[msg.sender], "RWA: onlyCTMRWAERC20");
        if (!_erc20s[msg.sender]) revert CTMRWA1_Unauthorized(Address.Sender);
        _;
    }

    /**
     * @param _tokenAdmin is the new tokenAdmin, or Issuer for this CTMRWA1
     * @dev This function can be called by the cross-chain CTMRWA1X architecture
     * @dev The override wallet for forceTransfer is reset for safety, but can be set up by the new admin
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
        // require(ICTMRWA1Storage(storageAddr).regulatorWallet() != address(0), "RWA: Not a Security");
        if (ICTMRWA1Storage(storageAddr).regulatorWallet() == address(0)) revert CTMRWA1_IsZeroAddress(Address.Regulator);
        overrideWallet = _overrideWallet;
    }

    /**
     * @notice Returns the token collection name.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @notice Returns the token collection symbol.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @notice Returns the number of decimals the token uses for value.
     */
    function valueDecimals() external view virtual returns (uint8) {
        return _decimals;
    }

    /**
     * @dev Sets the ID for this new CTMRWA1 after it has been deployed
     * @param nextID The ID for this CTMRWA1
     * @param _tokenAdmin The address requesting the setting of the ID
     * NOTE Only callable from CTMRWA1X
     */
    function attachId(uint256 nextID, address _tokenAdmin) external onlyRwa1X returns (bool) {
        // require(_tokenAdmin == tokenAdmin, "RWA: attachId is AdminOnly");
        if (_tokenAdmin != tokenAdmin) revert CTMRWA1_Unauthorized(Address.TokenAdmin);
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
     */
    function attachDividend(address _dividendAddr) external onlyCtmMap returns (bool) {
        // require(dividendAddr == address(0), "RWA: Cannot reset dividend contract");
        if (dividendAddr != address(0)) revert CTMRWA1_NotZeroAddress(Address.Dividend);
        dividendAddr = _dividendAddr;
        return (true);
    }

    /**
     * @dev Connects the CTMRWA1Storage contract to this CTMRWA1
     * @param _storageAddr The new CTMRWA1Storage contract address
     */
    function attachStorage(address _storageAddr) external onlyCtmMap returns (bool) {
        // require(storageAddr == address(0), "RWA: Cannot reset storage contract");
        if (storageAddr != address(0)) revert CTMRWA1_NotZeroAddress(Address.Storage);
        storageAddr = _storageAddr;
        return (true);
    }

    /**
     * @dev Connects the CTMRWA1Sentry contract to this CTMRWA1
     * @param _sentryAddr The new CTMRWA1Sentry contract address
     */
    function attachSentry(address _sentryAddr) external onlyCtmMap returns (bool) {
        // require(sentryAddr == address(0), "RWA: Cannot reset sentry contract");
        if (sentryAddr != address(0)) revert CTMRWA1_NotZeroAddress(Address.Sentry);
        sentryAddr = _sentryAddr;
        return (true);
    }

    /**
     * @notice Returns the id (NOT ID) of a user held token in this CTMRWA1
     * @param _tokenId The unique tokenId (instance of TokenData)
     */
    function idOf(uint256 _tokenId) public view virtual returns (uint256) {
        if (!_exists(_tokenId)) revert CTMRWA1_IDNonExistent(_tokenId);
        return _allTokens[_allTokensIndex[_tokenId]].id;
    }

    /**
     * @notice Returns the fungible balance of a user held token in this CTMRWA1
     * @param _tokenId The unique tokenId (instance of TokenData)
     */
    function balanceOf(uint256 _tokenId) public view virtual override returns (uint256) {
        if (!_exists(_tokenId)) revert CTMRWA1_IDNonExistent(_tokenId);
        return _allTokens[_allTokensIndex[_tokenId]].balance;
    }

    /**
     * @notice Returns the number of tokenIds owned by a wallet address
     * @param _owner The wallet address for which we want the balance of
     */
    function balanceOf(address _owner) public view virtual override returns (uint256) {
        // require(_owner != address(0), "RWA: zero address");
        if (_owner == address(0)) revert CTMRWA1_IsZeroAddress(Address.Owner);
        return _addressData[_owner].ownedTokens.length;
    }

    /**
     * @notice Returns the total balance of all tokenIds owned by a wallet address in a slot
     * @param _owner The wallet address for which we want the balance of in the slot
     * @param _slot The slot number for which to find the balance
     */
    function balanceOf(address _owner, uint256 _slot) public view returns (uint256) {
        // require(_owner != address(0), "RWA: zero address");
        if (_owner == address(0)) revert CTMRWA1_IsZeroAddress(Address.Owner);
        // require(slotExists(_slot), "RWA: slot not exist");
        if (!slotExists(_slot)) revert CTMRWA1_InvalidSlot(_slot);
        return _balance[_owner][_slot];
    }

    /**
     * @notice Returns the address of the owner of a token in this CTMRWA1
     * @param _tokenId The unique tokenId (instance of TokenData)
     */
    function ownerOf(uint256 _tokenId) public view virtual returns (address) {
        if (!_exists(_tokenId)) revert CTMRWA1_IDNonExistent(_tokenId);
        address owner = _allTokens[_allTokensIndex[_tokenId]].owner;
        // require(owner != address(0), "RWA: zero address");
        if (owner == address(0)) revert CTMRWA1_IsZeroAddress(Address.Owner);
        return owner;
    }

    /**
     * @notice Returns the slot of a token in this CTMRWA1
     * @param _tokenId The unique tokenId (instance of TokenData)
     */
    function slotOf(uint256 _tokenId) public view virtual override returns (uint256) {
        if (!_exists(_tokenId)) revert CTMRWA1_IDNonExistent(_tokenId);
        return _allTokens[_allTokensIndex[_tokenId]].slot;
    }

    /**
     * @notice Returns the name of a slot of a token in this CTMRWA1
     * @param _tokenId The unique tokenId (instance of TokenData)
     */
    function slotNameOf(uint256 _tokenId) public view virtual returns (string memory) {
        uint256 thisSlot = slotOf(_tokenId);
        return (slotName(thisSlot));
    }

    /**
     * @notice Returns an object with attributes of a token in this CTMRWA1
     * @param _tokenId The unique tokenId (instance of TokenData)
     */
    function getTokenInfo(uint256 _tokenId)
        external
        view
        returns (uint256, uint256, address, uint256, string memory, address)
    {
        if (!_exists(_tokenId)) revert CTMRWA1_IDNonExistent(_tokenId);

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
     * @dev Lower level function, called from CTMRWA1Dividend to change the dividend rate for a slot
     * @param _slot The slot number in this CTMRWA1
     * @param _dividend The dividend rate per unit of this slot that can be claimed by holders
     */
    function changeDividendRate(uint256 _slot, uint256 _dividend) external onlyDividend returns (bool) {
        // require(slotExists(_slot), "RWA: slot not exist");
        if (!slotExists(_slot)) revert CTMRWA1_InvalidSlot(_slot);
        _allSlots[_allSlotsIndex[_slot]].dividendRate = _dividend;
        return (true);
    }

    /**
     * @notice Returns the dividend rate for a slot in this CTMRWA1
     * @param _slot The slot number in this CTMRWA1
     */
    function getDividendRateBySlot(uint256 _slot) external view returns (uint256) {
        // require(slotExists(_slot), "RWA: slot not exist");
        if (!slotExists(_slot)) revert CTMRWA1_InvalidSlot(_slot);
        return (_allSlots[_allSlotsIndex[_slot]].dividendRate);
    }

    /**
     * @notice Allows a tokenAdmin to deploy an ERC20 that is an interface to ONE existing
     * slot of this CTMRWA1. It allows interaction with lending/markeplace protocols.
     * This function can only be called ONCE per slot.
     * @param _slot The slot number for which to create an ERC20
     * @param _erc20Name The name of this ERC20. It is automatically pre-pended with the slot number
     * @param _feeToken The fee token to pay for this service with. Must be configured in FeeManager
     */
    function deployErc20(uint256 _slot, string memory _erc20Name, address _feeToken) public onlyTokenAdmin {
        // require(slotExists(_slot), "RWA: Slot does not exist");
        if (!slotExists(_slot)) revert CTMRWA1_InvalidSlot(_slot);
        // require(_erc20Slots[_slot] == address(0), "RWA: ERC20 slot already exists");
        if (_erc20Slots[_slot] != address(0)) revert CTMRWA1_NotZeroAddress(Address.RWAERC20);
        // require(bytes(_erc20Name).length <= 128, "RWA: ERC20 name > 128");
        if (bytes(_erc20Name).length > 128) revert CTMRWA1_NameTooLong();
        address newErc20 =
            ICTMRWAERC20Deployer(erc20Deployer).deployERC20(ID, RWA_TYPE, VERSION, _slot, _erc20Name, _symbol, _feeToken);

        _erc20s[newErc20] = true;
        _erc20Slots[_slot] = newErc20;
    }

    /**
     * @notice Get the address of the ERC20 token representing a slot in this CTMRWA1
     * @param _slot The slot number
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
        // require(_to != owner, "RWA: approval current owner");
        if (_to == owner) revert CTMRWA1_Unauthorized(Address.To);

        // require(isApprovedOrOwner(msg.sender, _tokenId), "RWA: approve caller not owner/approved");
        if (isApprovedOrOwner(msg.sender, _tokenId))

        _approveValue(_tokenId, _to, _value);
    }

    /**
     * @notice The allowance to spend from fungible balance of a tokenId by a wallet address
     * @param _tokenId The tokenId in this CTMRWA1
     * @param _operator The wallet address for which the allowance is sought
     */
    function allowance(uint256 _tokenId, address _operator) public view virtual override returns (uint256) {
        if (!_exists(_tokenId)) revert CTMRWA1_IDNonExistent(_tokenId);
        return _approvedValues[_tokenId][_operator];
    }

    /**
     * @dev This lower level function is called by CTMRWA1X to transfer from the fungible balance of
     * a tokenId to another address
     * @param _fromTokenId The tokenId that the value id being transferred from
     * @param _to The wallet address that the value is being transferred to
     * @param _value The fungible value that is being transferred
     */
    function transferFrom(uint256 _fromTokenId, address _to, uint256 _value)
        public
        override
        onlyRwa1X
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
     */
    function transferFrom(uint256 _fromTokenId, uint256 _toTokenId, uint256 _value) public override nonReentrant returns (address) {
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
    function transferFrom(address _from, address _to, uint256 _tokenId) public onlyRwa1X {
        require(isApprovedOrOwner(msg.sender, _tokenId), "RWA: transfer caller not owner/approved");
        _transferTokenId(_from, _to, _tokenId);
    }

    /**
     * @notice Allows a the overrideWallet (if set) to force a transfer of any tokenId to another wallet
     * @param _from The wallet address from which the tokenId is being fransferred from
     * @param _to The wallet adddress to which the tokenId is being transferred to
     * @param _tokenId The tokenId being transferred
     */
    function forceTransfer(address _from, address _to, uint256 _tokenId) public returns (bool) {
        // require(overrideWallet != address(0), "RWA: Licensed Security override not set up");
        if (overrideWallet == address(0)) revert CTMRWA1_IsZeroAddress(Address.Override);
        // require(msg.sender == overrideWallet, "RWA: Cannot forceTransfer");
        if (msg.sender != overrideWallet) revert CTMRWA1_Unauthorized(Address.Sender);
        _transferTokenId(_from, _to, _tokenId);

        return true;
    }

    /**
     * @notice Returns the wallet address (if any) that is approved to spend any amount from a tokenId
     * @param _tokenId The tokenId being examined
     */
    function getApproved(uint256 _tokenId) public view virtual returns (address) {
        if (!_exists(_tokenId)) revert CTMRWA1_IDNonExistent(_tokenId);
        return _allTokens[_allTokensIndex[_tokenId]].approved;
    }

    /**
     * @notice Returns the total number of tokenIds in this CTMRWA1
     */
    function totalSupply() external view virtual returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @notice Returns the id (NOT ID) of a tokenId at an index for this CTMRWA1
     * @dev Deprecated
     */
    function tokenByIndex(uint256 _index) public view virtual returns (uint256) {
        require(_index < this.totalSupply(), "RWA: global index out of bounds");
        return _allTokens[_index].id;
    }

    /**
     * @notice Returns the tokenId for an index into an array of all tokenIds held by a wallet address
     * @param _owner The wallet address being axamined
     * @param _index The index into the wallet address
     */
    function tokenOfOwnerByIndex(address _owner, uint256 _index) external view virtual override returns (uint256) {
        require(_index < CTMRWA1.balanceOf(_owner), "RWA: owner index out of bounds");
        return _addressData[_owner].ownedTokens[_index];
    }

    /**
     * @notice An owner or a wallet that has sufficient allowance is approved to spend _value
     * @param _operator The wallet that is being given approval to spend _value
     * @param _tokenId The tokenId from which approval to spend _value is being given
     * @param _value The fungible value being given approval to spend
     */
    function spendAllowance(address _operator, uint256 _tokenId, uint256 _value) public virtual {
        uint256 currentAllowance = CTMRWA1.allowance(_tokenId, _operator);
        if (!isApprovedOrOwner(_operator, _tokenId) && currentAllowance != type(uint256).max) {
            require(currentAllowance >= _value, "RWA: insufficient allowance");
            _approveValue(_tokenId, _operator, currentAllowance - _value);
        }
    }

    /**
     * @dev tokenId exists?
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
        // require(_to != owner, "RWA: approval current owner");
        if (_to == owner) revert CTMRWA1_Unauthorized(Address.To);

        // require(msg.sender == owner, "RWA: approve caller not owner");
        if (msg.sender != owner) revert CTMRWA1_Unauthorized(Address.Sender);

        _approve(_to, _tokenId);
    }

    /**
     * @notice Returns whether an operator address is approved to spend from a tokenId
     * @param _operator The address being checked to see if they are approved
     * @param _tokenId The tokenId which is being checked
     */
    function isApprovedOrOwner(address _operator, uint256 _tokenId) public view virtual returns (bool) {
        if (!_exists(_tokenId)) revert CTMRWA1_IDNonExistent(_tokenId);
        address owner = CTMRWA1.ownerOf(_tokenId);
        return (_operator == owner || getApproved(_tokenId) == _operator || _erc20s[_operator]);
    }

    /**
     * @dev Internal function minting value to a slot creating a NEW tokenId
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
     */
    function mintFromX(address _to, uint256 _slot, string memory _slotName, uint256 _value)
        external
        onlyMinter
        returns (uint256 tokenId)
    {
        return (_mint(_to, _slot, _slotName, _value));
    }

    /**
     * @dev Low level function to mint, being passed a new tokenId that does not already exist.
     * If whitelists are enabled, then _to is checked in CTMRWA1Sentry
     */
    function _mint(address _to, uint256 _tokenId, uint256 _slot, string memory _slotName, uint256 _value) internal {
        // require(_to != address(0), "RWA: mint to zero address");
        if (_to == address(0)) revert CTMRWA1_IsZeroAddress(Address.To);
        // require(_tokenId != 0, "RWA: mint zero tokenId");
        if (_tokenId == 0) revert CTMRWA1_IsZeroUint(Uint.TokenId);
        // require(!_exists(_tokenId), "RWA: already minted");
        if (_exists(_tokenId)) revert CTMRWA1_IDExists(_tokenId);

        _beforeValueTransfer(address(0), _to, 0, _tokenId, _slot, _slotName, _value);
        __mintToken(_to, _tokenId, _slot);
        __mintValue(_tokenId, _value);
        _balance[_to][_slot] += _value;
        _supplyInSlot[_slot] += _value;
        _afterValueTransfer(address(0), _to, 0, _tokenId, _slot, _slotName, _value);
    }

    /**
     * @dev onlyMinter version of _mint
     */
    function mintFromX(address _to, uint256 _tokenId, uint256 _slot, string memory _slotName, uint256 _value)
        external
        onlyMinter
    {
        _mint(_to, _tokenId, _slot, _slotName, _value);
    }

    /**
     * @dev Mint value to an existing tokenId
     */
    function _mintValue(uint256 _tokenId, uint256 _value) private {
        address owner = CTMRWA1.ownerOf(_tokenId);
        uint256 slot = CTMRWA1.slotOf(_tokenId);
        string memory thisSlotName = CTMRWA1.slotNameOf(_tokenId);
        _beforeValueTransfer(address(0), owner, 0, _tokenId, slot, thisSlotName, _value);
        __mintValue(_tokenId, _value);
        _balance[owner][slot] += _value;
        _supplyInSlot[slot] += _value;
        _afterValueTransfer(address(0), owner, 0, _tokenId, slot, thisSlotName, _value);
    }

    /// @dev Lowest level mint function
    function __mintValue(uint256 _tokenId, uint256 _value) private {
        _allTokens[_allTokensIndex[_tokenId]].balance += _value;
        emit TransferValue(0, _tokenId, _value);
    }

    /// @dev Mint a new token using a new tokenId
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
    function burn(uint256 _tokenId) public virtual {
        // require(isApprovedOrOwner(msg.sender, _tokenId), "RWA: caller not owner/approved");
        if (!isApprovedOrOwner(msg.sender, _tokenId)) revert CTMRWA1_Unauthorized(Address.Sender);
        _burn(_tokenId);
    }

    /// @dev Lowest level burn function
    function _burn(uint256 _tokenId) private {
        if (!_exists(_tokenId)) revert CTMRWA1_IDNonExistent(_tokenId);

        (, uint256 bal, address owner, uint256 slot, string memory thisSlotName,) = this.getTokenInfo(_tokenId);

        _beforeValueTransfer(owner, address(0), _tokenId, 0, slot, thisSlotName, bal);

        _clearApprovedValues(_tokenId);
        _removeTokenFromOwnerEnumeration(owner, _tokenId);
        _removeTokenFromAllTokensEnumeration(_tokenId);

        _balance[owner][slot] -= bal;
        _supplyInSlot[slot] -= bal;

        emit TransferValue(_tokenId, 0, bal);
        emit SlotChanged(_tokenId, slot, 0);
        emit Transfer(owner, address(0), _tokenId);

        _afterValueTransfer(owner, address(0), _tokenId, 0, slot, thisSlotName, bal);
    }

    /// @dev Burn value from an existing tokenId
    function _burnValue(uint256 _tokenId, uint256 _value) internal {
        if (!_exists(_tokenId)) revert CTMRWA1_IDNonExistent(_tokenId);

        (, uint256 bal, address owner, uint256 slot, string memory thisSlotName,) = this.getTokenInfo(_tokenId);

        // require(bal >= _value, "RWA: burn > balance");
        if (bal < _value) revert CTMRWA1_InsufficientBalance();

        _beforeValueTransfer(owner, address(0), _tokenId, 0, slot, thisSlotName, _value);

        _allTokens[_allTokensIndex[_tokenId]].balance -= _value;
        _balance[owner][slot] -= _value;
        _supplyInSlot[slot] -= _value;

        emit TransferValue(_tokenId, 0, _value);

        _afterValueTransfer(owner, address(0), _tokenId, 0, slot, thisSlotName, _value);
    }

    /// @dev Add new tokenId to the array of tokens held by an address
    function _addTokenToOwnerEnumeration(address _to, uint256 _tokenId) private {
        _allTokens[_allTokensIndex[_tokenId]].owner = _to;

        _addressData[_to].ownedTokensIndex[_tokenId] = _addressData[_to].ownedTokens.length;
        _addressData[_to].ownedTokens.push(_tokenId);
    }

    /// @dev Remove an existing tokenId from the array of tokens held by an address
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
    function removeTokenFromOwnerEnumeration(address _from, uint256 _tokenId) external onlyRwa1X {
        _removeTokenFromOwnerEnumeration(_from, _tokenId);
    }

    /// @dev Add a new tokenId to the array of all tokenIds
    function _addTokenToAllTokensEnumeration(TokenData memory _tokenData) private {
        _allTokensIndex[_tokenData.id] = _allTokens.length;
        _allTokens.push(_tokenData);
    }

    /// @dev Remove an existing tokenId from the array of all tokenIds
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
    function _approve(address _to, uint256 _tokenId) private {
        _allTokens[_allTokensIndex[_tokenId]].approved = _to;
        emit Approval(CTMRWA1.ownerOf(_tokenId), _to, _tokenId);
    }

    /// @dev Version of _approve callable from CTMRWA1X
    function approveFromX(address _to, uint256 _tokenId) external onlyRwa1X {
        _approve(_to, _tokenId);
    }

    /// @dev Low level function to approve spending value from tokenId by an address
    function _approveValue(uint256 _tokenId, address _to, uint256 _value) internal {
        // require(_to != address(0), "RWA: approve to zero address");
        if (_to == address(0)) revert CTMRWA1_IsZeroAddress(Address.To);
        if (!_existApproveValue(_to, _tokenId)) {
            _allTokens[_allTokensIndex[_tokenId]].valueApprovals.push(_to);
        }
        _approvedValues[_tokenId][_to] = _value;

        emit ApprovalValue(_tokenId, _to, _value);
    }

    /// @dev Remove all permissions to spend any 'value' of tokenId by any address
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
    function clearApprovedValues(uint256 _tokenId) external onlyRwa1X {
        _clearApprovedValues(_tokenId);
    }

    /// @dev Version of _clearApprovedValues callable by CTMRWAERC20Deployer
    function clearApprovedValuesErc20(uint256 _tokenId) external onlyErc20Deployer {
        _clearApprovedValues(_tokenId);
    }

    /// @dev Check if an address has approval to spend 'value' from a tokenId
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
    function _transferValue(uint256 _fromTokenId, uint256 _toTokenId, uint256 _value) internal {
        // require(_exists(_fromTokenId), "RWA: transfer from invalid token");
        // require(_exists(_toTokenId), "RWA: transfer to invalid token");
        if (!_exists(_fromTokenId)) revert CTMRWA1_IDNonExistent(_fromTokenId);
        if (!_exists(_toTokenId)) revert CTMRWA1_IDNonExistent(_toTokenId);

        TokenData storage fromTokenData = _allTokens[_allTokensIndex[_fromTokenId]];
        TokenData storage toTokenData = _allTokens[_allTokensIndex[_toTokenId]];

        uint256 slot = fromTokenData.slot;

        // require(fromTokenData.balance >= _value, "RWA: balance<value");
        if (fromTokenData.balance < _value) revert CTMRWA1_InsufficientBalance();
        // require(slot == toTokenData.slot, "RWA: transfer to different slot");
        if (slot != toTokenData.slot) revert CTMRWA1_InvalidSlot(slot);

        string memory thisSlotName = slotNameOf(_fromTokenId);

        _beforeValueTransfer(
            fromTokenData.owner, toTokenData.owner, _fromTokenId, _toTokenId, slot, thisSlotName, _value
        );

        fromTokenData.balance -= _value;
        _balance[fromTokenData.owner][slot] -= _value;

        toTokenData.balance += _value;
        _balance[toTokenData.owner][slot] += _value;

        emit TransferValue(_fromTokenId, _toTokenId, _value);

        _afterValueTransfer(
            fromTokenData.owner, toTokenData.owner, _fromTokenId, _toTokenId, fromTokenData.slot, thisSlotName, _value
        );

        // require(_checkOnCTMRWA1Received(_fromTokenId, _toTokenId, _value, ""), "RWA: transfer rejected by receiver");
        if (!_checkOnCTMRWA1Received(_fromTokenId, _toTokenId, _value, "")) revert CTMRWA1_ReceiverRejected();
    }

    /// @dev Burn 'value' from a pre-existing tokenId, callable by any 'Minter'
    function burnValueX(uint256 _fromTokenId, uint256 _value) external onlyMinter returns (bool) {
        // require(_exists(_fromTokenId), "RWA: transfer from invalid token ID");
        if (!_exists(_fromTokenId)) revert CTMRWA1_IDNonExistent(_fromTokenId);

        TokenData storage fromTokenData = _allTokens[_allTokensIndex[_fromTokenId]];
        // require(fromTokenData.balance >= _value, "RWA: balance<value");
        if (fromTokenData.balance < _value) revert CTMRWA1_InsufficientBalance();

        fromTokenData.balance -= _value;
        return (true);
    }

    /**
     * @dev Mint 'value' to an existing tokenId, providing the slot is the same and the address is
     *  whitelisted (if whitelisting is enabled). Function is callable by any Minter
     */
    function mintValueX(uint256 _toTokenId, uint256 _slot, uint256 _value) external onlyMinter returns (bool) {
        // require(_exists(_toTokenId), "RWA: transfer to invalid token");
        if (!_exists(_toTokenId)) revert CTMRWA1_IDNonExistent(_toTokenId);
        address owner = ownerOf(_toTokenId);
        string memory toAddressStr = owner.toHexString();

        if (sentryAddr != address(0)) {
            // require(ICTMRWA1Sentry(sentryAddr).isAllowableTransfer(toAddressStr), "RWA: Transfer not WL");
            if (!ICTMRWA1Sentry(sentryAddr).isAllowableTransfer(toAddressStr)) revert CTMRWA1_WhiteListRejected(owner);
        }

        TokenData storage toTokenData = _allTokens[_allTokensIndex[_toTokenId]];
        // require(toTokenData.slot == _slot, "RWA: Dest slot != source slot");
        if (toTokenData.slot != _slot) revert CTMRWA1_InvalidSlot(_slot);

        toTokenData.balance += _value;
        return (true);
    }

    /// @dev Transfer ownership of a tokenId to another wallet
    function _transferTokenId(address _from, address _to, uint256 _tokenId) internal {
        // require(ownerOf(_tokenId) == _from, "RWA: transfer from invalid owner");
        if (ownerOf(_tokenId) != _from) revert CTMRWA1_Unauthorized(Address.Owner);
        // require(_to != address(0), "RWA: transfer to the zero address");
        if (_to == address(0)) revert CTMRWA1_IsZeroAddress(Address.To);

        uint256 slot = CTMRWA1.slotOf(_tokenId);
        uint256 value = CTMRWA1.balanceOf(_tokenId);
        string memory thisSlotName = slotNameOf(_tokenId);

        _beforeValueTransfer(_from, _to, _tokenId, _tokenId, slot, thisSlotName, value);

        _approve(address(0), _tokenId);
        _clearApprovedValues(_tokenId);

        _removeTokenFromOwnerEnumeration(_from, _tokenId);
        _balance[_from][slot] -= value;
        _addTokenToOwnerEnumeration(_to, _tokenId);
        _balance[_to][slot] += value;

        emit Transfer(_from, _to, _tokenId);

        _afterValueTransfer(_from, _to, _tokenId, _tokenId, slot, thisSlotName, value);
    }

    /// @dev Create a new tokenId. Only callable by an ERC20 interface
    function createOriginalTokenId() external onlyERC20 returns (uint256) {
        return (_createOriginalTokenId());
    }

    /// @dev A function called when _toTokenId receives some 'value'. Designed to be overriden
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
    function _createOriginalTokenId() internal returns (uint256) {
        return _tokenIdGenerator++;
    }

    /// @notice Return the number of slots in the CTMRWA1
    function slotCount() public view returns (uint256) {
        return _allSlots.length;
    }

    /// @notice Return arrays of all slot numbers and the corresponding slot names in this CTMRWA1
    function getAllSlots() public view returns (uint256[] memory, string[] memory) {
        return (slotNumbers, slotNames);
    }

    /**
     * @notice Returns the struct describing a slot in this CTMRWA1 by an index
     * @param _indx The index into the slot struct array
     */
    function getSlotInfoByIndex(uint256 _indx) public view returns (SlotData memory) {
        return (_allSlots[_indx]);
    }

    /// @dev Function is used to initialize the slot struct array on a newly deployed chain in this RWA
    function initializeSlotData(uint256[] memory _slotNumbers, string[] memory _slotNames) external onlyTokenFactory {
        // require(_slotNumbers.length == _slotNames.length, "RWA: SlotData length input mismatch");
        if (_slotNumbers.length != _slotNames.length) revert CTMRWA1_LengthMismatch(Uint.SlotLength);
        // require(_allSlots.length == 0, "RWA: Slot data must be uninit");
        if (_allSlots.length != 0) revert CTMRWA1_NonZeroUint(Uint.SlotLength);
        for (uint256 i = 0; i < _slotNumbers.length; i++) {
            _allSlots.push(SlotData(_slotNumbers[i], _slotNames[i], 0, emptyUint256));
        }
        slotNumbers = _slotNumbers;
        slotNames = _slotNames;
    }

    /**
     * @notice Returns the slot name associated with a slot number
     * @param _slot The slot number being examined
     */
    function slotName(uint256 _slot) public view returns (string memory) {
        // require(slotExists(_slot), "RWA: slot not exist");
        if (!slotExists(_slot)) revert CTMRWA1_InvalidSlot(_slot);
        return (_allSlots[_allSlotsIndex[_slot]].slotName);
    }

    /**
     * @notice Returns the slot number at an index into the array of structs of the slots
     * @param _index The index into the struct array
     */
    function slotByIndex(uint256 _index) public view returns (uint256) {
        // require(_index < slotCount(), "RWA: slot index out of bounds");
        if (_index >= slotCount()) revert CTMRWA1_OutOfBounds();
        return _allSlots[_index].slot;
    }

    /**
     * @notice Returns whether a slot number exists in the array of structs of the slots
     * @param _slot The slot number being examined
     */
    function slotExists(uint256 _slot) public view virtual returns (bool) {
        return _allSlots.length != 0 && _allSlots[_allSlotsIndex[_slot]].slot == _slot;
    }

    /**
     * @notice Returns the total number of tokenIds in a slot
     * @param _slot The slot being examined
     */
    function tokenSupplyInSlot(uint256 _slot) external view returns (uint256) {
        if (!slotExists(_slot)) {
            return 0;
        }
        return _allSlots[_allSlotsIndex[_slot]].slotTokens.length;
    }

    /**
     * @notice Returns the total fungible balance in a slot in this CTMRWA1
     * @param _slot The slot being examined
     */
    function totalSupplyInSlot(uint256 _slot) external view returns (uint256) {
        uint256 nTokens = this.tokenSupplyInSlot(_slot);

        uint256 total;
        uint256 tokenId;

        for (uint256 i = 0; i < nTokens; i++) {
            tokenId = tokenInSlotByIndex(_slot, i);
            total += balanceOf(tokenId);
        }

        return (total);
    }

    /**
     * @notice Returns the tokenId in a slot by an index number
     * @param _slot The slot being examined
     * @param _index The index into the slot tokens
     */
    function tokenInSlotByIndex(uint256 _slot, uint256 _index) public view returns (uint256) {
        // require(_index < this.tokenSupplyInSlot(_slot), "RWA: slot token index out of bounds");
        if (_index >= this.tokenSupplyInSlot(_slot)) revert CTMRWA1_OutOfBounds();
        return _allSlots[_allSlotsIndex[_slot]].slotTokens[_index];
    }

    /// @dev Check if a tokenId exists in a slot
    function _tokenExistsInSlot(uint256 _slot, uint256 _tokenId) private view returns (bool) {
        SlotData storage slotData = _allSlots[_allSlotsIndex[_slot]];
        return slotData.slotTokens.length > 0 && slotData.slotTokens[_slotTokensIndex[_slot][_tokenId]] == _tokenId;
    }

    /// @dev Interface to _createSlot from only CTMRWA1X
    function createSlotX(uint256 _slot, string memory _slotName) external onlyRwa1X {
        _createSlot(_slot, _slotName);
    }

    /// @dev Create a new slot struct and add it to the slot struct array
    function _createSlot(uint256 _slot, string memory _slotName) internal {
        SlotData memory slotData =
            SlotData({ slot: _slot, slotName: _slotName, dividendRate: 0, slotTokens: new uint256[](0) });
        _addSlotToAllSlotsEnumeration(slotData);
        slotNumbers.push(_slot);
        slotNames.push(_slotName);
        emit SlotChanged(0, 0, _slot);
    }

    /**
     * @dev Function that is always called before value is transferred. Checks that the address
     * being transferred to is whitelisted (if whitelisting is enabled). Also checks that the slot exists
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
        // require(slotExists(_slot), "RWA: Slot not exist");
        if (!slotExists(_slot)) revert CTMRWA1_InvalidSlot(_slot);

        if (sentryAddr != address(0)) {
            string memory toAddressStr = _to.toHexString();
            // require( ICTMRWA1Sentry(sentryAddr).isAllowableTransfer(toAddressStr), "RWA: Transfer token to address is not allowable");
            if (!ICTMRWA1Sentry(sentryAddr).isAllowableTransfer(toAddressStr)) revert CTMRWA1_Unauthorized(Address.To);
        }

        //currently unused
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
    function _addSlotToAllSlotsEnumeration(SlotData memory _slotData) private {
        _allSlotsIndex[_slotData.slot] = _allSlots.length;
        _allSlots.push(_slotData);
    }

    /// @dev Low level function to add a tokenId to the array of tokens in a slot
    function _addTokenToSlotEnumeration(uint256 _slot, uint256 _tokenId) private {
        SlotData storage slotData = _allSlots[_allSlotsIndex[_slot]];
        _slotTokensIndex[_slot][_tokenId] = slotData.slotTokens.length;
        slotData.slotTokens.push(_tokenId);
    }

    /// @dev Low level function to remove a tokenId from the array of tokens in a slot
    function _removeTokenFromSlotEnumeration(uint256 _slot, uint256 _tokenId) private {
        SlotData storage slotData = _allSlots[_allSlotsIndex[_slot]];
        uint256 lastTokenIndex = slotData.slotTokens.length - 1;
        uint256 lastTokenId = slotData.slotTokens[lastTokenIndex];
        uint256 tokenIndex = _slotTokensIndex[_slot][_tokenId];

        slotData.slotTokens[tokenIndex] = lastTokenId;
        _slotTokensIndex[_slot][lastTokenId] = tokenIndex;

        delete _slotTokensIndex[_slot][_tokenId];
        slotData.slotTokens.pop();
    }
}
