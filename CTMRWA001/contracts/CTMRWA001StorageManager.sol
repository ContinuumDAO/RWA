// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.23;

// import "forge-std/console.sol";

import {Context} from "@openzeppelin/contracts/utils/Context.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

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
            string memory chainIdStr = _toLower(_chainIdsStr[i]);

            if(stringsEqual(chainIdStr, cIdStr)) {
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
        fromChainIdStr = _toLower(fromChainIdStr);

        ICTMRWA001Storage(storageAddr).addURILocal(_ID, _uriCategory, _uriType, _slot, _objectName, _uriDataHash);

        return(true);
    }

    function _getTokenAddr(uint256 _ID) internal view returns(address, string memory) {
        (bool ok, address tokenAddr) = ICTMRWAMap(ctmRwa001Map).getTokenContract(_ID, rwaType, version);
        require(ok, "CTMRWA001X: The requested tokenID does not exist");
        string memory tokenAddrStr = _toLower(tokenAddr.toHexString());

        return(tokenAddr, tokenAddrStr);
    }

    function _getSM(string memory _toChainIdStr) internal view returns(string memory, string memory) {
        require(!stringsEqual(_toChainIdStr, cIdStr), "CTMRWA001X: Not a cross-chain tokenAdmin change");

        string memory fromAddressStr = _toLower(_msgSender().toHexString());

        (bool ok, string memory toSMStr) = ICTMRWAGateway(gateway).getAttachedStorageManager(rwaType, version, _toChainIdStr);
        require(ok, "CTMRWA001X: Target contract address not found");

        return(fromAddressStr, toSMStr);
    }

    function _checkTokenAdmin(address _tokenAddr) internal returns(address, string memory) {
        address currentAdmin = ICTMRWA001(_tokenAddr).tokenAdmin();
        string memory currentAdminStr = _toLower(currentAdmin.toHexString());

        require(_msgSender() == currentAdmin, "CTMRWA001X: Only tokenAdmin can change the tokenAdmin");

        return(currentAdmin, currentAdminStr);
    }

    function _stringToArray(string memory _string) internal pure returns(string[] memory) {
        string[] memory strArray = new string[](1);
        strArray[0] = _string;
        return(strArray);
    }

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