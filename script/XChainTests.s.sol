// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.19;

import { Script } from "forge-std/Script.sol";
import "forge-std/console.sol";

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

import { IC3Caller } from "@c3caller/IC3Caller.sol";

import { ITheiaERC20 } from "@c3caller/theia/ITheiaERC20.sol";
import { IUUIDKeeper } from "@c3caller/uuid/IUUIDKeeper.sol";

import { ICTMRWA1, SlotData } from "../src/core/ICTMRWA1.sol";

import { ICTMRWA1X } from "../src/crosschain/ICTMRWA1X.sol";
import { ICTMRWA1XFallback } from "../src/crosschain/ICTMRWA1XFallback.sol";
import { ICTMRWAGateway } from "../src/crosschain/ICTMRWAGateway.sol";

import { ICTMRWADeployer } from "../src/deployment/ICTMRWADeployer.sol";

import { ICTMRWA1Dividend } from "../src/dividend/ICTMRWA1Dividend.sol";

import { ICTMRWA1Sentry } from "../src/sentry/ICTMRWA1Sentry.sol";
import { ICTMRWA1SentryManager } from "../src/sentry/ICTMRWA1SentryManager.sol";

import { ICTMRWAMap } from "../src/shared/ICTMRWAMap.sol";

import { URICategory, URIType } from "../src/storage/ICTMRWA1Storage.sol";
import { ICTMRWA1Storage, URICategory, URIData, URIType } from "../src/storage/ICTMRWA1Storage.sol";
import { ICTMRWA1StorageManager } from "../src/storage/ICTMRWA1StorageManager.sol";

interface IDKeeper {
    function isUUIDExist(bytes32) external returns (bool);
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
    address rwa1XAddr;
    address ctmFallbackAddr;
    address ctmRwa1Map;
    address ctmRwaDeployer;
    address ctmRwaFactory;
    address dividendAddr;
    address storageManagerAddr;
    address sentryManagerAddr;

    ICTMRWAGateway gateway;
    ICTMRWA1X rwa1X;
    ICTMRWA1StorageManager storageManager;
    ICTMRWA1SentryManager sentryManager;
    ICTMRWA1XFallback ctmFallback;
    ICTMRWA1Dividend dividend;

    uint256 senderPrivateKey = vm.envUint("PRIVATE_KEY");
    address senderAccount = vm.addr(senderPrivateKey);

    function run() external {
        loadContracts(421_614);

        uint256 ID =
            32_040_649_258_612_427_893_281_522_177_540_151_650_934_260_323_877_079_186_698_121_410_535_279_995_065;

        // debugRwaXCall();

        // bytes32 uuid = 0x9521f78e716c509942f2b2b0167b089a447a04f6dc30afee8458e7d54a95637b;
        // checkC3Call(uuid);

        // decodeXChain();

        // checkDeployData();

        // uint256 idBack = deployLocal();

        // toChainIdsStr.push("421614");
        // toChainIdsStr.push("97");
        // toChainIdsStr.push("84532");
        // toChainIdsStr.push("78600"); // Vanguard
        // toChainIdsStr.push("534351"); // Scroll
        // toChainIdsStr.push("5003");
        // deployRemote(ID);
        // createSlots(ID, toChainIdsStr);
        // getSlots(ID,0);

        // mintLocalValue(ID);

        // string memory newAddrStr = "0xb5981FADCD79992f580ccFdB981d9D850b27DC37";
        // toChainIdsStr.push("421614");
        // activateWhitelist(ID);
        // addToWhitelist(ID, newAddrStr);

        // transferValueTokenToAddress(ID);

        // transferValueWholeTokenToAddress(ID);

        // addURI(ID, toChainIdsStr);

        // toChainIdsStr.push("5611");
        // lockRwa(ID);

        fundDividends(ID, 0);
    }

