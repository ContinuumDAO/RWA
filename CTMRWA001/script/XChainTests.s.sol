// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import "forge-std/console.sol";

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {IC3Caller} from "../contracts/c3Caller/IC3Caller.sol";
import {IUUIDKeeper} from "../contracts/c3Caller/IUUIDKeeper.sol";
import {ITheiaERC20} from "../contracts/routerV2/ITheiaERC20.sol";

import {ICTMRWA001, SlotData} from "../contracts/interfaces/ICTMRWA001.sol";
import {ICTMRWAGateway} from "../contracts/interfaces/ICTMRWAGateway.sol";
import {ICTMRWA001X} from "../contracts/interfaces/ICTMRWA001X.sol";
import {ICTMRWA001StorageManager} from "../contracts/interfaces/ICTMRWA001StorageManager.sol";
import {ICTMRWA001SentryManager} from "../contracts/interfaces/ICTMRWA001SentryManager.sol";
import {ICTMRWA001Sentry} from "../contracts/interfaces/ICTMRWA001Sentry.sol";
import {ICTMRWAMap} from "../contracts/interfaces/ICTMRWAMap.sol";
import {ICTMRWADeployer} from "../contracts/interfaces/ICTMRWADeployer.sol";
import {ICTMRWAMap} from "../contracts/interfaces/ICTMRWAMap.sol";
import {ICTMRWA001Token} from "../contracts/interfaces/ICTMRWA001Token.sol";
import {ICTMRWA001XFallback} from "../contracts/interfaces/ICTMRWA001XFallback.sol";
import {ICTMRWA001Dividend} from "../contracts/interfaces/ICTMRWA001Dividend.sol";
import {URICategory, URIType} from "../contracts/interfaces/ICTMRWA001Storage.sol";
import {URIType, URICategory, URIData, ICTMRWA001Storage} from "../contracts/interfaces/ICTMRWA001Storage.sol";

interface IDKeeper {
    function isUUIDExist(bytes32) external returns(bool);
}

