// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.19;

import {URICategory, URIType} from "./ICTMRWA001Storage.sol";

interface ICTMRWA001StorageManager {

    function ctmRwaDeployer() external returns(address);
    function ctmRwa001Map() external returns(address);
    function utilsAddr() external returns(address);

    function setGateway(address gateway) external;
    function setFeeManager(address feeManager) external;
    function setCtmRwaDeployer(address deployer) external;
    function setCtmRwaMap(address map) external;
    function setStorageUtils(address utilsAddr) external;
    function getLastReason() external view returns(string memory);

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

    function transferURI(
        uint256 ID,
        string[] memory chainIdsStr,
        string memory feeTokenStr
    ) external;

    function addURIX(
        uint256 ID,
        URICategory uriCategory,
        URIType uriType,
        uint256 slot,
        string memory objectName,
        bytes32 uriDataHash
    ) external returns(bool);  // onlyCaller

}