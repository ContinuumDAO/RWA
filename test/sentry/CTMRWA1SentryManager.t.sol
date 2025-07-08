// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.22;

import { Test } from "forge-std/Test.sol";
import { console } from "forge-std/console.sol";

import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

import { Helpers } from "../helpers/Helpers.sol";

import { ICTMRWA1Sentry } from "../../src/sentry/ICTMRWA1Sentry.sol";
import { ICTMRWA1Storage } from "../../src/storage/ICTMRWA1Storage.sol";
import { ICTMRWA1Storage, URICategory, URIData, URIType } from "../../src/storage/ICTMRWA1Storage.sol";

contract TestSentryManager is Helpers {
    using Strings for *;

    function test_sentryOptions() public {
        vm.startPrank(tokenAdmin);
        (ID, token) = _deployCTMRWA1(address(usdc));
        _createSomeSlots(ID, address(usdc), address(rwa1X));

        string memory feeTokenStr = address(usdc).toHexString();

        (bool ok, address sentry) = map.getSentryContract(ID, RWA_TYPE, VERSION);
        assertEq(ok, true);

        vm.stopPrank();

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

        vm.startPrank(tokenAdmin);

        vm.expectRevert("CTMRWA1SentryManager: Must set either whitelist or KYC");
        sentryManager.setSentryOptions(
            ID,
            false, // whitelistSwitch
            false, // kycSwitch
            false, // KYB
            false, // over18
            false, // accredited
            false, // country WL
            false, // country BL
            _stringToArray(cIdStr),
            feeTokenStr
        );

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

        vm.expectRevert("CTMRWA1SentryManager: Must set KYC to use over18 flag");
        sentryManager.setSentryOptions(
            ID,
            true, // whitelistSwitch
            false, // kycSwitch
            false, // kybSwitch
            true, // over18Switch
            false, // accredited
            false, // country WL
            false, // country BL
            _stringToArray(cIdStr),
            feeTokenStr
        );

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

        vm.expectRevert("CTMRWA1SentryManager: Must set KYC to use Country black or white lists");
        sentryManager.setSentryOptions(
            ID,
            true, // whitelistSwitch
            false, // kycSwitch
            false, // kybSwitch
            false, // over18Switch
            false, // accreditedSwitch
            false, // countryWLSwitch
            true, // countryBLSwitch
            _stringToArray(cIdStr),
            feeTokenStr
        );

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

        sentryManager.setSentryOptions(
            ID,
            false, // whitelistSwitch
            true, // kycSwitch
            false, // kybSwitch
            true, // over18Switch
            true, // accreditedSwitch
            true, // countryWLSwitch
            false, // countryBLSwitch
            _stringToArray(cIdStr),
            feeTokenStr
        );

        bool newAccredited = ICTMRWA1Sentry(sentry).accreditedSwitch();
        assertEq(newAccredited, true);

        sentryManager.goPublic(ID, _stringToArray(cIdStr), feeTokenStr);

        newAccredited = ICTMRWA1Sentry(sentry).accreditedSwitch();
        assertEq(newAccredited, false);

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

        vm.expectRevert("RWAX: Whitelist or kyc set No new chains");
        rwa1X.deployAllCTMRWA1X(
            false, // include local mint
            ID,
            RWA_TYPE,
            VERSION,
            "",
            "",
            18,
            "",
            _stringToArray("1"), // extend to another chain
            feeTokenStr
        );

        vm.stopPrank();
    }

    function test_setSentryOptionsX() public {
        // function setSentryOptionsX(
        //     uint256 _ID,
        //     bool _whitelist,
        //     bool _kyc,
        //     bool _kyb,
        //     bool _over18,
        //     bool _accredited,
        //     bool _countryWL,
        //     bool _countryBL
        // ) external onlyCaller returns(bool) {

        vm.startPrank(tokenAdmin); // this CTMRWA1 has an admin of admin
        (ID, token) = _deployCTMRWA1(address(usdc));

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

    function test_whitelists() public {
        vm.startPrank(tokenAdmin);
        (ID, token) = _deployCTMRWA1(address(usdc));
        _createSomeSlots(ID, address(usdc), address(rwa1X));

        string memory feeTokenStr = address(usdc).toHexString();

        (bool ok, address sentry) = map.getSentryContract(ID, RWA_TYPE, VERSION);

        string memory tokenAdminStr = tokenAdmin.toHexString();
        string memory user1Str = user1.toHexString();
        string memory user2Str = user2.toHexString();

        ok = ICTMRWA1Sentry(sentry).isAllowableTransfer(user2Str);
        assertEq(ok, true); // whitelistSwitch not called yet, so all addresses are allowable

        bool wl = ICTMRWA1Sentry(sentry).whitelistSwitch();
        assertEq(wl, false); // whitelistSwitch not called yet
        // ICTMRWA1Sentry(sentry).setWhitelist();

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

        wl = ICTMRWA1Sentry(sentry).whitelistSwitch();
        assertEq(wl, true); // whitelistSwitch now set

        ok = ICTMRWA1Sentry(sentry).isAllowableTransfer(user2.toHexString());
        assertEq(ok, false); // user2 not in whitelist, so is not now allowable

        sentryManager.addWhitelist(
            ID, _stringToArray(user1Str), _boolToArray(true), _stringToArray(cIdStr), feeTokenStr
        );

        sentryManager.addWhitelist(
            ID, _stringToArray(user2Str), _boolToArray(true), _stringToArray(cIdStr), feeTokenStr
        );

        ok = ICTMRWA1Sentry(sentry).isAllowableTransfer(user2Str);
        assertEq(ok, true); // user2 is now allowable

        sentryManager.addWhitelist(
            ID, _stringToArray(user1Str), _boolToArray(false), _stringToArray(cIdStr), feeTokenStr
        );

        ok = ICTMRWA1Sentry(sentry).isAllowableTransfer(user1Str);
        assertEq(ok, false); // user1 was removed and is not now allowable
        ok = ICTMRWA1Sentry(sentry).isAllowableTransfer(user2Str);
        assertEq(ok, true); // user2 remains in whitelist

        string memory addr1 = ICTMRWA1Sentry(sentry).getWhitelistAddressAtIndx(1);
        assertEq(stringToAddress(addr1), tokenAdmin);
        string memory addr2 = ICTMRWA1Sentry(sentry).getWhitelistAddressAtIndx(2);
        assertEq(stringToAddress(addr2), user2);

        rwa1X.changeTokenAdmin(user1Str, _stringToArray(cIdStr), ID, feeTokenStr);
        address newAdmin = ICTMRWA1Sentry(sentry).tokenAdmin();
        assertEq(newAdmin, user1);

        // tokenAdmin was replaced with user1 as tokenAdmin, but still remains in whitelist (at the end)
        ok = ICTMRWA1Sentry(sentry).isAllowableTransfer(tokenAdminStr);
        assertEq(ok, true);

        vm.expectRevert("CTMRWA1SentryManager: Not tokenAdmin");
        sentryManager.addWhitelist(
            ID, _stringToArray(tokenAdminStr), _boolToArray(false), _stringToArray(cIdStr), feeTokenStr
        );

        vm.stopPrank();

        vm.startPrank(user1);

        vm.expectRevert("CTMRWA1Sentry: Cannot remove tokenAdmin from the whitelist");
        sentryManager.addWhitelist(
            ID, _stringToArray(user1Str), _boolToArray(false), _stringToArray(cIdStr), feeTokenStr
        );

        // Now we test token minting by the tokenAdmin

        uint256 newTokenId = rwa1X.mintNewTokenValueLocal(user2, 0, 5, 1000, ID, feeTokenStr);

        vm.expectRevert("RWA: Transfer token to address is not allowable");
        newTokenId = rwa1X.mintNewTokenValueLocal(treasury, 0, 5, 1000, ID, feeTokenStr);

        vm.stopPrank();

        // here we can test transferring some tokens owned by user2
        vm.startPrank(user2);

        vm.expectRevert("RWA: Transfer token to address is not allowable");
        rwa1X.transferWholeTokenX(user2Str, treasury.toHexString(), cIdStr, newTokenId, ID, feeTokenStr);

        vm.expectRevert("RWA: Transfer token to address is not allowable");
        rwa1X.transferPartialTokenX(newTokenId, treasury.toHexString(), cIdStr, 10, ID, feeTokenStr);

        token.approve(treasury, newTokenId);

        vm.stopPrank();

        vm.startPrank(treasury);
        rwa1X.transferWholeTokenX(user2Str, tokenAdminStr, cIdStr, newTokenId, ID, feeTokenStr);

        vm.stopPrank();
    }

    function test_countryList() public {
        vm.startPrank(tokenAdmin); // this CTMRWA1 has an admin of admin
        // console.log("admin");
        // console.log(admin);
        // console.log("user1");
        // console.log(user1);
        // console.log("user2");
        // console.log(user2);

        (ID, token) = _deployCTMRWA1(address(usdc));
        _createSomeSlots(ID, address(usdc), address(rwa1X));

        // (, address sentry) = map.getSentryContract(ID, RWA_TYPE, VERSION);

        // string memory adminStr = admin.toHexString();
        // string memory user1Str = user1.toHexString();
        // string memory user2Str = user2.toHexString();

        vm.stopPrank();
    }
}
