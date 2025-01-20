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
            0x20A9F9D7282c6FDE913522A42c3951F5B18f62D5,
            0xD5870cb8400E75F2097F3AF9fD37aF0C758707e0,
            0xc4eDB1cBb639143A6fAa63b7cAF194ce53D88D29,
            0x769139881024cE730dE9de9c21E3ad6fb5a872f2,
            0xF0C7A83F1BB9cA54e7C60B4CDBC8c469Ce776A6d
        ));
        newchains.push(NewChain(   // POLYGON AMOY  Chain 80002
            80002,
            0x114ace1c918409889464c2a714f8442a97934Ccf,
            0x88a23d9ec1a9f1100d807D0E8c7a39927D4A7897,
            0x4cDa22b59a1fE957D09273E533cCb7D44bdEf90C,
            0x95ae66aD780E73eF2D2a80611458883C950a1356,
            0x9aF1e5b3e863d88A4E220fb07FfB8c2e5a96dDbd
        ));
        newchains.push(NewChain(  // BASE SEPOLIA  Chain 84532
            84532,
            0xF3A991cB19949cB6aBD9E416F0408C648B6c36Fa,
            0xb5d1f61f6B9f0CA2B89eb9D693e8cD737076846A,
            0x5b4d2c1b2e918fF1b0DE85803F5A737E5f816eCb,
            0xf9229aCEba228fdbb757A637EeeBadB46FDb617e,
            0x6f013Ad0b507590dcB26E674199ba99d613e9dFD
        ));
        newchains.push(NewChain(  // LINEA SEPOLIA Chain 59141
            59141,
            0x9266e8bf4943f2b366F2be89688a8622084DB8B9,
            0xB5638019CBfC1B523d5167a269E755b05BF24fD9,
            0xd1F0743C665d80D6BDaf1b4B8C9E82bfd1aE1994,
            0xa240B0714712e2927Ec055CEAa8e031AC671a55F,
            0x5a7Be43D528D75Ed78aAA16A9e3BF6A20a23B8A3
        ));
        // newchains.push(NewChain(  // CONFLUX ESPACE  Chain 71
        //     71,
            
        // ));
        newchains.push(NewChain(  // CORE Testnet Chain 1115
            1115,
            0xF4e7a775c8aBC8e0B7ed11d660b0a6b2e1B7a132,
            0x73943Ec95AaFBb4DD073b11F5c9701E5Bc3708A6,
            0x67510816512511818B5047a4Cce6E8f2ebB15d20,
            0x4b17E8eE1cC1814636DDe9Ac12a42472799CCB64,
            0x64C5734e22cf8126c6367c0230B66788fBE4AB90
        ));
        newchains.push(NewChain(  // HOLESKY Chain 17000
            17000,
            0xF4e7a775c8aBC8e0B7ed11d660b0a6b2e1B7a132,
            0x73943Ec95AaFBb4DD073b11F5c9701E5Bc3708A6,
            0x67510816512511818B5047a4Cce6E8f2ebB15d20,
            0x4b17E8eE1cC1814636DDe9Ac12a42472799CCB64,
            0x64C5734e22cf8126c6367c0230B66788fBE4AB90
        ));
        newchains.push(NewChain(  // MORPH HOLESKY  Chain 2810
            2810,
            0x9266e8bf4943f2b366F2be89688a8622084DB8B9,
            0xB5638019CBfC1B523d5167a269E755b05BF24fD9,
            0xd1F0743C665d80D6BDaf1b4B8C9E82bfd1aE1994,
            0xa240B0714712e2927Ec055CEAa8e031AC671a55F,
            0x5a7Be43D528D75Ed78aAA16A9e3BF6A20a23B8A3
        ));
        newchains.push(NewChain(  // BLAST SEPOLIA Chain 168587773
            168587773,
            0x9266e8bf4943f2b366F2be89688a8622084DB8B9,
            0xB5638019CBfC1B523d5167a269E755b05BF24fD9,
            0xd1F0743C665d80D6BDaf1b4B8C9E82bfd1aE1994,
            0xa240B0714712e2927Ec055CEAa8e031AC671a55F,
            0x5a7Be43D528D75Ed78aAA16A9e3BF6A20a23B8A3
        ));
        newchains.push(NewChain(  // BITLAYER TESTNET Chain 200810
            200810,
            0x64C5734e22cf8126c6367c0230B66788fBE4AB90,
            0xa4482dF3A723654A599Ba66d1b5091fD9C42ad05,
            0xEb28C8e7Cc2d8a8d361Cb41EC0937ac11c0c0A1F,
            0x048A5cefCDF0faeB734bc4A941E0de44d8c49f55,
            0xc3dC6a3EdC40460BAa684F45E9e377B7e42009b1
        ));
        newchains.push(NewChain(  // SCROLL SEPOLIA   Chain 534351
            534351,
            0x9266e8bf4943f2b366F2be89688a8622084DB8B9,
            0xB5638019CBfC1B523d5167a269E755b05BF24fD9,
            0xd1F0743C665d80D6BDaf1b4B8C9E82bfd1aE1994,
            0xa240B0714712e2927Ec055CEAa8e031AC671a55F,
            0x5a7Be43D528D75Ed78aAA16A9e3BF6A20a23B8A3
        ));
        newchains.push(NewChain(  // MANTLE SEPOLIA Chain 5003
            5003,
            0x9266e8bf4943f2b366F2be89688a8622084DB8B9,
            0xB5638019CBfC1B523d5167a269E755b05BF24fD9,
            0xd1F0743C665d80D6BDaf1b4B8C9E82bfd1aE1994,
            0xa240B0714712e2927Ec055CEAa8e031AC671a55F,
            0x5a7Be43D528D75Ed78aAA16A9e3BF6A20a23B8A3
        ));
        newchains.push(NewChain(  // LUKSO TESTNET  Chain 4201
            4201,
            0x2927d422CBEA7F315ee3E0660aF2eD9b35302004,
            0x1B87108B35Abb5751Bfc64647E9D5cD1Cb77E236,
            0x0897e91383Ab942bC502549eD75AA8ea7538B5Fe,
            0x3418a45e442210EC9579B074Ae9ACb13b2A67554,
            0x0D8723a971ab42D0c52bf241ddb313B20F84E837
        ));
        newchains.push(NewChain(  // BERA_BARTIO Chain 80084
            80084,
            0xa42864Da3ee7B05489eF1d99704089b734cb73a2,
            0x67510816512511818B5047a4Cce6E8f2ebB15d20,
            0x779f7FfdD1157935E1cD6344A6D7a9047736EBc1,
            0xa7C57315395def05F906310d590f4ea15308fe30,
            0xAc71dCF325724594525cc05552beE7D6550a80fD
        ));
        newchains.push(NewChain(  // LUMIA TESTNET Chain 1952959480
            1952959480,
            0xd1F0743C665d80D6BDaf1b4B8C9E82bfd1aE1994,
            0x9266e8bf4943f2b366F2be89688a8622084DB8B9,
            0x4f5b13A48d4fC78e154DDa6c49E39c6d59277213,
            0xde3Fdb278B0EC3254E8701c38e58CFd1168f13a5,
            0xA7EC64D41f32FfE662A46B62E59D1EBFEaD52522
        ));
        // newchains.push(NewChain(  // PLUME TESTNET Chain 161221135
        //     161221135,
            
        // ));
        newchains.push(NewChain(  // VANGUARD Chain 78600
            78600,
            0xeaDb6779c7284a7ef6f611f4535e60c3d59B321b,
            0x232c61b3d1A03cC57e976cCcD0F9C9Cd33a98fe0,
            0xa6e0Fa5cCEEf6e87d89B4DC51053E1Ff1A557B53,
            0xC33b3317912d173806D782BFadE797f262d9A4Bd,
            0x2CD9F1d9000D8752cC7653e10f259f7D9a94A5E7
        ));
        newchains.push(NewChain(  // RARI TESTNET Chain 1918988905
            1918988905,
            0x22c254662850f21bfb09714F6A5638D929439F8D,
            0x3Abb2780b0BbF630490D155C4861F4E82c623246,
            0x0D8723a971ab42D0c52bf241ddb313B20F84E837,
            0x56249F01CF2B50A7F211Bb9de08B1480835F574a,
            0x08A424008BAbad51161Ed85761C1421C26116DFe
        ));
        newchains.push(NewChain(  // U2U NEBULAS TESTNET Chain 2484
            2484,
            0x9266e8bf4943f2b366F2be89688a8622084DB8B9,
            0xB5638019CBfC1B523d5167a269E755b05BF24fD9,
            0xd1F0743C665d80D6BDaf1b4B8C9E82bfd1aE1994,
            0xa240B0714712e2927Ec055CEAa8e031AC671a55F,
            0x5a7Be43D528D75Ed78aAA16A9e3BF6A20a23B8A3
        ));
        newchains.push(NewChain(  // SONEIUM MINATO Chain 1946
            1946,
            0x9266e8bf4943f2b366F2be89688a8622084DB8B9,
            0xB5638019CBfC1B523d5167a269E755b05BF24fD9,
            0xd1F0743C665d80D6BDaf1b4B8C9E82bfd1aE1994,
            0xa240B0714712e2927Ec055CEAa8e031AC671a55F,
            0x5a7Be43D528D75Ed78aAA16A9e3BF6A20a23B8A3
        ));
        newchains.push(NewChain(  // OPBNB TESTNET  Chain 5611
            5611,
            0x9266e8bf4943f2b366F2be89688a8622084DB8B9,
            0xB5638019CBfC1B523d5167a269E755b05BF24fD9,
            0xd1F0743C665d80D6BDaf1b4B8C9E82bfd1aE1994,
            0xa240B0714712e2927Ec055CEAa8e031AC671a55F,
            0x5a7Be43D528D75Ed78aAA16A9e3BF6A20a23B8A3
        ));
        newchains.push(NewChain(  // SONIC TESTNET  Chain 64165
            64165,
            0xF4e7a775c8aBC8e0B7ed11d660b0a6b2e1B7a132,
            0x73943Ec95AaFBb4DD073b11F5c9701E5Bc3708A6,
            0x67510816512511818B5047a4Cce6E8f2ebB15d20,
            0x4b17E8eE1cC1814636DDe9Ac12a42472799CCB64,
            0x64C5734e22cf8126c6367c0230B66788fBE4AB90
        ));
        newchains.push(NewChain(  // FIRE THUNDER  Chain 997
            997,
            0xF4e7a775c8aBC8e0B7ed11d660b0a6b2e1B7a132,
            0x73943Ec95AaFBb4DD073b11F5c9701E5Bc3708A6,
            0x67510816512511818B5047a4Cce6E8f2ebB15d20,
            0x4b17E8eE1cC1814636DDe9Ac12a42472799CCB64,
            0x64C5734e22cf8126c6367c0230B66788fBE4AB90
        ));
        newchains.push(NewChain(  // HUMANODE TESTNET ISRAFEL  Chain 14853
            14853,
            0x9266e8bf4943f2b366F2be89688a8622084DB8B9,
            0xB5638019CBfC1B523d5167a269E755b05BF24fD9,
            0xd1F0743C665d80D6BDaf1b4B8C9E82bfd1aE1994,
            0xa240B0714712e2927Ec055CEAa8e031AC671a55F,
            0x5a7Be43D528D75Ed78aAA16A9e3BF6A20a23B8A3
        ));
        newchains.push(NewChain(   // CRONOS TESTNET   Chain 338
            338,
            0xAE66C08b9d76EeCaA74314c60f3305D43707ACc9,
            0x176cD7aBF4919068d7FeC79935c303b32B7DabE7,
            0x1f8548Eb8Ec40294D7eD5e85DbF0F3BCE228C3Bc,
            0xb8B99101c1DBFaD6Aa418220592773be082Db804,
            0x37415B746B2eF7f37608006dDaA404d377fdF633
        ));
        newchains.push(NewChain(  //  BSC TESTNET Chain 97
            97,
            0xBA08c3b81ed1A13e7A3457b6ab5DDdBa2DF34df4,
            0x21ea338975678968Da85deA76f298E7f11A09334,
            0x8b97E011A2F64F705C0A65706fB7bb968CB13d52,
            0x60A5B05DB6c8EB0b47F8227ea3b04Bd751B79DbC,
            0x618A42E871Ea7A9ee5F8477a1631dA8c433Eb9Bc
        ));
        newchains.push(NewChain(  //  SEPOLIA  Chain 11155111
            11155111,
            0x10A04ad4a73C8bb00Ee5A29B27d11eeE85390306,
            0x3AF6a526DD51C8B08FD54dBB624E042BB3b0a77e,
            0x926DF1f820Af8E3cF53A58C94332eB16BA4cB4b5,
            0x93DEF24108852Be52b2c34084d584338E46ab8f4,
            0x70aF28A024463D3EFB5772adb8869470015bf076
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