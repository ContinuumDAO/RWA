// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.27;

import { Utils } from "./Utils.sol";

import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

import { C3Caller } from "@c3caller/C3Caller.sol";
import { C3UUIDKeeper } from "@c3caller/uuid/C3UUIDKeeper.sol";

import { CTMRWA1 } from "../../src/core/CTMRWA1.sol";

import { CTMRWA1X } from "../../src/crosschain/CTMRWA1X.sol";
import { CTMRWA1XFallback } from "../../src/crosschain/CTMRWA1XFallback.sol";
import { CTMRWAGateway } from "../../src/crosschain/CTMRWAGateway.sol";

import { CTMRWA1TokenFactory } from "../../src/deployment/CTMRWA1TokenFactory.sol";
import { CTMRWADeployInvest } from "../../src/deployment/CTMRWADeployInvest.sol";
import { CTMRWADeployer } from "../../src/deployment/CTMRWADeployer.sol";

import { CTMRWAERC20Deployer } from "../../src/deployment/CTMRWAERC20Deployer.sol";

import { CTMRWA1DividendFactory } from "../../src/dividend/CTMRWA1DividendFactory.sol";

import { FeeManager } from "../../src/managers/FeeManager.sol";
import { FeeType } from "../../src/managers/IFeeManager.sol";

import { CTMRWA1SentryManager } from "../../src/sentry/CTMRWA1SentryManager.sol";
import { CTMRWA1SentryUtils } from "../../src/sentry/CTMRWA1SentryUtils.sol";

import { CTMRWAMap } from "../../src/shared/CTMRWAMap.sol";

import { CTMRWA1StorageManager } from "../../src/storage/CTMRWA1StorageManager.sol";
import { CTMRWA1StorageUtils } from "../../src/storage/CTMRWA1StorageUtils.sol";

