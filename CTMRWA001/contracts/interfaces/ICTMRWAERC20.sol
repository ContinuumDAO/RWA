// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ICTMRWAERC20 is IERC20 {
    function ID() external view returns(uint256);
    function ctmRwaName() external view returns(address);
    function slot() external view returns(uint256);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function totalSupply() external view returns (uint256);
    function balanceOf(address _account) external view returns (uint256);
    function allowance(address _owner, address _spender) external view returns (uint256);
    function approve(address _spender, uint256 _value) external returns (bool);
    function transfer(address _to, uint256 _value) external returns (bool);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool);

    function decimals() external view returns (uint8);
}