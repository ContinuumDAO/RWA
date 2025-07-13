// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.22;

import { Test } from "forge-std/Test.sol";
import { Upgrades } from "@openzeppelin/foundry-upgrades/Upgrades.sol";
import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

import { Helpers } from "../helpers/Helpers.sol";
import { CTMRWADeployer } from "../../src/deployment/CTMRWADeployer.sol";
import { ICTMRWADeployer } from "../../src/deployment/ICTMRWADeployer.sol";

// Mock implementation for testing upgrades
contract CTMRWADeployerV2 is CTMRWADeployer {
    // New storage variable to test storage collision safety
    uint256 public newStorageVariable;
    
    // New function to test upgrade functionality
    function newFunction() external pure returns (string memory) {
        return "V2 Function";
    }
    
    // Override existing function to test upgrade
    function deployCTMRWA1(
        uint256 _ID,
        uint256 _rwaType,
        uint256 _version,
        string memory _tokenName,
        string memory _symbol,
        uint8 _decimals,
        string memory _baseURI,
        address _tokenAdmin,
        address _ctmRwa1X,
        address _ctmRwa1Map,
        address _c3callerProxy,
        address _txSender,
        uint256 _dappID,
        uint256 _dividendDappID,
        uint256 _storageDappID
    ) external override returns (address) {
        // Add some logic to differentiate from V1
        address result = super.deployCTMRWA1(
            _ID,
            _rwaType,
            _version,
            _tokenName,
            _symbol,
            _decimals,
            _baseURI,
            _tokenAdmin,
            _ctmRwa1X,
            _ctmRwa1Map,
            _c3callerProxy,
            _txSender,
            _dappID,
            _dividendDappID,
            _storageDappID
        );
        
        // V2 could add additional logic here
        return result;
    }
}

// Malicious implementation that tries to access storage incorrectly
contract MaliciousCTMRWADeployer is CTMRWADeployer {
    // This will cause storage collision
    uint256 public maliciousStorage;
    
    function attack() external {
        // Try to access storage incorrectly
        maliciousStorage = 999;
    }
}

