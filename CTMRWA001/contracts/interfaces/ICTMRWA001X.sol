// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.20;

struct TokenContract {
    string chainIdStr;
    string contractStr;
}

interface ICTMRWA001X {
    
    function tokenContract() external returns(TokenContract[] memory);
    function totalSupply() external view returns (uint256);
    
    function addXChainInfo(
        string memory _tochainIdStr,
        string memory _toContractStr,
        string[] memory _chainIdsStr,
        string[] memory _contractAddrsStr
    ) external payable;
    function addChainContract(uint256 chainId, address contractAddress) external returns (bool);
    function deploy(
        uint256 rwaType,
        uint256 version,
        bytes memory deployData
    ) external returns(address, address);
    function checkTokenCompatibility(
        string memory _otherChainIdStr,
        string memory _otherContractStr
    ) external view returns(bool);
    
    function approveFromX(address to_, uint256 tokenId_) external;
    function clearApprovedValues(uint256 tokenId_) external;
    function removeTokenFromOwnerEnumeration(address from_, uint256 tokenId_) external;

    // transferFromX
    function transferFromX( // transfer from/to same tokenid with value
        uint256 fromTokenId_,
        string memory toAddressStr_,
        string memory toChainIdStr_,
        uint256 value_,
        string memory _ctmRwa001AddrStr,
        string memory feeTokenStr
    ) external payable;
    function transferFromX( // transfer from/to same tokenid without value
        string memory toAddressStr_,
        string memory toChainIdStr_,
        uint256 fromTokenId_,
        string memory _ctmRwa001AddrStr,
        string memory feeTokenStr
    ) external;
    function transferFromX( // transfer from tokenid to different tokenid with value
        uint256 fromTokenId_,
        string memory toAddressStr_,
        uint256 toTokenId_,
        string memory toChainIdStr_,
        uint256 value_,
        string memory _ctmRwa001AddrStr,
        string memory feeTokenStr
    ) external;
}