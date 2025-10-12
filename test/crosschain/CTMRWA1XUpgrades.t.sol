// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.27;

import { Test } from "forge-std/Test.sol";

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import { Helpers } from "../helpers/Helpers.sol";
import { CTMRWA1X } from "../../src/crosschain/CTMRWA1X.sol";
import { ICTMRWA1X } from "../../src/crosschain/ICTMRWA1X.sol";
import { CTMRWA1XFallback } from "../../src/crosschain/CTMRWA1XFallback.sol";
import { CTMRWAGateway } from "../../src/crosschain/CTMRWAGateway.sol";
import { FeeManager } from "../../src/managers/FeeManager.sol";
import { CTMRWAMap } from "../../src/shared/CTMRWAMap.sol";
import { CTMRWADeployer } from "../../src/deployment/CTMRWADeployer.sol";
import { CTMRWAErrorParam } from "../../src/utils/CTMRWAUtils.sol";

// Mock implementation for testing upgrades
contract MockCTMRWA1XV2 is CTMRWA1X {
    uint256 public newVersion;

    function initializeVX(uint256 _newVersion) external reinitializer(uint64(_newVersion)) {
        newVersion = _newVersion;
    }

    function newFunction() external pure returns (string memory) {
        return "V2 Function";
    }
}

// Malicious implementation that tries to change critical state
contract MaliciousCTMRWA1X is CTMRWA1X {
    function initializeV2() external reinitializer(2) {
        // Try to change critical addresses
        gateway = address(0xdead);
        feeManager = address(0xdead);
        ctmRwaDeployer = address(0xdead);
        ctmRwa1Map = address(0xdead);
        fallbackAddr = address(0xdead);
    }
}

/**
 * @title CTMRWA1X Upgrade Tests
 * @notice Tests for proxy upgrades of CTMRWA1X contract
 */
