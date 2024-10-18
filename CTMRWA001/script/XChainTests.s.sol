// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.23;

import {Script} from "forge-std/Script.sol";
import "forge-std/console.sol";

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {IC3Caller} from "../contracts/c3Caller/IC3Caller.sol";
import {IUUIDKeeper} from "../contracts/c3Caller/IUUIDKeeper.sol";

import {ICTMRWA001} from "../contracts/interfaces/ICTMRWA001.sol";
import {ICTMRWAGateway} from "../contracts/interfaces/ICTMRWAGateway.sol";
import {ICTMRWA001X} from "../contracts/interfaces/ICTMRWA001X.sol";
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
    address feeToken = 0x1eE4bA474da815f728dF08F0147DeFac07F0BAb3;
    string feeTokenStr = feeToken.toHexString();
    
    string[] toChainIdsStr;

    address c3 = 0x770c70D44C0c7b5B7D805077B66daADC00480FbC;  // on Arb Sepolia
    address c3UUIDKeeper = 0x034a2688912A880271544dAE915a9038d9D20229;

    address feeManager = 0xCA89ae89EFa4D49150237038D63562247d17Ca1C;  // Arb Sepolia
    address gatewayAddr =  0x8Ea9B4616e5653CF21B87e60c8D72d8384685ec6;
    address rwa001XAddr = 0x5330db730fAb0Bf0bB9db2FCefe7b1876c09a242;
    address ctmFallbackAddr = 0xd49BcC86916d744B965F1B8C2517F8dbCAcb3887;
    address ctmRwa001Map = 0x3B63cD222C5080cDeA921B8D3cF4A692b8DfEE4D;
    address ctmRwaDeployer = 0xa7441037961E31D4b64Aca57417d7673FEdC8fEC;
    address ctmRwaFactory = 0x93637D7068CEebC6cCDCB230E3AE65436666fe15;
    address dividendAddr = 0x797AA64f83e4d17c2C6C80321f22445AAB153630;
    address storageManagerAddr = 0x1249d751e6a0b7b11b9e55CBF8bC7d397AC3c083;

    ICTMRWAGateway gateway = ICTMRWAGateway(gatewayAddr);
    ICTMRWA001X rwa001X = ICTMRWA001X(rwa001XAddr);
    ICTMRWA001XFallback ctmFallback = ICTMRWA001XFallback(ctmFallbackAddr);
    ICTMRWA001Dividend dividend = ICTMRWA001Dividend(dividendAddr);

    uint256 senderPrivateKey = vm.envUint("PRIVATE_KEY");
    address senderAccount = vm.addr(senderPrivateKey);


    function run() external {

        // bytes32 uuid = 0x2d91e8c9105c329e9619683df2904341c0c3f94f29e264f0bada0e15fd3045d2;
        // checkC3Call(uuid);

        // checkDeployData();

        // this.deployLocal();

        // this.deployRemote();

        // this.transferValueTokenToAddress();

        // this.addURI();

        // this.transferValueTokenToToken();

        // this.transferValueWholeTokenToAddress();

        this.mintNewTokenValueX();
    }

    function mintNewTokenValueX() external {

        vm.startBroadcast(senderPrivateKey);

        address[] memory adminTokens = rwa001X.getAllTokensByAdminAddress(admin);
        console.log("First admin token address");
        console.log(adminTokens[0]);

        address firstTokenAddr = adminTokens[0];

        (, uint256 ID) = ICTMRWAMap(ctmRwa001Map).getTokenId(firstTokenAddr.toHexString(), 1, 1);

        // uint256 bal = IERC20(feeToken).balanceOf(admin);

        // IERC20(feeToken).approve(address(rwa001X), 100000);

        // function mintNewTokenValueX(
        //     string memory _toAddressStr,
        //     string memory _toChainIdStr,
        //     uint256 _slot,
        //     uint256 _value,
        //     uint256 _ID,
        //     string memory _feeTokenStr
        // ) public {

        rwa001X.mintNewTokenValueX(
            admin.toHexString(),
            "200810",
            4,
            1234,
            ID,
            feeTokenStr
        );

    }

    function transferValueTokenToAddress() external {

        vm.startBroadcast(senderPrivateKey);

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

        // function transferFromX(
        //     uint256 _fromTokenId,
        //     string memory _toAddressStr,
        //     string memory _toChainIdStr,
        //     uint256 _value,
        //     uint256 _ID,
        //     string memory _feeTokenStr
        // ) public {

        rwa001X.transferFromX(
            tokenId,
            admin.toHexString(),
            "97",
            50,
            ID,
            feeTokenStr
        );

    }

    function transferValueTokenToToken() external {

        vm.startBroadcast(senderPrivateKey);

        address[] memory adminTokens = rwa001X.getAllTokensByAdminAddress(admin);
        console.log("First admin token address");
        console.log(adminTokens[0]);

        address firstTokenAddr = adminTokens[0];

        (, uint256 ID) = ICTMRWAMap(ctmRwa001Map).getTokenId(firstTokenAddr.toHexString(), 1, 1);
        console.log("ID");
        console.log(ID);

        uint256 tokenId = ICTMRWA001(firstTokenAddr).tokenOfOwnerByIndex(admin, 1);
        console.log("second tokenId");
        console.log(tokenId);

        console.log("with slot");
        console.log(ICTMRWA001(firstTokenAddr).slotOf(tokenId));

    // function transferFromX(
    //     uint256 _fromTokenId,
    //     string memory _toAddressStr,
    //     uint256 _toTokenId,
    //     string memory _toChainIdStr,
    //     uint256 _value,
    //     uint256 _ID,
    //     string memory _feeTokenStr
    // ) public {

        rwa001X.transferFromX(
            tokenId,
            admin.toHexString(),
            1,
            "97",
            100,
            ID,
            feeTokenStr
        );

    }

    function transferValueWholeTokenToAddress() public {
        vm.startBroadcast(senderPrivateKey);

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

        // function transferFromX(
        //     string memory _toAddressStr,
        //     string memory _toChainIdStr,
        //     uint256 _fromTokenId,
        //     uint256 _ID,
        //     string memory _feeTokenStr
        // ) public {

        rwa001X.transferFromX(
            admin.toHexString(),
            "97",
            tokenId,
            ID,
            feeTokenStr
        );

    }


    function deployLocal() external {
       
        address ctmRwaDeployer = rwa001X.ctmRwaDeployer();

        vm.startBroadcast(senderPrivateKey);

        string[] memory chainIdsStr;

        uint256 IdBack = rwa001X.deployAllCTMRWA001X(true, 0, 1, 1, "Selqui SQ1", "SQ1", 18, "/Selqui", chainIdsStr, feeTokenStr);
    }

    function deployRemote() external {

        address ctmRwaDeployer = rwa001X.ctmRwaDeployer();

        vm.startBroadcast(senderPrivateKey);

        address[] memory adminTokens = rwa001X.getAllTokensByAdminAddress(admin);
        console.log("First admin token address");
        console.log(adminTokens[0]);

        (, uint256 ID) = ICTMRWAMap(ctmRwa001Map).getTokenId(adminTokens[0].toHexString(), 1, 1);
        console.log("ID");
        console.log(ID);

        address[] memory nRWA001 = rwa001X.getAllTokensByOwnerAddress(admin);

        uint256 newTokenId = rwa001X.mintNewTokenValueLocal(senderAccount, 0, 0, 1450, ID);

        uint256 tokenId = ICTMRWA001(adminTokens[0]).tokenOfOwnerByIndex(admin, 0);
        console.log("tokenId");
        console.log(tokenId);

        string memory tokenName = ICTMRWA001(adminTokens[0]).name();
        string memory symbol = ICTMRWA001(adminTokens[0]).symbol();
        uint8 decimals = ICTMRWA001(adminTokens[0]).valueDecimals();
        string memory baseURI = ICTMRWA001(adminTokens[0]).baseURI();

        toChainIdsStr.push("200810");

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

    function addURI() public {

        vm.startBroadcast(senderPrivateKey);

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

        toChainIdsStr.push("421614");
        toChainIdsStr.push("97");


        // function _addURI(
        //     uint256 _ID,
        //     URICategory _uriCategory,
        //     URIType _uriType,
        //     uint256 _slot,   
        //     bytes32 _uriDataHash,
        //     string[] memory _chainIdsStr
        // ) external {

        rwa001X._addURI(
            ID,
            URICategory.PROVENANCE,
            URIType.SLOT,
            slot,
            junkHash,
            toChainIdsStr
        );

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

}