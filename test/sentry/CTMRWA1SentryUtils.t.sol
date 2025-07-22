// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.27;

import { CTMRWA1Sentry } from "../../src/sentry/CTMRWA1Sentry.sol";
import { ICTMRWA1SentryUtils } from "../../src/sentry/ICTMRWA1SentryUtils.sol";
import { Address } from "../../src/utils/CTMRWAUtils.sol";
import { Helpers } from "../helpers/Helpers.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { Test } from "forge-std/Test.sol";
import { console } from "forge-std/console.sol";

contract CTMRWA1SentryUtilsTest is Helpers {
    using Strings for *;

    function setUp() public override {
        super.setUp();
        // All helpers and contracts are deployed, including sentryUtils, sentryManager, map, etc.
    }

    function test_OnlySentryManagerCanSentryC3Fallback() public {
        bytes4 selector = bytes4(keccak256("test()"));
        bytes memory data = "";
        bytes memory reason = "test reason";
        // Should succeed as sentryManager
        vm.prank(address(sentryManager));
        bool result = sentryUtils.sentryC3Fallback(selector, data, reason);
        assertTrue(result);
        // Should fail for non-sentryManager
        vm.prank(address(0xBEEF));
        vm.expectRevert(
            abi.encodeWithSelector(ICTMRWA1SentryUtils.CTMRWA1SentryUtils_Unauthorized.selector, Address.Sender)
        );
        sentryUtils.sentryC3Fallback(selector, data, reason);
    }

    function test_SentryC3Fallback_UpdatesLastSelectorDataReason() public {
        bytes4 selector = bytes4(keccak256("test()"));
        bytes memory data = "test data";
        bytes memory reason = "test reason";
        vm.prank(address(sentryManager));
        sentryUtils.sentryC3Fallback(selector, data, reason);
        assertEq(sentryUtils.lastSelector(), selector);
        assertEq(sentryUtils.lastData(), data);
        assertEq(sentryUtils.lastReason(), reason);
    }

    function test_SentryC3Fallback_EmitsLogFallback() public {
        bytes4 selector = bytes4(keccak256("test()"));
        bytes memory data = "test data";
        bytes memory reason = "test reason";
        vm.expectEmit(true, true, true, true);
        emit ICTMRWA1SentryUtils.LogFallback(selector, data, reason);
        vm.prank(address(sentryManager));
        sentryUtils.sentryC3Fallback(selector, data, reason);
    }

    function test_GetLastReason() public {
        bytes4 selector = bytes4(keccak256("test()"));
        bytes memory data = "test data";
        string memory reason = "test reason string";
        bytes memory reasonBytes = bytes(reason);
        vm.prank(address(sentryManager));
        sentryUtils.sentryC3Fallback(selector, data, reasonBytes);
        string memory retrievedReason = sentryUtils.getLastReason();
        assertEq(retrievedReason, reason);
    }

    function test_FuzzSentryC3Fallback(bytes4 selector, bytes memory data, bytes memory reason) public {
        vm.prank(address(sentryManager));
        bool result = sentryUtils.sentryC3Fallback(selector, data, reason);
        assertTrue(result);
    }

    function test_gasUsage_sentryC3Fallback() public {
        bytes4 selector = bytes4(keccak256("test()"));
        bytes memory data = "test data";
        bytes memory reason = "test reason";
        vm.prank(address(sentryManager));
        uint256 gasBefore = gasleft();
        bool result = sentryUtils.sentryC3Fallback(selector, data, reason);
        uint256 gasUsed = gasBefore - gasleft();
        assertTrue(gasUsed < 500_000, string.concat("Gas used: ", vm.toString(gasUsed)));
        assertTrue(result);
    }
}
