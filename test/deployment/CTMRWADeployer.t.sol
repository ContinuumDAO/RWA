// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.27;

import { ICTMRWA1 } from "../../src/core/ICTMRWA1.sol";

import { IC3GovernDApp } from "@c3caller/gov/IC3GovernDApp.sol";
import { C3ErrorParam } from "@c3caller/utils/C3CallerUtils.sol";

import { ICTMRWADeployInvest } from "../../src/deployment/ICTMRWADeployInvest.sol";
import { ICTMRWADeployer } from "../../src/deployment/ICTMRWADeployer.sol";
import { ICTMRWA1DividendFactory } from "../../src/dividend/ICTMRWA1DividendFactory.sol";
import { ICTMRWA1SentryManager } from "../../src/sentry/ICTMRWA1SentryManager.sol";
import { ICTMRWAMap } from "../../src/shared/ICTMRWAMap.sol";
import { ICTMRWA1StorageManager } from "../../src/storage/ICTMRWA1StorageManager.sol";

import { CTMRWAErrorParam } from "../../src/utils/CTMRWAUtils.sol";
import { Helpers } from "../helpers/Helpers.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { console } from "forge-std/console.sol";

error CTMRWA1X_InvalidLength(CTMRWAErrorParam);

contract TestCTMRWADeployer is Helpers {
    using Strings for *;

    function setUp() public override {
        Helpers.setUp();
    }

    function test_deploysAllContracts() public {
        vm.startPrank(address(rwa1X));
        uint256 testID = 12_345;
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
        uint256 testID = 23_456;
        bytes memory deployData = abi.encode(
            testID, tokenAdmin, "TestToken2", "TTK2", 18, "GFLD", new uint256[](0), new string[](0), address(rwa1X)
        );
        deployer.deploy(testID, RWA_TYPE, VERSION, deployData);
        vm.stopPrank();
        
        // Call deployNewInvestment as tokenAdmin (who has token balances and approvals)
        vm.startPrank(tokenAdmin);
        address investAddr = deployer.deployNewInvestment(testID, RWA_TYPE, VERSION, address(usdc));
        assertTrue(investAddr != address(0), "Investment not deployed");
        vm.stopPrank();
    }

    function test_mapHasCorrectContracts() public {
        vm.startPrank(address(rwa1X));
        uint256 testID = 34_567;
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
        uint256 testID = 45_678;
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
        uint256 testID = 56_789;
        bytes memory deployData = abi.encode(
            testID, tokenAdmin, "TestToken5", "TTK5", 18, "GFLD", new uint256[](0), new string[](0), address(rwa1X)
        );
        uint256 wrongVersion = VERSION + 1;
        vm.expectRevert(); // Expect a plain revert
        deployer.deploy(testID, RWA_TYPE, wrongVersion, deployData);
        vm.stopPrank();
    }

    function test_revertIfNotRwaX() public {
        uint256 testID = 67_890;
        bytes memory deployData = abi.encode(
            testID, tokenAdmin, "TestToken6", "TTK6", 18, "GFLD", new uint256[](0), new string[](0), address(rwa1X)
        );
        vm.expectRevert(abi.encodeWithSelector(ICTMRWADeployer.CTMRWADeployer_OnlyAuthorized.selector, CTMRWAErrorParam.Sender, CTMRWAErrorParam.RWAX));
        deployer.deploy(testID, RWA_TYPE, VERSION, deployData);
    }

    function test_revertIfZeroAddress() public {
        vm.startPrank(gov); // Run as governor
        // Try to set a zero address for a critical dependency
        vm.expectRevert(abi.encodeWithSelector(ICTMRWADeployer.CTMRWADeployer_IsZeroAddress.selector, CTMRWAErrorParam.Gateway));
        deployer.setGateway(address(0));
        vm.stopPrank();
    }

    // Governance Setter Access Control
    function test_onlyGovernorCanCallSetters(address nonGov) public {
        vm.assume(nonGov != gov && nonGov != address(0));
        vm.assume(!deployer.txSenders(nonGov));
        address dummy = address(0x1234);
        vm.startPrank(nonGov);
        vm.expectRevert(
            abi.encodeWithSelector(
                IC3GovernDApp.C3GovernDApp_OnlyAuthorized.selector, C3ErrorParam.Sender, C3ErrorParam.GovOrC3Caller
            )
        );
        deployer.setGateway(dummy);
        vm.expectRevert(
            abi.encodeWithSelector(
                IC3GovernDApp.C3GovernDApp_OnlyAuthorized.selector, C3ErrorParam.Sender, C3ErrorParam.GovOrC3Caller
            )
        );
        deployer.setFeeManager(dummy);
        vm.expectRevert(
            abi.encodeWithSelector(
                IC3GovernDApp.C3GovernDApp_OnlyAuthorized.selector, C3ErrorParam.Sender, C3ErrorParam.GovOrC3Caller
            )
        );
        deployer.setRwaX(dummy);
        vm.expectRevert(
            abi.encodeWithSelector(
                IC3GovernDApp.C3GovernDApp_OnlyAuthorized.selector, C3ErrorParam.Sender, C3ErrorParam.GovOrC3Caller
            )
        );
        deployer.setMap(dummy);
        vm.expectRevert(
            abi.encodeWithSelector(
                IC3GovernDApp.C3GovernDApp_OnlyAuthorized.selector, C3ErrorParam.Sender, C3ErrorParam.GovOrC3Caller
            )
        );
        deployer.setErc20DeployerAddress(dummy);
        vm.expectRevert(
            abi.encodeWithSelector(
                IC3GovernDApp.C3GovernDApp_OnlyAuthorized.selector, C3ErrorParam.Sender, C3ErrorParam.GovOrC3Caller
            )
        );
        deployer.setDeployInvest(dummy);
        vm.stopPrank();
    }

    // Double Investment Revert
    function test_revertOnDoubleInvestment() public {
        vm.startPrank(address(rwa1X));
        uint256 testID = 88_888;
        bytes memory deployData = abi.encode(
            testID, tokenAdmin, "DoubleInvest", "DBL", 18, "GFLD", new uint256[](0), new string[](0), address(rwa1X)
        );
        deployer.deploy(testID, RWA_TYPE, VERSION, deployData);
        vm.stopPrank();
        
        // Call deployNewInvestment as tokenAdmin (who has token balances and approvals)
        vm.startPrank(tokenAdmin);
        deployer.deployNewInvestment(testID, RWA_TYPE, VERSION, address(usdc));
        vm.expectRevert(abi.encodeWithSelector(ICTMRWADeployer.CTMRWADeployer_InvalidContract.selector, CTMRWAErrorParam.Invest));
        deployer.deployNewInvestment(testID, RWA_TYPE, VERSION, address(usdc));
        vm.stopPrank();
    }

    // Incompatible CTMRWAErrorParam Type/Version
    function test_revertOnIncompatibleRWATypeOrVersion() public {
        vm.startPrank(address(rwa1X));
        uint256 testID = 99_999;
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

    // Setter Zero CTMRWAErrorParam Revert (all setters)
    function test_revertIfZeroAddressSetters() public {
        vm.startPrank(gov);
        vm.expectRevert(abi.encodeWithSelector(ICTMRWADeployer.CTMRWADeployer_IsZeroAddress.selector, CTMRWAErrorParam.Gateway));
        deployer.setGateway(address(0));
        vm.expectRevert(
            abi.encodeWithSelector(ICTMRWADeployer.CTMRWADeployer_IsZeroAddress.selector, CTMRWAErrorParam.FeeManager)
        );
        deployer.setFeeManager(address(0));
        vm.expectRevert(abi.encodeWithSelector(ICTMRWADeployer.CTMRWADeployer_IsZeroAddress.selector, CTMRWAErrorParam.RWAX));
        deployer.setRwaX(address(0));
        vm.expectRevert(abi.encodeWithSelector(ICTMRWADeployer.CTMRWADeployer_IsZeroAddress.selector, CTMRWAErrorParam.Map));
        deployer.setMap(address(0));
        vm.expectRevert(
            abi.encodeWithSelector(ICTMRWADeployer.CTMRWADeployer_IsZeroAddress.selector, CTMRWAErrorParam.ERC20Deployer)
        );
        deployer.setErc20DeployerAddress(address(0));
        vm.expectRevert(
            abi.encodeWithSelector(ICTMRWADeployer.CTMRWADeployer_IsZeroAddress.selector, CTMRWAErrorParam.DeployInvest)
        );
        deployer.setDeployInvest(address(0));
        vm.stopPrank();
    }

    // Explicit array input test cases spanning length 1 to 50
    function test_arrayInputs_explicit() public {
        uint256[] memory lengths = new uint256[](7);
        lengths[0] = 1;
        lengths[1] = 5;
        lengths[2] = 10;
        lengths[3] = 20;
        lengths[4] = 30;
        lengths[5] = 40;
        lengths[6] = 50;
        for (uint256 i = 0; i < lengths.length; i++) {
            uint256 len = lengths[i];
            uint256[] memory slotNumbers = new uint256[](len);
            string[] memory slotNames = new string[](len);
            for (uint256 j = 0; j < len; j++) {
                slotNumbers[j] = j + 1;
                slotNames[j] = string(abi.encodePacked("Slot", Strings.toString(j + 1)));
            }
            vm.startPrank(address(rwa1X));
            uint256 testID = 654_321 + i;
            bytes memory deployData =
                abi.encode(testID, tokenAdmin, "ArrayToken", "ARY", 18, "GFLD", slotNumbers, slotNames, address(rwa1X));
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
        uint256 testID = 77_777;
        bytes memory deployData = abi.encode(
            testID, tokenAdmin, "NoFactory", "NOF", 18, "GFLD", new uint256[](0), new string[](0), address(rwa1X)
        );
        vm.expectRevert();
        deployer.deploy(testID, RWA_TYPE, VERSION, deployData);
        vm.stopPrank();
    }

    // Commission Rate Tests
    function test_setInvestCommissionRate_success() public {
        // Warp time forward to avoid the "change too soon" error
        vm.warp(block.timestamp + 30 days + 1);
        
        vm.startPrank(gov);
        uint256 newCommissionRate = 100; // 1% - within the 100 limit from 0
        deployer.setInvestCommissionRate(newCommissionRate);
        assertEq(deployer.getInvestCommissionRate(), newCommissionRate, "Commission rate should be updated");
        vm.stopPrank();
    }

    function test_setInvestCommissionRate_onlyGovernor() public {
        vm.startPrank(user1);
        vm.expectRevert(
            abi.encodeWithSelector(
                IC3GovernDApp.C3GovernDApp_OnlyAuthorized.selector, C3ErrorParam.Sender, C3ErrorParam.GovOrC3Caller
            )
        );
        deployer.setInvestCommissionRate(100);
        vm.stopPrank();
    }

    function test_setInvestCommissionRate_outOfBounds() public {
        vm.startPrank(gov);
        vm.expectRevert(abi.encodeWithSelector(ICTMRWADeployer.CTMRWADeployer_CommissionRateOutOfBounds.selector, CTMRWAErrorParam.Commission));
        deployer.setInvestCommissionRate(10001); // > 10000 (100%)
        vm.stopPrank();
    }

    function test_setInvestCommissionRate_increaseTooMuch() public {
        // Warp time forward to avoid the "change too soon" error
        vm.warp(block.timestamp + 30 days + 1);
        
        vm.startPrank(gov);
        // Set initial commission rate
        deployer.setInvestCommissionRate(100); // 1%
        
        // Try to increase by more than 100 (1%)
        vm.expectRevert(abi.encodeWithSelector(ICTMRWADeployer.CTMRWADeployer_CommissionRateIncreasedTooMuch.selector, CTMRWAErrorParam.Commission));
        deployer.setInvestCommissionRate(250); // 2.5% - increase of 1.5%
        vm.stopPrank();
    }

    function test_setInvestCommissionRate_changeTooSoon() public {
        // Warp time forward to avoid the "change too soon" error for initial set
        vm.warp(block.timestamp + 30 days + 1);
        
        vm.startPrank(gov);
        // Set initial commission rate
        deployer.setInvestCommissionRate(100); // 1%
        
        // Try to increase within 30 days (don't warp time)
        vm.expectRevert(abi.encodeWithSelector(ICTMRWADeployer.CTMRWADeployer_CommissionRateChangeTooSoon.selector, CTMRWAErrorParam.Commission));
        deployer.setInvestCommissionRate(150); // 1.5% - increase of 0.5%
        vm.stopPrank();
    }

    function test_setInvestCommissionRate_decreaseAllowed() public {
        // Warp time forward to avoid the "change too soon" error
        vm.warp(block.timestamp + 30 days + 1);
        
        vm.startPrank(gov);
        // Set initial commission rate (within 100 limit from 0)
        deployer.setInvestCommissionRate(100); // 1%
        
        // Decrease should be allowed immediately
        deployer.setInvestCommissionRate(50); // 0.5%
        assertEq(deployer.getInvestCommissionRate(), 50, "Commission rate should be decreased");
        vm.stopPrank();
    }

    function test_setInvestCommissionRate_increaseAfter30Days() public {
        // Warp time forward to avoid the "change too soon" error for initial set
        uint256 firstTime = 30 days + 1;
        vm.warp(firstTime);
        
        vm.startPrank(gov);
        // Set initial commission rate
        deployer.setInvestCommissionRate(100); // 1%
        vm.stopPrank();
        
        // Warp to 60 days + 2 seconds from start (30 days after first set)
        vm.warp(firstTime + 30 days + 1);
        
        vm.startPrank(gov);
        // Now increase should be allowed
        deployer.setInvestCommissionRate(150); // 1.5% - increase of 0.5%
        assertEq(deployer.getInvestCommissionRate(), 150, "Commission rate should be increased after 30 days");
        vm.stopPrank();
    }

    function test_setInvestCommissionRate_maximumIncrease() public {
        // Warp time forward to avoid the "change too soon" error for initial set
        uint256 firstTime = 30 days + 1;
        vm.warp(firstTime);
        
        vm.startPrank(gov);
        // Set initial commission rate
        deployer.setInvestCommissionRate(100); // 1%
        vm.stopPrank();
        
        // Warp to 60 days + 2 seconds from start (30 days after first set)
        vm.warp(firstTime + 30 days + 1);
        
        vm.startPrank(gov);
        // Maximum increase of 100 (1%)
        deployer.setInvestCommissionRate(200); // 2% - increase of exactly 1%
        assertEq(deployer.getInvestCommissionRate(), 200, "Commission rate should be increased by maximum allowed");
        vm.stopPrank();
    }

    function test_getInvestCommissionRate() public {
        // Warp time forward to avoid the "change too soon" error
        vm.warp(block.timestamp + 30 days + 1);
        
        vm.startPrank(gov);
        uint256 commissionRate = 100; // 1% - within the 100 limit from 0
        deployer.setInvestCommissionRate(commissionRate);
        assertEq(deployer.getInvestCommissionRate(), commissionRate, "Should return correct commission rate");
        vm.stopPrank();
    }

    function test_getLastCommissionRateChange() public {
        // Warp time forward to avoid the "change too soon" error
        vm.warp(block.timestamp + 30 days + 1);
        
        vm.startPrank(gov);
        uint256 initialTime = block.timestamp;
        deployer.setInvestCommissionRate(100);
        
        uint256 lastChange = deployer.getLastCommissionRateChange();
        assertEq(lastChange, initialTime, "Should return correct last change timestamp");
        vm.stopPrank();
    }

    function test_getLastCommissionRateChange_zeroAddress() public {
        // Try to set deployInvest to zero address - this should fail
        vm.startPrank(gov);
        vm.expectRevert(abi.encodeWithSelector(ICTMRWADeployer.CTMRWADeployer_IsZeroAddress.selector, CTMRWAErrorParam.DeployInvest));
        deployer.setDeployInvest(address(0));
        vm.stopPrank();
    }

    function test_setInvestCommissionRate_zeroAddress() public {
        // Try to set deployInvest to zero address - this should fail
        vm.startPrank(gov);
        vm.expectRevert(abi.encodeWithSelector(ICTMRWADeployer.CTMRWADeployer_IsZeroAddress.selector, CTMRWAErrorParam.DeployInvest));
        deployer.setDeployInvest(address(0));
        vm.stopPrank();
    }

    function test_commissionRateEvent() public {
        // Warp time forward to avoid the "change too soon" error
        vm.warp(block.timestamp + 30 days + 1);
        
        vm.startPrank(gov);
        uint256 newRate = 100; // 1% - within the 100 limit from 0
        
        vm.expectEmit(true, true, true, true);
        emit ICTMRWADeployer.CommissionRateChanged(newRate);
        deployer.setInvestCommissionRate(newRate);
        vm.stopPrank();
    }

    function test_fuzz_setInvestCommissionRate_validRange(uint256 rate) public {
        vm.assume(rate <= 100); // Valid range: 0 to 100 (0% to 1%) - within increase limit from 0
        
        // Warp time forward to avoid the "change too soon" error
        vm.warp(block.timestamp + 30 days + 1);
        
        vm.startPrank(gov);
        deployer.setInvestCommissionRate(rate);
        assertEq(deployer.getInvestCommissionRate(), rate, "Commission rate should be set correctly");
        vm.stopPrank();
    }

    function test_fuzz_setInvestCommissionRate_invalidRange(uint256 rate) public {
        vm.assume(rate > 10000); // Invalid range: > 10000 (100%)
        
        vm.startPrank(gov);
        vm.expectRevert(abi.encodeWithSelector(ICTMRWADeployer.CTMRWADeployer_CommissionRateOutOfBounds.selector, CTMRWAErrorParam.Commission));
        deployer.setInvestCommissionRate(rate);
        vm.stopPrank();
    }
}
