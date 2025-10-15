// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.27;

import { Test } from "forge-std/Test.sol";
import { console } from "forge-std/console.sol";

import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { ICTMRWA1Dividend } from "../../src/dividend/ICTMRWA1Dividend.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ICTMRWAMap } from "../../src/shared/ICTMRWAMap.sol";
import { CTMRWA1 } from "src/core/CTMRWA1.sol";
import { CTMRWAErrorParam } from "../../src/utils/CTMRWAUtils.sol";

import { Helpers } from "../helpers/Helpers.sol";

contract TestDividend is Helpers {
    using Strings for *;

    address public dividendContract;
    uint256 public tokenId1;
    uint256 public tokenId2;
    uint256 public tokenId3;

    function setUp() public override {
        super.setUp();
        vm.startPrank(tokenAdmin);
        (ID, token) = _deployCTMRWA1(address(usdc));
        (, dividendContract) = ICTMRWAMap(map).getDividendContract(ID, RWA_TYPE, VERSION);
        _createSomeSlots(ID, address(usdc), address(rwa1X));
        // (tokenId1, tokenId2, tokenId3) = _deployAFewTokensLocal(address(token), address(usdc), address(map), address(rwa1X), user1);
        vm.stopPrank();
    }

    function _setupBasicDividends() internal returns(uint256) {
        // Set up dividend token (USDC with 6 decimals)
        ICTMRWA1Dividend(dividendContract).setDividendToken(address(usdc));
        
        // Mint tokens for different users in different slots
        uint256 mintAmount1 = 6000 * 10**18; // 6000 CTMRWA1 units
        uint256 mintAmount2 = 4000 * 10**18; // 4000 CTMRWA1 units  
        uint256 mintAmount3 = 2000 * 10**18; // 2000 CTMRWA1 units
        
        string memory tokenStr = _toLower(address(usdc).toHexString());
        
        // Mint for user1 in slot 1
        rwa1XUtils.mintNewTokenValueLocal(user1, 0, 1, mintAmount1, ID, VERSION, tokenStr);
        
        // Mint for user1 in slot 3
        rwa1XUtils.mintNewTokenValueLocal(user1, 0, 3, mintAmount2, ID, VERSION, tokenStr);
        
        // Mint for user1 in slot 5
        rwa1XUtils.mintNewTokenValueLocal(user1, 0, 5, mintAmount3, ID, VERSION, tokenStr);
        
        // Set dividend rates for different slots
        uint256 rate1 = 100 * 10**6; // 100 USDC per CTMRWA1 unit
        uint256 rate2 = 150 * 10**6; // 150 USDC per CTMRWA1 unit
        uint256 rate3 = 80 * 10**6;  // 80 USDC per CTMRWA1 unit
        
        vm.warp(1 hours);
        ICTMRWA1Dividend(dividendContract).changeDividendRate(1, rate1);
        ICTMRWA1Dividend(dividendContract).changeDividendRate(3, rate2);
        ICTMRWA1Dividend(dividendContract).changeDividendRate(5, rate3);
        
        // Use a funding time that results in midnight = 1 day
        uint256 fundingTime = 1 days + 12 hours;
        
        // Get the actual dividend amounts to fund
        uint256 dividendToFund1 = ICTMRWA1Dividend(dividendContract).getDividendToFund(1, fundingTime);
        uint256 dividendToFund2 = ICTMRWA1Dividend(dividendContract).getDividendToFund(3, fundingTime);
        uint256 dividendToFund3 = ICTMRWA1Dividend(dividendContract).getDividendToFund(5, fundingTime);
        
        uint256 totalRequired = dividendToFund1 + dividendToFund2 + dividendToFund3;
        
        // Ensure tokenAdmin has enough USDC for the dividend payments
        deal(address(usdc), tokenAdmin, totalRequired);
        IERC20(usdc).approve(dividendContract, type(uint256).max);
        
        // Warp to a time after the funding time to avoid CTMRWA1Dividend_FundingTimeFuture error
        vm.warp(fundingTime + 1);
        
        // Fund dividends for all slots
        ICTMRWA1Dividend(dividendContract).fundDividend(1, fundingTime, "dividend-funding-1");
        ICTMRWA1Dividend(dividendContract).fundDividend(3, fundingTime, "dividend-funding-3");
        ICTMRWA1Dividend(dividendContract).fundDividend(5, fundingTime, "dividend-funding-5");
        
        return fundingTime;
    }

    

    function test_user_with_no_tokens_claims_zero() public {
        vm.startPrank(tokenAdmin);
        _setupBasicDividends();
        vm.stopPrank();

        // Record user2's initial USDC balance
        uint256 initialBalance = IERC20(usdc).balanceOf(user2);

        // User2 claims dividends
        vm.startPrank(user2);
        uint256 claimed = ICTMRWA1Dividend(dividendContract).claimDividend();
        vm.stopPrank();

        // User2's balance should not change and claimed should be zero
        uint256 finalBalance = IERC20(usdc).balanceOf(user2);
        assertEq(finalBalance, initialBalance);
        assertEq(claimed, 0, "User with no tokens should claim zero dividends");
    }

    function test_only_token_admin_can_fund_dividends() public {
        vm.startPrank(tokenAdmin);
        _setupBasicDividends();
        vm.stopPrank();
        
        // Try to fund as non-admin
        vm.startPrank(user1);
        vm.expectRevert(abi.encodeWithSelector(ICTMRWA1Dividend.CTMRWA1Dividend_OnlyAuthorized.selector, CTMRWAErrorParam.Sender, CTMRWAErrorParam.TokenAdmin));
        ICTMRWA1Dividend(dividendContract).fundDividend(1, 1 days, "test-funding");
        vm.stopPrank();
    }

    function test_invalid_slot_reverts() public {
        vm.startPrank(tokenAdmin);
        ICTMRWA1Dividend(dividendContract).setDividendToken(address(usdc));
        
        // Try to set dividend rate for non-existent slot
        vm.expectRevert(abi.encodeWithSelector(ICTMRWA1Dividend.CTMRWA1Dividend_InvalidSlot.selector, 999));
        ICTMRWA1Dividend(dividendContract).changeDividendRate(999, 100);
        vm.stopPrank();
    }

    function test_pause_unpause_functionality() public {
        vm.startPrank(tokenAdmin);
        _setupBasicDividends();
        
        // Pause the contract
        ICTMRWA1Dividend(dividendContract).pause();
        vm.stopPrank();

        // Attempt to claim dividends as user1 (should revert)
        vm.startPrank(user1);
        vm.expectRevert(ICTMRWA1Dividend.CTMRWA1Dividend_EnforcedPause.selector);
        ICTMRWA1Dividend(dividendContract).claimDividend();
        vm.stopPrank();

        // Unpause the contract
        vm.startPrank(tokenAdmin);
        ICTMRWA1Dividend(dividendContract).unpause();
        vm.stopPrank();

        // Now claim should succeed and return the actual dividend amount
        vm.startPrank(user1);
        uint256 claimed = ICTMRWA1Dividend(dividendContract).claimDividend();
        vm.stopPrank();
        
        assertGt(claimed, 0, "Claim should succeed after unpausing and return dividends");
    }

    function test_simple_dividend_calculation() public {
        vm.startPrank(tokenAdmin);
        
        // Set up dividend token (USDC with 6 decimals)
        ICTMRWA1Dividend(dividendContract).setDividendToken(address(usdc));
        
        // Mint 20 * 10^18 wei in slot 5 for tokenAdmin2
        uint256 mintAmount = 20 * 10**18; // 20 CTMRWA1 units
        string memory tokenStr = _toLower(address(usdc).toHexString());
        rwa1XUtils.mintNewTokenValueLocal(tokenAdmin2, 0, 5, mintAmount, ID, VERSION, tokenStr);
        
        // Set dividend scale to 12 (meaning per 1e12 wei instead of per 1e18 wei)
        // This means dividends are calculated per 1e-6 CTMRWA1 units instead of per 1 CTMRWA1 unit
        ICTMRWA1Dividend(dividendContract).setDividendScaleBySlot(5, 12);
        
        // Set dividend rate: 2000 USDC per CTMRWA1 unit (same as simple test)
        uint256 inputRate = 2000; // 2000 USDC per CTMRWA1 unit
        vm.warp(1 hours);
        
        ICTMRWA1Dividend(dividendContract).changeDividendRate(5, inputRate);
        
        // Check tokenAdmin2's balance in slot 5
        CTMRWA1(token).balanceOf(tokenAdmin2, 5);
        
        // Use a funding time that results in midnight = 1 day (86400 seconds)
        uint256 fundingTime = 1 days + 12 hours; // This will give us midnight = 1 day
        
        // Get the actual dividend to fund to determine the correct amount
        uint256 actualDividendToFund = ICTMRWA1Dividend(dividendContract).getDividendToFund(5, fundingTime);
        
        // Expected dividend: 20 CTMRWA1 units * 2000 USDC per unit = 40,000 USDC
        uint256 expectedDividend = 20 * 2000 * 10**6; // 20 units * 2000 USDC * 10^6 (USDC wei)
        
        // Ensure tokenAdmin has enough USDC for the dividend payment
        deal(address(usdc), tokenAdmin, actualDividendToFund);
        IERC20(usdc).approve(dividendContract, type(uint256).max);
        
        // Warp to a time after the funding time to avoid CTMRWA1Dividend_FundingTimeFuture error
        vm.warp(fundingTime + 1);
        
        ICTMRWA1Dividend(dividendContract).fundDividend(5, fundingTime, "dividend-funding-5");
        vm.stopPrank();

        // tokenAdmin2 claims dividends
        vm.startPrank(tokenAdmin2);
        uint256 claimed = ICTMRWA1Dividend(dividendContract).claimDividend();
        vm.stopPrank();
        
        // Verify the calculation
        assertEq(claimed, expectedDividend, "Dividend calculation should be correct");
    }

    function test_cannot_claim_dividends_twice() public {
        vm.startPrank(tokenAdmin);
        _setupBasicDividends();
        vm.stopPrank();
        
        // First claim should succeed
        vm.startPrank(user1);
        uint256 firstClaim = ICTMRWA1Dividend(dividendContract).claimDividend();
        vm.stopPrank();
        
        assertGt(firstClaim, 0, "First claim should succeed and return dividends");
        
        // Second claim should return 0 since dividends are already claimed
        vm.startPrank(user1);
        uint256 secondClaim = ICTMRWA1Dividend(dividendContract).claimDividend();
        vm.stopPrank();
        
        assertEq(secondClaim, 0, "Second claim should return 0 since dividends are already claimed");
    }

    function test_cannot_set_dividend_scale_to_zero() public {
        vm.startPrank(tokenAdmin);
        vm.expectRevert(abi.encodeWithSelector(ICTMRWA1Dividend.CTMRWA1Dividend_InvalidDividendScale.selector, 0));
        ICTMRWA1Dividend(dividendContract).setDividendScaleBySlot(1, 0);
        vm.stopPrank();
    }

    function test_dividend_calculation_with_custom_scale() public {
        vm.startPrank(tokenAdmin);
        
        // Set up dividend token (USDC with 6 decimals)
        ICTMRWA1Dividend(dividendContract).setDividendToken(address(usdc));
        
        // Mint 20 * 10^18 wei in slot 5 for tokenAdmin2
        uint256 mintAmount = 20 * 10**18; // 20 CTMRWA1 units
        string memory tokenStr = _toLower(address(usdc).toHexString());
        rwa1XUtils.mintNewTokenValueLocal(tokenAdmin2, 0, 5, mintAmount, ID, VERSION, tokenStr);
        
        // Set dividend scale to 12 (meaning per 1e12 wei instead of per 1e18 wei)
        // This means dividends are calculated per 1e-6 CTMRWA1 units instead of per 1 CTMRWA1 unit
        ICTMRWA1Dividend(dividendContract).setDividendScaleBySlot(5, 12);
        
        // Set dividend rate: 2000 USDC per CTMRWA1 unit (same as simple test)
        uint256 inputRate = 2000; // 2000 USDC per CTMRWA1 unit
        vm.warp(1 hours);
        
        ICTMRWA1Dividend(dividendContract).changeDividendRate(5, inputRate);
        
        // Check tokenAdmin2's balance in slot 5
        CTMRWA1(token).balanceOf(tokenAdmin2, 5);
        
        // Use a funding time that results in midnight = 1 day (86400 seconds)
        uint256 fundingTime = 1 days + 12 hours; // This will give us midnight = 1 day
        
        // Get the actual dividend to fund to determine the correct amount
        uint256 actualDividendToFund = ICTMRWA1Dividend(dividendContract).getDividendToFund(5, fundingTime);
        
        // Expected dividend calculation with custom scale:
        // - User has 20 * 10^18 wei (20 CTMRWA1 units)
        // - Scale is 10^12 (per 1e12 wei)
        // - Rate is 2000 USDC per CTMRWA1 unit
        // - Dividend = (20 * 10^18) * 2000 / (10^12) = 40 * 10^9 USDC wei = 40,000 USDC
        uint256 expectedDividend = (20 * 10**18) * 2000 / (10**12);
        
        // Ensure tokenAdmin has enough USDC for the dividend payment
        deal(address(usdc), tokenAdmin, actualDividendToFund);
        IERC20(usdc).approve(dividendContract, type(uint256).max);
        
        // Warp to a time after the funding time to avoid CTMRWA1Dividend_FundingTimeFuture error
        vm.warp(fundingTime + 1);
        
        ICTMRWA1Dividend(dividendContract).fundDividend(5, fundingTime, "dividend-funding-5-custom-scale");
        vm.stopPrank();

        // tokenAdmin2 claims dividends
        vm.startPrank(tokenAdmin2);
        uint256 claimed = ICTMRWA1Dividend(dividendContract).claimDividend();
        vm.stopPrank();
        
        // Verify the calculation with custom scale
        assertEq(claimed, expectedDividend, "Dividend calculation with custom scale should be correct");
        
        // Additional verification: the dividend should be much larger than the simple calculation
        // because we're now calculating per 1e12 wei instead of per 1e18 wei
        uint256 simpleExpectedDividend = 20 * 2000; // 40,000 USDC base units
        assertGt(claimed, simpleExpectedDividend, "Custom scale should result in larger dividends");
        
        // The ratio should be 10^6 (because scale changed from 18 to 12)
        uint256 expectedRatio = 10**6;
        assertEq(claimed / simpleExpectedDividend, expectedRatio, "Custom scale should increase dividends by 10^6");
    }

    function test_dividend_tracking_variables() public {
        vm.startPrank(tokenAdmin);
        
        // Set up dividend token
        ICTMRWA1Dividend(dividendContract).setDividendToken(address(usdc));
        
        // Mint tokens for user1 in slot 1
        uint256 mintAmount = 1000 * 10**18; // 1000 CTMRWA1 units
        string memory tokenStr = _toLower(address(usdc).toHexString());
        rwa1XUtils.mintNewTokenValueLocal(user1, 0, 1, mintAmount, ID, VERSION, tokenStr);
        
        // Set dividend rate
        uint256 inputRate = 100; // 100 USDC per CTMRWA1 unit
        vm.warp(1 hours);
        ICTMRWA1Dividend(dividendContract).changeDividendRate(1, inputRate);
        
        // Check initial tracking values
        uint256 initialPayable = ICTMRWA1Dividend(dividendContract).totalDividendPayable();
        uint256 initialClaimed = ICTMRWA1Dividend(dividendContract).totalDividendClaimed();
        assertEq(initialPayable, 0, "Initial totalDividendPayable should be 0");
        assertEq(initialClaimed, 0, "Initial totalDividendClaimed should be 0");
        
        // Fund dividends
        uint256 fundingTime = 1 days + 12 hours;
        uint256 dividendToFund = ICTMRWA1Dividend(dividendContract).getDividendToFund(1, fundingTime);
        
        // Ensure tokenAdmin has enough USDC
        deal(address(usdc), tokenAdmin, dividendToFund);
        IERC20(usdc).approve(dividendContract, type(uint256).max);
        
        vm.warp(fundingTime + 1);
        ICTMRWA1Dividend(dividendContract).fundDividend(1, fundingTime, "dividend-funding-1-tracking");
        
        // Check tracking after funding
        uint256 afterFundingPayable = ICTMRWA1Dividend(dividendContract).totalDividendPayable();
        uint256 afterFundingClaimed = ICTMRWA1Dividend(dividendContract).totalDividendClaimed();
        assertEq(afterFundingPayable, dividendToFund, "totalDividendPayable should be updated after funding");
        assertEq(afterFundingClaimed, 0, "totalDividendClaimed should still be 0 after funding");
        
        vm.stopPrank();
        
        // User1 claims dividends
        vm.startPrank(user1);
        uint256 claimed = ICTMRWA1Dividend(dividendContract).claimDividend();
        vm.stopPrank();
        
        // Check tracking after claiming
        uint256 afterClaimingPayable = ICTMRWA1Dividend(dividendContract).totalDividendPayable();
        uint256 afterClaimingClaimed = ICTMRWA1Dividend(dividendContract).totalDividendClaimed();
        assertEq(afterClaimingPayable, dividendToFund, "totalDividendPayable should remain the same after claiming");
        assertEq(afterClaimingClaimed, claimed, "totalDividendClaimed should be updated after claiming");
        assertEq(afterClaimingClaimed, dividendToFund, "totalDividendClaimed should equal the funded amount");
        
        // Fund more dividends
        vm.startPrank(tokenAdmin);
        uint256 fundingTime2 = 60 days + 12 hours; // 60 days later to avoid funding too frequent error
        uint256 dividendToFund2 = ICTMRWA1Dividend(dividendContract).getDividendToFund(1, fundingTime2);
        
        deal(address(usdc), tokenAdmin, dividendToFund2);
        vm.warp(fundingTime2 + 1);
        ICTMRWA1Dividend(dividendContract).fundDividend(1, fundingTime2, "dividend-funding-1-tracking-2");
        
        // Check tracking after second funding
        uint256 afterSecondFundingPayable = ICTMRWA1Dividend(dividendContract).totalDividendPayable();
        uint256 afterSecondFundingClaimed = ICTMRWA1Dividend(dividendContract).totalDividendClaimed();
        assertEq(afterSecondFundingPayable, dividendToFund + dividendToFund2, "totalDividendPayable should accumulate");
        assertEq(afterSecondFundingClaimed, claimed, "totalDividendClaimed should remain the same until next claim");
        
        vm.stopPrank();
        
        // User1 claims the new dividends
        vm.startPrank(user1);
        uint256 claimed2 = ICTMRWA1Dividend(dividendContract).claimDividend();
        vm.stopPrank();
        
        // Check final tracking values
        uint256 finalPayable = ICTMRWA1Dividend(dividendContract).totalDividendPayable();
        uint256 finalClaimed = ICTMRWA1Dividend(dividendContract).totalDividendClaimed();
        assertEq(finalPayable, dividendToFund + dividendToFund2, "totalDividendPayable should be total funded");
        assertEq(finalClaimed, claimed + claimed2, "totalDividendClaimed should be total claimed");
    }

    function test_setDividendScaleBySlot_restrictions() public {
        vm.startPrank(tokenAdmin);
        
        // Set up dividend token
        ICTMRWA1Dividend(dividendContract).setDividendToken(address(usdc));
        
        // Test 1: Set dividend scale successfully
        ICTMRWA1Dividend(dividendContract).setDividendScaleBySlot(1, 12);
        
        // Test 2: Try to set dividend scale again for the same slot (should fail)
        vm.expectRevert(abi.encodeWithSelector(ICTMRWA1Dividend.CTMRWA1Dividend_ScaleAlreadySetOrRateSet.selector, 1));
        ICTMRWA1Dividend(dividendContract).setDividendScaleBySlot(1, 15);
        
        // Test 3: Set dividend rate for slot 3
        vm.warp(1 hours);
        ICTMRWA1Dividend(dividendContract).changeDividendRate(3, 100);
        
        // Test 4: Try to set dividend scale for slot 3 after rate has been set (should fail)
        vm.expectRevert(abi.encodeWithSelector(ICTMRWA1Dividend.CTMRWA1Dividend_ScaleAlreadySetOrRateSet.selector, 3));
        ICTMRWA1Dividend(dividendContract).setDividendScaleBySlot(3, 12);
        
        // Test 5: Set dividend scale for a different slot (should succeed)
        ICTMRWA1Dividend(dividendContract).setDividendScaleBySlot(5, 10);
        
        vm.stopPrank();
    }

}
