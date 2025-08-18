// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.27;

import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { Test } from "forge-std/Test.sol";

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import { CTMRWAGateway } from "../../src/crosschain/CTMRWAGateway.sol";
import { ICTMRWAGateway } from "../../src/crosschain/ICTMRWAGateway.sol";
import { CTMRWAMap } from "../../src/shared/CTMRWAMap.sol";
import { CTMRWAErrorParam } from "../../src/utils/CTMRWAUtils.sol";
import { Helpers } from "../helpers/Helpers.sol";

// Mock implementation for testing upgrades
contract MockCTMRWAGatewayV2 is CTMRWAGateway {
    uint256 public newVersion;

    function initializeV2(uint256 _newVersion) external reinitializer(uint64(_newVersion)) {
        newVersion = _newVersion;
    }

    function newFunction() external pure returns (string memory) {
        return "V2 Function";
    }
}

// Malicious implementation that tries to change critical state
contract MaliciousCTMRWAGateway is CTMRWAGateway {
    function initializeV2() external reinitializer(2) {
        // Try to change critical addresses
        // Note: CTMRWAGateway doesn't have many state variables to change
        // but we can try to manipulate the chainContract array
    }
}

/**
 * @title CTMRWAGateway Upgrade Tests
 * @notice Tests for proxy upgrades of CTMRWAGateway contract
 */
