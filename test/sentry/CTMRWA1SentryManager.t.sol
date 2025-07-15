// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.22;

import { Test } from "forge-std/Test.sol";
import { console } from "forge-std/console.sol";

import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

import { Helpers } from "../helpers/Helpers.sol";

import { ICTMRWA1Sentry } from "../../src/sentry/ICTMRWA1Sentry.sol";
import { ICTMRWA1Storage } from "../../src/storage/ICTMRWA1Storage.sol";
import { ICTMRWA1Storage, URICategory, URIData, URIType } from "../../src/storage/ICTMRWA1Storage.sol";
import { ICTMRWA1, Address } from "../../src/core/ICTMRWA1.sol";
import { ICTMRWA1X } from "../../src/crosschain/ICTMRWA1X.sol";
import {List} from "../../src/CTMRWAUtils.sol";

contract TestSentryManager is Helpers {
    using Strings for *;

    // ============ ACCESS CONTROL TESTS ============

    function test_accessControl_setSentryOptions() public {
        vm.startPrank(tokenAdmin);
        (ID, token) = _deployCTMRWA1(address(usdc));
        _createSomeSlots(ID, address(usdc), address(rwa1X));
        vm.stopPrank();

        string memory feeTokenStr = address(usdc).toHexString();

        // Test non-admin cannot set sentry options
        vm.startPrank(user1);
        vm.expectRevert("CTMRWA1SentryManager: Not tokenAdmin");
        sentryManager.setSentryOptions(
            ID,
            true, // whitelistSwitch
            false,
            false,
            false,
            false,
            false,
            false,
            _stringToArray(cIdStr),
            feeTokenStr
        );
        vm.stopPrank();

        // Test admin can set sentry options
        vm.startPrank(tokenAdmin);
        sentryManager.setSentryOptions(
            ID,
            true, // whitelistSwitch
            false,
            false,
            false,
            false,
            false,
            false,
            _stringToArray(cIdStr),
            feeTokenStr
        );
        vm.stopPrank();
    }

    function test_accessControl_addWhitelist() public {
        vm.startPrank(tokenAdmin);
        (ID, token) = _deployCTMRWA1(address(usdc));
        _createSomeSlots(ID, address(usdc), address(rwa1X));
        
        string memory feeTokenStr = address(usdc).toHexString();
        
        // Enable whitelist
        sentryManager.setSentryOptions(
            ID,
            true, // whitelistSwitch
            false,
            false,
            false,
            false,
            false,
            false,
            _stringToArray(cIdStr),
            feeTokenStr
        );
        vm.stopPrank();

        // Test non-admin cannot add whitelist
        vm.startPrank(user1);
        vm.expectRevert("CTMRWA1SentryManager: Not tokenAdmin");
        sentryManager.addWhitelist(
            ID,
            _stringToArray(user1.toHexString()),
            _boolToArray(true),
            _stringToArray(cIdStr),
            feeTokenStr
        );
        vm.stopPrank();
    }

    function test_accessControl_addCountrylist() public {
        vm.startPrank(tokenAdmin);
        (ID, token) = _deployCTMRWA1(address(usdc));
        _createSomeSlots(ID, address(usdc), address(rwa1X));
        
        string memory feeTokenStr = address(usdc).toHexString();
        
        // Enable country whitelist
        sentryManager.setSentryOptions(
            ID,
            false,
            true, // kycSwitch
            false,
            false,
            false,
            true, // countryWLSwitch
            false,
            _stringToArray(cIdStr),
            feeTokenStr
        );
        vm.stopPrank();

        // Test non-admin cannot add country list
        vm.startPrank(user1);
        vm.expectRevert("CTMRWA1SentryManager: Not tokenAdmin");
        sentryManager.addCountrylist(
            ID,
            _stringToArray("US"),
            _boolToArray(true),
            _stringToArray(cIdStr),
            feeTokenStr
        );
        vm.stopPrank();
    }

    function test_accessControl_goPublic() public {
        vm.startPrank(tokenAdmin);
        (ID, token) = _deployCTMRWA1(address(usdc));
        _createSomeSlots(ID, address(usdc), address(rwa1X));
        
        string memory feeTokenStr = address(usdc).toHexString();
        
        // Set up KYC and accredited
        sentryManager.setSentryOptions(
            ID,
            false,
            true, // kycSwitch
            false,
            false,
            true, // accreditedSwitch
            true, // countryWLSwitch
            false,
            _stringToArray(cIdStr),
            feeTokenStr
        );
        vm.stopPrank();

        // Test non-admin cannot go public
        vm.startPrank(user1);
        vm.expectRevert("CTMRWA1SentryManager: Not tokenAdmin");
        sentryManager.goPublic(ID, _stringToArray(cIdStr), feeTokenStr);
        vm.stopPrank();
    }

    // ============ FUZZ TESTS ============

    function test_fuzz_setSentryOptions(uint8 whitelist, uint8 kyc, uint8 kyb, uint8 over18, uint8 accredited, uint8 countryWL, uint8 countryBL) public {
        // Only test valid combinations to avoid too many rejections
        bool whitelistBool = whitelist % 2 == 1;
        bool kycBool = kyc % 2 == 1;
        bool kybBool = kyb % 2 == 1;
        bool over18Bool = over18 % 2 == 1;
        bool accreditedBool = accredited % 2 == 1;
        bool countryWLBool = countryWL % 2 == 1;
        bool countryBLBool = countryBL % 2 == 1;

        // Only run if valid
        if (!(whitelistBool || kycBool)) return;
        if (kybBool && !kycBool) return;
        if (over18Bool && !kycBool) return;
        if (accreditedBool && !kycBool) return;
        if (accreditedBool && !countryWLBool) return;
        if ((countryWLBool || countryBLBool) && !kycBool) return;
        if (countryWLBool && countryBLBool) return;

        vm.startPrank(tokenAdmin);
        (ID, token) = _deployCTMRWA1(address(usdc));
        _createSomeSlots(ID, address(usdc), address(rwa1X));
        string memory feeTokenStr = address(usdc).toHexString();
        sentryManager.setSentryOptions(
            ID,
            whitelistBool,
            kycBool,
            kybBool,
            over18Bool,
            accreditedBool,
            countryWLBool,
            countryBLBool,
            _stringToArray(cIdStr),
            feeTokenStr
        );
        (, address sentry) = map.getSentryContract(ID, RWA_TYPE, VERSION);
        assertEq(ICTMRWA1Sentry(sentry).whitelistSwitch(), whitelistBool);
        assertEq(ICTMRWA1Sentry(sentry).kycSwitch(), kycBool);
        assertEq(ICTMRWA1Sentry(sentry).kybSwitch(), kybBool);
        assertEq(ICTMRWA1Sentry(sentry).age18Switch(), over18Bool);
        assertEq(ICTMRWA1Sentry(sentry).accreditedSwitch(), accreditedBool);
        assertEq(ICTMRWA1Sentry(sentry).countryWLSwitch(), countryWLBool);
        assertEq(ICTMRWA1Sentry(sentry).countryBLSwitch(), countryBLBool);
        vm.stopPrank();
    }

    function test_fuzz_addWhitelist(uint256 numAddresses) public {
        vm.assume(numAddresses > 0 && numAddresses <= 10); // Reasonable bounds
        
        vm.startPrank(tokenAdmin);
        (ID, token) = _deployCTMRWA1(address(usdc));
        _createSomeSlots(ID, address(usdc), address(rwa1X));
        
        string memory feeTokenStr = address(usdc).toHexString();
        
        // Enable whitelist
        sentryManager.setSentryOptions(
            ID,
            true, // whitelistSwitch
            false,
            false,
            false,
            false,
            false,
            false,
            _stringToArray(cIdStr),
            feeTokenStr
        );

        // Generate random addresses
        string[] memory addresses = new string[](numAddresses);
        bool[] memory choices = new bool[](numAddresses);
        
        for (uint256 i = 0; i < numAddresses; i++) {
            address randomAddr = address(uint160(uint256(keccak256(abi.encodePacked(i, block.timestamp)))));
            addresses[i] = randomAddr.toHexString();
            choices[i] = i % 2 == 0; // Alternate true/false
        }

        sentryManager.addWhitelist(ID, addresses, choices, _stringToArray(cIdStr), feeTokenStr);
        
        // Verify whitelist was set correctly
        (, address sentry) = map.getSentryContract(ID, RWA_TYPE, VERSION);
        for (uint256 i = 0; i < numAddresses; i++) {
            bool isAllowed = ICTMRWA1Sentry(sentry).isAllowableTransfer(addresses[i]);
            assertEq(isAllowed, choices[i]);
        }
        vm.stopPrank();
    }

    // ============ EDGE CASE TESTS ============

    function test_edgeCase_emptyArrays() public {
        vm.startPrank(tokenAdmin);
        (ID, token) = _deployCTMRWA1(address(usdc));
        _createSomeSlots(ID, address(usdc), address(rwa1X));
        
        string memory feeTokenStr = address(usdc).toHexString();
        
        // Enable whitelist
        sentryManager.setSentryOptions(
            ID,
            true, // whitelistSwitch
            false,
            false,
            false,
            false,
            false,
            false,
            _stringToArray(cIdStr),
            feeTokenStr
        );

        // Test empty arrays
        string[] memory emptyAddresses = new string[](0);
        bool[] memory emptyChoices = new bool[](0);
        
        sentryManager.addWhitelist(ID, emptyAddresses, emptyChoices, _stringToArray(cIdStr), feeTokenStr);
        vm.stopPrank();
    }

    function test_edgeCase_mismatchedArrayLengths() public {
        vm.startPrank(tokenAdmin);
        (ID, token) = _deployCTMRWA1(address(usdc));
        _createSomeSlots(ID, address(usdc), address(rwa1X));
        
        string memory feeTokenStr = address(usdc).toHexString();
        
        // Enable whitelist
        sentryManager.setSentryOptions(
            ID,
            true, // whitelistSwitch
            false,
            false,
            false,
            false,
            false,
            false,
            _stringToArray(cIdStr),
            feeTokenStr
        );

        // Test mismatched array lengths
        string[] memory addresses = _stringToArray(user1.toHexString());
        bool[] memory choices = new bool[](2); // Different length
        
        vm.expectRevert("CTMRWA1SentryManager: addWhitelist parameters lengths not equal");
        sentryManager.addWhitelist(ID, addresses, choices, _stringToArray(cIdStr), feeTokenStr);
        vm.stopPrank();
    }

    function test_edgeCase_whitelistWithoutEnabling() public {
        vm.startPrank(tokenAdmin);
        (ID, token) = _deployCTMRWA1(address(usdc));
        _createSomeSlots(ID, address(usdc), address(rwa1X));
        
        string memory feeTokenStr = address(usdc).toHexString();
        
        // Don't enable whitelist
        vm.expectRevert("CTMRWA1SentryManager: The whitelistSwitch has not been set");
        sentryManager.addWhitelist(
            ID,
            _stringToArray(user1.toHexString()),
            _boolToArray(true),
            _stringToArray(cIdStr),
            feeTokenStr
        );
        vm.stopPrank();
    }

    function test_edgeCase_countryListWithoutEnabling() public {
        vm.startPrank(tokenAdmin);
        (ID, token) = _deployCTMRWA1(address(usdc));
        _createSomeSlots(ID, address(usdc), address(rwa1X));
        
        string memory feeTokenStr = address(usdc).toHexString();
        
        // Don't enable country lists
        vm.expectRevert("CTMRWA1SentryManager: Neither country whitelist or blacklist has been set");
        sentryManager.addCountrylist(
            ID,
            _stringToArray("US"),
            _boolToArray(true),
            _stringToArray(cIdStr),
            feeTokenStr
        );
        vm.stopPrank();
    }

    // ============ VALIDATION TESTS ============

    function test_validation_setSentryOptions_noWhitelistNoKYC() public {
        vm.startPrank(tokenAdmin);
        (ID, token) = _deployCTMRWA1(address(usdc));
        _createSomeSlots(ID, address(usdc), address(rwa1X));
        
        string memory feeTokenStr = address(usdc).toHexString();
        
        vm.expectRevert("CTMRWA1SentryManager: Must set either whitelist or KYC");
        sentryManager.setSentryOptions(
            ID,
            false, // whitelistSwitch
            false, // kycSwitch
            false,
            false,
            false,
            false,
            false,
            _stringToArray(cIdStr),
            feeTokenStr
        );
        vm.stopPrank();
    }

    function test_validation_setSentryOptions_kybWithoutKYC() public {
        vm.startPrank(tokenAdmin);
        (ID, token) = _deployCTMRWA1(address(usdc));
        _createSomeSlots(ID, address(usdc), address(rwa1X));
        
        string memory feeTokenStr = address(usdc).toHexString();
        
        vm.expectRevert("CTMRWA1SentryManager: Must set KYC to use KYB");
        sentryManager.setSentryOptions(
            ID,
            true, // whitelistSwitch
            false, // kycSwitch
            true, // kybSwitch
            false,
            false,
            false,
            false,
            _stringToArray(cIdStr),
            feeTokenStr
        );
        vm.stopPrank();
    }

    function test_validation_setSentryOptions_over18WithoutKYC() public {
        vm.startPrank(tokenAdmin);
        (ID, token) = _deployCTMRWA1(address(usdc));
        _createSomeSlots(ID, address(usdc), address(rwa1X));
        
        string memory feeTokenStr = address(usdc).toHexString();
        
        vm.expectRevert("CTMRWA1SentryManager: Must set KYC to use over18 flag");
        sentryManager.setSentryOptions(
            ID,
            true, // whitelistSwitch
            false, // kycSwitch
            false, // kybSwitch
            true, // over18Switch
            false,
            false,
            false,
            _stringToArray(cIdStr),
            feeTokenStr
        );
        vm.stopPrank();
    }

    function test_validation_setSentryOptions_accreditedWithoutKYC() public {
        vm.startPrank(tokenAdmin);
        (ID, token) = _deployCTMRWA1(address(usdc));
        _createSomeSlots(ID, address(usdc), address(rwa1X));
        
        string memory feeTokenStr = address(usdc).toHexString();
        
        vm.expectRevert("CTMRWA1SentryManager: Must set KYC to use Accredited flag");
        sentryManager.setSentryOptions(
            ID,
            true, // whitelistSwitch
            false, // kycSwitch
            false, // kybSwitch
            false, // over18Switch
            true, // accreditedSwitch
            false,
            false,
            _stringToArray(cIdStr),
            feeTokenStr
        );
        vm.stopPrank();
    }

    function test_validation_setSentryOptions_accreditedWithoutCountryWL() public {
        vm.startPrank(tokenAdmin);
        (ID, token) = _deployCTMRWA1(address(usdc));
        _createSomeSlots(ID, address(usdc), address(rwa1X));
        
        string memory feeTokenStr = address(usdc).toHexString();
        
        vm.expectRevert("CTMRWA1SentryManager: Must set Country white lists to use Accredited");
        sentryManager.setSentryOptions(
            ID,
            false, // whitelistSwitch
            true, // kycSwitch
            false, // kybSwitch
            true, // over18Switch
            true, // accreditedSwitch
            false, // countryWLSwitch
            false, // countryBLSwitch
            _stringToArray(cIdStr),
            feeTokenStr
        );
        vm.stopPrank();
    }

    function test_validation_setSentryOptions_countryListsWithoutKYC() public {
        vm.startPrank(tokenAdmin);
        (ID, token) = _deployCTMRWA1(address(usdc));
        _createSomeSlots(ID, address(usdc), address(rwa1X));
        
        string memory feeTokenStr = address(usdc).toHexString();
        
        vm.expectRevert("CTMRWA1SentryManager: Must set KYC to use Country black or white lists");
        sentryManager.setSentryOptions(
            ID,
            true, // whitelistSwitch
            false, // kycSwitch
            false, // kybSwitch
            false, // over18Switch
            false, // accreditedSwitch
            true, // countryWLSwitch
            false,
            _stringToArray(cIdStr),
            feeTokenStr
        );
        vm.stopPrank();
    }

    function test_validation_setSentryOptions_bothCountryLists() public {
        vm.startPrank(tokenAdmin);
        (ID, token) = _deployCTMRWA1(address(usdc));
        _createSomeSlots(ID, address(usdc), address(rwa1X));
        
        string memory feeTokenStr = address(usdc).toHexString();
        
        vm.expectRevert("CTMRWA1SentryManager: Cannot set Country blacklist and Country whitelist together");
        sentryManager.setSentryOptions(
            ID,
            false, // whitelistSwitch
            true, // kycSwitch
            false, // kybSwitch
            false, // over18Switch
            false, // accreditedSwitch
            true, // countryWLSwitch
            true, // countryBLSwitch
            _stringToArray(cIdStr),
            feeTokenStr
        );
        vm.stopPrank();
    }

    // ============ STATE TRANSITION TESTS ============

    function test_stateTransition_goPublic() public {
        vm.startPrank(tokenAdmin);
        (ID, token) = _deployCTMRWA1(address(usdc));
        _createSomeSlots(ID, address(usdc), address(rwa1X));
        
        string memory feeTokenStr = address(usdc).toHexString();
        
        // Set up KYC and accredited
        sentryManager.setSentryOptions(
            ID,
            false,
            true, // kycSwitch
            false,
            true, // over18Switch
            true, // accreditedSwitch
            true, // countryWLSwitch
            false,
            _stringToArray(cIdStr),
            feeTokenStr
        );

        (, address sentry) = map.getSentryContract(ID, RWA_TYPE, VERSION);
        assertEq(ICTMRWA1Sentry(sentry).accreditedSwitch(), true);

        // Go public
        sentryManager.goPublic(ID, _stringToArray(cIdStr), feeTokenStr);

        // Verify accredited is now false
        assertEq(ICTMRWA1Sentry(sentry).accreditedSwitch(), false);
        vm.stopPrank();
    }

    function test_stateTransition_goPublicWithoutKYC() public {
        vm.startPrank(tokenAdmin);
        (ID, token) = _deployCTMRWA1(address(usdc));
        _createSomeSlots(ID, address(usdc), address(rwa1X));
        
        string memory feeTokenStr = address(usdc).toHexString();
        
        // Set up whitelist only (no KYC)
        sentryManager.setSentryOptions(
            ID,
            true, // whitelistSwitch
            false, // kycSwitch
            false,
            false,
            false,
            false,
            false,
            _stringToArray(cIdStr),
            feeTokenStr
        );

        vm.expectRevert("CTMRWA1SentryManager: KYC was not set, so cannot go public");
        sentryManager.goPublic(ID, _stringToArray(cIdStr), feeTokenStr);
        vm.stopPrank();
    }

    function test_stateTransition_goPublicWithoutAccredited() public {
        vm.startPrank(tokenAdmin);
        (ID, token) = _deployCTMRWA1(address(usdc));
        _createSomeSlots(ID, address(usdc), address(rwa1X));
        
        string memory feeTokenStr = address(usdc).toHexString();
        
        // Set up KYC but not accredited
        sentryManager.setSentryOptions(
            ID,
            false,
            true, // kycSwitch
            false,
            true, // over18Switch
            false, // accreditedSwitch
            true, // countryWLSwitch
            false,
            _stringToArray(cIdStr),
            feeTokenStr
        );

        vm.expectRevert("CTMRWA1SentryManager: Accredited was not set, so cannot go public");
        sentryManager.goPublic(ID, _stringToArray(cIdStr), feeTokenStr);
        vm.stopPrank();
    }

    // ============ WHITELIST FUNCTIONALITY TESTS ============

    function test_whitelist_basicFunctionality() public {
        vm.startPrank(tokenAdmin);
        (ID, token) = _deployCTMRWA1(address(usdc));
        _createSomeSlots(ID, address(usdc), address(rwa1X));
        
        string memory feeTokenStr = address(usdc).toHexString();
        string memory user1Str = user1.toHexString();
        string memory user2Str = user2.toHexString();

        (, address sentry) = map.getSentryContract(ID, RWA_TYPE, VERSION);

        // Initially all addresses are allowable
        bool ok = ICTMRWA1Sentry(sentry).isAllowableTransfer(user2Str);
        assertEq(ok, true);

        // Enable whitelist
        sentryManager.setSentryOptions(
            ID,
            true, // whitelistSwitch
            false,
            false,
            false,
            false,
            false,
            false,
            _stringToArray(cIdStr),
            feeTokenStr
        );

        // After enabling whitelist, addresses not in whitelist are not allowable
        ok = ICTMRWA1Sentry(sentry).isAllowableTransfer(user2Str);
        assertEq(ok, false);

        // Add addresses to whitelist
        sentryManager.addWhitelist(
            ID,
            _stringToArray(user1Str),
            _boolToArray(true),
            _stringToArray(cIdStr),
            feeTokenStr
        );

        sentryManager.addWhitelist(
            ID,
            _stringToArray(user2Str),
            _boolToArray(true),
            _stringToArray(cIdStr),
            feeTokenStr
        );

        // Verify addresses are now allowable
        ok = ICTMRWA1Sentry(sentry).isAllowableTransfer(user2Str);
        assertEq(ok, true);

        // Remove address from whitelist
        sentryManager.addWhitelist(
            ID,
            _stringToArray(user1Str),
            _boolToArray(false),
            _stringToArray(cIdStr),
            feeTokenStr
        );

        // Verify address is no longer allowable
        ok = ICTMRWA1Sentry(sentry).isAllowableTransfer(user1Str);
        assertEq(ok, false);
        ok = ICTMRWA1Sentry(sentry).isAllowableTransfer(user2Str);
        assertEq(ok, true);

        vm.stopPrank();
    }

    function test_whitelist_tokenAdminProtection() public {
        vm.startPrank(tokenAdmin);
        (ID, token) = _deployCTMRWA1(address(usdc));
        _createSomeSlots(ID, address(usdc), address(rwa1X));
        
        string memory feeTokenStr = address(usdc).toHexString();
        string memory tokenAdminStr = tokenAdmin.toHexString();

        // Enable whitelist
        sentryManager.setSentryOptions(
            ID,
            true, // whitelistSwitch
            false,
            false,
            false,
            false,
            false,
            false,
            _stringToArray(cIdStr),
            feeTokenStr
        );

        // Change token admin
        rwa1X.changeTokenAdmin(user1.toHexString(), _stringToArray(cIdStr), ID, feeTokenStr);
        
        (, address sentry) = map.getSentryContract(ID, RWA_TYPE, VERSION);
        address newAdmin = ICTMRWA1Sentry(sentry).tokenAdmin();
        assertEq(newAdmin, user1);
        string memory newAdminStr = user1.toHexString();

        // Old tokenAdmin should still be in whitelist
        bool ok = ICTMRWA1Sentry(sentry).isAllowableTransfer(tokenAdminStr);
        assertEq(ok, true);

        // New admin cannot remove themselves from whitelist
        vm.stopPrank();
        vm.startPrank(user1);
        vm.expectRevert("CTMRWA1Sentry: Cannot remove tokenAdmin from the whitelist");
        sentryManager.addWhitelist(
            ID,
            _stringToArray(newAdminStr),
            _boolToArray(false),
            _stringToArray(cIdStr),
            feeTokenStr
        );
        vm.stopPrank();
    }

    // ============ CROSS-CHAIN TESTS ============

    function test_crossChain_setSentryOptionsX() public {
        vm.prank(tokenAdmin);
        (ID, token) = _deployCTMRWA1(address(usdc));

        vm.startPrank(address(c3caller));

        sentryManager.setSentryOptionsX(
            ID,
            true, // whitelistSwitch
            true, // kycSwitch
            false, // kybSwitch
            true, // over18Switch
            false, // accreditedSwitch
            false, // countryWLSwitch
            false // countryBLSwitch
        );

        (, address sentry) = map.getSentryContract(ID, RWA_TYPE, VERSION);

        bool whitelistSwitch = ICTMRWA1Sentry(sentry).whitelistSwitch();
        assertEq(whitelistSwitch, true);
        bool kycSwitch = ICTMRWA1Sentry(sentry).kycSwitch();
        assertEq(kycSwitch, true);

        vm.stopPrank();
    }

    // ============ INVARIANT TESTS ============

    function test_invariant_sentryOptionsSetOnlyOnce() public {
        vm.startPrank(tokenAdmin);
        (ID, token) = _deployCTMRWA1(address(usdc));
        _createSomeSlots(ID, address(usdc), address(rwa1X));
        
        string memory feeTokenStr = address(usdc).toHexString();
        
        // Set sentry options
        sentryManager.setSentryOptions(
            ID,
            true, // whitelistSwitch
            false,
            false,
            false,
            false,
            false,
            false,
            _stringToArray(cIdStr),
            feeTokenStr
        );

        // Cannot set sentry options again
        vm.expectRevert("CTMRWA1SentryManager: Error. setSentryOptions has already been called");
        sentryManager.setSentryOptions(
            ID,
            false, // whitelistSwitch
            true, // kycSwitch
            false, // kybSwitch
            true, // over18Switch
            false, // accreditedSwitch
            false, // countryWLSwitch
            false, // countryBLSwitch
            _stringToArray(cIdStr),
            feeTokenStr
        );
        vm.stopPrank();
    }

    function test_invariant_kycDisabledAfterGoPublic() public {
        vm.startPrank(tokenAdmin);
        (ID, token) = _deployCTMRWA1(address(usdc));
        _createSomeSlots(ID, address(usdc), address(rwa1X));
        
        string memory feeTokenStr = address(usdc).toHexString();
        
        // Set up KYC and accredited
        sentryManager.setSentryOptions(
            ID,
            false,
            true, // kycSwitch
            false,
            true, // over18Switch
            true, // accreditedSwitch
            true, // countryWLSwitch
            false,
            _stringToArray(cIdStr),
            feeTokenStr
        );

        // Go public
        sentryManager.goPublic(ID, _stringToArray(cIdStr), feeTokenStr);

        // KYC should be disabled for new deployments
        vm.expectRevert(abi.encodeWithSelector(ICTMRWA1X.CTMRWA1X_InvalidList.selector, List.WhiteListEnabled));
        rwa1X.deployAllCTMRWA1X(
            false, // include local mint
            ID,
            RWA_TYPE,
            VERSION,
            "Token Name",
            "Symbol",
            18,
            "GFLD",
            _stringToArray("1"), // extend to another chain
            feeTokenStr
        );
        vm.stopPrank();
    }

}
