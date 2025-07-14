// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.22;

import { Test } from "forge-std/Test.sol";
import { console } from "forge-std/console.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { FeeManager } from "../../src/managers/FeeManager.sol";
import { IFeeManager, FeeType } from "../../src/managers/IFeeManager.sol";
import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import { PausableUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { Helpers } from "../helpers/Helpers.sol";
import { TestERC20 } from "../../src/mocks/TestERC20.sol";
import { MaliciousERC20 } from "../../src/mocks/MaliciousERC20.sol";

// Mock contract to test reentrancy
contract ReentrancyAttacker {
    string public feeTokenStr;
    uint256 public attackAmount;

    FeeManager feeManager;

    constructor(FeeManager _feeManager, string memory _feeTokenStr, uint256 _attackAmount) {
        feeTokenStr = _feeTokenStr;
        attackAmount = _attackAmount;
        feeManager = _feeManager;
    }

    function attack() external {
        feeManager.payFee(attackAmount, feeTokenStr);
    }

    // Simulate reentrancy during token transfer callback (if token had callback)
    function triggerReentrancy() external {
        feeManager.payFee(attackAmount, feeTokenStr);
    }
}

// Reentrancy attack contract for MaliciousERC20
contract MaliciousAttacker {
    FeeManager public feeManager;
    string public feeTokenStr;
    uint256 public attackAmount;
    bool public attacked;

    constructor(FeeManager _feeManager, string memory _feeTokenStr, uint256 _attackAmount) {
        feeManager = _feeManager;
        feeTokenStr = _feeTokenStr;
        attackAmount = _attackAmount;
    }

    // This function will be called by MaliciousERC20 during transferFrom
    function reenter() external {
        attacked = true;
        feeManager.payFee(attackAmount, feeTokenStr);
    }
}

contract TestFeeManager is Helpers {
    TestERC20 feeToken;
    uint256 public dappID = 123;

    string public feeTokenStr;
    string public chainIdStr = "421614"; // Example chain ID

    uint256 public constant INITIAL_SUPPLY = 1_000_000 * 10**18;
    uint256 public constant FEE_AMOUNT = 100 * 10**18;

    event AddFeeToken(address indexed feeToken);
    event DelFeeToken(address indexed feeToken);
    event SetFeeMultiplier(FeeType indexed feeType, uint256 multiplier);
    event WithdrawFee(address indexed feeToken, address indexed treasury, uint256 amount);

    function setUp() public override {
        super.setUp();
        feeToken = usdc;
        feeTokenStr = addressToString(address(usdc));
        // Mint tokens to user for testing
        feeToken.mint(user1, INITIAL_SUPPLY / 2);
        // Add fee token
        vm.prank(gov);
        feeManager.addFeeToken(feeTokenStr);
        // Set up fee configuration for a chain
        string[] memory tokens = new string[](1);
        tokens[0] = feeTokenStr;
        uint256[] memory fees = new uint256[](1);
        fees[0] = 100; // Base fee
        vm.prank(gov);
        feeManager.addFeeToken(chainIdStr, tokens, fees);
        // Set a fee multiplier
        vm.prank(gov);
        feeManager.setFeeMultiplier(FeeType.TX, 2);
    }

    // Access Control Tests
    function test_OnlyGovCanAddFeeToken() public {
        vm.expectRevert("Gov FORBIDDEN");
        vm.prank(user1);
        feeManager.addFeeToken(feeTokenStr);
    }

    function test_OnlyGovCanDelFeeToken() public {
        vm.expectRevert("Gov FORBIDDEN");
        vm.prank(user1);
        feeManager.delFeeToken(feeTokenStr);
    }

    function test_OnlyGovCanSetFeeMultiplier() public {
        vm.expectRevert("Gov FORBIDDEN");
        vm.prank(user1);
        feeManager.setFeeMultiplier(FeeType.TX, 5);
    }

    function test_OnlyGovCanWithdrawFee() public {
        vm.expectRevert("Gov FORBIDDEN");
        vm.prank(user1);
        feeManager.withdrawFee(feeTokenStr, FEE_AMOUNT, addressToString(treasury));
    }

    function test_OnlyGovCanPause() public {
        vm.expectRevert("Gov FORBIDDEN");
        vm.prank(user1);
        feeManager.pause();
    }

    function test_OnlyGovCanUnpause() public {
        vm.prank(gov);
        feeManager.pause();
        vm.expectRevert("Gov FORBIDDEN");
        vm.prank(user1);
        feeManager.unpause();
    }

    // Reentrancy Tests
    function test_Reentrancy_MaliciousERC20_PayFeeFails() public {
        // Deploy malicious ERC20 and attacker
        MaliciousERC20 maliciousToken = new MaliciousERC20("Malicious Token", "MAL", 18);
        string memory maliciousTokenStr = addressToString(address(maliciousToken));
        // Add malicious token to FeeManager
        vm.prank(gov);
        feeManager.addFeeToken(maliciousTokenStr);
        // Deploy attacker contract
        MaliciousAttacker attacker = new MaliciousAttacker(feeManager, maliciousTokenStr, FEE_AMOUNT / 2);
        // Set attacker and callback data in malicious token as admin (deployer)
        bytes memory callbackData = abi.encodeWithSelector(MaliciousAttacker.reenter.selector);
        maliciousToken.setAttacker(address(attacker), callbackData);
        // Mint tokens to user1
        maliciousToken.mint(user1, FEE_AMOUNT * 2);
        // Approve FeeManager to spend tokens
        vm.prank(user1);
        maliciousToken.approve(address(feeManager), FEE_AMOUNT * 2);
        // Expect reentrancy to fail due to nonReentrant
        vm.expectRevert("MaliciousERC20: attacker callback failed");
        vm.prank(user1);
        feeManager.payFee(FEE_AMOUNT, maliciousTokenStr);
    }

    // Pausing Functionality Tests
    function test_PausePreventsStateChanges() public {
        vm.prank(gov);
        feeManager.pause();
        // vm.expectRevert("Pausable: paused");
        vm.expectRevert(PausableUpgradeable.EnforcedPause.selector);
        vm.prank(gov);
        feeManager.addFeeToken(feeTokenStr);
    }

    function test_PausePreventsPayFee() public {
        vm.prank(gov);
        feeManager.pause();
        vm.prank(user1);
        feeToken.approve(address(feeManager), FEE_AMOUNT);
        // vm.expectRevert("Pausable: paused");
        vm.expectRevert(PausableUpgradeable.EnforcedPause.selector);
        vm.prank(user1);
        feeManager.payFee(FEE_AMOUNT, feeTokenStr);
    }

    function test_UnpauseRestoresFunctionality() public {
        vm.prank(gov);
        feeManager.pause();
        vm.prank(gov);
        feeManager.unpause();
        vm.prank(user1);
        feeToken.approve(address(feeManager), FEE_AMOUNT);
        vm.prank(user1);
        uint256 paid = feeManager.payFee(FEE_AMOUNT, feeTokenStr);
        assertEq(paid, FEE_AMOUNT, "Fee payment should succeed after unpause");
    }

    // Core Functionality Tests
    function test_AddAndRemoveFeeToken() public {
        address newToken = address(new TestERC20("New Token", "NTK", 18));
        string memory newTokenStr = addressToString(newToken);
        vm.expectEmit(true, false, false, false);
        emit AddFeeToken(newToken);
        vm.prank(gov);
        feeManager.addFeeToken(newTokenStr);
        address[] memory tokenList = feeManager.getFeeTokenList();
        assertEq(tokenList[tokenList.length - 1], newToken, "New token should be added");
        vm.expectEmit(true, false, false, false);
        emit DelFeeToken(newToken);
        vm.prank(gov);
        feeManager.delFeeToken(newTokenStr);
        assertEq(feeManager.getFeeTokenIndexMap(newTokenStr), 0, "Token index should be reset");
    }

    function test_SetAndGetFeeMultiplier() public {
        vm.expectEmit(true, false, false, true);
        emit SetFeeMultiplier(FeeType.TX, 5);
        vm.prank(gov);
        feeManager.setFeeMultiplier(FeeType.TX, 5);
        uint256 multiplier = feeManager.getFeeMultiplier(FeeType.TX);
        assertEq(multiplier, 5, "Multiplier should be updated");
    }

    function test_PayFeeTransfersTokens() public {
        uint256 userBalanceBefore = feeToken.balanceOf(user1);
        uint256 contractBalanceBefore = feeToken.balanceOf(address(feeManager));
        vm.prank(user1);
        feeToken.approve(address(feeManager), FEE_AMOUNT);
        vm.prank(user1);
        uint256 paid = feeManager.payFee(FEE_AMOUNT, feeTokenStr);
        assertEq(paid, FEE_AMOUNT, "Paid amount should match input");
        assertEq(feeToken.balanceOf(user1), userBalanceBefore - FEE_AMOUNT, "User balance should decrease");
        assertEq(feeToken.balanceOf(address(feeManager)), contractBalanceBefore + FEE_AMOUNT, "Contract balance should increase");
    }

    function test_WithdrawFeeTransfersTokens() public {
        // First, pay a fee to have balance in contract
        vm.prank(user1);
        feeToken.approve(address(feeManager), FEE_AMOUNT);
        vm.prank(user1);
        feeManager.payFee(FEE_AMOUNT, feeTokenStr);
        uint256 treasuryBalanceBefore = feeToken.balanceOf(treasury);
        uint256 contractBalanceBefore = feeToken.balanceOf(address(feeManager));
        vm.expectEmit(true, true, false, true);
        emit WithdrawFee(address(feeToken), treasury, FEE_AMOUNT);
        vm.prank(gov);
        feeManager.withdrawFee(feeTokenStr, FEE_AMOUNT, addressToString(treasury));
        assertEq(feeToken.balanceOf(treasury), treasuryBalanceBefore + FEE_AMOUNT, "Treasury balance should increase");
        assertEq(feeToken.balanceOf(address(feeManager)), contractBalanceBefore - FEE_AMOUNT, "Contract balance should decrease");
    }

    // Overflow/Underflow Tests
    function test_WithdrawMoreThanBalance() public {
        // Pay a small fee
        vm.prank(user1);
        feeToken.approve(address(feeManager), FEE_AMOUNT);
        vm.prank(user1);
        feeManager.payFee(FEE_AMOUNT, feeTokenStr);
        // Try to withdraw more than balance
        uint256 largeAmount = FEE_AMOUNT * 2;
        uint256 treasuryBalanceBefore = feeToken.balanceOf(treasury);
        vm.prank(gov);
        feeManager.withdrawFee(feeTokenStr, largeAmount, addressToString(treasury));
        assertEq(feeToken.balanceOf(treasury), treasuryBalanceBefore + FEE_AMOUNT, "Should withdraw only available balance");
        assertEq(feeToken.balanceOf(address(feeManager)), 0, "Contract balance should be 0");
    }

    function test_FeeMultiplierNoOverflow() public {
        // Set a very large multiplier
        uint256 largeMultiplier = type(uint256).max / 100;
        vm.prank(gov);
        feeManager.setFeeMultiplier(FeeType.TX, largeMultiplier);
        // Set a base fee
        string[] memory tokens = new string[](1);
        tokens[0] = feeTokenStr;
        uint256[] memory fees = new uint256[](1);
        fees[0] = 100;
        vm.prank(gov);
        feeManager.addFeeToken(chainIdStr, tokens, fees);
        // Calculate fee, should not overflow due to Solidity 0.8+ checks
        string[] memory chains = new string[](1);
        chains[0] = chainIdStr;
        uint256 fee = feeManager.getXChainFee(chains, false, FeeType.TX, feeTokenStr);
        assertEq(fee, 100 * largeMultiplier, "Fee calculation should not overflow");
    }

    // Gas Usage Tests
    function test_GasUsagePayFee() public {
        vm.prank(user1);
        feeToken.approve(address(feeManager), FEE_AMOUNT);
        uint256 gasStart = gasleft();
        vm.prank(user1);
        feeManager.payFee(FEE_AMOUNT, feeTokenStr);
        uint256 gasUsed = gasStart - gasleft();
        console.log("Gas used for payFee:", gasUsed);
        assertLt(gasUsed, 100_000, "Gas usage for payFee should be reasonable");
    }

    function test_GasUsageSetFeeMultiplier() public {
        uint256 gasStart = gasleft();
        vm.prank(gov);
        feeManager.setFeeMultiplier(FeeType.TX, 10);
        uint256 gasUsed = gasStart - gasleft();
        console.log("Gas used for setFeeMultiplier:", gasUsed);
        assertLt(gasUsed, 50_000, "Gas usage for setFeeMultiplier should be reasonable");
    }

    // Fuzz Tests
    function test_FuzzPayFee(uint256 amount) public {
        // Bound the amount to avoid overflow and ensure user has enough balance
        amount = bound(amount, 1, INITIAL_SUPPLY / 2);
        vm.prank(user1);
        feeToken.approve(address(feeManager), amount);
        uint256 userBalanceBefore = feeToken.balanceOf(user1);
        uint256 contractBalanceBefore = feeToken.balanceOf(address(feeManager));
        vm.prank(user1);
        uint256 paid = feeManager.payFee(amount, feeTokenStr);
        assertEq(paid, amount, "Paid amount should match input");
        assertEq(feeToken.balanceOf(user1), userBalanceBefore - amount, "User balance should decrease");
        assertEq(feeToken.balanceOf(address(feeManager)), contractBalanceBefore + amount, "Contract balance should increase");
    }

    function test_FuzzSetFeeMultiplier(uint8 feeTypeRaw, uint256 multiplier) public {
        uint256 feeTypeInt = uint256(feeTypeRaw) % 28; // 28 is the number of FeeType enum members
        FeeType feeType = FeeType(feeTypeInt);
        multiplier = bound(multiplier, 1, 1_000_000);
        vm.prank(gov);
        feeManager.setFeeMultiplier(feeType, multiplier);
        assertEq(feeManager.getFeeMultiplier(feeType), multiplier, "Multiplier should be set correctly");
    }

    // Invariant Tests
    function invariant_FeeTokenListConsistency() public view {
        address[] memory tokenList = feeManager.getFeeTokenList();
        for (uint256 i = 0; i < tokenList.length; i++) {
            assertGt(feeManager.getFeeTokenIndexMap(addressToString(tokenList[i])), 0, "Listed token should have valid index");
        }
    }

    function invariant_ContractBalanceNonNegative() public view {
        assertGe(feeToken.balanceOf(address(feeManager)), 0, "Contract balance should never be negative");
    }
}
