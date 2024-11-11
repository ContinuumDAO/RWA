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
            0x82C7Cf3AD2A7C6EA732C131e552AD171d190421E,
            0x6F2F79720C81631d3a0FE8e19c96F3ceBd56519a,
            0x1211a2Dd0d01848DC4042A7A354Cb8a4C51dF594,
            0x6DD5666Ef6b2E83D504C1EE586fB3C630aBc7fD2,
            0x3800dAcd202a91A791BC040dfD352a9565E51Aa7
        ));
        newchains.push(NewChain(   // POLYGON AMOY  Chain 80002
            80002,
            0xB75A2833405907508bD5f8DEa3A24FA537D9C85c,
            0x74Da08aBCb64A66370E9C1609771e68aAfEDE27B,
            0xF663c3De2d18920ffd7392242459275d0Dd249e4,
            0x44bd5B80fEd6d6574d21f9b748d0b9A1D5566312,
            0x63135C26Ad4a67D9D5dCfbCCDc94F11de83eB2Ca
        ));
        newchains.push(NewChain(  // BASE SEPOLIA  Chain 84532
            84532,
            0x8b8De69a9cBCa6B7cb85406DdE46116DD520d5B0,
            0x24DA0F2114B682D01234bC9E103ff7eEbF86aE6A,
            0xCBf4E5FDA887e602E5132FA800d74154DFb5B237,
            0x4fB3A28c53C88731D783610d0fF275B02bbF19E0,
            0x60676AB7BA46D702b171B67381648477AE16B5b8
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
            0x291E038Ef58dcFDF020e0BBEA0C9a36713dB7966,
            0x4328Bf65bC8C69067a03D0fbDe94ca1e24ED966c,
            0xBCe6B1Ab3790BCe90E2299cc9C46f6D2bCB56324,
            0x6187ee058bB5b7Db140cfd470a27EBe1f16D92B1,
            0x038a39974a702ada213a318c855792244884EDCC
        ));
        newchains.push(NewChain(  //  SEPOLIA  Chain 11155111
            11155111,
            0xF1a79c24efF78FfFfbd4f8Df0Ce31aDEc284b9Cf,
            0x2BE0C4Ac75784737D4D0E75C4026d4Bc671B938E,
            0xa9888fD40bc181958BD2C2b2D06DD1559D0c8E55,
            0x8E36C2b1aC03d98faC0074C9E8e27023a3ce2206,
            0x2927d422CBEA7F315ee3E0660aF2eD9b35302004
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