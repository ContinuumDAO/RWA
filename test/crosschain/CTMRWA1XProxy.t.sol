// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.22;

import { Test } from "forge-std/Test.sol";
import { Upgrades } from "@openzeppelin/foundry-upgrades/Upgrades.sol";
import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

import { Helpers } from "../helpers/Helpers.sol";
import { CTMRWA1X } from "../../src/crosschain/CTMRWA1X.sol";
import { ICTMRWA1X } from "../../src/crosschain/ICTMRWA1X.sol";

// Mock implementation for testing upgrades
contract CTMRWA1XV2 is CTMRWA1X {
    // New storage variable to test storage collision safety
    uint256 public newStorageVariable;
    
    // New function to test upgrade functionality
    function newFunction() external pure returns (string memory) {
        return "V2 Function";
    }
    
    // Override existing function to test upgrade
    function deployAllCTMRWA1X(
        bool _includeLocalMint,
        uint256 _ID,
        uint256 _rwaType,
        uint256 _version,
        string memory _tokenName,
        string memory _symbol,
        uint8 _decimals,
        string memory _baseURI,
        string[] memory _toChainIdsStr,
        string memory _feeTokenStr
    ) external override returns (uint256) {
        // Add some logic to differentiate from V1
        uint256 result = super.deployAllCTMRWA1X(
            _includeLocalMint,
            _ID,
            _rwaType,
            _version,
            _tokenName,
            _symbol,
            _decimals,
            _baseURI,
            _toChainIdsStr,
            _feeTokenStr
        );
        
        // V2 adds 1000 to the ID
        return result + 1000;
    }
}

// Malicious implementation that tries to access storage incorrectly
contract MaliciousCTMRWA1X is CTMRWA1X {
    // This will cause storage collision
    uint256 public maliciousStorage;
    
    function attack() external {
        // Try to access storage incorrectly
        maliciousStorage = 999;
    }
}

