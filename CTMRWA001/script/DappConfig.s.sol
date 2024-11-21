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
            0xeb4b038c0f1F086BB7Ab5B4192611015aFf95390,
            0xb3aefEa9F49De70C41Ce22Afa321E64393932d21,
            0x0e95227823f64F54D6611Ae6f4fb70a4D76D4378,
            0x37C7137Dc6e3DC3c3637bFEd3F6dBFbd43386429,
            0x1F95f5957BbAa5184ED90768F5B38a87b824B097
        ));
        newchains.push(NewChain(   // POLYGON AMOY  Chain 80002
            80002,
            0xfdD1a5B3AEEa2DF15a6F6B502784B61BdCbF66BC,
            0xD586Ea1FcE09384F71B69e80F643135FC0641def,
            0xA9522e00101Ee85f3B8E6a4F0723F5eA4A2F0A50,
            0xB523F0e72A7BdF94a5a3d84BA9e8Dc42E69229ea,
            0xA31AC55003cde3eF9CE9c576a691d0F41586c20b
        ));
        newchains.push(NewChain(  // BASE SEPOLIA  Chain 84532
            84532,
            0xEa4A06cB68ABa869e6BF98Edc4BdbC731d2D82e3,
            0x9A0F81de582Ce9194FEADC6CCefaf9eA70451616,
            0x66dc636132fb9b7f6ed858928B65864D3fd0ea67,
            0x9372CD1287E0bB6337802D80DFF342348c85fd78,
            0x69556bb0528157e0f6B31D3aCB38E61E16Bcd9f4
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
            0xc0DD542BCaC26095A2C83fFb10826CCEf806C07b,
            0x7658E59CdbA5e7E08263a216e89c8438C9F02048,
            0x605Ab9626e57C5d1f3f0508D5400aB0449b5a015,
            0x855c06F9f7b01838DC540Ec6fcfF17fD86A378D8,
            0x5dA87094aCD03EE1E3722A1E0f80280eeeCaD630
        ));
        newchains.push(NewChain(  //  SEPOLIA  Chain 11155111
            11155111,
            0xF065f9BbD5F59afa0D24BE34bDf8aD483485ED1C,
            0x1eE4bA474da815f728dF08F0147DeFac07F0BAb3,
            0x1e608FD1546e1bC1382Abc4E676CeFB7e314Fb30,
            0xCBf4E5FDA887e602E5132FA800d74154DFb5B237,
            0xD523b4f68c015B472724c24e127FF1f51EeE0fbf
        ));
    }


    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        console.log("Wallet of deployer");
        console.log(deployer);

        vm.startBroadcast(deployerPrivateKey);

        // addDappWhitelist(44);
        addSingle(44,0);

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