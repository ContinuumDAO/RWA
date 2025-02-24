// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.19;

import "forge-std/console.sol";
import {Script} from "forge-std/Script.sol";

import {ICTMRWADeployer} from "../contracts/interfaces/ICTMRWADeployer.sol";
import {CTMRWAGateway} from "../contracts/CTMRWAGateway.sol";
import {CTMRWA001X} from "../contracts/CTMRWA001X.sol";

// DEBUG ctmRwa001X address
//   0x3B63cD222C5080cDeA921B8D3cF4A692b8DfEE4D


contract DeployDebugRwaX is Script {

    CTMRWA001X ctmRwa001X;

    address gatewayAddr;
    address feeManagerAddr;


    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        console.log("Wallet of deployer");
        console.log(deployer);

        // env variables (changes based on deployment chain, edit in .env)
        address c3callerProxyAddr = vm.envAddress("C3_DEPLOY_BSC_TESTNET");
        address govAddr = deployer;
        uint256 dappID2 = vm.envUint("DAPP_ID2");
        

        address txSender = deployer;

        vm.startBroadcast(deployerPrivateKey);

        gatewayAddr = address(0x291E038Ef58dcFDF020e0BBEA0C9a36713dB7966);
        feeManagerAddr = address(0xBCe6B1Ab3790BCe90E2299cc9C46f6D2bCB56324);

     

        // deploy RWA001X
        ctmRwa001X = new CTMRWA001X(
            gatewayAddr,
            feeManagerAddr,
            govAddr,
            c3callerProxyAddr,
            txSender,
            dappID2
        );




        console.log("ctmRwa001X address");
        console.log(address(ctmRwa001X));

        address ctmRwaFallbackAddr = address(0xEa911684c200aC1FD3Ca8A3FFD21aFE9EF0e35Da);
        ctmRwa001X.setFallback(ctmRwaFallbackAddr);

        address ctmRwa001MapAddr = address(0x69D461E1314af5E3bcab39f0ebA3872c5de2c1e5);
        ctmRwa001X.setCtmRwaMap(ctmRwa001MapAddr);

        address ctmRwaDeployerAddr = address(0x038a39974a702ada213a318c855792244884EDCC);
        ctmRwa001X.setCtmRwaDeployer(ctmRwaDeployerAddr);

        // ICTMRWADeployer(ctmRwaDeployerAddr).setRwaX(address(ctmRwa001X));  // MUST CHANGE BACK


        vm.stopBroadcast();
    }

    
}