contract XChainTests is Script {
    using Strings for *;

    address admin = 0xe62Ab4D111f968660C6B2188046F9B9bA53C4Bae;
    address gov = admin;
    address feeToken;
    string feeTokenStr;

    uint256 rwaType = 1;
    uint256 version = 1;
    
    
    string[] toChainIdsStr;
    SlotData[] allSlots;

    string[] objNames;
    URICategory[] uricats;
    URIType[] uriTypes;
    string[] uriNames;
    bytes32[] hashes;

    uint256[] slots;
    // string[] slotNames;


    address c3UUIDKeeper = 0x034a2688912A880271544dAE915a9038d9D20229;

    address feeManager;
    address gatewayAddr;
    address rwa001XAddr;
    address ctmFallbackAddr;
    address ctmRwa001Map;
    address ctmRwaDeployer;
    address ctmRwaFactory;
    address dividendAddr;
    address storageManagerAddr;
    address sentryManagerAddr;

    ICTMRWAGateway gateway;
    ICTMRWA001X rwa001X;
    ICTMRWA001StorageManager storageManager;
    ICTMRWA001SentryManager sentryManager;
    ICTMRWA001XFallback ctmFallback;
    ICTMRWA001Dividend dividend;

    uint256 senderPrivateKey = vm.envUint("PRIVATE_KEY");
    address senderAccount = vm.addr(senderPrivateKey);



    function run() external {

        loadContracts(421614);

        uint256 ID = 70754967339914680257804728297836580739943633158567818391146504074652219566760;


        // debugRwaXCall();

        // bytes32 uuid = 0x9521f78e716c509942f2b2b0167b089a447a04f6dc30afee8458e7d54a95637b;
        // checkC3Call(uuid);

        // decodeXChain();

        // checkDeployData();


        // uint256 idBack = deployLocal();

        
        // toChainIdsStr.push("421614");
        // toChainIdsStr.push("84532");
        toChainIdsStr.push("80002");
        deployRemote(ID);
        // createSlots(ID, toChainIdsStr);
        // getSlots(ID,0);

        // mintLocalValue(0);

        
        // string memory newAddrStr = "0xb5981FADCD79992f580ccFdB981d9D850b27DC37";
        // toChainIdsStr.push("421614");
        // activateWhitelist(ID);
        // addToWhitelist(ID, newAddrStr);

        // transferValueTokenToAddress(ID);

        // transferValueWholeTokenToAddress(ID);

        // addURI(ID, toChainIdsStr);

        // toChainIdsStr.push("59141");
        // lockRwa(ID);


    }

    function loadContracts(uint256 chainId) public {
        if(chainId == 421614) {   // On ARB SEPOLIA
            // c3UUIDKeeper = ;
            feeToken = 0xbF5356AdE7e5F775659F301b07c4Bc6961044b11;
            feeManager =  0x8e1fc60c90Aff208023735c9eE54Ff6315D13182;
            gatewayAddr = 0x15E8BBa5f3F0118C357E74D86a65f46977D58053;
            rwa001XAddr = 0xb866653913aE6aCb12e9aa33D6d45651cDFEB78B;
            ctmFallbackAddr = 0xf098767bDe30c0b9C280dbA756f2Ae7E6a653a25;
            ctmRwa001Map = 0x47D91341Ba367BCe483d0Ee2fE02DD1420b883EC;
            ctmRwaDeployer =  0x3637d9Bc1A0e819c9d637aFb582c7B3011fCD9Ba;
            ctmRwaFactory = 0x9ccBe1F97e1B44FA9A7dc5A1aC0979eF013754eF;
            dividendAddr = 0x48Baaa226b610B506C04b1DCcEc2bA75E4C0191c;
            storageManagerAddr = 0x3804bD72656E086166f2d64E7C78f2F9CD2735b8;
            sentryManagerAddr = 0x9cEB3f7ddcEe31eB8aC66D51838999709B1d4e4F;
        } else if(chainId == 80002) {    // on POLYGON AMOY
            feeToken = 0x6a4DBC971533Ba36bdc23aD70F5A7a12E064f4ae;
            feeManager = 0x5Cc4E3125B75284246Ffd677eC53553f1d78b825;
            gatewayAddr = 0x6f013Ad0b507590dcB26E674199ba99d613e9dFD;
            rwa001XAddr = 0x68CE4a4a6F6EbF5Ba25791Ea5385080e57A5BE82;
            ctmFallbackAddr = 0x5c0712E102261ED6B7Dbde118bF351150BDa425f;
            ctmRwa001Map = 0xf9229aCEba228fdbb757A637EeeBadB46FDb617e;
            ctmRwaDeployer = 0x971C8BDd123aA0c864480419f378fB135f7CaBC1;
            ctmRwaFactory = 0x783264825Db3088b5448f85B6dc25BB7EEf666ec;
            dividendAddr = 0xBA08c3b81ed1A13e7A3457b6ab5DDdBa2DF34df4;
            storageManagerAddr = 0xE5b921BD326efa802e3dc20Fb3502559f59fd8AA;
            sentryManagerAddr = 0xe5f1354ad39be96a3d2566b27dBc12Dd1Af1b9dB;
        // } else if(chainId == 338) {    // on CRONOS
        //     feeToken = 0xf6d2060494cD08e776D22a47E67d485a33C8c5d2;
        //     feeManager = ;
        //     gatewayAddr = ;
        //     rwa001XAddr = ;
        //     ctmFallbackAddr = ;
        //     ctmRwa001Map = ;
        //     ctmRwaDeployer = ;
        //     ctmRwaFactory = ;
        //     dividendAddr = ;
        //     storageManagerAddr = ;
         } else if(chainId == 78600) {    // on VANGUARD
            feeToken = 0x6654D956A4487A26dF1186b01B689c26939544fC;
            feeManager = 0x8d494f8B762005cCA5BDEBb770Af3bf51E730305;
            gatewayAddr = 0xD523b4f68c015B472724c24e127FF1f51EeE0fbf;
            rwa001XAddr = 0x4dDcab55e1eae426a98e85f43896592Ad1dB0f84;
            ctmFallbackAddr = 0xdC910F7BCc6f163DFA4804eACa10891eb5B9E867;
            ctmRwa001Map = 0xCBf4E5FDA887e602E5132FA800d74154DFb5B237;
            ctmRwaDeployer = 0x24DA0F2114B682D01234bC9E103ff7eEbF86aE6A;
            ctmRwaFactory = 0x52661DbA4F88FeD997164ff2C453A2339216592C;
            dividendAddr = 0x4f06e8Cea14d352f67E6C21AbC4CBfed38498e6A;
            storageManagerAddr = 0x89c8CC177f04CC8209B93e42d81a780c3A685dD4;
            sentryManagerAddr = 0xDD15811D29A330AD2850A994f6AAEcFfA68A5c12;
        } else if(chainId == 3441006) {    // on MANTA
            feeToken = 0x20cEfCf72622156987f82E1B54E94Dbc0848De9C;
            feeManager = 0x6EE5C158882857c7F52b37FCe37B1CF39944f22E;
            gatewayAddr = 0x005c5Fd1585A73817107bFd3929f7e559750ceEd;
            rwa001XAddr = 0xDef5D31e4b2E0BF38Af3E8092a5ABF51Db484Eec;
            ctmFallbackAddr = 0xb76428eBE853F2f6a5D74C4361B72999f55EE637;
            ctmRwa001Map = 0x92BB6DEfEF73fa2ee42FeC2273d98693571bd7f3;
            ctmRwaDeployer = 0x7dAbce18C66b5c857355A815b6c1e926C701C23F;
            ctmRwaFactory = 0xaD2E580C931861360C998db3F0B090A5391DA58e;
            dividendAddr = 0x77aBD89181775355f39a2dfb74fB233499Fc4500;
            storageManagerAddr = 0xcAcF2003d4bC2e19C865e65Ebb9D57C440217f0F;
            sentryManagerAddr = 0xF53fb9bb64AB9d3D78F976735762c5af9B5fF341;
        } else if(chainId == 5003) {    // on MANTLE
            feeToken = 0x6a4DBC971533Ba36bdc23aD70F5A7a12E064f4ae;
            feeManager = 0x0156a74FD9432446030f47f7c55f4d1FbfdF5E9a;
            gatewayAddr = 0x00d850114aC97754eCf9611Bb0dA99BbFC21BC4C;
            rwa001XAddr = 0x69a68786C9A1088f7121633b5c390F3007EAEBbe;
            ctmFallbackAddr = 0xa328Fd0f353afc134f8f6Bdb51082D85395d7200;
            ctmRwa001Map = 0x41388451eca7344136004D29a813dCEe49577B44;
            ctmRwaDeployer = 0xe148fbc6C35B6cecC50d18Ebf69959a6A989cB7C;
            ctmRwaFactory = 0x208Ec1Ca3B07a50151c5741bc0E05C61beddad90;
            dividendAddr = 0x74972e7Ff5561bD902E3Ec3dDD5A22653088cA6f;
            storageManagerAddr = 0xA365a4Ea68929C6297ef32Da2c21BDBfd1d354f0;
            sentryManagerAddr = 0x6F86E2fEeC756591A65D10158aca89DEc2e5eB51;
        } else if(chainId == 11155111) {    // on SEPOLIA
            feeToken = 0xa4C104db0937F1E886d5C9c9789D6f0e5bfBA75c;
            feeManager = 0x06c067f00F946ecaA23C5b253fFf4B91a5869F10;
            gatewayAddr = 0xBB348A6f2227E56a210097f808025Ca3635BEE1d;
            rwa001XAddr = 0x3D9aD7fb378BCeb18C47e01AF6e60679B6CAa8A9;
            ctmFallbackAddr = 0xF6BeB087A52BC1deF538a16DA652337BDb0E5535;
            ctmRwa001Map = 0x8Ed2Dc74260aA279fcB5438932B5B367F221e7db;
            ctmRwaDeployer = 0x8ebc3d6994b3cA9052095dBcE3803dBf5ffeD062;
            ctmRwaFactory = 0xb0dB162169b0ca1ED329811D79F2CA78a4eeA504;
            dividendAddr = 0x3bc5C06b2e04d7D71a2e4AB3686D5D8011c53f6f;
            storageManagerAddr = 0xDC44569f688a91ba3517C292de75E30EA284eeA0;
            sentryManagerAddr = 0x636D43798340603707c936c1A93597Dc44Effbee;
         } else if(chainId == 2810) {    // on MORPH HOLESKY
            feeToken = 0x6a4DBC971533Ba36bdc23aD70F5A7a12E064f4ae;
            feeManager = 0x9E2F5D1228b02C2FbF3168Db1162e7461574eBB9;
            gatewayAddr = 0x25903bEA74d4fbE43B7D30703D2A740841DfB7b2;
            rwa001XAddr = 0x45cddE4bdAbC97b3ec02B1271432ceeBc04d4c53;
            ctmFallbackAddr = 0x80f1BB2DF520e3e091C79AebE81f46136A8fBCb5;
            ctmRwa001Map = 0x3dc0e90bB56DE095321c48aadF0D0c29b47b837a;
            ctmRwaDeployer = 0x3FfbC9f4C2Bb8fB74Ab712d3E01c695Ce2329b1D;
            ctmRwaFactory = 0x0A0C882706544F37377e9bb7976E0805cd29a94F;
            dividendAddr = 0xa3bae05aA45bcC739258b124FACE332043D3B1dA;
            storageManagerAddr = 0x6F0DDf81d8145301058e37CC51A485Ae6b44BCF9;
            sentryManagerAddr = 0xDFe447a7F6780dD40D3eA4CF3F132c1F3b50BfF7;
        } else if(chainId == 168587773) {    // on BLAST
            feeToken = 0x5d5408e949594E535d0c3d533761Cb044E11b664;
            feeManager = 0x610D47b471Ca1BA509F752AFAD8E391664bF4deC;
            gatewayAddr = 0x4218C42503FBB0CC65cbDf507B7ce64F0C52BC32;
            rwa001XAddr = 0xC230C289328a86d2daC10Db25E91f516aD7D0D3f;
            ctmFallbackAddr = 0x0f78335bD79BDF6C8cbE6f4F565Ca715a44Aed54;
            ctmRwa001Map = 0xD55F76833388137FB1ECFc0dE1e6982716A19640;
            ctmRwaDeployer = 0x25903bEA74d4fbE43B7D30703D2A740841DfB7b2;
            ctmRwaFactory = 0x80f1BB2DF520e3e091C79AebE81f46136A8fBCb5;
            dividendAddr = 0x0A0C882706544F37377e9bb7976E0805cd29a94F;
            storageManagerAddr = 0x3dc0e90bB56DE095321c48aadF0D0c29b47b837a;
            sentryManagerAddr = 0x3FfbC9f4C2Bb8fB74Ab712d3E01c695Ce2329b1D;
        } else if(chainId == 1952959480) {    // on LUMIA
            feeToken = 0x6a4DBC971533Ba36bdc23aD70F5A7a12E064f4ae;
            feeManager = 0x8BeaD36D15356320159A846a53AF8d6cB2eAA604;
            gatewayAddr = 0x3B973407EB120f75B4a3a8702145Aa7F96cb9c07;
            rwa001XAddr = 0x98269063D2bd9dDa4B9438f4240463b8B475c7f6;
            ctmFallbackAddr = 0x81Db0Cb1645C447214909a2C90A048B9AD4881f5;
            ctmRwa001Map = 0xeE894d33b491B5B4D930F21bd1D9B583EA5493C7;
            ctmRwaDeployer = 0xC47E0Da1a73b7E6aa86fce7F21C73Cc8D5E8ef4B;
            ctmRwaFactory = 0x7D29D0bcBFda9c23c82317AF1a57995F74954a7e;
            dividendAddr = 0x6fCfFb153d538194467357a887B8973b1dC286d9;
            storageManagerAddr = 0x6b556FaA59C5F719Bc0E70B8872e08A80F55969E;
            sentryManagerAddr = 0x656F2D9D696e03779263e92d43BF92829825CD09;
        // } else if(chainId == 14853) {    // on HUMANODE
        //     feeToken = 0x6dD69414E074575c45D5330d2707CAf80303a85B;
        //     feeManager = ;
        //     gatewayAddr = ;
        //     rwa001XAddr = ;
        //     ctmFallbackAddr = ;
        //     ctmRwa001Map = ;
        //     ctmRwaDeployer = ;
        //     ctmRwaFactory = ;
        //     dividendAddr = ;
        //     storageManagerAddr = ;
        } else if(chainId == 200810) {    // on Bitlayer
            feeToken = 0x6a4DBC971533Ba36bdc23aD70F5A7a12E064f4ae;
            feeManager = 0x66b719C489193594c617801e67119959CD15b63A;
            gatewayAddr = 0x5Fb1394608Ce2Ef7092A642d6c5D3b2325300bFD;
            rwa001XAddr = 0xe5AF1a54B2b8cA3091edD229329B60A82b7A04E8;
            ctmFallbackAddr = 0xe96270a4DeFb602d8C7E5aDB7f090EAC5291A641;
            ctmRwa001Map = 0x766061Cd28592Fd2503cAA3E4772C1215192cD3d;
            ctmRwaDeployer = 0xa78f13ddB2538e76ed0EB66F3B0c36d77c237Ab8;
            ctmRwaFactory = 0xE569c146B0d4c1c941607b5c6A648b5877AE29EF;
            dividendAddr = 0x41cf60030c69b88baE714c2e67D101E158C3bB97;
            storageManagerAddr = 0xC5E7f5e1BABBF45e3F1e0764B48736C19A122383;
            sentryManagerAddr = 0x0A576aB9704438ef4eF94C50c6bD0F13eFE12b06;
        } else if(chainId == 2484) {    // on U2U NEBULAS
            feeToken = 0x6a4DBC971533Ba36bdc23aD70F5A7a12E064f4ae;
            feeManager = 0xa3bae05aA45bcC739258b124FACE332043D3B1dA;
            gatewayAddr = 0x3CB56e6E5917a2a8924BC2A5C1f0ecc90b585e74;
            rwa001XAddr = 0x1F652e2D8A9FCa346A0F45D59a67FB998999e454;
            ctmFallbackAddr = 0x95574b1a28865A81D2df36683d027A9D7603aFC7;
            ctmRwa001Map = 0xEcabB66a84340E7E6D020EAD0dAb1364767f3f70;
            ctmRwaDeployer = 0xeFbd6990A5C4ABFA30b91409aA3d9A0e7C8Bb77b;
            ctmRwaFactory = 0x7AEECCcafb96e53460B5b633Fc668adf14ed8419;
            dividendAddr = 0x66b719C489193594c617801e67119959CD15b63A;
            storageManagerAddr = 0xA33cfD901896C775c5a6d62e94081b4Fdd1B09BC;
            sentryManagerAddr = 0x41543A4C6423E2546FC58AC63117B5692D68c323;
        } else if(chainId == 1115) {    // on CORE
            feeToken = 0x6a4DBC971533Ba36bdc23aD70F5A7a12E064f4ae;
            feeManager = 0x5b4d2c1b2e918fF1b0DE85803F5A737E5f816eCb;
            gatewayAddr = 0xF3A991cB19949cB6aBD9E416F0408C648B6c36Fa;
            rwa001XAddr = 0xb5d1f61f6B9f0CA2B89eb9D693e8cD737076846A;
            ctmFallbackAddr = 0xF96089140dd5869Cc84C5c3A4B65dE016BE7fAc3;
            ctmRwa001Map = 0xFCCE5239FF3783fDEFF7FC2E303D619e3e8e0870;
            ctmRwaDeployer = 0x6f013Ad0b507590dcB26E674199ba99d613e9dFD;
            ctmRwaFactory = 0x5c0712E102261ED6B7Dbde118bF351150BDa425f;
            dividendAddr = 0x783264825Db3088b5448f85B6dc25BB7EEf666ec;
            storageManagerAddr = 0xf9229aCEba228fdbb757A637EeeBadB46FDb617e;
        } else if(chainId == 534351) {    // on SCROLL
            feeToken = 0xe536Bf33585aa6bb528627Ed7Dc4D49009dafC58;
            feeManager = 0x7ED4D0234E6c0F6704463E9A62A33AB7B7846A09;
            gatewayAddr = 0xD55F76833388137FB1ECFc0dE1e6982716A19640;
            rwa001XAddr = 0x9E2F5D1228b02C2FbF3168Db1162e7461574eBB9;
            ctmFallbackAddr = 0x25903bEA74d4fbE43B7D30703D2A740841DfB7b2;
            ctmRwa001Map = 0x80f1BB2DF520e3e091C79AebE81f46136A8fBCb5;
            ctmRwaDeployer = 0x3dc0e90bB56DE095321c48aadF0D0c29b47b837a;
            ctmRwaFactory = 0x3FfbC9f4C2Bb8fB74Ab712d3E01c695Ce2329b1D;
            dividendAddr = 0xDFe447a7F6780dD40D3eA4CF3F132c1F3b50BfF7;
            storageManagerAddr = 0x0A0C882706544F37377e9bb7976E0805cd29a94F;
            sentryManagerAddr = 0x6F0DDf81d8145301058e37CC51A485Ae6b44BCF9;
        } else if(chainId == 59141) {    // on LINEA
            feeToken = 0x6654D956A4487A26dF1186b01B689c26939544fC;
            feeManager = 0x6a61BDf8faaE1614701674dB133A0bd1414E88Dc;
            gatewayAddr = 0x5Bd9BE690c9DA2Afb3E50eC6B73ae6EaA66d5d30;
            rwa001XAddr = 0xdfa830314001a2dc761c0564D61962a57b7A5B89;
            ctmFallbackAddr = 0x328bBD32Ca55cD85Ef95f88df18c95f7562b05AA;
            ctmRwa001Map = 0x3144e9ff0C0F7b2414Ec0684665451f0487293FA;
            ctmRwaDeployer = 0x75F6b1C030591b1075dad74C46705851c5bbF924;
            ctmRwaFactory = 0x114ace1c918409889464c2a714f8442a97934Ccf;
            dividendAddr = 0x9aF1e5b3e863d88A4E220fb07FfB8c2e5a96dDbd;
            storageManagerAddr = 0x73B4143b7cd9617F9f29452f268479Bd513e3d23;
            sentryManagerAddr = 0x5dA80743b6FD7FEB2Bf7207aBe20E57E204e2B5b;
        } else if(chainId == 1946) {    // on SONEIUM
            feeToken = 0x6a4DBC971533Ba36bdc23aD70F5A7a12E064f4ae;
            feeManager = 0xf7548cB35188aa7DaC8423fAA2ACe3855634e40C;
            gatewayAddr = 0x654Ad7D43857b354079caD2d668bFA1eF2a01Fcf;
            rwa001XAddr = 0x610D47b471Ca1BA509F752AFAD8E391664bF4deC;
            ctmFallbackAddr = 0x4218C42503FBB0CC65cbDf507B7ce64F0C52BC32;
            ctmRwa001Map = 0x0f78335bD79BDF6C8cbE6f4F565Ca715a44Aed54;
            ctmRwaDeployer = 0xD55F76833388137FB1ECFc0dE1e6982716A19640;
            ctmRwaFactory = 0x25903bEA74d4fbE43B7D30703D2A740841DfB7b2;
            dividendAddr = 0x3FfbC9f4C2Bb8fB74Ab712d3E01c695Ce2329b1D;
            storageManagerAddr = 0x80f1BB2DF520e3e091C79AebE81f46136A8fBCb5;
            sentryManagerAddr = 0x3dc0e90bB56DE095321c48aadF0D0c29b47b837a;
        } else if(chainId == 153) {    // on REDBELLY
            feeToken = 0xe536Bf33585aa6bb528627Ed7Dc4D49009dafC58;
            feeManager = 0xD4bD9BBA2fb97C36Bbd619303cAB636F476f8904;
            gatewayAddr = 0xeA5c4FBEFFDfe9173bE7dC8c94eD6288A1D8f85E;
            rwa001XAddr = 0x8d494f8B762005cCA5BDEBb770Af3bf51E730305;
            ctmFallbackAddr = 0xD523b4f68c015B472724c24e127FF1f51EeE0fbf;
            ctmRwa001Map = 0xdC910F7BCc6f163DFA4804eACa10891eb5B9E867;
            ctmRwaDeployer = 0xCBf4E5FDA887e602E5132FA800d74154DFb5B237;
            ctmRwaFactory = 0x24DA0F2114B682D01234bC9E103ff7eEbF86aE6A;
            dividendAddr = 0xDD15811D29A330AD2850A994f6AAEcFfA68A5c12;
            storageManagerAddr = 0x52661DbA4F88FeD997164ff2C453A2339216592C;
            sentryManagerAddr =  0x89c8CC177f04CC8209B93e42d81a780c3A685dD4;
        } else if(chainId == 84532) {    // on BASE SEPOLIA *
            feeToken = 0x6a4DBC971533Ba36bdc23aD70F5A7a12E064f4ae;
            feeManager = 0xD3ee2E923723D2e634219797512bD768d5973020;
            gatewayAddr = 0x808490311dEbe8818cdfFe1FAae436cb84fAa906;
            rwa001XAddr = 0xB3672d1bBd1bADbbBf6b327C2ad7785534aF2E7F;
            ctmFallbackAddr = 0x20D5CdE9700144ED0Da22754D89f3379916c99Fa;
            ctmRwa001Map = 0xC5A13F8750f362AA8e8Ace59f261268295923190;
            ctmRwaDeployer = 0xfFFDFD7bBd2D957dd12EA30Ce24852dc26F8b453;
            ctmRwaFactory = 0xf8da97e4A861EE781c5e3ab5d2e6472d0f900aFf;
            dividendAddr = 0x7048fc44bAEbb72929724f8E6BBdbA3ED470ab4c;
            storageManagerAddr = 0x1481875CA0EcD0ACdEb79d3d57FB76EAE726d128;
            sentryManagerAddr = 0x3bFF2A879a92e2125cDe895FA20BA3A4AEb2D4D7;
        } else if(chainId == 97) {  // BSC TESTNET
            feeToken = 0xDd43fc986a13392dDbC7aeA150b41EfE27b2d0eD;
            feeManager = 0x20D5CdE9700144ED0Da22754D89f3379916c99Fa;
            gatewayAddr = 0x4146FE54Fd379fd095C227ea012a50387674766D;
            rwa001XAddr = 0xC5A13F8750f362AA8e8Ace59f261268295923190;
            ctmFallbackAddr = 0xaD22d595152AB2De3aD57a97E127142B1B6Cd376;
            ctmRwa001Map = 0xC886FFa78114cf7e701Fd33505b270505B3FeAE3;
            ctmRwaDeployer = 0x3e15986e2fCbc9A636Ddf2eA798Ae6C162200144;
            ctmRwaFactory = 0xC6965959fa28741191DdCb20B6b99657fbDA9f45;
            dividendAddr = 0x823329dd3F730031E95338Ce59f5Fcb3BE6486B4;
            storageManagerAddr = 0x188af80a2ea153bc43dD448434d753C05D3C93f3;
            sentryManagerAddr = 0x39446dF8f82282Aebcb0EdDc61D6B716C188Ee85;
        }

        gateway = ICTMRWAGateway(gatewayAddr);
        rwa001X = ICTMRWA001X(rwa001XAddr);
        storageManager = ICTMRWA001StorageManager(storageManagerAddr);
        sentryManager = ICTMRWA001SentryManager(sentryManagerAddr);
        ctmFallback = ICTMRWA001XFallback(ctmFallbackAddr);
        dividend = ICTMRWA001Dividend(dividendAddr);
        feeTokenStr = feeToken.toHexString();
    }

    function deployLocal() public returns(uint256) {

        vm.startBroadcast(senderPrivateKey);

        IERC20(feeToken).approve(rwa001XAddr, 1000*10**ITheiaERC20(feeToken).decimals());

        string[] memory chainIdsStr;

        uint256 IdBack = rwa001X.deployAllCTMRWA001X(true, 0, 1, 1, "Closed Roses", "ROSE", 18, "GFLD", chainIdsStr, feeTokenStr);
        console.log(IdBack);

        vm.stopBroadcast();

        return(IdBack);
       
    }

    function deployRemote(uint256 _ID) public {

        vm.startBroadcast(senderPrivateKey);

        IERC20(feeToken).approve(rwa001XAddr, 1000*10**ITheiaERC20(feeToken).decimals());

        (bool ok, address ctmRwa001) = ICTMRWAMap(ctmRwa001Map).getTokenContract(_ID, rwaType, version);

        string memory tokenName = ICTMRWA001(ctmRwa001).name();
        string memory symbol = ICTMRWA001(ctmRwa001).symbol();
        uint8 decimals = ICTMRWA001(ctmRwa001).valueDecimals();
        string memory baseURI = ICTMRWA001(ctmRwa001).baseURI();


        // function deployAllCTMRWA001X(
        //     bool _includeLocal,
        //     uint256 _existingID,
        //     uint256 _rwaType,
        //     uint256 _version,
        //     string memory _tokenName, 
        //     string memory _symbol, 
        //     uint8 _decimals,
        //     string memory _baseURI,
        //     string[] memory _toChainIdsStr,
        //     string memory _feeTokenStr
        // ) public returns(uint256) {

        uint256 IdBack = rwa001X.deployAllCTMRWA001X(false, _ID, 1, 1, tokenName, symbol, decimals, baseURI, toChainIdsStr, feeTokenStr);

        console.log("IdBack");
        console.log(IdBack);

        vm.stopBroadcast();
    }

    

    function debugRwaXCall() public {

        string memory newAdminStr = admin.toHexString();
        uint256 ID = 29251130053171396288129669670399520996794011934199132580927820677505894114636;

        bool ok = rwa001X.deployCTMRWA001(
            newAdminStr,
            ID,
            "Selqui SQ1",
            "SQ1",
            uint8(18),
            "GFLD",
            allSlots
        );

        console.log("RETURNS");
        console.log(ok);

    }

    function createSlots(uint256 _ID, string[] memory chainIdsStr) public {
        vm.startBroadcast(senderPrivateKey);

        IERC20(feeToken).approve(rwa001XAddr, 10000*10**ITheiaERC20(feeToken).decimals());


        // function createNewSlot(
        //     uint256 _ID,
        //     uint256 _slot,
        //     string memory _slotName,
        //     string[] memory _toChainIdsStr,
        //     string memory _feeTokenStr
        // ) public returns(bool) 

        bool ok = rwa001X.createNewSlot(
            _ID,
            0,
            "Fractional painting",
            chainIdsStr,
            feeTokenStr
        );

        vm.stopBroadcast();
    }

    function getSlots(uint256 _ID, uint256 slotIndx) public view {

       (, address ctmRwa001) = ICTMRWAMap(ctmRwa001Map).getTokenContract(_ID, rwaType, version);

        (uint256[] memory slotNumbers, string[] memory slotNames) = ICTMRWA001(ctmRwa001).getAllSlots();

        console.log("SlotData - slot");
        console.log(slotNumbers[slotIndx]);
        console.log("SlotData - slotName");
        console.log(slotNames[slotIndx]);

    }

    function mintLocalValue(uint256 _ID) public {

        vm.startBroadcast(senderPrivateKey);

        IERC20(feeToken).approve(rwa001XAddr, 10000*10**ITheiaERC20(feeToken).decimals());

        uint256 newTokenId = rwa001X.mintNewTokenValueLocal(senderAccount, 0, 6, 1450, _ID);
        console.log("newTokenId = ");
        console.log(newTokenId);

        vm.stopBroadcast();

    }

    function activateWhitelist(uint256 _ID) public {
        vm.startBroadcast(senderPrivateKey);

        IERC20(feeToken).approve(sentryManagerAddr, 10000*10**ITheiaERC20(feeToken).decimals());

        (bool ok, address sentryAddr) = ICTMRWAMap(ctmRwa001Map).getSentryContract(_ID, 1, 1);
        console.log("Sentry contract");
        console.logAddress(sentryAddr);

        bool wl = ICTMRWA001Sentry(sentryAddr).whitelistSwitch();
        console.log("Before Whitelist, switch = ");
        console.logBool(wl);

        bool whitelistOnly = true;

        ICTMRWA001SentryManager(sentryManagerAddr).setSentryOptions(
            _ID, 
            whitelistOnly, 
            false, 
            false, 
            false, 
            false, 
            false, 
            false, 
            toChainIdsStr, 
            feeTokenStr
        );

        wl = ICTMRWA001Sentry(sentryAddr).whitelistSwitch();
        console.log("After Whitelist, switch = ");
        console.logBool(wl);


        vm.stopBroadcast();

    }

    function addToWhitelist(uint256 _ID, string memory _newAddrStr) public {
        vm.startBroadcast(senderPrivateKey);

        IERC20(feeToken).approve(sentryManagerAddr, 10000*10**ITheiaERC20(feeToken).decimals());

        (bool ok, address sentryAddr) = ICTMRWAMap(ctmRwa001Map).getSentryContract(_ID, 1, 1);
        console.log("Sentry contract");
        console.logAddress(sentryAddr);

        bool wl = ICTMRWA001Sentry(sentryAddr).whitelistSwitch();
        console.log("Before Whitelist, switch = ");
        console.logBool(wl);

        // function addWhitelist(
        //     uint256 _ID,
        //     string[] memory _wallets,
        //     bool[] memory _choices,
        //     string[] memory _chainIdsStr,
        //     string memory _feeTokenStr
        // ) public {



        ICTMRWA001SentryManager(sentryManagerAddr).addWhitelist(
            _ID,
            _stringToArray(_newAddrStr),
            _boolToArray(true),
            toChainIdsStr,
            feeTokenStr
        );



        vm.stopBroadcast();

    }
   
    function transferValueTokenToAddress(uint256 _ID) public {

        vm.startBroadcast(senderPrivateKey);

        IERC20(feeToken).approve(rwa001XAddr, 10000*10**ITheiaERC20(feeToken).decimals());

        (, address ctmRwa001) = ICTMRWAMap(ctmRwa001Map).getTokenContract(_ID, rwaType, version);

        uint256 tokenId = ICTMRWA001(ctmRwa001).tokenOfOwnerByIndex(admin, 0);
        console.log("tokenId");
        console.log(tokenId);
        console.log("with slot =");
        console.log(ICTMRWA001(ctmRwa001).slotOf(tokenId));

        // function transferPartialTokenX(
        //     uint256 _fromTokenId,
        //     string memory _toAddressStr,
        //     string memory _toChainIdStr,
        //     uint256 _value,
        //     uint256 _ID,
        //     string memory _feeTokenStr
        // ) public {

        rwa001X.transferPartialTokenX(
            tokenId,
            admin.toHexString(),
            "84532",
            50,
            _ID,
            feeTokenStr
        );

    }



    function transferValueWholeTokenToAddress(uint256 _ID) public {
        vm.startBroadcast(senderPrivateKey);

        IERC20(feeToken).approve(rwa001XAddr, 10000*10**ITheiaERC20(feeToken).decimals());

        (bool ok, address ctmRwa001) = ICTMRWAMap(ctmRwa001Map).getTokenContract(_ID, rwaType, version);

        uint256 tokenId = ICTMRWA001(ctmRwa001).tokenOfOwnerByIndex(admin, 2);
        console.log("second tokenId");
        console.log(tokenId);

        console.log("with slot");
        console.log(ICTMRWA001(ctmRwa001).slotOf(tokenId));

        // function transferWholeTokenX(
        //     string memory _toAddressStr,
        //     string memory _toChainIdStr,
        //     uint256 _fromTokenId,
        //     uint256 _ID,
        //     string memory _feeTokenStr
        // ) public {

        rwa001X.transferWholeTokenX(
            admin.toHexString(),
            admin.toHexString(),
            "97",
            tokenId,
            _ID,
            feeTokenStr
        );

        vm.stopBroadcast();

    }


    function addURI(uint256 _ID, string[] memory chainIdsStr) public {

        vm.startBroadcast(senderPrivateKey);

        IERC20(feeToken).approve(storageManagerAddr, 1000*10**ITheiaERC20(feeToken).decimals());

        (, address ctmRwa001) = ICTMRWAMap(ctmRwa001Map).getTokenContract(_ID, rwaType, version);

        (bool ok, address stor) = ICTMRWAMap(ctmRwa001Map).getStorageContract(_ID, 1, 1);
        console.log("Storage contract for ID = ");
        console.log(stor);

        // uint256 tokenId = ICTMRWA001(ctmRwa001).tokenOfOwnerByIndex(admin, 0);
        // console.log("first tokenId");
        // console.log(tokenId);

        // uint256 slot = ICTMRWA001(ctmRwa001).slotOf(tokenId);

        // console.log("with slot");
        // console.log(slot);

        // string memory randomData = "this is any old data";
        // bytes32 junkHash = keccak256(abi.encode(randomData));
        bytes32 junkHash = 0x63d458cf12f8c32326328cf36fb8dcf454c0e5dc9ab36a9ecd8366b22a8b5215;

        console.log("junkHash");
        console.logBytes32(junkHash);


        storageManager.addURI(
            _ID,
            "1",
            URICategory.ISSUER,
            URIType.CONTRACT,
            "Basic RWA for testing",
            0,
            junkHash,
            chainIdsStr,
            feeTokenStr
        );

        bool hashExists = ICTMRWA001Storage(stor).existURIHash(junkHash);
        console.log("junkhash exists = ");
        console.log(hashExists);

        vm.stopBroadcast();

    }

    function addURIX(uint256 _ID) public {
        
    }

    function lockRwa(uint256 _ID) public {

        vm.startBroadcast(senderPrivateKey);

        IERC20(feeToken).approve(storageManagerAddr, 1000*10**ITheiaERC20(feeToken).decimals());

        // function changeTokenAdmin(
        //     string memory _newAdminStr,
        //     string[] memory _toChainIdsStr,
        //     uint256 _ID,
        //     string memory _feeTokenStr
        // ) public returns(bool) {

        rwa001X.changeTokenAdmin(
            address(0).toHexString(),
            toChainIdsStr,
            _ID,
            feeTokenStr
        );


        vm.stopBroadcast();

    }

    function checkC3Call(bytes32 uuid) public {

        bool exists = IDKeeper(c3UUIDKeeper).isUUIDExist(uuid);
        console.log("isUUIDExist");
        console.log(exists);

        bool completed = IUUIDKeeper(c3UUIDKeeper).isCompleted(uuid);
        console.log("isCompleted");
        console.log(completed);
    }

    function checkDeployData() public {
        bytes4 sig = bytes4(abi.encodePacked(keccak256("deployCTMRWA001(string,uint256,uint256,uint256,string,string,uint8,string,string)")));
        bytes memory callData = "000000000000000000000000000000000000000000000000000000000000002d000000000000000000000000eef3d3678e1e739c6522eec209bede019779133900000000000000000000000000000000000000000000000000000000000000604df4ec149dcdce7cdc62ac48dd25a01148caedee5aa07c208e0f5ccf45ce9b02000000000000000000000000a85c68e9e09b2e84df95e2ea7325fb27019edf3000000000000000000000000000000000000000000000000000000000000000c00000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000018000000000000000000000000000000000000000000000000000000000000001e0000000000000000000000000000000000000000000000000000000000000000634323136313400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000042307864383034336338366462653233336235363135656230343738666532386465343264353335363061393665376564393664316135323533653139396365663938000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002a307862333763383164366639306131366262643737383838366166343961626562666431616430326337000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000244b82d98342d3e35573faf2c9b90c6356b02678c271a0742392c0db6e7646bd1a56f0af81e0000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000016000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003000000000000000000000000000000000000000000000000000000000000025800000000000000000000000000000000000000000000000000000000000001c00000000000000000000000000000000000000000000000000000000000000220000000000000000000000000000000000000000000000000000000000000002a30786536326162346431313166393638363630633662323138383034366639623962613533633462616500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002a30784233374338316436663930413136626244373738383836414634396162654266443141443032433700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002a30783535326431333834626630376138346230643862383665666161383035393333363938663335623900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000";
    
        console.log("sig");
        console.logBytes4(sig);


        console.log("Starting");
        // (
        //     string memory currentAdminStr,
        //     uint256 ID,
        //     uint256 rwaType,
        //     uint256 version,
        //     string memory _tokenName,
        //     string memory _symbol,
        //     uint8 _decimals,
        //     string memory _baseURI,
        //     string memory _ctmRwa001AddrStr
        //     ) = abi.decode(callData, (string,uint256,uint256,uint256,string,string,uint8,string,string));
    
    
        // console.log("token name");
        // console.log(_tokenName);
    }

    function stringToAddress(string memory str) internal pure returns (address) {
        bytes memory strBytes = bytes(str);
        require(strBytes.length == 42, "CTMRWAMap: Invalid address length");
        bytes memory addrBytes = new bytes(20);

        for (uint i = 0; i < 20; i++) {
            addrBytes[i] = bytes1(
                hexCharToByte(strBytes[2 + i * 2]) *
                    16 +
                    hexCharToByte(strBytes[3 + i * 2])
            );
        }

        return address(uint160(bytes20(addrBytes)));
    }

    function _boolToArray(bool _bool) internal pure returns(bool[] memory) {
        bool[] memory boolArray = new bool[](1);
        boolArray[0] = _bool;
        return(boolArray);
    }

    function hexCharToByte(bytes1 char) internal pure returns (uint8) {
        uint8 byteValue = uint8(char);
        if (
            byteValue >= uint8(bytes1("0")) && byteValue <= uint8(bytes1("9"))
        ) {
            return byteValue - uint8(bytes1("0"));
        } else if (
            byteValue >= uint8(bytes1("a")) && byteValue <= uint8(bytes1("f"))
        ) {
            return 10 + byteValue - uint8(bytes1("a"));
        } else if (
            byteValue >= uint8(bytes1("A")) && byteValue <= uint8(bytes1("F"))
        ) {
            return 10 + byteValue - uint8(bytes1("A"));
        }
        revert("Invalid hex character");
    }

    function _stringToArray(string memory _string) internal pure returns(string[] memory) {
        string[] memory strArray = new string[](1);
        strArray[0] = _string;
        return(strArray);
    }

    function decodeXChain() public {

        vm.startBroadcast(senderPrivateKey);

        bytes memory cData = bytes("0x000000000000000000000000b41c8b53ea014188ba6777233e04efddbf4877b100000000000000000000000000000000000000000000000000000000000000a000000000000000000000000000000000000000000000000000000000000000e00000000000000000000000000000000000000000000000000000000000000140000000000000000000000000000000000000000000000000000000000000042000000000000000000000000000000000000000000000000000000000000000023937000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002a3078396230626331653832363732353262326539396664613863333032623037313362613361383230320000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002a43d9ab49f0000000000000000000000000000000000000000000000000000000000000120ba2164ceba74b49a633fe49773785daecf83a8af13eeb22e8c160ca2cfb6246500000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000018000000000000000000000000000000000000000000000000000000000000001c0000000000000000000000000000000000000000000000000000000000000001200000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000240000000000000000000000000000000000000000000000000000000000000002a30786536326162346431313166393638363630633662323138383034366639623962613533633462616500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a53656c717569205351310000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000035351310000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000447464c4400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002a30786532306338663266613865646539386132373136653836353161363666633532643664636661323100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000");

        (
            string memory currentAdminStr,
            uint256 ID,
            uint256 rwaType,
            uint256 version,
            string memory _tokenName,
            string memory _symbol,
            uint8 _decimals,
            string memory _baseURI,
            string memory _ctmRwa001AddrStr
        ) = abi.decode(cData, (string,uint256,uint256,uint256,string,string,uint8,string,string));

        //address(0x9B0bc1e8267252B2E99fdA8c302b0713Ba3a8202).call(cData);

        vm.stopBroadcast();
    }

}