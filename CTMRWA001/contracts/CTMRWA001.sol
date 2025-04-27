// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Context} from "@openzeppelin/contracts/utils/Context.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

import {ICTMRWA001, SlotData} from "./interfaces/ICTMRWA001.sol";
import {ICTMRWA001Receiver} from "./interfaces/ICTMRWA001Receiver.sol";

import {ICTMRWA001X} from "./interfaces/ICTMRWA001X.sol";
import {ICTMRWAERC20Deployer} from "./interfaces/ICTMRWAERC20Deployer.sol";
import {ICTMRWA001Storage} from "./interfaces/ICTMRWA001Storage.sol";
import {ICTMRWA001Sentry} from "./interfaces/ICTMRWA001Sentry.sol";

/**
 * @title AssetX Multi-chain Semi-Fungible-Token for Real-World-Assets (RWAs)
 * @author @Selqui ContinuumDAO
 *
 * @notice The basic functionality relating to the Semi Fungible Token is derived from ERC3525
 *  https://eips.ethereum.org/EIPS/eip-3525
 *
 * CTMRWA001 is NOT ERC3525 compliant
 *
 * This token can be deployed many times and on multiple chains from CTMRWA001X
 */

contract CTMRWA001 is Context, ICTMRWA001 {
    using Strings for *;

    /// @notice Each CTMRWA001 corresponds to a single RWA. It is deployed on each chain

    /// @dev ID is a unique identifier linking CTMRWA001 across chains - same ID on every chain
    uint256 public ID;

    /// @dev version is the single integer version of this RWA type
    uint256 public constant version = 1;

    /// @dev rwaType is the RWA type defining CTMRWA001
    uint256 public constant rwaType = 1;

    /// @dev tokenAdmin is the address of the wallet controlling the RWA, also known as the Issuer
    address public tokenAdmin;

    /// @dev ctmRwaDeployer is the single contract on each chain which deploys the components of a CTMRWA001
    address public ctmRwaDeployer;
    
    /// @dev overrideWallet IF DEFINED by the tokenAdmin, is a wallet that can forceTransfer assets from any holder
    address public overrideWallet;

    /// @dev ctmRwaMap is the single contract which maps the multi-chain ID to the component address of each part of the CTMRWA001
    address ctmRwaMap;

    /** @dev ctmRwa001X is the single contract on each chain responsible for 
     *   Initiating deployment of an CTMRWA001 and its components
     *   Changing the tokenAdmin
     *   Defining Asset Classes (slots)
     *   Minting new value to slots
     *   Transfering value cross-chain via other ctmRwa001X contracts on other chains
     */
    address public ctmRwa001X;

    /// @dev rwa001XFallback is the contract responsible for dealing with failed cross-chain calls from ctmRwa001X
    address public rwa001XFallback;

    /// @dev dividendAddr is the contract managing dividend payments to CTMRWA001 holders
    address public dividendAddr;

    /// @dev storageAddr is the contract managing decentralized storage of information for CTMRWA001
    address public storageAddr;

    /// @dev sentryAddr is the contract controlling access to the CTMRWA001
    address public sentryAddr;

    /// @dev erc20Deployer is the contract which allows deployment an ERC20 representing any slot of a CTMRWA001
    address public erc20Deployer;

    /// @dev slotNumbers is an array holding the slots defined for this CTMRWA001
    uint256[] slotNumbers;
    /// @dev slotNames is an array holding the names of each slot in this CTMRWA001
    string[] slotNames;
    uint256[] emptyUint256;


    /// @param TokenData is the struct defining tokens in the CTMRWA001
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

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /** 
     *   @dev baseURI is a string identifying how information is stored about the CTMRWA001
     *   baseURI can be set to one of "GFLD", "IPFS", or "NONE"
     */
    string public baseURI;

    uint256 private _tokenIdGenerator;
   

    /**
     *   @dev  id => (approval => allowance)
     *   @dev _approvedValues cannot be defined within TokenData, because struct containing mappings cannot be constructed.
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
        address _ctmRwa001X
    ) {
        tokenAdmin = _tokenAdmin;
        ctmRwaMap = _map;
        _tokenIdGenerator = 1;
        _name = tokenName_;
        _symbol = symbol_;
        _decimals = decimals_;
        baseURI = baseURI_;
        ctmRwa001X = _ctmRwa001X;
        rwa001XFallback = ICTMRWA001X(ctmRwa001X).fallbackAddr();
        erc20Deployer = ICTMRWA001X(ctmRwa001X).erc20Deployer();
        ctmRwaDeployer = _msgSender();

    }
    
    modifier onlyTokenAdmin() {
        require(_msgSender() == tokenAdmin||_msgSender() == ctmRwa001X, "CTMRWA001: This is an onlyTokenAdmin function");
        _;
    }

    modifier onlyDeployer() {
        require(_msgSender() == ctmRwaDeployer, "CTMRWA001: This is an onlyDeployer function");
        _;
    }

    modifier onlyCtmMap() {
        require(_msgSender() == ctmRwaMap, "CTMRWA001: This can only be called by CTMRWAMap");
        _;
    }

    modifier onlyRwa001X() {
        require(
            _msgSender() == ctmRwa001X || 
            _msgSender() == rwa001XFallback ||
            _erc20s[_msgSender()], 
            "CTMRWA001: This can only be called by CTMRWA001X/CTMRWAERC20");
        _;
    }

    modifier onlyMinter() {
        require(
            ICTMRWA001X(ctmRwa001X).isMinter(_msgSender()) ||
            _erc20s[_msgSender()],
            "CTMRWA001: This is an onlyMinter function");
        _;
    }

    modifier onlyDividend() {
        require(_msgSender() == dividendAddr, "CTMRWA001: This can only be called by Dividend contract");
        _;
    }

    modifier onlyERC20() {
        require(_erc20s[_msgSender()], "CTMRWA001: Not a valid CTMRWAERC20");
        _;
    }
    
    /**
     * @param _tokenAdmin is the new tokenAdmin, or Issuer for this CTMRWA001
     * @dev This function can be called by the cross-chain CTMRWA001X architecture
     * @dev The override wallet for forceTransfer is reset for safety, but can be set up by the new admin
     */
    function changeAdmin(address _tokenAdmin) public onlyRwa001X returns(bool) {
        tokenAdmin = _tokenAdmin;
        overrideWallet = address(0);
        return true;
    }

    /**
     * @param _overrideWallet is the wallet address that can force transfers of any wallet
     * @dev The token admin can only call this if -
     *      They have fully described the Issuer details in CTMRWA001Storage
     *      They have gained a Security License from a Regulator, with the license details stored in LICENSE
     *      They have added the Regulator's wallet address in CTMRWA001Storage, which is public.
     * @dev override wallet should be a multi-sig or MPC TSS wallet with 2 out of -
     *      The Regulator wallet address
     *      The ContinuumDAO Governor address (requires a vote to sign)
     *      A reputable law firm's signature, with the law firm described in LEGAL in CTMRWA001Storage
     */
    function setOverrideWallet(address _overrideWallet) public onlyTokenAdmin {
        require(ICTMRWA001Storage(storageAddr).regulatorWallet() != address(0), "CTMRWA001: Token is not a Security");
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
     * @dev Sets the ID for this new CTMRWA001 after it has been deployed
     * @param nextID The ID for this CTMRWA001
     * @param _tokenAdmin The address requesting the setting of the ID
     * NOTE Only callable from CTMRWA001X
     */
    function attachId(uint256 nextID, address _tokenAdmin) external onlyRwa001X returns(bool) {
        require(_tokenAdmin == tokenAdmin, "CTMRWA001: attachId is an AdminOnly function");
        if(ID == 0) { // not yet attached
            ID = nextID;
            return(true);
        } else return(false);
    }

    /**
     * @dev Connects the CTMRWA001Dividend contract to this CTMRWA001
     * @param _dividendAddr The new CTMRWA001Dividend contract address
     */
    function attachDividend(address _dividendAddr) external onlyCtmMap returns(bool) {
        require(dividendAddr == address(0), "CTMRWA001: Cannot reset the dividend contract address");
        dividendAddr = _dividendAddr;
        return(true);
    }

    /**
     * @dev Connects the CTMRWA001Storage contract to this CTMRWA001
     * @param _storageAddr The new CTMRWA001Storage contract address
     */
    function attachStorage(address _storageAddr) external onlyCtmMap returns(bool) {
        require(storageAddr == address(0), "CTMRWA001: Cannot reset the storage contract address");
        storageAddr = _storageAddr;
        return(true);
    }

    /**
     * @dev Connects the CTMRWA001Sentry contract to this CTMRWA001
     * @param _sentryAddr The new CTMRWA001Sentry contract address
     */
    function attachSentry(address _sentryAddr) external onlyCtmMap returns(bool) {
        require(sentryAddr == address(0), "CTMRWA001: Cannot reset the sentry contract address");
        sentryAddr = _sentryAddr;
        return(true);
    }

    /**
     * @notice Returns the id (NOT ID) of a user held token in this CTMRWA001
     * @param _tokenId The unique tokenId (instance of TokenData)
     */
    function idOf(uint256 _tokenId) public view virtual returns(uint256) {
        requireMinted(_tokenId);
        return _allTokens[_allTokensIndex[_tokenId]].id;
    }
   
    /**
     * @notice Returns the fungible balance of a user held token in this CTMRWA001
     * @param _tokenId The unique tokenId (instance of TokenData)
     */
    function balanceOf(uint256 _tokenId) public view virtual override returns (uint256) {
        requireMinted(_tokenId);
        return _allTokens[_allTokensIndex[_tokenId]].balance;
    }

    /**
     * @notice Returns the number of tokenIds owned by a wallet address
     * @param _owner The wallet address for which we want the balance of
     */
    function balanceOf(address _owner) public view virtual override returns (uint256) {
        require(_owner != address(0), "CTMRWA001: balance query for the zero address");
        return _addressData[_owner].ownedTokens.length;
    }

    /**
     * @notice Returns the address of the owner of a token in this CTMRWA001
     * @param _tokenId The unique tokenId (instance of TokenData)
     */
    function ownerOf(uint256 _tokenId) public view virtual returns (address owner_) {
        requireMinted(_tokenId);
        owner_ = _allTokens[_allTokensIndex[_tokenId]].owner;
        require(owner_ != address(0), "CTMRWA001: invalid tokenId");
    }

    /**
     * @notice Returns the slot of a token in this CTMRWA001
     * @param _tokenId The unique tokenId (instance of TokenData)
     */
    function slotOf(uint256 _tokenId) public view virtual override returns (uint256) {
        requireMinted(_tokenId);
        return _allTokens[_allTokensIndex[_tokenId]].slot;
    }

    /**
     * @notice Returns the name of a slot of a token in this CTMRWA001
     * @param _tokenId The unique tokenId (instance of TokenData)
     */
    function slotNameOf(uint256 _tokenId) public view virtual returns(string memory) {
        uint256 thisSlot = slotOf(_tokenId);
        return(slotName(thisSlot));
    }

    /**
     * @notice Returns an object with attributes of a token in this CTMRWA001
     * @param _tokenId The unique tokenId (instance of TokenData)
     */
    function getTokenInfo(uint256 _tokenId) external view returns(uint256,uint256,address,uint256,string memory, address) {
        requireMinted(_tokenId);

        uint256 slot = slotOf(_tokenId);
    
        return(
            _allTokens[_allTokensIndex[_tokenId]].id,
            _allTokens[_allTokensIndex[_tokenId]].balance,
            _allTokens[_allTokensIndex[_tokenId]].owner,
            slot,
            slotName(slot),
            tokenAdmin
        );
    }

    /**
     * @dev Lower level function, called from CTMRWA001Dividend to change the dividend rate for a slot
     * @param _slot The slot number in this CTMRWA001
     * @param _dividend The dividend rate per unit of this slot that can be claimed by holders
     */
    function changeDividendRate(uint256 _slot, uint256 _dividend) external onlyDividend returns(bool) {
        require(slotExists(_slot), "CTMRWA001: in changeDividend, slot does not exist");
        _allSlots[_allSlotsIndex[_slot]].dividendRate = _dividend;
        return(true);
    }

    /**
     * @notice Returns the dividend rate for a slot in this CTMRWA001
     * @param _slot The slot number in this CTMRWA001
     */
    function getDividendRateBySlot(uint256 _slot) external view returns(uint256) {
        require(slotExists(_slot), "CTMRWA001: in getDividendBySlot, slot does not exist");
        return(_allSlots[_allSlotsIndex[_slot]].dividendRate);
    }

    /**
     * @notice Allows a tokenAdmin to deploy an ERC20 that is an interface to ONE existing
     * slot of this CTMRWA001. It allows interaction with lending/markeplace protocols.
     * This function can only be called ONCE per slot.
     * @param _slot The slot number for which to create an ERC20
     * @param _erc20Name The name of this ERC20. It is automatically pre-pended with the slot number
     * @param _feeToken The fee token to pay for this service with. Must be configured in FeeManager
     */
    function deployErc20(
        uint256 _slot,
        string memory _erc20Name,
        address _feeToken
    ) public onlyTokenAdmin {
        require(slotExists(_slot), "CTMRWA001: Slot does not exist");
        require(_erc20Slots[_slot] == address(0), "CTMRWA001: ERC20 for this slot already exists");
        address newErc20 = ICTMRWAERC20Deployer(erc20Deployer).deployERC20(
            ID,
            _slot,
            _erc20Name,
            _symbol,
            _decimals,
            _feeToken
        );

        _erc20s[newErc20] = true;
        _erc20Slots[_slot] = newErc20;
    }

    /**
     * @notice Get the address of the ERC20 token representing a slot in this CTMRWA001
     * @param _slot The slot number
     */
    function getErc20(uint256 _slot) public view returns(address) {
        return(_erc20Slots[_slot]);
    }

   /**
    * @notice Approve the spending of the fungible balance of a tokenId in this CTMRWA001
    * @param _tokenId The tokenId
    * @param _to The address being given approval to spend from this tokenId
    * @param _value The fungible amount being given approval to spend by _to
    */
    function approve(uint256 _tokenId, address _to, uint256 _value) public payable virtual override {
        address owner = CTMRWA001.ownerOf(_tokenId);
        require(_to != owner, "CTMRWA001: approval to current owner");

        require(isApprovedOrOwner(_msgSender(), _tokenId), "CTMRWA001: approve caller is not owner nor approved");

        _approveValue(_tokenId, _to, _value);
    }

    /**
     * @notice The allowance to spend from fungible balance of a tokenId by a wallet address
     * @param _tokenId The tokenId in this CTMRWA001
     * @param _operator The wallet address for which the allowance is sought
     */
    function allowance(uint256 _tokenId, address _operator) public view virtual override returns (uint256) {
        requireMinted(_tokenId);
        return _approvedValues[_tokenId][_operator];
    }

    /**
     * @dev This lower level function is called by CTMRWA001X to transfer from the fungible balance of
     * a tokenId to another address
     * @param _fromTokenId The tokenId that the value id being transferred from
     * @param _to The wallet address that the value is being transferred to
     * @param _value The fungible value that is being transferred
     */
    function transferFrom(
        uint256 _fromTokenId,
        address _to,
        uint256 _value
    ) public override onlyRwa001X returns (uint256 newTokenId) {
        spendAllowance(_msgSender(), _fromTokenId, _value);

        string memory thisSlotName = slotNameOf(_fromTokenId);

        newTokenId = _createOriginalTokenId();
        _mint(_to, newTokenId, CTMRWA001.slotOf(_fromTokenId), thisSlotName, 0);
        _transferValue(_fromTokenId, newTokenId, _value);

    }

    /**
     * @notice Transfer value from one tokenId to another. The caller must have a spend allowance
     * to transfer the value from the tokenId.
     * @param _fromTokenId The source tokenId
     * @param _toTokenId The desination tokenId
     * @param _value The fungible value being transferred
     */
    function transferFrom(
        uint256 _fromTokenId,
        uint256 _toTokenId,
        uint256 _value
    ) public override returns(address) {

        spendAllowance(_msgSender(), _fromTokenId, _value);
        _transferValue(_fromTokenId, _toTokenId, _value);

        return(ownerOf(_toTokenId));
    }

   /**
    * @dev This lower level function is called by CTMRWA001X to transfer a tokenId from
    * one wallet addres to another. The tokenId must be approved for transfer, or owned by _from
    * @param _from The wallet address from which the tokenId is being fransferred from
    * @param _to The wallet adddress to which the tokenId is being transferred to
    * @param _tokenId The tokenId being transferred
    */
    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) public onlyRwa001X {
        require(isApprovedOrOwner(_msgSender(), _tokenId), "CTMRWA001: transfer caller is not owner nor approved");
        _transferTokenId(_from, _to, _tokenId);

    }

    /**
     * @notice Allows a the overrideWallet (if set) to force a transfer of any tokenId to another wallet
     * @param _from The wallet address from which the tokenId is being fransferred from
     * @param _to The wallet adddress to which the tokenId is being transferred to
     * @param _tokenId The tokenId being transferred
     */
    function forceTransfer(address _from, address _to, uint256 _tokenId) public returns(bool) {
        require(overrideWallet != address(0), "CTMRWA001: Licensed Security override not set up");
        require(_msgSender() == overrideWallet, "CTMRWA001: Not authorized to force a transfer");
        _transferTokenId(_from, _to, _tokenId);

        return true;
    }

    /**
     * @notice Returns the wallet address (if any) that is approved to spend any amount from a tokenId
     * @param _tokenId The tokenId being examined
     */
    function getApproved(uint256 _tokenId) public view virtual returns (address) {
        requireMinted(_tokenId);
        return _allTokens[_allTokensIndex[_tokenId]].approved;
    }

    /**
     * @notice Returns the total number of tokenIds in this CTMRWA001
     */
    function totalSupply() external view virtual returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @notice Returns the id (NOT ID) of a tokenId at an index for this CTMRWA001
     * @dev Deprecated
     */
    function tokenByIndex(uint256 _index) public view virtual returns (uint256) {
        require(_index < this.totalSupply(), "CTMRWA001: global index out of bounds");
        return _allTokens[_index].id;
    }

    /**
     * @notice Returns the tokenId for an index into an array of all tokenIds held by a wallet address
     * @param _owner The wallet address being axamined
     * @param _index The index into the wallet address
     */
    function tokenOfOwnerByIndex(address _owner, uint256 _index) external view virtual override returns (uint256) {
        require(_index < CTMRWA001.balanceOf(_owner), "CTMRWA001: owner index out of bounds");
        return _addressData[_owner].ownedTokens[_index];
    }

    /**
     * @notice An owner or a wallet that has sufficient allowance is approved to spend _value
     * @param _operator The wallet that is being given approval to spend _value
     * @param _tokenId The tokenId from which approval to spend _value is being given
     * @param _value The fungible value being given approval to spend
     */
    function spendAllowance(address _operator, uint256 _tokenId, uint256 _value) public virtual {
        uint256 currentAllowance = CTMRWA001.allowance(_tokenId, _operator);
        if (!isApprovedOrOwner(_operator, _tokenId) && currentAllowance != type(uint256).max) {
            require(currentAllowance >= _value, "CTMRWA001: insufficient allowance");
            _approveValue(_tokenId, _operator, currentAllowance - _value);
        }
    }

    /**
     * @dev tokenId exists?
     */
    function _exists(uint256 _tokenId) internal view virtual returns (bool) {
        return _allTokens.length != 0 && _allTokens[_allTokensIndex[_tokenId]].id == _tokenId;
    }

    /**
     * @notice Returns a boolean whether a tokenId has been minted (exists)
     * @param _tokenId The tokenId being examined
     */
    function requireMinted(uint256 _tokenId) public view virtual returns(bool){
        return(_exists(_tokenId));
    }

     /**
     * @notice The owner of a tokenId approves an another address to spend any 'value' from it
     * @param _to The address being granted approval to spend from tokenId
     * @param _tokenId The tokenId from which spending is allowed by _to
     */
    function approve(address _to, uint256 _tokenId) public virtual {
        address owner = ownerOf(_tokenId);
        require(_to != owner, "CTMRWA001: approval to current owner");

        require(
            _msgSender() == owner, 
            "CTMRWA001: approve caller is not owner"
        );

        _approve(_to, _tokenId);
    }

    /**
     * @notice Returns whether an operator address is approved to spend from a tokenId
     * @param _operator The address being checked to see if they are approved
     * @param _tokenId The tokenId which is being checked
     */
    function isApprovedOrOwner(address _operator, uint256 _tokenId) public view virtual returns (bool) {
        requireMinted(_tokenId);
        address owner = CTMRWA001.ownerOf(_tokenId);
        return (
            _operator == owner ||
            getApproved(_tokenId) == _operator ||
            _erc20s[_operator]
        );
    }

    /**
     * @dev Internal function minting value to a slot creating a NEW tokenId
     */
    function _mint(address _to, uint256 _slot, string memory _slotName, uint256 _value) internal returns (uint256 tokenId) {
        tokenId = _createOriginalTokenId();
        _mint(_to, tokenId, _slot, _slotName, _value);  
    }

    /**
     * @dev A lower level function calling _mint from CTMRWA001X, creating a NEW tokenId
     */
    function mintFromX(address to_, uint256 slot_, string memory _slotName, uint256 value_) external onlyMinter returns (uint256 tokenId) {
        return(_mint(to_, slot_, _slotName, value_));
    }

    /**
     * @dev Low level function to mint, being passed a new tokenId that does not already exist.
     * If whitelists are enabled, then _to is checked in CTMRWA001Sentry
     */
    function _mint(address _to, uint256 _tokenId, uint256 _slot, string memory _slotName, uint256 _value) internal {
        require(_to != address(0), "CTMRWA001: cannot mint to the zero address");
        require(_tokenId != 0, "CTMRWA001: cannot mint zero tokenId");
        require(!_exists(_tokenId), "CTMRWA001: token already minted");

        _beforeValueTransfer(address(0), _to, 0, _tokenId, _slot, _slotName, _value);
        __mintToken(_to, _tokenId, _slot);
        __mintValue(_tokenId, _value);
        _afterValueTransfer(address(0), _to, 0, _tokenId, _slot, _slotName, _value);
    }

    /**
     * @dev onlyMinter version of _mint
     */
    function mintFromX(address _to, uint256 _tokenId, uint256 _slot, string memory _slotName, uint256 _value) external onlyMinter {
        _mint(_to, _tokenId, _slot, _slotName, _value);
    }

    /**
     * @dev Mint value to an existing tokenId
     */
    function _mintValue(uint256 _tokenId, uint256 _value) internal {
        address owner = CTMRWA001.ownerOf(_tokenId);
        uint256 slot = CTMRWA001.slotOf(_tokenId);
        string memory thisSlotName = CTMRWA001.slotNameOf(_tokenId);
        _beforeValueTransfer(address(0), owner, 0, _tokenId, slot, thisSlotName, _value);
        __mintValue(_tokenId, _value);
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
        require(isApprovedOrOwner(_msgSender(), _tokenId), "CTMRWA001: caller is not token owner nor approved");
        _burn(_tokenId);
    }

    /// @dev Lowest level burn function
    function _burn(uint256 _tokenId) internal {
        requireMinted(_tokenId);

        (, uint256 bal, address owner, uint256 slot, string memory thisSlotName,) = this.getTokenInfo(_tokenId);

        _beforeValueTransfer(owner, address(0), _tokenId, 0, slot, thisSlotName, bal);

        _clearApprovedValues(_tokenId);
        _removeTokenFromOwnerEnumeration(owner, _tokenId);
        _removeTokenFromAllTokensEnumeration(_tokenId);

        emit TransferValue(_tokenId, 0, bal);
        emit SlotChanged(_tokenId, slot, 0);
        emit Transfer(owner, address(0), _tokenId);

        _afterValueTransfer(owner, address(0), _tokenId, 0, slot, thisSlotName, bal);
    }

    /// @dev Burn value from an existing tokenId
    function _burnValue(uint256 _tokenId, uint256 _value) internal {
        requireMinted(_tokenId);

        (, uint256 bal, address owner, uint256 slot, string memory thisSlotName,) = this.getTokenInfo(_tokenId);

        require(bal >= _value, "CTMRWA001: burn value exceeds balance");

        _beforeValueTransfer(owner, address(0), _tokenId, 0, slot, thisSlotName, _value);
        
        _allTokens[_allTokensIndex[_tokenId]].balance -= _value;
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

    /// @dev Call _removeTokenFromOwnerEnumeration from CTMRWA001X
    function removeTokenFromOwnerEnumeration(address _from, uint256 _tokenId) external onlyRwa001X {
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
    function _approve(address _to, uint256 _tokenId) internal {
        _allTokens[_allTokensIndex[_tokenId]].approved = _to;
        emit Approval(CTMRWA001.ownerOf(_tokenId), _to, _tokenId);
    }

    /// @dev Version of _approve callable from CTMRWA001X
    function approveFromX(address _to, uint256 _tokenId) external onlyRwa001X {
        _approve(_to, _tokenId);
    }

    /// @dev Low level function to approve spending value from tokenId by an address
    function _approveValue(
        uint256 _tokenId,
        address _to,
        uint256 _value
    ) internal {
        require(_to != address(0), "CTMRWA001: approve value to the zero address");
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

    /// @dev Version of _clearApprovedValues callable by CTMRWA001X
    function clearApprovedValues(uint256 _tokenId) external onlyRwa001X {
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
    function _transferValue(
        uint256 _fromTokenId,
        uint256 _toTokenId,
        uint256 _value
    ) internal {
        require(_exists(_fromTokenId), "CTMRWA001: transfer from invalid token ID");
        require(_exists(_toTokenId), "CTMRWA001: transfer to invalid token ID");

        TokenData storage fromTokenData = _allTokens[_allTokensIndex[_fromTokenId]];
        TokenData storage toTokenData = _allTokens[_allTokensIndex[_toTokenId]];

        require(fromTokenData.balance >= _value, "CTMRWA001: insufficient balance for transfer");
        require(fromTokenData.slot == toTokenData.slot, "CTMRWA001: transfer to token with different slot");

        string memory thisSlotName = slotNameOf(_fromTokenId);

        _beforeValueTransfer(
            fromTokenData.owner,
            toTokenData.owner,
            _fromTokenId,
            _toTokenId,
            fromTokenData.slot,
            thisSlotName,
            _value
        );

        fromTokenData.balance -= _value;
        toTokenData.balance += _value;

        emit TransferValue(_fromTokenId, _toTokenId, _value);

        _afterValueTransfer(
            fromTokenData.owner,
            toTokenData.owner,
            _fromTokenId,
            _toTokenId,
            fromTokenData.slot,
            thisSlotName,
            _value
        );

        require(
            _checkOnCTMRWA001Received(_fromTokenId, _toTokenId, _value, ""),
            "CTMRWA001: transfer rejected by CTMRWA001Receiver"
        );
    }

    /// @dev Burn 'value' from a pre-existing tokenId, callable by any 'Minter'
    function burnValueX(uint256 _fromTokenId, uint256 _value) external onlyMinter returns(bool) {
        require(_exists(_fromTokenId), "CTMRWA001: transfer from invalid token ID");

        TokenData storage fromTokenData = _allTokens[_allTokensIndex[_fromTokenId]];
        require(fromTokenData.balance >= _value, "CTMRWA001: insufficient balance for transfer");

        fromTokenData.balance -= _value;
        return(true);
    }

    /** @dev Mint 'value' to an existing tokenId, providing the slot is the same and the address is
     *  whitelisted (if whitelisting is enabled). Function is callable by any Minter
     */
    function mintValueX(uint256 _toTokenId, uint256 _slot, uint256 _value) external onlyMinter returns(bool) {
        require(_exists(_toTokenId), "CTMRWA001: transfer to invalid token ID");
        string memory toAddressStr = ownerOf(_toTokenId).toHexString();

        if(sentryAddr != address(0)) {
            require(ICTMRWA001Sentry(sentryAddr).isAllowableTransfer(toAddressStr), 
                "CTMRWA001: Transfer of value to this address is not allowable"
            );
        }

        TokenData storage toTokenData = _allTokens[_allTokensIndex[_toTokenId]];
        require(toTokenData.slot == _slot, "CTMRWA001: Destination slot is not the same as source slot");

        toTokenData.balance += _value;
        return(true);
    }

    /// @dev Transfer ownership of a tokenId to another wallet
    function _transferTokenId(
        address _from,
        address _to,
        uint256 _tokenId
    ) internal {
        require(CTMRWA001.ownerOf(_tokenId) == _from, "CTMRWA001: transfer from invalid owner");
        require(_to != address(0), "CTMRWA001: transfer to the zero address");

        uint256 slot = CTMRWA001.slotOf(_tokenId);
        uint256 value = CTMRWA001.balanceOf(_tokenId);
        string memory thisSlotName = slotNameOf(_tokenId);

        _beforeValueTransfer(_from, _to, _tokenId, _tokenId, slot, thisSlotName, value);

        _approve(address(0), _tokenId);
        _clearApprovedValues(_tokenId);

        _removeTokenFromOwnerEnumeration(_from, _tokenId);
        _addTokenToOwnerEnumeration(_to, _tokenId);

        emit Transfer(_from, _to, _tokenId);

        _afterValueTransfer(_from, _to, _tokenId, _tokenId, slot, thisSlotName, value);
    }

    /// @dev Create a new tokenId. Only callable by an ERC20 interface
    function createOriginalTokenId() external onlyERC20 returns(uint256) {
        return(_createOriginalTokenId());
    }

    /// @dev A function called when _toTokenId receives some 'value'. Designed to be overriden
    function _checkOnCTMRWA001Received( 
        uint256 _fromTokenId, 
        uint256 _toTokenId, 
        uint256 _value, 
        bytes memory _data
    ) internal virtual returns (bool) {
        
        // Unused variables
        _fromTokenId;
        _toTokenId;
        _value;
        _data;

        // Placeholder
        return(true);
    }

    /// @dev Increments the tokenId counter (does NOT create a new tokenId)
    function _createOriginalTokenId() internal returns (uint256) {
        return _tokenIdGenerator++;
    }

    /// @dev Check if an address is a contract or not
    function _isContract(address _addr) private view returns (bool) {
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        return (size > 0);
    }
    

    function cID() internal view returns (uint256) {
        return block.chainid;
    }

    /// @dev Check if two strings are equal (strictly - if the strings have the same hash)
    function stringsEqual(
        string memory a,
        string memory b
    ) public pure returns (bool) {
        bytes32 ka = keccak256(abi.encode(a));
        bytes32 kb = keccak256(abi.encode(b));
        return (ka == kb);
    }

    /// @dev Convert a string to lower case
    function _toLower(string memory str) internal pure returns (string memory) {
        bytes memory bStr = bytes(str);
        bytes memory bLower = new bytes(bStr.length);
        for (uint i = 0; i < bStr.length; i++) {
            // Uppercase character...
            if ((uint8(bStr[i]) >= 65) && (uint8(bStr[i]) <= 90)) {
                // So we add 32 to make it lowercase
                bLower[i] = bytes1(uint8(bStr[i]) + 32);
            } else {
                bLower[i] = bStr[i];
            }
        }
        return string(bLower);
    }

   
    /// @notice Return the number of slots in the CTMRWA001
    function slotCount() public view returns (uint256) {
        return _allSlots.length;
    }

    /// @notice Return arrays of all slot numbers and the corresponding slot names in this CTMRWA001
    function getAllSlots() public view returns(uint256[] memory, string[] memory) {
       return(slotNumbers, slotNames);
    }

    /**
     * @notice Returns the struct describing a slot in this CTMRWA001 by an index
     * @param _indx The index into the slot struct array
     */
    function getSlotInfoByIndex(uint256 _indx) public view returns(SlotData memory) {
        return(_allSlots[_indx]);
    }

    /// @dev Function is used to initialize the slot struct array on a newly deployed chain in this RWA
    function initializeSlotData(uint256[] memory _slotNumbers, string[] memory _slotNames) external onlyDeployer {
        require(_slotNumbers.length == _slotNames.length, "CTMRWA001: initializeSlotData length input mismatch");
        require(_allSlots.length == 0, "CTMRWA001: initializeSlotData slot data must be uninitialized");
        for(uint256 i=0; i<_slotNumbers.length; i++) {
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
        require(slotExists(_slot), "CTMRWA001: slot does not exist");
        return( _allSlots[_allSlotsIndex[_slot]].slotName);
    }

    /**
     * @notice Returns the slot number at an index into the array of structs of the slots
     * @param _index The index into the struct array
     */
    function slotByIndex(uint256 _index) public view returns (uint256) {
        require(_index < slotCount(), "CTMRWA001: slot index out of bounds");
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
     * @notice Returns the total fungible balance in a slot in this CTMRWA001
     * @param _slot The slot being examined
     */
    function totalSupplyInSlot(uint256 _slot) external view returns (uint256) {
        uint256 nTokens = this.tokenSupplyInSlot(_slot);

        uint256 total;
        uint256 tokenId;

        for(uint256 i=0; i<nTokens; i++) {
            tokenId = tokenInSlotByIndex(_slot, i);
            total += balanceOf(tokenId);
        }

        return(total);
    }

    /**
     * @notice Returns the tokenId in a slot by an index number
     * @param _slot The slot being examined
     * @param _index The index into the slot tokens
     */
    function tokenInSlotByIndex(uint256 _slot, uint256 _index) public view returns (uint256) {
        require(_index < this.tokenSupplyInSlot(_slot), "CTMRWA001: slot token index out of bounds");
        return _allSlots[_allSlotsIndex[_slot]].slotTokens[_index];
    }

    /// @dev Check if a tokenId exists in a slot
    function _tokenExistsInSlot(uint256 _slot, uint256 _tokenId) private view returns (bool) {
        SlotData storage slotData = _allSlots[_allSlotsIndex[_slot]];
        return slotData.slotTokens.length > 0 && slotData.slotTokens[_slotTokensIndex[_slot][_tokenId]] == _tokenId;
    }

    /// @dev Interface to _createSlot from only CTMRWA001X
    function createSlotX(uint256 _slot, string memory _slotName) external onlyRwa001X {
        _createSlot(_slot, _slotName);
    }

    /// @dev Create a new slot struct and add it to the slot struct array
    function _createSlot(uint256 _slot, string memory _slotName) internal {
        require(!slotExists(_slot), "CTMRWA001: slot already exists");
        require(bytes(_name).length <= 128, "CTMRWA001: Slot name > 128 characters");
        SlotData memory slotData = SlotData({
            slot: _slot,
            slotName: _slotName,
            dividendRate: 0,
            slotTokens: new uint256[](0)
        });
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
        require(slotExists(_slot), "CTMRWA001: Slot does not exist");

        if(sentryAddr != address(0)) {
            string memory toAddressStr = _to.toHexString();
            require(ICTMRWA001Sentry(sentryAddr).isAllowableTransfer(toAddressStr), 
                "CTMRWA001: Transfer of the token to this address is not allowable"
            );
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

