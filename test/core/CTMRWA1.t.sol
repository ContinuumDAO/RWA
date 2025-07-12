// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.22;

import { console } from "forge-std/console.sol";

import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

import { Helpers } from "../helpers/Helpers.sol";

import { ICTMRWA1, Address } from "../../src/core/ICTMRWA1.sol";
import { ICTMRWA1Storage, URICategory, URIData, URIType } from "../../src/storage/ICTMRWA1Storage.sol";

contract TestCTMRWA1 is Helpers {
    using Strings for *;

    function test_changeAdmin() public {
        vm.startPrank(tokenAdmin);
        (ID, token) = _deployCTMRWA1(address(usdc));
        vm.stopPrank();

        // Check that an address other than tokenAdmin cannot changeAdmin
        vm.prank(tokenAdmin2);
        vm.expectRevert(abi.encodeWithSelector(ICTMRWA1.CTMRWA1_Unauthorized.selector, Address.Sender));
        token.changeAdmin(tokenAdmin2);

        // Check that changeAdmin sets the correct new admin and returns true
        vm.prank(address(rwa1X));
        bool ok = token.changeAdmin(tokenAdmin2);
        assertEq(token.tokenAdmin(), tokenAdmin2);
        assertTrue(ok);

        // Check that the override wallet was reset to address(0)
        assertEq(token.overrideWallet(), address(0));
    }

    function test_attachId() public {
        vm.startPrank(tokenAdmin);
        (ID, token) = _deployCTMRWA1(address(usdc));
        vm.stopPrank();

        // Check that an address other than address(rwa1X) cannot attachId
        vm.prank(address(tokenAdmin));
        vm.expectRevert(abi.encodeWithSelector(ICTMRWA1.CTMRWA1_Unauthorized.selector, Address.Sender));
        token.attachId(ID, tokenAdmin);

        vm.prank(address(rwa1X));
        // Check that the tokenAdmin address passed into the function by rwa1X is indeed the tokenAdmin
        vm.expectRevert(abi.encodeWithSelector(ICTMRWA1.CTMRWA1_Unauthorized.selector, Address.TokenAdmin));
        token.attachId(ID, tokenAdmin2);

        vm.prank(address(rwa1X));
        // Check that the attachId returns false (the ID was previously assigned);
        bool ok = token.attachId(ID, tokenAdmin);
        assertFalse(ok);
    }

    function test_attachDividend() public {
        vm.startPrank(tokenAdmin);
        (ID, token) = _deployCTMRWA1(address(usdc));
        vm.stopPrank();

        // Check that an address other than ctmRwaMap cannot attach dividend contract
        vm.prank(tokenAdmin);
        vm.expectRevert(abi.encodeWithSelector(ICTMRWA1.CTMRWA1_Unauthorized.selector, Address.Sender));
        token.attachDividend(address(dividendFactory));

        vm.prank(address(map));
        // Check that ctmRwaMap cannot reset the storage address for a previously attached divdend contract
        vm.expectRevert(abi.encodeWithSelector(ICTMRWA1.CTMRWA1_NotZeroAddress.selector, Address.Dividend));
        token.attachDividend(address(dividendFactory));

    }

    function test_attachStorage() public {
        vm.startPrank(tokenAdmin);
        (ID, token) = _deployCTMRWA1(address(usdc));
        vm.stopPrank();

        // Check that an address other than ctmRwaMap cannot attach storage contract
        vm.prank(tokenAdmin);
        vm.expectRevert(abi.encodeWithSelector(ICTMRWA1.CTMRWA1_Unauthorized.selector, Address.Sender));
        token.attachStorage(address(storageManager));

        vm.prank(address(map));
        // Check that ctmRwaMap cannot reset the storage address for a previously attached storage contract
        vm.expectRevert(abi.encodeWithSelector(ICTMRWA1.CTMRWA1_NotZeroAddress.selector, Address.Storage));
        token.attachStorage(address(storageManager));
    }

    function test_attachSentry() public {
        vm.startPrank(tokenAdmin);
        (ID, token) = _deployCTMRWA1(address(usdc));
        vm.stopPrank();

        // Check that an address other than ctmRwaMap cannot attach sentry contract
        vm.prank(tokenAdmin);
        vm.expectRevert(abi.encodeWithSelector(ICTMRWA1.CTMRWA1_Unauthorized.selector, Address.Sender));
        token.attachSentry(address(sentryManager));

        vm.prank(address(map));
        // Check that ctmRwaMap cannot reset the storage address for a previously attached sentry contract
        vm.expectRevert(abi.encodeWithSelector(ICTMRWA1.CTMRWA1_NotZeroAddress.selector, Address.Sentry));
        token.attachSentry(address(sentryManager));
    }

    function test_getTokenList() public {
        vm.startPrank(tokenAdmin);
        (ID, token) = _deployCTMRWA1(address(usdc));
        _deployAFewTokensLocal(address(token), address(usdc), address(map), address(rwa1X), user1);
        vm.stopPrank();

        address[] memory adminTokens = rwa1X.getAllTokensByAdminAddress(tokenAdmin);
        assertEq(adminTokens.length, 1); // only one CTMRWA1 token deployed
        assertEq(address(token), adminTokens[0]);

        address[] memory nRWA1 = rwa1X.getAllTokensByOwnerAddress(user1); // List of CTMRWA1 tokens that user1 has or
            // still has tokens in
        assertEq(nRWA1.length, 1);

        uint256 tokenId;
        uint256 id;
        uint256 bal;
        address owner;
        uint256 slot;
        string memory slotName;

        for (uint256 i = 0; i < nRWA1.length; i++) {
            tokenId = ICTMRWA1(nRWA1[i]).tokenOfOwnerByIndex(user1, i);
            (id, bal, owner, slot, slotName,) = ICTMRWA1(nRWA1[i]).getTokenInfo(tokenId);
            // console.log(tokenId);
            // console.log(id);
            // console.log(bal);
            // console.log(owner);
            // console.log(slot);
            // console.log(slotName);
            // console.log(admin);
            // console.log("************");

            /// @dev added 1 to the ID, as they are 1-indexed as opposed to this loop which is 0-indexed
            uint256 currentId = i + 1;
            assertEq(owner, user1);
            assertEq(tokenId, currentId);
            assertEq(id, currentId);
        }
    }

    function test_forceTransfer() public {
        vm.startPrank(tokenAdmin);
        (ID, token) = _deployCTMRWA1(address(usdc));
        _createSomeSlots(ID, address(usdc), address(rwa1X));

        uint256 slot = 1;

        string memory tokenStr = _toLower((address(usdc).toHexString()));

        uint256 tokenId1User1 = rwa1X.mintNewTokenValueLocal(user1, 0, slot, 2000, ID, tokenStr);

        uint256 tokenId2User1 = rwa1X.mintNewTokenValueLocal(user1, 0, slot, 1000, ID, tokenStr);

        // vm.expectRevert("RWA: Licensed Security override not set up");
        vm.expectRevert(abi.encodeWithSelector(ICTMRWA1.CTMRWA1_IsZeroAddress.selector, Address.Override));
        token.forceTransfer(user1, user2, tokenId1User1);

        string memory randomData = "this is any old data";
        bytes32 junkHash = keccak256(abi.encode(randomData));

        storageManager.addURI(
            ID,
            "2",
            URICategory.ISSUER,
            URIType.CONTRACT,
            "Basic RWA for testing",
            0, // dummy
            junkHash,
            _stringToArray(cIdStr),
            tokenStr
        );

        (, address stor) = map.getStorageContract(ID, RWA_TYPE, VERSION);

        // Attempt to set admin as the Regulator's wallet
        vm.expectRevert("CTMRWA1Storage: No description of the Security is present");
        ICTMRWA1Storage(stor).createSecurity(admin);

        randomData = "this is a dummy security";
        junkHash = keccak256(abi.encode(randomData));

        storageManager.addURI(
            ID,
            "1",
            URICategory.LICENSE,
            URIType.CONTRACT,
            "Dummy security",
            0, // dummy
            junkHash,
            _stringToArray(cIdStr),
            tokenStr
        );

        // vm.expectRevert("RWA: Licensed Security override not set up");
        vm.expectRevert(abi.encodeWithSelector(ICTMRWA1.CTMRWA1_IsZeroAddress.selector, Address.Override));
        token.forceTransfer(user1, user2, tokenId1User1);

        // set admin as the Regulator's wallet
        ICTMRWA1Storage(stor).createSecurity(admin);
        assertEq(ICTMRWA1Storage(stor).regulatorWallet(), admin);

        // vm.expectRevert("RWA: Licensed Security override not set up");
        vm.expectRevert(abi.encodeWithSelector(ICTMRWA1.CTMRWA1_IsZeroAddress.selector, Address.Override));
        token.forceTransfer(user1, user2, tokenId1User1);

        token.setOverrideWallet(tokenAdmin2);
        assertEq(token.overrideWallet(), tokenAdmin2);

        // vm.expectRevert("RWA: Cannot forceTransfer");
        vm.expectRevert(abi.encodeWithSelector(ICTMRWA1.CTMRWA1_Unauthorized.selector, Address.Sender));
        token.forceTransfer(user1, user2, tokenId1User1);

        vm.stopPrank();

        vm.startPrank(tokenAdmin2); // tokenAdmin2 is the override wallet
        token.forceTransfer(user1, user2, tokenId1User1);
        assertEq(token.ownerOf(tokenId1User1), user2); // successful forceTransfer
        vm.stopPrank();

        vm.startPrank(user2);
        // vm.expectRevert("RWA: Cannot forceTransfer");
        vm.expectRevert(abi.encodeWithSelector(ICTMRWA1.CTMRWA1_Unauthorized.selector, Address.Sender));
        token.forceTransfer(user1, user2, tokenId2User1);

        vm.stopPrank();

        vm.startPrank(tokenAdmin);
        rwa1X.changeTokenAdmin(tokenAdmin2.toHexString(), _stringToArray(cIdStr), ID, tokenStr);
        vm.stopPrank();

        vm.startPrank(tokenAdmin2);
        // vm.expectRevert("RWA: Licensed Security override not set up"); // Must re-setup override wallet if tokenAdmin
            // has changed
        vm.expectRevert(abi.encodeWithSelector(ICTMRWA1.CTMRWA1_IsZeroAddress.selector, Address.Override));
        token.forceTransfer(user1, user2, tokenId2User1);
        vm.stopPrank();
    }
}
