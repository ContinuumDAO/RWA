// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.23;

import "forge-std/console.sol";
import {Script} from "forge-std/Script.sol";

import {CTMRWADeployer} from "../contracts/CTMRWADeployer.sol";
import {CTMRWAMap} from "../contracts/CTMRWAMap.sol";
import {CTMRWA001TokenFactory} from "../contracts/CTMRWA001TokenFactory.sol";
import {CTMRWA001XFallback} from "../contracts/CTMRWA001XFallback.sol";
import {CTMRWA001DividendFactory} from "../contracts/CTMRWA001DividendFactory.sol";
import {CTMRWA001StorageManager} from "../contracts/CTMRWA001StorageManager.sol";

import {FeeManager} from "../contracts/FeeManager.sol";
import {CTMRWAGateway} from "../contracts/CTMRWAGateway.sol";
import {CTMRWA001X} from "../contracts/CTMRWA001X.sol";


// import {CTMRWADeployer} from "../flattened/CTMRWADeployer.sol";
// import {CTMRWA001TokenFactory} from "../flattened/CTMRWA001TokenFactory.sol";
// import {CTMRWA001XFallback} from "../flattened/CTMRWA001XFallback.sol";
// import {CTMRWA001DividendFactory} from "../flattened/CTMRWA001DividendFactory.sol";
// import {CTMRWA001StorageManager} from "../flattened/CTMRWA001StorageManager.sol";

// import {FeeManager} from "../flattened/FeeManager.sol";
// import {CTMRWAGateway} from "../flattened/CTMRWAGateway.sol";
// import {CTMRWA001X} from "../flattened/CTMRWA001X.sol";




contract Deploy is Script {

    CTMRWADeployer ctmRwaDeployer;
    CTMRWAMap ctmRwaMap;
    CTMRWAGateway gateway;
    CTMRWA001X ctmRwa001X;
    CTMRWA001TokenFactory tokenFactory;
    CTMRWA001XFallback ctmRwaFallback;
    CTMRWA001StorageManager storageManager;
    CTMRWA001DividendFactory dividendFactory;


    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        console.log("Wallet of deployer");
        console.log(deployer);

        // env variables (changes based on deployment chain, edit in .env)
        address c3callerProxyAddr = vm.envAddress("C3_DEPLOY_BSC_TESTNET");
        address govAddr = deployer;
        uint256 dappID1 = vm.envUint("DAPP_ID1");
        uint256 dappID2 = vm.envUint("DAPP_ID2");
        uint256 dappID3 = vm.envUint("DAPP_ID3");
        uint256 dappID4 = vm.envUint("DAPP_ID4");
        uint256 dappID5 = vm.envUint("DAPP_ID5");
        

        address txSender = deployer;

        vm.startBroadcast(deployerPrivateKey);

        // deploy fee manager
        FeeManager feeManager = new FeeManager(govAddr, c3callerProxyAddr, txSender, dappID1);
        address feeManagerAddr = address(feeManager);

        console.log("feeManager");
        console.log(feeManagerAddr);


        // deploy gateway
        gateway = new CTMRWAGateway(
            govAddr, 
            c3callerProxyAddr, 
            txSender,
            dappID4
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
            dappID2
        );

        console.log("ctmRwa001X address");
        console.log(address(ctmRwa001X));

        ctmRwaFallback = new CTMRWA001XFallback(address(ctmRwa001X));

        ctmRwa001X.setFallback(address(ctmRwaFallback));
        console.log("ctmRwaFallback address");
        console.log(address(ctmRwaFallback));


        address ctmMap = deployMap(govAddr);

        console.log("CTMRWAMap");
        console.log(ctmMap);

        ctmRwa001X.setCtmRwaMap(ctmMap);
        

        (
            address ctmDeployer, 
            address ctmStorage,
            address ctmDividend, 
            address ctmRWA001Factory
        ) = deployCTMRWADeployer(
            1,
            1,
            govAddr,
            address(ctmRwa001X),
            ctmMap,
            c3callerProxyAddr,
            txSender,
            dappID3,
            dappID5
        );

        console.log("ctmRWADeployer");
        console.log(ctmDeployer);
        console.log("CTM Storage");
        console.log(ctmStorage);
        console.log("Dividend Factory");
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
        address _map,
        address _c3callerProxy,
        address _txSender,
        uint256 _dappIDDeployer,
        uint256 _dappIDStorageManager
    ) internal returns(address, address, address, address) {
        ctmRwaDeployer = new CTMRWADeployer(
            _gov,
            _rwa001X,
            _map,
            _c3callerProxy,
            _txSender,
            _dappIDDeployer
        );

        tokenFactory = new CTMRWA001TokenFactory(_map, address(ctmRwaDeployer));

        ctmRwaDeployer.setTokenFactory(_rwaType, _version, address(tokenFactory));

        storageManager = new CTMRWA001StorageManager(
            _gov,
            _rwaType,
            _version,
            _c3callerProxy,
            _txSender,
            _dappIDStorageManager,
            address(ctmRwaDeployer)
        );

        dividendFactory = new CTMRWA001DividendFactory(address(ctmRwaDeployer));


        ctmRwaDeployer.setStorageFactory(_rwaType, _version, address(storageManager));
        ctmRwaDeployer.setDividendFactory(_rwaType, _version, address(dividendFactory));

        return(address(ctmRwaDeployer), address(storageManager), address(dividendFactory), address(tokenFactory));
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
