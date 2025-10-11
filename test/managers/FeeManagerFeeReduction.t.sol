// SPDX-License-Identifier: BSL-1.1
pragma solidity 0.8.27;

import {Test, console} from "forge-std/Test.sol";
import {FeeManager} from "../../src/managers/FeeManager.sol";
import {IFeeManager, FeeType} from "../../src/managers/IFeeManager.sol";
import {Helpers} from "../helpers/Helpers.sol";

contract FeeManagerFeeReductionTest is Helpers {

    function testAddFeeReduction() public {
        // Test adding fee reductions for multiple addresses
        address[] memory addresses = new address[](3);
        uint256[] memory factors = new uint256[](3);
        uint256[] memory expirations = new uint256[](3);
        
        addresses[0] = user1;
        addresses[1] = user2;
        addresses[2] = tokenAdmin;
        factors[0] = 5000; // 50% reduction
        factors[1] = 2500; // 25% reduction
        factors[2] = 7500; // 75% reduction
        expirations[0] = block.timestamp + 30 days; // temporary
        expirations[1] = 0; // permanent
        expirations[2] = block.timestamp + 7 days; // temporary
        
        // Add fee reductions as governance
        vm.prank(gov);
        bool success = feeManager.addFeeReduction(addresses, factors, expirations);
        assertTrue(success);
        
        // Verify the fee reductions were set correctly
        assertEq(feeManager.feeReduction(user1), 5000);
        assertEq(feeManager.feeReduction(user2), 2500);
        assertEq(feeManager.feeReduction(tokenAdmin), 7500);
        assertEq(feeManager.feeReductionExpiration(user1), block.timestamp + 30 days);
        assertEq(feeManager.feeReductionExpiration(user2), 0);
        assertEq(feeManager.feeReductionExpiration(tokenAdmin), block.timestamp + 7 days);
        
        console.log("Fee reduction functions work correctly");
    }

    function testRemoveFeeReduction() public {
        // First add some fee reductions
        address[] memory addresses = new address[](2);
        uint256[] memory factors = new uint256[](2);
        uint256[] memory expirations = new uint256[](2);
        
        addresses[0] = user1;
        addresses[1] = user2;
        factors[0] = 5000;
        factors[1] = 2500;
        expirations[0] = block.timestamp + 30 days;
        expirations[1] = 0;
        
        vm.prank(gov);
        feeManager.addFeeReduction(addresses, factors, expirations);
        
        // Verify they were added
        assertEq(feeManager.feeReduction(user1), 5000);
        assertEq(feeManager.feeReduction(user2), 2500);
        
        // Remove fee reductions
        vm.prank(gov);
        bool success = feeManager.removeFeeReduction(addresses);
        assertTrue(success);
        
        // Verify they were removed
        assertEq(feeManager.feeReduction(user1), 0);
        assertEq(feeManager.feeReduction(user2), 0);
        assertEq(feeManager.feeReductionExpiration(user1), 0);
        assertEq(feeManager.feeReductionExpiration(user2), 0);
        
        console.log("Fee reduction removal works correctly");
    }

    function testUpdateFeeReductionExpiration() public {
        // First add some fee reductions
        address[] memory addresses = new address[](2);
        uint256[] memory factors = new uint256[](2);
        uint256[] memory expirations = new uint256[](2);
        
        addresses[0] = user1;
        addresses[1] = user2;
        factors[0] = 5000;
        factors[1] = 2500;
        expirations[0] = block.timestamp + 30 days;
        expirations[1] = block.timestamp + 7 days;
        
        vm.prank(gov);
        feeManager.addFeeReduction(addresses, factors, expirations);
        
        // Update expiration times
        uint256[] memory newExpirations = new uint256[](2);
        newExpirations[0] = block.timestamp + 60 days; // extend
        newExpirations[1] = 0; // make permanent
        
        vm.prank(gov);
        bool success = feeManager.updateFeeReductionExpiration(addresses, newExpirations);
        assertTrue(success);
        
        // Verify the updates
        assertEq(feeManager.feeReductionExpiration(user1), block.timestamp + 60 days);
        assertEq(feeManager.feeReductionExpiration(user2), 0);
        
        console.log("Fee reduction expiration update works correctly");
    }

    function testGetFeeReduction() public {
        // Add some fee reductions with different expiration times
        address[] memory addresses = new address[](3);
        uint256[] memory factors = new uint256[](3);
        uint256[] memory expirations = new uint256[](3);
        
        addresses[0] = user1;
        addresses[1] = user2;
        addresses[2] = tokenAdmin;
        factors[0] = 5000;
        factors[1] = 2500;
        factors[2] = 7500;
        expirations[0] = block.timestamp + 30 days;
        expirations[1] = 0; // permanent
        expirations[2] = 1; // expired (timestamp 1, but we'll advance time)
        
        vm.prank(gov);
        feeManager.addFeeReduction(addresses, factors, expirations);
        
        // Test before expiration
        assertEq(feeManager.getFeeReduction(user1), 5000); // active
        assertEq(feeManager.getFeeReduction(user2), 2500); // permanent
        assertEq(feeManager.getFeeReduction(tokenAdmin), 7500); // not yet expired
        
        // Advance time to make the third address expired
        vm.warp(block.timestamp + 1);
        
        // Test after expiration
        assertEq(feeManager.getFeeReduction(user1), 5000); // still active
        assertEq(feeManager.getFeeReduction(user2), 2500); // still permanent
        assertEq(feeManager.getFeeReduction(tokenAdmin), 0); // now expired
        
        // Test non-existent address
        assertEq(feeManager.getFeeReduction(address(0x123)), 0); // no reduction
        
        console.log("Fee reduction retrieval works correctly");
    }

    function testOnlyGovCanManageFeeReductions() public {
        address[] memory addresses = new address[](1);
        uint256[] memory factors = new uint256[](1);
        uint256[] memory expirations = new uint256[](1);
        
        addresses[0] = user1;
        factors[0] = 5000;
        expirations[0] = block.timestamp + 30 days;
        
        // Try to add fee reduction as non-governance (should fail)
        vm.prank(user1);
        vm.expectRevert();
        feeManager.addFeeReduction(addresses, factors, expirations);
        
        // Try to remove fee reduction as non-governance (should fail)
        vm.prank(user1);
        vm.expectRevert();
        feeManager.removeFeeReduction(addresses);
        
        // Try to update expiration as non-governance (should fail)
        uint256[] memory newExpirations = new uint256[](1);
        newExpirations[0] = block.timestamp + 60 days;
        vm.prank(user1);
        vm.expectRevert();
        feeManager.updateFeeReductionExpiration(addresses, newExpirations);
        
        console.log("Access control works correctly - only governance can manage fee reductions");
    }
}
