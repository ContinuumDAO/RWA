// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.19;

import "forge-std/console.sol";
import {Script} from "forge-std/Script.sol";

import {CTMRWA001PolygonId} from "../contracts/CTMRWA001PolygonId.sol";

import {RequestId, ICTMRWA001PolygonId} from "../contracts/interfaces/ICTMRWA001PolygonId.sol";


contract DeployPolygonId is Script {
    uint256 rwaType = 1;
    uint256 version = 1;


    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        console.log("Wallet of deployer");
        console.log(deployer);

        require(block.chainid == 80002, "Must be connected to Polygon Amoy");

        // env variables (changes based on deployment chain, edit in .env)
        address c3callerProxyAddr = vm.envAddress("C3_DEPLOY_AMOY");
        address govAddr = deployer;
        uint256 dappID6 = vm.envUint("DAPP_ID6");
        
        address txSender = deployer;
        address mapAddr = 0x18433A774aF5d473191903A5AF156f3Eb205bBA4;
        address sentryManagerAddr = 0xBa59F04dbdcB1B74d601fbBF3E7e1ca82081c536;
        address feeManagerAddr = 0x2D2112DE9801EAf71B6D1cBf40A99E57AFc235a7;

        address verifierAddr = 0xfcc86A79fCb057A8e55C6B853dff9479C3cf607c;


        vm.startBroadcast(deployerPrivateKey);

        console.log("Deploying PolygonId contract...");

        CTMRWA001PolygonId ctmPolygonId = new CTMRWA001PolygonId (
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

        address ctmPolygonIdAddr = address(ctmPolygonId);

        console.log("CTMRWA001PolygonId");
        console.log(ctmPolygonIdAddr);

        console.log("Setting PrivadoID verifier address");

        ICTMRWA001PolygonId(ctmPolygonIdAddr).setVerifierAddress(verifierAddr);

        console.log("Finished");

        vm.stopBroadcast();

    }

        

}