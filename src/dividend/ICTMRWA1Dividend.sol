// SPDX-License-Identifier: BSL-1.1

pragma solidity 0.8.27;

import { ICTMRWA } from "../core/ICTMRWA.sol";
import { CTMRWAErrorParam } from "../utils/CTMRWAUtils.sol";

interface ICTMRWA1Dividend is ICTMRWA {

    error CTMRWA1Dividend_OnlyAuthorized(CTMRWAErrorParam, CTMRWAErrorParam);
    error CTMRWA1Dividend_InvalidDividend(CTMRWAErrorParam);
    error CTMRWA1Dividend_InvalidDividendScale(uint256);
    error CTMRWA1Dividend_ScaleAlreadySetOrRateSet(uint256);
    error CTMRWA1Dividend_CalculationOverflow(uint256 balance, uint256 rate);
    error CTMRWA1Dividend_FailedTransaction();
    error CTMRWA1Dividend_FundingTimeLow();
    error CTMRWA1Dividend_FundingTimeFuture();
    error CTMRWA1Dividend_FundingTooFrequent();
    error CTMRWA1Dividend_FundTokenNotSet();
    error CTMRWA1Dividend_InvalidSlot(uint256);
    error CTMRWA1Dividend_EnforcedPause();

    function ID() external view returns (uint256);
    function tokenAdmin() external view returns (address);
    function setTokenAdmin(address _tokenAdmin) external returns (bool);
    function setDividendToken(address dividendToken) external returns (bool);
    function dividendToken() external returns (address);
    function changeDividendRate(uint256 slot, uint256 dividendPerUnit) external returns (bool);
    function setDividendScaleBySlot(uint256 _slot, uint256 _dividendScale) external returns (bool);
    function getDecimalInfo() external view returns (uint8 ctmRwaDecimals, uint8 dividendDecimals);
    function getDividendToFund(uint256 slot, uint256 fundingTime) external returns(uint256);
    function fundDividend(uint256 slot, uint256 fundingTime, string memory _bnbGreenfieldObjectName) external returns (uint256);
    function getDividendPayableBySlot(uint256 slot, address holder) external view returns (uint256);
    function getDividendPayable(address holder) external view returns (uint256);
    function claimDividend() external returns (uint256);
    function dividendFundings(uint256 index) external view returns (uint256 slot, uint48 fundingTime, uint256 fundingAmount, string memory bnbGreenfieldObjectName);
    /// @notice Returns the last claimed index for a given slot and holder
    function lastClaimedIndex(uint256 slot, address holder) external view returns (uint256);
    function getDividendRateBySlotAt(uint256 _slot, uint48 _timestamp) external view returns (uint256);
    function getDividendRateBySlot(uint256 _slot) external view returns (uint256);
    function getStoredDividendRateBySlotAt(uint256 _slot, uint48 _timestamp) external view returns (uint256);
    /// @notice Returns the last funding timestamp for a given slot
    function lastFundingBySlot(uint256 slot) external view returns (uint48);
    function totalDividendPayable() external view returns (uint256);
    function totalDividendClaimed() external view returns (uint256);
    function pause() external;
    function unpause() external;
}
