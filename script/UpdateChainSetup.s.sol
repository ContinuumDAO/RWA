// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.22;

import { Script } from "forge-std/Script.sol";
import { console } from "forge-std/console.sol";

import { ICTMRWAGateway } from "../src/crosschain/ICTMRWAGateway.sol";

contract UpdateChainSetup is Script {
    uint256 rwaType = 1;
    uint256 version = 1;

    string[] feeTokensStr;
    uint256[] fees;

    string[] chainIdsStr;
    string[] gwaysStr;
    string[] rwa1XsStr;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        console.log("Wallet of deployer");
        console.log(deployer);

        fees.push(0);

        vm.startBroadcast(deployerPrivateKey);

        // Bitlayer Testnet
        string memory chainIdStr = "200810";
        string memory gatewayDestAddrStr = "0x005c5Fd1585A73817107bFd3929f7e559750ceEd";
        string memory rwa1XAddrStr = "0xDef5D31e4b2E0BF38Af3E8092a5ABF51Db484Eec";
        // address feeManager = 0x6EE5C158882857c7F52b37FCe37B1CF39944f22E;

        console.log("For Arb Sepolia");
        chainIdsStr.push(chainIdStr);
        gwaysStr.push(gatewayDestAddrStr);
        rwa1XsStr.push(rwa1XAddrStr);
        address gateway = 0x8Ea9B4616e5653CF21B87e60c8D72d8384685ec6;
        ICTMRWAGateway(gateway).addChainContract(chainIdsStr, gwaysStr);
        gwaysStr.pop();
        ICTMRWAGateway(gateway).attachRWAX(rwaType, version, chainIdsStr, rwa1XsStr);
        chainIdsStr.pop();

        vm.stopBroadcast();
    }
}
