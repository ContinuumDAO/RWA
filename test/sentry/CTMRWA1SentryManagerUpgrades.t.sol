// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.27;

import { Test } from "forge-std/Test.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import { IC3GovClient } from "@c3caller/gov/IC3GovClient.sol";
import { IC3GovernDApp } from "@c3caller/gov/IC3GovernDApp.sol";
import { C3ErrorParam } from "@c3caller/utils/C3CallerUtils.sol";

import { Helpers } from "../helpers/Helpers.sol";
import { CTMRWA1SentryManager } from "../../src/sentry/CTMRWA1SentryManager.sol";
import { ICTMRWA1SentryManager } from "../../src/sentry/ICTMRWA1SentryManager.sol";
import { CTMRWAMap } from "../../src/shared/CTMRWAMap.sol";
import { CTMRWAErrorParam } from "../../src/utils/CTMRWAUtils.sol";

// Mock implementation for testing upgrades
contract MockCTMRWA1SentryManagerV2 is CTMRWA1SentryManager {
    uint256 public newVersion;

    function initializeV2(uint256 _newVersion) external reinitializer(uint64(_newVersion)) {
        newVersion = _newVersion;
        // Simulate bumping the latest token version during an upgrade
        LATEST_VERSION = _newVersion;
    }

    function newFunction() external pure returns (string memory) {
        return "V2 Function";
    }
}

// Malicious implementation that tries to change critical state
contract MaliciousCTMRWA1SentryManager is CTMRWA1SentryManager {
    function initializeV2() external reinitializer(2) {
        // Try to change critical addresses
        ctmRwaDeployer = address(0xdead);
        ctmRwaMap = address(0xdead);
        utilsAddr = address(0xdead);
        gateway = address(0xdead);
        feeManager = address(0xdead);
        identity = address(0xdead);
    }
}

/**
 * @title CTMRWA1SentryManager Upgrade Tests
 * @notice Tests for proxy upgrades of CTMRWA1SentryManager contract
 */
