// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.27;

import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

import { Test } from "forge-std/Test.sol";

import { ICTMRWA1Storage, URICategory, URIData, URIType } from "../../src/storage/ICTMRWA1Storage.sol";
import { CTMRWAProxy } from "../../src/utils/CTMRWAProxy.sol";

contract Utils is Test {
    using Strings for *;

    struct FeeContracts {
        address rwa1X;
        address ctmRwaDeployInvest;
        address ctmRwaERC20Deployer;
        address identity;
        address sentryManager;
        address storageManager;
        address rwa1XUtils;
    }

    uint256 constant RWA_TYPE = 1;
    uint256 constant VERSION = 1;

    string cIdStr = block.chainid.toString();

    function getRevert(bytes calldata _payload) external pure returns (bytes memory) {
        return (abi.decode(_payload[4:], (bytes)));
    }

    function stringToAddress(string memory str) public pure returns (address) {
        bytes memory strBytes = bytes(str);
        require(strBytes.length == 42, "Invalid address length");
        bytes memory addrBytes = new bytes(20);

        for (uint256 i = 0; i < 20; i++) {
            addrBytes[i] = bytes1(hexCharToByte(strBytes[2 + i * 2]) * 16 + hexCharToByte(strBytes[3 + i * 2]));
        }

        return address(uint160(bytes20(addrBytes)));
    }

    function hexCharToByte(bytes1 _char) internal pure returns (uint8) {
        uint8 byteValue = uint8(_char);
        if (byteValue >= uint8(bytes1("0")) && byteValue <= uint8(bytes1("9"))) {
            return byteValue - uint8(bytes1("0"));
        } else if (byteValue >= uint8(bytes1("a")) && byteValue <= uint8(bytes1("f"))) {
            return 10 + byteValue - uint8(bytes1("a"));
        } else if (byteValue >= uint8(bytes1("A")) && byteValue <= uint8(bytes1("F"))) {
            return 10 + byteValue - uint8(bytes1("A"));
        }
        revert("Invalid hex character");
    }

    function _deployProxy(address implementation, bytes memory _data) internal returns (address proxy) {
        proxy = address(new CTMRWAProxy(implementation, _data));
    }

    function stringsEqual(string memory a, string memory b) public pure returns (bool) {
        bytes32 ka = keccak256(abi.encode(a));
        bytes32 kb = keccak256(abi.encode(b));
        return (ka == kb);
    }

    // Helper to convert address to string
    function addressToString(address _addr) internal pure returns (string memory) {
        bytes memory s = new bytes(40);
        for (uint256 i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint256(uint160(_addr)) / (2 ** (8 * (19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2 * i] = char(hi);
            s[2 * i + 1] = char(lo);
        }
        return string(abi.encodePacked("0x", s));
    }

    function char(bytes1 b) internal pure returns (bytes1 c) {
        if (uint8(b) < 10) {
            return bytes1(uint8(b) + 0x30);
        } else {
            return bytes1(uint8(b) + 0x57);
        }
    }

    function cID() internal view returns (uint256) {
        return block.chainid;
    }

    function _toLower(string memory str) internal pure returns (string memory) {
        bytes memory bStr = bytes(str);
        bytes memory bLower = new bytes(bStr.length);
        for (uint256 i = 0; i < bStr.length; i++) {
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

    function _includesAddress(address _addr, address[] memory _addressList) internal pure returns (bool) {
        uint256 len = _addressList.length;

        for (uint256 i = 0; i < len; i++) {
            if (_addressList[i] == _addr) {
                return true;
            }
        }
        return false;
    }

    function _stringToArray(string memory _string) internal pure returns (string[] memory) {
        string[] memory strArray = new string[](1);
        strArray[0] = _string;
        return (strArray);
    }

    function _boolToArray(bool _bool) internal pure returns (bool[] memory) {
        bool[] memory boolArray = new bool[](1);
        boolArray[0] = _bool;
        return (boolArray);
    }

    function _uint256ToArray(uint256 _myUint256) internal pure returns (uint256[] memory) {
        uint256[] memory uintArray = new uint256[](1);
        uintArray[0] = _myUint256;
        return (uintArray);
    }

    function _uint8ToArray(uint8 _myUint8) internal pure returns (uint8[] memory) {
        uint8[] memory uintArray = new uint8[](1);
        uintArray[0] = _myUint8;
        return (uintArray);
    }

    function _uriCategoryToArray(URICategory _myCat) internal pure returns (URICategory[] memory) {
        URICategory[] memory uriCatArray = new URICategory[](1);
        uriCatArray[0] = _myCat;
        return (uriCatArray);
    }

    function _uriTypeToArray(URIType _myType) internal pure returns (URIType[] memory) {
        URIType[] memory uriTypeArray = new URIType[](1);
        uriTypeArray[0] = _myType;
        return (uriTypeArray);
    }

    function _bytes32ToArray(bytes32 _myBytes32) internal pure returns (bytes32[] memory) {
        bytes32[] memory bytes32Array = new bytes32[](1);
        bytes32Array[0] = _myBytes32;
        return (bytes32Array);
    }
}
