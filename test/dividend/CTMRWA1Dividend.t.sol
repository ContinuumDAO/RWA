// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.27;

import { Test } from "forge-std/Test.sol";
import { console } from "forge-std/console.sol";

import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { ICTMRWA1Dividend } from "../../src/dividend/ICTMRWA1Dividend.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ICTMRWAMap } from "../../src/shared/ICTMRWAMap.sol";
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
        (tokenId1, tokenId2, tokenId3) = _deployAFewTokensLocal(address(token), address(usdc), address(map), address(rwa1X), user1);
        vm.stopPrank();
    }

    function _fundAndAssertDividends() internal {
        ICTMRWA1Dividend(dividendContract).setDividendToken(address(usdc));
        ICTMRWA1Dividend(dividendContract).changeDividendRate(1, 100);
        ICTMRWA1Dividend(dividendContract).changeDividendRate(3, 150);
        ICTMRWA1Dividend(dividendContract).changeDividendRate(5, 80);
        // Approve the dividend contract to spend USDC
        IERC20(usdc).approve(dividendContract, type(uint256).max);
        
        skip(100 days);
        uint256 slot = 1;
        uint256 fundingTime1 = block.timestamp - 1 days;
        uint256 funded1 = ICTMRWA1Dividend(dividendContract).fundDividend(slot, fundingTime1);

        skip(100 days);
        slot = 3;
        uint256 fundingTime2 = block.timestamp - 1 days;
        uint256 funded2 = ICTMRWA1Dividend(dividendContract).fundDividend(slot, fundingTime2);

        skip(100 days);
        slot = 5;
        uint256 fundingTime3 = block.timestamp - 1 days;
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
        rwa1X.transferPartialTokenX(
            tokenId3,
            user2.toHexString(),
            cIdStr,
            halfValue,
            ID,
            address(usdc).toHexString()
        );
        vm.stopPrank();

        // skip 5 days after the transfer, before the new fundDividend
        skip(5 days);

        // skip time and fund another dividend for slot 1
        skip(100);
        vm.startPrank(tokenAdmin);
        uint256 fundingTime = block.timestamp - 1 days;
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
        skip(24 days);
        ICTMRWA1Dividend(dividendContract).changeDividendRate(slot, 100);
        uint256 t1 = block.timestamp;
        console.log("t1:", t1);
        skip(3 days);
        ICTMRWA1Dividend(dividendContract).changeDividendRate(slot, 200);
        uint256 t2 = block.timestamp;
        console.log("t2:", t2);
        skip(4 days);
        ICTMRWA1Dividend(dividendContract).changeDividendRate(slot, 300);
        uint256 t3 = block.timestamp;
        console.log("t3:", t3);
        skip(2 days);
        ICTMRWA1Dividend(dividendContract).changeDividendRate(slot, 400);
        uint256 t4 = block.timestamp;
        console.log("t4:", t4);
        vm.stopPrank();

        // Check at various times
        // At the very start: should be 0
        console.log("start (1):", 1);
        assertEq(ICTMRWA1Dividend(dividendContract).getDividendRateBySlotAt(slot, 1), 0, "rate at start should be 0");
        // Just before t1: should be 0
        console.log("t1 - 1:", t1 - 1);
        assertEq(ICTMRWA1Dividend(dividendContract).getDividendRateBySlotAt(slot, uint48(t1 - 1)), 0, "rate before first change should be 0");
        // At t1: should be 100
        console.log("t1:", t1);
        assertEq(ICTMRWA1Dividend(dividendContract).getDividendRateBySlotAt(slot, uint48(t1)), 100, "rate at t1 should be 100");
        // Between t1 and t2: should be 100
        console.log("t1 + 1 days:", t1 + 1 days);
        assertEq(ICTMRWA1Dividend(dividendContract).getDividendRateBySlotAt(slot, uint48(t1 + 1 days)), 100, "rate between t1 and t2 should be 100");
        // At t2: should be 200
        console.log("t2:", t2);
        assertEq(ICTMRWA1Dividend(dividendContract).getDividendRateBySlotAt(slot, uint48(t2)), 200, "rate at t2 should be 200");
        // Between t2 and t3: should be 200
        console.log("t2 + 1 days:", t2 + 1 days);
        assertEq(ICTMRWA1Dividend(dividendContract).getDividendRateBySlotAt(slot, uint48(t2 + 1 days)), 200, "rate between t2 and t3 should be 200");
        // At t3: should be 300
        console.log("t3:", t3);
        assertEq(ICTMRWA1Dividend(dividendContract).getDividendRateBySlotAt(slot, uint48(t3)), 300, "rate at t3 should be 300");
        // At t4: should be 400
        console.log("t4:", t4);
        assertEq(ICTMRWA1Dividend(dividendContract).getDividendRateBySlotAt(slot, uint48(t4)), 400, "rate at t4 should be 400");
        // After t4: should be 400
        console.log("t4 + 1 days:", t4 + 1 days);
        assertEq(ICTMRWA1Dividend(dividendContract).getDividendRateBySlotAt(slot, uint48(t4 + 1 days)), 400, "rate after t4 should be 400");
    }
}
