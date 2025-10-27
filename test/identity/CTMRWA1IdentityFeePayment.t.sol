// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.27;

import { CTMRWA1Identity } from "../../src/identity/CTMRWA1Identity.sol";
import { ICTMRWA1Identity } from "../../src/identity/ICTMRWA1Identity.sol";
import { FeeType, IFeeManager } from "../../src/managers/IFeeManager.sol";
import { ICTMRWA1Sentry } from "../../src/sentry/ICTMRWA1Sentry.sol";
import { CTMRWAErrorParam, CTMRWAUtils } from "../../src/utils/CTMRWAUtils.sol";
import { Helpers } from "../helpers/Helpers.sol";

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

import { console } from "forge-std/console.sol";

// Minimal mock for IZkMeVerify
contract MockZkMeVerify {
    bool public approved = true;

    function setApproved(bool _a) external {
        approved = _a;
    }

    function hasApproved(address, address) external view returns (bool) {
        return approved;
    }
}

contract TestCTMRWA1IdentityFeePayment is Helpers {
    using Strings for *;
    using CTMRWAUtils for string;

    CTMRWA1Identity identity;
    MockZkMeVerify zkMe;
    string feeTokenStr;
    string[] chainIds;
    address public sentryAddr;
    ICTMRWA1Sentry public sentry;

    function setUp() public override {
        super.setUp();
        zkMe = new MockZkMeVerify();
        feeTokenStr = address(usdc).toHexString();
        chainIds = new string[](1);
        chainIds[0] = cIdStr;
        
        // Deploy a token and get its ID
        vm.startPrank(tokenAdmin);
        (ID, token) = _deployCTMRWA1(address(usdc));
        vm.stopPrank();
        
        // Get the sentry address for this token
        (bool ok, address _sentryAddr) = map.getSentryContract(ID, RWA_TYPE, VERSION);
        require(ok, "Sentry not found");
        sentryAddr = _sentryAddr;
        sentry = ICTMRWA1Sentry(sentryAddr);
        
        // Deploy the identity contract with real map, sentryManager, feeManager, and mock zkMe
        identity = new CTMRWA1Identity(
            RWA_TYPE, VERSION, address(map), address(sentryManager), address(zkMe), address(feeManager)
        );
        vm.prank(gov);
        sentryManager.setIdentity(address(identity), address(zkMe));
        
        // Update fee contracts to include identity contract
        feeContracts.identity = address(identity);
        
        // Add token approvals for the identity contract
        vm.startPrank(user1);
        usdc.approve(address(identity), type(uint256).max);
        ctm.approve(address(identity), type(uint256).max);
        vm.stopPrank();
        
        vm.startPrank(user2);
        usdc.approve(address(identity), type(uint256).max);
        ctm.approve(address(identity), type(uint256).max);
        vm.stopPrank();
    }

    // ============ SINGLE CHAIN FEE PAYMENT TESTS ============

    function test_verifyPerson_feePayment_singleChain() public {
        // Setup KYC
        vm.prank(tokenAdmin);
        sentryManager.setSentryOptions(ID, VERSION, true, true, false, false, false, false, false, chainIds, feeTokenStr);
        vm.prank(tokenAdmin);
        sentryManager.setZkMeParams(ID, VERSION, "", "", address(0x1234));
        zkMe.setApproved(true);
        
        // Get expected fee using FeeType.KYC
        uint256 expectedFee = feeManager.getXChainFee(chainIds, false, FeeType.KYC, feeTokenStr);
        
        // Record balances before
        uint256 userBalanceBefore = usdc.balanceOf(user1);
        uint256 feeManagerBalanceBefore = usdc.balanceOf(address(feeManager));
        
        // Execute verifyPerson
        vm.prank(user1);
        bool ok = identity.verifyPerson(ID, VERSION, chainIds, feeTokenStr);
        assertTrue(ok);
        
        // Verify fee payment
        uint256 userBalanceAfter = usdc.balanceOf(user1);
        uint256 feeManagerBalanceAfter = usdc.balanceOf(address(feeManager));
        
        assertEq(userBalanceBefore - userBalanceAfter, expectedFee, "User should pay correct KYC fee");
        assertEq(feeManagerBalanceAfter - feeManagerBalanceBefore, expectedFee, "FeeManager should receive KYC fee");
        
        // Verify user is whitelisted
        string memory userHex = user1.toHexString();
        assertTrue(sentry.isAllowableTransfer(userHex), "User should be whitelisted after payment");
    }

    function test_verifyPerson_feePayment_unsetFee() public {
        // Setup KYC first (before removing the fee token)
        vm.prank(tokenAdmin);
        sentryManager.setSentryOptions(ID, VERSION, true, true, false, false, false, false, false, chainIds, feeTokenStr);
        vm.prank(tokenAdmin);
        sentryManager.setZkMeParams(ID, VERSION, "", "", address(0x1234));
        zkMe.setApproved(true);
        
        // Now remove the fee token from the fee manager to simulate unset fee
        vm.prank(gov);
        feeManager.delFeeToken(feeTokenStr);
        
        // Record balances before
        uint256 userBalanceBefore = usdc.balanceOf(user1);
        
        // Execute verifyPerson - should revert because fee token is not supported
        vm.prank(user1);
        vm.expectRevert(abi.encodeWithSelector(IFeeManager.FeeManager_NonExistentToken.selector, address(usdc)));
        identity.verifyPerson(ID, VERSION, chainIds, feeTokenStr);
        
        // Verify no balance change
        uint256 userBalanceAfter = usdc.balanceOf(user1);
        assertEq(userBalanceBefore, userBalanceAfter, "User balance should not change on revert");
        
        // Re-add the fee token for other tests
        vm.prank(gov);
        feeManager.addFeeToken(feeTokenStr);
    }

    // ============ MULTIPLE CHAIN FEE PAYMENT TESTS ============

    function test_verifyPerson_feePayment_multipleChains() public {
        // Setup multiple chains using only chains that are configured in the gateway
        string[] memory multipleChains = new string[](2);
        multipleChains[0] = cIdStr;  // Local chain
        multipleChains[1] = "1";     // Ethereum (already configured in gateway)
        
        // Set up fees for Ethereum chain (needed for cross-chain operations)
        vm.startPrank(gov);
        string[] memory tokensStr = new string[](2);
        uint256[] memory fees = new uint256[](2);
        
        tokensStr[0] = _toLower(address(ctm).toHexString());
        tokensStr[1] = _toLower(address(usdc).toHexString());
        
        fees[0] = 10 ** 18; // 1 CTM baseFee (18 decimals)
        fees[1] = 10 ** 18; // 1 USDC baseFee (stored in 18 decimals, corrected to 6 decimals)
        
        // Add fees for Ethereum chain
        feeManager.addFeeToken("1", tokensStr, fees);
        
        // Add necessary operator permissions for C3 caller to work
        // This is needed for cross-chain calls to execute properly
        c3UUIDKeeper.addOperator(address(c3caller)); // Add C3Caller as operator to C3UUIDKeeper
        c3caller.addOperator(gov); // Add gov as an operator to C3Caller
        c3caller.addOperator(address(identity)); // Add identity as an operator to C3Caller
        vm.stopPrank();
        
        // Setup KYC
        vm.prank(tokenAdmin);
        sentryManager.setSentryOptions(ID, VERSION, true, true, false, false, false, false, false, multipleChains, feeTokenStr);
        vm.prank(tokenAdmin);
        sentryManager.setZkMeParams(ID, VERSION, "", "", address(0x1234));
        zkMe.setApproved(true);
        
        // Get expected fee for multiple chains using FeeType.KYC
        uint256 expectedFee = feeManager.getXChainFee(multipleChains, false, FeeType.KYC, feeTokenStr);
        
        // Verify that fee is proportional to number of chains
        uint256 singleChainFee = feeManager.getXChainFee(_stringToArray("1"), false, FeeType.KYC, feeTokenStr);
        assertEq(expectedFee, singleChainFee * 2, "Fee should be proportional to number of chains");
        
        // Record balances before
        uint256 userBalanceBefore = usdc.balanceOf(user1);
        uint256 feeManagerBalanceBefore = usdc.balanceOf(address(feeManager));
        
        // Execute verifyPerson with multiple chains
        vm.prank(user1);
        bool ok = identity.verifyPerson(ID, VERSION, multipleChains, feeTokenStr);
        assertTrue(ok);
        
        // Verify fee payment
        uint256 userBalanceAfter = usdc.balanceOf(user1);
        uint256 feeManagerBalanceAfter = usdc.balanceOf(address(feeManager));
        
        assertEq(userBalanceBefore - userBalanceAfter, expectedFee, "User should pay proportional fee for multiple chains");
        assertEq(feeManagerBalanceAfter - feeManagerBalanceBefore, expectedFee, "FeeManager should receive proportional fee");
        
        // Verify user is whitelisted
        string memory userHex = user1.toHexString();
        assertTrue(sentry.isAllowableTransfer(userHex), "User should be whitelisted after payment");
    }

    function test_verifyPerson_feePayment_includeLocalChain() public {
        // Setup multiple chains including local chain using only configured chains
        string[] memory chainsWithLocal = new string[](2);
        chainsWithLocal[0] = cIdStr;  // Local chain
        chainsWithLocal[1] = "1";     // Ethereum (already configured in gateway)
        
        // Set up fees for Ethereum chain
        vm.startPrank(gov);
        string[] memory tokensStr = new string[](2);
        uint256[] memory fees = new uint256[](2);
        
        tokensStr[0] = _toLower(address(ctm).toHexString());
        tokensStr[1] = _toLower(address(usdc).toHexString());
        
        fees[0] = 10 ** 18; // 1 CTM baseFee (18 decimals)
        fees[1] = 10 ** 18; // 1 USDC baseFee (stored in 18 decimals, corrected to 6 decimals)
        
        feeManager.addFeeToken("1", tokensStr, fees);
        
        // Add necessary operator permissions for C3 caller to work
        c3UUIDKeeper.addOperator(address(c3caller)); // Add C3Caller as operator to C3UUIDKeeper
        c3caller.addOperator(gov); // Add gov as an operator to C3Caller
        c3caller.addOperator(address(identity)); // Add identity as an operator to C3Caller
        vm.stopPrank();
        
        // Test fee calculation with includeLocal = false (as used in _payFee)
        uint256 feeWithoutLocal = feeManager.getXChainFee(chainsWithLocal, false, FeeType.KYC, feeTokenStr);
        
        // Test fee calculation with includeLocal = true
        uint256 feeWithLocal = feeManager.getXChainFee(chainsWithLocal, true, FeeType.KYC, feeTokenStr);
        
        // Fee with local should be higher than without local
        assertGt(feeWithLocal, feeWithoutLocal, "Fee with includeLocal=true should be higher than includeLocal=false");
        
        // Setup KYC
        vm.prank(tokenAdmin);
        sentryManager.setSentryOptions(ID, VERSION, true, true, false, false, false, false, false, chainsWithLocal, feeTokenStr);
        vm.prank(tokenAdmin);
        sentryManager.setZkMeParams(ID, VERSION, "", "", address(0x1234));
        zkMe.setApproved(true);
        
        // Get expected fee with includeLocal = false (as used in _payFee)
        uint256 expectedFee = feeManager.getXChainFee(chainsWithLocal, false, FeeType.KYC, feeTokenStr);
        
        // Record balances before
        uint256 userBalanceBefore = usdc.balanceOf(user1);
        
        // Execute verifyPerson
        vm.prank(user1);
        bool ok = identity.verifyPerson(ID, VERSION, chainsWithLocal, feeTokenStr);
        assertTrue(ok);
        
        // Verify fee payment
        uint256 userBalanceAfter = usdc.balanceOf(user1);
        assertEq(userBalanceBefore - userBalanceAfter, expectedFee, "User should pay correct fee including local chain");
    }

    // ============ FEE REDUCTION TESTS ============

    function test_verifyPerson_feeReduction() public {
        // Setup fee reduction for user1 (50% reduction)
        address[] memory addresses = new address[](1);
        addresses[0] = user1;
        uint256[] memory reductions = new uint256[](1);
        reductions[0] = 5000; // 50% reduction
        uint256[] memory expirations = new uint256[](1);
        expirations[0] = block.timestamp + 1 days;
        
        vm.prank(gov);
        feeManager.addFeeReduction(addresses, reductions, expirations);
        
        // Setup KYC
        vm.prank(tokenAdmin);
        sentryManager.setSentryOptions(ID, VERSION, true, true, false, false, false, false, false, chainIds, feeTokenStr);
        vm.prank(tokenAdmin);
        sentryManager.setZkMeParams(ID, VERSION, "", "", address(0x1234));
        zkMe.setApproved(true);
        
        // Get base fee and expected reduced fee
        uint256 baseFee = feeManager.getXChainFee(chainIds, false, FeeType.KYC, feeTokenStr);
        uint256 expectedReducedFee = baseFee * 5000 / 10000; // 50% reduction
        
        // Record balances before
        uint256 userBalanceBefore = usdc.balanceOf(user1);
        
        // Execute verifyPerson with fee reduction
        vm.prank(user1);
        bool ok = identity.verifyPerson(ID, VERSION, chainIds, feeTokenStr);
        assertTrue(ok);
        
        // Verify fee payment with reduction
        uint256 userBalanceAfter = usdc.balanceOf(user1);
        assertEq(userBalanceBefore - userBalanceAfter, expectedReducedFee, "User should pay reduced fee");
        
        // Verify user is whitelisted
        string memory userHex = user1.toHexString();
        assertTrue(sentry.isAllowableTransfer(userHex), "User should be whitelisted after payment");
    }

    function test_verifyPerson_feeReduction_expired() public {
        // Setup fee reduction for user1 (50% reduction) that will expire soon
        address[] memory addresses = new address[](1);
        addresses[0] = user1;
        uint256[] memory reductions = new uint256[](1);
        reductions[0] = 5000; // 50% reduction
        uint256[] memory expirations = new uint256[](1);
        expirations[0] = block.timestamp + 1 hours; // Expires in 1 hour
        
        vm.prank(gov);
        feeManager.addFeeReduction(addresses, reductions, expirations);
        
        // Warp time forward to make the reduction expire
        vm.warp(block.timestamp + 2 hours);
        
        // Setup KYC
        vm.prank(tokenAdmin);
        sentryManager.setSentryOptions(ID, VERSION, true, true, false, false, false, false, false, chainIds, feeTokenStr);
        vm.prank(tokenAdmin);
        sentryManager.setZkMeParams(ID, VERSION, "", "", address(0x1234));
        zkMe.setApproved(true);
        
        // Get expected full fee (no reduction since expired)
        uint256 expectedFee = feeManager.getXChainFee(chainIds, false, FeeType.KYC, feeTokenStr);
        
        // Record balances before
        uint256 userBalanceBefore = usdc.balanceOf(user1);
        
        // Execute verifyPerson with expired fee reduction
        vm.prank(user1);
        bool ok = identity.verifyPerson(ID, VERSION, chainIds, feeTokenStr);
        assertTrue(ok);
        
        // Verify full fee payment (no reduction)
        uint256 userBalanceAfter = usdc.balanceOf(user1);
        assertEq(userBalanceBefore - userBalanceAfter, expectedFee, "User should pay full fee when reduction is expired");
    }

    // ============ EDGE CASE TESTS ============

    function test_verifyPerson_insufficientBalance() public {
        // Setup KYC
        vm.prank(tokenAdmin);
        sentryManager.setSentryOptions(ID, VERSION, true, true, false, false, false, false, false, chainIds, feeTokenStr);
        vm.prank(tokenAdmin);
        sentryManager.setZkMeParams(ID, VERSION, "", "", address(0x1234));
        zkMe.setApproved(true);
        
        // Create a user with insufficient balance
        address poorUser = address(0x9999);
        vm.deal(poorUser, 1 ether); // Give some ETH but no USDC
        
        // Try to verify with insufficient balance
        vm.prank(poorUser);
        vm.expectRevert(); // Should revert due to insufficient balance
        identity.verifyPerson(ID, VERSION, chainIds, feeTokenStr);
    }

    function test_verifyPerson_differentFeeTokens() public {
        // Setup KYC
        vm.prank(tokenAdmin);
        sentryManager.setSentryOptions(ID, VERSION, true, true, false, false, false, false, false, chainIds, feeTokenStr);
        vm.prank(tokenAdmin);
        sentryManager.setZkMeParams(ID, VERSION, "", "", address(0x1234));
        zkMe.setApproved(true);
        
        // Test with CTM token instead of USDC
        string memory ctmFeeTokenStr = address(ctm).toHexString();
        
        // Get expected fee for CTM
        uint256 expectedFee = feeManager.getXChainFee(chainIds, false, FeeType.KYC, ctmFeeTokenStr);
        
        // Record balances before
        uint256 userBalanceBefore = ctm.balanceOf(user1);
        
        // Execute verifyPerson with CTM fee token
        vm.prank(user1);
        bool ok = identity.verifyPerson(ID, VERSION, chainIds, ctmFeeTokenStr);
        assertTrue(ok);
        
        // Verify fee payment with CTM
        uint256 userBalanceAfter = ctm.balanceOf(user1);
        assertEq(userBalanceBefore - userBalanceAfter, expectedFee, "User should pay correct fee in CTM");
    }

}