    function loadContracts(uint256 chainId) public {
        if (chainId == 421_614) {
            // On ARB SEPOLIA
            // c3UUIDKeeper = ;
            feeToken = 0xbF5356AdE7e5F775659F301b07c4Bc6961044b11;
            feeManager = 0xc28328b1f98076eD5111f1223C647E883f5d6E16;
            gatewayAddr = 0xFa89DD803b8872f991997778d26c74a3Aecd9639;
            rwa1XAddr = 0x8bd737F4Ea451911eDF0445ACB1B7efdc9565221;
            ctmFallbackAddr = 0xc84C772F77Ff379D00229F8fcdE16Ed91bcFe8Da;
            ctmRwa1Map = 0x4f390Eaa4Ddb82fc37053b8E8dbc3367594577E4;
            ctmRwaDeployer = 0x167EF5E62CF14Eb74c4A9bC599D9afcB2119c2f8;
            ctmRwaFactory = 0x35e0c0081fDAC9d2731B8dB54f131EFc5aa8d25E;
            dividendAddr = 0xEE7729FbC22B718ce4999bAe6aabACDd8e2C2878;
            storageManagerAddr = 0x7aB4De775c88e4aA4c93d0078d8318463fABfb13;
            sentryManagerAddr = 0xb63F83484b9bdbaD5C574B4c89Badf0359e78854;
        } else if (chainId == 80_002) {
            // on POLYGON AMOY
            feeToken = 0x6a4DBC971533Ba36bdc23aD70F5A7a12E064f4ae;
            feeManager = 0xA332fc0BF257AFF4aB07267De75d5Eb0c67B71AF;
            gatewayAddr = 0x66dB3f564807fdc689eC85285981eF464daeB943;
            rwa1XAddr = 0x2dA1B2763cF56b9DF5CbBB5A996C7e8836d8C6D8;
            ctmFallbackAddr = 0x2fDbB139FB38520C2aD6CD30cF45b3C8E5633C65;
            ctmRwa1Map = 0x9A48630090429E3039A5E1CDb4cf0433D54a1AEe;
            ctmRwaDeployer = 0x709b45446a540fA2bE3B9f8C6302B8c392AA9095;
            ctmRwaFactory = 0x2d65BF61631767CEC4D28BeCF7d38f40eD6AFe8E;
            dividendAddr = 0x3be6c5F79d6aA0cE17641fEE418063DB59acec5c;
            storageManagerAddr = 0xB3D138F0613CC476faA8c5E2C1a64e90D9d506F3;
            sentryManagerAddr = 0xf32bc63A511B3B3DeB8fB6AeB3c52eBC0541067e;
        } else if (chainId == 43_113) {
            // on AVALANCHE FUJI
            feeToken = 0x15A1ED0815ECeD97E46967179846c72BA21DABAd;
            feeManager = 0x0cB36959A63c02C004566829D11e9EAb4dA3aCE0;
            gatewayAddr = 0x8176186fa521E54f12Dd8011EB6729003E3D3Fe0;
            rwa1XAddr = 0x5e0D85dFa2827cD3065aB2D4af93E58DC82c5e96;
            ctmFallbackAddr = 0x5fA2d872ac859d6F4b9b695B3b11de80160905ab;
            ctmRwa1Map = 0xD2cd1c42e56Ca30588de604E724C0031b2139053;
            ctmRwaDeployer = 0xA84752aC44fe4eD2bD82EFa6B6e12d3f96885d10;
            ctmRwaFactory = 0xf63ee230AdD3B9F8b675FCd1A2CF95Cc34C0f30C;
            dividendAddr = 0x511A4e9af646E933c145A8892837547900078A97;
            storageManagerAddr = 0xAE66C08b9d76EeCaA74314c60f3305D43707ACc9;
            sentryManagerAddr = 0xf9EDcE2638da660F51Ee08220a1a5A32fAB61d61;
            // } else if(chainId == 338) {    // on CRONOS
            //     feeToken = 0xf6d2060494cD08e776D22a47E67d485a33C8c5d2;
            //     feeManager = ;
            //     gatewayAddr = ;
            //     rwa1XAddr = ;
            //     ctmFallbackAddr = ;
            //     ctmRwa1Map = ;
            //     ctmRwaDeployer = ;
            //     ctmRwaFactory = ;
            //     dividendAddr = ;
            //     storageManagerAddr = ;
            //  } else if(chainId == 78600) {    // on VANGUARD
            //     feeToken = 0x6654D956A4487A26dF1186b01B689c26939544fC;
            //     feeManager = ;
            //     gatewayAddr = ;
            //     rwa1XAddr = ;
            //     ctmFallbackAddr = ;
            //     ctmRwa1Map = ;
            //     ctmRwaDeployer = ;
            //     ctmRwaFactory = ;
            //     dividendAddr = ;
            //     storageManagerAddr = ;
            //     sentryManagerAddr = ;
            // } else if(chainId == 3441006) {    // on MANTA
            //     feeToken = 0x20cEfCf72622156987f82E1B54E94Dbc0848De9C;
            //     feeManager = ;
            //     gatewayAddr = ;
            //     rwa1XAddr = ;
            //     ctmFallbackAddr = ;
            //     ctmRwa1Map = ;
            //     ctmRwaDeployer = ;
            //     ctmRwaFactory = ;
            //     dividendAddr = ;
            //     storageManagerAddr = ;
            //     sentryManagerAddr = ;
        } else if (chainId == 5003) {
            // on MANTLE
            feeToken = 0x6a4DBC971533Ba36bdc23aD70F5A7a12E064f4ae;
            feeManager = 0x358498985E6ac7CA73F5110b415525aE04CB8313;
            gatewayAddr = 0x9DC772b55e95A630031EBe431706D105af01Cf03;
            rwa1XAddr = 0xad49cabD336f943a9c350b9ED60680c54fa2c3d1;
            ctmFallbackAddr = 0x47D8fbD6206CAa763105CEfdEE47b16D03F87890;
            ctmRwa1Map = 0x1b34e36f4A7B083b153803946C68F8567b4Fe021;
            ctmRwaDeployer = 0x0EeA0C2FB4122e8193E26B06358E384b2b909848;
            ctmRwaFactory = 0xc047401F28F43eC8Af8C5aAaC26Bf7d007E2474a;
            dividendAddr = 0x36d600bAF33DeF37318D71a186418bB84D2A63b9;
            storageManagerAddr = 0xeDe597aA066e6d7bc84BF586c494735DEB7DDe9F;
            sentryManagerAddr = 0xDa61b02D88D2c857dA9d2da435152b08F03E2836;
        } else if (chainId == 11_155_111) {
            // on SEPOLIA
            feeToken = 0xa4C104db0937F1E886d5C9c9789D6f0e5bfBA75c;
            feeManager = 0x08D0F2f8368CE13206F4839c3ce9151Be93893Bc;
            gatewayAddr = 0x13797c225F8E3645299F17d83365e0f5DB1c1607;
            rwa1XAddr = 0x778511925d3243Cf03a2486386ECc363E9Ad6647;
            ctmFallbackAddr = 0x3800dAcd202a91A791BC040dfD352a9565E51Aa7;
            ctmRwa1Map = 0x4f102432739a2DE082B7977316796A05C99147fb;
            ctmRwaDeployer = 0xef7c7BB5AB5b7bf55f7Cd9a38167C1F61eD15295;
            ctmRwaFactory = 0x91677ec1879987aBC3978fD2A71204640A9e9f4A;
            dividendAddr = 0x2bb5cD060F24DE792b7C54d7577D7847EAe63D71;
            storageManagerAddr = 0x6681DB630eB117050D78E0B89eB5619b35Ea12e8;
            sentryManagerAddr = 0xF4842C8354fE42e85D6DCDe11CFAda1B80BEAa33;
            //  } else if(chainId == 2810) {    // on MORPH HOLESKY
            //     feeToken = 0x6a4DBC971533Ba36bdc23aD70F5A7a12E064f4ae;
            //     feeManager = ;
            //     gatewayAddr = ;
            //     rwa1XAddr = ;
            //     ctmFallbackAddr = ;
            //     ctmRwa1Map = ;
            //     ctmRwaDeployer = ;
            //     ctmRwaFactory = ;
            //     dividendAddr = ;
            //     storageManagerAddr = ;
            //     sentryManagerAddr = ;
        } else if (chainId == 168_587_773) {
            // on BLAST
            feeToken = 0x5d5408e949594E535d0c3d533761Cb044E11b664;
            feeManager = 0x66dc636132fb9b7f6ed858928B65864D3fd0ea67;
            gatewayAddr = 0xEa4A06cB68ABa869e6BF98Edc4BdbC731d2D82e3;
            rwa1XAddr = 0x9A0F81de582Ce9194FEADC6CCefaf9eA70451616;
            ctmFallbackAddr = 0xF84A465ce158Aad1848B737a6eCAbE6D253D12C2;
            ctmRwa1Map = 0xcFF54249Dae66746377e15C07D95c42188D5d3A8;
            ctmRwaDeployer = 0x32101CD0cF6FbC0743B17B51A94224c75B7092A0;
            ctmRwaFactory = 0x1EeBC47AaE37F2EA390869efe60db5a2cF2c9d80;
            dividendAddr = 0x69a68786C9A1088f7121633b5c390F3007EAEBbe;
            storageManagerAddr = 0x8D4EEe23A687b304E94eee3211f3058A60744502;
            sentryManagerAddr = 0x0156a74FD9432446030f47f7c55f4d1FbfdF5E9a;
            // } else if(chainId == 1952959480) {    // on LUMIA
            //     feeToken = 0x6a4DBC971533Ba36bdc23aD70F5A7a12E064f4ae;
            //     feeManager = ;
            //     gatewayAddr = ;
            //     rwa1XAddr = ;
            //     ctmFallbackAddr = ;
            //     ctmRwa1Map = ;
            //     ctmRwaDeployer = ;
            //     ctmRwaFactory = ;
            //     dividendAddr = ;
            //     storageManagerAddr = ;
            //     sentryManagerAddr = ;
            // } else if(chainId == 14853) {    // on HUMANODE
            //     feeToken = 0x6dD69414E074575c45D5330d2707CAf80303a85B;
            //     feeManager = ;
            //     gatewayAddr = ;
            //     rwa1XAddr = ;
            //     ctmFallbackAddr = ;
            //     ctmRwa1Map = ;
            //     ctmRwaDeployer = ;
            //     ctmRwaFactory = ;
            //     dividendAddr = ;
            //     storageManagerAddr = ;
        } else if (chainId == 200_810) {
            // on Bitlayer
            feeToken = 0x6a4DBC971533Ba36bdc23aD70F5A7a12E064f4ae;
            feeManager = 0xb849bF0a5ca08f1e6EA792bDC06ff2317bb2fB90;
            gatewayAddr = 0xe08C7eE637336565511eb3421DAFdf45b860F9bc;
            rwa1XAddr = 0x78F81b1AEe019efaAfe58853D96c5E9Ac87be731;
            ctmFallbackAddr = 0x7743150e59d6A27ec96dDDa07B24131D0122b611;
            ctmRwa1Map = 0xb4317DBA65486889643585A8D96C8d1990971Cad;
            ctmRwaDeployer = 0xF813DdCDd690aCB06ddbFeb395Cf65D18Efe74A7;
            ctmRwaFactory = 0x140991fF31A86D700510C1d391A0ACd48CB7AbB7;
            dividendAddr = 0x605Ab9626e57C5d1f3f0508D5400aB0449b5a015;
            storageManagerAddr = 0x0F607AF04457E86eC349FbEbb6e23B0A6A0D067F;
            sentryManagerAddr = 0x10A04ad4a73C8bb00Ee5A29B27d11eeE85390306;
            // } else if(chainId == 2484) {    // on U2U NEBULAS
            //     feeToken = 0x6a4DBC971533Ba36bdc23aD70F5A7a12E064f4ae;
            //     feeManager = ;
            //     gatewayAddr = ;
            //     rwa1XAddr = ;
            //     ctmFallbackAddr = ;
            //     ctmRwa1Map = ;
            //     ctmRwaDeployer = ;
            //     ctmRwaFactory = ;
            //     dividendAddr = ;
            //     storageManagerAddr = ;
            //     sentryManagerAddr = ;
        } else if (chainId == 1115) {
            // on CORE
            feeToken = 0x6a4DBC971533Ba36bdc23aD70F5A7a12E064f4ae;
            feeManager = 0x87a0c3e97B52A42edBB513ad9701F6641B62afe2;
            gatewayAddr = 0xc0b8f765907ab09106010190Ee991aAae01F88Ba;
            rwa1XAddr = 0xC981D340AC02B717B52DC249c46B1942e20EDBAD;
            ctmFallbackAddr = 0xE9A9b06b26F1971D64a8f19682FE0E584eb5D541;
            ctmRwa1Map = 0x5ffFBa2E10d66e9368c6270cfD07e31802fff751;
            ctmRwaDeployer = 0x7f75443345A631751A7f6cdE34be3a8855ccdac7;
            ctmRwaFactory = 0x5318f955E3024C78329945Ea9517D3cC2443AeC4;
            dividendAddr = 0x309d782000B646429f79Bc927D2F382ec4DDf55C;
            storageManagerAddr = 0x2809808fC225FDAF859826cE7499a56B106D8870;
        } else if (chainId == 534_351) {
            // on SCROLL
            feeToken = 0xe536Bf33585aa6bb528627Ed7Dc4D49009dafC58;
            feeManager = 0x93637D7068CEebC6cCDCB230E3AE65436666fe15;
            gatewayAddr = 0x1944F7fdd330Af7b0e7C08349591213E35ed5948;
            rwa1XAddr = 0x1249d751e6a0b7b11b9e55CBF8bC7d397AC3c083;
            ctmFallbackAddr = 0x797AA64f83e4d17c2C6C80321f22445AAB153630;
            ctmRwa1Map = 0x21640b51400Da2B679916b8619c38b3Cc03692fe;
            ctmRwaDeployer = 0x20ADAf244972bC6cB064353F3EA4893f73E85599;
            ctmRwaFactory = 0x264D6501B1F4f3a98341C6aA81527e0C43587fB1;
            dividendAddr = 0x9A0F81de582Ce9194FEADC6CCefaf9eA70451616;
            storageManagerAddr = 0xb406b937C12E03d676727Fc1Bb686279EeDbc178;
            sentryManagerAddr = 0x66dc636132fb9b7f6ed858928B65864D3fd0ea67;
            // } else if(chainId == 59141) {    // on LINEA
            //     feeToken = 0x6654D956A4487A26dF1186b01B689c26939544fC;
            //     feeManager = ;
            //     gatewayAddr = ;
            //     rwa1XAddr = ;
            //     ctmFallbackAddr = ;
            //     ctmRwa1Map = ;
            //     ctmRwaDeployer = ;
            //     ctmRwaFactory = ;
            //     dividendAddr = ;
            //     storageManagerAddr = ;
            //     sentryManagerAddr = ;
        } else if (chainId == 1946) {
            // on SONEIUM
            feeToken = 0x6a4DBC971533Ba36bdc23aD70F5A7a12E064f4ae;
            feeManager = 0xF074c733800eC017Da580A5DC95533143CD6abE4;
            gatewayAddr = 0xa7441037961E31D4b64Aca57417d7673FEdC8fEC;
            rwa1XAddr = 0xf299832e535b9cc50D4002909061c320964D03FC;
            ctmFallbackAddr = 0x93637D7068CEebC6cCDCB230E3AE65436666fe15;
            ctmRwa1Map = 0x1249d751e6a0b7b11b9e55CBF8bC7d397AC3c083;
            ctmRwaDeployer = 0x797AA64f83e4d17c2C6C80321f22445AAB153630;
            ctmRwaFactory = 0x052E276c0A9D2D2adf1A2AeB6D7eCaEC38ec9dE6;
            dividendAddr = 0xD455BB0f664Ac8241b505729C3116f1ACC441be4;
            storageManagerAddr = 0x3f547B04f8CF9552434B7f3a51Fc23247911b797;
            sentryManagerAddr = 0xc04058E417De221448D4140FC1622dE24121C5e3;
        } else if (chainId == 153) {
            // on REDBELLY
            feeToken = 0xe536Bf33585aa6bb528627Ed7Dc4D49009dafC58;
            feeManager = 0xa328Fd0f353afc134f8f6Bdb51082D85395d7200;
            gatewayAddr = 0x24A74106195Acd7e3E0a8cc17fd44761CC32474a;
            rwa1XAddr = 0x41388451eca7344136004D29a813dCEe49577B44;
            ctmFallbackAddr = 0xe18CBAfD232945c93F0cFF5C38089c4A69623e7C;
            ctmRwa1Map = 0x9ae0309E655D58AA5fC29296523C2e4E8fcB7522;
            ctmRwaDeployer = 0x208Ec1Ca3B07a50151c5741bc0E05C61beddad90;
            ctmRwaFactory = 0x6F86E2fEeC756591A65D10158aca89DEc2e5eB51;
            dividendAddr = 0xe08C7eE637336565511eb3421DAFdf45b860F9bc;
            storageManagerAddr = 0x74972e7Ff5561bD902E3Ec3dDD5A22653088cA6f;
            sentryManagerAddr = 0x5930640c1572bCD396eB410f62a6975ab9b8A148;
        } else if (chainId == 84_532) {
            // on BASE SEPOLIA *
            feeToken = 0x6a4DBC971533Ba36bdc23aD70F5A7a12E064f4ae;
            feeManager = 0x050E942b8ebb0E174A847f343D04EfdC669dFf63;
            gatewayAddr = 0x31F21C6E2605D28e6b204CD323FF58421FC8Dd00;
            rwa1XAddr = 0x8736d3b789A6548Cc8fb607dA34Ed860ab626322;
            ctmFallbackAddr = 0x245B3Da2CE81797F7ACA1E37E2Bc6A2026De269b;
            ctmRwa1Map = 0x416D3bE80a79E4F082C92f7fB17b1C13fD91B055;
            ctmRwaDeployer = 0xd661BbE93a05ff2720623d501B54CF5eE72B2A9b;
            ctmRwaFactory = 0xb3aefEa9F49De70C41Ce22Afa321E64393932d21;
            dividendAddr = 0x129Cc2aaD6ea7a6f093D7b08DFda7b0414eDc02B;
            storageManagerAddr = 0x7e0858dE387f30Ebc0bC2F24A35dc4ad9231Cffd;
            sentryManagerAddr = 0x669AB21e6CeA598ea34CD1292680937c3DEF535c;
        } else if (chainId == 97) {
            // BSC TESTNET
            feeToken = 0xDd43fc986a13392dDbC7aeA150b41EfE27b2d0eD;
            feeManager = 0x1736009b39009f1cD6F08791C781317c2Dce4a88;
            gatewayAddr = 0x7a63F6b51c503e9A3354AF8262E8C7129aBDbBEb;
            rwa1XAddr = 0x37C7137Dc6e3DC3c3637bFEd3F6dBFbd43386429;
            ctmFallbackAddr = 0x80969848e69741E47d83db606A2497f816c24773;
            ctmRwa1Map = 0x15702A75071c424BbdC6F69aFeB6F919593B389E;
            ctmRwaDeployer = 0xdB2dC418F97DA871f5aCA6C4D50440FBffa40313;
            ctmRwaFactory = 0x57AAF7641Eb89AC6C55dFa1DEBd7e27b73E75fe9;
            dividendAddr = 0xf9F9cDc9d1e0B967aEFcE60919CAe45026E2A9e6;
            storageManagerAddr = 0x71645806ee984439ADC3352ABB5491Ec03928e63;
            sentryManagerAddr = 0x0d7B0bb763557EA0c7c2d938B5Ae3D5ccbbf8D44;
        } else if (chainId == 5611) {
            // OPBNB TESTNET  Chain 5611
            feeToken = 0x108642B1b2390AC3f54E3B45369B7c660aeFffAD;
            feeManager = 0xe08C7eE637336565511eb3421DAFdf45b860F9bc;
            gatewayAddr = 0x78F81b1AEe019efaAfe58853D96c5E9Ac87be731;
            rwa1XAddr = 0x7743150e59d6A27ec96dDDa07B24131D0122b611;
            ctmFallbackAddr = 0x89330bE16C672D4378B6731a8347D23B0c611de3;
            ctmRwa1Map = 0xF813DdCDd690aCB06ddbFeb395Cf65D18Efe74A7;
            ctmRwaDeployer = 0x093eaCfA2D856516ED71aF96D7DC7C571E6CA2a6;
            ctmRwaFactory = 0xe73Fb620e57F764746Ead61319865F71f6A5CD60;
            dividendAddr = 0xc0DD542BCaC26095A2C83fFb10826CCEf806C07b;
            storageManagerAddr = 0x926DF1f820Af8E3cF53A58C94332eB16BA4cB4b5;
            sentryManagerAddr = 0x3AF6a526DD51C8B08FD54dBB624E042BB3b0a77e;
        }

        gateway = ICTMRWAGateway(gatewayAddr);
        rwa1X = ICTMRWA1X(rwa1XAddr);
        storageManager = ICTMRWA1StorageManager(storageManagerAddr);
        sentryManager = ICTMRWA1SentryManager(sentryManagerAddr);
        ctmFallback = ICTMRWA1XFallback(ctmFallbackAddr);
        dividend = ICTMRWA1Dividend(dividendAddr);
        feeTokenStr = feeToken.toHexString();
    }

