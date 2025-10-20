// SPDX-License-Identifier: BSL-1.1

pragma solidity 0.8.27;

import { Test } from "forge-std/Test.sol";
import { CTMRWA1 } from "../../src/core/CTMRWA1.sol";
import { ICTMRWA1 } from "../../src/core/ICTMRWA1.sol";
import { ICTMRWA1Receiver } from "../../src/core/ICTMRWA1Receiver.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { Helpers } from "../helpers/Helpers.sol";

/**
 * @title Test contract for CTMRWA1 receiver hook functionality
 * @dev Tests the proper implementation of receiver checks in _checkOnCTMRWA1Received
 */
contract CTMRWA1ReceiverHookTest is Helpers {
    using Strings for *;
    
    // Test contracts
    ValidReceiver public validReceiver;
    InvalidReceiver public invalidReceiver;
    RevertingReceiver public revertingReceiver;
    ReentrancyReceiver public reentrancyReceiver;
    
    function setUp() public override {
        super.setUp();
        
        // Deploy CTMRWA1 using proper deployment pattern
        vm.startPrank(tokenAdmin);
        (ID, token) = _deployCTMRWA1(address(usdc));
        
        // Create slots and mint tokens for testing
        _createSomeSlots(ID, address(usdc), address(rwa1X));
        
        vm.stopPrank();
        
        // Deploy test receiver contracts
        validReceiver = new ValidReceiver();
        invalidReceiver = new InvalidReceiver();
        revertingReceiver = new RevertingReceiver();
        reentrancyReceiver = new ReentrancyReceiver();
    }
    
    function test_EOA_Transfer_Succeeds() public {
        vm.startPrank(tokenAdmin);
        
        // Mint a token to user1 using proper pattern (slot 1 exists from _createSomeSlots)
        string memory tokenStr = _toLower((address(usdc).toHexString()));
        uint256 tokenId = rwa1XUtils.mintNewTokenValueLocal(user1, 0, 1, 1000, ID, VERSION, tokenStr);
        
        // Mint a token to user2 for receiving
        uint256 tokenId2 = rwa1XUtils.mintNewTokenValueLocal(user2, 0, 1, 0, ID, VERSION, tokenStr);
        
        vm.stopPrank();
        vm.startPrank(user1);
        
        // Transfer to EOA (user2) - should succeed
        token.transferFrom(tokenId, tokenId2, 500);
        
        assertEq(token.balanceOf(tokenId), 500);
        assertEq(token.balanceOf(tokenId2), 500);
        vm.stopPrank();
    }
    
    function test_ValidReceiver_Transfer_Succeeds() public {
        vm.startPrank(tokenAdmin);
        
        // Mint a token to user1 using proper pattern
        string memory tokenStr = _toLower((address(usdc).toHexString()));
        uint256 tokenId = rwa1XUtils.mintNewTokenValueLocal(user1, 0, 1, 1000, ID, VERSION, tokenStr);
        
        // Mint a token to the valid receiver contract
        uint256 receiverTokenId = rwa1XUtils.mintNewTokenValueLocal(address(validReceiver), 0, 1, 0, ID, VERSION, tokenStr);
        
        vm.stopPrank();
        vm.startPrank(user1);
        
        // Transfer to valid receiver - should succeed
        token.transferFrom(tokenId, receiverTokenId, 500);
        
        assertEq(token.balanceOf(tokenId), 500);
        assertEq(token.balanceOf(receiverTokenId), 500);
        vm.stopPrank();
    }
    
    function test_InvalidReceiver_Transfer_Reverts() public {
        vm.startPrank(tokenAdmin);
        
        // Mint a token to user1 using proper pattern
        string memory tokenStr = _toLower((address(usdc).toHexString()));
        uint256 tokenId = rwa1XUtils.mintNewTokenValueLocal(user1, 0, 1, 1000, ID, VERSION, tokenStr);
        
        // Mint a token to the invalid receiver contract
        uint256 receiverTokenId = rwa1XUtils.mintNewTokenValueLocal(address(invalidReceiver), 0, 1, 0, ID, VERSION, tokenStr);
        
        vm.stopPrank();
        vm.startPrank(user1);
        
        // Transfer to invalid receiver - should revert
        vm.expectRevert(ICTMRWA1.CTMRWA1_ReceiverRejected.selector);
        token.transferFrom(tokenId, receiverTokenId, 500);
        
        vm.stopPrank();
    }
    
    function test_RevertingReceiver_Transfer_Reverts() public {
        vm.startPrank(tokenAdmin);
        
        // Mint a token to user1 using proper pattern
        string memory tokenStr = _toLower((address(usdc).toHexString()));
        uint256 tokenId = rwa1XUtils.mintNewTokenValueLocal(user1, 0, 1, 1000, ID, VERSION, tokenStr);
        
        // Mint a token to the reverting receiver contract
        uint256 receiverTokenId = rwa1XUtils.mintNewTokenValueLocal(address(revertingReceiver), 0, 1, 0, ID, VERSION, tokenStr);
        
        vm.stopPrank();
        vm.startPrank(user1);
        
        // Transfer to reverting receiver - should revert
        vm.expectRevert(ICTMRWA1.CTMRWA1_ReceiverRejected.selector);
        token.transferFrom(tokenId, receiverTokenId, 500);
        
        vm.stopPrank();
    }
    
    function test_ReentrancyReceiver_Transfer_Reverts() public {
        vm.startPrank(tokenAdmin);
        
        // Mint a token to user1 using proper pattern
        string memory tokenStr = _toLower((address(usdc).toHexString()));
        uint256 tokenId = rwa1XUtils.mintNewTokenValueLocal(user1, 0, 1, 1000, ID, VERSION, tokenStr);
        
        // Mint a token to the reentrancy receiver contract
        uint256 receiverTokenId = rwa1XUtils.mintNewTokenValueLocal(address(reentrancyReceiver), 0, 1, 0, ID, VERSION, tokenStr);
        
        vm.stopPrank();
        vm.startPrank(user1);
        // Approve the receiver contract to spend on behalf of user1's tokenId
        token.approve(tokenId, address(reentrancyReceiver), 100);
        // Configure reentrancy attempt parameters (attempt to reenter with value 50)
        reentrancyReceiver.setParams(tokenId, receiverTokenId, 50);
        
        // Transfer to reentrancy receiver - should succeed (reentrancy blocked internally)
        token.transferFrom(tokenId, receiverTokenId, 500);
        
        // Verify the transfer succeeded
        assertEq(token.balanceOf(tokenId), 500);
        assertEq(token.balanceOf(receiverTokenId), 500);
        
        vm.stopPrank();
    }
}

