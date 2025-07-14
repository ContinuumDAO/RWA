// SPDX-License-Identifier: BSL-1.1

pragma solidity ^0.8.22;

import {Uint, Address, Time} from "../CTMRWAUtils.sol";

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
    uint256 startTime;
    uint256 endTime;
    uint256 lockDuration;
    Holding[] holdings;
}

struct Holding {
    uint256 offerIndex;
    address investor;
    uint256 tokenId;
    uint256 escrowTime;
}

interface ICTMRWA1InvestWithTimeLock {
    error CTMRWA1InvestWithTimeLock_Unauthorized(Address);
    error CTMRWA1InvestWithTimeLock_InvalidContract(Address);
    error CTMRWA1InvestWithTimeLock_OutOfBounds();
    error CTMRWA1InvestWithTimeLock_NonExistentToken(uint256);
    error CTMRWA1InvestWithTimeLock_MaxOfferings();
    error CTMRWA1InvestWithTimeLock_InvalidLength(Uint);
    error CTMRWA1InvestWithTimeLock_Paused();
    error CTMRWA1InvestWithTimeLock_InvalidTimestamp(Time);
    error CTMRWA1InvestWithTimeLock_InvalidAmount(Uint);
    error CTMRWA1InvestWithTimeLock_NotWhiteListed(address);

    // TODO: implement this function
    // function holdingsByAddress(address) external view returns (Holding[] memory);

    function commissionRate() external view returns (uint256);

    function pauseOffering(uint256 _indx) external;
    function unpauseOffering(uint256 _indx) external;

    function isOfferingPaused(uint256 _indx) external view returns (bool);

    function createOffering(
        uint256 tokenId,
        uint256 price,
        address currency,
        uint256 minInvestment,
        uint256 maxInvestment,
        string memory regulatorCountry,
        string memory regulatorAcronym,
        string memory offeringType,
        uint256 startTime,
        uint256 endTime,
        uint256 lockDuration,
        address feeToken
    ) external;

    function investInOffering(uint256 indx, uint256 investment, address feeToken) external returns (uint256);

    function withdrawInvested(uint256 indx) external returns (uint256);

    function unlockTokenId(uint256 myIndx, address feeToken) external returns (uint256);

    function claimDividendInEscrow(uint256 myIndx) external returns (uint256);

    function offeringCount() external view returns (uint256);
    function listOfferings() external view returns (Offering[] memory);
    function listOffering(uint256 offerIndx) external view returns (Offering memory);

    function escrowHoldingCount(address holder) external view returns (uint256);
    function listEscrowHoldings(address holder) external view returns (Holding[] memory);

    function listEscrowHolding(address holder, uint256 myIndx) external view returns (Holding memory);
}
