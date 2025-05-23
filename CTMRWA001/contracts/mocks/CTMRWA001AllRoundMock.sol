// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.19;

import "@openzeppelin/contracts/utils/Context.sol";
import {CTMRWA001} from "../CTMRWA001.sol";

contract CTMRWA001AllRoundMock is Context, CTMRWA001 {

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

    function burn(uint256 tokenId_) public virtual override {
        require(isApprovedOrOwner(_msgSender(), tokenId_), "CTMRWA001: caller is not token owner nor approved");
        CTMRWA001._burn(tokenId_);
    }

    function burnValue(uint256 tokenId_, uint256 burnValue_) public virtual {
        require(isApprovedOrOwner(_msgSender(), tokenId_), "CTMRWA001: caller is not token owner nor approved");
        CTMRWA001._burnValue(tokenId_, burnValue_);
    }
}