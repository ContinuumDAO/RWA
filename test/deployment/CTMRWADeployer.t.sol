// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.22;

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

    function test_deployNewInvestment() public {
        vm.startPrank(address(rwa1X));
        uint256 testID = 23456;
        bytes memory deployData = abi.encode(
            testID, tokenAdmin, "TestToken2", "TTK2", 18, "GFLD", new uint256[](0), new string[](0), address(rwa1X)
        );
        (address tokenAddr,,,) = deployer.deploy(testID, RWA_TYPE, VERSION, deployData);
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
}
