// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

import "../interfaces/ICTMRWA001.sol";

/**
 * @title CTMRWA001 Semi-Fungible Token Standard, optional extension for manageable slots
 * @dev Interfaces for any contract that wants to support manageable slots.
 *  See https://docs.continuumdao.org
 * Note: the ERC-165 identifier for this interface is 0xbf0c56fa.
 */
interface ICTMRWA001SlotManageable is ICTMRWA001 {

    /**
     * @notice Get the total amount of slots managed by an address.
     * @param _manager The address for whom to query manageable slots
     * @return The total amount of slots managed by `_manager`
     */
    function slotCountOfManager(address _manager) external view returns (uint256);

    /**
     * @notice Get the slot at the specified index of all slots managed by an address.
     * @param _manager The address for whom to query manageable slots
     * @param _index The slot at `_index` of all slots managed by `_manager`
     */
    function slotOfManagerByIndex(address _manager, uint256 _index) external view returns (uint256);

    /**
     * @notice Get the manager of a slot.
     * @param _slot The slot for which to query the manager
     * return The manager of `_slot`
     */
    function managerOfSlot(uint256 _slot) external view returns (address);
}
