// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.27;

import { Helpers } from "../helpers/Helpers.sol";
import { CTMRWA1Identity } from "../../src/identity/CTMRWA1Identity.sol";
import { Address, CTMRWAUtils } from "../../src/CTMRWAUtils.sol";
import { FeeType } from "../../src/managers/IFeeManager.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { ICTMRWA1Sentry } from "../../src/sentry/ICTMRWA1Sentry.sol";
import { ICTMRWA1Identity } from "../../src/identity/ICTMRWA1Identity.sol";
import { console } from "forge-std/console.sol";

// Minimal mock for IZkMeVerify
contract MockZkMeVerify {
    bool public approved = true;
    function setApproved(bool _a) external { approved = _a; }
    function hasApproved(address, address) external view returns (bool) { return approved; }
}

contract TestCTMRWA1Identity is Helpers {
    using Strings for *;
    using CTMRWAUtils for string;

    CTMRWA1Identity identity;
    MockZkMeVerify zkMe;
    string feeTokenStr;
    string[] chainIds;
    address public sentryAddr;
    ICTMRWA1Sentry public sentry;

    function setUp() public override {
        super.setUp();
        zkMe = new MockZkMeVerify();
        feeTokenStr = address(usdc).toHexString();
        chainIds = new string[](1);
        chainIds[0] = cIdStr;
        // Deploy a token and get its ID
        vm.startPrank(tokenAdmin);
        (ID, token) = _deployCTMRWA1(address(usdc));
        vm.stopPrank();
        // Get the sentry address for this token
        (bool ok, address _sentryAddr) = map.getSentryContract(ID, RWA_TYPE, VERSION);
        require(ok, "Sentry not found");
        sentryAddr = _sentryAddr;
        sentry = ICTMRWA1Sentry(sentryAddr);
        // Deploy the identity contract with real map, sentryManager, feeManager, and mock zkMe
        identity = new CTMRWA1Identity(RWA_TYPE, VERSION, address(map), address(sentryManager), address(zkMe), address(feeManager));
        vm.prank(gov);
        sentryManager.setIdentity(address(identity), address(zkMe));
    }

    // --- Setters & Getters ---
    function test_setZkMeVerifierAddress_onlySentryManager() public {
        address newVerifier = address(0xCAFE);
        // Unauthorized
        vm.prank(user1);
        vm.expectRevert();
        sentryManager.setIdentity(address(identity), newVerifier);
        // Authorized
        vm.prank(gov);
        sentryManager.setIdentity(address(identity), newVerifier);
        assertEq(identity.zkMeVerifierAddress(), newVerifier);
        assertTrue(identity.isKycChain());
        vm.prank(gov);
        sentryManager.setIdentity(address(identity), address(0));
        assertFalse(identity.isKycChain());
    }

    // --- Access Control ---
    function test_onlyIdChain_revertIfZeroVerifier() public {
        vm.prank(gov);
        sentryManager.setIdentity(address(identity), address(0));
        vm.expectRevert(abi.encodeWithSelector(ICTMRWA1Identity.CTMRWA1Identity_IsZeroAddress.selector, Address.ZKMe));
        identity.isVerifiedPerson(ID, user1);
    }

    // --- verifyPerson: all revert paths ---
    function test_verifyPerson_revertIfZeroVerifier() public {
        vm.prank(gov);
        sentryManager.setIdentity(address(identity), address(0));
        vm.expectRevert(abi.encodeWithSelector(ICTMRWA1Identity.CTMRWA1Identity_IsZeroAddress.selector, Address.ZKMe));
        identity.verifyPerson(ID, chainIds, feeTokenStr);
    }
    function test_verifyPerson_revertIfInvalidContract() public {
        // Use a non-existent ID to force map.getSentryContract to fail
        uint256 badId = ID + 9999;
        vm.expectRevert(abi.encodeWithSelector(ICTMRWA1Identity.CTMRWA1Identity_InvalidContract.selector, Address.Sentry));
        identity.verifyPerson(badId, chainIds, feeTokenStr);
    }
    function test_verifyPerson_revertIfKYCDisabled() public {
        vm.prank(tokenAdmin);
        sentryManager.setSentryOptions(ID, true, false, false, false, false, false, false, chainIds, feeTokenStr);
        vm.expectRevert(abi.encodeWithSelector(ICTMRWA1Identity.CTMRWA1Identity_KYCDisabled.selector));
        identity.verifyPerson(ID, chainIds, feeTokenStr);
    }
    function test_verifyPerson_revertIfAlreadyWhitelisted() public {
        vm.prank(tokenAdmin);
        sentryManager.setSentryOptions(ID, true, true, false, false, false, false, false, chainIds, feeTokenStr);
        vm.prank(tokenAdmin);
        sentryManager.setZkMeParams(ID, "", "", address(0x1234));
        vm.prank(user1);
        identity.verifyPerson(ID, chainIds, feeTokenStr);
        vm.prank(user1);
        vm.expectRevert(abi.encodeWithSelector(ICTMRWA1Identity.CTMRWA1Identity_AlreadyWhitelisted.selector, user1));
        identity.verifyPerson(ID, chainIds, feeTokenStr);
    }
    function test_verifyPerson_revertIfZeroCooperator() public {
        vm.prank(tokenAdmin);
        sentryManager.setSentryOptions(ID, true, true, false, false, false, false, false, chainIds, feeTokenStr);
        vm.prank(tokenAdmin);
        sentryManager.setZkMeParams(ID, "", "", address(0));
        vm.expectRevert(abi.encodeWithSelector(ICTMRWA1Identity.CTMRWA1Identity_IsZeroAddress.selector, Address.Cooperator));
        identity.verifyPerson(ID, chainIds, feeTokenStr);
    }
    function test_verifyPerson_revertIfInvalidKYC() public {
        vm.prank(tokenAdmin);
        sentryManager.setSentryOptions(ID, true, true, false, false, false, false, false, chainIds, feeTokenStr);
        vm.prank(tokenAdmin);
        sentryManager.setZkMeParams(ID, "", "", address(0x1234));
        zkMe.setApproved(false);
        vm.prank(user1);
        vm.expectRevert(abi.encodeWithSelector(ICTMRWA1Identity.CTMRWA1Identity_InvalidKYC.selector, user1));
        identity.verifyPerson(ID, chainIds, feeTokenStr);
    }
    // --- verifyPerson: happy path ---
    function test_verifyPerson_success() public {
        vm.prank(tokenAdmin);
        sentryManager.setSentryOptions(ID, true, true, false, false, false, false, false, chainIds, feeTokenStr);
        vm.prank(tokenAdmin);
        sentryManager.setZkMeParams(ID, "", "", address(0x1234));
        zkMe.setApproved(true);
        vm.prank(user1);
        bool ok = identity.verifyPerson(ID, chainIds, feeTokenStr);
        assertTrue(ok);
        // User should now be whitelisted
        string memory userHex = user1.toHexString();
        assertTrue(sentry.isAllowableTransfer(userHex));
    }
    function test_verifyPerson_gasUsage() public {
        vm.prank(tokenAdmin);
        sentryManager.setSentryOptions(ID, true, true, false, false, false, false, false, chainIds, feeTokenStr);
        vm.prank(tokenAdmin);
        sentryManager.setZkMeParams(ID, "", "", address(0x1234));
        zkMe.setApproved(true);
        vm.prank(user1);
        uint256 gasBefore = gasleft();
        identity.verifyPerson(ID, chainIds, feeTokenStr);
        uint256 gasAfter = gasleft();
        uint256 gasUsed = gasBefore - gasAfter;
        // console.log("Gas used by verifyPerson (happy path):", gasUsed);
        assertLt(gasUsed, 1_200_000, "verifyPerson should use less than 1,200,000 gas");
    }
    // --- isVerifiedPerson ---
    function test_isVerifiedPerson_revertIfInvalidContract() public {
        uint256 badId = ID + 9999;
        vm.expectRevert(abi.encodeWithSelector(ICTMRWA1Identity.CTMRWA1Identity_InvalidContract.selector, Address.Sentry));
        identity.isVerifiedPerson(badId, user1);
    }
    function test_isVerifiedPerson_revertIfKYCDisabled() public {
        vm.prank(tokenAdmin);
        sentryManager.setSentryOptions(ID, true, false, false, false, false, false, false, chainIds, feeTokenStr);
        vm.expectRevert(abi.encodeWithSelector(ICTMRWA1Identity.CTMRWA1Identity_KYCDisabled.selector));
        identity.isVerifiedPerson(ID, user1);
    }
    function test_isVerifiedPerson_revertIfZeroCooperator() public {
        vm.prank(tokenAdmin);
        sentryManager.setSentryOptions(ID, true, true, false, false, false, false, false, chainIds, feeTokenStr);
        vm.prank(tokenAdmin);
        sentryManager.setZkMeParams(ID, "", "", address(0));
        vm.expectRevert(abi.encodeWithSelector(ICTMRWA1Identity.CTMRWA1Identity_IsZeroAddress.selector, Address.Cooperator));
        identity.isVerifiedPerson(ID, user1);
    }
    function test_isVerifiedPerson_success() public {
        vm.prank(tokenAdmin);
        sentryManager.setSentryOptions(ID, true, true, false, false, false, false, false, chainIds, feeTokenStr);
        vm.prank(tokenAdmin);
        sentryManager.setZkMeParams(ID, "", "", address(0x1234));
        zkMe.setApproved(true);
        bool ok = identity.isVerifiedPerson(ID, user1);
        assertTrue(ok);
        zkMe.setApproved(false);
        ok = identity.isVerifiedPerson(ID, user1);
        assertFalse(ok);
    }

}
