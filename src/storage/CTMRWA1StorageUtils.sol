// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.22;

import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

import { ICTMRWA1 } from "../core/ICTMRWA1.sol";

import { ICTMRWAMap } from "../shared/ICTMRWAMap.sol";
import { CTMRWA1Storage } from "./CTMRWA1Storage.sol";
import { ICTMRWA1Storage, URICategory, URIData, URIType } from "./ICTMRWA1Storage.sol";

/**
 * @title AssetX Multi-chain Semi-Fungible-Token for Real-World-Assets (RWAs)
 * @author @Selqui ContinuumDAO
 *
 * @notice This contract has two tasks. The first is to deploy a new CTMRWA1Storage contract on
 * one chain. It uses the CREATE2 instruction to deploy the contract, returning its address.
 * The second function is to manage all cross-chain failures in synchronizing the on-chain records
 * for Storage.
 *
 * This contract is only deployed ONCE on each chain and manages all CTMRWA1Storage contract
 * deployments and c3Fallbacks.
 */
contract CTMRWA1StorageUtils {
    using Strings for *;

    uint256 rwaType;
    uint256 version;
    address public ctmRwa1Map;
    address public storageManager;
    bytes4 public lastSelector;
    bytes public lastData;
    bytes public lastReason;

    modifier onlyStorageManager() {
        require(msg.sender == storageManager, "CTMRWA1StorageUtils: onlyStorageManager function");
        _;
    }

    event LogFallback(bytes4 selector, bytes data, bytes reason);

    bytes4 public AddURIX =
        bytes4(keccak256("addURIX(uint256,uint256,string[],uint8[],uint8[],string[],uint256[],uint256[],bytes32[])"));

    constructor(uint256 _rwaType, uint256 _version, address _map, address _storageManager) {
        rwaType = _rwaType;
        version = _version;
        ctmRwa1Map = _map;
        storageManager = _storageManager;
    }

    /**
     * @dev Deploy a new CTMRWA1Storage using 'salt' ID to ensure a unique contract address
     */
    function deployStorage(uint256 _ID, address _tokenAddr, uint256 _rwaType, uint256 _version, address _map)
        external
        onlyStorageManager
        returns (address)
    {
        CTMRWA1Storage ctmRwa1Storage =
            new CTMRWA1Storage{ salt: bytes32(_ID) }(_ID, _tokenAddr, _rwaType, _version, msg.sender, _map);

        return (address(ctmRwa1Storage));
    }

    /// @dev Get the latest revert string from a failed c3call cross-chain transaction
    function getLastReason() public view returns (string memory) {
        return (string(lastReason));
    }

    /**
     * @dev This fallback function from a failed c3call manages the reversion of an addURI
     * cross-chain c3call. The storage record is 'popped' and the nonce is rewound.
     * NOTE The storage object created on decentralized storage (e.g. BNB Greenfield) must
     * before another addURI call can be made
     */
    function smC3Fallback(bytes4 _selector, bytes calldata _data, bytes calldata _reason)
        external
        onlyStorageManager
        returns (bool)
    {
        lastSelector = _selector;
        lastData = _data;
        lastReason = _reason;

        if (_selector == AddURIX) {
            uint256 ID;
            uint256 startNonce;
            string[] memory objectName;

            (ID, startNonce, objectName,,,,,,) = abi.decode(
                _data, (uint256, uint256, string[], uint8[], uint8[], string[], uint256[], uint256[], bytes32[])
            );

            (bool ok, address storageAddr) = ICTMRWAMap(ctmRwa1Map).getStorageContract(ID, rwaType, version);
            require(ok, "CTMRWA1StorageUtils: Could not find _ID or its storage address");

            ICTMRWA1Storage(storageAddr).popURILocal(objectName.length);
            ICTMRWA1Storage(storageAddr).setNonce(startNonce);
        }

        emit LogFallback(_selector, _data, _reason);

        return (true);
    }

    /// @dev Get the address of the CTMRWA1 contract from the _ID
    function _getTokenAddr(uint256 _ID) internal view returns (address, string memory) {
        (bool ok, address tokenAddr) = ICTMRWAMap(ctmRwa1Map).getTokenContract(_ID, rwaType, version);
        require(ok, "CTMRWA1StorageUtils: The requested tokenID does not exist");
        string memory tokenAddrStr = _toLower(tokenAddr.toHexString());

        return (tokenAddr, tokenAddrStr);
    }

    /// @dev Convert a string to an EVM address. Also checks the string length
    function stringToAddress(string memory str) internal pure returns (address) {
        bytes memory strBytes = bytes(str);
        require(strBytes.length == 42, "CTMRWA1StorageUtils: Invalid address length");
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

    /// @dev Convert a string to lower case
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
