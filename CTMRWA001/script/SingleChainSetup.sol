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
    address feeToken;
}


contract SingleChainSetup is Script {
    using Strings for *;

    uint256 rwaType = 1;
    uint256 version = 1;

    uint256 chainId = 1115;   // This is the chainId we are processing

    string[] feeTokensStr;
    uint256[] fees;
    address thisGway;
    address thisRwaX;
    address thisStorageManager;
    address thisFeeManager;
    address thisFeeToken;
    string thisFeeTokenStr;

    string[] chainIdContractsStr;
    string[] gwaysStr;
    string[] chainIdRwaXsStr;
    string[] rwaXsStr;
    string[] chainIdStorsStr;
    string[] storageManagersStr;


    NewChain[] newchains;



    constructor() {
        newchains.push(NewChain(    // ARB Sepolia
            421614,
            0x20A9F9D7282c6FDE913522A42c3951F5B18f62D5,
            0xD5870cb8400E75F2097F3AF9fD37aF0C758707e0,
            0xc4eDB1cBb639143A6fAa63b7cAF194ce53D88D29,
            0x769139881024cE730dE9de9c21E3ad6fb5a872f2,
            0xbF5356AdE7e5F775659F301b07c4Bc6961044b11
        ));
        newchains.push(NewChain(   // POLYGON AMOY  Chain 80002
            80002,
            0x114ace1c918409889464c2a714f8442a97934Ccf,
            0x88a23d9ec1a9f1100d807D0E8c7a39927D4A7897,
            0x4cDa22b59a1fE957D09273E533cCb7D44bdEf90C,
            0x95ae66aD780E73eF2D2a80611458883C950a1356,
            0x6a4DBC971533Ba36bdc23aD70F5A7a12E064f4ae
        ));
        newchains.push(NewChain(  // BASE SEPOLIA  Chain 84532
            84532,
            0xF3A991cB19949cB6aBD9E416F0408C648B6c36Fa,
            0xb5d1f61f6B9f0CA2B89eb9D693e8cD737076846A,
            0x5b4d2c1b2e918fF1b0DE85803F5A737E5f816eCb,
            0xf9229aCEba228fdbb757A637EeeBadB46FDb617e,
            0x6a4DBC971533Ba36bdc23aD70F5A7a12E064f4ae
        ));
        newchains.push(NewChain(  // LINEA SEPOLIA Chain 59141
            59141,
            0x9266e8bf4943f2b366F2be89688a8622084DB8B9,
            0xB5638019CBfC1B523d5167a269E755b05BF24fD9,
            0xd1F0743C665d80D6BDaf1b4B8C9E82bfd1aE1994,
            0xa240B0714712e2927Ec055CEAa8e031AC671a55F,
            0x6654D956A4487A26dF1186b01B689c26939544fC
        ));
        //// newchains.push(NewChain(  // CONFLUX ESPACE  Chain 71
        ////     71,

        ////     0x6a4DBC971533Ba36bdc23aD70F5A7a12E064f4ae
        //// ));
        newchains.push(NewChain(  // CORE Testnet Chain 1115
            1115,
            0xF4e7a775c8aBC8e0B7ed11d660b0a6b2e1B7a132,
            0x73943Ec95AaFBb4DD073b11F5c9701E5Bc3708A6,
            0x67510816512511818B5047a4Cce6E8f2ebB15d20,
            0x4b17E8eE1cC1814636DDe9Ac12a42472799CCB64,
            0x6a4DBC971533Ba36bdc23aD70F5A7a12E064f4ae
        ));
        newchains.push(NewChain(  // HOLESKY Chain 17000
            17000,
            0xF4e7a775c8aBC8e0B7ed11d660b0a6b2e1B7a132,
            0x73943Ec95AaFBb4DD073b11F5c9701E5Bc3708A6,
            0x67510816512511818B5047a4Cce6E8f2ebB15d20,
            0x4b17E8eE1cC1814636DDe9Ac12a42472799CCB64,
            0x108642B1b2390AC3f54E3B45369B7c660aeFffAD
        ));
        newchains.push(NewChain(  // MORPH HOLESKY  Chain 2810
            2810,
            0x9266e8bf4943f2b366F2be89688a8622084DB8B9,
            0xB5638019CBfC1B523d5167a269E755b05BF24fD9,
            0xd1F0743C665d80D6BDaf1b4B8C9E82bfd1aE1994,
            0xa240B0714712e2927Ec055CEAa8e031AC671a55F,
            0x6a4DBC971533Ba36bdc23aD70F5A7a12E064f4ae
        ));
        newchains.push(NewChain(  // BLAST SEPOLIA Chain 168587773
            168587773,
            0x9266e8bf4943f2b366F2be89688a8622084DB8B9,
            0xB5638019CBfC1B523d5167a269E755b05BF24fD9,
            0xd1F0743C665d80D6BDaf1b4B8C9E82bfd1aE1994,
            0xa240B0714712e2927Ec055CEAa8e031AC671a55F,
            0x5d5408e949594E535d0c3d533761Cb044E11b664
        ));
        newchains.push(NewChain(  // BITLAYER TESTNET Chain 200810
            200810,
            0x64C5734e22cf8126c6367c0230B66788fBE4AB90,
            0xa4482dF3A723654A599Ba66d1b5091fD9C42ad05,
            0xEb28C8e7Cc2d8a8d361Cb41EC0937ac11c0c0A1F,
            0x048A5cefCDF0faeB734bc4A941E0de44d8c49f55,
            0x6a4DBC971533Ba36bdc23aD70F5A7a12E064f4ae
        ));
        newchains.push(NewChain(  // SCROLL SEPOLIA   Chain 534351
            534351,
            0x9266e8bf4943f2b366F2be89688a8622084DB8B9,
            0xB5638019CBfC1B523d5167a269E755b05BF24fD9,
            0xd1F0743C665d80D6BDaf1b4B8C9E82bfd1aE1994,
            0xa240B0714712e2927Ec055CEAa8e031AC671a55F,
            0xe536Bf33585aa6bb528627Ed7Dc4D49009dafC58
        ));
        newchains.push(NewChain(  // MANTLE SEPOLIA Chain 5003
            5003,
            0x9266e8bf4943f2b366F2be89688a8622084DB8B9,
            0xB5638019CBfC1B523d5167a269E755b05BF24fD9,
            0xd1F0743C665d80D6BDaf1b4B8C9E82bfd1aE1994,
            0xa240B0714712e2927Ec055CEAa8e031AC671a55F,
            0x6a4DBC971533Ba36bdc23aD70F5A7a12E064f4ae
        ));
        newchains.push(NewChain(  // LUKSO TESTNET  Chain 4201
            4201,
            0x2927d422CBEA7F315ee3E0660aF2eD9b35302004,
            0x1B87108B35Abb5751Bfc64647E9D5cD1Cb77E236,
            0x0897e91383Ab942bC502549eD75AA8ea7538B5Fe,
            0x3418a45e442210EC9579B074Ae9ACb13b2A67554,
            0xC92291fbBe0711b6B34928cB1b09aba1f737DEfd
        ));
        newchains.push(NewChain(  // BERA_BARTIO Chain 80084
            80084,
            0xa42864Da3ee7B05489eF1d99704089b734cb73a2,
            0x67510816512511818B5047a4Cce6E8f2ebB15d20,
            0x779f7FfdD1157935E1cD6344A6D7a9047736EBc1,
            0xa7C57315395def05F906310d590f4ea15308fe30,
            0x6a4DBC971533Ba36bdc23aD70F5A7a12E064f4ae
        ));
        newchains.push(NewChain(  // LUMIA TESTNET Chain 1952959480
            1952959480,
            0xd1F0743C665d80D6BDaf1b4B8C9E82bfd1aE1994,
            0x9266e8bf4943f2b366F2be89688a8622084DB8B9,
            0x4f5b13A48d4fC78e154DDa6c49E39c6d59277213,
            0xde3Fdb278B0EC3254E8701c38e58CFd1168f13a5,
            0x6a4DBC971533Ba36bdc23aD70F5A7a12E064f4ae
        ));
        //// newchains.push(NewChain(  // PLUME TESTNET Chain 161221135
        // //     161221135,
            
        ////     0x6a4DBC971533Ba36bdc23aD70F5A7a12E064f4ae
        //// ));
        newchains.push(NewChain(  // VANGUARD Chain 78600
            78600,
            0xeaDb6779c7284a7ef6f611f4535e60c3d59B321b,
            0x232c61b3d1A03cC57e976cCcD0F9C9Cd33a98fe0,
            0xa6e0Fa5cCEEf6e87d89B4DC51053E1Ff1A557B53,
            0xC33b3317912d173806D782BFadE797f262d9A4Bd,
            0x6654D956A4487A26dF1186b01B689c26939544fC
        ));
        newchains.push(NewChain(  // RARI TESTNET Chain 1918988905
            1918988905,
            0x22c254662850f21bfb09714F6A5638D929439F8D,
            0x3Abb2780b0BbF630490D155C4861F4E82c623246,
            0x0D8723a971ab42D0c52bf241ddb313B20F84E837,
            0x56249F01CF2B50A7F211Bb9de08B1480835F574a,
            0x6a4DBC971533Ba36bdc23aD70F5A7a12E064f4ae
        ));
        newchains.push(NewChain(  // U2U NEBULAS TESTNET Chain 2484
            2484,
            0x9266e8bf4943f2b366F2be89688a8622084DB8B9,
            0xB5638019CBfC1B523d5167a269E755b05BF24fD9,
            0xd1F0743C665d80D6BDaf1b4B8C9E82bfd1aE1994,
            0xa240B0714712e2927Ec055CEAa8e031AC671a55F, 
            0x6a4DBC971533Ba36bdc23aD70F5A7a12E064f4ae
        ));
        newchains.push(NewChain(  // SONEIUM MINATO Chain 1946
            1946,
            0x9266e8bf4943f2b366F2be89688a8622084DB8B9,
            0xB5638019CBfC1B523d5167a269E755b05BF24fD9,
            0xd1F0743C665d80D6BDaf1b4B8C9E82bfd1aE1994,
            0xa240B0714712e2927Ec055CEAa8e031AC671a55F,
            0x6a4DBC971533Ba36bdc23aD70F5A7a12E064f4ae
        ));
        newchains.push(NewChain(  // OPBNB TESTNET  Chain 5611
            5611,
            0x9266e8bf4943f2b366F2be89688a8622084DB8B9,
            0xB5638019CBfC1B523d5167a269E755b05BF24fD9,
            0xd1F0743C665d80D6BDaf1b4B8C9E82bfd1aE1994,
            0xa240B0714712e2927Ec055CEAa8e031AC671a55F,
            0x108642B1b2390AC3f54E3B45369B7c660aeFffAD
        ));
        newchains.push(NewChain(  // SONIC TESTNET  Chain 64165
            64165,
            0xF4e7a775c8aBC8e0B7ed11d660b0a6b2e1B7a132,
            0x73943Ec95AaFBb4DD073b11F5c9701E5Bc3708A6,
            0x67510816512511818B5047a4Cce6E8f2ebB15d20,
            0x4b17E8eE1cC1814636DDe9Ac12a42472799CCB64,
            0x1E411051A586EDB12282c08A933FB8C7699FEFB2
        ));
        newchains.push(NewChain(  // FIRE THUNDER  Chain 997
            997,
            0xF4e7a775c8aBC8e0B7ed11d660b0a6b2e1B7a132,
            0x73943Ec95AaFBb4DD073b11F5c9701E5Bc3708A6,
            0x67510816512511818B5047a4Cce6E8f2ebB15d20,
            0x4b17E8eE1cC1814636DDe9Ac12a42472799CCB64,
            0x6a4DBC971533Ba36bdc23aD70F5A7a12E064f4ae
        ));
        newchains.push(NewChain(  // HUMANODE TESTNET ISRAFEL  Chain 14853
            14853,
            0x9266e8bf4943f2b366F2be89688a8622084DB8B9,
            0xB5638019CBfC1B523d5167a269E755b05BF24fD9,
            0xd1F0743C665d80D6BDaf1b4B8C9E82bfd1aE1994,
            0xa240B0714712e2927Ec055CEAa8e031AC671a55F,
            0x6dD69414E074575c45D5330d2707CAf80303a85B
        ));
        newchains.push(NewChain(   // CRONOS TESTNET   Chain 338
            338,
            0xAE66C08b9d76EeCaA74314c60f3305D43707ACc9,
            0x176cD7aBF4919068d7FeC79935c303b32B7DabE7,
            0x1f8548Eb8Ec40294D7eD5e85DbF0F3BCE228C3Bc,
            0xb8B99101c1DBFaD6Aa418220592773be082Db804,
            0xf6d2060494cD08e776D22a47E67d485a33C8c5d2
        ));
        newchains.push(NewChain(  //  BSC TESTNET Chain 97
            97,
            0xBA08c3b81ed1A13e7A3457b6ab5DDdBa2DF34df4,
            0x21ea338975678968Da85deA76f298E7f11A09334,
            0x8b97E011A2F64F705C0A65706fB7bb968CB13d52,
            0x60A5B05DB6c8EB0b47F8227ea3b04Bd751B79DbC,
            0xDd43fc986a13392dDbC7aeA150b41EfE27b2d0eD
        ));
        newchains.push(NewChain(  //  SEPOLIA  Chain 11155111
            11155111,
            0x10A04ad4a73C8bb00Ee5A29B27d11eeE85390306,
            0x3AF6a526DD51C8B08FD54dBB624E042BB3b0a77e,
            0x926DF1f820Af8E3cF53A58C94332eB16BA4cB4b5,
            0x93DEF24108852Be52b2c34084d584338E46ab8f4,
            0xa4C104db0937F1E886d5C9c9789D6f0e5bfBA75c
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
                string memory storageManagerStr = thisStorageManager.toHexString();
                thisFeeManager = newchains[i].feeManager;
                thisFeeToken = newchains[i].feeToken;
                thisFeeTokenStr = thisFeeToken.toHexString();

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

            }
        }

        

        console.log("thisGway");
        console.log(thisGway);
        console.log("thisRwaX");
        console.log(thisRwaX);
        console.log("thisStorageManager");
        console.log(thisStorageManager);
        console.log("thisFeeManager");
        console.log(thisFeeManager);

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

            }

            feeTokensStr.push(thisFeeTokenStr);
            fees.push(100);  // Base fee = 1 token (e.g. USDT)
            IFeeManager(thisFeeManager).addFeeToken(chainIdStr, feeTokensStr, fees);
            feeTokensStr.pop();
            fees.pop();
            
        }

        ok = ICTMRWAGateway(thisGway).addChainContract(chainIdContractsStr, gwaysStr);
        ok = ICTMRWAGateway(thisGway).attachRWAX(rwaType, version, chainIdRwaXsStr, rwaXsStr);
        ok = ICTMRWAGateway(thisGway).attachStorageManager(rwaType, version, chainIdStorsStr, storageManagersStr);

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
