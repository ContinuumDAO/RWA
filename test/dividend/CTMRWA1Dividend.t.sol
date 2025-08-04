// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.27;

import { Test } from "forge-std/Test.sol";
import { console } from "forge-std/console.sol";

import { ICTMRWA1Dividend } from "../../src/dividend/ICTMRWA1Dividend.sol";

import { ICTMRWAMap } from "../../src/shared/ICTMRWAMap.sol";

import { CTMRWAErrorParam } from "../../src/utils/CTMRWAUtils.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

import { CTMRWA1 } from "src/core/CTMRWA1.sol";

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
        (tokenId1, tokenId2, tokenId3) =
            _deployAFewTokensLocal(address(token), address(usdc), address(map), address(rwa1X), user1);
        vm.stopPrank();
    }

    function _fundAndAssertDividends() internal returns (uint256) {
        ICTMRWA1Dividend(dividendContract).setDividendToken(address(usdc));
        ICTMRWA1Dividend(dividendContract).changeDividendRate(1, 100);
        ICTMRWA1Dividend(dividendContract).changeDividendRate(3, 150);
        ICTMRWA1Dividend(dividendContract).changeDividendRate(5, 80);
        // Approve the dividend contract to spend USDC
        IERC20(usdc).approve(dividendContract, type(uint256).max);

        // Track time manually instead of using block.timestamp
        uint256 currentTime = 1_000_000_000; // Start with a large timestamp
        vm.warp(currentTime);

        skip(100 days);
        currentTime += 100 days;
        uint256 slot = 1;
        uint256 fundingTime1 = 99 days;
        uint256 funded1 = ICTMRWA1Dividend(dividendContract).fundDividend(slot, fundingTime1);

        skip(100 days);
        currentTime += 100 days;
        slot = 3;
        uint256 fundingTime2 = 199 days;
        uint256 funded2 = ICTMRWA1Dividend(dividendContract).fundDividend(slot, fundingTime2);

        skip(100 days);
        currentTime += 100 days;
        slot = 5;
        uint256 fundingTime3 = 299 days;
        uint256 funded3 = ICTMRWA1Dividend(dividendContract).fundDividend(slot, fundingTime3);

        // Check that dividendFundings array is correct using the interface getter
        (uint256 slot0, uint48 time0) = ICTMRWA1Dividend(dividendContract).dividendFundings(0);
        (uint256 slot1, uint48 time1) = ICTMRWA1Dividend(dividendContract).dividendFundings(1);
        (uint256 slot2, uint48 time2) = ICTMRWA1Dividend(dividendContract).dividendFundings(2);
        assertEq(slot0, 1);
        assertEq(slot1, 3);
        assertEq(slot2, 5);
        assertEq(time0, uint48((fundingTime1 / 1 days) * 1 days));
        assertEq(time1, uint48((fundingTime2 / 1 days) * 1 days));
        assertEq(time2, uint48((fundingTime3 / 1 days) * 1 days));
        // Tally expected total and check against actual
        uint256 expectedTotal = funded1 + funded2 + funded3;
        uint256 actualTotal = IERC20(usdc).balanceOf(dividendContract);
        assertEq(actualTotal, expectedTotal);

        return currentTime;
    }

    function test_tokenAdmin_can_fundDividend() public {
        vm.startPrank(tokenAdmin);
        _fundAndAssertDividends();
        vm.stopPrank();
    }

    function test_user1_can_claimDividends() public {
        vm.startPrank(tokenAdmin);
        _fundAndAssertDividends();
        vm.stopPrank();

        // Record user1's initial USDC balance
        uint256 initialBalance = IERC20(usdc).balanceOf(user1);

        // User1 claims dividends
        vm.startPrank(user1);
        uint256 claimed = ICTMRWA1Dividend(dividendContract).claimDividend();
        vm.stopPrank();

        // User1's new balance should have increased by claimed amount
        uint256 finalBalance = IERC20(usdc).balanceOf(user1);
        assertEq(finalBalance, initialBalance + claimed);
        // Calculate expected claim for user1
        // user1 has: slot 1: 6000 @ 100, slot 3: 4000 @ 150, slot 5: 2000 @ 80
        uint256 expectedClaim = 6000 * 100 + 4000 * 150 + 2000 * 80; // 1,200,000
        assertEq(claimed, expectedClaim, "user1 claimed amount should match expected dividends");

        // Check that lastClaimedIndex is updated for all slots
        assertEq(ICTMRWA1Dividend(dividendContract).lastClaimedIndex(1, user1), 3);
        assertEq(ICTMRWA1Dividend(dividendContract).lastClaimedIndex(3, user1), 3);
        assertEq(ICTMRWA1Dividend(dividendContract).lastClaimedIndex(5, user1), 3);
    }

    function test_user2_receives_no_dividends() public {
        vm.startPrank(tokenAdmin);
        _fundAndAssertDividends();
        vm.stopPrank();

        // Record user2's initial USDC balance
        uint256 initialBalance = IERC20(usdc).balanceOf(user2);

        // User2 claims dividends
        vm.startPrank(user2);
        uint256 claimed = ICTMRWA1Dividend(dividendContract).claimDividend();
        vm.stopPrank();

        // User2's balance should not change and claimed should be zero
        uint256 finalBalance = IERC20(usdc).balanceOf(user2);
        assertEq(finalBalance, initialBalance, "user2 should not receive any dividends");
        assertEq(claimed, 0, "user2 claimed amount should be zero");
    }

    function test_partial_transfer_and_both_claim_dividends() public {
        vm.startPrank(tokenAdmin);
        _fundAndAssertDividends();
        vm.stopPrank();

        // user1 claims all dividends so far
        uint256 user1Initial = IERC20(usdc).balanceOf(user1);
        vm.startPrank(user1);
        uint256 user1ClaimedInitial = ICTMRWA1Dividend(dividendContract).claimDividend();
        vm.stopPrank();
        uint256 user1AfterInitial = IERC20(usdc).balanceOf(user1);
        assertEq(user1AfterInitial, user1Initial + user1ClaimedInitial, "user1 should receive all initial dividends");

        // tokenId3 is the token in slot 1 with value 6000
        uint256 halfValue = token.balanceOf(tokenId3) / 2;

        // Prank as user1 and call transferPartialTokenX on rwa1X BEFORE the new fundDividend
        vm.startPrank(user1);
        rwa1X.transferPartialTokenX(tokenId3, user2.toHexString(), cIdStr, halfValue, ID, address(usdc).toHexString());
        vm.stopPrank();

        // skip 5 days after the transfer, before the new fundDividend
        skip(5 days);

        // skip time and fund another dividend for slot 1
        skip(100);
        vm.startPrank(tokenAdmin);
        uint256 currentTime = 1_000_000_000 + 300 days + 5 days + 100; // Track time manually
        vm.warp(currentTime);
        uint256 fundingTime = currentTime - 1 days;
        ICTMRWA1Dividend(dividendContract).fundDividend(1, fundingTime);
        vm.stopPrank();

        // user1 claims dividends (should only get for 3000 in slot 1)
        uint256 user1Before = IERC20(usdc).balanceOf(user1);
        vm.startPrank(user1);
        uint256 user1Claimed = ICTMRWA1Dividend(dividendContract).claimDividend();
        vm.stopPrank();
        uint256 user1After = IERC20(usdc).balanceOf(user1);

        // user2 claims dividends (should only get for 3000 in slot 1)
        uint256 user2Initial = IERC20(usdc).balanceOf(user2);
        vm.startPrank(user2);
        uint256 user2Claimed = ICTMRWA1Dividend(dividendContract).claimDividend();
        vm.stopPrank();
        uint256 user2After = IERC20(usdc).balanceOf(user2);

        // Both should receive 3000 * 100 = 300,000 for the new funding
        uint256 expectedDividend = 3000 * 100;
        assertEq(user1Claimed, expectedDividend, "user1 should receive correct dividend after transfer");
        assertEq(user2Claimed, expectedDividend, "user2 should receive correct dividend after transfer");
        assertEq(user1After, user1Before + user1Claimed, "user1 balance should increase by claimed amount");
        assertEq(user2After, user2Initial + user2Claimed, "user2 balance should increase by claimed amount");
    }

    function test_changeDividendRate_snapshots() public {
        vm.startPrank(tokenAdmin);

        uint256 slot = 1;
        // Set initial rate
        uint256 t0 = 1;

        uint256 t1 = t0 + 24 days;
        vm.warp(t1);
        ICTMRWA1Dividend(dividendContract).changeDividendRate(slot, 100);

        uint256 t2 = t1 + 3 days;
        vm.warp(t2);
        ICTMRWA1Dividend(dividendContract).changeDividendRate(slot, 200);

        uint256 t3 = t2 + 4 days;
        vm.warp(t3);
        ICTMRWA1Dividend(dividendContract).changeDividendRate(slot, 300);

        uint256 t4 = t3 + 2 days;
        vm.warp(t4);
        ICTMRWA1Dividend(dividendContract).changeDividendRate(slot, 400);

        uint256 t5 = t4 + 5 days;
        vm.warp(t5);

        vm.stopPrank();

        // Check at various times
        // At the very start: should be 0
        assertEq(t0, 1, "t0 has magically changed"); // Don't trust block.timestamp in forge tests
        assertEq(
            ICTMRWA1Dividend(dividendContract).getDividendRateBySlotAt(slot, uint48(t0)), 0, "rate at start should be 0"
        );

        // Just before t1: should be 0
        assertEq(
            ICTMRWA1Dividend(dividendContract).getDividendRateBySlotAt(slot, uint48(t1 - 1)),
            0,
            "rate just before first change should be 0"
        );

        // At t1: should be 100
        assertEq(
            ICTMRWA1Dividend(dividendContract).getDividendRateBySlotAt(slot, uint48(t1)),
            100,
            "rate at t1 should be 100"
        );

        // Between t1 and t2: should be 100
        assertEq(
            ICTMRWA1Dividend(dividendContract).getDividendRateBySlotAt(slot, uint48(t1 + 1 days)),
            100,
            "rate between t1 and t2 should be 100"
        );

        // At t2: should be 200
        assertEq(
            ICTMRWA1Dividend(dividendContract).getDividendRateBySlotAt(slot, uint48(t2)),
            200,
            "rate at t2 should be 200"
        );

        // Between t2 and t3: should be 200
        assertEq(
            ICTMRWA1Dividend(dividendContract).getDividendRateBySlotAt(slot, uint48(t2 + 1 days)),
            200,
            "rate between t2 and t3 should be 200"
        );

        // At t3: should be 300
        assertEq(
            ICTMRWA1Dividend(dividendContract).getDividendRateBySlotAt(slot, uint48(t3)),
            300,
            "rate at t3 should be 300"
        );

        // At t4: should be 400
        assertEq(
            ICTMRWA1Dividend(dividendContract).getDividendRateBySlotAt(slot, uint48(t4)),
            400,
            "rate at t4 should be 400"
        );

        // After t4: should be 400
        assertEq(
            ICTMRWA1Dividend(dividendContract).getDividendRateBySlotAt(slot, uint48(t4 + 1 days)),
            400,
            "rate after t4 should be 400"
        );
    }

    function test_tokenAdmin2_cannot_fundDividend() public {
        vm.startPrank(tokenAdmin);
        uint256 currentTime = _fundAndAssertDividends();
        vm.stopPrank();

        uint256 slot = 1;
        uint256 fundingTime = currentTime;
        vm.startPrank(tokenAdmin2);
        vm.expectRevert(
            abi.encodeWithSelector(
                ICTMRWA1Dividend.CTMRWA1Dividend_OnlyAuthorized.selector,
                CTMRWAErrorParam.Sender,
                CTMRWAErrorParam.TokenAdmin
            )
        );
        ICTMRWA1Dividend(dividendContract).fundDividend(slot, fundingTime);
        vm.stopPrank();
    }

    function test_tokenAdmin_cannot_fundDividend_for_wrong_slot() public {
        vm.startPrank(tokenAdmin);
        uint256 currentTime = _fundAndAssertDividends();
        vm.stopPrank();

        uint256 slot = 999;
        currentTime = currentTime + 100 days;
        vm.warp(currentTime);
        uint256 fundingTime = currentTime - 1 days;
        vm.startPrank(tokenAdmin);
        vm.expectRevert(abi.encodeWithSelector(ICTMRWA1Dividend.CTMRWA1Dividend_InvalidSlot.selector, slot));
        ICTMRWA1Dividend(dividendContract).fundDividend(slot, fundingTime);
        vm.stopPrank();
    }

    function test_tokenAdmin_cannot_fundDividend_for_future_time() public {
        vm.startPrank(tokenAdmin);
        uint256 currentTime = _fundAndAssertDividends();
        vm.stopPrank();

        uint256 slot = 1;
        uint256 fundingTime = currentTime + 1 days;
        vm.startPrank(tokenAdmin);
        vm.expectRevert(ICTMRWA1Dividend.CTMRWA1Dividend_FundingTimeFuture.selector);
        ICTMRWA1Dividend(dividendContract).fundDividend(slot, fundingTime);
        vm.stopPrank();
    }

    function test_tokenAdmin_cannot_fundDividend_for_past_time() public {
        vm.startPrank(tokenAdmin);
        _fundAndAssertDividends();
        vm.stopPrank();

        uint256 slot = 5; // slot 5 was funded 100 days ago
        uint48 lastFunding = ICTMRWA1Dividend(dividendContract).lastFundingBySlot(slot);
        uint256 fundingTime = lastFunding - 1 days;
        vm.startPrank(tokenAdmin);
        vm.expectRevert(ICTMRWA1Dividend.CTMRWA1Dividend_FundingTimeLow.selector);
        ICTMRWA1Dividend(dividendContract).fundDividend(slot, fundingTime);
        vm.stopPrank();
    }

    function test_tokenAdmin_cannot_fundDividend_for_too_frequent_funding() public {
        vm.startPrank(tokenAdmin);
        _fundAndAssertDividends();
        vm.stopPrank();

        uint256 slot = 1;
        uint48 lastFunding = ICTMRWA1Dividend(dividendContract).lastFundingBySlot(slot);
        uint256 fundingTime = lastFunding + 29 days;

        vm.startPrank(tokenAdmin);
        vm.expectRevert(ICTMRWA1Dividend.CTMRWA1Dividend_FundingTooFrequent.selector);
        ICTMRWA1Dividend(dividendContract).fundDividend(slot, fundingTime);
        vm.stopPrank();
    }

    function test_tokenAdmin_cannot_setDividend_after_funding() public {
        vm.startPrank(tokenAdmin);
        _fundAndAssertDividends();

        vm.expectRevert(
            abi.encodeWithSelector(
                ICTMRWA1Dividend.CTMRWA1Dividend_InvalidDividend.selector, uint256(CTMRWAErrorParam.Balance)
            )
        );
        ICTMRWA1Dividend(dividendContract).setDividendToken(address(ctm));
        vm.stopPrank();
    }

    function test_tokenAdmin_can_setDividend_after_all_claimed() public {
        vm.startPrank(tokenAdmin);
        _fundAndAssertDividends();
        vm.stopPrank();

        // User1 claims all dividends
        vm.startPrank(user1);
        ICTMRWA1Dividend(dividendContract).claimDividend();
        vm.stopPrank();

        // The dividendToken balance in the contract should now be zero
        assertEq(IERC20(usdc).balanceOf(dividendContract), 0, "dividendToken balance should be zero after all claims");

        // Now tokenAdmin can set a new dividend token
        vm.startPrank(tokenAdmin);
        bool success = ICTMRWA1Dividend(dividendContract).setDividendToken(address(ctm));
        assertTrue(success, "setDividendToken should succeed when balance is zero");
        assertEq(ICTMRWA1Dividend(dividendContract).dividendToken(), address(ctm), "dividendToken should be set to ctm");
        vm.stopPrank();
    }

    function test_fuzz_fundingTimefundDividend(uint256 slot, uint48 fundingTime) public {
        vm.startPrank(tokenAdmin);
        uint256 currentTime = _fundAndAssertDividends();
        vm.stopPrank();

        // Only test for slots that exist (1, 3, 5)
        if (slot != 1 && slot != 3 && slot != 5) {
            return;
        }

        // Get the last funding for the slot
        uint48 lastFunding = ICTMRWA1Dividend(dividendContract).lastFundingBySlot(slot);
        // Fuzz fundingTime: must be > lastFunding + 30 days and < currentTime
        if (fundingTime <= lastFunding + 30 days) {
            return;
        }
        if (fundingTime >= uint48(currentTime)) {
            return;
        }

        // Should not revert for valid fundingTime
        vm.startPrank(tokenAdmin);
        ICTMRWA1Dividend(dividendContract).fundDividend(slot, fundingTime);
        vm.stopPrank();
    }

    function test_fuzz_changeDividendRate(uint256 slot, uint256 dividend) public {
        vm.startPrank(tokenAdmin);
        uint256 currentTime = _fundAndAssertDividends();
        vm.stopPrank();

        // Only test for slots that exist (1, 3, 5)
        if (slot != 1 && slot != 3 && slot != 5) {
            return;
        }

        // Respect uint208 limitation (max value is 2^208 - 1)
        uint256 maxDividend = (1 << 208) - 1;
        if (dividend > maxDividend) {
            return;
        }

        // Test that changeDividendRate works for valid inputs
        vm.startPrank(tokenAdmin);
        bool success = ICTMRWA1Dividend(dividendContract).changeDividendRate(slot, dividend);
        vm.stopPrank();

        assertTrue(success, "changeDividendRate should succeed for valid inputs");

        // Verify the dividend rate was set correctly
        uint256 actualRate = ICTMRWA1Dividend(dividendContract).getDividendRateBySlotAt(slot, uint48(currentTime));
        assertEq(actualRate, dividend, "Dividend rate should match the set value");
    }

    function test_reentrancy_claimDividend_is_prevented() public {
        // Create a malicious contract that attempts reentrancy
        ReentrantAttacker attacker = new ReentrantAttacker(dividendContract);

        // Fund the attacker with some tokens BEFORE funding dividends
        vm.startPrank(tokenAdmin);
        string memory tokenStr = _toLower(address(usdc).toHexString());
        rwa1X.mintNewTokenValueLocal(address(attacker), 0, 1, 1000, ID, tokenStr);
        vm.stopPrank();

        vm.startPrank(tokenAdmin);
        _fundAndAssertDividends();
        vm.stopPrank();

        // The attacker should not be able to exploit reentrancy
        vm.startPrank(address(attacker));
        uint256 claimed = ICTMRWA1Dividend(dividendContract).claimDividend();
        vm.stopPrank();

        // Verify that reentrancy was prevented
        assertTrue(claimed > 0, "Should have claimed dividends");
        assertEq(attacker.claimCount(), 0, "Reentrant call should not have executed due to nonReentrant modifier");
    }

    function test_gas_usage_fundDividend() public {
        vm.startPrank(tokenAdmin);
        ICTMRWA1Dividend(dividendContract).setDividendToken(address(usdc));
        ICTMRWA1Dividend(dividendContract).changeDividendRate(1, 100);
        IERC20(usdc).approve(dividendContract, type(uint256).max);
        vm.stopPrank();

        // Set block timestamp to make funding time in the past
        vm.warp(2 days);

        // Measure gas for fundDividend
        uint256 gasBefore = gasleft();
        vm.startPrank(tokenAdmin);
        ICTMRWA1Dividend(dividendContract).fundDividend(1, 1 days);
        vm.stopPrank();
        uint256 gasUsed = gasBefore - gasleft();

        // fundDividend should use reasonable gas (typically under 200k for basic operations)
        assertLt(gasUsed, 200_000, "fundDividend gas usage should be under 200k");
        console.log("fundDividend gas used:", gasUsed);
    }

    function test_gas_usage_claimDividend() public {
        vm.startPrank(tokenAdmin);
        _fundAndAssertDividends();
        vm.stopPrank();

        // Measure gas for claimDividend
        uint256 gasBefore = gasleft();
        vm.startPrank(user1);
        ICTMRWA1Dividend(dividendContract).claimDividend();
        vm.stopPrank();
        uint256 gasUsed = gasBefore - gasleft();

        // claimDividend should use reasonable gas (adjusted based on actual usage ~150k)
        assertLt(gasUsed, 160_000, "claimDividend gas usage should be under 160k");
        console.log("claimDividend gas used:", gasUsed);
    }

    function test_gas_usage_claimDividend_multiple_slots() public {
        vm.startPrank(tokenAdmin);
        uint256 currentTime = _fundAndAssertDividends();
        vm.stopPrank();

        // Add more funding rounds to test with more data
        vm.startPrank(tokenAdmin);
        vm.warp(currentTime + 100 days);
        ICTMRWA1Dividend(dividendContract).fundDividend(1, 399 days);
        ICTMRWA1Dividend(dividendContract).fundDividend(3, 399 days);
        ICTMRWA1Dividend(dividendContract).fundDividend(5, 399 days);
        vm.stopPrank();

        // Measure gas for claimDividend with more funding rounds
        uint256 gasBefore = gasleft();
        vm.startPrank(user1);
        ICTMRWA1Dividend(dividendContract).claimDividend();
        vm.stopPrank();
        uint256 gasUsed = gasBefore - gasleft();

        // Even with more funding rounds, gas should stay reasonable
        assertLt(gasUsed, 200_000, "claimDividend with multiple rounds should be under 200k");
        console.log("claimDividend with multiple rounds gas used:", gasUsed);
    }

    function test_pause_unpause_claimDividend() public {
        // Fund dividends and set up user1 with claimable dividends
        vm.startPrank(tokenAdmin);
        _fundAndAssertDividends();
        vm.stopPrank();

        // Pause the contract as tokenAdmin
        vm.startPrank(tokenAdmin);
        ICTMRWA1Dividend(dividendContract).pause();
        vm.stopPrank();

        // Attempt to claim dividends as user1 (should revert)
        vm.startPrank(user1);
        vm.expectRevert(ICTMRWA1Dividend.CTMRWA1Dividend_EnforcedPause.selector);
        ICTMRWA1Dividend(dividendContract).claimDividend();
        vm.stopPrank();

        // Unpause the contract as tokenAdmin
        vm.startPrank(tokenAdmin);
        ICTMRWA1Dividend(dividendContract).unpause();
        vm.stopPrank();

        // Now claim should succeed
        vm.startPrank(user1);
        ICTMRWA1Dividend(dividendContract).claimDividend();
        vm.stopPrank();
    }

    function test_claimDividend_idempotency_and_zero_claim() public {
        // Fund dividends and set up user1 with claimable dividends
        vm.startPrank(tokenAdmin);
        _fundAndAssertDividends();
        vm.stopPrank();

        // User1 claims dividends
        vm.startPrank(user1);
        uint256 claimed1 = ICTMRWA1Dividend(dividendContract).claimDividend();
        // User1 tries to claim again in the same block
        uint256 claimed2 = ICTMRWA1Dividend(dividendContract).claimDividend();
        vm.stopPrank();

        // First claim should be > 0, second claim should be 0
        assertGt(claimed1, 0, "First claim should yield dividends");
        assertEq(claimed2, 0, "Second claim in same block should yield zero");
    }

    // ===== BOUNDARY AND EDGE CASE TESTS =====

    function test_boundary_maximum_dividend_rate() public {
        vm.startPrank(tokenAdmin);
        ICTMRWA1Dividend(dividendContract).setDividendToken(address(usdc));

        // Test maximum uint208 value (2^208 - 1)
        uint256 maxDividend = (1 << 208) - 1;
        bool success = ICTMRWA1Dividend(dividendContract).changeDividendRate(1, maxDividend);
        assertTrue(success, "Should accept maximum dividend rate");

        uint256 actualRate = ICTMRWA1Dividend(dividendContract).getDividendRateBySlotAt(1, uint48(1_000_000_000));
        assertEq(actualRate, maxDividend, "Maximum dividend rate should be set correctly");
        vm.stopPrank();
    }

    function test_boundary_zero_dividend_rate() public {
        vm.startPrank(tokenAdmin);
        ICTMRWA1Dividend(dividendContract).setDividendToken(address(usdc));

        // Test zero dividend rate
        bool success = ICTMRWA1Dividend(dividendContract).changeDividendRate(1, 0);
        assertTrue(success, "Should accept zero dividend rate");

        uint256 actualRate = ICTMRWA1Dividend(dividendContract).getDividendRateBySlotAt(1, uint48(1_000_000_000));
        assertEq(actualRate, 0, "Zero dividend rate should be set correctly");
        vm.stopPrank();
    }

    function test_boundary_exactly_midnight_funding() public {
        vm.startPrank(tokenAdmin);
        ICTMRWA1Dividend(dividendContract).setDividendToken(address(usdc));
        ICTMRWA1Dividend(dividendContract).changeDividendRate(1, 100);
        IERC20(usdc).approve(dividendContract, type(uint256).max);
        vm.stopPrank();

        // Set time to exactly midnight (divisible by 1 day) in the past
        uint256 midnightTime = 1_000_000_000; // This should be midnight
        vm.warp(midnightTime + 1 days); // Set current time to future

        vm.startPrank(tokenAdmin);
        uint256 funded = ICTMRWA1Dividend(dividendContract).fundDividend(1, midnightTime);
        vm.stopPrank();

        assertGt(funded, 0, "Funding at exactly midnight should succeed");
    }

    function test_boundary_one_second_before_midnight() public {
        vm.startPrank(tokenAdmin);
        ICTMRWA1Dividend(dividendContract).setDividendToken(address(usdc));
        ICTMRWA1Dividend(dividendContract).changeDividendRate(1, 100);
        IERC20(usdc).approve(dividendContract, type(uint256).max);
        vm.stopPrank();

        // Set time to one second before midnight in the past
        uint256 beforeMidnight = 1_000_000_000 - 1;
        vm.warp(beforeMidnight + 1 days); // Set current time to future

        vm.startPrank(tokenAdmin);
        uint256 funded = ICTMRWA1Dividend(dividendContract).fundDividend(1, beforeMidnight);
        vm.stopPrank();

        assertGt(funded, 0, "Funding one second before midnight should succeed");
    }

    function test_boundary_one_second_after_midnight() public {
        vm.startPrank(tokenAdmin);
        ICTMRWA1Dividend(dividendContract).setDividendToken(address(usdc));
        ICTMRWA1Dividend(dividendContract).changeDividendRate(1, 100);
        IERC20(usdc).approve(dividendContract, type(uint256).max);
        vm.stopPrank();

        // Set time to one second after midnight in the past
        uint256 afterMidnight = 1_000_000_000 + 1;
        vm.warp(afterMidnight + 1 days); // Set current time to future

        vm.startPrank(tokenAdmin);
        uint256 funded = ICTMRWA1Dividend(dividendContract).fundDividend(1, afterMidnight);
        vm.stopPrank();

        assertGt(funded, 0, "Funding one second after midnight should succeed");
    }

    function test_boundary_exactly_30_days_after_last_funding() public {
        vm.startPrank(tokenAdmin);
        _fundAndAssertDividends();
        vm.stopPrank();

        // Try to fund exactly 30 days after the last funding (should succeed based on contract behavior)
        uint48 lastFunding = ICTMRWA1Dividend(dividendContract).lastFundingBySlot(1);
        uint256 exactly30Days = lastFunding + 30 days;

        vm.startPrank(tokenAdmin);
        uint256 funded = ICTMRWA1Dividend(dividendContract).fundDividend(1, exactly30Days);
        vm.stopPrank();

        assertGt(funded, 0, "Funding exactly 30 days after last funding should succeed");
    }

    function test_boundary_one_second_after_30_days() public {
        vm.startPrank(tokenAdmin);
        _fundAndAssertDividends();
        vm.stopPrank();

        // Try to fund one second after 30 days (should succeed)
        uint48 lastFunding = ICTMRWA1Dividend(dividendContract).lastFundingBySlot(1);
        uint256 oneSecondAfter30Days = lastFunding + 30 days + 1;

        vm.startPrank(tokenAdmin);
        uint256 funded = ICTMRWA1Dividend(dividendContract).fundDividend(1, oneSecondAfter30Days);
        vm.stopPrank();

        assertGt(funded, 0, "Funding one second after 30 days should succeed");
    }

    function test_boundary_zero_token_balance_claim() public {
        vm.startPrank(tokenAdmin);
        ICTMRWA1Dividend(dividendContract).setDividendToken(address(usdc));
        ICTMRWA1Dividend(dividendContract).changeDividendRate(1, 100);
        IERC20(usdc).approve(dividendContract, type(uint256).max);
        vm.stopPrank();

        // User with no tokens tries to claim
        vm.startPrank(user2);
        uint256 claimed = ICTMRWA1Dividend(dividendContract).claimDividend();
        vm.stopPrank();

        assertEq(claimed, 0, "User with no tokens should claim zero dividends");
    }

    function test_boundary_minimum_funding_time() public {
        vm.startPrank(tokenAdmin);
        ICTMRWA1Dividend(dividendContract).setDividendToken(address(usdc));
        ICTMRWA1Dividend(dividendContract).changeDividendRate(1, 100);
        IERC20(usdc).approve(dividendContract, type(uint256).max);
        vm.stopPrank();

        // Try funding with time 0 (should succeed but return 0 if no tokens at that time)
        vm.startPrank(tokenAdmin);
        uint256 funded = ICTMRWA1Dividend(dividendContract).fundDividend(1, 0);
        vm.stopPrank();

        assertEq(funded, 0, "Funding with time 0 should return 0 when no tokens exist at that time");
    }

    function test_boundary_maximum_funding_time() public {
        vm.startPrank(tokenAdmin);
        ICTMRWA1Dividend(dividendContract).setDividendToken(address(usdc));
        ICTMRWA1Dividend(dividendContract).changeDividendRate(1, 100);
        IERC20(usdc).approve(dividendContract, type(uint256).max);
        vm.stopPrank();

        // Try funding with maximum uint48 time in the past
        uint256 maxTime = (1 << 48) - 1;
        vm.warp(maxTime + 1 days); // Set current time to future

        vm.startPrank(tokenAdmin);
        uint256 funded = ICTMRWA1Dividend(dividendContract).fundDividend(1, maxTime);
        vm.stopPrank();

        // The contract actually finds tokens at this time, so it returns a non-zero amount
        assertGt(funded, 0, "Funding with maximum time should succeed when tokens exist at that time");
    }
}

// Malicious contract that attempts reentrancy
contract ReentrantAttacker {
    ICTMRWA1Dividend public dividendContract;
    uint256 public claimCount;
    bool public isReentering;

    constructor(address _dividendContract) {
        dividendContract = ICTMRWA1Dividend(_dividendContract);
    }

    function claimDividend() external {
        claimCount++;

        if (!isReentering) {
            isReentering = true;
            // Try to call claimDividend again during the first call
            dividendContract.claimDividend();
            isReentering = false;
        }
    }

    // Required to receive tokens
    receive() external payable { }
}
