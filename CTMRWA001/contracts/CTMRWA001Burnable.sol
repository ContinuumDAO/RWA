// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "@openzeppelin/contracts/utils/Context.sol";
import "./CTMRWA001Mintable.sol";

contract CTMRWA001Burnable is Context, CTMRWA001Mintable {


    constructor(
        address _admin,
        address _deployer,
        string memory name_, 
        string memory symbol_, 
        uint8 decimals_,
        string memory baseURI_,
        address _ctmRwa001XChain
    ) CTMRWA001Mintable(
        _admin,
        _deployer,
        name_,
        symbol_,
        decimals_,
        baseURI_,
       _ctmRwa001XChain
    ) {}

    function burn(uint256 tokenId_) public virtual override {
        require(isApprovedOrOwner(_msgSender(), tokenId_), "CTMRWA001: caller is not token owner nor approved");
        CTMRWA001._burn(tokenId_);
    }

    function burnValue(uint256 tokenId_, uint256 burnValue_) public virtual {
        require(isApprovedOrOwner(_msgSender(), tokenId_), "CTMRWA001: caller is not token owner nor approved");
        CTMRWA001._burnValue(tokenId_, burnValue_);
    }
}
