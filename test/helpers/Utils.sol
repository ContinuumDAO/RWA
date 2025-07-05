// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";

import {URIType, URICategory, URIData, ICTMRWA1Storage} from "../../src/storage/ICTMRWA1Storage.sol";

contract Utils is Test {

    uint256 constant RWA_TYPE = 1;
    uint256 constant VERSION = 1;

    function getRevert(bytes calldata _payload) external pure returns (bytes memory) {
        return(abi.decode(_payload[4:], (bytes)));
    }

    function stringToAddress(string memory str) public pure returns (address) {
        bytes memory strBytes = bytes(str);
        require(strBytes.length == 42, "Invalid address length");
        bytes memory addrBytes = new bytes(20);

        for (uint i = 0; i < 20; i++) {
            addrBytes[i] = bytes1(hexCharToByte(strBytes[2 + i * 2]) * 16 + hexCharToByte(strBytes[3 + i * 2]));
        }

        return address(uint160(bytes20(addrBytes)));
    }


    function hexCharToByte(bytes1 char) internal pure returns (uint8) {
        uint8 byteValue = uint8(char);
        if (byteValue >= uint8(bytes1('0')) && byteValue <= uint8(bytes1('9'))) {
            return byteValue - uint8(bytes1('0'));
        } else if (byteValue >= uint8(bytes1('a')) && byteValue <= uint8(bytes1('f'))) {
            return 10 + byteValue - uint8(bytes1('a'));
        } else if (byteValue >= uint8(bytes1('A')) && byteValue <= uint8(bytes1('F'))) {
            return 10 + byteValue - uint8(bytes1('A'));
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

    function cID() view internal returns(uint256) {
        return block.chainid;
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

    function _boolToArray(bool _bool) internal pure returns(bool[] memory) {
        bool[] memory boolArray = new bool[](1);
        boolArray[0] = _bool;
        return(boolArray);
    }

     function _uint256ToArray(uint256 _myUint256) internal pure returns(uint256[] memory) {
        uint256[] memory uintArray = new uint256[](1);
        uintArray[0] = _myUint256;
        return(uintArray);
    }

    function _uint8ToArray(uint8 _myUint8) internal pure returns(uint8[] memory) {
        uint8[] memory uintArray = new uint8[](1);
        uintArray[0] = _myUint8;
        return(uintArray);
    }

    function _uriCategoryToArray(URICategory _myCat) internal pure returns(URICategory[] memory) {
        URICategory[] memory uriCatArray = new URICategory[](1);
        uriCatArray[0] = _myCat;
        return(uriCatArray);
    }

    function _uriTypeToArray(URIType _myType) internal pure returns(URIType[] memory) {
        URIType[] memory uriTypeArray = new URIType[](1);
        uriTypeArray[0] = _myType;
        return(uriTypeArray);
    }

    function _bytes32ToArray(bytes32 _myBytes32) internal pure returns(bytes32[] memory) {
        bytes32[] memory bytes32Array = new bytes32[](1);
        bytes32Array[0] = _myBytes32;
        return(bytes32Array);
    }
}
