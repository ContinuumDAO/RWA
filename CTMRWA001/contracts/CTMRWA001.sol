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


contract CTMRWA001 is Context, ICTMRWA001 {
    using Strings for *;

    // The ID is a unique identifier linking contracts across chains - same ID on each chains
    uint256 public ID;

    uint256 public constant version = 1;
    uint256 public constant rwaType = 1;

    address public ctmRwaDeployer;
    address public tokenAdmin;
    address public overrideWallet;
    address ctmRwaMap;
    address public ctmRwa001X;
    address public rwa001XFallback;
    address public dividendAddr;
    address public storageAddr;
    address public sentryAddr;
    address public erc20Deployer;

    uint256[] slotNumbers;
    string[] slotNames;
    uint256[] emptyUint256;


    struct TokenData {
        uint256 id;
        uint256 slot;
        uint256 balance;
        address owner;
        address approved;
        address[] valueApprovals;
    }

    struct AddressData {
        uint256[] ownedTokens;
        mapping(uint256 => uint256) ownedTokensIndex;
    }

    

    // slot => tokenId => index
    mapping(uint256 => mapping(uint256 => uint256)) private _slotTokensIndex;

    SlotData[] public _allSlots;

    // slot => index
    mapping(uint256 => uint256) public _allSlotsIndex;

    string private _name;
    string private _symbol;
    uint8 private _decimals;
    string public baseURI;
    uint256 private _tokenIdGenerator;
   

    // id => (approval => allowance)
    // @dev _approvedValues cannot be defined within TokenData, cause struct containing mappings cannot be constructed.
    mapping(uint256 => mapping(address => uint256)) private _approvedValues;

    TokenData[] private _allTokens;

    // key: id
    mapping(uint256 => uint256) private _allTokensIndex;

    mapping(address => AddressData) private _addressData;

    mapping(address => bool) private _erc20s;
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
    
    function changeAdmin(address _tokenAdmin) public onlyRwa001X returns(bool) {
        tokenAdmin = _tokenAdmin;
        return true;
    }

    function setOverrideWallet(address _overrideWallet) public onlyTokenAdmin {
        require(ICTMRWA001Storage(storageAddr).regulatorWallet() != address(0), "CTMRWA001: Token is not a Security");
        overrideWallet = _overrideWallet;
    }

    /**
     * @dev Returns the token collection name.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals the token uses for value.
     */
    function valueDecimals() external view virtual returns (uint8) {
        return _decimals;
    }

    function attachId(uint256 nextID, address _tokenAdmin) external onlyRwa001X returns(bool) {
        require(_tokenAdmin == tokenAdmin, "CTMRWA001: attachId is an AdminOnly function");
        if(ID == 0) { // not yet attached
            ID = nextID;
            return(true);
        } else return(false);
    }

    function attachDividend(address _dividendAddr) external onlyCtmMap returns(bool) {
        require(dividendAddr == address(0), "CTMRWA001: Cannot reset the dividend contract address");
        dividendAddr = _dividendAddr;
        return(true);
    }

    function attachStorage(address _storageAddr) external onlyCtmMap returns(bool) {
        require(storageAddr == address(0), "CTMRWA001: Cannot reset the storage contract address");
        storageAddr = _storageAddr;
        return(true);
    }

    function attachSentry(address _sentryAddr) external onlyCtmMap returns(bool) {
        require(sentryAddr == address(0), "CTMRWA001: Cannot reset the sentry contract address");
        sentryAddr = _sentryAddr;
        return(true);
    }

    function idOf(uint256 tokenId_) public view virtual returns(uint256) {
        requireMinted(tokenId_);
        return _allTokens[_allTokensIndex[tokenId_]].id;
    }
   
    function balanceOf(uint256 tokenId_) public view virtual override returns (uint256) {
        requireMinted(tokenId_);
        return _allTokens[_allTokensIndex[tokenId_]].balance;
    }

    function ownerOf(uint256 tokenId_) public view virtual returns (address owner_) {
        requireMinted(tokenId_);
        owner_ = _allTokens[_allTokensIndex[tokenId_]].owner;
        require(owner_ != address(0), "CTMRWA001: invalid token ID");
    }

    function slotOf(uint256 tokenId_) public view virtual override returns (uint256) {
        requireMinted(tokenId_);
        return _allTokens[_allTokensIndex[tokenId_]].slot;
    }

    function slotNameOf(uint256 _tokenId) public view virtual returns(string memory) {
        uint256 thisSlot = slotOf(_tokenId);
        return(slotName(thisSlot));
    }

    function getTokenInfo(uint256 tokenId_) external view returns(uint256,uint256,address,uint256,string memory, address) {
        requireMinted(tokenId_);

        uint256 slot = slotOf(tokenId_);
    
        return(
            _allTokens[_allTokensIndex[tokenId_]].id,
            _allTokens[_allTokensIndex[tokenId_]].balance,
            _allTokens[_allTokensIndex[tokenId_]].owner,
            slot,
            slotName(slot),
            tokenAdmin
        );
    }

    function changeDividendRate(uint256 _slot, uint256 _dividend) external onlyDividend returns(bool) {
        require(slotExists(_slot), "CTMRWA001: in changeDividend, slot does not exist");
        _allSlots[_allSlotsIndex[_slot]].dividendRate = _dividend;

        return(true);
    }

    function getDividendRateBySlot(uint256 _slot) external view returns(uint256) {
        require(slotExists(_slot), "CTMRWA001: in getDividendBySlot, slot does not exist");
        return(_allSlots[_allSlotsIndex[_slot]].dividendRate);
    }


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


    function getErc20(uint256 _slot) public view returns(address) {
        return(_erc20Slots[_slot]);
    }

   
    function approve(uint256 tokenId_, address to_, uint256 value_) public payable virtual override {
        address owner = CTMRWA001.ownerOf(tokenId_);
        require(to_ != owner, "CTMRWA001: approval to current owner");

        require(isApprovedOrOwner(_msgSender(), tokenId_), "CTMRWA001: approve caller is not owner nor approved");

        _approveValue(tokenId_, to_, value_);
    }

    function allowance(uint256 tokenId_, address operator_) public view virtual override returns (uint256) {
        requireMinted(tokenId_);
        return _approvedValues[tokenId_][operator_];
    }

    function transferFrom(
        uint256 fromTokenId_,
        address to_,
        uint256 value_
    ) public override onlyRwa001X returns (uint256 newTokenId) {
        spendAllowance(_msgSender(), fromTokenId_, value_);

        string memory thisSlotName = slotNameOf(fromTokenId_);

        newTokenId = _createDerivedTokenId(fromTokenId_);
        _mint(to_, newTokenId, CTMRWA001.slotOf(fromTokenId_), thisSlotName, 0);
        _transferValue(fromTokenId_, newTokenId, value_);

    }

    function transferFrom(
        uint256 fromTokenId_,
        uint256 toTokenId_,
        uint256 value_
    ) public override returns(address) {

        spendAllowance(_msgSender(), fromTokenId_, value_);
        _transferValue(fromTokenId_, toTokenId_, value_);

        return(ownerOf(toTokenId_));
    }

    function balanceOf(address owner_) public view virtual override returns (uint256 balance) {
        require(owner_ != address(0), "CTMRWA001: balance query for the zero address");
        return _addressData[owner_].ownedTokens.length;
    }

    function transferFrom(
        address from_,
        address to_,
        uint256 tokenId_
    ) public onlyRwa001X {
        require(isApprovedOrOwner(_msgSender(), tokenId_), "CTMRWA001: transfer caller is not owner nor approved");
        _transferTokenId(from_, to_, tokenId_);

    }

    function forceTransfer(address _from, address _to, uint256 _tokenId) public returns(bool) {
        require(overrideWallet != address(0), "CTMRWA001: Licensed Security override not set up");
        _transferTokenId(_from, _to, _tokenId);

        return true;
    }


    function getApproved(uint256 tokenId_) public view virtual returns (address) {
        requireMinted(tokenId_);
        return _allTokens[_allTokensIndex[tokenId_]].approved;
    }

    function totalSupply() external view virtual returns (uint256) {
        return _allTokens.length;
    }

    function tokenByIndex(uint256 index_) public view virtual returns (uint256) {
        require(index_ < this.totalSupply(), "CTMRWA001: global index out of bounds");
        return _allTokens[index_].id;
    }

    function tokenOfOwnerByIndex(address owner_, uint256 index_) external view virtual override returns (uint256) {
        require(index_ < CTMRWA001.balanceOf(owner_), "CTMRWA001: owner index out of bounds");
        return _addressData[owner_].ownedTokens[index_];
    }

    function spendAllowance(address operator_, uint256 tokenId_, uint256 value_) public virtual {
        uint256 currentAllowance = CTMRWA001.allowance(tokenId_, operator_);
        if (!isApprovedOrOwner(operator_, tokenId_) && currentAllowance != type(uint256).max) {
            require(currentAllowance >= value_, "CTMRWA001: insufficient allowance");
            _approveValue(tokenId_, operator_, currentAllowance - value_);
        }
    }

    function _exists(uint256 tokenId_) internal view virtual returns (bool) {
        return _allTokens.length != 0 && _allTokens[_allTokensIndex[tokenId_]].id == tokenId_;
    }

    function requireMinted(uint256 tokenId_) public view virtual returns(bool){
        return(_exists(tokenId_));
    }

    function _mint(address to_, uint256 slot_, string memory _slotName, uint256 value_) internal virtual returns (uint256 tokenId) {
        tokenId = _createOriginalTokenId();
        _mint(to_, tokenId, slot_, _slotName, value_);  
    }

    function mintFromX(address to_, uint256 slot_, string memory _slotName, uint256 value_) external onlyMinter returns (uint256 tokenId) {
        return(_mint(to_, slot_, _slotName, value_));
    }

    function _mint(address to_, uint256 tokenId_, uint256 slot_, string memory _slotName, uint256 value_) internal virtual {
        require(to_ != address(0), "CTMRWA001: cannot mint to the zero address");
        require(tokenId_ != 0, "CTMRWA001: cannot mint zero tokenId");
        require(!_exists(tokenId_), "CTMRWA001: token already minted");

        _beforeValueTransfer(address(0), to_, 0, tokenId_, slot_, _slotName, value_);
        __mintToken(to_, tokenId_, slot_);
        __mintValue(tokenId_, value_);
        _afterValueTransfer(address(0), to_, 0, tokenId_, slot_, value_);
    }

    function mintFromX(address to_, uint256 tokenId_, uint256 slot_, string memory _slotName, uint256 value_) external onlyMinter {
        _mint(to_, tokenId_, slot_, _slotName, value_);
    }

    function _mintValue(uint256 tokenId_, uint256 value_) internal virtual {
        address owner = CTMRWA001.ownerOf(tokenId_);
        uint256 slot = CTMRWA001.slotOf(tokenId_);
        string memory thisSlotName = CTMRWA001.slotNameOf(tokenId_);
        _beforeValueTransfer(address(0), owner, 0, tokenId_, slot, thisSlotName, value_);
        __mintValue(tokenId_, value_);
        _afterValueTransfer(address(0), owner, 0, tokenId_, slot, value_);
    }

    function __mintValue(uint256 tokenId_, uint256 value_) private {
        _allTokens[_allTokensIndex[tokenId_]].balance += value_;
        emit TransferValue(0, tokenId_, value_);
    }

    function __mintToken(address to_, uint256 tokenId_, uint256 slot_) private {
        TokenData memory tokenData = TokenData({
            id: tokenId_,
            slot: slot_,
            balance: 0,
            owner: to_,
            approved: address(0),
            valueApprovals: new address[](0)
        });

        _addTokenToAllTokensEnumeration(tokenData);
        _addTokenToOwnerEnumeration(to_, tokenId_);

        emit Transfer(address(0), to_, tokenId_);
        emit SlotChanged(tokenId_, 0, slot_);
    }

    function burn(uint256 tokenId_) public virtual {
        require(isApprovedOrOwner(_msgSender(), tokenId_), "CTMRWA001: caller is not token owner nor approved");
        _burn(tokenId_);
    }

    function _burn(uint256 tokenId_) internal virtual {
        requireMinted(tokenId_);

        TokenData storage tokenData = _allTokens[_allTokensIndex[tokenId_]];
        address owner = tokenData.owner;
        uint256 slot = tokenData.slot;
        string memory thisSlotName = slotNameOf(tokenId_);
        uint256 value = tokenData.balance;

        _beforeValueTransfer(owner, address(0), tokenId_, 0, slot, thisSlotName, value);

        _clearApprovedValues(tokenId_);
        _removeTokenFromOwnerEnumeration(owner, tokenId_);
        _removeTokenFromAllTokensEnumeration(tokenId_);

        emit TransferValue(tokenId_, 0, value);
        emit SlotChanged(tokenId_, slot, 0);
        emit Transfer(owner, address(0), tokenId_);

        _afterValueTransfer(owner, address(0), tokenId_, 0, slot, value);
    }

    function _burnValue(uint256 tokenId_, uint256 burnValue_) internal virtual {
        requireMinted(tokenId_);

        TokenData storage tokenData = _allTokens[_allTokensIndex[tokenId_]];
        address owner = tokenData.owner;
        uint256 slot = tokenData.slot;
        string memory thisSlotName = slotNameOf(tokenId_);
        uint256 value = tokenData.balance;

        require(value >= burnValue_, "CTMRWA001: burn value exceeds balance");

        _beforeValueTransfer(owner, address(0), tokenId_, 0, slot, thisSlotName, burnValue_);
        
        tokenData.balance -= burnValue_;
        emit TransferValue(tokenId_, 0, burnValue_);
        
        _afterValueTransfer(owner, address(0), tokenId_, 0, slot, burnValue_);
    }

    function _addTokenToOwnerEnumeration(address to_, uint256 tokenId_) private {
        _allTokens[_allTokensIndex[tokenId_]].owner = to_;

        _addressData[to_].ownedTokensIndex[tokenId_] = _addressData[to_].ownedTokens.length;
        _addressData[to_].ownedTokens.push(tokenId_);
    }

    function _removeTokenFromOwnerEnumeration(address from_, uint256 tokenId_) private {
        _allTokens[_allTokensIndex[tokenId_]].owner = address(0);

        AddressData storage ownerData = _addressData[from_];
        uint256 lastTokenIndex = ownerData.ownedTokens.length - 1;
        uint256 lastTokenId = ownerData.ownedTokens[lastTokenIndex];
        uint256 tokenIndex = ownerData.ownedTokensIndex[tokenId_];

        ownerData.ownedTokens[tokenIndex] = lastTokenId;
        ownerData.ownedTokensIndex[lastTokenId] = tokenIndex;

        delete ownerData.ownedTokensIndex[tokenId_];
        ownerData.ownedTokens.pop();
    }

    function removeTokenFromOwnerEnumeration(address from_, uint256 tokenId_) external onlyRwa001X {
        _removeTokenFromOwnerEnumeration(from_, tokenId_);
    }

    function _addTokenToAllTokensEnumeration(TokenData memory tokenData_) private {
        _allTokensIndex[tokenData_.id] = _allTokens.length;
        _allTokens.push(tokenData_);
    }

    function _removeTokenFromAllTokensEnumeration(uint256 tokenId_) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId_];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        TokenData memory lastTokenData = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenData; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenData.id] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId_];
        _allTokens.pop();
    }

    function _approve(address to_, uint256 tokenId_) internal virtual {
        _allTokens[_allTokensIndex[tokenId_]].approved = to_;
        emit Approval(CTMRWA001.ownerOf(tokenId_), to_, tokenId_);
    }

    function approveFromX(address to_, uint256 tokenId_) external onlyRwa001X {
        _approve(to_, tokenId_);
    }

    function _approveValue(
        uint256 tokenId_,
        address to_,
        uint256 value_
    ) internal virtual {
        require(to_ != address(0), "CTMRWA001: approve value to the zero address");
        if (!_existApproveValue(to_, tokenId_)) {
            _allTokens[_allTokensIndex[tokenId_]].valueApprovals.push(to_);
        }
        _approvedValues[tokenId_][to_] = value_;

        emit ApprovalValue(tokenId_, to_, value_);
    }

    function _clearApprovedValues(uint256 tokenId_) internal virtual {
        TokenData storage tokenData = _allTokens[_allTokensIndex[tokenId_]];
        uint256 length = tokenData.valueApprovals.length;
        for (uint256 i = 0; i < length; i++) {
            address approval = tokenData.valueApprovals[i];
            delete _approvedValues[tokenId_][approval];
        }
        delete tokenData.valueApprovals;
    }

    function clearApprovedValues(uint256 tokenId_) external onlyRwa001X {
        _clearApprovedValues(tokenId_);
    }

    function _existApproveValue(address to_, uint256 tokenId_) internal view virtual returns (bool) {
        uint256 length = _allTokens[_allTokensIndex[tokenId_]].valueApprovals.length;
        for (uint256 i = 0; i < length; i++) {
            if (_allTokens[_allTokensIndex[tokenId_]].valueApprovals[i] == to_) {
                return true;
            }
        }
        return false;
    }

    function _transferValue(
        uint256 fromTokenId_,
        uint256 toTokenId_,
        uint256 value_
    ) internal virtual {
        require(_exists(fromTokenId_), "CTMRWA001: transfer from invalid token ID");
        require(_exists(toTokenId_), "CTMRWA001: transfer to invalid token ID");

        TokenData storage fromTokenData = _allTokens[_allTokensIndex[fromTokenId_]];
        TokenData storage toTokenData = _allTokens[_allTokensIndex[toTokenId_]];

        require(fromTokenData.balance >= value_, "CTMRWA001: insufficient balance for transfer");
        require(fromTokenData.slot == toTokenData.slot, "CTMRWA001: transfer to token with different slot");

        _beforeValueTransfer(
            fromTokenData.owner,
            toTokenData.owner,
            fromTokenId_,
            toTokenId_,
            fromTokenData.slot,
            slotNameOf(fromTokenId_),
            value_
        );

        fromTokenData.balance -= value_;
        toTokenData.balance += value_;

        emit TransferValue(fromTokenId_, toTokenId_, value_);

        _afterValueTransfer(
            fromTokenData.owner,
            toTokenData.owner,
            fromTokenId_,
            toTokenId_,
            fromTokenData.slot,
            value_
        );

        require(
            _checkOnCTMRWA001Received(fromTokenId_, toTokenId_, value_, ""),
            "CTMRWA001: transfer rejected by CTMRWA001Receiver"
        );
    }

    function burnValueX(uint256 fromTokenId_, uint256 value_) external onlyMinter returns(bool) {
        require(_exists(fromTokenId_), "CTMRWA001: transfer from invalid token ID");

        TokenData storage fromTokenData = _allTokens[_allTokensIndex[fromTokenId_]];
        require(fromTokenData.balance >= value_, "CTMRWA001: insufficient balance for transfer");

        fromTokenData.balance -= value_;
        return(true);
    }

    function mintValueX(uint256 toTokenId_, uint256 slot_, uint256 value_) external onlyMinter returns(bool) {
        require(_exists(toTokenId_), "CTMRWA001: transfer to invalid token ID");
        string memory toAddressStr = ownerOf(toTokenId_).toHexString();

        if(sentryAddr != address(0)) {
            require(ICTMRWA001Sentry(sentryAddr).isAllowableTransfer(toAddressStr), 
                "CTMRWA001: Transfer of value to this address is not allowable"
            );
        }

        TokenData storage toTokenData = _allTokens[_allTokensIndex[toTokenId_]];
        require(toTokenData.slot == slot_, "CTMRWA001: Destination slot is not the same as source slot");

        toTokenData.balance += value_;
        return(true);
    }

    function _transferTokenId(
        address from_,
        address to_,
        uint256 tokenId_
    ) internal virtual {
        require(CTMRWA001.ownerOf(tokenId_) == from_, "CTMRWA001: transfer from invalid owner");
        require(to_ != address(0), "CTMRWA001: transfer to the zero address");

        uint256 slot = CTMRWA001.slotOf(tokenId_);
        uint256 value = CTMRWA001.balanceOf(tokenId_);
        string memory thisSlotName = slotNameOf(tokenId_);

        _beforeValueTransfer(from_, to_, tokenId_, tokenId_, slot, thisSlotName, value);

        _approve(address(0), tokenId_);
        _clearApprovedValues(tokenId_);

        _removeTokenFromOwnerEnumeration(from_, tokenId_);
        _addTokenToOwnerEnumeration(to_, tokenId_);

        emit Transfer(from_, to_, tokenId_);

        _afterValueTransfer(from_, to_, tokenId_, tokenId_, slot, value);
    }

    function createOriginalTokenId() external onlyERC20 returns(uint256) {
        return(_createOriginalTokenId());
    }

    function _checkOnCTMRWA001Received( 
        uint256 fromTokenId_, 
        uint256 toTokenId_, 
        uint256 value_, 
        bytes memory data_
    ) internal virtual returns (bool) {
        address to = CTMRWA001.ownerOf(toTokenId_);
        
        // Placeholder
        return(true);
    }

    /* solhint-enable */

    function _createOriginalTokenId() internal virtual returns (uint256) {
        return _tokenIdGenerator++;
    }

    function _createDerivedTokenId(uint256 fromTokenId_) internal virtual returns (uint256) {
        fromTokenId_;
        return _createOriginalTokenId();
    }

    function _isContract(address addr_) private view returns (bool) {
        uint32 size;
        assembly {
            size := extcodesize(addr_)
        }
        return (size > 0);
    }
    

    function cID() internal view returns (uint256) {
        return block.chainid;
    }

    function stringsEqual(
        string memory a,
        string memory b
    ) public pure returns (bool) {
        bytes32 ka = keccak256(abi.encode(a));
        bytes32 kb = keccak256(abi.encode(b));
        return (ka == kb);
    }

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

    function approve(address to_, uint256 tokenId_) public virtual override {
        address owner = ownerOf(tokenId_);
        require(to_ != owner, "CTMRWA001: approval to current owner");

        require(
            _msgSender() == owner, 
            "CTMRWA001: approve caller is not owner"
        );

        _approve(to_, tokenId_);
    }

    function isApprovedOrOwner(address operator_, uint256 tokenId_) public view virtual returns (bool) {
        requireMinted(tokenId_);
        address owner = CTMRWA001.ownerOf(tokenId_);
        return (
            operator_ == owner ||
            getApproved(tokenId_) == operator_ ||
            _erc20s[operator_]
        );
    }


    function slotCount() public view virtual override returns (uint256) {
        return _allSlots.length;
    }

    function getAllSlots() public view returns(uint256[] memory, string[] memory) {
       return(slotNumbers, slotNames);
    }

    function getSlotInfoByIndex(uint256 _indx) public view returns(SlotData memory) {
        return(_allSlots[_indx]);
    }

    function initializeSlotData(uint256[] memory _slotNumbers, string[] memory _slotNames) external onlyDeployer {
        require(_slotNumbers.length == _slotNames.length, "CTMRWA001: initializeSlotData length input mismatch");
        require(_allSlots.length == 0, "CTMRWA001: initializeSlotData slot data must be uninitialized");
        for(uint256 i=0; i<_slotNumbers.length; i++) {
            _allSlots.push(SlotData(_slotNumbers[i], _slotNames[i], 0, emptyUint256));
        }
        slotNumbers = _slotNumbers;
        slotNames = _slotNames;
    }

    function slotName(uint256 _slot) public view virtual returns (string memory) {
        require(slotExists(_slot), "CTMRWA001: slot does not exist");
        return( _allSlots[_allSlotsIndex[_slot]].slotName);
    }

    function slotByIndex(uint256 index_) public view virtual override returns (uint256) {
        require(index_ < slotCount(), "CTMRWA001: slot index out of bounds");
        return _allSlots[index_].slot;
    }

    function slotExists(uint256 slot_) public view virtual returns (bool) {
        return _allSlots.length != 0 && _allSlots[_allSlotsIndex[slot_]].slot == slot_;
    }

    function tokenSupplyInSlot(uint256 slot_) external view virtual override returns (uint256) {
        if (!slotExists(slot_)) {
            return 0;
        }
        return _allSlots[_allSlotsIndex[slot_]].slotTokens.length;
    }

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

    function tokenInSlotByIndex(uint256 slot_, uint256 index_) public view virtual override returns (uint256) {
        require(index_ < this.tokenSupplyInSlot(slot_), "CTMRWA001: slot token index out of bounds");
        return _allSlots[_allSlotsIndex[slot_]].slotTokens[index_];
    }

    function _tokenExistsInSlot(uint256 slot_, uint256 tokenId_) private view returns (bool) {
        SlotData storage slotData = _allSlots[_allSlotsIndex[slot_]];
        return slotData.slotTokens.length > 0 && slotData.slotTokens[_slotTokensIndex[slot_][tokenId_]] == tokenId_;
    }

    function createSlotX(uint256 _slot, string memory _slotName) external onlyRwa001X {
        _createSlot(_slot, _slotName);
    }

    function _createSlot(uint256 _slot, string memory _slotName) internal virtual {
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
   
    function _beforeValueTransfer(
        address _from,
        address _to,
        uint256 _fromTokenId,
        uint256 _toTokenId,
        uint256 _slot,
        string memory _slotName,
        uint256 _value
    ) internal virtual {
        if (_from == address(0) && _fromTokenId == 0 && !slotExists(_slot)) {
            _createSlot(_slot, _slotName);
        }

        if(sentryAddr != address(0)) {
            string memory toAddressStr = _to.toHexString();
            require(ICTMRWA001Sentry(sentryAddr).isAllowableTransfer(toAddressStr), 
                "CTMRWA001: Transfer of the token to this address is not allowable"
            );
        }

        //currently unused
        _toTokenId;
        _value;
    }

    function _afterValueTransfer(
        address from_,
        address to_,
        uint256 fromTokenId_,
        uint256 toTokenId_,
        uint256 slot_,
        uint256 value_
    ) internal virtual {
        if (from_ == address(0) && fromTokenId_ == 0 && !_tokenExistsInSlot(slot_, toTokenId_)) {
            _addTokenToSlotEnumeration(slot_, toTokenId_);
        } else if (to_ == address(0) && toTokenId_ == 0 && _tokenExistsInSlot(slot_, fromTokenId_)) {
            _removeTokenFromSlotEnumeration(slot_, fromTokenId_);
        }

        //currently unused
        value_;
    }

    function _addSlotToAllSlotsEnumeration(SlotData memory slotData) private {
        _allSlotsIndex[slotData.slot] = _allSlots.length;
        _allSlots.push(slotData);
    }

    function _addTokenToSlotEnumeration(uint256 slot_, uint256 tokenId_) private {
        SlotData storage slotData = _allSlots[_allSlotsIndex[slot_]];
        _slotTokensIndex[slot_][tokenId_] = slotData.slotTokens.length;
        slotData.slotTokens.push(tokenId_);
    }

    function _removeTokenFromSlotEnumeration(uint256 slot_, uint256 tokenId_) private {
        SlotData storage slotData = _allSlots[_allSlotsIndex[slot_]];
        uint256 lastTokenIndex = slotData.slotTokens.length - 1;
        uint256 lastTokenId = slotData.slotTokens[lastTokenIndex];
        uint256 tokenIndex = _slotTokensIndex[slot_][tokenId_];

        slotData.slotTokens[tokenIndex] = lastTokenId;
        _slotTokensIndex[slot_][lastTokenId] = tokenIndex;

        delete _slotTokensIndex[slot_][tokenId_];
        slotData.slotTokens.pop();
    }

}

