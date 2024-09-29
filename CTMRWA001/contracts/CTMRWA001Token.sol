// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

// import {Context} from "@openzeppelin/contracts/utils/Context.sol";
// import "./CTMRWA001SlotApprovable.sol";
import {CTMRWA001} from "./CTMRWA001.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract CTMRWA001Token is CTMRWA001 {
    using SafeERC20 for IERC20;

    uint256 public constant version = 1;
    uint256 public constant rwaType = 1;


    constructor(
        address _tokenAdmin,
        string memory name_, 
        string memory symbol_, 
        uint8 decimals_,
        string memory baseURI_,
        address _ctmRwa001XChain
    ) CTMRWA001(
        _tokenAdmin,
        name_,
        symbol_,
        decimals_,
        baseURI_,
        _ctmRwa001XChain
    ) {}

    function getRWAType() external pure returns(uint256) {
        return(rwaType);
    }

    function getVersion() external pure returns(uint256) {
        return(version);
    }
    
}
