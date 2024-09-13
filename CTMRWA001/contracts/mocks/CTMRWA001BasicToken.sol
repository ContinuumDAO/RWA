// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/Context.sol";
import "../CTMRWA001SlotApprovable.sol";

contract CTMRWA001BasicToken is Context, CTMRWA001SlotApprovable {

    constructor(
        address _admin,
        string memory name_, 
        string memory symbol_, 
        uint8 decimals_,
        address _ctmRwa001XChain
    ) CTMRWA001SlotApprovable (
        _admin,
        name_,
        symbol_,
        decimals_,
        _ctmRwa001XChain
    ) {}

    function mint(
        address mintTo_,
        uint256 tokenId_,
        uint256 slot_,
        uint256 value_
    ) public virtual {
        CTMRWA001._mint(mintTo_, tokenId_, slot_, value_);
    }

    function mintValue(
        uint256 tokenId_,
        uint256 value_
    ) public virtual {
        CTMRWA001._mintValue(tokenId_, value_);
    }

    function burn(uint256 tokenId_) public virtual {
        require(_isApprovedOrOwner(_msgSender(), tokenId_), "CTMRWA001: caller is not token owner nor approved");
        CTMRWA001._burn(tokenId_);
    }

    function burnValue(uint256 tokenId_, uint256 burnValue_) public virtual {
        require(_isApprovedOrOwner(_msgSender(), tokenId_), "CTMRWA001: caller is not token owner nor approved");
        CTMRWA001._burnValue(tokenId_, burnValue_);
    }

    function transferFrom(
        address from_,
        address to_,
        uint256 tokenId_
    ) public payable virtual override(CTMRWA001, IERC721) {
        require(_isApprovedOrOwner(_msgSender(), tokenId_), "CTMRWA001: transfer caller is not owner nor approved");
        _transferTokenId(from_, to_, tokenId_);
    }

    function safeTransferFrom(
        address from_,
        address to_,
        uint256 tokenId_,
        bytes memory data_
    ) public payable virtual override(CTMRWA001, IERC721) {
        require(_isApprovedOrOwner(_msgSender(), tokenId_), "CTMRWA001: transfer caller is not owner nor approved");
        _safeTransferTokenId(from_, to_, tokenId_, data_);
    }

    function safeTransferFrom(
        address from_,
        address to_,
        uint256 tokenId_
    ) public payable virtual override(CTMRWA001, IERC721) {
        safeTransferFrom(from_, to_, tokenId_, "");
    }


}