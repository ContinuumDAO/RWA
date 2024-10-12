// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.23;

import {Script} from "forge-std/Script.sol";
import "forge-std/console.sol";

import "@openzeppelin/contracts/utils/Strings.sol";

import {IC3Caller} from "../contracts/c3Caller/IC3Caller.sol";
import {IUUIDKeeper} from "../contracts/c3Caller/IUUIDKeeper.sol";

import {ICTMRWA001} from "../contracts/interfaces/ICTMRWA001.sol";
import {ICTMRWAGateway} from "../contracts/interfaces/ICTMRWAGateway.sol";
import {ICTMRWA001X} from "../contracts/interfaces/ICTMRWA001X.sol";
import {ICTMRWADeployer} from "../contracts/interfaces/ICTMRWADeployer.sol";
import {ICTMRWAMap} from "../contracts/interfaces/ICTMRWAMap.sol";
import {ICTMRWA001Token} from "../contracts/interfaces/ICTMRWA001Token.sol";
import {ICTMRWA001XFallback} from "../contracts/interfaces/ICTMRWA001XFallback.sol";
import {ICTMRWA001Dividend} from "../contracts/interfaces/ICTMRWA001Dividend.sol";

interface IDKeeper {
    function isUUIDExist(bytes32) external returns(bool);
}

contract XChainTests is Script {
    using Strings for *;

    address admin = 0xe62Ab4D111f968660C6B2188046F9B9bA53C4Bae;
    address gov = admin;
    address feeToken = 0x2A2a5e1e2475Bf35D8F3f85D8C736f376BDb1C02;
    string feeTokenStr = feeToken.toHexString();
    
    string[] toChainIdsStr;

    address c3 = 0x770c70D44C0c7b5B7D805077B66daADC00480FbC;  // on Arb Sepolia
    address c3UUIDKeeper = 0x034a2688912A880271544dAE915a9038d9D20229;

    address gatewayAddr = 0x699DE1Ff83FaD8c40Aea628975e1B3Ee71Dcfb56;  // Arb Sepolia
    address rwa001XAddr = 0xB37C81d6f90A16bbD778886AF49abeBfD1AD02C7;
    address ctmFallbackAddr = 0xF663c3De2d18920ffd7392242459275d0Dd249e4;
    address dividendAddr = 0xa3325B2fA099c81a06d9b7532317d4a4Da7F2aB7;

    ICTMRWAGateway gateway = ICTMRWAGateway(gatewayAddr);
    ICTMRWA001X rwa001X = ICTMRWA001X(rwa001XAddr);
    ICTMRWA001XFallback ctmFallback = ICTMRWA001XFallback(ctmFallbackAddr);
    ICTMRWA001Dividend dividend = ICTMRWA001Dividend(dividendAddr);

    function run() external {

        // bytes32 uuid = 0xc38cb2630185f377010c4955e6705726ce8347ba69bf5987eada14da45e48756;

        // checkC3Call(uuid);

        checkDeployData();
    }

    // function deployRemote() external {

    //     uint256 senderPrivateKey = vm.envUint("PRIVATE_KEY");
    //     address senderAccount = vm.addr(senderPrivateKey);

    //     address ctmRwaDeployer = rwa001X.ctmRwaDeployer();

    //     vm.startBroadcast(senderPrivateKey);

    //     address[] memory adminTokens = rwa001X.getAllTokensByAdminAddress(admin);
    //     console.log("First admin token address");
    //     console.log(adminTokens[0]);

    //     (, uint256 ID) = ICTMRWADeployer(ctmRwaDeployer).getAttachedID(adminTokens[0]);
    //     console.log("ID");
    //     console.log(ID);

    //     address[] memory nRWA001 = rwa001X.getAllTokensByOwnerAddress(admin);
    //     uint256 tokenId = ICTMRWA001(adminTokens[0]).tokenOfOwnerByIndex(admin, 0);
    //     console.log("tokenId");
    //     console.log(tokenId);

    //     string memory tokenName = ICTMRWA001(adminTokens[0]).name();
    //     string memory symbol = ICTMRWA001(adminTokens[0]).symbol();
    //     uint8 decimals = ICTMRWA001(adminTokens[0]).valueDecimals();
    //     string memory baseURI = ICTMRWA001(adminTokens[0]).baseURI();

    //     toChainIdsStr.push("97");

    //     // function deployAllCTMRWA001X(
    //     //     bool _includeLocal,
    //     //     uint256 _existingID,
    //     //     uint256 _rwaType,
    //     //     uint256 _version,
    //     //     string memory _tokenName, 
    //     //     string memory _symbol, 
    //     //     uint8 _decimals,
    //     //     string memory _baseURI,
    //     //     string[] memory _toChainIdsStr,
    //     //     string memory _feeTokenStr
    //     // ) public returns(uint256) {

    //     uint256 IdBack = rwa001X.deployAllCTMRWA001X(false, ID, 1, 1, tokenName, symbol, decimals, baseURI, toChainIdsStr, feeTokenStr);

    //     console.log("IdBack");
    //     console.log(IdBack);

    //     vm.stopBroadcast();
    // }

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

}