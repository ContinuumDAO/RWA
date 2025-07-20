// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.27;

import { console } from "forge-std/console.sol";

import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

import { Helpers } from "../helpers/Helpers.sol";

import { ICTMRWAERC20 } from "../../src/deployment/ICTMRWAERC20.sol";
import { ICTMRWAERC20Deployer } from "../../src/deployment/ICTMRWAERC20Deployer.sol";
import { ICTMRWA1, Address } from "../../src/core/ICTMRWA1.sol";
import { IERC20Errors } from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";

contract TestERC20Deployer is Helpers {
    using Strings for *;

    function test_deployErc20_revertsOnNonExistentSlot() public {
        vm.startPrank(tokenAdmin);
        (ID, token) = _deployCTMRWA1(address(usdc));
        uint256 nonExistentSlot = 42;
        string memory name = "No Slot";
        usdc.approve(address(feeManager), 100000000);
        vm.expectRevert(abi.encodeWithSelector(ICTMRWA1.CTMRWA1_InvalidSlot.selector, nonExistentSlot));
        token.deployErc20(nonExistentSlot, name, address(usdc));
        vm.stopPrank();
    }

    function test_deployErc20_deployment() public {
        vm.startPrank(tokenAdmin);
        (ID, token) = _deployCTMRWA1(address(usdc));
        _createSomeSlots(ID, address(usdc), address(rwa1X));
        uint256 slot = 1;
        string memory name = "Basic Stuff";
        usdc.approve(address(feeManager), 100000000);
        token.deployErc20(slot, name, address(usdc));
        address newErc20 = token.getErc20(slot);
        assertEq(stringsEqual(ICTMRWAERC20(newErc20).name(), "slot 1| Basic Stuff"), true);
        assertEq(stringsEqual(ICTMRWAERC20(newErc20).symbol(), "SFTX"), true);
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
        usdc.approve(address(feeManager), 100000000);
        token.deployErc20(slot, name, address(usdc));
        vm.expectRevert(abi.encodeWithSelector(ICTMRWA1.CTMRWA1_NotZeroAddress.selector, Address.RWAERC20));
        token.deployErc20(slot, name, address(usdc));
        vm.expectRevert(abi.encodeWithSelector(ICTMRWA1.CTMRWA1_InvalidSlot.selector, 99));
        token.deployErc20(99, name, address(usdc));
        vm.stopPrank();
    }

    function test_minting_and_supply() public {
        vm.startPrank(tokenAdmin);
        (ID, token) = _deployCTMRWA1(address(usdc));
        _createSomeSlots(ID, address(usdc), address(rwa1X));
        uint256 slot = 1;
        string memory name = "Basic Stuff";
        string memory feeTokenStr = _toLower((address(usdc).toHexString()));
        usdc.approve(address(feeManager), 100000000);
        token.deployErc20(slot, name, address(usdc));
        address newErc20 = token.getErc20(slot);
        rwa1X.mintNewTokenValueLocal(user1, 0, slot, 2000, ID, feeTokenStr);
        assertEq(ICTMRWAERC20(newErc20).balanceOf(user1), 2000);
        assertEq(ICTMRWAERC20(newErc20).totalSupply(), 2000);
        rwa1X.mintNewTokenValueLocal(user2, 0, slot, 3000, ID, feeTokenStr);
        assertEq(ICTMRWAERC20(newErc20).totalSupply(), 5000);
        rwa1X.mintNewTokenValueLocal(user2, 0, slot, 4000, ID, feeTokenStr);
        assertEq(ICTMRWAERC20(newErc20).balanceOf(user2), 7000);
        assertEq(ICTMRWAERC20(newErc20).totalSupply(), 9000);
        vm.stopPrank();
    }

    function test_transfer_and_approval() public {
        vm.startPrank(tokenAdmin);
        (ID, token) = _deployCTMRWA1(address(usdc));
        _createSomeSlots(ID, address(usdc), address(rwa1X));
        uint256 slot = 1;
        string memory name = "Basic Stuff";
        string memory feeTokenStr = _toLower((address(usdc).toHexString()));
        usdc.approve(address(feeManager), 100000000);
        token.deployErc20(slot, name, address(usdc));
        address newErc20 = token.getErc20(slot);
        rwa1X.mintNewTokenValueLocal(user1, 0, slot, 2000, ID, feeTokenStr);
        rwa1X.mintNewTokenValueLocal(user2, 0, slot, 3000, ID, feeTokenStr);
        vm.stopPrank();
        vm.startPrank(user1);
        ICTMRWAERC20(newErc20).transfer(user2, 1000);
        assertEq(ICTMRWAERC20(newErc20).balanceOf(user1), 1000);
        assertEq(ICTMRWAERC20(newErc20).balanceOf(user2), 4000);
        vm.expectRevert();
        ICTMRWAERC20(newErc20).transfer(user2, 1001);
        vm.stopPrank();
        vm.startPrank(user2);
        ICTMRWAERC20(newErc20).approve(admin, 9000);
        assertEq(ICTMRWAERC20(newErc20).allowance(user2, admin), 9000);
        vm.stopPrank();
        vm.startPrank(admin);
        ICTMRWAERC20(newErc20).transferFrom(user2, user1, 4000);
        assertEq(ICTMRWAERC20(newErc20).balanceOf(user1), 5000);
        assertEq(ICTMRWAERC20(newErc20).balanceOf(user2), 0);
        assertEq(ICTMRWAERC20(newErc20).allowance(user2, admin), 5000);
        vm.expectRevert(abi.encodeWithSelector(IERC20Errors.ERC20InsufficientAllowance.selector, admin, 5000, 5001));
        ICTMRWAERC20(newErc20).transferFrom(user2, user1, 5001);
        vm.stopPrank();
    }

    function test_zeroValueTransferRevert() public {
        vm.startPrank(tokenAdmin);
        (ID, token) = _deployCTMRWA1(address(usdc));
        _createSomeSlots(ID, address(usdc), address(rwa1X));
        uint256 slot = 1;
        string memory name = "Basic Stuff";
        string memory feeTokenStr = _toLower((address(usdc).toHexString()));
        usdc.approve(address(feeManager), 100000000);
        token.deployErc20(slot, name, address(usdc));
        address newErc20 = token.getErc20(slot);
        rwa1X.mintNewTokenValueLocal(user1, 0, slot, 2000, ID, feeTokenStr);
        rwa1X.mintNewTokenValueLocal(user2, 0, slot, 3000, ID, feeTokenStr);
        vm.stopPrank();
        vm.startPrank(user1);
        vm.expectRevert(abi.encodeWithSelector(ICTMRWA1.CTMRWA1_IsZeroUint.selector, 5));
        ICTMRWAERC20(newErc20).transferFrom(user1, user2, 0);
        vm.stopPrank();
    }

    // Fuzz test for transfer
    function testFuzz_transfer(uint256 amount) public {
        vm.assume(amount > 0 && amount < 1e18);
        vm.startPrank(tokenAdmin);
        (ID, token) = _deployCTMRWA1(address(usdc));
        _createSomeSlots(ID, address(usdc), address(rwa1X));
        uint256 slot = 1;
        string memory name = "Basic Stuff";
        string memory feeTokenStr = _toLower((address(usdc).toHexString()));
        usdc.approve(address(feeManager), 100000000);
        token.deployErc20(slot, name, address(usdc));
        address newErc20 = token.getErc20(slot);
        rwa1X.mintNewTokenValueLocal(user1, 0, slot, amount, ID, feeTokenStr);
        vm.stopPrank();
        vm.startPrank(user1);
        ICTMRWAERC20(newErc20).transfer(user2, amount);
        assertEq(ICTMRWAERC20(newErc20).balanceOf(user2), amount);
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
        usdc.approve(address(feeManager), 100000000);
        token.deployErc20(slot, name, address(usdc));
        address newErc20 = token.getErc20(slot);
        rwa1X.mintNewTokenValueLocal(user1, 0, slot, 1000, ID, feeTokenStr);
        rwa1X.mintNewTokenValueLocal(user2, 0, slot, 2000, ID, feeTokenStr);
        uint256 total = ICTMRWAERC20(newErc20).balanceOf(user1) + ICTMRWAERC20(newErc20).balanceOf(user2);
        assertEq(ICTMRWAERC20(newErc20).totalSupply(), total);
        vm.stopPrank();
    }

    // Edge: transfer more than balance
    function test_transferMoreThanBalanceReverts() public {
        vm.startPrank(tokenAdmin);
        (ID, token) = _deployCTMRWA1(address(usdc));
        _createSomeSlots(ID, address(usdc), address(rwa1X));
        uint256 slot = 1;
        string memory name = "Basic Stuff";
        string memory feeTokenStr = _toLower((address(usdc).toHexString()));
        usdc.approve(address(feeManager), 100000000);
        token.deployErc20(slot, name, address(usdc));
        address newErc20 = token.getErc20(slot);
        rwa1X.mintNewTokenValueLocal(user1, 0, slot, 1000, ID, feeTokenStr);
        vm.stopPrank();
        vm.startPrank(user1);
        vm.expectRevert();
        ICTMRWAERC20(newErc20).transfer(user2, 1001);
        vm.stopPrank();
    }

    // Edge: approve and transferFrom with underflow/overflow
    function test_approveAndTransferFromOverflow() public {
        vm.startPrank(tokenAdmin);
        (ID, token) = _deployCTMRWA1(address(usdc));
        _createSomeSlots(ID, address(usdc), address(rwa1X));
        uint256 slot = 1;
        string memory name = "Basic Stuff";
        string memory feeTokenStr = _toLower((address(usdc).toHexString()));
        usdc.approve(address(feeManager), 100000000);
        token.deployErc20(slot, name, address(usdc));
        address newErc20 = token.getErc20(slot);
        rwa1X.mintNewTokenValueLocal(user2, 0, slot, 1000, ID, feeTokenStr);
        vm.stopPrank();
        vm.startPrank(user2);
        ICTMRWAERC20(newErc20).approve(admin, type(uint256).max);
        vm.stopPrank();
        vm.startPrank(admin);
        vm.expectRevert();
        ICTMRWAERC20(newErc20).transferFrom(user2, user1, type(uint256).max);
        vm.stopPrank();
    }
}
