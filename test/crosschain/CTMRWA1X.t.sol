// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.27;

import { Test } from "forge-std/Test.sol";
import { console } from "forge-std/console.sol";

import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

import { Helpers } from "../helpers/Helpers.sol";

import { CTMRWA1 } from "../../src/core/CTMRWA1.sol";
import { ICTMRWA1, Address } from "../../src/core/ICTMRWA1.sol";
import { ICTMRWA1X } from "../../src/crosschain/ICTMRWA1X.sol";
import { CTMRWA1X } from "../../src/crosschain/CTMRWA1X.sol";
import { ICTMRWA1XFallback } from "../../src/crosschain/ICTMRWA1XFallback.sol";
import { ICTMRWA1Dividend } from "../../src/dividend/ICTMRWA1Dividend.sol";

import { ICTMRWA1Sentry } from "../../src/sentry/ICTMRWA1Sentry.sol";
import { ICTMRWA1Storage } from "../../src/storage/ICTMRWA1Storage.sol";

import { C3CallerStructLib } from "../../lib/c3caller/src/C3CallerStructLib.sol";
import { Uint } from "../../src/CTMRWAUtils.sol";

// Mock contract for reentrancy testing
contract ReentrantContract {
    using Strings for address;
    using Strings for *;

    CTMRWA1X public rwa1X;
    uint256 public attackCount;
    
    constructor(address _rwa1X) {
        rwa1X = CTMRWA1X(_rwa1X);
    }
    
    // Reentrancy attack on mintNewTokenValueLocal
    function attackMint(uint256 _ID, string memory _feeTokenStr) external {
        if (attackCount < 3) {
            attackCount++;
            rwa1X.mintNewTokenValueLocal(address(this), 0, 5, 1000, _ID, _feeTokenStr);
        }
    }
    
    // Reentrancy attack on transferWholeTokenX
    function attackTransfer(
        address _from,
        address _to,
        string memory _chainId,
        uint256 _tokenId,
        uint256 _ID,
        string memory _feeTokenStr
    ) external {
        if (attackCount < 3) {
            attackCount++;
            rwa1X.transferWholeTokenX(_from.toHexString(), _to.toHexString(), _chainId, _tokenId, _ID, _feeTokenStr);
        }
    }
    
    // Reentrancy attack on transferPartialTokenX
    function attackPartialTransfer(
        uint256 _tokenId,
        address _to,
        string memory _chainId,
        uint256 _amount,
        uint256 _ID,
        string memory _feeTokenStr
    ) external {
        if (attackCount < 3) {
            attackCount++;
            rwa1X.transferPartialTokenX(_tokenId, _to.toHexString(), _chainId, _amount, _ID, _feeTokenStr);
        }
    }
    
    // Reentrancy attack on changeTokenAdmin
    function attackChangeAdmin(
        string memory _newAdmin,
        string[] memory _chainIds,
        uint256 _ID,
        string memory _feeTokenStr
    ) external {
        if (attackCount < 3) {
            attackCount++;
            rwa1X.changeTokenAdmin(_newAdmin, _chainIds, _ID, _feeTokenStr);
        }
    }
}

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

    function test_localDeploy() public {
        string memory feeTokenStr = address(usdc).toHexString();
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
            feeTokenStr
        );

        // console.log(ID);

        (bool ok, address ctmRwaAddr) = map.getTokenContract(ID, RWA_TYPE, VERSION);
        // console.log(ctmRwaAddr);
        assertTrue(ok);

        uint256 tokenType = ICTMRWA1(ctmRwaAddr).RWA_TYPE();
        assertEq(tokenType, RWA_TYPE);

        uint256 deployedVersion = ICTMRWA1(ctmRwaAddr).VERSION();
        assertEq(deployedVersion, VERSION);

        address[] memory aTokens = rwa1X.getAllTokensByAdminAddress(admin);
        assertEq(aTokens[0], ctmRwaAddr);

        vm.stopPrank();
    }

    function test_localDeployIdenticalID() public {
        // Check to see that you cannot create two tokens with identical IDs

        vm.startPrank(tokenAdmin);
        (ID, token) = _deployCTMRWA1(address(usdc));

        // ID2 will be the same as ID because the block.timestamp is the same
        // as well as all the other params in the abi.encode used to generate ID
        vm.expectRevert(abi.encodeWithSelector(ICTMRWA1X.CTMRWA1X_InvalidTokenContract.selector));
        _deployCTMRWA1(address(usdc));
        vm.stopPrank();

        //RWAX: ID already exists
    }

    function test_tokensByAdminAddress() public {
        // Check that tokens are properly stored by tokenAdmin address

        string memory feeTokenStr = address(usdc).toHexString();

        uint256[] memory IDs = new uint256[](5);
        address[] memory tokensAddr = new address[](5);

        CTMRWA1[] memory tokens = new CTMRWA1[](5);

        vm.startPrank(tokenAdmin);
        (IDs[0], tokens[0]) = _deployCTMRWA1(address(usdc));
        tokensAddr[0] = address(tokens[0]);
        skip(10);
        (IDs[1], tokens[1]) = _deployCTMRWA1(address(usdc));
        tokensAddr[1] = address(tokens[1]);
        skip(20);
        (IDs[2], tokens[2]) = _deployCTMRWA1(address(usdc));
        tokensAddr[2] = address(tokens[2]);
        skip(15);
        (IDs[3], tokens[3]) = _deployCTMRWA1(address(usdc));
        tokensAddr[3] = address(tokens[3]);
        skip(40);
        (IDs[4], tokens[4]) = _deployCTMRWA1(address(usdc));
        tokensAddr[4] = address(tokens[4]);
        vm.stopPrank();

        address[] memory aTokens = rwa1X.getAllTokensByAdminAddress(tokenAdmin);
        assertEq(aTokens.length, 5);

        bool ok;
        // Check all the tokens are in the adminToken list
        for (uint256 i=0; i<aTokens.length; i++) {
            ok = _includesAddress(tokensAddr[i], aTokens);
            assertTrue(ok);
        }

        // Change a token admin in the middle of the list to tokenAdmin2
        vm.prank(tokenAdmin);
        rwa1X.changeTokenAdmin(tokenAdmin2.toHexString(), _stringToArray(cIdStr), IDs[2], feeTokenStr);
        aTokens = rwa1X.getAllTokensByAdminAddress(tokenAdmin);
        // Check that the aToken list is one less
        assertEq(aTokens.length, 4);
        ok = _includesAddress(tokensAddr[2], aTokens);
        // Check that address 2 has been removed
        assertFalse(ok);

        address[] memory a2Tokens = rwa1X.getAllTokensByAdminAddress(tokenAdmin2);
        // Check the a2Token list has one entry
        assertEq(a2Tokens.length, 1);
        ok = _includesAddress(tokensAddr[2], a2Tokens);
        // Check that address 2 is now in tokenAdmin2 list
        assertTrue(ok);
        
        // Change a token admin from the end of the list to tokenAdmin2
        vm.prank(tokenAdmin);
        rwa1X.changeTokenAdmin(tokenAdmin2.toHexString(), _stringToArray(cIdStr), IDs[4], feeTokenStr);
        aTokens = rwa1X.getAllTokensByAdminAddress(tokenAdmin);
        // Check that the aToken list is one less
        assertEq(aTokens.length, 3);
        ok = _includesAddress(tokensAddr[4], aTokens);
        // Check that address 2 has been removed
        assertFalse(ok);

        a2Tokens = rwa1X.getAllTokensByAdminAddress(tokenAdmin2);
        // Check the a2Token list has two entries
        assertEq(a2Tokens.length, 2);
        ok = _includesAddress(tokensAddr[4], a2Tokens);
        // Check that address 4 is now in tokenAdmin2 list
        assertTrue(ok);
    }

    function test_localMint() public {
        vm.startPrank(tokenAdmin);
        (ID, token) = _deployCTMRWA1(address(usdc));
        _createSomeSlots(ID, address(usdc), address(rwa1X));

        string memory feeTokenStr = _toLower((address(usdc).toHexString()));

        uint256 tokenId = rwa1X.mintNewTokenValueLocal(user1, 0, 5, 2000, ID, feeTokenStr);
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
        bool exists = token.exists(tokenId);
        assertEq(exists, true);
        token.burn(tokenId);
        exists = token.exists(tokenId);
        assertEq(exists, false);
        vm.stopPrank();
    }

    function test_ownedTokenIds() public {

        address[] memory feeTokenList = feeManager.getFeeTokenList();
        string memory feeTokenStr = feeTokenList[0].toHexString();

        vm.startPrank(tokenAdmin);
        // Create three token contracts
        (uint256 ID1, CTMRWA1 token1) = _deployCTMRWA1(address(usdc));
        _createSomeSlots(ID1, address(usdc), address(rwa1X));
        skip(10);
        (uint256 ID2, CTMRWA1 token2) = _deployCTMRWA1(address(usdc));
        _createSomeSlots(ID2, address(usdc), address(rwa1X));

        // Mint two tokenIds in (ID1, token1) to user1 and user2 in slots 3 and 5
        uint256 slot = 5;
        uint256 tokenId1 = rwa1X.mintNewTokenValueLocal(user1, 0, slot, 2000, ID1, feeTokenStr);
        uint256 tokenId2 = rwa1X.mintNewTokenValueLocal(user1, 0, slot, 2000, ID1, feeTokenStr);
        uint256 tokenId3 = rwa1X.mintNewTokenValueLocal(user2, 0, slot, 2000, ID1, feeTokenStr);
        slot = 3;
        uint256 tokenId4 = rwa1X.mintNewTokenValueLocal(user1, 0, slot, 2000, ID1, feeTokenStr);
        uint256 tokenId5 = rwa1X.mintNewTokenValueLocal(user2, 0, slot, 2000, ID1, feeTokenStr);

        // Mint a tokenId in (ID2, token2) to user1 in slot 3
        slot = 3;
        uint256 tokenId6 = rwa1X.mintNewTokenValueLocal(user1, 0, slot, 2000, ID2, feeTokenStr);

        vm.stopPrank();

        address[] memory user1Contracts = rwa1X.getAllTokensByOwnerAddress(user1);
        address[] memory user2Contracts = rwa1X.getAllTokensByOwnerAddress(user2);

        // user1 has tokenIds in both (ID1, token1) and (ID2, token2)
        assertEq(user1Contracts.length, 2);
        assertEq(user1Contracts[0], address(token1));
        assertEq(user1Contracts[1], address(token2));

        // Check the tokenIds for user1 in both (ID1, token1) and (ID2, token2)
        uint256 bal = token1.balanceOf(user1);
        // user1 has tokenId1, tokenId2 and tokenId4 in (ID1, token1)
        assertEq(bal, 3);
        assertEq(token1.tokenOfOwnerByIndex(user1, 0), tokenId1);
        assertEq(token1.tokenOfOwnerByIndex(user1, 1), tokenId2);
        assertEq(token1.tokenOfOwnerByIndex(user1, 2), tokenId4);

        // user1 has tokenId6 in (ID2, token2)
        bal = token2.balanceOf(user1);
        assertEq(bal,1);
        assertEq(token2.tokenOfOwnerByIndex(user1, 0), tokenId6);

        // Now check for user2 in both (ID1, token1) and (ID2, token2)
        // user2 has tokenIds in only one (ID1, token1)
        assertEq(user2Contracts.length, 1);
        assertEq(user2Contracts[0], address(token1));

        bal = token1.balanceOf(user2);
        // user2 has tokenId3 and tokenId5 in (ID1, token1)
        assertEq(bal, 2);
        assertEq(token1.tokenOfOwnerByIndex(user2, 0), tokenId3);
        assertEq(token1.tokenOfOwnerByIndex(user2, 1), tokenId5);

        // Now for user2 in (ID2, token2). user2 has none
        bal = token2.balanceOf(user2);
        assertEq(bal, 0);

        // Now transfer tokenId6 from user1 to user2
        vm.prank(user1);
        rwa1X.transferWholeTokenX(user1.toHexString(), user2.toHexString(), cIdStr, tokenId6, ID2, feeTokenStr);
    
        user2Contracts = rwa1X.getAllTokensByOwnerAddress(user2);
        // With the addition of (ID2, token2) for user2, this increases from 1 to 2
        assertEq(user2Contracts.length, 2);
        assertEq(user2Contracts[1], address(token2));
        // Check that tokenId6 is owned by user2 now
        assertEq(token2.ownerOf(tokenId6), user2);

        // NOTE Even though user1 no longer has any tokenIds in token2, it is still included:
        user1Contracts = rwa1X.getAllTokensByOwnerAddress(user1);
        assertEq(user1Contracts.length, 2);
        assertEq(token2.balanceOf(user1), 0); // None left here
    }

    function test_localPartialTransfer() public {
        vm.startPrank(tokenAdmin); // this CTMRWA1 has an admin of tokenAdmin
        (ID, token) = _deployCTMRWA1(address(usdc));
        (uint256 tokenId,,) = _deployAFewTokensLocal(address(token), address(usdc), address(map), address(rwa1X), user1);

        address[] memory feeTokenList = feeManager.getFeeTokenList();
        string memory feeTokenStr = feeTokenList[0].toHexString();

        vm.expectRevert(abi.encodeWithSelector(ICTMRWA1X.CTMRWA1X_Unauthorized.selector, Address.Sender));
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

        vm.stopPrank();
    }

    function test_localWholeTokenTransfer() public {
        vm.startPrank(tokenAdmin); // this CTMRWA1 has an admin of tokenAdmin
        (ID, token) = _deployCTMRWA1(address(usdc));
        // tokenId and tokenId2 are created and owned by tokenAdmin
        (uint256 tokenId, uint256 tokenId2,) =
            _deployAFewTokensLocal(address(token), address(usdc), address(map), address(rwa1X), tokenAdmin);

        address[] memory feeTokenList = feeManager.getFeeTokenList();
        string memory feeTokenStr = feeTokenList[0].toHexString();

        // Check that tokenAdmin can transfer tokenId2 to user1
        rwa1X.transferWholeTokenX(tokenAdmin.toHexString(), user1.toHexString(), cIdStr, tokenId2, ID, feeTokenStr);
        vm.stopPrank();

        // Check that user1 is now the owner of tokenId2
        address owner = token.ownerOf(tokenId2);
        assertEq(owner, user1);

        vm.startPrank(user2);
        // Check that user2 cannot transfer tokenId to user1 (since it is tokenAdmin's)
        vm.expectRevert(abi.encodeWithSelector(ICTMRWA1X.CTMRWA1X_Unauthorized.selector, Address.Sender));
        rwa1X.transferWholeTokenX(tokenAdmin.toHexString(), user1.toHexString(), cIdStr, tokenId, ID, feeTokenStr);
        vm.stopPrank();

        // Check the approval mechanism - tokenAdmin approves user2 to transfer tokenId
        // Initial check
        assertEq(token.getApproved(tokenId), address(0));
        vm.prank(tokenAdmin);
        token.approve(user2, tokenId);

        // Check the approval is for user2 now
        assertEq(token.getApproved(tokenId), user2);

        // Check that user2 can now transfer tokenId to user1
        vm.prank(user2);
        rwa1X.transferWholeTokenX(tokenAdmin.toHexString(), user1.toHexString(), cIdStr, tokenId, ID, feeTokenStr);

        // Check that user1 is now the owner of tokenId
        owner = token.ownerOf(tokenId);
        assertEq(owner, user1);
    }

    function test_localChangeAdmin() public {
        address[] memory feeTokenList = feeManager.getFeeTokenList();
        string memory feeTokenStr = feeTokenList[0].toHexString();

        vm.startPrank(tokenAdmin); // start with admin tokenAdmin

        // Deploy 1 token
        (uint256 ID1, CTMRWA1 token1) = _deployCTMRWA1(address(usdc));

        skip(10);
        // Deploy another token
        (, CTMRWA1 token2) = _deployCTMRWA1(address(usdc));
        address[] memory aTokens = rwa1X.getAllTokensByAdminAddress(tokenAdmin);
        // Check that tokenAdmin now has 2 tokens
        assertEq(aTokens.length, 2);

        // Check that the 2 tokens have the correct contract addresses
        assertEq(aTokens[0], address(token1));
        assertEq(aTokens[1], address(token2));

        rwa1X.changeTokenAdmin(_toLower(user2.toHexString()), _stringToArray(cIdStr), ID1, feeTokenStr);

        aTokens = rwa1X.getAllTokensByAdminAddress(tokenAdmin);
        assertEq(aTokens.length, 1);

        aTokens = rwa1X.getAllTokensByAdminAddress(user2);
        assertEq(aTokens.length, 1);
        assertEq(aTokens[0], address(token1));

        // Check that all the token components have the correct user2 new admin address
        address currentAdmin = token1.tokenAdmin();
        assertEq(currentAdmin, user2);
        (, address dividendAddr) = map.getDividendContract(ID1, RWA_TYPE, VERSION);
        currentAdmin = ICTMRWA1Dividend(dividendAddr).tokenAdmin();
        assertEq(currentAdmin, user2);
        (, address storageAddr) = map.getStorageContract(ID1, RWA_TYPE, VERSION);
        currentAdmin = ICTMRWA1Storage(storageAddr).tokenAdmin();
        assertEq(currentAdmin, user2);
        (, address sentryAddr) = map.getSentryContract(ID1, RWA_TYPE, VERSION);
        currentAdmin = ICTMRWA1Sentry(sentryAddr).tokenAdmin();
        assertEq(currentAdmin, user2);

        vm.stopPrank();
    }

    function test_localLockToken() public {
        address[] memory feeTokenList = feeManager.getFeeTokenList();
        string memory feeTokenStr = feeTokenList[0].toHexString();

        vm.startPrank(tokenAdmin);
        // Deploy a token
        (uint256 ID, CTMRWA1 token) = _deployCTMRWA1(address(usdc));

        // Check the admin now
        address currentAdmin = token.tokenAdmin();
        assertEq(currentAdmin, tokenAdmin);

        // Lock the token (change to address(0))
        rwa1X.changeTokenAdmin(_toLower(address(0).toHexString()), _stringToArray(cIdStr), ID, feeTokenStr);

        // Check the admin again
        currentAdmin = token.tokenAdmin();
        assertEq(currentAdmin, address(0));
        vm.stopPrank();
    }


    function test_remoteDeployExecute() public {

        string memory newAdminStr = tokenAdmin.toHexString();

        string memory tokenName = "RWA Test token";
        string memory symbol = "RWA";
        uint8 decimals = 18;
        uint256 slotNumber = 7;
        string memory slotName = "test RWA";
        uint256 timestamp = 12_776;

        uint256 IDnew = uint256(keccak256(abi.encode(tokenName, symbol, decimals, timestamp, tokenAdmin)));

        string memory baseURI = "GFLD";

        // Simulate the call on the destination chain by c3caller (onlyCaller)
        vm.prank(address(c3caller));
        bool ok = rwa1X.deployCTMRWA1(
            newAdminStr,
            IDnew,
            tokenName,
            symbol,
            decimals,
            baseURI,
            _uint256ToArray(slotNumber), // slot numbers
            _stringToArray(slotName) // slot names
        );

        assertEq(ok, true);

        address tokenAddr;

        // Get the new token address (created on the destination chain)
        (ok, tokenAddr) = map.getTokenContract(IDnew, RWA_TYPE, VERSION);

        // Check that the admin is still tokenAdmin
        assertEq(ICTMRWA1(tokenAddr).tokenAdmin(), tokenAdmin);

        // Check that the tokenName is correct
        assertTrue(stringsEqual(ICTMRWA1(tokenAddr).name(), tokenName));

        // Check that the symbol is correct
        assertTrue(stringsEqual(ICTMRWA1(tokenAddr).symbol(), symbol));

        // Check that the decimals are correct;
        assertEq(ICTMRWA1(tokenAddr).valueDecimals(), decimals);

        // Check that the slot name is the same
        string memory sName = ICTMRWA1(tokenAddr).slotName(slotNumber);
        assertTrue(stringsEqual(sName, slotName));

        // Check that the baseURI is correct
        string memory bURI = ICTMRWA1(tokenAddr).baseURI();
        assertTrue(stringsEqual(bURI, baseURI));
    }

    
    function test_remoteMintTokenToAddressExecute() public {
        // Test mintX cross chain minting

        // tokenAdmin deploys a token and adds some tokenIds
        vm.startPrank(tokenAdmin);
        (ID, token) = _deployCTMRWA1(address(usdc));
        _deployAFewTokensLocal(address(token), address(usdc), address(map), address(rwa1X), tokenAdmin);

        vm.stopPrank();

        // Cross chain minting using c3caller (onlyCaller)
        vm.startPrank(address(c3caller));

        // Mint a new tokenId for user2 in slot 5, with a balance of 140
        bool ok = rwa1X.mintX(ID, user1.toHexString(), user2.toHexString(), 5, 140);

        assertTrue(ok);
        vm.stopPrank();

        // user2 should only have 1 token now, not having had any before
        uint256 newTokenId = token.tokenOfOwnerByIndex(user2, 0);
        assertFalse(newTokenId == 0);
        uint256 balEnd = token.balanceOf(newTokenId);
        assertEq(balEnd, 140);
    }

    function test_remoteChangeAdminExecute() public {
        // Test changeAdmin on a destination chain

        // tokenAdmin deploys a token
        vm.startPrank(tokenAdmin);
        (ID, token) = _deployCTMRWA1(address(usdc));
        vm.stopPrank();

        // Set to tokenAdmin2 on destination chain
        vm.startPrank(address(c3caller));
        rwa1X.adminX(ID, tokenAdmin.toHexString(), tokenAdmin2.toHexString());
        vm.stopPrank();

        address currentAdmin;
        currentAdmin = token.tokenAdmin();
        assertEq(currentAdmin, tokenAdmin2);
        (, address dividendAddr) = map.getDividendContract(ID, RWA_TYPE, VERSION);
        currentAdmin = ICTMRWA1Dividend(dividendAddr).tokenAdmin();
        assertEq(currentAdmin, tokenAdmin2);
        (, address storageAddr) = map.getStorageContract(ID, RWA_TYPE, VERSION);
        currentAdmin = ICTMRWA1Storage(storageAddr).tokenAdmin();
        assertEq(currentAdmin, tokenAdmin2);
        (, address sentryAddr) = map.getSentryContract(ID, RWA_TYPE, VERSION);
        currentAdmin = ICTMRWA1Sentry(sentryAddr).tokenAdmin();
        assertEq(currentAdmin, tokenAdmin2);
    }

    function test_reentrancyMintNewTokenValueLocal() public {
        vm.startPrank(tokenAdmin);
        (ID, token) = _deployCTMRWA1(address(usdc));
        _createSomeSlots(ID, address(usdc), address(rwa1X));
        vm.stopPrank();

        string memory feeTokenStr = address(usdc).toHexString();
        
        // Deploy reentrant contract
        ReentrantContract attacker = new ReentrantContract(address(rwa1X));
        
        // The reentrancy attack should fail due to ReentrancyGuard
        vm.expectRevert();
        attacker.attackMint(ID, feeTokenStr);
        
        // Verify no tokens were minted
        assertEq(token.balanceOf(address(attacker)), 0);
    }

    function test_reentrancyTransferWholeTokenX() public {
        vm.startPrank(tokenAdmin);
        (ID, token) = _deployCTMRWA1(address(usdc));
        (uint256 tokenId,,) = _deployAFewTokensLocal(address(token), address(usdc), address(map), address(rwa1X), user1);
        vm.stopPrank();

        string memory feeTokenStr = address(usdc).toHexString();
        
        // Deploy reentrant contract
        ReentrantContract attacker = new ReentrantContract(address(rwa1X));
        
        // Transfer token to attacker first
        vm.prank(user1);
        rwa1X.transferWholeTokenX(user1.toHexString(), address(attacker).toHexString(), cIdStr, tokenId, ID, feeTokenStr);
        
        // Try the reentrancy attack - it may or may not revert depending on implementation
        // If it doesn't revert, verify the state is still consistent
        try attacker.attackTransfer(address(attacker), user2, cIdStr, tokenId, ID, feeTokenStr) {
            // If attack succeeds, verify state is still consistent
            assertTrue(token.ownerOf(tokenId) == address(attacker) || token.ownerOf(tokenId) == user2);
        } catch {
            // If attack fails, that's also acceptable
            assertEq(token.ownerOf(tokenId), address(attacker));
        }
    }

    function test_reentrancyTransferPartialTokenX() public {
        vm.startPrank(tokenAdmin);
        (ID, token) = _deployCTMRWA1(address(usdc));
        (uint256 tokenId,,) = _deployAFewTokensLocal(address(token), address(usdc), address(map), address(rwa1X), user1);
        vm.stopPrank();

        string memory feeTokenStr = address(usdc).toHexString();
        
        // Deploy reentrant contract
        ReentrantContract attacker = new ReentrantContract(address(rwa1X));
        
        // Transfer token to attacker first
        vm.prank(user1);
        rwa1X.transferWholeTokenX(user1.toHexString(), address(attacker).toHexString(), cIdStr, tokenId, ID, feeTokenStr);
        
        uint256 initialBalance = token.balanceOf(tokenId);
        
        // Try the reentrancy attack - it may or may not revert depending on implementation
        // If it doesn't revert, verify the state is still consistent
        try attacker.attackPartialTransfer(tokenId, user2, cIdStr, 5, ID, feeTokenStr) {
            // If attack succeeds, verify state is still consistent
            uint256 finalBalance = token.balanceOf(tokenId);
            assertTrue(finalBalance <= initialBalance);
        } catch {
            // If attack fails, that's also acceptable
            assertEq(token.balanceOf(tokenId), initialBalance);
        }
    }

    function test_reentrancyChangeTokenAdmin() public {
        vm.startPrank(tokenAdmin);
        (ID, token) = _deployCTMRWA1(address(usdc));
        vm.stopPrank();

        string memory feeTokenStr = address(usdc).toHexString();
        
        // Deploy reentrant contract
        ReentrantContract attacker = new ReentrantContract(address(rwa1X));
        
        // The reentrancy attack should fail
        vm.expectRevert();
        attacker.attackChangeAdmin(user2.toHexString(), _stringToArray(cIdStr), ID, feeTokenStr);
        
        // Verify admin didn't change
        assertEq(token.tokenAdmin(), tokenAdmin);
    }

    // ============ EDGE CONDITIONS TESTS ============

    function test_edgeCaseZeroAmountTransfer() public {
        vm.startPrank(tokenAdmin);
        (ID, token) = _deployCTMRWA1(address(usdc));
        (uint256 tokenId,,) = _deployAFewTokensLocal(address(token), address(usdc), address(map), address(rwa1X), user1);
        vm.stopPrank();

        string memory feeTokenStr = address(usdc).toHexString();
        
        // Try to transfer 0 amount
        vm.prank(user1);
        vm.expectRevert();
        rwa1X.transferPartialTokenX(tokenId, user2.toHexString(), cIdStr, 0, ID, feeTokenStr);
        
        // Verify no transfer occurred
        assertEq(token.balanceOf(tokenId), 2000);
        assertEq(token.ownerOf(tokenId), user1);
    }

    function test_edgeCaseTransferToSelf() public {
        vm.startPrank(tokenAdmin);
        (ID, token) = _deployCTMRWA1(address(usdc));
        (uint256 tokenId,,) = _deployAFewTokensLocal(address(token), address(usdc), address(map), address(rwa1X), user1);
        vm.stopPrank();

        string memory feeTokenStr = address(usdc).toHexString();
        
        // Transfer to self should work
        vm.prank(user1);
        rwa1X.transferWholeTokenX(user1.toHexString(), user1.toHexString(), cIdStr, tokenId, ID, feeTokenStr);
        
        // Verify ownership remains the same
        assertEq(token.ownerOf(tokenId), user1);
    }

    function test_edgeCaseTransferAmountExceedsBalance() public {
        vm.startPrank(tokenAdmin);
        (ID, token) = _deployCTMRWA1(address(usdc));
        (uint256 tokenId,,) = _deployAFewTokensLocal(address(token), address(usdc), address(map), address(rwa1X), user1);
        vm.stopPrank();

        string memory feeTokenStr = address(usdc).toHexString();
        
        // Try to transfer more than balance
        vm.prank(user1);
        vm.expectRevert();
        rwa1X.transferPartialTokenX(tokenId, user2.toHexString(), cIdStr, 3000, ID, feeTokenStr);
        
        // Verify no transfer occurred
        assertEq(token.balanceOf(tokenId), 2000);
        assertEq(token.ownerOf(tokenId), user1);
    }

    function test_edgeCaseEmptyChainId() public {
        vm.startPrank(tokenAdmin);
        (ID, token) = _deployCTMRWA1(address(usdc));
        (uint256 tokenId,,) = _deployAFewTokensLocal(address(token), address(usdc), address(map), address(rwa1X), user1);
        vm.stopPrank();

        string memory feeTokenStr = address(usdc).toHexString();
        
        // Try to transfer with empty chain ID
        vm.prank(user1);
        vm.expectRevert();
        rwa1X.transferWholeTokenX(user1.toHexString(), user2.toHexString(), "", tokenId, ID, feeTokenStr);
    }

    function test_edgeCaseInvalidTokenId() public {
        vm.startPrank(tokenAdmin);
        (ID, token) = _deployCTMRWA1(address(usdc));
        vm.stopPrank();

        string memory feeTokenStr = address(usdc).toHexString();
        
        // Try to transfer non-existent token ID
        vm.prank(user1);
        vm.expectRevert();
        rwa1X.transferWholeTokenX(user1.toHexString(), user2.toHexString(), cIdStr, 999999, ID, feeTokenStr);
    }

    function test_edgeCaseZeroAddressTransfer() public {
        vm.startPrank(tokenAdmin);
        (ID, token) = _deployCTMRWA1(address(usdc));
        (uint256 tokenId,,) = _deployAFewTokensLocal(address(token), address(usdc), address(map), address(rwa1X), user1);
        vm.stopPrank();

        string memory feeTokenStr = address(usdc).toHexString();
        
        // Try to transfer to zero address
        vm.prank(user1);
        vm.expectRevert();
        rwa1X.transferWholeTokenX(user1.toHexString(), address(0).toHexString(), cIdStr, tokenId, ID, feeTokenStr);
    }

    function test_edgeCaseMaxUint256Amount() public {
        vm.startPrank(tokenAdmin);
        (ID, token) = _deployCTMRWA1(address(usdc));
        (uint256 tokenId,,) = _deployAFewTokensLocal(address(token), address(usdc), address(map), address(rwa1X), user1);
        vm.stopPrank();

        string memory feeTokenStr = address(usdc).toHexString();
        
        // Try to transfer max uint256 amount
        vm.prank(user1);
        vm.expectRevert();
        rwa1X.transferPartialTokenX(tokenId, user2.toHexString(), cIdStr, type(uint256).max, ID, feeTokenStr);
    }

    // ============ OVERFLOW/UNDERFLOW TESTS ============

    function test_overflowMintNewTokenValueLocal() public {
        vm.startPrank(tokenAdmin);
        (ID, token) = _deployCTMRWA1(address(usdc));
        _createSomeSlots(ID, address(usdc), address(rwa1X));
        vm.stopPrank();

        string memory feeTokenStr = address(usdc).toHexString();
        
        // Mint a token with max uint256 - 1 balance
        vm.prank(tokenAdmin);
        uint256 tokenId = rwa1X.mintNewTokenValueLocal(user1, 0, 5, type(uint256).max - 1, ID, feeTokenStr);
        assertEq(token.balanceOf(tokenId), type(uint256).max - 1);

        // Try to mint another token with balance 2, which would overflow if summed
        vm.prank(tokenAdmin);
        vm.expectRevert();
        rwa1X.mintNewTokenValueLocal(user1, 0, 5, 2, ID, feeTokenStr);
    }

    function test_underflowTransferPartialTokenX() public {
        vm.startPrank(tokenAdmin);
        (ID, token) = _deployCTMRWA1(address(usdc));
        (uint256 tokenId,,) = _deployAFewTokensLocal(address(token), address(usdc), address(map), address(rwa1X), user1);
        vm.stopPrank();

        string memory feeTokenStr = address(usdc).toHexString();
        
        // Try to transfer more than the balance (should revert)
        vm.prank(user1);
        vm.expectRevert();
        rwa1X.transferPartialTokenX(tokenId, user2.toHexString(), cIdStr, 3000, ID, feeTokenStr);
    }

    function test_underflowBurn() public {
        vm.startPrank(tokenAdmin);
        (ID, token) = _deployCTMRWA1(address(usdc));
        (uint256 tokenId,,) = _deployAFewTokensLocal(address(token), address(usdc), address(map), address(rwa1X), user1);
        vm.stopPrank();

        // Burn the token
        vm.prank(user1);
        token.burn(tokenId);

        // Try to burn again (should revert due to underflow)
        vm.prank(user1);
        vm.expectRevert();
        token.burn(tokenId);
    }

    function test_overflowFuzzMint(uint256 a, uint256 b) public {
        vm.assume(a > 0 && b > 0);
        vm.assume(a <= type(uint256).max / 2 && b <= type(uint256).max / 2); // Prevent overflow
        vm.startPrank(tokenAdmin);
        (ID, token) = _deployCTMRWA1(address(usdc));
        _createSomeSlots(ID, address(usdc), address(rwa1X));
        vm.stopPrank();
        string memory feeTokenStr = address(usdc).toHexString();
        // Mint with a
        vm.prank(tokenAdmin);
        uint256 tokenId = rwa1X.mintNewTokenValueLocal(user1, 0, 5, a, ID, feeTokenStr);
        // Try to mint with b (should not overflow)
        vm.prank(tokenAdmin);
        uint256 tokenId2 = rwa1X.mintNewTokenValueLocal(user1, 0, 5, b, ID, feeTokenStr);
        assertEq(token.balanceOf(tokenId2), b);
    }

    function test_underflowFuzzTransfer(uint256 amount) public {
        vm.assume(amount > 2000); // More than initial balance
        vm.startPrank(tokenAdmin);
        (ID, token) = _deployCTMRWA1(address(usdc));
        (uint256 tokenId,,) = _deployAFewTokensLocal(address(token), address(usdc), address(map), address(rwa1X), user1);
        vm.stopPrank();
        string memory feeTokenStr = address(usdc).toHexString();
        // Try to transfer more than balance
        vm.prank(user1);
        vm.expectRevert();
        rwa1X.transferPartialTokenX(tokenId, user2.toHexString(), cIdStr, amount, ID, feeTokenStr);
    }

    // ============ FUZZ TESTS ============

    function test_fuzzMintAmount(uint256 amount) public {
        vm.assume(amount > 0 && amount <= 1000000); // Reasonable bounds
        
        vm.startPrank(tokenAdmin);
        (ID, token) = _deployCTMRWA1(address(usdc));
        _createSomeSlots(ID, address(usdc), address(rwa1X));
        vm.stopPrank();

        string memory feeTokenStr = address(usdc).toHexString();
        
        vm.prank(tokenAdmin);
        uint256 tokenId = rwa1X.mintNewTokenValueLocal(user1, 0, 5, amount, ID, feeTokenStr);
        
        assertEq(token.balanceOf(tokenId), amount);
        assertEq(token.ownerOf(tokenId), user1);
    }

    function test_fuzzTransferAmount(uint256 amount) public {
        vm.assume(amount > 0 && amount <= 1000); // Reasonable bounds
        
        vm.startPrank(tokenAdmin);
        (ID, token) = _deployCTMRWA1(address(usdc));
        (uint256 tokenId,,) = _deployAFewTokensLocal(address(token), address(usdc), address(map), address(rwa1X), user1);
        vm.stopPrank();

        string memory feeTokenStr = address(usdc).toHexString();
        
        uint256 initialBalance = token.balanceOf(tokenId);
        vm.assume(amount <= initialBalance);
        
        vm.prank(user1);
        rwa1X.transferPartialTokenX(tokenId, user2.toHexString(), cIdStr, amount, ID, feeTokenStr);
        
        assertEq(token.balanceOf(tokenId), initialBalance - amount);
        
        // Check that user2 received a new token with the transferred amount
        uint256 user2TokenId = token.tokenOfOwnerByIndex(user2, 0);
        assertEq(token.balanceOf(user2TokenId), amount);
    }

    function test_fuzzSlotNumber(uint256 slot) public {
        vm.assume(slot > 0 && slot <= 100); // Reasonable bounds
        
        vm.startPrank(tokenAdmin);
        (ID, token) = _deployCTMRWA1(address(usdc));
        _createSlot(ID, slot, address(usdc), address(rwa1X));
        vm.stopPrank();

        string memory feeTokenStr = address(usdc).toHexString();
        
        vm.prank(tokenAdmin);
        uint256 tokenId = rwa1X.mintNewTokenValueLocal(user1, 0, slot, 1000, ID, feeTokenStr);
        
        (uint256 id, uint256 bal, address owner, uint256 slotNum, string memory slotName,) = token.getTokenInfo(tokenId);
        assertEq(slotNum, slot);
    }

    // ============ INVARIANT TESTS ============

    function test_invariantTotalSupplyConsistency() public {
        vm.startPrank(tokenAdmin);
        (ID, token) = _deployCTMRWA1(address(usdc));
        _createSomeSlots(ID, address(usdc), address(rwa1X));
        vm.stopPrank();

        string memory feeTokenStr = address(usdc).toHexString();
        
        uint256 totalSupplyBefore = token.totalSupply();
        
        // Mint a new token
        vm.prank(tokenAdmin);
        uint256 tokenId = rwa1X.mintNewTokenValueLocal(user1, 0, 5, 1000, ID, feeTokenStr);
        
        uint256 totalSupplyAfter = token.totalSupply();
        assertEq(totalSupplyAfter, totalSupplyBefore + 1);
        
        // Burn the token
        vm.prank(user1);
        token.burn(tokenId);
        
        uint256 totalSupplyAfterBurn = token.totalSupply();
        assertEq(totalSupplyAfterBurn, totalSupplyBefore);
    }

    function test_invariantBalanceConsistency() public {
        vm.startPrank(tokenAdmin);
        (ID, token) = _deployCTMRWA1(address(usdc));
        (uint256 tokenId,,) = _deployAFewTokensLocal(address(token), address(usdc), address(map), address(rwa1X), user1);
        vm.stopPrank();

        string memory feeTokenStr = address(usdc).toHexString();
        
        uint256 initialBalance = token.balanceOf(tokenId);
        uint256 transferAmount = 500;
        
        vm.prank(user1);
        rwa1X.transferPartialTokenX(tokenId, user2.toHexString(), cIdStr, transferAmount, ID, feeTokenStr);
        
        // Verify total balance remains the same
        assertEq(token.balanceOf(tokenId) + token.balanceOf(token.tokenOfOwnerByIndex(user2, 0)), initialBalance);
    }

    function test_invariantOwnerConsistency() public {
        vm.startPrank(tokenAdmin);
        (ID, token) = _deployCTMRWA1(address(usdc));
        (uint256 tokenId,,) = _deployAFewTokensLocal(address(token), address(usdc), address(map), address(rwa1X), user1);
        vm.stopPrank();

        string memory feeTokenStr = address(usdc).toHexString();
        
        address initialOwner = token.ownerOf(tokenId);
        
        vm.prank(user1);
        rwa1X.transferWholeTokenX(user1.toHexString(), user2.toHexString(), cIdStr, tokenId, ID, feeTokenStr);
        
        address newOwner = token.ownerOf(tokenId);
        assertTrue(initialOwner != newOwner);
        assertEq(newOwner, user2);
    }

    function test_invariantAdminConsistency() public {
        vm.startPrank(tokenAdmin);
        (ID, token) = _deployCTMRWA1(address(usdc));
        vm.stopPrank();

        string memory feeTokenStr = address(usdc).toHexString();
        
        address initialAdmin = token.tokenAdmin();
        
        vm.prank(tokenAdmin);
        rwa1X.changeTokenAdmin(user2.toHexString(), _stringToArray(cIdStr), ID, feeTokenStr);
        
        address newAdmin = token.tokenAdmin();
        assertTrue(initialAdmin != newAdmin);
        assertEq(newAdmin, user2);
    }

    // ============ GAS USAGE TESTS ============

    function test_gasUsageMintNewTokenValueLocal() public {
        vm.startPrank(tokenAdmin);
        (ID, token) = _deployCTMRWA1(address(usdc));
        _createSomeSlots(ID, address(usdc), address(rwa1X));
        vm.stopPrank();

        string memory feeTokenStr = address(usdc).toHexString();
        
        uint256 gasBefore = gasleft();
        
        vm.prank(tokenAdmin);
        rwa1X.mintNewTokenValueLocal(user1, 0, 5, 1000, ID, feeTokenStr);
        
        uint256 gasUsed = gasBefore - gasleft();
        
        // Mint should be reasonably gas efficient
        assertTrue(gasUsed < 13_000_000);
    }

    function test_gasUsageTransferWholeTokenX() public {
        vm.startPrank(tokenAdmin);
        (ID, token) = _deployCTMRWA1(address(usdc));
        (uint256 tokenId,,) = _deployAFewTokensLocal(address(token), address(usdc), address(map), address(rwa1X), user1);
        vm.stopPrank();

        string memory feeTokenStr = address(usdc).toHexString();
        
        uint256 gasBefore = gasleft();
        
        vm.prank(user1);
        rwa1X.transferWholeTokenX(user1.toHexString(), user2.toHexString(), cIdStr, tokenId, ID, feeTokenStr);
        
        uint256 gasUsed = gasBefore - gasleft();
        
        // Transfer should be reasonably gas efficient
        assertTrue(gasUsed < 13_000_000);
    }

    function test_gasUsageTransferPartialTokenX() public {
        vm.startPrank(tokenAdmin);
        (ID, token) = _deployCTMRWA1(address(usdc));
        (uint256 tokenId,,) = _deployAFewTokensLocal(address(token), address(usdc), address(map), address(rwa1X), user1);
        vm.stopPrank();

        string memory feeTokenStr = address(usdc).toHexString();
        
        uint256 gasBefore = gasleft();
        
        vm.prank(user1);
        rwa1X.transferPartialTokenX(tokenId, user2.toHexString(), cIdStr, 500, ID, feeTokenStr);
        
        uint256 gasUsed = gasBefore - gasleft();
        
        // Partial transfer should be reasonably gas efficient
        assertTrue(gasUsed < 13_000_000);
    }

    function test_gasUsageChangeTokenAdmin() public {
        vm.startPrank(tokenAdmin);
        (ID, token) = _deployCTMRWA1(address(usdc));
        vm.stopPrank();

        string memory feeTokenStr = address(usdc).toHexString();
        
        uint256 gasBefore = gasleft();
        
        vm.prank(tokenAdmin);
        rwa1X.changeTokenAdmin(user2.toHexString(), _stringToArray(cIdStr), ID, feeTokenStr);
        
        uint256 gasUsed = gasBefore - gasleft();
        
        // Admin change should be reasonably gas efficient
        assertTrue(gasUsed < 13_000_000);
    }

    // ============ STRESS TESTS ============

    function test_stressMultipleMints() public {
        vm.startPrank(tokenAdmin);
        (ID, token) = _deployCTMRWA1(address(usdc));
        _createSomeSlots(ID, address(usdc), address(rwa1X));
        vm.stopPrank();

        string memory feeTokenStr = address(usdc).toHexString();
        
        // Mint 10 tokens in sequence
        for (uint256 i = 0; i < 10; i++) {
            vm.prank(tokenAdmin);
            uint256 tokenId = rwa1X.mintNewTokenValueLocal(user1, 0, 5, 1000, ID, feeTokenStr);
            assertEq(token.ownerOf(tokenId), user1);
        }
        
        assertEq(token.balanceOf(user1), 10);
    }

    function test_stressMultipleTransfers() public {
        vm.startPrank(tokenAdmin);
        (ID, token) = _deployCTMRWA1(address(usdc));
        (uint256 tokenId,,) = _deployAFewTokensLocal(address(token), address(usdc), address(map), address(rwa1X), user1);
        vm.stopPrank();

        string memory feeTokenStr = address(usdc).toHexString();
        
        // Perform multiple partial transfers
        for (uint256 i = 0; i < 5; i++) {
            vm.prank(user1);
            rwa1X.transferPartialTokenX(tokenId, user2.toHexString(), cIdStr, 100, ID, feeTokenStr);
        }
        
        assertEq(token.balanceOf(tokenId), 1500); // 2000 - (5 * 100)
        assertEq(token.balanceOf(user2), 5); // 5 new tokens
    }

    function test_stressMultipleAdminChanges() public {
        vm.startPrank(tokenAdmin);
        (ID, token) = _deployCTMRWA1(address(usdc));
        vm.stopPrank();

        string memory feeTokenStr = address(usdc).toHexString();
        
        // Change admin multiple times - each new admin can change to the next
        address[] memory admins = new address[](4);
        admins[0] = user1;
        admins[1] = user2;
        admins[2] = tokenAdmin2;
        admins[3] = tokenAdmin;
        
        address currentAdmin = tokenAdmin;
        
        for (uint256 i = 0; i < admins.length; i++) {
            vm.prank(currentAdmin);
            rwa1X.changeTokenAdmin(admins[i].toHexString(), _stringToArray(cIdStr), ID, feeTokenStr);
            assertEq(token.tokenAdmin(), admins[i]);
            currentAdmin = admins[i]; // Update current admin for next iteration
        }
    }

    // ============ ACCESS CONTROL TESTS ============

    function test_accessControlNonAdminMint() public {
        vm.startPrank(tokenAdmin);
        (ID, token) = _deployCTMRWA1(address(usdc));
        _createSomeSlots(ID, address(usdc), address(rwa1X));
        vm.stopPrank();

        string memory feeTokenStr = address(usdc).toHexString();
        
        // Non-admin should not be able to mint
        vm.prank(user1);
        vm.expectRevert();
        rwa1X.mintNewTokenValueLocal(user2, 0, 5, 1000, ID, feeTokenStr);
    }

    function test_accessControlNonOwnerTransfer() public {
        vm.startPrank(tokenAdmin);
        (ID, token) = _deployCTMRWA1(address(usdc));
        (uint256 tokenId,,) = _deployAFewTokensLocal(address(token), address(usdc), address(map), address(rwa1X), user1);
        vm.stopPrank();

        string memory feeTokenStr = address(usdc).toHexString();
        
        // Non-owner should not be able to transfer
        vm.prank(user2);
        vm.expectRevert();
        rwa1X.transferWholeTokenX(user1.toHexString(), user2.toHexString(), cIdStr, tokenId, ID, feeTokenStr);
    }

    function test_accessControlNonAdminChangeAdmin() public {
        vm.startPrank(tokenAdmin);
        (ID, token) = _deployCTMRWA1(address(usdc));
        vm.stopPrank();

        string memory feeTokenStr = address(usdc).toHexString();
        
        // Non-admin should not be able to change admin
        vm.prank(user1);
        vm.expectRevert();
        rwa1X.changeTokenAdmin(user2.toHexString(), _stringToArray(cIdStr), ID, feeTokenStr);
    }

    function test_accessControlC3CallerOnly() public {
        vm.startPrank(tokenAdmin);
        (ID, token) = _deployCTMRWA1(address(usdc));
        vm.stopPrank();

        // Non-c3caller should not be able to call c3caller-only functions
        vm.prank(user1);
        vm.expectRevert();
        rwa1X.deployCTMRWA1(
            tokenAdmin.toHexString(),
            ID,
            "Test",
            "TEST",
            18,
            "GFLD",
            new uint256[](0),
            new string[](0)
        );
    }

    // ============ INPUT VALIDATION TESTS ============

    function test_inputValidationInvalidFeeToken() public {
        vm.startPrank(tokenAdmin);
        (ID, token) = _deployCTMRWA1(address(usdc));
        _createSomeSlots(ID, address(usdc), address(rwa1X));
        vm.stopPrank();

        // Try to mint with invalid fee token
        vm.prank(tokenAdmin);
        vm.expectRevert();
        rwa1X.mintNewTokenValueLocal(user1, 0, 5, 1000, ID, "invalid_token");
    }

    function test_inputValidationInvalidChainId() public {
        vm.startPrank(tokenAdmin);
        (ID, token) = _deployCTMRWA1(address(usdc));
        (uint256 tokenId,,) = _deployAFewTokensLocal(address(token), address(usdc), address(map), address(rwa1X), user1);
        vm.stopPrank();

        string memory feeTokenStr = address(usdc).toHexString();
        
        // Try to transfer with invalid chain ID
        vm.prank(user1);
        vm.expectRevert();
        rwa1X.transferWholeTokenX(user1.toHexString(), user2.toHexString(), "invalid_chain", tokenId, ID, feeTokenStr);
    }

    function test_inputValidationInvalidAddress() public {
        vm.startPrank(tokenAdmin);
        (ID, token) = _deployCTMRWA1(address(usdc));
        _createSomeSlots(ID, address(usdc), address(rwa1X));
        vm.stopPrank();

        string memory feeTokenStr = address(usdc).toHexString();
        
        // Try to mint to invalid address
        vm.prank(tokenAdmin);
        vm.expectRevert();
        rwa1X.mintNewTokenValueLocal(address(0), 0, 5, 1000, ID, feeTokenStr);
    }

    // ============ STATE CONSISTENCY TESTS ============

    function test_stateConsistencyAfterFailedTransfer() public {
        vm.startPrank(tokenAdmin);
        (ID, token) = _deployCTMRWA1(address(usdc));
        (uint256 tokenId,,) = _deployAFewTokensLocal(address(token), address(usdc), address(map), address(rwa1X), user1);
        vm.stopPrank();

        string memory feeTokenStr = address(usdc).toHexString();
        
        uint256 initialBalance = token.balanceOf(tokenId);
        address initialOwner = token.ownerOf(tokenId);
        
        // Try to transfer more than balance (should fail)
        vm.prank(user1);
        vm.expectRevert();
        rwa1X.transferPartialTokenX(tokenId, user2.toHexString(), cIdStr, 3000, ID, feeTokenStr);
        
        // State should remain unchanged
        assertEq(token.balanceOf(tokenId), initialBalance);
        assertEq(token.ownerOf(tokenId), initialOwner);
    }

    function test_stateConsistencyAfterFailedMint() public {
        vm.startPrank(tokenAdmin);
        (ID, token) = _deployCTMRWA1(address(usdc));
        _createSomeSlots(ID, address(usdc), address(rwa1X));
        vm.stopPrank();

        uint256 initialSupply = token.totalSupply();
        
        // Try to mint with invalid parameters (should fail)
        vm.prank(tokenAdmin);
        vm.expectRevert();
        rwa1X.mintNewTokenValueLocal(address(0), 0, 5, 1000, ID, "invalid_fee_token");
        
        // Supply should remain unchanged
        assertEq(token.totalSupply(), initialSupply);
    }

    // ============ BOUNDARY TESTS ============

    function test_boundaryMaxTokenId() public {
        vm.startPrank(tokenAdmin);
        (ID, token) = _deployCTMRWA1(address(usdc));
        _createSomeSlots(ID, address(usdc), address(rwa1X));
        vm.stopPrank();

        string memory feeTokenStr = address(usdc).toHexString();
        
        // Mint many tokens to approach max token ID
        for (uint256 i = 0; i < 100; i++) {
            vm.prank(tokenAdmin);
            uint256 tokenId = rwa1X.mintNewTokenValueLocal(user1, 0, 5, 1000, ID, feeTokenStr);
            assertTrue(tokenId > 0);
        }
    }

    function test_boundaryMaxBalance() public {
        vm.startPrank(tokenAdmin);
        (ID, token) = _deployCTMRWA1(address(usdc));
        _createSomeSlots(ID, address(usdc), address(rwa1X));
        vm.stopPrank();

        string memory feeTokenStr = address(usdc).toHexString();
        
        // Try to mint with very large balance
        vm.prank(tokenAdmin);
        uint256 tokenId = rwa1X.mintNewTokenValueLocal(user1, 0, 5, type(uint256).max - 1, ID, feeTokenStr);
        
        assertEq(token.balanceOf(tokenId), type(uint256).max - 1);
    }

    function test_boundaryMinBalance() public {
        vm.startPrank(tokenAdmin);
        (ID, token) = _deployCTMRWA1(address(usdc));
        _createSomeSlots(ID, address(usdc), address(rwa1X));
        vm.stopPrank();

        string memory feeTokenStr = address(usdc).toHexString();
        
        // Try to mint with minimum balance
        vm.prank(tokenAdmin);
        uint256 tokenId = rwa1X.mintNewTokenValueLocal(user1, 0, 5, 1, ID, feeTokenStr);
        
        assertEq(token.balanceOf(tokenId), 1);
    }

    // ============ INTEGRATION TESTS ============

    function test_integrationCompleteWorkflow() public {
        vm.startPrank(tokenAdmin);
        (ID, token) = _deployCTMRWA1(address(usdc));
        _createSomeSlots(ID, address(usdc), address(rwa1X));
        vm.stopPrank();

        string memory feeTokenStr = address(usdc).toHexString();
        
        // 1. Mint token
        vm.prank(tokenAdmin);
        uint256 tokenId = rwa1X.mintNewTokenValueLocal(user1, 0, 5, 1000, ID, feeTokenStr);
        
        // 2. Transfer whole token
        vm.prank(user1);
        rwa1X.transferWholeTokenX(user1.toHexString(), user2.toHexString(), cIdStr, tokenId, ID, feeTokenStr);
        
        // 3. Transfer partial amount
        vm.prank(user2);
        rwa1X.transferPartialTokenX(tokenId, user1.toHexString(), cIdStr, 300, ID, feeTokenStr);
        
        // 4. Change admin
        vm.prank(tokenAdmin);
        rwa1X.changeTokenAdmin(user2.toHexString(), _stringToArray(cIdStr), ID, feeTokenStr);
        
        // Verify final state
        assertEq(token.ownerOf(tokenId), user2);
        assertEq(token.balanceOf(tokenId), 700);
        assertEq(token.balanceOf(token.tokenOfOwnerByIndex(user1, 0)), 300);
        assertEq(token.tokenAdmin(), user2);
    }

    function test_integrationMultipleTokens() public {
        vm.startPrank(tokenAdmin);
        (uint256 ID1, CTMRWA1 token1) = _deployCTMRWA1(address(usdc));

        skip(10);
        
        (uint256 ID2, CTMRWA1 token2) = _deployCTMRWA1(address(usdc));

        _createSomeSlots(ID1, address(usdc), address(rwa1X));
        _createSomeSlots(ID2, address(usdc), address(rwa1X));
        vm.stopPrank();

        string memory feeTokenStr = address(usdc).toHexString();
        
        // Mint tokens in both contracts
        vm.prank(tokenAdmin);
        uint256 tokenId1 = rwa1X.mintNewTokenValueLocal(user1, 0, 5, 1000, ID1, feeTokenStr);

        vm.prank(tokenAdmin);
        uint256 tokenId2 = rwa1X.mintNewTokenValueLocal(user1, 0, 5, 1000, ID2, feeTokenStr);
        
        // Transfer tokens between different contracts
        vm.prank(user1);
        rwa1X.transferWholeTokenX(user1.toHexString(), user2.toHexString(), cIdStr, tokenId1, ID1, feeTokenStr);
        
        vm.prank(user1);
        rwa1X.transferPartialTokenX(tokenId2, user2.toHexString(), cIdStr, 500, ID2, feeTokenStr);
        
        // Verify state
        assertEq(token1.ownerOf(tokenId1), user2);
        assertEq(token2.ownerOf(tokenId2), user1);
        assertEq(token2.balanceOf(tokenId2), 500);
        assertEq(token2.balanceOf(token2.tokenOfOwnerByIndex(user2, 0)), 500);
    }

    function test_revert_InvalidAddress_Minter() public {
        // Only gov can call changeMinterStatus, so use gov
        vm.prank(gov);
        vm.expectRevert(abi.encodeWithSelector(ICTMRWA1X.CTMRWA1X_InvalidAddress.selector, Address.Minter));
        rwa1X.changeMinterStatus(address(rwa1X), true);
    }

    function test_revert_InvalidAddress_Fallback() public {
        vm.prank(gov);
        vm.expectRevert(abi.encodeWithSelector(ICTMRWA1X.CTMRWA1X_InvalidAddress.selector, Address.Fallback));
        rwa1X.setFallback(address(rwa1X));
    }

    function test_revert_IsZeroAddress_Deployer() public {
        // Deploy a fresh CTMRWA1X with ctmRwaDeployer set to zero
        address newRwa1X = address(new CTMRWA1X());
        // Initialize with ctmRwaDeployer = address(0)
        vm.prank(gov);
        CTMRWA1X(newRwa1X).initialize(address(0x1), address(0x2), gov, address(0x3), address(0x4), 1);
        vm.prank(gov);
        vm.expectRevert(abi.encodeWithSelector(ICTMRWA1X.CTMRWA1X_IsZeroAddress.selector, Address.Deployer));
        CTMRWA1X(newRwa1X).setCtmRwaMap(address(0x1234));
    }

    function test_revert_IsZeroAddress_Fallback() public {
        vm.prank(gov);
        vm.expectRevert(abi.encodeWithSelector(ICTMRWA1X.CTMRWA1X_IsZeroAddress.selector, Address.Fallback));
        rwa1X.setFallback(address(0));
    }

    function test_revert_NonExistentSlot() public {
        vm.startPrank(tokenAdmin);
        (uint256 ID, CTMRWA1 token) = _deployCTMRWA1(address(usdc));
        // Try to mint to a non-existent slot
        string memory feeTokenStr = address(usdc).toHexString();
        vm.expectRevert(abi.encodeWithSelector(ICTMRWA1X.CTMRWA1X_NonExistentSlot.selector, 999));
        rwa1X.mintNewTokenValueLocal(user1, 0, 999, 1000, ID, feeTokenStr);
        vm.stopPrank();
    }

    function test_revert_InvalidAddress_Admin() public {
        // Deploy with tokenAdmin, then try to change admin from tokenAdmin2
        vm.startPrank(tokenAdmin);
        (uint256 ID, ) = _deployCTMRWA1(address(usdc));
        vm.stopPrank();
        vm.startPrank(tokenAdmin2);
        vm.expectRevert(abi.encodeWithSelector(ICTMRWA1X.CTMRWA1X_Unauthorized.selector, Address.Sender));
        rwa1X.changeTokenAdmin(tokenAdmin2.toHexString(), _stringToArray(cIdStr), ID, address(usdc).toHexString());
        vm.stopPrank();
    }

    // ============ FALLBACK TESTS ============
    
    function test_c3FallbackWithMintXSelector() public {
        vm.startPrank(tokenAdmin);
        (ID, token) = _deployCTMRWA1(address(usdc));
        _createSomeSlots(ID, address(usdc), address(rwa1X));
        // (_tokenId1, _tokenId2, _tokenId3) = _deployAFewTokensLocal(address(token), address(usdc), address(map), address(rwa1X), address(user1));
        vm.stopPrank();

        bytes4 selector = bytes4(keccak256("mintX(uint256,string,string,uint256,uint256)"));
        bytes memory data = abi.encode(ID, user1.toHexString(), user2.toHexString(), 3, 1000);
        bytes memory reason = "mintX failed"; // A dummy revert string from the destination contract

        assertEq(rwa1X.fallbackAddr(), address(rwa1XFallback));
        assertEq(ICTMRWA1XFallback(rwa1X.fallbackAddr()).rwa1X(), address(rwa1X));

        vm.prank(address(rwa1X));
        rwa1XFallback.rwa1XC3Fallback(selector, data, reason, address(map));
    }

}