    function deployLocal() public returns (uint256) {
        vm.startBroadcast(senderPrivateKey);

        IERC20(feeToken).approve(rwa1XAddr, 1000 * 10 ** ITheiaERC20(feeToken).decimals());

        string[] memory chainIdsStr;

        uint256 IdBack =
            rwa1X.deployAllCTMRWA1X(true, 0, 1, 1, "Closed Roses", "ROSE", 18, "GFLD", chainIdsStr, feeTokenStr);
        console.log(IdBack);

        vm.stopBroadcast();

        return (IdBack);
    }

    function deployRemote(uint256 _ID) public {
        vm.startBroadcast(senderPrivateKey);

        IERC20(feeToken).approve(rwa1XAddr, 1000 * 10 ** ITheiaERC20(feeToken).decimals());

        ( /*bool ok*/ , address ctmRwa1) = ICTMRWAMap(ctmRwa1Map).getTokenContract(_ID, rwaType, version);

        string memory tokenName = ICTMRWA1(ctmRwa1).name();
        string memory symbol = ICTMRWA1(ctmRwa1).symbol();
        uint8 decimals = ICTMRWA1(ctmRwa1).valueDecimals();
        string memory baseURI = ICTMRWA1(ctmRwa1).baseURI();

        // function deployAllCTMRWA1X(
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

        uint256 IdBack =
            rwa1X.deployAllCTMRWA1X(false, _ID, 1, 1, tokenName, symbol, decimals, baseURI, toChainIdsStr, feeTokenStr);

        console.log("IdBack");
        console.log(IdBack);

        vm.stopBroadcast();
    }

