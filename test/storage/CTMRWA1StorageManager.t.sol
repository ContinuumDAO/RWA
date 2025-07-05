// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

import {Helpers} from "../helpers/Helpers.sol";

contract TestFeeManager is Helpers {
    using Strings for *;

    function test_addURI() public {
        (uint256 ID, address ctmRwaAddr) = CTMRWA1Deploy();
        createSomeSlots(ID);

        string memory tokenStr = _toLower((address(usdc).toHexString()));


        string memory randomData = "this is any old data";
        bytes32 junkHash = keccak256(abi.encode(randomData));

        vm.expectRevert("CTMRWA1Storage: Type CONTRACT and CATEGORY ISSUER must be the first stored element");
        storageManager.addURI(
            ID,
            "1",
            URICategory.IMAGE,
            URIType.CONTRACT,
            "Basic RWA for testing",
            0, // dummy
            junkHash,
            _stringToArray(cIdStr),
            tokenStr
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
            tokenStr
        );

        (bool ok, address thisStorage) = map.getStorageContract(ID, rwaType, version);

        bool existObject = ICTMRWA1Storage(thisStorage).existObjectName("1");
        assertEq(existObject, true);

        uint256 num = ICTMRWA1Storage(thisStorage).getURIHashCount(URICategory.ISSUER, URIType.CONTRACT);
        assertEq(num, 1);

        URIData memory thisHash = ICTMRWA1Storage(thisStorage).getURIHash(junkHash);
        assertEq(uint8(thisHash.uriCategory), uint8(URICategory.ISSUER));

        uint256 indx = 0;
        bytes32 issuerHash;
        string memory objectName;

        (issuerHash, objectName) = ICTMRWA1Storage(thisStorage).getURIHashByIndex(URICategory.ISSUER, URIType.CONTRACT, indx);
        // console.log("ObjectName");
        // console.log(objectName);
        // console.log("Issuer hash");
        // console.logBytes32(issuerHash);
        assertEq(issuerHash, junkHash);

    }

    function test_addURIX() public {
        (uint256 ID, address ctmRwaAddr) = CTMRWA1Deploy();
        createSomeSlots(ID);

        string memory tokenStr = _toLower((address(usdc).toHexString()));

        URICategory _uriCategory = URICategory.ISSUER;
        URIType _uriType = URIType.CONTRACT;

        string memory randomData = "this is any old data";
        bytes32 junkHash = keccak256(abi.encode(randomData));

        vm.expectRevert("CTMRWA0CTMRWA1StorageManager: addURI Starting nonce mismatch");
        storageManager.addURIX(
            ID,
            2,  // incorrect nonce
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

        (bool ok, address thisStorage) = map.getStorageContract(ID, rwaType, version);

        uint256 newNonce = ICTMRWA1Storage(thisStorage).nonce();
        assertEq(newNonce,2);

        bool exists = ICTMRWA1Storage(thisStorage).existObjectName("1");
        assertEq(exists, true);

        URIData memory uri = ICTMRWA1Storage(thisStorage).getURIHash(junkHash);
        assertEq(stringsEqual(uri.title, "A Title"), true);

    }

}
