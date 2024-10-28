// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.23;

import {URICategory, URIType} from "./ICTMRWA001Storage.sol";

interface ICTMRWA001StorageManager {

    function setGateway(address gateway) external;
    function setFeeManager(address feeManager) external;
    function setCtmRwaDeployer(address deployer) external;
    function setCtmRwaMap(address map) external;

    function _addURI(
        uint256 ID,
        URICategory uriCategory,
        URIType uriType,
        uint256 slot,
        bytes memory link,  
        bytes32 uriDataHash,
        string[] memory chainIdsStr
    ) external;

    function addURIX(
        uint256 ID,
        URICategory uriCategory,
        URIType uriType,
        uint256 slot,
        bytes memory link,
        bytes32 uriDataHash
    ) external returns(bool);

}