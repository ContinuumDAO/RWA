// SPDX-License-Identifier: BSL-1.1

pragma solidity ^0.8.22;

import { URICategory, URIType } from "./ICTMRWA1Storage.sol";

import {ICTMRWA} from "../core/ICTMRWA.sol";

interface ICTMRWA1StorageManager is ICTMRWA {
    function ctmRwaDeployer() external returns (address);
    function ctmRwa1Map() external returns (address);
    function utilsAddr() external returns (address);

    function setGateway(address gateway) external;
    function setFeeManager(address feeManager) external;
    function setCtmRwaDeployer(address deployer) external;
    function setCtmRwaMap(address map) external;
    function setStorageUtils(address utilsAddr) external;
    function getLastReason() external view returns (string memory);

    function addURI(
        uint256 ID,
        string memory objectName,
        URICategory uriCategory,
        URIType uriType,
        string memory title,
        uint256 slot,
        bytes32 uriDataHash,
        string[] memory chainIdsStr,
        string memory feeTokenStr
    ) external;

    function transferURI(uint256 ID, string[] memory chainIdsStr, string memory feeTokenStr) external;

    function addURIX(
        uint256 _ID,
        uint256 _startNonce,
        string[] memory _objectName,
        uint8[] memory _uriCategory,
        uint8[] memory _uriType,
        string[] memory _title,
        uint256[] memory _slot,
        uint256[] memory _timestamp,
        bytes32[] memory _uriDataHash
    ) external returns (bool); // onlyCaller
}
