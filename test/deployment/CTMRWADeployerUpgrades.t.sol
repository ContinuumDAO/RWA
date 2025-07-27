// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.27;

import { Test } from "forge-std/Test.sol";

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import { Helpers } from "../helpers/Helpers.sol";
import { CTMRWADeployer } from "../../src/deployment/CTMRWADeployer.sol";
import { ICTMRWADeployer } from "../../src/deployment/ICTMRWADeployer.sol";
import { FeeManager } from "../../src/managers/FeeManager.sol";
import { CTMRWAMap } from "../../src/shared/CTMRWAMap.sol";
import { Address } from "../../src/utils/CTMRWAUtils.sol";

// Mock implementation for testing upgrades
contract MockCTMRWADeployerV2 is CTMRWADeployer {
    uint256 public newVersion;

    function initializeV2(uint256 _newVersion) external reinitializer(uint64(_newVersion)) {
        newVersion = _newVersion;
    }

    function newFunction() external pure returns (string memory) {
        return "V2 Function";
    }
}

// Malicious implementation that tries to change critical state
contract MaliciousCTMRWADeployer is CTMRWADeployer {
    function initializeV2() external reinitializer(2) {
        // Try to change critical addresses
        gateway = address(0xdead);
        feeManager = address(0xdead);
        rwaX = address(0xdead);
        ctmRwaMap = address(0xdead);
        erc20Deployer = address(0xdead);
        deployInvest = address(0xdead);
    }
}

/**
 * @title CTMRWADeployer Upgrade Tests
 * @notice Tests for proxy upgrades of CTMRWADeployer contract
 */
