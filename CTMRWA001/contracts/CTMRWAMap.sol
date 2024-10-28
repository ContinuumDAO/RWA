// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

import "forge-std/console.sol";

import {Context} from "@openzeppelin/contracts/utils/Context.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

import "./lib/RWALib.sol";

import{ICTMRWAAttachment} from "./interfaces/ICTMRWAMap.sol";

struct TokenContract {
    string chainIdStr;
    string contractStr;
    string storageAddrStr;
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


    constructor(
        address _gov,
        address _gateway,
        address _rwa001X
    ) {
        gov = _gov;
        gateway = _gateway;
        ctmRwa001X = _rwa001X;
        cIdStr = RWALib.cID().toString();
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

        string memory tokenAddrStr = RWALib._toLower(_tokenAddrStr);

        uint256 id = contractToId[tokenAddrStr];
        return (id != 0, id);
    }

    function getTokenContract(uint256 _ID, uint256 _rwaType, uint256 _version) public view returns(bool, address) {
        require(_rwaType == rwaType && _version == version, "CTMRWAMap: incorrect RWA type or version");

        string memory _contractStr = idToContract[_ID];
        return bytes(_contractStr).length != 0 
            ? (true, RWALib.stringToAddress(_contractStr)) 
            : (false, address(0));
    }

    function getDividendContract(uint256 _ID, uint256 _rwaType, uint256 _version) public view returns(bool, address) {
        require(_rwaType == rwaType && _version == version, "CTMRWAMap: incorrect RWA type or version");

        string memory _dividendStr = idToDividend[_ID];
        return bytes(_dividendStr).length != 0 
            ? (true, RWALib.stringToAddress(_dividendStr)) 
            : (false, address(0));
    }

    function getStorageContract(uint256 _ID, uint256 _rwaType, uint256 _version) public view returns(bool, address) {
        require(_rwaType == rwaType && _version == version, "CTMRWAMap: incorrect RWA type or version");

        string memory _storageStr = idToStorage[_ID];
        return bytes(_storageStr).length != 0 
            ? (true, RWALib.stringToAddress(_storageStr)) 
            : (false, address(0));
    }


    function attachContracts(
        uint256 _ID, 
        uint256 _rwaType, 
        uint256 _version,
        address _tokenAddr, 
        address _dividendAddr, 
        address _storageAddr
    ) external onlyDeployer {
        require(_rwaType == rwaType && _version == version, "CTMRWAMap: incorrect RWA type or version");

        bool ok = _attachCTMRWAID(
            _ID,
            _tokenAddr,
            _dividendAddr, 
            _storageAddr
        );
        require(ok, "CTMRWAMap: Failed to set token ID");

        ok = ICTMRWAAttachment(_tokenAddr).attachDividend(_dividendAddr);
        require(ok, "CTMRWAMap: Failed to set the dividend contract address");

        ok = ICTMRWAAttachment(_tokenAddr).attachStorage(_storageAddr);
        require(ok, "CTMRWAMap: Failed to set the storage contract address");

    }

    function _attachCTMRWAID(
        uint256 _ID, 
        address _ctmRwaAddr,
        address _dividendAddr, 
        address _storageAddr
    ) internal returns(bool) {

        string memory ctmRwaAddrStr = RWALib._toLower(_ctmRwaAddr.toHexString());
        string memory dividendAddr = RWALib._toLower(_dividendAddr.toHexString());
        string memory storageAddr = RWALib._toLower(_storageAddr.toHexString());

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

            return(true);
        }
    }


   

}