// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.27;

import { Test } from "forge-std/Test.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

import { Helpers } from "../helpers/Helpers.sol";
import { CTMRWA1XFallback } from "../../src/crosschain/CTMRWA1XFallback.sol";
import { ICTMRWA1XFallback } from "../../src/crosschain/ICTMRWA1XFallback.sol";
import { CTMRWA1 } from "../../src/core/CTMRWA1.sol";
import { ICTMRWA1 } from "../../src/core/ICTMRWA1.sol";
import { CTMRWAUtils } from "../../src/CTMRWAUtils.sol";

contract CTMRWA1XFallbackTest is Helpers {
    using CTMRWAUtils for string;
    using Strings for address;

    CTMRWA1XFallback fallbackContract;
    CTMRWA1 testToken;
    uint256 testTokenId;

    function setUp() public override {
        super.setUp();
        
        // Use the existing fallback contract from Helpers setup
        fallbackContract = CTMRWA1XFallback(address(rwa1XFallback));
        
        // Deploy a test CTMRWA1 token
        (testTokenId, testToken) = _deployCTMRWA1(address(usdc));
        
        // Create a slot for testing
        _createSlot(testTokenId, 1, address(usdc), address(rwa1X));
    }

    function test_Constructor() public {
        assertEq(fallbackContract.rwa1X(), address(rwa1X));
    }

    function test_OnlyRwa1XModifier() public {
        bytes4 selector = bytes4(keccak256("test()"));
        bytes memory data = "";
        bytes memory reason = "test reason";

        // Should revert when called by non-RWA1X address
        vm.expectRevert(abi.encodeWithSelector(ICTMRWA1XFallback.CTMRWA1XFallback_Unauthorized.selector, 0));
        fallbackContract.rwa1XC3Fallback(selector, data, reason);
    }

    function test_Rwa1XC3Fallback_NonMintXSelector() public {
        bytes4 selector = bytes4(keccak256("transfer(address,uint256)"));
        bytes memory data = abi.encode(address(0x1), 100);
        bytes memory reason = "transfer failed";

        vm.prank(address(rwa1X));
        bool result = fallbackContract.rwa1XC3Fallback(selector, data, reason);

        assertTrue(result);
        assertEq(fallbackContract.lastSelector(), selector);
        assertEq(fallbackContract.lastData(), data);
        assertEq(fallbackContract.lastReason(), reason);
    }

    function test_Rwa1XC3Fallback_MintXSelector() public {
        bytes4 mintXSelector = bytes4(keccak256("mintX(uint256,string,string,uint256,uint256,uint256,string)"));
        
        uint256 ID = testTokenId;
        string memory fromAddressStr = _toLower(user1.toHexString());
        string memory toAddressStr = _toLower(user2.toHexString());
        uint256 fromTokenId = 1;
        uint256 slot = 1;
        uint256 value = 1000;
        string memory ctmRwa1AddrStr = _toLower(address(testToken).toHexString());

        bytes memory data = abi.encode(ID, fromAddressStr, toAddressStr, fromTokenId, slot, value, ctmRwa1AddrStr);
        bytes memory reason = "mintX failed";

        // Get initial balance
        uint256 initialBalance = testToken.balanceOf(user1, slot);

        vm.prank(address(rwa1X));
        bool result = fallbackContract.rwa1XC3Fallback(mintXSelector, data, reason);

        assertTrue(result);
        assertEq(fallbackContract.lastSelector(), mintXSelector);
        assertEq(fallbackContract.lastData(), data);
        assertEq(fallbackContract.lastReason(), reason);

        // Check that mintFromX was called and balance increased
        // The fallback contract calls mintFromX with fromAddr (user1), not toAddr (user2)
        uint256 finalBalance = testToken.balanceOf(user1, slot);
        assertEq(finalBalance, initialBalance + value);
    }

    function test_Rwa1XC3Fallback_MintXSelector_WithExistingToken() public {
        bytes4 mintXSelector = bytes4(keccak256("mintX(uint256,string,string,uint256,uint256,uint256,string)"));
        
        uint256 ID = testTokenId;
        string memory fromAddressStr = _toLower(user1.toHexString());
        string memory toAddressStr = _toLower(user2.toHexString());
        uint256 fromTokenId = 1;
        uint256 slot = 1;
        uint256 value = 1000;
        string memory ctmRwa1AddrStr = _toLower(address(testToken).toHexString());

        // First, mint a token to user2
        vm.prank(address(rwa1X));
        uint256 existingTokenId = testToken.mintFromX(user2, slot, "Test Slot", 500);

        bytes memory data = abi.encode(ID, fromAddressStr, toAddressStr, fromTokenId, slot, value, ctmRwa1AddrStr);
        bytes memory reason = "mintX failed";

        // Get initial balance
        uint256 initialBalance = testToken.balanceOf(user1, slot);

        vm.prank(address(rwa1X));
        bool result = fallbackContract.rwa1XC3Fallback(mintXSelector, data, reason);

        assertTrue(result);

        // Check that mintFromX was called and balance increased
        uint256 finalBalance = testToken.balanceOf(user1, slot);
        assertEq(finalBalance, initialBalance + value);
    }

    function test_Rwa1XC3Fallback_MintXSelector_InvalidAddress() public {
        bytes4 mintXSelector = bytes4(keccak256("mintX(uint256,string,string,uint256,uint256,uint256,string)"));
        
        uint256 ID = testTokenId;
        string memory fromAddressStr = "invalid_address";
        string memory toAddressStr = _toLower(user2.toHexString());
        uint256 fromTokenId = 1;
        uint256 slot = 1;
        uint256 value = 1000;
        string memory ctmRwa1AddrStr = _toLower(address(testToken).toHexString());

        bytes memory data = abi.encode(ID, fromAddressStr, toAddressStr, fromTokenId, slot, value, ctmRwa1AddrStr);
        bytes memory reason = "mintX failed";

        vm.prank(address(rwa1X));
        vm.expectRevert(); // Should revert due to invalid address conversion
        fallbackContract.rwa1XC3Fallback(mintXSelector, data, reason);
    }

    function test_Rwa1XC3Fallback_MintXSelector_InvalidTokenAddress() public {
        bytes4 mintXSelector = bytes4(keccak256("mintX(uint256,string,string,uint256,uint256,uint256,string)"));
        
        uint256 ID = testTokenId;
        string memory fromAddressStr = _toLower(user1.toHexString());
        string memory toAddressStr = _toLower(user2.toHexString());
        uint256 fromTokenId = 1;
        uint256 slot = 1;
        uint256 value = 1000;
        string memory ctmRwa1AddrStr = "invalid_token_address";

        bytes memory data = abi.encode(ID, fromAddressStr, toAddressStr, fromTokenId, slot, value, ctmRwa1AddrStr);
        bytes memory reason = "mintX failed";

        vm.prank(address(rwa1X));
        vm.expectRevert(); // Should revert due to invalid token address conversion
        fallbackContract.rwa1XC3Fallback(mintXSelector, data, reason);
    }

    function test_Rwa1XC3Fallback_MintXSelector_NonExistentSlot() public {
        bytes4 mintXSelector = bytes4(keccak256("mintX(uint256,string,string,uint256,uint256,uint256,string)"));
        
        uint256 ID = testTokenId;
        string memory fromAddressStr = _toLower(user1.toHexString());
        string memory toAddressStr = _toLower(user2.toHexString());
        uint256 fromTokenId = 1;
        uint256 slot = 999; // Non-existent slot
        uint256 value = 1000;
        string memory ctmRwa1AddrStr = _toLower(address(testToken).toHexString());

        bytes memory data = abi.encode(ID, fromAddressStr, toAddressStr, fromTokenId, slot, value, ctmRwa1AddrStr);
        bytes memory reason = "mintX failed";

        vm.prank(address(rwa1X));
        vm.expectRevert(); // Should revert due to non-existent slot
        fallbackContract.rwa1XC3Fallback(mintXSelector, data, reason);
    }

    function test_GetLastReason() public {
        bytes4 selector = bytes4(keccak256("test()"));
        bytes memory data = "";
        string memory reason = "test reason string";
        bytes memory reasonBytes = bytes(reason);

        vm.prank(address(rwa1X));
        fallbackContract.rwa1XC3Fallback(selector, data, reasonBytes);

        string memory retrievedReason = fallbackContract.getLastReason();
        assertEq(retrievedReason, reason);
    }

    function test_Rwa1XC3Fallback_Events() public {
        bytes4 selector = bytes4(keccak256("mintX(uint256,string,string,uint256,uint256,uint256,string)"));
        
        uint256 ID = testTokenId;
        string memory fromAddressStr = _toLower(user1.toHexString());
        string memory toAddressStr = _toLower(user2.toHexString());
        uint256 fromTokenId = 1;
        uint256 slot = 1;
        uint256 value = 1000;
        string memory ctmRwa1AddrStr = _toLower(address(testToken).toHexString());

        bytes memory data = abi.encode(ID, fromAddressStr, toAddressStr, fromTokenId, slot, value, ctmRwa1AddrStr);
        bytes memory reason = "mintX failed";

        vm.prank(address(rwa1X));
        vm.expectEmit(true, true, true, true);
        emit ICTMRWA1XFallback.ReturnValueFallback(user1, slot, value);
        
        vm.expectEmit(true, true, true, true);
        emit ICTMRWA1XFallback.LogFallback(selector, data, reason);
        
        fallbackContract.rwa1XC3Fallback(selector, data, reason);
    }

    function test_Rwa1XC3Fallback_NonMintXSelector_Events() public {
        bytes4 selector = bytes4(keccak256("transfer(address,uint256)"));
        bytes memory data = abi.encode(address(0x1), 100);
        bytes memory reason = "transfer failed";

        vm.prank(address(rwa1X));
        vm.expectEmit(true, true, true, true);
        emit ICTMRWA1XFallback.LogFallback(selector, data, reason);
        
        fallbackContract.rwa1XC3Fallback(selector, data, reason);
    }

    function test_Rwa1XC3Fallback_MintXSelector_LargeValue() public {
        bytes4 mintXSelector = bytes4(keccak256("mintX(uint256,string,string,uint256,uint256,uint256,string)"));
        
        uint256 ID = testTokenId;
        string memory fromAddressStr = _toLower(user1.toHexString());
        string memory toAddressStr = _toLower(user2.toHexString());
        uint256 fromTokenId = 1;
        uint256 slot = 1;
        uint256 value = 1e18; // Large value
        string memory ctmRwa1AddrStr = _toLower(address(testToken).toHexString());

        bytes memory data = abi.encode(ID, fromAddressStr, toAddressStr, fromTokenId, slot, value, ctmRwa1AddrStr);
        bytes memory reason = "mintX failed";

        uint256 initialBalance = testToken.balanceOf(user1, slot);

        vm.prank(address(rwa1X));
        bool result = fallbackContract.rwa1XC3Fallback(mintXSelector, data, reason);

        assertTrue(result);

        uint256 finalBalance = testToken.balanceOf(user1, slot);
        assertEq(finalBalance, initialBalance + value);
    }

    function test_Rwa1XC3Fallback_MintXSelector_ZeroValue() public {
        bytes4 mintXSelector = bytes4(keccak256("mintX(uint256,string,string,uint256,uint256,uint256,string)"));
        
        uint256 ID = testTokenId;
        string memory fromAddressStr = _toLower(user1.toHexString());
        string memory toAddressStr = _toLower(user2.toHexString());
        uint256 fromTokenId = 1;
        uint256 slot = 1;
        uint256 value = 0; // Zero value
        string memory ctmRwa1AddrStr = _toLower(address(testToken).toHexString());

        bytes memory data = abi.encode(ID, fromAddressStr, toAddressStr, fromTokenId, slot, value, ctmRwa1AddrStr);
        bytes memory reason = "mintX failed";

        uint256 initialBalance = testToken.balanceOf(user1, slot);

        vm.prank(address(rwa1X));
        bool result = fallbackContract.rwa1XC3Fallback(mintXSelector, data, reason);

        assertTrue(result);

        uint256 finalBalance = testToken.balanceOf(user1, slot);
        assertEq(finalBalance, initialBalance + value);
    }

    function test_Rwa1XC3Fallback_MintXSelector_MultipleCalls() public {
        bytes4 mintXSelector = bytes4(keccak256("mintX(uint256,string,string,uint256,uint256,uint256,string)"));
        
        uint256 ID = testTokenId;
        string memory fromAddressStr = _toLower(user1.toHexString());
        string memory toAddressStr = _toLower(user2.toHexString());
        uint256 fromTokenId = 1;
        uint256 slot = 1;
        uint256 value1 = 1000;
        uint256 value2 = 2000;
        string memory ctmRwa1AddrStr = _toLower(address(testToken).toHexString());

        bytes memory data1 = abi.encode(ID, fromAddressStr, toAddressStr, fromTokenId, slot, value1, ctmRwa1AddrStr);
        bytes memory data2 = abi.encode(ID, fromAddressStr, toAddressStr, fromTokenId, slot, value2, ctmRwa1AddrStr);
        bytes memory reason = "mintX failed";

        uint256 initialBalance = testToken.balanceOf(user1, slot);

        // First call
        vm.prank(address(rwa1X));
        bool result1 = fallbackContract.rwa1XC3Fallback(mintXSelector, data1, reason);
        assertTrue(result1);

        // Second call
        vm.prank(address(rwa1X));
        bool result2 = fallbackContract.rwa1XC3Fallback(mintXSelector, data2, reason);
        assertTrue(result2);

        uint256 finalBalance = testToken.balanceOf(user1, slot);
        assertEq(finalBalance, initialBalance + value1 + value2);
    }

    function test_Rwa1XC3Fallback_MintXSelector_DifferentSlots() public {
        bytes4 mintXSelector = bytes4(keccak256("mintX(uint256,string,string,uint256,uint256,uint256,string)"));
        
        // Create additional slots
        _createSlot(testTokenId, 2, address(usdc), address(rwa1X));
        _createSlot(testTokenId, 3, address(usdc), address(rwa1X));
        
        uint256 ID = testTokenId;
        string memory fromAddressStr = _toLower(user1.toHexString());
        string memory toAddressStr = _toLower(user2.toHexString());
        uint256 fromTokenId = 1;
        uint256 value = 1000;
        string memory ctmRwa1AddrStr = _toLower(address(testToken).toHexString());

        // Test slot 1
        bytes memory data1 = abi.encode(ID, fromAddressStr, toAddressStr, fromTokenId, 1, value, ctmRwa1AddrStr);
        bytes memory reason = "mintX failed";

        vm.prank(address(rwa1X));
        bool result1 = fallbackContract.rwa1XC3Fallback(mintXSelector, data1, reason);
        assertTrue(result1);

        // Test slot 2
        bytes memory data2 = abi.encode(ID, fromAddressStr, toAddressStr, fromTokenId, 2, value, ctmRwa1AddrStr);

        vm.prank(address(rwa1X));
        bool result2 = fallbackContract.rwa1XC3Fallback(mintXSelector, data2, reason);
        assertTrue(result2);

        // Test slot 3
        bytes memory data3 = abi.encode(ID, fromAddressStr, toAddressStr, fromTokenId, 3, value, ctmRwa1AddrStr);

        vm.prank(address(rwa1X));
        bool result3 = fallbackContract.rwa1XC3Fallback(mintXSelector, data3, reason);
        assertTrue(result3);

        // Check balances in different slots
        assertEq(testToken.balanceOf(user1, 1), value);
        assertEq(testToken.balanceOf(user1, 2), value);
        assertEq(testToken.balanceOf(user1, 3), value);
    }

    function test_Rwa1XC3Fallback_MintXSelector_DifferentRecipients() public {
        bytes4 mintXSelector = bytes4(keccak256("mintX(uint256,string,string,uint256,uint256,uint256,string)"));
        
        uint256 ID = testTokenId;
        string memory fromAddressStr = _toLower(user1.toHexString());
        uint256 fromTokenId = 1;
        uint256 slot = 1;
        uint256 value = 1000;
        string memory ctmRwa1AddrStr = _toLower(address(testToken).toHexString());

        // Test user2
        string memory toAddressStr1 = _toLower(user2.toHexString());
        bytes memory data1 = abi.encode(ID, fromAddressStr, toAddressStr1, fromTokenId, slot, value, ctmRwa1AddrStr);
        bytes memory reason = "mintX failed";

        vm.prank(address(rwa1X));
        bool result1 = fallbackContract.rwa1XC3Fallback(mintXSelector, data1, reason);
        assertTrue(result1);

        // Test user1
        string memory toAddressStr2 = _toLower(user1.toHexString());
        bytes memory data2 = abi.encode(ID, fromAddressStr, toAddressStr2, fromTokenId, slot, value, ctmRwa1AddrStr);

        vm.prank(address(rwa1X));
        bool result2 = fallbackContract.rwa1XC3Fallback(mintXSelector, data2, reason);
        assertTrue(result2);

        // Test admin
        string memory toAddressStr3 = _toLower(admin.toHexString());
        bytes memory data3 = abi.encode(ID, fromAddressStr, toAddressStr3, fromTokenId, slot, value, ctmRwa1AddrStr);

        vm.prank(address(rwa1X));
        bool result3 = fallbackContract.rwa1XC3Fallback(mintXSelector, data3, reason);
        assertTrue(result3);

        // Check balances for different recipients
        // All tokens are minted to user1 (fromAddr), so the total balance should be 3 * value
        assertEq(testToken.balanceOf(user1, slot), 3 * value);
    }

    function test_Rwa1XC3Fallback_StorageVariables() public {
        bytes4 selector = bytes4(keccak256("test()"));
        bytes memory data = "test data";
        bytes memory reason = "test reason";

        vm.prank(address(rwa1X));
        fallbackContract.rwa1XC3Fallback(selector, data, reason);

        // Check storage variables
        assertEq(fallbackContract.lastSelector(), selector);
        assertEq(fallbackContract.lastData(), data);
        assertEq(fallbackContract.lastReason(), reason);

        // Update with new values
        bytes4 newSelector = bytes4(keccak256("newTest()"));
        bytes memory newData = "new test data";
        bytes memory newReason = "new test reason";

        vm.prank(address(rwa1X));
        fallbackContract.rwa1XC3Fallback(newSelector, newData, newReason);

        // Check updated storage variables
        assertEq(fallbackContract.lastSelector(), newSelector);
        assertEq(fallbackContract.lastData(), newData);
        assertEq(fallbackContract.lastReason(), newReason);
    }
}