    function debugRwaXCall() public {
        string memory newAdminStr = admin.toHexString();
        uint256 ID =
            29_251_130_053_171_396_288_129_669_670_399_520_996_794_011_934_199_132_580_927_820_677_505_894_114_636;

        bool ok = rwa1X.deployCTMRWA1(newAdminStr, ID, "Selqui SQ1", "SQ1", uint8(18), "GFLD", allSlots);

        console.log("RETURNS");
        console.log(ok);
    }

    function createSlots(uint256 _ID, string[] memory chainIdsStr) public {
        vm.startBroadcast(senderPrivateKey);

        IERC20(feeToken).approve(rwa1XAddr, 10_000 * 10 ** ITheiaERC20(feeToken).decimals());

        // function createNewSlot(
        //     uint256 _ID,
        //     uint256 _slot,
        //     string memory _slotName,
        //     string[] memory _toChainIdsStr,
        //     string memory _feeTokenStr
        // ) public returns(bool)

        /*bool ok = */
        rwa1X.createNewSlot(_ID, 0, "Fractional painting", chainIdsStr, feeTokenStr);

        vm.stopBroadcast();
    }

    function getSlots(uint256 _ID, uint256 slotIndx) public view {
        (, address ctmRwa1) = ICTMRWAMap(ctmRwa1Map).getTokenContract(_ID, rwaType, version);

        (uint256[] memory slotNumbers, string[] memory slotNames) = ICTMRWA1(ctmRwa1).getAllSlots();

        console.log("SlotData - slot");
        console.log(slotNumbers[slotIndx]);
        console.log("SlotData - slotName");
        console.log(slotNames[slotIndx]);
    }

