// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.27;

import { Test } from "forge-std/Test.sol";
import { console } from "forge-std/console.sol";

import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

import { Helpers } from "../helpers/Helpers.sol";

import { ICTMRWA1Storage } from "../../src/storage/ICTMRWA1Storage.sol";
import { ICTMRWA1Storage, URICategory, URIData, URIType } from "../../src/storage/ICTMRWA1Storage.sol";
import { ICTMRWA1StorageManager } from "../../src/storage/ICTMRWA1StorageManager.sol";

event AddingURI(uint256 ID, string chainIdStr);
event URIAdded(uint256 ID);

contract TestStorageManager is Helpers {
    using Strings for *;

    function test_addURI() public {
        vm.startPrank(tokenAdmin);
        (ID, token) = _deployCTMRWA1(address(usdc));
        _createSomeSlots(ID, address(usdc), address(rwa1X));

        string memory feeTokenStr = _toLower((address(usdc).toHexString()));

        string memory randomData = "this is any old data";
        bytes32 junkHash = keccak256(abi.encode(randomData));

        // Expect custom error for first element not being ISSUER/CONTRACT
        vm.expectRevert(abi.encodeWithSelector(ICTMRWA1Storage.CTMRWA1Storage_IssuerNotFirst.selector));
        storageManager.addURI(
            ID,
            "1",
            URICategory.IMAGE,
            URIType.CONTRACT,
            "Basic RWA for testing",
            0, // dummy
            junkHash,
            _stringToArray(cIdStr),
            feeTokenStr
        );

        storageManager.addURI(
            ID,
            "1",
            URICategory.ISSUER,
            URIType.CONTRACT,
            "Basic RWA for testing",
            0, // dummy
            junkHash,
            _stringToArray(cIdStr),
            feeTokenStr
        );

        (bool ok, address thisStorage) = map.getStorageContract(ID, RWA_TYPE, VERSION);
        assertEq(ok, true);

        bool existObject = ICTMRWA1Storage(thisStorage).existObjectName("1");
        assertEq(existObject, true);

        uint256 num = ICTMRWA1Storage(thisStorage).getURIHashCount(URICategory.ISSUER, URIType.CONTRACT);
        assertEq(num, 1);

        URIData memory thisHash = ICTMRWA1Storage(thisStorage).getURIHash(junkHash);
        assertEq(uint8(thisHash.uriCategory), uint8(URICategory.ISSUER));

        uint256 indx = 0;
        bytes32 issuerHash;
        string memory objectName;

        (issuerHash, objectName) =
            ICTMRWA1Storage(thisStorage).getURIHashByIndex(URICategory.ISSUER, URIType.CONTRACT, indx);
        // console.log("ObjectName");
        // console.log(objectName);
        // console.log("Issuer hash");
        // console.logBytes32(issuerHash);
        assertEq(issuerHash, junkHash);

        vm.stopPrank();
    }

    function test_addURIX() public {
        // Test the onlyCaller function addURIX called by the MPC network to add storage refs cross-chain
        vm.startPrank(tokenAdmin);
        (ID, token) = _deployCTMRWA1(address(usdc));
        _createSomeSlots(ID, address(usdc), address(rwa1X));
        vm.stopPrank();

        URICategory _uriCategory = URICategory.ISSUER;
        URIType _uriType = URIType.CONTRACT;

        string memory randomData = "this is any old data";
        bytes32 junkHash = keccak256(abi.encode(randomData));

        vm.startPrank(address(c3caller));

        vm.expectRevert(abi.encodeWithSelector(ICTMRWA1StorageManager.CTMRWA1StorageManager_StartNonce.selector));
        storageManager.addURIX(
            ID,
            2, // incorrect nonce
            _stringToArray("1"),
            _uint8ToArray(uint8(_uriCategory)),
            _uint8ToArray(uint8(_uriType)),
            _stringToArray("A Title"),
            _uint256ToArray(0),
            _uint256ToArray(block.timestamp),
            _bytes32ToArray(junkHash)
        );

        storageManager.addURIX(
            ID,
            1,
            _stringToArray("1"),
            _uint8ToArray(uint8(_uriCategory)),
            _uint8ToArray(uint8(_uriType)),
            _stringToArray("A Title"),
            _uint256ToArray(0),
            _uint256ToArray(block.timestamp),
            _bytes32ToArray(junkHash)
        );

        (, address thisStorage) = map.getStorageContract(ID, RWA_TYPE, VERSION);

        uint256 newNonce = ICTMRWA1Storage(thisStorage).nonce();
        assertEq(newNonce, 2);

        bool exists = ICTMRWA1Storage(thisStorage).existObjectName("1");
        assertEq(exists, true);

        URIData memory uri = ICTMRWA1Storage(thisStorage).getURIHash(junkHash);
        assertEq(stringsEqual(uri.title, "A Title"), true);

        vm.stopPrank();
    }

    // ============ ACCESS CONTROL TESTS ============
    function test_onlyTokenAdminCanAddURI() public {
        vm.startPrank(tokenAdmin);
        (ID, token) = _deployCTMRWA1(address(usdc));
        _createSomeSlots(ID, address(usdc), address(rwa1X));
        string memory feeTokenStr = _toLower((address(usdc).toHexString()));
        string memory randomData = "access control test";
        bytes32 junkHash = keccak256(abi.encode(randomData));
        // Should succeed for tokenAdmin
        storageManager.addURI(
            ID,
            "1",
            URICategory.ISSUER,
            URIType.CONTRACT,
            "Access Control RWA",
            0,
            junkHash,
            _stringToArray(cIdStr),
            feeTokenStr
        );
        vm.stopPrank();
        // Should fail for unauthorized user
        address unauthorized = address(0xBEEF);
        vm.startPrank(unauthorized);
        vm.expectRevert();
        storageManager.addURI(
            ID,
            "2",
            URICategory.ISSUER,
            URIType.CONTRACT,
            "Should fail",
            0,
            keccak256(abi.encode("fail")),
            _stringToArray(cIdStr),
            feeTokenStr
        );
        vm.stopPrank();
    }

    function test_onlyC3CallerCanAddURIX() public {
        vm.startPrank(tokenAdmin);
        (ID, token) = _deployCTMRWA1(address(usdc));
        _createSomeSlots(ID, address(usdc), address(rwa1X));
        vm.stopPrank();
        URICategory _uriCategory = URICategory.ISSUER;
        URIType _uriType = URIType.CONTRACT;
        string memory randomData = "crosschain access control";
        bytes32 junkHash = keccak256(abi.encode(randomData));
        // Should fail for non-c3caller
        vm.startPrank(tokenAdmin);
        vm.expectRevert();
        storageManager.addURIX(
            ID,
            1,
            _stringToArray("1"),
            _uint8ToArray(uint8(_uriCategory)),
            _uint8ToArray(uint8(_uriType)),
            _stringToArray("Title"),
            _uint256ToArray(0),
            _uint256ToArray(block.timestamp),
            _bytes32ToArray(junkHash)
        );
        vm.stopPrank();
        // Should succeed for c3caller
        vm.startPrank(address(c3caller));
        storageManager.addURIX(
            ID,
            1,
            _stringToArray("1"),
            _uint8ToArray(uint8(_uriCategory)),
            _uint8ToArray(uint8(_uriType)),
            _stringToArray("Title"),
            _uint256ToArray(0),
            _uint256ToArray(block.timestamp),
            _bytes32ToArray(junkHash)
        );
        vm.stopPrank();
    }

    // ============ INVARIANT TESTS ============
    function test_invariantNonceIncrements() public {
        vm.startPrank(tokenAdmin);
        (ID, token) = _deployCTMRWA1(address(usdc));
        _createSomeSlots(ID, address(usdc), address(rwa1X));
        string memory feeTokenStr = _toLower((address(usdc).toHexString()));
        string memory randomData = "nonce test";
        bytes32 junkHash = keccak256(abi.encode(randomData));
        storageManager.addURI(
            ID,
            "1",
            URICategory.ISSUER,
            URIType.CONTRACT,
            "Nonce Test",
            0,
            junkHash,
            _stringToArray(cIdStr),
            feeTokenStr
        );
        (, address thisStorage) = map.getStorageContract(ID, RWA_TYPE, VERSION);
        uint256 nonceBefore = ICTMRWA1Storage(thisStorage).nonce();
        // Add another URI
        bytes32 newHash = keccak256(abi.encode("nonce2"));
        storageManager.addURI(
            ID,
            "2",
            URICategory.ISSUER,
            URIType.CONTRACT,
            "Nonce Test 2",
            0,
            newHash,
            _stringToArray(cIdStr),
            feeTokenStr
        );
        uint256 nonceAfter = ICTMRWA1Storage(thisStorage).nonce();
        assertEq(nonceAfter, nonceBefore + 1);
        vm.stopPrank();
    }

    function test_invariantNoDuplicateHashes() public {
        vm.startPrank(tokenAdmin);
        (ID, token) = _deployCTMRWA1(address(usdc));
        _createSomeSlots(ID, address(usdc), address(rwa1X));
        string memory feeTokenStr = _toLower((address(usdc).toHexString()));
        string memory randomData = "dup hash";
        bytes32 junkHash = keccak256(abi.encode(randomData));
        storageManager.addURI(
            ID,
            "1",
            URICategory.ISSUER,
            URIType.CONTRACT,
            "Dup Hash Test",
            0,
            junkHash,
            _stringToArray(cIdStr),
            feeTokenStr
        );
        // Try to add the same hash again
        vm.expectRevert();
        storageManager.addURI(
            ID,
            "1",
            URICategory.ISSUER,
            URIType.CONTRACT,
            "Dup Hash Test",
            0,
            junkHash,
            _stringToArray(cIdStr),
            feeTokenStr
        );
        vm.stopPrank();
    }

    // ============ GAS USAGE TESTS ============
    function test_gas_addURI() public {
        vm.startPrank(tokenAdmin);
        (ID, token) = _deployCTMRWA1(address(usdc));
        _createSomeSlots(ID, address(usdc), address(rwa1X));
        string memory feeTokenStr = _toLower((address(usdc).toHexString()));
        string memory randomData = "gas test";
        bytes32 junkHash = keccak256(abi.encode(randomData));
        uint256 gasBefore = gasleft();
        storageManager.addURI(
            ID,
            "1",
            URICategory.ISSUER,
            URIType.CONTRACT,
            "Gas Test 01",
            0,
            junkHash,
            _stringToArray(cIdStr),
            feeTokenStr
        );
        uint256 gasUsed = gasBefore - gasleft();
        assertLt(gasUsed, 500_000, "addURI gas usage should be reasonable");
        vm.stopPrank();
    }

    function test_gas_addURIX() public {
        vm.startPrank(tokenAdmin);
        (ID, token) = _deployCTMRWA1(address(usdc));
        _createSomeSlots(ID, address(usdc), address(rwa1X));
        vm.stopPrank();
        URICategory _uriCategory = URICategory.ISSUER;
        URIType _uriType = URIType.CONTRACT;
        string memory randomData = "gas urix";
        bytes32 junkHash = keccak256(abi.encode(randomData));
        vm.startPrank(address(c3caller));
        uint256 gasBefore = gasleft();
        storageManager.addURIX(
            ID,
            1,
            _stringToArray("1"),
            _uint8ToArray(uint8(_uriCategory)),
            _uint8ToArray(uint8(_uriType)),
            _stringToArray("Gas URIX"),
            _uint256ToArray(0),
            _uint256ToArray(block.timestamp),
            _bytes32ToArray(junkHash)
        );
        uint256 gasUsed = gasBefore - gasleft();
        assertLt(gasUsed, 600_000, "addURIX gas usage should be reasonable");
        vm.stopPrank();
    }

    // ============ FUZZ & EDGE CASE TESTS ============
    function test_fuzz_addURI_bytes32(uint256 fuzzVal) public {
        vm.startPrank(tokenAdmin);
        (ID, token) = _deployCTMRWA1(address(usdc));
        _createSomeSlots(ID, address(usdc), address(rwa1X));
        string memory feeTokenStr = _toLower((address(usdc).toHexString()));
        bytes32 fuzzHash = keccak256(abi.encode(fuzzVal));
        storageManager.addURI(
            ID,
            "fuzz",
            URICategory.ISSUER,
            URIType.CONTRACT,
            "Fuzz Test 01",
            0,
            fuzzHash,
            _stringToArray(cIdStr),
            feeTokenStr
        );
        (, address thisStorage) = map.getStorageContract(ID, RWA_TYPE, VERSION);
        bool exists = ICTMRWA1Storage(thisStorage).existObjectName("fuzz");
        assertEq(exists, true);
        vm.stopPrank();
    }

    function test_addURI_zeroAddress() public {
        // Should revert if called with zero address as tokenAdmin
        vm.startPrank(address(0));
        vm.expectRevert();
        storageManager.addURI(
            0,
            "zero",
            URICategory.ISSUER,
            URIType.CONTRACT,
            "Zero Address",
            0,
            bytes32(0),
            _stringToArray(cIdStr),
            ""
        );
        vm.stopPrank();
    }

}
