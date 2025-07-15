// SPDX-License-Identifier: BSL-1.1

pragma solidity 0.8.27;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ITestERC20 is IERC20 {
    function decimals() external view returns (uint8);
    function print(address to, uint256 amount) external;
    function mint(address to, uint256 amount) external;
    function burn(address from) external;
}
