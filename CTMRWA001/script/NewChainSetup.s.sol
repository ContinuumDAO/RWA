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
    address feeToken;
}


contract NewChainSetup is Script {
    using Strings for *;

    uint256 rwaType = 1;
    uint256 version = 1;

    uint256 chainId = 4201;   // This is the chainId we are processing

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
        newchains.push(NewChain(    // ARB Sepolia *
            421614,
            0x15E8BBa5f3F0118C357E74D86a65f46977D58053,
            0xb866653913aE6aCb12e9aa33D6d45651cDFEB78B,
            0x8e1fc60c90Aff208023735c9eE54Ff6315D13182,
            0x3804bD72656E086166f2d64E7C78f2F9CD2735b8,
            0x9cEB3f7ddcEe31eB8aC66D51838999709B1d4e4F,
            0xbF5356AdE7e5F775659F301b07c4Bc6961044b11
        ));
        newchains.push(NewChain(   // POLYGON AMOY  Chain 80002 *
            80002,
            0x6f013Ad0b507590dcB26E674199ba99d613e9dFD,
            0x68CE4a4a6F6EbF5Ba25791Ea5385080e57A5BE82,
            0x5Cc4E3125B75284246Ffd677eC53553f1d78b825,
            0xE5b921BD326efa802e3dc20Fb3502559f59fd8AA,
            0xe5f1354ad39be96a3d2566b27dBc12Dd1Af1b9dB,
            0x6a4DBC971533Ba36bdc23aD70F5A7a12E064f4ae
        ));
        newchains.push(NewChain(  // BASE SEPOLIA  Chain 84532
            84532,
            0x808490311dEbe8818cdfFe1FAae436cb84fAa906,
            0xB3672d1bBd1bADbbBf6b327C2ad7785534aF2E7F,
            0xD3ee2E923723D2e634219797512bD768d5973020,
            0x1481875CA0EcD0ACdEb79d3d57FB76EAE726d128,
            0x3bFF2A879a92e2125cDe895FA20BA3A4AEb2D4D7,
            0x6a4DBC971533Ba36bdc23aD70F5A7a12E064f4ae
        ));
        newchains.push(NewChain(  // LINEA SEPOLIA Chain 59141
            59141,
            0x5Bd9BE690c9DA2Afb3E50eC6B73ae6EaA66d5d30,
            0xdfa830314001a2dc761c0564D61962a57b7A5B89,
            0x6a61BDf8faaE1614701674dB133A0bd1414E88Dc,
            0x73B4143b7cd9617F9f29452f268479Bd513e3d23,
            0x5dA80743b6FD7FEB2Bf7207aBe20E57E204e2B5b,
            0x6654D956A4487A26dF1186b01B689c26939544fC
        ));
        // newchains.push(NewChain(  // CONFLUX ESPACE  Chain 71
        //     71,

        //     0x6a4DBC971533Ba36bdc23aD70F5A7a12E064f4ae
        // ));
        newchains.push(NewChain(  // CORE Testnet Chain 1115  With Solidity 0.8.22
            1115,
            0xF3A991cB19949cB6aBD9E416F0408C648B6c36Fa,
            0xb5d1f61f6B9f0CA2B89eb9D693e8cD737076846A,
            0x5b4d2c1b2e918fF1b0DE85803F5A737E5f816eCb,
            0xf9229aCEba228fdbb757A637EeeBadB46FDb617e,
            0x971C8BDd123aA0c864480419f378fB135f7CaBC1,
            0x6a4DBC971533Ba36bdc23aD70F5A7a12E064f4ae
        ));
        newchains.push(NewChain(  // HOLESKY Chain 17000
            17000,
            0xeFbd6990A5C4ABFA30b91409aA3d9A0e7C8Bb77b,
            0x43B8494f3C645c8CBA2B0D13C7Bd948D9877620c,
            0xd13779b354c3C72c9B438ABe7Db3086098778A7a,
            0xe5AF1a54B2b8cA3091edD229329B60A82b7A04E8,
            0xDbBbbbd746F539d8C82aea9d4F776e5BA0F4e1a1,
            0x108642B1b2390AC3f54E3B45369B7c660aeFffAD
        ));
        newchains.push(NewChain(  // MORPH HOLESKY  Chain 2810
            2810,
            0x25903bEA74d4fbE43B7D30703D2A740841DfB7b2,
            0x45cddE4bdAbC97b3ec02B1271432ceeBc04d4c53,
            0x9E2F5D1228b02C2FbF3168Db1162e7461574eBB9,
            0x6F0DDf81d8145301058e37CC51A485Ae6b44BCF9,
            0xDFe447a7F6780dD40D3eA4CF3F132c1F3b50BfF7,
            0x6a4DBC971533Ba36bdc23aD70F5A7a12E064f4ae
        ));
        newchains.push(NewChain(  // BLAST SEPOLIA Chain 168587773
            168587773,
            0x4218C42503FBB0CC65cbDf507B7ce64F0C52BC32,
            0xC230C289328a86d2daC10Db25E91f516aD7D0D3f,
            0x610D47b471Ca1BA509F752AFAD8E391664bF4deC,
            0x3dc0e90bB56DE095321c48aadF0D0c29b47b837a,
            0x3FfbC9f4C2Bb8fB74Ab712d3E01c695Ce2329b1D,
            0x5d5408e949594E535d0c3d533761Cb044E11b664
        ));
        newchains.push(NewChain(  // BITLAYER TESTNET Chain 200810
            200810,
            0x5Fb1394608Ce2Ef7092A642d6c5D3b2325300bFD,
            0xe5AF1a54B2b8cA3091edD229329B60A82b7A04E8,
            0x66b719C489193594c617801e67119959CD15b63A,
            0xC5E7f5e1BABBF45e3F1e0764B48736C19A122383,
            0x0A576aB9704438ef4eF94C50c6bD0F13eFE12b06,
            0x6a4DBC971533Ba36bdc23aD70F5A7a12E064f4ae
        ));
        newchains.push(NewChain(  // SCROLL SEPOLIA   Chain 534351
            534351,
            0xD55F76833388137FB1ECFc0dE1e6982716A19640,
            0x9E2F5D1228b02C2FbF3168Db1162e7461574eBB9,
            0x7ED4D0234E6c0F6704463E9A62A33AB7B7846A09,
            0x0A0C882706544F37377e9bb7976E0805cd29a94F,
            0x6F0DDf81d8145301058e37CC51A485Ae6b44BCF9,
            0xe536Bf33585aa6bb528627Ed7Dc4D49009dafC58
        ));
        newchains.push(NewChain(  // MANTLE SEPOLIA Chain 5003 solidity 0.8.22
            5003,
            0x00d850114aC97754eCf9611Bb0dA99BbFC21BC4C,
            0x69a68786C9A1088f7121633b5c390F3007EAEBbe,
            0x0156a74FD9432446030f47f7c55f4d1FbfdF5E9a,
            0xA365a4Ea68929C6297ef32Da2c21BDBfd1d354f0,
            0x6F86E2fEeC756591A65D10158aca89DEc2e5eB51,
            0x6a4DBC971533Ba36bdc23aD70F5A7a12E064f4ae
        ));
        // newchains.push(NewChain(  // LUKSO TESTNET  Chain 4201
        //     4201,
        //     0xDbBbbbd746F539d8C82aea9d4F776e5BA0F4e1a1,
        //     0x766061Cd28592Fd2503cAA3E4772C1215192cD3d,
        //     0xe96270a4DeFb602d8C7E5aDB7f090EAC5291A641,
        //     0xFA633c1aB4Ed7d8aa032f50219c6065189D13bd0,
        //     0xd6374b3842652fc5Fc963c069ce05f1A48f965ce,
        //     0xC92291fbBe0711b6B34928cB1b09aba1f737DEfd
            
        // ));
        // newchains.push(NewChain(  // LUMIA TESTNET Chain 1952959480 Solidity 0.8.22
        //     1952959480,
        //     0x0632cB03145500fe2E9CF44f59FC020910Dd79aD,
        //     0xce2dAd6e634a28e75C6dD96AE1fd3624AB20AA2f,
        //     0x1a18668aFa9f8E5Eb1fD0616926311e854723b5a,
        //     0x49653d473B80Bed6e159D8Be4710b5d31875fBee,
        //     0x81aA882dcCB2772ce63CF6b54C5e1B6b4aDa34eF,
        //     0x6a4DBC971533Ba36bdc23aD70F5A7a12E064f4ae
        // ));
        // newchains.push(NewChain(  // PLUME TESTNET Chain 161221135
        //     161221135,
            
        //     0x6a4DBC971533Ba36bdc23aD70F5A7a12E064f4ae
        // ));
        newchains.push(NewChain(  // VANGUARD Chain 78600
            78600,
            0xD523b4f68c015B472724c24e127FF1f51EeE0fbf,
            0x4dDcab55e1eae426a98e85f43896592Ad1dB0f84,
            0x8d494f8B762005cCA5BDEBb770Af3bf51E730305,
            0x89c8CC177f04CC8209B93e42d81a780c3A685dD4,
            0xDD15811D29A330AD2850A994f6AAEcFfA68A5c12,
            0x6654D956A4487A26dF1186b01B689c26939544fC
        ));
        newchains.push(NewChain(  // U2U NEBULAS TESTNET Chain 2484
            2484,
            0x3CB56e6E5917a2a8924BC2A5C1f0ecc90b585e74,
            0x1F652e2D8A9FCa346A0F45D59a67FB998999e454,
            0xa3bae05aA45bcC739258b124FACE332043D3B1dA,
            0xA33cfD901896C775c5a6d62e94081b4Fdd1B09BC, 
            0x41543A4C6423E2546FC58AC63117B5692D68c323,
            0x6a4DBC971533Ba36bdc23aD70F5A7a12E064f4ae
        ));
        newchains.push(NewChain(  // SONEIUM MINATO Chain 1946
            1946,
            0x654Ad7D43857b354079caD2d668bFA1eF2a01Fcf,
            0x610D47b471Ca1BA509F752AFAD8E391664bF4deC,
            0xf7548cB35188aa7DaC8423fAA2ACe3855634e40C,
            0x80f1BB2DF520e3e091C79AebE81f46136A8fBCb5,
            0x3dc0e90bB56DE095321c48aadF0D0c29b47b837a,
            0x6a4DBC971533Ba36bdc23aD70F5A7a12E064f4ae
        ));
        newchains.push(NewChain(  // OPBNB TESTNET  Chain 5611
            5611,
            0x6F0DDf81d8145301058e37CC51A485Ae6b44BCF9,
            0xCa19ddc73718512B968B2cb838b1408885D74A05,
            0x4596F5bFba6cB5ebdb23a0d118434b43Ad9Be3B7,
            0xd13779b354c3C72c9B438ABe7Db3086098778A7a,
            0x43B8494f3C645c8CBA2B0D13C7Bd948D9877620c,
            0x108642B1b2390AC3f54E3B45369B7c660aeFffAD
        ));
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
        newchains.push(NewChain(  //  BSC TESTNET Chain 97
            97,
            0x4146FE54Fd379fd095C227ea012a50387674766D,
            0xC5A13F8750f362AA8e8Ace59f261268295923190,
            0x20D5CdE9700144ED0Da22754D89f3379916c99Fa,
            0x188af80a2ea153bc43dD448434d753C05D3C93f3,
            0x39446dF8f82282Aebcb0EdDc61D6B716C188Ee85,
            0xDd43fc986a13392dDbC7aeA150b41EfE27b2d0eD
        ));
        newchains.push(NewChain(  //  SEPOLIA  Chain 11155111
            11155111,
            0xBB348A6f2227E56a210097f808025Ca3635BEE1d,
            0x3D9aD7fb378BCeb18C47e01AF6e60679B6CAa8A9,
            0x06c067f00F946ecaA23C5b253fFf4B91a5869F10,
            0xDC44569f688a91ba3517C292de75E30EA284eeA0,
            0x636D43798340603707c936c1A93597Dc44Effbee,
            0xa4C104db0937F1E886d5C9c9789D6f0e5bfBA75c
        ));
        newchains.push(NewChain(  //  OPTIMISM SEPOLIA Chain 11155420
            11155420,
            0xcDEcbA8e8a537823733238225df54Cc212d681Cd,
            0x8393181277c8a85ec0468B3f1ee61Bbfd78E62b4,
            0x73943Ec95AaFBb4DD073b11F5c9701E5Bc3708A6,
            0xc3dC6a3EdC40460BAa684F45E9e377B7e42009b1,
            0xF1a79c24efF78FfFfbd4f8Df0Ce31aDEc284b9Cf,
            0x6a4DBC971533Ba36bdc23aD70F5A7a12E064f4ae
        ));
        newchains.push(NewChain(  //  REDBELLY TESTNET Chain 153 Solidity 0.8.22
            153,
            0xeA5c4FBEFFDfe9173bE7dC8c94eD6288A1D8f85E,
            0x8d494f8B762005cCA5BDEBb770Af3bf51E730305,
            0xD4bD9BBA2fb97C36Bbd619303cAB636F476f8904,
            0x52661DbA4F88FeD997164ff2C453A2339216592C,
            0x89c8CC177f04CC8209B93e42d81a780c3A685dD4,
            0xe536Bf33585aa6bb528627Ed7Dc4D49009dafC58
        ));
        newchains.push(NewChain(  //  MANTA PACIFIC Chain 3441006 Solidity 0.8.27
            3441006,
            0x005c5Fd1585A73817107bFd3929f7e559750ceEd,
            0xDef5D31e4b2E0BF38Af3E8092a5ABF51Db484Eec,
            0x6EE5C158882857c7F52b37FCe37B1CF39944f22E,
            0xcAcF2003d4bC2e19C865e65Ebb9D57C440217f0F,
            0xF53fb9bb64AB9d3D78F976735762c5af9B5fF341,
            0x20cEfCf72622156987f82E1B54E94Dbc0848De9C
        ));
        newchains.push(NewChain(  //  AVALANCHE FUJI Chain 43113 Solidity 0.8.27
            43113,
            0x005c5Fd1585A73817107bFd3929f7e559750ceEd,
            0xDef5D31e4b2E0BF38Af3E8092a5ABF51Db484Eec,
            0x6EE5C158882857c7F52b37FCe37B1CF39944f22E,
            0xcAcF2003d4bC2e19C865e65Ebb9D57C440217f0F,
            0xF53fb9bb64AB9d3D78F976735762c5af9B5fF341,
            0x15A1ED0815ECeD97E46967179846c72BA21DABAd
        ));
    }
    
   

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        console.log("Wallet of deployer");
        console.log(deployer);

        bool ok;


        vm.startBroadcast(deployerPrivateKey);

        uint256 len = newchains.length;

        for(uint256 i=0; i<len; i++) {
            if(newchains[i].chainId == chainId) {
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

                    if(IFeeManager(thisFeeManager).getFeeTokenList().length == 0) {  // Allow just one fee token for now
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
                    

                    if(!stringsEqual(_toLower(ICTMRWAGateway(thisGway).getChainContract(chainIdStr)), thisGway.toHexString())) {
                        chainIdContractsStr.push(chainIdStr);
                        gwaysStr.push(thisGway.toHexString());
                    }

                    (, string memory rwax) = ICTMRWAGateway(thisGway).getAttachedRWAX(rwaType, version, chainIdStr);
                    if(!stringsEqual(rwax, _toLower(rwaXStr))) {
                        chainIdRwaXsStr.push(chainIdStr);
                        rwaXsStr.push(rwaXStr);
                    }

                    (, string memory stor) = ICTMRWAGateway(thisGway).getAttachedStorageManager(rwaType, version, chainIdStr);
                    if(!stringsEqual(stor, _toLower(storageManagerStr))) {
                        chainIdStorsStr.push(chainIdStr);
                        storageManagersStr.push(storageManagerStr);
                    }

                    (, string memory sentry) = ICTMRWAGateway(thisGway).getAttachedSentryManager(rwaType, version, chainIdStr);
                    if(!stringsEqual(sentry, _toLower(sentryManagerStr))) {
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

        for(uint256 i=0; i<len; i++) {     // 
            address gway =  newchains[i].gateway;
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
            address feeManager = newchains[i].feeManager;
            address feeToken = newchains[i].feeToken;
            string memory feeTokenStr = feeToken.toHexString();

            if(newchains[i].chainId == chainId) {
                string memory storedContract = ICTMRWAGateway(thisGway).getChainContract(chainIdStr);
                require(stringsEqual(
                    _toLower(gway.toHexString()), 
                    ICTMRWAGateway(gway).getChainContract(newchains[i].chainId.toString())
                ), "NewChainSetup: incorrect chainContract address stored");

            } else {
                console.log("Adding");
                console.log(newchains[i].chainId);

                if(!stringsEqual(_toLower(ICTMRWAGateway(thisGway).getChainContract(chainIdStr)), gwayStr)) {
                    chainIdContractsStr.push(chainIdStr);
                    gwaysStr.push(gwayStr);
                    // ok = ICTMRWAGateway(thisGway).addChainContract(_stringToArray(chainIdStr), _stringToArray(gwayStr));
                }

                (, string memory rwax) = ICTMRWAGateway(thisGway).getAttachedRWAX(rwaType, version, chainIdStr);
                if(!stringsEqual(rwax, _toLower(rwaXStr))) {
                    chainIdRwaXsStr.push(chainIdStr);
                    rwaXsStr.push(rwaXStr);
                    // ok = ICTMRWAGateway(thisGway).attachRWAX(rwaType, version, _stringToArray(chainIdStr), _stringToArray(rwaXStr));
                }

                (, string memory stor) = ICTMRWAGateway(thisGway).getAttachedStorageManager(rwaType, version, chainIdStr);
                if(!stringsEqual(stor, _toLower(storageManagerStr))) {
                    chainIdStorsStr.push(chainIdStr);
                    storageManagersStr.push(storageManagerStr);
                    // ok = ICTMRWAGateway(thisGway).attachStorageManager(rwaType, version, _stringToArray(chainIdStr), _stringToArray(storageManagerStr));
                }

                (, string memory sentry) = ICTMRWAGateway(thisGway).getAttachedSentryManager(rwaType, version, chainIdStr);
                if(!stringsEqual(sentry, _toLower(sentryManagerStr))) {
                    chainIdSentryStr.push(chainIdStr);
                    sentryManagersStr.push(sentryManagerStr);
                    // ok = ICTMRWAGateway(thisGway).attachSentryManager(rwaType, version, _stringToArray(chainIdStr), _stringToArray(sentryManagerStr));
                }

            }

            if (COMPLETE) {
                IFeeManager(thisFeeManager).addFeeToken(chainIdStr, _stringToArray(thisFeeTokenStr), _uint256ToArray(100));
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

    function strToUint(
        string memory _str
    ) external pure returns (uint256 res, bool err) {
        if (bytes(_str).length == 0) {
            return (0, true);
        }
        for (uint256 i = 0; i < bytes(_str).length; i++) {
            if (
                (uint8(bytes(_str)[i]) - 48) < 0 ||
                (uint8(bytes(_str)[i]) - 48) > 9
            ) {
                return (0, false);
            }
            res +=
                (uint8(bytes(_str)[i]) - 48) *
                10 ** (bytes(_str).length - i - 1);
        }

        return (res, true);
    }

    function stringToAddress(string memory str) internal pure returns (address) {
        bytes memory strBytes = bytes(str);
        require(strBytes.length == 42, "CTMRWA001X: Invalid address length");
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

    function stringsEqual(
        string memory a,
        string memory b
    ) internal pure returns (bool) {
        bytes32 ka = keccak256(abi.encode(a));
        bytes32 kb = keccak256(abi.encode(b));
        return (ka == kb);
    }

    function _toLower(string memory str) internal pure returns (string memory) {
        bytes memory bStr = bytes(str);
        bytes memory bLower = new bytes(bStr.length);
        for (uint i = 0; i < bStr.length; i++) {
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
    
    function _stringToArray(string memory _string) internal pure returns(string[] memory) {
        string[] memory strArray = new string[](1);
        strArray[0] = _string;
        return(strArray);
    }

    function _uint256ToArray(uint256 _myUint256) internal pure returns(uint256[] memory) {
        uint256[] memory uintArray = new uint256[](1);
        uintArray[0] = _myUint256;
        return(uintArray);
    }

}
