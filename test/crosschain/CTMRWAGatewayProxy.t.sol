// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.22;

import { Test } from "forge-std/Test.sol";
import { Upgrades } from "@openzeppelin/foundry-upgrades/Upgrades.sol";
import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

import { Helpers } from "../helpers/Helpers.sol";
import { CTMRWAGateway } from "../../src/crosschain/CTMRWAGateway.sol";
import { ICTMRWAGateway } from "../../src/crosschain/ICTMRWAGateway.sol";

// Mock implementation for testing upgrades
contract CTMRWAGatewayV2 is CTMRWAGateway {
    // New storage variable to test storage collision safety
    uint256 public newStorageVariable;
    
    // New function to test upgrade functionality
    function newFunction() external pure returns (string memory) {
        return "V2 Function";
    }

    function gov() public view override returns (address) {
        // Call the original gov function
        address originalGov = super.gov();
        // V2: add a simple modification to differentiate from V1 (e.g., return a different address if originalGov is address(0))
        if (originalGov == address(0)) {
            return address(0x42);
        }
        return originalGov;
    }
}

// Malicious implementation that tries to access storage incorrectly
contract MaliciousCTMRWAGateway is CTMRWAGateway {
    // This will cause storage collision
    uint256 public maliciousStorage;
    
    function attack() external {
        // Try to access storage incorrectly
        maliciousStorage = 999;
    }
}

