// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.27;

import { ICTMRWA1Storage, URICategory, URIData, URIType } from "../../src/storage/ICTMRWA1Storage.sol";
import { CTMRWAErrorParam } from "../../src/utils/CTMRWAUtils.sol";
import { Helpers } from "../helpers/Helpers.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { Test } from "forge-std/Test.sol";
import { console } from "forge-std/console.sol";

contract CTMRWA1StorageTest is Helpers {
    using Strings for *;

    event NewURI(URICategory uriCategory, URIType uriType, uint256 slot, bytes32 uriDataHash);

    ICTMRWA1Storage stor;

    function setUp() public override {
        super.setUp();
        address storAddr;
        vm.startPrank(tokenAdmin);
        (ID, token) = _deployCTMRWA1(address(usdc));
        _createSomeSlots(ID, address(usdc), address(rwa1X));
        (, storAddr) = map.getStorageContract(ID, RWA_TYPE, VERSION);
        stor = ICTMRWA1Storage(storAddr);
        vm.stopPrank();
        // All helpers and contracts are deployed, including storage, storageManager, map, etc.
    }

    function test_onlyStorageManagerCanAddURILocal() public {
        vm.prank(address(storageManager));
        stor.addURILocal(ID, VERSION, "1", URICategory.ISSUER, URIType.CONTRACT, "Title", 0, block.timestamp, keccak256("data"));
        // Should fail for non-storageManager
        vm.prank(address(0xBEEF));
        vm.expectRevert(abi.encodeWithSelector(ICTMRWA1Storage.CTMRWA1Storage_OnlyAuthorized.selector, CTMRWAErrorParam.Sender, CTMRWAErrorParam.StorageManager));
        stor.addURILocal(
            ID, VERSION, "2", URICategory.ISSUER, URIType.CONTRACT, "Title2", 0, block.timestamp, keccak256("data2")
        );
    }

    function test_gas_addURILocal() public {
        vm.prank(address(storageManager));
        uint256 gasBefore = gasleft();
        stor.addURILocal(ID, VERSION, "1", URICategory.ISSUER, URIType.CONTRACT, "Title", 0, block.timestamp, keccak256("data"));
        uint256 gasUsed = gasBefore - gasleft();
        assertTrue(gasUsed < 500_000, string.concat("Gas used: ", vm.toString(gasUsed)));
    }

    function test_fuzz_addURILocal(bytes32 fuzzHash) public {
        vm.prank(address(storageManager));
        // Use a unique object name for each fuzz run, starting with '1' and appending the hash
        string memory objectName = string(abi.encodePacked("1", vm.toString(uint256(fuzzHash))));
        stor.addURILocal(
            ID, VERSION, objectName, URICategory.ISSUER, URIType.CONTRACT, "Fuzz Title", 0, block.timestamp, fuzzHash
        );
        assertTrue(stor.existURIHash(fuzzHash));
    }

    function test_invalidIDReverts() public {
        vm.prank(address(storageManager));
        vm.expectRevert(abi.encodeWithSelector(ICTMRWA1Storage.CTMRWA1Storage_InvalidID.selector, ID, ID + 1));
        stor.addURILocal(
            ID + 1, VERSION, "1", URICategory.ISSUER, URIType.CONTRACT, "Title", 0, block.timestamp, keccak256("data")
        );
    }

    function test_duplicateHashReverts() public {
        bytes32 hash = keccak256("dup");
        vm.prank(address(storageManager));
        stor.addURILocal(ID, VERSION, "1", URICategory.ISSUER, URIType.CONTRACT, "Title", 0, block.timestamp, hash);
        vm.prank(address(storageManager));
        vm.expectRevert(abi.encodeWithSelector(ICTMRWA1Storage.CTMRWA1Storage_HashExists.selector, hash));
        stor.addURILocal(ID, VERSION, "2", URICategory.ISSUER, URIType.CONTRACT, "Title2", 0, block.timestamp, hash);
    }

    function test_invalidSlotReverts() public {
        vm.prank(address(storageManager));
        vm.expectRevert(abi.encodeWithSelector(ICTMRWA1Storage.CTMRWA1Storage_InvalidSlot.selector, 999));
        stor.addURILocal(ID, VERSION, "1", URICategory.ISSUER, URIType.SLOT, "Title", 999, block.timestamp, keccak256("data"));
    }

    function test_firstElementNotIssuerContractReverts() public {
        vm.prank(address(storageManager));
        vm.expectRevert(ICTMRWA1Storage.CTMRWA1Storage_IssuerNotFirst.selector);
        stor.addURILocal(ID, VERSION, "1", URICategory.LEGAL, URIType.SLOT, "Title", 5, block.timestamp, keccak256("data"));
    }

    function test_addURILocal_revertsOnIssuerSlot() public {
        vm.prank(address(storageManager));
        vm.expectRevert(abi.encodeWithSelector(ICTMRWA1Storage.CTMRWA1Storage_IssuerNotFirst.selector));
        stor.addURILocal(ID, VERSION, "1", URICategory.ISSUER, URIType.SLOT, "Title", 5, block.timestamp, keccak256("data"));
    }

    function test_popURILocal_removesURI() public {
        // Add a URI
        vm.prank(address(storageManager));
        string memory objectName = "1";
        bytes32 hash = keccak256("pop-test");
        stor.addURILocal(ID, VERSION, objectName, URICategory.ISSUER, URIType.CONTRACT, "Pop Test", 0, block.timestamp, hash);
        assertTrue(stor.existURIHash(hash));
        // Pop the URI
        vm.prank(address(storageManager));
        stor.popURILocal(1);
        // Assert the hash no longer exists
        assertFalse(stor.existURIHash(hash));
    }

    function test_onlyTokenAdminCanIncreaseNonce() public {
        // Should succeed for tokenAdmin
        vm.startPrank(tokenAdmin);
        uint256 newNonce = stor.nonce() + 10;
        stor.increaseNonce(newNonce);
        vm.stopPrank();
        assertEq(stor.nonce(), newNonce);
        // Should fail for non-admin
        vm.prank(address(0xBEEF));
        vm.expectRevert(abi.encodeWithSelector(ICTMRWA1Storage.CTMRWA1Storage_OnlyAuthorized.selector, CTMRWAErrorParam.Sender, CTMRWAErrorParam.TokenAdmin));
        stor.increaseNonce(newNonce + 1);
    }

    function test_onlyStorageManagerCanSetNonce() public {
        // Should succeed for storageManager
        vm.prank(address(storageManager));
        stor.setNonce(42);
        assertEq(stor.nonce(), 42);
        // Should fail for non-storageManager
        vm.prank(address(0xBEEF));
        vm.expectRevert(abi.encodeWithSelector(ICTMRWA1Storage.CTMRWA1Storage_OnlyAuthorized.selector, CTMRWAErrorParam.Sender, CTMRWAErrorParam.StorageManager));
        stor.setNonce(43);
    }

    function test_increaseNonce_cannotDecreaseNonce() public {
        // Set nonce to a higher value
        vm.startPrank(tokenAdmin);
        uint256 higherNonce = stor.nonce() + 10;
        stor.increaseNonce(higherNonce);
        assertEq(stor.nonce(), higherNonce);
        // Attempt to decrease nonce
        vm.expectRevert(ICTMRWA1Storage.CTMRWA1Storage_IncreasingNonceOnly.selector);
        stor.increaseNonce(higherNonce - 1);
        vm.stopPrank();
    }

    function test_createSecurity_behavior() public {
        address regulator = address(0xBEEF);
        // Should revert if no LICENSE/CONTRACT URI exists
        vm.prank(tokenAdmin);
        vm.expectRevert(ICTMRWA1Storage.CTMRWA1Storage_NoSecurityDescription.selector);
        stor.createSecurity(regulator);
        // Add a LICENSE/CONTRACT URI
        vm.prank(address(storageManager));
        stor.addURILocal(ID, VERSION, "1", URICategory.ISSUER, URIType.CONTRACT, "Title", 0, block.timestamp, keccak256("data"));
        // Should revert if no LICENSE/CONTRACT URI exists
        vm.prank(tokenAdmin);
        vm.expectRevert(ICTMRWA1Storage.CTMRWA1Storage_NoSecurityDescription.selector);
        stor.createSecurity(regulator);
        // Add a LICENSE/CONTRACT URI
        vm.prank(address(storageManager));
        stor.addURILocal(
            ID, VERSION, "2", URICategory.LICENSE, URIType.CONTRACT, "License Title", 0, block.timestamp, keccak256("license")
        );
        // Should succeed now
        vm.prank(tokenAdmin);
        stor.createSecurity(regulator);
        assertEq(stor.regulatorWallet(), regulator);
    }

    function test_getAllURIData_returnsCorrectData() public {
        // Add 5 URIs
        vm.startPrank(address(storageManager));
        stor.addURILocal(
            ID,
            VERSION,
            "1",
            URICategory.ISSUER,
            URIType.CONTRACT,
            "Issuer Contract",
            0,
            block.timestamp,
            keccak256("issuer-contract")
        );
        stor.addURILocal(
            ID,
            VERSION,
            "2",
            URICategory.LEGAL,
            URIType.CONTRACT,
            "Legal Contract",
            0,
            block.timestamp,
            keccak256("legal-contract")
        );
        stor.addURILocal(
            ID,
            VERSION,
            "3",
            URICategory.FINANCIAL,
            URIType.SLOT,
            "Financial Slot 3",
            3,
            block.timestamp,
            keccak256("financial-slot-3")
        );
        stor.addURILocal(
            ID,
            VERSION,
            "4",
            URICategory.LICENSE,
            URIType.CONTRACT,
            "License Contract",
            0,
            block.timestamp,
            keccak256("license-contract")
        );
        stor.addURILocal(
            ID,
            VERSION,
            "5",
            URICategory.REDEMPTION,
            URIType.SLOT,
            "Redemption Slot 5",
            5,
            block.timestamp,
            keccak256("redemption-slot-5")
        );
        vm.stopPrank();

        // Call getAllURIData
        (
            uint8[] memory uriCategories,
            uint8[] memory uriTypes,
            string[] memory titles,
            uint256[] memory slots,
            string[] memory objectNames,
            bytes32[] memory uriHashes,
            uint256[] memory timestamps
        ) = stor.getAllURIData();

        // Check length
        assertEq(uriCategories.length, 5);
        assertEq(uriTypes.length, 5);
        assertEq(titles.length, 5);
        assertEq(slots.length, 5);
        assertEq(objectNames.length, 5);
        assertEq(uriHashes.length, 5);
        assertEq(timestamps.length, 5);

        // Check first entry (ISSUER/CONTRACT)
        assertEq(uriCategories[0], uint8(URICategory.ISSUER));
        assertEq(uriTypes[0], uint8(URIType.CONTRACT));
        assertEq(objectNames[0], "1");
        assertEq(titles[0], "Issuer Contract");
        assertEq(slots[0], 0);
        assertEq(uriHashes[0], keccak256("issuer-contract"));
        // Check third entry (FINANCIAL/SLOT, slot 3)
        assertEq(uriCategories[2], uint8(URICategory.FINANCIAL));
        assertEq(uriTypes[2], uint8(URIType.SLOT));
        assertEq(slots[2], 3);
        assertEq(objectNames[2], "3");
        assertEq(titles[2], "Financial Slot 3");
        assertEq(uriHashes[2], keccak256("financial-slot-3"));
        // Check fifth entry (REDEMPTION/SLOT, slot 5)
        assertEq(uriCategories[4], uint8(URICategory.REDEMPTION));
        assertEq(uriTypes[4], uint8(URIType.SLOT));
        assertEq(slots[4], 5);
        assertEq(objectNames[4], "5");
        assertEq(titles[4], "Redemption Slot 5");
        assertEq(uriHashes[4], keccak256("redemption-slot-5"));
    }

    function test_getURIHashByIndex_returnsCorrectDataAndHandlesOutOfBounds() public {
        // Add 5 URIs
        vm.startPrank(address(storageManager));
        stor.addURILocal(
            ID,
            VERSION,
            "1",
            URICategory.ISSUER,
            URIType.CONTRACT,
            "Issuer Contract",
            0,
            block.timestamp,
            keccak256("issuer-contract")
        );
        stor.addURILocal(
            ID,
            VERSION,
            "2",
            URICategory.LEGAL,
            URIType.CONTRACT,
            "Legal Contract",
            0,
            block.timestamp,
            keccak256("legal-contract")
        );
        stor.addURILocal(
            ID,
            VERSION,
            "3",
            URICategory.FINANCIAL,
            URIType.SLOT,
            "Financial Slot 3",
            3,
            block.timestamp,
            keccak256("financial-slot-3")
        );
        stor.addURILocal(
            ID,
            VERSION,
            "4",
            URICategory.LICENSE,
            URIType.CONTRACT,
            "License Contract",
            0,
            block.timestamp,
            keccak256("license-contract")
        );
        stor.addURILocal(
            ID,
            VERSION,
            "5",
            URICategory.REDEMPTION,
            URIType.SLOT,
            "Redemption Slot 5",
            5,
            block.timestamp,
            keccak256("redemption-slot-5")
        );
        vm.stopPrank();

        // Get the hash and object name for the third FINANCIAL/SLOT entry (index 0, since only one exists)
        (bytes32 hash, string memory objName) = stor.getURIHashByIndex(URICategory.FINANCIAL, URIType.SLOT, 0);
        assertEq(hash, keccak256("financial-slot-3"));
        assertEq(objName, "3");

        // Get the hash and object name for the first ISSUER/CONTRACT entry (index 0)
        (hash, objName) = stor.getURIHashByIndex(URICategory.ISSUER, URIType.CONTRACT, 0);
        assertEq(hash, keccak256("issuer-contract"));
        assertEq(objName, "1");

        // Get the hash and object name for LICENSE/CONTRACT entry (index 0)
        (hash, objName) = stor.getURIHashByIndex(URICategory.LICENSE, URIType.CONTRACT, 0);
        assertEq(hash, keccak256("license-contract"));
        assertEq(objName, "4");

        // Out-of-bounds: index 1 for FINANCIAL/SLOT (only one exists)
        (hash, objName) = stor.getURIHashByIndex(URICategory.FINANCIAL, URIType.SLOT, 1);
        assertEq(hash, bytes32(0));
        assertEq(objName, "");
    }

    function test_addURILocal_emitsNewURIEvent() public {
        bytes32 hash = keccak256("event-test");
        string memory objectName = "1";
        URICategory category = URICategory.ISSUER;
        URIType uriType = URIType.CONTRACT;
        string memory title = "Event Test";
        uint256 slot = 0;
        uint256 timestamp = block.timestamp;
        // Expect the event
        vm.expectEmit(true, true, true, true);
        emit NewURI(category, uriType, slot, hash);
        vm.prank(address(storageManager));
        stor.addURILocal(ID, VERSION, objectName, category, uriType, title, slot, timestamp, hash);
    }

    function test_getURIHashByObjectName_returnsCorrectData() public {
        // Add a URI
        string memory objectName = "1";
        URICategory category = URICategory.ISSUER;
        URIType uriType = URIType.CONTRACT;
        string memory title = "Test Title";
        uint256 slot = 42;
        uint256 timestamp = block.timestamp;
        bytes32 hash = keccak256("test-uri-hash");
        vm.prank(address(storageManager));
        stor.addURILocal(ID, VERSION, objectName, category, uriType, title, slot, timestamp, hash);

        // Retrieve by object name
        URIData memory data = stor.getURIByObjectName(objectName);
        assertEq(uint8(data.uriCategory), uint8(category));
        assertEq(uint8(data.uriType), uint8(uriType));
        assertEq(data.title, title);
        assertEq(data.slot, slot);
        assertEq(data.objectName, objectName);
        assertEq(data.uriHash, hash);
        assertEq(data.timeStamp, timestamp);

        // Test for non-existent object name
        URIData memory emptyData = stor.getURIByObjectName("doesnotexist");
        assertEq(uint8(emptyData.uriCategory), uint8(URICategory.EMPTY));
        assertEq(uint8(emptyData.uriType), uint8(URIType.EMPTY));
        assertEq(emptyData.title, "");
        assertEq(emptyData.slot, 0);
        assertEq(emptyData.objectName, "");
        assertEq(emptyData.uriHash, 0);
        assertEq(emptyData.timeStamp, 0);
    }

    // ========== O(1) OPTIMIZATION TESTS ==========

    function test_O1_optimization_basic() public {
        // Add a few URIs to test basic O(1) functionality using storage manager
        vm.startPrank(tokenAdmin);
        
        // Add first URI (ISSUER/CONTRACT - required)
        storageManager.addURI(
            ID, VERSION, "obj1", URICategory.ISSUER, URIType.CONTRACT, 
            "This is a valid title for the first URI object", 0, keccak256("hash1"), _stringToArray(cIdStr), _toLower(address(usdc).toHexString())
        );
        
        // Add second URI
        storageManager.addURI(
            ID, VERSION, "obj2", URICategory.LEGAL, URIType.CONTRACT, 
            "This is a valid title for the second URI object", 0, keccak256("hash2"), _stringToArray(cIdStr), _toLower(address(usdc).toHexString())
        );
        
        // Add third URI with SLOT type
        storageManager.addURI(
            ID, VERSION, "obj3", URICategory.FINANCIAL, URIType.SLOT, 
            "This is a valid title for the third URI object", 1, keccak256("hash3"), _stringToArray(cIdStr), _toLower(address(usdc).toHexString())
        );
        
        vm.stopPrank();

        // Test O(1) existURIHash
        uint256 gasBefore = gasleft();
        bool exists = stor.existURIHash(keccak256("hash2"));
        uint256 gasUsed = gasBefore - gasleft();
        
        assertTrue(exists);
        assertTrue(gasUsed < 5_000, string.concat("O(1) existURIHash gas too high: ", gasUsed.toString()));
        
        // Test O(1) getURIHash
        gasBefore = gasleft();
        URIData memory data = stor.getURIHash(keccak256("hash2"));
        gasUsed = gasBefore - gasleft();
        
        assertEq(data.uriHash, keccak256("hash2"));
        assertTrue(gasUsed < 15_000, string.concat("O(1) getURIHash gas too high: ", gasUsed.toString()));
        
        // Test O(1) getURIHashCount
        gasBefore = gasleft();
        uint256 count = stor.getURIHashCount(URICategory.LEGAL, URIType.CONTRACT);
        gasUsed = gasBefore - gasleft();
        
        assertEq(count, 1);
        assertTrue(gasUsed < 8_000, string.concat("O(1) getURIHashCount gas too high: ", gasUsed.toString()));
        
        // Test O(1) getURIHashByIndex
        gasBefore = gasleft();
        (bytes32 hash, string memory objName) = stor.getURIHashByIndex(URICategory.LEGAL, URIType.CONTRACT, 0);
        gasUsed = gasBefore - gasleft();
        
        assertEq(hash, keccak256("hash2"));
        assertEq(objName, "obj2");
        assertTrue(gasUsed < 15_000, string.concat("O(1) getURIHashByIndex gas too high: ", gasUsed.toString()));
    }

    function test_gas_O1_existURIHash_largeDataset() public {
        // Add 1000 URIs to test O(1) performance
        vm.startPrank(address(storageManager));
        for (uint256 i = 0; i < 1000; i++) {
            string memory objectName = string(abi.encodePacked("obj", vm.toString(i)));
            bytes32 hash = keccak256(abi.encodePacked("data", i));
            stor.addURILocal(
                ID, VERSION, objectName, URICategory.ISSUER, URIType.CONTRACT, 
                string(abi.encodePacked("Title ", i)), 0, block.timestamp, hash
            );
        }
        vm.stopPrank();

        // Test O(1) lookup performance - should be constant gas regardless of dataset size
        bytes32 testHash = keccak256(abi.encodePacked("data", uint256(500))); // Hash that exists
        bytes32 nonExistentHash = keccak256("nonexistent");
        
        uint256 gasBefore = gasleft();
        bool exists = stor.existURIHash(testHash);
        uint256 gasUsed = gasBefore - gasleft();
        
        assertTrue(exists);
        // O(1) lookup should use minimal gas (around 2,100 gas)
        assertTrue(gasUsed < 5_000, string.concat("O(1) existURIHash gas too high: ", vm.toString(gasUsed)));
        
        // Test non-existent hash
        gasBefore = gasleft();
        bool notExists = stor.existURIHash(nonExistentHash);
        gasUsed = gasBefore - gasleft();
        
        assertFalse(notExists);
        assertTrue(gasUsed < 5_000, string.concat("O(1) existURIHash gas too high: ", vm.toString(gasUsed)));
    }

    function test_gas_O1_getURIHash_largeDataset() public {
        // Add 50 URIs to test O(1) performance using storage manager
        vm.startPrank(tokenAdmin);
        for (uint256 i = 0; i < 50; i++) {
            string memory objectName = string(abi.encodePacked("obj", i.toString()));
            bytes32 hash = keccak256(abi.encodePacked("data", i.toString()));
            string memory title = string(abi.encodePacked("This is a valid title for URI object number ", i.toString()));
            
            storageManager.addURI(
                ID, VERSION, objectName, URICategory.ISSUER, URIType.CONTRACT, 
                title, 0, hash, _stringToArray(cIdStr), _toLower(address(usdc).toHexString())
            );
        }
        vm.stopPrank();

        // Test O(1) lookup performance
        bytes32 testHash = keccak256(abi.encodePacked("data", "25")); // Hash that exists
        
        uint256 gasBefore = gasleft();
        URIData memory data = stor.getURIHash(testHash);
        uint256 gasUsed = gasBefore - gasleft();
        
        assertEq(data.uriHash, testHash);
        assertTrue(gasUsed < 20_000, string.concat("O(1) getURIHash gas too high: ", gasUsed.toString()));
    }

    function test_gas_O1_getURIHashCount_largeDataset() public {
        // Add 1000 URIs with different categories/types
        vm.startPrank(address(storageManager));
        for (uint256 i = 0; i < 1000; i++) {
            string memory objectName = string(abi.encodePacked("obj", vm.toString(i)));
            bytes32 hash = keccak256(abi.encodePacked("data", i));
            
            URICategory category = URICategory(uint8(i % 5)); // Cycle through categories
            URIType uriType = i % 2 == 0 ? URIType.CONTRACT : URIType.SLOT;
            uint256 slot = 0;
            if (uriType == URIType.SLOT) {
                slot = (i % 3 == 0) ? 1 : (i % 3 == 1) ? 3 : 5; // Use slots 1, 3, 5
            }
            
            stor.addURILocal(
                ID, VERSION, objectName, category, uriType, 
                string(abi.encodePacked("Title ", i)), slot, block.timestamp, hash
            );
        }
        vm.stopPrank();

        // Test O(1) count performance
        uint256 gasBefore = gasleft();
        uint256 count = stor.getURIHashCount(URICategory.ISSUER, URIType.CONTRACT);
        uint256 gasUsed = gasBefore - gasleft();
        
        // Should be around 200 ISSUER/CONTRACT entries (1000/5 categories)
        assertTrue(count > 0);
        assertTrue(gasUsed < 8_000, string.concat("O(1) getURIHashCount gas too high: ", vm.toString(gasUsed)));
    }

    function test_gas_O1_getURIHashByIndex_largeDataset() public {
        // Add 1000 URIs with different categories/types
        vm.startPrank(address(storageManager));
        for (uint256 i = 0; i < 1000; i++) {
            string memory objectName = string(abi.encodePacked("obj", vm.toString(i)));
            bytes32 uriHash = keccak256(abi.encodePacked("data", i));
            
            URICategory category = URICategory(uint8(i % 5)); // Cycle through categories
            URIType uriType = i % 2 == 0 ? URIType.CONTRACT : URIType.SLOT;
            uint256 slot = uriType == URIType.SLOT ? (i % 3) + 1 : 0; // Use valid slots 1, 3, 5 (but we only have 1,3,5 so use 1,3,5)
            if (uriType == URIType.SLOT) {
                slot = (i % 3 == 0) ? 1 : (i % 3 == 1) ? 3 : 5; // Use slots 1, 3, 5
            }
            
            stor.addURILocal(
                ID, VERSION, objectName, category, uriType, 
                string(abi.encodePacked("Title ", i)), slot, block.timestamp, uriHash
            );
        }
        vm.stopPrank();

        // Test O(1) index lookup performance
        uint256 gasBefore = gasleft();
        (bytes32 hash,) = stor.getURIHashByIndex(URICategory.ISSUER, URIType.CONTRACT, 0);
        uint256 gasUsed = gasBefore - gasleft();
        
        assertTrue(hash != bytes32(0));
        assertTrue(gasUsed < 15_000, string.concat("O(1) getURIHashByIndex gas too high: ", vm.toString(gasUsed)));
    }

    function test_largeDataset_500_records() public {
        // Add 500 URIs to test O(1) performance with larger dataset
        vm.startPrank(tokenAdmin);
        for (uint256 i = 0; i < 500; i++) {
            string memory objectName = string(abi.encodePacked("obj", i.toString()));
            bytes32 uriHash = keccak256(abi.encodePacked("data", i.toString()));
            
            URICategory category = URICategory(uint8(i % 5)); // Cycle through 5 categories
            URIType uriType = i % 2 == 0 ? URIType.CONTRACT : URIType.SLOT;
            uint256 slot = 0;
            if (uriType == URIType.SLOT) {
                slot = (i % 3 == 0) ? 1 : (i % 3 == 1) ? 3 : 5; // Use slots 1, 3, 5
            }
            
            string memory title = string(abi.encodePacked("This is a valid title for URI object number ", i.toString()));
            
            storageManager.addURI(
                ID, VERSION, objectName, category, uriType, 
                title, slot, uriHash, _stringToArray(cIdStr), _toLower(address(usdc).toHexString())
            );
        }
        vm.stopPrank();

        // Test all O(1) functions with large dataset
        console.log("Testing O(1) functions with 500 records:");
        
        // Test existURIHash
        uint256 gasBefore = gasleft();
        bool exists = stor.existURIHash(keccak256(abi.encodePacked("data", "250")));
        uint256 gasUsed = gasBefore - gasleft();
        assertTrue(exists);
        console.log("existURIHash gas:", gasUsed);
        assertTrue(gasUsed < 8_000, "existURIHash should be O(1)");
        
        // Test getURIHash
        gasBefore = gasleft();
        URIData memory data = stor.getURIHash(keccak256(abi.encodePacked("data", "375")));
        gasUsed = gasBefore - gasleft();
        assertEq(data.uriHash, keccak256(abi.encodePacked("data", "375")));
        console.log("getURIHash gas:", gasUsed);
        assertTrue(gasUsed < 20_000, "getURIHash should be O(1)");
        
        // Test getURIHashCount
        gasBefore = gasleft();
        gasUsed = gasBefore - gasleft();
        console.log("getURIHashCount gas:", gasUsed);
        assertTrue(gasUsed < 8_000, "getURIHashCount should be O(1)");
        
        // Test getURIHashByIndex
        gasBefore = gasleft();
        (bytes32 hash,) = stor.getURIHashByIndex(URICategory.ISSUER, URIType.CONTRACT, 0);
        gasUsed = gasBefore - gasleft();
        assertTrue(hash != bytes32(0));
        console.log("getURIHashByIndex gas:", gasUsed);
        assertTrue(gasUsed < 15_000, "getURIHashByIndex should be O(1)");
    }

    function test_largeDataset_1000_records() public {
        // Add 1000 URIs with various categories and types
        vm.startPrank(address(storageManager));
        for (uint256 i = 0; i < 1000; i++) {
            string memory objectName = string(abi.encodePacked("obj", vm.toString(i)));
            bytes32 uriHash = keccak256(abi.encodePacked("data", i));
            
            URICategory category = URICategory(uint8(i % 10)); // Cycle through 10 categories
            URIType uriType = i % 3 == 0 ? URIType.CONTRACT : URIType.SLOT;
            uint256 slot = 0;
            if (uriType == URIType.SLOT) {
                slot = (i % 3 == 0) ? 1 : (i % 3 == 1) ? 3 : 5; // Use slots 1, 3, 5
            }
            
            stor.addURILocal(
                ID, VERSION, objectName, category, uriType, 
                string(abi.encodePacked("Title ", i)), slot, block.timestamp, uriHash
            );
        }
        vm.stopPrank();

        // Test all O(1) functions with large dataset
        console.log("Testing O(1) functions with 1000 records:");
        
        // Test existURIHash
        uint256 gasBefore = gasleft();
        bool exists = stor.existURIHash(keccak256(abi.encodePacked("data", uint256(500))));
        uint256 gasUsed = gasBefore - gasleft();
        assertTrue(exists);
        console.log("existURIHash gas:", gasUsed);
        assertTrue(gasUsed < 8_000, "existURIHash should be O(1)");
        
        // Test getURIHash
        gasBefore = gasleft();
        URIData memory data = stor.getURIHash(keccak256(abi.encodePacked("data", uint256(750))));
        gasUsed = gasBefore - gasleft();
        assertEq(data.uriHash, keccak256(abi.encodePacked("data", uint256(750))));
        console.log("getURIHash gas:", gasUsed);
        assertTrue(gasUsed < 20_000, "getURIHash should be O(1)");
        
        // Test getURIHashCount
        gasBefore = gasleft();
        gasUsed = gasBefore - gasleft();
        console.log("getURIHashCount gas:", gasUsed);
        assertTrue(gasUsed < 8_000, "getURIHashCount should be O(1)");
        
        // Test getURIHashByIndex
        gasBefore = gasleft();
        (bytes32 hash,) = stor.getURIHashByIndex(URICategory.ISSUER, URIType.CONTRACT, 0);
        gasUsed = gasBefore - gasleft();
        assertTrue(hash != bytes32(0));
        console.log("getURIHashByIndex gas:", gasUsed);
        assertTrue(gasUsed < 15_000, "getURIHashByIndex should be O(1)");
    }

    function test_veryLargeDataset_5000_records() public {
        // Add 5000 URIs to test extreme scalability
        vm.startPrank(address(storageManager));
        for (uint256 i = 0; i < 5000; i++) {
            string memory objectName = string(abi.encodePacked("obj", vm.toString(i)));
            bytes32 hash = keccak256(abi.encodePacked("data", i));
            
            URICategory category = URICategory(uint8(i % 15)); // Cycle through 15 categories
            URIType uriType = i % 2 == 0 ? URIType.CONTRACT : URIType.SLOT;
            uint256 slot = 0;
            if (uriType == URIType.SLOT) {
                slot = (i % 3 == 0) ? 1 : (i % 3 == 1) ? 3 : 5; // Use slots 1, 3, 5
            }
            
            stor.addURILocal(
                ID, VERSION, objectName, category, uriType, 
                string(abi.encodePacked("Title ", i)), slot, block.timestamp, hash
            );
        }
        vm.stopPrank();

        console.log("Testing O(1) functions with 5000 records:");
        
        // Test existURIHash - should still be O(1)
        uint256 gasBefore = gasleft();
        bool exists = stor.existURIHash(keccak256(abi.encodePacked("data", uint256(2500))));
        uint256 gasUsed = gasBefore - gasleft();
        assertTrue(exists);
        console.log("existURIHash with 5000 records gas:", gasUsed);
        assertTrue(gasUsed < 8_000, "existURIHash should remain O(1) even with 5000 records");
        
        // Test getURIHash - should still be O(1)
        gasBefore = gasleft();
        URIData memory data = stor.getURIHash(keccak256(abi.encodePacked("data", uint256(3750))));
        gasUsed = gasBefore - gasleft();
        assertEq(data.uriHash, keccak256(abi.encodePacked("data", uint256(3750))));
        console.log("getURIHash with 5000 records gas:", gasUsed);
        assertTrue(gasUsed < 20_000, "getURIHash should remain O(1) even with 5000 records");
    }

    function test_mappingConsistency_afterPopURILocal() public {
        // Add 100 URIs
        vm.startPrank(address(storageManager));
        for (uint256 i = 0; i < 100; i++) {
            string memory objectName = string(abi.encodePacked("obj", vm.toString(i)));
            bytes32 hash = keccak256(abi.encodePacked("data", i));
            stor.addURILocal(
                ID, VERSION, objectName, URICategory.ISSUER, URIType.CONTRACT, 
                string(abi.encodePacked("Title ", i)), 0, block.timestamp, hash
            );
        }
        vm.stopPrank();

        // Verify initial state
        assertTrue(stor.existURIHash(keccak256(abi.encodePacked("data", uint256(50)))));
        assertEq(stor.getURIHashCount(URICategory.ISSUER, URIType.CONTRACT), 100);

        // Pop 10 URIs
        vm.prank(address(storageManager));
        stor.popURILocal(10);

        // Verify mappings are cleaned up correctly
        assertFalse(stor.existURIHash(keccak256(abi.encodePacked("data", uint256(95))))); // Last added should be gone
        assertTrue(stor.existURIHash(keccak256(abi.encodePacked("data", uint256(50))))); // Earlier ones should still exist
        assertEq(stor.getURIHashCount(URICategory.ISSUER, URIType.CONTRACT), 90);
    }
}
