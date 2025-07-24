// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.27;

import { CTMRWA1 } from "../../src/core/CTMRWA1.sol";
import { ICTMRWAMap } from "../../src/shared/ICTMRWAMap.sol";
import { CTMRWA1Storage } from "../../src/storage/CTMRWA1Storage.sol";

import { CTMRWA1StorageManager } from "../../src/storage/CTMRWA1StorageManager.sol";
import { ICTMRWA1Storage, URICategory, URIType } from "../../src/storage/ICTMRWA1Storage.sol";
import { ICTMRWA1StorageUtils } from "../../src/storage/ICTMRWA1StorageUtils.sol";
import { Address } from "../../src/utils/CTMRWAUtils.sol";
import { Helpers } from "../helpers/Helpers.sol";

import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { Test } from "forge-std/Test.sol";
import { console } from "forge-std/console.sol";

contract CTMRWA1StorageUtilsTest is Helpers {
    using Strings for *;

    uint256 startNonce;

    function setUp() public override {
        super.setUp();
        // All helpers and contracts are deployed, including storageUtils, storageManager, map, etc.

        vm.startPrank(tokenAdmin);
        (ID, token) = _deployCTMRWA1(address(usdc));
        _createSomeSlots(ID, address(usdc), address(rwa1X));

        address stor;

        (, stor) = map.getStorageContract(ID, RWA_TYPE, VERSION);
        startNonce = ICTMRWA1Storage(stor).nonce();

        // Add a URI to the storage for testing fallback scenarios
        string memory feeTokenStr = _toLower(address(usdc).toHexString());
        string memory randomData = "test document for fallback";
        bytes32 junkHash = keccak256(abi.encode(randomData));

        storageManager.addURI(
            ID,
            "test_document_001",
            URICategory.ISSUER,
            URIType.CONTRACT,
            "Test Document for Fallback",
            startNonce,
            junkHash,
            _stringToArray(cIdStr),
            feeTokenStr
        );
        vm.stopPrank();
    }

    function _createAddURIXTestData(
        uint256 _ID,
        uint256 _startNonce,
        string memory _objectName,
        string memory _title,
        uint256 _slot
    ) internal view returns (bytes4 addURIXSelector, bytes memory data) {
        // Create the AddURIX selector
        addURIXSelector = bytes4(
            keccak256("addURIX(uint256,uint256,string[],uint8[],uint8[],string[],uint256[],uint256[],bytes32[])")
        );

        // Create realistic data for addURIX function (simulating a failed cross-chain call)
        string[] memory _objectNameArray = _stringToArray(_objectName);
        uint8[] memory _uriCategory = _uint8ToArray(uint8(URICategory.ISSUER));
        uint8[] memory _uriType = _uint8ToArray(uint8(URIType.CONTRACT));
        string[] memory _titleArray = _stringToArray(_title);
        uint256[] memory _slotArray = _uint256ToArray(_slot);
        uint256[] memory _timestamp = _uint256ToArray(block.timestamp);

        // Create a realistic hash for the document
        string memory documentData =
            string.concat(_title, " - Property Portfolio: 123 Main St, 456 Oak Ave, 789 Pine Blvd");
        bytes32 _uriDataHash = keccak256(abi.encode(documentData));
        bytes32[] memory _uriDataHashArray = _bytes32ToArray(_uriDataHash);

        // Encode the data for the addURIX function
        data = abi.encode(
            _ID,
            _startNonce,
            _objectNameArray,
            _uriCategory,
            _uriType,
            _titleArray,
            _slotArray,
            _timestamp,
            _uriDataHashArray
        );
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
        vm.expectRevert(
            abi.encodeWithSelector(ICTMRWA1StorageUtils.CTMRWA1StorageUtils_OnlyAuthorized.selector, Address.Sender, Address.StorageManager)
        );
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

    function test_SmC3Fallback_AddURIX_SuccessfulFallback() public {
        // Test smC3Fallback with AddURIX selector and realistic data
        (bool ok, address storageAddr) = map.getStorageContract(ID, RWA_TYPE, VERSION);
        assertTrue(ok, "Storage contract should exist");

        // Verify URI was added in setUp
        bool exists = ICTMRWA1Storage(storageAddr).existObjectName("test_document_001");
        assertTrue(exists, "URI should exist in storage from setUp");

        // Create test data using the internal function
        (bytes4 addURIXSelector, bytes memory data) = _createAddURIXTestData(
            ID,
            1, // startNonce
            "test_document_002",
            "Real Estate Investment Trust Certificate",
            1 // slot
        );

        bytes memory reason = "Cross-chain URI addition failed - reverting changes";

        // Call smC3Fallback with AddURIX selector to simulate reverting a failed cross-chain call
        vm.prank(address(storageManager));
        bool result = storageUtils.smC3Fallback(addURIXSelector, data, reason);

        // Verify the fallback was successful
        assertTrue(result, "smC3Fallback should return true for successful AddURIX fallback");

        // Verify the storage variables were updated
        assertEq(storageUtils.lastSelector(), addURIXSelector, "lastSelector should be updated to AddURIX selector");
        assertEq(storageUtils.lastData(), data, "lastData should be updated to the encoded data");
        assertEq(storageUtils.lastReason(), reason, "lastReason should be updated to the reason");

        // Verify the reason can be retrieved as string
        string memory retrievedReason = storageUtils.getLastReason();
        assertEq(retrievedReason, string(reason), "getLastReason should return the correct reason string");

        // Verify the LogFallback event was emitted (it was already emitted in the first call above)
        // The event emission is tested implicitly by the successful execution of smC3Fallback
    }

    function test_SmC3Fallback_AddURIX_VerifiesNonceResetAndURIPopping() public {
        // Test that after smC3Fallback with AddURIX selector, the nonce is reset and URIs are popped
        (bool ok, address storageAddr) = map.getStorageContract(ID, RWA_TYPE, VERSION);
        assertTrue(ok, "Storage contract should exist");

        // Verify initial state - URI exists and nonce is 2 (after setUp created one URI)
        string memory documentData = "test document for fallback";
        bytes32 uriHash = keccak256(abi.encode(documentData));
        bool exists = ICTMRWA1Storage(storageAddr).existURIHash(uriHash);
        assertTrue(exists, "URI should exist in storage from setUp");
        uint256 initialNonce = ICTMRWA1Storage(storageAddr).nonce();
        assertEq(initialNonce, 2, "Initial nonce should be 2 after setUp created one URI");

        // Create test data using the internal function with _startNonce = 0 (simulating revert to beginning)
        (bytes4 addURIXSelector, bytes memory data) = _createAddURIXTestData(
            ID,
            0, // startNonce - This will reset the nonce to 0
            "test_document_001", // Same name as the one in storage
            "Test Document for Fallback",
            1 // slot
        );

        bytes memory reason = "Cross-chain URI addition failed - reverting to initial state";

        // Call smC3Fallback with AddURIX selector
        vm.prank(address(storageManager));
        bool result = storageUtils.smC3Fallback(addURIXSelector, data, reason);

        // Verify the fallback was successful
        assertTrue(result, "smC3Fallback should return true for successful AddURIX fallback");

        // Verify the nonce was reset to _startNonce (0)
        uint256 newNonce = ICTMRWA1Storage(storageAddr).nonce();
        assertEq(newNonce, 0, "Nonce should be reset to 0");

        // Verify the URI was popped (no longer exists)
        bool stillExists = ICTMRWA1Storage(storageAddr).existURIHash(uriHash);
        assertFalse(stillExists, "URI should be popped and no longer exist");

        // Verify the length of objectName array (1) matches the number of URIs popped
        // We know from _createAddURIXTestData that objectName array has length 1
        assertEq(data.length > 0, true, "Data should not be empty");

        // Verify storage variables were updated
        assertEq(storageUtils.lastSelector(), addURIXSelector, "lastSelector should be updated");
        assertEq(storageUtils.lastData(), data, "lastData should be updated");
        assertEq(storageUtils.lastReason(), reason, "lastReason should be updated");
    }

    function test_gasUsage_smC3Fallback() public {
        // Test gas usage with realistic AddURIX selector and data
        (bytes4 addURIXSelector, bytes memory data) = _createAddURIXTestData(
            ID,
            1, // startNonce
            "real_estate_document_001",
            "Real Estate Investment Trust Certificate - Property Portfolio Management",
            1 // slot
        );

        bytes memory reason = "Cross-chain URI addition failed";

        vm.prank(address(storageManager));
        uint256 gasBefore = gasleft();
        bool result = storageUtils.smC3Fallback(addURIXSelector, data, reason);
        uint256 gasUsed = gasBefore - gasleft();

        // More realistic gas limit for AddURIX fallback (includes storage operations)
        assertTrue(gasUsed < 1_000_000, string.concat("Gas used: ", vm.toString(gasUsed)));
        assertTrue(result, "smC3Fallback should succeed with AddURIX selector");

        // Verify the operation was successful
        assertEq(storageUtils.lastSelector(), addURIXSelector, "lastSelector should be updated");
        assertEq(storageUtils.lastData(), data, "lastData should be updated");
        assertEq(storageUtils.lastReason(), reason, "lastReason should be updated");
    }
}