/**
 * @title Valid receiver that properly implements the interface
 */
contract ValidReceiver is ICTMRWA1Receiver {
    function onCTMRWA1Received(
        address,
        uint256,
        uint256,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return ICTMRWA1Receiver.onCTMRWA1Received.selector;
    }
}

/**
 * @title Invalid receiver that returns wrong selector
 */
contract InvalidReceiver is ICTMRWA1Receiver {
    function onCTMRWA1Received(
        address,
        uint256,
        uint256,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return 0x12345678; // Wrong selector
    }
}

/**
 * @title Receiver that always reverts
 */
contract RevertingReceiver is ICTMRWA1Receiver {
    function onCTMRWA1Received(
        address,
        uint256,
        uint256,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        revert("Always reverts");
    }
}

/**
 * @title Receiver that attempts reentrancy
 */
contract ReentrancyReceiver is ICTMRWA1Receiver {
    uint256 private reFrom;
    uint256 private reTo;
    uint256 private reValue;
    
    function setParams(uint256 _fromTokenId, uint256 _toTokenId, uint256 _value) external {
        reFrom = _fromTokenId;
        reTo = _toTokenId;
        reValue = _value;
    }
    
    function onCTMRWA1Received(
        address,
        uint256,
        uint256,
        uint256,
        bytes calldata
    ) external override returns (bytes4) {
        // Attempt reentrancy by calling transferFrom again
        // This should be blocked by the nonReentrant guard in transferFrom(uint256,uint256,uint256)
        // We'll use the msg.sender (which should be the CTMRWA1 contract) to make the call
        try ICTMRWA1(msg.sender).transferFrom(reFrom, reTo, reValue) {
            // Should not succeed
        } catch {
            // Expected to fail due to reentrancy guard
        }
        
        return ICTMRWA1Receiver.onCTMRWA1Received.selector;
    }
}
