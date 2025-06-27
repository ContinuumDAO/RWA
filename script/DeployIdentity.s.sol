// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.19;

import "forge-std/console.sol";
import {Script} from "forge-std/Script.sol";

import {CTMRWA001Identity} from "../contracts/CTMRWA001Identity.sol";

import {RequestId, ICTMRWA001Identity} from "../contracts/interfaces/ICTMRWA001Identity.sol";


contract DeployPolygonId is Script {
    uint256 rwaType = 1;
    uint256 version = 1;


    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        console.log("Wallet of deployer");
        console.log(deployer);

        require(block.chainid == 534351, "Must be connected to Scroll Sepolia");

        // env variables (changes based on deployment chain, edit in .env)
        address c3callerProxyAddr = vm.envAddress("C3_DEPLOY_SCROLL_SEPOLIA");
        address govAddr = deployer;
        uint256 dappID6 = vm.envUint("DAPP_ID6");
        
        address txSender = deployer; 
        address mapAddr = 0x18433A774aF5d473191903A5AF156f3Eb205bBA4;
        address sentryManagerAddr = 0xBa59F04dbdcB1B74d601fbBF3E7e1ca82081c536;
        address feeManagerAddr = 0x2D2112DE9801EAf71B6D1cBf40A99E57AFc235a7;

        address verifierAddr = 0xf8E1973814E66BF03002862C325305A5EeF98cc1;  //zkMe


        vm.startBroadcast(deployerPrivateKey);

        console.log("Deploying Identity contract...");

        CTMRWA001Identity ctmIdentity = new CTMRWA001Identity (
            govAddr,
            rwaType,
            version,
            c3callerProxyAddr,
            txSender,
            dappID6,
            mapAddr,
            sentryManagerAddr,
            feeManagerAddr
        );

        address ctmIdAddr = address(ctmIdentity);

        console.log("CTMRWA001Identity");
        console.log(ctmIdAddr);

        console.log("Setting zKMe verifier address");

        ICTMRWA001Identity(ctmIdAddr).setZkMeVerifierAddress(verifierAddr);

        console.log("Finished");

        vm.stopBroadcast();

    }

        

}