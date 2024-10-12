// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

import {CTMRWA001} from "./CTMRWA001.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract CTMRWA001Token is CTMRWA001 {
    using SafeERC20 for IERC20;

    constructor(
        address _tokenAdmin,
        address _deployer,
        string memory _name, 
        string memory _symbol, 
        uint8 _decimals,
        string memory _baseURI,
        address _ctmRwa001X
    ) CTMRWA001(
        _tokenAdmin,
        _deployer,
        _name,
        _symbol,
        _decimals,
        _baseURI,
        _ctmRwa001X
    ) {}

    function getRWAType() external pure returns(uint256) {
        return(rwaType);
    }

    function getVersion() external pure returns(uint256) {
        return(version);
    }
    
}
