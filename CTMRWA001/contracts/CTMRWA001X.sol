// SPDX-License-Identifier: GPL-3.0-or-later

// import "forge-std/console.sol";

pragma solidity ^0.8.23;

import {Context} from "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import {GovernDapp} from "./routerV2/GovernDapp.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./lib/RWALib.sol";

import {IFeeManager, FeeType, IERC20Extended} from "./interfaces/IFeeManager.sol";
import {ICTMRWAGateway} from "./interfaces/ICTMRWAGateway.sol";
import {ICTMRWA001, TokenContract, ITokenContract} from "./interfaces/ICTMRWA001.sol";
import {ICTMRWADeployer} from "./interfaces/ICTMRWADeployer.sol";
import {ICTMRWAMap} from "./interfaces/ICTMRWAMap.sol";
import {URICategory, URIType, ICTMRWA001Storage} from "./interfaces/ICTMRWA001Storage.sol";
import {ICTMRWA001XFallback} from "./interfaces/ICTMRWA001XFallback.sol";
import {ICTMRWA001Token} from "./interfaces/ICTMRWA001Token.sol";


contract CTMRWA001X is Context, GovernDapp {
    using Strings for *;
    using SafeERC20 for IERC20;

    address public gateway;
    uint256 rwaType;
    uint256 version;
    address public feeManager;
    address public ctmRwaDeployer;
    address public ctmRwa001Map;
    address public fallbackAddr;
    string public cIDStr;


    mapping(address => address[]) public adminTokens;  // tokenAdmin address => array of CTMRWA001 contracts
    mapping(address => address[]) public ownedCtmRwa001;  // owner address => array of CTMRWA001 contracts

    //event LogFallback(bytes4 selector, bytes data, bytes reason);

    event CreateNewCTMRWA001(
        address ctmRwa001Token, 
        uint256 ID, 
        address newAdmin, 
        string fromChainIdStr, 
        string fromContractStr
    );

    event ChangeAdminDest(string currentAdminStr, string newAdminStr, string fromChainIdStr);
    event AddNewChainAndToken(string fromChainIdStr, string fromContractStr, string[] chainIdsStr, string[] ctmRwa001AddrsStr);
   

    event TransferToDestX(
        uint256 ID,
        string fromAddressStr,
        string toAddressStr,
        uint256 fromTokenId,
        uint256 toTokenId,
        uint256 slot,
        uint256 value,
        string fromChainIdStr,
        string fromTokenStr,
        string ctmRwa001AddrStr
    );


    constructor(
        address _gateway,
        address _feeManager,
        address _gov,
        address _c3callerProxy,
        address _txSender,
        uint256 _dappID
    ) GovernDapp(_gov, _c3callerProxy, _txSender, _dappID) {
        gateway = _gateway;
        rwaType = 1;
        version = 1;
        feeManager = _feeManager;
        cIDStr = RWALib.cID().toString();
    }

    function changeFeeManager(address _feeManager) external onlyGov {
        feeManager = _feeManager;
    }

    function setGateway(address _gateway) external onlyGov {
        gateway = _gateway;
    }


    function setCtmRwaMap(address _map) external onlyGov {
        ctmRwa001Map = _map;
    }

    function setCtmRwaDeployer(address _deployer) external onlyGov {
        ctmRwaDeployer = _deployer;
    }

    function setFallback(address _fallbackAddr) external onlyGov {
        fallbackAddr = _fallbackAddr;

    }
   

    function deployAllCTMRWA001X(
        bool _includeLocal,
        uint256 _existingID,
        uint256 _rwaType,
        uint256 _version,
        string memory _tokenName, 
        string memory _symbol, 
        uint8 _decimals,
        string memory _baseURI,
        string[] memory _toChainIdsStr,
        string memory _feeTokenStr
    ) public returns(uint256) {
        require(!_includeLocal && _existingID>0 || _includeLocal && _existingID == 0, "CTMRWA001X: Incorrect call logic");
        uint256 nChains = _toChainIdsStr.length;

        string memory ctmRwa001AddrStr;
        address ctmRwa001Addr;
        address currentAdmin;
        uint256 ID;
        string memory tokenName;
        string memory symbol;
        uint8 decimals;
        string memory baseURI;

        if(_includeLocal) {
            // generate a new ID
            ID = uint256(keccak256(abi.encode(
                _tokenName,
                _symbol,
                _decimals,
                block.timestamp,
                _msgSender()
            )));

            tokenName = _tokenName;
            symbol = _symbol;
            decimals = _decimals;
            baseURI = _baseURI;

            currentAdmin = _msgSender();
            ctmRwa001Addr = _deployCTMRWA001Local(ID, _rwaType, _version, _tokenName, _symbol, _decimals, baseURI, currentAdmin);

            emit CreateNewCTMRWA001(ctmRwa001Addr, ID, currentAdmin, cIDStr, "");
        } else {  // a CTMRWA001 token must be deployed already, so use the existing ID
            ID = _existingID;
            (bool ok, address rwa001Addr) = ICTMRWAMap(ctmRwa001Map).getTokenContract(ID, _rwaType, _version);
            require(ok, "CTMRWA001X: ID does not exist on local chain");
            ctmRwa001Addr = rwa001Addr;

            _checkTokenAdmin(ctmRwa001Addr);

            tokenName = ICTMRWA001(ctmRwa001Addr).name();
            symbol = ICTMRWA001(ctmRwa001Addr).symbol();
            decimals = ICTMRWA001(ctmRwa001Addr).valueDecimals();
            baseURI = ICTMRWA001(ctmRwa001Addr).baseURI();
        }

        ctmRwa001AddrStr = RWALib._toLower(ctmRwa001Addr.toHexString());

        _payFee(FeeType.DEPLOY, _feeTokenStr, _toChainIdsStr, _includeLocal);

        for(uint256 i=0; i<nChains; i++){
            _deployCTMRWA001X(
                tokenName, 
                symbol,
                decimals, 
                baseURI,
                _toChainIdsStr[i], 
                ctmRwa001AddrStr
            );
        }

        return(ID);

    }

        
    function _deployCTMRWA001Local(
        uint256 _ID,
        uint256 _rwaType,
        uint256 _version,
        string memory _tokenName, 
        string memory _symbol, 
        uint8 _decimals,
        string memory _baseURI,
        address _tokenAdmin
    ) internal returns(address) {
        (bool ok,) = ICTMRWAMap(ctmRwa001Map).getTokenContract(_ID, _rwaType, _version);
        require(!ok, "CTMRWA001X: A local contract with this ID already exists");

        bytes memory deployData = abi.encode(_ID, _tokenAdmin, _tokenName, _symbol, _decimals, _baseURI, address(this));

        address ctmRwa001Token = ICTMRWADeployer(ctmRwaDeployer).deploy(
            _ID,
            _rwaType,
            _version,
            deployData
        );

        ICTMRWA001(ctmRwa001Token).changeAdmin(_tokenAdmin);

        ok = ICTMRWA001(ctmRwa001Token).attachId(_ID, _tokenAdmin);
        require(ok, "CTMRWA001X: Could not attachId to new token");

        adminTokens[_tokenAdmin].push(ctmRwa001Token);

        return(ctmRwa001Token);
    }


    // Deploys a new CTMRWA001 instance on a destination chain, 
    // recovering the ID from a required local instance of CTMRWA001, owned by tokenAdmin
    function _deployCTMRWA001X(
        string memory _tokenName, 
        string memory _symbol, 
        uint8 _decimals,
        string memory _baseURI,
        string memory _toChainIdStr,
        string memory _ctmRwa001AddrStr
    ) internal returns (bool) {
        require(!RWALib.stringsEqual(_toChainIdStr, RWALib.cID().toString()), "CTMRWA001X: Not a cross-chain transfer");
        address ctmRwa001Addr = RWALib.stringToAddress(_ctmRwa001AddrStr);

        (, string memory currentAdminStr) = _checkTokenAdmin(ctmRwa001Addr);

        uint256 ID = ICTMRWA001(ctmRwa001Addr).ID();

        string memory toChainIdStr = RWALib._toLower(_toChainIdStr);

        (, string memory toRwaXStr) = _getRWAX(toChainIdStr);

        string memory funcCall = "deployCTMRWA001(string,uint256,uint256,uint256,string,string,uint8,string,string)";
        bytes memory callData = abi.encodeWithSignature(
            funcCall,
            currentAdminStr,
            ID,
            rwaType,
            version,
            _tokenName,
            _symbol,
            _decimals,
            _baseURI,
            _ctmRwa001AddrStr
        );

        c3call(toRwaXStr, toChainIdStr, callData);

        return(true);
        
    }

    // Deploys a new CTMRWA001 instance on a destination chain, 
    // with the ID sent from a required local instance of CTMRWA001, owned by tokenAdmin
    function deployCTMRWA001(
        string memory _newAdminStr,
        uint256 _ID,
        uint256 _rwaType,
        uint256 _version,
        string memory _tokenName, 
        string memory _symbol, 
        uint8 _decimals,
        string memory _baseURI,
        string memory _fromContractStr
    ) external onlyCaller returns(bool) {

        (bool ok,) = ICTMRWAMap(ctmRwa001Map).getTokenContract(_ID, _rwaType, _version);
        require(!ok, "CTMRWA001X: A local contract with this ID already exists");

        address newAdmin = RWALib.stringToAddress(_newAdminStr);

        (, string memory fromChainIdStr,) = context();
        fromChainIdStr = RWALib._toLower(fromChainIdStr);

        address ctmRwa001Token = _deployCTMRWA001Local(_ID, _rwaType, _version, _tokenName, _symbol, _decimals, _baseURI, newAdmin);

        emit CreateNewCTMRWA001(ctmRwa001Token, _ID, newAdmin, fromChainIdStr, _fromContractStr);

        return(true);
    }


    function changeAdmin(address _newAdmin, uint256 _ID) external returns(bool) {

        (address ctmRwa001Addr,) = _getTokenAddr(_ID);
        _checkTokenAdmin(ctmRwa001Addr);

        bool ok = _replaceAdmin(_newAdmin, _msgSender(), ctmRwa001Addr);
        if(ok) {
            ICTMRWA001(ctmRwa001Addr).changeAdmin(_newAdmin);
            (, address ctmRwa001StorageAddr) = ICTMRWAMap(ctmRwa001Map).getStorageContract(_ID, rwaType, version);
            ICTMRWA001Storage(ctmRwa001StorageAddr).setTokenAdmin(_newAdmin);
            return(true);
        } else revert("CTMRWA001X: Could not replace admin address");

        // emit ChangeAdmin(_ID, currentAdminStr, _newAdmin.toHexString(), "");

    }

    
    // Change the tokenAdmin address of a deployed CTMRWA001 instance on another chain
    function changeAdminCrossChain(
        string memory _newAdminStr,
        string memory _toChainIdStr,
        uint256 _ID,
        string memory _feeTokenStr
    ) public returns(bool) {

        string memory toChainIdStr = RWALib._toLower(_toChainIdStr);
        
        (address ctmRwa001Addr, ) = _getTokenAddr(_ID);
        (, string memory toRwaXStr) = _getRWAX(toChainIdStr);
        (, string memory currentAdminStr) = _checkTokenAdmin(ctmRwa001Addr);

        _payFee(FeeType.ADMIN, _feeTokenStr, RWALib._stringToArray(toChainIdStr), false);

        string memory funcCall = "adminX(uint256,string,string)";
        bytes memory callData = abi.encodeWithSignature(
            funcCall,
            _ID,
            currentAdminStr,
            _newAdminStr
        );

        c3call(toRwaXStr, toChainIdStr, callData);

        return(true);
    }


    function adminX(
        uint256 _ID,
        string memory _oldAdminStr,
        string memory _newAdminStr
    ) external onlyCaller returns(bool) {
        
        (bool ok, address ctmRwa001Addr) = ICTMRWAMap(ctmRwa001Map).getTokenContract(_ID, rwaType, version);
        require(ok, "CTMRWA001X: Destination token contract with this ID does not exist");

        address newAdmin = RWALib.stringToAddress(_newAdminStr);

        (, string memory fromChainIdStr,) = context();
        fromChainIdStr = RWALib._toLower(fromChainIdStr);

        address currentAdmin = ICTMRWA001(ctmRwa001Addr).tokenAdmin();
        address oldAdmin = RWALib.stringToAddress(_oldAdminStr);
        require(currentAdmin == oldAdmin, "CTMRWA001X: Not admin. Cannot change admin address");

        ok = _replaceAdmin(newAdmin, oldAdmin, ctmRwa001Addr);
        if(ok) {
            ICTMRWA001(ctmRwa001Addr).changeAdmin(newAdmin);
            (, address ctmRwa001StorageAddr) = ICTMRWAMap(ctmRwa001Map).getStorageContract(_ID, rwaType, version);
            ICTMRWA001Storage(ctmRwa001StorageAddr).setTokenAdmin(newAdmin);
            return(true);
        } else revert("CTMRWA001X: Could not replace admin address");
    
    }


    function mintNewTokenValueLocal(
        address toAddress_,
        uint256 toTokenId_,  // Set to 0 to create a newTokenId
        uint256 slot_,
        uint256 value_,
        uint256 _ID
    ) public returns(uint256) {

        (address ctmRwa001Addr, ) = _getTokenAddr(_ID);
        _checkTokenAdmin(ctmRwa001Addr);

        if(toTokenId_>0) {
            ICTMRWA001(ctmRwa001Addr).mintValueX(toTokenId_, slot_, value_);
            return(toTokenId_);
        } else {
            uint256 newTokenId = ICTMRWA001(ctmRwa001Addr).mintFromX(toAddress_, slot_, value_);
            (,,address owner,) = ICTMRWA001(ctmRwa001Addr).getTokenInfo(newTokenId);
            ownedCtmRwa001[owner].push(ctmRwa001Addr);

            return(newTokenId);
        }

    }

    function mintNewTokenValueX(
        string memory _toAddressStr,
        string memory _toChainIdStr,
        uint256 _slot,
        uint256 _value,
        uint256 _ID,
        string memory _feeTokenStr
    ) public {
        string memory toChainIdStr = RWALib._toLower(_toChainIdStr);

        (address ctmRwa001Addr, string memory ctmRwa001AddrStr) = _getTokenAddr(_ID);
        (string memory fromAddressStr, string memory toRwaXStr) = _getRWAX(toChainIdStr);
        _checkTokenAdmin(ctmRwa001Addr);

        _payFee(FeeType.MINT, _feeTokenStr, RWALib._stringToArray(toChainIdStr), false);

        string memory funcCall = "mintX(uint256,string,string,uint256,uint256,uint256,string)";
        bytes memory callData = abi.encodeWithSignature(
            funcCall,
            _ID,
            fromAddressStr,
            _toAddressStr,
            0,  // Not used, since we are not transferring value from a tokenId, but creating new value
            _slot,
            _value,
            ctmRwa001AddrStr
        );

        c3call(toRwaXStr, toChainIdStr, callData);
    }

    
    function transferFromX(
        uint256 _fromTokenId,
        string memory _toAddressStr,
        string memory _toChainIdStr,
        uint256 _value,
        uint256 _ID,
        string memory _feeTokenStr
    ) public {
        require(bytes(_toAddressStr).length>0, "CTMRWA001X: Destination address has zero length");

        string memory toChainIdStr = RWALib._toLower(_toChainIdStr);

        (address ctmRwa001Addr, string memory ctmRwa001AddrStr) = _getTokenAddr(_ID);
        (string memory fromAddressStr, string memory toRwaXStr) = _getRWAX(toChainIdStr);
        
        ICTMRWA001(ctmRwa001Addr).spendAllowance(_msgSender(), _fromTokenId, _value);

        _payFee(FeeType.TX, _feeTokenStr, RWALib._stringToArray(toChainIdStr), false);

        uint256 slot = ICTMRWA001(ctmRwa001Addr).slotOf(_fromTokenId);

        ICTMRWA001(ctmRwa001Addr).burnValueX(_fromTokenId, _value);

        string memory funcCall = "mintX(uint256,string,string,uint256,uint256,uint256,string)";
        
        bytes memory callData = abi.encodeWithSignature(
            funcCall,
            _ID,
            fromAddressStr,
            _toAddressStr,
            _fromTokenId,
            slot,
            _value,
            ctmRwa001AddrStr
        );
        
        c3call(toRwaXStr, toChainIdStr, callData);

    }
    

    function transferFromX(
        uint256 _fromTokenId,
        string memory _toAddressStr,
        uint256 _toTokenId,
        string memory _toChainIdStr,
        uint256 _value,
        uint256 _ID,
        string memory _feeTokenStr
    ) public {
        string memory toChainIdStr = RWALib._toLower(_toChainIdStr);

        (address ctmRwa001Addr, string memory ctmRwa001AddrStr) = _getTokenAddr(_ID);
        (string memory fromAddressStr, string memory toRwaXStr) = _getRWAX(toChainIdStr);
        
        ICTMRWA001(ctmRwa001Addr).spendAllowance(_msgSender(), _fromTokenId, _value);
        require(bytes(_toAddressStr).length>0, "CTMRWA001X: Destination address has zero length");

        _payFee(FeeType.TX, _feeTokenStr, RWALib._stringToArray(toChainIdStr), false);

        uint256 slot = ICTMRWA001(ctmRwa001Addr).slotOf(_fromTokenId);

        ICTMRWA001(ctmRwa001Addr).burnValueX(_fromTokenId, _value);

        string memory funcCall = "mintX(uint256,string,string,uint256,uint256,uint256,uint256,string)";
        
        bytes memory callData = abi.encodeWithSignature(
            funcCall,
            _ID,
            fromAddressStr,
            _toAddressStr,
            _fromTokenId,
            _toTokenId,
            slot,
            _value,
            ctmRwa001AddrStr
        );
        
        c3call(toRwaXStr, toChainIdStr, callData);

    }

    function mintX(
        uint256 _ID,
        string memory _fromAddressStr,
        string memory _toAddressStr,
        uint256 _fromTokenId,
        uint256 _toTokenId,
        uint256 _slot,
        uint256 _value,
        string memory _fromTokenStr
    ) external onlyCaller returns(bool){

        (, string memory fromChainIdStr,) = context();

        (bool ok, address ctmRwa001Addr) = ICTMRWAMap(ctmRwa001Map).getTokenContract(_ID, rwaType, version);
        require(ok, "CTMRWA001X: Destination token contract with this ID does not exist");

        string memory ctmRwa001AddrStr = RWALib._toLower(ctmRwa001Addr.toHexString());

        ICTMRWA001(ctmRwa001Addr).mintValueX(_toTokenId, _slot, _value);
        (,,address owner,) = ICTMRWA001(ctmRwa001Addr).getTokenInfo(_toTokenId);
        ownedCtmRwa001[owner].push(ctmRwa001Addr);

        emit TransferToDestX(
            _ID,
            _fromAddressStr,
            _toAddressStr,
            _fromTokenId,
            _toTokenId,
            _slot,
            _value,
            fromChainIdStr,
            _fromTokenStr,
            ctmRwa001AddrStr
        );

        return(true);
    }

    function transferFromX(
        string memory _toAddressStr,
        string memory _toChainIdStr,
        uint256 _fromTokenId,
        uint256 _ID,
        string memory _feeTokenStr
    ) public {
        string memory toChainIdStr = RWALib._toLower(_toChainIdStr);

        (address ctmRwa001Addr, string memory ctmRwa001AddrStr) = _getTokenAddr(_ID);
        (string memory fromAddressStr, string memory toRwaXStr) = _getRWAX(toChainIdStr);
        
        require(ICTMRWA001(ctmRwa001Addr).isApprovedOrOwner(_msgSender(), _fromTokenId), "CTMRWA001X: transfer caller is not owner nor approved");

        _payFee(FeeType.TX, _feeTokenStr, RWALib._stringToArray(toChainIdStr), false);

        (,uint256 value,,uint256 slot) = ICTMRWA001(ctmRwa001Addr).getTokenInfo(_fromTokenId);

        ICTMRWA001(ctmRwa001Addr).approveFromX(address(0), _fromTokenId);
        ICTMRWA001(ctmRwa001Addr).clearApprovedValues(_fromTokenId);

        ICTMRWA001(ctmRwa001Addr).removeTokenFromOwnerEnumeration(_msgSender(), _fromTokenId);

        string memory funcCall = "mintX(uint256,string,string,uint256,uint256,uint256,string)";
        bytes memory callData = abi.encodeWithSignature(
            funcCall,
            _ID,
            fromAddressStr,
            _toAddressStr,
            _fromTokenId,
            slot,
            value,
            ctmRwa001AddrStr
        );

        c3call(toRwaXStr, toChainIdStr, callData);

    }


    function mintX(
        uint256 _ID,
        string memory _fromAddressStr,
        string memory _toAddressStr,
        uint256 _fromTokenId,
        uint256 _slot,
        uint256 _balance,
        string memory _fromTokenStr
    ) external onlyCaller returns(bool){

        (, string memory fromChainIdStr,) = context();

        address toAddr = RWALib.stringToAddress(_toAddressStr);

        (bool ok, address ctmRwa001Addr) = ICTMRWAMap(ctmRwa001Map).getTokenContract(_ID, rwaType, version);
        require(ok, "CTMRWA001X: Destination token contract with this ID does not exist"); 

        string memory ctmRwa001AddrStr = RWALib._toLower(ctmRwa001Addr.toHexString());

        uint256 newTokenId = ICTMRWA001(ctmRwa001Addr).mintFromX(toAddr, _slot, _balance);

        ownedCtmRwa001[toAddr].push(ctmRwa001Addr);

        emit TransferToDestX(
            _ID,
            _fromAddressStr,
            _toAddressStr,
            _fromTokenId,
            newTokenId,
            _slot,
            _balance,
            fromChainIdStr,
            _fromTokenStr,
            ctmRwa001AddrStr
        );

        return(true);
    }


    // End of cross chain transfers


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

    function _getTokenAddr(uint256 _ID) internal view returns(address, string memory) {
        (bool ok, address tokenAddr) = ICTMRWAMap(ctmRwa001Map).getTokenContract(_ID, rwaType, version);
        require(ok, "CTMRWA001X: The requested tokenID does not exist");
        string memory tokenAddrStr = RWALib._toLower(tokenAddr.toHexString());

        return(tokenAddr, tokenAddrStr);
    }

    function _getRWAX(string memory _toChainIdStr) internal view returns(string memory, string memory) {
        require(!RWALib.stringsEqual(_toChainIdStr, cIDStr), "CTMRWA001X: Not a cross-chain tokenAdmin change");

        string memory fromAddressStr = RWALib._toLower(_msgSender().toHexString());

        (bool ok, string memory toRwaXStr) = ICTMRWAGateway(gateway).getAttachedRWAX(rwaType, version, _toChainIdStr);
        require(ok, "CTMRWA001X: Target contract address not found");

        return(fromAddressStr, toRwaXStr);
    }

    function _checkTokenAdmin(address _tokenAddr) internal returns(address, string memory) {
        address currentAdmin = ICTMRWA001(_tokenAddr).tokenAdmin();
        string memory currentAdminStr = RWALib._toLower(currentAdmin.toHexString());

        require(_msgSender() == currentAdmin, "CTMRWA001X: Only tokenAdmin can change the tokenAdmin");

        return(currentAdmin, currentAdminStr);
    }

    function _replaceAdmin(address _newAdmin, address _oldAdmin, address _tokenId) internal returns(bool) {
        uint256 found;
        for(uint256 i=0; i<adminTokens[_oldAdmin].length; i++) {
            if(adminTokens[_oldAdmin][i] == _tokenId) {
                found = i;
            }
        }
        if(found>0) {
            adminTokens[_newAdmin].push(_tokenId);
            delete adminTokens[_oldAdmin][found];
            return(true);
        } else return(false);
    }

    function _payFee(
        FeeType _feeType, 
        string memory _feeTokenStr, 
        string[] memory _toChainIdsStr,
        bool _includeLocal
    ) internal returns(bool) {
        uint256 fee = IFeeManager(feeManager).getXChainFee(_toChainIdsStr, _includeLocal, _feeType, _feeTokenStr);
        
        if(fee>0) {
            address feeToken = RWALib.stringToAddress(_feeTokenStr);
            uint256 feeWei = fee*10**(IERC20Extended(feeToken).decimals()-2);

            IERC20(feeToken).transferFrom(_msgSender(), address(this), feeWei);
            
            IERC20(feeToken).approve(feeManager, feeWei);
            IFeeManager(feeManager).payFee(feeWei, _feeTokenStr);
        }
        return(true);
    }

   

    function _c3Fallback(
        bytes4 _selector,
        bytes calldata _data,
        bytes calldata _reason
    ) internal override returns (bool) {

        bool ok = ICTMRWA001XFallback(fallbackAddr).rwa001XC3Fallback(
            _selector,
            _data,
            _reason
        );

        //emit LogFallback(_selector, _data, _reason);
        return ok;
    }

}