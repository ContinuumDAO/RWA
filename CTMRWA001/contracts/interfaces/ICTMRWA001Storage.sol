// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.23;

enum URICategory {
    PROVENANCE,
    VALUATION,
    RATING,
    LICENSE,
    NOTICE,
    DIVIDEND,
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
    bytes objectName;
    bytes32 uriHash;
}

interface ICTMRWA001Storage {
    function ID() external returns(uint256);
    function nonce() external returns(uint256);

    function setTokenAdmin(address _tokenAdmin) external returns(bool);

    function contractURI() external view returns (string memory);
    function slotURI(uint256 slot_) external view returns (string memory);
    function tokenURI(uint256 tokenId_) external view returns (string memory);

    function addURILocal(
        uint256 ID,
        URICategory uriCategory,
        URIType uriType,
        uint256 slot,
        bytes memory objectName,
        bytes32 uriDataHash
    ) external;

    function getURIHashByIndex(URICategory uriCat, URIType uriTyp, uint256 index) external view returns(bytes32);
    function getURIHashCount(URICategory uriCat, URIType uriTyp) external view returns(uint256);
    function getURIHash(bytes32 _hash) external view returns(URIData memory);
    function existURIHash(bytes32 uriHash) external view returns(bool);
}