contract Deployer is Utils {
    using Strings for *;

    C3UUIDKeeper c3UUIDKeeper;
    C3Caller c3caller;

    FeeManager feeManager;
    string[] tokensStr;
    uint256[] fees;

    CTMRWAGateway gateway;

    CTMRWA1X rwa1X;
    CTMRWA1XFallback rwa1XFallback;

    CTMRWAMap map;

    CTMRWADeployer deployer;
    CTMRWADeployInvest ctmRwaDeployInvest;
    CTMRWAERC20Deployer ctmRwaErc20Deployer;

    CTMRWA1TokenFactory tokenFactory;

    CTMRWA1DividendFactory dividendFactory;

    CTMRWA1StorageManager storageManager;
    CTMRWA1StorageUtils storageUtils;

    CTMRWA1SentryManager sentryManager;
    CTMRWA1SentryUtils sentryUtils;

    FeeContracts feeContracts;

    uint256 ID;
    CTMRWA1 token;

    function _deployC3Caller(address gov) internal {
        address c3UUIDKeeperImpl = address(new C3UUIDKeeper());
        c3UUIDKeeper = C3UUIDKeeper(_deployProxy(c3UUIDKeeperImpl, abi.encodeCall(C3UUIDKeeper.initialize, (gov))));
        address c3callerImpl = address(new C3Caller());
        c3caller = C3Caller(_deployProxy(c3callerImpl, abi.encodeCall(C3Caller.initialize, (address(c3UUIDKeeper)))));
    }

    function _deployFeeManager(address gov, address admin, address ctm, address usdc) internal {
        address feeManagerImpl = address(new FeeManager());
        feeManager = FeeManager(
            _deployProxy(feeManagerImpl, abi.encodeCall(FeeManager.initialize, (gov, address(c3caller), admin, 1)))
        );

        feeManager.addFeeToken(address(ctm).toHexString());
        feeManager.addFeeToken(address(usdc).toHexString());

        feeManager.setFeeMultiplier(FeeType.ADMIN, 5);
        feeManager.setFeeMultiplier(FeeType.DEPLOY, 100);
        feeManager.setFeeMultiplier(FeeType.MINT, 5);
        feeManager.setFeeMultiplier(FeeType.BURN, 5);
        feeManager.setFeeMultiplier(FeeType.TX, 1);
        feeManager.setFeeMultiplier(FeeType.WHITELIST, 1);
        feeManager.setFeeMultiplier(FeeType.COUNTRY, 1);
        feeManager.setFeeMultiplier(FeeType.KYC, 1);

        string memory destChain = "1";
        string memory ctmAddrStr = _toLower(address(ctm).toHexString());
        string memory usdcAddrStr = _toLower(address(usdc).toHexString());

        tokensStr.push(ctmAddrStr);
        tokensStr.push(usdcAddrStr);

        fees.push(10**18);  // 1 CTM baseFee
        fees.push(10**6);   // 1 USDC baseFee

        feeManager.addFeeToken(destChain, tokensStr, fees);
    }

    function _deployGateway(address gov, address admin) internal {
        address gatewayImpl = address(new CTMRWAGateway());
        gateway = CTMRWAGateway(
            _deployProxy(gatewayImpl, abi.encodeCall(CTMRWAGateway.initialize, (gov, address(c3caller), admin, 4)))
        );

        string[] memory chainIdsStr = _stringToArray("1");
        string[] memory gwaysStr = _stringToArray("ethereumGateway");
        gateway.addChainContract(chainIdsStr, gwaysStr);
    }

    function _deployCTMRWA1X(address gov, address admin) internal {
        address rwa1XImpl = address(new CTMRWA1X());
        rwa1X = CTMRWA1X(
            _deployProxy(
                rwa1XImpl, abi.encodeCall(
                    CTMRWA1X.initialize, (address(gateway), address(feeManager), gov, address(c3caller), admin, 2)
                )
            )
        );

        rwa1XFallback = new CTMRWA1XFallback(address(rwa1X));

        rwa1X.setFallback(address(rwa1XFallback));

        string[] memory chainIdsStr = new string[](2);
        string[] memory rwaXsStr = new string[](2);

        chainIdsStr[0] = cIdStr;
        chainIdsStr[1] = "999999999999999999999";

        rwaXsStr[0] = address(rwa1X).toHexString();
        rwaXsStr[1] = "thisIsSomeRandomAddressOnNEARForTestingWallet123456789.test.near";

        gateway.attachRWAX(RWA_TYPE, VERSION, chainIdsStr, rwaXsStr);
    }

    function _deployMap(address gov, address admin) internal {
        address mapImpl = address(new CTMRWAMap());
        map = CTMRWAMap(
            _deployProxy(
                mapImpl, abi.encodeCall(
                    CTMRWAMap.initialize, (gov, address(c3caller), address(admin), 87, address(gateway), address(rwa1X))
                )
            )
        );
    }

    function _deployCTMRWADeployer(address gov, address admin) internal {
        address deployerImpl = address(new CTMRWADeployer());
        deployer = CTMRWADeployer(_deployProxy(deployerImpl, abi.encodeCall(
            CTMRWADeployer.initialize, (
                gov,
                address(gateway),
                address(feeManager),
                address(rwa1X),
                address(map),
                address(c3caller),
                admin,
                3
            )
        )));

        ctmRwaDeployInvest = new CTMRWADeployInvest(
            address(map),
            address(deployer),
            0, // commission rate = 0
            address(feeManager)
        );

        ctmRwaErc20Deployer = new CTMRWAERC20Deployer(address(map), address(feeManager));

        deployer.setDeployInvest(address(ctmRwaDeployInvest));
        deployer.setErc20DeployerAddress(address(ctmRwaErc20Deployer));
        rwa1X.setCtmRwaDeployer(address(deployer));
        rwa1X.setCtmRwaMap(address(map));
    }

    function _deployTokenFactory() internal {
        tokenFactory = new CTMRWA1TokenFactory(address(map), address(deployer));
        deployer.setTokenFactory(RWA_TYPE, VERSION, address(tokenFactory));
    }

    function _deployDividendFactory() internal {
        dividendFactory = new CTMRWA1DividendFactory(address(deployer));
        deployer.setDividendFactory(RWA_TYPE, VERSION, address(dividendFactory));
    }

    function _deployStorage(address gov, address admin) internal {
        address storageManagerImpl = address(new CTMRWA1StorageManager());
        storageManager = CTMRWA1StorageManager(
            _deployProxy(
                storageManagerImpl, abi.encodeCall(
                    CTMRWA1StorageManager.initialize,
                    (
                        gov,
                        address(c3caller),
                        admin,
                        88,
                        address(deployer),
                        address(gateway),
                        address(feeManager)
                    )
                )
            )
        );

        storageUtils = new CTMRWA1StorageUtils(RWA_TYPE, VERSION, address(map), address(storageManager));

        storageManager.setStorageUtils(address(storageUtils));
        storageManager.setCtmRwaDeployer(address(deployer));
        storageManager.setCtmRwaMap(address(map));
        deployer.setStorageFactory(RWA_TYPE, VERSION, address(storageManager));

        string[] memory chainIdsStr = new string[](2);
        string[] memory storagesStr = new string[](2);

        chainIdsStr[0] = cIdStr;
        chainIdsStr[1] = "1";

        storagesStr[0] = address(storageManager).toHexString();
        storagesStr[1] = "ethereumStorageManager";

        gateway.attachStorageManager(RWA_TYPE, VERSION, chainIdsStr, storagesStr);
    }

    function _deploySentry(address gov, address admin) internal {
        address sentryManagerImpl = address(new CTMRWA1SentryManager());
        sentryManager = CTMRWA1SentryManager(
            _deployProxy(
                sentryManagerImpl, abi.encodeCall(
                    CTMRWA1SentryManager.initialize,
                    (
                        gov,
                        address(c3caller),
                        admin,
                        88,
                        address(deployer),
                        address(gateway),
                        address(feeManager)
                    )
                )
            )
        );

        deployer.setSentryFactory(RWA_TYPE, VERSION, address(sentryManager));

        sentryUtils = new CTMRWA1SentryUtils(RWA_TYPE, VERSION, address(map), address(sentryManager));

        sentryManager.setSentryUtils(address(sentryUtils));
        sentryManager.setCtmRwaDeployer(address(deployer));
        sentryManager.setCtmRwaMap(address(map));

        string[] memory chainIdsStr = new string[](2);
        string[] memory sentriesStr = new string[](2);

        chainIdsStr[0] = cIdStr;
        chainIdsStr[1] = "1";

        sentriesStr[0] = address(sentryManager).toHexString();
        sentriesStr[1] = "ethereumSentryManager";

        gateway.attachSentryManager(RWA_TYPE, VERSION, chainIdsStr, sentriesStr);
    }

    function _setFeeContracts() internal {
        feeContracts = FeeContracts(
            address(rwa1X),
            address(ctmRwaDeployInvest),
            address(ctmRwaErc20Deployer),
            // address(identity),
            address(sentryManager),
            address(storageManager)
        );
    }

    function _deployCTMRWA1(address feeToken) public returns (uint256, CTMRWA1) {
        string memory feeTokenStr = _toLower((address(feeToken).toHexString()));
        string[] memory dummyChainIdsStr;

        ID = rwa1X.deployAllCTMRWA1X(
            true, // include local mint
            0,
            RWA_TYPE,
            VERSION,
            "Semi Fungible Token XChain",
            "SFTX",
            18,
            "GFLD",
            dummyChainIdsStr, // empty array - no cross-chain minting
            feeTokenStr
        );

        (, address tokenAddress) = map.getTokenContract(ID, RWA_TYPE, VERSION);

        token = CTMRWA1(tokenAddress);

        return (ID, token);
    }
}
