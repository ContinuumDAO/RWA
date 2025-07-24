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
        // _createSomeSlots(ID, address(usdc), address(rwa1X)); // Removed to avoid SlotExists revert
        (uint256 tokenId1, uint256 tokenId2, uint256 tokenId3) = _deployAFewTokensLocal(address(token), address(usdc), address(map), address(rwa1X), user1);
        vm.stopPrank();
    }

    function test_tokenAdmin_can_fundDividend() public {
        vm.startPrank(tokenAdmin);
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
        vm.stopPrank();

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
}
