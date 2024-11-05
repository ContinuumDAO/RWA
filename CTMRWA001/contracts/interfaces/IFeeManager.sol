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

    
    function addFeeToken(
        string memory dstChainIDStr,
        string[] memory feeTokensStr,
        uint256[] memory fee // human readable * 100
    ) external returns (bool);
    function addFeeToken(string memory feeTokenStr) external returns (bool);
    function delFeeToken(string memory feeTokenStr) external returns (bool);

    function setFeeMultiplier(FeeType feeType, uint256 multiplier) external returns (bool);

    function getFeeTokenList() external returns(address[] memory);
    function isValidFeeToken(string memory feeTokenStr) external view returns(bool);
    function getFeeTokenIndexMap(string memory) external view returns (uint256);
    function payFee(uint256 fee, string memory feeTokenStr) external returns (uint256);
}

interface IERC20Extended {
    function decimals() external view returns (uint8);
}