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


contract NewChainSetup is Script {
    using Strings for *;

    uint256 rwaType = 1;
    uint256 version = 1;

    uint256 chainId = 11155111;   // This is the chainId we are processing

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
            0xeb4b038c0f1F086BB7Ab5B4192611015aFf95390,
            0xb3aefEa9F49De70C41Ce22Afa321E64393932d21,
            0x0e95227823f64F54D6611Ae6f4fb70a4D76D4378,
            0x37C7137Dc6e3DC3c3637bFEd3F6dBFbd43386429,
            0x92829288C6Aa874c1A0F190dA35A4023C22be637
        ));
        newchains.push(NewChain(   // POLYGON AMOY  Chain 80002
            80002,
            0xfdD1a5B3AEEa2DF15a6F6B502784B61BdCbF66BC,
            0xD586Ea1FcE09384F71B69e80F643135FC0641def,
            0xA9522e00101Ee85f3B8E6a4F0723F5eA4A2F0A50,
            0xB523F0e72A7BdF94a5a3d84BA9e8Dc42E69229ea,
            0x6a4DBC971533Ba36bdc23aD70F5A7a12E064f4ae
        ));
        newchains.push(NewChain(  // BASE SEPOLIA  Chain 84532
            84532,
            0xEa4A06cB68ABa869e6BF98Edc4BdbC731d2D82e3,
            0x9A0F81de582Ce9194FEADC6CCefaf9eA70451616,
            0x66dc636132fb9b7f6ed858928B65864D3fd0ea67,
            0x9372CD1287E0bB6337802D80DFF342348c85fd78,
            0x6a4DBC971533Ba36bdc23aD70F5A7a12E064f4ae
        ));
        // newchains.push(NewChain(  // LINEA SEPOLIA Chain 59141
        //     59141,

        //     0x6654D956A4487A26dF1186b01B689c26939544fC
        // ));
        // newchains.push(NewChain(  // CONFLUX ESPACE  Chain 71
        //     71,

        //     0x6a4DBC971533Ba36bdc23aD70F5A7a12E064f4ae
        // ));
        // newchains.push(NewChain(  // CORE Testnet Chain 1115
        //     1115,
            
        //     0x6a4DBC971533Ba36bdc23aD70F5A7a12E064f4ae
        // ));


        // uint256 chainId;
        // address gateway;
        // address rwaX;
        // address feeManager;
        // address storageManager;
        // address feeToken;


        // newchains.push(NewChain(  // HOLESKY Chain 17000
        //     17000,
            
        //     0x108642B1b2390AC3f54E3B45369B7c660aeFffAD
        // ));
        // newchains.push(NewChain(  // MORPH HOLESKY  Chain 2810
        //     2810,
            
        //     0x6a4DBC971533Ba36bdc23aD70F5A7a12E064f4ae
        // ));
        // newchains.push(NewChain(  // BLAST SEPOLIA Chain 168587773
        //     168587773,
            
        //     0x5d5408e949594E535d0c3d533761Cb044E11b664
        // ));
        // newchains.push(NewChain(  // BITLAYER TESTNET Chain 200810
        //     200810,
            
        //     0x6a4DBC971533Ba36bdc23aD70F5A7a12E064f4ae
        // ));
        // newchains.push(NewChain(  // SCROLL SEPOLIA   Chain 534351
        //     534351,
            
        //     0xe536Bf33585aa6bb528627Ed7Dc4D49009dafC58
        // ));
        // newchains.push(NewChain(  // MANTLE SEPOLIA Chain 5003
        //     5003,
            
        //     0x6a4DBC971533Ba36bdc23aD70F5A7a12E064f4ae
        // ));
        // newchains.push(NewChain(  // LUKSO TESTNET  Chain 4201
        //     4201,
            
        //     0xC92291fbBe0711b6B34928cB1b09aba1f737DEfd
        // ));
        // newchains.push(NewChain(  // BERA_BARTIO Chain 80084
        //     80084,
           
        //     0x6a4DBC971533Ba36bdc23aD70F5A7a12E064f4ae
        // ));
        // newchains.push(NewChain(  // LUMIA TESTNET Chain 1952959480
        //     1952959480,
            
        //     0x6a4DBC971533Ba36bdc23aD70F5A7a12E064f4ae
        // ));
        // newchains.push(NewChain(  // PLUME TESTNET Chain 161221135
        //     161221135,
            
        //     0x6a4DBC971533Ba36bdc23aD70F5A7a12E064f4ae
        // ));
        // newchains.push(NewChain(  // VANGUARD Chain 78600
        //     78600,
            
        //     0x6654D956A4487A26dF1186b01B689c26939544fC
        // ));
        // newchains.push(NewChain(  // RARI TESTNET Chain 1918988905
        //     1918988905,
            
        //     0x6a4DBC971533Ba36bdc23aD70F5A7a12E064f4ae
        // ));
        // newchains.push(NewChain(  // U2U NEBULAS TESTNET Chain 2484
        //     2484,
            
        //     0x6a4DBC971533Ba36bdc23aD70F5A7a12E064f4ae
        // ));
        // newchains.push(NewChain(  // SONEIUM MINATO Chain 1946
        //     1946,
            
        //     0x6a4DBC971533Ba36bdc23aD70F5A7a12E064f4ae
        // ));
        // newchains.push(NewChain(  // OPBNB TESTNET  Chain 5611
        //     5611,
            
        //     0x108642B1b2390AC3f54E3B45369B7c660aeFffAD
        // ));
        // newchains.push(NewChain(  // SONIC TESTNET  Chain 64165
        //     64165,
            
        //     0x1E411051A586EDB12282c08A933FB8C7699FEFB2
        // ));
        // newchains.push(NewChain(  // FIRE THUNDER  Chain 997
        //     997,
            
        //     0x6a4DBC971533Ba36bdc23aD70F5A7a12E064f4ae
        // ));
        // newchains.push(NewChain(  // HUMANODE TESTNET ISRAFEL  Chain 14853
        //     14853,
            
        //     0x6dD69414E074575c45D5330d2707CAf80303a85B
        // ));
        // newchains.push(NewChain(   // CRONOS TESTNET   Chain 338
        //     338,
            
        //     0xf6d2060494cD08e776D22a47E67d485a33C8c5d2
        // ));
        newchains.push(NewChain(  //  BSC TESTNET Chain 97
            97,
            0xc0DD542BCaC26095A2C83fFb10826CCEf806C07b,
            0x7658E59CdbA5e7E08263a216e89c8438C9F02048,
            0x605Ab9626e57C5d1f3f0508D5400aB0449b5a015,
            0x855c06F9f7b01838DC540Ec6fcfF17fD86A378D8,
            0xDd43fc986a13392dDbC7aeA150b41EfE27b2d0eD
        ));
        newchains.push(NewChain(  //  SEPOLIA  Chain 11155111
            11155111,
            0xF065f9BbD5F59afa0D24BE34bDf8aD483485ED1C,
            0x1eE4bA474da815f728dF08F0147DeFac07F0BAb3,
            0x1e608FD1546e1bC1382Abc4E676CeFB7e314Fb30,
            0xCBf4E5FDA887e602E5132FA800d74154DFb5B237,
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
                ok = IFeeManager(thisFeeManager).setFeeMultiplier(FeeType.IMAGE, 2);
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
