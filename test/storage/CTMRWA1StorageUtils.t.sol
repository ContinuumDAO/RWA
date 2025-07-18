// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.27;

import { Test } from "forge-std/Test.sol";
import { console } from "forge-std/console.sol";
import { Helpers } from "../helpers/Helpers.sol";
import { ICTMRWA1StorageUtils } from "../../src/storage/ICTMRWA1StorageUtils.sol";
import { Address } from "../../src/CTMRWAUtils.sol";
import { CTMRWA1Storage } from "../../src/storage/CTMRWA1Storage.sol";
import { ICTMRWA1Storage, URICategory, URIType } from "../../src/storage/ICTMRWA1Storage.sol";
import { ICTMRWAMap } from "../../src/shared/ICTMRWAMap.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { CTMRWA1 } from "../../src/core/CTMRWA1.sol";
import { CTMRWA1StorageManager } from "../../src/storage/CTMRWA1StorageManager.sol";


contract CTMRWA1StorageUtilsTest is Helpers {
    using Strings for *;

    function setUp() public override {
        super.setUp();
        // All helpers and contracts are deployed, including storageUtils, storageManager, map, etc.
    }

    function test_OnlyStorageManagerCanSmC3Fallback() public {
        bytes4 selector = bytes4(keccak256("test()"));
        bytes memory data = "";
        bytes memory reason = "test reason";
        // Should succeed as storageManager
        vm.prank(address(storageManager));
        bool result = storageUtils.smC3Fallback(selector, data, reason);
        assertTrue(result);
        // Should fail for non-storageManager
        vm.prank(address(0xBEEF));
        vm.expectRevert(abi.encodeWithSelector(ICTMRWA1StorageUtils.CTMRWA1StorageUtils_Unauthorized.selector, Address.Sender));
        storageUtils.smC3Fallback(selector, data, reason);
    }

    function test_SmC3Fallback_UpdatesLastSelectorDataReason() public {
        bytes4 selector = bytes4(keccak256("test()"));
        bytes memory data = "test data";
        bytes memory reason = "test reason";
        vm.prank(address(storageManager));
        storageUtils.smC3Fallback(selector, data, reason);
        assertEq(storageUtils.lastSelector(), selector);
        assertEq(storageUtils.lastData(), data);
        assertEq(storageUtils.lastReason(), reason);
    }

    function test_SmC3Fallback_EmitsLogFallback() public {
        bytes4 selector = bytes4(keccak256("test()"));
        bytes memory data = "test data";
        bytes memory reason = "test reason";
        vm.expectEmit(true, true, true, true);
        emit ICTMRWA1StorageUtils.LogFallback(selector, data, reason);
        vm.prank(address(storageManager));
        storageUtils.smC3Fallback(selector, data, reason);
    }

    function test_GetLastReason() public {
        bytes4 selector = bytes4(keccak256("test()"));
        bytes memory data = "test data";
        string memory reason = "test reason string";
        bytes memory reasonBytes = bytes(reason);
        vm.prank(address(storageManager));
        storageUtils.smC3Fallback(selector, data, reasonBytes);
        string memory retrievedReason = storageUtils.getLastReason();
        assertEq(retrievedReason, reason);
    }


    function test_FuzzSmC3Fallback(bytes4 selector, bytes memory data, bytes memory reason) public {
        vm.prank(address(storageManager));
        bool result = storageUtils.smC3Fallback(selector, data, reason);
        assertTrue(result);
    }

    function test_gasUsage_smC3Fallback() public {
        bytes4 selector = bytes4(keccak256("test()"));
        bytes memory data = "test data";
        bytes memory reason = "test reason";
        vm.prank(address(storageManager));
        uint256 gasBefore = gasleft();
        bool result = storageUtils.smC3Fallback(selector, data, reason);
        uint256 gasUsed = gasBefore - gasleft();
        assertTrue(gasUsed < 500_000, string.concat("Gas used: ", vm.toString(gasUsed)));
        assertTrue(result);
    }
}
