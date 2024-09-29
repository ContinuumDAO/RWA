// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/Strings.sol";
import {GovernDapp} from "./routerV2/GovernDapp.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {ICTMRWA001X, TokenContract} from "./interfaces/ICTMRWA001X.sol";
import {ICTMRWA001} from "./interfaces/ICTMRWA001.sol";
import {ICTMRWA001Token} from "./interfaces/ICTMRWA001Token.sol";

//import "forge-std/console.sol";

// struct ChainAndAdmin {
//     string fromAddressStr;
//     address tokenAddr;
//     string tokenAddrStr;
//     address currentAdmin;
//     string currentAdminStr;
//     string toContractStr;
//     string targetStr;
// }


import "./FeeManager.sol";

contract CTMRWA001X is  GovernDapp {
    using Strings for *;
    using SafeERC20 for IERC20;

    address public feeManager;
    address public ctmRwaDeployer;
    string public chainIdStr;

    // ChainAndAdmin cAndA; 

    mapping(address => address[]) public adminTokens;  // tokenAdmin address => array of CTMRWA001 contracts
    mapping(address => address[]) public ownedCtmRwa001;  // owner address => array of CTMRWA001 contracts

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
        address _gov,
        address _c3callerProxy,
        address _txSender,
        uint256 _dappID
    ) GovernDapp(_gov, _c3callerProxy, _txSender, _dappID) {
        feeManager = _feeManager;
        chainIdStr = cID().toString();
        _addChainContract(cID(), address(this));
        
    }

    function changeFeeManager(address _feeManager) external onlyGov {
        feeManager = _feeManager;
    }

    function setCtmRwaDeployer(address _deployer) external onlyGov {
        ctmRwaDeployer = _deployer;
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
    ) external onlyGov {
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
        uint256 _rwaType,
        uint256 _version,
        string memory tokenName_, 
        string memory symbol_, 
        uint8 decimals_,
        string memory baseURI_,
        address tokenAdmin
    ) internal returns(address) {
        bool ok = _isUniqueId(_ID);  // only checks local deployments!
        require(ok, "CTMRWA001X: A local contract with this ID already exists");

        bytes memory deployData = abi.encode(_ID, tokenAdmin, tokenName_, symbol_, decimals_, baseURI_, address(this));

        (address ctmRwa001Token, address dividendAddr) = ICTMRWA001X(ctmRwaDeployer).deploy(
            _rwaType,
            _version,
            deployData
        );

        ok = _attachCTMRWA001ID(_ID, ctmRwa001Token);
        require(ok, "CTMRWA001X: Failed to set token ID");

        ok = ICTMRWA001(ctmRwa001Token).attachDividend(dividendAddr);
        require(ok, "CTMRWA001X: Failed to set the dividend contract address");

        ICTMRWA001(ctmRwa001Token).changeAdminX(tokenAdmin);
        adminTokens[tokenAdmin].push(ctmRwa001Token);

        emit CreateNewCTMRWA001(ctmRwa001Token, _ID, tokenAdmin, cID().toString(), "");

        return(ctmRwa001Token);
    }

    function deployAllCTMRWA001X(
        bool includeLocal,
        uint256 existingID_,
        uint256 rwaType_,
        uint256 version_,
        string memory tokenName_, 
        string memory symbol_, 
        uint8 decimals_,
        string memory baseURI_,
        string[] memory toChainIdsStr_,
        string memory feeTokenStr
    ) public returns(uint256) {
        require(!includeLocal && existingID_>0 || includeLocal && existingID_ == 0, "CTMRWA001X: Incorrect call logic");
        uint256 nChains = toChainIdsStr_.length;
        require(bytes(feeTokenStr).length == 42, "CTMRWA001X: feeTokenStr has the wrong length");
        require(IFeeManager(feeManager).isValidFeeToken(feeTokenStr), "CTMRWA001X: Not a valid fee token");

        string memory ctmRwa001AddrStr;
        address ctmRwa001Addr;
        address currentAdmin;
        uint256 ID;
        string memory tokenName;
        string memory symbol;
        uint8 decimals;
        string memory baseURI;

        if(includeLocal) {
            // generate a new ID
            ID = uint256(keccak256(abi.encode(
                tokenName_,
                symbol_,
                decimals_,
                block.timestamp,
                msg.sender
            )));

            tokenName = tokenName_;
            symbol = symbol_;
            decimals = decimals_;
            baseURI = baseURI_;

            ctmRwa001Addr = _deployCTMRWA001Local(ID, rwaType_, version_, tokenName_, symbol_, decimals_, baseURI, msg.sender);
            ICTMRWA001(ctmRwa001Addr).changeAdminX(msg.sender);
            
            currentAdmin = msg.sender;
        } else {  // a CTMRWA001 token must be deployed already, so use the existing ID
            ID = existingID_;
            (bool ok, address rwa001Addr) = this.getAttachedTokenAddress(ID);
            require(ok, "CTMRWA001X: ID does not exist on local chain");
            ctmRwa001Addr = rwa001Addr;
            currentAdmin = ICTMRWA001(ctmRwa001Addr).tokenAdmin();
            require(msg.sender == currentAdmin, "CTMRWA001X: Only tokenAdmin can deploy");

            tokenName = ICTMRWA001(ctmRwa001Addr).name();
            symbol = ICTMRWA001(ctmRwa001Addr).symbol();
            decimals = ICTMRWA001(ctmRwa001Addr).valueDecimals();
            baseURI = ICTMRWA001(ctmRwa001Addr).baseURI();
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
                tokenName, 
                symbol,
                decimals, 
                baseURI,
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

        uint256 ID = ICTMRWA001(ctmRwa001Addr).ID();
        uint256 rwaType = ICTMRWA001Token(ctmRwa001Addr).getRWAType();
        uint256 version = ICTMRWA001Token(ctmRwa001Addr).getVersion();
        
        string memory targetStr = this.getChainContract(toChainIdStr_);
        require(bytes(targetStr).length>0, "CTMRWA001X: Target contract address not found");

        string memory funcCall = "deployCTMRWA001(string,uint256,uint256,uint256,string,string,uint8,string,string)";
        bytes memory callData = abi.encodeWithSignature(
            funcCall,
            currentAdminStr,
            ID,
            rwaType,
            version,
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
        uint256 _rwaType,
        uint256 _version,
        string memory tokenName_, 
        string memory symbol_, 
        uint8 decimals_,
        string memory baseURI_,
        string memory _fromContractStr
    ) external onlyCaller returns(bool) {

        address newAdmin = stringToAddress(_newAdminStr);

        (, string memory fromChainIdStr,) = context();
        fromChainIdStr = _toLower(fromChainIdStr);

        bytes memory deployData = abi.encode(_ID, newAdmin, tokenName_, symbol_, decimals_, baseURI_, address(this));

        (address ctmRwa001Token, address dividendAddr) = ICTMRWA001X(ctmRwaDeployer).deploy(
            _rwaType,
            _version,
            deployData
        );

        bool ok = _attachCTMRWA001ID(_ID, ctmRwa001Token);
        require(ok, "CTMRWA001X: Failed to set token ID");

        ok = ICTMRWA001(ctmRwa001Token).attachDividend(dividendAddr);
        require(ok, "CTMRWA001X: Failed to set the dividend contract address");

        ICTMRWA001(ctmRwa001Token).changeAdminX(newAdmin);
        adminTokens[newAdmin].push(ctmRwa001Token);

        emit CreateNewCTMRWA001(ctmRwa001Token, _ID, newAdmin, fromChainIdStr, _fromContractStr);

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

    function _checkChainAndAdmin(uint256 _ID, string memory _toChainIdStr) internal returns
    (
        string memory,
        address,
        string memory,
        address,
        string memory,
        string memory,
        string memory
    ) {
        require(!stringsEqual(_toChainIdStr, cID().toString()), "CTMRWA001X: Not a cross-chain tokenAdmin change");
        (bool ok, address ctmRwa001Addr) = this.getAttachedTokenAddress(_ID);
        require(ok, "CTMRWA001X: The requested tokenID does not exist");
        string memory ctmRwa001AddrStr = _toLower(ctmRwa001Addr.toHexString());
        address currentAdmin = ICTMRWA001(ctmRwa001Addr).tokenAdmin();
        
        string memory currentAdminStr = currentAdmin.toHexString();
        string memory fromAddressStr = msg.sender.toHexString();
        string memory toContractStr = ICTMRWA001(ctmRwa001Addr).getTokenContract(_toChainIdStr);

        string memory targetStr = this.getChainContract(_toChainIdStr);
        require(bytes(targetStr).length>0, "CTMRWA001X: Target contract address not found");

        return(fromAddressStr, ctmRwa001Addr, ctmRwa001AddrStr, currentAdmin, currentAdminStr, toContractStr, targetStr);

        // return(cAndA);
    }

    // Change the tokenAdmin address of a deployed CTMRWA001 instance on another chain
    function changeAdminCrossChain(
        string memory _newAdminStr,
        string memory _toChainIdStr,
        uint256 _ID,
        string memory feeTokenStr
    ) public returns(bool) {
        
        (
            string memory fromAddressStr, 
            address ctmRwa001Addr, 
            string memory ctmRwa001AddrStr, 
            address currentAdmin, 
            string memory currentAdminStr, 
            string memory toContractStr, 
            string memory targetStr
        ) = _checkChainAndAdmin(_ID, _toChainIdStr);

        require(msg.sender == currentAdmin, "CTMRWA001X: Only tokenAdmin can change the tokenAdmin");

        require(IFeeManager(feeManager).isValidFeeToken(feeTokenStr), "CTMRWA001X: Not a valid fee token");
        
        uint256 xChainFee = FeeManager(feeManager).getXChainFee(_toChainIdStr, FeeType.ADMIN, feeTokenStr);
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

        c3call(targetStr, _toChainIdStr, callData);

        emit ChangeAdmin(_ID, currentAdminStr, _newAdminStr, _toChainIdStr);

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

        string memory storedContractStr = ICTMRWA001(ctmRwa001Addr).getTokenContract(fromChainIdStr);
        require(stringsEqual(storedContractStr, _fromContractStr), "CTMRWA001X: From an invalid CTMRWA001");

        ICTMRWA001(ctmRwa001Addr).changeAdminX(newAdmin);
        adminTokens[newAdmin].push(ctmRwa001Addr);

        emit ChangeAdminDest(_currentAdminStr, _newAdminStr, fromChainIdStr);

        return(true);
    }

    function lockCTMRWA001(
        uint256 _ID,
        string memory feeTokenStr
    ) external {
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
        if(ICTMRWA001(_ctmRwa001Addr).balanceOf(_owner) > 0) return(true);
        else return(false);
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
            bool ok = ICTMRWA001(_ctmRwa001Addr).attachId(_ID, msg.sender);
            if(ok) {
                CTMRWA001ID memory newAttach = CTMRWA001ID(_ID, _toLower(_ctmRwa001Addr.toHexString()));
                ctmRwa001Ids.push(newAttach);
                return(true);
            } else return(false);
        } else return(false);
    }

    // Add an array of new chainId/ctmRwa001Addr pairs corresponding to other chain deployments
    function addNewChainIdAndToken(
        string memory _toChainIdStr,
        string[] memory _chainIdsStr,
        string[] memory _otherCtmRwa001AddrsStr,
        uint256 _ID
    ) public {
        // (bool ok, address ctmRwa001Addr) = this.getAttachedTokenAddress(_ID);
        // require(ok, "CTMRWA001X: The CTMRWA001 contract has not yet been attached");
        // string memory ctmRwa001AddrStr = _toLower(ctmRwa001Addr.toHexString());
        // address currentAdmin = ICTMRWA001(ctmRwa001Addr).tokenAdmin();
        // require(msg.sender == currentAdmin, "CTMRWA001X: Only tokenAdmin function");
        // string memory currentAdminStr = currentAdmin.toHexString();

        

        // string memory targetStr = this.getChainContract(toChainIdStr_);
        // require(bytes(targetStr).length>0, "CTMRWA001X: Target contract address not found");

        (
            string memory fromAddressStr, 
            address ctmRwa001Addr, 
            string memory ctmRwa001AddrStr, 
            address currentAdmin, 
            string memory currentAdminStr, 
            string memory toContractStr, 
            string memory targetStr
        ) = _checkChainAndAdmin(_ID, _toChainIdStr);

        require(msg.sender == currentAdmin, "CTMRWA001X: Only tokenAdmin function");

        string memory _toContractStr = ICTMRWA001(ctmRwa001Addr).getTokenContract(_toChainIdStr);

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

        c3call(targetStr, _toChainIdStr, callData);

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

        bool success = ICTMRWA001(ctmRwa001Addr).addXTokenInfo(
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
    ) public returns(uint256) {
        (bool ok, address ctmRwa001Addr) = this.getAttachedTokenAddress(_ID);
        require(ok, "CTMRWA001X: The CTMRWA001 contract has not yet been attached");
        address currentAdmin = ICTMRWA001(ctmRwa001Addr).tokenAdmin();
        require(msg.sender == currentAdmin, "CTMRWA001X: Only tokenAdmin function");

        if(toTokenId_>0) {
            ICTMRWA001(ctmRwa001Addr).mintValueX(toTokenId_, slot_, value_);

            emit MintIncrementalTokenValue(
                _ID,
                msg.sender,
                toTokenId_,
                slot_,
                value_
            );
            return(toTokenId_);
        } else {
            uint256 newTokenId = ICTMRWA001(ctmRwa001Addr).mintFromX(toAddress_, slot_, value_);
            (,,address owner,) = ICTMRWA001(ctmRwa001Addr).getTokenInfo(newTokenId);
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
        string memory _toAddressStr,
        string memory _toChainIdStr,
        uint256 _slot,
        uint256 _value,
        uint256 _ID,
        string memory feeTokenStr
    ) public {
        // (bool ok, address ctmRwa001Addr) = this.getAttachedTokenAddress(_ID);
        // require(ok, "CTMRWA001X: The CTMRWA001 contract has not yet been attached");
        // string memory ctmRwa001AddrStr = _toLower(ctmRwa001Addr.toHexString()); 
        // address currentAdmin = ICTMRWA001(ctmRwa001Addr).tokenAdmin();
        // require(msg.sender == currentAdmin, "CTMRWA001X: Only tokenAdmin function");
        // require(!stringsEqual(toChainIdStr_, cID().toString()), "CTMRWA001X: This function call is only for cross-chain minting");

        require(bytes(feeTokenStr).length == 42, "CTMRWA001X: feeTokenStr has the wrong length");
        
        (
            string memory fromAddressStr, 
            address ctmRwa001Addr, 
            string memory ctmRwa001AddrStr, 
            address currentAdmin, 
            string memory currentAdminStr, 
            string memory toContractStr, 
            string memory targetStr
        ) = _checkChainAndAdmin(_ID, _toChainIdStr);

        require(msg.sender == currentAdmin, "CTMRWA001X: Only tokenAdmin function");
        
        require(IFeeManager(feeManager).isValidFeeToken(feeTokenStr), "CTMRWA001X: Not a valid fee token");

        // string memory fromAddressStr = msg.sender.toHexString();

        // string memory targetStr = this.getChainContract(toChainIdStr_);
        // require(bytes(targetStr).length>0, "CTMRWA001X: Target contract address not found");

        uint256 xChainFee = FeeManager(feeManager).getXChainFee(_toChainIdStr, FeeType.MINT, feeTokenStr);
        address feeToken = stringToAddress(feeTokenStr);
        IERC20(feeToken).transferFrom(msg.sender, address(this), xChainFee);
        IERC20(feeToken).approve(feeManager, xChainFee);
        if(xChainFee>0) FeeManager(feeManager).payFee(xChainFee, feeTokenStr);

        string memory _toContractStr = ICTMRWA001(ctmRwa001Addr).getTokenContract(_toChainIdStr);

        string memory funcCall = "mintX(uint256,string,string,uint256,uint256,uint256,string,string)";
        bytes memory callData = abi.encodeWithSignature(
            funcCall,
            _ID,
            fromAddressStr,
            _toAddressStr,
            0,  // Not used, since we are not transferring value from a tokenId, but creating new value
            _slot,
            _value,
            ctmRwa001AddrStr,
            _toContractStr
        );

        c3call(targetStr, _toChainIdStr, callData);
    }

    
    function transferFromX(
        uint256 _fromTokenId,
        string memory _toAddressStr,
        string memory _toChainIdStr,
        uint256 _value,
        uint256 _ID,
        string memory feeTokenStr
    ) public {
        require(bytes(feeTokenStr).length == 42, "CTMRWA001X: feeTokenStr has the wrong length");
        // require(!stringsEqual(toChainIdStr_, cID().toString()), "CTMRWA001X: Not a cross-chain transfer");
        // (bool ok, address ctmRwa001Addr) = this.getAttachedTokenAddress(_ID);
        // require(ok, "CTMRWA001X: The CTMRWA001 contract does not exist");
        // string memory ctmRwa001AddrStr = _toLower(ctmRwa001Addr.toHexString()); 

        (
            string memory fromAddressStr, 
            address ctmRwa001Addr, 
            string memory ctmRwa001AddrStr, 
            address currentAdmin, 
            string memory currentAdminStr, 
            string memory toContractStr, 
            string memory targetStr
        ) = _checkChainAndAdmin(_ID, _toChainIdStr);

        ICTMRWA001(ctmRwa001Addr).spendAllowance(msg.sender, _fromTokenId, _value);
        require(IFeeManager(feeManager).isValidFeeToken(feeTokenStr), "CTMRWA001X: Not a valid fee token");

        require(bytes(_toAddressStr).length>0, "CTMRWA001X: Destination address has zero length");
        // string memory fromAddressStr = msg.sender.toHexString();

        // string memory targetStr = this.getChainContract(toChainIdStr_);
        // require(bytes(targetStr).length>0, "CTMRWA001X: Target contract address not found");

        

        uint256 xChainFee = FeeManager(feeManager).getXChainFee(_toChainIdStr, FeeType.TX, feeTokenStr);
        address feeToken = stringToAddress(feeTokenStr);
        IERC20(feeToken).transferFrom(msg.sender, address(this), xChainFee);
        IERC20(feeToken).approve(feeManager, xChainFee);
        if(xChainFee>0) FeeManager(feeManager).payFee(xChainFee, feeTokenStr);

        (,,,uint256 slot) = ICTMRWA001(ctmRwa001Addr).getTokenInfo(_fromTokenId);
        // string memory toContractStr = ICTMRWA001(ctmRwa001Addr).getTokenContract(_toChainIdStr);

        ICTMRWA001(ctmRwa001Addr).burnValueX(_fromTokenId, _value);

        string memory funcCall = "mintX(uint256,string,string,uint256,uint256,uint256,string,string)";
        
        bytes memory callData = abi.encodeWithSignature(
            funcCall,
            _ID,
            fromAddressStr,
            _toAddressStr,
            _fromTokenId,
            slot,
            _value,
            ctmRwa001Addr,
            toContractStr
        );
        
        c3call(targetStr, _toChainIdStr, callData);

        emit TransferFromSourceX(
            _ID,
            fromAddressStr,
            _toAddressStr,
            _fromTokenId,
            0,
            slot,
            _value,
            ctmRwa001AddrStr,
            toContractStr
        );
    }

    function transferFromX(
        uint256 _fromTokenId,
        string memory _toAddressStr,
        uint256 _toTokenId,
        string memory _toChainIdStr,
        uint256 _value,
        uint256 _ID,
        string memory feeTokenStr
    ) public {
        // require(!stringsEqual(toChainIdStr_, cID().toString()), "CTMRWA001X: Not a cross-chain transfer");
        // (bool ok, address ctmRwa001Addr) = this.getAttachedTokenAddress(_ID);
        // require(ok, "CTMRWA001X: The CTMRWA001 contract does not exist");
        // string memory ctmRwa001AddrStr = _toLower(ctmRwa001Addr.toHexString()); 
        require(bytes(feeTokenStr).length == 42, "CTMRWA001X: feeTokenStr has the wrong length");
        
        (
            string memory fromAddressStr, 
            address ctmRwa001Addr, 
            string memory ctmRwa001AddrStr, 
            address currentAdmin, 
            string memory currentAdminStr, 
            string memory toContractStr, 
            string memory targetStr
        ) = _checkChainAndAdmin(_ID, _toChainIdStr);
        
        require(IFeeManager(feeManager).isValidFeeToken(feeTokenStr), "CTMRWA001X: Not a valid fee token");

        ICTMRWA001(ctmRwa001Addr).spendAllowance(msg.sender, _fromTokenId, _value);
        require(bytes(_toAddressStr).length>0, "CTMRWA001X: Destination address has zero length");
        // string memory fromAddressStr = msg.sender.toHexString();

        uint256 xChainFee = FeeManager(feeManager).getXChainFee(_toChainIdStr, FeeType.TX, feeTokenStr);
        address feeToken = stringToAddress(feeTokenStr);
        IERC20(feeToken).transferFrom(msg.sender, address(this), xChainFee);
        IERC20(feeToken).approve(feeManager, xChainFee);
        if(xChainFee>0) FeeManager(feeManager).payFee(xChainFee, feeTokenStr);

        // string memory targetStr = this.getChainContract(toChainIdStr_);
        // require(bytes(targetStr).length>0, "CTMRWA001X: Target contract address not found");

        (,,,uint256 slot) = ICTMRWA001(ctmRwa001Addr).getTokenInfo(_fromTokenId);
        // string memory toContractStr = ICTMRWA001(ctmRwa001Addr).getTokenContract(_toChainIdStr);

        ICTMRWA001(ctmRwa001Addr).burnValueX(_fromTokenId, _value);

        string memory funcCall = "mintX(uint256,string,string,uint256,uint256,uint256,uint256,string,string)";
        
        bytes memory callData = abi.encodeWithSignature(
            funcCall,
            _ID,
            fromAddressStr,
            _toAddressStr,
            _fromTokenId,
            _toTokenId,
            slot,
            _value,
            ctmRwa001AddrStr,
            toContractStr
        );
        
        c3call(targetStr, _toChainIdStr, callData);

        emit TransferFromSourceX(
            _ID,
            fromAddressStr,
            _toAddressStr,
            _fromTokenId,
            _toTokenId,
            slot,
            _value,
            ctmRwa001AddrStr,
            toContractStr
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

        require(ICTMRWA001(ctmRwa001Addr).ID() == _ID, "CTMRWA001X: Destination CTMRWA001 ID is incorrect");

        string memory storedContractStr = ICTMRWA001(ctmRwa001Addr).getTokenContract(fromChainIdStr);
        require(stringsEqual(storedContractStr, _fromContractStr), "CTMRWA001X: From an invalid CTMRWA001");

        ICTMRWA001(ctmRwa001Addr).mintValueX(toTokenId_, slot_, value_);
        (,,address owner,) = ICTMRWA001(ctmRwa001Addr).getTokenInfo(toTokenId_);
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
        string memory _toAddressStr,
        string memory _toChainIdStr,
        uint256 _fromTokenId,
        uint256 _ID,
        string memory feeTokenStr
    ) public {
        // require(!stringsEqual(toChainIdStr_, cID().toString()), "CTMRWA001X: Not a cross-chain transfer");
        // (bool ok, address ctmRwa001Addr) = this.getAttachedTokenAddress(_ID);
        // require(ok, "CTMRWA001X: The CTMRWA001 contract does not exist");
        // string memory ctmRwa001AddrStr = _toLower(ctmRwa001Addr.toHexString()); 
        require(bytes(feeTokenStr).length == 42, "CTMRWA001X: feeTokenStr has the wrong length");
        
        (
            string memory fromAddressStr, 
            address ctmRwa001Addr, 
            string memory ctmRwa001AddrStr, 
            address currentAdmin, 
            string memory currentAdminStr, 
            string memory toContractStr, 
            string memory targetStr
        ) = _checkChainAndAdmin(_ID, _toChainIdStr);
        
        require(ICTMRWA001(ctmRwa001Addr).isApprovedOrOwner(msg.sender, _fromTokenId), "CTMRWA001X: transfer caller is not owner nor approved");
        // string memory fromAddressStr = msg.sender.toHexString();


        require(IFeeManager(feeManager).isValidFeeToken(feeTokenStr), "CTMRWA001X: Not a valid fee token");

        uint256 xChainFee = FeeManager(feeManager).getXChainFee(_toChainIdStr, FeeType.TX, feeTokenStr);
        address feeToken = stringToAddress(feeTokenStr);
        IERC20(feeToken).transferFrom(msg.sender, address(this), xChainFee);
        IERC20(feeToken).approve(feeManager, xChainFee);
        if(xChainFee>0) FeeManager(feeManager).payFee(xChainFee, feeTokenStr);

        // string memory targetStr = this.getChainContract(toChainIdStr_);
        // require(bytes(targetStr).length>0, "CTMRWA001X: Target contract address not found");

        // string memory toContractStr = ICTMRWA001(ctmRwa001Addr).getTokenContract(_toChainIdStr);

        (,uint256 value,,uint256 slot) = ICTMRWA001(ctmRwa001Addr).getTokenInfo(_fromTokenId);


        ICTMRWA001X(ctmRwa001Addr).approveFromX(address(0), _fromTokenId);
        ICTMRWA001X(ctmRwa001Addr).clearApprovedValues(_fromTokenId);

        ICTMRWA001X(ctmRwa001Addr).removeTokenFromOwnerEnumeration(msg.sender, _fromTokenId);

        string memory funcCall = "mintX(uint256,string,string,uint256,uint256,uint256,string,string)";
        bytes memory callData = abi.encodeWithSignature(
            funcCall,
            _ID,
            fromAddressStr,
            _toAddressStr,
            _fromTokenId,
            slot,
            value,
            ctmRwa001AddrStr,
            toContractStr
        );

        c3call(targetStr, _toChainIdStr, callData);

        emit TransferFromSourceX(
            _ID,
            fromAddressStr,
            _toAddressStr,
            _fromTokenId,
            0,
            slot,
            value,
            ctmRwa001AddrStr,
            toContractStr
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

        require(ICTMRWA001(ctmRwa001Addr).ID() == _ID, "CTMRWA001X: Destination CTMRWA001 ID is incorrect");

        string memory storedContractStr = ICTMRWA001(ctmRwa001Addr).getTokenContract(fromChainIdStr);
        require(stringsEqual(storedContractStr, _fromContractStr), "CTMRWA001X: From an invalid CTMRWA001");

        uint256 newTokenId = ICTMRWA001(ctmRwa001Addr).mintFromX(toAddr, slot_, balance_);

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