// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.22;

import { Script } from "forge-std/Script.sol";
import { console } from "forge-std/console.sol";

import { Upgrades } from "@openzeppelin/foundry-upgrades/Upgrades.sol";

import { CTMRWA1X } from "../src/crosschain/CTMRWA1X.sol";
import { CTMRWA1XFallback } from "../src/crosschain/CTMRWA1XFallback.sol";
import { CTMRWAGateway } from "../src/crosschain/CTMRWAGateway.sol";

import { CTMRWA1TokenFactory } from "../src/deployment/CTMRWA1TokenFactory.sol";
import { CTMRWADeployInvest } from "../src/deployment/CTMRWADeployInvest.sol";
import { CTMRWADeployer } from "../src/deployment/CTMRWADeployer.sol";
import { CTMRWAERC20Deployer } from "../src/deployment/CTMRWAERC20Deployer.sol";

import { CTMRWA1DividendFactory } from "../src/dividend/CTMRWA1DividendFactory.sol";

import { FeeManager } from "../src/managers/FeeManager.sol";

import { CTMRWA1SentryManager } from "../src/sentry/CTMRWA1SentryManager.sol";
import { CTMRWA1SentryUtils } from "../src/sentry/CTMRWA1SentryUtils.sol";

import { CTMRWAMap } from "../src/shared/CTMRWAMap.sol";

import { CTMRWA1StorageManager } from "../src/storage/CTMRWA1StorageManager.sol";
import { CTMRWA1StorageUtils } from "../src/storage/CTMRWA1StorageUtils.sol";

// import {CTMRWADeployer} from "../flattened/CTMRWADeployer.sol";
// import {CTMRWAMap} from "../flattened/CTMRWAMap.sol";
// import {CTMRWA1TokenFactory} from "../flattened/CTMRWA1TokenFactory.sol";
// import {CTMRWA1XFallback} from "../flattened/CTMRWA1XFallback.sol";
// import {CTMRWA1DividendFactory} from "../flattened/CTMRWA1DividendFactory.sol";
// import {CTMRWA1StorageManager} from "../flattened/CTMRWA1StorageManager.sol";
// import {CTMRWA1StorageUtils} from "../src/storage/CTMRWA1StorageUtils.sol";
// import {CTMRWAERC20Deployer} from "../src/deployer/CTMRWAERC20Deployer.sol";
// import {CTMRWADeployInvest} from "../src/deployer/CTMRWADeployInvest.sol";
// import {CTMRWA1SentryManager} from "../flattened/CTMRWA1SentryManager.sol";
// import {CTMRWA1SentryUtils} from "../src/sentry/CTMRWA1SentryUtils.sol";
// import {FeeManager} from "../flattened/FeeManager.sol";
// import {CTMRWAGateway} from "../flattened/CTMRWAGateway.sol";
// import {CTMRWA1X} from "../flattened/CTMRWA1X.sol";

