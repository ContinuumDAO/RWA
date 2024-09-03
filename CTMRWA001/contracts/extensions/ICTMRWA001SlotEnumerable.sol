// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "../ICTMRWA001.sol";
import "./IERC721Enumerable.sol";
/**
 * @title CTMRWA001 Semi-Fungible Token Standard, optional extension for slot enumeration
 * @dev Interfaces for any contract that wants to support enumeration of slots as well as tokens 
 *  with the same slot.
 *  See https://docs.continuumdao.org
 * Note: the ERC-165 identifier for this interface is 0x3b741b9e.
 */
interface ICTMRWA001SlotEnumerable is ICTMRWA001, IERC721Enumerable {

    /**
     * @notice Get the total amount of slots stored by the contract.
     * @return The total amount of slots
     */
    function slotCount() external view returns (uint256);

    /**
     * @notice Get the slot at the specified index of all slots stored by the contract.
     * @param _index The index in the slot list
     * @return The slot at `index` of all slots.
     */
    function slotByIndex(uint256 _index) external view returns (uint256);

    /**
     * @notice Get the total amount of tokens with the same slot.
     * @param _slot The slot to query token supply for
     * @return The total amount of tokens with the specified `_slot`
     */
    function tokenSupplyInSlot(uint256 _slot) external view returns (uint256);

    /**
     * @notice Get the token at the specified index of all tokens with the same slot.
     * @param _slot The slot to query tokens with
     * @param _index The index in the token list of the slot
     * @return The token ID at `_index` of all tokens with `_slot`
     */
    function tokenInSlotByIndex(uint256 _slot, uint256 _index) external view returns (uint256);
}
