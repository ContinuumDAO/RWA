// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.23;

// import "forge-std/console.sol";


import {Context} from "@openzeppelin/contracts/utils/Context.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

import {ICTMRWA001, ITokenContract} from "./interfaces/ICTMRWA001.sol";
import {ICTMRWAMap} from "./interfaces/ICTMRWAMap.sol";
import {URIType, URICategory} from "./interfaces/ICTMRWA001Storage.sol";


contract CTMRWA001Storage is Context {
    using Strings for *;

    address public tokenAddr;
    uint256 public ID;
    uint256 rwaType;
    uint256 version;
    address storageManagerAddr;
    address public tokenAdmin;
    address public ctmRwa001X;
    address public ctmRwa001Map;
    string baseURI;

    string constant TYPE = "/ContinuumDAO/RWA001/";

    
    struct URIData {
        URICategory uriCategory;
        URIType uriType;
        uint256 slot;
        bytes32 uriHash;
    }

    URIData[] uriData;


    modifier onlyTokenAdmin() {
        require(
            _msgSender() == tokenAdmin || _msgSender() == ctmRwa001X, 
            "CTMRWA001Storage: onlyTokenAdmin function");
        _;
    }

   
    constructor(
        uint256 _ID,
        address _tokenAddr,
        uint256 _rwaType,
        uint256 _version,
        address _map
    ) {
        rwaType = _rwaType;
        version = _version;
        ctmRwa001Map = _map;

        tokenAddr = _tokenAddr;

        tokenAdmin = ICTMRWA001(tokenAddr).tokenAdmin();
        ctmRwa001X = ICTMRWA001(tokenAddr).ctmRwa001X();
        
        storageManagerAddr = _msgSender();

        baseURI = ICTMRWA001(tokenAddr).baseURI();
    }

    function setTokenAdmin(address _tokenAdmin) external onlyTokenAdmin returns(bool) {
        tokenAdmin = _tokenAdmin;
        return(true);
    }

    function contractURI() public view virtual returns (string memory) {
        return 
            bytes(baseURI).length > 0 ? 
                string(abi.encodePacked(baseURI, TYPE, ID.toString(), "/contract/")) : 
                "";
    }

    function slotURI(uint256 slot_) public view virtual returns (string memory) {
        return 
            bytes(baseURI).length > 0 ? 
                string(abi.encodePacked(baseURI, TYPE, ID.toString(), "/slot/", slot_.toString())) : 
                "";
    }

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId_) public view virtual returns (string memory) {
        ICTMRWA001(tokenAddr).requireMinted(tokenId_);
        return 
            bytes(baseURI).length > 0 ? 
                string(abi.encodePacked(baseURI, TYPE, ID.toString(), "/", tokenId_.toString())) : 
                "";
    }

    
    function addURILocal(
        uint256 _ID,
        URICategory _uriCategory,
        URIType _uriType,
        uint256 _slot,   
        bytes32 _uriDataHash
    ) external onlyTokenAdmin {
        require(_ID == ID, "CTMRWA001Storage: Attempt to add URI to an incorrect ID");
        require(!existURIHash(_uriDataHash), "CTMRWA001Storage: Hash already exists");

        uriData.push(URIData(_uriCategory, _uriType, _slot, _uriDataHash));
    }

    function getURIHashByIndex(URICategory uriCat, URIType uriTyp, uint256 index) public view returns(bytes32) {

        uint256 currentIndx;

        for(uint256 i=0; i<uriData.length; i++) {
            if(uriData[i].uriType == uriTyp && uriData[i].uriCategory == uriCat) {
                if(index == currentIndx) {
                    return(uriData[i].uriHash);
                } else currentIndx++;
            }
        }

        return(bytes32(0));
    }

    function getURIHashCount(URICategory uriCat, URIType uriTyp) public view returns(uint256) {
        uint256 count;
        for(uint256 i=0; i<uriData.length; i++) {
            if(uriData[i].uriType == uriTyp && uriData[i].uriCategory == uriCat) {
                count++;
            }
        }
        return(count);
    }

    function existURIHash(bytes32 uriHash) public view returns(bool) {
        for(uint256 i=0; i<uriData.length; i++) {
            if(uriData[i].uriHash == uriHash) return(true);
        }
        return(false);
    }


    function cID() internal view returns (uint256) {
        return block.chainid;
    }

    
}