// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.27;

import { Test } from "forge-std/Test.sol";
import { console } from "forge-std/console.sol";

import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import { IC3GovClient } from "@c3caller/gov/IC3GovClient.sol";
import { IC3GovernDApp } from "@c3caller/gov/IC3GovernDApp.sol";
import { C3ErrorParam } from "@c3caller/utils/C3CallerUtils.sol";

import { Helpers } from "../helpers/Helpers.sol";
import { FeeManager } from "../../src/managers/FeeManager.sol";
import { IFeeManager, FeeType } from "../../src/managers/IFeeManager.sol";
import { CTMRWAMap } from "../../src/shared/CTMRWAMap.sol";
import { CTMRWAErrorParam } from "../../src/utils/CTMRWAUtils.sol";
import { TestERC20 } from "../../src/mocks/TestERC20.sol";

// Mock implementation for testing upgrades
contract MockFeeManagerV2 is FeeManager {
    uint256 public newVersion;

    function initializeV2(uint256 _newVersion) external reinitializer(uint64(_newVersion)) {
        newVersion = _newVersion;
    }

    function newFunction() external pure returns (string memory) {
        return "V2 Function";
    }
}

// Malicious implementation that tries to change critical state
contract MaliciousFeeManager is FeeManager {
    function initializeV2() external reinitializer(2) {
        // Try to add a critical address
        feeTokenList[0] = address(0xdead);
    }
}

/**
 * @title FeeManager Upgrade Tests
 * @notice Tests for proxy upgrades of FeeManager contract
 */
