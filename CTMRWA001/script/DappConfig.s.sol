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
            0x9b81c6A2A62EEA2A814AFDBB5D69CE0592E1C751,
            0xe0f1cd117107457Bc14c2f1b82E218157c2a620c,
            0x3Dd9BB1ff0e52390c1BC16f1aB77608a2C7631c4,
            0x78e9F16b42508a9BC0892bFF922c09067de08Fc5,
            0x24b34AB7851871E761cd502dbCAD5a461eE5d4D8
        ));
        newchains.push(NewChain(   // POLYGON AMOY  Chain 80002
            80002,
            0x1249d751e6a0b7b11b9e55CBF8bC7d397AC3c083,
            0x797AA64f83e4d17c2C6C80321f22445AAB153630,
            0x1944F7fdd330Af7b0e7C08349591213E35ed5948,
            0xb406b937C12E03d676727Fc1Bb686279EeDbc178,
            0xDfCF0181d2c2608D6e055997D2C215811AcC2D49
        ));
        newchains.push(NewChain(  // BASE SEPOLIA  Chain 84532
            84532,
            0x2d1967eF42ECf9a42785D08398aADba806Aa090B,
            0xA09E913fa1aA5383a90aD6d8B94BC3DaBeE90332,
            0x9BFaB09e477e0e931F292C8132F2579883C6921A,
            0xa840A5eC6557DF201a6a1561DbDc8AD6f3B3fAF4,
            0x88802732af13061009363B12256A446DaEd6Fb81
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
            0x1392fC45312550197adF2039de80e8DA58fc72A3,
            0xC5070659D0290f2Eb2B1eD886f3F7574fde5C4Be,
            0xf204b97DBbba1bed029Bd13bef456d1A17dA9Bf9,
            0x8159be9135ecC4893826E40cf19047a79c523008,
            0x89251083bEFB84486cE91407f40634c0E547Cc0e
        ));
        newchains.push(NewChain(  //  SEPOLIA  Chain 11155111
            11155111,
            0xb07C3788549cd48aD1d4Cb9B7336f7C9Dd53D67F,
            0x69D461E1314af5E3bcab39f0ebA3872c5de2c1e5,
            0xEa911684c200aC1FD3Ca8A3FFD21aFE9EF0e35Da,
            0x8Ee0AeE8A42f55Ed43F5e7DB765FA591C4714C41,
            0x7635A9b23275892aC46479B7eAd9831A80171AcE
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