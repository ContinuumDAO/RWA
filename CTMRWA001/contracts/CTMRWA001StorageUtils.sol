// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.19;

import {Context} from "@openzeppelin/contracts/utils/Context.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

import {ICTMRWA001} from "./interfaces/ICTMRWA001.sol";
import {ICTMRWA001Storage, URICategory, URIType, URIData} from "./interfaces/ICTMRWA001Storage.sol";
import {ICTMRWAMap} from "./interfaces/ICTMRWAMap.sol";

import {CTMRWA001Storage} from "./CTMRWA001Storage.sol";


contract CTMRWA001StorageUtils is Context {
    using Strings for *;

    uint256 rwaType;
    uint256 version;
    address public ctmRwa001Map;
    address public storageManager;

    bytes4 public lastSelector;
    bytes public lastData;
    bytes public lastReason;

    modifier onlyStorageManager {
        require(_msgSender() == storageManager, "CTMRWA001StorageUtils: onlyStorageManager function");
        _;
    }

    event LogFallback(bytes4 selector, bytes data, bytes reason);

    bytes4 public AddURIX =
        bytes4(
            keccak256(
                "addURIX(uint256,uint256,string[],uint8[],uint8[],string[],uint256[],uint256[],bytes32[])"
            )
        );
        


    constructor(
        uint256 _rwaType,
        uint256 _version,
        address _map,
        address _storageManager
    ) {
        rwaType = _rwaType;
        version = _version;
        ctmRwa001Map = _map;
        storageManager = _storageManager;
    }

    function deployStorage(
        uint256 _ID,
        address _tokenAddr,
        uint256 _rwaType,
        uint256 _version,
        address _map
    ) external onlyStorageManager returns(address) {

        CTMRWA001Storage ctmRwa001Storage = new CTMRWA001Storage{
            salt: bytes32(_ID) 
        }(
            _ID,
            _tokenAddr,
            _rwaType,
            _version,
            _msgSender(),
            _map
        );

        return(address(ctmRwa001Storage));
    }

    function getLastReason() public view returns(string memory) {
        return(string(lastReason));
    }

    function smC3Fallback(
        bytes4 _selector,
        bytes calldata _data,
        bytes calldata _reason
    ) external onlyStorageManager returns(bool) {

        lastSelector = _selector;
        lastData = _data;
        lastReason = _reason;


        if(_selector == AddURIX) {

            uint256 ID;
            uint256 startNonce;
            string[] memory objectName;
            
            (
                ID,
                startNonce,
                objectName,,,,,,
            ) = abi.decode(_data,
                (uint256,uint256,string[],URICategory[],URIType[],string[],uint256[],uint256[],bytes32[])
            );

            (bool ok, address storageAddr) = ICTMRWAMap(ctmRwa001Map).getStorageContract(ID, rwaType, version);
            require(ok, "CTMRWA001StorageUtils: Could not find _ID or its storage address");

            ICTMRWA001Storage(storageAddr).popURILocal(objectName.length);
            ICTMRWA001Storage(storageAddr).setNonce(startNonce);
        }

        emit LogFallback(_selector, _data, _reason);

        return(true);
    }

    function _getTokenAddr(uint256 _ID) internal view returns(address, string memory) {
        (bool ok, address tokenAddr) = ICTMRWAMap(ctmRwa001Map).getTokenContract(_ID, rwaType, version);
        require(ok, "CTMRWA001StorageUtils: The requested tokenID does not exist");
        string memory tokenAddrStr = _toLower(tokenAddr.toHexString());

        return(tokenAddr, tokenAddrStr);
    }

    function stringToAddress(string memory str) internal pure returns (address) {
        bytes memory strBytes = bytes(str);
        require(strBytes.length == 42, "CTMRWA001StorageUtils: Invalid address length");
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