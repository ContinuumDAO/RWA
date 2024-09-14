// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/Context.sol";
import "./CTMRWA001SlotApprovable.sol";

contract CTMRWA001Token is Context, CTMRWA001SlotApprovable {

    constructor(
        address _admin,
        string memory name_, 
        string memory symbol_, 
        uint8 decimals_,
        string memory baseURI_,
        address _ctmRwa001XChain
    ) CTMRWA001SlotApprovable (
        _admin,
        name_,
        symbol_,
        decimals_,
        baseURI_,
        _ctmRwa001XChain
    ) {}

    

}
