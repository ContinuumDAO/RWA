// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

import "@openzeppelin/contracts/utils/Context.sol";
import "./CTMRWA001.sol";

contract CTMRWA001Mintable is Context, CTMRWA001 {

    constructor(
        address _admin,
        address _deployer,
        string memory name_, 
        string memory symbol_, 
        uint8 decimals_,
        string memory baseURI_,
        address _ctmRwa001XChain
    ) CTMRWA001(
        _admin,
        _deployer,
        name_,
        symbol_,
        decimals_,
        baseURI_,
        _ctmRwa001XChain
    ) {}

    function mint(
        address mintTo_,
        uint256 tokenId_,
        uint256 slot_,
        string memory _slotName,
        uint256 value_
    ) public virtual {
        CTMRWA001._mint(mintTo_, tokenId_, slot_, _slotName, value_);
    }

    function mintValue(
        uint256 tokenId_,
        uint256 value_
    ) public virtual {
        CTMRWA001._mintValue(tokenId_, value_);
    }
}
