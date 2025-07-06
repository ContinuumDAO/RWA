// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.19;

import { ITestERC20 } from "./ITestERC20.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TestERC20 is ITestERC20, ERC20 {
    uint8 _decimals;
    address public admin;

    constructor(string memory _name, string memory _symbol, uint8 decimals_) ERC20(_name, _symbol) {
        admin = msg.sender;
        _decimals = decimals_;
    }

    function decimals() public view override(ITestERC20, ERC20) returns (uint8) {
        return _decimals;
    }

    // testing only
    function print(address to, uint256 amount) external {
        _mint(to, amount);
    }

    function mint(address to, uint256 amount) external {
        require(msg.sender == admin);
        _mint(to, amount);
    }

    function burn(address from) external {
        require(msg.sender == admin);
        _burn(from, balanceOf(from));
    }
}
