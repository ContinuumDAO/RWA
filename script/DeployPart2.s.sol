// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import "forge-std/console.sol";

import {CTMRWAERC20Deployer} from "../src/core/CTMRWAERC20Deployer.sol";
import {CTMRWA1DividendFactory} from "../src/core/CTMRWA1DividendFactory.sol";

import {CTMRWAGateway} from "../src/crosschain/CTMRWAGateway.sol";
import {CTMRWA1X} from "../src/crosschain/CTMRWA1X.sol";
import {ICTMRWA1X} from "../src/crosschain/ICTMRWA1X.sol";
import {CTMRWA1XFallback} from "../src/crosschain/CTMRWA1XFallback.sol";
import {ICTMRWAGateway} from "../src/crosschain/ICTMRWAGateway.sol";

import {CTMRWADeployInvest} from "../src/deployment/CTMRWADeployInvest.sol";
import {CTMRWADeployer} from "../src/deployment/CTMRWADeployer.sol";
import {CTMRWA1TokenFactory} from "../src/deployment/CTMRWA1TokenFactory.sol";

import {FeeManager} from "../src/managers/FeeManager.sol";

import {CTMRWA1SentryManager} from "../src/sentry/CTMRWA1SentryManager.sol";
import {CTMRWA1SentryUtils} from "../src/sentry/CTMRWA1SentryUtils.sol";

import {CTMRWAMap} from "../src/shared/CTMRWAMap.sol";

import {CTMRWA1StorageManager} from "../src/storage/CTMRWA1StorageManager.sol";
import {CTMRWA1StorageUtils} from "../src/storage/CTMRWA1StorageUtils.sol";

contract DeployPart2 is Script {
  CTMRWADeployer ctmRwaDeployer;
  CTMRWAMap ctmRwaMap;
  CTMRWA1TokenFactory tokenFactory;
  CTMRWA1XFallback ctmRwaFallback;
  CTMRWADeployInvest ctmRwaDeployInvest;
  CTMRWAERC20Deployer ctmRwaErc20Deployer;
  CTMRWA1StorageManager storageManager;
  CTMRWA1StorageUtils storageUtils;
  CTMRWA1SentryManager sentryManager;
  CTMRWA1SentryUtils sentryUtils;
  CTMRWA1DividendFactory dividendFactory;

  address rwa1XAddr = 0x0000000000000000000000000000000000000000;
  address gatewayAddr = 0x0000000000000000000000000000000000000000;
  address feeManagerAddr = 0x0000000000000000000000000000000000000000;

  ICTMRWAGateway gateway;
  ICTMRWA1X ctmRwa1X;

  function run() external {
    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
    address deployer = vm.addr(deployerPrivateKey);
    console.log("Wallet of deployer");
    console.log(deployer);

    // env variables (changes based on deployment chain, edit in .env)
    address c3callerProxyAddr = vm.envAddress("C3_DEPLOY_OPTIMISM_SEPOLIA");
    address govAddr = deployer;

    uint256 dappID4 = vm.envUint("DAPP_ID4");
    uint256 dappID5 = vm.envUint("DAPP_ID5");
    uint256 dappID6 = vm.envUint("DAPP_ID6");

    address txSender = deployer;

    vm.startBroadcast(deployerPrivateKey);

    gateway = ICTMRWAGateway(gatewayAddr);
    require(rwa1XAddr != address(0));
    ctmRwa1X = ICTMRWA1X(rwa1XAddr);

    address ctmRwa1Map = deployMap(/*govAddr*/);

    console.log("CTMRWAMap");
    console.log(ctmRwa1Map);

    (
      address ctmDeployer,
      address ctmStorage,
      address ctmSentry,
      address ctmDividend,
      address ctmRWA1Factory
    ) = deployCTMRWADeployer(
      1,
      1,
      govAddr,
      address(ctmRwa1X),
      ctmRwa1Map,
      c3callerProxyAddr,
      txSender,
      dappID4,
      dappID5,
      dappID6
    );

    console.log("ctmRWADeployer");
    console.log(ctmDeployer);
    console.log("CTM Storage Manager");
    console.log(ctmStorage);
    console.log("Dividend Factory");
    console.log(ctmSentry);
    console.log("Sentry Factory");
    console.log(ctmDividend);
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
    ctmRwaDeployer = new CTMRWADeployer(
      _gov,
      address(gateway),
      feeManagerAddr,
      _rwa1X,
      _ctmRwa1Map,
      _c3callerProxy,
      _txSender,
      _dappIDDeployer
    );

    ctmRwaDeployInvest =
      new CTMRWADeployInvest(_ctmRwa1Map, address(ctmRwaDeployer), 0, feeManagerAddr);

    ctmRwaErc20Deployer = new CTMRWAERC20Deployer(_ctmRwa1Map, feeManagerAddr);

    ctmRwa1X.setCtmRwaDeployer(address(ctmRwaDeployer));
    ctmRwa1X.setCtmRwaMap(_ctmRwa1Map);

    tokenFactory = new CTMRWA1TokenFactory(_ctmRwa1Map, address(ctmRwaDeployer));

    ctmRwaDeployer.setTokenFactory(_rwaType, _version, address(tokenFactory));

    ctmRwaDeployer.setDeployInvest(address(ctmRwaDeployInvest));
    ctmRwaDeployer.setErc20DeployerAddress(address(ctmRwaErc20Deployer));

    storageManager = new CTMRWA1StorageManager(
      _gov,
      _rwaType,
      _version,
      _c3callerProxy,
      _txSender,
      _dappIDStorageManager,
      address(ctmRwaDeployer),
      address(gateway),
      feeManagerAddr
    );

    address storageManagerAddr = address(storageManager);

    storageUtils = new CTMRWA1StorageUtils(_rwaType, _version, _ctmRwa1Map, storageManagerAddr);

    sentryManager = new CTMRWA1SentryManager(
      _gov,
      _rwaType,
      _version,
      _c3callerProxy,
      _txSender,
      _dappIDSentryManager,
      address(ctmRwaDeployer),
      address(gateway),
      feeManagerAddr
    );

    dividendFactory = new CTMRWA1DividendFactory(address(ctmRwaDeployer));

    storageManager.setStorageUtils(address(storageUtils));
    storageManager.setCtmRwaDeployer(address(ctmRwaDeployer));
    storageManager.setCtmRwaMap(_ctmRwa1Map);

    sentryManager.setSentryUtils(address(sentryUtils));
    sentryManager.setCtmRwaDeployer(address(ctmRwaDeployer));
    sentryManager.setCtmRwaMap(_ctmRwa1Map);

    ctmRwaDeployer.setStorageFactory(_rwaType, _version, storageManagerAddr);
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

  function deployMap(/*address _gov*/) internal returns (address) {
    ctmRwaMap = new CTMRWAMap(address(gateway), address(ctmRwa1X));

    return (address(ctmRwaMap));
  }
}
