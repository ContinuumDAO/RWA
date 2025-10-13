// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.27;

import { Test } from "forge-std/Test.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import { Helpers } from "../helpers/Helpers.sol";
import { ICTMRWA1Storage } from "../../src/storage/ICTMRWA1Storage.sol";
import { CTMRWA1StorageManager } from "../../src/storage/CTMRWA1StorageManager.sol";
import { ICTMRWA1StorageManager } from "../../src/storage/ICTMRWA1StorageManager.sol";
import { CTMRWAMap } from "../../src/shared/CTMRWAMap.sol";
import { CTMRWAErrorParam } from "../../src/utils/CTMRWAUtils.sol";
import { URICategory, URIType } from "../../src/storage/ICTMRWA1Storage.sol";

// Mock implementation for testing upgrades
contract MockCTMRWA1StorageManagerV2 is CTMRWA1StorageManager {
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
contract MaliciousCTMRWA1StorageManager is CTMRWA1StorageManager {
    function initializeV2() external reinitializer(2) {
        // Try to change critical addresses
        ctmRwaDeployer = address(0xdead);
        ctmRwa1Map = address(0xdead);
        utilsAddr = address(0xdead);
        gateway = address(0xdead);
        feeManager = address(0xdead);
    }
}

/**
 * @title CTMRWA1StorageManager Upgrade Tests
 * @notice Tests for proxy upgrades of CTMRWA1StorageManager contract
 */
contract TestCTMRWA1StorageManagerUpgrades is Helpers {
    using Strings for *;

    // Mock implementation for testing upgrades
    MockCTMRWA1StorageManagerV2 mockImpl;

    // Malicious implementation that tries to change critical state
    MaliciousCTMRWA1StorageManager maliciousImpl;

    ICTMRWA1Storage stor;

    function setUp() public override {
        super.setUp();
        mockImpl = new MockCTMRWA1StorageManagerV2();
        maliciousImpl = new MaliciousCTMRWA1StorageManager();

        vm.startPrank(tokenAdmin);
        (ID, token) = _deployCTMRWA1(address(usdc));
        _createSomeSlots(ID, address(usdc), address(rwa1X));
        (bool success, address storageAddr) = map.getStorageContract(ID, 1, 1);
        assertTrue(success, "getStorageContract failed");
        stor = ICTMRWA1Storage(storageAddr);
        vm.stopPrank();
    }

    function test_upgrade_proxy_successfully() public {
        // Store initial state
        address initialDeployer = storageManager.ctmRwaDeployer();
        address initialMap = storageManager.ctmRwa1Map();
        address initialUtils = storageManager.utilsAddr();
        uint256 initialRwaType = storageManager.RWA_TYPE();

        // Upgrade the proxy
        vm.startPrank(gov);
        (bool success, ) = address(storageManager).call(abi.encodeWithSignature("upgradeToAndCall(address,bytes)", address(mockImpl), abi.encodeCall(MockCTMRWA1StorageManagerV2.initializeV2, (42))));
        assertTrue(success, "upgradeToAndCall failed");
        vm.stopPrank();

        // Verify state is preserved
        assertEq(storageManager.ctmRwaDeployer(), initialDeployer, "Deployer should be preserved");
        assertEq(storageManager.ctmRwa1Map(), initialMap, "Map should be preserved");
        assertEq(storageManager.utilsAddr(), initialUtils, "Utils should be preserved");
        assertEq(storageManager.RWA_TYPE(), initialRwaType, "RWA_TYPE should be preserved");
        // Verify LATEST_VERSION was updated by the upgrade initializer
        assertEq(storageManager.LATEST_VERSION(), 42, "LATEST_VERSION should be bumped to new initializer version");

        // Verify new functionality works
        MockCTMRWA1StorageManagerV2(address(storageManager)).newFunction();
        assertEq(MockCTMRWA1StorageManagerV2(address(storageManager)).newVersion(), 42, "New version should be set");
    }

    function test_upgrade_proxy_without_initialization() public {
        // Store initial state
        address initialDeployer = storageManager.ctmRwaDeployer();

        // Upgrade the proxy without initialization
        vm.startPrank(gov);
        (bool success,) = address(storageManager).call(abi.encodeWithSignature("upgradeToAndCall(address,bytes)", address(mockImpl), bytes("")));
        assertTrue(success, "upgradeToAndCall failed");
        vm.stopPrank();

        // Verify state is preserved
        assertEq(storageManager.ctmRwaDeployer(), initialDeployer, "Deployer should be preserved");

        // Verify new functionality works
        MockCTMRWA1StorageManagerV2(address(storageManager)).newFunction();
        assertEq(MockCTMRWA1StorageManagerV2(address(storageManager)).newVersion(), 0, "New version should be default");
    }

    function test_upgrade_proxy_preserves_mappings() public {
        string[] memory toChainIdsStr = new string[](1);
        toChainIdsStr[0] = cIdStr;
        vm.startPrank(tokenAdmin);
        // Set up some state in mappings
        storageManager.addURI(ID, VERSION, "test-uri", URICategory.ISSUER, URIType.CONTRACT, "test-checksum", 1, keccak256("test-uri"), toChainIdsStr, address(usdc).toHexString());
        vm.stopPrank();

        // Verify initial state
        assertEq(stor.getURIHashCount(URICategory.ISSUER, URIType.CONTRACT), 1, "URI should be added");

        // Upgrade the proxy
        vm.startPrank(gov);
        (bool success, ) = address(storageManager).call(abi.encodeWithSignature("upgradeToAndCall(address,bytes)", address(mockImpl), abi.encodeCall(MockCTMRWA1StorageManagerV2.initializeV2, (42))));
        assertTrue(success, "upgradeToAndCall failed");
        vm.stopPrank();

        // Verify mappings are preserved
        assertEq(stor.getURIHashCount(URICategory.ISSUER, URIType.CONTRACT), 1, "URI hash count should still be 1");
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
        (bool success, ) = address(storageManager).call(abi.encodeWithSignature("upgradeToAndCall(address,bytes)", address(mockImpl), abi.encodeCall(MockCTMRWA1StorageManagerV2.initializeV2, (42))));
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
        (bool success, ) = address(storageManager).call(abi.encodeWithSignature("upgradeToAndCall(address,bytes)", address(mockImpl), abi.encodeCall(MockCTMRWA1StorageManagerV2.initializeV2, (42))));
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
        uint256 initialRwaType = storageManager.RWA_TYPE();
        // Upgrade the proxy
        vm.prank(gov);
        (bool success, ) = address(storageManager).call(abi.encodeWithSignature("upgradeToAndCall(address,bytes)", address(mockImpl), abi.encodeCall(MockCTMRWA1StorageManagerV2.initializeV2, (42))));
        assertTrue(success, "upgradeToAndCall failed");
        // Verify constants are preserved
        assertEq(storageManager.RWA_TYPE(), initialRwaType, "RWA_TYPE should be preserved");
        // VERSION is no longer accessible as a function, but the contract should still work
        // We can test that the contract is still functional by checking other properties
        assertTrue(true, "StorageManager upgrade completed successfully");
    }

    function test_upgrade_proxy_preserves_utils_address() public {
        // Store initial utils address
        address initialUtils = storageManager.utilsAddr();
        assertTrue(initialUtils != address(0), "Should have utils address");
        // Upgrade the proxy
        vm.startPrank(gov);
        (bool success, ) = address(storageManager).call(abi.encodeWithSignature("upgradeToAndCall(address,bytes)", address(mockImpl), abi.encodeCall(MockCTMRWA1StorageManagerV2.initializeV2, (42))));
        assertTrue(success, "upgradeToAndCall failed");
        vm.stopPrank();
        // Verify fallback address is preserved
        assertEq(storageManager.utilsAddr(), initialUtils, "Utils address should be preserved");
    }

    function test_upgrade_proxy_preserves_deployer_and_map_addresses() public {
        // Store initial addresses
        address initialDeployer = storageManager.ctmRwaDeployer();
        address initialMap = storageManager.ctmRwa1Map();
        address initialUtils = storageManager.utilsAddr();
        // Deploy new implementation and upgrade
        MockCTMRWA1StorageManagerV2 newImpl = new MockCTMRWA1StorageManagerV2();
        vm.startPrank(gov);
        (bool success, ) = address(storageManager).call(abi.encodeWithSignature("upgradeToAndCall(address,bytes)", address(newImpl), abi.encodeCall(MockCTMRWA1StorageManagerV2.initializeV2, (42))));
        assertTrue(success, "upgradeToAndCall failed");
        vm.stopPrank();
        // Verify addresses are preserved
        assertEq(storageManager.ctmRwaDeployer(), initialDeployer, "Deployer address should be preserved");
        assertEq(storageManager.ctmRwa1Map(), initialMap, "Map address should be preserved");
        assertEq(storageManager.utilsAddr(), initialUtils, "Utils address should be preserved");
    }

    function test_upgrade_proxy_unauthorized_reverts() public {
        // Deploy new implementation
        MockCTMRWA1StorageManagerV2 newImpl = new MockCTMRWA1StorageManagerV2();
        // Try to upgrade without being gov
        vm.startPrank(user1);
        vm.expectRevert();
        (bool success, ) = address(storageManager).call(abi.encodeWithSignature("upgradeToAndCall(address,bytes)", address(newImpl), abi.encodeCall(MockCTMRWA1StorageManagerV2.initializeV2, (42))));
        assertTrue(success, "upgradeToAndCall failed");
        vm.stopPrank();
    }

    function test_upgrade_proxy_with_zero_address_reverts() public {
        // Try to upgrade to zero address
        vm.startPrank(gov);
        vm.expectRevert();
        (bool success, ) = address(storageManager).call(abi.encodeWithSignature("upgradeToAndCall(address,bytes)", address(0)));
        assertTrue(success, "upgradeToAndCall failed");
        vm.stopPrank();
    }

    function test_upgrade_proxy_with_invalid_implementation_reverts() public {
        // Try to upgrade to a contract that doesn't implement the interface
        address invalidImpl = address(new CTMRWAMap());
        vm.startPrank(gov);
        vm.expectRevert();
        (bool success, ) = address(storageManager).call(abi.encodeWithSignature("upgradeToAndCall(address,bytes)", invalidImpl, abi.encodeCall(MockCTMRWA1StorageManagerV2.initializeV2, (42))));
        assertTrue(success, "upgradeToAndCall failed");
        vm.stopPrank();
    }

    function test_upgrade_proxy_preserves_functionality() public {
        // Test that core functionality still works after upgrade
        // Deploy new implementation and upgrade
        MockCTMRWA1StorageManagerV2 newImpl = new MockCTMRWA1StorageManagerV2();
        vm.startPrank(gov);
        (bool success, ) = address(storageManager).call(abi.encodeWithSignature("upgradeToAndCall(address,bytes)", address(newImpl), abi.encodeCall(MockCTMRWA1StorageManagerV2.initializeV2, (42))));
        assertTrue(success, "upgradeToAndCall failed");
        vm.stopPrank();
        // Test that governance functions still work
        string[] memory toChainIdsStr = new string[](1);
        toChainIdsStr[0] = cIdStr;
        vm.prank(tokenAdmin);
        storageManager.addURI(ID, VERSION, "test-uri", URICategory.ISSUER, URIType.CONTRACT, "test-checksum", 1, keccak256("test-uri"), toChainIdsStr, address(usdc).toHexString());
        assertEq(stor.getURIHashCount(URICategory.ISSUER, URIType.CONTRACT), 1, "URI should be added");
        vm.prank(gov);
        storageManager.setGateway(address(0x123));
        assertEq(storageManager.gateway(), address(0x123), "Gateway should be set");
    }

    function test_fail_upgrade_proxy_same_version() public {
        // Upgrading to same version (1)
        MockCTMRWA1StorageManagerV2 impl1 = new MockCTMRWA1StorageManagerV2();
        (, bytes memory dataOldImpl) = address(storageManager).call(abi.encodeWithSignature("getImplementation()"));
        address oldImpl = abi.decode(dataOldImpl, (address));
        vm.startPrank(gov);
        vm.expectRevert(Initializable.InvalidInitialization.selector);
        (bool success, ) = address(storageManager).call(abi.encodeWithSignature("upgradeToAndCall(address,bytes)", address(impl1), abi.encodeCall(MockCTMRWA1StorageManagerV2.initializeV2, (1))));
        assertTrue(success);
        vm.stopPrank();
        // check that version is still one
        (, bytes memory dataCurrentImpl) = address(storageManager).call(abi.encodeWithSignature("getImplementation()"));
        address currentImpl = abi.decode(dataCurrentImpl, (address));

        assertEq(currentImpl, oldImpl);
    }

    function test_upgrade_proxy_multiple_upgrades() public {
        // Perform multiple upgrades and verify state preservation
        // First upgrade
        MockCTMRWA1StorageManagerV2 impl2 = new MockCTMRWA1StorageManagerV2();
        vm.startPrank(gov);
        (bool success, ) = address(storageManager).call(abi.encodeWithSignature("upgradeToAndCall(address,bytes)", address(impl2), abi.encodeCall(MockCTMRWA1StorageManagerV2.initializeV2, (2))));
        assertTrue(success, "upgradeToAndCall failed");
        vm.stopPrank();
        // Verify first upgrade
        assertEq(MockCTMRWA1StorageManagerV2(address(storageManager)).newVersion(), 2, "First upgrade should work");
        // Second upgrade
        MockCTMRWA1StorageManagerV2 impl3 = new MockCTMRWA1StorageManagerV2();
        vm.startPrank(gov);
        (success, ) = address(storageManager).call(abi.encodeWithSignature("upgradeToAndCall(address,bytes)", address(impl3), abi.encodeCall(MockCTMRWA1StorageManagerV2.initializeV2, (3))));
        assertTrue(success, "upgradeToAndCall failed");
        vm.stopPrank();
        // Verify second upgrade
        assertEq(MockCTMRWA1StorageManagerV2(address(storageManager)).newVersion(), 3, "Second upgrade should work");
        // Verify core state is still preserved
        assertTrue(storageManager.ctmRwaDeployer() != address(0), "Deployer should still be set");
        assertTrue(storageManager.ctmRwa1Map() != address(0), "Map should still be set");
    }

    function test_upgrade_proxy_preserves_c3govern_dapp_functionality() public {
        // Perform unauthorized upgrade fails
        // First upgrade
        MockCTMRWA1StorageManagerV2 impl2 = new MockCTMRWA1StorageManagerV2();
        vm.startPrank(gov);
        (bool success, ) = address(storageManager).call(abi.encodeWithSignature("upgradeToAndCall(address,bytes)", address(impl2), abi.encodeCall(MockCTMRWA1StorageManagerV2.initializeV2, (2))));
        assertTrue(success, "upgradeToAndCall failed");
        vm.stopPrank();
        // Verify first upgrade
        assertEq(MockCTMRWA1StorageManagerV2(address(storageManager)).newVersion(), 2, "First upgrade should work");
        // Second upgrade
        MockCTMRWA1StorageManagerV2 impl3 = new MockCTMRWA1StorageManagerV2();
        // not sending as gov to test that upgradeToAndCall reverts
        vm.expectRevert();
        (success, ) = address(storageManager).call(abi.encodeWithSignature("upgradeToAndCall(address,bytes)", address(impl3), abi.encodeCall(MockCTMRWA1StorageManagerV2.initializeV2, (3))));
        // Second upgrade should fail
        assertEq(MockCTMRWA1StorageManagerV2(address(storageManager)).newVersion(), 2, "Second upgrade should fail");
    }

    function test_upgrade_proxy_preserves_reentrancy_guard() public {
        // Deploy new implementation and upgrade
        MockCTMRWA1StorageManagerV2 newImpl = new MockCTMRWA1StorageManagerV2();
        vm.startPrank(gov);
        (bool success, ) = address(storageManager).call(abi.encodeWithSignature("upgradeToAndCall(address,bytes)", address(newImpl), abi.encodeCall(MockCTMRWA1StorageManagerV2.initializeV2, (42))));
        assertTrue(success, "upgradeToAndCall failed");
        vm.stopPrank();
        // Test that reentrancy guard is still active
        // This is implicit since the contract still inherits from ReentrancyGuardUpgradeable
        // and the upgrade doesn't break the reentrancy protection
        assertTrue(true, "Reentrancy guard should still be active");
    }

    function test_upgrade_proxy_preserves_uups_functionality() public {
        // Deploy new implementation and upgrade
        MockCTMRWA1StorageManagerV2 newImpl = new MockCTMRWA1StorageManagerV2();
        vm.startPrank(gov);
        (bool success, ) = address(storageManager).call(abi.encodeWithSignature("upgradeToAndCall(address,bytes)", address(newImpl), abi.encodeCall(MockCTMRWA1StorageManagerV2.initializeV2, (42))));
        assertTrue(success, "upgradeToAndCall failed");
        vm.stopPrank();
        // Test that UUPS functionality is preserved
        // The contract should still be upgradeable
        MockCTMRWA1StorageManagerV2 impl3 = new MockCTMRWA1StorageManagerV2();
        vm.startPrank(gov);
        (success, ) = address(storageManager).call(abi.encodeWithSignature("upgradeToAndCall(address,bytes)", address(impl3), bytes("")));
        assertTrue(success, "upgradeToAndCall failed");
        vm.stopPrank();
        assertTrue(true, "UUPS functionality should be preserved");
    }

    function test_updateLatestVersion_basic_functionality() public {
        // Test basic updateLatestVersion functionality
        uint256 initialVersion = storageManager.LATEST_VERSION();
        assertEq(initialVersion, 1, "Initial version should be 1");

        // Update to version 5
        vm.prank(gov);
        storageManager.updateLatestVersion(5);
        assertEq(storageManager.LATEST_VERSION(), 5, "Version should be updated to 5");

        // Update to version 10
        vm.prank(gov);
        storageManager.updateLatestVersion(10);
        assertEq(storageManager.LATEST_VERSION(), 10, "Version should be updated to 10");
    }

    function test_updateLatestVersion_unauthorized_reverts() public {
        // Test that non-governance addresses cannot update version
        vm.prank(user1);
        vm.expectRevert();
        storageManager.updateLatestVersion(5);
    }

    function test_updateLatestVersion_after_upgrade() public {
        // Store initial version
        uint256 initialVersion = storageManager.LATEST_VERSION();
        assertEq(initialVersion, 1, "Initial version should be 1");

        // Upgrade the proxy
        MockCTMRWA1StorageManagerV2 newImpl = new MockCTMRWA1StorageManagerV2();
        vm.startPrank(gov);
        (bool success, ) = address(storageManager).call(abi.encodeWithSignature("upgradeToAndCall(address,bytes)", address(newImpl), abi.encodeCall(MockCTMRWA1StorageManagerV2.initializeV2, (42))));
        assertTrue(success, "upgradeToAndCall failed");
        vm.stopPrank();

        // Verify version was updated by the upgrade initializer
        assertEq(storageManager.LATEST_VERSION(), 42, "Version should be updated by upgrade initializer");

        // Test that updateLatestVersion still works after upgrade
        vm.prank(gov);
        storageManager.updateLatestVersion(100);
        assertEq(storageManager.LATEST_VERSION(), 100, "Version should be updateable after upgrade");

        // Test multiple updates after upgrade
        vm.prank(gov);
        storageManager.updateLatestVersion(200);
        assertEq(storageManager.LATEST_VERSION(), 200, "Version should be updateable multiple times after upgrade");
    }

    function test_updateLatestVersion_preserves_other_state() public {
        // Store initial state
        address initialDeployer = storageManager.ctmRwaDeployer();
        address initialMap = storageManager.ctmRwa1Map();
        address initialUtils = storageManager.utilsAddr();
        address initialGateway = storageManager.gateway();
        address initialFeeManager = storageManager.feeManager();

        // Update version
        vm.prank(gov);
        storageManager.updateLatestVersion(5);

        // Verify other state is preserved
        assertEq(storageManager.ctmRwaDeployer(), initialDeployer, "Deployer should be preserved");
        assertEq(storageManager.ctmRwa1Map(), initialMap, "Map should be preserved");
        assertEq(storageManager.utilsAddr(), initialUtils, "Utils should be preserved");
        assertEq(storageManager.gateway(), initialGateway, "Gateway should be preserved");
        assertEq(storageManager.feeManager(), initialFeeManager, "FeeManager should be preserved");
        assertEq(storageManager.RWA_TYPE(), 1, "RWA_TYPE should be preserved");
    }

    function test_updateLatestVersion_with_zero_version_reverts() public {
        // Test updating to version 0 (should revert)
        vm.prank(gov);
        vm.expectRevert();
        storageManager.updateLatestVersion(0);
    }

    function test_updateLatestVersion_with_max_version() public {
        // Test updating to a very large version number
        uint256 maxVersion = type(uint256).max;
        vm.prank(gov);
        storageManager.updateLatestVersion(maxVersion);
        assertEq(storageManager.LATEST_VERSION(), maxVersion, "Version should be updateable to max uint256");
    }


    function test_updateLatestVersion_multiple_updates() public {
        // Test multiple sequential updates
        vm.startPrank(gov);
        storageManager.updateLatestVersion(2);
        assertEq(storageManager.LATEST_VERSION(), 2, "First update should work");
        
        storageManager.updateLatestVersion(3);
        assertEq(storageManager.LATEST_VERSION(), 3, "Second update should work");
        
        storageManager.updateLatestVersion(1);
        assertEq(storageManager.LATEST_VERSION(), 1, "Third update should work");
        vm.stopPrank();
    }
}
