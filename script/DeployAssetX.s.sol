// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.27;

import { Script } from "forge-std/Script.sol";
import { console } from "forge-std/console.sol";

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

import { CTMRWAProxy } from "../flattened/utils/CTMRWAProxy.sol";

import { ChainContracts } from "./Utils.s.sol";

contract DeployAssetX is Script {
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

    string chainIdStr;
    address feeToken;

    function _deployProxy(address implementation, bytes memory data) internal returns (address proxy) {
        proxy = address(new CTMRWAProxy(implementation, data));
    }

    function _deployFeeManager(uint256 dappID, address gov, address c3caller, address mpc) internal {
        address feeManagerImpl = address(new FeeManager());
        feeManager = address(
            FeeManager(_deployProxy(feeManagerImpl, abi.encodeCall(FeeManager.initialize, (gov, c3caller, mpc, dappID))))
        );
    }

    function _deployGateway(uint256 dappID, address gov, address c3caller, address mpc) internal {
        address gatewayImpl = address(new CTMRWAGateway());
        gateway = address(
            CTMRWAGateway(
                _deployProxy(gatewayImpl, abi.encodeCall(CTMRWAGateway.initialize, (gov, c3caller, mpc, dappID)))
            )
        );
    }

    function _deployCTMRWA1X(uint256 dappID, address gov, address c3caller, address mpc) internal {
        address rwa1XImpl = address(new CTMRWA1X());
        rwa1X = address(
            CTMRWA1X(
                _deployProxy(
                    rwa1XImpl, abi.encodeCall(CTMRWA1X.initialize, (gateway, feeManager, gov, c3caller, mpc, dappID))
                )
            )
        );

        rwa1XFallback = address(new CTMRWA1XFallback(rwa1X));
    }

    function _deployMap(uint256 dappID, address gov, address c3caller, address mpc) internal {
        address mapImpl = address(new CTMRWAMap());
        map = address(
            CTMRWAMap(
                _deployProxy(mapImpl, abi.encodeCall(CTMRWAMap.initialize, (gov, c3caller, mpc, dappID, gateway, rwa1X)))
            )
        );
    }

    function _deployCTMRWADeployer(uint256 dappID, address gov, address c3caller, address mpc) internal {
        address deployerImpl = address(new CTMRWADeployer());
        deployer = address(
            CTMRWADeployer(
                _deployProxy(
                    deployerImpl,
                    abi.encodeCall(
                        CTMRWADeployer.initialize, (gov, gateway, feeManager, rwa1X, map, c3caller, mpc, dappID)
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

    function _deployStorage(uint256 dappID, address gov, address c3caller, address mpc) internal {
        address storageManagerImpl = address(new CTMRWA1StorageManager());
        storageManager = address(
            CTMRWA1StorageManager(
                _deployProxy(
                    storageManagerImpl,
                    abi.encodeCall(
                        CTMRWA1StorageManager.initialize, (gov, c3caller, mpc, dappID, deployer, gateway, feeManager)
                    )
                )
            )
        );

        storageUtils = address(new CTMRWA1StorageUtils(RWA_TYPE, VERSION, map, storageManager));
    }

    function _deploySentry(uint256 dappID, address gov, address c3caller, address mpc) internal {
        address sentryManagerImpl = address(new CTMRWA1SentryManager());
        sentryManager = address(
            CTMRWA1SentryManager(
                _deployProxy(
                    sentryManagerImpl,
                    abi.encodeCall(
                        CTMRWA1SentryManager.initialize, (gov, c3caller, mpc, dappID, deployer, gateway, feeManager)
                    )
                )
            )
        );

        sentryUtils = address(new CTMRWA1SentryUtils(RWA_TYPE, VERSION, map, sentryManager));
    }

    function run() public {

        RWA_TYPE = vm.envUint("RWA_TYPE");
        VERSION = vm.envUint("VERSION");

        address gov = vm.envAddress("GOV");
        address mpc = vm.envAddress("MPC");
        uint256 dappIDGateway = vm.envUint("DAPP_ID_GATEWAY");
        uint256 dappIDFeeManager = vm.envUint("DAPP_ID_FEE_MANAGER");
        uint256 dappIDRWA1X = vm.envUint("DAPP_ID_RWA1X");
        uint256 dappIDMap = vm.envUint("DAPP_ID_MAP");
        uint256 dappIDDeployer = vm.envUint("DAPP_ID_DEPLOYER");
        uint256 dappIDStorageManager = vm.envUint("DAPP_ID_STORAGE_MANAGER");
        uint256 dappIDSentryManager = vm.envUint("DAPP_ID_SENTRY_MANAGER");

        vm.startBroadcast();

        chainIdStr = vm.toString(block.chainid);
        if (block.chainid == 31337) revert ("Use --chain flag!");

        string memory feeTokenKey = string.concat("FEE_TOKEN_", chainIdStr);

        try vm.envAddress(feeTokenKey) returns (address _feeToken) {
            feeToken = _feeToken;
        } catch {
            revert (string.concat(feeTokenKey, " not set"));
        }

        address c3caller = vm.envAddress(string.concat("C3CALLER_", chainIdStr));

        _deployFeeManager(dappIDFeeManager, gov, c3caller, mpc);
        _deployGateway(dappIDGateway, gov, c3caller, mpc);
        _deployCTMRWA1X(dappIDRWA1X, gov, c3caller, mpc);
        _deployMap(dappIDMap, gov, c3caller, mpc);
        _deployCTMRWADeployer(dappIDDeployer, gov, c3caller, mpc);
        _deployTokenFactory();
        _deployDividendFactory();
        _deployStorage(dappIDStorageManager, gov, c3caller, mpc);
        _deploySentry(dappIDSentryManager, gov, c3caller, mpc);

        vm.stopBroadcast();

        console.log("AssetX deployed successfully");

        ChainContracts memory chainContracts = ChainContracts(chainIdStr, feeManager, gateway, rwa1X, rwa1XFallback, map, deployer, deployInvest, erc20Deployer, tokenFactory, dividendFactory, storageManager, storageUtils, sentryManager, sentryUtils, feeToken);

        console.log(string.concat("Deployed AssetX contracts successfully to chain ID ", chainIdStr));
    }
}
