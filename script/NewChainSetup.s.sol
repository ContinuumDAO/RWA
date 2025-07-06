// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.19;

import { Script } from "forge-std/Script.sol";
import "forge-std/console.sol";

import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

import { ICTMRWAGateway } from "../src/crosschain/ICTMRWAGateway.sol";

import { FeeType, IFeeManager } from "../src/managers/IFeeManager.sol";

// import {CTMRWAGateway} from "../flattened/CTMRWAGateway.sol";
// import {FeeManager} from "../flattened/FeeManager.sol";

struct NewChain {
    uint256 chainId;
    address gateway;
    address rwaX;
    address feeManager;
    address storageManager;
    address sentryManager;
    address feeToken;
}

contract NewChainSetup is Script {
    using Strings for *;

    uint256 rwaType = 1;
    uint256 version = 1;

    uint256 chainId = 43_113; // This is the chainId we are processing

    bool COMPLETE = true;

    string[] feeTokensStr;
    uint256[] fees;
    address thisGway;
    address thisRwaX;
    address thisStorageManager;
    address thisSentryManager;
    address thisFeeManager;
    address thisFeeToken;
    string thisFeeTokenStr;

    string[] chainIdContractsStr;
    string[] gwaysStr;
    string[] chainIdRwaXsStr;
    string[] rwaXsStr;
    string[] chainIdStorsStr;
    string[] chainIdSentryStr;
    string[] storageManagersStr;
    string[] sentryManagersStr;

    NewChain[] newchains;

    // struct NewChain {
    //     uint256 chainId;
    //     address gateway;
    //     address rwaX;
    //     address feeManager;
    //     address storageManager;
    //     address sentryManager;
    //     address feeToken;
    // }

    constructor() {
        newchains.push(
            NewChain( // ARB Sepolia  Solidity 0.8.27 *
                421_614,
                0xFa89DD803b8872f991997778d26c74a3Aecd9639,
                0x8bd737F4Ea451911eDF0445ACB1B7efdc9565221,
                0xc28328b1f98076eD5111f1223C647E883f5d6E16,
                0x7aB4De775c88e4aA4c93d0078d8318463fABfb13,
                0xb63F83484b9bdbaD5C574B4c89Badf0359e78854,
                0xbF5356AdE7e5F775659F301b07c4Bc6961044b11
            )
        );
        newchains.push(
            NewChain( // BASE SEPOLIA  Chain 84532 Solidity 0.8.27 *
                84_532,
                0x31F21C6E2605D28e6b204CD323FF58421FC8Dd00,
                0x8736d3b789A6548Cc8fb607dA34Ed860ab626322,
                0x050E942b8ebb0E174A847f343D04EfdC669dFf63,
                0x7e0858dE387f30Ebc0bC2F24A35dc4ad9231Cffd,
                0x669AB21e6CeA598ea34CD1292680937c3DEF535c,
                0x6a4DBC971533Ba36bdc23aD70F5A7a12E064f4ae
            )
        );
        newchains.push(
            NewChain( // POLYGON AMOY  Chain 80002  Solidity 0.8.27 *
                80_002,
                0x66dB3f564807fdc689eC85285981eF464daeB943,
                0x2dA1B2763cF56b9DF5CbBB5A996C7e8836d8C6D8,
                0xA332fc0BF257AFF4aB07267De75d5Eb0c67B71AF,
                0xB3D138F0613CC476faA8c5E2C1a64e90D9d506F3,
                0xf32bc63A511B3B3DeB8fB6AeB3c52eBC0541067e,
                0x6a4DBC971533Ba36bdc23aD70F5A7a12E064f4ae
            )
        );
        newchains.push(
            NewChain( //  SEPOLIA  Chain 11155111 Solidity 0.8.27 *
                11_155_111,
                0x13797c225F8E3645299F17d83365e0f5DB1c1607,
                0x778511925d3243Cf03a2486386ECc363E9Ad6647,
                0x08D0F2f8368CE13206F4839c3ce9151Be93893Bc,
                0x6681DB630eB117050D78E0B89eB5619b35Ea12e8,
                0xF4842C8354fE42e85D6DCDe11CFAda1B80BEAa33,
                0xa4C104db0937F1E886d5C9c9789D6f0e5bfBA75c
            )
        );
        newchains.push(
            NewChain( //  BSC TESTNET Chain 97 Solidity 0.8.27 *
                97,
                0x7a63F6b51c503e9A3354AF8262E8C7129aBDbBEb,
                0x37C7137Dc6e3DC3c3637bFEd3F6dBFbd43386429,
                0x1736009b39009f1cD6F08791C781317c2Dce4a88,
                0x71645806ee984439ADC3352ABB5491Ec03928e63,
                0x0d7B0bb763557EA0c7c2d938B5Ae3D5ccbbf8D44,
                0xDd43fc986a13392dDbC7aeA150b41EfE27b2d0eD
            )
        );
        newchains.push(
            NewChain( // LUMIA TESTNET Chain 1952959480 Solidity 0.8.27 DIDN'T WORK
                1_952_959_480,
                0x5fd63cA6c373Cd35E8e373fb5Fa7830A8783ECED,
                0x62421e1C0110AEbD376e34411c2616C10efF9161,
                0xAFd6479edC4A6354B3531333827c924089ba3880,
                0xE3A405Aa844DA4b6E83eAe852bA471219163CBe0,
                0x4A707B416Ee66aF8b1671209ed48f5dcc00257bF,
                0x6a4DBC971533Ba36bdc23aD70F5A7a12E064f4ae
            )
        );
        newchains.push(
            NewChain( // OPBNB TESTNET  Chain 5611 Solidity 0.8.27 *
                5611,
                0x78F81b1AEe019efaAfe58853D96c5E9Ac87be731,
                0x7743150e59d6A27ec96dDDa07B24131D0122b611,
                0xe08C7eE637336565511eb3421DAFdf45b860F9bc,
                0x926DF1f820Af8E3cF53A58C94332eB16BA4cB4b5,
                0x3AF6a526DD51C8B08FD54dBB624E042BB3b0a77e,
                0x108642B1b2390AC3f54E3B45369B7c660aeFffAD
            )
        );
        newchains.push(
            NewChain( // SONEIUM MINATO Chain 1946 Solidity 0.8.27 *
                1946,
                0xa7441037961E31D4b64Aca57417d7673FEdC8fEC,
                0xf299832e535b9cc50D4002909061c320964D03FC,
                0xF074c733800eC017Da580A5DC95533143CD6abE4,
                0x3f547B04f8CF9552434B7f3a51Fc23247911b797,
                0xc04058E417De221448D4140FC1622dE24121C5e3,
                0x6a4DBC971533Ba36bdc23aD70F5A7a12E064f4ae
            )
        );
        newchains.push(
            NewChain( // SCROLL SEPOLIA   Chain 534351 Solidity 0.8.27 *
                534_351,
                0x1944F7fdd330Af7b0e7C08349591213E35ed5948,
                0x1249d751e6a0b7b11b9e55CBF8bC7d397AC3c083,
                0x93637D7068CEebC6cCDCB230E3AE65436666fe15,
                0xb406b937C12E03d676727Fc1Bb686279EeDbc178,
                0x66dc636132fb9b7f6ed858928B65864D3fd0ea67,
                0xe536Bf33585aa6bb528627Ed7Dc4D49009dafC58
            )
        );
        newchains.push(
            NewChain( // HOLESKY Chain 17000 Solidity 0.8.27 *
                17_000,
                0x1EeBC47AaE37F2EA390869efe60db5a2cF2c9d80,
                0x9372CD1287E0bB6337802D80DFF342348c85fd78,
                0x1371eC7be82175C768Adc2E9E9AE5018863D5151,
                0xe148fbc6C35B6cecC50d18Ebf69959a6A989cB7C,
                0x208Ec1Ca3B07a50151c5741bc0E05C61beddad90,
                0x108642B1b2390AC3f54E3B45369B7c660aeFffAD
            )
        );
        newchains.push(
            NewChain( // MANTLE SEPOLIA Chain 5003 solidity 0.8.22 *
                5003,
                0x9DC772b55e95A630031EBe431706D105af01Cf03,
                0xad49cabD336f943a9c350b9ED60680c54fa2c3d1,
                0x358498985E6ac7CA73F5110b415525aE04CB8313,
                0xeDe597aA066e6d7bc84BF586c494735DEB7DDe9F,
                0xDa61b02D88D2c857dA9d2da435152b08F03E2836,
                0x6a4DBC971533Ba36bdc23aD70F5A7a12E064f4ae
            )
        );
        newchains.push(
            NewChain( // BLAST SEPOLIA Chain 168587773 Solidity 0.8.27 *
                168_587_773,
                0xEa4A06cB68ABa869e6BF98Edc4BdbC731d2D82e3,
                0x9A0F81de582Ce9194FEADC6CCefaf9eA70451616,
                0x66dc636132fb9b7f6ed858928B65864D3fd0ea67,
                0x8D4EEe23A687b304E94eee3211f3058A60744502,
                0x0156a74FD9432446030f47f7c55f4d1FbfdF5E9a,
                0x5d5408e949594E535d0c3d533761Cb044E11b664
            )
        );
        newchains.push(
            NewChain( //  REDBELLY TESTNET Chain 153 Solidity 0.8.22 *
                153,
                0x24A74106195Acd7e3E0a8cc17fd44761CC32474a,
                0x41388451eca7344136004D29a813dCEe49577B44,
                0xa328Fd0f353afc134f8f6Bdb51082D85395d7200,
                0x74972e7Ff5561bD902E3Ec3dDD5A22653088cA6f,
                0x5930640c1572bCD396eB410f62a6975ab9b8A148,
                0xe536Bf33585aa6bb528627Ed7Dc4D49009dafC58
            )
        );
        newchains.push(
            NewChain( //  OPTIMISM SEPOLIA Chain 11155420 Solidity 0.8.27 *
                11_155_420,
                0xf74b4051a565399B114a0fd6a674eCAB864aE186,
                0xb9de1C03EEa7546D9dB1fa6fc19Dfa7443f0AEDE,
                0x6Da387268C610E7276ee20255252819e923C754e,
                0x6429D598684EfBe5a5fF70451e7B2C501c85e254,
                0xA31AC55003cde3eF9CE9c576a691d0F41586c20b,
                0x6a4DBC971533Ba36bdc23aD70F5A7a12E064f4ae
            )
        );
        newchains.push(
            NewChain( //  AVALANCHE FUJI Chain 43113 Solidity 0.8.27 *
                43_113,
                0x8176186fa521E54f12Dd8011EB6729003E3D3Fe0,
                0x5e0D85dFa2827cD3065aB2D4af93E58DC82c5e96,
                0x0cB36959A63c02C004566829D11e9EAb4dA3aCE0,
                0xAE66C08b9d76EeCaA74314c60f3305D43707ACc9,
                0xf9EDcE2638da660F51Ee08220a1a5A32fAB61d61,
                0x15A1ED0815ECeD97E46967179846c72BA21DABAd
            )
        );
        // newchains.push(NewChain(  // LINEA SEPOLIA Chain 59141
        //     59141,
        //     ,
        //     ,
        //     ,
        //     ,
        //     ,
        //     0x6654D956A4487A26dF1186b01B689c26939544fC
        // ));
        // newchains.push(NewChain(  // CONFLUX ESPACE  Chain 71
        //     71,

        //     0x6a4DBC971533Ba36bdc23aD70F5A7a12E064f4ae
        // ));
        newchains.push(
            NewChain( // CORE Testnet Chain 1115  With Solidity 0.8.22 *
                1115,
                0xc0b8f765907ab09106010190Ee991aAae01F88Ba,
                0xC981D340AC02B717B52DC249c46B1942e20EDBAD,
                0x87a0c3e97B52A42edBB513ad9701F6641B62afe2,
                0x2809808fC225FDAF859826cE7499a56B106D8870,
                0xEa37aEfe52E5327528F71171844474CF77507770,
                0x6a4DBC971533Ba36bdc23aD70F5A7a12E064f4ae
            )
        );
        // newchains.push(NewChain(  // MORPH HOLESKY  Chain 2810
        //     2810,
        //     ,
        //     ,
        //     ,
        //     ,
        //     ,
        //     0x6a4DBC971533Ba36bdc23aD70F5A7a12E064f4ae
        // ));
        newchains.push(
            NewChain( // BITLAYER TESTNET Chain 200810 *
                200_810,
                0xe08C7eE637336565511eb3421DAFdf45b860F9bc,
                0x78F81b1AEe019efaAfe58853D96c5E9Ac87be731,
                0xb849bF0a5ca08f1e6EA792bDC06ff2317bb2fB90,
                0x0F607AF04457E86eC349FbEbb6e23B0A6A0D067F,
                0x10A04ad4a73C8bb00Ee5A29B27d11eeE85390306,
                0x6a4DBC971533Ba36bdc23aD70F5A7a12E064f4ae
            )
        );
        // newchains.push(NewChain(  // LUKSO TESTNET  Chain 4201
        //     4201,
        //     ,
        //     ,
        //     ,
        //     ,
        //     ,
        //     0xC92291fbBe0711b6B34928cB1b09aba1f737DEfd

        // ));
        // newchains.push(NewChain(  // PLUME TESTNET Chain 161221135
        //     161221135,

        //     0x6a4DBC971533Ba36bdc23aD70F5A7a12E064f4ae
        // ));
        // newchains.push(NewChain(  // VANGUARD Chain 78600
        //     78600,
        //     ,
        //     ,
        //     ,
        //     ,
        //     ,
        //     0x6654D956A4487A26dF1186b01B689c26939544fC
        // ));
        // newchains.push(NewChain(  // U2U NEBULAS TESTNET Chain 2484
        //     2484,
        //     ,
        //     ,
        //     ,
        //     ,
        //     ,
        //     0x6a4DBC971533Ba36bdc23aD70F5A7a12E064f4ae
        // ));
        // newchains.push(NewChain(  // SONIC TESTNET  Chain 64165
        //     64165,
        //     ,
        //     ,
        //     ,
        //     ,
        //     ,
        //     0x1E411051A586EDB12282c08A933FB8C7699FEFB2

        // ));
        // newchains.push(NewChain(  // FIRE THUNDER  Chain 997
        //     997,
        //     ,
        //     ,
        //     ,
        //     ,
        //     ,
        //     0x6a4DBC971533Ba36bdc23aD70F5A7a12E064f4ae

        // ));
        // newchains.push(NewChain(  // HUMANODE TESTNET ISRAFEL  Chain 14853
        //     14853,
        //     ,
        //     ,
        //     ,
        //     ,
        //     ,
        //     0x6dD69414E074575c45D5330d2707CAf80303a85B

        // ));
        // newchains.push(NewChain(   // CRONOS TESTNET   Chain 338
        //     338,
        //     ,
        //     ,
        //     ,
        //     ,
        //     ,
        //     0xf6d2060494cD08e776D22a47E67d485a33C8c5d2

        // ));
        // newchains.push(NewChain(  //  MANTA PACIFIC Chain 3441006 Solidity 0.8.27
        //     3441006,
        //     ,
        //     ,
        //     ,
        //     ,
        //     ,
        //     0x20cEfCf72622156987f82E1B54E94Dbc0848De9C
        // ));
    }

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        console.log("Wallet of deployer");
        console.log(deployer);

        bool ok;

        vm.startBroadcast(deployerPrivateKey);

        uint256 len = newchains.length;

        for (uint256 i = 0; i < len; i++) {
            if (newchains[i].chainId == chainId) {
                string memory chainIdStr = chainId.toString();
                thisGway = newchains[i].gateway;
                thisRwaX = newchains[i].rwaX;
                string memory rwaXStr = thisRwaX.toHexString();
                thisStorageManager = newchains[i].storageManager;
                thisSentryManager = newchains[i].sentryManager;
                string memory storageManagerStr = thisStorageManager.toHexString();
                string memory sentryManagerStr = thisSentryManager.toHexString();
                thisFeeManager = newchains[i].feeManager;
                thisFeeToken = newchains[i].feeToken;
                thisFeeTokenStr = thisFeeToken.toHexString();

                if (COMPLETE) {
                    if (IFeeManager(thisFeeManager).getFeeTokenList().length == 0) {
                        // Allow just one fee token for now
                        ok = IFeeManager(thisFeeManager).addFeeToken(thisFeeTokenStr);
                        require(ok, "NewChainSetup: Could not add fee token");
                    }

                    ok = IFeeManager(thisFeeManager).setFeeMultiplier(FeeType.ADMIN, 2);
                    require(ok, "NewChainSetup: Could not set fee multiplier");
                    ok = IFeeManager(thisFeeManager).setFeeMultiplier(FeeType.DEPLOY, 10);
                    require(ok, "NewChainSetup: Could not set fee multiplier");
                    ok = IFeeManager(thisFeeManager).setFeeMultiplier(FeeType.TX, 1);
                    require(ok, "NewChainSetup: Could not set fee multiplier");
                    ok = IFeeManager(thisFeeManager).setFeeMultiplier(FeeType.MINT, 4);
                    require(ok, "NewChainSetup: Could not set fee multiplier");
                    ok = IFeeManager(thisFeeManager).setFeeMultiplier(FeeType.BURN, 4);
                    require(ok, "NewChainSetup: Could not set fee multiplier");
                    ok = IFeeManager(thisFeeManager).setFeeMultiplier(FeeType.ISSUER, 4);
                    require(ok, "NewChainSetup: Could not set fee multiplier");
                    ok = IFeeManager(thisFeeManager).setFeeMultiplier(FeeType.PROVENANCE, 8);
                    require(ok, "NewChainSetup: Could not set fee multiplier");
                    ok = IFeeManager(thisFeeManager).setFeeMultiplier(FeeType.VALUATION, 4);
                    require(ok, "NewChainSetup: Could not set fee multiplier");
                    ok = IFeeManager(thisFeeManager).setFeeMultiplier(FeeType.PROSPECTUS, 10);
                    require(ok, "NewChainSetup: Could not set fee multiplier");
                    ok = IFeeManager(thisFeeManager).setFeeMultiplier(FeeType.RATING, 8);
                    require(ok, "NewChainSetup: Could not set fee multiplier");
                    ok = IFeeManager(thisFeeManager).setFeeMultiplier(FeeType.LEGAL, 8);
                    require(ok, "NewChainSetup: Could not set fee multiplier");
                    ok = IFeeManager(thisFeeManager).setFeeMultiplier(FeeType.FINANCIAL, 8);
                    require(ok, "NewChainSetup: Could not set fee multiplier");
                    ok = IFeeManager(thisFeeManager).setFeeMultiplier(FeeType.LICENSE, 20);
                    require(ok, "NewChainSetup: Could not set fee multiplier");
                    ok = IFeeManager(thisFeeManager).setFeeMultiplier(FeeType.DUEDILIGENCE, 8);
                    require(ok, "NewChainSetup: Could not set fee multiplier");
                    ok = IFeeManager(thisFeeManager).setFeeMultiplier(FeeType.NOTICE, 4);
                    require(ok, "NewChainSetup: Could not set fee multiplier");
                    ok = IFeeManager(thisFeeManager).setFeeMultiplier(FeeType.DIVIDEND, 4);
                    require(ok, "NewChainSetup: Could not set fee multiplier");
                    ok = IFeeManager(thisFeeManager).setFeeMultiplier(FeeType.REDEMPTION, 4);
                    require(ok, "NewChainSetup: Could not set fee multiplier");
                    ok = IFeeManager(thisFeeManager).setFeeMultiplier(FeeType.WHOCANINVEST, 4);
                    require(ok, "NewChainSetup: Could not set fee multiplier");
                    ok = IFeeManager(thisFeeManager).setFeeMultiplier(FeeType.IMAGE, 2);
                    require(ok, "NewChainSetup: Could not set fee multiplier");
                    ok = IFeeManager(thisFeeManager).setFeeMultiplier(FeeType.VIDEO, 20);
                    require(ok, "NewChainSetup: Could not set fee multiplier");
                    ok = IFeeManager(thisFeeManager).setFeeMultiplier(FeeType.ICON, 2);
                    require(ok, "NewChainSetup: Could not set fee multiplier");
                    ok = IFeeManager(thisFeeManager).setFeeMultiplier(FeeType.WHITELIST, 1);
                    require(ok, "NewChainSetup: Could not set fee multiplier");
                    ok = IFeeManager(thisFeeManager).setFeeMultiplier(FeeType.COUNTRY, 1);
                    require(ok, "NewChainSetup: Could not set fee multiplier");
                    ok = IFeeManager(thisFeeManager).setFeeMultiplier(FeeType.KYC, 5);
                    require(ok, "NewChainSetup: Could not set fee multiplier");
                    ok = IFeeManager(thisFeeManager).setFeeMultiplier(FeeType.ERC20, 5);
                    require(ok, "NewChainSetup: Could not set fee multiplier");
                    ok = IFeeManager(thisFeeManager).setFeeMultiplier(FeeType.DEPLOYINVEST, 5);
                    require(ok, "NewChainSetup: Could not set fee multiplier");
                    ok = IFeeManager(thisFeeManager).setFeeMultiplier(FeeType.OFFERING, 5);
                    require(ok, "NewChainSetup: Could not set fee multiplier");
                    ok = IFeeManager(thisFeeManager).setFeeMultiplier(FeeType.INVEST, 5);
                    require(ok, "NewChainSetup: Could not set fee multiplier");

                    if (
                        !stringsEqual(
                            _toLower(ICTMRWAGateway(thisGway).getChainContract(chainIdStr)), thisGway.toHexString()
                        )
                    ) {
                        chainIdContractsStr.push(chainIdStr);
                        gwaysStr.push(thisGway.toHexString());
                    }

                    (, string memory rwax) = ICTMRWAGateway(thisGway).getAttachedRWAX(rwaType, version, chainIdStr);
                    if (!stringsEqual(rwax, _toLower(rwaXStr))) {
                        chainIdRwaXsStr.push(chainIdStr);
                        rwaXsStr.push(rwaXStr);
                    }

                    (, string memory stor) =
                        ICTMRWAGateway(thisGway).getAttachedStorageManager(rwaType, version, chainIdStr);
                    if (!stringsEqual(stor, _toLower(storageManagerStr))) {
                        chainIdStorsStr.push(chainIdStr);
                        storageManagersStr.push(storageManagerStr);
                    }

                    (, string memory sentry) =
                        ICTMRWAGateway(thisGway).getAttachedSentryManager(rwaType, version, chainIdStr);
                    if (!stringsEqual(sentry, _toLower(sentryManagerStr))) {
                        chainIdSentryStr.push(chainIdStr);
                        sentryManagersStr.push(sentryManagerStr);
                    }
                }
            }
        }

        console.log("thisGway");
        console.log(thisGway);
        console.log("thisRwaX");
        console.log(thisRwaX);
        console.log("thisStorageManager");
        console.log(thisStorageManager);
        console.log("thisSentryManager");
        console.log(thisSentryManager);
        console.log("thisFeeManager");
        console.log(thisFeeManager);

        // thisGway = 0xAc71dCF325724594525cc05552beE7D6550a80fD;
        // thisRwaX = 0xEb28C8e7Cc2d8a8d361Cb41EC0937ac11c0c0A1F;
        // thisStorageManager = 0xF1a79c24efF78FfFfbd4f8Df0Ce31aDEc284b9Cf;
        // thisSentryManager = 0x048A5cefCDF0faeB734bc4A941E0de44d8c49f55;
        // thisFeeManager = 0x8393181277c8a85ec0468B3f1ee61Bbfd78E62b4;
        // thisFeeToken = 0xe536Bf33585aa6bb528627Ed7Dc4D49009dafC58;
        // thisFeeTokenStr = thisFeeToken.toHexString();

        // revert("debug exit");

        for (uint256 i = 0; i < len; i++) {
            //
            address gway = newchains[i].gateway;
            string memory chainIdStr = newchains[i].chainId.toString();
            console.log("Processing chainIdStr");
            console.log(chainIdStr);
            string memory gwayStr = gway.toHexString();
            address rwaX = newchains[i].rwaX;
            string memory rwaXStr = rwaX.toHexString();
            address storageManager = newchains[i].storageManager;
            string memory storageManagerStr = storageManager.toHexString();
            address sentryManager = newchains[i].sentryManager;
            string memory sentryManagerStr = sentryManager.toHexString();
            // address feeManager = newchains[i].feeManager;
            // address feeToken = newchains[i].feeToken;
            // string memory feeTokenStr = feeToken.toHexString();

            if (newchains[i].chainId == chainId) {
                // string memory storedContract = ICTMRWAGateway(thisGway).getChainContract(chainIdStr);
                require(
                    stringsEqual(
                        _toLower(gway.toHexString()),
                        ICTMRWAGateway(gway).getChainContract(newchains[i].chainId.toString())
                    ),
                    "NewChainSetup: incorrect chainContract address stored"
                );
            } else {
                console.log("Adding");
                console.log(newchains[i].chainId);

                if (!stringsEqual(_toLower(ICTMRWAGateway(thisGway).getChainContract(chainIdStr)), gwayStr)) {
                    chainIdContractsStr.push(chainIdStr);
                    gwaysStr.push(gwayStr);
                    // ok = ICTMRWAGateway(thisGway).addChainContract(_stringToArray(chainIdStr),
                    // _stringToArray(gwayStr));
                }

                (, string memory rwax) = ICTMRWAGateway(thisGway).getAttachedRWAX(rwaType, version, chainIdStr);
                if (!stringsEqual(rwax, _toLower(rwaXStr))) {
                    chainIdRwaXsStr.push(chainIdStr);
                    rwaXsStr.push(rwaXStr);
                    // ok = ICTMRWAGateway(thisGway).attachRWAX(rwaType, version, _stringToArray(chainIdStr),
                    // _stringToArray(rwaXStr));
                }

                (, string memory stor) =
                    ICTMRWAGateway(thisGway).getAttachedStorageManager(rwaType, version, chainIdStr);
                if (!stringsEqual(stor, _toLower(storageManagerStr))) {
                    chainIdStorsStr.push(chainIdStr);
                    storageManagersStr.push(storageManagerStr);
                    // ok = ICTMRWAGateway(thisGway).attachStorageManager(rwaType, version, _stringToArray(chainIdStr),
                    // _stringToArray(storageManagerStr));
                }

                (, string memory sentry) =
                    ICTMRWAGateway(thisGway).getAttachedSentryManager(rwaType, version, chainIdStr);
                if (!stringsEqual(sentry, _toLower(sentryManagerStr))) {
                    chainIdSentryStr.push(chainIdStr);
                    sentryManagersStr.push(sentryManagerStr);
                    // ok = ICTMRWAGateway(thisGway).attachSentryManager(rwaType, version, _stringToArray(chainIdStr),
                    // _stringToArray(sentryManagerStr));
                }
            }

            if (COMPLETE) {
                IFeeManager(thisFeeManager).addFeeToken(
                    chainIdStr, _stringToArray(thisFeeTokenStr), _uint256ToArray(100)
                );
            }
        }

        ok = ICTMRWAGateway(thisGway).addChainContract(chainIdContractsStr, gwaysStr);
        ok = ICTMRWAGateway(thisGway).attachRWAX(rwaType, version, chainIdRwaXsStr, rwaXsStr);
        ok = ICTMRWAGateway(thisGway).attachStorageManager(rwaType, version, chainIdStorsStr, storageManagersStr);
        ok = ICTMRWAGateway(thisGway).attachSentryManager(rwaType, version, chainIdSentryStr, sentryManagersStr);

        vm.stopBroadcast();
    }

    function cID() external view returns (uint256) {
        return block.chainid;
    }

    function strToUint(string memory _str) external pure returns (uint256 res, bool err) {
        if (bytes(_str).length == 0) {
            return (0, true);
        }
        for (uint256 i = 0; i < bytes(_str).length; i++) {
            if ((uint8(bytes(_str)[i]) - 48) < 0 || (uint8(bytes(_str)[i]) - 48) > 9) {
                return (0, false);
            }
            res += (uint8(bytes(_str)[i]) - 48) * 10 ** (bytes(_str).length - i - 1);
        }

        return (res, true);
    }

    function stringToAddress(string memory str) internal pure returns (address) {
        bytes memory strBytes = bytes(str);
        require(strBytes.length == 42, "CTMRWA1X: Invalid address length");
        bytes memory addrBytes = new bytes(20);

        for (uint256 i = 0; i < 20; i++) {
            addrBytes[i] = bytes1(hexCharToByte(strBytes[2 + i * 2]) * 16 + hexCharToByte(strBytes[3 + i * 2]));
        }

        return address(uint160(bytes20(addrBytes)));
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

    function stringsEqual(string memory a, string memory b) internal pure returns (bool) {
        bytes32 ka = keccak256(abi.encode(a));
        bytes32 kb = keccak256(abi.encode(b));
        return (ka == kb);
    }

    function _toLower(string memory str) internal pure returns (string memory) {
        bytes memory bStr = bytes(str);
        bytes memory bLower = new bytes(bStr.length);
        for (uint256 i = 0; i < bStr.length; i++) {
            // Uppercase character...
            if ((uint8(bStr[i]) >= 65) && (uint8(bStr[i]) <= 90)) {
                // So we add 32 to make it lowercase
                bLower[i] = bytes1(uint8(bStr[i]) + 32);
            } else {
                bLower[i] = bStr[i];
            }
        }
        return string(bLower);
    }

    function _stringToArray(string memory _string) internal pure returns (string[] memory) {
        string[] memory strArray = new string[](1);
        strArray[0] = _string;
        return (strArray);
    }

    function _uint256ToArray(uint256 _myUint256) internal pure returns (uint256[] memory) {
        uint256[] memory uintArray = new uint256[](1);
        uintArray[0] = _myUint256;
        return (uintArray);
    }
}
