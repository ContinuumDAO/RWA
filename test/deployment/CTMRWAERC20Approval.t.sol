// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.27;

import { console } from "forge-std/console.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { IERC20Errors } from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";

import { Helpers } from "../helpers/Helpers.sol";
import { ICTMRWA1 } from "../../src/core/ICTMRWA1.sol";
import { ICTMRWAERC20 } from "../../src/deployment/ICTMRWAERC20.sol";
import { ICTMRWAERC20Deployer } from "../../src/deployment/ICTMRWAERC20Deployer.sol";
import { FeeType } from "../../src/managers/IFeeManager.sol";
import { CTMRWAErrorParam } from "../../src/utils/CTMRWAUtils.sol";

contract TestERC20Approval is Helpers {
    using Strings for *;

    uint256 testSlot = 1;
    address testErc20;
    uint256[] testTokenIds;

    function setUp() public override {
        super.setUp();
        
        // Set up fee multipliers for operations that will be tested
        vm.startPrank(gov);
        feeManager.setFeeMultiplier(FeeType.MINT, 5);
        feeManager.setFeeMultiplier(FeeType.ERC20, 50);
        vm.stopPrank();
        
        // Deploy CTMRWA1 and create slots
        vm.startPrank(tokenAdmin);
        (ID, token) = _deployCTMRWA1(address(usdc));
        _createSomeSlots(ID, address(usdc), address(rwa1X));
        
        // Deploy ERC20 for the test slot
        usdc.approve(address(ctmRwaErc20Deployer), 100_000_000);
        testErc20 = ctmRwaErc20Deployer.deployERC20(ID, 1, 1, testSlot, "Test ERC20", address(usdc));
        
        // Mint some test tokens
        string memory feeTokenStr = _toLower((address(usdc).toHexString()));
        rwa1X.mintNewTokenValueLocal(user1, 0, testSlot, 1000, ID, VERSION, feeTokenStr);
        rwa1X.mintNewTokenValueLocal(user1, 0, testSlot, 2000, ID, VERSION, feeTokenStr);
        rwa1X.mintNewTokenValueLocal(user1, 0, testSlot, 3000, ID, VERSION, feeTokenStr);
        
        // Get the tokenIds that were minted
        uint256 balance = ICTMRWA1(address(token)).balanceOf(user1);
        for (uint256 i = 0; i < balance; i++) {
            uint256 tokenId = ICTMRWA1(address(token)).tokenOfOwnerByIndex(user1, i);
            if (ICTMRWA1(address(token)).slotOf(tokenId) == testSlot) {
                testTokenIds.push(tokenId);
            }
        }
        
        vm.stopPrank();
    }

    // ============ ERC20 APPROVAL TESTS ============

    function test_approveErc20_success() public {
        vm.startPrank(user1);
        
        // Approve the first tokenId for ERC20 spending
        uint256 tokenId = testTokenIds[0];
        token.approveErc20(tokenId);
        
        // Verify the approval
        assertEq(token.getApproved(tokenId), testErc20);
        
        // Verify the tokenId is in the approvals array
        uint256[] memory approvals = token.getErc20Approvals(user1, testSlot);
        assertEq(approvals.length, 1);
        assertEq(approvals[0], tokenId);
        
        vm.stopPrank();
    }

    function test_approveErc20_reverts_whenNotOwner() public {
        vm.startPrank(user2);
        
        uint256 tokenId = testTokenIds[0];
        vm.expectRevert(abi.encodeWithSelector(ICTMRWA1.CTMRWA1_OnlyAuthorized.selector, CTMRWAErrorParam.Sender, CTMRWAErrorParam.Owner));
        token.approveErc20(tokenId);
        
        vm.stopPrank();
    }

    function test_approveErc20_reverts_whenTokenNonExistent() public {
        vm.startPrank(user1);
        
        uint256 nonExistentTokenId = 999999;
        vm.expectRevert(abi.encodeWithSelector(ICTMRWA1.CTMRWA1_IDNonExistent.selector, nonExistentTokenId));
        token.approveErc20(nonExistentTokenId);
        
        vm.stopPrank();
    }

    function test_approveErc20_reverts_whenERC20NonExistent() public {
        // Create a tokenId in a slot without an ERC20 using tokenAdmin
        vm.startPrank(tokenAdmin);
        string memory feeTokenStr = _toLower((address(usdc).toHexString()));
        rwa1X.mintNewTokenValueLocal(user1, 0, 3, 1000, ID, VERSION, feeTokenStr);
        vm.stopPrank();
        
        // Get the newly created tokenId
        uint256 balance = ICTMRWA1(address(token)).balanceOf(user1);
        uint256 tokenId = ICTMRWA1(address(token)).tokenOfOwnerByIndex(user1, balance - 1);
        
        // Now test that approveErc20 reverts for a slot without an ERC20
        vm.startPrank(user1);
        vm.expectRevert(abi.encodeWithSelector(ICTMRWA1.CTMRWA1_ERC20NonExistent.selector, 3));
        token.approveErc20(tokenId);
        vm.stopPrank();
    }

    function test_approveErc20_reverts_whenAlreadyApproved() public {
        vm.startPrank(user1);
        
        uint256 tokenId = testTokenIds[0];
        token.approveErc20(tokenId);
        
        // Try to approve again
        vm.expectRevert(abi.encodeWithSelector(ICTMRWA1.CTMRWA1_ERC20AlreadyApproved.selector, tokenId));
        token.approveErc20(tokenId);
        
        vm.stopPrank();
    }

    function test_revokeApproval_success() public {
        vm.startPrank(user1);
        
        uint256 tokenId = testTokenIds[0];
        token.approveErc20(tokenId);
        
        // Verify approval exists
        assertEq(token.getApproved(tokenId), testErc20);
        uint256[] memory approvals = token.getErc20Approvals(user1, testSlot);
        assertEq(approvals.length, 1);
        
        // Revoke approval
        token.revokeApproval(tokenId);
        
        // Verify approval is revoked
        assertEq(token.getApproved(tokenId), address(0));
        approvals = token.getErc20Approvals(user1, testSlot);
        assertEq(approvals.length, 0);
        
        vm.stopPrank();
    }

    function test_revokeApproval_reverts_whenNotOwner() public {
        vm.startPrank(user1);
        uint256 tokenId = testTokenIds[0];
        token.approveErc20(tokenId);
        vm.stopPrank();
        
        vm.startPrank(user2);
        vm.expectRevert(abi.encodeWithSelector(ICTMRWA1.CTMRWA1_OnlyAuthorized.selector, CTMRWAErrorParam.Sender, CTMRWAErrorParam.Owner));
        token.revokeApproval(tokenId);
        vm.stopPrank();
    }

    // ============ ERC20 TRANSFER TESTS ============

    function test_erc20Transfer_success_withApprovedTokenIds() public {
        vm.startPrank(user1);
        
        // Approve all tokenIds for ERC20 spending
        for (uint256 i = 0; i < testTokenIds.length; i++) {
            token.approveErc20(testTokenIds[i]);
        }
        vm.stopPrank();
        
        // Verify ERC20 balance reflects approved tokenIds
        uint256 erc20Balance = ICTMRWAERC20(testErc20).balanceOf(user1);
        assertEq(erc20Balance, 6000); // 1000 + 2000 + 3000
        
        // Transfer via ERC20
        vm.startPrank(user1);
        ICTMRWAERC20(testErc20).transfer(user2, 1500);
        vm.stopPrank();
        
        // Verify balances
        assertEq(ICTMRWAERC20(testErc20).balanceOf(user1), 4500);
        assertEq(ICTMRWAERC20(testErc20).balanceOf(user2), 1500);
        
        // Verify total supply
        assertEq(ICTMRWAERC20(testErc20).totalSupply(), 6000);
    }

    function test_erc20Transfer_reverts_whenNoApprovedTokenIds() public {
        // Don't approve any tokenIds
        
        // Try to transfer via ERC20
        vm.startPrank(user1);
        vm.expectRevert(abi.encodeWithSelector(IERC20Errors.ERC20InsufficientBalance.selector, user1, 0, 1000));
        ICTMRWAERC20(testErc20).transfer(user2, 1000);
        vm.stopPrank();
    }

    function test_erc20Transfer_reverts_whenInsufficientApprovedBalance() public {
        vm.startPrank(user1);
        
        // Only approve one tokenId (1000 balance)
        token.approveErc20(testTokenIds[0]);
        vm.stopPrank();
        
        // Try to transfer more than approved balance
        vm.startPrank(user1);
        vm.expectRevert(abi.encodeWithSelector(IERC20Errors.ERC20InsufficientBalance.selector, user1, 1000, 1500));
        ICTMRWAERC20(testErc20).transfer(user2, 1500);
        vm.stopPrank();
    }

    function test_erc20Transfer_partialApproval() public {
        vm.startPrank(user1);
        
        // Only approve first two tokenIds (1000 + 2000 = 3000 total)
        token.approveErc20(testTokenIds[0]);
        token.approveErc20(testTokenIds[1]);
        vm.stopPrank();
        
        // Verify ERC20 balance reflects only approved tokenIds
        uint256 erc20Balance = ICTMRWAERC20(testErc20).balanceOfApproved(user1);
        assertEq(erc20Balance, 3000);
        
        // Transfer the full approved amount
        vm.startPrank(user1);
        ICTMRWAERC20(testErc20).transfer(user2, 3000);
        vm.stopPrank();
        
        // Verify balances
        assertEq(ICTMRWAERC20(testErc20).balanceOf(user1), 3000); // user1 still has tokenId 3 (3000 balance)
        assertEq(ICTMRWAERC20(testErc20).balanceOf(user2), 3000);
    }

    function test_erc20TransferFrom_success() public {
        vm.startPrank(user1);
        
        // Approve all tokenIds for ERC20 spending
        for (uint256 i = 0; i < testTokenIds.length; i++) {
            token.approveErc20(testTokenIds[i]);
        }
        
        // Approve user2 to spend ERC20 tokens
        ICTMRWAERC20(testErc20).approve(user2, 2000);
        vm.stopPrank();
        
        // user2 transfers from user1
        vm.startPrank(user2);
        ICTMRWAERC20(testErc20).transferFrom(user1, user2, 2000);
        vm.stopPrank();
        
        // Verify balances
        assertEq(ICTMRWAERC20(testErc20).balanceOf(user1), 4000);
        assertEq(ICTMRWAERC20(testErc20).balanceOf(user2), 2000);
    }

    function test_erc20TransferFrom_reverts_whenNoApprovedTokenIds() public {
        vm.startPrank(user1);
        
        // Don't approve any tokenIds for ERC20 spending
        // But approve user2 to spend ERC20 tokens
        ICTMRWAERC20(testErc20).approve(user2, 2000);
        vm.stopPrank();
        
        // user2 tries to transfer from user1
        vm.startPrank(user2);
        vm.expectRevert(abi.encodeWithSelector(IERC20Errors.ERC20InsufficientBalance.selector, user1, 0, 2000));
        ICTMRWAERC20(testErc20).transferFrom(user1, user2, 2000);
        vm.stopPrank();
    }

    // ============ APPROVAL ARRAY MANAGEMENT TESTS ============

    function test_approvalArrayMaintainsIntegrity() public {
        vm.startPrank(user1);
        
        // Approve multiple tokenIds
        for (uint256 i = 0; i < testTokenIds.length; i++) {
            token.approveErc20(testTokenIds[i]);
        }
        
        // Verify all are in the array
        uint256[] memory approvals = token.getErc20Approvals(user1, testSlot);
        assertEq(approvals.length, testTokenIds.length);
        
        // Revoke the middle one
        token.revokeApproval(testTokenIds[1]);
        
        // Verify array integrity (should have 2 remaining, no gaps)
        approvals = token.getErc20Approvals(user1, testSlot);
        assertEq(approvals.length, 2);
        
        // Verify the remaining tokenIds are still approved
        assertEq(token.getApproved(testTokenIds[0]), testErc20);
        assertEq(token.getApproved(testTokenIds[1]), address(0)); // revoked
        assertEq(token.getApproved(testTokenIds[2]), testErc20);
        
        vm.stopPrank();
    }

    function test_approvalArrayHandlesRevocationCorrectly() public {
        vm.startPrank(user1);
        
        // Approve all tokenIds
        for (uint256 i = 0; i < testTokenIds.length; i++) {
            token.approveErc20(testTokenIds[i]);
        }
        
        // Revoke the last one
        token.revokeApproval(testTokenIds[2]);
        
        // Verify array and approvals
        uint256[] memory approvals = token.getErc20Approvals(user1, testSlot);
        assertEq(approvals.length, 2);
        assertEq(token.getApproved(testTokenIds[2]), address(0));
        
        // Revoke the first one
        token.revokeApproval(testTokenIds[0]);
        
        // Verify array and approvals
        approvals = token.getErc20Approvals(user1, testSlot);
        assertEq(approvals.length, 1);
        assertEq(token.getApproved(testTokenIds[0]), address(0));
        assertEq(token.getApproved(testTokenIds[1]), testErc20); // still approved
        
        vm.stopPrank();
    }

    // ============ EDGE CASE TESTS ============

    function test_erc20Transfer_withRevokedApproval() public {
        vm.startPrank(user1);
        
        // Approve all tokenIds
        for (uint256 i = 0; i < testTokenIds.length; i++) {
            token.approveErc20(testTokenIds[i]);
        }
        
        // Revoke one approval
        token.revokeApproval(testTokenIds[1]);
        vm.stopPrank();
        
        // Verify ERC20 balance reflects only remaining approved tokenIds
        uint256 erc20Balance = ICTMRWAERC20(testErc20).balanceOfApproved(user1);
        assertEq(erc20Balance, 4000); // 1000 + 3000 (2000 from revoked tokenId not counted)
        
        // Transfer should work with remaining approved balance
        vm.startPrank(user1);
        ICTMRWAERC20(testErc20).transfer(user2, 4000);
        vm.stopPrank();
        
        // Verify balances
        assertEq(ICTMRWAERC20(testErc20).balanceOf(user1), 2000); // user1 still has tokenId 1 (2000 balance)
        assertEq(ICTMRWAERC20(testErc20).balanceOf(user2), 4000);
    }

    function test_multipleUsersApprovalIsolation() public {
        // Mint tokens for user2
        vm.startPrank(tokenAdmin);
        string memory feeTokenStr = _toLower((address(usdc).toHexString()));
        rwa1X.mintNewTokenValueLocal(user2, 0, testSlot, 5000, ID, VERSION, feeTokenStr);
        vm.stopPrank();
        
        // Get user2's tokenId
        uint256 user2Balance = ICTMRWA1(address(token)).balanceOf(user2);
        uint256 user2TokenId = ICTMRWA1(address(token)).tokenOfOwnerByIndex(user2, user2Balance - 1);
        
        // user1 approves their tokenIds
        vm.startPrank(user1);
        token.approveErc20(testTokenIds[0]);
        vm.stopPrank();
        
        // user2 approves their tokenId
        vm.startPrank(user2);
        token.approveErc20(user2TokenId);
        vm.stopPrank();
        
        // Verify isolation
        uint256[] memory user1Approvals = token.getErc20Approvals(user1, testSlot);
        uint256[] memory user2Approvals = token.getErc20Approvals(user2, testSlot);
        
        assertEq(user1Approvals.length, 1);
        assertEq(user1Approvals[0], testTokenIds[0]);
        
        assertEq(user2Approvals.length, 1);
        assertEq(user2Approvals[0], user2TokenId);
        
        // Verify ERC20 balances
        assertEq(ICTMRWAERC20(testErc20).balanceOfApproved(user1), 1000);
        assertEq(ICTMRWAERC20(testErc20).balanceOfApproved(user2), 5000);
    }
}
