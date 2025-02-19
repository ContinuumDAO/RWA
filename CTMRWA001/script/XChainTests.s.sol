// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.23;

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

    ICTMRWAGateway gateway;
    ICTMRWA001X rwa001X;
    ICTMRWA001StorageManager storageManager;
    ICTMRWA001XFallback ctmFallback;
    ICTMRWA001Dividend dividend;

    uint256 senderPrivateKey = vm.envUint("PRIVATE_KEY");
    address senderAccount = vm.addr(senderPrivateKey);



    function run() external {

        loadContracts(421614);


        // debugRwaXCall();

        // bytes32 uuid = 0x9521f78e716c509942f2b2b0167b089a447a04f6dc30afee8458e7d54a95637b;
        // checkC3Call(uuid);

        // decodeXChain();

        // checkDeployData();


        toChainIdsStr.push("421614");
        // deployLocal();

        
        // toChainIdsStr.push("97");
        // toChainIdsStr.push("84532");
        // deployRemote(0);
        createSlots(toChainIdsStr, 1);
        // getSlots(0,0);

        // mintLocalValue(0);

        // transferValueTokenToAddress();

        // this.transferValueWholeTokenToAddress();

        // addURI(toChainIdsStr);


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
            storageManagerAddr = 0xfefE834c4b32BF5DA89f7F0C059590719Fe3e3eE;
        // } else if(chainId == 80002) {    // on POLYGON AMOY
        //     feeToken = 0x6a4DBC971533Ba36bdc23aD70F5A7a12E064f4ae;
        //     feeManager = 0x4cDa22b59a1fE957D09273E533cCb7D44bdEf90C;
        //     gatewayAddr = 0x114ace1c918409889464c2a714f8442a97934Ccf;
        //     rwa001XAddr = 0x88a23d9ec1a9f1100d807D0E8c7a39927D4A7897;
        //     ctmFallbackAddr = 0x73B4143b7cd9617F9f29452f268479Bd513e3d23;
        //     ctmRwa001Map = 0x5dA80743b6FD7FEB2Bf7207aBe20E57E204e2B5b;
        //     ctmRwaDeployer = 0x9aF1e5b3e863d88A4E220fb07FfB8c2e5a96dDbd;
        //     ctmRwaFactory = 0x08A7Ac9982804D131b5523b6165a2EFAaF064C90;
        //     dividendAddr = 0x2d7E6446fd6938e692173F88946a9DeC52442A8b;
        //     storageManagerAddr = 0x95ae66aD780E73eF2D2a80611458883C950a1356;
        // } else if(chainId == 338) {    // on CRONOS
        //     feeToken = 0xf6d2060494cD08e776D22a47E67d485a33C8c5d2;
        //     feeManager = 0x1f8548Eb8Ec40294D7eD5e85DbF0F3BCE228C3Bc;
        //     gatewayAddr = 0xAE66C08b9d76EeCaA74314c60f3305D43707ACc9;
        //     rwa001XAddr = 0x176cD7aBF4919068d7FeC79935c303b32B7DabE7;
        //     ctmFallbackAddr = 0xf9EDcE2638da660F51Ee08220a1a5A32fAB61d61;
        //     ctmRwa001Map = 0x511A4e9af646E933c145A8892837547900078A97;
        //     ctmRwaDeployer = 0x37415B746B2eF7f37608006dDaA404d377fdF633;
        //     ctmRwaFactory = 0x5066e6DF1232532cEC032Ad45Cb29320f2b8D065;
        //     dividendAddr = 0x4f5b13A48d4fC78e154DDa6c49E39c6d59277213;
        //     storageManagerAddr = 0xb8B99101c1DBFaD6Aa418220592773be082Db804;
        //  } else if(chainId == 78600) {    // on VANGUARD
        //     feeToken = 0x6654D956A4487A26dF1186b01B689c26939544fC;
        //     feeManager = 0xa6e0Fa5cCEEf6e87d89B4DC51053E1Ff1A557B53;
        //     gatewayAddr = 0xeaDb6779c7284a7ef6f611f4535e60c3d59B321b;
        //     rwa001XAddr = 0x232c61b3d1A03cC57e976cCcD0F9C9Cd33a98fe0;
        //     ctmFallbackAddr = 0xEeFc94902e330CDd0f641Ac7b7E428F3a587320E;
        //     ctmRwa001Map = 0x12dC185A10F894e0bc2e55CF3f899970828c9ebE;
        //     ctmRwaDeployer = 0x2CD9F1d9000D8752cC7653e10f259f7D9a94A5E7;
        //     ctmRwaFactory = 0x99d26Ed0E4bb6659b56eE36DD9EE1814345aE9B9;
        //     dividendAddr = 0x630937764C9F8A4a08e33cE43A3f67d73752e341;
        //     storageManagerAddr = 0xC33b3317912d173806D782BFadE797f262d9A4Bd;
        // } else if(chainId == 5003) {    // on MANTLE
        //     feeToken = 0x6a4DBC971533Ba36bdc23aD70F5A7a12E064f4ae;
        //     feeManager = 0xd1F0743C665d80D6BDaf1b4B8C9E82bfd1aE1994;
        //     gatewayAddr = 0x9266e8bf4943f2b366F2be89688a8622084DB8B9;
        //     rwa001XAddr = 0xB5638019CBfC1B523d5167a269E755b05BF24fD9;
        //     ctmFallbackAddr = 0xBa1DCBCF5885BE9946286c965279BD426975B7f2;
        //     ctmRwa001Map = 0x59cBB22fbcBA3Df213f317A506dDeDBa5FCf9404;
        //     ctmRwaDeployer = 0x5a7Be43D528D75Ed78aAA16A9e3BF6A20a23B8A3;
        //     ctmRwaFactory = 0x4E3ab9d7871fba13dF6d45075B9141EAA18aD339;
        //     dividendAddr = 0x06edC167555ceb6038E2C6b3bED7A47C628F2Eed;
        //     storageManagerAddr = 0xa240B0714712e2927Ec055CEAa8e031AC671a55F;
        //  } else if(chainId == 2810) {    // on MORPH HOLESKY
        //     feeToken = 0x6a4DBC971533Ba36bdc23aD70F5A7a12E064f4ae;
        //     feeManager = 0xd1F0743C665d80D6BDaf1b4B8C9E82bfd1aE1994;
        //     gatewayAddr = 0x9266e8bf4943f2b366F2be89688a8622084DB8B9;
        //     rwa001XAddr = 0xB5638019CBfC1B523d5167a269E755b05BF24fD9;
        //     ctmFallbackAddr = 0xBa1DCBCF5885BE9946286c965279BD426975B7f2;
        //     ctmRwa001Map = 0x59cBB22fbcBA3Df213f317A506dDeDBa5FCf9404;
        //     ctmRwaDeployer = 0x5a7Be43D528D75Ed78aAA16A9e3BF6A20a23B8A3;
        //     ctmRwaFactory = 0x4E3ab9d7871fba13dF6d45075B9141EAA18aD339;
        //     dividendAddr = 0x06edC167555ceb6038E2C6b3bED7A47C628F2Eed;
        //     storageManagerAddr = 0xa240B0714712e2927Ec055CEAa8e031AC671a55F;
        // } else if(chainId == 168587773) {    // on BLAST
        //     feeToken = 0x5d5408e949594E535d0c3d533761Cb044E11b664;
        //     feeManager = 0xd1F0743C665d80D6BDaf1b4B8C9E82bfd1aE1994;
        //     gatewayAddr = 0x9266e8bf4943f2b366F2be89688a8622084DB8B9;
        //     rwa001XAddr = 0xB5638019CBfC1B523d5167a269E755b05BF24fD9;
        //     ctmFallbackAddr = 0xBa1DCBCF5885BE9946286c965279BD426975B7f2;
        //     ctmRwa001Map = 0x59cBB22fbcBA3Df213f317A506dDeDBa5FCf9404;
        //     ctmRwaDeployer = 0x5a7Be43D528D75Ed78aAA16A9e3BF6A20a23B8A3;
        //     ctmRwaFactory = 0x4E3ab9d7871fba13dF6d45075B9141EAA18aD339;
        //     dividendAddr = 0x06edC167555ceb6038E2C6b3bED7A47C628F2Eed;
        //     storageManagerAddr = 0xa240B0714712e2927Ec055CEAa8e031AC671a55F;
        // } else if(chainId == 1952959480) {    // on LUMIA
        //     feeToken = 0x6a4DBC971533Ba36bdc23aD70F5A7a12E064f4ae;
        //     feeManager = 0x4f5b13A48d4fC78e154DDa6c49E39c6d59277213;
        //     gatewayAddr = 0xd1F0743C665d80D6BDaf1b4B8C9E82bfd1aE1994;
        //     rwa001XAddr = 0x9266e8bf4943f2b366F2be89688a8622084DB8B9;
        //     ctmFallbackAddr = 0xB5638019CBfC1B523d5167a269E755b05BF24fD9;
        //     ctmRwa001Map = 0x02E77B34A4d16D9b00c7B4e787776327adB1344C;
        //     ctmRwaDeployer = 0xA7EC64D41f32FfE662A46B62E59D1EBFEaD52522;
        //     ctmRwaFactory = 0x8641613849038f495FA8Dd313f13a3f7F2D73815;
        //     dividendAddr = 0xa240B0714712e2927Ec055CEAa8e031AC671a55F;
        //     storageManagerAddr = 0xde3Fdb278B0EC3254E8701c38e58CFd1168f13a5;
        // } else if(chainId == 14853) {    // on HUMANODE
        //     feeToken = 0x6dD69414E074575c45D5330d2707CAf80303a85B;
        //     feeManager = 0xd1F0743C665d80D6BDaf1b4B8C9E82bfd1aE1994;
        //     gatewayAddr = 0x9266e8bf4943f2b366F2be89688a8622084DB8B9;
        //     rwa001XAddr = 0xB5638019CBfC1B523d5167a269E755b05BF24fD9;
        //     ctmFallbackAddr = 0xBa1DCBCF5885BE9946286c965279BD426975B7f2;
        //     ctmRwa001Map = 0x59cBB22fbcBA3Df213f317A506dDeDBa5FCf9404;
        //     ctmRwaDeployer = 0x5a7Be43D528D75Ed78aAA16A9e3BF6A20a23B8A3;
        //     ctmRwaFactory = 0x4E3ab9d7871fba13dF6d45075B9141EAA18aD339;
        //     dividendAddr = 0x06edC167555ceb6038E2C6b3bED7A47C628F2Eed;
        //     storageManagerAddr = 0xa240B0714712e2927Ec055CEAa8e031AC671a55F;
        // } else if(chainId == 997) {    // on 5IRE
        //     feeToken = 0x6a4DBC971533Ba36bdc23aD70F5A7a12E064f4ae;
        //     feeManager = 0x67510816512511818B5047a4Cce6E8f2ebB15d20;
        //     gatewayAddr = 0xF4e7a775c8aBC8e0B7ed11d660b0a6b2e1B7a132;
        //     rwa001XAddr = 0x73943Ec95AaFBb4DD073b11F5c9701E5Bc3708A6;
        //     ctmFallbackAddr = 0xcDEcbA8e8a537823733238225df54Cc212d681Cd;
        //     ctmRwa001Map = 0xAc71dCF325724594525cc05552beE7D6550a80fD;
        //     ctmRwaDeployer = 0x64C5734e22cf8126c6367c0230B66788fBE4AB90;
        //     ctmRwaFactory = 0xa7C57315395def05F906310d590f4ea15308fe30;
        //     dividendAddr = 0xce0b17dD3C7Ad94eF7B6F75d67521c8870b31282;
        //     storageManagerAddr = 0x4b17E8eE1cC1814636DDe9Ac12a42472799CCB64;
        // } else if(chainId == 84532) {    // on BASE SEPOLIA
        //     feeToken = ;
        //     feeManager = ;
        //     gatewayAddr = ;
        //     rwa001XAddr = ;
        //     ctmFallbackAddr = ;
        //     ctmRwa001Map = ;
        //     ctmRwaDeployer = ;
        //     ctmRwaFactory = ;
        //     dividendAddr = ;
        //     storageManagerAddr = ;
        // } else if(chainId == 97) {  // BSC TESTNET
        //     feeToken = ;
        //     feeManager = ;
        //     gatewayAddr = ;
        //     rwa001XAddr = ;
        //     ctmFallbackAddr = ;
        //     ctmRwa001Map = ;
        //     ctmRwaDeployer = ;
        //     ctmRwaFactory = ;
        //     dividendAddr = ;
        //     storageManagerAddr = ;
        }

        gateway = ICTMRWAGateway(gatewayAddr);
        rwa001X = ICTMRWA001X(rwa001XAddr);
        storageManager = ICTMRWA001StorageManager(storageManagerAddr);
        ctmFallback = ICTMRWA001XFallback(ctmFallbackAddr);
        dividend = ICTMRWA001Dividend(dividendAddr);
        feeTokenStr = feeToken.toHexString();
    }

    function deployLocal() public {

        vm.startBroadcast(senderPrivateKey);

        IERC20(feeToken).approve(rwa001XAddr, 1000*10**ITheiaERC20(feeToken).decimals());

        string[] memory chainIdsStr;

        uint256 IdBack = rwa001X.deployAllCTMRWA001X(true, 0, 1, 1, "Roses in Summer", "ROSE", 18, "GFLD", chainIdsStr, feeTokenStr);
        console.log(IdBack);

        vm.stopBroadcast();
    }

    function deployRemote(uint256 indx) public {

        vm.startBroadcast(senderPrivateKey);

        IERC20(feeToken).approve(rwa001XAddr, 1000*10**ITheiaERC20(feeToken).decimals());


        address[] memory adminTokens = rwa001X.getAllTokensByAdminAddress(admin);
        console.log("First admin token address");
        console.log(adminTokens[indx]);

        (, uint256 ID) = ICTMRWAMap(ctmRwa001Map).getTokenId(adminTokens[indx].toHexString(), 1, 1);
        console.log("ID");
        console.log(ID);

        // address[] memory nRWA001 = rwa001X.getAllTokensByOwnerAddress(admin);

        // uint256 newTokenId = rwa001X.mintNewTokenValueLocal(senderAccount, 0, 0, 1450, ID);

        // uint256 tokenId = ICTMRWA001(adminTokens[indx]).tokenOfOwnerByIndex(admin, 0);
        // console.log("tokenId");
        // console.log(tokenId);

        string memory tokenName = ICTMRWA001(adminTokens[indx]).name();
        string memory symbol = ICTMRWA001(adminTokens[indx]).symbol();
        uint8 decimals = ICTMRWA001(adminTokens[indx]).valueDecimals();
        string memory baseURI = ICTMRWA001(adminTokens[indx]).baseURI();


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

        uint256 IdBack = rwa001X.deployAllCTMRWA001X(false, ID, 1, 1, tokenName, symbol, decimals, baseURI, toChainIdsStr, feeTokenStr);

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

    function createSlots(string[] memory chainIdsStr, uint256 indx) public {
        vm.startBroadcast(senderPrivateKey);

        address[] memory adminTokens = rwa001X.getAllTokensByAdminAddress(admin);
        console.log("admin token address");
        console.log(adminTokens[indx]);

        address tokenAddr = adminTokens[indx];

        (, uint256 ID) = ICTMRWAMap(ctmRwa001Map).getTokenId(tokenAddr.toHexString(), 1, 1);
        console.log("ID");
        console.log(ID);

        IERC20(feeToken).approve(rwa001XAddr, 10000*10**ITheiaERC20(feeToken).decimals());


        // function createNewSlot(
        //     uint256 _ID,
        //     uint256 _slot,
        //     string memory _slotName,
        //     string[] memory _toChainIdsStr,
        //     string memory _feeTokenStr
        // ) public returns(bool) 

        bool ok = rwa001X.createNewSlot(
            ID,
            0,
            "Pink closed from Amsterdam",
            chainIdsStr,
            feeTokenStr
        );

        vm.stopBroadcast();
    }

    function getSlots(uint256 tokenIndx, uint256 slotIndx) public {

        address[] memory adminTokens = rwa001X.getAllTokensByAdminAddress(admin);
        console.log("admin token address");
        console.log(adminTokens[tokenIndx]);

        address tokenAddr = adminTokens[tokenIndx];

        (uint256[] memory slotNumbers, string[] memory slotNames) = ICTMRWA001(tokenAddr).getAllSlots();

        console.log("SlotData - slot");
        console.log(slotNumbers[slotIndx]);
        console.log("SlotData - slotName");
        console.log(slotNames[slotIndx]);

    }

    function mintLocalValue(uint256 indx) public {

        vm.startBroadcast(senderPrivateKey);

        IERC20(feeToken).approve(rwa001XAddr, 10000*10**ITheiaERC20(feeToken).decimals());


        address[] memory adminTokens = rwa001X.getAllTokensByAdminAddress(admin);
        console.log("First admin token address");
        console.log(adminTokens[indx]);

        (, uint256 ID) = ICTMRWAMap(ctmRwa001Map).getTokenId(adminTokens[indx].toHexString(), 1, 1);
        console.log("ID");
        console.log(ID);

        address[] memory nRWA001 = rwa001X.getAllTokensByOwnerAddress(admin);

        uint256 newTokenId = rwa001X.mintNewTokenValueLocal(senderAccount, 0, 6, 1450, ID);
        console.log("newTokenId = ");
        console.log(newTokenId);

        vm.stopBroadcast();

    }
   
    function transferValueTokenToAddress() public {

        vm.startBroadcast(senderPrivateKey);

        IERC20(feeToken).approve(rwa001XAddr, 10000*10**ITheiaERC20(feeToken).decimals());

        address[] memory adminTokens = rwa001X.getAllTokensByAdminAddress(admin);
        console.log("First admin token address");
        console.log(adminTokens[0]);

        address firstTokenAddr = adminTokens[0];

        (, uint256 ID) = ICTMRWAMap(ctmRwa001Map).getTokenId(firstTokenAddr.toHexString(), 1, 1);
        console.log("ID");
        console.log(ID);

        uint256 tokenId = ICTMRWA001(firstTokenAddr).tokenOfOwnerByIndex(admin, 0);
        console.log("tokenId");
        console.log(tokenId);
        console.log("with slot =");
        console.log(ICTMRWA001(firstTokenAddr).slotOf(tokenId));

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
            ID,
            feeTokenStr
        );

    }



    function transferValueWholeTokenToAddress() public {
        vm.startBroadcast(senderPrivateKey);

        IERC20(feeToken).approve(rwa001XAddr, 10000*10**ITheiaERC20(feeToken).decimals());

        address[] memory adminTokens = rwa001X.getAllTokensByAdminAddress(admin);
        console.log("First admin token address");
        console.log(adminTokens[0]);

        address firstTokenAddr = adminTokens[0];

        (, uint256 ID) = ICTMRWAMap(ctmRwa001Map).getTokenId(firstTokenAddr.toHexString(), 1, 1);
        console.log("ID");
        console.log(ID);

        uint256 tokenId = ICTMRWA001(firstTokenAddr).tokenOfOwnerByIndex(admin, 2);
        console.log("second tokenId");
        console.log(tokenId);

        console.log("with slot");
        console.log(ICTMRWA001(firstTokenAddr).slotOf(tokenId));

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
            ID,
            feeTokenStr
        );

        vm.stopBroadcast();

    }


    function addURI(string[] memory chainIdsStr) public {

        vm.startBroadcast(senderPrivateKey);

        IERC20(feeToken).approve(storageManagerAddr, 1000*10**ITheiaERC20(feeToken).decimals());

       
        address[] memory adminTokens = rwa001X.getAllTokensByAdminAddress(admin);
        console.log("First admin token address");
        console.log(adminTokens[0]);

        address firstTokenAddr = adminTokens[0];

        (, uint256 ID) = ICTMRWAMap(ctmRwa001Map).getTokenId(firstTokenAddr.toHexString(), 1, 1);
        console.log("ID");
        console.log(ID);

        (bool ok, address stor) = ICTMRWAMap(ctmRwa001Map).getStorageContract(ID, 1, 1);
        console.log("Storage contract for ID = ");
        console.log(stor);

        uint256 tokenId = ICTMRWA001(firstTokenAddr).tokenOfOwnerByIndex(admin, 0);
        console.log("first tokenId");
        console.log(tokenId);

        uint256 slot = ICTMRWA001(firstTokenAddr).slotOf(tokenId);

        console.log("with slot");
        console.log(slot);

        // string memory randomData = "this is any old data";
        // bytes32 junkHash = keccak256(abi.encode(randomData));
        bytes32 junkHash = 0x63d458cf12f8c32326328cf36fb8dcf454c0e5dc9ab36a9ecd8366b22a8b5215;

        console.log("junkHash");
        console.logBytes32(junkHash);


        storageManager.addURI(
            ID,
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