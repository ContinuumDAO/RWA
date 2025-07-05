// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import "forge-std/console.sol";

import {CTMRWA1XFallback} from "../src/crosschain/CTMRWA1XFallback.sol";
import {CTMRWAGateway} from "../src/crosschain/CTMRWAGateway.sol";
import {CTMRWA1X} from "../src/crosschain/CTMRWA1X.sol";

import {CTMRWADeployer} from "../src/deployment/CTMRWADeployer.sol";
import {CTMRWA1TokenFactory} from "../src/deployment/CTMRWA1TokenFactory.sol";

import {CTMRWA1DividendFactory} from "../src/dividend/CTMRWA1DividendFactory.sol";

import {FeeManager} from "../src/managers/FeeManager.sol";

import {CTMRWA1SentryManager} from "../src/sentry/CTMRWA1SentryManager.sol";

import {CTMRWAMap} from "../src/shared/CTMRWAMap.sol";

import {CTMRWA1StorageManager} from "../src/storage/CTMRWA1StorageManager.sol";

// import {CTMRWADeployer} from "../flattened/CTMRWADeployer.sol";
// import {CTMRWA1TokenFactory} from "../flattened/CTMRWA1TokenFactory.sol";
// import {CTMRWA1XFallback} from "../flattened/CTMRWA1XFallback.sol";
// import {FeeManager} from "../flattened/FeeManager.sol";
// import {CTMRWAGateway} from "../flattened/CTMRWAGateway.sol";
// import {CTMRWA1X} from "../flattened/CTMRWA1X.sol";

contract DeployPart1 is Script {

    CTMRWADeployer ctmRwaDeployer;
    CTMRWAGateway gateway;
    FeeManager feeManager;
    CTMRWA1X ctmRwa1X;
    CTMRWA1TokenFactory tokenFactory;
    CTMRWA1XFallback ctmRwaFallback;

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


        // deploy RWA1X
        ctmRwa1X = new CTMRWA1X(
            address(gateway),
            feeManagerAddr,
            govAddr,
            c3callerProxyAddr,
            txSender,
            dappID3
        );

        console.log("ctmRwa1X address");
        console.log(address(ctmRwa1X));

        ctmRwaFallback = new CTMRWA1XFallback(address(ctmRwa1X));

        ctmRwa1X.setFallback(address(ctmRwaFallback));
        console.log("ctmRwaFallback address");
        console.log(address(ctmRwaFallback));

    }
    
}
