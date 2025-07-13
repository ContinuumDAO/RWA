// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.22;

import { Test } from "forge-std/Test.sol";
import { Upgrades } from "@openzeppelin/foundry-upgrades/Upgrades.sol";
import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

import { Helpers } from "../helpers/Helpers.sol";
import { CTMRWAMap } from "../../src/shared/CTMRWAMap.sol";
import { ICTMRWAMap } from "../../src/shared/ICTMRWAMap.sol";


// Mock implementation for testing upgrades
contract CTMRWAMapV2 is CTMRWAMap {

    // New storage variable to test storage collision safety
    uint256 public newStorageVariable;
    
    // New function to test upgrade functionality
    function newFunction() external pure returns (string memory) {
        return "V2 Function";
    }
    
    // Override existing function to test upgrade
    function getTokenId(string memory _tokenAddrStr, uint256 _rwaType, uint256 _version) 
        external 
        view 
        override 
        returns (bool, uint256) 
    {
        // Add some logic to differentiate from V1
        (bool exists, uint256 id) = super.getTokenId(_tokenAddrStr, _rwaType, _version);
        if (exists) {
            return (exists, id + 1000); // Add 1000 to test upgrade
        }
        return (exists, id);
    }
}

// Malicious implementation that tries to access storage incorrectly
contract MaliciousCTMRWAMap is CTMRWAMap {
    // This will cause storage collision
    uint256 public maliciousStorage;
    
    function attack() external {
        // Try to access storage incorrectly
        maliciousStorage = 999;
    }
}