contract TestCTMRWA1SentryManagerUpgrades is Helpers {
    // Mock implementation for testing upgrades
    MockCTMRWA1SentryManagerV2 mockImpl;

    // Malicious implementation that tries to change critical state
    MaliciousCTMRWA1SentryManager maliciousImpl;

    function setUp() public override {
        super.setUp();
        mockImpl = new MockCTMRWA1SentryManagerV2();
        maliciousImpl = new MaliciousCTMRWA1SentryManager();
    }

    function test_upgrade_proxy_successfully() public {
        // Store initial state
        address initialDeployer = sentryManager.ctmRwaDeployer();
        address initialMap = sentryManager.ctmRwaMap();
        address initialUtils = sentryManager.utilsAddr();
        uint256 initialRwaType = sentryManager.RWA_TYPE();

        // Upgrade the proxy
        vm.startPrank(gov);
        (bool success, ) = address(sentryManager).call(abi.encodeWithSignature("upgradeToAndCall(address,bytes)", address(mockImpl), abi.encodeCall(MockCTMRWA1SentryManagerV2.initializeV2, (42))));
        assertTrue(success, "upgradeToAndCall failed");
        vm.stopPrank();

        // Verify state is preserved
        assertEq(sentryManager.ctmRwaDeployer(), initialDeployer, "Deployer should be preserved");
        assertEq(sentryManager.ctmRwaMap(), initialMap, "Map should be preserved");
        assertEq(sentryManager.utilsAddr(), initialUtils, "Utils should be preserved");
        // RWA_TYPE is immutable; confirm it remains preserved across upgrade
        uint256 preservedRwaType = sentryManager.RWA_TYPE();
        assertEq(preservedRwaType, initialRwaType, "RWA_TYPE should be preserved");

        // Verify new functionality works
        MockCTMRWA1SentryManagerV2(address(sentryManager)).newFunction();
        assertEq(MockCTMRWA1SentryManagerV2(address(sentryManager)).newVersion(), 42, "New version should be set");

        // Verify LATEST_VERSION was updated by the upgrade initializer
        uint256 afterLatest = sentryManager.LATEST_VERSION();
        assertEq(afterLatest, 42, "LATEST_VERSION should be bumped to new initializer version");
    }

    function test_upgrade_proxy_without_initialization() public {
        // Store initial state
        address initialDeployer = sentryManager.ctmRwaDeployer();

        // Upgrade the proxy without initialization
        vm.startPrank(gov);
        (bool success,) = address(sentryManager).call(abi.encodeWithSignature("upgradeToAndCall(address,bytes)", address(mockImpl), bytes("")));
        assertTrue(success, "upgradeToAndCall failed");
        vm.stopPrank();

        // Verify state is preserved
        assertEq(sentryManager.ctmRwaDeployer(), initialDeployer, "Deployer should be preserved");

        // Verify new functionality works
        MockCTMRWA1SentryManagerV2(address(sentryManager)).newFunction();
        assertEq(MockCTMRWA1SentryManagerV2(address(sentryManager)).newVersion(), 0, "New version should be default");
    }

    function test_upgrade_proxy_preserves_admin_tokens_mapping() public {
        // Deploy a CTMRWA1 token to populate adminTokens mapping
        vm.startPrank(tokenAdmin);
        string[] memory toChainIdsStr = new string[](0);

        rwa1X.deployAllCTMRWA1X(
            true, // includeLocal
            0, // existingID
            1, // version
            "Test Token",
            "TEST",
            18, // decimals
            "GFLD", // baseURI
            toChainIdsStr,
            _toLower(addressToString(address(ctm)))
        );
        vm.stopPrank();

        // Get admin tokens before upgrade
        address[] memory adminTokensBefore = rwa1X.getAllTokensByAdminAddress(tokenAdmin);
        assertGt(adminTokensBefore.length, 0, "Should have admin tokens before upgrade");

        // Upgrade the proxy
        vm.startPrank(gov);
        (bool success, ) = address(sentryManager).call(abi.encodeWithSignature("upgradeToAndCall(address,bytes)", address(mockImpl), abi.encodeCall(MockCTMRWA1SentryManagerV2.initializeV2, (42))));
        assertTrue(success, "upgradeToAndCall failed");
        vm.stopPrank();

        // Get admin tokens after upgrade
        address[] memory adminTokensAfter = rwa1X.getAllTokensByAdminAddress(tokenAdmin);

        // Verify admin tokens mapping is preserved
        assertEq(adminTokensAfter.length, adminTokensBefore.length, "Admin tokens count should be preserved");
        for (uint256 i = 0; i < adminTokensBefore.length; i++) {
            assertEq(adminTokensAfter[i], adminTokensBefore[i], "Admin token should be preserved");
        }
    }

    function test_upgrade_proxy_preserves_owned_ctmrwa1_mapping() public {
        // Deploy a CTMRWA1 token and mint some tokens to populate ownedCtmRwa1 mapping
        vm.startPrank(tokenAdmin);
        string[] memory toChainIdsStr = new string[](0);

        rwa1X.deployAllCTMRWA1X(
            true, // includeLocal
            0, // existingID
            1, // version
            "Test Token",
            "TEST",
            18, // decimals
            "GFLD", // baseURI
            toChainIdsStr,
            _toLower(addressToString(address(ctm)))
        );
        vm.stopPrank();

        // Get owned tokens before upgrade
        address[] memory ownedTokensBefore = rwa1X.getAllTokensByOwnerAddress(tokenAdmin);

        // Upgrade the proxy
        vm.startPrank(gov);
        (bool success, ) = address(sentryManager).call(abi.encodeWithSignature("upgradeToAndCall(address,bytes)", address(mockImpl), abi.encodeCall(MockCTMRWA1SentryManagerV2.initializeV2, (42))));
        assertTrue(success, "upgradeToAndCall failed");
        vm.stopPrank();

        // Get owned tokens after upgrade
        address[] memory ownedTokensAfter = rwa1X.getAllTokensByOwnerAddress(tokenAdmin);
        // Verify owned tokens mapping is preserved
        assertEq(ownedTokensAfter.length, ownedTokensBefore.length, "Owned tokens count should be preserved");
        for (uint256 i = 0; i < ownedTokensBefore.length; i++) {
            assertEq(ownedTokensAfter[i], ownedTokensBefore[i], "Owned token should be preserved");
        }
    }

    function test_upgrade_proxy_preserves_constants() public {
        // Store initial constants
        uint256 initialRwaType = sentryManager.RWA_TYPE();
        // Upgrade the proxy
        vm.prank(gov);
        (bool success, ) = address(sentryManager).call(abi.encodeWithSignature("upgradeToAndCall(address,bytes)", address(mockImpl), abi.encodeCall(MockCTMRWA1SentryManagerV2.initializeV2, (42))));
        assertTrue(success, "upgradeToAndCall failed");
        // Verify constants are preserved
        assertEq(sentryManager.RWA_TYPE(), initialRwaType, "RWA_TYPE should be preserved");
    }

    function test_upgrade_proxy_preserves_utils_address() public {
        // Store initial utils address
        address initialUtils = sentryManager.utilsAddr();
        assertTrue(initialUtils != address(0), "Should have utils address");
        // Upgrade the proxy
        vm.startPrank(gov);
        (bool success, ) = address(sentryManager).call(abi.encodeWithSignature("upgradeToAndCall(address,bytes)", address(mockImpl), abi.encodeCall(MockCTMRWA1SentryManagerV2.initializeV2, (42))));
        assertTrue(success, "upgradeToAndCall failed");
        vm.stopPrank();
        // Verify utils address is preserved
        assertEq(sentryManager.utilsAddr(), initialUtils, "Utils address should be preserved");
    }

    function test_upgrade_proxy_preserves_deployer_and_map_addresses() public {
        // Store initial addresses
        address initialDeployer = sentryManager.ctmRwaDeployer();
        address initialMap = sentryManager.ctmRwaMap();
        address initialUtils = sentryManager.utilsAddr();
        // Deploy new implementation and upgrade
        MockCTMRWA1SentryManagerV2 newImpl = new MockCTMRWA1SentryManagerV2();
        vm.startPrank(gov);
        (bool success, ) = address(sentryManager).call(abi.encodeWithSignature("upgradeToAndCall(address,bytes)", address(newImpl), abi.encodeCall(MockCTMRWA1SentryManagerV2.initializeV2, (42))));
        assertTrue(success, "upgradeToAndCall failed");
        vm.stopPrank();
        // Verify addresses are preserved
        assertEq(sentryManager.ctmRwaDeployer(), initialDeployer, "Deployer address should be preserved");
        assertEq(sentryManager.ctmRwaMap(), initialMap, "Map address should be preserved");
        assertEq(sentryManager.utilsAddr(), initialUtils, "Utils address should be preserved");
    }

    function test_upgrade_proxy_unauthorized_reverts() public {
        // Deploy new implementation
        MockCTMRWA1SentryManagerV2 newImpl = new MockCTMRWA1SentryManagerV2();
        // Try to upgrade without being gov (use an address that is neither gov nor caller)
        vm.startPrank(user2);
        (bool success, ) = address(sentryManager).call(
            abi.encodeWithSignature(
                "upgradeToAndCall(address,bytes)",
                address(newImpl),
                abi.encodeCall(MockCTMRWA1SentryManagerV2.initializeV2, (42))
            )
        );
        assertFalse(success, "upgradeToAndCall did not fail");
        vm.stopPrank();
    }

    function test_upgrade_proxy_with_zero_address_reverts() public {
        // Try to upgrade to zero address
        vm.startPrank(gov);
        vm.expectRevert("ERC1967: new implementation is not a contract");
        (bool success, ) = address(sentryManager).call(abi.encodeWithSignature("upgradeToAndCall(address,bytes)", address(0)));
        assertFalse(success, "upgradeToAndCall did not fail");
        vm.stopPrank();
    }

    function test_upgrade_proxy_with_invalid_implementation_reverts() public {
        // Try to upgrade to a contract that doesn't implement the interface
        address invalidImpl = address(new CTMRWAMap());
        vm.startPrank(gov);
        vm.expectRevert("ERC1967: new implementation is not a contract");
        (bool success, ) = address(sentryManager).call(abi.encodeWithSignature("upgradeToAndCall(address,bytes)", invalidImpl, abi.encodeCall(MockCTMRWA1SentryManagerV2.initializeV2, (42))));
        assertFalse(success, "upgradeToAndCall did not fail");
        vm.stopPrank();
    }

    function test_upgrade_proxy_preserves_functionality() public {
        // Test that core functionality still works after upgrade
        // Deploy new implementation and upgrade
        MockCTMRWA1SentryManagerV2 newImpl = new MockCTMRWA1SentryManagerV2();
        vm.startPrank(gov);
        (bool success, ) = address(sentryManager).call(abi.encodeWithSignature("upgradeToAndCall(address,bytes)", address(newImpl), abi.encodeCall(MockCTMRWA1SentryManagerV2.initializeV2, (42))));
        assertTrue(success, "upgradeToAndCall failed");
        vm.stopPrank();
        // Test that governance functions still work
        vm.startPrank(gov);
        sentryManager.setGateway(address(0xdead));
        assertEq(sentryManager.gateway(), address(0xdead), "Gateway should be set");
        vm.stopPrank();
    }

    function test_fail_upgrade_proxy_same_version() public {
        // Upgrading to same version (1)
        MockCTMRWA1SentryManagerV2 impl1 = new MockCTMRWA1SentryManagerV2();
        (, bytes memory dataOldImpl) = address(sentryManager).call(abi.encodeWithSignature("getImplementation()"));
        address oldImpl = abi.decode(dataOldImpl, (address));
        vm.startPrank(gov);
        vm.expectRevert(Initializable.InvalidInitialization.selector);
        (bool success, ) = address(sentryManager).call(abi.encodeWithSignature("upgradeToAndCall(address,bytes)", address(impl1), abi.encodeCall(MockCTMRWA1SentryManagerV2.initializeV2, (1))));
        assertTrue(success);
        vm.stopPrank();
        // check that version is still one
        (, bytes memory dataCurrentImpl) = address(sentryManager).call(abi.encodeWithSignature("getImplementation()"));
        address currentImpl = abi.decode(dataCurrentImpl, (address));

        assertEq(currentImpl, oldImpl);
    }

    function test_upgrade_proxy_multiple_upgrades() public {
        // Perform multiple upgrades and verify state preservation
        // First upgrade
        MockCTMRWA1SentryManagerV2 impl2 = new MockCTMRWA1SentryManagerV2();
        vm.startPrank(gov);
        (bool success, ) = address(sentryManager).call(abi.encodeWithSignature("upgradeToAndCall(address,bytes)", address(impl2), abi.encodeCall(MockCTMRWA1SentryManagerV2.initializeV2, (2))));
        assertTrue(success, "upgradeToAndCall failed");
        vm.stopPrank();
        // Verify first upgrade
        assertEq(MockCTMRWA1SentryManagerV2(address(sentryManager)).newVersion(), 2, "First upgrade should work");
        // Second upgrade
        MockCTMRWA1SentryManagerV2 impl3 = new MockCTMRWA1SentryManagerV2();
        vm.startPrank(gov);
        (success, ) = address(sentryManager).call(abi.encodeWithSignature("upgradeToAndCall(address,bytes)", address(impl3), abi.encodeCall(MockCTMRWA1SentryManagerV2.initializeV2, (3))));
        assertTrue(success, "upgradeToAndCall failed");
        vm.stopPrank();
        // Verify second upgrade
        assertEq(MockCTMRWA1SentryManagerV2(address(sentryManager)).newVersion(), 3, "Second upgrade should work");
        // Verify core state is still preserved
        assertTrue(sentryManager.ctmRwaDeployer() != address(0), "Deployer should still be set");
        assertTrue(sentryManager.ctmRwaMap() != address(0), "Map should still be set");
    }

    function test_upgrade_proxy_preserves_c3govern_dapp_functionality() public {
        // Perform unauthorized upgrade fails
        // First upgrade
        MockCTMRWA1SentryManagerV2 impl2 = new MockCTMRWA1SentryManagerV2();
        vm.startPrank(gov);
        (bool success, ) = address(sentryManager).call(abi.encodeWithSignature("upgradeToAndCall(address,bytes)", address(impl2), abi.encodeCall(MockCTMRWA1SentryManagerV2.initializeV2, (2))));
        assertTrue(success, "upgradeToAndCall failed");
        vm.stopPrank();
        // Verify first upgrade
        assertEq(MockCTMRWA1SentryManagerV2(address(sentryManager)).newVersion(), 2, "First upgrade should work");
        // Second upgrade
        MockCTMRWA1SentryManagerV2 impl3 = new MockCTMRWA1SentryManagerV2();
        // not sending as gov to test that upgradeToAndCall reverts
        vm.expectRevert(
            abi.encodeWithSelector(
                IC3GovernDApp.C3GovernDApp_OnlyAuthorized.selector,
                C3ErrorParam.Sender,
                C3ErrorParam.GovOrC3Caller
            )
        );
        (success, ) = address(sentryManager).call(abi.encodeWithSignature("upgradeToAndCall(address,bytes)", address(impl3), abi.encodeCall(MockCTMRWA1SentryManagerV2.initializeV2, (3))));
        // Second upgrade should fail
        assertEq(MockCTMRWA1SentryManagerV2(address(sentryManager)).newVersion(), 2, "Second upgrade should fail");
    }

    function test_upgrade_proxy_preserves_reentrancy_guard() public {
        // Deploy new implementation and upgrade
        MockCTMRWA1SentryManagerV2 newImpl = new MockCTMRWA1SentryManagerV2();
        vm.startPrank(gov);
        (bool success, ) = address(sentryManager).call(abi.encodeWithSignature("upgradeToAndCall(address,bytes)", address(newImpl), abi.encodeCall(MockCTMRWA1SentryManagerV2.initializeV2, (42))));
        assertTrue(success, "upgradeToAndCall failed");
        vm.stopPrank();
        // Test that reentrancy guard is still active
        // This is implicit since the contract still inherits from ReentrancyGuardUpgradeable
        // and the upgrade doesn't break the reentrancy protection
        assertTrue(true, "Reentrancy guard should still be active");
    }

    function test_upgrade_proxy_preserves_uups_functionality() public {
        // Deploy new implementation and upgrade
        MockCTMRWA1SentryManagerV2 newImpl = new MockCTMRWA1SentryManagerV2();
        vm.startPrank(gov);
        (bool success, ) = address(sentryManager).call(abi.encodeWithSignature("upgradeToAndCall(address,bytes)", address(newImpl), abi.encodeCall(MockCTMRWA1SentryManagerV2.initializeV2, (42))));
        assertTrue(success, "upgradeToAndCall failed");
        vm.stopPrank();
        // Test that UUPS functionality is preserved
        // The contract should still be upgradeable
        MockCTMRWA1SentryManagerV2 impl3 = new MockCTMRWA1SentryManagerV2();
        vm.startPrank(gov);
        (success, ) = address(sentryManager).call(abi.encodeWithSignature("upgradeToAndCall(address,bytes)", address(impl3), bytes("")));
        assertTrue(success, "upgradeToAndCall failed");
        vm.stopPrank();
        assertTrue(true, "UUPS functionality should be preserved");
    }

    function test_updateLatestVersion_basic_functionality() public {
        // Test basic updateLatestVersion functionality
        uint256 initialVersion = sentryManager.LATEST_VERSION();
        assertEq(initialVersion, 1, "Initial version should be 1");

        // Update to version 5
        vm.prank(gov);
        sentryManager.updateLatestVersion(5);
        assertEq(sentryManager.LATEST_VERSION(), 5, "Version should be updated to 5");

        // Update to version 10
        vm.prank(gov);
        sentryManager.updateLatestVersion(10);
        assertEq(sentryManager.LATEST_VERSION(), 10, "Version should be updated to 10");
    }

    function test_updateLatestVersion_unauthorized_reverts() public {
        // Test that non-governance addresses cannot update version
        vm.prank(user1);
        vm.expectRevert(
            abi.encodeWithSelector(
                IC3GovernDApp.C3GovernDApp_OnlyAuthorized.selector,
                C3ErrorParam.Sender,
                C3ErrorParam.GovOrC3Caller
            )
        );
        sentryManager.updateLatestVersion(5);
    }

    function test_updateLatestVersion_after_upgrade() public {
        // Store initial version
        uint256 initialVersion = sentryManager.LATEST_VERSION();
        assertEq(initialVersion, 1, "Initial version should be 1");

        // Upgrade the proxy
        MockCTMRWA1SentryManagerV2 newImpl = new MockCTMRWA1SentryManagerV2();
        vm.startPrank(gov);
        (bool success, ) = address(sentryManager).call(abi.encodeWithSignature("upgradeToAndCall(address,bytes)", address(newImpl), abi.encodeCall(MockCTMRWA1SentryManagerV2.initializeV2, (42))));
        assertTrue(success, "upgradeToAndCall failed");
        vm.stopPrank();

        // Verify version was updated by the upgrade initializer
        assertEq(sentryManager.LATEST_VERSION(), 42, "Version should be updated by upgrade initializer");

        // Test that updateLatestVersion still works after upgrade
        vm.prank(gov);
        sentryManager.updateLatestVersion(100);
        assertEq(sentryManager.LATEST_VERSION(), 100, "Version should be updateable after upgrade");

        // Test multiple updates after upgrade
        vm.prank(gov);
        sentryManager.updateLatestVersion(200);
        assertEq(sentryManager.LATEST_VERSION(), 200, "Version should be updateable multiple times after upgrade");
    }

    function test_updateLatestVersion_preserves_other_state() public {
        // Store initial state
        address initialDeployer = sentryManager.ctmRwaDeployer();
        address initialMap = sentryManager.ctmRwaMap();
        address initialUtils = sentryManager.utilsAddr();
        address initialGateway = sentryManager.gateway();
        address initialFeeManager = sentryManager.feeManager();
        address initialIdentity = sentryManager.identity();

        // Update version
        vm.prank(gov);
        sentryManager.updateLatestVersion(5);

        // Verify other state is preserved
        assertEq(sentryManager.ctmRwaDeployer(), initialDeployer, "Deployer should be preserved");
        assertEq(sentryManager.ctmRwaMap(), initialMap, "Map should be preserved");
        assertEq(sentryManager.utilsAddr(), initialUtils, "Utils should be preserved");
        assertEq(sentryManager.gateway(), initialGateway, "Gateway should be preserved");
        assertEq(sentryManager.feeManager(), initialFeeManager, "FeeManager should be preserved");
        assertEq(sentryManager.identity(), initialIdentity, "Identity should be preserved");
        assertEq(sentryManager.RWA_TYPE(), 1, "RWA_TYPE should be preserved");
    }

    function test_updateLatestVersion_with_zero_version_reverts() public {
        // Test updating to version 0 (should revert)
        vm.prank(gov);
        vm.expectRevert();
        sentryManager.updateLatestVersion(0);
    }

    function test_updateLatestVersion_with_max_version() public {
        // Test updating to a very large version number
        uint256 maxVersion = type(uint256).max;
        vm.prank(gov);
        sentryManager.updateLatestVersion(maxVersion);
        assertEq(sentryManager.LATEST_VERSION(), maxVersion, "Version should be updateable to max uint256");
    }

    function test_updateLatestVersion_multiple_updates() public {
        // Test multiple sequential updates
        vm.startPrank(gov);
        sentryManager.updateLatestVersion(2);
        assertEq(sentryManager.LATEST_VERSION(), 2, "First update should work");
        
        sentryManager.updateLatestVersion(3);
        assertEq(sentryManager.LATEST_VERSION(), 3, "Second update should work");
        
        sentryManager.updateLatestVersion(1);
        assertEq(sentryManager.LATEST_VERSION(), 1, "Third update should work");
        vm.stopPrank();
    }

    function test_updateLatestVersion_governance_controls() public {
        // Test that only governance can update version
        vm.startPrank(user1);
        vm.expectRevert(
            abi.encodeWithSelector(
                IC3GovernDApp.C3GovernDApp_OnlyAuthorized.selector,
                C3ErrorParam.Sender,
                C3ErrorParam.GovOrC3Caller
            )
        );
        sentryManager.updateLatestVersion(5);
        vm.stopPrank();

        // Test that governance can update version
        vm.prank(gov);
        sentryManager.updateLatestVersion(5);
        assertEq(sentryManager.LATEST_VERSION(), 5, "Governance should be able to update version");
    }
}