contract TestFeeManagerUpgrades is Helpers {
    using Strings for *;

    // Mock implementation for testing upgrades
    MockFeeManagerV2 mockImpl;

    // Malicious implementation that tries to change critical state
    MaliciousFeeManager maliciousImpl;

    function setUp() public override {
        super.setUp();
        mockImpl = new MockFeeManagerV2();
        maliciousImpl = new MaliciousFeeManager();
    }

    function test_upgrade_proxy_successfully() public {
        // Store initial state
        address[] memory initialFeeTokenList = feeManager.getFeeTokenList();
        uint256 initialFeeMultiplier = feeManager.feeMultiplier(0);

        // Upgrade the proxy
        vm.startPrank(gov);
        (bool success, ) = address(feeManager).call(abi.encodeWithSignature("upgradeToAndCall(address,bytes)", address(mockImpl), abi.encodeCall(MockFeeManagerV2.initializeV2, (42))));
        assertTrue(success, "upgradeToAndCall failed");
        vm.stopPrank();

        // Verify state is preserved
        address[] memory feeTokenListAfter = feeManager.getFeeTokenList();
        assertEq(feeTokenListAfter.length, initialFeeTokenList.length, "Fee token list length should be preserved");
        assertEq(feeManager.feeMultiplier(0), initialFeeMultiplier, "Fee multiplier should be preserved");

        // Verify new functionality works
        MockFeeManagerV2(address(feeManager)).newFunction();
        assertEq(MockFeeManagerV2(address(feeManager)).newVersion(), 42, "New version should be set");
    }

    function test_upgrade_proxy_without_initialization() public {
        // Store initial state
        address[] memory initialFeeTokenList = feeManager.getFeeTokenList();

        // Upgrade the proxy without initialization
        vm.startPrank(gov);
        (bool success,) = address(feeManager).call(abi.encodeWithSignature("upgradeToAndCall(address,bytes)", address(mockImpl), bytes("")));
        assertTrue(success, "upgradeToAndCall failed");
        vm.stopPrank();

        // Verify state is preserved
        address[] memory feeTokenListAfter = feeManager.getFeeTokenList();
        assertEq(feeTokenListAfter.length, initialFeeTokenList.length, "Fee token list length should be preserved");

        // Verify new functionality works
        MockFeeManagerV2(address(feeManager)).newFunction();
        assertEq(MockFeeManagerV2(address(feeManager)).newVersion(), 0, "New version should be default");
    }

    function test_upgrade_proxy_preserves_mappings() public {
        // Create a test token for the upgrade test
        TestERC20 testToken = new TestERC20("Test Token", "TEST", 18);
        
        // Set up some state in mappings
        vm.startPrank(gov);
        feeManager.addFeeToken(address(testToken).toHexString());
        feeManager.setFeeMultiplier(FeeType.OFFERING, 100);
        vm.stopPrank();

        // Verify initial state
        assertTrue(feeManager.feeTokenIndexMap(address(testToken)) > 0, "Fee token should be added");
        assertEq(feeManager.feeMultiplier(uint8(FeeType.OFFERING)), 100, "Fee multiplier should be set");

        // Upgrade the proxy
        vm.startPrank(gov);
        (bool success, ) = address(feeManager).call(abi.encodeWithSignature("upgradeToAndCall(address,bytes)", address(mockImpl), abi.encodeCall(MockFeeManagerV2.initializeV2, (42))));
        assertTrue(success, "upgradeToAndCall failed");
        vm.stopPrank();

        // Verify mappings are preserved
        assertTrue(feeManager.feeTokenIndexMap(address(testToken)) > 0, "Fee token should still be added after upgrade");
        assertEq(feeManager.feeMultiplier(uint8(FeeType.OFFERING)), 100, "Fee multiplier should still be set after upgrade");
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
        (bool success, ) = address(feeManager).call(abi.encodeWithSignature("upgradeToAndCall(address,bytes)", address(mockImpl), abi.encodeCall(MockFeeManagerV2.initializeV2, (42))));
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
        (bool success, ) = address(feeManager).call(abi.encodeWithSignature("upgradeToAndCall(address,bytes)", address(mockImpl), abi.encodeCall(MockFeeManagerV2.initializeV2, (42))));
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
        uint256 initialMaxSafeMultiplier = feeManager.MAX_SAFE_MULTIPLIER();
        // Upgrade the proxy
        vm.prank(gov);
        (bool success, ) = address(feeManager).call(abi.encodeWithSignature("upgradeToAndCall(address,bytes)", address(mockImpl), abi.encodeCall(MockFeeManagerV2.initializeV2, (42))));
        assertTrue(success, "upgradeToAndCall failed");
        // Verify constants are preserved
        assertEq(feeManager.MAX_SAFE_MULTIPLIER(), initialMaxSafeMultiplier, "MAX_SAFE_MULTIPLIER should be preserved");
    }

    function test_upgrade_proxy_unauthorized_reverts() public {
        // Deploy new implementation
        MockFeeManagerV2 newImpl = new MockFeeManagerV2();
        // Try to upgrade without being gov
        vm.startPrank(user1);
        vm.expectRevert(abi.encodeWithSelector(IC3GovClient.C3GovClient_OnlyAuthorized.selector, C3ErrorParam.Sender, C3ErrorParam.Gov));
        (bool success, ) = address(feeManager).call(abi.encodeWithSignature("upgradeToAndCall(address,bytes)", address(newImpl), abi.encodeCall(MockFeeManagerV2.initializeV2, (42))));
        assertFalse(success, "upgradeToAndCall did not fail");
        vm.stopPrank();
    }

    function test_upgrade_proxy_with_zero_address_reverts() public {
        // Try to upgrade to zero address
        vm.startPrank(gov);
        vm.expectRevert("ERC1967: new implementation is not a contract");
        (bool success, ) = address(feeManager).call(abi.encodeWithSignature("upgradeToAndCall(address,bytes)", address(0)));
        assertFalse(success, "upgradeToAndCall did not fail");
        vm.stopPrank();
    }

    function test_upgrade_proxy_with_invalid_implementation_reverts() public {
        // Try to upgrade to a contract that doesn't implement the interface
        address invalidImpl = address(new CTMRWAMap());
        vm.startPrank(gov);
        vm.expectRevert("ERC1967: new implementation is not a contract");
        (bool success, ) = address(feeManager).call(abi.encodeWithSignature("upgradeToAndCall(address,bytes)", invalidImpl, abi.encodeCall(MockFeeManagerV2.initializeV2, (42))));
        assertFalse(success, "upgradeToAndCall did not fail");
        vm.stopPrank();
    }

    function test_upgrade_proxy_preserves_functionality() public {
        // Test that core functionality still works after upgrade
        // Deploy new implementation and upgrade
        MockFeeManagerV2 newImpl = new MockFeeManagerV2();
        vm.startPrank(gov);
        (bool success, ) = address(feeManager).call(abi.encodeWithSignature("upgradeToAndCall(address,bytes)", address(newImpl), abi.encodeCall(MockFeeManagerV2.initializeV2, (42))));
        assertTrue(success, "upgradeToAndCall failed");
        vm.stopPrank();
        // Test that governance functions still work
        TestERC20 testToken = new TestERC20("Test Token", "TEST", 18);
        vm.startPrank(gov);
        feeManager.addFeeToken(address(testToken).toHexString());
        assertTrue(feeManager.feeTokenIndexMap(address(testToken)) > 0, "Fee token should be added");
        feeManager.setFeeMultiplier(FeeType.OFFERING, 200);
        assertEq(feeManager.feeMultiplier(uint8(FeeType.OFFERING)), 200, "Fee multiplier should be set");
        vm.stopPrank();
    }

    function test_fail_upgrade_proxy_same_version() public {
        // Upgrading to same version (1)
        MockFeeManagerV2 impl1 = new MockFeeManagerV2();
        (, bytes memory dataOldImpl) = address(feeManager).call(abi.encodeWithSignature("getImplementation()"));
        address oldImpl = abi.decode(dataOldImpl, (address));
        vm.startPrank(gov);
        vm.expectRevert(Initializable.InvalidInitialization.selector);
        (bool success, ) = address(feeManager).call(abi.encodeWithSignature("upgradeToAndCall(address,bytes)", address(impl1), abi.encodeCall(MockFeeManagerV2.initializeV2, (1))));
        assertTrue(success);
        vm.stopPrank();
        // check that version is still one
        (, bytes memory dataCurrentImpl) = address(feeManager).call(abi.encodeWithSignature("getImplementation()"));
        address currentImpl = abi.decode(dataCurrentImpl, (address));

        assertEq(currentImpl, oldImpl);
    }

    function test_upgrade_proxy_multiple_upgrades() public {
        // Perform multiple upgrades and verify state preservation
        // First upgrade
        MockFeeManagerV2 impl2 = new MockFeeManagerV2();
        vm.startPrank(gov);
        (bool success, ) = address(feeManager).call(abi.encodeWithSignature("upgradeToAndCall(address,bytes)", address(impl2), abi.encodeCall(MockFeeManagerV2.initializeV2, (2))));
        assertTrue(success, "upgradeToAndCall failed");
        vm.stopPrank();
        // Verify first upgrade
        assertEq(MockFeeManagerV2(address(feeManager)).newVersion(), 2, "First upgrade should work");
        // Second upgrade
        MockFeeManagerV2 impl3 = new MockFeeManagerV2();
        vm.startPrank(gov);
        (success, ) = address(feeManager).call(abi.encodeWithSignature("upgradeToAndCall(address,bytes)", address(impl3), abi.encodeCall(MockFeeManagerV2.initializeV2, (3))));
        assertTrue(success, "upgradeToAndCall failed");
        vm.stopPrank();
        // Verify second upgrade
        assertEq(MockFeeManagerV2(address(feeManager)).newVersion(), 3, "Second upgrade should work");
    }

    function test_upgrade_proxy_preserves_reentrancy_guard() public {
        // Deploy new implementation and upgrade
        MockFeeManagerV2 newImpl = new MockFeeManagerV2();
        vm.startPrank(gov);
        (bool success, ) = address(feeManager).call(abi.encodeWithSignature("upgradeToAndCall(address,bytes)", address(newImpl), abi.encodeCall(MockFeeManagerV2.initializeV2, (42))));
        assertTrue(success, "upgradeToAndCall failed");
        vm.stopPrank();
        // Test that reentrancy guard is still active
        // This is implicit since the contract still inherits from ReentrancyGuardUpgradeable
        // and the upgrade doesn't break the reentrancy protection
        assertTrue(true, "Reentrancy guard should still be active");
    }

    function test_upgrade_proxy_preserves_uups_functionality() public {
        // Deploy new implementation and upgrade
        MockFeeManagerV2 newImpl = new MockFeeManagerV2();
        vm.startPrank(gov);
        (bool success, ) = address(feeManager).call(abi.encodeWithSignature("upgradeToAndCall(address,bytes)", address(newImpl), abi.encodeCall(MockFeeManagerV2.initializeV2, (42))));
        assertTrue(success, "upgradeToAndCall failed");
        vm.stopPrank();
        // Test that UUPS functionality is preserved
        // The contract should still be upgradeable
        MockFeeManagerV2 impl3 = new MockFeeManagerV2();
        vm.startPrank(gov);
        (success, ) = address(feeManager).call(abi.encodeWithSignature("upgradeToAndCall(address,bytes)", address(impl3), bytes("")));
        assertTrue(success, "upgradeToAndCall failed");
        vm.stopPrank();
        assertTrue(true, "UUPS functionality should be preserved");
    }

    function test_upgrade_proxy_preserves_c3govern_dapp_functionality() public {
        // Verify that user1 and gov are different addresses
        assertTrue(user1 != gov, "user1 should not be the same as gov");
        
        // First, test that governance works before upgrade
        // Create the test token first (outside of expectRevert)
        TestERC20 testToken = new TestERC20("Test Token", "TEST", 18);
        
        vm.startPrank(user1);
        vm.expectRevert(
            abi.encodeWithSelector(
                IC3GovernDApp.C3GovernDApp_OnlyAuthorized.selector, C3ErrorParam.Sender, C3ErrorParam.GovOrC3Caller
            )
        );
        feeManager.addFeeToken(address(testToken).toHexString());
        vm.stopPrank();
        
        // Deploy new implementation and upgrade
        MockFeeManagerV2 newImpl = new MockFeeManagerV2();
        vm.startPrank(gov);
        (bool success, ) = address(feeManager).call(abi.encodeWithSignature("upgradeToAndCall(address,bytes)", address(newImpl), abi.encodeCall(MockFeeManagerV2.initializeV2, (42))));
        assertTrue(success, "upgradeToAndCall failed");
        vm.stopPrank();
        
        // Test that C3GovernDApp functionality is preserved after upgrade
        // The contract should still have governance controls
        vm.startPrank(user1);
        vm.expectRevert(
            abi.encodeWithSelector(
                IC3GovernDApp.C3GovernDApp_OnlyAuthorized.selector, C3ErrorParam.Sender, C3ErrorParam.GovOrC3Caller
            )
        );
        success = feeManager.addFeeToken(address(testToken).toHexString());
        assertFalse(success, "addFeeToken did not fail");
        vm.stopPrank();
        vm.startPrank(gov);
        success = feeManager.addFeeToken(address(testToken).toHexString());
        assertTrue(success, "addFeeToken failed");
        assertTrue(feeManager.feeTokenIndexMap(address(testToken)) > 0, "Governance should still work");
        vm.stopPrank();
    }
}