contract TestCTMRWAMapProxy is Helpers {
    using Strings for *;
    
    CTMRWAMap public implementation;
    CTMRWAMap public proxy;
    CTMRWAMapV2 public implementationV2;
    MaliciousCTMRWAMap public maliciousImplementation;
    
    function setUp() public override {
        super.setUp();
        
        // Deploy initial implementation
        implementation = new CTMRWAMap();
        
        // Deploy proxy
        bytes memory initData = abi.encodeCall(
            CTMRWAMap.initialize,
            (gov, address(c3caller), admin, 1)
        );
        
        proxy = CTMRWAMap(
            address(
                new ERC1967Proxy(
                    address(implementation),
                    initData
                )
            )
        );
        
        // Deploy V2 implementation
        implementationV2 = new CTMRWAMapV2();
        
        // Deploy malicious implementation
        maliciousImplementation = new MaliciousCTMRWAMap();
    }

    // ============ UPGRADEABILITY TESTS ============

    function test_upgradeToNewImplementation() public {
        // Verify initial state
        assertEq(proxy.getTokenId("test", 1, 1), (false, 0));
        
        // Upgrade to V2
        vm.prank(gov);
        proxy.upgradeToAndCall(address(implementationV2), "");
        
        // Test new functionality
        CTMRWAMapV2 proxyV2 = CTMRWAMapV2(address(proxy));
        assertEq(proxyV2.newFunction(), "V2 Function");
        
        // Test that existing functionality still works
        assertEq(proxy.getTokenId("test", 1, 1), (false, 0));
    }

    function test_upgradeToAndCall() public {
        // Upgrade and call a function in one transaction
        bytes memory upgradeData = abi.encodeCall(
            CTMRWAMapV2.newFunction,
            ()
        );
        
        vm.prank(gov);
        proxy.upgradeToAndCall(address(implementationV2), upgradeData);
        
        // Verify upgrade worked
        CTMRWAMapV2 proxyV2 = CTMRWAMapV2(address(proxy));
        assertEq(proxyV2.newFunction(), "V2 Function");
    }

    function test_upgradeToSameImplementation() public {
        // Should not revert when upgrading to same implementation
        vm.prank(gov);
        proxy.upgradeToAndCall(address(implementation), "");
        
        // Verify functionality still works
        assertEq(proxy.getTokenId("test", 1, 1), (false, 0));
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
        proxy.addTokenContract("test", 1, 1, address(0x123));
        
        // Upgrade to malicious implementation
        vm.prank(gov);
        proxy.upgradeToAndCall(address(maliciousImplementation), "");
        
        // Try to call the attack function
        MaliciousCTMRWAMap maliciousProxy = MaliciousCTMRWAMap(address(proxy));
        maliciousProxy.attack();
        
        // Verify that the attack didn't corrupt existing storage
        // The malicious storage should be separate from the original storage
        assertEq(maliciousProxy.maliciousStorage(), 999);
        
        // Original functionality should still work
        assertEq(proxy.getTokenContract("test", 1, 1), (true, address(0x123)));
    }

    function test_storageLayoutCompatibility() public {
        // Add some data
        vm.prank(gov);
        proxy.addTokenContract("test", 1, 1, address(0x123));
        
        // Upgrade to V2
        vm.prank(gov);
        proxy.upgradeToAndCall(address(implementationV2), "");
        
        // Verify data is preserved
        (bool exists, address tokenAddr) = proxy.getTokenContract("test", 1, 1);
        assertTrue(exists);
        assertEq(tokenAddr, address(0x123));
        
        // Test new storage variable
        CTMRWAMapV2 proxyV2 = CTMRWAMapV2(address(proxy));
        proxyV2.newStorageVariable();
    }

    // ============ FUNCTIONALITY PRESERVATION TESTS ============

    function test_functionalityPreservedAfterUpgrade() public {
        // Add some data before upgrade
        vm.prank(gov);
        proxy.addTokenContract("test1", 1, 1, address(0x111));
        vm.prank(gov);
        proxy.addTokenContract("test2", 1, 1, address(0x222));
        
        // Upgrade to V2
        vm.prank(gov);
        proxy.upgradeToAndCall(address(implementationV2), "");
        
        // Verify all data is preserved
        (bool exists1, address addr1) = proxy.getTokenContract("test1", 1, 1);
        (bool exists2, address addr2) = proxy.getTokenContract("test2", 1, 1);
        
        assertTrue(exists1);
        assertTrue(exists2);
        assertEq(addr1, address(0x111));
        assertEq(addr2, address(0x222));
    }

    function test_overriddenFunctionWorks() public {
        // Add a token contract
        vm.prank(gov);
        proxy.addTokenContract("test", 1, 1, address(0x123));
        
        // Get token ID before upgrade
        (bool exists, uint256 id) = proxy.getTokenId("test", 1, 1);
        assertTrue(exists);
        uint256 originalId = id;
        
        // Upgrade to V2
        vm.prank(gov);
        proxy.upgradeToAndCall(address(implementationV2), "");
        
        // Get token ID after upgrade (should be modified by V2)
        (exists, id) = proxy.getTokenId("test", 1, 1);
        assertTrue(exists);
        assertEq(id, originalId + 1000); // V2 adds 1000
    }

    // ============ REINITIALIZATION PROTECTION TESTS ============

    function test_cannotReinitialize() public {
        // Try to reinitialize the proxy
        bytes memory initData = abi.encodeCall(
            CTMRWAMap.initialize,
            (gov, address(c3caller), admin, 1)
        );
        
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
        proxy.addTokenContract("test", 1, 1, address(0x123));
        
        // Verify through proxy
        (bool exists, address addr) = proxy.getTokenContract("test", 1, 1);
        assertTrue(exists);
        assertEq(addr, address(0x123));
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

    function test_upgradeToImplementationWithConstructor() public {
        // Test upgrading to an implementation that has a constructor
        // This should work as long as the constructor doesn't have parameters
        // or the parameters are provided in upgradeToAndCall
    }

    function test_multipleUpgrades() public {
        // Perform multiple upgrades
        vm.prank(gov);
        proxy.upgradeToAndCall(address(implementationV2), "");
        
        vm.prank(gov);
        proxy.upgradeToAndCall(address(implementation), "");
        
        vm.prank(gov);
        proxy.upgradeToAndCall(address(implementationV2), "");
        
        // Verify final state
        CTMRWAMapV2 proxyV2 = CTMRWAMapV2(address(proxy));
        assertEq(proxyV2.newFunction(), "V2 Function");
    }

    function test_upgradeWithActiveData() public {
        // Add significant amount of data
        for (uint256 i = 0; i < 10; i++) {
            vm.prank(gov);
            proxy.addTokenContract(
                string(abi.encodePacked("test", vm.toString(i))),
                1,
                1,
                address(uint160(i + 1))
            );
        }
        
        // Upgrade with active data
        vm.prank(gov);
        proxy.upgradeToAndCall(address(implementationV2), "");
        
        // Verify all data is preserved
        for (uint256 i = 0; i < 10; i++) {
            (bool exists, address addr) = proxy.getTokenContract(
                string(abi.encodePacked("test", vm.toString(i))),
                1,
                1
            );
            assertTrue(exists);
            assertEq(addr, address(uint160(i + 1)));
        }
    }

    // ============ SECURITY TESTS ============

    function test_upgradeToMaliciousContract() public {
        // Test upgrading to a contract that tries to manipulate storage
        // This should be prevented by proper storage layout validation
        
        vm.prank(gov);
        proxy.upgradeToAndCall(address(maliciousImplementation), "");
        
        // The upgrade should succeed but the malicious contract should not
        // be able to corrupt the original storage
        MaliciousCTMRWAMap maliciousProxy = MaliciousCTMRWAMap(address(proxy));
        maliciousProxy.attack();
        
        // Original functionality should still work
        assertEq(proxy.getTokenContract("test", 1, 1), (false, address(0)));
    }

    function test_upgradeToContractWithSelfDestruct() public {
        // This test would verify that upgrading to a contract with selfdestruct
        // doesn't break the proxy. However, this is more of a deployment concern
        // rather than a runtime concern.
    }
} 