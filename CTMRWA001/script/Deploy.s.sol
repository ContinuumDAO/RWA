// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.19;

import "forge-std/console.sol";
import {Script} from "forge-std/Script.sol";

// import {CTMRWADeployer} from "../contracts/CTMRWADeployer.sol";
// import {CTMRWAMap} from "../contracts/CTMRWAMap.sol";
// import {CTMRWA001TokenFactory} from "../contracts/CTMRWA001TokenFactory.sol";
// import {CTMRWA001XFallback} from "../contracts/CTMRWA001XFallback.sol";
// import {CTMRWA001DividendFactory} from "../contracts/CTMRWA001DividendFactory.sol";
// import {CTMRWA001StorageManager} from "../contracts/CTMRWA001StorageManager.sol";
// import {CTMRWA001SentryManager} from "../contracts/CTMRWA001SentryManager.sol";
// import {FeeManager} from "../contracts/FeeManager.sol";
// import {CTMRWAGateway} from "../contracts/CTMRWAGateway.sol";
// import {CTMRWA001X} from "../contracts/CTMRWA001X.sol";


import {CTMRWADeployer} from "../flattened/CTMRWADeployer.sol";
import {CTMRWAMap} from "../flattened/CTMRWAMap.sol";
import {CTMRWA001TokenFactory} from "../flattened/CTMRWA001TokenFactory.sol";
import {CTMRWA001XFallback} from "../flattened/CTMRWA001XFallback.sol";
import {CTMRWA001DividendFactory} from "../flattened/CTMRWA001DividendFactory.sol";
import {CTMRWA001StorageManager} from "../flattened/CTMRWA001StorageManager.sol";
import {CTMRWA001StorageUtils} from "../contracts/CTMRWA001StorageUtils.sol";
import {CTMRWAERC20Deployer} from "../contracts/CTMRWAERC20Deployer.sol";
import {CTMRWA001SentryManager} from "../flattened/CTMRWA001SentryManager.sol";
import {CTMRWA001SentryUtils} from "../contracts/CTMRWA001SentryUtils.sol";
import {FeeManager} from "../flattened/FeeManager.sol";
import {CTMRWAGateway} from "../flattened/CTMRWAGateway.sol";
import {CTMRWA001X} from "../flattened/CTMRWA001X.sol";




