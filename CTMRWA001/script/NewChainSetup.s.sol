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

    uint256 chainId = 1952959480;   // This is the chainId we are processing

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
            0xbab5Ec2802257958d3f3a34dcE2F7Aa65Eac922d,
            0xDB3caaE3A1fD4846bC2a7dDBcb2B7b4dbd3484b8,
            0x7e61a5AF95Fc6efaC03F7d92320F42B2c2fe96f0,
            0xf55fB33d9BD6Bb47461d68890bc8F951480211FC,
            0x998f9E69CF313d06b1D4BA22FeCE9c23D0D0Ca31,
            0xbF5356AdE7e5F775659F301b07c4Bc6961044b11
        ));
        newchains.push(NewChain(   // POLYGON AMOY  Chain 80002 *
            80002,
            0xb1bC63301670F8ec9EE98BD501c89783d65ddC8a,
            0xDf495F3724a6c705fed4aDfa7588Cd326162A39c,
            0x2D2112DE9801EAf71B6D1cBf40A99E57AFc235a7,
            0xad49cabD336f943a9c350b9ED60680c54fa2c3d1,
            0xC7a339588569Da96def78A96732eE20c3446BF11,
            0x6a4DBC971533Ba36bdc23aD70F5A7a12E064f4ae
            
        ));
        newchains.push(NewChain(  // BASE SEPOLIA  Chain 84532
            84532,
            0xe1C4c5a0e6A99bB61b842Bb78E5c66EA1256D292,
            0x6681DB630eB117050D78E0B89eB5619b35Ea12e8,
            0x91677ec1879987aBC3978fD2A71204640A9e9f4A,
            0xE6d89DBE4113BDDc79c4D8256C3604d9Db291fEa,
            0x0dB39536F72E19edFfd45e318b1Da9A3684679a2,
            0x6a4DBC971533Ba36bdc23aD70F5A7a12E064f4ae
            
        ));
        // newchains.push(NewChain(  // LINEA SEPOLIA Chain 59141
        //     59141,
        //     0x41543A4C6423E2546FC58AC63117B5692D68c323,
        //     0x969035b34B913c507b87FD805Fff608FB1fE13f0,
        //     0x0c4AedfD2Aef21B742c29F061CA80Cc79D64A106,
        //     0x208Ec1Ca3B07a50151c5741bc0E05C61beddad90,
        //     ,
        //     0x6654D956A4487A26dF1186b01B689c26939544fC
            
        // ));
        // newchains.push(NewChain(  // CONFLUX ESPACE  Chain 71
        //     71,

        //     0x6a4DBC971533Ba36bdc23aD70F5A7a12E064f4ae
        // ));
        newchains.push(NewChain(  // CORE Testnet Chain 1115
            1115,
            0xb849bF0a5ca08f1e6EA792bDC06ff2317bb2fB90,
            0xe08C7eE637336565511eb3421DAFdf45b860F9bc,
            0x5930640c1572bCD396eB410f62a6975ab9b8A148,
            0x533A9CeCcBa37453337e28DCB3EC4705d5d22260,
            0x604643F60B3bF7eE767a998e35Fe0B9c6356223a,
            0x6a4DBC971533Ba36bdc23aD70F5A7a12E064f4ae
            
        ));
        newchains.push(NewChain(  // HOLESKY Chain 17000
            17000,
            0x05a804374Bb77345854022Fd0CD2A602E00bF2E7,
            0x16b049e17b49C5DC1D8598b53593D4497c858c9a,
            0xe98eCde78f1E8Ca24445eCfc4b5560aF193C842F,
            0xa74Af157716e604042cF835Bd3a3F3A85C1c0959,
            0xCa19ddc73718512B968B2cb838b1408885D74A05,
            0x108642B1b2390AC3f54E3B45369B7c660aeFffAD
            
        ));
        newchains.push(NewChain(  // MORPH HOLESKY  Chain 2810
            2810,
            0xa3325B2fA099c81a06d9b7532317d4a4Da7F2aB7,
            0x63135C26Ad4a67D9D5dCfbCCDc94F11de83eB2Ca,
            0x94C3fD7a91ee706B89214B9C2E9a505508109a3c,
            0xB128Ee08fb55a9Ae0b18d753a093Bf40EBC1d804,
            0xe0F2017BC8206Ffc8D563a6c0C9Fb52c0189a5a6,
            0x6a4DBC971533Ba36bdc23aD70F5A7a12E064f4ae
            
        ));
        newchains.push(NewChain(  // BLAST SEPOLIA Chain 168587773
            168587773,
            0x74Da08aBCb64A66370E9C1609771e68aAfEDE27B,
            0x67193A5129e506dB83f434461a839938d98b2628,
            0xB75A2833405907508bD5f8DEa3A24FA537D9C85c,
            0x93aE0e18578828631489c6CB8f8045eBe8D4599f,
            0x3912670e1A1b6183c89a2079AAa3299ce585296a,
            0x5d5408e949594E535d0c3d533761Cb044E11b664
            
        ));
        newchains.push(NewChain(  // BITLAYER TESTNET Chain 200810
            200810,
            0x1e46d7f21299Ac06AAd49017A1f733Cd5e6134f3,
            0xc74D2556d610F886B55653FAfFddF4bd0c1605B6,
            0xb008b6Cc593fC290Ed03d5011e90f4E9d19f9a87,
            0x3CB56e6E5917a2a8924BC2A5C1f0ecc90b585e74,
            0xeFbd6990A5C4ABFA30b91409aA3d9A0e7C8Bb77b,
            0x6a4DBC971533Ba36bdc23aD70F5A7a12E064f4ae
            
        ));
        newchains.push(NewChain(  // SCROLL SEPOLIA   Chain 534351
            534351,
            0xa3325B2fA099c81a06d9b7532317d4a4Da7F2aB7,
            0x63135C26Ad4a67D9D5dCfbCCDc94F11de83eB2Ca,
            0x94C3fD7a91ee706B89214B9C2E9a505508109a3c,
            0xB128Ee08fb55a9Ae0b18d753a093Bf40EBC1d804,
            0xe0F2017BC8206Ffc8D563a6c0C9Fb52c0189a5a6,
            0xe536Bf33585aa6bb528627Ed7Dc4D49009dafC58
            
        ));
        newchains.push(NewChain(  // MANTLE SEPOLIA Chain 5003
            5003,
            0x563c5c85CC7ba923c50b66479588e5b3B2C93470,
            0x30a63CF179996ae6332C0AC3898CdFD48b105118,
            0x63135C26Ad4a67D9D5dCfbCCDc94F11de83eB2Ca,
            0x3912670e1A1b6183c89a2079AAa3299ce585296a,
            0xf7548cB35188aa7DaC8423fAA2ACe3855634e40C,
            0x6a4DBC971533Ba36bdc23aD70F5A7a12E064f4ae
            
        ));
        newchains.push(NewChain(  // LUKSO TESTNET  Chain 4201
            4201,
            0xdbD55D95D447E363251592A8FF573bBf16c2CB68,
            0xd6f9Cc85F5a3031D6E32a03DdB8a7aEDBeBd953E,
            0xc74D2556d610F886B55653FAfFddF4bd0c1605B6,
            0x95574b1a28865A81D2df36683d027A9D7603aFC7,
            0x7AEECCcafb96e53460B5b633Fc668adf14ed8419,
            0xC92291fbBe0711b6B34928cB1b09aba1f737DEfd
            
        ));
        newchains.push(NewChain(  // LUMIA TESTNET Chain 1952959480
            1952959480,
            0x052E276c0A9D2D2adf1A2AeB6D7eCaEC38ec9dE6,
            0xDfCF0181d2c2608D6e055997D2C215811AcC2D49,
            0x20ADAf244972bC6cB064353F3EA4893f73E85599,
            0xE91ABb1F959C96a91674B0923478860eACd653D2,
            0xC98984dAe5EF66e702Fe16D1B69b043BC163435C,
            0x6a4DBC971533Ba36bdc23aD70F5A7a12E064f4ae
            
        ));
        // newchains.push(NewChain(  // PLUME TESTNET Chain 161221135
        //     161221135,
            
        //     0x6a4DBC971533Ba36bdc23aD70F5A7a12E064f4ae
        // ));
        newchains.push(NewChain(  // VANGUARD Chain 78600
            78600,
            0x06edC167555ceb6038E2C6b3bED7A47C628F2Eed,
            0x282EccB80074e9aB23ea5d28bd795C0BBA3726A6,
            0xa240B0714712e2927Ec055CEAa8e031AC671a55F,
            0x094bd93DF885D063e89B61702AaD4463dE313ebE,
            0xdbD55D95D447E363251592A8FF573bBf16c2CB68,
            0x6654D956A4487A26dF1186b01B689c26939544fC
            
        ));
        newchains.push(NewChain(  // U2U NEBULAS TESTNET Chain 2484
            2484,
            0x16b049e17b49C5DC1D8598b53593D4497c858c9a,
            0xFC63DC90296800c67cBb96330238fc17FbD674A2,
            0x05a804374Bb77345854022Fd0CD2A602E00bF2E7,
            0x25903bEA74d4fbE43B7D30703D2A740841DfB7b2, 
            0x3FfbC9f4C2Bb8fB74Ab712d3E01c695Ce2329b1D,
            0x6a4DBC971533Ba36bdc23aD70F5A7a12E064f4ae
            
        ));
        newchains.push(NewChain(  // SONEIUM MINATO Chain 1946
            1946,
            0xF663c3De2d18920ffd7392242459275d0Dd249e4,
            0xB75A2833405907508bD5f8DEa3A24FA537D9C85c,
            0xB37C81d6f90A16bbD778886AF49abeBfD1AD02C7,
            0x652003e2253e9200D7779D4bc8b962cD1F8D604b,
            0xB128Ee08fb55a9Ae0b18d753a093Bf40EBC1d804,
            0x6a4DBC971533Ba36bdc23aD70F5A7a12E064f4ae
            
        ));
        newchains.push(NewChain(  // OPBNB TESTNET  Chain 5611
            5611,
            0x563c5c85CC7ba923c50b66479588e5b3B2C93470,
            0x30a63CF179996ae6332C0AC3898CdFD48b105118,
            0x63135C26Ad4a67D9D5dCfbCCDc94F11de83eB2Ca,
            0xC230C289328a86d2daC10Db25E91f516aD7D0D3f,
            0x45cddE4bdAbC97b3ec02B1271432ceeBc04d4c53,
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
            0xD362AFB113D7a2226aFf228F4FB161BEFd3b6BD4,
            0x2bBA6E0eDBe1aC6794B12B960A37156d9d07f009,
            0x7ad438D2B3AC77D55c85275fD09d51Cec9Bb2987,
            0x0f92c2F73498BF195c6129b2528c64f3D0BED434,
            0x2AD99B7D982B119848a647676C02663018A1928a,
            0xDd43fc986a13392dDbC7aeA150b41EfE27b2d0eD
            
        ));
        newchains.push(NewChain(  //  SEPOLIA  Chain 11155111
            11155111,
            0xF8fe7804AE6DBC7306AB5A97aE2302706170530C,
            0x1a72d73B379A2454160B395cE7326755CBc76BCe,
            0xee53A0AD7f17715774Acc3963693B37040900019,
            0x5438B4f84152061E3717350721F00eE9c6151baF,
            0xe831D6DCAF9F45089eb82DcddA8014355273F1dC,
            0xa4C104db0937F1E886d5C9c9789D6f0e5bfBA75c
            
        ));
        newchains.push(NewChain(  //  OPTIMISM SEPOLIA Chain 11155420
            11155420,
            0x3b44962Bf264b8CebAC13DA24722faa27fC693a1,
            0x266442249F62A8Dd4e29348A52af8c806c7CB0da,
            0xD8fB50721bC30bF3E4D591c078747b4e7cE46e7A,
            0xA7EC64D41f32FfE662A46B62E59D1EBFEaD52522,
            0x06edC167555ceb6038E2C6b3bED7A47C628F2Eed,
            0x6a4DBC971533Ba36bdc23aD70F5A7a12E064f4ae
        ));
        newchains.push(NewChain(  //  REDBELLY TESTNET Chain 153
            153,
            0xDC635161b63Ca5281F96F2d70C3f7C0060d151d3,
            0x92BB6DEfEF73fa2ee42FeC2273d98693571bd7f3,
            0xb76428eBE853F2f6a5D74C4361B72999f55EE637,
            0x8641613849038f495FA8Dd313f13a3f7F2D73815,
            0xA4dAb6Df348B312a5a0320D08ebEF76441178CFe,
            0xe536Bf33585aa6bb528627Ed7Dc4D49009dafC58
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
                // thisRwaX = newchains[i].rwaX;
                // string memory rwaXStr = thisRwaX.toHexString();
                thisStorageManager = newchains[i].storageManager;
                thisSentryManager = newchains[i].sentryManager;
                string memory storageManagerStr = thisStorageManager.toHexString();
                string memory sentryManagerStr = thisSentryManager.toHexString();
                // thisFeeManager = newchains[i].feeManager;
                // thisFeeToken = newchains[i].feeToken;
                // thisFeeTokenStr = thisFeeToken.toHexString();

                // if(IFeeManager(thisFeeManager).getFeeTokenList().length == 0) {  // Allow just one fee token for now
                //     ok = IFeeManager(thisFeeManager).addFeeToken(thisFeeTokenStr);
                //     require(ok, "NewChainSetup: Could not add fee token");
                // }


                // ok = IFeeManager(thisFeeManager).setFeeMultiplier(FeeType.ADMIN, 2);
                // require(ok, "NewChainSetup: Could not set fee multiplier");
                // ok = IFeeManager(thisFeeManager).setFeeMultiplier(FeeType.DEPLOY, 10);
                // require(ok, "NewChainSetup: Could not set fee multiplier");
                // ok = IFeeManager(thisFeeManager).setFeeMultiplier(FeeType.TX, 1);
                // require(ok, "NewChainSetup: Could not set fee multiplier");
                // ok = IFeeManager(thisFeeManager).setFeeMultiplier(FeeType.MINT, 4);
                // require(ok, "NewChainSetup: Could not set fee multiplier");
                // ok = IFeeManager(thisFeeManager).setFeeMultiplier(FeeType.BURN, 4);
                // require(ok, "NewChainSetup: Could not set fee multiplier");
                // ok = IFeeManager(thisFeeManager).setFeeMultiplier(FeeType.ISSUER, 4);
                // require(ok, "NewChainSetup: Could not set fee multiplier");
                // ok = IFeeManager(thisFeeManager).setFeeMultiplier(FeeType.PROVENANCE, 8);
                // require(ok, "NewChainSetup: Could not set fee multiplier");
                // ok = IFeeManager(thisFeeManager).setFeeMultiplier(FeeType.VALUATION, 4);
                // require(ok, "NewChainSetup: Could not set fee multiplier");
                // ok = IFeeManager(thisFeeManager).setFeeMultiplier(FeeType.PROSPECTUS, 10);
                // require(ok, "NewChainSetup: Could not set fee multiplier");
                // ok = IFeeManager(thisFeeManager).setFeeMultiplier(FeeType.RATING, 8);
                // require(ok, "NewChainSetup: Could not set fee multiplier");
                // ok = IFeeManager(thisFeeManager).setFeeMultiplier(FeeType.LEGAL, 8);
                // require(ok, "NewChainSetup: Could not set fee multiplier");
                // ok = IFeeManager(thisFeeManager).setFeeMultiplier(FeeType.FINANCIAL, 8);
                // require(ok, "NewChainSetup: Could not set fee multiplier");
                // ok = IFeeManager(thisFeeManager).setFeeMultiplier(FeeType.LICENSE, 20);
                // require(ok, "NewChainSetup: Could not set fee multiplier");
                // ok = IFeeManager(thisFeeManager).setFeeMultiplier(FeeType.DUEDILIGENCE, 8);
                // require(ok, "NewChainSetup: Could not set fee multiplier");
                // ok = IFeeManager(thisFeeManager).setFeeMultiplier(FeeType.NOTICE, 4);
                // require(ok, "NewChainSetup: Could not set fee multiplier");
                // ok = IFeeManager(thisFeeManager).setFeeMultiplier(FeeType.DIVIDEND, 4);
                // require(ok, "NewChainSetup: Could not set fee multiplier");
                // ok = IFeeManager(thisFeeManager).setFeeMultiplier(FeeType.REDEMPTION, 4);
                // require(ok, "NewChainSetup: Could not set fee multiplier");
                // ok = IFeeManager(thisFeeManager).setFeeMultiplier(FeeType.WHOCANINVEST, 4);
                // require(ok, "NewChainSetup: Could not set fee multiplier");
                // ok = IFeeManager(thisFeeManager).setFeeMultiplier(FeeType.IMAGE, 2);
                // require(ok, "NewChainSetup: Could not set fee multiplier");
                // ok = IFeeManager(thisFeeManager).setFeeMultiplier(FeeType.VIDEO, 20);
                // require(ok, "NewChainSetup: Could not set fee multiplier");
                // ok = IFeeManager(thisFeeManager).setFeeMultiplier(FeeType.ICON, 2);
                // require(ok, "NewChainSetup: Could not set fee multiplier");
                // ok = IFeeManager(thisFeeManager).setFeeMultiplier(FeeType.WHITELIST, 1);
                // require(ok, "NewChainSetup: Could not set fee multiplier");
                // ok = IFeeManager(thisFeeManager).setFeeMultiplier(FeeType.COUNTRY, 1);
                // require(ok, "NewChainSetup: Could not set fee multiplier");
                // ok = IFeeManager(thisFeeManager).setFeeMultiplier(FeeType.KYC, 5);
                // require(ok, "NewChainSetup: Could not set fee multiplier");

                if(!stringsEqual(_toLower(ICTMRWAGateway(thisGway).getChainContract(chainIdStr)), thisGway.toHexString())) {
                    chainIdContractsStr.push(chainIdStr);
                    gwaysStr.push(thisGway.toHexString());
                }

                // (, string memory rwax) = ICTMRWAGateway(thisGway).getAttachedRWAX(rwaType, version, chainIdStr);
                // if(!stringsEqual(rwax, _toLower(rwaXStr))) {
                //     chainIdRwaXsStr.push(chainIdStr);
                //     rwaXsStr.push(rwaXStr);
                // }

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

    
        console.log("thisGway");
        console.log(thisGway);
        // console.log("thisRwaX");
        // console.log(thisRwaX);
        console.log("thisStorageManager");
        console.log(thisStorageManager);
        console.log("thisSentryManager");
        console.log(thisSentryManager);
        // console.log("thisFeeManager");
        // console.log(thisFeeManager);

        // revert("debug exit");

        for(uint256 i=0; i<len; i++) {     // 
            address gway =  newchains[i].gateway;
            string memory chainIdStr = newchains[i].chainId.toString();
            console.log("Processing chainIdStr");
            console.log(chainIdStr); 
            string memory gwayStr = gway.toHexString();
            // address rwaX = newchains[i].rwaX;
            // string memory rwaXStr = rwaX.toHexString();
            address storageManager = newchains[i].storageManager;
            string memory storageManagerStr = storageManager.toHexString();
            address sentryManager = newchains[i].sentryManager;
            string memory sentryManagerStr = sentryManager.toHexString();
            // address feeManager = newchains[i].feeManager;
            // address feeToken = newchains[i].feeToken;
            // string memory feeTokenStr = feeToken.toHexString();

            if(newchains[i].chainId == chainId) {
                string memory storedContract = ICTMRWAGateway(thisGway).getChainContract(chainIdStr);
                require(stringsEqual(
                    _toLower(gway.toHexString()), 
                    ICTMRWAGateway(gway).getChainContract(newchains[i].chainId.toString())
                ), "NewChainSetup: incorrect chainContract address stored");

            } else {
                console.log("Adding");
                console.log(newchains[i].chainId);

                // if(!stringsEqual(_toLower(ICTMRWAGateway(thisGway).getChainContract(chainIdStr)), gwayStr)) {
                //     chainIdContractsStr.push(chainIdStr);
                //     gwaysStr.push(gwayStr);
                // }

                // (, string memory rwax) = ICTMRWAGateway(thisGway).getAttachedRWAX(rwaType, version, chainIdStr);
                // if(!stringsEqual(rwax, _toLower(rwaXStr))) {
                //     chainIdRwaXsStr.push(chainIdStr);
                //     rwaXsStr.push(rwaXStr);
                // }

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

            // feeTokensStr.push(thisFeeTokenStr);
            // fees.push(100);  // Base fee = 1 token (e.g. USDT)
            // IFeeManager(thisFeeManager).addFeeToken(chainIdStr, feeTokensStr, fees);
            // feeTokensStr.pop();
            // fees.pop();
            
        }

        // ok = ICTMRWAGateway(thisGway).addChainContract(chainIdContractsStr, gwaysStr);
        // ok = ICTMRWAGateway(thisGway).attachRWAX(rwaType, version, chainIdRwaXsStr, rwaXsStr);
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


}
