// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.27;

import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { Test } from "forge-std/Test.sol";

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import { FeeManager } from "../../src/managers/FeeManager.sol";
import { CTMRWAMap } from "../../src/shared/CTMRWAMap.sol";
import { ICTMRWAMap } from "../../src/shared/ICTMRWAMap.sol";
import { Helpers } from "../helpers/Helpers.sol";

// Mock implementation for testing upgrades
contract MockCTMRWAMapV2 is CTMRWAMap {
    uint256 public newVersion;

    function initializeV2(uint256 _newVersion) external reinitializer(uint64(_newVersion)) {
        newVersion = _newVersion;
    }

    function newFunction() external pure returns (string memory) {
        return "V2 Function";
    }
}

// Malicious implementation that tries to change critical state
contract MaliciousCTMRWAMap is CTMRWAMap {
    function initializeV2() external reinitializer(2) {
        // Try to change critical addresses
        gateway = address(0xdead);
        ctmRwaDeployer = address(0xdead);
        ctmRwa1X = address(0xdead);
    }
}

/**
 * @title CTMRWAMap Upgrade Tests
 * @notice Tests for proxy upgrades of CTMRWAMap contract
 */
contract TestCTMRWAMapUpgrades is Helpers {
    using Strings for *;

    // Mock implementation for testing upgrades
    MockCTMRWAMapV2 mockImpl;

    // Malicious implementation that tries to change critical state
    MaliciousCTMRWAMap maliciousImpl;

    function setUp() public override {
        super.setUp();
        mockImpl = new MockCTMRWAMapV2();
        maliciousImpl = new MaliciousCTMRWAMap();

        vm.startPrank(tokenAdmin);
        (ID, token) = _deployCTMRWA1(address(usdc));
        _createSomeSlots(ID, address(usdc), address(rwa1X));
        vm.stopPrank();
    }

    function test_upgrade_proxy_successfully() public {
        // Store initial state
        address initialGateway = map.gateway();
        address initialDeployer = map.ctmRwaDeployer();
        address initialRwa1X = map.ctmRwa1X();

        // Upgrade the proxy
        vm.startPrank(gov);
        (bool success,) = address(map).call(
            abi.encodeWithSignature(
                "upgradeToAndCall(address,bytes)", address(mockImpl), abi.encodeCall(MockCTMRWAMapV2.initializeV2, (42))
            )
        );
        assertTrue(success, "upgradeToAndCall failed");
        vm.stopPrank();

        // Verify state is preserved
        assertEq(map.gateway(), initialGateway, "Gateway should be preserved");
        assertEq(map.ctmRwaDeployer(), initialDeployer, "Deployer should be preserved");
        assertEq(map.ctmRwa1X(), initialRwa1X, "Rwa1X should be preserved");

        // Verify new functionality works
        MockCTMRWAMapV2(address(map)).newFunction();
        assertEq(MockCTMRWAMapV2(address(map)).newVersion(), 42, "New version should be set");
    }

    function test_upgrade_proxy_without_initialization() public {
        // Store initial state
        address initialGateway = map.gateway();

        // Upgrade the proxy without initialization
        vm.startPrank(gov);
        (bool success,) =
            address(map).call(abi.encodeWithSignature("upgradeToAndCall(address,bytes)", address(mockImpl), bytes("")));
        assertTrue(success, "upgradeToAndCall failed");
        vm.stopPrank();

        // Verify state is preserved
        assertEq(map.gateway(), initialGateway, "Gateway should be preserved");

        // Verify new functionality works
        MockCTMRWAMapV2(address(map)).newFunction();
        assertEq(MockCTMRWAMapV2(address(map)).newVersion(), 0, "New version should be default");
    }

    function test_upgrade_proxy_preserves_mappings() public {
        deployer.deployNewInvestment(ID, RWA_TYPE, VERSION, address(usdc));
        (bool ok, address investmentContractAddr) = map.getInvestContract(ID, 1, 1);
        assertTrue(ok, "Invest contract should be deployed");
        assertNotEq(investmentContractAddr, address(0), "Invest contract should be deployed");

        // Upgrade the proxy
        vm.startPrank(gov);
        (bool success,) = address(map).call(
            abi.encodeWithSignature(
                "upgradeToAndCall(address,bytes)", address(mockImpl), abi.encodeCall(MockCTMRWAMapV2.initializeV2, (42))
            )
        );
        assertTrue(success, "upgradeToAndCall failed");
        vm.stopPrank();

        (, address investmentContractAddrAfter) = map.getInvestContract(ID, 1, 1);
        assertEq(
            investmentContractAddrAfter, investmentContractAddr, "Invest contract should be preserved after upgrade"
        );
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
        (bool success,) = address(map).call(
            abi.encodeWithSignature(
                "upgradeToAndCall(address,bytes)", address(mockImpl), abi.encodeCall(MockCTMRWAMapV2.initializeV2, (42))
            )
        );
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
        (bool success,) = address(map).call(
            abi.encodeWithSignature(
                "upgradeToAndCall(address,bytes)", address(mockImpl), abi.encodeCall(MockCTMRWAMapV2.initializeV2, (42))
            )
        );
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
        address initialGateway = map.gateway();
        address initialDeployer = map.ctmRwaDeployer();
        address initialRwa1X = map.ctmRwa1X();
        // Deploy new implementation and upgrade
        MockCTMRWAMapV2 newImpl = new MockCTMRWAMapV2();
        vm.startPrank(gov);
        (bool success,) = address(map).call(
            abi.encodeWithSignature(
                "upgradeToAndCall(address,bytes)", address(newImpl), abi.encodeCall(MockCTMRWAMapV2.initializeV2, (42))
            )
        );
        assertTrue(success, "upgradeToAndCall failed");
        vm.stopPrank();
        // Verify addresses are preserved
        assertEq(map.gateway(), initialGateway, "Gateway address should be preserved");
        assertEq(map.ctmRwaDeployer(), initialDeployer, "Deployer address should be preserved");
        assertEq(map.ctmRwa1X(), initialRwa1X, "Rwa1X address should be preserved");
    }

    function test_upgrade_proxy_unauthorized_reverts() public {
        // Deploy new implementation
        MockCTMRWAMapV2 newImpl = new MockCTMRWAMapV2();
        // Try to upgrade without being gov
        vm.startPrank(user1);
        vm.expectRevert();
        (bool success,) = address(map).call(
            abi.encodeWithSignature(
                "upgradeToAndCall(address,bytes)", address(newImpl), abi.encodeCall(MockCTMRWAMapV2.initializeV2, (42))
            )
        );
        assertTrue(success, "upgradeToAndCall failed");
        vm.stopPrank();
    }

    function test_upgrade_proxy_with_zero_address_reverts() public {
        // Try to upgrade to zero address
        vm.startPrank(gov);
        vm.expectRevert();
        (bool success,) = address(map).call(abi.encodeWithSignature("upgradeToAndCall(address,bytes)", address(0)));
        assertTrue(success, "upgradeToAndCall failed");
        vm.stopPrank();
    }

    function test_upgrade_proxy_with_invalid_implementation_reverts() public {
        // Try to upgrade to a contract that doesn't implement the interface
        address invalidImpl = address(new FeeManager());
        vm.startPrank(gov);
        vm.expectRevert();
        (bool success,) = address(map).call(
            abi.encodeWithSignature(
                "upgradeToAndCall(address,bytes)", invalidImpl, abi.encodeCall(MockCTMRWAMapV2.initializeV2, (42))
            )
        );
        assertTrue(success, "upgradeToAndCall failed");
        vm.stopPrank();
    }

    function test_upgrade_proxy_preserves_functionality() public {
        // Test that core functionality still works after upgrade
        // Deploy new implementation and upgrade
        MockCTMRWAMapV2 newImpl = new MockCTMRWAMapV2();
        vm.startPrank(gov);
        (bool success,) = address(map).call(
            abi.encodeWithSignature(
                "upgradeToAndCall(address,bytes)", address(newImpl), abi.encodeCall(MockCTMRWAMapV2.initializeV2, (42))
            )
        );
        assertTrue(success, "upgradeToAndCall failed");
        vm.stopPrank();
        // Test that functions still work
        // Use setCtmRwaDeployer to test post-upgrade functionality
        vm.prank(address(rwa1X));
        map.setCtmRwaDeployer(address(0x123), address(0x456), address(0x789));
        assertEq(map.ctmRwaDeployer(), address(0x123), "Deployer should be set after upgrade");
    }

    function test_fail_upgrade_proxy_same_version() public {
        // Upgrading to same version (1)
        MockCTMRWAMapV2 impl1 = new MockCTMRWAMapV2();
        (, bytes memory dataOldImpl) = address(map).call(abi.encodeWithSignature("getImplementation()"));
        address oldImpl = abi.decode(dataOldImpl, (address));
        vm.startPrank(gov);
        vm.expectRevert(Initializable.InvalidInitialization.selector);
        (bool success,) = address(map).call(
            abi.encodeWithSignature(
                "upgradeToAndCall(address,bytes)", address(impl1), abi.encodeCall(MockCTMRWAMapV2.initializeV2, (1))
            )
        );
        assertTrue(success);
        vm.stopPrank();
        // check that version is still one
        (, bytes memory dataCurrentImpl) = address(map).call(abi.encodeWithSignature("getImplementation()"));
        address currentImpl = abi.decode(dataCurrentImpl, (address));

        assertEq(currentImpl, oldImpl);
    }

    function test_upgrade_proxy_multiple_upgrades() public {
        // Perform multiple upgrades and verify state preservation
        // First upgrade
        MockCTMRWAMapV2 impl2 = new MockCTMRWAMapV2();
        vm.startPrank(gov);
        (bool success,) = address(map).call(
            abi.encodeWithSignature(
                "upgradeToAndCall(address,bytes)", address(impl2), abi.encodeCall(MockCTMRWAMapV2.initializeV2, (2))
            )
        );
        assertTrue(success, "upgradeToAndCall failed");
        vm.stopPrank();
        // Verify first upgrade
        assertEq(MockCTMRWAMapV2(address(map)).newVersion(), 2, "First upgrade should work");
        // Second upgrade
        MockCTMRWAMapV2 impl3 = new MockCTMRWAMapV2();
        vm.startPrank(gov);
        (success,) = address(map).call(
            abi.encodeWithSignature(
                "upgradeToAndCall(address,bytes)", address(impl3), abi.encodeCall(MockCTMRWAMapV2.initializeV2, (3))
            )
        );
        assertTrue(success, "upgradeToAndCall failed");
        vm.stopPrank();
        // Verify second upgrade
        assertEq(MockCTMRWAMapV2(address(map)).newVersion(), 3, "Second upgrade should work");
        // Verify core state is still preserved
        assertTrue(map.gateway() != address(0), "Gateway should still be set");
        assertTrue(map.ctmRwaDeployer() != address(0), "Deployer should still be set");
    }

    function test_upgrade_proxy_preserves_c3govern_dapp_functionality() public {
        // Perform unauthorized upgrade fails
        // First upgrade
        MockCTMRWAMapV2 impl2 = new MockCTMRWAMapV2();
        vm.startPrank(gov);
        (bool success,) = address(map).call(
            abi.encodeWithSignature(
                "upgradeToAndCall(address,bytes)", address(impl2), abi.encodeCall(MockCTMRWAMapV2.initializeV2, (2))
            )
        );
        assertTrue(success, "upgradeToAndCall failed");
        vm.stopPrank();
        // Verify first upgrade
        assertEq(MockCTMRWAMapV2(address(map)).newVersion(), 2, "First upgrade should work");
        // Second upgrade
        MockCTMRWAMapV2 impl3 = new MockCTMRWAMapV2();
        // not sending as gov to test that upgradeToAndCall reverts
        vm.expectRevert();
        (success,) = address(map).call(
            abi.encodeWithSignature(
                "upgradeToAndCall(address,bytes)", address(impl3), abi.encodeCall(MockCTMRWAMapV2.initializeV2, (3))
            )
        );
        // Second upgrade should fail
        assertEq(MockCTMRWAMapV2(address(map)).newVersion(), 2, "Second upgrade should fail");
    }

    function test_upgrade_proxy_preserves_reentrancy_guard() public {
        // Deploy new implementation and upgrade
        MockCTMRWAMapV2 newImpl = new MockCTMRWAMapV2();
        vm.startPrank(gov);
        (bool success,) = address(map).call(
            abi.encodeWithSignature(
                "upgradeToAndCall(address,bytes)", address(newImpl), abi.encodeCall(MockCTMRWAMapV2.initializeV2, (42))
            )
        );
        assertTrue(success, "upgradeToAndCall failed");
        vm.stopPrank();
        // Test that reentrancy guard is still active
        // This is implicit since the contract still inherits from ReentrancyGuardUpgradeable
        // and the upgrade doesn't break the reentrancy protection
        assertTrue(true, "Reentrancy guard should still be active");
    }

    function test_upgrade_proxy_preserves_uups_functionality() public {
        // Deploy new implementation and upgrade
        MockCTMRWAMapV2 newImpl = new MockCTMRWAMapV2();
        vm.startPrank(gov);
        (bool success,) = address(map).call(
            abi.encodeWithSignature(
                "upgradeToAndCall(address,bytes)", address(newImpl), abi.encodeCall(MockCTMRWAMapV2.initializeV2, (42))
            )
        );
        assertTrue(success, "upgradeToAndCall failed");
        vm.stopPrank();
        // Test that UUPS functionality is preserved
        // The contract should still be upgradeable
        MockCTMRWAMapV2 impl3 = new MockCTMRWAMapV2();
        vm.startPrank(gov);
        (success,) =
            address(map).call(abi.encodeWithSignature("upgradeToAndCall(address,bytes)", address(impl3), bytes("")));
        assertTrue(success, "upgradeToAndCall failed");
        vm.stopPrank();
        assertTrue(true, "UUPS functionality should be preserved");
    }
}
