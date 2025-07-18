// SPDX-License-Identifier: BSL-1.1

pragma solidity 0.8.27;

import { ICTMRWA } from "../core/ICTMRWA.sol";
import { Address } from "../CTMRWAUtils.sol";

enum URICategory {
    ISSUER,
    PROVENANCE,
    VALUATION,
    PROSPECTUS,
    RATING,
    LEGAL,
    FINANCIAL,
    LICENSE,
    DUEDILIGENCE,
    NOTICE,
    DIVIDEND,
    REDEMPTION,
    WHOCANINVEST,
    IMAGE,
    VIDEO,
    ICON,
    EMPTY
}

enum URIType {
    CONTRACT,
    SLOT,
    EMPTY
}

struct URIData {
    URICategory uriCategory;
    URIType uriType;
    string title;
    uint256 slot;
    string objectName;
    bytes32 uriHash;
    uint256 timeStamp;
}

interface ICTMRWA1Storage is ICTMRWA {
    error CTMRWA1Storage_Unauthorized(Address);
    error CTMRWA1Storage_InvalidID(uint256 expected, uint256 actual);
    error CTMRWA1Storage_HashExists(bytes32);
    error CTMRWA1Storage_InvalidSlot(uint256);
    error CTMRWA1Storage_IssuerNotFirst();
    error CTMRWA1Storage_OutOfBounds();
    error CTMRWA1Storage_IncreasingNonceOnly();
    error CTMRWA1Storage_InvalidContract(Address);
    error CTMRWA1Storage_ForceTransferNotSetup();
    error CTMRWA1Storage_NoSecurityDescription();
    error CTMRWA1Storage_IssuerNotFirst();

    function ID() external returns (uint256);
    function regulatorWallet() external returns (address);
    function nonce() external returns (uint256);
    function tokenAdmin() external returns (address);
    function ctmRwa1X() external returns (address);
    function ctmRwa1Map() external returns (address);
    function storageManagerAddr() external returns (address);
    function uriData(uint256 index)
        external
        returns (
            URICategory uriCategory,
            URIType uriType,
            string memory title,
            uint256 slot,
            string memory objectName,
            bytes32 uriHash,
            uint256 timeStamp
        );
    function popURILocal(uint256 toPop) external;

    function setTokenAdmin(address _tokenAdmin) external returns (bool);

    function greenfieldBucket() external view returns (string memory);

    function addURILocal(
        uint256 ID,
        string memory objectName,
        URICategory uriCategory,
        URIType uriType,
        string memory title,
        uint256 slot,
        uint256 timestamp,
        bytes32 uriDataHash
    ) external;

    function setNonce(uint256 val) external;
    function increaseNonce(uint256 val) external;

    function createSecurity(address regulatorWallet) external;

    function getAllURIData()
        external
        view
        returns (
            uint8[] memory uriCategory,
            uint8[] memory uriType,
            string[] memory title,
            uint256[] memory slot,
            string[] memory objectName,
            bytes32[] memory uriHash,
            uint256[] memory timeStamp
        );
    function getURIHashByIndex(URICategory uriCat, URIType uriTyp, uint256 index)
        external
        view
        returns (bytes32, string memory);
    function getURIHashCount(URICategory uriCat, URIType uriTyp) external view returns (uint256);
    function getURIHash(bytes32 _hash) external view returns (URIData memory);
    function existURIHash(bytes32 uriHash) external view returns (bool);
    function existObjectName(string memory objectName) external view returns (bool);
    function getURIHashByObjectName(string memory objectName) external view returns (URIData memory);
}
