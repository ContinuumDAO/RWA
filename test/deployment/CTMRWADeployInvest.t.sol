// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.22;

import { Test } from "forge-std/Test.sol";
import { console } from "forge-std/console.sol";

import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

import { Helpers } from "../helpers/Helpers.sol";

import { Holding, ICTMRWA1InvestWithTimeLock, Offering } from "../../src/deployment/ICTMRWADeployInvest.sol";

import { ICTMRWA1Dividend } from "../../src/dividend/ICTMRWA1Dividend.sol";
import { FeeType } from "../../src/managers/IFeeManager.sol";

contract TestInvest is Helpers {
    using Strings for *;

    function test_invest() public {
        vm.startPrank(tokenAdmin);
        (ID, token) = _deployCTMRWA1(address(usdc));
        _deployAFewTokensLocal(address(token), address(usdc), address(map), address(rwa1X), tokenAdmin);

        uint256 oneUsdc = 10 ** usdc.decimals();
        uint8 decimalsRwa = token.valueDecimals();
        uint256 oneRwaUnit = 10 ** decimalsRwa;

        string memory feeTokenStr = address(usdc).toHexString();

        uint256 slot = 1;

        uint256 tokenIdAdmin = rwa1X.mintNewTokenValueLocal(
            tokenAdmin,
            0,
            slot,
            4 * oneRwaUnit, // 4 apartments (2 bed)
            ID,
            feeTokenStr
        );

        slot = 5;

        uint256 tokenIdAdmin2 = rwa1X.mintNewTokenValueLocal(
            tokenAdmin,
            0,
            slot,
            2 * oneRwaUnit, // 2 apartments (3 bed)
            ID,
            feeTokenStr
        );

        feeManager.setFeeMultiplier(FeeType.DEPLOYINVEST, 50);
        feeManager.setFeeMultiplier(FeeType.OFFERING, 50);
        feeManager.setFeeMultiplier(FeeType.INVEST, 5);

        bool ok;
        address investContract;

        address ctmInvest = deployer.deployNewInvestment(ID, RWA_TYPE, VERSION, address(usdc));

        vm.expectRevert("CTMDeploy: Investment contract already deployed");
        deployer.deployNewInvestment(ID, RWA_TYPE, VERSION, address(usdc));

        (ok, investContract) = map.getInvestContract(ID, RWA_TYPE, VERSION);
        assertEq(ok, true);
        assertEq(investContract, ctmInvest);

        vm.stopPrank();

        uint256 price = 200_000 * oneUsdc; // price of an apartment
        address currency = address(usdc);
        uint256 minInvest = 1000 * oneUsdc;
        uint256 maxInvest = 4000 * oneUsdc;
        string memory regulatorCountry = "US";
        string memory regulatorAcronym = "SEC";
        string memory offeringType = "Private Placement | Schedule D, 506(c)";
        uint256 startTime = block.timestamp + 1 * 24 * 3600;
        uint256 endTime = startTime + 30 * 24 * 3600;
        uint256 lockDuration = 366 * 24 * 3600;

        vm.startPrank(user1);

        vm.expectRevert("CTMInvest: Not tokenAdmin");
        ICTMRWA1InvestWithTimeLock(investContract).createOffering(
            tokenIdAdmin,
            price,
            currency,
            minInvest,
            maxInvest,
            regulatorCountry,
            regulatorAcronym,
            offeringType,
            startTime,
            endTime,
            lockDuration,
            address(usdc)
        );

        vm.stopPrank();

        vm.startPrank(tokenAdmin);

        vm.expectRevert("RWAX: Not owner/approved");
        ICTMRWA1InvestWithTimeLock(investContract).createOffering(
            tokenIdAdmin,
            price,
            currency,
            minInvest,
            maxInvest,
            regulatorCountry,
            regulatorAcronym,
            offeringType,
            startTime,
            endTime,
            lockDuration,
            address(usdc)
        );

        token.approve(investContract, tokenIdAdmin);
        ICTMRWA1InvestWithTimeLock(investContract).createOffering(
            tokenIdAdmin,
            price,
            currency,
            minInvest,
            maxInvest,
            regulatorCountry,
            regulatorAcronym,
            offeringType,
            startTime,
            endTime,
            lockDuration,
            address(usdc)
        );

        uint256 count = ICTMRWA1InvestWithTimeLock(investContract).offeringCount();
        assertEq(count, 1);

        Offering[] memory offerings = ICTMRWA1InvestWithTimeLock(investContract).listOfferings();
        assertEq(offerings[0].tokenId, tokenIdAdmin);
        assertEq(offerings[0].currency, currency);

        address tokenOwner = token.ownerOf(tokenIdAdmin);
        assertEq(tokenOwner, investContract);

        // try to add the same tokenId again
        vm.expectRevert("RWA: transfer from invalid owner");
        ICTMRWA1InvestWithTimeLock(investContract).createOffering(
            tokenIdAdmin,
            price,
            currency,
            minInvest,
            maxInvest,
            regulatorCountry,
            regulatorAcronym,
            offeringType,
            startTime,
            endTime,
            lockDuration,
            address(usdc)
        );

        vm.stopPrank();

        vm.startPrank(user1);

        uint256 indx = 0;
        uint256 investment = 2000 * oneUsdc;

        vm.expectRevert("CTMInvest: Offer not yet started");
        uint256 tokenInEscrow =
            ICTMRWA1InvestWithTimeLock(investContract).investInOffering(indx, investment, address(usdc));

        skip(1 * 24 * 3600 + 1);

        vm.expectRevert("CTMInvest: investment too low");
        tokenInEscrow = ICTMRWA1InvestWithTimeLock(investContract).investInOffering(indx, 500 * oneUsdc, address(usdc));

        vm.expectRevert("CTMInvest: investment too high");
        tokenInEscrow = ICTMRWA1InvestWithTimeLock(investContract).investInOffering(indx, 5000 * oneUsdc, address(usdc));

        usdc.approve(investContract, investment);
        tokenInEscrow = ICTMRWA1InvestWithTimeLock(investContract).investInOffering(indx, investment, address(usdc));

        uint256 balInEscrow = token.balanceOf(tokenInEscrow);
        assertEq(balInEscrow * price, investment * oneRwaUnit);

        Holding memory myHolding = ICTMRWA1InvestWithTimeLock(investContract).listEscrowHolding(user1, 0);
        assertEq(myHolding.offerIndex, 0);
        assertEq(myHolding.investor, user1);
        assertEq(myHolding.tokenId, tokenInEscrow);
        // block.timestamp hasn't advanced since the investOffering call
        assertEq(myHolding.escrowTime, offerings[myHolding.offerIndex].lockDuration + block.timestamp);

        address owner = token.ownerOf(tokenInEscrow);
        assertEq(owner, investContract);

        // skip(30*24*3600);

        // vm.expectRevert("CTMInvest: Offer expired");
        // usdc.approve(investContract, investment);
        // uint256 tokenInEscrow2 = ICTMRWA1InvestWithTimeLock(investContract).investInOffering(
        //     indx, investment, address(usdc)
        // );

        skip(365 * 24 * 3600); // Day is now 1 day before lockDuration for tokenInEscrow

        vm.expectRevert("CTMInvest: tokenId is still locked");
        ICTMRWA1InvestWithTimeLock(investContract).unlockTokenId(myHolding.offerIndex, address(usdc));

        skip(1 * 24 * 3600);
        ICTMRWA1InvestWithTimeLock(investContract).unlockTokenId(myHolding.offerIndex, address(usdc));

        owner = token.ownerOf(tokenInEscrow);
        assertEq(owner, user1);

        // Try again
        vm.expectRevert("CTMInvest: tokenId already withdrawn");
        ICTMRWA1InvestWithTimeLock(investContract).unlockTokenId(myHolding.offerIndex, address(usdc));

        vm.stopPrank();

        vm.startPrank(tokenAdmin);

        sentryManager.setSentryOptions(
            ID,
            true, // whitelistSwitch
            false, // kycSwitch
            false, // kybSwitch
            false, // over18Switch
            false, // accreditedSwitch
            false, // countryWLSwitch
            false, // countryBLSwitch
            _stringToArray(cIdStr),
            feeTokenStr
        );

        // Create another holding for slot 5 this time
        token.approve(investContract, tokenIdAdmin2);
        ICTMRWA1InvestWithTimeLock(investContract).createOffering(
            tokenIdAdmin2,
            price,
            currency,
            minInvest,
            maxInvest,
            regulatorCountry,
            regulatorAcronym,
            offeringType,
            block.timestamp,
            block.timestamp + 30 * 24 * 3600,
            lockDuration,
            address(usdc)
        );
        count = ICTMRWA1InvestWithTimeLock(investContract).offeringCount();
        assertEq(count, 2);

        vm.stopPrank();

        vm.startPrank(user1);

        indx = 1; // This new second offering
        usdc.approve(investContract, investment);
        vm.expectRevert("CTMInvest: Not whitelisted");
        tokenInEscrow = ICTMRWA1InvestWithTimeLock(investContract).investInOffering(indx, investment, address(usdc));

        vm.stopPrank();

        vm.startPrank(tokenAdmin);

        sentryManager.addWhitelist(
            ID, _stringToArray(user1.toHexString()), _boolToArray(true), _stringToArray(cIdStr), feeTokenStr
        );

        vm.stopPrank();

        vm.startPrank(user1);

        tokenInEscrow = ICTMRWA1InvestWithTimeLock(investContract).investInOffering(indx, investment, address(usdc));

        uint256 holdingCount = ICTMRWA1InvestWithTimeLock(investContract).escrowHoldingCount(user1);
        assertEq(holdingCount, 2); // The first one has already been redeemed

        vm.stopPrank();

        vm.startPrank(tokenAdmin);
        // Test to see if pause works
        ICTMRWA1InvestWithTimeLock(investContract).pauseOffering(indx);
        vm.stopPrank();

        vm.startPrank(user1);
        usdc.approve(investContract, investment);
        vm.expectRevert("CTMInvest: Offering is paused");
        ICTMRWA1InvestWithTimeLock(investContract).investInOffering(indx, investment, address(usdc));
        vm.stopPrank();

        vm.startPrank(tokenAdmin);
        // Test to see if pause works
        ICTMRWA1InvestWithTimeLock(investContract).unpauseOffering(indx);
        vm.stopPrank();

        vm.startPrank(user1);
        ICTMRWA1InvestWithTimeLock(investContract).investInOffering(indx, investment, address(usdc));
        holdingCount = ICTMRWA1InvestWithTimeLock(investContract).escrowHoldingCount(user1);
        assertEq(holdingCount, 3);
        vm.stopPrank();

        vm.startPrank(tokenAdmin);

        // Test to see if we can claim dividends whilst token is in escrow

        address ctmDividend = token.dividendAddr();

        ICTMRWA1Dividend(ctmDividend).setDividendToken(address(usdc));

        uint256 divRate = 2;
        ICTMRWA1Dividend(ctmDividend).changeDividendRate(5, divRate);

        // uint256 dividendTotal = ICTMRWA1Dividend(ctmDividend).getTotalDividend();

        // usdc.approve(ctmDividend, dividendTotal);
        // uint256 unclaimed = ICTMRWA1Dividend(ctmDividend).fundDividend();

        vm.stopPrank();
    }
}
