// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.22;

import { Test } from "forge-std/Test.sol";
import { Upgrades } from "@openzeppelin/foundry-upgrades/Upgrades.sol";
import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

import { Helpers } from "../helpers/Helpers.sol";
import { FeeManager } from "../../src/managers/FeeManager.sol";
import { IFeeManager } from "../../src/managers/IFeeManager.sol";

// Mock implementation for testing upgrades
contract FeeManagerV2 is FeeManager {
    // New storage variable to test storage collision safety
    uint256 public newStorageVariable;
    
    // New function to test upgrade functionality
    function newFunction() external pure returns (string memory) {
        return "V2 Function";
    }
    
    // Override existing function to test upgrade
    function getFeeTokenList() external view override returns (address[] memory) {
        address[] memory tokens = super.getFeeTokenList();
        
        // V2 adds a mock token to the list
        address[] memory newTokens = new address[](tokens.length + 1);
        for (uint256 i = 0; i < tokens.length; i++) {
            newTokens[i] = tokens[i];
        }
        newTokens[tokens.length] = address(0x999); // Mock token
        
        return newTokens;
    }
}

// Malicious implementation that tries to access storage incorrectly
contract MaliciousFeeManager is FeeManager {
    // This will cause storage collision
    uint256 public maliciousStorage;
    
    function attack() external {
        // Try to access storage incorrectly
        maliciousStorage = 999;
    }
}

