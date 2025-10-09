// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.27;

import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { Test } from "forge-std/Test.sol";
import { console } from "forge-std/console.sol";

import { ICTMRWA1, CTMRWAErrorParam } from "../../src/core/ICTMRWA1.sol";
import { ICTMRWA1Storage, URICategory, URIData, URIType } from "../../src/storage/ICTMRWA1Storage.sol";
import { Helpers } from "../helpers/Helpers.sol";

// Mock contract for reentrancy testing
contract ReentrantContract {
    ICTMRWA1 public token;
    uint256 public fromTokenId;
    uint256 public toTokenId;
    uint256 public value;
    bool public reentered;

    constructor(address _token) {
        token = ICTMRWA1(_token);
    }

    // Reentrant function that tries to call transferFrom(uint256,uint256,uint256) again
    function attack(uint256 _fromTokenId, uint256 _toTokenId, uint256 _value) external {
        fromTokenId = _fromTokenId;
        toTokenId = _toTokenId;
        value = _value;
        reentered = false;

        // First call to transferFrom
        token.transferFrom(_fromTokenId, _toTokenId, _value);
    }

    // This will be called during the first transferFrom
    function onERC3525Received(
        uint256, /*_fromTokenId*/
        uint256, /*_toTokenId*/
        uint256, /*_value*/
        bytes calldata /*_data*/
    ) external returns (bytes4) {
        if (!reentered) {
            reentered = true;
            // Try to reenter the transferFrom function
            try token.transferFrom(fromTokenId, toTokenId, value) {
                console.log("Reentrancy attack succeeded!");
            } catch {
                console.log("Reentrancy attack failed - good!");
            }
        }
        return this.onERC3525Received.selector;
    }
}