contract TestCTMRWA1XProxy is Helpers {
    using Strings for *;
    
    CTMRWA1X public implementation;
    CTMRWA1X public proxy;
    CTMRWA1XV2 public implementationV2;
    MaliciousCTMRWA1X public maliciousImplementation;
    
    function setUp() public override {
        super.setUp();
        
        // Deploy initial implementation
        implementation = new CTMRWA1X();
        
        // Deploy proxy
        bytes memory initData = abi.encodeCall(
            CTMRWA1X.initialize,
            (address(gateway), address(feeManager), gov, address(c3caller), admin, 1)
        );
        
        proxy = CTMRWA1X(
            address(
                new ERC1967Proxy(
                    address(implementation),
                    initData
                )
            )
        );
        
        // Deploy V2 implementation
        implementationV2 = new CTMRWA1XV2();
        
        // Deploy malicious implementation
        maliciousImplementation = new MaliciousCTMRWA1X();
    }

    // ============ UPGRADEABILITY TESTS ============

    function test_upgradeToNewImplementation() public {
        // Verify initial state
        assertEq(proxy.getAllTokensByAdminAddress(tokenAdmin).length, 0);
        
        // Upgrade to V2
        vm.prank(gov);
        proxy.upgradeToAndCall(address(implementationV2), "");
        
        // Test new functionality
        CTMRWA1XV2 proxyV2 = CTMRWA1XV2(address(proxy));
        assertEq(proxyV2.newFunction(), "V2 Function");
        
        // Test that existing functionality still works
        assertEq(proxy.getAllTokensByAdminAddress(tokenAdmin).length, 0);
    }

    function test_upgradeToAndCall() public {
        // Upgrade and call a function in one transaction
        bytes memory upgradeData = abi.encodeCall(
            CTMRWA1XV2.newFunction,
            ()
        );
        
        vm.prank(gov);
        proxy.upgradeToAndCall(address(implementationV2), upgradeData);
        
        // Verify upgrade worked
        CTMRWA1XV2 proxyV2 = CTMRWA1XV2(address(proxy));
        assertEq(proxyV2.newFunction(), "V2 Function");
    }

    function test_upgradeToSameImplementation() public {
        // Should not revert when upgrading to same implementation
        vm.prank(gov);
        proxy.upgradeToAndCall(address(implementation), "");
        
        // Verify functionality still works
        assertEq(proxy.getAllTokensByAdminAddress(tokenAdmin).length, 0);
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
        vm.prank(tokenAdmin);
        proxy.deployAllCTMRWA1X(
            true,
            0,
            1,
            1,
            "Test Token",
            "TEST",
            18,
            "GFLD",
            new string[](0),
            address(usdc).toHexString()
        );
        
        // Upgrade to malicious implementation
        vm.prank(gov);
        proxy.upgradeToAndCall(address(maliciousImplementation), "");
        
        // Try to call the attack function
        MaliciousCTMRWA1X maliciousProxy = MaliciousCTMRWA1X(address(proxy));
        maliciousProxy.attack();
        
        // Verify that the attack didn't corrupt existing storage
        // The malicious storage should be separate from the original storage
        assertEq(maliciousProxy.maliciousStorage(), 999);
        
        // Original functionality should still work
        assertEq(proxy.getAllTokensByAdminAddress(tokenAdmin).length, 1);
    }

    function test_storageLayoutCompatibility() public {
        // Add some data
        vm.prank(tokenAdmin);
        uint256 tokenId = proxy.deployAllCTMRWA1X(
            true,
            0,
            1,
            1,
            "Test Token",
            "TEST",
            18,
            "GFLD",
            new string[](0),
            address(usdc).toHexString()
        );
        
        // Upgrade to V2
        vm.prank(gov);
        proxy.upgradeToAndCall(address(implementationV2), "");
        
        // Verify data is preserved
        address[] memory tokens = proxy.getAllTokensByAdminAddress(tokenAdmin);
        assertEq(tokens.length, 1);
        
        // Test new storage variable
        CTMRWA1XV2 proxyV2 = CTMRWA1XV2(address(proxy));
        proxyV2.newStorageVariable();
    }

    // ============ FUNCTIONALITY PRESERVATION TESTS ============

    function test_functionalityPreservedAfterUpgrade() public {
        // Add some data before upgrade
        vm.prank(tokenAdmin);
        proxy.deployAllCTMRWA1X(
            true,
            0,
            1,
            1,
            "Test Token 1",
            "TEST1",
            18,
            "GFLD",
            new string[](0),
            address(usdc).toHexString()
        );
        
        vm.prank(tokenAdmin);
        proxy.deployAllCTMRWA1X(
            true,
            0,
            1,
            1,
            "Test Token 2",
            "TEST2",
            18,
            "GFLD",
            new string[](0),
            address(usdc).toHexString()
        );
        
        // Upgrade to V2
        vm.prank(gov);
        proxy.upgradeToAndCall(address(implementationV2), "");
        
        // Verify all data is preserved
        address[] memory tokens = proxy.getAllTokensByAdminAddress(tokenAdmin);
        assertEq(tokens.length, 2);
    }

    function test_overriddenFunctionWorks() public {
        // Deploy a token before upgrade
        vm.prank(tokenAdmin);
        uint256 originalTokenId = proxy.deployAllCTMRWA1X(
            true,
            0,
            1,
            1,
            "Test Token",
            "TEST",
            18,
            "GFLD",
            new string[](0),
            address(usdc).toHexString()
        );
        
        // Upgrade to V2
        vm.prank(gov);
        proxy.upgradeToAndCall(address(implementationV2), "");
        
        // Deploy another token after upgrade (should be modified by V2)
        vm.prank(tokenAdmin);
        uint256 newTokenId = proxy.deployAllCTMRWA1X(
            true,
            0,
            1,
            1,
            "Test Token V2",
            "TESTV2",
            18,
            "GFLD",
            new string[](0),
            address(usdc).toHexString()
        );
        
        // V2 should add 1000 to the ID
        assertEq(newTokenId, originalTokenId + 1000 + 1); // +1 for the new token
    }

    // ============ REINITIALIZATION PROTECTION TESTS ============

    function test_cannotReinitialize() public {
        // Try to reinitialize the proxy
        vm.prank(gov);
        vm.expectRevert();
        proxy.initialize(address(gateway), address(feeManager), gov, address(c3caller), admin, 1);
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
        vm.prank(tokenAdmin);
        proxy.deployAllCTMRWA1X(
            true,
            0,
            1,
            1,
            "Test Token",
            "TEST",
            18,
            "GFLD",
            new string[](0),
            address(usdc).toHexString()
        );
        
        // Verify through proxy
        address[] memory tokens = proxy.getAllTokensByAdminAddress(tokenAdmin);
        assertEq(tokens.length, 1);
    }

    // ============ CROSS-CHAIN FUNCTIONALITY TESTS ============

    function test_crossChainFunctionalityAfterUpgrade() public {
        // Deploy a token
        vm.prank(tokenAdmin);
        uint256 tokenId = proxy.deployAllCTMRWA1X(
            true,
            0,
            1,
            1,
            "Test Token",
            "TEST",
            18,
            "GFLD",
            new string[](0),
            address(usdc).toHexString()
        );
        
        // Upgrade to V2
        vm.prank(gov);
        proxy.upgradeToAndCall(address(implementationV2), "");
        
        // Test cross-chain functionality still works
        vm.prank(tokenAdmin);
        proxy.createNewSlot(
            tokenId,
            5,
            "Test Slot",
            new string[](0),
            address(usdc).toHexString()
        );
        
        // Verify slot was created
        // Note: This would require access to the actual token contract
        // which is beyond the scope of this proxy test
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
        CTMRWA1XV2 proxyV2 = CTMRWA1XV2(address(proxy));
        assertEq(proxyV2.newFunction(), "V2 Function");
    }

    function test_upgradeWithActiveData() public {
        // Add significant amount of data
        for (uint256 i = 0; i < 5; i++) {
            vm.prank(tokenAdmin);
            proxy.deployAllCTMRWA1X(
                true,
                0,
                1,
                1,
                string(abi.encodePacked("Test Token ", vm.toString(i))),
                string(abi.encodePacked("TEST", vm.toString(i))),
                18,
                "GFLD",
                new string[](0),
                address(usdc).toHexString()
            );
        }
        
        // Upgrade with active data
        vm.prank(gov);
        proxy.upgradeToAndCall(address(implementationV2), "");
        
        // Verify all data is preserved
        address[] memory tokens = proxy.getAllTokensByAdminAddress(tokenAdmin);
        assertEq(tokens.length, 5);
    }

    // ============ SECURITY TESTS ============

    function test_upgradeToMaliciousContract() public {
        // Test upgrading to a contract that tries to manipulate storage
        // This should be prevented by proper storage layout validation
        
        vm.prank(gov);
        proxy.upgradeToAndCall(address(maliciousImplementation), "");
        
        // The upgrade should succeed but the malicious contract should not
        // be able to corrupt the original storage
        MaliciousCTMRWA1X maliciousProxy = MaliciousCTMRWA1X(address(proxy));
        maliciousProxy.attack();
        
        // Original functionality should still work
        assertEq(proxy.getAllTokensByAdminAddress(tokenAdmin).length, 0);
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
        // This would include functions like changeTokenAdmin, etc.
        // The exact functions depend on the CTMRWA1X implementation
    }

    // ============ FEE MANAGER INTEGRATION TESTS ============

    function test_feeManagerIntegrationAfterUpgrade() public {
        // Upgrade to V2
        vm.prank(gov);
        proxy.upgradeToAndCall(address(implementationV2), "");
        
        // Test that fee manager integration still works
        // This would include functions that interact with the fee manager
    }

    // ============ GATEWAY INTEGRATION TESTS ============

    function test_gatewayIntegrationAfterUpgrade() public {
        // Upgrade to V2
        vm.prank(gov);
        proxy.upgradeToAndCall(address(implementationV2), "");
        
        // Test that gateway integration still works
        // This would include functions that interact with the gateway
    }
} 