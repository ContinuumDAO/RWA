// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.19;

import { Context } from "@openzeppelin/contracts/utils/Context.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

import { ICTMRWA1 } from "../core/ICTMRWA1.sol";

import { CTMRWA1Sentry } from "../sentry/CTMRWA1Sentry.sol";
import { ICTMRWA1Sentry } from "../sentry/ICTMRWA1Sentry.sol";
import { ICTMRWAMap } from "../shared/ICTMRWAMap.sol";

contract CTMRWA1SentryUtils is Context {
    using Strings for *;

    uint256 rwaType;
    uint256 version;
    address public ctmRwa1Map;
    address public sentryManager;

    bytes4 public lastSelector;
    bytes public lastData;
    bytes public lastReason;

    modifier onlySentryManager() {
        require(_msgSender() == sentryManager, "CTMRWA1SentryUtils: onlySentryManager function");
        _;
    }

    event LogFallback(bytes4 selector, bytes data, bytes reason);

    constructor(uint256 _rwaType, uint256 _version, address _map, address _sentryManager) {
        rwaType = _rwaType;
        version = _version;
        ctmRwa1Map = _map;
        sentryManager = _sentryManager;
    }

    function deploySentry(uint256 _ID, address _tokenAddr, uint256 _rwaType, uint256 _version, address _map)
        external
        onlySentryManager
        returns (address)
    {
        CTMRWA1Sentry ctmRwa1Sentry =
            new CTMRWA1Sentry{ salt: bytes32(_ID) }(_ID, _tokenAddr, _rwaType, _version, _msgSender(), _map);

        return (address(ctmRwa1Sentry));
    }

    function getLastReason() public view returns (string memory) {
        return (string(lastReason));
    }

    function sentryC3Fallback(bytes4 _selector, bytes calldata _data, bytes calldata _reason)
        external
        onlySentryManager
        returns (bool)
    {
        lastSelector = _selector;
        lastData = _data;
        lastReason = _reason;

        emit LogFallback(_selector, _data, _reason);

        return (true);
    }

    function _getTokenAddr(uint256 _ID) internal view returns (address, string memory) {
        (bool ok, address tokenAddr) = ICTMRWAMap(ctmRwa1Map).getTokenContract(_ID, rwaType, version);
        require(ok, "CTMRWA1StorageFallback: The requested tokenID does not exist");
        string memory tokenAddrStr = _toLower(tokenAddr.toHexString());

        return (tokenAddr, tokenAddrStr);
    }

    function stringToAddress(string memory str) internal pure returns (address) {
        bytes memory strBytes = bytes(str);
        require(strBytes.length == 42, "CTMRWA1StorageFallback: Invalid address length");
        bytes memory addrBytes = new bytes(20);

        for (uint256 i = 0; i < 20; i++) {
            addrBytes[i] = bytes1(hexCharToByte(strBytes[2 + i * 2]) * 16 + hexCharToByte(strBytes[3 + i * 2]));
        }

        return address(uint160(bytes20(addrBytes)));
    }

    function hexCharToByte(bytes1 char) internal pure returns (uint8) {
        uint8 byteValue = uint8(char);
        if (byteValue >= uint8(bytes1("0")) && byteValue <= uint8(bytes1("9"))) {
            return byteValue - uint8(bytes1("0"));
        } else if (byteValue >= uint8(bytes1("a")) && byteValue <= uint8(bytes1("f"))) {
            return 10 + byteValue - uint8(bytes1("a"));
        } else if (byteValue >= uint8(bytes1("A")) && byteValue <= uint8(bytes1("F"))) {
            return 10 + byteValue - uint8(bytes1("A"));
        }
        revert("Invalid hex character");
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
}