contract TestCTMRWADeployerProxy is Helpers {
    using Strings for *;
    
    CTMRWADeployer public implementation;
    CTMRWADeployer public proxy;
    CTMRWADeployerV2 public implementationV2;
    MaliciousCTMRWADeployer public maliciousImplementation;
    
    function setUp() public override {
        super.setUp();
        
        // Deploy initial implementation
        implementation = new CTMRWADeployer();
        
        // Deploy proxy
        bytes memory initData = abi.encodeCall(
            CTMRWADeployer.initialize,
            (gov, address(c3caller), admin, 1)
        );
        
        proxy = CTMRWADeployer(
            address(
                new ERC1967Proxy(
                    address(implementation),
                    initData
                )
            )
        );
        
        // Deploy V2 implementation
        implementationV2 = new CTMRWADeployerV2();
        
        // Deploy malicious implementation
        maliciousImplementation = new MaliciousCTMRWADeployer();
    }

    // ============ UPGRADEABILITY TESTS ============

    function test_upgradeToNewImplementation() public {
        // Verify initial state
        assertEq(proxy.gov(), gov);
        
        // Upgrade to V2
        vm.prank(gov);
        proxy.upgradeToAndCall(address(implementationV2), "");
        
        // Test new functionality
        CTMRWADeployerV2 proxyV2 = CTMRWADeployerV2(address(proxy));
        assertEq(proxyV2.newFunction(), "V2 Function");
        
        // Test that existing functionality still works
        assertEq(proxy.gov(), gov);
    }

    function test_upgradeToAndCall() public {
        // Upgrade and call a function in one transaction
        bytes memory upgradeData = abi.encodeCall(
            CTMRWADeployerV2.newFunction,
            ()
        );
        
        vm.prank(gov);
        proxy.upgradeToAndCall(address(implementationV2), upgradeData);
        
        // Verify upgrade worked
        CTMRWADeployerV2 proxyV2 = CTMRWADeployerV2(address(proxy));
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
        // Upgrade to malicious implementation
        vm.prank(gov);
        proxy.upgradeToAndCall(address(maliciousImplementation), "");
        
        // Try to call the attack function
        MaliciousCTMRWADeployer maliciousProxy = MaliciousCTMRWADeployer(address(proxy));
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
        CTMRWADeployerV2 proxyV2 = CTMRWADeployerV2(address(proxy));
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
        // Upgrade to V2
        vm.prank(gov);
        proxy.upgradeToAndCall(address(implementationV2), "");
        
        // Test deployment function after upgrade
        vm.prank(gov);
        address deployedToken = proxy.deployCTMRWA1(
            1,
            1,
            1,
            "Test Token",
            "TEST",
            18,
            "GFLD",
            tokenAdmin,
            address(rwa1X),
            address(map),
            address(c3caller),
            admin,
            1,
            2,
            3
        );
        
        // Verify deployment worked
        assertTrue(deployedToken != address(0));
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

    // ============ DEPLOYMENT FUNCTIONALITY TESTS ============

    function test_deploymentAfterUpgrade() public {
        // Upgrade to V2
        vm.prank(gov);
        proxy.upgradeToAndCall(address(implementationV2), "");
        
        // Test deployment functionality still works
        vm.prank(gov);
        address deployedToken = proxy.deployCTMRWA1(
            1,
            1,
            1,
            "Test Token",
            "TEST",
            18,
            "GFLD",
            tokenAdmin,
            address(rwa1X),
            address(map),
            address(c3caller),
            admin,
            1,
            2,
            3
        );
        
        // Verify deployment worked
        assertTrue(deployedToken != address(0));
    }

    function test_deploymentAuthorizationAfterUpgrade() public {
        // Upgrade to V2
        vm.prank(gov);
        proxy.upgradeToAndCall(address(implementationV2), "");
        
        // Test that only authorized callers can deploy
        // Non-authorized caller should fail
        vm.prank(user1);
        vm.expectRevert();
        proxy.deployCTMRWA1(
            1,
            1,
            1,
            "Test Token",
            "TEST",
            18,
            "GFLD",
            tokenAdmin,
            address(rwa1X),
            address(map),
            address(c3caller),
            admin,
            1,
            2,
            3
        );
        
        // Authorized caller should succeed
        vm.prank(gov);
        proxy.deployCTMRWA1(
            1,
            1,
            1,
            "Test Token",
            "TEST",
            18,
            "GFLD",
            tokenAdmin,
            address(rwa1X),
            address(map),
            address(c3caller),
            admin,
            1,
            2,
            3
        );
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
        CTMRWADeployerV2 proxyV2 = CTMRWADeployerV2(address(proxy));
        assertEq(proxyV2.newFunction(), "V2 Function");
    }

    function test_upgradeWithActiveData() public {
        // Deploy some tokens before upgrade
        vm.prank(gov);
        address token1 = proxy.deployCTMRWA1(
            1,
            1,
            1,
            "Test Token 1",
            "TEST1",
            18,
            "GFLD",
            tokenAdmin,
            address(rwa1X),
            address(map),
            address(c3caller),
            admin,
            1,
            2,
            3
        );
        
        vm.prank(gov);
        address token2 = proxy.deployCTMRWA1(
            2,
            1,
            1,
            "Test Token 2",
            "TEST2",
            18,
            "GFLD",
            tokenAdmin,
            address(rwa1X),
            address(map),
            address(c3caller),
            admin,
            1,
            2,
            3
        );
        
        // Upgrade with active data
        vm.prank(gov);
        proxy.upgradeToAndCall(address(implementationV2), "");
        
        // Verify all data is preserved
        assertEq(proxy.gov(), gov);
        assertEq(proxy.c3CallerProxy(), address(c3caller));
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
        MaliciousCTMRWADeployer maliciousProxy = MaliciousCTMRWADeployer(address(proxy));
        maliciousProxy.attack();
        
        // Original functionality should still work
        assertEq(proxy.gov(), gov);
    }

    function test_deploymentSecurityAfterUpgrade() public {
        // Upgrade to V2
        vm.prank(gov);
        proxy.upgradeToAndCall(address(implementationV2), "");
        
        // Test that security measures still work
        // Only gov should be able to deploy
        
        vm.prank(user1);
        vm.expectRevert();
        proxy.deployCTMRWA1(
            1,
            1,
            1,
            "Test Token",
            "TEST",
            18,
            "GFLD",
            tokenAdmin,
            address(rwa1X),
            address(map),
            address(c3caller),
            admin,
            1,
            2,
            3
        );
        
        vm.prank(user2);
        vm.expectRevert();
        proxy.deployCTMRWA1(
            1,
            1,
            1,
            "Test Token",
            "TEST",
            18,
            "GFLD",
            tokenAdmin,
            address(rwa1X),
            address(map),
            address(c3caller),
            admin,
            1,
            2,
            3
        );
        
        // Only gov should succeed
        vm.prank(gov);
        proxy.deployCTMRWA1(
            1,
            1,
            1,
            "Test Token",
            "TEST",
            18,
            "GFLD",
            tokenAdmin,
            address(rwa1X),
            address(map),
            address(c3caller),
            admin,
            1,
            2,
            3
        );
    }

    // ============ GOVERNANCE INTEGRATION TESTS ============

    function test_governanceFunctionsAfterUpgrade() public {
        // Upgrade to V2
        vm.prank(gov);
        proxy.upgradeToAndCall(address(implementationV2), "");
        
        // Test that governance functions still work
        assertEq(proxy.gov(), gov);
    }

    // ============ C3CALLER INTEGRATION TESTS ============

    function test_c3callerIntegrationAfterUpgrade() public {
        // Upgrade to V2
        vm.prank(gov);
        proxy.upgradeToAndCall(address(implementationV2), "");
        
        // Test that c3caller integration still works
        assertEq(proxy.c3CallerProxy(), address(c3caller));
    }

    // ============ DEPLOYMENT PARAMETER TESTS ============

    function test_deploymentWithDifferentParameters() public {
        // Upgrade to V2
        vm.prank(gov);
        proxy.upgradeToAndCall(address(implementationV2), "");
        
        // Test deployment with different parameters
        vm.prank(gov);
        address token1 = proxy.deployCTMRWA1(
            1,
            1,
            1,
            "Token 1",
            "TKN1",
            6,
            "GFLD",
            tokenAdmin,
            address(rwa1X),
            address(map),
            address(c3caller),
            admin,
            1,
            2,
            3
        );
        
        vm.prank(gov);
        address token2 = proxy.deployCTMRWA1(
            2,
            2,
            1,
            "Token 2",
            "TKN2",
            18,
            "GFLD",
            user1,
            address(rwa1X),
            address(map),
            address(c3caller),
            admin,
            1,
            2,
            3
        );
        
        // Verify both deployments worked
        assertTrue(token1 != address(0));
        assertTrue(token2 != address(0));
        assertTrue(token1 != token2);
    }

    // ============ ERROR HANDLING TESTS ============

    function test_errorHandlingAfterUpgrade() public {
        // Upgrade to V2
        vm.prank(gov);
        proxy.upgradeToAndCall(address(implementationV2), "");
        
        // Test error handling for invalid parameters
        vm.prank(gov);
        vm.expectRevert();
        proxy.deployCTMRWA1(
            0, // Invalid ID
            1,
            1,
            "Test Token",
            "TEST",
            18,
            "GFLD",
            tokenAdmin,
            address(rwa1X),
            address(map),
            address(c3caller),
            admin,
            1,
            2,
            3
        );
    }

    // ============ UPGRADE VALIDATION TESTS ============

    function test_upgradeValidation() public {
        // Test that upgrade validation works correctly
        // This would typically involve checking storage layout compatibility
        // and other upgrade safety measures
        
        vm.prank(gov);
        proxy.upgradeToAndCall(address(implementationV2), "");
        
        // Verify the upgrade was successful
        CTMRWADeployerV2 proxyV2 = CTMRWADeployerV2(address(proxy));
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
        assertEq(proxy.c3callerProxy(), address(c3caller));
    }

    // ============ BATCH DEPLOYMENT TESTS ============

    function test_batchDeploymentAfterUpgrade() public {
        // Upgrade to V2
        vm.prank(gov);
        proxy.upgradeToAndCall(address(implementationV2), "");
        
        // Test batch deployment
        address[] memory deployedTokens = new address[](3);
        
        for (uint256 i = 0; i < 3; i++) {
            vm.prank(gov);
            deployedTokens[i] = proxy.deployCTMRWA1(
                i + 1,
                1,
                1,
                string(abi.encodePacked("Token ", vm.toString(i + 1))),
                string(abi.encodePacked("TKN", vm.toString(i + 1))),
                18,
                "GFLD",
                tokenAdmin,
                address(rwa1X),
                address(map),
                address(c3caller),
                admin,
                1,
                2,
                3
            );
        }
        
        // Verify all deployments worked
        for (uint256 i = 0; i < 3; i++) {
            assertTrue(deployedTokens[i] != address(0));
        }
    }
} 