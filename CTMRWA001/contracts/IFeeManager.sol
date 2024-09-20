// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.20;

interface IFeeManager {
    function getXChainFee(
        string memory toChainIDStr,
        string memory feeToken
    ) external returns (uint256);

    function getFeeTokenList() external returns(address[] memory);
    function isValidFeeToken(string memory feeTokenStr) external view returns(bool);
    function getFeeTokenIndexMap(string memory) external view returns (uint256);
}