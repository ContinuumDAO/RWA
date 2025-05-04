// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

interface ICTMRWAERC20Deployer {
    function deployERC20(
        uint256 ID,
        uint256 slot,
        string memory name, 
        string memory symbol, 
        address feeToken
    ) external returns(address);
}