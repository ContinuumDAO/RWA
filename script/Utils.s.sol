// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.27;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";

struct DeployedContracts {
    string chainIdStr;
    address feeManager;
    address gateway;
    address rwa1X;
    address rwa1XFallback;
    address map;
    address deployer;
    address deployInvest;
    address erc20Deployer;
    address tokenFactory;
    address dividendFactory;
    address storageManager;
    address storageUtils;
    address sentryManager;
    address sentryUtils;
    address feeToken;
}
