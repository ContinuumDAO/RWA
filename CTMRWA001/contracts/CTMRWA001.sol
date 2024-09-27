// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./IERC721.sol";
import "./ICTMRWA001.sol";
import "./IERC721Receiver.sol";
import "./ICTMRWA001Receiver.sol";
import "./extensions/IERC721Enumerable.sol";
import "./extensions/IERC721Metadata.sol";
import "./extensions/ICTMRWA001Metadata.sol";
import "./periphery/interface/ICTMRWA001MetadataDescriptor.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
//import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract CTMRWA001 is Context, ICTMRWA001Metadata, IERC721Enumerable {
    using Strings for *;
    using SafeERC20 for IERC20;
    //using SafeMath for uint256;

    // The ID is a unique identifier linking contracts across chains - same ID on each chains
    uint256 public ID;
    // regulator is the wallet address of the Regulator, if this is a Security, else zero length
    string public regulator;
    address public tokenAdmin;
    address public ctmRwa001XChain;

    string constant TYPE = "CTMRWA001/";
    

    event SetMetadataDescriptor(address indexed metadataDescriptor);

    struct TokenContract {
        string chainIdStr;
        string contractStr;
    }

    TokenContract[] public tokenContract;

    struct TokenData {
        uint256 id;
        uint256 slot;
        uint256 balance;
        address owner;
        uint256 dividendUnclaimed;
        address approved;
        address[] valueApprovals;
    }

    struct AddressData {
        uint256[] ownedTokens;
        mapping(uint256 => uint256) ownedTokensIndex;
        mapping(address => bool) approvals;
    }

    string private _name;
    string private _symbol;
    uint8 private _decimals;
    string public baseURI;
    string public constant version = "1";
    uint256 private _tokenIdGenerator;

    // id => (approval => allowance)
    // @dev _approvedValues cannot be defined within TokenData, cause struct containing mappings cannot be constructed.
    mapping(uint256 => mapping(address => uint256)) private _approvedValues;

    TokenData[] private _allTokens;

    // key: id
    mapping(uint256 => uint256) private _allTokensIndex;

    mapping(address => AddressData) private _addressData;

    ICTMRWA001MetadataDescriptor public metadataDescriptor;


    constructor(
        address _tokenAdmin,
        string memory tokenName_, 
        string memory symbol_, 
        uint8 decimals_,
        string memory baseURI_,
        address _ctmRwa001XChain
    ) {
        tokenAdmin = _tokenAdmin;
        _tokenIdGenerator = 1;
        _name = tokenName_;
        _symbol = symbol_;
        _decimals = decimals_;
        baseURI = baseURI_;
        ctmRwa001XChain = _ctmRwa001XChain;
        

        _addTokenContract(cID().toString(), _toLower(address(this).toHexString()));
    }
    
    modifier onlyTokenAdmin() {
        require(msg.sender == tokenAdmin, "CTMRWA001: This is an onlyTokenAdmin function");
        _;
    }

    modifier onlyGateKeeper() {
        require(msg.sender == ctmRwa001XChain, "CTMRWA001: This can only be called by CTMRWA001X");
        _;
    }
    

    function changeAdminX(address _tokenAdmin) external onlyGateKeeper returns(bool) {
        tokenAdmin = _tokenAdmin;
        return true;
    }

    function changeAdmin(address _tokenAdmin) external onlyTokenAdmin returns(bool) {
        tokenAdmin = _tokenAdmin;
        return true;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return
            interfaceId == type(IERC165).interfaceId ||
            interfaceId == type(ICTMRWA001).interfaceId ||
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(ICTMRWA001Metadata).interfaceId ||
            interfaceId == type(IERC721Enumerable).interfaceId || 
            interfaceId == type(IERC721Metadata).interfaceId;
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
    function valueDecimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    function attachId(uint256 nextID, address _tokenAdmin) external onlyGateKeeper returns(bool) {
        require(_tokenAdmin == tokenAdmin, "CTMRWA001X: attachId is an AdminOnly function");
        if(ID == 0) { // not yet attached
            ID = nextID;
            return(true);
        } else return(false);
    }

    function addXTokenInfo(
        address _tokenAdmin,
        string[] memory _chainIdsStr,
        string[] memory _contractAddrsStr
    ) external onlyGateKeeper returns(bool){
        require(_tokenAdmin == tokenAdmin, "CTMRWA001X: AdminOnly function");
        require(_chainIdsStr.length == _contractAddrsStr.length, "CTMRWA001: Length mismatch chainIds and contractAddrs");

        for(uint256 i=0; i<_chainIdsStr.length; i++) {
            if(!stringsEqual(_chainIdsStr[i], cID().toString())) {
                bool success = _addTokenContract(_chainIdsStr[i], _contractAddrsStr[i]);
                if(!success) return(false);
            }
        }

        return(true);
    }

    function _addTokenContract(string memory _chainIdStr, string memory _contractAddrStr) internal returns(bool) {

        for(uint256 i=0; i<tokenContract.length; i++) {
            if(stringsEqual(tokenContract[i].chainIdStr, _chainIdStr)) {
                return(false); // Cannot change an entry
            }
        }

        tokenContract.push(TokenContract(_chainIdStr, _contractAddrStr));
        return(true);
    }

    function getTokenContract(string memory _chainIdStr) external view returns(string memory) {
        for(uint256 i=0; i<tokenContract.length; i++) {
            if(stringsEqual(tokenContract[i].chainIdStr, _toLower(_chainIdStr))) {
                return(tokenContract[i].contractStr);
            }
        }
        return("");
    }

    // Check that another CTMRWA001 token contract is part of the same set as this one
    function checkTokenCompatibility(
        string memory _otherChainIdStr,
        string memory _otherContractStr
    ) external view returns(bool) {
        string memory otherChainIdStr = _toLower(_otherChainIdStr);
        string memory otherContractStr = _toLower(_otherContractStr);

        for(uint256 i=0; i<tokenContract.length; i++) {
            if(stringsEqual(otherChainIdStr, tokenContract[i].chainIdStr)
            && stringsEqual(otherContractStr, tokenContract[i].contractStr)) return(true);
        }
        return(false);
    }

    function idOf(uint256 tokenId_) public view virtual returns(uint256) {
        _requireMinted(tokenId_);
        return _allTokens[_allTokensIndex[tokenId_]].id;
    }
   
    function balanceOf(uint256 tokenId_) public view virtual override returns (uint256) {
        _requireMinted(tokenId_);
        return _allTokens[_allTokensIndex[tokenId_]].balance;
    }

    function dividendUnclaimedOf(uint256 tokenId_) external view virtual returns (uint256) {
        _requireMinted(tokenId_);
        return _allTokens[_allTokensIndex[tokenId_]].dividendUnclaimed;
    }

    function ownerOf(uint256 tokenId_) public view virtual override returns (address owner_) {
        _requireMinted(tokenId_);
        owner_ = _allTokens[_allTokensIndex[tokenId_]].owner;
        require(owner_ != address(0), "CTMRWA001: invalid token ID");
    }

    function slotOf(uint256 tokenId_) public view virtual override returns (uint256) {
        _requireMinted(tokenId_);
        return _allTokens[_allTokensIndex[tokenId_]].slot;
    }

    function getTokenInfo(uint256 tokenId_) external view returns(uint256,uint256,address,uint256) {
        _requireMinted(tokenId_);
        return(
            _allTokens[_allTokensIndex[tokenId_]].id,
            _allTokens[_allTokensIndex[tokenId_]].balance,
            _allTokens[_allTokensIndex[tokenId_]].owner,
            _allTokens[_allTokensIndex[tokenId_]].slot
        );
    }

    function incrementDividend(uint256 _tokenId, uint256 _dividend) internal onlyTokenAdmin returns(uint256) {
        _requireMinted(_tokenId);
        _allTokens[_allTokensIndex[_tokenId]].dividendUnclaimed += _dividend;
        return(_allTokens[_allTokensIndex[_tokenId]].dividendUnclaimed);
    }

    function decrementDividend(uint256 _tokenId, uint256 _dividend) internal returns(uint256) {
        _requireMinted(_tokenId);
        _allTokens[_tokenId].dividendUnclaimed -= _dividend;
        return(_allTokens[_tokenId].dividendUnclaimed);
    }


    function setBaseURI(string memory _baseURI) public onlyTokenAdmin {
        baseURI = _baseURI;
    }

    function contractURI() public view virtual override returns (string memory) {
        return 
            address(metadataDescriptor) != address(0) ? 
                metadataDescriptor.constructContractURI() :
                bytes(baseURI).length > 0 ? 
                    string(abi.encodePacked(baseURI, TYPE, "contract/", ID)) : 
                    "";
    }

    function slotURI(uint256 slot_) public view virtual override returns (string memory) {
        return 
            address(metadataDescriptor) != address(0) ? 
                metadataDescriptor.constructSlotURI(slot_) : 
                bytes(baseURI).length > 0 ? 
                    string(abi.encodePacked(baseURI, TYPE, "slot/", slot_.toString())) : 
                    "";
    }

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId_) public view virtual override returns (string memory) {
        _requireMinted(tokenId_);
        return 
            address(metadataDescriptor) != address(0) ? 
                metadataDescriptor.constructTokenURI(tokenId_) : 
                bytes(baseURI).length > 0 ? 
                    string(abi.encodePacked(baseURI, TYPE, tokenId_.toString())) : 
                    "";
    }

    function approve(uint256 tokenId_, address to_, uint256 value_) public payable virtual override {
        address owner = CTMRWA001.ownerOf(tokenId_);
        require(to_ != owner, "CTMRWA001: approval to current owner");

        require(_isApprovedOrOwner(_msgSender(), tokenId_), "CTMRWA001: approve caller is not owner nor approved");

        _approveValue(tokenId_, to_, value_);
    }

    function allowance(uint256 tokenId_, address operator_) public view virtual override returns (uint256) {
        _requireMinted(tokenId_);
        return _approvedValues[tokenId_][operator_];
    }

    function transferFrom(
        uint256 fromTokenId_,
        address to_,
        uint256 value_
    ) public payable virtual override returns (uint256 newTokenId) {
        this.spendAllowance(_msgSender(), fromTokenId_, value_);

        newTokenId = _createDerivedTokenId(fromTokenId_);
        _mint(to_, newTokenId, CTMRWA001.slotOf(fromTokenId_), 0);
        _transferValue(fromTokenId_, newTokenId, value_);
    }

    function transferFrom(
        uint256 fromTokenId_,
        uint256 toTokenId_,
        uint256 value_
    ) public payable virtual override {
        this.spendAllowance(_msgSender(), fromTokenId_, value_);
        _transferValue(fromTokenId_, toTokenId_, value_);
    }

    function balanceOf(address owner_) public view virtual override returns (uint256 balance) {
        require(owner_ != address(0), "CTMRWA001: balance query for the zero address");
        return _addressData[owner_].ownedTokens.length;
    }

    function balanceOfX(address owner_) external view returns (uint256 balance) {
        require(owner_ != address(0), "CTMRWA001: balance query for the zero address");
        return _addressData[owner_].ownedTokens.length;
    }

    function transferFrom(
        address from_,
        address to_,
        uint256 tokenId_
    ) public payable virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId_), "CTMRWA001: transfer caller is not owner nor approved");
        _transferTokenId(from_, to_, tokenId_);
    }

    function safeTransferFrom(
        address from_,
        address to_,
        uint256 tokenId_,
        bytes memory data_
    ) public payable virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId_), "CTMRWA001: transfer caller is not owner nor approved");
        _safeTransferTokenId(from_, to_, tokenId_, data_);
    }

    function safeTransferFrom(
        address from_,
        address to_,
        uint256 tokenId_
    ) public payable virtual override {
        safeTransferFrom(from_, to_, tokenId_, "");
    }


    function approve(address to_, uint256 tokenId_) public payable virtual override {
        address owner = CTMRWA001.ownerOf(tokenId_);
        require(to_ != owner, "CTMRWA001: approval to current owner");

        require(
            _msgSender() == owner || CTMRWA001.isApprovedForAll(owner, _msgSender()),
            "CTMRWA001: approve caller is not owner nor approved for all"
        );

        _approve(to_, tokenId_);
    }

    function getApproved(uint256 tokenId_) public view virtual override returns (address) {
        _requireMinted(tokenId_);
        return _allTokens[_allTokensIndex[tokenId_]].approved;
    }

    function setApprovalForAll(address operator_, bool approved_) public virtual override {
        _setApprovalForAll(_msgSender(), operator_, approved_);
    }

    function isApprovedForAll(address owner_, address operator_) public view virtual override returns (bool) {
        return _addressData[owner_].approvals[operator_];
    }

    function totalSupply() external view virtual override returns (uint256) {
        return _allTokens.length;
    }

    function tokenByIndex(uint256 index_) public view virtual override returns (uint256) {
        require(index_ < this.totalSupply(), "CTMRWA001: global index out of bounds");
        return _allTokens[index_].id;
    }

    function tokenOfOwnerByIndex(address owner_, uint256 index_) external view virtual override returns (uint256) {
        require(index_ < CTMRWA001.balanceOf(owner_), "CTMRWA001: owner index out of bounds");
        return _addressData[owner_].ownedTokens[index_];
    }

    function _setApprovalForAll(
        address owner_,
        address operator_,
        bool approved_
    ) internal virtual {
        require(owner_ != operator_, "CTMRWA001: approve to caller");

        _addressData[owner_].approvals[operator_] = approved_;

        emit ApprovalForAll(owner_, operator_, approved_);
    }

    function _isApprovedOrOwner(address operator_, uint256 tokenId_) internal view virtual returns (bool) {
        address owner = CTMRWA001.ownerOf(tokenId_);
        return (
            operator_ == owner ||
            CTMRWA001.isApprovedForAll(owner, operator_) ||
            CTMRWA001.getApproved(tokenId_) == operator_
        );
    }

    function isApprovedOrOwner(address operator_, uint256 tokenId_) external view onlyGateKeeper returns(bool) {
        return(_isApprovedOrOwner(operator_, tokenId_));
    }

    function spendAllowance(address operator_, uint256 tokenId_, uint256 value_) external virtual {
        uint256 currentAllowance = CTMRWA001.allowance(tokenId_, operator_);
        if (!_isApprovedOrOwner(operator_, tokenId_) && currentAllowance != type(uint256).max) {
            require(currentAllowance >= value_, "CTMRWA001: insufficient allowance");
            _approveValue(tokenId_, operator_, currentAllowance - value_);
        }
    }

    function _exists(uint256 tokenId_) internal view virtual returns (bool) {
        return _allTokens.length != 0 && _allTokens[_allTokensIndex[tokenId_]].id == tokenId_;
    }

    function _requireMinted(uint256 tokenId_) internal view virtual {
        require(_exists(tokenId_), "CTMRWA001: invalid token ID");
    }

    function requireMinted(uint256 tokenId_) external view virtual returns(bool){
        return(_exists(tokenId_));
    }

    function _mint(address to_, uint256 slot_, uint256 value_) internal virtual returns (uint256 tokenId) {
        tokenId = _createOriginalTokenId();
        _mint(to_, tokenId, slot_, value_);  
    }

    function mintFromX(address to_, uint256 slot_, uint256 value_) external onlyGateKeeper returns (uint256 tokenId) {
        return(_mint(to_, slot_, value_));
    }

    function _mint(address to_, uint256 tokenId_, uint256 slot_, uint256 value_) internal virtual {
        require(to_ != address(0), "CTMRWA001: mint to the zero address");
        require(tokenId_ != 0, "CTMRWA001: cannot mint zero tokenId");
        require(!_exists(tokenId_), "CTMRWA001: token already minted");

        _beforeValueTransfer(address(0), to_, 0, tokenId_, slot_, value_);
        __mintToken(to_, tokenId_, slot_);
        __mintValue(tokenId_, value_);
        _afterValueTransfer(address(0), to_, 0, tokenId_, slot_, value_);
    }

    function mintFromX(address to_, uint256 tokenId_, uint256 slot_, uint256 value_) external onlyGateKeeper {
        _mint(to_, tokenId_, slot_, value_);
    }

    function _mintValue(uint256 tokenId_, uint256 value_) internal virtual {
        address owner = CTMRWA001.ownerOf(tokenId_);
        uint256 slot = CTMRWA001.slotOf(tokenId_);
        _beforeValueTransfer(address(0), owner, 0, tokenId_, slot, value_);
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
            dividendUnclaimed: 0,
            approved: address(0),
            valueApprovals: new address[](0)
        });

        _addTokenToAllTokensEnumeration(tokenData);
        _addTokenToOwnerEnumeration(to_, tokenId_);

        emit Transfer(address(0), to_, tokenId_);
        emit SlotChanged(tokenId_, 0, slot_);
    }

    function _burn(uint256 tokenId_) internal virtual {
        _requireMinted(tokenId_);

        TokenData storage tokenData = _allTokens[_allTokensIndex[tokenId_]];
        address owner = tokenData.owner;
        uint256 slot = tokenData.slot;
        uint256 value = tokenData.balance;

        _beforeValueTransfer(owner, address(0), tokenId_, 0, slot, value);

        _clearApprovedValues(tokenId_);
        _removeTokenFromOwnerEnumeration(owner, tokenId_);
        _removeTokenFromAllTokensEnumeration(tokenId_);

        emit TransferValue(tokenId_, 0, value);
        emit SlotChanged(tokenId_, slot, 0);
        emit Transfer(owner, address(0), tokenId_);

        _afterValueTransfer(owner, address(0), tokenId_, 0, slot, value);
    }

    function _burnValue(uint256 tokenId_, uint256 burnValue_) internal virtual {
        _requireMinted(tokenId_);

        TokenData storage tokenData = _allTokens[_allTokensIndex[tokenId_]];
        address owner = tokenData.owner;
        uint256 slot = tokenData.slot;
        uint256 value = tokenData.balance;

        require(value >= burnValue_, "CTMRWA001: burn value exceeds balance");

        _beforeValueTransfer(owner, address(0), tokenId_, 0, slot, burnValue_);
        
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

    function removeTokenFromOwnerEnumeration(address from_, uint256 tokenId_) external onlyGateKeeper {
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

    function approveFromX(address to_, uint256 tokenId_) external onlyGateKeeper {
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

    function clearApprovedValues(uint256 tokenId_) external onlyGateKeeper {
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

    function burnValueX(uint256 fromTokenId_, uint256 value_) external onlyGateKeeper returns(bool) {
        require(_exists(fromTokenId_), "CTMRWA001: transfer from invalid token ID");

        TokenData storage fromTokenData = _allTokens[_allTokensIndex[fromTokenId_]];
        require(fromTokenData.balance >= value_, "CTMRWA001: insufficient balance for transfer");

        fromTokenData.balance -= value_;
        return(true);
    }

    function mintValueX(uint256 toTokenId_, uint256 slot_, uint256 value_) external onlyGateKeeper returns(bool) {
        require(_exists(toTokenId_), "CTMRWA001: transfer to invalid token ID");

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

        _beforeValueTransfer(from_, to_, tokenId_, tokenId_, slot, value);

        _approve(address(0), tokenId_);
        _clearApprovedValues(tokenId_);

        _removeTokenFromOwnerEnumeration(from_, tokenId_);
        _addTokenToOwnerEnumeration(to_, tokenId_);

        emit Transfer(from_, to_, tokenId_);

        _afterValueTransfer(from_, to_, tokenId_, tokenId_, slot, value);
    }

    function _safeTransferTokenId(
        address from_,
        address to_,
        uint256 tokenId_,
        bytes memory data_
    ) internal virtual {
        _transferTokenId(from_, to_, tokenId_);
        require(
            _checkOnERC721Received(from_, to_, tokenId_, data_),
            "CTMRWA001: transfer to non ERC721Receiver"
        );
    }

    function _checkOnCTMRWA001Received( 
        uint256 fromTokenId_, 
        uint256 toTokenId_, 
        uint256 value_, 
        bytes memory data_
    ) internal virtual returns (bool) {
        address to = CTMRWA001.ownerOf(toTokenId_);
        if (_isContract(to)) {
            try IERC165(to).supportsInterface(type(ICTMRWA001Receiver).interfaceId) returns (bool retval) {
                if (retval) {
                    bytes4 receivedVal = ICTMRWA001Receiver(to).onCTMRWA001Received(_msgSender(), fromTokenId_, toTokenId_, value_, data_);
                    return receivedVal == ICTMRWA001Receiver.onCTMRWA001Received.selector;
                } else {
                    return true;
                }
            } catch (bytes memory /** reason */) {
                return true;
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from_ address representing the previous owner of the given token ID
     * @param to_ target address that will receive the tokens
     * @param tokenId_ uint256 ID of the token to be transferred
     * @param data_ bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from_,
        address to_,
        uint256 tokenId_,
        bytes memory data_
    ) private returns (bool) {
        if (_isContract(to_)) {
            try 
                IERC721Receiver(to_).onERC721Received(_msgSender(), from_, tokenId_, data_) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /* solhint-disable */
    function _beforeValueTransfer(
        address from_,
        address to_,
        uint256 fromTokenId_,
        uint256 toTokenId_,
        uint256 slot_,
        uint256 value_
    ) internal virtual {}

    function _beforeValueTransferX(
        string memory fromAddressStr_,
        string memory toAddressStr,
        string memory toChainIdStr_,
        uint256 fromTokenId_,
        uint256 toTokenId_,
        uint256 slot_,
        uint256 value_
    ) internal virtual {}

    function _afterValueTransfer(
        address from_,
        address to_,
        uint256 fromTokenId_,
        uint256 toTokenId_,
        uint256 slot_,
        uint256 value_
    ) internal virtual {}
    /* solhint-enable */

    function _setMetadataDescriptor(address metadataDescriptor_) internal virtual {
        metadataDescriptor = ICTMRWA001MetadataDescriptor(metadataDescriptor_);
        emit SetMetadataDescriptor(metadataDescriptor_);
    }

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

}

