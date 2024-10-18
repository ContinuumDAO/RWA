// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.23;

import "forge-std/console.sol";
import {Script} from "forge-std/Script.sol";

import {CTMRWAGateway} from "../contracts/CTMRWAGateway.sol";
import {FeeManager} from "../contracts/FeeManager.sol";
import {ICTMRWAGateway} from "../contracts/interfaces/ICTMRWAGateway.sol";
import {IFeeManager} from "../contracts/interfaces/IFeeManager.sol";



contract NewChainSetup is Script {

    uint256 rwaType = 1;
    uint256 version = 1;

    CTMRWAGateway gatewayDest;

    string[] feeTokensStr;
    uint256[] fees;
    
   

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        console.log("Wallet of deployer");
        console.log(deployer);

        fees.push(0);

        vm.startBroadcast(deployerPrivateKey);

        // Bitlayer Testnet
        string memory chainIdStr = "84532";
        address gatewayDestAddr = 0x4c054027b323baaC49100c0929097df88B3e4b47;
        address feeManagerAddr = 0x298F37599789926A4ab495F72d3Bb5CC7838ff73;
        string memory feeTokenStr = "0x6a4DBC971533Ba36bdc23aD70F5A7a12E064f4ae";
        
        

        string memory chainContractStr = ICTMRWAGateway(gatewayDestAddr).getChainContract(chainIdStr);
        console.log("chainContractStr");
        console.log(chainContractStr);

        console.log("For Base");
        console.log("Adding Arb Sepolia...");
        ICTMRWAGateway(gatewayDestAddr).addChainContract("421614", "0x8Ea9B4616e5653CF21B87e60c8D72d8384685ec6");
        ICTMRWAGateway(gatewayDestAddr).attachRWAX(rwaType, version, "421614", "0x5330db730fAb0Bf0bB9db2FCefe7b1876c09a242");

        console.log("Adding BSC Testnet...");
        ICTMRWAGateway(gatewayDestAddr).addChainContract("97", "0x2BE0C4Ac75784737D4D0E75C4026d4Bc671B938E");
        ICTMRWAGateway(gatewayDestAddr).attachRWAX(rwaType, version, "97", "0x048A5cefCDF0faeB734bc4A941E0de44d8c49f55");

        console.log("Adding Bitlayer Testnet...");
        ICTMRWAGateway(gatewayDestAddr).addChainContract("200810", "0x005c5Fd1585A73817107bFd3929f7e559750ceEd");
        ICTMRWAGateway(gatewayDestAddr).attachRWAX(rwaType, version, "200810", "0xDef5D31e4b2E0BF38Af3E8092a5ABF51Db484Eec");




        console.log("Adding Fee Token");
        feeTokensStr.push(feeTokenStr);

        IFeeManager(feeManagerAddr).addFeeToken(feeTokensStr[0]);
        
        IFeeManager(feeManagerAddr).addFeeToken("421614", feeTokensStr, fees);
        IFeeManager(feeManagerAddr).addFeeToken("97", feeTokensStr, fees);
        IFeeManager(feeManagerAddr).addFeeToken("200810", feeTokensStr, fees);
        feeTokensStr.pop();

        vm.stopBroadcast();
    }

}
