// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.20;

interface ICTMRWAGateway {
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
        string memory _rwaTypeStr, 
        string memory _chainIdStr
    ) external view returns(bool, string memory);
    function attachRWAX (
        string memory _rwaTypeStr, 
        string memory _chainIdStr, 
        string memory _rwaXAddrStr
    ) external returns(bool);   // onlyGov
}