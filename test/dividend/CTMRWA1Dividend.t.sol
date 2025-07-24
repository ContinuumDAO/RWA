// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.27;

import { Test } from "forge-std/Test.sol";
import { console } from "forge-std/console.sol";

import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { ICTMRWA1Dividend } from "../../src/dividend/ICTMRWA1Dividend.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ICTMRWAMap } from "../../src/shared/ICTMRWAMap.sol";

import { Helpers } from "../helpers/Helpers.sol";

contract TestDividend is Helpers {
    using Strings for *;

    address public dividendContract;

    function setUp() public override {
        super.setUp();
        vm.startPrank(tokenAdmin);
        (ID, token) = _deployCTMRWA1(address(usdc));
        (, dividendContract) = ICTMRWAMap(map).getDividendContract(ID, RWA_TYPE, VERSION);
        (uint256 tokenId1, uint256 tokenId2, uint256 tokenId3) = _deployAFewTokensLocal(address(token), address(usdc), address(map), address(rwa1X), user1);
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
}
