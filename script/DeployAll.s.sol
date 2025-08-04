// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.27;

import { Script } from "forge-std/Script.sol";

import { CTMRWA1X } from "../flattened/crosschain/CTMRWA1X.sol";
import { CTMRWA1XFallback } from "../flattened/crosschain/CTMRWA1XFallback.sol";
import { CTMRWAGateway } from "../flattened/crosschain/CTMRWAGateway.sol";

import { CTMRWA1TokenFactory } from "../flattened/deployment/CTMRWA1TokenFactory.sol";
import { CTMRWADeployInvest } from "../flattened/deployment/CTMRWADeployInvest.sol";
import { CTMRWADeployer } from "../flattened/deployment/CTMRWADeployer.sol";

import { CTMRWAERC20Deployer } from "../flattened/deployment/CTMRWAERC20Deployer.sol";

import { CTMRWA1DividendFactory } from "../flattened/dividend/CTMRWA1DividendFactory.sol";

import { FeeManager, FeeType } from "../flattened/managers/FeeManager.sol";

import { CTMRWA1SentryManager } from "../flattened/sentry/CTMRWA1SentryManager.sol";
import { CTMRWA1SentryUtils } from "../flattened/sentry/CTMRWA1SentryUtils.sol";

import { CTMRWAMap } from "../flattened/shared/CTMRWAMap.sol";

import { CTMRWA1StorageManager } from "../flattened/storage/CTMRWA1StorageManager.sol";
import { CTMRWA1StorageUtils } from "../flattened/storage/CTMRWA1StorageUtils.sol";

import { CTMRWAProxy } from "../flattened/proxy/CTMRWAProxy.sol";

contract DeployAll is Script {
    address feeManager;

    address gateway;

    address rwa1X;
    address rwa1XFallback;

    address map;

    address deployer;
    address deployInvest;
    address erc20Deployer;

    address tokenFactory;

    address dividendFactory;

    address storageManager;
    address storageUtils;

    address sentryManager;
    address sentryUtils;

    uint256 RWA_TYPE;
    uint256 VERSION;

    function _deployProxy(address implementation, bytes memory data) internal returns (address proxy) {
        proxy = address(new CTMRWAProxy(implementation, data));
    }

    function _deployFeeManager(address gov, address c3caller, address admin, address ctm, address usdc) internal {
        address feeManagerImpl = address(new FeeManager());
        feeManager = address(
            FeeManager(_deployProxy(feeManagerImpl, abi.encodeCall(FeeManager.initialize, (gov, c3caller, admin, 1))))
        );
    }

    function _deployGateway(address gov, address c3caller, address admin) internal {
        address gatewayImpl = address(new CTMRWAGateway());
        gateway = address(
            CTMRWAGateway(
                _deployProxy(gatewayImpl, abi.encodeCall(CTMRWAGateway.initialize, (gov, c3caller, admin, 4)))
            )
        );
    }

    function _deployCTMRWA1X(address gov, address c3caller, address admin) internal {
        address rwa1XImpl = address(new CTMRWA1X());
        rwa1X = address(
            CTMRWA1X(
                _deployProxy(
                    rwa1XImpl, abi.encodeCall(CTMRWA1X.initialize, (gateway, feeManager, gov, c3caller, admin, 2))
                )
            )
        );

        rwa1XFallback = address(new CTMRWA1XFallback(rwa1X));
    }

    function _deployMap(address gov, address c3caller, address admin) internal {
        address mapImpl = address(new CTMRWAMap());
        map = address(
            CTMRWAMap(
                _deployProxy(mapImpl, abi.encodeCall(CTMRWAMap.initialize, (gov, c3caller, admin, 87, gateway, rwa1X)))
            )
        );
    }

    function _deployCTMRWADeployer(address gov, address c3caller, address admin) internal {
        address deployerImpl = address(new CTMRWADeployer());
        deployer = address(
            CTMRWADeployer(
                _deployProxy(
                    deployerImpl,
                    abi.encodeCall(
                        CTMRWADeployer.initialize, (gov, gateway, feeManager, rwa1X, map, c3caller, admin, 3)
                    )
                )
            )
        );

        deployInvest = address(
            new CTMRWADeployInvest(
                map,
                deployer,
                0, // commission rate = 0
                feeManager
            )
        );

        erc20Deployer = address(new CTMRWAERC20Deployer(map, feeManager));
    }

    function _deployTokenFactory() internal {
        tokenFactory = address(new CTMRWA1TokenFactory(map, deployer));
    }

    function _deployDividendFactory() internal {
        dividendFactory = address(new CTMRWA1DividendFactory(deployer));
    }

    function _deployStorage(address gov, address c3caller, address admin) internal {
        address storageManagerImpl = address(new CTMRWA1StorageManager());
        storageManager = address(
            CTMRWA1StorageManager(
                _deployProxy(
                    storageManagerImpl,
                    abi.encodeCall(
                        CTMRWA1StorageManager.initialize, (gov, c3caller, admin, 88, deployer, gateway, feeManager)
                    )
                )
            )
        );

        storageUtils = address(new CTMRWA1StorageUtils(RWA_TYPE, VERSION, map, storageManager));
    }

    function _deploySentry(address gov, address c3caller, address admin) internal {
        address sentryManagerImpl = address(new CTMRWA1SentryManager());
        sentryManager = address(
            CTMRWA1SentryManager(
                _deployProxy(
                    sentryManagerImpl,
                    abi.encodeCall(
                        CTMRWA1SentryManager.initialize, (gov, c3caller, admin, 88, deployer, gateway, feeManager)
                    )
                )
            )
        );

        sentryUtils = address(new CTMRWA1SentryUtils(RWA_TYPE, VERSION, map, sentryManager));
    }

    function run() public {
        vm.startBroadcast();

        address gov = vm.envAddress("GOV");
        address admin = vm.envAddress("ADMIN");
        address c3caller = vm.envAddress("C3CALLER");
        address ctm = vm.envAddress("CTM");
        address usdc = vm.envAddress("USDC");
        uint256 rwaType = vm.envUint("RWA_TYPE");
        uint256 version = vm.envUint("VERSION");

        RWA_TYPE = rwaType;
        VERSION = version;

        _deployFeeManager(gov, c3caller, admin, ctm, usdc);
        _deployGateway(gov, c3caller, admin);
        _deployCTMRWA1X(gov, c3caller, admin);
        _deployMap(gov, c3caller, admin);
        _deployCTMRWADeployer(gov, c3caller, admin);
        _deployTokenFactory();
        _deployDividendFactory();
        _deployStorage(gov, c3caller, admin);
        _deploySentry(gov, c3caller, admin);

        vm.stopBroadcast();
    }
}
