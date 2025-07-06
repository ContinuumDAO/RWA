// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.19;

import { Test } from "forge-std/Test.sol";
import { console } from "forge-std/console.sol";

import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

import { Helpers } from "../helpers/Helpers.sol";

contract TestDividend is Helpers {
    using Strings for *;

    function test_dividends() public {
        vm.startPrank(admin); // this CTMRWA1 has an admin of admin
        (, address ctmRwaAddr) = CTMRWA1Deploy();
        (uint256 tokenId1, uint256 tokenId2, uint256 tokenId3) = deployAFewTokensLocal(ctmRwaAddr);

        address ctmDividend = ICTMRWA1(ctmRwaAddr).dividendAddr();

        ICTMRWA1Dividend(ctmDividend).setDividendToken(address(usdc));
        address token = ICTMRWA1Dividend(ctmDividend).dividendToken();
        assertEq(token, address(usdc));

        uint256 divRate = ICTMRWA1Dividend(ctmDividend).getDividendRateBySlot(3);
        assertEq(divRate, 0);

        uint256 divRate3 = 2500;
        ICTMRWA1Dividend(ctmDividend).changeDividendRate(3, divRate3);
        divRate = ICTMRWA1Dividend(ctmDividend).getDividendRateBySlot(3);
        assertEq(divRate, divRate3);

        uint256 divRate1 = 8000;
        ICTMRWA1Dividend(ctmDividend).changeDividendRate(1, divRate1);

        uint256 balSlot1 = ICTMRWA1(ctmRwaAddr).totalSupplyInSlot(1);

        uint256 dividend = ICTMRWA1Dividend(ctmDividend).getTotalDividendBySlot(1);
        assertEq(dividend, balSlot1 * divRate1);

        uint256 balSlot3 = ICTMRWA1(ctmRwaAddr).totalSupplyInSlot(3);

        uint256 balSlot5 = ICTMRWA1(ctmRwaAddr).totalSupplyInSlot(5);

        uint256 divRate5 = ICTMRWA1Dividend(ctmDividend).getDividendRateBySlot(5);

        uint256 dividendTotal = ICTMRWA1Dividend(ctmDividend).getTotalDividend();
        assertEq(dividendTotal, balSlot1 * divRate1 + balSlot3 * divRate3 + balSlot5 * divRate5);

        usdc.approve(ctmDividend, dividendTotal);
        uint256 unclaimed = ICTMRWA1Dividend(ctmDividend).fundDividend();
        vm.stopPrank();
        assertEq(unclaimed, dividendTotal);

        vm.stopPrank(); // end of prank admin

        vm.startPrank(user1);
        bool ok = ICTMRWA1Dividend(ctmDividend).claimDividend();
        vm.stopPrank();
        assertEq(ok, true);
        uint256 balAfter = usdc.balanceOf(user1);

        vm.stopPrank();
    }
}