    function mintLocalValue(uint256 _ID) public {
        vm.startBroadcast(senderPrivateKey);

        IERC20(feeToken).approve(rwa1XAddr, 10_000 * 10 ** ITheiaERC20(feeToken).decimals());

        uint256 newTokenId = rwa1X.mintNewTokenValueLocal(senderAccount, 0, 0, 1450, _ID, feeTokenStr);
        console.log("newTokenId = ");
        console.log(newTokenId);

        vm.stopBroadcast();
    }

    function activateWhitelist(uint256 _ID) public {
        vm.startBroadcast(senderPrivateKey);

        IERC20(feeToken).approve(sentryManagerAddr, 10_000 * 10 ** ITheiaERC20(feeToken).decimals());

        ( /*bool ok*/ , address sentryAddr) = ICTMRWAMap(ctmRwa1Map).getSentryContract(_ID, 1, 1);
        console.log("Sentry contract");
        console.logAddress(sentryAddr);

        bool wl = ICTMRWA1Sentry(sentryAddr).whitelistSwitch();
        console.log("Before Whitelist, switch = ");
        console.logBool(wl);

        bool whitelistOnly = true;

        ICTMRWA1SentryManager(sentryManagerAddr).setSentryOptions(
            _ID, whitelistOnly, false, false, false, false, false, false, toChainIdsStr, feeTokenStr
        );

        wl = ICTMRWA1Sentry(sentryAddr).whitelistSwitch();
        console.log("After Whitelist, switch = ");
        console.logBool(wl);

        vm.stopBroadcast();
    }

