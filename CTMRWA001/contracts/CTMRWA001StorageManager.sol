// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.23;

// import "forge-std/console.sol";

import {Context} from "@openzeppelin/contracts/utils/Context.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";


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
    using SafeERC20 for IERC20;

    address public ctmRwaDeployer;
    address public ctmRwa001Map;
    uint256 public rwaType;
    uint256 public version;
    address gateway;
    address feeManager;
    string cIdStr;
    
    string[] chainIdsStr;

    modifier onlyDeployer {
        require(msg.sender == ctmRwaDeployer, "CTMRWA001StorageManager: onlyDeployer function");
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
        cIdStr = cID().toString();
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
        string memory _title,
        uint256 _slot,
        bytes32 _uriDataHash,
        string[] memory _chainIdsStr,
        string memory _feeTokenStr
    ) public {
        uint256 titleLength = bytes(_title).length;
        require(titleLength >= 10 && titleLength <= 128, "CTMRWA001StorageManager: The title parameter must be between 10 and 128 characters");
        (bool ok, address storageAddr) = ICTMRWAMap(ctmRwa001Map).getStorageContract(_ID, rwaType, version);
        require(ok, "CTMRWA001StorageManager: Could not find _ID or its storage address");

        (address ctmRwa001Addr, ) = _getTokenAddr(_ID);
        _checkTokenAdmin(ctmRwa001Addr);

        require(bytes(ICTMRWA001(ctmRwa001Addr).baseURI()).length > 0, "CTMRWA001StorageManager: This token does not have storage");

        if(_uriType != URIType.CONTRACT || _uriCategory != URICategory.ISSUER) {
            require(ICTMRWA001Storage(storageAddr).getURIHashCount(URICategory.ISSUER, URIType.CONTRACT) > 0, 
            "CTMRWA001StorageManager: Type CONTRACT and CATEGORY ISSUER must be the first stored element");
        }

        _payFee(_uriCategory, _feeTokenStr, _chainIdsStr, true);

        string memory objectName;

        if(stringsEqual(ICTMRWA001(ctmRwa001Addr).baseURI(), "GFLD")) {
            objectName = CTMRWA001Storage(storageAddr).greenfieldObject(_uriType, _slot);
        } else objectName = "";


        for(uint256 i=0; i<_chainIdsStr.length; i++) {
            string memory chainIdStr = _toLower(_chainIdsStr[i]);

            if(stringsEqual(chainIdStr, cIdStr)) {
                ICTMRWA001Storage(storageAddr).addURILocal(_ID, _uriCategory, _uriType, _title, _slot, objectName, _uriDataHash);
            } else {
                (, string memory toRwaSMStr) = _getSM(chainIdStr);

                string memory funcCall = "addURIX(uint256,uint8,uint8,string,uint256,string,bytes32)";
                bytes memory callData = abi.encodeWithSignature(
                    funcCall,
                    _ID,
                    _uriCategory,
                    _uriType,
                    _title,
                    _slot,
                    objectName,
                    _uriDataHash
                );

                c3call(toRwaSMStr, chainIdStr, callData);
            }
        }
    }


    function addURIX(
        uint256 _ID,
        URICategory _uriCategory,
        URIType _uriType,
        string memory _title,
        uint256 _slot,
        string memory _objectName,
        bytes32 _uriDataHash
    ) external onlyCaller returns(bool) {

        (bool ok, address storageAddr) = ICTMRWAMap(ctmRwa001Map).getStorageContract(_ID, rwaType, version);
        require(ok, "CTMRWA0CTMRWA001StorageManager: Could not find _ID or its storage address");

        ICTMRWA001Storage(storageAddr).addURILocal(_ID, _uriCategory, _uriType, _title, _slot, _objectName, _uriDataHash);

        return(true);
    }

    function _getTokenAddr(uint256 _ID) internal view returns(address, string memory) {
        (bool ok, address tokenAddr) = ICTMRWAMap(ctmRwa001Map).getTokenContract(_ID, rwaType, version);
        require(ok, "CTMRWA001StorageManager: The requested tokenID does not exist");
        string memory tokenAddrStr = _toLower(tokenAddr.toHexString());

        return(tokenAddr, tokenAddrStr);
    }

    function _getSM(string memory _toChainIdStr) internal view returns(string memory, string memory) {
        require(!stringsEqual(_toChainIdStr, cIdStr), "CTMRWA001StorageManager: Not a cross-chain tokenAdmin change");

        string memory fromAddressStr = _toLower(_msgSender().toHexString());

        (bool ok, string memory toSMStr) = ICTMRWAGateway(gateway).getAttachedStorageManager(rwaType, version, _toChainIdStr);
        require(ok, "CTMRWA001StorageManager: Target contract address not found");

        return(fromAddressStr, toSMStr);
    }

    function _checkTokenAdmin(address _tokenAddr) internal returns(address, string memory) {
        address currentAdmin = ICTMRWA001(_tokenAddr).tokenAdmin();
        string memory currentAdminStr = _toLower(currentAdmin.toHexString());

        require(_msgSender() == currentAdmin, "CTMRWA001StorageManager: Not tokenAdmin");

        return(currentAdmin, currentAdminStr);
    }

    function _payFee(
        URICategory _uriCategory, 
        string memory _feeTokenStr, 
        string[] memory _toChainIdsStr,
        bool _includeLocal
    ) internal returns(bool) {

        FeeType feeType;

        if(_uriCategory == URICategory.ISSUER) feeType = FeeType.ISSUER;
        else if(_uriCategory == URICategory.PROVENANCE) feeType = FeeType.PROVENANCE;
        else if(_uriCategory == URICategory.VALUATION) feeType = FeeType.VALUATION;
        else if(_uriCategory == URICategory.PROSPECTUS) feeType = FeeType.PROSPECTUS;
        else if(_uriCategory == URICategory.RATING) feeType = FeeType.RATING;
        else if(_uriCategory == URICategory.LEGAL) feeType = FeeType.LEGAL;
        else if(_uriCategory == URICategory.FINANCIAL) feeType = FeeType.FINANCIAL;
        else if(_uriCategory == URICategory.LICENSE) feeType = FeeType.LICENSE;
        else if(_uriCategory == URICategory.DUEDILIGENCE) feeType = FeeType.DUEDILIGENCE;
        else if(_uriCategory == URICategory.NOTICE) feeType = FeeType.NOTICE;
        else if(_uriCategory == URICategory.DIVIDEND) feeType = FeeType.DIVIDEND;
        else if(_uriCategory == URICategory.REDEMPTION) feeType = FeeType.REDEMPTION;
        else if(_uriCategory == URICategory.WHOCANINVEST) feeType = FeeType.WHOCANINVEST;
        else if(_uriCategory == URICategory.IMAGE) feeType = FeeType.IMAGE;
        else if(_uriCategory == URICategory.ICON) feeType = FeeType.ICON;

        uint256 fee = IFeeManager(feeManager).getXChainFee(_toChainIdsStr, _includeLocal, feeType, _feeTokenStr);
        
        if(fee>0) {
            address feeToken = stringToAddress(_feeTokenStr);
            uint256 feeWei = fee*10**(IERC20Extended(feeToken).decimals()-2);

            IERC20(feeToken).transferFrom(_msgSender(), address(this), feeWei);
            
            IERC20(feeToken).approve(feeManager, feeWei);
            IFeeManager(feeManager).payFee(feeWei, _feeTokenStr);
        }
        return(true);
    }

    function cID() internal view returns (uint256) {
        return block.chainid;
    }

    function strToUint(
        string memory _str
    ) internal pure returns (uint256 res, bool err) {
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

    function stringToAddress(string memory str) internal pure returns (address) {
        bytes memory strBytes = bytes(str);
        require(strBytes.length == 42, "CTMRWA001StorageManager: Invalid address length");
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
    ) internal pure returns (bool) {
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
    
    function _stringToArray(string memory _string) internal pure returns(string[] memory) {
        string[] memory strArray = new string[](1);
        strArray[0] = _string;
        return(strArray);
    }

    function _c3Fallback(bytes4 _selector,
        bytes calldata _data,
        bytes calldata _reason) internal override returns (bool) {


        emit LogFallback(_selector, _data, _reason);
        return true;
    }
}