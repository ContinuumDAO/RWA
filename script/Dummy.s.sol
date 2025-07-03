// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import "forge-std/console.sol";

contract Dummy is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        // address deployer = vm.addr(deployerPrivateKey);

        vm.startBroadcast(deployerPrivateKey);
        Test test = new Test();

        uint256 res = test.add(5,6);
        console.log(res);

        vm.stopBroadcast();
    }
}

contract Test {
    function add(uint256 a, uint256 b) external pure returns(uint256) {
        return(a+b);
    }
}
