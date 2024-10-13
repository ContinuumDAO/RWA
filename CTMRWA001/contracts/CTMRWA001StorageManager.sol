// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.23;

// import "forge-std/console.sol";

import {Context} from "@openzeppelin/contracts/utils/Context.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

import {GovernDapp} from "./routerV2/GovernDapp.sol";

import {ICTMRWA001Storage, URIType, URICategory} from "./interfaces/ICTMRWA001Storage.sol";
import {ICTMRWAMap} from "./interfaces/ICTMRWAMap.sol";
import {ITokenContract} from "./interfaces/ICTMRWA001.sol";

import {CTMRWA001Storage} from "./CTMRWA001Storage.sol";


interface TokenID {
    function ID() external view returns(uint256);
}

struct URIData {
    URICategory uriCategory;
    URIType uriType;
    uint256 slot;
    bytes32 uriHash;
}

contract CTMRWA001StorageManager is Context, GovernDapp {
    using Strings for *;

    address public ctmRwaDeployer;
    address public ctmRwa001Map;
    uint256 public rwaType;
    uint256 public version;
    
    string[] chainIdsStr;

    modifier onlyDeployer {
        require(msg.sender == ctmRwaDeployer, "CTMRWA001ManagerFactory: onlyDeployer function");
        _;
    }

    event LogFallback(bytes4 selector, bytes data, bytes reason);

    constructor(
        address _gov,
        uint256 _rwaType,
        uint256 _version,
        address _c3callerProxy,
        address _txSender,
        uint256 _dappID,
        address _ctmRwaDeployer
    ) GovernDapp(_gov, _c3callerProxy, _txSender, _dappID) {
        ctmRwaDeployer = _ctmRwaDeployer;
        rwaType = _rwaType;
        version = _version;
    }

    function deployStorage(
        uint256 _ID,
        address _tokenAddr,
        uint256 _rwaType,
        uint256 _version,
        address _map
    ) external onlyDeployer returns(address) {

        CTMRWA001Storage ctmRwa001Storage = new CTMRWA001Storage{
            salt: bytes32(_ID) 
        }(
            _ID,
            _tokenAddr,
            _rwaType,
            _version,
            _map
        );

        return(address(ctmRwa001Storage));
    }

    function setCtmRwaDeployer(address _deployer) external onlyGov {
        ctmRwaDeployer = _deployer;
    }

    function setCtmRwaMap(address _map) external onlyGov {
        ctmRwa001Map = _map;
    }


    function _c3Fallback(bytes4 _selector,
        bytes calldata _data,
        bytes calldata _reason) internal override returns (bool) {


        emit LogFallback(_selector, _data, _reason);
        return true;
    }
}