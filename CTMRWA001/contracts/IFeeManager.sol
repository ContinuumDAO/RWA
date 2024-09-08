// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.20;

interface IFeeManager {
    function getXChainFee(
        uint256 fromChainID,
        uint256 toChainID,
        address feeToken
    ) external returns (uint256);

    function getFeeTokenList() external returns(address[] memory);
    function getFeeTokenIndexMap(address) external view returns (uint256);
}