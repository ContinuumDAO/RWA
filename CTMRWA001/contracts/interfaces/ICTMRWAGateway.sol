// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.23;

interface ICTMRWAGateway {
    function getChainCount() external view returns(uint256);
    function addXChainInfo(
        string memory tochainIdStr,
        string memory toContractStr,
        string[] memory chainIdsStr,
        string[] memory contractAddrsStr
    ) external;
    function addChainContract(string memory chainIdStr, string memory contractAddressStr) external returns (bool);
    function getChainContract(string memory chainIdStr) external view returns(string memory);
    function addXChainInfoX(
        string[] memory chainIdsStr,
        string[] memory contractAddrsStr,
        string memory fromContractStr
    ) external returns(bool);  // onlyCaller
    function getAttachedRWAX(
        uint256 rwaType,
        uint256 version,
        string memory _chainIdStr
    ) external view returns(bool, string memory);
    function getAttachedRWAX(
        uint256 _rwaType,
        uint256 _version,
        uint256 _indx
    ) external view returns(string memory, string memory);
    function getRWAXCount(
        uint256 _rwaType,
        uint256 _version
    ) external view returns(uint256);
    function attachRWAX (
        uint256 rwaType,
        uint256 version,
        string memory _chainIdStr, 
        string memory _rwaXAddrStr
    ) external returns(bool);   // onlyGov
    function getAttachedStorageManager(
        uint256 _rwaType,
        uint256 _version,
        uint256 _indx
    ) external view returns(string memory, string memory);
    function getAttachedStorageManager(
        uint256 _rwaType,
        uint256 _version,
        string memory _chainIdStr
    ) external view returns(bool, string memory);
    function getStorageManagerCount(
        uint256 _rwaType,
        uint256 _version
    ) external view returns(uint256);
}