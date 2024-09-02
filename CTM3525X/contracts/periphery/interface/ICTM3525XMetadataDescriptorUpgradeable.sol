// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ICTM3525XMetadataDescriptorUpgradeable {

    function constructContractURI() external view returns (string memory);

    function constructSlotURI(uint256 slot) external view returns (string memory);
    
    function constructTokenURI(uint256 tokenId) external view returns (string memory);

}