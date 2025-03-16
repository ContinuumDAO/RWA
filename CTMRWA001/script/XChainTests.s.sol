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

        uint256 ID = 26654037064898864838309145093493456113595369659210875061410208439006009189861;


        // debugRwaXCall();

        // bytes32 uuid = 0x9521f78e716c509942f2b2b0167b089a447a04f6dc30afee8458e7d54a95637b;
        // checkC3Call(uuid);

        // decodeXChain();

        // checkDeployData();


        // uint256 idBack = deployLocal();

        
        toChainIdsStr.push("97");
        // toChainIdsStr.push("84532");
        // toChainIdsStr.push("59141");
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
            feeManager =  0x7e61a5AF95Fc6efaC03F7d92320F42B2c2fe96f0;
            gatewayAddr = 0xbab5Ec2802257958d3f3a34dcE2F7Aa65Eac922d;
            rwa001XAddr = 0xDB3caaE3A1fD4846bC2a7dDBcb2B7b4dbd3484b8;
            ctmFallbackAddr = 0x7323b2452Aa4839EB2501ACE128D710BE7e359aD;
            ctmRwa001Map = 0xcC9AC238318d5dBe97b20957c09aC09bA73Eeb25;
            ctmRwaDeployer =  0x13b17e90f430760eb038b83C5EBFd8082c027e00;
            ctmRwaFactory = 0xE367E5FE0aB98d81aC9C07A5a35386A6ddc83E2e;
            dividendAddr = 0x97161c4c66B11629f2d3211c8Bd8131705d64092;
            storageManagerAddr = 0xf55fB33d9BD6Bb47461d68890bc8F951480211FC;
            sentryManagerAddr = 0x998f9E69CF313d06b1D4BA22FeCE9c23D0D0Ca31;
        } else if(chainId == 80002) {    // on POLYGON AMOY
            feeToken = 0x6a4DBC971533Ba36bdc23aD70F5A7a12E064f4ae;
            feeManager = 0x2D2112DE9801EAf71B6D1cBf40A99E57AFc235a7;
            gatewayAddr = 0xb1bC63301670F8ec9EE98BD501c89783d65ddC8a;
            rwa001XAddr = 0xDf495F3724a6c705fed4aDfa7588Cd326162A39c;
            ctmFallbackAddr = 0x3672eB3780De1e08548CB3E2bB5DF05900063370;
            ctmRwa001Map = 0x18433A774aF5d473191903A5AF156f3Eb205bBA4;
            ctmRwaDeployer = 0x77Aa59Ba778C00946122E43702509c87b81604F5;
            ctmRwaFactory = 0x9BFaB09e477e0e931F292C8132F2579883C6921A;
            dividendAddr = 0xec66EE6116CF91FFC2a7Afc0dFb1cB882caab4D0;
            storageManagerAddr = 0xad49cabD336f943a9c350b9ED60680c54fa2c3d1;
            sentryManagerAddr = 0xC7a339588569Da96def78A96732eE20c3446BF11;
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
        //  } else if(chainId == 78600) {    // on VANGUARD
        //     feeToken = 0x6654D956A4487A26dF1186b01B689c26939544fC;
        //     feeManager = ;
        //     gatewayAddr = ;
        //     rwa001XAddr = ;
        //     ctmFallbackAddr = ;
        //     ctmRwa001Map = ;
        //     ctmRwaDeployer = ;
        //     ctmRwaFactory = ;
        //     dividendAddr = ;
        //     storageManagerAddr = ;
        // } else if(chainId == 5003) {    // on MANTLE
        //     feeToken = 0x6a4DBC971533Ba36bdc23aD70F5A7a12E064f4ae;
        //     feeManager = ;
        //     gatewayAddr = ;
        //     rwa001XAddr = ;
        //     ctmFallbackAddr = ;
        //     ctmRwa001Map = ;
        //     ctmRwaDeployer = ;
        //     ctmRwaFactory = ;
        //     dividendAddr = ;
        //     storageManagerAddr = ;
        //  } else if(chainId == 2810) {    // on MORPH HOLESKY
        //     feeToken = 0x6a4DBC971533Ba36bdc23aD70F5A7a12E064f4ae;
        //     feeManager = ;
        //     gatewayAddr = ;
        //     rwa001XAddr = ;
        //     ctmFallbackAddr = ;
        //     ctmRwa001Map = ;
        //     ctmRwaDeployer = ;
        //     ctmRwaFactory = ;
        //     dividendAddr = ;
        //     storageManagerAddr = ;
        // } else if(chainId == 168587773) {    // on BLAST
        //     feeToken = 0x5d5408e949594E535d0c3d533761Cb044E11b664;
        //     feeManager = ;
        //     gatewayAddr = ;
        //     rwa001XAddr = ;
        //     ctmFallbackAddr = ;
        //     ctmRwa001Map = ;
        //     ctmRwaDeployer = ;
        //     ctmRwaFactory = ;
        //     dividendAddr = ;
        //     storageManagerAddr = ;
        // } else if(chainId == 1952959480) {    // on LUMIA
        //     feeToken = 0x6a4DBC971533Ba36bdc23aD70F5A7a12E064f4ae;
        //     feeManager = 0x4f5b13A48d4fC78e154DDa6c49E39c6d59277213;
        //     gatewayAddr = ;
        //     rwa001XAddr = ;
        //     ctmFallbackAddr = ;
        //     ctmRwa001Map = ;
        //     ctmRwaDeployer = ;
        //     ctmRwaFactory = ;
        //     dividendAddr = ;
        //     storageManagerAddr = ;
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
        } else if(chainId == 153) {    // on REDBELLY
            feeToken = 0xe536Bf33585aa6bb528627Ed7Dc4D49009dafC58;
            feeManager = 0xb76428eBE853F2f6a5D74C4361B72999f55EE637;
            gatewayAddr = 0xDC635161b63Ca5281F96F2d70C3f7C0060d151d3;
            rwa001XAddr = 0x92BB6DEfEF73fa2ee42FeC2273d98693571bd7f3;
            ctmFallbackAddr = 0xD52966352E5A15DCB05CdfB4D8f54F565d487210;
            ctmRwa001Map = 0xf7Ed4f388e07Ab2B9138D1f7CF2F0Cf6B23820aF;
            ctmRwaDeployer = 0xE305d37aDBE6F7c987108F537dc247F8Df5C1F24;
            ctmRwaFactory = 0xc55A8332086781225EF371DEf7ED4F05C9F03B9e;
            dividendAddr = 0x4a82933a6d097a1f4c99880e4A3b4C7b7D291765;
            storageManagerAddr = 0x8641613849038f495FA8Dd313f13a3f7F2D73815;
            sentryManagerAddr =  0xA4dAb6Df348B312a5a0320D08ebEF76441178CFe;
        } else if(chainId == 84532) {    // on BASE SEPOLIA *
            feeToken = 0x6a4DBC971533Ba36bdc23aD70F5A7a12E064f4ae;
            feeManager = 0x91677ec1879987aBC3978fD2A71204640A9e9f4A;
            gatewayAddr = 0xe1C4c5a0e6A99bB61b842Bb78E5c66EA1256D292;
            rwa001XAddr = 0x6681DB630eB117050D78E0B89eB5619b35Ea12e8;
            ctmFallbackAddr = 0x64c90B0E66c665128cBA3f2D9c03f962bc340ECa;
            ctmRwa001Map = 0xCf46f23D86a672AF5614FBa6A7505031805EF5e2;
            ctmRwaDeployer = 0x11D5B22218A54981D27E0B6a6439Fd61589bf02a;
            ctmRwaFactory = 0x4cc54eb029f61C5dFBa1BA9F6EcBE01386B4D3A2;
            dividendAddr = 0xae57e6D1CfBCE6872F7d2bebdA2E09cdE089d0bC;
            storageManagerAddr = 0xE6d89DBE4113BDDc79c4D8256C3604d9Db291fEa;
            sentryManagerAddr = 0x0dB39536F72E19edFfd45e318b1Da9A3684679a2;
        } else if(chainId == 97) {  // BSC TESTNET
            feeToken = 0xDd43fc986a13392dDbC7aeA150b41EfE27b2d0eD;
            feeManager = 0x7ad438D2B3AC77D55c85275fD09d51Cec9Bb2987;
            gatewayAddr = 0xD362AFB113D7a2226aFf228F4FB161BEFd3b6BD4;
            rwa001XAddr = 0x2bBA6E0eDBe1aC6794B12B960A37156d9d07f009;
            ctmFallbackAddr = 0xC466f37824268183508f4DE28af274C84B70C986;
            ctmRwa001Map = 0x5F0C4a82BDE669347Add86CD13587ba40d29dAd6;
            ctmRwaDeployer = 0xd09A46f3a221a5595f4a71a24296787235bBb895;
            ctmRwaFactory = 0x001204b6e9A8B478cC6c08F74e5Ad56fd35a27AA;
            dividendAddr = 0x2fDbB139FB38520C2aD6CD30cF45b3C8E5633C65;
            storageManagerAddr = 0x0f92c2F73498BF195c6129b2528c64f3D0BED434;
            sentryManagerAddr = 0x2AD99B7D982B119848a647676C02663018A1928a;
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