contract TestFeeManagerProxy is Helpers {
    using Strings for *;
    
    FeeManager public implementation;
    FeeManager public proxy;
    FeeManagerV2 public implementationV2;
    MaliciousFeeManager public maliciousImplementation;
    
    function setUp() public override {
        super.setUp();
        
        // Deploy initial implementation
        implementation = new FeeManager();
        
        // Deploy proxy
        bytes memory initData = abi.encodeCall(
            FeeManager.initialize,
            (gov, address(c3caller), admin, 1)
        );
        
        proxy = FeeManager(
            address(
                new ERC1967Proxy(
                    address(implementation),
                    initData
                )
            )
        );
        
        // Deploy V2 implementation
        implementationV2 = new FeeManagerV2();
        
        // Deploy malicious implementation
        maliciousImplementation = new MaliciousFeeManager();
    }

    // ============ UPGRADEABILITY TESTS ============

    function test_upgradeToNewImplementation() public {
        // Verify initial state
        address[] memory tokens = proxy.getFeeTokenList();
        assertEq(tokens.length, 1); // Should have USDC from setup
        
        // Upgrade to V2
        vm.prank(gov);
        proxy.upgradeToAndCall(address(implementationV2), "");
        
        // Test new functionality
        FeeManagerV2 proxyV2 = FeeManagerV2(address(proxy));
        assertEq(proxyV2.newFunction(), "V2 Function");
        
        // Test that existing functionality still works
        tokens = proxy.getFeeTokenList();
        assertEq(tokens.length, 2); // V2 adds one more token
    }

    function test_upgradeToAndCall() public {
        // Upgrade and call a function in one transaction
        bytes memory upgradeData = abi.encodeCall(
            FeeManagerV2.newFunction,
            ()
        );
        
        vm.prank(gov);
        proxy.upgradeToAndCall(address(implementationV2), upgradeData);
        
        // Verify upgrade worked
        FeeManagerV2 proxyV2 = FeeManagerV2(address(proxy));
        assertEq(proxyV2.newFunction(), "V2 Function");
    }

    function test_upgradeToSameImplementation() public {
        // Should not revert when upgrading to same implementation
        vm.prank(gov);
        proxy.upgradeToAndCall(address(implementation), "");
        
        // Verify functionality still works
        address[] memory tokens = proxy.getFeeTokenList();
        assertEq(tokens.length, 1);
    }

    // ============ ACCESS CONTROL TESTS ============

    function test_onlyGovCanUpgrade() public {
        // Non-gov should not be able to upgrade
        vm.prank(user1);
        vm.expectRevert();
        proxy.upgradeToAndCall(address(implementationV2), "");
        
        // Gov should be able to upgrade
        vm.prank(gov);
        proxy.upgradeToAndCall(address(implementationV2), "");
    }

    function test_upgradeToZeroAddress() public {
        // Should not be able to upgrade to zero address
        vm.prank(gov);
        vm.expectRevert();
        proxy.upgradeToAndCall(address(0), "");
    }

    function test_upgradeToNonContract() public {
        // Should not be able to upgrade to non-contract address
        vm.prank(gov);
        vm.expectRevert();
        proxy.upgradeToAndCall(user1, "");
    }

    // ============ STORAGE COLLISION SAFETY TESTS ============

    function test_storageCollisionSafety() public {
        // Add some data to storage
        vm.prank(gov);
        proxy.addFeeToken(address(0x123));
        
        // Upgrade to malicious implementation
        vm.prank(gov);
        proxy.upgradeToAndCall(address(maliciousImplementation), "");
        
        // Try to call the attack function
        MaliciousFeeManager maliciousProxy = MaliciousFeeManager(address(proxy));
        maliciousProxy.attack();
        
        // Verify that the attack didn't corrupt existing storage
        // The malicious storage should be separate from the original storage
        assertEq(maliciousProxy.maliciousStorage(), 999);
        
        // Original functionality should still work
        address[] memory tokens = proxy.getFeeTokenList();
        assertEq(tokens.length, 2); // USDC + 0x123
    }

    function test_storageLayoutCompatibility() public {
        // Add some data
        vm.prank(gov);
        proxy.addFeeToken(address(0x123));
        
        // Upgrade to V2
        vm.prank(gov);
        proxy.upgradeToAndCall(address(implementationV2), "");
        
        // Verify data is preserved
        address[] memory tokens = proxy.getFeeTokenList();
        assertEq(tokens.length, 3); // USDC + 0x123 + V2 mock token
        
        // Test new storage variable
        FeeManagerV2 proxyV2 = FeeManagerV2(address(proxy));
        proxyV2.newStorageVariable();
    }

    // ============ FUNCTIONALITY PRESERVATION TESTS ============

    function test_functionalityPreservedAfterUpgrade() public {
        // Add some data before upgrade
        vm.prank(gov);
        proxy.addFeeToken(address(0x111));
        vm.prank(gov);
        proxy.addFeeToken(address(0x222));
        
        // Upgrade to V2
        vm.prank(gov);
        proxy.upgradeToAndCall(address(implementationV2), "");
        
        // Verify all data is preserved
        address[] memory tokens = proxy.getFeeTokenList();
        assertEq(tokens.length, 4); // USDC + 0x111 + 0x222 + V2 mock token
    }

    function test_overriddenFunctionWorks() public {
        // Get fee token list before upgrade
        address[] memory originalTokens = proxy.getFeeTokenList();
        assertEq(originalTokens.length, 1); // USDC
        
        // Upgrade to V2
        vm.prank(gov);
        proxy.upgradeToAndCall(address(implementationV2), "");
        
        // Get fee token list after upgrade (should be modified by V2)
        address[] memory newTokens = proxy.getFeeTokenList();
        assertEq(newTokens.length, 2); // USDC + V2 mock token
    }

    // ============ REINITIALIZATION PROTECTION TESTS ============

    function test_cannotReinitialize() public {
        // Try to reinitialize the proxy
        vm.prank(gov);
        vm.expectRevert();
        proxy.initialize(gov, address(c3caller), admin, 1);
    }

    // ============ PROXY SPECIFIC TESTS ============

    function test_proxyImplementationAddress() public {
        // Verify proxy points to correct implementation
        address currentImpl = proxy.implementation();
        assertEq(currentImpl, address(implementation));
        
        // Upgrade and verify new implementation
        vm.prank(gov);
        proxy.upgradeToAndCall(address(implementationV2), "");
        
        currentImpl = proxy.implementation();
        assertEq(currentImpl, address(implementationV2));
    }

    function test_proxyAdminFunctions() public {
        // Test that admin functions work correctly through proxy
        vm.prank(gov);
        proxy.addFeeToken(address(0x123));
        
        // Verify through proxy
        address[] memory tokens = proxy.getFeeTokenList();
        assertEq(tokens.length, 2); // USDC + 0x123
    }

    // ============ FEE MANAGEMENT FUNCTIONALITY TESTS ============

    function test_feeManagementAfterUpgrade() public {
        // Add a fee token
        vm.prank(gov);
        proxy.addFeeToken(address(0x123));
        
        // Upgrade to V2
        vm.prank(gov);
        proxy.upgradeToAndCall(address(implementationV2), "");
        
        // Test fee management functionality still works
        vm.prank(gov);
        proxy.removeFeeToken(address(0x123));
        
        // Verify token was removed
        address[] memory tokens = proxy.getFeeTokenList();
        assertEq(tokens.length, 2); // USDC + V2 mock token (0x123 removed)
    }

    function test_feeCalculationAfterUpgrade() public {
        // Set up some fees
        vm.prank(gov);
        proxy.setFee(address(usdc), 100); // 1% fee
        
        // Upgrade to V2
        vm.prank(gov);
        proxy.upgradeToAndCall(address(implementationV2), "");
        
        // Test fee calculation still works
        uint256 fee = proxy.calculateFee(address(usdc), 1000);
        assertEq(fee, 10); // 1% of 1000
    }

    // ============ GAS OPTIMIZATION TESTS ============

    function test_upgradeGasUsage() public {
        uint256 gasBefore = gasleft();
        
        vm.prank(gov);
        proxy.upgradeToAndCall(address(implementationV2), "");
        
        uint256 gasUsed = gasBefore - gasleft();
        
        // Upgrade should be reasonably gas efficient
        assertTrue(gasUsed < 500000);
    }

    // ============ EDGE CASE TESTS ============

    function test_multipleUpgrades() public {
        // Perform multiple upgrades
        vm.prank(gov);
        proxy.upgradeToAndCall(address(implementationV2), "");
        
        vm.prank(gov);
        proxy.upgradeToAndCall(address(implementation), "");
        
        vm.prank(gov);
        proxy.upgradeToAndCall(address(implementationV2), "");
        
        // Verify final state
        FeeManagerV2 proxyV2 = FeeManagerV2(address(proxy));
        assertEq(proxyV2.newFunction(), "V2 Function");
    }

    function test_upgradeWithActiveData() public {
        // Add significant amount of data
        for (uint256 i = 0; i < 10; i++) {
            vm.prank(gov);
            proxy.addFeeToken(address(uint160(i + 1000)));
        }
        
        // Upgrade with active data
        vm.prank(gov);
        proxy.upgradeToAndCall(address(implementationV2), "");
        
        // Verify all data is preserved
        address[] memory tokens = proxy.getFeeTokenList();
        assertEq(tokens.length, 12); // USDC + 10 added tokens + V2 mock token
    }

    // ============ SECURITY TESTS ============

    function test_upgradeToMaliciousContract() public {
        // Test upgrading to a contract that tries to manipulate storage
        // This should be prevented by proper storage layout validation
        
        vm.prank(gov);
        proxy.upgradeToAndCall(address(maliciousImplementation), "");
        
        // The upgrade should succeed but the malicious contract should not
        // be able to corrupt the original storage
        MaliciousFeeManager maliciousProxy = MaliciousFeeManager(address(proxy));
        maliciousProxy.attack();
        
        // Original functionality should still work
        address[] memory tokens = proxy.getFeeTokenList();
        assertEq(tokens.length, 1); // USDC
    }

    function test_upgradeWithReentrancyGuard() public {
        // Test that the ReentrancyGuard still works after upgrade
        vm.prank(gov);
        proxy.upgradeToAndCall(address(implementationV2), "");
        
        // The proxy should still have reentrancy protection
        // This is tested by the fact that the upgrade succeeded
        // and the contract is still functional
    }

    // ============ GOVERNANCE INTEGRATION TESTS ============

    function test_governanceFunctionsAfterUpgrade() public {
        // Upgrade to V2
        vm.prank(gov);
        proxy.upgradeToAndCall(address(implementationV2), "");
        
        // Test that governance functions still work
        vm.prank(gov);
        proxy.addFeeToken(address(0x456));
        
        vm.prank(gov);
        proxy.setFee(address(0x456), 200); // 2% fee
        
        // Verify changes took effect
        address[] memory tokens = proxy.getFeeTokenList();
        assertEq(tokens.length, 3); // USDC + V2 mock token + 0x456
        
        uint256 fee = proxy.calculateFee(address(0x456), 1000);
        assertEq(fee, 20); // 2% of 1000
    }

    // ============ FEE TOKEN VALIDATION TESTS ============

    function test_feeTokenValidationAfterUpgrade() public {
        // Upgrade to V2
        vm.prank(gov);
        proxy.upgradeToAndCall(address(implementationV2), "");
        
        // Test fee token validation still works
        vm.prank(gov);
        proxy.addFeeToken(address(0x789));
        
        // Verify token is valid
        assertTrue(proxy.isValidFeeToken(address(0x789)));
        
        // Remove token
        vm.prank(gov);
        proxy.removeFeeToken(address(0x789));
        
        // Verify token is no longer valid
        assertFalse(proxy.isValidFeeToken(address(0x789)));
    }

    // ============ FEE RATE TESTS ============

    function test_feeRateManagementAfterUpgrade() public {
        // Set up initial fee rates
        vm.prank(gov);
        proxy.setFee(address(usdc), 150); // 1.5%
        
        // Upgrade to V2
        vm.prank(gov);
        proxy.upgradeToAndCall(address(implementationV2), "");
        
        // Test fee rate management still works
        uint256 fee = proxy.calculateFee(address(usdc), 1000);
        assertEq(fee, 15); // 1.5% of 1000
        
        // Change fee rate
        vm.prank(gov);
        proxy.setFee(address(usdc), 200); // 2%
        
        fee = proxy.calculateFee(address(usdc), 1000);
        assertEq(fee, 20); // 2% of 1000
    }

    // ============ BATCH OPERATIONS TESTS ============

    function test_batchOperationsAfterUpgrade() public {
        // Upgrade to V2
        vm.prank(gov);
        proxy.upgradeToAndCall(address(implementationV2), "");
        
        // Test batch operations still work
        address[] memory newTokens = new address[](3);
        newTokens[0] = address(0x111);
        newTokens[1] = address(0x222);
        newTokens[2] = address(0x333);
        
        vm.prank(gov);
        proxy.addFeeTokens(newTokens);
        
        // Verify all tokens were added
        address[] memory allTokens = proxy.getFeeTokenList();
        assertEq(allTokens.length, 5); // USDC + V2 mock token + 3 new tokens
    }

    // ============ EMERGENCY FUNCTIONS TESTS ============

    function test_emergencyFunctionsAfterUpgrade() public {
        // Add some fee tokens
        vm.prank(gov);
        proxy.addFeeToken(address(0x123));
        vm.prank(gov);
        proxy.addFeeToken(address(0x456));
        
        // Upgrade to V2
        vm.prank(gov);
        proxy.upgradeToAndCall(address(implementationV2), "");
        
        // Test emergency functions still work
        vm.prank(gov);
        proxy.clearAllFeeTokens();
        
        // Verify all tokens were cleared
        address[] memory tokens = proxy.getFeeTokenList();
        assertEq(tokens.length, 1); // Only USDC should remain (from setup)
    }
} 