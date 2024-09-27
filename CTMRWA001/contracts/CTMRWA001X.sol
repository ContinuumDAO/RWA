// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/Strings.sol";
import {GovernDapp} from "./routerV2/GovernDapp.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
//import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import {ICTMRWA001X, TokenContract} from "./ICTMRWA001X.sol";
import {ICTMRWA001} from "./ICTMRWA001.sol";

//import "forge-std/console.sol";


import "./FeeManager.sol";

contract CTMRWA001X is  GovernDapp {
    using Strings for *;
    using SafeERC20 for IERC20;
    //using SafeMath for uint256;

    address public feeManager;
    address public ctmRwa001Deployer;
    string public chainIdStr;

    // This is temporary until we have a MongoDB storing this information
    mapping(address => address[]) public adminTokens;  // tokenAdmin address => array of CTMRWA001 contracts
    mapping(address => address[]) public ownedCtmRwa001;  // owner address => array of CTMRWA001 contracts
    mapping(address => mapping(uint256 => mapping(uint256 => bool))) forgottonTokens; // CTMRWA001 address => tokenId =>  slot => bool. True = forget

    event LogFallback(bytes4 selector, bytes data, bytes reason);

    event CreateNewCTMRWA001(
        address ctmRwa001Token, 
        uint256 ID, 
        address newAdmin, 
        string fromChainIdStr, 
        string fromContractStr
    );

    event SetChainContract(string[] chainIdsStr, string[] contractAddrsStr, string fromContractStr, string fromChainIdStr);
    event ChangeAdmin(uint256 ID, string currentAdminStr, string newAdminStr, string toChainIdStr);
    event ChangeAdminDest(string currentAdminStr, string newAdminStr, string fromChainIdStr);
    event AddNewChainAndToken(string fromChainIdStr, string fromContractStr, string[] chainIdsStr, string[] ctmRwa001AddrsStr);
    event LockToken(uint256 ID, address ctmRwa001Addr, uint256 nChains);

    event TransferFromSourceX(
        uint256 ID,
        string fromAddressStr,
        string toAddressStr,
        uint256 fromtokenId,
        uint256 toTokenId,
        uint256 slot,
        uint256 value,
        string fromCtmRwa001AddrStr,
        string toCtmRwa001AddrStr
    );

    event TransferToDestX(
        uint256 ID,
        string fromAddressStr,
        string toAddressStr,
        uint256 fromTokenId,
        uint256 toTokenId,
        uint256 slot,
        uint256 value,
        string fromContractStr,
        string ctmRwa001AddrStr
    );

    event MintIncrementalTokenValue(
        uint256 ID,
        address minter,
        uint256 toTokenId,
        uint256 slot,
        uint256 value
    );

    event MintTokenValueNewId(
                uint256 ID,
                address minter,
                uint256 newTokenId,
                uint256 slot,
                uint256 value
    );


//  This holds the chainID and GateKeeper contract address of a single chain
    struct ChainContract {
        string chainIdStr;
        string contractStr;
    }
//  This array holds ChainContract structs for all chains
    ChainContract[] public chainContract;

//  This holds the contract address of an individual CTMRWA001 contract and its corresponding unique ID
    struct CTMRWA001ID {
        uint256 ID;
        string contractStr;
    }

//  This is a list of all unique CTMRWA001 contracts on this chainID. Other chains may have matching IDs
    CTMRWA001ID[] public ctmRwa001Ids;

    constructor(
        address _feeManager,
        address _ctmRwa001Deployer,
        address _gov,
        address _c3callerProxy,
        address _txSender,
        uint256 _dappID
    ) GovernDapp(_gov, _c3callerProxy, _txSender, _dappID) {
        feeManager = _feeManager;
        ctmRwa001Deployer = _ctmRwa001Deployer;
        
        chainIdStr = cID().toString();
        _addChainContract(cID(), address(this));
        
    }

    function changeFeeManager(address _feeManager) external onlyGov {
        feeManager = _feeManager;
    }

    function changeTokenDeployer(address _tokenDeployer) external onlyGov {
        ctmRwa001Deployer = _tokenDeployer;
    }


    function _addChainContract(uint256 _chainId, address contractAddr) internal returns(bool) {
        string memory newChainIdStr = _chainId.toString();
        string memory contractStr = _toLower(contractAddr.toHexString());

        for(uint256 i=0; i<chainContract.length; i++) {
            if(stringsEqual(chainContract[i].chainIdStr, newChainIdStr)) {
                return(false); // Cannot change an entry
            }
        }

        chainContract.push(ChainContract(chainIdStr, contractStr));
        return(true);
    }

    function addChainContract(string memory _newChainIdStr, string memory _contractAddrStr) external returns (bool) {
        string memory newChainIdStr = _toLower(_newChainIdStr);
        string memory contractAddrStr = _toLower(_contractAddrStr);

        for(uint256 i=0; i<chainContract.length; i++) {
            if(stringsEqual(chainContract[i].chainIdStr, newChainIdStr)) {
                return(false); // Cannot change an entry
            }
        }

        chainContract.push(ChainContract(newChainIdStr, contractAddrStr));
        return(true);
    }

    function getChainContract(string memory _chainIdStr) external view returns(string memory) {
        for(uint256 i=0; i<chainContract.length; i++) {
            if(stringsEqual(chainContract[i].chainIdStr, _toLower(_chainIdStr))) {
                return(chainContract[i].contractStr);
            }
        }
        return("");
    }

    function getChainContract(uint256 _pos) public view returns(string memory, string memory) {
        return(chainContract[_pos].chainIdStr, chainContract[_pos].contractStr);
    }


    // Synchronise the CTMRWA001X GateKeeper contract address across other chains. Governance controlled
    function addXChainInfo(
        string memory _tochainIdStr,
        string memory _toContractStr,
        string[] memory _chainIdsStr,
        string[] memory _contractAddrsStr
    ) external payable onlyGov {
        require(_chainIdsStr.length>0, "CTMRWA001X: Zero length _chainIdsStr");
        require(_chainIdsStr.length == _contractAddrsStr.length, "CTMRWA001X: Length mismatch chainIds and contractAddrs");
        string memory fromContractStr = address(this).toHexString();

        string memory funcCall = "addXChainInfoX(string[],string[],string)";
        bytes memory callData = abi.encodeWithSignature(
            funcCall,
            _chainIdsStr,
            _contractAddrsStr,
            fromContractStr
        );

        c3call(_toContractStr, _tochainIdStr, callData);

    }

    function addXChainInfoX(
        string[] memory _chainIdsStr,
        string[] memory _contractAddrsStr,
        string memory _fromContractStr
    ) external onlyCaller returns(bool){
        uint256 chainId;
        bool ok;

        (, string memory fromChainIdStr,) = context();
        fromChainIdStr = _toLower(fromChainIdStr);

        for(uint256 i=0; i<_chainIdsStr.length; i++) {
            (chainId, ok) = strToUint(_chainIdsStr[i]);
            require(ok && chainId!=0,"CTMRWA001X: Illegal chainId");
            address contractAddr = stringToAddress(_contractAddrsStr[i]);
            if(chainId != cID()) {
                bool success = _addChainContract(chainId, contractAddr);
                if(!success) revert("CTMRWA001X: _addXChainInfoX failed");
            }
        }

        emit SetChainContract(_chainIdsStr, _contractAddrsStr, _fromContractStr, fromChainIdStr);

        return(true);
    }

    function _deployCTMRWA001Local(
        uint256 _ID,
        string memory tokenName_, 
        string memory symbol_, 
        uint8 decimals_,
        string memory baseURI_,
        address tokenAdmin
    ) internal returns(address) {
        bool ok = _isUniqueId(_ID);  // only checks local deployments!
        require(ok, "CTMRWA001X: A local contract with this ID already exists");

        address _ctmRwa001Token = ICTMRWA001X(ctmRwa001Deployer).deploy(
            _ID,
            tokenAdmin,
            tokenName_,
            symbol_,
            decimals_,
            baseURI_,
            address(this)
        );

        ok = _attachCTMRWA001ID(_ID,_ctmRwa001Token);
        require(ok, "CTMRWA001X: Failed to set token ID");

        ICTMRWA001(_ctmRwa001Token).changeAdminX(tokenAdmin);
        adminTokens[tokenAdmin].push(_ctmRwa001Token);

        emit CreateNewCTMRWA001(_ctmRwa001Token, _ID, tokenAdmin, cID().toString(), "");

        return(_ctmRwa001Token);
    }

    function deployAllCTMRWA001X(
        bool includeLocal,
        uint256 existingID_,
        string memory tokenName_, 
        string memory symbol_, 
        uint8 decimals_,
        string memory baseURI_,
        string[] memory toChainIdsStr_,
        string memory feeTokenStr
    ) public payable returns(uint256) {
        require(!includeLocal && existingID_>0 || includeLocal && existingID_ == 0, "CTMRWA001X: Incorrect call logic");
        uint256 nChains = toChainIdsStr_.length;
        require(bytes(feeTokenStr).length == 42, "CTMRWA001X: feeTokenStr has the wrong length");
        require(IFeeManager(feeManager).isValidFeeToken(feeTokenStr), "CTMRWA001X: Not a valid fee token");

        string memory ctmRwa001AddrStr;
        address ctmRwa001Addr;
        address currentAdmin;
        uint256 ID;

        if(includeLocal) {
            // generate a new ID
            ID = uint256(keccak256(abi.encode(
                tokenName_,
                symbol_,
                decimals_,
                block.timestamp,
                msg.sender
            )));

            ctmRwa001Addr = _deployCTMRWA001Local(ID, tokenName_, symbol_, decimals_, baseURI_, msg.sender);
            ICTMRWA001(ctmRwa001Addr).changeAdminX(msg.sender);
            
            currentAdmin = msg.sender;
        } else {  // a CTMRWA001 token must be deployed already, so use the existing ID
            ID = existingID_;
            (bool ok, address rwa001Addr) = this.getAttachedTokenAddress(ID);
            require(ok, "CTMRWA001X: ID does not exist on local chain");
            ctmRwa001Addr = rwa001Addr;
            currentAdmin = ICTMRWA001(ctmRwa001Addr).tokenAdmin();
            require(msg.sender == currentAdmin, "CTMRWA001X: Only tokenAdmin can deploy");
        }

        ctmRwa001AddrStr = _toLower(ctmRwa001Addr.toHexString());

        uint256 totalFee;
        uint256 xChainFee;

        for(uint256 i=0; i<nChains; i++) {
            xChainFee = FeeManager(feeManager).getXChainFee(toChainIdsStr_[i], FeeType.DEPLOY, feeTokenStr);
            totalFee += xChainFee;
        }
        if(includeLocal) totalFee += xChainFee;

        address feeToken = stringToAddress(feeTokenStr);
        IERC20(feeToken).transferFrom(msg.sender, address(this), totalFee);
        IERC20(feeToken).approve(feeManager, xChainFee);
        if(totalFee>0) FeeManager(feeManager).payFee(totalFee, feeTokenStr);


        for(uint256 i=0; i<nChains; i++){
            _deployCTMRWA001X(
                tokenName_, 
                symbol_, 
                decimals_, 
                baseURI_,
                toChainIdsStr_[i], 
                ctmRwa001AddrStr
            );
        }

        return(ID);

    }

    // Deploys a new CTMRWA001 instance on a destination chain, 
    // recovering the ID from a required local instance of CTMRWA001, owned by tokenAdmin
    function _deployCTMRWA001X(
        string memory tokenName_, 
        string memory symbol_, 
        uint8 decimals_,
        string memory baseURI_,
        string memory toChainIdStr_,
        string memory _ctmRwa001AddrStr
    ) internal returns (bool) {
        require(!stringsEqual(toChainIdStr_, cID().toString()), "CTMRWA001X: Not a cross-chain transfer");
        address ctmRwa001Addr = stringToAddress(_ctmRwa001AddrStr);
        address currentAdmin = ICTMRWA001(ctmRwa001Addr).tokenAdmin();
        require(msg.sender == currentAdmin, "CTMRWA001X: Only tokenAdmin can deploy");

        string memory currentAdminStr = currentAdmin.toHexString();

        uint256 ID = ICTMRWA001X(ctmRwa001Addr).ID();
        
        string memory targetStr = this.getChainContract(toChainIdStr_);
        require(bytes(targetStr).length>0, "CTMRWA001X: Target contract address not found");

        string memory funcCall = "deployCTMRWA001(string,uint256,string,string,uint8,string,string)";
        bytes memory callData = abi.encodeWithSignature(
            funcCall,
            currentAdminStr,
            ID,
            tokenName_,
            symbol_,
            decimals_,
            baseURI_,
            _ctmRwa001AddrStr
        );

        c3call(targetStr, toChainIdStr_, callData);

        return(true);
        
    }

    // Deploys a new CTMRWA001 instance on a destination chain, 
    // with the ID sent from a required local instance of CTMRWA001, owned by tokenAdmin
    function deployCTMRWA001(
        string memory _newAdminStr,
        uint256 _ID,
        string memory tokenName_, 
        string memory symbol_, 
        uint8 decimals_,
        string memory baseURI_,
        string memory _fromContractStr
    ) external onlyCaller returns(bool) {

        address newAdmin = stringToAddress(_newAdminStr);

        (, string memory fromChainIdStr,) = context();
        fromChainIdStr = _toLower(fromChainIdStr);

        address _ctmRwa001Token = ICTMRWA001X(ctmRwa001Deployer).deploy(
            _ID,
            newAdmin,
            tokenName_,
            symbol_,
            decimals_,
            baseURI_,
            address(this)
        );

        bool ok = _attachCTMRWA001ID(_ID,_ctmRwa001Token);
        require(ok, "CTMRWA001X: Failed to set token ID");

        ICTMRWA001(_ctmRwa001Token).changeAdminX(newAdmin);
        adminTokens[newAdmin].push(_ctmRwa001Token);

        emit CreateNewCTMRWA001(_ctmRwa001Token, _ID, newAdmin, fromChainIdStr, _fromContractStr);

        return(true);
    }

    function changeAdmin(address _newAdmin, uint256 _ID) external returns(bool) {
        (bool ok, address ctmRwa001Addr) = this.getAttachedTokenAddress(_ID);
        require(ok, "CTMRWA001X: The requested tokenID does not exist");
        address currentAdmin = ICTMRWA001(ctmRwa001Addr).tokenAdmin();
        require(msg.sender == currentAdmin, "CTMRWA001X: Only tokenAdmin can change the tokenAdmin");
        ICTMRWA001(ctmRwa001Addr).changeAdminX(_newAdmin);
        adminTokens[_newAdmin].push(ctmRwa001Addr);

        emit ChangeAdmin(_ID, currentAdmin.toHexString(), _newAdmin.toHexString(), "");

        return(true);
    }

    // Change the tokenAdmin address of a deployed CTMRWA001 instance on another chain
    function changeAdminCrossChain(
        string memory _newAdminStr,
        string memory toChainIdStr_,
        uint256 ID_,
        string memory feeTokenStr
    ) public payable virtual returns(bool) {
        require(!stringsEqual(toChainIdStr_, cID().toString()), "CTMRWA001X: Not a cross-chain tokenAdmin change");
        (bool ok, address ctmRwa001Addr) = this.getAttachedTokenAddress(ID_);
        require(ok, "CTMRWA001X: The requested tokenID does not exist");
        string memory ctmRwa001AddrStr = _toLower(ctmRwa001Addr.toHexString());
        address currentAdmin = ICTMRWA001(ctmRwa001Addr).tokenAdmin();
        require(msg.sender == currentAdmin, "CTMRWA001X: Only tokenAdmin can change the tokenAdmin");
        require(IFeeManager(feeManager).isValidFeeToken(feeTokenStr), "CTMRWA001X: Not a valid fee token");

        string memory currentAdminStr = currentAdmin.toHexString();
        string memory toContractStr = ICTMRWA001X(ctmRwa001Addr).getTokenContract(toChainIdStr_);

        string memory targetStr = this.getChainContract(toChainIdStr_);
        require(bytes(targetStr).length>0, "CTMRWA001X: Target contract address not found");

        uint256 xChainFee = FeeManager(feeManager).getXChainFee(toChainIdStr_, FeeType.ADMIN, feeTokenStr);
        address feeToken = stringToAddress(feeTokenStr);
        IERC20(feeToken).transferFrom(msg.sender, address(this), xChainFee);
        IERC20(feeToken).approve(feeManager, xChainFee);
        if(xChainFee>0) FeeManager(feeManager).payFee(xChainFee, feeTokenStr);

        string memory funcCall = "adminX(string,string,string,string)";
        bytes memory callData = abi.encodeWithSignature(
            funcCall,
            currentAdminStr,
            _newAdminStr,
            ctmRwa001AddrStr,
            toContractStr
        );

        c3call(targetStr, toChainIdStr_, callData);

        emit ChangeAdmin(ID_, currentAdminStr, _newAdminStr, toChainIdStr_);

        return(true);
    }


    function adminX(
        string memory _currentAdminStr,
        string memory _newAdminStr,
        string memory _fromContractStr,
        string memory _ctmRwa001AddrStr
    ) external onlyCaller returns(bool) {
        address ctmRwa001Addr = stringToAddress(_ctmRwa001AddrStr);
        address newAdmin = stringToAddress(_newAdminStr);

        (, string memory fromChainIdStr,) = context();
        fromChainIdStr = _toLower(fromChainIdStr);

        string memory storedContractStr = ICTMRWA001X(ctmRwa001Addr).getTokenContract(fromChainIdStr);
        require(stringsEqual(storedContractStr, _fromContractStr), "CTMRWA001X: From an invalid CTMRWA001");

        ICTMRWA001(ctmRwa001Addr).changeAdminX(newAdmin);
        adminTokens[newAdmin].push(ctmRwa001Addr);

        emit ChangeAdminDest(_currentAdminStr, _newAdminStr, fromChainIdStr);

        return(true);
    }

    function lockCTMRWA001(
        uint256 _ID,
        string memory feeTokenStr
    ) external payable {
        (bool ok, address ctmRwa001Addr) = this.getAttachedTokenAddress(_ID);
        require(ok, "CTMRWA001X: The requested tokenID does not exist");
        string memory ctmRwa001AddrStr = _toLower(ctmRwa001Addr.toHexString());
        address currentAdmin = ICTMRWA001(ctmRwa001Addr).tokenAdmin();
        require(msg.sender == currentAdmin, "CTMRWA001X: Only tokenAdmin function");
        string memory currentAdminStr = currentAdmin.toHexString();
        require(bytes(feeTokenStr).length == 42, "CTMRWA001X: feeTokenStr has the wrong length");
        require(IFeeManager(feeManager).isValidFeeToken(feeTokenStr), "CTMRWA001X: Not a valid fee token");

        TokenContract[] memory tokenContracts =  ICTMRWA001X(ctmRwa001Addr).tokenContract();

        uint256 nChains = tokenContracts.length;
        string memory toChainIdStr;
        string memory gatewayTargetStr;
        string memory ctmRwa001TokenStr;

        uint256 totalFee;
        uint256 xChainFee;

        for(uint256 i=0; i<nChains; i++) {
            xChainFee = FeeManager(feeManager).getXChainFee(tokenContracts[i].chainIdStr, FeeType.ADMIN, feeTokenStr);
            totalFee += xChainFee;
        }

        address feeToken = stringToAddress(feeTokenStr);
        IERC20(feeToken).transferFrom(msg.sender, address(this), totalFee);
        IERC20(feeToken).approve(feeManager, xChainFee);
        if(totalFee>0) FeeManager(feeManager).payFee(totalFee, feeTokenStr);

        for(uint256 i=1; i<nChains; i++) {  // leave local chain to the end, so start at 1
            toChainIdStr = tokenContracts[i].chainIdStr;
            ctmRwa001TokenStr = tokenContracts[i].contractStr;
            gatewayTargetStr = this.getChainContract(toChainIdStr);

            string memory funcCall = "adminX(string,string,string,string)";
            bytes memory callData = abi.encodeWithSignature(
                funcCall,
                currentAdminStr,
                "0",
                ctmRwa001AddrStr,
                ctmRwa001TokenStr
            );

            c3call(gatewayTargetStr, toChainIdStr, callData);

        }

        ICTMRWA001(ctmRwa001Addr).changeAdminX(stringToAddress("0"));

        emit LockToken(_ID, ctmRwa001Addr, nChains);

    }

    function _isUniqueId(uint256 _ID) internal view returns(bool) {
        for(uint256 i=0; i<ctmRwa001Ids.length; i++) {
            if(ctmRwa001Ids[i].ID == _ID) return(false);
        }
        return(true);
    }

    function getAllTokensByAdminAddress(address _admin) public view returns(address[] memory) {
        return(adminTokens[_admin]);
    }

    function getAllTokensByOwnerAddress(address _owner) public view returns(address[] memory) {
        return(ownedCtmRwa001[_owner]);
    }

    function isOwnedToken(address _owner, address _ctmRwa001Addr) public view returns(bool) {
        if(ICTMRWA001X(_ctmRwa001Addr).balanceOfX(_owner) > 0) return(true);
        else return(false);
    }

    function isForgottonTokenSlot(uint256 _tokenId, uint256 _slot, address _ctmRwa001) public view returns(bool) {
        return(forgottonTokens[_ctmRwa001][_tokenId][_slot]);
    }

    function forgetTokenSlot(uint256 _tokenId, uint256 _slot, address _ctmRwa001) external returns(bool) {
        require(ICTMRWA001X(_ctmRwa001).requireMinted(_tokenId), "CTMRWA001X: TokenId does not exist");
        (, uint256 balance, address owner, uint256 slot) = ICTMRWA001X(_ctmRwa001).getTokenInfo(_tokenId);
        if(owner == msg.sender && _slot == slot && balance>0) {
            forgottonTokens[_ctmRwa001][_tokenId][_slot] = true;
            return(true);
        } else return(false);
    }

    function rememberTokenSlot(uint256 _tokenId, uint256 _slot, address _ctmRwa001) external returns(bool) {
        require(ICTMRWA001X(_ctmRwa001).requireMinted(_tokenId), "CTMRWA001X: TokenId does not exist");
        (, uint256 balance, address owner, uint256 slot) = ICTMRWA001X(_ctmRwa001).getTokenInfo(_tokenId);
        if(owner == msg.sender && _slot == slot && balance>0) {
            forgottonTokens[_ctmRwa001][_tokenId][_slot] = false;
            return(true);
        } else return(false);
    }

    function getAttachedID(address _ctmRwa001Addr) external view returns(bool, uint256) {
        for(uint256 i=0; i<ctmRwa001Ids.length; i++) {
            if(stringsEqual(ctmRwa001Ids[i].contractStr, _toLower(_ctmRwa001Addr.toHexString()))) {
                return(true, ctmRwa001Ids[i].ID);
            }
        }
        return(false, 0);
    }

    function getAttachedTokenAddress(uint256 _ID) external view returns(bool, address) {
        for(uint256 i=0; i<ctmRwa001Ids.length; i++) {
            if(ctmRwa001Ids[i].ID == _ID) {
                return(true, stringToAddress(ctmRwa001Ids[i].contractStr));
            }
        }
            
        return(false, address(0));
    }

    // Keeps a record of token IDs in this gateway contract. Check offline to see if other contracts have it
    function _attachCTMRWA001ID(uint256 _ID, address _ctmRwa001Addr) internal returns(bool) {
        (bool attached,) = this.getAttachedID(_ctmRwa001Addr);
        if (!attached) {
            bool ok = ICTMRWA001X(_ctmRwa001Addr).attachId(_ID, msg.sender);
            if(ok) {
                CTMRWA001ID memory newAttach = CTMRWA001ID(_ID, _toLower(_ctmRwa001Addr.toHexString()));
                ctmRwa001Ids.push(newAttach);
                return(true);
            } else return(false);
        } else return(false);
    }

    // Add an array of new chainId/ctmRwa001Addr pairs corresponding to other chain deployments
    function addNewChainIdAndToken(
        string memory toChainIdStr_,
        string[] memory _chainIdsStr,
        string[] memory _otherCtmRwa001AddrsStr,
        uint256 _ID
    ) public payable virtual {
        (bool ok, address ctmRwa001Addr) = this.getAttachedTokenAddress(_ID);
        require(ok, "CTMRWA001X: The CTMRWA001 contract has not yet been attached");
        string memory ctmRwa001AddrStr = _toLower(ctmRwa001Addr.toHexString());
        address currentAdmin = ICTMRWA001(ctmRwa001Addr).tokenAdmin();
        require(msg.sender == currentAdmin, "CTMRWA001X: Only tokenAdmin function");
        string memory currentAdminStr = currentAdmin.toHexString();

        string memory _toContractStr = ICTMRWA001X(ctmRwa001Addr).getTokenContract(toChainIdStr_);

        string memory targetStr = this.getChainContract(toChainIdStr_);
        require(bytes(targetStr).length>0, "CTMRWA001X: Target contract address not found");

        string memory funcCall = "addNewChainIdAndTokenX(uint256,string,string[],string[],string,string)";
        bytes memory callData = abi.encodeWithSignature(
            funcCall,
            _ID,
            currentAdminStr,
            _chainIdsStr,
            _otherCtmRwa001AddrsStr,
            ctmRwa001AddrStr,
            _toContractStr
        );

        c3call(targetStr, toChainIdStr_, callData);

    }

    function addNewChainIdAndTokenX(
        string memory _adminStr,
        uint256 _Id,
        string[] memory _chainIdsStr,
        string[] memory _otherCtmRwa001AddrsStr,
        string memory _fromContractStr,
        string memory _ctmRwa001AddrStr
    ) external onlyCaller returns(bool) {

        (, string memory fromChainIdStr,) = context();
        fromChainIdStr = _toLower(fromChainIdStr);

        address tokenAdmin = stringToAddress(_adminStr);
        address ctmRwa001Addr = stringToAddress(_ctmRwa001AddrStr);

        address currentAdmin = ICTMRWA001(ctmRwa001Addr).tokenAdmin();
        require(tokenAdmin == currentAdmin, "CTMRWA001X: No tokenAdmin access to add chains/contracts");

        (bool ok, uint256 ID) = this.getAttachedID(ctmRwa001Addr);
        require(ok && ID == _Id, "CTMRWA001X: Incorrect or unattached CTMRWA001 contract");

        bool success = ICTMRWA001X(ctmRwa001Addr).addXTokenInfo(
            tokenAdmin, 
            _chainIdsStr, 
            _otherCtmRwa001AddrsStr
        );

        if(!success) revert("CTMRWA001X: addNewChainIdAndToken failed");

        emit AddNewChainAndToken(fromChainIdStr, _fromContractStr, _chainIdsStr, _otherCtmRwa001AddrsStr);

        return(true);
    }

    function mintNewTokenValueLocal(
        address toAddress_,
        uint256 toTokenId_,  // Set to 0 to create a newTokenId
        uint256 slot_,
        uint256 value_,
        uint256 _ID
    ) public payable virtual returns(uint256) {
        (bool ok, address ctmRwa001Addr) = this.getAttachedTokenAddress(_ID);
        require(ok, "CTMRWA001X: The CTMRWA001 contract has not yet been attached");
        address currentAdmin = ICTMRWA001(ctmRwa001Addr).tokenAdmin();
        require(msg.sender == currentAdmin, "CTMRWA001X: Only tokenAdmin function");

        if(toTokenId_>0) {
            ICTMRWA001X(ctmRwa001Addr).mintValueX(toTokenId_, slot_, value_);

            emit MintIncrementalTokenValue(
                _ID,
                msg.sender,
                toTokenId_,
                slot_,
                value_
            );
            return(toTokenId_);
        } else {
            uint256 newTokenId = ICTMRWA001X(ctmRwa001Addr).mintFromX(toAddress_, slot_, value_);
            (,,address owner,) = ICTMRWA001X(ctmRwa001Addr).getTokenInfo(newTokenId);
            ownedCtmRwa001[owner].push(ctmRwa001Addr);

            emit MintTokenValueNewId(
                _ID,
                msg.sender,
                newTokenId,
                slot_,
                value_
            );
            return(newTokenId);
        }

    }

    function mintNewTokenValueX(
        string memory toAddressStr_,
        string memory toChainIdStr_,
        uint256 slot_,
        uint256 value_,
        uint256 _ID,
        string memory feeTokenStr
    ) public payable virtual {
        (bool ok, address ctmRwa001Addr) = this.getAttachedTokenAddress(_ID);
        require(ok, "CTMRWA001X: The CTMRWA001 contract has not yet been attached");
        string memory ctmRwa001AddrStr = _toLower(ctmRwa001Addr.toHexString()); 
        address currentAdmin = ICTMRWA001(ctmRwa001Addr).tokenAdmin();
        require(msg.sender == currentAdmin, "CTMRWA001X: Only tokenAdmin function");
        require(!stringsEqual(toChainIdStr_, cID().toString()), "CTMRWA001X: This function call is only for cross-chain minting");

        require(bytes(feeTokenStr).length == 42, "CTMRWA001X: feeTokenStr has the wrong length");
        require(IFeeManager(feeManager).isValidFeeToken(feeTokenStr), "CTMRWA001X: Not a valid fee token");

        string memory fromAddressStr = msg.sender.toHexString();

        string memory targetStr = this.getChainContract(toChainIdStr_);
        require(bytes(targetStr).length>0, "CTMRWA001X: Target contract address not found");

        uint256 xChainFee = FeeManager(feeManager).getXChainFee(toChainIdStr_, FeeType.MINT, feeTokenStr);
        address feeToken = stringToAddress(feeTokenStr);
        IERC20(feeToken).transferFrom(msg.sender, address(this), xChainFee);
        IERC20(feeToken).approve(feeManager, xChainFee);
        if(xChainFee>0) FeeManager(feeManager).payFee(xChainFee, feeTokenStr);

        string memory _toContractStr = ICTMRWA001X(ctmRwa001Addr).getTokenContract(toChainIdStr_);

        string memory funcCall = "mintX(uint256,string,string,uint256,uint256,uint256,string,string)";
        bytes memory callData = abi.encodeWithSignature(
            funcCall,
            _ID,
            fromAddressStr,
            toAddressStr_,
            0,  // Not used, since we are not transferring value from a tokenId, but creating new value
            slot_,
            value_,
            ctmRwa001AddrStr,
            _toContractStr
        );

        c3call(targetStr, toChainIdStr_, callData);
    }

    
    function transferFromX(
        uint256 fromTokenId_,
        string memory toAddressStr_,
        string memory toChainIdStr_,
        uint256 value_,
        uint256 _ID,
        string memory feeTokenStr
    ) public payable virtual {
        require(bytes(feeTokenStr).length == 42, "CTMRWA001X: feeTokenStr has the wrong length");
        require(!stringsEqual(toChainIdStr_, cID().toString()), "CTMRWA001X: Not a cross-chain transfer");
        (bool ok, address ctmRwa001Addr) = this.getAttachedTokenAddress(_ID);
        require(ok, "CTMRWA001X: The CTMRWA001 contract does not exist");
        string memory ctmRwa001AddrStr = _toLower(ctmRwa001Addr.toHexString()); 

        ICTMRWA001X(ctmRwa001Addr).spendAllowance(msg.sender, fromTokenId_, value_);
        require(IFeeManager(feeManager).isValidFeeToken(feeTokenStr), "CTMRWA001X: Not a valid fee token");

        require(bytes(toAddressStr_).length>0, "CTMRWA001X: Destination address has zero length");
        string memory fromAddressStr = msg.sender.toHexString();

        string memory targetStr = this.getChainContract(toChainIdStr_);
        require(bytes(targetStr).length>0, "CTMRWA001X: Target contract address not found");

        

        uint256 xChainFee = FeeManager(feeManager).getXChainFee(toChainIdStr_, FeeType.TX, feeTokenStr);
        address feeToken = stringToAddress(feeTokenStr);
        IERC20(feeToken).transferFrom(msg.sender, address(this), xChainFee);
        IERC20(feeToken).approve(feeManager, xChainFee);
        if(xChainFee>0) FeeManager(feeManager).payFee(xChainFee, feeTokenStr);

        (,,,uint256 slot) = ICTMRWA001X(ctmRwa001Addr).getTokenInfo(fromTokenId_);
        string memory _toContractStr = ICTMRWA001X(ctmRwa001Addr).getTokenContract(toChainIdStr_);

        _beforeValueTransferX(fromAddressStr, toAddressStr_, toChainIdStr_, fromTokenId_, fromTokenId_, slot, value_);
    
        ICTMRWA001X(ctmRwa001Addr).burnValueX(fromTokenId_, value_);

        string memory funcCall = "mintX(uint256,string,string,uint256,uint256,uint256,string,string)";
        
        bytes memory callData = abi.encodeWithSignature(
            funcCall,
            _ID,
            fromAddressStr,
            toAddressStr_,
            fromTokenId_,
            slot,
            value_,
            ctmRwa001AddrStr,
            _toContractStr
        );
        
        c3call(targetStr, toChainIdStr_, callData);

        emit TransferFromSourceX(
            _ID,
            fromAddressStr,
            toAddressStr_,
            fromTokenId_,
            0,
            slot,
            value_,
            ctmRwa001AddrStr,
            _toContractStr
        );
    }

    function transferFromX(
        uint256 fromTokenId_,
        string memory toAddressStr_,
        uint256 toTokenId_,
        string memory toChainIdStr_,
        uint256 value_,
        uint256 _ID,
        string memory feeTokenStr
    ) public payable virtual {
        require(!stringsEqual(toChainIdStr_, cID().toString()), "CTMRWA001X: Not a cross-chain transfer");
        (bool ok, address ctmRwa001Addr) = this.getAttachedTokenAddress(_ID);
        require(ok, "CTMRWA001X: The CTMRWA001 contract does not exist");
        string memory ctmRwa001AddrStr = _toLower(ctmRwa001Addr.toHexString()); 
        require(bytes(feeTokenStr).length == 42, "CTMRWA001X: feeTokenStr has the wrong length");
        require(IFeeManager(feeManager).isValidFeeToken(feeTokenStr), "CTMRWA001X: Not a valid fee token");

        ICTMRWA001X(ctmRwa001Addr).spendAllowance(msg.sender, fromTokenId_, value_);
        require(bytes(toAddressStr_).length>0, "CTMRWA001X: Destination address has zero length");
        string memory fromAddressStr = msg.sender.toHexString();

        uint256 xChainFee = FeeManager(feeManager).getXChainFee(toChainIdStr_, FeeType.TX, feeTokenStr);
        address feeToken = stringToAddress(feeTokenStr);
        IERC20(feeToken).transferFrom(msg.sender, address(this), xChainFee);
        IERC20(feeToken).approve(feeManager, xChainFee);
        if(xChainFee>0) FeeManager(feeManager).payFee(xChainFee, feeTokenStr);

        string memory targetStr = this.getChainContract(toChainIdStr_);
        require(bytes(targetStr).length>0, "CTMRWA001X: Target contract address not found");

        (,,,uint256 slot) = ICTMRWA001X(ctmRwa001Addr).getTokenInfo(fromTokenId_);
        string memory _toContractStr = ICTMRWA001X(ctmRwa001Addr).getTokenContract(toChainIdStr_);

        _beforeValueTransferX(fromAddressStr, toAddressStr_, toChainIdStr_, toTokenId_, toTokenId_, slot, value_);

        ICTMRWA001X(ctmRwa001Addr).burnValueX(fromTokenId_, value_);

        string memory funcCall = "mintX(uint256,string,string,uint256,uint256,uint256,uint256,string,string)";
        
        bytes memory callData = abi.encodeWithSignature(
            funcCall,
            _ID,
            fromAddressStr,
            toAddressStr_,
            fromTokenId_,
            toTokenId_,
            slot,
            value_,
            ctmRwa001AddrStr,
            _toContractStr
        );
        
        c3call(targetStr, toChainIdStr_, callData);

        emit TransferFromSourceX(
            _ID,
            fromAddressStr,
            toAddressStr_,
            fromTokenId_,
            toTokenId_,
            slot,
            value_,
            ctmRwa001AddrStr,
            _toContractStr
        );
    }

    function mintX(
        uint256 _ID,
        string memory fromAddressStr_,
        string memory toAddressStr_,
        uint256 fromTokenId_,
        uint256 toTokenId_,
        uint256 slot_,
        uint256 value_,
        string memory _fromContractStr,
        string memory _ctmRwa001AddrStr
    ) external onlyCaller returns(bool){

        address ctmRwa001Addr = stringToAddress(_ctmRwa001AddrStr);

        (, string memory fromChainIdStr,) = context();
        fromChainIdStr = _toLower(fromChainIdStr);

        require(ICTMRWA001X(ctmRwa001Addr).ID() == _ID, "CTMRWA001X: Destination CTMRWA001 ID is incorrect");

        string memory storedContractStr = ICTMRWA001X(ctmRwa001Addr).getTokenContract(fromChainIdStr);
        require(stringsEqual(storedContractStr, _fromContractStr), "CTMRWA001X: From an invalid CTMRWA001");

        ICTMRWA001X(ctmRwa001Addr).mintValueX(toTokenId_, slot_, value_);
        (,,address owner,) = ICTMRWA001X(ctmRwa001Addr).getTokenInfo(toTokenId_);
        ownedCtmRwa001[owner].push(ctmRwa001Addr);

        emit TransferToDestX(
            _ID,
            fromAddressStr_,
            toAddressStr_,
            fromTokenId_,
            toTokenId_,
            slot_,
            value_,
            _fromContractStr,
            _ctmRwa001AddrStr
        );

        return(true);
    }

    function transferFromX(
        string memory toAddressStr_,
        string memory toChainIdStr_,
        uint256 fromTokenId_,
        uint256 _ID,
        string memory feeTokenStr
    ) public payable virtual {
        require(!stringsEqual(toChainIdStr_, cID().toString()), "CTMRWA001X: Not a cross-chain transfer");
        (bool ok, address ctmRwa001Addr) = this.getAttachedTokenAddress(_ID);
        require(ok, "CTMRWA001X: The CTMRWA001 contract does not exist");
        string memory ctmRwa001AddrStr = _toLower(ctmRwa001Addr.toHexString()); 
        require(bytes(feeTokenStr).length == 42, "CTMRWA001X: feeTokenStr has the wrong length");
        require(ICTMRWA001X(ctmRwa001Addr).isApprovedOrOwner(msg.sender, fromTokenId_), "CTMRWA001X: transfer caller is not owner nor approved");
        string memory fromAddressStr = msg.sender.toHexString();
        require(IFeeManager(feeManager).isValidFeeToken(feeTokenStr), "CTMRWA001X: Not a valid fee token");

        uint256 xChainFee = FeeManager(feeManager).getXChainFee(toChainIdStr_, FeeType.TX, feeTokenStr);
        address feeToken = stringToAddress(feeTokenStr);
        IERC20(feeToken).transferFrom(msg.sender, address(this), xChainFee);
        IERC20(feeToken).approve(feeManager, xChainFee);
        if(xChainFee>0) FeeManager(feeManager).payFee(xChainFee, feeTokenStr);

        string memory targetStr = this.getChainContract(toChainIdStr_);
        require(bytes(targetStr).length>0, "CTMRWA001X: Target contract address not found");

        string memory _toContractStr = ICTMRWA001X(ctmRwa001Addr).getTokenContract(toChainIdStr_);

        (,uint256 value,,uint256 slot) = ICTMRWA001X(ctmRwa001Addr).getTokenInfo(fromTokenId_);

        _beforeValueTransferX(fromAddressStr, toAddressStr_, toChainIdStr_, fromTokenId_, fromTokenId_, slot, value);

        ICTMRWA001X(ctmRwa001Addr).approveFromX(address(0), fromTokenId_);
        ICTMRWA001X(ctmRwa001Addr).clearApprovedValues(fromTokenId_);

        ICTMRWA001X(ctmRwa001Addr).removeTokenFromOwnerEnumeration(msg.sender, fromTokenId_);

        string memory funcCall = "mintX(uint256,string,string,uint256,uint256,uint256,string,string)";
        bytes memory callData = abi.encodeWithSignature(
            funcCall,
            _ID,
            fromAddressStr,
            toAddressStr_,
            fromTokenId_,
            slot,
            value,
            ctmRwa001AddrStr,
            _toContractStr
        );

        c3call(targetStr, toChainIdStr_, callData);

        emit TransferFromSourceX(
            _ID,
            fromAddressStr,
            toAddressStr_,
            fromTokenId_,
            0,
            slot,
            value,
            ctmRwa001AddrStr,
            _toContractStr
        );
    }

    function mintX(
        uint256 _ID,
        string memory fromAddressStr_,
        string memory toAddressStr_,
        uint256 fromTokenId_,
        uint256 slot_,
        uint256 balance_,
        string memory _fromContractStr,
        string memory _ctmRwa001AddrStr
    ) external onlyCaller returns(bool){

        (, string memory fromChainIdStr,) = context();
        fromChainIdStr = _toLower(fromChainIdStr);

        address ctmRwa001Addr = stringToAddress(_ctmRwa001AddrStr);
        address toAddr = stringToAddress(toAddressStr_);

        require(ICTMRWA001X(ctmRwa001Addr).ID() == _ID, "CTMRWA001X: Destination CTMRWA001 ID is incorrect");

        string memory storedContractStr = ICTMRWA001X(ctmRwa001Addr).getTokenContract(fromChainIdStr);
        require(stringsEqual(storedContractStr, _fromContractStr), "CTMRWA001X: From an invalid CTMRWA001");

        uint256 newTokenId = ICTMRWA001X(ctmRwa001Addr).mintFromX(toAddr, slot_, balance_);

        emit TransferToDestX(
            _ID,
            fromAddressStr_,
            toAddressStr_,
            fromTokenId_,
            newTokenId,
            slot_,
            balance_,
            _fromContractStr,
            _ctmRwa001AddrStr
        );

        return(true);
    }


    // End of cross chain transfers


    function _beforeValueTransferX(
        string memory fromAddressStr_,
        string memory toAddressStr,
        string memory toChainIdStr_,
        uint256 fromTokenId_,
        uint256 toTokenId_,
        uint256 slot_,
        uint256 value_
    ) internal virtual {}


    function cID() internal view returns (uint256) {
        return block.chainid;
    }

    function strToUint(
        string memory _str
    ) public pure returns (uint256 res, bool err) {
        if (bytes(_str).length == 0) {
            return (0, true);
        }
        for (uint256 i = 0; i < bytes(_str).length; i++) {
            if (
                (uint8(bytes(_str)[i]) - 48) < 0 ||
                (uint8(bytes(_str)[i]) - 48) > 9
            ) {
                return (0, false);
            }
            res +=
                (uint8(bytes(_str)[i]) - 48) *
                10 ** (bytes(_str).length - i - 1);
        }

        return (res, true);
    }

    function stringToAddress(string memory str) public pure returns (address) {
        bytes memory strBytes = bytes(str);
        require(strBytes.length == 42, "CTMRWA001X: Invalid address length");
        bytes memory addrBytes = new bytes(20);

        for (uint i = 0; i < 20; i++) {
            addrBytes[i] = bytes1(
                hexCharToByte(strBytes[2 + i * 2]) *
                    16 +
                    hexCharToByte(strBytes[3 + i * 2])
            );
        }

        return address(uint160(bytes20(addrBytes)));
    }

    function hexCharToByte(bytes1 char) internal pure returns (uint8) {
        uint8 byteValue = uint8(char);
        if (
            byteValue >= uint8(bytes1("0")) && byteValue <= uint8(bytes1("9"))
        ) {
            return byteValue - uint8(bytes1("0"));
        } else if (
            byteValue >= uint8(bytes1("a")) && byteValue <= uint8(bytes1("f"))
        ) {
            return 10 + byteValue - uint8(bytes1("a"));
        } else if (
            byteValue >= uint8(bytes1("A")) && byteValue <= uint8(bytes1("F"))
        ) {
            return 10 + byteValue - uint8(bytes1("A"));
        }
        revert("Invalid hex character");
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

    function _c3Fallback(bytes4 _selector,
        bytes calldata _data,
        bytes calldata _reason) internal override returns (bool) {


        emit LogFallback(_selector, _data, _reason);
        return true;
    }

}