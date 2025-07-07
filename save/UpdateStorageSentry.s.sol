// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.19;

import { Script } from "forge-std/Script.sol";
import "forge-std/console.sol";

import { ICTMRWADeployer } from "../src/deployment/ICTMRWADeployer.sol";

import { CTMRWA1SentryManager } from "../src/sentry/CTMRWA1SentryManager.sol";
import { CTMRWA1SentryUtils } from "../src/sentry/CTMRWA1SentryUtils.sol";

import { CTMRWA1StorageManager } from "../src/storage/CTMRWA1StorageManager.sol";
import { CTMRWA1StorageUtils } from "../src/storage/CTMRWA1StorageUtils.sol";
import { ICTMRWA1StorageManager } from "../src/storage/ICTMRWA1StorageManager.sol";

contract UpdateStorageSentry is Script {
    CTMRWA1StorageManager storageManager;
    CTMRWA1StorageUtils storageUtils;
    CTMRWA1SentryUtils sentryUtils;
    CTMRWA1SentryManager sentryManager;

    uint256 chainId;

    address txSender;
    address c3callerProxyAddr;
    address feeManagerAddr;
    address gatewayAddr;
    address deployerAddr;
    address mapAddr;

    bool STORAGE = false;
    bool SENTRY = true;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        console.log("Wallet of deployer");
        console.log(deployer);

        chainId = 153;

        if (chainId == 421_614) {
            c3callerProxyAddr = vm.envAddress("C3_DEPLOY_ARB_SEPOLIA");
            feeManagerAddr = 0x7e61a5AF95Fc6efaC03F7d92320F42B2c2fe96f0;
            gatewayAddr = 0xbab5Ec2802257958d3f3a34dcE2F7Aa65Eac922d;
            deployerAddr = 0x13b17e90f430760eb038b83C5EBFd8082c027e00;
            mapAddr = 0xcC9AC238318d5dBe97b20957c09aC09bA73Eeb25;
        } else if (chainId == 84_532) {
            c3callerProxyAddr = vm.envAddress("C3_DEPLOY_BASE_SEPOLIA");
            feeManagerAddr = 0x91677ec1879987aBC3978fD2A71204640A9e9f4A;
            gatewayAddr = 0xe1C4c5a0e6A99bB61b842Bb78E5c66EA1256D292;
            deployerAddr = 0x11D5B22218A54981D27E0B6a6439Fd61589bf02a;
            mapAddr = 0xCf46f23D86a672AF5614FBa6A7505031805EF5e2;
        } else if (chainId == 80_002) {
            c3callerProxyAddr = vm.envAddress("C3_DEPLOY_AMOY");
            feeManagerAddr = 0x2D2112DE9801EAf71B6D1cBf40A99E57AFc235a7;
            gatewayAddr = 0xb1bC63301670F8ec9EE98BD501c89783d65ddC8a;
            deployerAddr = 0x77Aa59Ba778C00946122E43702509c87b81604F5;
            mapAddr = 0x18433A774aF5d473191903A5AF156f3Eb205bBA4;
        } else if (chainId == 11_155_111) {
            c3callerProxyAddr = vm.envAddress("C3_DEPLOY_SEPOLIA");
            // feeManagerAddr = 0xee53A0AD7f17715774Acc3963693B370409019;
            gatewayAddr = 0xF8fe7804AE6DBC7306AB5A97aE2302706170530C;
            deployerAddr = 0x0A91De653d4c09E7bC757eD794a03e4b40A1D057;
            mapAddr = 0xd546A3a98D86d22e28d688FAf3a074D000F2612B;
        } else if (chainId == 97) {
            c3callerProxyAddr = vm.envAddress("C3_DEPLOY_BSC_TESTNET");
            feeManagerAddr = 0x7ad438D2B3AC77D55c85275fD09d51Cec9Bb2987;
            gatewayAddr = 0xD362AFB113D7a2226aFf228F4FB161BEFd3b6BD4;
            deployerAddr = 0xd09A46f3a221a5595f4a71a24296787235bBb895;
            mapAddr = 0x5F0C4a82BDE669347Add86CD13587ba40d29dAd6;
        } else if (chainId == 200_810) {
            c3callerProxyAddr = vm.envAddress("C3_DEPLOY_BITLAYER_TESTNET");
            feeManagerAddr = 0xb008b6Cc593fC290Ed03d5011e90f4E9d19f9a87;
            gatewayAddr = 0x1e46d7f21299Ac06AAd49017A1f733Cd5e6134f3;
            deployerAddr = 0x1eE4bA474da815f728dF08F0147DeFac07F0BAb3;
            mapAddr = 0x1e608FD1546e1bC1382Abc4E676CeFB7e314Fb30;
        } else if (chainId == 59_141) {
            c3callerProxyAddr = vm.envAddress("C3_DEPLOY_LINEA");
            feeManagerAddr = 0x0c4AedfD2Aef21B742c29F061CA80Cc79D64A106;
            gatewayAddr = 0x41543A4C6423E2546FC58AC63117B5692D68c323;
            deployerAddr = 0xDbBbbbd746F539d8C82aea9d4F776e5BA0F4e1a1;
            mapAddr = 0xe5AF1a54B2b8cA3091edD229329B60A82b7A04E8;
        } else if (chainId == 78_600) {
            c3callerProxyAddr = vm.envAddress("C3_DEPLOY_VANGUARD");
            feeManagerAddr = 0xa240B0714712e2927Ec055CEAa8e031AC671a55F;
            gatewayAddr = 0x06edC167555ceb6038E2C6b3bED7A47C628F2Eed;
            deployerAddr = 0x67510816512511818B5047a4Cce6E8f2ebB15d20;
            mapAddr = 0x779f7FfdD1157935E1cD6344A6D7a9047736EBc1;
        } else if (chainId == 2484) {
            c3callerProxyAddr = vm.envAddress("C3_DEPLOY_U2U_NEBULAS_TESTNET");
            feeManagerAddr = 0x05a804374Bb77345854022Fd0CD2A602E00bF2E7;
            gatewayAddr = 0x16b049e17b49C5DC1D8598b53593D4497c858c9a;
            deployerAddr = 0x1EB65ef07b5a3B8f89FD851E078194E5d9e85F4b;
            mapAddr = 0xEd3c7279F4175F88Ab6bBcd16c8B8214387725e7;
        } else if (chainId == 1_952_959_480) {
            c3callerProxyAddr = vm.envAddress("C3_DEPLOY_LUMIA_TESTNET");
            feeManagerAddr = 0x20ADAf244972bC6cB064353F3EA4893f73E85599;
            gatewayAddr = 0x052E276c0A9D2D2adf1A2AeB6D7eCaEC38ec9dE6;
            deployerAddr = 0xD455BB0f664Ac8241b505729C3116f1ACC441be4;
            mapAddr = 0xc04058E417De221448D4140FC1622dE24121C5e3;
        } else if (chainId == 5611) {
            c3callerProxyAddr = vm.envAddress("C3_DEPLOY_OPBNB_TESTNET");
            feeManagerAddr = 0x63135C26Ad4a67D9D5dCfbCCDc94F11de83eB2Ca;
            gatewayAddr = 0x563c5c85CC7ba923c50b66479588e5b3B2C93470;
            deployerAddr = 0x5020f191FD0ce7F9340659b2d03ea0ba5921B44A;
            mapAddr = 0xfC2175A02c2e1e673F1Ba374A321d274Bb29bD68;
        } else if (chainId == 1115) {
            c3callerProxyAddr = vm.envAddress("C3_DEPLOY_CORE_TESTNET");
            feeManagerAddr = 0x5930640c1572bCD396eB410f62a6975ab9b8A148;
            gatewayAddr = 0xb849bF0a5ca08f1e6EA792bDC06ff2317bb2fB90;
            deployerAddr = 0xF813DdCDd690aCB06ddbFeb395Cf65D18Efe74A7;
            mapAddr = 0x89330bE16C672D4378B6731a8347D23B0c611de3;
        } else if (chainId == 1946) {
            c3callerProxyAddr = vm.envAddress("C3_DEPLOY_SONEIUM_MINATO");
            feeManagerAddr = 0xB37C81d6f90A16bbD778886AF49abeBfD1AD02C7;
            gatewayAddr = 0xF663c3De2d18920ffd7392242459275d0Dd249e4;
            deployerAddr = 0xa3325B2fA099c81a06d9b7532317d4a4Da7F2aB7;
            mapAddr = 0xa568D1Ed42CBE94E72b0ED736588200536917E0c;
        } else if (chainId == 2810) {
            c3callerProxyAddr = vm.envAddress("C3_DEPLOY_MORPH_HOLESKY");
            feeManagerAddr = 0x94C3fD7a91ee706B89214B9C2E9a505508109a3c;
            gatewayAddr = 0xa3325B2fA099c81a06d9b7532317d4a4Da7F2aB7;
            deployerAddr = 0xfC2175A02c2e1e673F1Ba374A321d274Bb29bD68;
            mapAddr = 0x48F214fDA66380A454DADAd9F84eF9D11d1f1D39;
        } else if (chainId == 534_351) {
            c3callerProxyAddr = vm.envAddress("C3_DEPLOY_SCROLL_SEPOLIA");
            feeManagerAddr = 0x94C3fD7a91ee706B89214B9C2E9a505508109a3c;
            gatewayAddr = 0xa3325B2fA099c81a06d9b7532317d4a4Da7F2aB7;
            deployerAddr = 0xfC2175A02c2e1e673F1Ba374A321d274Bb29bD68;
            mapAddr = 0x48F214fDA66380A454DADAd9F84eF9D11d1f1D39;
        } else if (chainId == 17_000) {
            c3callerProxyAddr = vm.envAddress("C3_DEPLOY_HOLESKY_TESTNET");
            feeManagerAddr = 0xe98eCde78f1E8Ca24445eCfc4b5560aF193C842F;
            gatewayAddr = 0x05a804374Bb77345854022Fd0CD2A602E00bF2E7;
            deployerAddr = 0x094bd93DF885D063e89B61702AaD4463dE313ebE;
            mapAddr = 0xAF685f104E7428311F25526180cbd416Fa8668CD;
        } else if (chainId == 5003) {
            c3callerProxyAddr = vm.envAddress("C3_DEPLOY_MANTLE_SEPOLIA");
            feeManagerAddr = 0x63135C26Ad4a67D9D5dCfbCCDc94F11de83eB2Ca;
            gatewayAddr = 0x563c5c85CC7ba923c50b66479588e5b3B2C93470;
            deployerAddr = 0x5020f191FD0ce7F9340659b2d03ea0ba5921B44A;
            mapAddr = 0xfC2175A02c2e1e673F1Ba374A321d274Bb29bD68;
        } else if (chainId == 4201) {
            c3callerProxyAddr = vm.envAddress("C3_DEPLOY_LUKSO_TESTNET");
            feeManagerAddr = 0xc74D2556d610F886B55653FAfFddF4bd0c1605B6;
            gatewayAddr = 0xdbD55D95D447E363251592A8FF573bBf16c2CB68;
            deployerAddr = 0xD4bD9BBA2fb97C36Bbd619303cAB636F476f8904;
            mapAddr = 0x1eE4bA474da815f728dF08F0147DeFac07F0BAb3;
        } else if (chainId == 80_084) {
            c3callerProxyAddr = vm.envAddress("C3_DEPLOY_BERA_BARTIO");
            feeManagerAddr = 0x9B0bc1e8267252B2E99fdA8c302b0713Ba3a8202;
            gatewayAddr = 0xbf56d054A81583e18c3D186aBACA3302bE399F3C;
            deployerAddr = 0x127d5ADA49071c33d10AA8de441e218a71475119;
            mapAddr = 0x8be9dda9F320c0D9598A487E3C8F57196d53AcAe;
        } else if (chainId == 168_587_773) {
            c3callerProxyAddr = vm.envAddress("C3_DEPLOY_BLAST_SEPOLIA");
            feeManagerAddr = 0xB75A2833405907508bD5f8DEa3A24FA537D9C85c;
            gatewayAddr = 0x74Da08aBCb64A66370E9C1609771e68aAfEDE27B;
            deployerAddr = 0x563c5c85CC7ba923c50b66479588e5b3B2C93470;
            mapAddr = 0xa3325B2fA099c81a06d9b7532317d4a4Da7F2aB7;
        } else if (chainId == 153) {
            c3callerProxyAddr = vm.envAddress("C3_DEPLOY_REDBELLY_TESTNET");
            feeManagerAddr = 0xb76428eBE853F2f6a5D74C4361B72999f55EE637;
            gatewayAddr = 0xDC635161b63Ca5281F96F2d70C3f7C0060d151d3;
            deployerAddr = 0xE305d37aDBE6F7c987108F537dc247F8Df5C1F24;
            mapAddr = 0xf7Ed4f388e07Ab2B9138D1f7CF2F0Cf6B23820aF;
        } else if (chainId == 11_155_420) {
            c3callerProxyAddr = vm.envAddress("C3_DEPLOY_OPTIMISM_SEPOLIA");
            feeManagerAddr = 0xD8fB50721bC30bF3E4D591c078747b4e7cE46e7A;
            gatewayAddr = 0x3b44962Bf264b8CebAC13DA24722faa27fC693a1;
            deployerAddr = 0xCFC2D5Fa55534019b3406257723506a3AB5e2Eed;
            mapAddr = 0xc8464ec2c98d3a0883E6bB64F08195AEFA807279;
        } else {
            revert("Bad chainId set");
        }

        // env variables (changes based on deployment chain, edit in .env)
        address govAddr = deployer;
        uint256 dappID5 = vm.envUint("DAPP_ID5"); // Storage
        uint256 dappID6 = vm.envUint("DAPP_ID6"); // Sentry

        txSender = deployer;

        vm.startBroadcast(deployerPrivateKey);

        (address ctmStorage, address ctmSentry) = deployCTMRWADeployer(
            1,
            1,
            govAddr,
            dappID5, // Storage
            dappID6 // Sentry
        );

        if (STORAGE) {
            console.log("CTM Storage Manager");
            console.log(ctmStorage);
        }
        if (SENTRY) {
            console.log("CTM Sentry Factory");
            console.log(ctmSentry);
        }

        vm.stopBroadcast();
    }

    function deployCTMRWADeployer(
        uint256 _rwaType,
        uint256 _version,
        address _gov,
        uint256 _dappIDStorageManager,
        uint256 _dappIDSentryManager
    ) internal returns (address, address) {
        if (STORAGE) {
            storageManager = new CTMRWA1StorageManager(
                _gov,
                _rwaType,
                _version,
                c3callerProxyAddr,
                txSender,
                _dappIDStorageManager,
                deployerAddr,
                gatewayAddr,
                feeManagerAddr
            );

            address storageManagerAddr = address(storageManager);
            // address storageManagerAddr = 0xFA1e6C9B7464668a01309c0969b0f6Fa893E8f;

            storageUtils = new CTMRWA1StorageUtils(_rwaType, _version, mapAddr, storageManagerAddr);

            // ICTMRWA1StorageManager(storageManagerAddr).setStorageUtils(address(storageUtils));
            storageManager.setStorageUtils(address(storageUtils));
            storageManager.setCtmRwaDeployer(deployerAddr);
            storageManager.setCtmRwaMap(mapAddr);

            ICTMRWADeployer(deployerAddr).setStorageFactory(_rwaType, _version, storageManagerAddr);
        }

        if (SENTRY) {
            sentryManager = new CTMRWA1SentryManager(
                _gov,
                _rwaType,
                _version,
                c3callerProxyAddr,
                txSender,
                _dappIDSentryManager,
                deployerAddr,
                gatewayAddr,
                feeManagerAddr
            );

            address sentryManagerAddr = address(sentryManager);

            sentryUtils = new CTMRWA1SentryUtils(_rwaType, _version, mapAddr, sentryManagerAddr);

            sentryManager.setSentryUtils(address(sentryUtils));
            sentryManager.setCtmRwaDeployer(deployerAddr);
            sentryManager.setCtmRwaMap(mapAddr);

            ICTMRWADeployer(deployerAddr).setSentryFactory(_rwaType, _version, address(sentryManager));
        }

        return (address(storageManager), address(sentryManager));
    }
}