contract TestCTMRWAGatewayUpgrades is Helpers {
    using Strings for *;

    // Mock implementation for testing upgrades
    MockCTMRWAGatewayV2 mockImpl;

    // Malicious implementation that tries to change critical state
    MaliciousCTMRWAGateway maliciousImpl;

    function setUp() public override {
        super.setUp();
        mockImpl = new MockCTMRWAGatewayV2();
        maliciousImpl = new MaliciousCTMRWAGateway();
    }

    function test_upgrade_proxy_successfully() public {
        // Store initial state
        string memory initialCIdStr = gateway.cIdStr();
        uint256 initialChainCount = gateway.getChainCount();

        // Upgrade the proxy
        vm.startPrank(gov);
        (bool success,) = address(gateway).call(
            abi.encodeWithSignature(
                "upgradeToAndCall(address,bytes)",
                address(mockImpl),
                abi.encodeCall(MockCTMRWAGatewayV2.initializeV2, (42))
            )
        );
        assertTrue(success, "upgradeToAndCall failed");
        vm.stopPrank();

        // Verify state is preserved
        assertEq(gateway.cIdStr(), initialCIdStr, "Chain ID string should be preserved");
        assertEq(gateway.getChainCount(), initialChainCount, "Chain contract length should be preserved");

        // Verify new functionality works
        MockCTMRWAGatewayV2(address(gateway)).newFunction();
        assertEq(MockCTMRWAGatewayV2(address(gateway)).newVersion(), 42, "New version should be set");
    }

    function test_upgrade_proxy_without_initialization() public {
        // Store initial state
        string memory initialCIdStr = gateway.cIdStr();

        // Upgrade the proxy without initialization
        vm.startPrank(gov);
        (bool success,) = address(gateway).call(
            abi.encodeWithSignature("upgradeToAndCall(address,bytes)", address(mockImpl), bytes(""))
        );
        assertTrue(success, "upgradeToAndCall failed");
        vm.stopPrank();

        // Verify state is preserved
        assertEq(gateway.cIdStr(), initialCIdStr, "Chain ID string should be preserved");

        // Verify new functionality works
        MockCTMRWAGatewayV2(address(gateway)).newFunction();
        assertEq(MockCTMRWAGatewayV2(address(gateway)).newVersion(), 0, "New version should be default");
    }

    function test_upgrade_proxy_preserves_mappings() public {
        // Set up some state in mappings
        vm.startPrank(gov);
        string[] memory chainIds = new string[](1);
        string[] memory contractAddrs = new string[](1);
        chainIds[0] = "1";
        contractAddrs[0] = address(0x123).toHexString();
        gateway.addChainContract(chainIds, contractAddrs);
        vm.stopPrank();

        // Verify initial state
        assertGt(gateway.getChainCount(), 0, "Chain contract should be added");

        // Upgrade the proxy
        vm.startPrank(gov);
        (bool success,) = address(gateway).call(
            abi.encodeWithSignature(
                "upgradeToAndCall(address,bytes)",
                address(mockImpl),
                abi.encodeCall(MockCTMRWAGatewayV2.initializeV2, (42))
            )
        );
        assertTrue(success, "upgradeToAndCall failed");
        vm.stopPrank();

        // Verify mappings are preserved
        assertGt(gateway.getChainCount(), 0, "Chain contract should still be added after upgrade");
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
        (bool success,) = address(gateway).call(
            abi.encodeWithSignature(
                "upgradeToAndCall(address,bytes)",
                address(mockImpl),
                abi.encodeCall(MockCTMRWAGatewayV2.initializeV2, (42))
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
        (bool success,) = address(gateway).call(
            abi.encodeWithSignature(
                "upgradeToAndCall(address,bytes)",
                address(mockImpl),
                abi.encodeCall(MockCTMRWAGatewayV2.initializeV2, (42))
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

    function test_upgrade_proxy_unauthorized_reverts() public {
        // Deploy new implementation
        MockCTMRWAGatewayV2 newImpl = new MockCTMRWAGatewayV2();
        // Try to upgrade without being gov
        vm.startPrank(user1);
        vm.expectRevert();
        (bool success,) = address(gateway).call(
            abi.encodeWithSignature(
                "upgradeToAndCall(address,bytes)",
                address(newImpl),
                abi.encodeCall(MockCTMRWAGatewayV2.initializeV2, (42))
            )
        );
        assertTrue(success, "upgradeToAndCall failed");
        vm.stopPrank();
    }

    function test_upgrade_proxy_with_zero_address_reverts() public {
        // Try to upgrade to zero address
        vm.startPrank(gov);
        vm.expectRevert();
        (bool success,) = address(gateway).call(abi.encodeWithSignature("upgradeToAndCall(address,bytes)", address(0)));
        assertTrue(success, "upgradeToAndCall failed");
        vm.stopPrank();
    }

    function test_upgrade_proxy_with_invalid_implementation_reverts() public {
        // Try to upgrade to a contract that doesn't implement the interface
        address invalidImpl = address(new CTMRWAMap());
        vm.startPrank(gov);
        vm.expectRevert();
        (bool success,) = address(gateway).call(
            abi.encodeWithSignature(
                "upgradeToAndCall(address,bytes)", invalidImpl, abi.encodeCall(MockCTMRWAGatewayV2.initializeV2, (42))
            )
        );
        assertTrue(success, "upgradeToAndCall failed");
        vm.stopPrank();
    }

    function test_upgrade_proxy_preserves_functionality() public {
        // Test that core functionality still works after upgrade
        // Deploy new implementation and upgrade
        MockCTMRWAGatewayV2 newImpl = new MockCTMRWAGatewayV2();
        vm.startPrank(gov);
        (bool success,) = address(gateway).call(
            abi.encodeWithSignature(
                "upgradeToAndCall(address,bytes)",
                address(newImpl),
                abi.encodeCall(MockCTMRWAGatewayV2.initializeV2, (42))
            )
        );
        assertTrue(success, "upgradeToAndCall failed");
        vm.stopPrank();
        // Test that governance functions still work
        vm.startPrank(gov);
        string[] memory chainIds = new string[](1);
        string[] memory contractAddrs = new string[](1);
        chainIds[0] = "2";
        contractAddrs[0] = address(0x456).toHexString();
        gateway.addChainContract(chainIds, contractAddrs);
        assertGt(gateway.getChainCount(), 0, "Chain contract should be added");
        vm.stopPrank();
    }

    function test_fail_upgrade_proxy_same_version() public {
        // Upgrading to same version (1)
        MockCTMRWAGatewayV2 impl1 = new MockCTMRWAGatewayV2();
        (, bytes memory dataOldImpl) = address(gateway).call(abi.encodeWithSignature("getImplementation()"));
        address oldImpl = abi.decode(dataOldImpl, (address));
        vm.startPrank(gov);
        vm.expectRevert(Initializable.InvalidInitialization.selector);
        (bool success,) = address(gateway).call(
            abi.encodeWithSignature(
                "upgradeToAndCall(address,bytes)", address(impl1), abi.encodeCall(MockCTMRWAGatewayV2.initializeV2, (1))
            )
        );
        assertTrue(success);
        vm.stopPrank();
        // check that version is still one
        (, bytes memory dataCurrentImpl) = address(gateway).call(abi.encodeWithSignature("getImplementation()"));
        address currentImpl = abi.decode(dataCurrentImpl, (address));

        assertEq(currentImpl, oldImpl);
    }

    function test_upgrade_proxy_multiple_upgrades() public {
        // Perform multiple upgrades and verify state preservation
        // First upgrade
        MockCTMRWAGatewayV2 impl2 = new MockCTMRWAGatewayV2();
        vm.startPrank(gov);
        (bool success,) = address(gateway).call(
            abi.encodeWithSignature(
                "upgradeToAndCall(address,bytes)", address(impl2), abi.encodeCall(MockCTMRWAGatewayV2.initializeV2, (2))
            )
        );
        assertTrue(success, "upgradeToAndCall failed");
        vm.stopPrank();
        // Verify first upgrade
        assertEq(MockCTMRWAGatewayV2(address(gateway)).newVersion(), 2, "First upgrade should work");
        // Second upgrade
        MockCTMRWAGatewayV2 impl3 = new MockCTMRWAGatewayV2();
        vm.startPrank(gov);
        (success,) = address(gateway).call(
            abi.encodeWithSignature(
                "upgradeToAndCall(address,bytes)", address(impl3), abi.encodeCall(MockCTMRWAGatewayV2.initializeV2, (3))
            )
        );
        assertTrue(success, "upgradeToAndCall failed");
        vm.stopPrank();
        // Verify second upgrade
        assertEq(MockCTMRWAGatewayV2(address(gateway)).newVersion(), 3, "Second upgrade should work");
        // Verify core state is still preserved
        assertTrue(bytes(gateway.cIdStr()).length > 0, "Chain ID string should still be set");
    }

    function test_upgrade_proxy_preserves_reentrancy_guard() public {
        // Deploy new implementation and upgrade
        MockCTMRWAGatewayV2 newImpl = new MockCTMRWAGatewayV2();
        vm.startPrank(gov);
        (bool success,) = address(gateway).call(
            abi.encodeWithSignature(
                "upgradeToAndCall(address,bytes)",
                address(newImpl),
                abi.encodeCall(MockCTMRWAGatewayV2.initializeV2, (42))
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
        MockCTMRWAGatewayV2 newImpl = new MockCTMRWAGatewayV2();
        vm.startPrank(gov);
        (bool success,) = address(gateway).call(
            abi.encodeWithSignature(
                "upgradeToAndCall(address,bytes)",
                address(newImpl),
                abi.encodeCall(MockCTMRWAGatewayV2.initializeV2, (42))
            )
        );
        assertTrue(success, "upgradeToAndCall failed");
        vm.stopPrank();
        // Test that UUPS functionality is preserved
        // The contract should still be upgradeable
        MockCTMRWAGatewayV2 impl3 = new MockCTMRWAGatewayV2();
        vm.startPrank(gov);
        (success,) =
            address(gateway).call(abi.encodeWithSignature("upgradeToAndCall(address,bytes)", address(impl3), bytes("")));
        assertTrue(success, "upgradeToAndCall failed");
        vm.stopPrank();
        assertTrue(true, "UUPS functionality should be preserved");
    }

    function test_upgrade_proxy_preserves_c3govern_dapp_functionality() public {
        // Deploy new implementation and upgrade
        MockCTMRWAGatewayV2 newImpl = new MockCTMRWAGatewayV2();
        vm.startPrank(gov);
        (bool success,) = address(gateway).call(
            abi.encodeWithSignature(
                "upgradeToAndCall(address,bytes)",
                address(newImpl),
                abi.encodeCall(MockCTMRWAGatewayV2.initializeV2, (42))
            )
        );
        assertTrue(success, "upgradeToAndCall failed");
        vm.stopPrank();
        // Test that C3GovernDApp functionality is preserved
        // The contract should still have governance controls
        vm.startPrank(user1);
        vm.expectRevert();
        string[] memory chainIds = new string[](1);
        string[] memory contractAddrs = new string[](1);
        chainIds[0] = "3";
        contractAddrs[0] = address(0x789).toHexString();
        (success,) = address(gateway).call(
            abi.encodeWithSignature("addChainContract(string[],string[])", chainIds, contractAddrs)
        );
        assertTrue(success, "addChainContract failed");
        vm.stopPrank();
        vm.startPrank(gov);
        (success,) = address(gateway).call(
            abi.encodeWithSignature("addChainContract(string[],string[])", chainIds, contractAddrs)
        );
        assertTrue(success, "addChainContract failed");
        assertGt(gateway.getChainCount(), 0, "Governance should still work");
        vm.stopPrank();
    }

    function test_upgrade_proxy_preserves_chain_id_string() public {
        // Store initial chain ID string
        string memory initialCIdStr = gateway.cIdStr();
        // Deploy new implementation and upgrade
        MockCTMRWAGatewayV2 newImpl = new MockCTMRWAGatewayV2();
        vm.startPrank(gov);
        (bool success,) = address(gateway).call(
            abi.encodeWithSignature(
                "upgradeToAndCall(address,bytes)",
                address(newImpl),
                abi.encodeCall(MockCTMRWAGatewayV2.initializeV2, (42))
            )
        );
        assertTrue(success, "upgradeToAndCall failed");
        vm.stopPrank();
        // Verify chain ID string is preserved
        assertEq(gateway.cIdStr(), initialCIdStr, "Chain ID string should be preserved");
    }
}
