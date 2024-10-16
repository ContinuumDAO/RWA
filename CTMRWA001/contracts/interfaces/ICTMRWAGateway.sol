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
    function addChainContract(uint256 chainId, address contractAddress) external returns (bool);
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
    function attachRWAX (
        uint256 rwaType,
        uint256 version,
        string memory _chainIdStr, 
        string memory _rwaXAddrStr
    ) external returns(bool);   // onlyGov
}