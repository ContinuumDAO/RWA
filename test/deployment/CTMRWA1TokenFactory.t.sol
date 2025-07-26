// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.27;

import { console } from "forge-std/console.sol";
import { CTMRWA1 } from "../../src/core/CTMRWA1.sol";
import { ICTMRWA1 } from "../../src/core/ICTMRWA1.sol";
import { CTMRWA1TokenFactory } from "../../src/deployment/CTMRWA1TokenFactory.sol";
import { ICTMRWA1TokenFactory } from "../../src/deployment/ICTMRWA1TokenFactory.sol";
import { Helpers } from "../helpers/Helpers.sol";
import {Address} from "../../src/utils/CTMRWAUtils.sol";

contract MockDeployer {
// Used to test onlyDeployer modifier
}

contract CTMRWA1TokenFactoryTest is Helpers {
    CTMRWA1TokenFactory public factory;
    address public ctmRwaMap;
    address public ctmRwaDeployer;
    address public notDeployer = address(0xdead);
    address public ctmRwa1X;
    string public tokenName = "Test RWA Token";
    string public symbol = "TRWA";
    uint8 public decimals = 18;
    string public baseURI = "GFLD";
    uint256[] public slotNumbers = [1, 2, 3];
    string[] public slotNames = ["Class A", "Class B", "Class C"];

    function setUp() public override {
        Helpers.setUp(); // Ensure all helpers and contracts are deployed
        // Use the deployed tokenFactory, map, and deployer from helpers
        factory = tokenFactory;
        ctmRwaMap = address(map);
        ctmRwaDeployer = address(deployer);
        ctmRwa1X = address(rwa1X);
        // admin is already set by Helpers
    }

    function getDeployData(
        uint256 id,
        address _admin,
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        string memory _baseURI,
        uint256[] memory _slotNumbers,
        string[] memory _slotNames,
        address _ctmRwa1X
    ) public pure returns (bytes memory) {
        return abi.encode(id, _admin, _name, _symbol, _decimals, _baseURI, _slotNumbers, _slotNames, _ctmRwa1X);
    }

    function test_OnlyDeployerCanDeploy() public {
        bytes memory deployData =
            getDeployData(ID, admin, tokenName, symbol, decimals, baseURI, slotNumbers, slotNames, ctmRwa1X);
        // Should succeed as deployer
        vm.prank(address(deployer));
        address deployed = factory.deploy(deployData);
        assertTrue(deployed != address(0), "Deployment should succeed");
        // Try as notDeployer
        vm.prank(notDeployer);
        vm.expectRevert(abi.encodeWithSelector(ICTMRWA1TokenFactory.CTMRWA1TokenFactory_OnlyAuthorized.selector, Address.Sender, Address.Deployer));
        factory.deploy(deployData);
    }

    function test_DeployInitializesSlotData() public {
        bytes memory deployData =
            getDeployData(ID, admin, tokenName, symbol, decimals, baseURI, slotNumbers, slotNames, ctmRwa1X);
        vm.prank(address(deployer));
        address deployed = factory.deploy(deployData);
        ICTMRWA1 token = ICTMRWA1(deployed);
        (uint256[] memory slots, string[] memory names) = token.getAllSlots();
        assertEq(slots.length, slotNumbers.length, "Slot count should match");
        for (uint256 i = 0; i < slots.length; i++) {
            assertEq(slots[i], slotNumbers[i], "Slot number mismatch");
            assertEq(keccak256(bytes(names[i])), keccak256(bytes(slotNames[i])), "Slot name mismatch");
        }
    }

    function test_DeployWithNoSlots() public {
        uint256[] memory emptySlots = new uint256[](0);
        string[] memory emptyNames = new string[](0);
        bytes memory deployData =
            getDeployData(ID, admin, tokenName, symbol, decimals, baseURI, emptySlots, emptyNames, ctmRwa1X);
        vm.prank(address(deployer));
        address deployed = factory.deploy(deployData);
        ICTMRWA1 token = ICTMRWA1(deployed);
        (uint256[] memory slots,) = token.getAllSlots();
        assertEq(slots.length, 0, "No slots should be initialized");
    }

    function test_DeployDeterministicAddress() public {
        bytes memory deployData =
            getDeployData(ID, admin, tokenName, symbol, decimals, baseURI, slotNumbers, slotNames, ctmRwa1X);
        vm.prank(address(deployer));
        address deployed1 = factory.deploy(deployData);
        // Deploy again with same ID and data should revert (CREATE2 collision)
        vm.prank(address(deployer));
        vm.expectRevert();
        factory.deploy(deployData);
        // Deploy with different ID should succeed
        bytes memory deployData2 =
            getDeployData(ID + 1, admin, tokenName, symbol, decimals, baseURI, slotNumbers, slotNames, ctmRwa1X);
        vm.prank(address(deployer));
        address deployed2 = factory.deploy(deployData2);
        assertTrue(deployed2 != address(0) && deployed2 != deployed1, "Should deploy at a new address");
    }

    function test_FuzzDeploy(uint256 fuzzID, uint8 fuzzDecimals) public {
        fuzzID = bound(fuzzID, 1, type(uint256).max);
        fuzzDecimals = uint8(bound(fuzzDecimals, 0, 36));
        bytes memory deployData =
            getDeployData(fuzzID, admin, tokenName, symbol, fuzzDecimals, baseURI, slotNumbers, slotNames, ctmRwa1X);
        vm.prank(address(deployer));
        address deployed = factory.deploy(deployData);
        assertTrue(deployed != address(0), "Fuzz deploy should succeed");
    }

    function test_GasUsageDeploy() public {
        bytes memory deployData =
            getDeployData(ID, admin, tokenName, symbol, decimals, baseURI, slotNumbers, slotNames, ctmRwa1X);
        uint256 gasStart = gasleft();
        vm.prank(address(deployer));
        factory.deploy(deployData);
        uint256 gasUsed = gasStart - gasleft();
        console.log("Gas used for deploy:", gasUsed);
        assertLt(gasUsed, 4_700_000, "Gas usage should be reasonable");
    }

    function test_RevertOnInvalidDeployer() public {
        bytes memory deployData =
            getDeployData(ID, admin, tokenName, symbol, decimals, baseURI, slotNumbers, slotNames, ctmRwa1X);
        vm.prank(notDeployer);
        vm.expectRevert(abi.encodeWithSelector(ICTMRWA1TokenFactory.CTMRWA1TokenFactory_OnlyAuthorized.selector, Address.Sender, Address.Deployer));
        factory.deploy(deployData);
    }

    function test_DeployEmitsContract() public {
        bytes memory deployData =
            getDeployData(ID, admin, tokenName, symbol, decimals, baseURI, slotNumbers, slotNames, ctmRwa1X);
        vm.prank(address(deployer));
        address deployed = factory.deploy(deployData);
        assertTrue(deployed != address(0), "Deployment should emit contract address");
    }

    // Invariant: Deployed address is deterministic for same salt/data
    function invariant_DeterministicAddress() public {
        bytes memory deployData =
            getDeployData(ID, admin, tokenName, symbol, decimals, baseURI, slotNumbers, slotNames, ctmRwa1X);
        vm.prank(address(deployer));
        address deployed1 = factory.deploy(deployData);
        // Compute expected address using CREATE2 formula
        bytes32 salt = bytes32(ID);
        bytes memory bytecode = abi.encodePacked(
            type(CTMRWA1).creationCode, abi.encode(admin, ctmRwaMap, tokenName, symbol, decimals, baseURI, ctmRwa1X)
        );
        bytes32 hash = keccak256(abi.encodePacked(bytes1(0xff), address(factory), salt, keccak256(bytecode)));
        address expected = address(uint160(uint256(hash)));
        assertEq(deployed1, expected, "Deployed address should match CREATE2 formula");
    }
}