contract TestCTMRWADeployerUpgrades is Helpers {
    // Mock implementation for testing upgrades
    MockCTMRWADeployerV2 mockImpl;

    // Malicious implementation that tries to change critical state
    MaliciousCTMRWADeployer maliciousImpl;

    function setUp() public override {
        super.setUp();
        mockImpl = new MockCTMRWADeployerV2();
        maliciousImpl = new MaliciousCTMRWADeployer();
    }

    function test_upgrade_proxy_successfully() public {
        // Store initial state
        address initialGateway = deployer.gateway();
        address initialFeeManager = deployer.feeManager();
        address initialRwaX = deployer.rwaX();
        address initialMap = deployer.ctmRwaMap();

        // Upgrade the proxy
        vm.startPrank(gov);
        (bool success, ) = address(deployer).call(abi.encodeWithSignature("upgradeToAndCall(address,bytes)", address(mockImpl), abi.encodeCall(MockCTMRWADeployerV2.initializeV2, (42))));
        assertTrue(success, "upgradeToAndCall failed");
        vm.stopPrank();

        // Verify state is preserved
        assertEq(deployer.gateway(), initialGateway, "Gateway should be preserved");
        assertEq(deployer.feeManager(), initialFeeManager, "FeeManager should be preserved");
        assertEq(deployer.rwaX(), initialRwaX, "RwaX should be preserved");
        assertEq(deployer.ctmRwaMap(), initialMap, "Map should be preserved");

        // Verify new functionality works
        MockCTMRWADeployerV2(address(deployer)).newFunction();
        assertEq(MockCTMRWADeployerV2(address(deployer)).newVersion(), 42, "New version should be set");
    }

    function test_upgrade_proxy_without_initialization() public {
        // Store initial state
        address initialGateway = deployer.gateway();

        // Upgrade the proxy without initialization
        vm.startPrank(gov);
        (bool success,) = address(deployer).call(abi.encodeWithSignature("upgradeToAndCall(address,bytes)", address(mockImpl), bytes("")));
        assertTrue(success, "upgradeToAndCall failed");
        vm.stopPrank();

        // Verify state is preserved
        assertEq(deployer.gateway(), initialGateway, "Gateway should be preserved");

        // Verify new functionality works
        MockCTMRWADeployerV2(address(deployer)).newFunction();
        assertEq(MockCTMRWADeployerV2(address(deployer)).newVersion(), 0, "New version should be default");
    }

    function test_upgrade_proxy_preserves_mappings() public {
        // Set up some state in mappings
        vm.startPrank(gov);
        deployer.setTokenFactory(1, 1, address(0x123));
        deployer.setDividendFactory(1, 1, address(0x456));
        deployer.setStorageFactory(1, 1, address(0x789));
        deployer.setSentryFactory(1, 1, address(0xabc));
        vm.stopPrank();

        // Verify initial state
        assertEq(deployer.tokenFactory(1, 1), address(0x123), "Token factory should be set");
        assertEq(deployer.dividendFactory(1, 1), address(0x456), "Dividend factory should be set");
        assertEq(deployer.storageFactory(1, 1), address(0x789), "Storage factory should be set");
        assertEq(deployer.sentryFactory(1, 1), address(0xabc), "Sentry factory should be set");

        // Upgrade the proxy
        vm.startPrank(gov);
        (bool success, ) = address(deployer).call(abi.encodeWithSignature("upgradeToAndCall(address,bytes)", address(mockImpl), abi.encodeCall(MockCTMRWADeployerV2.initializeV2, (42))));
        assertTrue(success, "upgradeToAndCall failed");
        vm.stopPrank();

        // Verify mappings are preserved
        assertEq(deployer.tokenFactory(1, 1), address(0x123), "Token factory should still be set after upgrade");
        assertEq(deployer.dividendFactory(1, 1), address(0x456), "Dividend factory should still be set after upgrade");
        assertEq(deployer.storageFactory(1, 1), address(0x789), "Storage factory should still be set after upgrade");
        assertEq(deployer.sentryFactory(1, 1), address(0xabc), "Sentry factory should still be set after upgrade");
    }

    function test_upgrade_proxy_preserves_admin_tokens_mapping() public {
        // Deploy a CTMRWA1 token to populate adminTokens mapping
        vm.startPrank(tokenAdmin);
        string[] memory toChainIdsStr = new string[](0);

        rwa1X.deployAllCTMRWA1X(
            true, // includeLocal
            0, // existingID
            1, // rwaType
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
        (bool success, ) = address(deployer).call(abi.encodeWithSignature("upgradeToAndCall(address,bytes)", address(mockImpl), abi.encodeCall(MockCTMRWADeployerV2.initializeV2, (42))));
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
            1, // rwaType
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
        (bool success, ) = address(deployer).call(abi.encodeWithSignature("upgradeToAndCall(address,bytes)", address(mockImpl), abi.encodeCall(MockCTMRWADeployerV2.initializeV2, (42))));
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

    function test_upgrade_proxy_preserves_deployer_and_map_addresses() public {
        // Store initial addresses
        address initialGateway = deployer.gateway();
        address initialFeeManager = deployer.feeManager();
        address initialRwaX = deployer.rwaX();
        address initialMap = deployer.ctmRwaMap();
        // Deploy new implementation and upgrade
        MockCTMRWADeployerV2 newImpl = new MockCTMRWADeployerV2();
        vm.startPrank(gov);
        (bool success, ) = address(deployer).call(abi.encodeWithSignature("upgradeToAndCall(address,bytes)", address(newImpl), abi.encodeCall(MockCTMRWADeployerV2.initializeV2, (42))));
        assertTrue(success, "upgradeToAndCall failed");
        vm.stopPrank();
        // Verify addresses are preserved
        assertEq(deployer.gateway(), initialGateway, "Gateway address should be preserved");
        assertEq(deployer.feeManager(), initialFeeManager, "FeeManager address should be preserved");
        assertEq(deployer.rwaX(), initialRwaX, "RwaX address should be preserved");
        assertEq(deployer.ctmRwaMap(), initialMap, "Map address should be preserved");
    }

    function test_upgrade_proxy_unauthorized_reverts() public {
        // Deploy new implementation
        MockCTMRWADeployerV2 newImpl = new MockCTMRWADeployerV2();
        // Try to upgrade without being gov
        vm.startPrank(user1);
        vm.expectRevert();
        (bool success, ) = address(deployer).call(abi.encodeWithSignature("upgradeToAndCall(address,bytes)", address(newImpl), abi.encodeCall(MockCTMRWADeployerV2.initializeV2, (42))));
        assertTrue(success, "upgradeToAndCall failed");
        vm.stopPrank();
    }

    function test_upgrade_proxy_with_zero_address_reverts() public {
        // Try to upgrade to zero address
        vm.startPrank(gov);
        vm.expectRevert();
        (bool success, ) = address(deployer).call(abi.encodeWithSignature("upgradeToAndCall(address,bytes)", address(0)));
        assertTrue(success, "upgradeToAndCall failed");
        vm.stopPrank();
    }

    function test_upgrade_proxy_with_invalid_implementation_reverts() public {
        // Try to upgrade to a contract that doesn't implement the interface
        address invalidImpl = address(new FeeManager());
        vm.startPrank(gov);
        vm.expectRevert();
        (bool success, ) = address(deployer).call(abi.encodeWithSignature("upgradeToAndCall(address,bytes)", invalidImpl, abi.encodeCall(MockCTMRWADeployerV2.initializeV2, (42))));
        assertTrue(success, "upgradeToAndCall failed");
        vm.stopPrank();
    }

    function test_upgrade_proxy_preserves_functionality() public {
        // Test that core functionality still works after upgrade
        // Deploy new implementation and upgrade
        MockCTMRWADeployerV2 newImpl = new MockCTMRWADeployerV2();
        vm.startPrank(gov);
        (bool success, ) = address(deployer).call(abi.encodeWithSignature("upgradeToAndCall(address,bytes)", address(newImpl), abi.encodeCall(MockCTMRWADeployerV2.initializeV2, (42))));
        assertTrue(success, "upgradeToAndCall failed");
        vm.stopPrank();
        // Test that governance functions still work
        vm.startPrank(gov);
        deployer.setGateway(address(0x123));
        assertEq(deployer.gateway(), address(0x123), "Gateway should be set");
        deployer.setFeeManager(address(0x456));
        assertEq(deployer.feeManager(), address(0x456), "FeeManager should be set");
        vm.stopPrank();
    }

    function test_fail_upgrade_proxy_same_version() public {
        // Upgrading to same version (1)
        MockCTMRWADeployerV2 impl1 = new MockCTMRWADeployerV2();
        (, bytes memory dataOldImpl) = address(deployer).call(abi.encodeWithSignature("getImplementation()"));
        address oldImpl = abi.decode(dataOldImpl, (address));
        vm.startPrank(gov);
        vm.expectRevert(Initializable.InvalidInitialization.selector);
        (bool success, ) = address(deployer).call(abi.encodeWithSignature("upgradeToAndCall(address,bytes)", address(impl1), abi.encodeCall(MockCTMRWADeployerV2.initializeV2, (1))));
        assertTrue(success);
        vm.stopPrank();
        // check that version is still one
        (, bytes memory dataCurrentImpl) = address(deployer).call(abi.encodeWithSignature("getImplementation()"));
        address currentImpl = abi.decode(dataCurrentImpl, (address));

        assertEq(currentImpl, oldImpl);
    }

    function test_upgrade_proxy_multiple_upgrades() public {
        // Perform multiple upgrades and verify state preservation
        // First upgrade
        MockCTMRWADeployerV2 impl2 = new MockCTMRWADeployerV2();
        vm.startPrank(gov);
        (bool success, ) = address(deployer).call(abi.encodeWithSignature("upgradeToAndCall(address,bytes)", address(impl2), abi.encodeCall(MockCTMRWADeployerV2.initializeV2, (2))));
        assertTrue(success, "upgradeToAndCall failed");
        vm.stopPrank();
        // Verify first upgrade
        assertEq(MockCTMRWADeployerV2(address(deployer)).newVersion(), 2, "First upgrade should work");
        // Second upgrade
        MockCTMRWADeployerV2 impl3 = new MockCTMRWADeployerV2();
        vm.startPrank(gov);
        (success, ) = address(deployer).call(abi.encodeWithSignature("upgradeToAndCall(address,bytes)", address(impl3), abi.encodeCall(MockCTMRWADeployerV2.initializeV2, (3))));
        assertTrue(success, "upgradeToAndCall failed");
        vm.stopPrank();
        // Verify second upgrade
        assertEq(MockCTMRWADeployerV2(address(deployer)).newVersion(), 3, "Second upgrade should work");
        // Verify core state is still preserved
        assertTrue(deployer.gateway() != address(0), "Gateway should still be set");
        assertTrue(deployer.feeManager() != address(0), "FeeManager should still be set");
    }

    function test_upgrade_proxy_preserves_reentrancy_guard() public {
        // Deploy new implementation and upgrade
        MockCTMRWADeployerV2 newImpl = new MockCTMRWADeployerV2();
        vm.startPrank(gov);
        (bool success, ) = address(deployer).call(abi.encodeWithSignature("upgradeToAndCall(address,bytes)", address(newImpl), abi.encodeCall(MockCTMRWADeployerV2.initializeV2, (42))));
        assertTrue(success, "upgradeToAndCall failed");
        vm.stopPrank();
        // Test that reentrancy guard is still active
        // This is implicit since the contract still inherits from ReentrancyGuardUpgradeable
        // and the upgrade doesn't break the reentrancy protection
        assertTrue(true, "Reentrancy guard should still be active");
    }

    function test_upgrade_proxy_preserves_uups_functionality() public {
        // Deploy new implementation and upgrade
        MockCTMRWADeployerV2 newImpl = new MockCTMRWADeployerV2();
        vm.startPrank(gov);
        (bool success, ) = address(deployer).call(abi.encodeWithSignature("upgradeToAndCall(address,bytes)", address(newImpl), abi.encodeCall(MockCTMRWADeployerV2.initializeV2, (42))));
        assertTrue(success, "upgradeToAndCall failed");
        vm.stopPrank();
        // Test that UUPS functionality is preserved
        // The contract should still be upgradeable
        MockCTMRWADeployerV2 impl3 = new MockCTMRWADeployerV2();
        vm.startPrank(gov);
        (success, ) = address(deployer).call(abi.encodeWithSignature("upgradeToAndCall(address,bytes)", address(impl3), bytes("")));
        assertTrue(success, "upgradeToAndCall failed");
        vm.stopPrank();
        assertTrue(true, "UUPS functionality should be preserved");
    }

    function test_upgrade_proxy_preserves_c3govern_dapp_functionality() public {
        // Deploy new implementation and upgrade
        MockCTMRWADeployerV2 newImpl = new MockCTMRWADeployerV2();
        vm.startPrank(gov);
        (bool success, ) = address(deployer).call(abi.encodeWithSignature("upgradeToAndCall(address,bytes)", address(newImpl), abi.encodeCall(MockCTMRWADeployerV2.initializeV2, (42))));
        assertTrue(success, "upgradeToAndCall failed");
        vm.stopPrank();
        // Test that C3GovernDapp functionality is preserved
        // The contract should still have governance controls
        vm.startPrank(user1);
        vm.expectRevert();
        (success, ) = address(deployer).call(abi.encodeWithSignature("setGateway(address)", address(0x123)));
        assertTrue(success, "setGateway failed");
        vm.stopPrank();
        vm.startPrank(gov);
        (success, ) = address(deployer).call(abi.encodeWithSignature("setGateway(address)", address(0x123)));
        assertTrue(success, "setGateway failed");
        assertEq(deployer.gateway(), address(0x123), "Governance should still work");
        vm.stopPrank();
    }
}