contract Deploy is Script {

    CTMRWADeployer ctmRwaDeployer;
    CTMRWAMap ctmRwaMap;
    CTMRWAGateway gateway;
    FeeManager feeManager;
    CTMRWA001X ctmRwa001X;
    CTMRWA001TokenFactory tokenFactory;
    CTMRWA001XFallback ctmRwaFallback;
    CTMRWAERC20Deployer ctmRwaErc20Deployer;
    CTMRWA001StorageManager storageManager;
    CTMRWA001SentryManager sentryManager;
    CTMRWA001StorageUtils storageUtils;
    CTMRWA001SentryUtils sentryUtils;
    CTMRWA001DividendFactory dividendFactory;

    address feeManagerAddr;


    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        console.log("Wallet of deployer");
        console.log(deployer);

        // env variables (changes based on deployment chain, edit in .env)
        address c3callerProxyAddr = vm.envAddress("C3_DEPLOY_LUKSO_TESTNET");
        address govAddr = deployer;
        uint256 dappID1 = vm.envUint("DAPP_ID1");  // Gateway
        uint256 dappID2 = vm.envUint("DAPP_ID2");  // FeeManager
        uint256 dappID3 = vm.envUint("DAPP_ID3");  // CTMRWAX
        uint256 dappID4 = vm.envUint("DAPP_ID4");  // CTMRWADEPLOYER
        uint256 dappID5 = vm.envUint("DAPP_ID5");  // CTMRWASTORAGE
        uint256 dappID6 = vm.envUint("DAPP_ID6");  // CTMRWASENTRY
        

        address txSender = deployer;

        vm.startBroadcast(deployerPrivateKey);

        // deploy fee manager
        feeManager = new FeeManager(govAddr, c3callerProxyAddr, txSender, dappID2);
        feeManagerAddr = address(feeManager);

        console.log("feeManager");
        console.log(feeManagerAddr);


        // deploy gateway
        gateway = new CTMRWAGateway(
            govAddr, 
            c3callerProxyAddr, 
            txSender,
            dappID1
        );

        console.log("gateway address");
        console.log(address(gateway));


        // deploy RWA001X
        ctmRwa001X = new CTMRWA001X(
            address(gateway),
            feeManagerAddr,
            govAddr,
            c3callerProxyAddr,
            txSender,
            dappID3
        );

        console.log("ctmRwa001X address");
        console.log(address(ctmRwa001X));

        ctmRwaFallback = new CTMRWA001XFallback(address(ctmRwa001X));

        ctmRwa001X.setFallback(address(ctmRwaFallback));
        console.log("ctmRwaFallback address");
        console.log(address(ctmRwaFallback));


        address ctmRwa001Map = deployMap();

        console.log("CTMRWAMap");
        console.log(ctmRwa001Map);


        (
            address ctmDeployer, 
            address ctmStorage,
            address ctmSentry,
            address ctmDividend, 
            address ctmRWA001Factory
        ) = deployCTMRWADeployer(
            1,
            1,
            govAddr,
            address(ctmRwa001X),
            ctmRwa001Map,
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
        console.log(ctmDividend);
        console.log("Sentry Factory");
        console.log(ctmSentry);
        console.log("CTMRWA001Factory");
        console.log(ctmRWA001Factory);

        vm.stopBroadcast();
    }

    function deployCTMRWADeployer(
        uint256 _rwaType,
        uint256 _version,
        address _gov,
        address _rwa001X,
        address _ctmRwa001Map,
        address _c3callerProxy,
        address _txSender,
        uint256 _dappIDDeployer,
        uint256 _dappIDStorageManager,
        uint256 _dappIDSentryManager
    ) internal returns(address, address, address, address, address) {
        ctmRwaDeployer = new CTMRWADeployer(
            _gov,
            address(gateway),
            feeManagerAddr,
            _rwa001X,
            _ctmRwa001Map,
            _c3callerProxy,
            _txSender,
            _dappIDDeployer
        );

        ctmRwaErc20Deployer = new CTMRWAERC20Deployer(
            _ctmRwa001Map,
            feeManagerAddr
        );

        ctmRwa001X.setCtmRwaDeployer(address(ctmRwaDeployer), address(ctmRwaErc20Deployer));
        ctmRwa001X.setCtmRwaMap(_ctmRwa001Map);

        tokenFactory = new CTMRWA001TokenFactory(_ctmRwa001Map, address(ctmRwaDeployer));

        ctmRwaDeployer.setTokenFactory(_rwaType, _version, address(tokenFactory));

        storageManager = new CTMRWA001StorageManager(
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

        storageUtils = new CTMRWA001StorageUtils(
            _rwaType,
            _version,
            _ctmRwa001Map,
            storageManagerAddr
        );


        sentryManager = new CTMRWA001SentryManager(
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

        address sentryManagerAddr = address(sentryManager);

        sentryUtils = new CTMRWA001SentryUtils(
            _rwaType,
            _version,
            _ctmRwa001Map,
            sentryManagerAddr
        );

        dividendFactory = new CTMRWA001DividendFactory(address(ctmRwaDeployer));

        storageManager.setStorageUtils(address(storageUtils));
        storageManager.setCtmRwaDeployer(address(ctmRwaDeployer));
        storageManager.setCtmRwaMap(_ctmRwa001Map);
        
        sentryManager.setSentryUtils(address(sentryUtils));
        sentryManager.setCtmRwaDeployer(address(ctmRwaDeployer));
        sentryManager.setCtmRwaMap(_ctmRwa001Map);

        ctmRwaDeployer.setStorageFactory(_rwaType, _version, address(storageManager));
        ctmRwaDeployer.setSentryFactory(_rwaType, _version, address(sentryManager));
        ctmRwaDeployer.setDividendFactory(_rwaType, _version, address(dividendFactory));

        return(address(ctmRwaDeployer), address(storageManager), address(sentryManager), address(dividendFactory), address(tokenFactory));
    }

    function deployMap() internal returns(address) {

        ctmRwaMap = new CTMRWAMap(
            address(gateway),
            address(ctmRwa001X)
        );

        return(address(ctmRwaMap));
    }
    
}
