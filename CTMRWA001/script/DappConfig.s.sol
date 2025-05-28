// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.19;

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
    address sentryManager;
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
    //     address sentryManager;
    //     address deployer;
    // }

    constructor() {
        newchains.push(NewChain(    // ARB Sepolia
            421614,
            ,
            ,
            ,
            ,
            ,
            
        ));
        newchains.push(NewChain(   // POLYGON AMOY  Chain 80002
            80002,
            ,
            ,
            ,
            ,
            ,
            
        ));
        newchains.push(NewChain(  // BASE SEPOLIA  Chain 84532
            84532,
            ,
            ,
            ,
            ,
            ,
            
        
        ));
        // newchains.push(NewChain(  // LINEA SEPOLIA Chain 59141
        //     59141,
        //     ,
        //     ,
        //     ,
        //     ,
        //     ,
        //     
        // ));
        // newchains.push(NewChain(  // CONFLUX ESPACE  Chain 71
        //     71,
            
        // ));
        newchains.push(NewChain(  // CORE Testnet Chain 1115
            1115,
            ,
            ,
            ,
            ,
            ,
            
        ));
        newchains.push(NewChain(  // HOLESKY Chain 17000
            17000,
            ,
            ,
            ,
            ,
            ,
            
        ));
        newchains.push(NewChain(  // MORPH HOLESKY  Chain 2810
            2810,
            ,
            ,
            ,
            ,
            ,
            
        ));
        newchains.push(NewChain(  // BLAST SEPOLIA Chain 168587773
            168587773,
            ,
            ,
            ,
            ,
            ,
            
        ));
        newchains.push(NewChain(  // BITLAYER TESTNET Chain 200810
            200810,
            ,
            ,
            ,
            ,
            ,
            
        ));
        newchains.push(NewChain(  // SCROLL SEPOLIA   Chain 534351
            534351,
            ,
            ,
            ,
            ,
            ,
            
        ));
        newchains.push(NewChain(  // MANTLE SEPOLIA Chain 5003
            5003,
            ,
            ,
            ,
            ,
            ,
            
        ));
        newchains.push(NewChain(  // LUKSO TESTNET  Chain 4201
            4201,
            ,
            ,
            ,
            ,
            ,
            
        ));
        newchains.push(NewChain(  // LUMIA TESTNET Chain 1952959480
            1952959480,
            ,
            ,
            ,
            ,
            ,
            
        ));
        // newchains.push(NewChain(  // PLUME TESTNET Chain 161221135
        //     161221135,
            
        // ));
        newchains.push(NewChain(  // VANGUARD Chain 78600
            78600,
            ,
            ,
            ,
            ,
            ,
            
        ));
        newchains.push(NewChain(  // U2U NEBULAS TESTNET Chain 2484
            2484,
            ,
            ,
            ,
            ,
            ,
            
        ));
        newchains.push(NewChain(  // SONEIUM MINATO Chain 1946
            1946,
            ,
            ,
            ,
            ,
            ,
            
        ));
        newchains.push(NewChain(  // OPBNB TESTNET  Chain 5611
            5611,
            ,
            ,
            ,
            ,
            ,
            
        ));
        // newchains.push(NewChain(  // SONIC TESTNET  Chain 64165
        //     64165,
        //     ,
        //     ,
        //     ,
        //     ,
        //     ,
            
        // ));
        // newchains.push(NewChain(  // FIRE THUNDER  Chain 997
        //     997,
        //     ,
        //     ,
        //     ,
        //     ,
        //     ,
            
        // ));
        // newchains.push(NewChain(  // HUMANODE TESTNET ISRAFEL  Chain 14853
        //     14853,
        //     ,
        //     ,
        //     ,
        //     ,
        //     ,
            
        // ));
        // newchains.push(NewChain(   // CRONOS TESTNET   Chain 338
        //     338,
        //     ,
        //     ,
        //     ,
        //     ,
        //     ,
            
        // ));
        newchains.push(NewChain(  //  BSC TESTNET Chain 97
            97,
            ,
            ,
            ,
            ,
            ,
            
        ));
        newchains.push(NewChain(  //  SEPOLIA  Chain 11155111
            11155111,
            ,
            ,
            ,
            ,
            ,
            
        ));
        newchains.push(NewChain(  //  REDBELLY  Chain 153
            153,
            ,
            ,
            ,
            ,
            ,
            
        ));
         newchains.push(NewChain(  //  OPTIMISM  Chain 11155420
            11155420,
            ,
            ,
            ,
            ,
            ,
            
        ));
    }


    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        console.log("Wallet of deployer");
        console.log(deployer);

        vm.startBroadcast(deployerPrivateKey);

        // addDappWhitelist(65);
        address toAdd = 0xF53fb9bb64AB9d3D78F976735762c5af9B5fF341;
        addOneAddress(65,toAdd);
        // addSingle(58,19);

        vm.stopBroadcast();

    }

    
    function addDappWhitelist(uint256 dappID) public {
        require(block.chainid == 421614, "Should be chainId for ARBITRUM SEPOLIA");

        address thisAddress;

        uint256 len = newchains.length;

        for(uint256 i=0; i<len; i++) {
            console.log("Processing blockchain = ");
            console.log(newchains[i].chainId);

            if(dappID == 61) {  // FeeManager
                thisAddress = newchains[i].feeManager;
                wList = _stringToArray(newchains[i].feeManager.toHexString());
            } else if(dappID == 62) {  // CTMRWA001X
                thisAddress = newchains[i].rwaX;
                wList = _stringToArray(newchains[i].rwaX.toHexString());
            } else if(dappID == 63) {  // CTMRWADeployer
                thisAddress = newchains[i].deployer;
                wList = _stringToArray(newchains[i].deployer.toHexString());
            } else if(dappID == 60) {  // CTMRWAGateway
                thisAddress = newchains[i].gateway;
                wList = _stringToArray(newchains[i].gateway.toHexString());
            } else if(dappID == 64) {  // CTMRWA001Storage
                thisAddress = newchains[i].storageManager;
                wList = _stringToArray(newchains[i].storageManager.toHexString());
            } else if(dappID == 65) {  // CTMRWA001Sentry
                thisAddress = newchains[i].sentryManager;
                wList = _stringToArray(newchains[i].sentryManager.toHexString());
            }

            if (
                1 == 1
                // DappID 60
                // thisAddress != 0xeFbd6990A5C4ABFA30b91409aA3d9A0e7C8Bb77b &&
                // thisAddress != 0x25903bEA74d4fbE43B7D30703D2A740841DfB7b2 &&
                // thisAddress != 0x3CB56e6E5917a2a8924BC2A5C1f0ecc90b585e74

                // DappID 61
                // thisAddress != 0x9E2F5D1228b02C2FbF3168Db1162e7461574eBB9 &&
                // thisAddress != 0xf7548cB35188aa7DaC8423fAA2ACe3855634e40C

                // DappID 62
                // thisAddress != 0x45cddE4bdAbC97b3ec02B1271432ceeBc04d4c53 &&
                // thisAddress != 0xC230C289328a86d2daC10Db25E91f516aD7D0D3f &&
                // thisAddress != 0x610D47b471Ca1BA509F752AFAD8E391664bF4deC &&
                // thisAddress != 0xCa19ddc73718512B968B2cb838b1408885D74A05 &&
                // thisAddress != 0x8393181277c8a85ec0468B3f1ee61Bbfd78E62b4

                // DappID 63
                // thisAddress != 0x3FfbC9f4C2Bb8fB74Ab712d3E01c695Ce2329b1D &&
                // thisAddress != 0x25903bEA74d4fbE43B7D30703D2A740841DfB7b2 &&
                // thisAddress != 0xeFbd6990A5C4ABFA30b91409aA3d9A0e7C8Bb77b &&
                // thisAddress != 0xD55F76833388137FB1ECFc0dE1e6982716A19640 &&
                // thisAddress != 0x1F652e2D8A9FCa346A0F45D59a67FB998999e454

                // DappID 64
                // thisAddress != 0xe5AF1a54B2b8cA3091edD229329B60A82b7A04E8 &&
                // thisAddress != 0x6F0DDf81d8145301058e37CC51A485Ae6b44BCF9 &&
                // thisAddress != 0x3dc0e90bB56DE095321c48aadF0D0c29b47b837a &&
                // thisAddress != 0xd13779b354c3C72c9B438ABe7Db3086098778A7a

                // DappID 65
                // thisAddress != 0xDbBbbbd746F539d8C82aea9d4F776e5BA0F4e1a1 &&
                // thisAddress != 0x3FfbC9f4C2Bb8fB74Ab712d3E01c695Ce2329b1D &&
                // thisAddress != 0x6F0DDf81d8145301058e37CC51A485Ae6b44BCF9 &&
                // thisAddress != 0xDFe447a7F6780dD40D3eA4CF3F132c1F3b50BfF7 &&
                // thisAddress != 0x41543A4C6423E2546FC58AC63117B5692D68c323 &&
                // thisAddress != 0x3dc0e90bB56DE095321c48aadF0D0c29b47b837a &&
                // thisAddress != 0x43B8494f3C645c8CBA2B0D13C7Bd948D9877620c &&
                // thisAddress != 0xF1a79c24efF78FfFfbd4f8Df0Ce31aDEc284b9Cf
            ) {
                try IDapp(dappContract).addDappAddr(dappID, wList) {

                } catch {

                }
            }
        }
        
        
        return;
    }

    function addOneAddress(uint256 dappID, address c3Address) public {
        IDapp(dappContract).addDappAddr(dappID, _stringToArray(c3Address.toHexString()));
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
        } else if(dappID == 58) {  // CTMRWA001Sentry
            wList.push(newchains[indx].sentryManager.toHexString());
        }

        IDapp(dappContract).addDappAddr(dappID, wList);
        
        return;
    }

    function _stringToArray(string memory _string) internal pure returns(string[] memory) {
        string[] memory strArray = new string[](1);
        strArray[0] = _string;
        return(strArray);
    }

}    