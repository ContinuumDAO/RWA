// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.27;

import { ICTMRWA1 } from "../../src/core/ICTMRWA1.sol";
import { Address } from "../../src/core/ICTMRWA1.sol";
import { ICTMRWA1Sentry } from "../../src/sentry/ICTMRWA1Sentry.sol";
import { Uint } from "../../src/utils/CTMRWAUtils.sol";
import { Helpers } from "../helpers/Helpers.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

contract TestCTMRWA1Sentry is Helpers {
    using Strings for address;

    ICTMRWA1Sentry sentry;
    address sentryAddr;

    function setUp() public override {
        super.setUp();
        vm.startPrank(tokenAdmin);
        (ID, token) = _deployCTMRWA1(address(usdc));
        vm.stopPrank();
        (, sentryAddr) = map.getSentryContract(ID, RWA_TYPE, VERSION);
        sentry = ICTMRWA1Sentry(sentryAddr);
    }

    // ========== GETTERS =============
    function test_ID() public view {
        assertEq(sentry.ID(), ID);
    }

    function test_tokenAdmin() public view {
        assertEq(sentry.tokenAdmin(), tokenAdmin);
    }

    function test_RWA_TYPE_and_VERSION() public view {
        assertEq(sentry.RWA_TYPE(), RWA_TYPE);
        assertEq(sentry.VERSION(), VERSION);
    }

    function test_ctmWhitelist_and_countryList_initial() public view {
        // ctmWhitelist[0] is always 0xffff...ffff
        assertEq(sentry.ctmWhitelist(0), "0xffffffffffffffffffffffffffffffffffffffff");
        // countryList[0] is always "NOGO"
        assertEq(sentry.countryList(0), "NOGO");
    }

    function test_getWhitelistLength_and_getWhitelistAddressAtIndx() public {
        uint256 len = sentry.getWhitelistLength();
        // Should be 1 (tokenAdmin added in constructor)
        assertEq(len, 1);
        // tokenAdmin is at index 1
        assertEq(sentry.getWhitelistAddressAtIndx(1), tokenAdmin.toHexString());
    }

    function test_getZkMeParams_default() public view {
        (string memory appId, string memory programNo, address cooperator) = sentry.getZkMeParams();
        assertEq(appId, "");
        assertEq(programNo, "");
        assertEq(cooperator, address(0));
    }

    function test_switches_defaults() public {
        assertEq(sentry.whitelistSwitch(), false);
        assertEq(sentry.kycSwitch(), false);
        assertEq(sentry.kybSwitch(), false);
        assertEq(sentry.countryWLSwitch(), false);
        assertEq(sentry.countryBLSwitch(), false);
        assertEq(sentry.accreditedSwitch(), false);
        assertEq(sentry.age18Switch(), false);
        assertEq(sentry.sentryOptionsSet(), false);
    }

    // ========== SETTERS: ACCESS CONTROL =============
    function test_setTokenAdmin_access() public {
        address newAdmin = tokenAdmin2;
        // Only tokenAdmin or ctmRwa1X can call
        vm.prank(user1);
        vm.expectRevert(abi.encodeWithSelector(ICTMRWA1Sentry.CTMRWA1Sentry_OnlyAuthorized.selector, Address.Sender, Address.TokenAdmin));
        sentry.setTokenAdmin(newAdmin);
        // ctmRwa1X can call
        vm.prank(address(rwa1X));
        sentry.setTokenAdmin(newAdmin);
        // tokenAdmin can call
        vm.prank(newAdmin);
        sentry.setTokenAdmin(tokenAdmin);
    }

    function test_setTokenAdmin_effect() public {
        address newAdmin = tokenAdmin2;
        vm.prank(tokenAdmin);
        sentry.setTokenAdmin(newAdmin);
        assertEq(sentry.tokenAdmin(), newAdmin);
        // Should be whitelisted
        assertTrue(sentry.isAllowableTransfer(newAdmin.toHexString()));
    }

    function test_setZkMeParams_access() public {
        // Only sentryManager can call
        vm.prank(user1);
        vm.expectRevert();
        sentry.setZkMeParams("app", "prog", user2);
        vm.prank(address(sentryManager));
        sentry.setZkMeParams("app", "prog", user2);
    }

    function test_setZkMeParams_effect() public {
        vm.prank(address(sentryManager));
        sentry.setZkMeParams("appId", "progNo", user2);
        (string memory appId, string memory progNo, address coop) = sentry.getZkMeParams();
        assertEq(appId, "appId");
        assertEq(progNo, "progNo");
        assertEq(coop, user2);
    }

    function test_setSentryOptionsLocal_access() public {
        // Only sentryManager can call
        vm.prank(user1);
        vm.expectRevert();
        sentry.setSentryOptionsLocal(ID, true, true, true, true, true, true, true);
        vm.prank(address(sentryManager));
        sentry.setSentryOptionsLocal(ID, true, true, true, true, true, true, true);
    }

    function test_setSentryOptionsLocal_effect_countryWL() public {
        // Deploy a new token and sentry for this test
        vm.startPrank(tokenAdmin);
        skip(10);
        (uint256 newID,) = _deployCTMRWA1(address(usdc));
        vm.stopPrank();
        (, address newSentryAddr) = map.getSentryContract(newID, RWA_TYPE, VERSION);
        ICTMRWA1Sentry newSentry = ICTMRWA1Sentry(newSentryAddr);
        vm.prank(address(sentryManager));
        newSentry.setSentryOptionsLocal(newID, true, true, true, true, true, true, false);
        assertTrue(newSentry.whitelistSwitch());
        assertTrue(newSentry.kycSwitch());
        assertTrue(newSentry.kybSwitch());
        assertTrue(newSentry.age18Switch());
        assertTrue(newSentry.countryWLSwitch());
        assertTrue(newSentry.accreditedSwitch());
        assertFalse(newSentry.countryBLSwitch());
        assertTrue(newSentry.sentryOptionsSet());
    }

    function test_setSentryOptionsLocal_effect_countryBL() public {
        // Deploy a new token and sentry for this test
        vm.startPrank(tokenAdmin);
        skip(10);
        (uint256 newID,) = _deployCTMRWA1(address(usdc));
        vm.stopPrank();
        (, address newSentryAddr) = map.getSentryContract(newID, RWA_TYPE, VERSION);
        ICTMRWA1Sentry newSentry = ICTMRWA1Sentry(newSentryAddr);
        vm.prank(address(sentryManager));
        newSentry.setSentryOptionsLocal(newID, true, true, true, true, true, false, true);
        assertTrue(newSentry.whitelistSwitch());
        assertTrue(newSentry.kycSwitch());
        assertTrue(newSentry.kybSwitch());
        assertTrue(newSentry.age18Switch());
        assertFalse(newSentry.countryWLSwitch());
        // accreditedSwitch is only set when countryWLSwitch is true
        assertFalse(newSentry.accreditedSwitch());
        assertTrue(newSentry.countryBLSwitch());
        assertTrue(newSentry.sentryOptionsSet());
    }

    function test_setWhitelistSentry_access() public {
        string[] memory wallets = new string[](1);
        wallets[0] = user1.toHexString();
        bool[] memory choices = new bool[](1);
        choices[0] = true;
        // Only sentryManager can call
        vm.prank(user1);
        vm.expectRevert();
        sentry.setWhitelistSentry(ID, wallets, choices);
        vm.prank(address(sentryManager));
        sentry.setWhitelistSentry(ID, wallets, choices);
    }

    function test_setWhitelistSentry_effect() public {
        // Enable whitelist enforcement
        vm.prank(address(sentryManager));
        sentry.setSentryOptionsLocal(ID, true, false, false, false, false, false, false);

        string[] memory wallets = new string[](2);
        wallets[0] = user1.toHexString();
        wallets[1] = user2.toHexString();
        bool[] memory choices = new bool[](2);
        choices[0] = true;
        choices[1] = false;
        vm.prank(address(sentryManager));
        sentry.setWhitelistSentry(ID, wallets, choices);
        assertTrue(sentry.isAllowableTransfer(user1.toHexString()));
        assertFalse(sentry.isAllowableTransfer(user2.toHexString()));
    }

    function test_setCountryListLocal_access() public {
        string[] memory countries = new string[](1);
        countries[0] = "US";
        bool[] memory choices = new bool[](1);
        choices[0] = true;
        // Only sentryManager can call
        vm.prank(user1);
        vm.expectRevert();
        sentry.setCountryListLocal(ID, countries, choices);
        vm.prank(address(sentryManager));
        sentry.setCountryListLocal(ID, countries, choices);
    }

    function test_setCountryListLocal_effect() public {
        string[] memory countries = new string[](2);
        countries[0] = "US";
        countries[1] = "GB";
        bool[] memory choices = new bool[](2);
        choices[0] = true;
        choices[1] = true;
        vm.prank(address(sentryManager));
        sentry.setCountryListLocal(ID, countries, choices);
        // Should be present in countryList
        assertEq(sentry.countryList(1), "US");
        assertEq(sentry.countryList(2), "GB");
    }

    // ========== FUNCTIONAL =============
    function test_isAllowableTransfer_logic() public {
        // By default, whitelistSwitch is false, so any address is allowed
        assertTrue(sentry.isAllowableTransfer(user1.toHexString()));
        // Enable whitelist
        vm.prank(address(sentryManager));
        sentry.setSentryOptionsLocal(ID, true, false, false, false, false, false, false);
        // Only whitelisted addresses allowed
        string[] memory wallets = new string[](1);
        wallets[0] = user1.toHexString();
        bool[] memory choices = new bool[](1);
        choices[0] = true;
        vm.prank(address(sentryManager));
        sentry.setWhitelistSentry(ID, wallets, choices);
        assertTrue(sentry.isAllowableTransfer(user1.toHexString()));
        assertFalse(sentry.isAllowableTransfer(user2.toHexString()));
    }
}
