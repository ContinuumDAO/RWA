// SPDX-License-Identifier: BSL-1.1

pragma solidity 0.8.27;

import { Uint } from "../CTMRWAUtils.sol";

enum FeeType {
    ADMIN,
    DEPLOY,
    TX,
    MINT,
    BURN,
    ISSUER,
    PROVENANCE,
    VALUATION,
    PROSPECTUS,
    RATING,
    LEGAL,
    FINANCIAL,
    LICENSE,
    DUEDILIGENCE,
    NOTICE,
    DIVIDEND,
    REDEMPTION,
    WHOCANINVEST,
    IMAGE,
    VIDEO,
    ICON,
    WHITELIST,
    COUNTRY,
    KYC,
    ERC20,
    DEPLOYINVEST,
    OFFERING,
    INVEST
}

interface IFeeManager {
    error FeeManager_InvalidLength(Uint);
    error FeeManager_NonExistentToken(address);
    error FeeManager_FailedTransfer();

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

    function getFeeTokenList() external returns (address[] memory);
    function getFeeTokenIndexMap(string memory) external view returns (uint256);
    function payFee(uint256 fee, string memory feeTokenStr) external returns (uint256);
}

interface IERC20Extended {
    function decimals() external view returns (uint8);
}
