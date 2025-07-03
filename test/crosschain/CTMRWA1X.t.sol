// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

contract TestCTMRWA1X is SetUp {
    using Strings for *;

    function test_CTMRWA1Deploy() public {
        string memory tokenStr = _toLower((address(usdc).toHexString()));
        string[] memory chainIdsStr;

        uint256 rwaType = 1;
        uint256 version = 1;

        vm.startPrank(admin);
        uint256 ID = rwa1X.deployAllCTMRWA1X(
            true,  // include local mint
            0,
            rwaType,
            version,
            "Semi Fungible Token XChain",
            "SFTX",
            18,
            "GFLD",
            chainIdsStr,  // empty array - no cross-chain minting
            tokenStr
        );

        console.log("finished deploy, ID = ");
        console.log(ID);

        (bool ok, address ctmRwaAddr) = map.getTokenContract(ID, rwaType, version);
        console.log("ctmRwaAddr");
        console.log(ctmRwaAddr);
        assertEq(ok, true);

        uint256 tokenType = ICTMRWA1(ctmRwaAddr).rwaType();
        assertEq(tokenType, rwaType);

        uint256 deployedVersion = ICTMRWA1(ctmRwaAddr).version();
        assertEq(deployedVersion, version);

        address[] memory aTokens = rwa1X.getAllTokensByAdminAddress(admin);
        console.log('aTokens');
        assertEq(aTokens[0], ctmRwaAddr);

        vm.stopPrank();
    }

    function test_CTMRWA1Mint() public {
        (uint256 ID, address ctmRwaAddr) = CTMRWA1Deploy();

        createSomeSlots(ID);

        string memory tokenStr = _toLower((address(usdc).toHexString()));

        uint256 tokenId = rwa1X.mintNewTokenValueLocal(
            user1,
            0,
            5,
            2000,
            ID,
            tokenStr
        );

        assertEq(tokenId, 1);
        (uint256 id, uint256 bal, address owner, uint256 slot, string memory slotName,) = ICTMRWA1(ctmRwaAddr).getTokenInfo(tokenId);
        //console.log(id, bal, owner, slot);
        assertEq(id,1);
        assertEq(bal, 2000);
        assertEq(owner, user1);
        assertEq(slot, 5);
        assertEq(stringsEqual(slotName, "slot 5 is the best RWA"), true);

        vm.startPrank(user1);
        bool exists = ICTMRWA1(ctmRwaAddr).requireMinted(tokenId);
        assertEq(exists, true);
        ICTMRWA1(ctmRwaAddr).burn(tokenId);
        exists = ICTMRWA1(ctmRwaAddr).requireMinted(tokenId);
        assertEq(exists, false);
        vm.stopPrank();
    }


    function test_localTransferX() public {
        vm.startPrank(admin);  // this CTMRWA1 has an admin of admin
        (uint256 ID, address ctmRwaAddr) = CTMRWA1Deploy();
        (uint256 tokenId, uint256 tokenId2, uint256 tokenId3) = deployAFewTokensLocal(ctmRwaAddr);

        address[] memory feeTokenList = feeManager.getFeeTokenList();
        string memory feeTokenStr = feeTokenList[0].toHexString();


        vm.expectRevert("RWAX: Not approved or owner");
        rwa1X.transferPartialTokenX(tokenId, user1.toHexString(), cIdStr, 5, ID, feeTokenStr);
        vm.stopPrank();


        vm.startPrank(user1);
        uint256 balBefore = ICTMRWA1(ctmRwaAddr).balanceOf(tokenId);
        rwa1X.transferPartialTokenX(tokenId, user2.toHexString(), cIdStr, 5, ID, feeTokenStr);
        uint256 balAfter = ICTMRWA1(ctmRwaAddr).balanceOf(tokenId);
        assertEq(balBefore, balAfter+5);

        address owned = rwa1X.getAllTokensByOwnerAddress(user2)[0];
        assertEq(owned, ctmRwaAddr);

        uint256 newTokenId = ICTMRWA1(ctmRwaAddr).tokenOfOwnerByIndex(user2,0);
        assertEq(ICTMRWA1(ctmRwaAddr).ownerOf(newTokenId), user2);
        uint256 balNewToken = ICTMRWA1(ctmRwaAddr).balanceOf(newTokenId);
        assertEq(balNewToken, 5);

        // ICTMRWA1(ctmRwaAddr).approve(tokenId2, user2, 50);
        ICTMRWA1(ctmRwaAddr).approve(user2, tokenId2);
        vm.stopPrank();

        vm.startPrank(user2);
        rwa1X.transferWholeTokenX(user1.toHexString(), admin.toHexString(), cIdStr, tokenId2, ID, feeTokenStr);
        address owner = ICTMRWA1(ctmRwaAddr).ownerOf(tokenId2);
        assertEq(owner, admin);
        assertEq(ICTMRWA1(ctmRwaAddr).getApproved(tokenId2), admin);

        vm.stopPrank();

    }

    function test_changeAdmin() public {

        address[] memory feeTokenList = feeManager.getFeeTokenList();
        string memory feeTokenStr = feeTokenList[0].toHexString(); // CTM

        vm.startPrank(admin);  // this CTMRWA1 has an admin of admin
        (uint256 ID, address ctmRwaAddr) = CTMRWA1Deploy();
        skip(10);
        (uint256 ID2, address ctmRwaAddr2) = CTMRWA1Deploy();
        address[] memory aTokens = rwa1X.getAllTokensByAdminAddress(admin);
        assertEq(aTokens.length, 2);
        
        assertEq(aTokens[0], ctmRwaAddr);
        assertEq(aTokens[1], ctmRwaAddr2);

        rwa1X.changeTokenAdmin(
            _toLower(user2.toHexString()),
            _stringToArray(cIdStr),
            ID,
            feeTokenStr
        );

        aTokens = rwa1X.getAllTokensByAdminAddress(admin);
        assertEq(aTokens.length, 1);

        aTokens = rwa1X.getAllTokensByAdminAddress(user2);
        assertEq(aTokens.length, 1);
        assertEq(aTokens[0], ctmRwaAddr);


        rwa1X.changeTokenAdmin(
            _toLower(address(0).toHexString()),
            _stringToArray(cIdStr),
            ID2,
            feeTokenStr
        );

        aTokens = rwa1X.getAllTokensByAdminAddress(admin);
        assertEq(aTokens.length, 0);

        address dustbin = ICTMRWA1(ctmRwaAddr2).tokenAdmin();
        assertEq(dustbin, address(0));


        vm.stopPrank();

    }

    function test_remoteDeploy() public {

        vm.startPrank(user1);
        (, address ctmRwaAddr) = CTMRWA1Deploy();
        vm.stopPrank();
        (bool ok, uint256 ID) = map.getTokenId(ctmRwaAddr.toHexString(), rwaType, version);
        assertEq(ok, true);

        // admin of the CTMRWA1 token
        string memory currentAdminStr = _toLower(user1.toHexString());

        address tokenAdmin = ICTMRWA1(ctmRwaAddr).tokenAdmin();
        assertEq(tokenAdmin, user1);

        address[] memory feeTokenList = feeManager.getFeeTokenList();
        string memory ctmRwaAddrStr = ctmRwaAddr.toHexString();
        string memory feeTokenStr = feeTokenList[0].toHexString(); // CTM
        toChainIdsStr.push("1");


        string memory targetStr;
        (ok, targetStr) = gateway.getAttachedRWAX(rwaType, version, "1");
        assertEq(ok, true);
        uint256 currentNonce = c3UUIDKeeper.currentNonce();

        uint256 rwaType = ICTMRWA1(ctmRwaAddr).rwaType();
        uint256 version = ICTMRWA1(ctmRwaAddr).version();

        string memory sig = "deployCTMRWA1(string,uint256,uint256,uint256,string,string,uint8,string,string)";

        string memory tokenName = "Semi Fungible Token XChain";
        string memory symbol = "SFTX";
        uint8 decimals = 18;

        // string memory funcCall = "deployCTMRWA1(string,uint256,uint256,uint256,string,string,uint8,string,string)";
        // bytes memory callData = abi.encodeWithSignature(
        //     funcCall,
        //     currentAdminStr,
        //     ID,
        //     rwaType,
        //     version,
        //     tokenName_,
        //     symbol_,
        //     decimals_,
        //     baseURI_,
        //     _ctmRwa1AddrStr
        // );

        bytes memory callData = abi.encodeWithSignature(
            sig,
            currentAdminStr,
            ID,
            tokenName,
            symbol,
            decimals,
            "GFLD",
            ctmRwaAddrStr
        );

        bytes32 testUUID = keccak256(abi.encode(
            address(c3UUIDKeeper),
            address(c3CallerLogic),
            block.chainid,
            2,
            targetStr,
            toChainIdsStr[0],
            currentNonce + 1,
            callData
        ));

        vm.expectEmit(true, true, false, true);
        emit LogC3Call(2, testUUID, address(rwa1X), toChainIdsStr[0], targetStr, callData, bytes(""));

        // function deployAllCTMRWA1X(
        //     bool includeLocal,
        //     uint256 existingID_,
        //     string memory tokenName_, 
        //     string memory symbol_, 
        //     uint8 decimals_,
        //     string memory baseURI_,
        //     string[] memory toChainIdsStr_,
        //     string memory feeTokenStr
        // ) public payable returns(uint256) {

        vm.prank(user1);
        rwa1X.deployAllCTMRWA1X(false, ID, rwaType, version, tokenName, symbol, decimals, "", toChainIdsStr, feeTokenStr);

    }

    function test_deployExecute() public {

        // function deployCTMRWA1(
        //     string memory _newAdminStr,
        //     uint256 _ID,
        //     uint256 _rwaType,
        //     uint256 _version,
        //     string memory _tokenName, 
        //     string memory _symbol, 
        //     uint8 _decimals,
        //     string memory _baseURI,
        //     string memory _fromContractStr
        // ) external onlyCaller returns(bool) {

        string memory newAdminStr = _toLower(user1.toHexString());

        string memory tokenName = "RWA Test token";
        string memory symbol = "RWA";
        uint8 decimals = 18;
        uint256 timestamp = 12776;
        slotNumbers.push(7);
        slotNames.push("test RWA");

        uint256 ID = uint256(keccak256(abi.encode(
            tokenName,
            symbol,
            decimals,
            timestamp,
            user1
        )));

        string memory baseURI = "GFLD";


        vm.prank(address(c3CallerLogic));
        bool ok = rwa1X.deployCTMRWA1(
            newAdminStr,
            ID,
            tokenName,
            symbol,
            decimals,
            baseURI,
            slotNumbers,
            slotNames
        );

        assertEq(ok, true);
        
        address tokenAddr;

        (ok, tokenAddr) = ICTMRWAMap(ctmRwa1Map).getTokenContract(ID, rwaType, version);

        assertEq(ICTMRWA1(tokenAddr).tokenAdmin(), user1);

        console.log("tokenAddr");
        console.log(tokenAddr);

        string memory sName = ICTMRWA1(tokenAddr).slotName(7);
        console.log(sName);

    }

    function test_transferToAddressExecute() public {

        vm.startPrank(user1);
        (uint256 ID, address ctmRwaAddr) = CTMRWA1Deploy();
       
        (, uint256 tokenId2,) = deployAFewTokensLocal(ctmRwaAddr);
         vm.stopPrank();

        console.log("tokenId2");
        console.log(tokenId2);

        uint256 slot = ICTMRWA1(ctmRwaAddr).slotOf(tokenId2);
        console.log("slot");
        console.log(slot);


        // address[] memory ops = c3GovClient.getAllOperators();
        // console.log("operators");
        // console.log(ops[0]);

        uint dapp = 2;


        string memory funcCall = "mintX(uint256,string,string,uint256,uint256,uint256,string)";
        bytes memory inputData = abi.encodeWithSignature(
            funcCall,
            ID,
            user1.toHexString(),
            user2.toHexString(),
            0,
            slot,
            10,
            ctmRwaAddr.toHexString()
        );

        // library C3CallerStructLib {
        //     struct C3EvmMessage {
        //         bytes32 uuid;
        //         address to;
        //         string fromChainID;
        //         string sourceTx;
        //         string fallbackTo;
        //         bytes data;
        //     }
        // }

        
        C3CallerStructLib.C3EvmMessage memory c3message = C3CallerStructLib.C3EvmMessage(
            0x0dd256c5649d5658f91dc4fe936c407ab6dd42183a795d5a256f4508631d0ccb,
            address(rwa1X),
            "421614",
            "0x04f1802a1e9f4c8de6f80e4c2e31b1ea32e019fd59aa38e8e20393ff7770026a",
            address(rwa1X).toHexString(),
            inputData
        );

        // console.log("transfering value of 10 from tokenId 2, slot 3 from user1 to user2");

        // console.log("BEFORE user1");
        // listAllTokensByAddress(ctmRwaAddr, user1);

        vm.prank(address(rwa1X));
        ICTMRWA1(ctmRwaAddr).burnValueX(tokenId2, 10);

        vm.prank(address(gov)); // blank onlyOperator require in C3Gov to test
        c3.execute(dapp, c3message);

        // console.log("AFTER user1");
        // listAllTokensByAddress(ctmRwaAddr, user1);
        // console.log("AFTER user2");
        // listAllTokensByAddress(ctmRwaAddr, user2);
    }

    function test_transferTokenIdToAddressExecute() public {

    // function mintX(
    //     uint256 _ID,
    //     string memory _fromAddressStr,
    //     string memory _toAddressStr,
    //     uint256 _fromTokenId,
    //     uint256 _slot,
    //     uint256 _balance,
    //     string memory _fromTokenStr
    // ) external onlyCaller returns(bool){

        vm.startPrank(admin);
        (uint256 ID, address ctmRwaAddr) = CTMRWA1Deploy();
        (uint256 tokenId1,,) = deployAFewTokensLocal(ctmRwaAddr);
        vm.stopPrank();

        vm.startPrank(address(c3CallerLogic));

        uint256 balStart = ICTMRWA1(ctmRwaAddr).balanceOf(tokenId1);
        console.log("balStart");
        console.log(balStart);

        bool ok = rwa1X.mintX(
            ID,
            user1.toHexString(),
            user2.toHexString(),
            // tokenId1,
            5,
            140/*,
            ctmRwaAddr.toHexString()*/
        );

        assertEq(ok, true);

        vm.stopPrank();

        uint256 newTokenId = ICTMRWA1(ctmRwaAddr).tokenOfOwnerByIndex(user2, 0);
        uint256 balEnd = ICTMRWA1(ctmRwaAddr).balanceOf(newTokenId);
        assertEq(balEnd, 140);

        string memory slotDescription = ICTMRWA1(ctmRwaAddr).slotName(5);
        // console.log("slotDescription = ");
        // console.log(slotDescription);
        assertEq(stringsEqual(slotDescription, "slot 5 is the best RWA"), true);

    }



    function test_transferToken() public {
        vm.startPrank(admin);
        (uint256 ID, address ctmRwaAddr) = CTMRWA1Deploy();
        (uint256 tokenId1,,) = deployAFewTokensLocal(ctmRwaAddr);
        vm.stopPrank();

        /*token1
            to: user1
            to token: 0 (new token)
            slot: 5
            value: 2000
            token addr: _ctmRwaAddr
        */

        /*token2
            to: user1
            to token: 0 (new token)
            slot: 3
            value: 4000
            token addr: _ctmRwaAddr
        */

        /*token2
            to: user1
            to token: 0 (new token)
            slot: 1
            value: 6000
            token addr: _ctmRwaAddr
        */

        

        string memory user1Str = user1.toHexString();
        address[] memory feeTokenList = feeManager.getFeeTokenList();
        string memory ctmRwaAddrStr = ctmRwaAddr.toHexString();
        string memory feeTokenStr = feeTokenList[0].toHexString(); // CTM
        string memory toChainIdStr = "1";
        string memory sig = "mintX(uint256,string,string,uint256,uint256,uint256,string)";

 
        (, string memory toRwaXStr) = gateway.getAttachedRWAX(rwaType, version, toChainIdStr);
        (,uint256 value,,uint256 slot, string memory slotName,) = ICTMRWA1(ctmRwaAddr).getTokenInfo(tokenId1);
        uint256 currentNonce = c3UUIDKeeper.currentNonce();

        string memory thisSlotName = ICTMRWA1(ctmRwaAddr).slotName(slot);


        // string memory funcCall = "mintX(uint256,string,string,uint256,uint256,uint256,string)";
        // bytes memory callData = abi.encodeWithSignature(
        //     funcCall,
        //     _ID,
        //     fromAddressStr,
        //     _toAddressStr,
        //     _fromTokenId,
        //     slot,
        //     slotName,
        //     value,
        //     ctmRwa1AddrStr
        // );

        bytes memory callData = abi.encodeWithSignature(
            sig,
            ID,
            user1Str,
            user1Str,
            tokenId1,
            slot,
            thisSlotName,
            value,
            ctmRwaAddrStr
        );


        bytes32 testUUID = keccak256(abi.encode(
            address(c3UUIDKeeper),
            address(c3CallerLogic),
            block.chainid,
            2,
            toRwaXStr,
            toChainIdStr,
            currentNonce + 1,
            callData
        ));

        vm.expectEmit(true, true, false, true);
        emit LogC3Call(2, testUUID, address(rwa1X), toChainIdStr, toRwaXStr, callData, bytes(""));

        // function transferWholeTokenX(
        //     string memory _fromAddressStr,
        //     string memory _toAddressStr,
        //     string memory _toChainIdStr,
        //     uint256 _fromTokenId,
        //     uint256 _ID,
        //     string memory _feeTokenStr
        // ) public {

        vm.prank(user1);
        rwa1X.transferWholeTokenX(user1Str, user1Str, toChainIdStr, tokenId1, ID, feeTokenStr);
    }


    function test_valueTransferNewTokenCreation() public {

        vm.startPrank(admin);
        (uint256 ID, address ctmRwaAddr) = CTMRWA1Deploy();
        (uint256 tokenId1,,) = deployAFewTokensLocal(ctmRwaAddr);
        vm.stopPrank();

        string memory user1Str = user1.toHexString();
        address[] memory feeTokenList = feeManager.getFeeTokenList();
        string memory ctmRwaAddrStr = ctmRwaAddr.toHexString();
        string memory feeTokenStr = feeTokenList[0].toHexString(); // CTM
        string memory toChainIdStr = "1";

        (bool ok, string memory toRwaXStr) = gateway.getAttachedRWAX(rwaType, version, toChainIdStr);
        require(ok, "CTMRWA1X: Target contract address not found");
        (,uint256 value,,uint256 slot, string memory thisSlotName,) = ICTMRWA1(ctmRwaAddr).getTokenInfo(tokenId1);
        uint256 currentNonce = c3UUIDKeeper.currentNonce();

        string memory sig = "mintX(uint256,string,string,uint256,uint256,uint256,string)";

        // string memory funcCall = "mintX(uint256,string,string,uint256,uint256,string,uint256,string)";
        // bytes memory callData = abi.encodeWithSignature(
        //     funcCall,
        //     _ID,
        //     fromAddressStr,
        //     _toAddressStr,
        //     _fromTokenId,
        //     slot,
        //     thisSlotName,
        //     _value,
        //     ctmRwa1AddrStr
        // );

       
        console.log("SLOTNAME");
        console.log(thisSlotName);

        bytes memory callData = abi.encodeWithSignature(
            sig,
            ID,
            user1Str,
            user1Str,
            tokenId1,
            slot,
            thisSlotName,
            value/2,  // send half the value to other chain
            ctmRwaAddrStr
        );


        bytes32 testUUID = keccak256(abi.encode(
            address(c3UUIDKeeper),
            address(c3CallerLogic),
            block.chainid,
            2,
            toRwaXStr,
            toChainIdStr,
            currentNonce + 1,
            callData
        ));

        vm.expectEmit(true, true, false, true);
        emit LogC3Call(2, testUUID, address(rwa1X), toChainIdStr, toRwaXStr, callData, bytes(""));

    //    function transferPartialTokenX(
    //         uint256 _fromTokenId,
    //         string memory _toAddressStr,
    //         string memory _toChainIdStr,
    //         uint256 _value,
    //         uint256 _ID,
    //         string memory _feeTokenStr
    //     ) public 

        vm.prank(user1);
        rwa1X.transferPartialTokenX(tokenId1, user1Str, toChainIdStr, value/2, ID, feeTokenStr);

    }

}