// Simple test contract that doesn't inherit from Helpers to avoid upgrade validation
contract CTMRWA1XFallbackSimpleTest is Test {
    using CTMRWAUtils for string;
    using Strings for address;

    CTMRWA1XFallback fallbackContract;
    address rwa1X;

    function setUp() public {
        // Create a mock RWA1X address
        rwa1X = address(0x1234567890123456789012345678901234567890);
        
        // Deploy the fallback contract
        fallbackContract = new CTMRWA1XFallback(rwa1X);
    }

    function test_SimpleConstructor() public {
        assertEq(fallbackContract.rwa1X(), rwa1X);
    }

    function test_SimpleOnlyRwa1XModifier() public {
        vm.expectRevert(abi.encodeWithSelector(ICTMRWA1XFallback.CTMRWA1XFallback_Unauthorized.selector, 0));
        bytes4 selector = bytes4(keccak256("test()"));
        bytes memory data = "";
        bytes memory reason = "test reason";

        // Should revert when called by non-RWA1X address
        fallbackContract.rwa1XC3Fallback(selector, data, reason);
    }

    function test_SimpleNonMintXSelector() public {
        bytes4 selector = bytes4(keccak256("transfer(address,uint256)"));
        bytes memory data = abi.encode(address(0x1), 100);
        bytes memory reason = "transfer failed";

        vm.prank(rwa1X);
        bool result = fallbackContract.rwa1XC3Fallback(selector, data, reason);

        assertTrue(result);
        assertEq(fallbackContract.lastSelector(), selector);
        assertEq(fallbackContract.lastData(), data);
        assertEq(fallbackContract.lastReason(), reason);
    }

    function test_SimpleGetLastReason() public {
        bytes4 selector = bytes4(keccak256("test()"));
        bytes memory data = "";
        string memory reason = "test reason string";
        bytes memory reasonBytes = bytes(reason);

        vm.prank(rwa1X);
        fallbackContract.rwa1XC3Fallback(selector, data, reasonBytes);

        string memory retrievedReason = fallbackContract.getLastReason();
        assertEq(retrievedReason, reason);
    }

    function test_SimpleStorageVariables() public {
        bytes4 selector = bytes4(keccak256("test()"));
        bytes memory data = "test data";
        bytes memory reason = "test reason";

        vm.prank(rwa1X);
        fallbackContract.rwa1XC3Fallback(selector, data, reason);

        // Check storage variables
        assertEq(fallbackContract.lastSelector(), selector);
        assertEq(fallbackContract.lastData(), data);
        assertEq(fallbackContract.lastReason(), reason);

        // Update with new values
        bytes4 newSelector = bytes4(keccak256("newTest()"));
        bytes memory newData = "new test data";
        bytes memory newReason = "new test reason";

        vm.prank(rwa1X);
        fallbackContract.rwa1XC3Fallback(newSelector, newData, newReason);

        // Check updated storage variables
        assertEq(fallbackContract.lastSelector(), newSelector);
        assertEq(fallbackContract.lastData(), newData);
        assertEq(fallbackContract.lastReason(), newReason);
    }
}
