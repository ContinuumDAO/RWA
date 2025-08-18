// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.27;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {LoadDeployedContracts} from "./LoadDeployedContracts.s.sol";
import {DeployedContracts} from "./Utils.s.sol";

import {IFeeManager, FeeType} from "../src/managers/IFeeManager.sol";
import {ICTMRWAGateway} from "../src/crosschain/ICTMRWAGateway.sol";
import {ICTMRWA1X} from "../src/crosschain/ICTMRWA1X.sol";
import {ICTMRWADeployer} from "../src/deployment/ICTMRWADeployer.sol";
import {ICTMRWA1StorageManager} from "../src/storage/ICTMRWA1StorageManager.sol";
import {ICTMRWA1SentryManager} from "../src/sentry/ICTMRWA1SentryManager.sol";

contract ConfigureAssetX is Script {
    string chainIdStr;
    DeployedContracts[] deployedContracts;

    uint256 rwaType = vm.envUint("RWA_TYPE");
    uint256 version = vm.envUint("VERSION");

    string[] chainIdsStr;
    string[] gatewaysStr;
    string[] rwaXsStr;
    string[] storageManagersStr;
    string[] sentryManagersStr;

    address localGateway;

    function initFeeManager(uint256 i) public {
        console.log("Setting fees for chain: ");
        console.log(chainIdStr);

        address feeManager = deployedContracts[i].feeManager;
        string memory feeTokenStr = vm.toString(deployedContracts[i].feeToken);
        if (IFeeManager(feeManager).getFeeTokenList().length == 0) {
            IFeeManager(feeManager).addFeeToken(feeTokenStr);
            for (uint8 j = 0; j < deployedContracts.length; j++) {
                string memory chainIdStrJ = deployedContracts[j].chainIdStr;
                if (Strings.equal(chainIdStrJ, chainIdStr)) continue;
                string[] memory feeTokensStr = new string[](1);
                uint256[] memory baseFee = new uint256[](1);
                feeTokensStr[0] = feeTokenStr;
                baseFee[0] = 100;
                IFeeManager(feeManager).addFeeToken(chainIdStrJ, feeTokensStr, baseFee);
            }
            for (uint8 j = 0; j < 27; j++) {
                uint256 feeMultiplier = vm.envUint(string.concat("FEE_MULTIPLIER_", vm.toString(j)));
                IFeeManager(feeManager).setFeeMultiplier(FeeType(j), feeMultiplier);
            }
        }
    }

    function initGateway(uint256 i) public {
        address gateway = deployedContracts[i].gateway;
        ICTMRWAGateway(gateway).addChainContract(chainIdsStr, gatewaysStr);
        ICTMRWAGateway(gateway).attachRWAX(rwaType, version, chainIdsStr, rwaXsStr);
        ICTMRWAGateway(gateway).attachStorageManager(rwaType, version, chainIdsStr, storageManagersStr);
        ICTMRWAGateway(gateway).attachSentryManager(rwaType, version, chainIdsStr, sentryManagersStr);
    }

    function initRWA1X(uint256 i) public {
        address rwa1X = deployedContracts[i].rwa1X;
        ICTMRWA1X(rwa1X).setFallback(deployedContracts[i].rwa1XFallback);
        ICTMRWA1X(rwa1X).setCtmRwaDeployer(deployedContracts[i].deployer);
        ICTMRWA1X(rwa1X).setCtmRwaMap(deployedContracts[i].map);
    }

    function initDeployer(uint256 i) public {
        address deployer = deployedContracts[i].deployer;
        ICTMRWADeployer(deployer).setDeployInvest(deployedContracts[i].deployInvest);
        ICTMRWADeployer(deployer).setErc20DeployerAddress(deployedContracts[i].erc20Deployer);
        ICTMRWADeployer(deployer).setTokenFactory(rwaType, version, deployedContracts[i].tokenFactory);
        ICTMRWADeployer(deployer).setDividendFactory(rwaType, version, deployedContracts[i].dividendFactory);
        ICTMRWADeployer(deployer).setStorageFactory(rwaType, version, deployedContracts[i].storageManager);
        ICTMRWADeployer(deployer).setSentryFactory(rwaType, version, deployedContracts[i].sentryManager);
    }

    function initStorageManager(uint256 i) public {
        address storageManager = deployedContracts[i].storageManager;
        ICTMRWA1StorageManager(storageManager).setStorageUtils(deployedContracts[i].storageUtils);
        ICTMRWA1StorageManager(storageManager).setCtmRwaDeployer(deployedContracts[i].deployer);
        ICTMRWA1StorageManager(storageManager).setCtmRwaMap(deployedContracts[i].map);
    }

    function initSentryManager(uint256 i) public {
        address sentryManager = deployedContracts[i].sentryManager;
        ICTMRWA1SentryManager(sentryManager).setSentryUtils(deployedContracts[i].sentryUtils);
        ICTMRWA1SentryManager(sentryManager).setCtmRwaDeployer(deployedContracts[i].deployer);
        ICTMRWA1SentryManager(sentryManager).setCtmRwaMap(deployedContracts[i].map);
    }

    function buildContractSetup() public {
        for (uint256 j = 0; j < deployedContracts.length; j++) {
            chainIdsStr.push(deployedContracts[j].chainIdStr); // already is string
            gatewaysStr.push(vm.toString(deployedContracts[j].gateway));
            rwaXsStr.push(vm.toString(deployedContracts[j].rwa1X));
            storageManagersStr.push(vm.toString(deployedContracts[j].storageManager));
            sentryManagersStr.push(vm.toString(deployedContracts[j].sentryManager));
        }
    }

    function run() public {
        LoadDeployedContracts loadDeployedContracts = new LoadDeployedContracts();
        deployedContracts = loadDeployedContracts.run();

        if (block.chainid == 31337) revert ("Use --chain-id flag!");
        chainIdStr = vm.toString(block.chainid);

        vm.startBroadcast();

        console.log("Initializing contracts for chain: ");
        console.log(chainIdStr);

        buildContractSetup();

        for (uint256 i = 0; i < deployedContracts.length; i++) {
            if (Strings.equal(deployedContracts[i].chainIdStr, chainIdStr)) {
                initFeeManager(i);
                initRWA1X(i);
                initDeployer(i);
                initStorageManager(i);
                initSentryManager(i);
                if (deployedContracts.length > 1) initGateway(i);
            }
        }

        vm.stopBroadcast();
    }
}
