// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/Context.sol";
import "./CTMRWA001SlotApprovable.sol";

contract CTMRWA001Token is Context, CTMRWA001SlotApprovable {

    constructor(
        string memory name_, 
        string memory symbol_, 
        uint8 decimals_,
        address _ctmRwa001XChain
    ) CTMRWA001SlotApprovable (
        name_,
        symbol_,
        decimals_,
        _ctmRwa001XChain
    ) {}

}
