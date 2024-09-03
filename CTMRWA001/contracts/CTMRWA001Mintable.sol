// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/Context.sol";
import "./CTMRWA001.sol";

contract CTMRWA001Mintable is Context, CTMRWA001 {

    constructor(
        string memory name_, 
        string memory symbol_, 
        uint8 decimals_,
        address _feeManager,
        address _gov,
        address _c3CallerProxy,
        address _txSender,
        uint256 _dappID
    ) CTMRWA001(
        name_,
        symbol_,
        decimals_,
        _feeManager,
        _gov,
        _c3CallerProxy,
        _txSender,
        _dappID
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
}
