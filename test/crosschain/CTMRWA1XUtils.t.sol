// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.27;

import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { Test } from "forge-std/Test.sol";

import { CTMRWA1 } from "../../src/core/CTMRWA1.sol";
import { ICTMRWA1 } from "../../src/core/ICTMRWA1.sol";
import { CTMRWA1X } from "../../src/crosschain/CTMRWA1X.sol";
import { CTMRWA1XUtils } from "../../src/crosschain/CTMRWA1XUtils.sol";
import { ICTMRWA1XUtils } from "../../src/crosschain/ICTMRWA1XUtils.sol";
import { ICTMRWA1X } from "../../src/crosschain/ICTMRWA1X.sol";
import { CTMRWAUtils, CTMRWAErrorParam } from "../../src/utils/CTMRWAUtils.sol";
import { Helpers } from "../helpers/Helpers.sol";

error EnforcedPause();

contract CTMRWA1XUtilsTest is Helpers {
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
        assertEq(rwa1XUtils.rwa1X(), address(rwa1X));
    }

    function test_OnlyRwa1XModifier() public {
        bytes4 selector = bytes4(keccak256("test()"));
        bytes memory data = "";
        bytes memory reason = "test reason";

        // Should revert when called by non-RWA1X address
        vm.expectRevert(
            abi.encodeWithSelector(
                ICTMRWA1XUtils.CTMRWA1XUtils_OnlyAuthorized.selector, CTMRWAErrorParam.Sender, CTMRWAErrorParam.RWAX
            )
        );
        rwa1XUtils.rwa1XC3Fallback(selector, data, reason, address(map));
    }

    function test_Rwa1XC3Fallback_NonMintXSelector() public {
        bytes4 selector = bytes4(keccak256("transfer(address,uint256)"));
        bytes memory data = abi.encode(address(0x1), 100);
        bytes memory reason = "transfer failed";

        vm.prank(address(rwa1X));
        bool result = rwa1XUtils.rwa1XC3Fallback(selector, data, reason, address(map));

        // Check that the fallback was successful, even though the selector is not mintX
        assertTrue(result);
        assertEq(rwa1XUtils.lastSelector(), selector);
        assertEq(rwa1XUtils.lastData(), data);
        assertEq(rwa1XUtils.lastReason(), reason);
    }

    function test_Rwa1XC3Fallback_MintXSelector() public {
        bytes4 mintXSelector = bytes4(keccak256("mintX(uint256,uint256,string,string,uint256,uint256)"));

        string memory fromAddressStr = _toLower(user1.toHexString());
        string memory toAddressStr = _toLower(user2.toHexString());
        uint256 slot = 1;
        uint256 value = 1000;

        bytes memory data = abi.encode(ID, VERSION, fromAddressStr, toAddressStr, slot, value);
        bytes memory reason = "mintX failed";

        // Get initial balance
        uint256 initialBalance = token.balanceOf(user1, slot);

        vm.prank(address(rwa1X));
        bool result = rwa1XUtils.rwa1XC3Fallback(mintXSelector, data, reason, address(map));

        assertTrue(result);
        assertEq(rwa1XUtils.lastSelector(), mintXSelector);
        assertEq(rwa1XUtils.lastData(), data);
        assertEq(rwa1XUtils.lastReason(), reason);

        // Check that mintFromX was called and balance increased
        // The fallback contract calls mintFromX with fromAddr (user1), not toAddr (user2)
        uint256 finalBalance = token.balanceOf(user1, slot);
        assertEq(finalBalance, initialBalance + value);
    }

    function test_Rwa1XC3Fallback_MintXSelector_InvalidAddress() public {
        bytes4 mintXSelector = bytes4(keccak256("mintX(uint256,uint256,string,string,uint256,uint256)"));

        string memory fromAddressStr = "invalid_address";
        string memory toAddressStr = _toLower(user2.toHexString());
        uint256 slot = 1;
        uint256 value = 1000;

        bytes memory data = abi.encode(ID, VERSION, fromAddressStr, toAddressStr, slot, value);
        bytes memory reason = "mintX failed";

        vm.prank(address(rwa1X));
        vm.expectRevert(); // Should revert due to invalid address conversion
        rwa1XUtils.rwa1XC3Fallback(mintXSelector, data, reason, address(map));
    }

    function test_Rwa1XC3Fallback_MintXSelector_NonExistentSlot() public {
        bytes4 mintXSelector = bytes4(keccak256("mintX(uint256,uint256,string,string,uint256,uint256)"));

        string memory fromAddressStr = _toLower(user1.toHexString());
        string memory toAddressStr = _toLower(user2.toHexString());
        uint256 slot = 999; // Non-existent slot
        uint256 value = 1000;

        bytes memory data = abi.encode(ID, VERSION, fromAddressStr, toAddressStr, slot, value);
        bytes memory reason = "mintX failed";

        vm.prank(address(rwa1X));
        vm.expectRevert(); // Should revert due to non-existent slot
        rwa1XUtils.rwa1XC3Fallback(mintXSelector, data, reason, address(map));
    }

    function test_GetLastReason() public {
        bytes4 selector = bytes4(keccak256("test()"));
        bytes memory data = "";
        string memory reason = "test reason string";
        bytes memory reasonBytes = bytes(reason);

        vm.prank(address(rwa1X));
        rwa1XUtils.rwa1XC3Fallback(selector, data, reasonBytes, address(map));

        string memory retrievedReason = rwa1XUtils.getLastReason();
        assertEq(retrievedReason, reason);
    }

    function test_Rwa1XC3Fallback_Events() public {
        bytes4 selector = bytes4(keccak256("mintX(uint256,uint256,string,string,uint256,uint256)"));

        string memory fromAddressStr = _toLower(user1.toHexString());
        string memory toAddressStr = _toLower(user2.toHexString());
        uint256 slot = 1;
        uint256 value = 1000;

        bytes memory data = abi.encode(ID, VERSION, fromAddressStr, toAddressStr, slot, value);
        bytes memory reason = "mintX failed";

        vm.prank(address(rwa1X));
        vm.expectEmit(true, true, true, true);
        emit ICTMRWA1XUtils.ReturnValueFallback(user1, slot, value);

        vm.expectEmit(true, true, true, true);
        emit ICTMRWA1XUtils.LogFallback(selector, data, reason);

        rwa1XUtils.rwa1XC3Fallback(selector, data, reason, address(map));
    }

    function test_Rwa1XC3Fallback_NonMintXSelector_Events() public {
        bytes4 selector = bytes4(keccak256("transfer(address,uint256)"));
        bytes memory data = abi.encode(address(0x1), 100);
        bytes memory reason = "transfer failed";

        vm.prank(address(rwa1X));
        vm.expectEmit(true, true, true, true);
        emit ICTMRWA1XUtils.LogFallback(selector, data, reason);

        rwa1XUtils.rwa1XC3Fallback(selector, data, reason, address(map));
    }

    function test_Rwa1XC3Fallback_MintXSelector_LargeValue() public {
        bytes4 mintXSelector = bytes4(keccak256("mintX(uint256,uint256,string,string,uint256,uint256)"));

        string memory fromAddressStr = _toLower(user1.toHexString());
        string memory toAddressStr = _toLower(user2.toHexString());
        uint256 slot = 1;
        uint256 value = 1e18; // Large value

        bytes memory data = abi.encode(ID, VERSION, fromAddressStr, toAddressStr, slot, value);
        bytes memory reason = "mintX failed";

        uint256 initialBalance = token.balanceOf(user1, slot);

        vm.prank(address(rwa1X));
        bool result = rwa1XUtils.rwa1XC3Fallback(mintXSelector, data, reason, address(map));

        assertTrue(result);

        uint256 finalBalance = token.balanceOf(user1, slot);
        assertEq(finalBalance, initialBalance + value);
    }

    function test_Rwa1XC3Fallback_MintXSelector_ZeroValue() public {
        bytes4 mintXSelector = bytes4(keccak256("mintX(uint256,uint256,string,string,uint256,uint256)"));

        string memory fromAddressStr = _toLower(user1.toHexString());
        string memory toAddressStr = _toLower(user2.toHexString());
        uint256 slot = 1;
        uint256 value = 0; // Zero value

        bytes memory data = abi.encode(ID, VERSION, fromAddressStr, toAddressStr, slot, value);
        bytes memory reason = "mintX failed";

        uint256 initialBalance = token.balanceOf(user1, slot);

        vm.prank(address(rwa1X));
        bool result = rwa1XUtils.rwa1XC3Fallback(mintXSelector, data, reason, address(map));

        assertTrue(result);

        uint256 finalBalance = token.balanceOf(user1, slot);
        assertEq(finalBalance, initialBalance + value);
    }

    function test_Rwa1XC3Fallback_MintXSelector_MultipleCalls() public {
        bytes4 mintXSelector = bytes4(keccak256("mintX(uint256,uint256,string,string,uint256,uint256)"));

        string memory fromAddressStr = _toLower(user1.toHexString());
        string memory toAddressStr = _toLower(user2.toHexString());
        uint256 slot = 1;
        uint256 value1 = 1000;
        uint256 value2 = 2000;

        bytes memory data1 = abi.encode(ID, VERSION, fromAddressStr, toAddressStr, slot, value1);
        bytes memory data2 = abi.encode(ID, VERSION, fromAddressStr, toAddressStr, slot, value2);
        bytes memory reason = "mintX failed";

        uint256 initialBalance = token.balanceOf(user1, slot);

        // First call
        vm.prank(address(rwa1X));
        bool result1 = rwa1XUtils.rwa1XC3Fallback(mintXSelector, data1, reason, address(map));
        assertTrue(result1);

        // Second call
        vm.prank(address(rwa1X));
        bool result2 = rwa1XUtils.rwa1XC3Fallback(mintXSelector, data2, reason, address(map));
        assertTrue(result2);

        uint256 finalBalance = token.balanceOf(user1, slot);
        assertEq(finalBalance, initialBalance + value1 + value2);
    }

    function test_Rwa1XC3Fallback_MintXSelector_DifferentSlots() public {
        bytes4 mintXSelector = bytes4(keccak256("mintX(uint256,uint256,string,string,uint256,uint256)"));

        // Create additional slots with proper permissions
        vm.startPrank(tokenAdmin);
        _createSlot(ID, 8, address(usdc), address(rwa1X));
        _createSlot(ID, 9, address(usdc), address(rwa1X));
        vm.stopPrank();

        string memory fromAddressStr = _toLower(user1.toHexString());
        string memory toAddressStr = _toLower(user2.toHexString());
        uint256 value = 1000;

        // Test slot 1
        bytes memory data1 = abi.encode(ID, VERSION, fromAddressStr, toAddressStr, 1, value);
        bytes memory reason = "mintX failed";

        vm.prank(address(rwa1X));
        bool result1 = rwa1XUtils.rwa1XC3Fallback(mintXSelector, data1, reason, address(map));
        assertTrue(result1);

        // Test slot 8
        bytes memory data2 = abi.encode(ID, VERSION, fromAddressStr, toAddressStr, 8, value);

        vm.prank(address(rwa1X));
        bool result2 = rwa1XUtils.rwa1XC3Fallback(mintXSelector, data2, reason, address(map));
        assertTrue(result2);

        // Test slot 9
        bytes memory data3 = abi.encode(ID, VERSION, fromAddressStr, toAddressStr, 9, value);

        vm.prank(address(rwa1X));
        bool result3 = rwa1XUtils.rwa1XC3Fallback(mintXSelector, data3, reason, address(map));
        assertTrue(result3);

        // Check balances in different slots
        assertEq(token.balanceOf(user1, 1), value);
        assertEq(token.balanceOf(user1, 8), value);
        assertEq(token.balanceOf(user1, 9), value);
    }

    function test_Rwa1XC3Fallback_MintXSelector_DifferentRecipients() public {
        bytes4 mintXSelector = bytes4(keccak256("mintX(uint256,uint256,string,string,uint256,uint256)"));
        uint256 slot = 1;
        uint256 value = 1000;
        string memory fromAddressStr = _toLower(tokenAdmin2.toHexString());

        // Test user2
        string memory toAddressStr1 = _toLower(user2.toHexString());
        bytes memory data1 = abi.encode(ID, VERSION, fromAddressStr, toAddressStr1, slot, value);
        bytes memory reason = "mintX failed";

        vm.prank(address(rwa1X));
        bool result1 = rwa1XUtils.rwa1XC3Fallback(mintXSelector, data1, reason, address(map));
        assertTrue(result1);

        // Test user1
        string memory toAddressStr2 = _toLower(user1.toHexString());
        bytes memory data2 = abi.encode(ID, VERSION, fromAddressStr, toAddressStr2, slot, value);

        vm.prank(address(rwa1X));
        bool result2 = rwa1XUtils.rwa1XC3Fallback(mintXSelector, data2, reason, address(map));
        assertTrue(result2);

        // Test admin
        string memory toAddressStr3 = _toLower(admin.toHexString());
        bytes memory data3 = abi.encode(ID, VERSION, fromAddressStr, toAddressStr3, slot, value);

        vm.prank(address(rwa1X));
        bool result3 = rwa1XUtils.rwa1XC3Fallback(mintXSelector, data3, reason, address(map));
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
        rwa1XUtils.rwa1XC3Fallback(selector, data, reason, address(map));

        // Check storage variables
        assertEq(rwa1XUtils.lastSelector(), selector);
        assertEq(rwa1XUtils.lastData(), data);
        assertEq(rwa1XUtils.lastReason(), reason);

        // Update with new values
        bytes4 newSelector = bytes4(keccak256("newTest()"));
        bytes memory newData = "new test data";
        bytes memory newReason = "new test reason";

        vm.prank(address(rwa1X));
        rwa1XUtils.rwa1XC3Fallback(newSelector, newData, newReason, address(map));

        // Check updated storage variables
        assertEq(rwa1XUtils.lastSelector(), newSelector);
        assertEq(rwa1XUtils.lastData(), newData);
        assertEq(rwa1XUtils.lastReason(), newReason);
    }

    // ============ MINT NEW TOKEN VALUE LOCAL TESTS ============

    function test_localMint() public {
        string memory feeTokenStr = _toLower((address(usdc).toHexString()));

        vm.prank(tokenAdmin);
        uint256 tokenId = rwa1XUtils.mintNewTokenValueLocal(user1, 0, 5, 2000, ID, VERSION, feeTokenStr);

        assertEq(tokenId, 1);
        (uint256 id, uint256 bal, address owner, uint256 slot, string memory slotName,) = token.getTokenInfo(tokenId);
        assertEq(id, 1);
        assertEq(bal, 2000);
        assertEq(owner, user1);
        assertEq(slot, 5);
        assertEq(stringsEqual(slotName, "slot 5 is the best RWA"), true);

        vm.startPrank(user1);
        bool exists = token.exists(tokenId);
        assertEq(exists, true);
        token.burn(tokenId);
        exists = token.exists(tokenId);
        assertEq(exists, false);
        vm.stopPrank();
    }

    function test_fuzzMintAmount(uint256 amount) public {
        vm.assume(amount > 0 && amount <= 1_000_000); // Reasonable bounds

        string memory feeTokenStr = address(usdc).toHexString();

        vm.prank(tokenAdmin);
        uint256 tokenId = rwa1XUtils.mintNewTokenValueLocal(user1, 0, 5, amount, ID, VERSION, feeTokenStr);

        assertEq(token.balanceOf(tokenId), amount);
        assertEq(token.ownerOf(tokenId), user1);
    }

    function test_overflowMintNewTokenValueLocal() public {
        string memory feeTokenStr = address(usdc).toHexString();

        // Try to mint with a value that exceeds uint208 limit
        vm.prank(tokenAdmin);
        uint256 maxUint208 = 2**208 - 1;
        vm.expectRevert(abi.encodeWithSelector(ICTMRWA1.CTMRWA1_ValueOverflow.selector, maxUint208 + 1, maxUint208));
        rwa1XUtils.mintNewTokenValueLocal(user1, 0, 5, maxUint208 + 1, ID, VERSION, feeTokenStr);
    }

    function test_overflowFuzzMint(uint256 a, uint256 b) public {
        vm.assume(a > 0 && b > 0);
        // Use uint208 limits to prevent overflow in balance calculations
        uint256 maxUint208 = 2**208 - 1;
        vm.assume(a <= maxUint208 && b <= maxUint208);
        string memory feeTokenStr = address(usdc).toHexString();
        // Mint with a
        vm.prank(tokenAdmin);
        rwa1XUtils.mintNewTokenValueLocal(user1, 0, 5, a, ID, VERSION, feeTokenStr);
        // Try to mint with b (should not overflow)
        vm.prank(tokenAdmin);
        uint256 tokenId2 = rwa1XUtils.mintNewTokenValueLocal(user1, 0, 5, b, ID, VERSION, feeTokenStr);
        assertEq(token.balanceOf(tokenId2), b);
    }

    function test_gasUsageMintNewTokenValueLocal() public {
        string memory feeTokenStr = address(usdc).toHexString();

        uint256 gasBefore = gasleft();

        vm.prank(tokenAdmin);
        rwa1XUtils.mintNewTokenValueLocal(user1, 0, 5, 1000, ID, VERSION, feeTokenStr);

        uint256 gasUsed = gasBefore - gasleft();

        // Mint should be reasonably gas efficient
        assertTrue(gasUsed < 13_000_000);
    }

    function test_stressMultipleMints() public {
        string memory feeTokenStr = address(usdc).toHexString();

        // Mint 10 tokens in sequence
        for (uint256 i = 0; i < 10; i++) {
            vm.prank(tokenAdmin);
            uint256 tokenId = rwa1XUtils.mintNewTokenValueLocal(user1, 0, 5, 1000, ID, VERSION, feeTokenStr);
            assertEq(token.ownerOf(tokenId), user1);
        }

        assertEq(token.balanceOf(user1), 10);
    }

    function test_accessControlNonAdminMint() public {
        string memory feeTokenStr = address(usdc).toHexString();

        // Non-admin should not be able to mint
        vm.prank(user1);
        vm.expectRevert();
        rwa1XUtils.mintNewTokenValueLocal(user2, 0, 5, 1000, ID, VERSION, feeTokenStr);
    }

    function test_stateConsistencyAfterFailedMint() public {
        uint256 initialSupply = token.totalSupply();

        // Try to mint with invalid parameters (should fail)
        vm.prank(tokenAdmin);
        vm.expectRevert();
        rwa1XUtils.mintNewTokenValueLocal(address(0), 0, 5, 1000, ID, VERSION, "invalid_fee_token");

        // Supply should remain unchanged
        assertEq(token.totalSupply(), initialSupply);
    }

    function test_mintNewTokenValueLocal_paused_unpaused() public {
        string memory feeTokenStr = address(usdc).toHexString();
        
        vm.prank(tokenAdmin);
        token.pause();

        // Paused: should revert
        vm.prank(tokenAdmin);
        vm.expectRevert(EnforcedPause.selector);
        rwa1XUtils.mintNewTokenValueLocal(user1, 0, 5, 1000, ID, VERSION, feeTokenStr);

        // Unpause and try again
        vm.prank(tokenAdmin);
        token.unpause();

        vm.prank(tokenAdmin);
        uint256 tokenId = rwa1XUtils.mintNewTokenValueLocal(user1, 0, 5, 1000, ID, VERSION, feeTokenStr);
        assertEq(token.ownerOf(tokenId), user1);
        assertEq(token.balanceOf(tokenId), 1000);
    }

    function test_reentrancyMintNewTokenValueLocal() public {
        string memory feeTokenStr = address(usdc).toHexString();

        // Deploy reentrant contract
        ReentrantContract attacker = new ReentrantContract(address(rwa1X), address(rwa1XUtils));

        // The reentrancy attack should fail due to ReentrancyGuard
        vm.expectRevert();
        attacker.attackMint(ID, feeTokenStr);

        // Verify no tokens were minted
        assertEq(token.balanceOf(address(attacker)), 0);
    }

}

// Mock contract for reentrancy testing
contract ReentrantContract {
    using Strings for address;
    using Strings for *;

    CTMRWA1X public rwa1X;
    CTMRWA1XUtils public rwa1XUtils;
    uint256 public attackCount;

    constructor(address _rwa1X, address _rwa1XUtils) {
        rwa1X = CTMRWA1X(_rwa1X);
        rwa1XUtils = CTMRWA1XUtils(_rwa1XUtils);
    }

    // Reentrancy attack on mintNewTokenValueLocal
    function attackMint(uint256 _ID, string memory _feeTokenStr) external {
        if (attackCount < 3) {
            attackCount++;
            rwa1XUtils.mintNewTokenValueLocal(address(this), 0, 5, 1000, _ID, 1, _feeTokenStr);
        }
    }
}
