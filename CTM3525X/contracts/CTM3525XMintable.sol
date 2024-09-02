// SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

import "@openzeppelin/contracts/utils/Context.sol";
import "./CTM3525X.sol";

contract CTM3525XMintable is Context, CTM3525X {

    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    ) CTM3525X(name_, symbol_, decimals_) {
    }

    function mint(
        address mintTo_,
        uint256 tokenId_,
        uint256 slot_,
        uint256 value_
    ) public virtual {
        CTM3525X._mint(mintTo_, tokenId_, slot_, value_);
    }

    function mintValue(
        uint256 tokenId_,
        uint256 value_
    ) public virtual {
        CTM3525X._mintValue(tokenId_, value_);
    }
}