    function addToWhitelist(uint256 _ID, string memory _newAddrStr) public {
        vm.startBroadcast(senderPrivateKey);

        IERC20(feeToken).approve(sentryManagerAddr, 10_000 * 10 ** ITheiaERC20(feeToken).decimals());

        ( /*bool ok*/ , address sentryAddr) = ICTMRWAMap(ctmRwa1Map).getSentryContract(_ID, 1, 1);
        console.log("Sentry contract");
        console.logAddress(sentryAddr);

        bool wl = ICTMRWA1Sentry(sentryAddr).whitelistSwitch();
        console.log("Before Whitelist, switch = ");
        console.logBool(wl);

        // function addWhitelist(
        //     uint256 _ID,
        //     string[] memory _wallets,
        //     bool[] memory _choices,
        //     string[] memory _chainIdsStr,
        //     string memory _feeTokenStr
        // ) public {

        ICTMRWA1SentryManager(sentryManagerAddr).addWhitelist(
            _ID, _stringToArray(_newAddrStr), _boolToArray(true), toChainIdsStr, feeTokenStr
        );

        vm.stopBroadcast();
    }

    function transferValueTokenToAddress(uint256 _ID) public {
        vm.startBroadcast(senderPrivateKey);

        IERC20(feeToken).approve(rwa1XAddr, 10_000 * 10 ** ITheiaERC20(feeToken).decimals());

        (, address ctmRwa1) = ICTMRWAMap(ctmRwa1Map).getTokenContract(_ID, rwaType, version);

        uint256 tokenId = ICTMRWA1(ctmRwa1).tokenOfOwnerByIndex(admin, 0);
        console.log("tokenId");
        console.log(tokenId);
        console.log("with slot =");
        console.log(ICTMRWA1(ctmRwa1).slotOf(tokenId));

        // function transferPartialTokenX(
        //     uint256 _fromTokenId,
        //     string memory _toAddressStr,
        //     string memory _toChainIdStr,
        //     uint256 _value,
        //     uint256 _ID,
        //     string memory _feeTokenStr
        // ) public {

        rwa1X.transferPartialTokenX(tokenId, admin.toHexString(), "84532", 50, _ID, feeTokenStr);
    }

