// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.20;

interface ICTMRWA001X {
    function addXTokenInfo(
        address _admin,
        string[] memory _chainIdsStr,
        string[] memory _contractAddrsStr
    ) external returns(bool);
    function checkTokenCompatibility(
        string memory _otherChainIdStr,
        string memory _otherContractStr
    ) external view returns(bool);
    function getTokenContract(string memory _chainIdStr) external view returns(string memory);
    function spendAllowance(address operator_, uint256 tokenId_, uint256 value_) external;
    function getTokenInfo(uint256 tokenId_) external view returns(uint256 id,uint256 bal,address owner,uint256 slot);
    function burnValueX(uint256 fromTokenId_, uint256 value_) external returns(bool);
    function mintValueX(uint256 toTokenId_, uint256 slot_, uint256 value_) external returns(bool);
    function mintFromX(address to_, uint256 slot_, uint256 value_) external returns (uint256 tokenId);
    function mintFromX(address to_, uint256 tokenId_, uint256 slot_, uint256 value_) external;
    function isApprovedOrOwner(address operator_, uint256 tokenId_) external view returns(bool);
    function approveFromX(address to_, uint256 tokenId_) external;
    function clearApprovedValues(uint256 tokenId_) external;
    function removeTokenFromOwnerEnumeration(address from_, uint256 tokenId_) external;
}