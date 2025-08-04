// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.27;

import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { Test } from "forge-std/Test.sol";

import { CTMRWA1 } from "../../src/core/CTMRWA1.sol";
import { ICTMRWA1 } from "../../src/core/ICTMRWA1.sol";
import { CTMRWA1XFallback } from "../../src/crosschain/CTMRWA1XFallback.sol";
import { ICTMRWA1XFallback } from "../../src/crosschain/ICTMRWA1XFallback.sol";
import { CTMRWAErrorParam, CTMRWAUtils } from "../../src/utils/CTMRWAUtils.sol";
import { Helpers } from "../helpers/Helpers.sol";

contract CTMRWA1XFallbackTest is Helpers {
    using CTMRWAUtils for string;
    using Strings for address;

    function setUp() public override {
        super.setUp();

        vm.startPrank(tokenAdmin);
        (ID, token) = _deployCTMRWA1(address(usdc));
        _createSomeSlots(ID, address(usdc), address(rwa1X));
        vm.stopPrank();
    }

    function test_Constructor() public view {
        assertEq(rwa1XFallback.rwa1X(), address(rwa1X));
    }

    function test_OnlyRwa1XModifier() public {
        bytes4 selector = bytes4(keccak256("test()"));
        bytes memory data = "";
        bytes memory reason = "test reason";

        // Should revert when called by non-RWA1X address
        vm.expectRevert(
            abi.encodeWithSelector(
                ICTMRWA1XFallback.CTMRWA1XFallback_OnlyAuthorized.selector,
                CTMRWAErrorParam.Sender,
                CTMRWAErrorParam.RWAX
            )
        );
        rwa1XFallback.rwa1XC3Fallback(selector, data, reason, address(map));
    }

    function test_Rwa1XC3Fallback_NonMintXSelector() public {
        bytes4 selector = bytes4(keccak256("transfer(address,uint256)"));
        bytes memory data = abi.encode(address(0x1), 100);
        bytes memory reason = "transfer failed";

        vm.prank(address(rwa1X));
        bool result = rwa1XFallback.rwa1XC3Fallback(selector, data, reason, address(map));

        // Check that the fallback was successful, even though the selector is not mintX
        assertTrue(result);
        assertEq(rwa1XFallback.lastSelector(), selector);
        assertEq(rwa1XFallback.lastData(), data);
        assertEq(rwa1XFallback.lastReason(), reason);
    }

    function test_Rwa1XC3Fallback_MintXSelector() public {
        bytes4 mintXSelector = bytes4(keccak256("mintX(uint256,string,string,uint256,uint256)"));

        string memory fromAddressStr = _toLower(user1.toHexString());
        string memory toAddressStr = _toLower(user2.toHexString());
        uint256 slot = 1;
        uint256 value = 1000;

        bytes memory data = abi.encode(ID, fromAddressStr, toAddressStr, slot, value);
        bytes memory reason = "mintX failed";

        // Get initial balance
        uint256 initialBalance = token.balanceOf(user1, slot);

        vm.prank(address(rwa1X));
        bool result = rwa1XFallback.rwa1XC3Fallback(mintXSelector, data, reason, address(map));

        assertTrue(result);
        assertEq(rwa1XFallback.lastSelector(), mintXSelector);
        assertEq(rwa1XFallback.lastData(), data);
        assertEq(rwa1XFallback.lastReason(), reason);

        // Check that mintFromX was called and balance increased
        // The fallback contract calls mintFromX with fromAddr (user1), not toAddr (user2)
        uint256 finalBalance = token.balanceOf(user1, slot);
        assertEq(finalBalance, initialBalance + value);
    }

    function test_Rwa1XC3Fallback_MintXSelector_InvalidAddress() public {
        bytes4 mintXSelector = bytes4(keccak256("mintX(uint256,string,string,uint256,uint256)"));

        string memory fromAddressStr = "invalid_address";
        string memory toAddressStr = _toLower(user2.toHexString());
        uint256 slot = 1;
        uint256 value = 1000;

        bytes memory data = abi.encode(ID, fromAddressStr, toAddressStr, slot, value);
        bytes memory reason = "mintX failed";

        vm.prank(address(rwa1X));
        vm.expectRevert(); // Should revert due to invalid address conversion
        rwa1XFallback.rwa1XC3Fallback(mintXSelector, data, reason, address(map));
    }

    function test_Rwa1XC3Fallback_MintXSelector_NonExistentSlot() public {
        bytes4 mintXSelector = bytes4(keccak256("mintX(uint256,string,string,uint256,uint256)"));

        string memory fromAddressStr = _toLower(user1.toHexString());
        string memory toAddressStr = _toLower(user2.toHexString());
        uint256 slot = 999; // Non-existent slot
        uint256 value = 1000;

        bytes memory data = abi.encode(ID, fromAddressStr, toAddressStr, slot, value);
        bytes memory reason = "mintX failed";

        vm.prank(address(rwa1X));
        vm.expectRevert(); // Should revert due to non-existent slot
        rwa1XFallback.rwa1XC3Fallback(mintXSelector, data, reason, address(map));
    }

    function test_GetLastReason() public {
        bytes4 selector = bytes4(keccak256("test()"));
        bytes memory data = "";
        string memory reason = "test reason string";
        bytes memory reasonBytes = bytes(reason);

        vm.prank(address(rwa1X));
        rwa1XFallback.rwa1XC3Fallback(selector, data, reasonBytes, address(map));

        string memory retrievedReason = rwa1XFallback.getLastReason();
        assertEq(retrievedReason, reason);
    }

    function test_Rwa1XC3Fallback_Events() public {
        bytes4 selector = bytes4(keccak256("mintX(uint256,string,string,uint256,uint256)"));

        string memory fromAddressStr = _toLower(user1.toHexString());
        string memory toAddressStr = _toLower(user2.toHexString());
        uint256 slot = 1;
        uint256 value = 1000;

        bytes memory data = abi.encode(ID, fromAddressStr, toAddressStr, slot, value);
        bytes memory reason = "mintX failed";

        vm.prank(address(rwa1X));
        vm.expectEmit(true, true, true, true);
        emit ICTMRWA1XFallback.ReturnValueFallback(user1, slot, value);

        vm.expectEmit(true, true, true, true);
        emit ICTMRWA1XFallback.LogFallback(selector, data, reason);

        rwa1XFallback.rwa1XC3Fallback(selector, data, reason, address(map));
    }

    function test_Rwa1XC3Fallback_NonMintXSelector_Events() public {
        bytes4 selector = bytes4(keccak256("transfer(address,uint256)"));
        bytes memory data = abi.encode(address(0x1), 100);
        bytes memory reason = "transfer failed";

        vm.prank(address(rwa1X));
        vm.expectEmit(true, true, true, true);
        emit ICTMRWA1XFallback.LogFallback(selector, data, reason);

        rwa1XFallback.rwa1XC3Fallback(selector, data, reason, address(map));
    }

    function test_Rwa1XC3Fallback_MintXSelector_LargeValue() public {
        bytes4 mintXSelector = bytes4(keccak256("mintX(uint256,string,string,uint256,uint256)"));

        string memory fromAddressStr = _toLower(user1.toHexString());
        string memory toAddressStr = _toLower(user2.toHexString());
        uint256 slot = 1;
        uint256 value = 1e18; // Large value

        bytes memory data = abi.encode(ID, fromAddressStr, toAddressStr, slot, value);
        bytes memory reason = "mintX failed";

        uint256 initialBalance = token.balanceOf(user1, slot);

        vm.prank(address(rwa1X));
        bool result = rwa1XFallback.rwa1XC3Fallback(mintXSelector, data, reason, address(map));

        assertTrue(result);

        uint256 finalBalance = token.balanceOf(user1, slot);
        assertEq(finalBalance, initialBalance + value);
    }

    function test_Rwa1XC3Fallback_MintXSelector_ZeroValue() public {
        bytes4 mintXSelector = bytes4(keccak256("mintX(uint256,string,string,uint256,uint256)"));

        string memory fromAddressStr = _toLower(user1.toHexString());
        string memory toAddressStr = _toLower(user2.toHexString());
        uint256 slot = 1;
        uint256 value = 0; // Zero value

        bytes memory data = abi.encode(ID, fromAddressStr, toAddressStr, slot, value);
        bytes memory reason = "mintX failed";

        uint256 initialBalance = token.balanceOf(user1, slot);

        vm.prank(address(rwa1X));
        bool result = rwa1XFallback.rwa1XC3Fallback(mintXSelector, data, reason, address(map));

        assertTrue(result);

        uint256 finalBalance = token.balanceOf(user1, slot);
        assertEq(finalBalance, initialBalance + value);
    }

    function test_Rwa1XC3Fallback_MintXSelector_MultipleCalls() public {
        bytes4 mintXSelector = bytes4(keccak256("mintX(uint256,string,string,uint256,uint256)"));

        string memory fromAddressStr = _toLower(user1.toHexString());
        string memory toAddressStr = _toLower(user2.toHexString());
        uint256 slot = 1;
        uint256 value1 = 1000;
        uint256 value2 = 2000;

        bytes memory data1 = abi.encode(ID, fromAddressStr, toAddressStr, slot, value1);
        bytes memory data2 = abi.encode(ID, fromAddressStr, toAddressStr, slot, value2);
        bytes memory reason = "mintX failed";

        uint256 initialBalance = token.balanceOf(user1, slot);

        // First call
        vm.prank(address(rwa1X));
        bool result1 = rwa1XFallback.rwa1XC3Fallback(mintXSelector, data1, reason, address(map));
        assertTrue(result1);

        // Second call
        vm.prank(address(rwa1X));
        bool result2 = rwa1XFallback.rwa1XC3Fallback(mintXSelector, data2, reason, address(map));
        assertTrue(result2);

        uint256 finalBalance = token.balanceOf(user1, slot);
        assertEq(finalBalance, initialBalance + value1 + value2);
    }

    function test_Rwa1XC3Fallback_MintXSelector_DifferentSlots() public {
        bytes4 mintXSelector = bytes4(keccak256("mintX(uint256,string,string,uint256,uint256)"));

        // Create additional slots with proper permissions
        vm.startPrank(tokenAdmin);
        _createSlot(ID, 8, address(usdc), address(rwa1X));
        _createSlot(ID, 9, address(usdc), address(rwa1X));
        vm.stopPrank();

        string memory fromAddressStr = _toLower(user1.toHexString());
        string memory toAddressStr = _toLower(user2.toHexString());
        uint256 value = 1000;

        // Test slot 1
        bytes memory data1 = abi.encode(ID, fromAddressStr, toAddressStr, 1, value);
        bytes memory reason = "mintX failed";

        vm.prank(address(rwa1X));
        bool result1 = rwa1XFallback.rwa1XC3Fallback(mintXSelector, data1, reason, address(map));
        assertTrue(result1);

        // Test slot 8
        bytes memory data2 = abi.encode(ID, fromAddressStr, toAddressStr, 8, value);

        vm.prank(address(rwa1X));
        bool result2 = rwa1XFallback.rwa1XC3Fallback(mintXSelector, data2, reason, address(map));
        assertTrue(result2);

        // Test slot 9
        bytes memory data3 = abi.encode(ID, fromAddressStr, toAddressStr, 9, value);

        vm.prank(address(rwa1X));
        bool result3 = rwa1XFallback.rwa1XC3Fallback(mintXSelector, data3, reason, address(map));
        assertTrue(result3);

        // Check balances in different slots
        assertEq(token.balanceOf(user1, 1), value);
        assertEq(token.balanceOf(user1, 8), value);
        assertEq(token.balanceOf(user1, 9), value);
    }

    function test_Rwa1XC3Fallback_MintXSelector_DifferentRecipients() public {
        bytes4 mintXSelector = bytes4(keccak256("mintX(uint256,string,string,uint256,uint256)"));
        uint256 slot = 1;
        uint256 value = 1000;
        string memory fromAddressStr = _toLower(tokenAdmin2.toHexString());

        // Test user2
        string memory toAddressStr1 = _toLower(user2.toHexString());
        bytes memory data1 = abi.encode(ID, fromAddressStr, toAddressStr1, slot, value);
        bytes memory reason = "mintX failed";

        vm.prank(address(rwa1X));
        bool result1 = rwa1XFallback.rwa1XC3Fallback(mintXSelector, data1, reason, address(map));
        assertTrue(result1);

        // Test user1
        string memory toAddressStr2 = _toLower(user1.toHexString());
        bytes memory data2 = abi.encode(ID, fromAddressStr, toAddressStr2, slot, value);

        vm.prank(address(rwa1X));
        bool result2 = rwa1XFallback.rwa1XC3Fallback(mintXSelector, data2, reason, address(map));
        assertTrue(result2);

        // Test admin
        string memory toAddressStr3 = _toLower(admin.toHexString());
        bytes memory data3 = abi.encode(ID, fromAddressStr, toAddressStr3, slot, value);

        vm.prank(address(rwa1X));
        bool result3 = rwa1XFallback.rwa1XC3Fallback(mintXSelector, data3, reason, address(map));
        assertTrue(result3);

        // Check balances for different recipients
        // All tokens are minted to tokenAdmin2 (fromAddr), so the total balance should be 3 * value
        assertEq(token.balanceOf(tokenAdmin2, slot), 3 * value);
    }

    function test_Rwa1XC3Fallback_StorageVariables() public {
        bytes4 selector = bytes4(keccak256("test()"));
        bytes memory data = "test data";
        bytes memory reason = "test reason";

        vm.prank(address(rwa1X));
        rwa1XFallback.rwa1XC3Fallback(selector, data, reason, address(map));

        // Check storage variables
        assertEq(rwa1XFallback.lastSelector(), selector);
        assertEq(rwa1XFallback.lastData(), data);
        assertEq(rwa1XFallback.lastReason(), reason);

        // Update with new values
        bytes4 newSelector = bytes4(keccak256("newTest()"));
        bytes memory newData = "new test data";
        bytes memory newReason = "new test reason";

        vm.prank(address(rwa1X));
        rwa1XFallback.rwa1XC3Fallback(newSelector, newData, newReason, address(map));

        // Check updated storage variables
        assertEq(rwa1XFallback.lastSelector(), newSelector);
        assertEq(rwa1XFallback.lastData(), newData);
        assertEq(rwa1XFallback.lastReason(), newReason);
    }
}