    function transferValueWholeTokenToAddress(uint256 _ID) public {
        vm.startBroadcast(senderPrivateKey);

        IERC20(feeToken).approve(rwa1XAddr, 10_000 * 10 ** ITheiaERC20(feeToken).decimals());

        ( /*bool ok*/ , address ctmRwa1) = ICTMRWAMap(ctmRwa1Map).getTokenContract(_ID, rwaType, version);

        uint256 tokenId = ICTMRWA1(ctmRwa1).tokenOfOwnerByIndex(admin, 2);
        console.log("second tokenId");
        console.log(tokenId);

        console.log("with slot");
        console.log(ICTMRWA1(ctmRwa1).slotOf(tokenId));

        // function transferWholeTokenX(
        //     string memory _toAddressStr,
        //     string memory _toChainIdStr,
        //     uint256 _fromTokenId,
        //     uint256 _ID,
        //     string memory _feeTokenStr
        // ) public {

        rwa1X.transferWholeTokenX(admin.toHexString(), admin.toHexString(), "97", tokenId, _ID, feeTokenStr);

        vm.stopBroadcast();
    }

    function addURI(uint256 _ID, string[] memory chainIdsStr) public {
        vm.startBroadcast(senderPrivateKey);

        IERC20(feeToken).approve(storageManagerAddr, 1000 * 10 ** ITheiaERC20(feeToken).decimals());

        /*(bool ok, address ctmRwa1) = */
        ICTMRWAMap(ctmRwa1Map).getTokenContract(_ID, rwaType, version);

        ( /*bool ok*/ , address stor) = ICTMRWAMap(ctmRwa1Map).getStorageContract(_ID, 1, 1);
        console.log("Storage contract for ID = ");
        console.log(stor);

        // uint256 tokenId = ICTMRWA1(ctmRwa1).tokenOfOwnerByIndex(admin, 0);
        // console.log("first tokenId");
        // console.log(tokenId);

        // uint256 slot = ICTMRWA1(ctmRwa1).slotOf(tokenId);

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

        bool hashExists = ICTMRWA1Storage(stor).existURIHash(junkHash);
        console.log("junkhash exists = ");
        console.log(hashExists);

        vm.stopBroadcast();
    }

    function addURIX(uint256 _ID) public { }

    function lockRwa(uint256 _ID) public {
        vm.startBroadcast(senderPrivateKey);

        IERC20(feeToken).approve(rwa1XAddr, 1000 * 10 ** ITheiaERC20(feeToken).decimals());

        // function changeTokenAdmin(
        //     string memory _newAdminStr,
        //     string[] memory _toChainIdsStr,
        //     uint256 _ID,
        //     string memory _feeTokenStr
        // ) public returns(bool) {

        rwa1X.changeTokenAdmin(address(0).toHexString(), toChainIdsStr, _ID, feeTokenStr);

        vm.stopBroadcast();
    }

