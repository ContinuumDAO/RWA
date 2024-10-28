// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.23;

import {Context} from "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./lib/RWALib.sol";

import {GovernDapp} from "./routerV2/GovernDapp.sol";



contract CTMRWAGateway is Context, GovernDapp {
    using Strings for *;

    string public cIdStr;

    mapping(uint256 => mapping(uint256 => ChainContract[])) rwaX; // rwaType => version => ChainContract
    mapping(uint256 => mapping(uint256 => ChainContract[])) storageManager;

    event SetChainContract(string[] chainIdsStr, string[] contractAddrsStr, string fromContractStr, string fromChainIdStr);
    event LogFallback(bytes4 selector, bytes data, bytes reason);

    struct ChainContract {
        string chainIdStr;
        string contractStr;
    }
    //  This array holds ChainContract structs for all chains
    ChainContract[] public chainContract;

    constructor(
        address _gov,
        address _c3callerProxy,
        address _txSender,
        uint256 _dappID
    ) GovernDapp(_gov, _c3callerProxy, _txSender, _dappID) {
        cIdStr = RWALib.cID().toString();
        _addChainContract(RWALib.cID(), address(this));
    }

    function _addChainContract(uint256 _chainId, address _contractAddr) internal  {
        string memory newChainIdStr = _chainId.toString();
        string memory contractStr = RWALib._toLower(_contractAddr.toHexString());

        chainContract.push(ChainContract(newChainIdStr, contractStr));
    }

    function addChainContract(string memory _newChainIdStr, string memory _contractAddrStr) external onlyGov returns (bool) {
        string memory newChainIdStr = RWALib._toLower(_newChainIdStr);
        string memory contractAddrStr = RWALib._toLower(_contractAddrStr);

        for(uint256 i=0; i<chainContract.length; i++) {
            if(RWALib.stringsEqual(chainContract[i].chainIdStr, newChainIdStr)) {
                chainContract[i].contractStr = contractAddrStr;
                return(true); // existed = true
            }
        }

        chainContract.push(ChainContract(newChainIdStr, contractAddrStr));
        return(false);
    }

    function getChainContract(string memory _chainIdStr) external view returns(string memory) {
        for(uint256 i=0; i<chainContract.length; i++) {
            if(RWALib.stringsEqual(chainContract[i].chainIdStr, RWALib._toLower(_chainIdStr))) {
                return(chainContract[i].contractStr);
            }
        }
        return("");
    }

    function getChainContract(uint256 _pos) public view returns(string memory, string memory) {
        return(chainContract[_pos].chainIdStr, chainContract[_pos].contractStr);
    }

    function getChainCount() public view returns(uint256) {
        return(chainContract.length);
    }

    function getAttachedRWAX(
        uint256 _rwaType,
        uint256 _version,
        uint256 _indx
    ) public view returns(string memory, string memory) {
        return(
            rwaX[_rwaType][_version][_indx].chainIdStr,
            rwaX[_rwaType][_version][_indx].contractStr
        );
    }

    function getRWAXCount(
        uint256 _rwaType,
        uint256 _version
    ) public view returns(uint256) {
        return(rwaX[_rwaType][_version].length);
    }
        

    function getAttachedRWAX(
        uint256 _rwaType,
        uint256 _version,
        string memory _chainIdStr
    ) public view returns(bool, string memory) {

        for(uint256 i=0; i<rwaX[_rwaType][_version].length; i++) {
            if(RWALib.stringsEqual(rwaX[_rwaType][_version][i].chainIdStr, _chainIdStr)) {
                return(true, rwaX[_rwaType][_version][i].contractStr);
            }
        }

        return(false, "0");
    }

    function getAttachedStorageManager(
        uint256 _rwaType,
        uint256 _version,
        uint256 _indx
    ) public view returns(string memory, string memory) {
        return(
            storageManager[_rwaType][_version][_indx].chainIdStr,
            storageManager[_rwaType][_version][_indx].contractStr
        );
    }

    function getStorageManagerCount(
        uint256 _rwaType,
        uint256 _version
    ) public view returns(uint256) {
        return(storageManager[_rwaType][_version].length);
    }

    function getAttachedStorageManager(
        uint256 _rwaType,
        uint256 _version,
        string memory _chainIdStr
    ) public view returns(bool, string memory) {

        for(uint256 i=0; i<storageManager[_rwaType][_version].length; i++) {
            if(RWALib.stringsEqual(storageManager[_rwaType][_version][i].chainIdStr, _chainIdStr)) {
                return(true, storageManager[_rwaType][_version][i].contractStr);
            }
        }

        return(false, "0");
    }

    // Keeps a record of RWA contracts on this chain on other chains.
    function attachRWAX (
        uint256 _rwaType,
        uint256 _version,
        string memory _chainIdStr, 
        string memory _rwaXAddrStr
    ) external onlyGov returns(bool) {
        require(bytes(_rwaXAddrStr).length == 42, "CTMRWAGateway: Incorrect address length");
        string memory rwaXAddrStr = RWALib._toLower(_rwaXAddrStr);
        string memory chainIdStr = RWALib._toLower(_chainIdStr);


        for(uint256 i=0; i<rwaX[_rwaType][_version].length; i++) {
            if(RWALib.stringsEqual(rwaX[_rwaType][_version][i].chainIdStr, chainIdStr)) {
                rwaX[_rwaType][_version][i].contractStr = rwaXAddrStr;
                return(true); // existed = true
            }
        }

        ChainContract memory newAttach = ChainContract(chainIdStr, rwaXAddrStr);
        rwaX[_rwaType][_version].push(newAttach);
        return(false);
    }

    function attachStorageManager (
        uint256 _rwaType,
        uint256 _version,
        string memory _chainIdStr, 
        string memory _storageManagerAddrStr
    ) external onlyGov returns(bool) {
        require(bytes(_storageManagerAddrStr).length == 42, "CTMRWAGateway: Incorrect address length");
        string memory storageManagerAddrStr = RWALib._toLower(_storageManagerAddrStr);
        string memory chainIdStr = RWALib._toLower(_chainIdStr);


        for(uint256 i=0; i<storageManager[_rwaType][_version].length; i++) {
            if(RWALib.stringsEqual(storageManager[_rwaType][_version][i].chainIdStr, chainIdStr)) {
                storageManager[_rwaType][_version][i].contractStr = storageManagerAddrStr;
                return(true); // existed = true
            }
        }

        ChainContract memory newAttach = ChainContract(chainIdStr, storageManagerAddrStr);
        storageManager[_rwaType][_version].push(newAttach);
        return(false);
    }



    function _c3Fallback(bytes4 _selector,
        bytes calldata _data,
        bytes calldata _reason) internal override returns (bool) {


        emit LogFallback(_selector, _data, _reason);
        return true;
    }

}