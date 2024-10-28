// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.23;

// import "forge-std/console.sol";

import {Context} from "@openzeppelin/contracts/utils/Context.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

import "./lib/RWALib.sol";

import {GovernDapp} from "./routerV2/GovernDapp.sol";

import {IFeeManager, FeeType, IERC20Extended} from "./interfaces/IFeeManager.sol";
import {ICTMRWAGateway} from "./interfaces/ICTMRWAGateway.sol";
import {ICTMRWA001, TokenContract, ITokenContract} from "./interfaces/ICTMRWA001.sol";
import {ICTMRWA001Storage, URICategory, URIType} from "./interfaces/ICTMRWA001Storage.sol";
import {ICTMRWAMap} from "./interfaces/ICTMRWAMap.sol";
import {ITokenContract} from "./interfaces/ICTMRWA001.sol";

import {CTMRWA001Storage} from "./CTMRWA001Storage.sol";


interface TokenID {
    function ID() external view returns(uint256);
}

struct URIData {
    URICategory uriCategory;
    URIType uriType;
    uint256 slot;
    bytes32 uriHash;
}

contract CTMRWA001StorageManager is Context, GovernDapp {
    using Strings for *;

    address public ctmRwaDeployer;
    address public ctmRwa001Map;
    uint256 public rwaType;
    uint256 public version;
    address gateway;
    address feeManager;
    string cIdStr;
    
    string[] chainIdsStr;

    modifier onlyDeployer {
        require(msg.sender == ctmRwaDeployer, "CTMRWA001ManagerFactory: onlyDeployer function");
        _;
    }

    event LogFallback(bytes4 selector, bytes data, bytes reason);

    constructor(
        address _gov,
        uint256 _rwaType,
        uint256 _version,
        address _c3callerProxy,
        address _txSender,
        uint256 _dappID,
        address _ctmRwaDeployer,
        address _gateway,
        address _feeManager
    ) GovernDapp(_gov, _c3callerProxy, _txSender, _dappID) {
        ctmRwaDeployer = _ctmRwaDeployer;
        rwaType = _rwaType;
        version = _version;
        gateway = _gateway;
        feeManager = _feeManager;
        cIdStr = RWALib.cID().toString();
    }

    function setGateway(address _gateway) external onlyGov {
        gateway = _gateway;
    }

    function setFeeManager(address _feeManager) external onlyGov {
        feeManager = _feeManager;
    }

    function setCtmRwaDeployer(address _deployer) external onlyGov {
        ctmRwaDeployer = _deployer;
    }

    function setCtmRwaMap(address _map) external onlyGov {
        ctmRwa001Map = _map;
    }


    function deployStorage(
        uint256 _ID,
        address _tokenAddr,
        uint256 _rwaType,
        uint256 _version,
        address _map,
        address _gateway,
        address _feeManager
    ) external onlyDeployer returns(address) {

        CTMRWA001Storage ctmRwa001Storage = new CTMRWA001Storage{
            salt: bytes32(_ID) 
        }(
            _ID,
            _tokenAddr,
            _rwaType,
            _version,
            _map
        );

        return(address(ctmRwa001Storage));
    }

   
    
    function addURI(
        uint256 _ID,
        URICategory _uriCategory,
        URIType _uriType,
        uint256 _slot,
        bytes memory _objectName,
        bytes32 _uriDataHash,
        string[] memory _chainIdsStr
    ) external {

        (bool ok, address storageAddr) = ICTMRWAMap(ctmRwa001Map).getStorageContract(_ID, rwaType, version);
        require(ok, "CTMRWA001X: Could not find _ID or its storage address");

        (address ctmRwa001Addr, ) = _getTokenAddr(_ID);
        _checkTokenAdmin(ctmRwa001Addr);

        for(uint256 i=0; i<_chainIdsStr.length; i++) {
            string memory chainIdStr = RWALib._toLower(_chainIdsStr[i]);

            if(RWALib.stringsEqual(chainIdStr, cIdStr)) {
                ICTMRWA001Storage(storageAddr).addURILocal(_ID, _uriCategory, _uriType, _slot, _objectName, _uriDataHash);
            } else {
                (, string memory toRwaXStr) = _getSM(chainIdStr);

                string memory funcCall = "addURIX(uint256,uint8,uint8,uint256,string,bytes32)";
                bytes memory callData = abi.encodeWithSignature(
                    funcCall,
                    _ID,
                    _uriCategory,
                    _uriType,
                    _slot,
                    _objectName,
                    _uriDataHash
                );

                c3call(toRwaXStr, chainIdStr, callData);
            }
        }
    }


    function addURIX(
        uint256 _ID,
        URICategory _uriCategory,
        URIType _uriType,
        uint256 _slot,
        bytes memory _objectName,
        bytes32 _uriDataHash
    ) external onlyCaller returns(bool) {

        (bool ok, address storageAddr) = ICTMRWAMap(ctmRwa001Map).getStorageContract(_ID, rwaType, version);
        require(ok, "CTMRWA001X: Could not find _ID or its storage address");

        (, string memory fromChainIdStr,) = context();
        fromChainIdStr = RWALib._toLower(fromChainIdStr);

        ICTMRWA001Storage(storageAddr).addURILocal(_ID, _uriCategory, _uriType, _slot, _objectName, _uriDataHash);

        return(true);
    }

    function _getTokenAddr(uint256 _ID) internal view returns(address, string memory) {
        (bool ok, address tokenAddr) = ICTMRWAMap(ctmRwa001Map).getTokenContract(_ID, rwaType, version);
        require(ok, "CTMRWA001X: The requested tokenID does not exist");
        string memory tokenAddrStr = RWALib._toLower(tokenAddr.toHexString());

        return(tokenAddr, tokenAddrStr);
    }

    function _getSM(string memory _toChainIdStr) internal view returns(string memory, string memory) {
        require(!RWALib.stringsEqual(_toChainIdStr, cIdStr), "CTMRWA001X: Not a cross-chain tokenAdmin change");

        string memory fromAddressStr = RWALib._toLower(_msgSender().toHexString());

        (bool ok, string memory toSMStr) = ICTMRWAGateway(gateway).getAttachedStorageManager(rwaType, version, _toChainIdStr);
        require(ok, "CTMRWA001X: Target contract address not found");

        return(fromAddressStr, toSMStr);
    }

    function _checkTokenAdmin(address _tokenAddr) internal returns(address, string memory) {
        address currentAdmin = ICTMRWA001(_tokenAddr).tokenAdmin();
        string memory currentAdminStr = RWALib._toLower(currentAdmin.toHexString());

        require(_msgSender() == currentAdmin, "CTMRWA001X: Only tokenAdmin can change the tokenAdmin");

        return(currentAdmin, currentAdminStr);
    }



    function _c3Fallback(bytes4 _selector,
        bytes calldata _data,
        bytes calldata _reason) internal override returns (bool) {


        emit LogFallback(_selector, _data, _reason);
        return true;
    }
}