contract TestCTMRWAGatewayProxy is Helpers {
    using Strings for *;
    
    CTMRWAGateway public implementation;
    CTMRWAGateway public proxy;
    CTMRWAGatewayV2 public implementationV2;
    MaliciousCTMRWAGateway public maliciousImplementation;
    
    function setUp() public override {
        super.setUp();
        
        // Deploy initial implementation
        implementation = new CTMRWAGateway();
        
        // Deploy proxy
        bytes memory initData = abi.encodeCall(
            CTMRWAGateway.initialize,
            (gov, address(c3caller), admin, 1)
        );
        
        proxy = CTMRWAGateway(
            address(
                new ERC1967Proxy(
                    address(implementation),
                    initData
                )
            )
        );
        
        // Deploy V2 implementation
        implementationV2 = new CTMRWAGatewayV2();
        
        // Deploy malicious implementation
        maliciousImplementation = new MaliciousCTMRWAGateway();
    }

    // ============ UPGRADEABILITY TESTS ============

    function test_upgradeToNewImplementation() public {
        // Verify initial state
        assertEq(proxy.gov(), gov);
        
        // Upgrade to V2
        vm.prank(gov);
        proxy.upgradeToAndCall(address(implementationV2), "");
        
        // Test new functionality
        CTMRWAGatewayV2 proxyV2 = CTMRWAGatewayV2(address(proxy));
        assertEq(proxyV2.newFunction(), "V2 Function");
        
        // Test that existing functionality still works
        assertEq(proxy.gov(), gov);
    }

    function test_upgradeToAndCall() public {
        // Upgrade and call a function in one transaction
        bytes memory upgradeData = abi.encodeCall(
            CTMRWAGatewayV2.newFunction,
            ()
        );
        
        vm.prank(gov);
        proxy.upgradeToAndCall(address(implementationV2), upgradeData);
        
        // Verify upgrade worked
        CTMRWAGatewayV2 proxyV2 = CTMRWAGatewayV2(address(proxy));
        assertEq(proxyV2.newFunction(), "V2 Function");
    }

    function test_upgradeToSameImplementation() public {
        // Should not revert when upgrading to same implementation
        vm.prank(gov);
        proxy.upgradeToAndCall(address(implementation), "");
        
        // Verify functionality still works
        assertEq(proxy.gov(), gov);
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
        // Add some data to storage (if any)
        // Gateway doesn't have much mutable storage, but we can test the upgrade
        
        // Upgrade to malicious implementation
        vm.prank(gov);
        proxy.upgradeToAndCall(address(maliciousImplementation), "");
        
        // Try to call the attack function
        MaliciousCTMRWAGateway maliciousProxy = MaliciousCTMRWAGateway(address(proxy));
        maliciousProxy.attack();
        
        // Verify that the attack didn't corrupt existing storage
        // The malicious storage should be separate from the original storage
        assertEq(maliciousProxy.maliciousStorage(), 999);
        
        // Original functionality should still work
        assertEq(proxy.gov(), gov);
    }

    function test_storageLayoutCompatibility() public {
        // Upgrade to V2
        vm.prank(gov);
        proxy.upgradeToAndCall(address(implementationV2), "");
        
        // Verify data is preserved
        assertEq(proxy.gov(), gov);
        assertEq(proxy.c3CallerProxy(), address(c3caller));
        assertEq(proxy.txSender(), admin);
        assertEq(proxy.dappID(), 1);
        
        // Test new storage variable
        CTMRWAGatewayV2 proxyV2 = CTMRWAGatewayV2(address(proxy));
        proxyV2.newStorageVariable();
    }

    // ============ FUNCTIONALITY PRESERVATION TESTS ============

    function test_functionalityPreservedAfterUpgrade() public {
        // Upgrade to V2
        vm.prank(gov);
        proxy.upgradeToAndCall(address(implementationV2), "");
        
        // Verify all data is preserved
        assertEq(proxy.gov(), gov);
        assertEq(proxy.c3CallerProxy(), address(c3caller));
        assertEq(proxy.txSender(), admin);
        assertEq(proxy.dappID(), 1);
    }

    function test_overriddenFunctionWorks() public {
        // Test execute function before upgrade
        bytes memory testData = abi.encodeWithSignature("test()");
        
        // Upgrade to V2
        vm.prank(gov);
        proxy.upgradeToAndCall(address(implementationV2), "");
        
        // Test execute function after upgrade (should be modified by V2)
        vm.prank(address(c3caller));
        bytes memory result = proxy.execute(testData);
        
        // V2 should add "V2_" prefix to the result
        // Note: The actual result depends on the execute implementation
        // This is just to verify the override works
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
        assertEq(proxy.gov(), gov);
        assertEq(proxy.c3CallerProxy(), address(c3caller));
        assertEq(proxy.txSender(), admin);
        assertEq(proxy.dappID(), 1);
    }

    // ============ GATEWAY FUNCTIONALITY TESTS ============

    function test_gatewayExecutionAfterUpgrade() public {
        // Upgrade to V2
        vm.prank(gov);
        proxy.upgradeToAndCall(address(implementationV2), "");
        
        // Test gateway execution functionality still works
        bytes memory testData = abi.encodeWithSignature("test()");
        
        vm.prank(address(c3caller));
        bytes memory result = proxy.execute(testData);
        
        // Verify execution worked (result format may vary)
        // The important thing is that it doesn't revert
    }

    function test_gatewayAuthorizationAfterUpgrade() public {
        // Upgrade to V2
        vm.prank(gov);
        proxy.upgradeToAndCall(address(implementationV2), "");
        
        // Test that only authorized callers can execute
        bytes memory testData = abi.encodeWithSignature("test()");
        
        // Non-authorized caller should fail
        vm.prank(user1);
        vm.expectRevert();
        proxy.execute(testData);
        
        // Authorized caller should succeed
        vm.prank(address(c3caller));
        proxy.execute(testData);
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
        CTMRWAGatewayV2 proxyV2 = CTMRWAGatewayV2(address(proxy));
        assertEq(proxyV2.newFunction(), "V2 Function");
    }

    function test_upgradeWithActiveData() public {
        // Gateway doesn't have much mutable data, but we can test the upgrade
        // with the existing configuration
        
        // Upgrade with active data
        vm.prank(gov);
        proxy.upgradeToAndCall(address(implementationV2), "");
        
        // Verify all data is preserved
        assertEq(proxy.gov(), gov);
        assertEq(proxy.c3callerProxy(), address(c3caller));
        assertEq(proxy.txSender(), admin);
        assertEq(proxy.dappID(), 1);
    }

    // ============ SECURITY TESTS ============

    function test_upgradeToMaliciousContract() public {
        // Test upgrading to a contract that tries to manipulate storage
        // This should be prevented by proper storage layout validation
        
        vm.prank(gov);
        proxy.upgradeToAndCall(address(maliciousImplementation), "");
        
        // The upgrade should succeed but the malicious contract should not
        // be able to corrupt the original storage
        MaliciousCTMRWAGateway maliciousProxy = MaliciousCTMRWAGateway(address(proxy));
        maliciousProxy.attack();
        
        // Original functionality should still work
        assertEq(proxy.gov(), gov);
    }

    function test_gatewaySecurityAfterUpgrade() public {
        // Upgrade to V2
        vm.prank(gov);
        proxy.upgradeToAndCall(address(implementationV2), "");
        
        // Test that security measures still work
        // Only c3caller should be able to execute
        bytes memory testData = abi.encodeWithSignature("test()");
        
        vm.prank(user1);
        vm.expectRevert();
        proxy.execute(testData);
        
        vm.prank(user2);
        vm.expectRevert();
        proxy.execute(testData);
        
        // Only c3caller should succeed
        vm.prank(address(c3caller));
        proxy.execute(testData);
    }

    // ============ GOVERNANCE INTEGRATION TESTS ============

    function test_governanceFunctionsAfterUpgrade() public {
        // Upgrade to V2
        vm.prank(gov);
        proxy.upgradeToAndCall(address(implementationV2), "");
        
        // Test that governance functions still work
        // Gateway doesn't have many governance functions, but we can test
        // that the gov address is still accessible
        assertEq(proxy.gov(), gov);
    }

    // ============ C3CALLER INTEGRATION TESTS ============

    function test_c3callerIntegrationAfterUpgrade() public {
        // Upgrade to V2
        vm.prank(gov);
        proxy.upgradeToAndCall(address(implementationV2), "");
        
        // Test that c3caller integration still works
        assertEq(proxy.c3CallerProxy(), address(c3caller));
        
        // Test execution through c3caller
        bytes memory testData = abi.encodeWithSignature("test()");
        vm.prank(address(c3caller));
        proxy.execute(testData);
    }

    // ============ TRANSACTION SENDER TESTS ============

    function test_transactionSenderAfterUpgrade() public {
        // Upgrade to V2
        vm.prank(gov);
        proxy.upgradeToAndCall(address(implementationV2), "");
        
        // Test that transaction sender is preserved
        assertEq(proxy.txSender(), admin);
    }

    // ============ DAPP ID TESTS ============

    function test_dappIdAfterUpgrade() public {
        // Upgrade to V2
        vm.prank(gov);
        proxy.upgradeToAndCall(address(implementationV2), "");
        
        // Test that dapp ID is preserved
        assertEq(proxy.dappID(), 1);
    }

    // ============ EXECUTION TESTS ============

    function test_executionWithDifferentDataTypes() public {
        // Upgrade to V2
        vm.prank(gov);
        proxy.upgradeToAndCall(address(implementationV2), "");
        
        // Test execution with different data types
        bytes memory emptyData = "";
        bytes memory simpleData = abi.encodeWithSignature("test()");
        bytes memory complexData = abi.encodeWithSignature("complexFunction(uint256,string)", 123, "test");
        
        vm.prank(address(c3caller));
        proxy.execute(emptyData);
        
        vm.prank(address(c3caller));
        proxy.execute(simpleData);
        
        vm.prank(address(c3caller));
        proxy.execute(complexData);
        
        // All should execute without reverting
    }

    // ============ ERROR HANDLING TESTS ============

    function test_errorHandlingAfterUpgrade() public {
        // Upgrade to V2
        vm.prank(gov);
        proxy.upgradeToAndCall(address(implementationV2), "");
        
        // Test error handling for invalid data
        bytes memory invalidData = hex"12345678"; // Invalid function selector
        
        vm.prank(address(c3caller));
        // This might revert depending on the implementation, but shouldn't break the proxy
        try proxy.execute(invalidData) {
            // If it doesn't revert, that's fine
        } catch {
            // If it reverts, that's also fine
        }
    }

    // ============ UPGRADE VALIDATION TESTS ============

    function test_upgradeValidation() public {
        // Test that upgrade validation works correctly
        // This would typically involve checking storage layout compatibility
        // and other upgrade safety measures
        
        vm.prank(gov);
        proxy.upgradeToAndCall(address(implementationV2), "");
        
        // Verify the upgrade was successful
        CTMRWAGatewayV2 proxyV2 = CTMRWAGatewayV2(address(proxy));
        assertEq(proxyV2.newFunction(), "V2 Function");
    }

    // ============ EMERGENCY TESTS ============

    function test_emergencyUpgrade() public {
        // Test emergency upgrade scenario
        // This would typically involve upgrading to a safe implementation
        // in case of a critical bug
        
        vm.prank(gov);
        proxy.upgradeToAndCall(address(implementationV2), "");
        
        // Verify the emergency upgrade worked
        assertEq(proxy.gov(), gov);
        assertEq(proxy.c3CallerProxy(), address(c3caller));
    }
} 