contract Deploy is Script {
    CTMRWADeployer ctmRwaDeployer;
    CTMRWAMap ctmRwaMap;
    CTMRWAGateway gateway;
    FeeManager feeManager;
    CTMRWA1X ctmRwa1X;
    CTMRWA1TokenFactory tokenFactory;
    CTMRWA1XFallback ctmRwaFallback;
    CTMRWADeployInvest ctmRwaDeployInvest;
    CTMRWAERC20Deployer ctmRwaErc20Deployer;
    CTMRWA1StorageManager storageManager;
    CTMRWA1SentryManager sentryManager;
    CTMRWA1StorageUtils storageUtils;
    CTMRWA1SentryUtils sentryUtils;
    CTMRWA1DividendFactory dividendFactory;

    address feeManagerAddr;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        console.log("Wallet of deployer");
        console.log(deployer);

        // env variables (changes based on deployment chain, edit in .env)
        address c3callerProxyAddr = vm.envAddress("C3_DEPLOY_U2U_NEBULAS_TESTNET");
        address govAddr = deployer;
        uint256 dappID1 = vm.envUint("DAPP_ID1"); // Gateway
        uint256 dappID2 = vm.envUint("DAPP_ID2"); // FeeManager
        uint256 dappID3 = vm.envUint("DAPP_ID3"); // CTMRWAX
        uint256 dappID4 = vm.envUint("DAPP_ID4"); // CTMRWADEPLOYER
        uint256 dappID5 = vm.envUint("DAPP_ID5"); // CTMRWASTORAGE
        uint256 dappID6 = vm.envUint("DAPP_ID6"); // CTMRWASENTRY
        uint256 dappID7 = vm.envUint("DAPP_ID7"); // CTMRWAMAP

        address txSender = deployer;

        vm.startBroadcast(deployerPrivateKey);

        // deploy fee manager
        feeManagerAddr = Upgrades.deployUUPSProxy(
            "FeeManager.sol", abi.encodeCall(FeeManager.initialize, (govAddr, c3callerProxyAddr, txSender, dappID2))
        );
        feeManager = FeeManager(feeManagerAddr);

        console.log("feeManager");
        console.log(feeManagerAddr);

        // deploy gateway
        address gatewayAddress = Upgrades.deployUUPSProxy(
            "CTMRWAGateway.sol",
            abi.encodeCall(CTMRWAGateway.initialize, (govAddr, c3callerProxyAddr, txSender, dappID1))
        );
        gateway = CTMRWAGateway(gatewayAddress);

        console.log("gateway address");
        console.log(address(gateway));

        // deploy RWA1X
        address rwa1XAddress = Upgrades.deployUUPSProxy(
            "CTMRWA1X.sol",
            abi.encodeCall(
                CTMRWA1X.initialize, (address(gateway), feeManagerAddr, govAddr, c3callerProxyAddr, txSender, dappID3)
            )
        );
        ctmRwa1X = CTMRWA1X(rwa1XAddress);

        console.log("ctmRwa1X address");
        console.log(rwa1XAddress);

        ctmRwaFallback = new CTMRWA1XFallback(address(ctmRwa1X));

        ctmRwa1X.setFallback(address(ctmRwaFallback));
        console.log("ctmRwaFallback address");
        console.log(address(ctmRwaFallback));

        address ctmRwa1Map = Upgrades.deployUUPSProxy(
            "CTMRWAMap.sol",
            abi.encodeCall(
                CTMRWAMap.initialize,
                (govAddr, c3callerProxyAddr, txSender, dappID7, address(gateway), address(ctmRwa1X))
            )
        );

        console.log("CTMRWAMap");
        console.log(ctmRwa1Map);

        (address ctmDeployer, address ctmStorage, address ctmSentry, address ctmDividend, address ctmRWA1Factory) =
        deployCTMRWADeployer(
            1, 1, govAddr, address(ctmRwa1X), ctmRwa1Map, c3callerProxyAddr, txSender, dappID4, dappID5, dappID6
        );

        console.log("ctmRWADeployer");
        console.log(ctmDeployer);
        console.log("CTM Storage Manager");
        console.log(ctmStorage);
        console.log("Dividend Factory");
        console.log(ctmDividend);
        console.log("Sentry Factory");
        console.log(ctmSentry);
        console.log("CTMRWA1Factory");
        console.log(ctmRWA1Factory);

        vm.stopBroadcast();
    }

    function deployCTMRWADeployer(
        uint256 _rwaType,
        uint256 _version,
        address _gov,
        address _rwa1X,
        address _ctmRwa1Map,
        address _c3callerProxy,
        address _txSender,
        uint256 _dappIDDeployer,
        uint256 _dappIDStorageManager,
        uint256 _dappIDSentryManager
    ) internal returns (address, address, address, address, address) {
        address deployerAddr = Upgrades.deployUUPSProxy(
            "CTMRWADeployer.sol",
            abi.encodeCall(
                CTMRWADeployer.initialize,
                (
                    _gov,
                    address(gateway),
                    feeManagerAddr,
                    _rwa1X,
                    _ctmRwa1Map,
                    _c3callerProxy,
                    _txSender,
                    _dappIDDeployer
                )
            )
        );

        ctmRwaDeployInvest = new CTMRWADeployInvest(_ctmRwa1Map, address(ctmRwaDeployer), 0, feeManagerAddr);

        ctmRwaErc20Deployer = new CTMRWAERC20Deployer(_ctmRwa1Map, feeManagerAddr);

        ctmRwa1X.setCtmRwaDeployer(address(ctmRwaDeployer));
        ctmRwa1X.setCtmRwaMap(_ctmRwa1Map);

        tokenFactory = new CTMRWA1TokenFactory(_ctmRwa1Map, address(ctmRwaDeployer));

        ctmRwaDeployer.setTokenFactory(_rwaType, _version, address(tokenFactory));

        ctmRwaDeployer.setDeployInvest(address(ctmRwaDeployInvest));
        ctmRwaDeployer.setErc20DeployerAddress(address(ctmRwaErc20Deployer));

        address storageManagerAddr = Upgrades.deployUUPSProxy(
            "CTMRWA1StorageManager.sol",
            abi.encodeCall(
                CTMRWA1StorageManager.initialize,
                (
                    _gov,
                    _rwaType,
                    _version,
                    _c3callerProxy,
                    _txSender,
                    _dappIDStorageManager,
                    address(ctmRwaDeployer),
                    address(gateway),
                    feeManagerAddr
                )
            )
        );
        storageManager = CTMRWA1StorageManager(storageManagerAddr);

        storageUtils = new CTMRWA1StorageUtils(_rwaType, _version, _ctmRwa1Map, storageManagerAddr);

        address sentryManagerAddr = Upgrades.deployUUPSProxy(
            "CTMRWA1SentryManager.sol",
            abi.encodeCall(
                CTMRWA1SentryManager.initialize,
                (
                    _gov,
                    _rwaType,
                    _version,
                    _c3callerProxy,
                    _txSender,
                    _dappIDSentryManager,
                    address(ctmRwaDeployer),
                    address(gateway),
                    feeManagerAddr
                )
            )
        );
        sentryManager = CTMRWA1SentryManager(sentryManagerAddr);

        sentryUtils = new CTMRWA1SentryUtils(_rwaType, _version, _ctmRwa1Map, sentryManagerAddr);

        dividendFactory = new CTMRWA1DividendFactory(address(ctmRwaDeployer));

        storageManager.setStorageUtils(address(storageUtils));
        storageManager.setCtmRwaDeployer(address(ctmRwaDeployer));
        storageManager.setCtmRwaMap(_ctmRwa1Map);

        sentryManager.setSentryUtils(address(sentryUtils));
        sentryManager.setCtmRwaDeployer(address(ctmRwaDeployer));
        sentryManager.setCtmRwaMap(_ctmRwa1Map);

        ctmRwaDeployer.setStorageFactory(_rwaType, _version, address(storageManager));
        ctmRwaDeployer.setSentryFactory(_rwaType, _version, address(sentryManager));
        ctmRwaDeployer.setDividendFactory(_rwaType, _version, address(dividendFactory));

        return (
            address(ctmRwaDeployer),
            address(storageManager),
            address(sentryManager),
            address(dividendFactory),
            address(tokenFactory)
        );
    }
}
