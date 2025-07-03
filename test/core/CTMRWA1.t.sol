// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

contract TestCTMRWA1 is SetUp {
    using Strings for *;


    function test_getTokenList() public {
        vm.startPrank(user1);
        (, address ctmRwaAddr) = CTMRWA1Deploy();
        deployAFewTokensLocal(ctmRwaAddr);
        vm.stopPrank();

        address[] memory adminTokens = rwa1X.getAllTokensByAdminAddress(user1);
        assertEq(adminTokens.length, 1);  // only one CTMRWA1 token deployed
        assertEq(ctmRwaAddr, adminTokens[0]);

        address[] memory nRWA1 = rwa1X.getAllTokensByOwnerAddress(user1);  // List of CTMRWA1 tokens that user1 has or still has tokens in
        assertEq(nRWA1.length, 1);

        uint256 tokenId;
        uint256 id;
        uint256 bal;
        address owner;
        uint256 slot;
        string memory slotName;

        for(uint256 i=0; i<nRWA1.length; i++) {
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
        (uint256 ID, address ctmRwaAddr) = CTMRWA1Deploy();
        createSomeSlots(ID);

        uint256 slot = 1;
        string memory name = "Basic Stuff";

        string memory tokenStr = _toLower((address(usdc).toHexString()));

        uint256 tokenId1User1 = rwa1X.mintNewTokenValueLocal(
            user1,
            0,
            slot,
            2000,
            ID,
            tokenStr
        );

        uint256 tokenId2User1 = rwa1X.mintNewTokenValueLocal(
            user1,
            0,
            slot,
            1000,
            ID,
            tokenStr
        );

        vm.expectRevert("RWA: Licensed Security override not set up");
        ICTMRWA1(ctmRwaAddr).forceTransfer(user1, user2, tokenId1User1);

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

        (, address stor) = map.getStorageContract(ID, rwaType, version);

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

        vm.expectRevert("RWA: Licensed Security override not set up");
        ICTMRWA1(ctmRwaAddr).forceTransfer(user1, user2, tokenId1User1);


        // set admin as the Regulator's wallet
        ICTMRWA1Storage(stor).createSecurity(admin);
        assertEq(ICTMRWA1Storage(stor).regulatorWallet(), admin);

        vm.expectRevert("RWA: Licensed Security override not set up");
        ICTMRWA1(ctmRwaAddr).forceTransfer(user1, user2, tokenId1User1);

        ICTMRWA1(ctmRwaAddr).setOverrideWallet(tokenAdmin2);
        assertEq(ICTMRWA1(ctmRwaAddr).overrideWallet(), tokenAdmin2);

        vm.expectRevert("RWA: Cannot forceTransfer");
        ICTMRWA1(ctmRwaAddr).forceTransfer(user1, user2, tokenId1User1);

        vm.stopPrank();

        vm.startPrank(tokenAdmin2);  // tokenAdmin2 is the override wallet
        ICTMRWA1(ctmRwaAddr).forceTransfer(user1, user2, tokenId1User1);
        assertEq(ICTMRWA1(ctmRwaAddr).ownerOf(tokenId1User1), user2); // successful forceTransfer
        vm.stopPrank();

        vm.startPrank(user2);
        vm.expectRevert("RWA: Cannot forceTransfer");
        ICTMRWA1(ctmRwaAddr).forceTransfer(user1, user2, tokenId2User1);

        vm.stopPrank();

        vm.startPrank(tokenAdmin);
        rwa1X.changeTokenAdmin(tokenAdmin2.toHexString(), _stringToArray(cIdStr), ID, tokenStr);
        vm.stopPrank();

        vm.startPrank(tokenAdmin2);
        vm.expectRevert("RWA: Licensed Security override not set up"); // Must re-setup override wallet if tokenAdmin has changed
        ICTMRWA1(ctmRwaAddr).forceTransfer(user1, user2, tokenId2User1);
        vm.stopPrank();

    }

}
