// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.23;

enum FeeType {
    ADMIN,
    DEPLOY,
    TX,
    MINT,
    BURN
}

interface IFeeManager {
    function getXChainFee(
        string[] memory _toChainIDsStr,
        bool _includeLocal,
        FeeType _feeType,
        string memory _feeTokenStr
    ) external view returns (uint256);

    function getFeeTokenList() external returns(address[] memory);
    function isValidFeeToken(string memory feeTokenStr) external view returns(bool);
    function getFeeTokenIndexMap(string memory) external view returns (uint256);
    function payFee(uint256 fee, string memory feeTokenStr) external returns (uint256);
}

interface IERC20Extended {
    function decimals() external view returns (uint8);
}