// SPDX-License-Identifier: BSL-1.1
pragma solidity 0.8.27;

import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { PausableUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import { IC3GovernDApp } from "@c3caller/gov/IC3GovernDApp.sol";
import { C3ErrorParam } from "@c3caller/utils/C3CallerUtils.sol";

import { FeeManager } from "../../src/managers/FeeManager.sol";
import { FeeType, IERC20Extended, IFeeManager } from "../../src/managers/IFeeManager.sol";

import { MaliciousERC20 } from "../../src/mocks/MaliciousERC20.sol";
import { TestERC20 } from "../../src/mocks/TestERC20.sol";
import { Uint } from "../../src/utils/CTMRWAUtils.sol";
import { Helpers } from "../helpers/Helpers.sol";
import { Test } from "forge-std/Test.sol";
import { console } from "forge-std/console.sol";

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

    uint256 public constant INITIAL_SUPPLY = 1_000_000 * 10 ** 18;
    uint256 public constant FEE_AMOUNT = 100 * 10 ** 18;

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
        vm.expectRevert(
            abi.encodeWithSelector(
                IC3GovernDApp.C3GovernDApp_OnlyAuthorized.selector, C3ErrorParam.Sender, C3ErrorParam.GovOrC3Caller
            )
        );
        vm.prank(user1);
        feeManager.addFeeToken(feeTokenStr);
    }

    function test_OnlyGovCanDelFeeToken() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                IC3GovernDApp.C3GovernDApp_OnlyAuthorized.selector, C3ErrorParam.Sender, C3ErrorParam.GovOrC3Caller
            )
        );
        vm.prank(user1);
        feeManager.delFeeToken(feeTokenStr);
    }

    function test_OnlyGovCanSetFeeMultiplier() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                IC3GovernDApp.C3GovernDApp_OnlyAuthorized.selector, C3ErrorParam.Sender, C3ErrorParam.GovOrC3Caller
            )
        );
        vm.prank(user1);
        feeManager.setFeeMultiplier(FeeType.TX, 5);
    }

    function test_OnlyGovCanWithdrawFee() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                IC3GovernDApp.C3GovernDApp_OnlyAuthorized.selector, C3ErrorParam.Sender, C3ErrorParam.GovOrC3Caller
            )
        );
        vm.prank(user1);
        feeManager.withdrawFee(feeTokenStr, FEE_AMOUNT, addressToString(treasury));
    }

    function test_OnlyGovCanPause() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                IC3GovernDApp.C3GovernDApp_OnlyAuthorized.selector, C3ErrorParam.Sender, C3ErrorParam.GovOrC3Caller
            )
        );
        vm.prank(user1);
        feeManager.pause();
    }

    function test_OnlyGovCanUnpause() public {
        vm.prank(gov);
        feeManager.pause();
        vm.expectRevert(
            abi.encodeWithSelector(
                IC3GovernDApp.C3GovernDApp_OnlyAuthorized.selector, C3ErrorParam.Sender, C3ErrorParam.GovOrC3Caller
            )
        );
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

    function test_AddDeleteMultipleFeeTokens() public {
        // Add three new fee tokens
        address tokenA = address(new TestERC20("TokenA", "TKA", 18));
        address tokenB = address(new TestERC20("TokenB", "TKB", 18));
        address tokenC = address(new TestERC20("TokenC", "TKC", 18));
        string memory tokenAStr = addressToString(tokenA);
        string memory tokenBStr = addressToString(tokenB);
        string memory tokenCStr = addressToString(tokenC);

        // Add all tokens
        vm.prank(gov);
        feeManager.addFeeToken(tokenAStr);
        vm.prank(gov);
        feeManager.addFeeToken(tokenBStr);
        vm.prank(gov);
        feeManager.addFeeToken(tokenCStr);

        // Check all tokens are present
        address[] memory tokenList = feeManager.getFeeTokenList();
        assertEq(tokenList[tokenList.length - 3], tokenA, "TokenA should be present");
        assertEq(tokenList[tokenList.length - 2], tokenB, "TokenB should be present");
        assertEq(tokenList[tokenList.length - 1], tokenC, "TokenC should be present");

        // Delete tokenB (middle)
        vm.prank(gov);
        feeManager.delFeeToken(tokenBStr);
        tokenList = feeManager.getFeeTokenList();
        // TokenA and TokenC should still be present
        bool foundA = false;
        bool foundC = false;
        for (uint256 i = 0; i < tokenList.length; i++) {
            if (tokenList[i] == tokenA) {
                foundA = true;
            }
            if (tokenList[i] == tokenC) {
                foundC = true;
            }
            assert(tokenList[i] != tokenB); // TokenB should not be present
        }
        assertTrue(foundA, "TokenA should still be present after deleting TokenB");
        assertTrue(foundC, "TokenC should still be present after deleting TokenB");

        // Delete tokenC (end)
        vm.prank(gov);
        feeManager.delFeeToken(tokenCStr);
        tokenList = feeManager.getFeeTokenList();
        // Only TokenA should remain
        foundA = false;
        for (uint256 i = 0; i < tokenList.length; i++) {
            if (tokenList[i] == tokenA) {
                foundA = true;
            }
            assert(tokenList[i] != tokenB && tokenList[i] != tokenC); // TokenB and TokenC should not be present
        }
        assertTrue(foundA, "TokenA should still be present after deleting TokenC");
    }

    function testFuzz_AddDeleteMultipleFeeTokens(uint8 numTokensRaw, uint8 deleteMidRaw) public {
        uint8 numTokens = uint8(bound(numTokensRaw, 3, 20)); // At least 3 tokens, max 20
        address[] memory tokens = new address[](numTokens);
        string[] memory tokenStrs = new string[](numTokens);
        // Add all tokens
        for (uint8 i = 0; i < numTokens; i++) {
            tokens[i] = address(uint160(uint256(keccak256(abi.encodePacked(i, block.timestamp, address(this))))));
            tokenStrs[i] = addressToString(tokens[i]);
            vm.prank(gov);
            feeManager.addFeeToken(tokenStrs[i]);
        }
        // Check all tokens are present
        address[] memory tokenList = feeManager.getFeeTokenList();
        for (uint8 i = 0; i < numTokens; i++) {
            assertEq(tokenList[tokenList.length - numTokens + i], tokens[i], "Token should be present");
        }
        // Delete a token from the middle
        uint8 deleteMid = uint8(bound(deleteMidRaw, 1, numTokens - 2)); // Not first or last
        vm.prank(gov);
        feeManager.delFeeToken(tokenStrs[deleteMid]);
        tokenList = feeManager.getFeeTokenList();
        // Check all tokens except deleted one are present
        for (uint8 i = 0; i < numTokens; i++) {
            bool found = false;
            for (uint256 j = 0; j < tokenList.length; j++) {
                if (tokenList[j] == tokens[i]) {
                    found = true;
                }
            }
            if (i == deleteMid) {
                assertTrue(!found, "Deleted token should not be present");
            } else {
                assertTrue(found, "Token should still be present");
            }
        }
        // Delete a token from the end (last in the original array, unless it was already deleted)
        uint8 deleteEnd = numTokens - 1;
        if (deleteEnd == deleteMid) {
            deleteEnd--;
        }
        vm.prank(gov);
        feeManager.delFeeToken(tokenStrs[deleteEnd]);
        tokenList = feeManager.getFeeTokenList();
        // Check all tokens except deleted ones are present
        for (uint8 i = 0; i < numTokens; i++) {
            bool found = false;
            for (uint256 j = 0; j < tokenList.length; j++) {
                if (tokenList[j] == tokens[i]) {
                    found = true;
                }
            }
            if (i == deleteMid || i == deleteEnd) {
                assertTrue(!found, "Deleted token should not be present");
            } else {
                assertTrue(found, "Token should still be present");
            }
        }
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
        assertEq(
            feeToken.balanceOf(address(feeManager)),
            contractBalanceBefore + FEE_AMOUNT,
            "Contract balance should increase"
        );
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
        assertEq(
            feeToken.balanceOf(address(feeManager)),
            contractBalanceBefore - FEE_AMOUNT,
            "Contract balance should decrease"
        );
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
        assertEq(
            feeToken.balanceOf(treasury), treasuryBalanceBefore + FEE_AMOUNT, "Should withdraw only available balance"
        );
        assertEq(feeToken.balanceOf(address(feeManager)), 0, "Contract balance should be 0");
    }

    function test_FeeMultiplierNoOverflow() public {
        // Set a very large multiplier (should revert)
        uint256 largeMultiplier = 1e55 + 1; // MAX_SAFE_MULTIPLIER + 1 (hardcoded, since not public)
        vm.expectRevert(abi.encodeWithSelector(IFeeManager.FeeManager_InvalidLength.selector, Uint.Multiplier));
        vm.prank(gov);
        feeManager.setFeeMultiplier(FeeType.TX, largeMultiplier);
        // Set a safe multiplier (should succeed)
        uint256 safeMultiplier = 1e55; // MAX_SAFE_MULTIPLIER (hardcoded)
        vm.prank(gov);
        feeManager.setFeeMultiplier(FeeType.TX, safeMultiplier);
        // Set a base fee
        string[] memory tokens = new string[](1);
        tokens[0] = feeTokenStr;
        uint256[] memory fees = new uint256[](1);
        fees[0] = 100;
        vm.prank(gov);
        feeManager.addFeeToken(chainIdStr, tokens, fees);
        // Calculate fee, should not overflow
        string[] memory chains = new string[](1);
        chains[0] = chainIdStr;
        // uint8 decimals = IERC20Extended(address(feeToken)).decimals();
        uint256 expectedFee = 100 * safeMultiplier; // baseFee is already in wei
        uint256 fee = feeManager.getXChainFee(chains, false, FeeType.TX, feeTokenStr);
        assertEq(fee, expectedFee, "Fee calculation should not overflow and should match contract logic");
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
        assertEq(
            feeToken.balanceOf(address(feeManager)), contractBalanceBefore + amount, "Contract balance should increase"
        );
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
            assertGt(
                feeManager.getFeeTokenIndexMap(addressToString(tokenList[i])), 0, "Listed token should have valid index"
            );
        }
    }

    function invariant_ContractBalanceNonNegative() public view {
        assertGe(feeToken.balanceOf(address(feeManager)), 0, "Contract balance should never be negative");
    }
}
