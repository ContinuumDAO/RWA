// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.27;

import { console } from "forge-std/console.sol";

import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

import { Helpers } from "../helpers/Helpers.sol";

import { ICTMRWA1 } from "../../src/core/ICTMRWA1.sol";
import { ICTMRWAERC20 } from "../../src/deployment/ICTMRWAERC20.sol";
import { ICTMRWAERC20Deployer } from "../../src/deployment/ICTMRWAERC20Deployer.sol";
import { ICTMRWADeployer } from "../../src/deployment/ICTMRWADeployer.sol";
import { IERC20Errors } from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";
import { FeeType } from "../../src/managers/IFeeManager.sol";
import { CTMRWAErrorParam } from "../../src/utils/CTMRWAUtils.sol";

error EnforcedPause();

contract TestERC20Deployer is Helpers {
    using Strings for *;


    function test_deployErc20_revertsOnNonExistentSlot() public {
        vm.startPrank(tokenAdmin);
        (ID, token) = _deployCTMRWA1(address(usdc));
        uint256 nonExistentSlot = 42;
        string memory name = "No Slot";
        usdc.approve(address(deployer), 100_000_000);
        vm.expectRevert(abi.encodeWithSelector(ICTMRWADeployer.CTMRWADeployer_InvalidContract.selector, CTMRWAErrorParam.SlotName));
        deployer.deployERC20(ID, 1, 1, nonExistentSlot, name, address(usdc));
        vm.stopPrank();
    }

    function test_deployErc20_deployment() public {
        vm.startPrank(tokenAdmin);
        (ID, token) = _deployCTMRWA1(address(usdc));
        _createSomeSlots(ID, address(usdc), address(rwa1X));
        uint256 slot = 1;
        string memory name = "Basic Stuff";
        usdc.approve(address(deployer), 100_000_000);
        address newErc20 = deployer.deployERC20(ID, 1, 1, slot, name, address(usdc));
        assertEq(stringsEqual(ICTMRWAERC20(newErc20).name(), "slot 1| Basic Stuff"), true);
        assertEq(stringsEqual(ICTMRWAERC20(newErc20).symbol(), "SFTX1"), true);
        assertEq(ICTMRWAERC20(newErc20).decimals(), 18);
        assertEq(ICTMRWAERC20(newErc20).totalSupply(), 0);
        vm.stopPrank();
    }

    function test_deployErc20_reverts() public {
        vm.startPrank(tokenAdmin);
        (ID, token) = _deployCTMRWA1(address(usdc));
        _createSomeSlots(ID, address(usdc), address(rwa1X));
        uint256 slot = ICTMRWA1(address(token)).slotByIndex(0); // just use the first slot
        string memory name = "Basic Stuff";
        usdc.approve(address(deployer), 100_000_000);
        deployer.deployERC20(ID, 1, 1, slot, name, address(usdc));
        vm.expectRevert(abi.encodeWithSelector(ICTMRWADeployer.CTMRWADeployer_InvalidContract.selector, CTMRWAErrorParam.RWAERC20)); // ERC20 already exists for this slot
        deployer.deployERC20(ID, 1, 1, slot, name, address(usdc));
        vm.expectRevert(abi.encodeWithSelector(ICTMRWADeployer.CTMRWADeployer_InvalidContract.selector, CTMRWAErrorParam.SlotName));
        deployer.deployERC20(ID, 1, 1, 99, name, address(usdc));
        vm.stopPrank();
    }

    function test_minting_and_supply() public {
        vm.startPrank(tokenAdmin);
        (ID, token) = _deployCTMRWA1(address(usdc));
        _createSomeSlots(ID, address(usdc), address(rwa1X));
        uint256 slot = 1;
        string memory name = "Basic Stuff";
        string memory feeTokenStr = _toLower((address(usdc).toHexString()));
        usdc.approve(address(deployer), 100_000_000);
        address newErc20 = deployer.deployERC20(ID, 1, 1, slot, name, address(usdc));
        rwa1XUtils.mintNewTokenValueLocal(user1, 0, slot, 2000, ID, VERSION, feeTokenStr);
        assertEq(ICTMRWAERC20(newErc20).balanceOf(user1), 2000);
        assertEq(ICTMRWAERC20(newErc20).totalSupply(), 2000);
        rwa1XUtils.mintNewTokenValueLocal(user2, 0, slot, 3000, ID, VERSION, feeTokenStr);
        assertEq(ICTMRWAERC20(newErc20).totalSupply(), 5000);
        rwa1XUtils.mintNewTokenValueLocal(user2, 0, slot, 4000, ID, VERSION, feeTokenStr);
        assertEq(ICTMRWAERC20(newErc20).balanceOf(user2), 7000);
        assertEq(ICTMRWAERC20(newErc20).totalSupply(), 9000);
        vm.stopPrank();
    }




    // Invariant: total supply equals sum of all balances
    function testInvariant_totalSupplyEqualsBalances() public {
        vm.startPrank(tokenAdmin);
        (ID, token) = _deployCTMRWA1(address(usdc));
        _createSomeSlots(ID, address(usdc), address(rwa1X));
        uint256 slot = 1;
        string memory name = "Basic Stuff";
        string memory feeTokenStr = _toLower((address(usdc).toHexString()));
        usdc.approve(address(deployer), 100_000_000);
        address newErc20 = deployer.deployERC20(ID, 1, 1, slot, name, address(usdc));
        rwa1XUtils.mintNewTokenValueLocal(user1, 0, slot, 1000, ID, VERSION, feeTokenStr);
        rwa1XUtils.mintNewTokenValueLocal(user2, 0, slot, 2000, ID, VERSION, feeTokenStr);
        uint256 total = ICTMRWAERC20(newErc20).balanceOf(user1) + ICTMRWAERC20(newErc20).balanceOf(user2);
        assertEq(ICTMRWAERC20(newErc20).totalSupply(), total);
        vm.stopPrank();
    }

    // Edge: transfer more than balance





    function test_deployErc20_withFeePayment() public {
        // Set up fee for ERC20 deployment
        vm.startPrank(gov);
        feeManager.setFeeMultiplier(FeeType.ERC20, 50); // Set ERC20 fee multiplier to 50
        vm.stopPrank();

        // Deploy CTMRWA1 contract
        vm.startPrank(tokenAdmin);
        (ID, token) = _deployCTMRWA1(address(usdc));
        _createSomeSlots(ID, address(usdc), address(rwa1X));
        
        uint256 slot = 1;
        string memory name = "Fee Test ERC20";
        
        // Get initial balances
        uint256 initialBalance = usdc.balanceOf(tokenAdmin);
        uint256 initialFeeManagerBalance = usdc.balanceOf(address(feeManager));
        
        // Debug: Check what fee is actually being charged
        string memory feeTokenStr = address(usdc).toHexString();
        uint256 actualFee = feeManager.getXChainFee(
            _stringToArray(block.chainid.toString()), 
            false, 
            FeeType.ERC20, 
            feeTokenStr
        );
        
        // Use the actual fee from the FeeManager
        uint256 expectedFee = actualFee;
        
        // Approve the CTMRWAERC20Deployer to spend the fee tokens
        usdc.approve(address(ctmRwaErc20Deployer), expectedFee);
        
        // Deploy the ERC20
        deployer.deployERC20(ID, 1, 1, slot, name, address(usdc));
        
        // Verify the ERC20 was deployed
        address newErc20 = token.getErc20(slot);
        assertEq(stringsEqual(ICTMRWAERC20(newErc20).name(), "slot 1| Fee Test ERC20"), true);
        assertEq(stringsEqual(ICTMRWAERC20(newErc20).symbol(), "SFTX1"), true);
        
        // Verify the fee was paid correctly
        uint256 finalBalance = usdc.balanceOf(tokenAdmin);
        uint256 finalFeeManagerBalance = usdc.balanceOf(address(feeManager));
        
        // The tokenAdmin should have paid the fee
        assertEq(initialBalance - finalBalance, expectedFee, "TokenAdmin should have paid the correct fee");
        
        // The FeeManager should have received the fee
        assertEq(finalFeeManagerBalance - initialFeeManagerBalance, expectedFee, "FeeManager should have received the fee");
        
        vm.stopPrank();
    }

    // ========== APPROVED BALANCE TESTS ==========

    function test_approved_balance_basic() public {
        vm.startPrank(tokenAdmin);
        (ID, token) = _deployCTMRWA1(address(usdc));
        _createSomeSlots(ID, address(usdc), address(rwa1X));
        uint256 slot = 1;
        string memory name = "Approved Balance Test";
        string memory feeTokenStr = _toLower((address(usdc).toHexString()));
        usdc.approve(address(deployer), 100_000_000);
        address newErc20 = deployer.deployERC20(ID, 1, 1, slot, name, address(usdc));
        
        // Mint tokens to user1
        rwa1XUtils.mintNewTokenValueLocal(user1, 0, slot, 5000, ID, VERSION, feeTokenStr);
        
        // Initially, user1 has balance but no approved balance
        assertEq(ICTMRWAERC20(newErc20).balanceOf(user1), 5000);
        assertEq(ICTMRWAERC20(newErc20).balanceOfApproved(user1), 0);
        
        // Get the tokenId that was minted
        uint256 tokenCount = ICTMRWA1(address(token)).balanceOf(user1);
        assertEq(tokenCount, 1);
        uint256 tokenId = ICTMRWA1(address(token)).tokenOfOwnerByIndex(user1, 0);
        
        // Approve the tokenId for ERC20 spending
        vm.stopPrank();
        vm.startPrank(user1);
        ICTMRWA1(address(token)).approveErc20(tokenId);
        
        // Now user1 should have approved balance
        assertEq(ICTMRWAERC20(newErc20).balanceOfApproved(user1), 5000);
        
        vm.stopPrank();
    }

    function test_approved_balance_transferFrom() public {
        vm.startPrank(tokenAdmin);
        (ID, token) = _deployCTMRWA1(address(usdc));
        _createSomeSlots(ID, address(usdc), address(rwa1X));
        uint256 slot = 1;
        string memory name = "Approved Transfer Test";
        string memory feeTokenStr = _toLower((address(usdc).toHexString()));
        usdc.approve(address(deployer), 100_000_000);
        address newErc20 = deployer.deployERC20(ID, 1, 1, slot, name, address(usdc));
        
        // Mint tokens to user1
        rwa1XUtils.mintNewTokenValueLocal(user1, 0, slot, 5000, ID, VERSION, feeTokenStr);
        
        // Get the tokenId and approve it for ERC20
        uint256 tokenId = ICTMRWA1(address(token)).tokenOfOwnerByIndex(user1, 0);
        vm.stopPrank();
        vm.startPrank(user1);
        ICTMRWA1(address(token)).approveErc20(tokenId);
        
        // Approve user2 to spend 2000 tokens
        ICTMRWAERC20(newErc20).approve(user2, 2000);
        vm.stopPrank();
        
        // user2 transfers 2000 from user1
        vm.startPrank(user2);
        ICTMRWAERC20(newErc20).transferFrom(user1, user2, 2000);
        
        // Check balances
        assertEq(ICTMRWAERC20(newErc20).balanceOf(user1), 3000);
        assertEq(ICTMRWAERC20(newErc20).balanceOf(user2), 2000);
        assertEq(ICTMRWAERC20(newErc20).balanceOfApproved(user1), 3000);
        assertEq(ICTMRWAERC20(newErc20).balanceOfApproved(user2), 0); // user2's new token not approved yet
        
        vm.stopPrank();
    }

    function test_approved_balance_insufficient_approved() public {
        vm.startPrank(tokenAdmin);
        (ID, token) = _deployCTMRWA1(address(usdc));
        _createSomeSlots(ID, address(usdc), address(rwa1X));
        uint256 slot = 1;
        string memory name = "Insufficient Approved Test";
        string memory feeTokenStr = _toLower((address(usdc).toHexString()));
        usdc.approve(address(deployer), 100_000_000);
        address newErc20 = deployer.deployERC20(ID, 1, 1, slot, name, address(usdc));
        
        // Mint tokens to user1
        rwa1XUtils.mintNewTokenValueLocal(user1, 0, slot, 5000, ID, VERSION, feeTokenStr);
        
        // Get the tokenId but DON'T approve it for ERC20
        vm.stopPrank();
        
        // Try to transfer without approved balance - should fail with ERC20InsufficientBalance
        vm.startPrank(user1);
        vm.expectRevert(abi.encodeWithSelector(IERC20Errors.ERC20InsufficientBalance.selector, user1, 0, 1000));
        ICTMRWAERC20(newErc20).transfer(user2, 1000);
        vm.stopPrank();
    }

    function test_approved_balance_partial_transfer() public {
        vm.startPrank(tokenAdmin);
        (ID, token) = _deployCTMRWA1(address(usdc));
        _createSomeSlots(ID, address(usdc), address(rwa1X));
        uint256 slot = 1;
        string memory name = "Partial Transfer Test";
        string memory feeTokenStr = _toLower((address(usdc).toHexString()));
        usdc.approve(address(deployer), 100_000_000);
        address newErc20 = deployer.deployERC20(ID, 1, 1, slot, name, address(usdc));
        
        // Mint tokens to user1
        rwa1XUtils.mintNewTokenValueLocal(user1, 0, slot, 5000, ID, VERSION, feeTokenStr);
        
        // Get the tokenId and approve it for ERC20
        uint256 tokenId = ICTMRWA1(address(token)).tokenOfOwnerByIndex(user1, 0);
        vm.stopPrank();
        vm.startPrank(user1);
        ICTMRWA1(address(token)).approveErc20(tokenId);
        
        // Transfer partial amount
        ICTMRWAERC20(newErc20).transfer(user2, 2000);
        
        // Check balances
        assertEq(ICTMRWAERC20(newErc20).balanceOf(user1), 3000);
        assertEq(ICTMRWAERC20(newErc20).balanceOf(user2), 2000);
        assertEq(ICTMRWAERC20(newErc20).balanceOfApproved(user1), 3000);
        
        vm.stopPrank();
    }

    function test_approved_balance_multiple_tokens() public {
        vm.startPrank(tokenAdmin);
        (ID, token) = _deployCTMRWA1(address(usdc));
        _createSomeSlots(ID, address(usdc), address(rwa1X));
        uint256 slot = 1;
        string memory name = "Multiple Tokens Test";
        string memory feeTokenStr = _toLower((address(usdc).toHexString()));
        usdc.approve(address(deployer), 100_000_000);
        address newErc20 = deployer.deployERC20(ID, 1, 1, slot, name, address(usdc));
        
        // Mint multiple tokens to user1
        rwa1XUtils.mintNewTokenValueLocal(user1, 0, slot, 2000, ID, VERSION, feeTokenStr);
        rwa1XUtils.mintNewTokenValueLocal(user1, 0, slot, 3000, ID, VERSION, feeTokenStr);
        
        // Get tokenIds
        uint256 tokenId1 = ICTMRWA1(address(token)).tokenOfOwnerByIndex(user1, 0);
        uint256 tokenId2 = ICTMRWA1(address(token)).tokenOfOwnerByIndex(user1, 1);
        
        vm.stopPrank();
        vm.startPrank(user1);
        
        // Approve only the first token for ERC20
        ICTMRWA1(address(token)).approveErc20(tokenId1);
        
        // Check approved balance (should only include first token)
        assertEq(ICTMRWAERC20(newErc20).balanceOf(user1), 5000);
        assertEq(ICTMRWAERC20(newErc20).balanceOfApproved(user1), 2000);
        
        // Approve the second token as well
        ICTMRWA1(address(token)).approveErc20(tokenId2);
        
        // Now approved balance should include both tokens
        assertEq(ICTMRWAERC20(newErc20).balanceOfApproved(user1), 5000);
        
        vm.stopPrank();
    }

    function test_approved_balance_clear_approvals() public {
        vm.startPrank(tokenAdmin);
        (ID, token) = _deployCTMRWA1(address(usdc));
        _createSomeSlots(ID, address(usdc), address(rwa1X));
        uint256 slot = 1;
        string memory name = "Clear Approvals Test";
        string memory feeTokenStr = _toLower((address(usdc).toHexString()));
        usdc.approve(address(deployer), 100_000_000);
        address newErc20 = deployer.deployERC20(ID, 1, 1, slot, name, address(usdc));
        
        // Mint tokens to user1
        rwa1XUtils.mintNewTokenValueLocal(user1, 0, slot, 5000, ID, VERSION, feeTokenStr);
        
        // Get the tokenId and approve it for ERC20
        uint256 tokenId = ICTMRWA1(address(token)).tokenOfOwnerByIndex(user1, 0);
        vm.stopPrank();
        vm.startPrank(user1);
        ICTMRWA1(address(token)).approveErc20(tokenId);
        
        // Check approved balance
        assertEq(ICTMRWAERC20(newErc20).balanceOfApproved(user1), 5000);
        
        // Clear the approval
        ICTMRWA1(address(token)).revokeApproval(tokenId);
        
        // Approved balance should now be 0
        assertEq(ICTMRWAERC20(newErc20).balanceOfApproved(user1), 0);
        // But regular balance should remain
        assertEq(ICTMRWAERC20(newErc20).balanceOf(user1), 5000);
        
        vm.stopPrank();
    }

    function test_approved_balance_transfer_exceeds_approved() public {
        vm.startPrank(tokenAdmin);
        (ID, token) = _deployCTMRWA1(address(usdc));
        _createSomeSlots(ID, address(usdc), address(rwa1X));
        uint256 slot = 1;
        string memory name = "Exceeds Approved Test";
        string memory feeTokenStr = _toLower((address(usdc).toHexString()));
        usdc.approve(address(deployer), 100_000_000);
        address newErc20 = deployer.deployERC20(ID, 1, 1, slot, name, address(usdc));
        
        // Mint tokens to user1
        rwa1XUtils.mintNewTokenValueLocal(user1, 0, slot, 5000, ID, VERSION, feeTokenStr);
        
        // Get the tokenId and approve it for ERC20
        uint256 tokenId = ICTMRWA1(address(token)).tokenOfOwnerByIndex(user1, 0);
        vm.stopPrank();
        vm.startPrank(user1);
        ICTMRWA1(address(token)).approveErc20(tokenId);
        
        // Try to transfer more than approved balance - should fail with ERC20InsufficientBalance
        vm.expectRevert(abi.encodeWithSelector(IERC20Errors.ERC20InsufficientBalance.selector, user1, 5000, 6000));
        ICTMRWAERC20(newErc20).transfer(user2, 6000);
        
        vm.stopPrank();
    }
}
