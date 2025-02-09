// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

import "forge-std/console.sol";

import {Context} from "@openzeppelin/contracts/utils/Context.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";


import{ICTMRWAAttachment} from "./interfaces/ICTMRWAMap.sol";

struct TokenContract {
    string chainIdStr;
    string contractStr;
    string storageAddrStr;
    string sentryAddrStr;
}

uint256 constant rwaType = 1;
uint256 constant version = 1;


contract CTMRWAMap is Context {
    using Strings for *;

    address gov;
    address gateway;
    address public ctmRwaDeployer;
    address public ctmRwa001X;

    string cIdStr;


    mapping(uint256 => string) idToContract; // ID => tokenContractAddrStr
    mapping(string => uint256) contractToId; // tokenContractAddrStr => ID

    mapping(uint256 => string) idToDividend;
    mapping(string => uint256) dividendToId;

    mapping(uint256 => string) idToStorage;
    mapping(string => uint256) storageToId;

    mapping(uint256 => string) idToSentry;
    mapping(string => uint256) sentryToId;


    constructor(
        address _gov,
        address _gateway,
        address _rwa001X
    ) {
        gov = _gov;
        gateway = _gateway;
        ctmRwa001X = _rwa001X;
        cIdStr = cID().toString();
    }

    modifier onlyGov {
        require(
            _msgSender() == gov,
            "CTMRWAMap: This is an onlyGov function"
        );
        _;
    }

    modifier onlyDeployer {
        require(
            _msgSender() == ctmRwaDeployer,
            "CTMRWAMap: This is an onlyDeployer function"
        );
        _;
    }

    modifier onlyRwa001X {
        require(
            _msgSender() == ctmRwa001X,
            "CTMRWAMap: This is an onlyRwa001X function"
        );
        _;
    }

    function setCtmRwaDeployer(address _deployer) external onlyGov {
        ctmRwaDeployer = _deployer;
    }

    function setGateway(address _gateway) external onlyGov {
        gateway = _gateway;
    }

    function setRwa001X(address _ctmRwa001X) external onlyGov {
        ctmRwa001X = _ctmRwa001X;
    }

    function getTokenId(string memory _tokenAddrStr, uint256 _rwaType, uint256 _version) public view returns(bool, uint256) {
        require(_rwaType == rwaType && _version == version, "CTMRWAMap: incorrect RWA type or version");

        string memory tokenAddrStr = _toLower(_tokenAddrStr);

        uint256 id = contractToId[tokenAddrStr];
        return (id != 0, id);
    }

    function getTokenContract(uint256 _ID, uint256 _rwaType, uint256 _version) public view returns(bool, address) {
        require(_rwaType == rwaType && _version == version, "CTMRWAMap: incorrect RWA type or version");

        string memory _contractStr = idToContract[_ID];
        return bytes(_contractStr).length != 0 
            ? (true, stringToAddress(_contractStr)) 
            : (false, address(0));
    }

    function getDividendContract(uint256 _ID, uint256 _rwaType, uint256 _version) public view returns(bool, address) {
        require(_rwaType == rwaType && _version == version, "CTMRWAMap: incorrect RWA type or version");

        string memory _dividendStr = idToDividend[_ID];
        return bytes(_dividendStr).length != 0 
            ? (true, stringToAddress(_dividendStr)) 
            : (false, address(0));
    }

    function getStorageContract(uint256 _ID, uint256 _rwaType, uint256 _version) public view returns(bool, address) {
        require(_rwaType == rwaType && _version == version, "CTMRWAMap: incorrect RWA type or version");

        string memory _storageStr = idToStorage[_ID];
        return bytes(_storageStr).length != 0 
            ? (true, stringToAddress(_storageStr)) 
            : (false, address(0));
    }

    function getSentryContract(uint256 _ID, uint256 _rwaType, uint256 _version) public view returns(bool, address) {
        require(_rwaType == rwaType && _version == version, "CTMRWAMap: incorrect RWA type or version");

        string memory _sentryStr = idToSentry[_ID];
        return bytes(_sentryStr).length != 0 
            ? (true, stringToAddress(_sentryStr)) 
            : (false, address(0));
    }


    function attachContracts(
        uint256 _ID, 
        uint256 _rwaType, 
        uint256 _version,
        address _tokenAddr, 
        address _dividendAddr, 
        address _storageAddr,
        address _sentryAddr
    ) external onlyDeployer {
        require(_rwaType == rwaType && _version == version, "CTMRWAMap: incorrect RWA type or version");

        bool ok = _attachCTMRWAID(
            _ID,
            _tokenAddr,
            _dividendAddr, 
            _storageAddr,
            _sentryAddr
        );
        require(ok, "CTMRWAMap: Failed to set token ID");

        ok = ICTMRWAAttachment(_tokenAddr).attachDividend(_dividendAddr);
        require(ok, "CTMRWAMap: Failed to set the dividend contract address");

        ok = ICTMRWAAttachment(_tokenAddr).attachStorage(_storageAddr);
        require(ok, "CTMRWAMap: Failed to set the storage contract address");

        ok = ICTMRWAAttachment(_tokenAddr).attachSentry(_sentryAddr);
        require(ok, "CTMRWAMap: Failed to set the sentry contract address");

    }

    function _attachCTMRWAID(
        uint256 _ID, 
        address _ctmRwaAddr,
        address _dividendAddr, 
        address _storageAddr,
        address _sentryAddr
    ) internal returns(bool) {

        string memory ctmRwaAddrStr = _toLower(_ctmRwaAddr.toHexString());
        string memory dividendAddr = _toLower(_dividendAddr.toHexString());
        string memory storageAddr = _toLower(_storageAddr.toHexString());
        string memory sentryAddr = _toLower(_sentryAddr.toHexString());

        uint256 lenContract = bytes(idToContract[_ID]).length;

        if(lenContract > 0 || contractToId[ctmRwaAddrStr] != 0) {
            return(false);
        } else {
            idToContract[_ID] = ctmRwaAddrStr;
            contractToId[ctmRwaAddrStr] = _ID;

            idToDividend[_ID] = dividendAddr;
            dividendToId[dividendAddr] = _ID;

            idToStorage[_ID] = storageAddr;
            storageToId[storageAddr] = _ID;

            idToSentry[_ID] = sentryAddr;
            sentryToId[sentryAddr] = _ID;

            return(true);
        }
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