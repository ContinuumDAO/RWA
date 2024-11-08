// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.23;

// import "forge-std/console.sol";


import {Context} from "@openzeppelin/contracts/utils/Context.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";


import {ICTMRWA001, ITokenContract} from "./interfaces/ICTMRWA001.sol";
import {ICTMRWAMap} from "./interfaces/ICTMRWAMap.sol";
import {URIData, URIType, URICategory} from "./interfaces/ICTMRWA001Storage.sol";


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

    string idStr;
    uint256 public nonce;

    string constant TYPE = "ctm-rwa001.";

    URIData[] uriData;


    modifier onlyTokenAdmin() {
        require(
            _msgSender() == tokenAdmin || _msgSender() == ctmRwa001X, 
            "CTMRWA001Storage: onlyTokenAdmin function"
        );
        _;
    }

    modifier onlyStorageManager() {
        require(
            _msgSender() == storageManagerAddr,
            "CTMRWA001Storage: onlyStorageManager function"
        );
        _;
    }

   
    constructor(
        uint256 _ID,
        address _tokenAddr,
        uint256 _rwaType,
        uint256 _version,
        address _map
    ) {
        ID = _ID;
        idStr = _toLower(((ID<<192)>>192).toHexString());  // shortens string to 16 characters
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

    function contractURI() public view returns (string memory) {
        return
            stringsEqual(baseURI, "GFLD") || stringsEqual(baseURI, "IPFS")
                ? string.concat(TYPE, idStr, ".c.", nonce.toString())
                : "";
    }

    function slotURI(uint256 slot_) public view returns (string memory) {
        return 
            stringsEqual(baseURI, "GFLD") || stringsEqual(baseURI, "IPFS") 
                ? string.concat(TYPE, idStr, ".s.", slot_.toString(), ".", nonce.toString())
                : "";
    }

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId_) public view returns (string memory) {
        ICTMRWA001(tokenAddr).requireMinted(tokenId_);
        return 
            stringsEqual(baseURI, "GFLD") || stringsEqual(baseURI, "IPFS")
                ? string.concat(TYPE, idStr, ".t.", tokenId_.toString(), ".", nonce.toString())
                : "";
    }

    function addURILocal(
        uint256 _ID,
        URICategory _uriCategory,
        URIType _uriType,
        uint256 _slot,
        bytes memory _objectName,
        bytes32 _uriDataHash
    ) external onlyStorageManager {
        require(_ID == ID, "CTMRWA001Storage: Attempt to add URI to an incorrect ID");
        require(!existURIHash(_uriDataHash), "CTMRWA001Storage: Hash already exists");

        uriData.push(URIData(_uriCategory, _uriType, _slot, _objectName, _uriDataHash));
        nonce++;
    }

    function getURIHashByIndex(URICategory uriCat, URIType uriTyp, uint256 index) public view returns(bytes32, bytes memory) {
        uint256 currentIndx;

        for(uint256 i=0; i<uriData.length; i++) {
            if(uriData[i].uriType == uriTyp && uriData[i].uriCategory == uriCat) {
                if(index == currentIndx) {
                    return(uriData[i].uriHash, uriData[i].objectName);
                } else currentIndx++;
            }
        }

        return(bytes32(0), "");
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

    function getURIHash(bytes32 _hash) public view returns(URIData memory) {
        for(uint256 i=0; i<uriData.length; i++) {
            if(uriData[i].uriHash == _hash) {
                return(uriData[i]);
            }
        }
        return(URIData(URICategory.EMPTY,URIType.EMPTY,0,bytes(""),0));
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

    function strToUint(
        string memory _str
    ) internal pure returns (uint256 res, bool err) {
        if (bytes(_str).length == 0) {
            return (0, true);
        }
        for (uint256 i = 0; i < bytes(_str).length; i++) {
            if (
                (uint8(bytes(_str)[i]) - 48) < 0 ||
                (uint8(bytes(_str)[i]) - 48) > 9
            ) {
                return (0, false);
            }
            res +=
                (uint8(bytes(_str)[i]) - 48) *
                10 ** (bytes(_str).length - i - 1);
        }

        return (res, true);
    }

    function stringToAddress(string memory str) internal pure returns (address) {
        bytes memory strBytes = bytes(str);
        require(strBytes.length == 42, "CTMRWA001X: Invalid address length");
        bytes memory addrBytes = new bytes(20);

        for (uint i = 0; i < 20; i++) {
            addrBytes[i] = bytes1(
                hexCharToByte(strBytes[2 + i * 2]) *
                    16 +
                    hexCharToByte(strBytes[3 + i * 2])
            );
        }

        return address(uint160(bytes20(addrBytes)));
    }

    function hexCharToByte(bytes1 char) internal pure returns (uint8) {
        uint8 byteValue = uint8(char);
        if (
            byteValue >= uint8(bytes1("0")) && byteValue <= uint8(bytes1("9"))
        ) {
            return byteValue - uint8(bytes1("0"));
        } else if (
            byteValue >= uint8(bytes1("a")) && byteValue <= uint8(bytes1("f"))
        ) {
            return 10 + byteValue - uint8(bytes1("a"));
        } else if (
            byteValue >= uint8(bytes1("A")) && byteValue <= uint8(bytes1("F"))
        ) {
            return 10 + byteValue - uint8(bytes1("A"));
        }
        revert("Invalid hex character");
    }

    function stringsEqual(
        string memory a,
        string memory b
    ) internal pure returns (bool) {
        bytes32 ka = keccak256(abi.encode(a));
        bytes32 kb = keccak256(abi.encode(b));
        return (ka == kb);
    }

    function _toLower(string memory str) internal pure returns (string memory) {
        bytes memory bStr = bytes(str);
        bytes memory bLower = new bytes(bStr.length);
        for (uint i = 0; i < bStr.length; i++) {
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
    
    function _stringToArray(string memory _string) internal pure returns(string[] memory) {
        string[] memory strArray = new string[](1);
        strArray[0] = _string;
        return(strArray);
    }
    
}