// SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

import "@openzeppelin/contracts/utils/Context.sol";
import "./CTM3525XMintable.sol";

contract CTM3525XBurnable is Context, CTM3525XMintable {

    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    ) CTM3525XMintable(name_, symbol_, decimals_) {
    }

    function burn(uint256 tokenId_) public virtual {
        require(_isApprovedOrOwner(_msgSender(), tokenId_), "CTM3525X: caller is not token owner nor approved");
        CTM3525X._burn(tokenId_);
    }

    function burnValue(uint256 tokenId_, uint256 burnValue_) public virtual {
        require(_isApprovedOrOwner(_msgSender(), tokenId_), "CTM3525X: caller is not token owner nor approved");
        CTM3525X._burnValue(tokenId_, burnValue_);
    }
}
