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
            0x15E8BBa5f3F0118C357E74D86a65f46977D58053,
            0xb866653913aE6aCb12e9aa33D6d45651cDFEB78B,
            0x8e1fc60c90Aff208023735c9eE54Ff6315D13182,
            0x3804bD72656E086166f2d64E7C78f2F9CD2735b8,
            0x9cEB3f7ddcEe31eB8aC66D51838999709B1d4e4F,
            0x3637d9Bc1A0e819c9d637aFb582c7B3011fCD9Ba
        ));
        newchains.push(NewChain(   // POLYGON AMOY  Chain 80002
            80002,
            0x6f013Ad0b507590dcB26E674199ba99d613e9dFD,
            0x68CE4a4a6F6EbF5Ba25791Ea5385080e57A5BE82,
            0x5Cc4E3125B75284246Ffd677eC53553f1d78b825,
            0xE5b921BD326efa802e3dc20Fb3502559f59fd8AA,
            0xe5f1354ad39be96a3d2566b27dBc12Dd1Af1b9dB,
            0x971C8BDd123aA0c864480419f378fB135f7CaBC1
        ));
        newchains.push(NewChain(  // BASE SEPOLIA  Chain 84532
            84532,
            0x808490311dEbe8818cdfFe1FAae436cb84fAa906,
            0xB3672d1bBd1bADbbBf6b327C2ad7785534aF2E7F,
            0xD3ee2E923723D2e634219797512bD768d5973020,
            0x1481875CA0EcD0ACdEb79d3d57FB76EAE726d128,
            0x3bFF2A879a92e2125cDe895FA20BA3A4AEb2D4D7,
            0xfFFDFD7bBd2D957dd12EA30Ce24852dc26F8b453
        
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
            0xf3F62dAF8f096e5e1e8626cF2F35d816d454bC93,
            0x4f91E4166D76b9BD900b6cCD44C5E6A370ECcD6f,
            0x1ef34A3344CEAbA7A772EFD8B2d55EB52D15215a,
            0x730e8b2D89bA0D3403bb3d8C9929A9f0da61E051,
            0x63c159E655481C4bde8D2340448b57089E10D967,
            0xA05eE9f49a37c117051c808a8d802aeC90916731
        ));
        newchains.push(NewChain(  // HOLESKY Chain 17000
            17000,
            0xeFbd6990A5C4ABFA30b91409aA3d9A0e7C8Bb77b,
            0x43B8494f3C645c8CBA2B0D13C7Bd948D9877620c,
            0xd13779b354c3C72c9B438ABe7Db3086098778A7a,
            0xe5AF1a54B2b8cA3091edD229329B60A82b7A04E8,
            0xDbBbbbd746F539d8C82aea9d4F776e5BA0F4e1a1,
            0x41543A4C6423E2546FC58AC63117B5692D68c323
        ));
        newchains.push(NewChain(  // MORPH HOLESKY  Chain 2810
            2810,
            0x25903bEA74d4fbE43B7D30703D2A740841DfB7b2,
            0x45cddE4bdAbC97b3ec02B1271432ceeBc04d4c53,
            0x9E2F5D1228b02C2FbF3168Db1162e7461574eBB9,
            0x6F0DDf81d8145301058e37CC51A485Ae6b44BCF9,
            0xDFe447a7F6780dD40D3eA4CF3F132c1F3b50BfF7,
            0x3FfbC9f4C2Bb8fB74Ab712d3E01c695Ce2329b1D
        ));
        newchains.push(NewChain(  // BLAST SEPOLIA Chain 168587773
            168587773,
            0x4218C42503FBB0CC65cbDf507B7ce64F0C52BC32,
            0xC230C289328a86d2daC10Db25E91f516aD7D0D3f,
            0x610D47b471Ca1BA509F752AFAD8E391664bF4deC,
            0x3dc0e90bB56DE095321c48aadF0D0c29b47b837a,
            0x3FfbC9f4C2Bb8fB74Ab712d3E01c695Ce2329b1D,
            0x25903bEA74d4fbE43B7D30703D2A740841DfB7b2
        ));
        newchains.push(NewChain(  // BITLAYER TESTNET Chain 200810
            200810,
            0x5Fb1394608Ce2Ef7092A642d6c5D3b2325300bFD,
            0xe5AF1a54B2b8cA3091edD229329B60A82b7A04E8,
            0x66b719C489193594c617801e67119959CD15b63A,
            0xC5E7f5e1BABBF45e3F1e0764B48736C19A122383,
            0x0A576aB9704438ef4eF94C50c6bD0F13eFE12b06,
            0xa78f13ddB2538e76ed0EB66F3B0c36d77c237Ab8
        ));
        newchains.push(NewChain(  // SCROLL SEPOLIA   Chain 534351
            534351,
            0xD55F76833388137FB1ECFc0dE1e6982716A19640,
            0x9E2F5D1228b02C2FbF3168Db1162e7461574eBB9,
            0x7ED4D0234E6c0F6704463E9A62A33AB7B7846A09,
            0x0A0C882706544F37377e9bb7976E0805cd29a94F,
            0x6F0DDf81d8145301058e37CC51A485Ae6b44BCF9,
            0x3dc0e90bB56DE095321c48aadF0D0c29b47b837a
        ));
        newchains.push(NewChain(  // MANTLE SEPOLIA Chain 5003
            5003,
            0x25903bEA74d4fbE43B7D30703D2A740841DfB7b2,
            0x45cddE4bdAbC97b3ec02B1271432ceeBc04d4c53,
            0x9E2F5D1228b02C2FbF3168Db1162e7461574eBB9,
            0x6F0DDf81d8145301058e37CC51A485Ae6b44BCF9,
            0xDFe447a7F6780dD40D3eA4CF3F132c1F3b50BfF7,
            0x3FfbC9f4C2Bb8fB74Ab712d3E01c695Ce2329b1D
        ));
        newchains.push(NewChain(  // LUKSO TESTNET  Chain 4201
            4201,
            0xDbBbbbd746F539d8C82aea9d4F776e5BA0F4e1a1,
            0x766061Cd28592Fd2503cAA3E4772C1215192cD3d,
            0xe96270a4DeFb602d8C7E5aDB7f090EAC5291A641,
            0xFA633c1aB4Ed7d8aa032f50219c6065189D13bd0,
            0xd6374b3842652fc5Fc963c069ce05f1A48f965ce,
            0x208a83079E25e17fe5dC64BbB77e388FEe725A99
        ));
        newchains.push(NewChain(  // LUMIA TESTNET Chain 1952959480
            1952959480,
            0x1b34e36f4A7B083b153803946C68F8567b4Fe021,
            0x0EeA0C2FB4122e8193E26B06358E384b2b909848,
            0x68A5Ec275ade39a59B058ABA931E6D41bc39F833,
            0x672472B8E2FdFEFA99653d562Afe042500f8CF58,
            0x020119205333c7cae5a5aac190092558C1C61281,
            0x890205BF3Ad9737AFaF27cc8bb51291E6A135f48
        ));
        // newchains.push(NewChain(  // PLUME TESTNET Chain 161221135
        //     161221135,
            
        // ));
        newchains.push(NewChain(  // VANGUARD Chain 78600
            78600,
            0xD523b4f68c015B472724c24e127FF1f51EeE0fbf,
            0x4dDcab55e1eae426a98e85f43896592Ad1dB0f84,
            0x8d494f8B762005cCA5BDEBb770Af3bf51E730305,
            0x89c8CC177f04CC8209B93e42d81a780c3A685dD4,
            0xDD15811D29A330AD2850A994f6AAEcFfA68A5c12,
            0x24DA0F2114B682D01234bC9E103ff7eEbF86aE6A
        ));
        newchains.push(NewChain(  // U2U NEBULAS TESTNET Chain 2484
            2484,
            0x3CB56e6E5917a2a8924BC2A5C1f0ecc90b585e74,
            0x1F652e2D8A9FCa346A0F45D59a67FB998999e454,
            0xa3bae05aA45bcC739258b124FACE332043D3B1dA,
            0xA33cfD901896C775c5a6d62e94081b4Fdd1B09BC,
            0x41543A4C6423E2546FC58AC63117B5692D68c323,
            0xeFbd6990A5C4ABFA30b91409aA3d9A0e7C8Bb77b
        ));
        newchains.push(NewChain(  // SONEIUM MINATO Chain 1946
            1946,
            0x654Ad7D43857b354079caD2d668bFA1eF2a01Fcf,
            0x610D47b471Ca1BA509F752AFAD8E391664bF4deC,
            0xf7548cB35188aa7DaC8423fAA2ACe3855634e40C,
            0x80f1BB2DF520e3e091C79AebE81f46136A8fBCb5,
            0x3dc0e90bB56DE095321c48aadF0D0c29b47b837a,
            0xD55F76833388137FB1ECFc0dE1e6982716A19640
        ));
        newchains.push(NewChain(  // OPBNB TESTNET  Chain 5611
            5611,
            0x6F0DDf81d8145301058e37CC51A485Ae6b44BCF9,
            0xCa19ddc73718512B968B2cb838b1408885D74A05,
            0x4596F5bFba6cB5ebdb23a0d118434b43Ad9Be3B7,
            0xd13779b354c3C72c9B438ABe7Db3086098778A7a,
            0x43B8494f3C645c8CBA2B0D13C7Bd948D9877620c,
            0x1F652e2D8A9FCa346A0F45D59a67FB998999e454
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
            0x4146FE54Fd379fd095C227ea012a50387674766D,
            0xC5A13F8750f362AA8e8Ace59f261268295923190,
            0x20D5CdE9700144ED0Da22754D89f3379916c99Fa,
            0x188af80a2ea153bc43dD448434d753C05D3C93f3,
            0x39446dF8f82282Aebcb0EdDc61D6B716C188Ee85,
            0x3e15986e2fCbc9A636Ddf2eA798Ae6C162200144
        ));
        newchains.push(NewChain(  //  SEPOLIA  Chain 11155111
            11155111,
            0xBB348A6f2227E56a210097f808025Ca3635BEE1d,
            0x3D9aD7fb378BCeb18C47e01AF6e60679B6CAa8A9,
            0x06c067f00F946ecaA23C5b253fFf4B91a5869F10,
            0xDC44569f688a91ba3517C292de75E30EA284eeA0,
            0x636D43798340603707c936c1A93597Dc44Effbee,
            0x8ebc3d6994b3cA9052095dBcE3803dBf5ffeD062
        ));
        newchains.push(NewChain(  //  REDBELLY  Chain 153
            153,
            0xAc71dCF325724594525cc05552beE7D6550a80fD,
            0xEb28C8e7Cc2d8a8d361Cb41EC0937ac11c0c0A1F,
            0x8393181277c8a85ec0468B3f1ee61Bbfd78E62b4,
            0xF1a79c24efF78FfFfbd4f8Df0Ce31aDEc284b9Cf,
            0x048A5cefCDF0faeB734bc4A941E0de44d8c49f55,
            0x4b17E8eE1cC1814636DDe9Ac12a42472799CCB64
        ));
         newchains.push(NewChain(  //  OPTIMISM  Chain 11155420
            11155420,
            0xcDEcbA8e8a537823733238225df54Cc212d681Cd,
            0x8393181277c8a85ec0468B3f1ee61Bbfd78E62b4,
            0x73943Ec95AaFBb4DD073b11F5c9701E5Bc3708A6,
            0xc3dC6a3EdC40460BAa684F45E9e377B7e42009b1,
            0xF1a79c24efF78FfFfbd4f8Df0Ce31aDEc284b9Cf,
            0xa7C57315395def05F906310d590f4ea15308fe30
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