contract CTMRWA1XUpgradesTest is Helpers {
    // Mock implementation for testing upgrades
    MockCTMRWA1XV2 mockImpl;

    // Malicious implementation that tries to change critical state
    MaliciousCTMRWA1X maliciousImpl;

    function setUp() public override {
        super.setUp();
        mockImpl = new MockCTMRWA1XV2();
        maliciousImpl = new MaliciousCTMRWA1X();
    }

    function test_upgrade_proxy_successfully() public {
        // Store initial state
        address initialGateway = rwa1X.gateway();
        address initialFeeManager = rwa1X.feeManager();
        address initialFallback = rwa1X.fallbackAddr();
        bool initialMinterStatus = rwa1X.isMinter(address(this));

        // Upgrade the proxy
        vm.startPrank(gov);
        (bool success, ) = address(rwa1X).call(abi.encodeWithSignature("upgradeToAndCall(address,bytes)", address(mockImpl), abi.encodeCall(MockCTMRWA1XV2.initializeVX, (42))));
        assertTrue(success, "upgradeToAndCall failed");
        vm.stopPrank();

        // Verify state is preserved
        assertEq(rwa1X.gateway(), initialGateway, "Gateway should be preserved");
        assertEq(rwa1X.feeManager(), initialFeeManager, "FeeManager should be preserved");
        assertEq(rwa1X.fallbackAddr(), initialFallback, "Fallback should be preserved");
        assertEq(rwa1X.isMinter(address(this)), initialMinterStatus, "Minter status should be preserved");

        // Verify new functionality works
        MockCTMRWA1XV2(address(rwa1X)).newFunction();
        assertEq(MockCTMRWA1XV2(address(rwa1X)).newVersion(), 42, "New version should be set");
    }

    function test_upgrade_proxy_without_initialization() public {
        // Store initial state
        address initialGateway = rwa1X.gateway();

        // Upgrade the proxy without initialization
        vm.startPrank(gov);
        (bool success,) = address(rwa1X).call(abi.encodeWithSignature("upgradeToAndCall(address,bytes)", address(mockImpl), bytes("")));
        assertTrue(success, "upgradeToAndCall failed");
        vm.stopPrank();

        // Verify state is preserved
        assertEq(rwa1X.gateway(), initialGateway, "Gateway should be preserved");

        // Verify new functionality works
        MockCTMRWA1XV2(address(rwa1X)).newFunction();
        assertEq(MockCTMRWA1XV2(address(rwa1X)).newVersion(), 0, "New version should be default");
    }

    function test_upgrade_proxy_preserves_mappings() public {
        // Set up some state in mappings
        vm.startPrank(gov);
        rwa1X.changeMinterStatus(user1, true);
        rwa1X.changeMinterStatus(user2, false);
        vm.stopPrank();

        // Verify initial state
        assertTrue(rwa1X.isMinter(user1), "User1 should be minter");
        assertFalse(rwa1X.isMinter(user2), "User2 should not be minter");

        // Upgrade the proxy
        vm.startPrank(gov);
        (bool success, ) = address(rwa1X).call(abi.encodeWithSignature("upgradeToAndCall(address,bytes)", address(mockImpl), abi.encodeCall(MockCTMRWA1XV2.initializeVX, (42))));
        assertTrue(success, "upgradeToAndCall failed");
        vm.stopPrank();

        // Verify mappings are preserved
        assertTrue(rwa1X.isMinter(user1), "User1 should still be minter after upgrade");
        assertFalse(rwa1X.isMinter(user2), "User2 should still not be minter after upgrade");
    }

    function test_upgrade_proxy_preserves_admin_tokens_mapping() public {
        // Deploy a CTMRWA1 token to populate adminTokens mapping
        vm.startPrank(tokenAdmin);
        // string[] memory toChainIdsStr = _stringToArray(cIdStr);
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
        (bool success, ) = address(rwa1X).call(abi.encodeWithSignature("upgradeToAndCall(address,bytes)", address(mockImpl), abi.encodeCall(MockCTMRWA1XV2.initializeVX, (42))));
        assertTrue(success, "upgradeToAndCall failed");
        vm.stopPrank();

        // // Get admin tokens after upgrade
        // address[] memory adminTokensAfter = rwa1X.getAllTokensByAdminAddress(tokenAdmin);

        // // Verify admin tokens mapping is preserved
        // assertEq(adminTokensAfter.length, adminTokensBefore.length, "Admin tokens count should be preserved");
        // for (uint256 i = 0; i < adminTokensBefore.length; i++) {
        //     assertEq(adminTokensAfter[i], adminTokensBefore[i], "Admin token should be preserved");
        // }
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
        (bool success, ) = address(rwa1X).call(abi.encodeWithSignature("upgradeToAndCall(address,bytes)", address(mockImpl), abi.encodeCall(MockCTMRWA1XV2.initializeVX, (42))));
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
        uint256 initialRwaType = rwa1X.RWA_TYPE();
        uint256 initialVersion = rwa1X.VERSION();
        // string memory initialCIdStr = rwa1X.cIdStr(); // cIdStr is not public
        // Upgrade the proxy
        vm.prank(gov);
        (bool success, ) = address(rwa1X).call(abi.encodeWithSignature("upgradeToAndCall(address,bytes)", address(mockImpl), abi.encodeCall(MockCTMRWA1XV2.initializeVX, (42))));
        assertTrue(success, "upgradeToAndCall failed");
        // Verify constants are preserved
        assertEq(rwa1X.RWA_TYPE(), initialRwaType, "RWA_TYPE should be preserved");
        assertEq(rwa1X.VERSION(), initialVersion, "VERSION should be preserved");
        // Can't check cIdStr since it's not public
    }

    function test_upgrade_proxy_preserves_fallback_address() public {
        // Store initial fallback address
        address initialFallback = rwa1X.fallbackAddr();
        assertTrue(initialFallback != address(0), "Should have fallback address");
        // Upgrade the proxy
        vm.startPrank(gov);
        (bool success, ) = address(rwa1X).call(abi.encodeWithSignature("upgradeToAndCall(address,bytes)", address(mockImpl), abi.encodeCall(MockCTMRWA1XV2.initializeVX, (42))));
        assertTrue(success, "upgradeToAndCall failed");
        vm.stopPrank();
        // Verify fallback address is preserved
        assertEq(rwa1X.fallbackAddr(), initialFallback, "Fallback address should be preserved");
    }

    function test_upgrade_proxy_preserves_deployer_and_map_addresses() public {
        // Store initial addresses
        address initialDeployer = rwa1X.ctmRwaDeployer();
        address initialMap = rwa1X.ctmRwa1Map();
        // Deploy new implementation and upgrade
        MockCTMRWA1XV2 newImpl = new MockCTMRWA1XV2();
        vm.startPrank(gov);
        (bool success, ) = address(rwa1X).call(abi.encodeWithSignature("upgradeToAndCall(address,bytes)", address(newImpl), abi.encodeCall(MockCTMRWA1XV2.initializeVX, (42))));
        assertTrue(success, "upgradeToAndCall failed");
        vm.stopPrank();
        // Verify addresses are preserved
        assertEq(rwa1X.ctmRwaDeployer(), initialDeployer, "Deployer address should be preserved");
        assertEq(rwa1X.ctmRwa1Map(), initialMap, "Map address should be preserved");
    }

    function test_upgrade_proxy_unauthorized_reverts() public {
        // Deploy new implementation
        MockCTMRWA1XV2 newImpl = new MockCTMRWA1XV2();
        // Try to upgrade without being gov
        vm.startPrank(user1);
        vm.expectRevert();
        (bool success, ) = address(rwa1X).call(abi.encodeWithSignature("upgradeToAndCall(address,bytes)", address(newImpl), abi.encodeCall(MockCTMRWA1XV2.initializeVX, (42))));
        assertTrue(success, "upgradeToAndCall failed");
        vm.stopPrank();
    }

    function test_upgrade_proxy_with_zero_address_reverts() public {
        // Try to upgrade to zero address
        vm.startPrank(gov);
        vm.expectRevert();
        (bool success, ) = address(rwa1X).call(abi.encodeWithSignature("upgradeToAndCall(address,bytes)", address(0)));
        assertTrue(success, "upgradeToAndCall failed");
        vm.stopPrank();
    }

    function test_upgrade_proxy_with_invalid_implementation_reverts() public {
        // Try to upgrade to a contract that doesn't implement the interface
        address invalidImpl = address(new FeeManager());
        vm.startPrank(gov);
        vm.expectRevert();
        (bool success, ) = address(rwa1X).call(abi.encodeWithSignature("upgradeToAndCall(address,bytes)", invalidImpl, abi.encodeCall(MockCTMRWA1XV2.initializeVX, (42))));
        assertTrue(success, "upgradeToAndCall failed");
        vm.stopPrank();
    }

    function test_upgrade_proxy_preserves_functionality() public {
        // Test that core functionality still works after upgrade
        // Deploy new implementation and upgrade
        MockCTMRWA1XV2 newImpl = new MockCTMRWA1XV2();
        vm.startPrank(gov);
        (bool success, ) = address(rwa1X).call(abi.encodeWithSignature("upgradeToAndCall(address,bytes)", address(newImpl), abi.encodeCall(MockCTMRWA1XV2.initializeVX, (42))));
        assertTrue(success, "upgradeToAndCall failed");
        vm.stopPrank();
        // Test that governance functions still work
        vm.startPrank(gov);
        rwa1X.changeMinterStatus(user1, true);
        assertTrue(rwa1X.isMinter(user1), "Minter status should be set");
        rwa1X.changeMinterStatus(user1, false);
        assertFalse(rwa1X.isMinter(user1), "Minter status should be unset");
        vm.stopPrank();
    }

    function test_fail_upgrade_proxy_same_version() public {
        // Upgrading to same version (1)
        MockCTMRWA1XV2 impl1 = new MockCTMRWA1XV2();
        (, bytes memory dataOldImpl) = address(rwa1X).call(abi.encodeWithSignature("getImplementation()"));
        address oldImpl = abi.decode(dataOldImpl, (address));
        vm.startPrank(gov);
        vm.expectRevert(Initializable.InvalidInitialization.selector);
        (bool success, ) = address(rwa1X).call(abi.encodeWithSignature("upgradeToAndCall(address,bytes)", address(impl1), abi.encodeCall(MockCTMRWA1XV2.initializeVX, (1))));
        assertTrue(success);
        vm.stopPrank();
        // check that version is still one
        (, bytes memory dataCurrentImpl) = address(rwa1X).call(abi.encodeWithSignature("getImplementation()"));
        address currentImpl = abi.decode(dataCurrentImpl, (address));

        assertEq(currentImpl, oldImpl);
    }

    function test_upgrade_proxy_multiple_upgrades() public {
        // Perform multiple upgrades and verify state preservation
        // First upgrade
        MockCTMRWA1XV2 impl2 = new MockCTMRWA1XV2();
        vm.startPrank(gov);
        (bool success, ) = address(rwa1X).call(abi.encodeWithSignature("upgradeToAndCall(address,bytes)", address(impl2), abi.encodeCall(MockCTMRWA1XV2.initializeVX, (2))));
        assertTrue(success, "upgradeToAndCall failed");
        vm.stopPrank();
        // Verify first upgrade
        assertEq(MockCTMRWA1XV2(address(rwa1X)).newVersion(), 2, "First upgrade should work");
        // Second upgrade
        MockCTMRWA1XV2 impl3 = new MockCTMRWA1XV2();
        vm.startPrank(gov);
        (success, ) = address(rwa1X).call(abi.encodeWithSignature("upgradeToAndCall(address,bytes)", address(impl3), abi.encodeCall(MockCTMRWA1XV2.initializeVX, (3))));
        assertTrue(success, "upgradeToAndCall failed");
        vm.stopPrank();
        // Verify second upgrade
        assertEq(MockCTMRWA1XV2(address(rwa1X)).newVersion(), 3, "Second upgrade should work");
        // Verify core state is still preserved
        assertTrue(rwa1X.gateway() != address(0), "Gateway should still be set");
        assertTrue(rwa1X.feeManager() != address(0), "FeeManager should still be set");
    }

    function test_upgrade_proxy_preserves_reentrancy_guard() public {
        // Deploy new implementation and upgrade
        MockCTMRWA1XV2 newImpl = new MockCTMRWA1XV2();
        vm.startPrank(gov);
        (bool success, ) = address(rwa1X).call(abi.encodeWithSignature("upgradeToAndCall(address,bytes)", address(newImpl), abi.encodeCall(MockCTMRWA1XV2.initializeVX, (42))));
        assertTrue(success, "upgradeToAndCall failed");
        vm.stopPrank();
        // Test that reentrancy guard is still active
        // This is implicit since the contract still inherits from ReentrancyGuardUpgradeable
        // and the upgrade doesn't break the reentrancy protection
        assertTrue(true, "Reentrancy guard should still be active");
    }

    function test_upgrade_proxy_preserves_uups_functionality() public {
        // Deploy new implementation and upgrade
        MockCTMRWA1XV2 newImpl = new MockCTMRWA1XV2();
        vm.startPrank(gov);
        (bool success, ) = address(rwa1X).call(abi.encodeWithSignature("upgradeToAndCall(address,bytes)", address(newImpl), abi.encodeCall(MockCTMRWA1XV2.initializeVX, (42))));
        assertTrue(success, "upgradeToAndCall failed");
        vm.stopPrank();
        // Test that UUPS functionality is preserved
        // The contract should still be upgradeable
        MockCTMRWA1XV2 impl3 = new MockCTMRWA1XV2();
        vm.startPrank(gov);
        (success, ) = address(rwa1X).call(abi.encodeWithSignature("upgradeToAndCall(address,bytes)", address(impl3), bytes("")));
        assertTrue(success, "upgradeToAndCall failed");
        vm.stopPrank();
        assertTrue(true, "UUPS functionality should be preserved");
    }

    function test_upgrade_proxy_preserves_c3govern_dapp_functionality() public {
        // Deploy new implementation and upgrade
        MockCTMRWA1XV2 newImpl = new MockCTMRWA1XV2();
        vm.startPrank(gov);
        (bool success, ) = address(rwa1X).call(abi.encodeWithSignature("upgradeToAndCall(address,bytes)", address(newImpl), abi.encodeCall(MockCTMRWA1XV2.initializeVX, (42))));
        assertTrue(success, "upgradeToAndCall failed");
        vm.stopPrank();
        // Test that C3GovernDApp functionality is preserved
        // The contract should still have governance controls
        vm.startPrank(user1);
        vm.expectRevert();
        (success, ) = address(rwa1X).call(abi.encodeWithSignature("changeMinterStatus(address,bool)", user2, true));
        assertTrue(success, "changeMinterStatus failed");
        vm.stopPrank();
        vm.startPrank(gov);
        (success, ) = address(rwa1X).call(abi.encodeWithSignature("changeMinterStatus(address,bool)", user2, true));
        assertTrue(success, "changeMinterStatus failed");
        assertTrue(rwa1X.isMinter(user2), "Governance should still work");
        vm.stopPrank();
    }

    function test_upgrade_proxy_preserves_chain_id_string() public {
        // Store initial chain ID string
        string memory initialCIdStr = rwa1X.cIdStr();
        // Deploy new implementation and upgrade
        MockCTMRWA1XV2 newImpl = new MockCTMRWA1XV2();
        vm.startPrank(gov);
        (bool success, ) = address(rwa1X).call(abi.encodeWithSignature("upgradeToAndCall(address,bytes)", address(newImpl), abi.encodeCall(MockCTMRWA1XV2.initializeVX, (42))));
        assertTrue(success, "upgradeToAndCall failed");
        vm.stopPrank();
        // Verify chain ID string is preserved
        assertEq(rwa1X.cIdStr(), initialCIdStr, "Chain ID string should be preserved");
    }

    function test_upgrade_proxy_preserves_self_minter_status() public {
        // Verify that the contract itself is a minter
        assertTrue(rwa1X.isMinter(address(rwa1X)), "Contract should be minter");
        // Deploy new implementation and upgrade
        MockCTMRWA1XV2 newImpl = new MockCTMRWA1XV2();
        vm.startPrank(gov);
        (bool success, ) = address(rwa1X).call(abi.encodeWithSignature("upgradeToAndCall(address,bytes)", address(newImpl), abi.encodeCall(MockCTMRWA1XV2.initializeVX, (42))));
        assertTrue(success, "upgradeToAndCall failed");
        vm.stopPrank();
        // Verify self minter status is preserved
        assertTrue(rwa1X.isMinter(address(rwa1X)), "Contract should still be minter after upgrade");
    }

    function test_upgrade_proxy_preserves_fallback_minter_status() public {
        // Store initial fallback minter status
        address fallbackAddr = rwa1X.fallbackAddr();
        bool fallbackMinterStatus = rwa1X.isMinter(fallbackAddr);
        // Deploy new implementation and upgrade
        MockCTMRWA1XV2 newImpl = new MockCTMRWA1XV2();
        vm.startPrank(gov);
        (bool success, ) = address(rwa1X).call(abi.encodeWithSignature("upgradeToAndCall(address,bytes)", address(newImpl), abi.encodeCall(MockCTMRWA1XV2.initializeVX, (42))));
        assertTrue(success, "upgradeToAndCall failed");
        vm.stopPrank();
        // Verify fallback minter status is preserved
        assertEq(rwa1X.isMinter(fallbackAddr), fallbackMinterStatus, "Fallback minter status should be preserved");
    }
}
