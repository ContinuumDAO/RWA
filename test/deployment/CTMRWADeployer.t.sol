// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.27;

import { console } from "forge-std/console.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { Helpers } from "../helpers/Helpers.sol";
import { ICTMRWA1 } from "../../src/core/ICTMRWA1.sol";
import { ICTMRWAMap } from "../../src/shared/ICTMRWAMap.sol";
import { ICTMRWADeployer } from "../../src/deployment/ICTMRWADeployer.sol";
import { ICTMRWA1DividendFactory } from "../../src/dividend/ICTMRWA1DividendFactory.sol";
import { ICTMRWA1StorageManager } from "../../src/storage/ICTMRWA1StorageManager.sol";
import { ICTMRWA1SentryManager } from "../../src/sentry/ICTMRWA1SentryManager.sol";
import { ICTMRWADeployInvest } from "../../src/deployment/ICTMRWADeployInvest.sol";
import { Address, RWA } from "../../src/CTMRWAUtils.sol";
import { Uint } from "../../src/CTMRWAUtils.sol";

error CTMRWA1X_InvalidLength(Uint);

contract TestCTMRWADeployer is Helpers {
    using Strings for *;

    function setUp() public override {
        Helpers.setUp();
    }

    function test_deploysAllContracts() public {
        vm.startPrank(address(rwa1X));
        uint256 testID = 12345;
        bytes memory deployData = abi.encode(
            testID, tokenAdmin, "TestToken", "TTK", 18, "GFLD", new uint256[](0), new string[](0), address(rwa1X)
        );
        (address tokenAddr, address dividendAddr, address storageAddr, address sentryAddr) =
            deployer.deploy(testID, RWA_TYPE, VERSION, deployData);
        assertTrue(tokenAddr != address(0), "CTMRWA1 not deployed");
        assertTrue(dividendAddr != address(0), "Dividend not deployed");
        assertTrue(storageAddr != address(0), "Storage not deployed");
        assertTrue(sentryAddr != address(0), "Sentry not deployed");
        vm.stopPrank();
    }

    function test_fuzz_deploysAllContracts(uint256 testID) public {
        vm.startPrank(address(rwa1X));
        bytes memory deployData = abi.encode(
            testID, tokenAdmin, "FuzzToken", "FZZ", 18, "GFLD", new uint256[](0), new string[](0), address(rwa1X)
        );
        (address tokenAddr, address dividendAddr, address storageAddr, address sentryAddr) =
            deployer.deploy(testID, RWA_TYPE, VERSION, deployData);
        assertTrue(tokenAddr != address(0), "CTMRWA1 not deployed");
        assertTrue(dividendAddr != address(0), "Dividend not deployed");
        assertTrue(storageAddr != address(0), "Storage not deployed");
        assertTrue(sentryAddr != address(0), "Sentry not deployed");
        vm.stopPrank();
    }

    function test_deployNewInvestment() public {
        vm.startPrank(address(rwa1X));
        uint256 testID = 23456;
        bytes memory deployData = abi.encode(
            testID, tokenAdmin, "TestToken2", "TTK2", 18, "GFLD", new uint256[](0), new string[](0), address(rwa1X)
        );
        deployer.deploy(testID, RWA_TYPE, VERSION, deployData);
        address investAddr = deployer.deployNewInvestment(testID, RWA_TYPE, VERSION, address(usdc));
        assertTrue(investAddr != address(0), "Investment not deployed");
        vm.stopPrank();
    }

    function test_mapHasCorrectContracts() public {
        vm.startPrank(address(rwa1X));
        uint256 testID = 34567;
        bytes memory deployData = abi.encode(
            testID, tokenAdmin, "TestToken3", "TTK3", 18, "GFLD", new uint256[](0), new string[](0), address(rwa1X)
        );
        (address tokenAddr, address dividendAddr, address storageAddr, address sentryAddr) =
            deployer.deploy(testID, RWA_TYPE, VERSION, deployData);
        (bool ok, address mapTokenAddr) = map.getTokenContract(testID, RWA_TYPE, VERSION);
        assertTrue(ok && mapTokenAddr == tokenAddr, "Map token address incorrect");
        (bool okDiv, address mapDivAddr) = map.getDividendContract(testID, RWA_TYPE, VERSION);
        assertTrue(okDiv && mapDivAddr == dividendAddr, "Map dividend address incorrect");
        (bool okStor, address mapStorAddr) = map.getStorageContract(testID, RWA_TYPE, VERSION);
        assertTrue(okStor && mapStorAddr == storageAddr, "Map storage address incorrect");
        (bool okSentry, address mapSentryAddr) = map.getSentryContract(testID, RWA_TYPE, VERSION);
        assertTrue(okSentry && mapSentryAddr == sentryAddr, "Map sentry address incorrect");
        vm.stopPrank();
    }

    function test_revertOnWrongRWAType() public {
        vm.startPrank(address(rwa1X));
        uint256 testID = 45678;
        bytes memory deployData = abi.encode(
            testID, tokenAdmin, "TestToken4", "TTK4", 18, "GFLD", new uint256[](0), new string[](0), address(rwa1X)
        );
        uint256 wrongType = RWA_TYPE + 1;
        vm.expectRevert(); // Expect a plain revert
        deployer.deploy(testID, wrongType, VERSION, deployData);
        vm.stopPrank();
    }

    function test_revertOnWrongVersion() public {
        vm.startPrank(address(rwa1X));
        uint256 testID = 56789;
        bytes memory deployData = abi.encode(
            testID, tokenAdmin, "TestToken5", "TTK5", 18, "GFLD", new uint256[](0), new string[](0), address(rwa1X)
        );
        uint256 wrongVersion = VERSION + 1;
        vm.expectRevert(); // Expect a plain revert
        deployer.deploy(testID, RWA_TYPE, wrongVersion, deployData);
        vm.stopPrank();
    }

    function test_revertIfNotRwaX() public {
        uint256 testID = 67890;
        bytes memory deployData = abi.encode(
            testID, tokenAdmin, "TestToken6", "TTK6", 18, "GFLD", new uint256[](0), new string[](0), address(rwa1X)
        );
        vm.expectRevert(abi.encodeWithSelector(ICTMRWADeployer.CTMRWADeployer_Unauthorized.selector, Address.Sender));
        deployer.deploy(testID, RWA_TYPE, VERSION, deployData);
    }

    function test_revertIfZeroAddress() public {
        vm.startPrank(gov); // Run as governor
        // Try to set a zero address for a critical dependency
        vm.expectRevert(abi.encodeWithSelector(ICTMRWADeployer.CTMRWADeployer_IsZeroAddress.selector, Address.Gateway));
        deployer.setGateway(address(0));
        vm.stopPrank();
    }

    // Governance Setter Access Control
    function test_onlyGovernorCanCallSetters(address nonGov) public {
        vm.assume(nonGov != gov && nonGov != address(0));
        address dummy = address(0x1234);
        vm.startPrank(nonGov);
        vm.expectRevert("Gov FORBIDDEN");
        deployer.setGateway(dummy);
        vm.expectRevert("Gov FORBIDDEN");
        deployer.setFeeManager(dummy);
        vm.expectRevert("Gov FORBIDDEN");
        deployer.setRwaX(dummy);
        vm.expectRevert("Gov FORBIDDEN");
        deployer.setMap(dummy);
        vm.expectRevert("Gov FORBIDDEN");
        deployer.setErc20DeployerAddress(dummy);
        vm.expectRevert("Gov FORBIDDEN");
        deployer.setDeployInvest(dummy);
        vm.stopPrank();
    }

    // Double Investment Revert
    function test_revertOnDoubleInvestment() public {
        vm.startPrank(address(rwa1X));
        uint256 testID = 88888;
        bytes memory deployData = abi.encode(
            testID, tokenAdmin, "DoubleInvest", "DBL", 18, "GFLD", new uint256[](0), new string[](0), address(rwa1X)
        );
        deployer.deploy(testID, RWA_TYPE, VERSION, deployData);
        deployer.deployNewInvestment(testID, RWA_TYPE, VERSION, address(usdc));
        vm.expectRevert(abi.encodeWithSelector(ICTMRWADeployer.CTMRWADeployer_InvalidContract.selector, Address.Invest));
        deployer.deployNewInvestment(testID, RWA_TYPE, VERSION, address(usdc));
        vm.stopPrank();
    }

    // Incompatible RWA Type/Version
    function test_revertOnIncompatibleRWATypeOrVersion() public {
        vm.startPrank(address(rwa1X));
        uint256 testID = 99999;
        bytes memory deployData = abi.encode(
            testID, tokenAdmin, "BadType", "BAD", 18, "GFLD", new uint256[](0), new string[](0), address(rwa1X)
        );
        uint256 wrongType = RWA_TYPE + 100;
        uint256 wrongVersion = VERSION + 100;
        vm.expectRevert();
        deployer.deploy(testID, wrongType, VERSION, deployData);
        vm.expectRevert();
        deployer.deploy(testID, RWA_TYPE, wrongVersion, deployData);
        vm.stopPrank();
    }

    // Setter Updates State
    function test_settersUpdateState() public {
        vm.startPrank(gov);
        address dummy = address(0x5678);
        deployer.setGateway(dummy);
        assertEq(address(deployer.gateway()), dummy, "Gateway not updated");
        deployer.setFeeManager(dummy);
        assertEq(address(deployer.feeManager()), dummy, "FeeManager not updated");
        deployer.setRwaX(dummy);
        assertEq(address(deployer.rwaX()), dummy, "RwaX not updated");
        deployer.setMap(dummy);
        assertEq(address(deployer.ctmRwaMap()), dummy, "Map not updated");
        deployer.setErc20DeployerAddress(dummy);
        assertEq(address(deployer.erc20Deployer()), dummy, "Erc20Deployer not updated");
        deployer.setDeployInvest(dummy);
        assertEq(address(deployer.deployInvest()), dummy, "DeployInvest not updated");
        vm.stopPrank();
    }

    // Setter Zero Address Revert (all setters)
    function test_revertIfZeroAddressSetters() public {
        vm.startPrank(gov);
        vm.expectRevert(abi.encodeWithSelector(ICTMRWADeployer.CTMRWADeployer_IsZeroAddress.selector, Address.Gateway));
        deployer.setGateway(address(0));
        vm.expectRevert(abi.encodeWithSelector(ICTMRWADeployer.CTMRWADeployer_IsZeroAddress.selector, Address.FeeManager));
        deployer.setFeeManager(address(0));
        vm.expectRevert(abi.encodeWithSelector(ICTMRWADeployer.CTMRWADeployer_IsZeroAddress.selector, Address.RWAX));
        deployer.setRwaX(address(0));
        vm.expectRevert(abi.encodeWithSelector(ICTMRWADeployer.CTMRWADeployer_IsZeroAddress.selector, Address.Map));
        deployer.setMap(address(0));
        vm.expectRevert(abi.encodeWithSelector(ICTMRWADeployer.CTMRWADeployer_IsZeroAddress.selector, Address.Erc20Deployer));
        deployer.setErc20DeployerAddress(address(0));
        vm.expectRevert(abi.encodeWithSelector(ICTMRWADeployer.CTMRWADeployer_IsZeroAddress.selector, Address.DeployInvest));
        deployer.setDeployInvest(address(0));
        vm.stopPrank();
    }

    // Explicit array input test cases spanning length 1 to 50
    function test_arrayInputs_explicit() public {
        uint[] memory lengths = new uint[](7);
        lengths[0] = 1;
        lengths[1] = 5;
        lengths[2] = 10;
        lengths[3] = 20;
        lengths[4] = 30;
        lengths[5] = 40;
        lengths[6] = 50;
        for (uint i = 0; i < lengths.length; i++) {
            uint len = lengths[i];
            uint256[] memory slotNumbers = new uint256[](len);
            string[] memory slotNames = new string[](len);
            for (uint j = 0; j < len; j++) {
                slotNumbers[j] = j + 1;
                slotNames[j] = string(abi.encodePacked("Slot", Strings.toString(j + 1)));
            }
            vm.startPrank(address(rwa1X));
            uint256 testID = 654321 + i;
            bytes memory deployData = abi.encode(
                testID, tokenAdmin, "ArrayToken", "ARY", 18, "GFLD", slotNumbers, slotNames, address(rwa1X)
            );
            (address tokenAddr,,,) = deployer.deploy(testID, RWA_TYPE, VERSION, deployData);
            assertTrue(tokenAddr != address(0), "CTMRWA1 not deployed");
            vm.stopPrank();
        }
    }

    // Revert if Factory Not Set (ensure governor sets factory, rwa1X calls deploy)
    function test_revertIfFactoryNotSet() public {
        // Governor unsets the token factory
        vm.startPrank(gov);
        deployer.setTokenFactory(RWA_TYPE, VERSION, address(0));
        vm.stopPrank();
        // rwa1X tries to deploy, should revert due to missing factory
        vm.startPrank(address(rwa1X));
        uint256 testID = 77777;
        bytes memory deployData = abi.encode(
            testID, tokenAdmin, "NoFactory", "NOF", 18, "GFLD", new uint256[](0), new string[](0), address(rwa1X)
        );
        vm.expectRevert();
        deployer.deploy(testID, RWA_TYPE, VERSION, deployData);
        vm.stopPrank();
    }
}
