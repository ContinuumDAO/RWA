// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.19;

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

interface ICTMRWADeployInvest {
    function ID() external view returns(uint256);
    function commissionRate() external view returns(uint256);

    function setCommissionRate(uint256 commissionRate) external;

    function setDeployerMapFee(
        address deployer, 
        address ctmRwaMap, 
        address feeManager
    ) external;

    function deployInvest(
        uint256 ID,
        uint256 rwaType,
        uint256 version,
        address feeToken
    ) external returns(address);
}

interface ICTMRWA001InvestWithTimeLock {
    function holdingsByAddress(address) external view returns(Holding[] memory);
    function commissionRate() external view returns(uint256);

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

    function investInOffering(
        uint256 indx, 
        uint256 investment,
        address feeToken
    ) external returns(uint256);

    function withdrawInvested(uint256 indx) external returns(uint256);

    function unlockTokenId(uint256 myIndx, address feeToken) external returns(uint256);

    function claimDividendInEscrow(uint256 myIndx) external returns(uint256);

    function offeringCount() external view returns(uint256);
    function listOfferings() external view returns(Offering[] memory);
    function listOffering(uint256 offerIndx) external view returns(Offering memory);

    function escrowHoldingCount(address holder) external view returns(uint256);
    function listEscrowHoldings(address holder) external view returns(Holding[] memory);

    function listEscrowHolding(
        address holder, 
        uint256 myIndx
    ) external view returns(Holding memory);
}