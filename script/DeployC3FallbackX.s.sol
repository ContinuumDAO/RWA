// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.19;

import "forge-std/console.sol";
import {Script} from "forge-std/Script.sol";

import {CTMRWA001XFallback} from "../contracts/CTMRWA001XFallback.sol";
import {CTMRWA001X} from "../contracts/CTMRWA001X.sol";
import {ICTMRWA001X} from "../contracts/interfaces/ICTMRWA001X.sol";



contract DeployC3FallbackX is Script {

    CTMRWA001XFallback ctmRwaFallback;
   

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        console.log("Wallet of deployer");
        console.log(deployer);


        vm.startBroadcast(deployerPrivateKey);

        address ctmRwa001XAddr = 0x22D305a430b57a12D569f1e578B9F2f7613f92F8;


        ctmRwaFallback = new CTMRWA001XFallback(ctmRwa001XAddr);

        // ICTMRWA001X(ctmRwa001XAddr).setFallback(address(ctmRwaFallback));
        console.log("ctmRwaFallback address");
        console.log(address(ctmRwaFallback));

        vm.stopBroadcast();
    }

}
