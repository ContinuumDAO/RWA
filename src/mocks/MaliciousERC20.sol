// SPDX-License-Identifier: BSL-1.1

pragma solidity 0.8.27;

import { ITestERC20 } from "./ITestERC20.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { console } from "forge-std/console.sol";

contract MaliciousERC20 is ITestERC20, ERC20 {
    uint8 _decimals;
    address public admin;
    address public attacker;
    bytes public callbackData;

    constructor(string memory _name, string memory _symbol, uint8 decimals_) ERC20(_name, _symbol) {
        admin = msg.sender;
        _decimals = decimals_;
    }

    function decimals() public view override(ITestERC20, ERC20) returns (uint8) {
        return _decimals;
    }

    // Set the attacker contract and callback data
    function setAttacker(address _attacker, bytes calldata _callbackData) external {
        require(msg.sender == admin, "Only admin");
        attacker = _attacker;
        callbackData = _callbackData;
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

    // Override transferFrom to call back into the attacker
    function transferFrom(address from, address to, uint256 amount) public override(ERC20, IERC20) returns (bool) {
        bool result = super.transferFrom(from, to, amount);
        if (attacker != address(0) && callbackData.length > 0) {
            console.log("MaliciousERC20: About to call attacker");
            (bool success, bytes memory returndata) = attacker.call(callbackData);
            console.log("MaliciousERC20: Attacker call success? %s", success);
            if (!success) {
                if (returndata.length > 0) {
                    // Try to decode revert reason
                    console.logBytes(returndata);
                }
                revert("MaliciousERC20: attacker callback failed");
            }
        }
        return result;
    }
}
