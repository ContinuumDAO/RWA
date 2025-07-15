// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.27;

import { Test } from "forge-std/Test.sol";
import { console } from "forge-std/console.sol";

import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

import { Helpers } from "../helpers/Helpers.sol";

contract TestGateway is Helpers {
    using Strings for *;

    function test_CTMRWAGateway_chainContract() public {
        uint256 nChains = gateway.getChainCount();
        assertEq(nChains, 2); // local chain + "ethereumGateway"

        // Check the local chain gateway at position 0 added by initialize
        string memory gatewayStr = gateway.getChainContract(cID().toString());
        // console.log(gatewayStr);
        assertTrue(stringsEqual(gatewayStr, _toLower(address(gateway).toHexString())));
        address gway = stringToAddress(gatewayStr);
        // console.log(gway);
        assertEq(gway, address(gateway));

        string memory chainIdStr;
        uint256 pos = 1;
        (chainIdStr, gatewayStr) = gateway.getChainContract(pos); // Check position 1 in the array
        assertTrue(stringsEqual(chainIdStr, "1"));
        assertTrue(stringsEqual(gatewayStr, _toLower("ethereumGateway")));

        // Check for Ethereum chainID added by deployer test setup
        gatewayStr = gateway.getChainContract("1");
        assertTrue(stringsEqual(gatewayStr, _toLower("ethereumGateway")));

        // Check that addChainContract is onlyGov
        vm.expectRevert("Gov FORBIDDEN");
        gateway.addChainContract(_stringToArray("2"), _stringToArray("Dummy"));

        vm.startPrank(gov);
        vm.expectRevert("Gateway: max string length exceeded");
        gateway.addChainContract(
            _stringToArray("012345678901234567890123456789012345678901234567890123456789012345"),
            _stringToArray("Dummy")
        );
        vm.expectRevert("Gateway: max string length exceeded");
        gateway.addChainContract(
            _stringToArray("2"), _stringToArray("AVeryLongContractAddress999999999999999999999999999999999999999999")
        );
        vm.stopPrank();
    }

    function test_CTMRWAGateway_rwaXChain() public {
        uint256 nChains = gateway.getRWAXCount(RWA_TYPE, VERSION);
        assertEq(nChains, 2);

        nChains = gateway.getRWAXCount(RWA_TYPE + 1, VERSION);
        assertEq(nChains, 0); // There are no chains for rwaType == 2

        string memory rwaxChainStr;
        string memory chainIdStr;
        bool ok;

        // Check the local chain rwa1X
        (ok, rwaxChainStr) = gateway.getAttachedRWAX(RWA_TYPE, VERSION, cIdStr);
        assertTrue(ok);
        // console.log(chainIdStr);
        // console.log(address(rwa1X).toHexString());
        assertTrue(stringsEqual(rwaxChainStr, _toLower(address(rwa1X).toHexString())));

        // Check the rwaxChainStr at position 1
        uint256 pos = 1;
        (chainIdStr, rwaxChainStr) = gateway.getAttachedRWAX(RWA_TYPE, VERSION, pos);
        assertTrue(stringsEqual(chainIdStr, _toLower("999999999999999999999")));

        chainIdStr = "999999999999999999999";
        assertTrue(
            stringsEqual(rwaxChainStr, _toLower("thisIsSomeRandomAddressOnNEARForTestingWallet123456789.test.near"))
        );

        // Check getAllRwaXChains function
        string[] memory allRwaXs = gateway.getAllRwaXChains(RWA_TYPE, VERSION);
        assertTrue(stringsEqual(allRwaXs[1], _toLower("999999999999999999999")));

        // Check existRwaXChain function
        ok = gateway.existRwaXChain(RWA_TYPE, VERSION, "999999999999999999999");
        assertTrue(ok);

        vm.startPrank(gov);
        vm.expectRevert("Gateway: max string length exceeded");
        gateway.attachRWAX(RWA_TYPE, VERSION, 
            _stringToArray("012345678901234567890123456789012345678901234567890123456789012345"), //len 65
            _stringToArray("Dummy")
        );

        vm.expectRevert("Gateway: max string length exceeded");
        gateway.attachRWAX(RWA_TYPE, VERSION, 
            _stringToArray("2"),
            _stringToArray("AVeryLongContractAddress999999999999999999999999999999999999999999") // len 65
        );
        vm.stopPrank();

        vm.startPrank(user1);
        vm.expectRevert("Gov FORBIDDEN");
        gateway.attachRWAX(RWA_TYPE, VERSION, _stringToArray("2"), _stringToArray("Dummy"));
        vm.stopPrank();
    }

    function test_CTMRWAGateway_storageChain() public {
        uint256 nChains = gateway.getStorageManagerCount(RWA_TYPE, VERSION);
        assertEq(nChains, 2);

        string memory storageChainStr;
        string memory chainIdStr;
        bool ok;

        // Check the local chain
        (ok, storageChainStr) = gateway.getAttachedStorageManager(RWA_TYPE, VERSION, cIdStr);
        assertTrue(ok);

        // Check another chain (Ethereum) at pos 1
        uint256 pos = 1;
        (chainIdStr, storageChainStr) = gateway.getAttachedStorageManager(RWA_TYPE, VERSION, pos);
        assertTrue(stringsEqual(chainIdStr, "1"));
        assertTrue(stringsEqual(storageChainStr, _toLower("ethereumStorageManager")));

        vm.startPrank(gov);
        vm.expectRevert("Gateway: max string length exceeded");
        gateway.attachStorageManager(RWA_TYPE, VERSION, 
            _stringToArray("012345678901234567890123456789012345678901234567890123456789012345"), //len 65
            _stringToArray("Dummy")
        );

        vm.expectRevert("Gateway: max string length exceeded");
        gateway.attachStorageManager(RWA_TYPE, VERSION, 
            _stringToArray("2"),
            _stringToArray("AVeryLongContractAddress999999999999999999999999999999999999999999") // len 65
        );
        vm.stopPrank();

        vm.startPrank(user1);
        vm.expectRevert("Gov FORBIDDEN");
        gateway.attachStorageManager(RWA_TYPE, VERSION, _stringToArray("2"), _stringToArray("Dummy"));
        vm.stopPrank();
    }

    function test_CTMRWAGateway_sentryChain() public {
        uint256 nChains = gateway.getSentryManagerCount(RWA_TYPE, VERSION);
        assertEq(nChains, 2);

        string memory sentryChainStr;
        string memory chainIdStr;
        bool ok;

        // Check the local chain
        (ok, sentryChainStr) = gateway.getAttachedSentryManager(RWA_TYPE, VERSION, cIdStr);
        assertTrue(ok);

        // Check another chain (Ethereum) at pos 1
        uint256 pos = 1;
        (chainIdStr, sentryChainStr) = gateway.getAttachedSentryManager(RWA_TYPE, VERSION, pos);
        assertTrue(stringsEqual(chainIdStr, "1"));
        assertTrue(stringsEqual(sentryChainStr, _toLower("ethereumSentryManager")));

        vm.startPrank(gov);
        vm.expectRevert("Gateway: max string length exceeded");
        gateway.attachSentryManager(RWA_TYPE, VERSION, 
            _stringToArray("012345678901234567890123456789012345678901234567890123456789012345"), //len 65
            _stringToArray("Dummy")
        );

        vm.expectRevert("Gateway: max string length exceeded");
        gateway.attachSentryManager(RWA_TYPE, VERSION, 
            _stringToArray("2"),
            _stringToArray("AVeryLongContractAddress999999999999999999999999999999999999999999") // len 65
        );
        vm.stopPrank();

        vm.startPrank(user1);
        vm.expectRevert("Gov FORBIDDEN");
        gateway.attachSentryManager(RWA_TYPE, VERSION, _stringToArray("2"), _stringToArray("Dummy"));
        vm.stopPrank();
    }
}
