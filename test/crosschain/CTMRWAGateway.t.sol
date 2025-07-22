// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.27;

import { Test } from "forge-std/Test.sol";
import { console } from "forge-std/console.sol";

import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

import { ICTMRWAGateway } from "../../src/crosschain/ICTMRWAGateway.sol";
import { CTMRWAUtils, Uint } from "../../src/utils/CTMRWAUtils.sol";
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
        vm.expectRevert(CTMRWAUtils.CTMRWAUtils_StringTooLong.selector);
        gateway.addChainContract(
            _stringToArray("012345678901234567890123456789012345678901234567890123456789012345"),
            _stringToArray("Dummy")
        );
        vm.expectRevert(CTMRWAUtils.CTMRWAUtils_StringTooLong.selector);
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
        vm.expectRevert(CTMRWAUtils.CTMRWAUtils_StringTooLong.selector);
        gateway.attachRWAX(
            RWA_TYPE,
            VERSION,
            _stringToArray("012345678901234567890123456789012345678901234567890123456789012345"), //len 65
            _stringToArray("Dummy")
        );

        vm.expectRevert(CTMRWAUtils.CTMRWAUtils_StringTooLong.selector);
        gateway.attachRWAX(
            RWA_TYPE,
            VERSION,
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
        vm.expectRevert(CTMRWAUtils.CTMRWAUtils_StringTooLong.selector);
        gateway.attachStorageManager(
            RWA_TYPE,
            VERSION,
            _stringToArray("012345678901234567890123456789012345678901234567890123456789012345"), //len 65
            _stringToArray("Dummy")
        );

        vm.expectRevert(CTMRWAUtils.CTMRWAUtils_StringTooLong.selector);
        gateway.attachStorageManager(
            RWA_TYPE,
            VERSION,
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
        vm.expectRevert(CTMRWAUtils.CTMRWAUtils_StringTooLong.selector);
        gateway.attachSentryManager(
            RWA_TYPE,
            VERSION,
            _stringToArray("012345678901234567890123456789012345678901234567890123456789012345"), //len 65
            _stringToArray("Dummy")
        );

        vm.expectRevert(CTMRWAUtils.CTMRWAUtils_StringTooLong.selector);
        gateway.attachSentryManager(
            RWA_TYPE,
            VERSION,
            _stringToArray("2"),
            _stringToArray("AVeryLongContractAddress999999999999999999999999999999999999999999") // len 65
        );
        vm.stopPrank();

        vm.startPrank(user1);
        vm.expectRevert("Gov FORBIDDEN");
        gateway.attachSentryManager(RWA_TYPE, VERSION, _stringToArray("2"), _stringToArray("Dummy"));
        vm.stopPrank();
    }

    function test_attachRWAX() public {
        vm.startPrank(gov);
        string[] memory chainIds = new string[](1);
        string[] memory addrs = new string[](1);
        chainIds[0] = "12345";
        addrs[0] = "0x1234567890abcdef1234567890abcdef12345678";
        bool ok = gateway.attachRWAX(RWA_TYPE, VERSION, chainIds, addrs);
        assertTrue(ok);
        (bool found, string memory addr) = gateway.getAttachedRWAX(RWA_TYPE, VERSION, chainIds[0]);
        assertTrue(found);
        assertEq(addr, addrs[0]);
        vm.expectRevert();
        gateway.attachRWAX(RWA_TYPE, VERSION, chainIds, new string[](0));
        vm.stopPrank();
    }

    function test_attachStorageManager() public {
        vm.startPrank(gov);
        string[] memory chainIds = new string[](1);
        string[] memory addrs = new string[](1);
        chainIds[0] = "54321";
        addrs[0] = "0xabcdefabcdefabcdefabcdefabcdefabcdefabcd";
        bool ok = gateway.attachStorageManager(RWA_TYPE, VERSION, chainIds, addrs);
        assertTrue(ok);
        (bool found, string memory addr) = gateway.getAttachedStorageManager(RWA_TYPE, VERSION, chainIds[0]);
        assertTrue(found);
        assertEq(addr, addrs[0]);
        vm.expectRevert();
        gateway.attachStorageManager(RWA_TYPE, VERSION, chainIds, new string[](0));
        vm.stopPrank();
    }

    function test_attachSentryManager() public {
        vm.startPrank(gov);
        string[] memory chainIds = new string[](1);
        string[] memory addrs = new string[](1);
        chainIds[0] = "67890";
        addrs[0] = "0xdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef";
        bool ok = gateway.attachSentryManager(RWA_TYPE, VERSION, chainIds, addrs);
        assertTrue(ok);
        (bool found, string memory addr) = gateway.getAttachedSentryManager(RWA_TYPE, VERSION, chainIds[0]);
        assertTrue(found);
        assertEq(addr, addrs[0]);
        vm.expectRevert();
        gateway.attachSentryManager(RWA_TYPE, VERSION, chainIds, new string[](0));
        vm.stopPrank();
    }

    // (2) Duplicate Attachments / Idempotency
    function test_attachRWAX_duplicate_overwrites() public {
        vm.startPrank(gov);
        string[] memory chainIds = new string[](1);
        string[] memory addrs1 = new string[](1);
        string[] memory addrs2 = new string[](1);
        chainIds[0] = "99999";
        addrs1[0] = "0x1111111111111111111111111111111111111111";
        addrs2[0] = "0x2222222222222222222222222222222222222222";
        gateway.attachRWAX(RWA_TYPE, VERSION, chainIds, addrs1);
        (bool found1, string memory addr1) = gateway.getAttachedRWAX(RWA_TYPE, VERSION, chainIds[0]);
        assertTrue(found1);
        assertEq(addr1, addrs1[0]);
        // Overwrite
        gateway.attachRWAX(RWA_TYPE, VERSION, chainIds, addrs2);
        (bool found2, string memory addr2) = gateway.getAttachedRWAX(RWA_TYPE, VERSION, chainIds[0]);
        assertTrue(found2);
        assertEq(addr2, addrs2[0]);
        vm.stopPrank();
    }

    function test_attachRWAX_idempotency() public {
        vm.startPrank(gov);
        string[] memory chainIds = new string[](1);
        string[] memory addrs = new string[](1);
        chainIds[0] = "88888";
        addrs[0] = "0x8888888888888888888888888888888888888888";
        gateway.attachRWAX(RWA_TYPE, VERSION, chainIds, addrs);
        gateway.attachRWAX(RWA_TYPE, VERSION, chainIds, addrs);
        (bool found, string memory addr) = gateway.getAttachedRWAX(RWA_TYPE, VERSION, chainIds[0]);
        assertTrue(found);
        assertEq(addr, addrs[0]);
        vm.stopPrank();
    }

    // (3) Getter Edge Cases
    function test_getAttachedRWAX_nonexistent_returnsFalse() public view {
        (bool found, string memory addr) = gateway.getAttachedRWAX(RWA_TYPE, VERSION, "nonexistent");
        assertFalse(found);
        assertEq(addr, "0");
    }

    function test_getAttachedRWAX_emptyString_returnsFalse() public view {
        (bool found, string memory addr) = gateway.getAttachedRWAX(RWA_TYPE, VERSION, "");
        assertFalse(found);
        assertEq(addr, "0");
    }

    // (5) Input Validation
    function test_attachRWAX_zeroAddress_allowed() public {
        vm.startPrank(gov);
        string[] memory chainIds = new string[](1);
        string[] memory addrs = new string[](1);
        chainIds[0] = "77777";
        addrs[0] = "0x0000000000000000000000000000000000000000";
        bool ok = gateway.attachRWAX(RWA_TYPE, VERSION, chainIds, addrs);
        assertTrue(ok);
        (bool found, string memory addr) = gateway.getAttachedRWAX(RWA_TYPE, VERSION, chainIds[0]);
        assertTrue(found);
        assertEq(addr, addrs[0]);
        vm.stopPrank();
    }

    function test_attachRWAX_emptyArrays_revert() public {
        vm.startPrank(gov);
        string[] memory chainIds = new string[](0);
        string[] memory addrs = new string[](0);
        vm.expectRevert();
        gateway.attachRWAX(RWA_TYPE, VERSION, chainIds, addrs);
        vm.stopPrank();
    }

    // (6) Gas Usage for Batch Operations
    function test_attachRWAX_batch_gasUsage() public {
        vm.startPrank(gov);
        uint256 n = 10;
        string[] memory chainIds = new string[](n);
        string[] memory addrs = new string[](n);
        for (uint256 i = 0; i < n; i++) {
            chainIds[i] = string(abi.encodePacked("batch", vm.toString(i)));
            addrs[i] = string(abi.encodePacked("0x", vm.toString(i)));
        }
        uint256 gasStart = gasleft();
        gateway.attachRWAX(RWA_TYPE, VERSION, chainIds, addrs);
        uint256 gasUsed = gasStart - gasleft();
        // Just assert that it doesn't use more than 1,000,000 gas for 10 entries (arbitrary reasonable bound)
        assertLt(gasUsed, 1_000_000);
        vm.stopPrank();
    }
}
