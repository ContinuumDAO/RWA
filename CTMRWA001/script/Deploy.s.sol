// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.20;

import "forge-std/console.sol";
import {Script} from "forge-std/Script.sol";

import {CTMRWA001Deployer} from "../contracts/CTMRWA001Deployer.sol";
import {FeeManager} from "../contracts/FeeManager.sol";
import {CTMRWA001X} from "../contracts/CTMRWA001X.sol";

contract Deploy is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        // env variables (changes based on deployment chain, edit in .env)
        address c3callerProxyAddr = vm.envAddress("C3_DEPLOY");
        address govAddr = deployer;
        uint256 dappID = vm.envUint("DAPP_ID");

        address txSender = deployer;

        vm.startBroadcast(deployerPrivateKey);

        // deploy fee manager
        FeeManager feeManager = new FeeManager(govAddr, c3callerProxyAddr, txSender, dappID);
        address feeManagerAddr = address(feeManager);

        // deploy factory
        CTMRWA001Deployer ctmRwa001Deployer = new CTMRWA001Deployer();
        address ctmRwa001DeployerAddr = address(ctmRwa001Deployer);

        // deploy gateway
        CTMRWA001X ctmRwa001X = new CTMRWA001X(
            feeManagerAddr,
            ctmRwa001DeployerAddr,
            govAddr,
            c3callerProxyAddr,
            txSender,
            dappID
        );

        vm.stopBroadcast();
    }
}