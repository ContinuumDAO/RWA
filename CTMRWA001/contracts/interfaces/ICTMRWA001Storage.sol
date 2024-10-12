// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.23;

// import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
// import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
// import {ICTMRWA001Metadata} from "../extensions/ICTMRWA001Metadata.sol";

enum URICategory {
    PROVENANCE,
    VALUATION,
    RATING,
    LICENSE
}

enum URIType {
    CONTRACT,
    SLOT
}


interface ICTMRWA001Storage {
    function ID() external returns(uint256);

    function contractURI() external view returns (string memory);
    function slotURI(uint256 slot_) external view returns (string memory);
    function tokenURI(uint256 tokenId_) external view returns (string memory);

    function addURILocal(
        uint256 ID,
        URICategory uriCategory,
        URIType uriType,
        uint256 slot,   
        bytes32 uriDataHash
    ) external;

    function getURIHashByIndex(URICategory uriCat, URIType uriTyp, uint256 index) external view returns(bytes32);
    function getURIHashCount(URICategory uriCat, URIType uriTyp) external view returns(uint256);
    function existURIHash(bytes32 uriHash) external view returns(bool);
}