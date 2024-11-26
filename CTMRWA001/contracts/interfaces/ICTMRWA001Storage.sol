// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.23;

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
    uint256 slot;
    string objectName;
    bytes32 uriHash;
    uint256 timeStamp;
}

interface ICTMRWA001Storage {
    function ID() external returns(uint256);
    function nonce() external returns(uint256);

    function setTokenAdmin(address _tokenAdmin) external returns(bool);

    function greenfieldBucket() external view returns (string memory);
    function greenfieldObject(URIType _uriType,  uint256 _slot) external view returns (string memory);

    function addURILocal(
        uint256 ID,
        URICategory uriCategory,
        URIType uriType,
        uint256 slot,
        string memory objectName,
        bytes32 uriDataHash
    ) external;

    function getURIHashByIndex(URICategory uriCat, URIType uriTyp, uint256 index) external view returns(bytes32);
    function getURIHashCount(URICategory uriCat, URIType uriTyp) external view returns(uint256);
    function getURIHash(bytes32 _hash) external view returns(URIData memory);
    function existURIHash(bytes32 uriHash) external view returns(bool);
}