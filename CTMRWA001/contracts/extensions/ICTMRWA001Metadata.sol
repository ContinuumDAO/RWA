// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "../ICTMRWA001.sol";
import "./IERC721Metadata.sol";

/**
 * @title CTMRWA001 Semi-Fungible Token Standard, optional extension for metadata
 * @dev Interfaces for any contract that wants to support query of the Uniform Resource Identifier
 *  (URI) for the CTMRWA001 contract as well as a specified slot.
 *  Because of the higher reliability of data stored in smart contracts compared to data stored in
 *  centralized systems, it is recommended that metadata, including `contractURI`, `slotURI` and
 *  `tokenURI`, be directly returned in JSON format, instead of being returned with a url pointing
 *  to any resource stored in a centralized system.
 *  See https://docs.continuumdao.org
 * Note: the ERC-165 identifier for this interface is 0xe1600902.
 */
interface ICTMRWA001Metadata is ICTMRWA001, IERC721Metadata {
    /**
     * @notice Returns the Uniform Resource Identifier (URI) for the current CTMRWA001 contract.
     * @dev This function SHOULD return the URI for this contract in JSON format, starting with
     *  header `data:application/json;`.
     *  See https://docs.continuumdao.org for the JSON schema for contract URI.
     * @return The JSON formatted URI of the current CTMRWA001 contract
     */
    function contractURI() external view returns (string memory);

    /**
     * @notice Returns the Uniform Resource Identifier (URI) for the specified slot.
     * @dev This function SHOULD return the URI for `_slot` in JSON format, starting with header
     *  `data:application/json;`.
     *  See https://docs.continuumdao.org for the JSON schema for slot URI.
     * @return The JSON formatted URI of `_slot`
     */
    function slotURI(uint256 _slot) external view returns (string memory);

    function baseURI() external view returns (string memory);
}
