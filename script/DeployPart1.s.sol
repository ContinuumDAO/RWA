// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.19;

import "forge-std/console.sol";
import {Script} from "forge-std/Script.sol";

// import {CTMRWADeployer} from "../src/CTMRWADeployer.sol";
// import {CTMRWAMap} from "../src/CTMRWAMap.sol";
// import {CTMRWA001TokenFactory} from "../src/CTMRWA001TokenFactory.sol";
// import {CTMRWA001XFallback} from "../src/CTMRWA001XFallback.sol";
// import {CTMRWA001DividendFactory} from "../src/CTMRWA001DividendFactory.sol";
// import {CTMRWA001StorageManager} from "../src/CTMRWA001StorageManager.sol";
// import {CTMRWA001SentryManager} from "../src/CTMRWA001SentryManager.sol";
// import {FeeManager} from "../src/FeeManager.sol";
// import {CTMRWAGateway} from "../src/CTMRWAGateway.sol";
// import {CTMRWA001X} from "../src/CTMRWA001X.sol";

import {CTMRWADeployer} from "../flattened/CTMRWADeployer.sol";
import {CTMRWA001TokenFactory} from "../flattened/CTMRWA001TokenFactory.sol";
import {CTMRWA001XFallback} from "../flattened/CTMRWA001XFallback.sol";
import {FeeManager} from "../flattened/FeeManager.sol";
import {CTMRWAGateway} from "../flattened/CTMRWAGateway.sol";
import {CTMRWA001X} from "../flattened/CTMRWA001X.sol";





contract DeployPart1 is Script {

    CTMRWADeployer ctmRwaDeployer;
    CTMRWAGateway gateway;
    FeeManager feeManager;
    CTMRWA001X ctmRwa001X;
    CTMRWA001TokenFactory tokenFactory;
    CTMRWA001XFallback ctmRwaFallback;

    address feeManagerAddr;


    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        console.log("Wallet of deployer");
        console.log(deployer);

        // env variables (changes based on deployment chain, edit in .env)
        address c3callerProxyAddr = vm.envAddress("C3_DEPLOY_CORE_TESTNET");
        address govAddr = deployer;
        uint256 dappID1 = vm.envUint("DAPP_ID1");
        uint256 dappID2 = vm.envUint("DAPP_ID2");
        uint256 dappID3 = vm.envUint("DAPP_ID3");
        // uint256 dappID4 = vm.envUint("DAPP_ID4");
        // uint256 dappID5 = vm.envUint("DAPP_ID5");
        // uint256 dappID6 = vm.envUint("DAPP_ID6");
        

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

    }
    
}
