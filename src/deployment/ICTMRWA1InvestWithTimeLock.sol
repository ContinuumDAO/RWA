// SPDX-License-Identifier: BSL-1.1

pragma solidity 0.8.27;

import { CTMRWAErrorParam } from "../utils/CTMRWAUtils.sol";

struct Offering {
    uint256 tokenId;
    uint256 offerAmount;
    uint256 balRemaining;
    uint256 price;
    address currency;
    uint256 minInvestment;
    uint256 maxInvestment;
    uint256 investment;
    string regulatorCountry;
    string regulatorAcronym;
    string offeringType;
    string bnbGreenfieldObjectName;
    uint256 startTime;
    uint256 endTime;
    uint256 lockDuration;
    address rewardToken;
    Holding[] holdings;
}

struct Holding {
    uint256 offerIndex;
    address investor;
    uint256 tokenId;
    uint256 escrowTime;
    uint256 rewardAmount;
}

interface ICTMRWA1InvestWithTimeLock {
    // Events
    event CreateOffering(uint256 indexed ID, uint256 indx, uint256 slot, uint256 offer);
    event OfferingPaused(uint256 indexed ID, uint256 indexed indx, address account);
    event OfferingUnpaused(uint256 indexed ID, uint256 indexed indx, address account);
    event InvestInOffering(uint256 indexed ID, uint256 indx, uint256 holdingIndx, uint256 investment);
    event WithdrawFunds(uint256 indexed ID, uint256 indx, uint256 funds);
    event UnlockInvestmentToken(uint256 indexed ID, address holder, uint256 holdingIndx);
    event ClaimDividendInEscrow(uint256 indexed ID, address holder, uint256 unclaimed);
    event FundedRewardToken(uint256 indexed offeringIndex, uint256 fundAmount, uint256 rewardMultiplier);
    event RewardClaimed(address indexed holder, uint256 indexed offerIndex, uint256 indexed holdingIndex, uint256 amount);
    event RemoveRemainingBalance(uint256 indexed ID, uint256 indexed indx, uint256 remainingBalance);

    // Errors
    error CTMRWA1InvestWithTimeLock_OnlyAuthorized(CTMRWAErrorParam, CTMRWAErrorParam);
    error CTMRWA1InvestWithTimeLock_InvalidContract(CTMRWAErrorParam);
    error CTMRWA1InvestWithTimeLock_OutOfBounds();
    error CTMRWA1InvestWithTimeLock_NonExistentToken(uint256);
    error CTMRWA1InvestWithTimeLock_MaxOfferings();
    error CTMRWA1InvestWithTimeLock_InvalidLength(CTMRWAErrorParam);
    error CTMRWA1InvestWithTimeLock_Paused();
    error CTMRWA1InvestWithTimeLock_InvalidTimestamp(CTMRWAErrorParam);
    error CTMRWA1InvestWithTimeLock_InvalidAmount(CTMRWAErrorParam);
    error CTMRWA1InvestWithTimeLock_NotWhiteListed(address);
    error CTMRWA1InvestWithTimeLock_AlreadyWithdrawn(uint256);
    error CTMRWA1InvestWithTimeLock_InvalidOfferingIndex();
    error CTMRWA1InvestWithTimeLock_InvalidHoldingIndex();
    error CTMRWA1InvestWithTimeLock_NoRewardToken();
    error CTMRWA1InvestWithTimeLock_NoRewardsToClaim();
    error CTMRWA1InvestWithTimeLock_HoldingNotFound();
    error CTMRWA1InvestWithTimeLock_OfferingNotEnded();
    error CTMRWA1InvestWithTimeLock_NoRemainingBalance();
    error CTMRWA1InvestWithTimeLock_FailedTransfer();

    // Public constants
    function RWA_TYPE() external view returns (uint256);
    function VERSION() external view returns (uint256);
    function MAX_OFFERINGS() external view returns (uint256);

    // Public variables
    function commissionRate() external view returns (uint256);
    function ctmRwaDividend() external view returns (address);
    function ctmRwaSentry() external view returns (address);
    function ctmRwa1X() external view returns (address);
    function ctmRwaMap() external view returns (address);
    function feeManager() external view returns (address);
    function tokenAdmin() external view returns (address);

    function pauseOffering(uint256 _indx) external;
    function unpauseOffering(uint256 _indx) external;

    function isOfferingPaused(uint256 _indx) external view returns (bool);

    function createOffering(
        uint256 _tokenId,
        uint256 _price,
        address _currency,
        uint256 _minInvestment,
        uint256 _maxInvestment,
        string memory _regulatorCountry,
        string memory _regulatorAcronym,
        string memory _offeringType,
        string memory _bnbGreenfieldObjectName,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _lockDuration,
        address _rewardToken,
        address _feeToken
    ) external;

    function ID() external returns (uint256);

    function setTokenAdmin(address _tokenAdmin, bool _force) external returns (bool);

    function investInOffering(uint256 indx, uint256 investment, address feeToken) external returns (uint256);

    function withdrawInvested(uint256 indx) external returns (uint256);

    function unlockTokenId(uint256 myIndx, address feeToken) external returns (uint256);

    function getTokenIdsInEscrow() external returns (uint256[] memory, address[] memory);

    function offeringCount() external view returns (uint256);
    function listOfferings() external view returns (Offering[] memory);
    function listOffering(uint256 offerIndx) external view returns (Offering memory);

    function escrowHoldingCount(address holder) external view returns (uint256);
    function listEscrowHoldings(address holder) external view returns (Holding[] memory);

    function listEscrowHolding(address holder, uint256 myIndx) external view returns (Holding memory);

    function getRewardInfo(address holder, uint256 offerIndex, uint256 holdingIndex) external view returns (address rewardToken, uint256 rewardAmount);
    function claimReward(uint256 offerIndex, uint256 holdingIndex) external;
    function fundRewardTokenForOffering(uint256 _offeringIndex, uint256 _fundAmount, uint256 _rewardMultiplier, uint256 _rateDivisor) external;
    function removeRemainingTokenId(uint256 _indx, address _feeToken) external returns (uint256);
}
