// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.22;

import { Test } from "forge-std/Test.sol";
import { console } from "forge-std/console.sol";

import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

import { Helpers } from "../helpers/Helpers.sol";

import { FeeType, IFeeManager } from "../../src/managers/IFeeManager.sol";

contract TestFeeManager is Helpers {
    using Strings for *;

    function test_feeManager() public {
        address[] memory feeTokenList = feeManager.getFeeTokenList();
        assertEq(feeTokenList[0], address(ctm));
        assertEq(feeTokenList[1], address(usdc));

        string memory tokenStr = address(usdc).toHexString();

        uint256 fee = feeManager.getXChainFee(_stringToArray("1"), false, FeeType.TX, tokenStr);

        assertEq(fee, 1000);

        fee = fee * 10 ** usdc.decimals() / 100;

        vm.startPrank(user1);
        usdc.approve(address(feeManager), 10000000);
        uint256 initBal = usdc.balanceOf(address(user1));
        uint256 feePaid = feeManager.payFee(fee, tokenStr);
        uint256 endBal = usdc.balanceOf(address(user1));
        assertEq(initBal - feePaid, endBal);
        vm.stopPrank();

        vm.startPrank(gov);
        uint256 initialTreasuryBal = usdc.balanceOf(address(treasury));
        feeManager.withdrawFee(tokenStr, endBal, treasury.toHexString());
        uint256 treasuryBal = usdc.balanceOf(address(treasury));
        assertEq(treasuryBal - initialTreasuryBal, feePaid);
        vm.stopPrank();

        vm.startPrank(gov);
        feeTokenList = feeManager.getFeeTokenList();
        assertEq(feeTokenList.length, 2);
        feeManager.delFeeToken(tokenStr);
        feeTokenList = feeManager.getFeeTokenList();
        assertEq(feeTokenList.length, 1);
        assertEq(feeTokenList[0], address(ctm));
        vm.stopPrank();
    }
}
