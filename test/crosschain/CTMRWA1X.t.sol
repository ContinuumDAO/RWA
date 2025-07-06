// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.19;

import { Test } from "forge-std/Test.sol";
import { console } from "forge-std/console.sol";

import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

import { Helpers } from "../helpers/Helpers.sol";

import { CTMRWA1 } from "../../src/core/CTMRWA1.sol";
import { ICTMRWA1 } from "../../src/core/ICTMRWA1.sol";

import { C3CallerStructLib } from "../../lib/c3caller/src/C3CallerStructLib.sol";

contract TestCTMRWA1X is Helpers {
    using Strings for *;

    event LogC3Call(
        uint256 indexed dappID,
        bytes32 indexed uuid,
        address caller,
        string toChainID,
        string to,
        bytes data,
        bytes extra
    );

    function test_CTMRWA1Deploy() public {
        string memory tokenStr = address(usdc).toHexString();
        string[] memory chainIdsStr;

        vm.startPrank(admin);
        uint256 ID = rwa1X.deployAllCTMRWA1X(
            true, // include local mint
            0,
            RWA_TYPE,
            VERSION,
            "Semi Fungible Token XChain",
            "SFTX",
            18,
            "GFLD",
            chainIdsStr, // empty array - no cross-chain minting
            tokenStr
        );

        console.log("finished deploy, ID = ");
        console.log(ID);

        (bool ok, address ctmRwaAddr) = map.getTokenContract(ID, RWA_TYPE, VERSION);
        console.log("ctmRwaAddr");
        console.log(ctmRwaAddr);
        assertEq(ok, true);

        uint256 tokenType = ICTMRWA1(ctmRwaAddr).rwaType();
        assertEq(tokenType, RWA_TYPE);

        uint256 deployedVersion = ICTMRWA1(ctmRwaAddr).version();
        assertEq(deployedVersion, VERSION);

        address[] memory aTokens = rwa1X.getAllTokensByAdminAddress(admin);
        console.log("aTokens");
        assertEq(aTokens[0], ctmRwaAddr);

        vm.stopPrank();
    }

    function test_CTMRWA1Mint() public {
        vm.startPrank(tokenAdmin);
        (ID, token) = _deployCTMRWA1(address(usdc));
        _createSomeSlots(ID, address(usdc), address(rwa1X));

        string memory tokenStr = _toLower((address(usdc).toHexString()));

        uint256 tokenId = rwa1X.mintNewTokenValueLocal(user1, 0, 5, 2000, ID, tokenStr);
        vm.stopPrank();

        assertEq(tokenId, 1);
        (uint256 id, uint256 bal, address owner, uint256 slot, string memory slotName,) = token.getTokenInfo(tokenId);
        //console.log(id, bal, owner, slot);
        assertEq(id, 1);
        assertEq(bal, 2000);
        assertEq(owner, user1);
        assertEq(slot, 5);
        assertEq(stringsEqual(slotName, "slot 5 is the best RWA"), true);

        vm.startPrank(user1);
        bool exists = token.requireMinted(tokenId);
        assertEq(exists, true);
        token.burn(tokenId);
        exists = token.requireMinted(tokenId);
        assertEq(exists, false);
        vm.stopPrank();
    }

    function test_localTransferX() public {
        vm.startPrank(tokenAdmin); // this CTMRWA1 has an admin of tokenAdmin
        (ID, token) = _deployCTMRWA1(address(usdc));
        (uint256 tokenId, uint256 tokenId2, uint256 tokenId3) =
            _deployAFewTokensLocal(address(token), address(usdc), address(map), address(rwa1X), user1);

        address[] memory feeTokenList = feeManager.getFeeTokenList();
        string memory feeTokenStr = feeTokenList[0].toHexString();

        vm.expectRevert("RWAX: Not approved or owner");
        rwa1X.transferPartialTokenX(tokenId, user1.toHexString(), cIdStr, 5, ID, feeTokenStr);
        vm.stopPrank();

        vm.startPrank(user1);
        uint256 balBefore = token.balanceOf(tokenId);
        rwa1X.transferPartialTokenX(tokenId, user2.toHexString(), cIdStr, 5, ID, feeTokenStr);
        uint256 balAfter = token.balanceOf(tokenId);
        assertEq(balBefore, balAfter + 5);

        address owned = rwa1X.getAllTokensByOwnerAddress(user2)[0];
        assertEq(owned, address(token));

        uint256 newTokenId = token.tokenOfOwnerByIndex(user2, 0);
        assertEq(token.ownerOf(newTokenId), user2);
        uint256 balNewToken = token.balanceOf(newTokenId);
        assertEq(balNewToken, 5);

        token.approve(user2, tokenId2);
        vm.stopPrank();

        vm.startPrank(user2);
        rwa1X.transferWholeTokenX(user1.toHexString(), admin.toHexString(), cIdStr, tokenId2, ID, feeTokenStr);
        address owner = token.ownerOf(tokenId2);
        assertEq(owner, admin);
        assertEq(token.getApproved(tokenId2), admin);

        vm.stopPrank();
    }

    function test_changeAdmin() public {
        address[] memory feeTokenList = feeManager.getFeeTokenList();
        string memory feeTokenStr = feeTokenList[0].toHexString(); // CTM

        vm.startPrank(tokenAdmin);  // start with admin tokenAdmin
        (ID, token) = _deployCTMRWA1(address(usdc));

        skip(10);
        (uint256 ID2, CTMRWA1 token2) = _deployCTMRWA1(address(usdc));
        address[] memory aTokens = rwa1X.getAllTokensByAdminAddress(tokenAdmin);
        assertEq(aTokens.length, 2);

        assertEq(aTokens[0], address(token));
        assertEq(aTokens[1], address(token2));

        rwa1X.changeTokenAdmin(_toLower(user2.toHexString()), _stringToArray(cIdStr), ID, feeTokenStr);

        aTokens = rwa1X.getAllTokensByAdminAddress(tokenAdmin);
        assertEq(aTokens.length, 1);

        aTokens = rwa1X.getAllTokensByAdminAddress(user2);
        assertEq(aTokens.length, 1);
        assertEq(aTokens[0], address(token));

        rwa1X.changeTokenAdmin(_toLower(address(0).toHexString()), _stringToArray(cIdStr), ID2, feeTokenStr);

        aTokens = rwa1X.getAllTokensByAdminAddress(tokenAdmin);
        assertEq(aTokens.length, 0);

        address dustbin = token2.tokenAdmin();
        assertEq(dustbin, address(0));

        vm.stopPrank();
    }

    function test_remoteDeploy() public {
        vm.startPrank(tokenAdmin);
        (ID, token) = _deployCTMRWA1(address(usdc));
        vm.stopPrank();

        (bool ok, uint256 ID) = map.getTokenId(address(token).toHexString(), RWA_TYPE, VERSION);
        assertEq(ok, true);

        // admin of the CTMRWA1 token
        string memory currentAdminStr = tokenAdmin.toHexString();

        address currentTokenAdmin = token.tokenAdmin();
        assertEq(currentTokenAdmin, tokenAdmin);

        string memory feeTokenStr = address(usdc).toHexString();
        string[] memory toChainIdsStr = _stringToArray("1");

        string memory targetStr;
        (ok, targetStr) = gateway.getAttachedRWAX(RWA_TYPE, VERSION, "1");
        assertEq(ok, true);
        uint256 currentNonce = c3UUIDKeeper.currentNonce();

        uint256 rwaType = token.rwaType();
        uint256 version = token.version();

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

        bytes memory callData =
            abi.encodeWithSignature(sig, currentAdminStr, ID, tokenName, symbol, decimals, "GFLD", address(token).toHexString());

        bytes32 testUUID = keccak256(
            abi.encode(
                address(c3UUIDKeeper),
                address(c3caller),
                block.chainid,
                2,
                targetStr,
                toChainIdsStr[0],
                currentNonce + 1,
                callData
            )
        );

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

        vm.prank(tokenAdmin);
        rwa1X.deployAllCTMRWA1X(
            false, ID, rwaType, version, tokenName, symbol, decimals, "", toChainIdsStr, feeTokenStr
        );
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

        string memory newAdminStr = tokenAdmin.toHexString();

        string memory tokenName = "RWA Test token";
        string memory symbol = "RWA";
        uint8 decimals = 18;
        uint256 timestamp = 12_776;

        uint256 ID = uint256(keccak256(abi.encode(tokenName, symbol, decimals, timestamp, tokenAdmin)));

        string memory baseURI = "GFLD";

        vm.prank(address(c3caller));
        bool ok = rwa1X.deployCTMRWA1(
            newAdminStr, 
            ID, 
            tokenName, 
            symbol, 
            decimals, 
            baseURI, 
            _uint256ToArray(7),  // slot numbers 
            _stringToArray("test RWA")  // slot names
        );

        assertEq(ok, true);

        address tokenAddr;

        (ok, tokenAddr) = map.getTokenContract(ID, RWA_TYPE, VERSION);

        assertEq(token.tokenAdmin(), tokenAdmin);

        string memory sName = token.slotName(7);
        console.log(sName);
    }

    function test_transferToAddressExecute() public {
        vm.startPrank(tokenAdmin);
        (ID, token) = _deployCTMRWA1(address(usdc));
        (, uint256 tokenId2,) =
            _deployAFewTokensLocal(address(token), address(usdc), address(map), address(rwa1X), tokenAdmin);

        vm.stopPrank();

        console.log("tokenId2");
        console.log(tokenId2);

        uint256 slot = token.slotOf(tokenId2);
        console.log("slot");
        console.log(slot);

        // address[] memory ops = c3GovClient.getAllOperators();
        // console.log("operators");
        // console.log(ops[0]);

        uint256 dapp = 2;

        string memory funcCall = "mintX(uint256,string,string,uint256,uint256,uint256,string)";
        bytes memory inputData = abi.encodeWithSignature(
            funcCall, ID, tokenAdmin.toHexString(), user2.toHexString(), 0, slot, 10, address(token).toHexString()
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

        // console.log("transfering value of 10 from tokenId 2, slot 3 from tokenAdmin to user2");

        // console.log("BEFORE tokenAdmin");
        // listAllTokensByAddress(ctmRwaAddr, tokenAdmin);

        vm.prank(address(rwa1X));
        token.burnValueX(tokenId2, 10);

        vm.prank(address(gov)); // blank onlyOperator require in C3Gov to test
        c3caller.execute(dapp, c3message);

        // console.log("AFTER tokenAdmin");
        // listAllTokensByAddress(ctmRwaAddr, tokenAdmin);
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

        vm.startPrank(tokenAdmin);
        (ID, token) = _deployCTMRWA1(address(usdc));
        (uint256 tokenId1,,) =
            _deployAFewTokensLocal(address(token), address(usdc), address(map), address(rwa1X), tokenAdmin);

        vm.stopPrank();

        vm.startPrank(address(c3caller));

        uint256 balStart = token.balanceOf(tokenId1);
        console.log("balStart");
        console.log(balStart);

        bool ok = rwa1X.mintX(
            ID,
            user1.toHexString(),
            user2.toHexString(),
            // tokenId1,
            5,
            140 /*,
            ctmRwaAddr.toHexString()*/
        );

        assertEq(ok, true);

        vm.stopPrank();

        uint256 newTokenId = token.tokenOfOwnerByIndex(user2, 0);
        uint256 balEnd = token.balanceOf(newTokenId);
        assertEq(balEnd, 140);

        string memory slotDescription = token.slotName(5);
        // console.log("slotDescription = ");
        // console.log(slotDescription);
        assertEq(stringsEqual(slotDescription, "slot 5 is the best RWA"), true);
    }

    function test_transferToken() public {
        vm.startPrank(tokenAdmin);
        (ID, token) = _deployCTMRWA1(address(usdc));
        (uint256 tokenId1,,) =
            _deployAFewTokensLocal(address(token), address(usdc), address(map), address(rwa1X), tokenAdmin);

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
        string memory feeTokenStr = address(usdc).toHexString();
        string memory toChainIdStr = "1";
        string memory sig = "mintX(uint256,string,string,uint256,uint256,uint256,string)";

        (, string memory toRwaXStr) = gateway.getAttachedRWAX(RWA_TYPE, VERSION, toChainIdStr);
        (, uint256 value,, uint256 slot, string memory slotName,) = token.getTokenInfo(tokenId1);
        uint256 currentNonce = c3UUIDKeeper.currentNonce();

        string memory thisSlotName = token.slotName(slot);

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

        bytes memory callData =
            abi.encodeWithSignature(sig, ID, user1Str, user1Str, tokenId1, slot, thisSlotName, value, address(token).toHexString());

        bytes32 testUUID = keccak256(
            abi.encode(
                address(c3UUIDKeeper),
                address(c3caller),
                block.chainid,
                2,
                toRwaXStr,
                toChainIdStr,
                currentNonce + 1,
                callData
            )
        );

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
        vm.startPrank(tokenAdmin);
        (ID, token) = _deployCTMRWA1(address(usdc));
        (uint256 tokenId1,,) =
            _deployAFewTokensLocal(address(token), address(usdc), address(map), address(rwa1X), tokenAdmin);

        vm.stopPrank();

        string memory user1Str = user1.toHexString();
        address[] memory feeTokenList = feeManager.getFeeTokenList();
        string memory feeTokenStr = address(usdc).toHexString();
        string memory toChainIdStr = "1";

        (bool ok, string memory toRwaXStr) = gateway.getAttachedRWAX(RWA_TYPE, VERSION, toChainIdStr);
        require(ok, "CTMRWA1X: Target contract address not found");
        (, uint256 value,, uint256 slot, string memory thisSlotName,) = token.getTokenInfo(tokenId1);
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
            value / 2, // send half the value to other chain
            address(token).toHexString()
        );

        bytes32 testUUID = keccak256(
            abi.encode(
                address(c3UUIDKeeper),
                address(c3caller),
                block.chainid,
                2,
                toRwaXStr,
                toChainIdStr,
                currentNonce + 1,
                callData
            )
        );

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
        rwa1X.transferPartialTokenX(tokenId1, user1Str, toChainIdStr, value / 2, ID, feeTokenStr);
    }
}
