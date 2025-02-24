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
// // import {FeeManager} from "../contracts/FeeManager.sol";
// import {CTMRWAGateway} from "../contracts/CTMRWAGateway.sol";
// import {CTMRWA001X} from "../contracts/CTMRWA001X.sol";


import {CTMRWADeployer} from "../flattened/CTMRWADeployer.sol";
import {CTMRWAMap} from "../flattened/CTMRWAMap.sol";
import {CTMRWA001TokenFactory} from "../flattened/CTMRWA001TokenFactory.sol";
import {CTMRWA001XFallback} from "../flattened/CTMRWA001XFallback.sol";
import {CTMRWA001DividendFactory} from "../flattened/CTMRWA001DividendFactory.sol";
import {CTMRWA001StorageManager} from "../flattened/CTMRWA001StorageManager.sol";
import {CTMRWA001SentryManager} from "../flattened/CTMRWA001SentryManager.sol";
// import {FeeManager} from "../flattened/FeeManager.sol";
import {CTMRWAGateway} from "../flattened/CTMRWAGateway.sol";
import {CTMRWA001X} from "../flattened/CTMRWA001X.sol";

import {ICTMRWAGateway} from "../contracts/interfaces/ICTMRWAGateway.sol";
import {ICTMRWA001X} from "../contracts/interfaces/ICTMRWA001X.sol";




contract DeployPart2 is Script {

    CTMRWADeployer ctmRwaDeployer;
    CTMRWAMap ctmRwaMap;
    // CTMRWAGateway gateway;
    // FeeManager feeManager;
    // CTMRWA001X ctmRwa001X;
    CTMRWA001TokenFactory tokenFactory;
    CTMRWA001XFallback ctmRwaFallback;
    CTMRWA001StorageManager storageManager;
    CTMRWA001SentryManager sentryManager;
    CTMRWA001DividendFactory dividendFactory;


    address rwa001XAddr = 0x266442249F62A8Dd4e29348A52af8c806c7CB0da;
    address gatewayAddr = 0x3b44962Bf264b8CebAC13DA24722faa27fC693a1;
    address feeManagerAddr = 0xD8fB50721bC30bF3E4D591c078747b4e7cE46e7A;

    ICTMRWAGateway gateway;
    ICTMRWA001X ctmRwa001X;


    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        console.log("Wallet of deployer");
        console.log(deployer);

        // env variables (changes based on deployment chain, edit in .env)
        address c3callerProxyAddr = vm.envAddress("C3_DEPLOY_OPTIMISM_SEPOLIA");
        address govAddr = deployer;
        // uint256 dappID1 = vm.envUint("DAPP_ID1");
        // uint256 dappID2 = vm.envUint("DAPP_ID2");
        uint256 dappID3 = vm.envUint("DAPP_ID3");
        // uint256 dappID4 = vm.envUint("DAPP_ID4");
        uint256 dappID5 = vm.envUint("DAPP_ID5");
        uint256 dappID6 = vm.envUint("DAPP_ID6");
        

        address txSender = deployer;

        vm.startBroadcast(deployerPrivateKey);

        // // deploy fee manager
        // feeManager = new FeeManager(govAddr, c3callerProxyAddr, txSender, dappID1);
        // feeManagerAddr = address(feeManager);

        // console.log("feeManager");
        // console.log(feeManagerAddr);


        // // deploy gateway
        // gateway = new CTMRWAGateway(
        //     govAddr, 
        //     c3callerProxyAddr, 
        //     txSender,
        //     dappID4
        // );

        // console.log("gateway address");
        // console.log(address(gateway));


        // // deploy RWA001X
        // ctmRwa001X = new CTMRWA001X(
        //     address(gateway),
        //     feeManagerAddr,
        //     govAddr,
        //     c3callerProxyAddr,
        //     txSender,
        //     dappID2
        // );

        // console.log("ctmRwa001X address");
        // console.log(address(ctmRwa001X));

        // ctmRwaFallback = new CTMRWA001XFallback(address(ctmRwa001X));

        // ctmRwa001X.setFallback(address(ctmRwaFallback));
        // console.log("ctmRwaFallback address");
        // console.log(address(ctmRwaFallback));

        

        gateway = ICTMRWAGateway(gatewayAddr);
        ctmRwa001X = ICTMRWA001X(rwa001XAddr);


        address ctmRwa001Map = deployMap(govAddr);

        console.log("CTMRWAMap");
        console.log(ctmRwa001Map);

        ctmRwa001X.setCtmRwaMap(ctmRwa001Map);
        

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
            dappID3,
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
        console.log("CTMRWA001Factory");
        console.log(ctmRWA001Factory);

        ctmRwaMap.setCtmRwaDeployer(address(ctmRwaDeployer));

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

        ctmRwa001X.setCtmRwaDeployer(address(ctmRwaDeployer));

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

        dividendFactory = new CTMRWA001DividendFactory(address(ctmRwaDeployer));
        storageManager.setCtmRwaDeployer(address(ctmRwaDeployer));
        storageManager.setCtmRwaMap(_ctmRwa001Map);
        sentryManager.setCtmRwaDeployer(address(ctmRwaDeployer));
        sentryManager.setCtmRwaMap(_ctmRwa001Map);

        ctmRwaDeployer.setStorageFactory(_rwaType, _version, address(storageManager));
        ctmRwaDeployer.setSentryFactory(_rwaType, _version, address(sentryManager));
        ctmRwaDeployer.setDividendFactory(_rwaType, _version, address(dividendFactory));

        return(address(ctmRwaDeployer), address(storageManager), address(sentryManager), address(dividendFactory), address(tokenFactory));
    }

    function deployMap(address _gov) internal returns(address) {

        ctmRwaMap = new CTMRWAMap(
            _gov,
            address(gateway),
            address(ctmRwa001X)
        );

        return(address(ctmRwaMap));
    }
    
}
