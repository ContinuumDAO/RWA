// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import "forge-std/console.sol";

import {ICTMRWA1X} from "../src/crosschain/ICTMRWA1X.sol";
import {CTMRWA1X} from "../src/crosschain/CTMRWA1X.sol";
import {CTMRWA1XFallback} from "../src/crosschain/CTMRWA1XFallback.sol";

contract DeployC3FallbackX is Script {
  CTMRWA1XFallback ctmRwaFallback;

  function run() external {
    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
    address deployer = vm.addr(deployerPrivateKey);
    console.log("Wallet of deployer");
    console.log(deployer);

    vm.startBroadcast(deployerPrivateKey);

    address ctmRwa1XAddr = 0x22D305a430b57a12D569f1e578B9F2f7613f92F8;

    ctmRwaFallback = new CTMRWA1XFallback(ctmRwa1XAddr);

    // ICTMRWA1X(ctmRwa1XAddr).setFallback(address(ctmRwaFallback));
    console.log("ctmRwaFallback address");
    console.log(address(ctmRwaFallback));

    vm.stopBroadcast();
  }
}
