// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.20;

struct TokenContract {
    string chainIdStr;
    string contractStr;
}

interface ICTMRWA001X {
    
    function ID() external returns(uint256);
    function getRWAType() external pure returns(uint256);
    function getVersion() external pure returns(uint256);
    function tokenContract() external returns(TokenContract[] memory);
    function totalSupply() external view returns (uint256);
    function balanceOfX(address owner_) external view returns (uint256 balance);
    
    function tokenOfOwnerByIndex(address owner_, uint256 index_) external view returns (uint256);
    function addXTokenInfo(
        address _admin,
        string[] memory _chainIdsStr,
        string[] memory _contractAddrsStr
    ) external returns(bool);
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
    function getTokenContract(string memory _chainIdStr) external view returns(string memory);
    function spendAllowance(address operator_, uint256 tokenId_, uint256 value_) external;
    function getTokenInfo(uint256 tokenId_) external view returns(uint256 id,uint256 bal,address owner,uint256 slot);
    function requireMinted(uint256 tokenId_) external view returns(bool);
    function burnValueX(uint256 fromTokenId_, uint256 value_) external returns(bool);
    function mintValueX(uint256 toTokenId_, uint256 slot_, uint256 value_) external returns(bool);
    function mintFromX(address to_, uint256 slot_, uint256 value_) external returns (uint256 tokenId);
    function mintFromX(address to_, uint256 tokenId_, uint256 slot_, uint256 value_) external;
    function isApprovedOrOwner(address operator_, uint256 tokenId_) external view returns(bool);
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