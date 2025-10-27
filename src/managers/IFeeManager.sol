// SPDX-License-Identifier: BSL-1.1

pragma solidity 0.8.27;

import { CTMRWAErrorParam } from "../utils/CTMRWAUtils.sol";

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
    INVEST,
    EMPTY
}

interface IFeeManager {
    error FeeManager_InvalidFeeType(FeeType);
    error FeeManager_InvalidLength(CTMRWAErrorParam);
    error FeeManager_NonExistentToken(address);
    error FeeManager_FailedTransfer();
    error FeeManager_UnsetFee(address);
    error FeeManager_InvalidReductionFactor(uint256);
    error FeeManager_InvalidExpiration(uint256);
    error FeeManager_InvalidAddress(address);
    error FeeManager_UnsafeToken(address);
    error FeeManager_UpgradeableToken(address);
    error FeeManager_InvalidDecimals(address token, uint8 decimals);
    error FeeManager_TokenAlreadyListed(address token);
    
    function getXChainFee(
        string[] memory _toChainIDsStr,
        bool _includeLocal,
        FeeType _feeType,
        string memory _feeTokenStr
    ) external view returns (uint256);
    
    function getFeeMultiplier(FeeType _feeType) external view returns (uint256);

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
    
    function addFeeReduction(address[] memory addresses, uint256[] memory reductionFactors, uint256[] memory expirations) external returns (bool);
    function removeFeeReduction(address[] memory addresses) external returns (bool);
    function updateFeeReductionExpiration(address[] memory addresses, uint256[] memory newExpirations) external returns (bool);
    function getFeeReduction(address _address) external view returns (uint256);
    
    function getToChainBaseFee(string memory _toChainIDStr, string memory _feeTokenStr) external view returns (uint256);
    function withdrawFee(string memory _feeTokenStr, uint256 _amount, string memory _treasuryStr) external returns (bool);
    function pause() external;
    function unpause() external;
}

interface IERC20Extended {
    function decimals() external view returns (uint8);
}
