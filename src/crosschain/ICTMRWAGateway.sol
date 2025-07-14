// SPDX-License-Identifier: BSL-1.1

pragma solidity ^0.8.22;

import { IC3GovernDapp } from "@c3caller/gov/IC3GovernDapp.sol";

struct ChainContract {
    string chainIdStr;
    string contractStr;
}

interface ICTMRWAGateway is IC3GovernDapp {
    function getChainCount() external view returns (uint256);
    function addChainContract(string[] memory chainIdsStr, string[] memory contractsAddressStr)
        external
        returns (bool);
    function getChainContract(uint256 pos) external view returns (string memory, string memory);
    function getChainContract(string memory chainIdStr) external view returns (string memory);
    function getAllRwaXChains(uint256 rwaType, uint256 version) external view returns (string[] memory);
    function existRwaXChain(uint256 rwaType, uint256 version, string memory chainIdStr) external view returns (bool);
    function getAttachedRWAX(uint256 rwaType, uint256 version, string memory _chainIdStr)
        external
        view
        returns (bool, string memory);
    function getAttachedRWAX(uint256 _rwaType, uint256 _version, uint256 _indx)
        external
        view
        returns (string memory, string memory);
    function getRWAXCount(uint256 _rwaType, uint256 _version) external view returns (uint256);
    function attachRWAX(uint256 rwaType, uint256 version, string[] memory _chainIdStr, string[] memory _rwaXAddrStr)
        external
        returns (bool); // onlyGov
    function getAttachedStorageManager(uint256 _rwaType, uint256 _version, uint256 _indx)
        external
        view
        returns (string memory, string memory);
    function getAttachedStorageManager(uint256 _rwaType, uint256 _version, string memory _chainIdStr)
        external
        view
        returns (bool, string memory);
    function getStorageManagerCount(uint256 _rwaType, uint256 _version) external view returns (uint256);
    function attachStorageManager(
        uint256 rwaType,
        uint256 version,
        string[] memory chainIdStr,
        string[] memory storageManagerStr
    ) external returns (bool); // onlyGov

    function getAttachedSentryManager(uint256 _rwaType, uint256 _version, uint256 _indx)
        external
        view
        returns (string memory, string memory);
    function getAttachedSentryManager(uint256 _rwaType, uint256 _version, string memory _chainIdStr)
        external
        view
        returns (bool, string memory);
    function getSentryManagerCount(uint256 _rwaType, uint256 _version) external view returns (uint256);
    function attachSentryManager(
        uint256 rwaType,
        uint256 version,
        string[] memory chainIdStr,
        string[] memory storageManagerStr
    ) external returns (bool); // onlyGov
}