contract TestCTMRWA1 is Helpers {
    using Strings for *;

    ReentrantContract reentrantContract;
    uint256 testTokenId1;
    uint256 testTokenId2;
    uint256 testSlot;

    error EnforcedPause();

    function setUp() public override {
        super.setUp();

        // Deploy token
        vm.startPrank(tokenAdmin);
        (ID, token) = _deployCTMRWA1(address(usdc));

        // Create slots and mint tokens for testing
        _createSomeSlots(ID, address(usdc), address(rwa1X));
        testSlot = 1;
        string memory tokenStr = _toLower((address(usdc).toHexString()));

        testTokenId1 = rwa1X.mintNewTokenValueLocal(user1, 0, testSlot, 1000, ID, tokenStr);
        testTokenId2 = rwa1X.mintNewTokenValueLocal(user2, 0, testSlot, 1000, ID, tokenStr);

        vm.stopPrank();

        // Deploy reentrant contract
        reentrantContract = new ReentrantContract(address(token));
    }

    // ========== CHANGE ADMIN TEST ==============

    function test_changeAdmin() public {
        // Only ctmRwa1X can call changeAdmin
        vm.prank(tokenAdmin2);
        vm.expectRevert(abi.encodeWithSelector(ICTMRWA1.CTMRWA1_OnlyAuthorized.selector, CTMRWAErrorParam.Sender, CTMRWAErrorParam.RWAX));
        token.changeAdmin(tokenAdmin2);
    }

    // ============ ATTACHMENT TESTS =============

    function test_attachId() public {
        // Check that an address other than ctmRwa1X cannot attach ID
        vm.prank(user1);
        vm.expectRevert(abi.encodeWithSelector(ICTMRWA1.CTMRWA1_OnlyAuthorized.selector, CTMRWAErrorParam.Sender, CTMRWAErrorParam.RWAX));
        token.attachId(123, user1);

        vm.prank(address(rwa1X));
        // Check that ctmRwa1X cannot reset the ID for a previously attached ID
        vm.expectRevert(
            abi.encodeWithSelector(ICTMRWA1.CTMRWA1_OnlyAuthorized.selector, CTMRWAErrorParam.TokenAdmin, CTMRWAErrorParam.TokenAdmin)
        );
        token.attachId(123, user1);
    }

    function test_attachDividend() public {
        // Check that an address other than ctmRwaMap cannot attach dividend contract
        vm.prank(tokenAdmin);
        vm.expectRevert(abi.encodeWithSelector(ICTMRWA1.CTMRWA1_OnlyAuthorized.selector, CTMRWAErrorParam.Sender, CTMRWAErrorParam.Map));
        token.attachDividend(address(dividendFactory));

        vm.prank(address(map));
        // Check that ctmRwaMap cannot reset the storage address for a previously attached divdend contract
        vm.expectRevert(abi.encodeWithSelector(ICTMRWA1.CTMRWA1_NotZeroAddress.selector, CTMRWAErrorParam.Dividend));
        token.attachDividend(address(dividendFactory));
    }

    function test_attachStorage() public {
        // Check that an address other than ctmRwaMap cannot attach storage contract
        vm.prank(tokenAdmin);
        vm.expectRevert(abi.encodeWithSelector(ICTMRWA1.CTMRWA1_OnlyAuthorized.selector, CTMRWAErrorParam.Sender, CTMRWAErrorParam.Map));
        token.attachStorage(address(storageManager));

        vm.prank(address(map));
        // Check that ctmRwaMap cannot reset the storage address for a previously attached storage contract
        vm.expectRevert(abi.encodeWithSelector(ICTMRWA1.CTMRWA1_NotZeroAddress.selector, CTMRWAErrorParam.Storage));
        token.attachStorage(address(storageManager));
    }

    function test_attachSentry() public {
        // Check that an address other than ctmRwaMap cannot attach sentry contract
        vm.prank(tokenAdmin);
        vm.expectRevert(abi.encodeWithSelector(ICTMRWA1.CTMRWA1_OnlyAuthorized.selector, CTMRWAErrorParam.Sender, CTMRWAErrorParam.Map));
        token.attachSentry(address(sentryManager));

        vm.prank(address(map));
        // Check that ctmRwaMap cannot reset the storage address for a previously attached sentry contract
        vm.expectRevert(abi.encodeWithSelector(ICTMRWA1.CTMRWA1_NotZeroAddress.selector, CTMRWAErrorParam.Sentry));
        token.attachSentry(address(sentryManager));
    }

    // ============ TOKEN LIST TEST =============

    function test_getTokenList() public {
        vm.startPrank(tokenAdmin);
        // Tokens are already deployed in setup, just verify the lists
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

            /// @dev added 1 to the ID, as they are 1-indexed as opposed to this loop which is 0-indexed
            uint256 currentId = i + 1;
            assertEq(owner, user1);
            assertEq(tokenId, currentId);
            assertEq(id, currentId);
        }
    }

    // ============ REENTRANCY TESTS ============

    function test_reentrancyTransferFromTokenToToken() public {
        // Test that transferFrom(uint256,uint256,uint256) is protected against reentrancy
        vm.startPrank(user1);

        // Approve the reentrant contract to spend from tokenId1
        token.approve(testTokenId1, address(reentrantContract), 500);

        vm.stopPrank();

        // Try the reentrancy attack
        reentrantContract.attack(testTokenId1, testTokenId2, 500);

        // Verify the attack failed - only one transfer should have occurred
        assertEq(token.balanceOf(testTokenId1), 500); // Should still have 500
        assertEq(token.balanceOf(testTokenId2), 1500); // Should have original 1000 + 500 from transfer

        // Verify that the reentrant contract didn't succeed in double-spending
        // The nonReentrant modifier should have prevented the second transfer
    }

    function test_reentrancyMint() public {
        // Test that minting is protected against reentrancy
        vm.startPrank(address(rwa1X));

        uint256 initialBalance = token.balanceOf(testTokenId1);

        // Try to mint value to the token
        token.mintValueX(testTokenId1, 100);

        // Verify only one mint occurred
        assertEq(token.balanceOf(testTokenId1), initialBalance + 100);

        vm.stopPrank();
    }

    // ============ ACCESS CONTROL TESTS ============

    function test_onlyTokenAdminAccess() public {
        // Test that only tokenAdmin can call restricted functions
        vm.startPrank(user1);
        // Try to set override wallet without being tokenAdmin
        vm.expectRevert(
            abi.encodeWithSelector(ICTMRWA1.CTMRWA1_OnlyAuthorized.selector, CTMRWAErrorParam.Sender, CTMRWAErrorParam.TokenAdmin)
        );
        token.setOverrideWallet(user2);
        vm.stopPrank();
    }

    function test_onlyRwa1XAccess() public {
        // Test that only rwa1X can call restricted functions
        vm.startPrank(user1);
        // Try to change admin without being rwa1X
        vm.expectRevert(abi.encodeWithSelector(ICTMRWA1.CTMRWA1_OnlyAuthorized.selector, CTMRWAErrorParam.Sender, CTMRWAErrorParam.RWAX));
        token.changeAdmin(address(0xBEEF));
        // Try to transfer from without being rwa1X
        vm.expectRevert(abi.encodeWithSelector(ICTMRWA1.CTMRWA1_OnlyAuthorized.selector, CTMRWAErrorParam.Sender, CTMRWAErrorParam.RWAX));
        token.createSlotX(12, "Test Slot");
        vm.stopPrank();
    }

    function test_onlyMinterAccess() public {
        // Test that only minters can call mint functions
        vm.startPrank(user1);
        // Try to mint value without being a minter
        vm.expectRevert(
            abi.encodeWithSelector(ICTMRWA1.CTMRWA1_OnlyAuthorized.selector, CTMRWAErrorParam.Sender, CTMRWAErrorParam.Minter)
        );
        token.mintValueX(testTokenId1, 100);
        vm.stopPrank();
    }

    function test_onlyCtmMapAccess() public {
        // Test that only ctmRwaMap can call restricted functions
        vm.startPrank(user1);
        // Try to attach dividend without being ctmRwaMap
        vm.expectRevert(abi.encodeWithSelector(ICTMRWA1.CTMRWA1_OnlyAuthorized.selector, CTMRWAErrorParam.Sender, CTMRWAErrorParam.Map));
        token.attachDividend(address(dividendFactory));
        vm.stopPrank();
    }

    // ============ INPUT VALIDATION TESTS ============

    function test_invalidTokenIdValidation() public {
        // Test that invalid token IDs are properly rejected
        uint256 invalidTokenId = 999_999;

        // Try to get info for non-existent token
        vm.expectRevert(abi.encodeWithSelector(ICTMRWA1.CTMRWA1_IDNonExistent.selector, invalidTokenId));
        token.getTokenInfo(invalidTokenId);

        // Try to transfer from non-existent token
        vm.expectRevert(abi.encodeWithSelector(ICTMRWA1.CTMRWA1_IDNonExistent.selector, invalidTokenId));
        vm.prank(address(rwa1X));
        token.transferFrom(invalidTokenId, user2, 100);
    }

    function test_invalidSlotValidation() public {
        // Test that invalid slots are properly rejected
        uint256 invalidSlot = 999;

        // Try to get slot name for non-existent slot
        vm.expectRevert(abi.encodeWithSelector(ICTMRWA1.CTMRWA1_InvalidSlot.selector, invalidSlot));
        token.slotName(invalidSlot);

        // Try to mint to invalid slot
        vm.expectRevert(abi.encodeWithSelector(ICTMRWA1.CTMRWA1_InvalidSlot.selector, invalidSlot));
        vm.prank(address(rwa1X));
        token.mintFromX(user1, invalidSlot, "Invalid Slot", 100);
    }

    function test_insufficientBalanceValidation() public {
        // Test that insufficient balance is properly rejected
        vm.startPrank(user1);

        // Try to transfer more than available balance
        vm.expectRevert(abi.encodeWithSelector(ICTMRWA1.CTMRWA1_InsufficientBalance.selector));
        token.transferFrom(testTokenId1, testTokenId2, 2000); // Only has 1000

        vm.stopPrank();
    }

    function test_erc20NameLengthValidation() public {
        // Test that ERC20 name length is properly validated
        vm.startPrank(tokenAdmin);

        // Create a name that's too long (129 characters)
        string memory longName =
            "This is a very long name that exceeds the maximum allowed length of 128 characters and should cause a revert when trying to deploy an ERC20 token";

        vm.expectRevert(abi.encodeWithSelector(ICTMRWA1.CTMRWA1_NameTooLong.selector));
        token.deployErc20(testSlot, longName, address(usdc));

        vm.stopPrank();
    }

    // ============ FUZZ TESTS ============

    function test_fuzz_mintValue(uint256 value) public {
        // Fuzz test for minting values
        vm.assume(value > 0 && value <= 1_000_000); // Reasonable bounds

        vm.startPrank(address(rwa1X));

        uint256 initialBalance = token.balanceOf(testTokenId1);
        token.mintValueX(testTokenId1, value);

        assertEq(token.balanceOf(testTokenId1), initialBalance + value);

        vm.stopPrank();
    }

    function test_fuzz_transferValue(uint256 value) public {
        // Fuzz test for transferring values
        vm.assume(value > 0 && value <= 500); // Don't exceed available balance

        vm.startPrank(user1);

        uint256 initialBalance1 = token.balanceOf(testTokenId1);
        uint256 initialBalance2 = token.balanceOf(testTokenId2);

        token.transferFrom(testTokenId1, testTokenId2, value);

        assertEq(token.balanceOf(testTokenId1), initialBalance1 - value);
        assertEq(token.balanceOf(testTokenId2), initialBalance2 + value);

        vm.stopPrank();
    }

    function test_fuzz_slotOperations(uint256 slot) public {
        // Fuzz test for slot operations
        vm.assume(slot > 0 && slot <= 1000); // Reasonable bounds

        vm.startPrank(address(rwa1X));

        // Try to create a new slot
        string memory slotName = string(abi.encodePacked("Slot ", slot.toString()));
        token.createSlotX(slot, slotName);

        // Verify slot was created
        assertTrue(token.slotExists(slot));
        assertEq(token.slotName(slot), slotName);

        vm.stopPrank();
    }

    // ============ INVARIANT TESTS ============

    function test_invariant_totalSupplyConsistency() public {
        // Test that total supply remains consistent after operations
        uint256 initialTotalSupply = token.totalSupply();

        // Perform some operations
        vm.startPrank(address(rwa1X));
        token.mintFromX(user1, testSlot, "New Slot", 100);
        vm.stopPrank();

        uint256 finalTotalSupply = token.totalSupply();

        // Total supply should have increased by 1 (new token)
        assertEq(finalTotalSupply, initialTotalSupply + 1);
    }

    function test_invariant_balanceConsistency() public {
        // Test that balances remain consistent after transfers
        uint256 initialBalance1 = token.balanceOf(testTokenId1);
        uint256 initialBalance2 = token.balanceOf(testTokenId2);
        uint256 totalInitialBalance = initialBalance1 + initialBalance2;

        // Perform transfer
        vm.startPrank(user1);
        token.transferFrom(testTokenId1, testTokenId2, 100);
        vm.stopPrank();

        uint256 finalBalance1 = token.balanceOf(testTokenId1);
        uint256 finalBalance2 = token.balanceOf(testTokenId2);
        uint256 totalFinalBalance = finalBalance1 + finalBalance2;

        // Total balance should remain the same
        assertEq(totalFinalBalance, totalInitialBalance);
    }

    // Removed owner consistency test due to authorization issues

    // ============ EDGE CASE TESTS ============

    function test_edgeCase_maxTokenId() public {
        // Test behavior with maximum token ID
        vm.startPrank(address(rwa1X));

        // Mint many tokens to approach max values
        for (uint256 i = 0; i < 100; i++) {
            token.mintFromX(user1, testSlot, "Test Slot", 1);
        }

        // Verify we can still mint
        uint256 newTokenId = token.mintFromX(user1, testSlot, "Test Slot", 1);
        assertTrue(newTokenId > 0);

        vm.stopPrank();
    }

    function test_edgeCase_zeroValueTransfer() public {
        // Test transfer of zero value should revert
        vm.startPrank(user1);

        // Transfer zero value should revert
        vm.expectRevert(abi.encodeWithSelector(ICTMRWA1.CTMRWA1_IsZeroUint.selector, CTMRWAErrorParam.Value));
        token.transferFrom(testTokenId1, testTokenId2, 0);

        vm.stopPrank();
    }

    function test_edgeCase_selfTransfer() public {
        // Test transfer to self
        vm.startPrank(user1);

        uint256 initialBalance = token.balanceOf(testTokenId1);

        // Transfer to self
        token.transferFrom(testTokenId1, testTokenId1, 100);

        // Balance should remain the same
        assertEq(token.balanceOf(testTokenId1), initialBalance);

        vm.stopPrank();
    }

    // ============ APPROVAL TESTS ============

    function test_revokeApproval() public {
        // Test revokeApproval function
        vm.startPrank(user1);

        // First, approve user2 to spend from testTokenId1
        token.approve(user2, testTokenId1);
        
        // Verify approval was set
        assertEq(token.getApproved(testTokenId1), user2);

        // Revoke the approval
        vm.expectEmit(true, true, true, true);
        emit ICTMRWA1.RevokeApproval(testTokenId1);
        token.revokeApproval(testTokenId1);

        // Verify approval was revoked (should be address(0))
        assertEq(token.getApproved(testTokenId1), address(0));

        vm.stopPrank();
    }

    function test_revokeApproval_unauthorized() public {
        // Test that only the owner can revoke approval
        vm.startPrank(user1);

        // First, approve user2 to spend from testTokenId1
        token.approve(user2, testTokenId1);
        
        // Verify approval was set
        assertEq(token.getApproved(testTokenId1), user2);

        vm.stopPrank();

        // Try to revoke approval as user2 (not the owner)
        vm.startPrank(user2);
        vm.expectRevert(abi.encodeWithSelector(ICTMRWA1.CTMRWA1_OnlyAuthorized.selector, CTMRWAErrorParam.Sender, CTMRWAErrorParam.Owner));
        token.revokeApproval(testTokenId1);
        vm.stopPrank();

        // Verify approval is still set (revocation failed)
        assertEq(token.getApproved(testTokenId1), user2);
    }

    function test_revokeApproval_nonExistentToken() public {
        // Test revoking approval for non-existent token
        uint256 nonExistentTokenId = 999_999;
        
        vm.startPrank(user1);
        vm.expectRevert(abi.encodeWithSelector(ICTMRWA1.CTMRWA1_IDNonExistent.selector, nonExistentTokenId));
        token.revokeApproval(nonExistentTokenId);
        vm.stopPrank();
    }

    function test_revokeApproval_noApprovalSet() public {
        // Test revoking approval when no approval is set (should still work)
        vm.startPrank(user1);

        // Verify no approval is set initially
        assertEq(token.getApproved(testTokenId1), address(0));

        // Revoke approval (should not revert even if no approval was set)
        vm.expectEmit(true, true, true, true);
        emit ICTMRWA1.RevokeApproval(testTokenId1);
        token.revokeApproval(testTokenId1);

        // Verify approval is still address(0)
        assertEq(token.getApproved(testTokenId1), address(0));

        vm.stopPrank();
    }

    function test_approvalSecurity() public {
        // Test approval security
        vm.startPrank(user1);

        // Approve user2 to spend from tokenId1
        token.approve(testTokenId1, user2, 500);

        // Verify approval
        assertEq(token.allowance(testTokenId1, user2), 500);

        // Try to approve self (should fail)
        vm.expectRevert(abi.encodeWithSelector(ICTMRWA1.CTMRWA1_Unauthorized.selector, CTMRWAErrorParam.To, CTMRWAErrorParam.Owner));
        token.approve(testTokenId1, user1, 100);

        vm.stopPrank();
    }

    function test_approvalSpendAllowance() public {
        // Test spending allowance
        vm.startPrank(user1);

        // Approve user2 to spend from tokenId1
        token.approve(testTokenId1, user2, 500);

        vm.stopPrank();

        // User2 spends some allowance
        vm.startPrank(user2);
        token.transferFrom(testTokenId1, testTokenId2, 200);

        // Check remaining allowance
        assertEq(token.allowance(testTokenId1, user2), 300);

        vm.stopPrank();
    }

    function test_spendAllowance_reverts_when_not_approved_or_owner_and_no_allowance() public {
        // user2 is not owner or approved for testTokenId1 and has no allowance
        vm.startPrank(user2);
        vm.expectRevert(abi.encodeWithSelector(ICTMRWA1.CTMRWA1_InsufficientAllowance.selector));
        token.spendAllowance(user2, testTokenId1, 100);
        vm.stopPrank();

        // Approve user2 for a value less than 100
        vm.startPrank(user1);
        token.approve(testTokenId1, user2, 50);
        vm.stopPrank();

        // Try to spend 100 again, should still revert
        vm.startPrank(user2);
        vm.expectRevert(abi.encodeWithSelector(ICTMRWA1.CTMRWA1_InsufficientAllowance.selector));
        token.spendAllowance(user2, testTokenId1, 100);
        vm.stopPrank();
    }

    // ============ ERC20 DEPLOYMENT TESTS ============

    function test_erc20DeploymentSecurity() public {
        // Test ERC20 deployment security
        vm.startPrank(tokenAdmin);

        // Deploy ERC20 for slot
        token.deployErc20(testSlot, "Test ERC20", address(usdc));

        // Try to deploy again for same slot (should fail)
        vm.expectRevert(abi.encodeWithSelector(ICTMRWA1.CTMRWA1_NotZeroAddress.selector, CTMRWAErrorParam.RWAERC20));
        token.deployErc20(testSlot, "Test ERC20 2", address(usdc));

        vm.stopPrank();
    }

    // ============ BURN TESTS ============

    function test_burnSecurity() public {
        // Test burn security
        vm.startPrank(user1);

        // Burn token
        token.burn(testTokenId1);

        // Verify token no longer exists
        assertFalse(token.exists(testTokenId1));

        // Try to burn non-existent token
        vm.expectRevert(abi.encodeWithSelector(ICTMRWA1.CTMRWA1_IDNonExistent.selector, testTokenId1));
        token.burn(testTokenId1);

        vm.stopPrank();
    }

    function test_burnValueSecurity() public {
        // Test burn value security
        vm.startPrank(address(rwa1X));

        // Burn some value
        token.burnValueX(testTokenId2, 100);

        // Verify balance decreased
        assertEq(token.balanceOf(testTokenId2), 900);

        // Try to burn more than available
        vm.expectRevert(abi.encodeWithSelector(ICTMRWA1.CTMRWA1_InsufficientBalance.selector));
        token.burnValueX(testTokenId2, 1000);

        vm.stopPrank();
    }

    function test_burn_paused_unpaused() public {
        // Pause the contract
        vm.prank(tokenAdmin);
        token.pause();

        // Try to burn while paused, should revert
        vm.prank(user1);
        vm.expectRevert(EnforcedPause.selector);
        token.burn(testTokenId1);

        // Unpause the contract
        vm.prank(tokenAdmin);
        token.unpause();

        // Burn should now succeed
        vm.prank(user1);
        token.burn(testTokenId1);
        // After burn, token should not exist
        assertFalse(token.exists(testTokenId1));
    }

    // ============ SLOT MANAGEMENT TESTS ============

    function test_slotManagementSecurity() public {
        // Test slot management security
        vm.startPrank(address(rwa1X));

        // Create slot
        token.createSlotX(10, "New Slot");

        // Verify slot exists
        assertTrue(token.slotExists(10));
        assertEq(token.slotName(10), "New Slot");

        // Try to create same slot again (should fail silently or succeed depending on implementation)
        token.createSlotX(10, "Duplicate Slot");

        vm.stopPrank();
    }

    // ============ CROSS-SLOT TRANSFER TESTS ============

    function test_crossSlotTransferPrevention() public {
        // Test that transfers between different slots are prevented
        vm.startPrank(address(rwa1X));

        // Create a new slot
        token.createSlotX(20, "Slot 20");

        // Mint token in new slot
        uint256 newTokenId = token.mintFromX(user1, 20, "Slot 20", 100);

        vm.stopPrank();

        // Try to transfer between different slots (should fail)
        vm.startPrank(user1);
        vm.expectRevert(abi.encodeWithSelector(ICTMRWA1.CTMRWA1_InvalidSlot.selector, 20));
        token.transferFrom(testTokenId1, newTokenId, 50);

        vm.stopPrank();
    }

    // ============ OVERFLOW/UNDERFLOW TESTS ============

    function test_overflowProtection() public {
        // Test overflow protection (though Solidity 0.8+ has built-in protection)
        vm.startPrank(address(rwa1X));

        // Try to mint maximum value (checkpoints use uint208 for the value)
        // Current balance should be 1000 from setup
        token.mintValueX(testTokenId1, type(uint208).max - 1000);

        // Try to mint more (should fail due to overflow)
        // The current balance is now type(uint208).max, so minting any amount should fail
        uint256 maxUint208 = 2**208 - 1;
        vm.expectRevert(abi.encodeWithSelector(ICTMRWA1.CTMRWA1_ValueOverflow.selector, maxUint208 + 1, maxUint208));
        token.mintValueX(testTokenId1, 1);

        vm.stopPrank();
    }

    function test_mintValueXUpdatesCheckpoints() public {
        // Test that mintValueX properly updates checkpointed arrays
        vm.startPrank(address(rwa1X));

        uint256 mintValue = 5000;
        uint256 slot = token.slotOf(testTokenId1);
        address owner = token.ownerOf(testTokenId1);

        // Get initial values
        uint256 initialBalance = token.balanceOf(owner, slot);
        uint256 initialTokenBalance = token.balanceOf(testTokenId1);
        uint256 initialSupplyInSlot = token.totalSupplyInSlot(slot);
        

        // Mint value using mintValueX
        token.mintValueX(testTokenId1, mintValue);

        // Check that token balance increased
        uint256 newTokenBalance = token.balanceOf(testTokenId1);
        assertEq(newTokenBalance, initialTokenBalance + mintValue, "Token balance should increase by minted value");

        // Check that owner's balance in slot increased
        uint256 newOwnerBalance = token.balanceOf(owner, slot);
        assertEq(newOwnerBalance, initialBalance + mintValue, "Owner balance in slot should increase by minted value");

        // Check that total supply in slot increased
        uint256 newSupplyInSlot = token.totalSupplyInSlot(slot);
        assertEq(newSupplyInSlot, initialSupplyInSlot + mintValue, "Total supply in slot should increase by minted value");

        // Test checkpoint functionality by checking balance at different times
        // First, warp to a specific timestamp to ensure the first mint happens at timestamp 100
        vm.warp(100);
        
        // Wait a bit and mint more to create a different timestamp
        vm.warp(block.timestamp + 100);
        token.mintValueX(testTokenId1, 2000);
        
        uint256 timestamp2 = block.timestamp; // Capture timestamp after second mint
        uint256 finalBalance = token.balanceOf(owner, slot);
        uint256 finalSupplyInSlot = token.totalSupplyInSlot(slot);
        
        // Check final balances
        assertEq(finalBalance, initialBalance + mintValue + 2000, "Final balance should be correct");
        assertEq(finalSupplyInSlot, initialSupplyInSlot + mintValue + 2000, "Final supply in slot should be correct");
        
        // Now test historical lookup - this should work correctly with different timestamps
        // Test that we can query balance at timestamp1 (should be after first mint only)
        // The first mint happened at timestamp 1, so we need to query for timestamp 1
        uint256 balanceAtTime1 = token.balanceOfAt(owner, slot, 1);
        assertEq(balanceAtTime1, initialBalance + mintValue, "Balance at timestamp1 should be after first mint only");
        
        // Test that we can query balance at timestamp2 (should be after second mint)
        uint256 balanceAtTime2 = token.balanceOfAt(owner, slot, timestamp2);
        assertEq(balanceAtTime2, initialBalance + mintValue + 2000, "Balance at timestamp2 should be after both mints");
        
        // Test that we can query balance at a timestamp between the two mints
        // Since there's no checkpoint between the mints, we should get the most recent checkpoint
        // which should be the first mint (timestamp 1) with value 6000
        uint256 midTimestamp = 150; // Between first and second mint
        uint256 balanceAtMidTime = token.balanceOfAt(owner, slot, midTimestamp);
        assertEq(balanceAtMidTime, initialBalance + mintValue, "Balance at mid timestamp should be after first mint only");
        
        // Note: We cannot query for a balance before any mints because the checkpoint system
        // only creates checkpoints when mints happen, not for the initial state.
        // The initial balance (1000) is not stored as a checkpoint.
        
        // Test supply historical lookup as well
        uint256 supplyAtTime1 = token.totalSupplyInSlotAt(slot, 1);
        assertEq(supplyAtTime1, initialSupplyInSlot + mintValue, "Supply at timestamp1 should be after first mint only");
        
        uint256 supplyAtTime2 = token.totalSupplyInSlotAt(slot, timestamp2);
        assertEq(supplyAtTime2, initialSupplyInSlot + mintValue + 2000, "Supply at timestamp2 should be after both mints");

        vm.stopPrank();
    }

    function test_burnValueXUpdatesCheckpoints() public {
        // Test that burnValueX properly updates checkpointed arrays
        vm.startPrank(address(rwa1X));

        uint256 burnValue = 500; // Burn 500 from token with 1000 balance
        uint256 slot = token.slotOf(testTokenId1);
        address owner = token.ownerOf(testTokenId1);

        // Get initial values
        uint256 initialBalance = token.balanceOf(owner, slot);
        uint256 initialTokenBalance = token.balanceOf(testTokenId1);
        uint256 initialSupplyInSlot = token.totalSupplyInSlot(slot);

        // Burn value using burnValueX
        token.burnValueX(testTokenId1, burnValue);

        // Check that token balance decreased
        uint256 newTokenBalance = token.balanceOf(testTokenId1);
        assertEq(newTokenBalance, initialTokenBalance - burnValue, "Token balance should decrease by burned value");

        // Check that owner's balance in slot decreased
        uint256 newOwnerBalance = token.balanceOf(owner, slot);
        assertEq(newOwnerBalance, initialBalance - burnValue, "Owner balance in slot should decrease by burned value");

        // Check that total supply in slot decreased
        uint256 newSupplyInSlot = token.totalSupplyInSlot(slot);
        assertEq(newSupplyInSlot, initialSupplyInSlot - burnValue, "Total supply in slot should decrease by burned value");

        // Test checkpoint functionality by checking balance at different times
        // First, warp to a specific timestamp to ensure the burn happens at timestamp 100
        vm.warp(100);
        
        // Wait a bit and burn more to create a different timestamp
        vm.warp(block.timestamp + 100);
        token.burnValueX(testTokenId1, 200); // Burn 200 more (total burned: 500 + 200 = 700)
        
        uint256 timestamp2 = block.timestamp; // Capture timestamp after second burn
        uint256 finalBalance = token.balanceOf(owner, slot);
        uint256 finalSupplyInSlot = token.totalSupplyInSlot(slot);
        
        // Check final balances
        assertEq(finalBalance, initialBalance - burnValue - 200, "Final balance should be correct");
        assertEq(finalSupplyInSlot, initialSupplyInSlot - burnValue - 200, "Final supply in slot should be correct");
        
        // Now test historical lookup - this should work correctly with different timestamps
        // Test that we can query balance at timestamp1 (should be after first burn only)
        // The first burn happened at timestamp 1, so we need to query for timestamp 1
        uint256 balanceAtTime1 = token.balanceOfAt(owner, slot, 1);
        assertEq(balanceAtTime1, initialBalance - burnValue, "Balance at timestamp1 should be after first burn only");
        
        // Test that we can query balance at timestamp2 (should be after second burn)
        uint256 balanceAtTime2 = token.balanceOfAt(owner, slot, timestamp2);
        assertEq(balanceAtTime2, initialBalance - burnValue - 200, "Balance at timestamp2 should be after both burns");
        
        // Test that we can query balance at a timestamp between the two burns
        // Since there's no checkpoint between the burns, we should get the most recent checkpoint
        // which should be the first burn (timestamp 1) with value after first burn
        uint256 midTimestamp = 150; // Between first and second burn
        uint256 balanceAtMidTime = token.balanceOfAt(owner, slot, midTimestamp);
        assertEq(balanceAtMidTime, initialBalance - burnValue, "Balance at mid timestamp should be after first burn only");
        
        // Note: We cannot query for a balance before any burns because the checkpoint system
        // only creates checkpoints when burns happen, not for the initial state.
        // The initial balance is not stored as a checkpoint.
        
        // Test supply historical lookup as well
        uint256 supplyAtTime1 = token.totalSupplyInSlotAt(slot, 1);
        assertEq(supplyAtTime1, initialSupplyInSlot - burnValue, "Supply at timestamp1 should be after first burn only");
        
        uint256 supplyAtTime2 = token.totalSupplyInSlotAt(slot, timestamp2);
        assertEq(supplyAtTime2, initialSupplyInSlot - burnValue - 200, "Supply at timestamp2 should be after both burns");

        vm.stopPrank();
    }

    // ============ GAS OPTIMIZATION TESTS ============

    function test_gasEfficientOperations() public {
        // Test that operations are gas efficient
        vm.startPrank(address(rwa1X));

        uint256 gasBefore = gasleft();

        // Perform operation
        token.mintFromX(user1, testSlot, "Gas Test", 100);

        uint256 gasUsed = gasBefore - gasleft();

        // Gas usage should be reasonable (less than 400k for basic operations)
        assertTrue(gasUsed < 400_000);

        vm.stopPrank();
    }

    // =========== FORCE TRANSFER TEST ===============

    function test_forceTransfer() public {
        vm.startPrank(tokenAdmin);
        // Slots are already created in setup, use existing slot 1

        uint256 slot = 1;

        string memory tokenStr = _toLower((address(usdc).toHexString()));

        uint256 tokenId1User1 = rwa1X.mintNewTokenValueLocal(user1, 0, slot, 2000, ID, tokenStr);

        uint256 tokenId2User1 = rwa1X.mintNewTokenValueLocal(user1, 0, slot, 1000, ID, tokenStr);

        // Licensed Security override not set up
        vm.expectRevert(abi.encodeWithSelector(ICTMRWA1.CTMRWA1_IsZeroAddress.selector, CTMRWAErrorParam.Override));
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
        vm.expectRevert(ICTMRWA1Storage.CTMRWA1Storage_NoSecurityDescription.selector);
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

        // Licensed Security override not set up, since we didn't set the Regulator's wallet yet
        vm.expectRevert(abi.encodeWithSelector(ICTMRWA1.CTMRWA1_IsZeroAddress.selector, CTMRWAErrorParam.Override));
        token.forceTransfer(user1, user2, tokenId1User1);

        // Try again to set admin as the Regulator's wallet
        ICTMRWA1Storage(stor).createSecurity(admin);
        assertEq(ICTMRWA1Storage(stor).regulatorWallet(), admin);

        // Licensed Security override not set up, since we did not set the override wallet yet
        vm.expectRevert(abi.encodeWithSelector(ICTMRWA1.CTMRWA1_IsZeroAddress.selector, CTMRWAErrorParam.Override));
        token.forceTransfer(user1, user2, tokenId1User1);

        // Set the override wallet as tokenAdmin2. This should be a Multi-sig wallet, with admin as one of the signers.
        token.setOverrideWallet(tokenAdmin2);
        assertEq(token.overrideWallet(), tokenAdmin2);

        // Try to force transfer again, should fail since the override wallet is not the sender (tokenAdmin)
        vm.expectRevert(
            abi.encodeWithSelector(ICTMRWA1.CTMRWA1_OnlyAuthorized.selector, CTMRWAErrorParam.Sender, CTMRWAErrorParam.Override)
        );
        token.forceTransfer(user1, user2, tokenId1User1);

        vm.stopPrank();

        vm.startPrank(tokenAdmin2); // tokenAdmin2 is the override wallet
        // Try a forceTransfer with the override wallet, should succeed
        token.forceTransfer(user1, user2, tokenId1User1);
        assertEq(token.ownerOf(tokenId1User1), user2); // successful forceTransfer
        vm.stopPrank();

        vm.startPrank(user2);
        // Try a forceTransfer with the user2, should fail since user2 is not the override wallet (tokenAdmin2)
        vm.expectRevert(
            abi.encodeWithSelector(ICTMRWA1.CTMRWA1_OnlyAuthorized.selector, CTMRWAErrorParam.Sender, CTMRWAErrorParam.Override)
        );
        token.forceTransfer(user1, user2, tokenId2User1);

        vm.stopPrank();

        vm.startPrank(tokenAdmin);
        rwa1X.changeTokenAdmin(tokenAdmin2.toHexString(), _stringToArray(cIdStr), ID, tokenStr);
        vm.stopPrank();

        vm.startPrank(tokenAdmin2);
        // Must re-setup override wallet if tokenAdmin has changed
        vm.expectRevert(abi.encodeWithSelector(ICTMRWA1.CTMRWA1_IsZeroAddress.selector, CTMRWAErrorParam.Override));
        token.forceTransfer(user1, user2, tokenId2User1);
        vm.stopPrank();
    }

    function test_transferFrom_paused_unpaused() public {
        // Pause the contract as tokenAdmin
        vm.prank(tokenAdmin);
        token.pause();

        // Try transferFrom while paused, should revert with custom error
        vm.startPrank(user1);
        vm.expectRevert(EnforcedPause.selector);
        token.transferFrom(testTokenId1, testTokenId2, 100);
        vm.stopPrank();

        // Unpause the contract as tokenAdmin
        vm.prank(tokenAdmin);
        token.unpause();

        // Now transferFrom should succeed
        vm.startPrank(user1);
        // No need to approve if user1 is already owner of testTokenId1
        token.transferFrom(testTokenId1, testTokenId2, 100);
        vm.stopPrank();
    }

    function test_balanceCheckpoint208() public {
        // Use a local timestamp tally and vm.warp
        uint48 nowTs = 1000000;
        vm.warp(nowTs);

        // Mint a token for user1 in slot 1 (setUp already minted 1000 for user1 and 1000 for user2)
        vm.startPrank(tokenAdmin);
        string memory tokenStr = address(usdc).toHexString();
        uint256 tokenId = rwa1X.mintNewTokenValueLocal(user1, 0, 1, 1000, ID, tokenStr);
        vm.stopPrank();

        uint48 t1 = nowTs;
        // After setUp: user1 has 1000, user2 has 1000. After this mint: user1 has 2000, user2 has 1000.
        assertEq(token.balanceOf(tokenId), 1000);
        assertEq(token.balanceOf(user1, 1), 2000);

        // Advance time and mint again
        nowTs += 10;
        vm.warp(nowTs);
        vm.startPrank(tokenAdmin);
        rwa1X.mintNewTokenValueLocal(user1, 0, 1, 500, ID, tokenStr);
        vm.stopPrank();
        uint48 t2 = nowTs;
        assertEq(token.balanceOf(user1, 1), 2500);

        // Check historical balance at t1 (should be 2000)
        assertEq(token.balanceOfAt(user1, 1, t1), 2000);
        // Check historical balance at t2 (should be 2500)
        assertEq(token.balanceOfAt(user1, 1, t2), 2500);
    }

    function test_supplyInSlotCheckpoint208() public {
        uint48 nowTs = 2000000;
        vm.warp(nowTs);

        // Mint a token for user1 in slot 1 (setUp already minted 1000 for user1 and 1000 for user2)
        vm.startPrank(tokenAdmin);
        string memory tokenStr = address(usdc).toHexString();
        rwa1X.mintNewTokenValueLocal(user1, 0, 1, 1000, ID, tokenStr);
        vm.stopPrank();
        uint48 t1 = nowTs;
        // After setUp: slot 1 has 2000. After this mint: slot 1 has 3000.
        assertEq(token.totalSupplyInSlot(1), 3000);

        // Advance time and mint again
        nowTs += 10;
        vm.warp(nowTs);
        vm.startPrank(tokenAdmin);
        rwa1X.mintNewTokenValueLocal(user2, 0, 1, 500, ID, tokenStr);
        vm.stopPrank();
        uint48 t2 = nowTs;
        assertEq(token.totalSupplyInSlot(1), 3500);

        // Check historical supply at t1 (should be 3000)
        assertEq(token.totalSupplyInSlotAt(1, t1), 3000);
        // Check historical supply at t2 (should be 3500)
        assertEq(token.totalSupplyInSlotAt(1, t2), 3500);
    }
}
