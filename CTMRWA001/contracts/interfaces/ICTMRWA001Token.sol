// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

interface ICTMRWA001Token {
    function getRWAType() external pure returns(uint256);
    function getVersion() external pure returns(uint256);

     function burn(uint256 tokenId_) external;
}