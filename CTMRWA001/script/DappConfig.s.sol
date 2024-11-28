// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.23;

import "forge-std/console.sol";
import {Script} from "forge-std/Script.sol";

import "@openzeppelin/contracts/utils/Strings.sol";

// import {CTMRWAGateway} from "../flattened/CTMRWAGateway.sol";
// import {FeeManager} from "../flattened/FeeManager.sol";
import {ICTMRWAGateway} from "../contracts/interfaces/ICTMRWAGateway.sol";
import {IFeeManager, FeeType} from "../contracts/interfaces/IFeeManager.sol";

struct NewChain {
    uint256 chainId;
    address gateway;
    address rwaX;
    address feeManager;
    address storageManager;
    address deployer;
}


interface IDapp {
    function addDappAddr(uint256 dappID, string[] memory whitelist) external;
}

contract DappConfig is Script {
    using Strings for *;

    string[] wList;

    address dappContract = address(0xf77C7BdF97245EB9b12e7d7C10ab6ABc2ABA0f6a);

    NewChain[] newchains;


    // struct NewChain {
    //     uint256 chainId;
    //     address gateway;
    //     address rwaX;
    //     address feeManager;
    //     address storageManager;
    //     address deployer;
    // }

    constructor() {
        newchains.push(NewChain(    // ARB Sepolia
            421614,
            0xD990EF52a6a375B19375B07cfC2AAD2B592E66Be,
            0x8BDe23E16f4F9b19b3E11EdCb65168E7f2720006,
            0x33348aa4A1D62757Eb6077C86554672Dd22902Ae,
            0xf4E9Dc949cA6EB2bBaFA1e887017E91E523C1BC8,
            0x4E154f20a4C932378457ebE90044566939605f9D
        ));
        newchains.push(NewChain(   // POLYGON AMOY  Chain 80002
            80002,
            0x73a3ECD2fad26975d16B31E482EAF0f5152d420E,
            0x4DA174a7024b242Fb979D120EE63F1Bf6Aba3E07,
            0xcC2461B294f68e860B046038Df8Ad3A2A8C2fC51,
            0xb07C3788549cd48aD1d4Cb9B7336f7C9Dd53D67F,
            0xBCe6B1Ab3790BCe90E2299cc9C46f6D2bCB56324
        ));
        newchains.push(NewChain(  // BASE SEPOLIA  Chain 84532
            84532,
            0x497d31415cc6D20113d2F96c90C706b98701c1c9,
            0xbe87477FD18FbEbD8cCcdD003f6F66FFC4D49CD1,
            0x1b902Cf02724ac790DA51e8004B82c7d0DE6F957,
            0x2c4be93Acd346CA06363b37a06bEb9D693d02dAc,
            0xF5F405ccF62c2E9f636f9f0de9878dD26550B63d
        ));
        // newchains.push(NewChain(  // LINEA SEPOLIA Chain 59141
        //     59141,
            
        // ));
        // newchains.push(NewChain(  // CONFLUX ESPACE  Chain 71
        //     71,
            
        // ));
        // newchains.push(NewChain(  // CORE Testnet Chain 1115
        //     1115,
           
        // ));
        // newchains.push(NewChain(  // HOLESKY Chain 17000
        //     17000,
            
        // ));
        // newchains.push(NewChain(  // MORPH HOLESKY  Chain 2810
        //     2810,
            
        // ));
        // newchains.push(NewChain(  // BLAST SEPOLIA Chain 168587773
        //     168587773,
            
        // ));
        // newchains.push(NewChain(  // BITLAYER TESTNET Chain 200810
        //     200810,
            
        // ));
        // newchains.push(NewChain(  // SCROLL SEPOLIA   Chain 534351
        //     534351,
            
        // ));
        // newchains.push(NewChain(  // MANTLE SEPOLIA Chain 5003
        //     5003,
            
        // ));
        // newchains.push(NewChain(  // LUKSO TESTNET  Chain 4201
        //     4201,
            
        // ));
        // newchains.push(NewChain(  // BERA_BARTIO Chain 80084
        //     80084,
            
        // ));
        // newchains.push(NewChain(  // LUMIA TESTNET Chain 1952959480
        //     1952959480,
            
        // ));
        // newchains.push(NewChain(  // PLUME TESTNET Chain 161221135
        //     161221135,
            
        // ));
        // newchains.push(NewChain(  // VANGUARD Chain 78600
        //     78600,
            
        // ));
        // newchains.push(NewChain(  // RARI TESTNET Chain 1918988905
        //     1918988905,
            
        // ));
        // newchains.push(NewChain(  // U2U NEBULAS TESTNET Chain 2484
        //     2484,
            
        // ));
        // newchains.push(NewChain(  // SONEIUM MINATO Chain 1946
        //     1946,
            
        // ));
        // newchains.push(NewChain(  // OPBNB TESTNET  Chain 5611
        //     5611,
            
        // ));
        // newchains.push(NewChain(  // SONIC TESTNET  Chain 64165
        //     64165,
            
        // ));
        // newchains.push(NewChain(  // FIRE THUNDER  Chain 997
        //     997,
            
        // ));
        // newchains.push(NewChain(  // HUMANODE TESTNET ISRAFEL  Chain 14853
        //     14853,
            
        // ));
        // newchains.push(NewChain(   // CRONOS TESTNET   Chain 338
        //     338,
            
        // ));
        newchains.push(NewChain(  //  BSC TESTNET Chain 97
            97,
            0x9B191600588B59e314D2927204c8EdC57603D672,
            0x730e8b2D89bA0D3403bb3d8C9929A9f0da61E051,
            0x0bCb87c43E2ad859412D90892FF73d64C6DbB962,
            0xc653cd79F70165005319eF97Ad1229aC7f88a25D,
            0xDf495F3724a6c705fed4aDfa7588Cd326162A39c
        ));
        newchains.push(NewChain(  //  SEPOLIA  Chain 11155111
            11155111,
            0x3CB56e6E5917a2a8924BC2A5C1f0ecc90b585e74,
            0x1F652e2D8A9FCa346A0F45D59a67FB998999e454,
            0xa3bae05aA45bcC739258b124FACE332043D3B1dA,
            0xA33cfD901896C775c5a6d62e94081b4Fdd1B09BC,
            0xeFbd6990A5C4ABFA30b91409aA3d9A0e7C8Bb77b
        ));
    }


    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        console.log("Wallet of deployer");
        console.log(deployer);

        vm.startBroadcast(deployerPrivateKey);

        // addDappWhitelist(44);
        addSingle(48,4);

        vm.stopBroadcast();

    }

    
    function addDappWhitelist(uint256 dappID) public {
        require(block.chainid == 421614, "Should be chainId for ARBITRUM SEPOLIA");

        uint256 len = newchains.length;

        for(uint256 i=0; i<len; i++) {
            console.log("Processing blockchain = ");
            console.log(newchains[i].chainId);

            if(dappID == 44) {  // FeeManager
                wList.push(newchains[i].feeManager.toHexString());
            } else if(dappID == 45) {  // CTMRWA001X
                wList.push(newchains[i].rwaX.toHexString());
            } else if(dappID == 46) {  // CTMRWADeployer
                wList.push(newchains[i].deployer.toHexString());
            } else if(dappID == 47) {  // CTMRWAGateway
                wList.push(newchains[i].gateway.toHexString());
            } else if(dappID == 48) {  // CTMRWA001Storage
                wList.push(newchains[i].storageManager.toHexString());
            }
        }
        IDapp(dappContract).addDappAddr(dappID, wList);
        
        return;
    }

    function addSingle(uint256 dappID, uint256 indx) public {

        if(dappID == 44) {  // FeeManager
                wList.push(newchains[indx].feeManager.toHexString());
        } else if(dappID == 45) {  // CTMRWA001X
            wList.push(newchains[indx].rwaX.toHexString());
        } else if(dappID == 46) {  // CTMRWADeployer
            wList.push(newchains[indx].deployer.toHexString());
        } else if(dappID == 47) {  // CTMRWAGateway
            wList.push(newchains[indx].gateway.toHexString());
        } else if(dappID == 48) {  // CTMRWA001Storage
            wList.push(newchains[indx].storageManager.toHexString());
        }

        IDapp(dappContract).addDappAddr(dappID, wList);
        
        return;
    }

}    