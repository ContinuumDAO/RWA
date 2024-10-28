// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;


import "forge-std/console.sol";


import {Context} from "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./lib/RWALib.sol";

import {GovernDapp} from "./routerV2/GovernDapp.sol";

import {ICTMRWA001} from "./interfaces/ICTMRWA001.sol";
import {ICTMRWAFactory} from "./interfaces/ICTMRWAFactory.sol";
import {ICTMRWAMap} from "./interfaces/ICTMRWAMap.sol";

interface TokenType {
    function getRWAType() external returns(uint256);
    function getVersion() external returns(uint256);
}


contract CTMRWADeployer is Context, GovernDapp {
    using Strings for *;

    address gateway;
    address feeManager;
    address public rwaX;
    address public ctmRwaMap;

    mapping(uint256 => address[1_000_000_000]) public tokenFactory;
    mapping(uint256 => address[1_000_000_000]) public dividendFactory;
    mapping(uint256 => address[1_000_000_000]) public storageFactory;


    event LogFallback(bytes4 selector, bytes data, bytes reason);

    modifier onlyRwaX {
        require(_msgSender() == rwaX, "CTMRWADeployer: OnlyRwaX function");
        _;
    }

    constructor(
        address _gov,
        address _gateway,
        address _feeManager,
        address _rwaX,
        address _map,
        address _c3callerProxy,
        address _txSender,
        uint256 _dappID
    ) GovernDapp(_gov, _c3callerProxy, _txSender, _dappID) {
        gateway = _gateway;
        feeManager = _feeManager;
        rwaX = _rwaX;
        ctmRwaMap = _map;
    }

    function setGateway(address _gateway) external onlyGov {
        gateway = _gateway;
    }

    function setFeeManager(address _feeManager) external onlyGov {
        feeManager = _feeManager;
    }

    function setRwaX(address _rwaX) external onlyGov {
        rwaX = _rwaX;
    }

    function setMap(address _map) external onlyGov {
        ctmRwaMap = _map;
    }

    function deploy(
        uint256 _ID,
        uint256 _rwaType,
        uint256 _version,
        bytes memory deployData
    ) external onlyRwaX returns(address, address, address) {
        address tokenAddr = ICTMRWAFactory(tokenFactory[_rwaType][_version]).deploy(deployData);

        require(TokenType(tokenAddr).getRWAType() == _rwaType, "CTMRWADeployer: Wrong RWA type");
        require(TokenType(tokenAddr).getVersion() == _version, "CTMRWADeployer: Wrong RWA version");
        
        address dividendAddr = deployDividend(_ID, tokenAddr, _rwaType, _version);
        address storageAddr = deployStorage(_ID, tokenAddr, _rwaType, _version);

        ICTMRWAMap(ctmRwaMap).attachContracts(_ID, _rwaType, _version, tokenAddr, dividendAddr, storageAddr);

        return(tokenAddr, dividendAddr, storageAddr);
    }

    function deployDividend(
        uint256 _ID,
        address _tokenAddr,
        uint256 _rwaType,
        uint256 _version
    ) internal returns(address) {
        if(dividendFactory[_rwaType][_version] != address(0)) {
            address dividendAddr = ICTMRWAFactory(dividendFactory[_rwaType][_version]).deployDividend(
                _ID, 
                _tokenAddr, 
                _rwaType, 
                _version, 
                ctmRwaMap
            );
            return(dividendAddr);
        }
        else return(address(0));
    }

    function deployStorage(
        uint256 _ID,
        address _tokenAddr,
        uint256 _rwaType,
        uint256 _version
    ) internal returns(address) {
        if(storageFactory[_rwaType][_version] != address(0)){
            address storageAddr = ICTMRWAFactory(storageFactory[_rwaType][_version]).deployStorage(
                _ID,
                _tokenAddr,
                _rwaType, 
                _version, 
                ctmRwaMap,
                gateway,
                feeManager
            );
            return(storageAddr);
        }
        else return(address(0));
    }

    function setTokenFactory(uint256 _rwaType, uint256 _version, address _tokenFactory) external onlyGov {
        tokenFactory[_rwaType][_version] = _tokenFactory;
    }

    function setDividendFactory(uint256 _rwaType, uint256 _version, address _dividendFactory) external onlyGov {
        dividendFactory[_rwaType][_version] = _dividendFactory;
    }

    function setStorageFactory(uint256 _rwaType, uint256 _version, address _storageFactory) external onlyGov {
        storageFactory[_rwaType][_version] = _storageFactory;
    }

    

    function _c3Fallback(bytes4 _selector,
        bytes calldata _data,
        bytes calldata _reason) internal override returns (bool) {


        emit LogFallback(_selector, _data, _reason);
        return true;
    }

    

}