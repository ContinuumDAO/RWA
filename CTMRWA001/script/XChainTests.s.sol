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

        loadContracts(84532);


        // debugRwaXCall();

        // bytes32 uuid = 0x0af4db05db5de1fe5bf857058d248429a9b590d7ba9b0d9303245791707e87f4;
        // checkC3Call(uuid);

        // decodeXChain();

        // checkDeployData();

        // deployLocal();

        // deployRemote(97, 0);

        toChainIdsStr.push("97");
        toChainIdsStr.push("84532");
        // createSlots(toChainIdsStr, 0);
        // getSlots(0,0);

        // mintLocalValue(0);

        // transferValueTokenToAddress();

        // this.transferValueWholeTokenToAddress();

        addURI(toChainIdsStr);


    }

    function loadContracts(uint256 chainId) public {
        if(chainId == 421614) {   // On ARB SEPOLIA
            // c3UUIDKeeper = ;
            feeToken = 0x92829288C6Aa874c1A0F190dA35A4023C22be637;
            feeManager = 0x3Dd9BB1ff0e52390c1BC16f1aB77608a2C7631c4;
            gatewayAddr = 0x9b81c6A2A62EEA2A814AFDBB5D69CE0592E1C751;
            rwa001XAddr = 0xe0f1cd117107457Bc14c2f1b82E218157c2a620c;
            ctmFallbackAddr = 0xdb23084993Cc7647c7210fb8d096b19188601783;
            ctmRwa001Map = 0x53C42f0AE7BbBD3c5c1336d7E87a9408EC27b90F;
            ctmRwaDeployer = 0x24b34AB7851871E761cd502dbCAD5a461eE5d4D8;
            ctmRwaFactory = 0x975715Af31AF252a5A8788ea369D13021675ABAf;
            dividendAddr = 0x2E3dD74986BD4c23b048090794259ca09402b61F;
            storageManagerAddr = 0x78e9F16b42508a9BC0892bFF922c09067de08Fc5;
        } else if(chainId == 84532) {    // on BASE SEPOLIA
            feeToken = 0x6a4DBC971533Ba36bdc23aD70F5A7a12E064f4ae;
            feeManager = 0x9BFaB09e477e0e931F292C8132F2579883C6921A;
            gatewayAddr = 0x2d1967eF42ECf9a42785D08398aADba806Aa090B;
            rwa001XAddr = 0xA09E913fa1aA5383a90aD6d8B94BC3DaBeE90332;
            ctmFallbackAddr = 0xBa59F04dbdcB1B74d601fbBF3E7e1ca82081c536;
            ctmRwa001Map = 0xE881090c0635c60EA579B5ABa3eef25Ac6a9599a;
            ctmRwaDeployer = 0x88802732af13061009363B12256A446DaEd6Fb81;
            ctmRwaFactory = 0x9d3fA9C6436D9b447aB548458d3167B166A85F83;
            dividendAddr = 0xF7B712f57e4227a9CE876A482762a0F5a67b2B8E;
            storageManagerAddr = 0xa840A5eC6557DF201a6a1561DbDc8AD6f3B3fAF4;
        } else if(chainId == 97) {  // BSC TESTNET
            feeToken = 0xDd43fc986a13392dDbC7aeA150b41EfE27b2d0eD;
            feeManager = 0xf204b97DBbba1bed029Bd13bef456d1A17dA9Bf9;
            gatewayAddr = 0x1392fC45312550197adF2039de80e8DA58fc72A3;
            rwa001XAddr = 0xC5070659D0290f2Eb2B1eD886f3F7574fde5C4Be;
            ctmFallbackAddr = 0xC18200720f76B30DB33cEB20eF18DEaC96e32671;
            ctmRwa001Map = 0x0Cd62Ee006ea6ef99EEcd69085315Ebc66786772;
            ctmRwaDeployer = 0x89251083bEFB84486cE91407f40634c0E547Cc0e;
            ctmRwaFactory = 0x6C67D4fb441f56F4E2dDb197d4347c244Fcd3bC8;
            dividendAddr = 0xC813b7b87712f7Aad5c0a3aca49177DBee2D1a70;
            storageManagerAddr = 0x8159be9135ecC4893826E40cf19047a79c523008;
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

        uint256 IdBack = rwa001X.deployAllCTMRWA001X(true, 0, 1, 1, "Selqui SQ1", "SQ1", 18, "GFLD", chainIdsStr, feeTokenStr);
    
        vm.stopBroadcast();
    }

    function deployRemote(uint256 _toChainId, uint256 indx) public {

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

        toChainIdsStr.push(_toChainId.toString());

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
            6,
            "Another new RWA",
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

        uint256 tokenId = ICTMRWA001(firstTokenAddr).tokenOfOwnerByIndex(admin, 0);
        console.log("first tokenId");
        console.log(tokenId);

        uint256 slot = ICTMRWA001(firstTokenAddr).slotOf(tokenId);

        console.log("with slot");
        console.log(slot);

        string memory randomData = "this is any old data";
        bytes32 junkHash = keccak256(abi.encode(randomData));

        console.log("junkHash");
        console.logBytes32(junkHash);

        // function addURI(
        //     uint256 _ID,
        //     URICategory _uriCategory,
        //     URIType _uriType,
        //     uint256 _slot,
        //     bytes32 _uriDataHash,
        //     string[] memory _chainIdsStr,
        //     string memory _feeTokenStr
        // ) public {


        storageManager.addURI(
            ID,
            URICategory.ISSUER,
            URIType.CONTRACT,
            slot,
            junkHash,
            chainIdsStr,
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