    function fundDividends(uint256 _ID, uint256 _slot) public returns (uint256) {
        vm.startBroadcast(senderPrivateKey);

        ( /*bool ok*/ , address divAddr) = ICTMRWAMap(ctmRwa1Map).getDividendContract(_ID, 1, 1);

        IERC20(feeToken).approve(divAddr, 1000 * 10 ** ITheiaERC20(feeToken).decimals());

        ICTMRWA1Dividend(divAddr).setDividendToken(feeToken);

        address token = ICTMRWA1Dividend(divAddr).dividendToken();
        assert(token == address(feeToken));

        uint256 divRate = 2;
        ICTMRWA1Dividend(divAddr).changeDividendRate(_slot, divRate);

        /*uint256 dividendTotal = */
        ICTMRWA1Dividend(divAddr).getTotalDividend();

        uint256 unclaimed = ICTMRWA1Dividend(divAddr).fundDividend();

        vm.stopBroadcast();

        return unclaimed;
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
        // bytes4 sig = bytes4(
        //   abi.encodePacked(
        //     keccak256("deployCTMRWA1(string,uint256,uint256,uint256,string,string,uint8,string,string)")
        //   )
        // );

        bytes memory callData =
            "000000000000000000000000000000000000000000000000000000000000002d000000000000000000000000eef3d3678e1e739c6522eec209bede019779133900000000000000000000000000000000000000000000000000000000000000604df4ec149dcdce7cdc62ac48dd25a01148caedee5aa07c208e0f5ccf45ce9b02000000000000000000000000a85c68e9e09b2e84df95e2ea7325fb27019edf3000000000000000000000000000000000000000000000000000000000000000c00000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000018000000000000000000000000000000000000000000000000000000000000001e0000000000000000000000000000000000000000000000000000000000000000634323136313400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000042307864383034336338366462653233336235363135656230343738666532386465343264353335363061393665376564393664316135323533653139396365663938000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002a307862333763383164366639306131366262643737383838366166343961626562666431616430326337000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000244b82d98342d3e35573faf2c9b90c6356b02678c271a0742392c0db6e7646bd1a56f0af81e0000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000016000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003000000000000000000000000000000000000000000000000000000000000025800000000000000000000000000000000000000000000000000000000000001c00000000000000000000000000000000000000000000000000000000000000220000000000000000000000000000000000000000000000000000000000000002a30786536326162346431313166393638363630633662323138383034366639623962613533633462616500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a53656c717569205351310000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000035351310000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000447464c4400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002a30786532306338663266613865646539386132373136653836353161363666633532643664636661323100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000";

        /*(
      string memory currentAdminStr,
      uint256 ID,
      uint256 _rwaType,
      uint256 _version,
      string memory _tokenName,
      string memory _symbol,
      uint8 _decimals,
      string memory _baseURI,
      string memory _ctmRwa1AddrStr
    ) = */
        abi.decode(callData, (string, uint256, uint256, uint256, string, string, uint8, string, string));

        //address(0x9B0bc1e8267252B2E99fdA8c302b0713Ba3a8202).call(cData);

        vm.stopBroadcast();
    }

    function stringToAddress(string memory str) internal pure returns (address) {
        bytes memory strBytes = bytes(str);
        require(strBytes.length == 42, "CTMRWAMap: Invalid address length");
        bytes memory addrBytes = new bytes(20);

        for (uint256 i = 0; i < 20; i++) {
            addrBytes[i] = bytes1(hexCharToByte(strBytes[2 + i * 2]) * 16 + hexCharToByte(strBytes[3 + i * 2]));
        }

        return address(uint160(bytes20(addrBytes)));
    }

    function _boolToArray(bool _bool) internal pure returns (bool[] memory) {
        bool[] memory boolArray = new bool[](1);
        boolArray[0] = _bool;
        return (boolArray);
    }

    function hexCharToByte(bytes1 char) internal pure returns (uint8) {
        uint8 byteValue = uint8(char);
        if (byteValue >= uint8(bytes1("0")) && byteValue <= uint8(bytes1("9"))) {
            return byteValue - uint8(bytes1("0"));
        } else if (byteValue >= uint8(bytes1("a")) && byteValue <= uint8(bytes1("f"))) {
            return 10 + byteValue - uint8(bytes1("a"));
        } else if (byteValue >= uint8(bytes1("A")) && byteValue <= uint8(bytes1("F"))) {
            return 10 + byteValue - uint8(bytes1("A"));
        }
        revert("Invalid hex character");
    }

    function _stringToArray(string memory _string) internal pure returns (string[] memory) {
        string[] memory strArray = new string[](1);
        strArray[0] = _string;
        return (strArray);
    }

    function decodeXChain() public {
        vm.startBroadcast(senderPrivateKey);

        bytes memory cData = bytes(
            "0x000000000000000000000000b41c8b53ea014188ba6777233e04efddbf4877b100000000000000000000000000000000000000000000000000000000000000a000000000000000000000000000000000000000000000000000000000000000e00000000000000000000000000000000000000000000000000000000000000140000000000000000000000000000000000000000000000000000000000000042000000000000000000000000000000000000000000000000000000000000000023937000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002a3078396230626331653832363732353262326539396664613863333032623037313362613361383230320000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002a43d9ab49f0000000000000000000000000000000000000000000000000000000000000120ba2164ceba74b49a633fe49773785daecf83a8af13eeb22e8c160ca2cfb6246500000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000018000000000000000000000000000000000000000000000000000000000000001c0000000000000000000000000000000000000000000000000000000000000001200000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000240000000000000000000000000000000000000000000000000000000000000002a30786536326162346431313166393638363630633662323138383034366639623962613533633462616500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a53656c717569205351310000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000035351310000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000447464c4400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002a30786532306338663266613865646539386132373136653836353161363666633532643664636661323100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
        );

        /*(
      string memory currentAdminStr,
      uint256 ID,
      uint256 _rwaType,
      uint256 _version,
      string memory _tokenName,
      string memory _symbol,
      uint8 _decimals,
      string memory _baseURI,
      string memory _ctmRwa1AddrStr
    ) = */
        abi.decode(cData, (string, uint256, uint256, uint256, string, string, uint8, string, string));

        //address(0x9B0bc1e8267252B2E99fdA8c302b0713Ba3a8202).call(cData);

        vm.stopBroadcast();
    }
}
