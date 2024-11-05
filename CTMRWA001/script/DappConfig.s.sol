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


    constructor() {
        newchains.push(NewChain(    // ARB Sepolia
            421614, 
            0x358498985E6ac7CA73F5110b415525aE04CB8313,
            0x9DC772b55e95A630031EBe431706D105af01Cf03,
            0x9068F274555af3cD0A934Dbcf1c56E7b83Ad450A,
            0xc047401F28F43eC8Af8C5aAaC26Bf7d007E2474a,
            0x0EeA0C2FB4122e8193E26B06358E384b2b909848
        ));
        newchains.push(NewChain(   // POLYGON AMOY  Chain 80002
            80002,
            0x2927d422CBEA7F315ee3E0660aF2eD9b35302004,
            0x1B87108B35Abb5751Bfc64647E9D5cD1Cb77E236,
            0x0897e91383Ab942bC502549eD75AA8ea7538B5Fe,
            0x3418a45e442210EC9579B074Ae9ACb13b2A67554,
            0x0D8723a971ab42D0c52bf241ddb313B20F84E837
        ));
        newchains.push(NewChain(  // BASE SEPOLIA  Chain 84532
            84532,
            0x6640eC42F86ABCF799C21A070f7bAF6Db38a2AB9,
            0x8230abAb39F9C618282dDd0AF1DFA278DE7Df98f,
            0xeCd4b2ab820215AcC3Cd579B8e65530D44A83643,
            0xAF685f104E7428311F25526180cbd416Fa8668CD,
            0x05a804374Bb77345854022Fd0CD2A602E00bF2E7
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
            0x969035b34B913c507b87FD805Fff608FB1fE13f0,
            0x66b719C489193594c617801e67119959CD15b63A,
            0x41543A4C6423E2546FC58AC63117B5692D68c323,
            0xE569c146B0d4c1c941607b5c6A648b5877AE29EF,
            0x766061Cd28592Fd2503cAA3E4772C1215192cD3d
        ));
        newchains.push(NewChain(  //  SEPOLIA  Chain 11155111
            11155111,
            0x9266e8bf4943f2b366F2be89688a8622084DB8B9,
            0xB5638019CBfC1B523d5167a269E755b05BF24fD9,
            0xd1F0743C665d80D6BDaf1b4B8C9E82bfd1aE1994,
            0xa240B0714712e2927Ec055CEAa8e031AC671a55F,
            0x5a7Be43D528D75Ed78aAA16A9e3BF6A20a23B8A3
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