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

        bytes32 uuid = 0x0af4db05db5de1fe5bf857058d248429a9b590d7ba9b0d9303245791707e87f4;
        checkC3Call(uuid);

        // decodeXChain();

        // checkDeployData();

        // this.deployLocal();

        //IERC20(feeToken).approve(feeManager, 10000*10**18);
        // IERC20(feeToken).approve(rwa001XAddr, 10000*10**6);

        // this.deployRemote(97, 0);

        // this.transferValueTokenToAddress();

        // this.addURI();

        // this.transferValueTokenToToken();

        // this.transferValueWholeTokenToAddress();

        // this.mintNewTokenValueX();
    }

    function loadContracts(uint256 chainId) public {
        if(chainId == 421614) {   // On ARB SEPOLIA
            // c3UUIDKeeper = ;
            feeToken = 0x92829288C6Aa874c1A0F190dA35A4023C22be637;
            feeManager = 0x9068F274555af3cD0A934Dbcf1c56E7b83Ad450A;
            gatewayAddr =  0x358498985E6ac7CA73F5110b415525aE04CB8313;
            rwa001XAddr = 0x9DC772b55e95A630031EBe431706D105af01Cf03;
            ctmFallbackAddr =   0xad49cabD336f943a9c350b9ED60680c54fa2c3d1;
            ctmRwa001Map = 0x68A5Ec275ade39a59B058ABA931E6D41bc39F833;
            ctmRwaDeployer = 0x0EeA0C2FB4122e8193E26B06358E384b2b909848;
            ctmRwaFactory = 0xC7a339588569Da96def78A96732eE20c3446BF11;
            dividendAddr = 0x890205BF3Ad9737AFaF27cc8bb51291E6A135f48;
            storageManagerAddr = 0xc047401F28F43eC8Af8C5aAaC26Bf7d007E2474a;

        } else if(chainId == 84532) {    // on BASE SEPOLIA
            feeToken = 0x6a4DBC971533Ba36bdc23aD70F5A7a12E064f4ae;
            feeManager = 0xeCd4b2ab820215AcC3Cd579B8e65530D44A83643;
            gatewayAddr =  0x6640eC42F86ABCF799C21A070f7bAF6Db38a2AB9;
            rwa001XAddr = 0x8230abAb39F9C618282dDd0AF1DFA278DE7Df98f;
            ctmFallbackAddr =   0x8be9dda9F320c0D9598A487E3C8F57196d53AcAe;
            ctmRwa001Map = 0x127d5ADA49071c33d10AA8de441e218a71475119;
            ctmRwaDeployer = 0x05a804374Bb77345854022Fd0CD2A602E00bF2E7;
            ctmRwaFactory = 0xFC63DC90296800c67cBb96330238fc17FbD674A2;
            dividendAddr = 0xEd3c7279F4175F88Ab6bBcd16c8B8214387725e7;
            storageManagerAddr = 0xAF685f104E7428311F25526180cbd416Fa8668CD;
        } else if(chainId == 97) {  // 
            feeToken = 0xDd43fc986a13392dDbC7aeA150b41EfE27b2d0eD;
            feeManager = 0x41543A4C6423E2546FC58AC63117B5692D68c323;
            gatewayAddr =  0x969035b34B913c507b87FD805Fff608FB1fE13f0;
            rwa001XAddr = 0x66b719C489193594c617801e67119959CD15b63A;
            ctmFallbackAddr =   0x5Fb1394608Ce2Ef7092A642d6c5D3b2325300bFD;
            ctmRwa001Map = 0xe96270a4DeFb602d8C7E5aDB7f090EAC5291A641;
            ctmRwaDeployer = 0x766061Cd28592Fd2503cAA3E4772C1215192cD3d;
            ctmRwaFactory = 0xa78f13ddB2538e76ed0EB66F3B0c36d77c237Ab8;
            dividendAddr = 0x208a83079E25e17fe5dC64BbB77e388FEe725A99;
            storageManagerAddr = 0xE569c146B0d4c1c941607b5c6A648b5877AE29EF;
        }

        gateway = ICTMRWAGateway(gatewayAddr);
        rwa001X = ICTMRWA001X(rwa001XAddr);
        storageManager = ICTMRWA001StorageManager(storageManagerAddr);
        ctmFallback = ICTMRWA001XFallback(ctmFallbackAddr);
        dividend = ICTMRWA001Dividend(dividendAddr);
        feeTokenStr = feeToken.toHexString();
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
            "97",
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

        vm.stopBroadcast();

    }


    function deployLocal() external {
       
        //address ctmRwaDeployer = rwa001X.ctmRwaDeployer();

        vm.startBroadcast(senderPrivateKey);

        string[] memory chainIdsStr;

        uint256 IdBack = rwa001X.deployAllCTMRWA001X(true, 0, 1, 1, "Selqui SQ1", "SQ1", 18, "GFLD", chainIdsStr, feeTokenStr);
    
        vm.stopBroadcast();
    }

    function deployRemote(uint256 _toChainId, uint256 indx) external {

        // address ctmRwaDeployer = rwa001X.ctmRwaDeployer();

        vm.startBroadcast(senderPrivateKey);


        address[] memory adminTokens = rwa001X.getAllTokensByAdminAddress(admin);
        console.log("First admin token address");
        console.log(adminTokens[indx]);

        (, uint256 ID) = ICTMRWAMap(ctmRwa001Map).getTokenId(adminTokens[indx].toHexString(), 1, 1);
        console.log("ID");
        console.log(ID);

        address[] memory nRWA001 = rwa001X.getAllTokensByOwnerAddress(admin);

        uint256 newTokenId = rwa001X.mintNewTokenValueLocal(senderAccount, 0, 0, 1450, ID);

        uint256 tokenId = ICTMRWA001(adminTokens[indx]).tokenOfOwnerByIndex(admin, 0);
        console.log("tokenId");
        console.log(tokenId);

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

        storageManager._addURI(
            ID,
            URICategory.PROVENANCE,
            URIType.SLOT,
            slot,
            bytes("proof_that_the_asset_exists"),
            junkHash,
            toChainIdsStr
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