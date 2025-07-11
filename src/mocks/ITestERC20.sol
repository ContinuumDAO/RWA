// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ITestERC20 is IERC20 {
    function decimals() external view returns (uint8);
    function print(address to, uint256 amount) external;
    function mint(address to, uint256 amount) external;
    function burn(address from) external;
}
