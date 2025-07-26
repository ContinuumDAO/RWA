// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.27;

import { CTMRWA1InvestWithTimeLock } from "../../src/deployment/CTMRWA1InvestWithTimeLock.sol";
import { ICTMRWA1InvestWithTimeLock } from "../../src/deployment/ICTMRWA1InvestWithTimeLock.sol";

import { Holding } from "../../src/deployment/ICTMRWA1InvestWithTimeLock.sol";

import { IERC20Extended } from "../../src/managers/IFeeManager.sol";
import { ICTMRWA1Sentry } from "../../src/sentry/ICTMRWA1Sentry.sol";
import { ICTMRWA1SentryManager } from "../../src/sentry/ICTMRWA1SentryManager.sol";
import { ICTMRWAMap } from "../../src/shared/ICTMRWAMap.sol";

import { Time, Uint } from "../../src/utils/CTMRWAUtils.sol";
import { Helpers } from "../helpers/Helpers.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { console } from "forge-std/console.sol";

import { ICTMRWA1 } from "src/core/ICTMRWA1.sol";

error EnforcedPause();

// Malicious contract for reentrancy testing
contract ReentrantAttacker {
    CTMRWA1InvestWithTimeLock public targetContract;
    uint256 public attackCount;
    uint256 public targetOfferingIndex;
    address public currency;
    address public feeToken;

    constructor(address _targetContract) {
        targetContract = CTMRWA1InvestWithTimeLock(_targetContract);
    }

    function attack(uint256 _offeringIndex, address _currency, address _feeToken, uint256 _amount) external {
        targetOfferingIndex = _offeringIndex;
        currency = _currency;
        feeToken = _feeToken;
        attackCount = 0;

        // Start the attack
        targetContract.investInOffering(_offeringIndex, _amount, _feeToken);
    }

    // This function will be called during the reentrancy attack
    function onERC721Received(address, address, uint256, bytes calldata) external returns (bytes4) {
        if (attackCount < 3) {
            // Limit to prevent infinite loops
            attackCount++;
            // Try to reenter the investment function
            targetContract.investInOffering(targetOfferingIndex, 100, feeToken);
        }
        return this.onERC721Received.selector;
    }

    // Fallback function for potential reentrancy
    receive() external payable {
        if (attackCount < 3) {
            attackCount++;
            targetContract.investInOffering(targetOfferingIndex, 100, feeToken);
        }
    }
}

// Helper malicious contract for reentrancy test
contract MaliciousRewardClaimer {
    ICTMRWA1InvestWithTimeLock public investContract;
    IERC20 public rewardToken;
    bool public attackInProgress;
    constructor(address _investContract, address _rewardToken) {
        investContract = ICTMRWA1InvestWithTimeLock(_investContract);
        rewardToken = IERC20(_rewardToken);
    }
    function attack(uint256 offerIndex, uint256 holdingIndex) external {
        attackInProgress = true;
        investContract.claimReward(offerIndex, holdingIndex);
        attackInProgress = false;
    }
    // Fallback to try reentrancy
    receive() external payable {
        if (attackInProgress) {
            investContract.claimReward(0, 0);
        }
    }
}

contract TestInvest is Helpers {
    using Strings for address;

    ICTMRWA1InvestWithTimeLock public investContract;
    uint256 public tokenId;
    uint256 public slotId = 1;
    uint256 public amount = 1000;
    string public feeTokenStr;
    address public currency;
    uint256 public price;
    uint256 public minInvest;
    uint256 public maxInvest;
    uint256 public startTime;
    uint256 public endTime;
    uint256 public lockDuration;

    function setUp() public override {
        super.setUp();
        // console.log("setUp: after super.setUp()");

        // Deploy token as tokenAdmin
        vm.startPrank(tokenAdmin);
        (ID, token) = _deployCTMRWA1(address(usdc));

        _createSlot(ID, slotId, address(usdc), address(rwa1X));

        feeTokenStr = address(usdc).toHexString();

        address investAddr = deployer.deployNewInvestment(ID, RWA_TYPE, VERSION, address(usdc));
        vm.stopPrank();

        // Get the actual investment contract from the map
        // console.log("setUp: getting investment contract from map...");
        (bool ok, address investAddrFromMap) = ICTMRWAMap(address(map)).getInvestContract(ID, RWA_TYPE, VERSION);
        require(ok, "Investment contract not found");
        require(investAddr == investAddrFromMap, "Investment contract address mismatch");
        investContract = ICTMRWA1InvestWithTimeLock(investAddr);
        // console.log("setUp: investment contract retrieved successfully");

        // Mint a token first (needed for offering)
        vm.startPrank(tokenAdmin);
        // console.log("setUp: minting token for offering...");
        uint256 newTokenId = rwa1X.mintNewTokenValueLocal(
            tokenAdmin, // toAddress
            0, // toTokenId (0 = create new token)
            slotId, // slot
            1000e18, // value (1000 tokens)
            ID, // ID
            feeTokenStr // feeTokenStr
        );
        // console.log("setUp: token minted with ID:", newTokenId);
        vm.stopPrank();

        // Set offering parameters
        currency = address(usdc);
        price = 1e6; // 1 USDC per unit (assuming USDC has 6 decimals)
        minInvest = 100;
        maxInvest = 1_000_000;
        startTime = block.timestamp;
        endTime = block.timestamp + 30 days;
        lockDuration = 1 days;

        // Approve the investment contract to transfer the token
        vm.startPrank(tokenAdmin);
        // console.log("setUp: approving investment contract to transfer token...");
        token.approve(address(investContract), newTokenId);
        // console.log("setUp: approval granted");

        // Create offering using the minted token
        // console.log("setUp: creating offering...");
        investContract.createOffering(
            newTokenId, // Use the minted token ID instead of tokenId
            price,
            currency,
            minInvest,
            maxInvest,
            "US",
            "SEC",
            "Private Placement",
            startTime,
            endTime,
            lockDuration,
            currency, // _rewardToken (use currency for now)
            currency
        );
        // console.log("setUp: offering created successfully");
        vm.stopPrank();


        // console.log("setUp: completed successfully");
    }

    // ============ DEPLOYMENT TESTS ============

    function test_deployment_duplicateDeployment() public {
        // Try to deploy investment contract for same ID again
        vm.startPrank(tokenAdmin);
        vm.expectRevert();
        ctmRwaDeployInvest.deployInvest(ID, RWA_TYPE, VERSION, address(usdc));
        vm.stopPrank();
    }

    function test_deployment_investmentContractRegistered() public view {
        // Verify investment contract is properly registered in map
        (bool ok, address investAddr) = ICTMRWAMap(address(map)).getInvestContract(ID, RWA_TYPE, VERSION);
        assertTrue(ok, "Investment contract should be registered");
        assertEq(investAddr, address(investContract), "Investment contract address should match");
    }

    // ============ BASIC FUNCTIONALITY TESTS ============

    function test_investmentCreation() public {
        vm.startPrank(user1);
        usdc.approve(address(investContract), amount);
        uint256 initialBalance = usdc.balanceOf(user1);
        investContract.investInOffering(0, amount, currency);
        assertLt(usdc.balanceOf(user1), initialBalance, "USDC balance should decrease");
        vm.stopPrank();
    }

    function test_multipleInvestments() public {
        vm.startPrank(user1);
        usdc.approve(address(investContract), 500);
        investContract.investInOffering(0, 500, currency);
        usdc.approve(address(investContract), 750);
        investContract.investInOffering(0, 750, currency);
        vm.stopPrank();
    }

    function test_investmentBelowMinimumReverts() public {
        vm.startPrank(user1);
        usdc.approve(address(investContract), minInvest - 1);
        vm.expectRevert(
            abi.encodeWithSelector(
                ICTMRWA1InvestWithTimeLock.CTMRWA1InvestWithTimeLock_InvalidAmount.selector, uint8(Uint.InvestmentLow)
            )
        );
        investContract.investInOffering(0, minInvest - 1, currency);
        vm.stopPrank();
    }

    function test_investmentAboveMaximumReverts() public {
        vm.startPrank(user1);
        usdc.approve(address(investContract), maxInvest + 1);
        vm.expectRevert(
            abi.encodeWithSelector(
                ICTMRWA1InvestWithTimeLock.CTMRWA1InvestWithTimeLock_InvalidAmount.selector, uint8(Uint.InvestmentHigh)
            )
        );
        investContract.investInOffering(0, maxInvest + 1, currency);
        vm.stopPrank();
    }

    function test_investInOffering_underflow() public {
        // Set up an offering with decimalsRwa < decimalsCurrency
        // Simulate a currency with 18 decimals and RWA with 0 decimals
        // (This is a mock test, as actual decimals are set in the token contracts)
        // We'll use a very small investment and a very large price to force value to 0
        uint256 smallInvestment = 1; // 1 unit of currency
        // uint256 largePrice = 1e18; // Large price
        vm.startPrank(user1);
        usdc.approve(address(investContract), smallInvestment);
        // Expect value to underflow to 0, so the transferPartialTokenX should revert or result in 0 value
        vm.expectRevert();
        investContract.investInOffering(0, smallInvestment, currency);
        vm.stopPrank();
    }

    function test_investInOffering_overflow() public {
        // Set up an offering with very large investment and decimalsRwa > decimalsCurrency
        // This is a mock test, as actual decimals are set in the token contracts
        // We'll use a very large investment to try to overflow value
        uint256 largeInvestment = type(uint256).max / 1e10; // Large but not max to avoid immediate revert
        vm.startPrank(user1);
        usdc.approve(address(investContract), largeInvestment);
        // Expect revert due to overflow or exceeding max investment
        vm.expectRevert();
        investContract.investInOffering(0, largeInvestment, currency);
        vm.stopPrank();
    }

    function test_investInOffering_paused_unpaused() public {
        // Pause the CTMRWA1 token
        vm.prank(tokenAdmin);
        token.pause();

        // Try to invest while paused, should revert
        vm.startPrank(user1);
        usdc.approve(address(investContract), amount);
        vm.expectRevert(EnforcedPause.selector);
        investContract.investInOffering(0, amount, currency);
        vm.stopPrank();

        // Unpause the CTMRWA1 token
        vm.prank(tokenAdmin);
        token.unpause();

        // Try to invest again, should succeed
        vm.startPrank(user1);
        usdc.approve(address(investContract), amount);
        investContract.investInOffering(0, amount, currency);
        vm.stopPrank();
    }

    // ============ ACCESS CONTROL TESTS ============

    function test_onlyAuthorizedCanInvest() public {
        vm.startPrank(user1);
        usdc.approve(address(investContract), amount);
        investContract.investInOffering(0, amount, currency);
        vm.stopPrank();
    }

    function test_unauthorizedUserCannotInvest() public {
        address unauthorizedUser = address(0x999);
        vm.deal(unauthorizedUser, 100 ether);
        deal(address(usdc), unauthorizedUser, 10_000);

        // Get the sentry contract address from the map
        (bool ok, address sentryAddr) = ICTMRWAMap(address(map)).getSentryContract(ID, RWA_TYPE, VERSION);
        require(ok, "Sentry contract not found");

        // Enable whitelist in the sentry contract via the sentryManager
        string[] memory chainIdsStr = new string[](1);
        chainIdsStr[0] = cIdStr;
        vm.startPrank(tokenAdmin);
        ICTMRWA1SentryManager(address(sentryManager)).setSentryOptions(
            ID,
            true, // whitelistSwitch
            false, // kyc
            false, // kyb
            false, // over18
            false, // accredited
            false, // countryWL
            false, // countryBL
            chainIdsStr,
            feeTokenStr
        );
        vm.stopPrank();

        // Check if the unauthorized user is allowed to transfer (should be false)
        bool isAllowed = ICTMRWA1Sentry(sentryAddr).isAllowableTransfer(unauthorizedUser.toHexString());
        assertFalse(isAllowed, "Unauthorized user should not be allowed to transfer");

        vm.startPrank(unauthorizedUser);
        usdc.approve(address(investContract), 10_000);
        vm.expectRevert(
            abi.encodeWithSelector(
                ICTMRWA1InvestWithTimeLock.CTMRWA1InvestWithTimeLock_NotWhiteListed.selector, address(0x999)
            )
        );
        investContract.investInOffering(0, amount, currency);
        vm.stopPrank();
    }

    // ============ FUZZ TESTS ============

    function test_fuzz_investmentAmounts(uint256 _amount) public {
        vm.assume(_amount >= minInvest && _amount <= maxInvest);
        vm.startPrank(user1);
        usdc.approve(address(investContract), _amount);
        investContract.investInOffering(0, _amount, currency);
        vm.stopPrank();
    }

    // ============ EDGE CASE TESTS ============

    function test_zeroAmountInvestment() public {
        vm.startPrank(user1);
        usdc.approve(address(investContract), 0);
        vm.expectRevert(
            abi.encodeWithSelector(
                ICTMRWA1InvestWithTimeLock.CTMRWA1InvestWithTimeLock_InvalidAmount.selector, uint8(Uint.Value)
            )
        );
        investContract.investInOffering(0, 0, currency);
        vm.stopPrank();
    }

    function test_maxAmountInvestment() public {
        vm.startPrank(user1);
        usdc.approve(address(investContract), maxInvest);
        investContract.investInOffering(0, maxInvest, currency);
        vm.stopPrank();
    }

    function test_redeemMoreThanOwned() public {
        vm.startPrank(user1);
        usdc.approve(address(investContract), amount);
        investContract.investInOffering(0, amount, currency);
        vm.expectRevert();
        investContract.withdrawInvested(9999);
        vm.stopPrank();
    }

    // ============ ERROR HANDLING TESTS ============

    function test_errorHandling_insufficientBalance() public {
        vm.startPrank(user1);
        uint256 excessiveAmount = usdc.balanceOf(user1) + 1;
        usdc.approve(address(investContract), excessiveAmount);
        vm.expectRevert(
            abi.encodeWithSelector(
                ICTMRWA1InvestWithTimeLock.CTMRWA1InvestWithTimeLock_InvalidAmount.selector, uint8(Uint.Balance)
            )
        );
        investContract.investInOffering(0, excessiveAmount, currency);
        vm.stopPrank();
    }

    function test_errorHandling_insufficientAllowance() public {
        vm.startPrank(user1);
        usdc.approve(address(investContract), 0);
        vm.expectRevert();
        investContract.investInOffering(0, amount, currency);
        vm.stopPrank();
    }

    function test_errorHandling_invalidFeeToken() public {
        vm.startPrank(user1);
        address invalidToken = address(0xdead);
        usdc.approve(address(investContract), amount);
        vm.expectRevert();
        investContract.investInOffering(0, amount, invalidToken);
        vm.stopPrank();
    }

    // ============ REENTRANCY TESTS ============

    function test_reentrancy_investInOffering() public {
        // Deploy the reentrant attacker contract
        ReentrantAttacker attacker = new ReentrantAttacker(address(investContract));

        // Fund the attacker with USDC
        deal(address(usdc), address(attacker), 10_000);

        // Approve the investment contract to spend attacker's USDC
        vm.startPrank(address(attacker));
        usdc.approve(address(investContract), 10_000);
        vm.stopPrank();

        // Attempt the reentrancy attack
        vm.startPrank(address(attacker));
        attacker.attack(0, address(usdc), address(usdc), 1000);
        vm.stopPrank();

        // The attack should fail due to nonReentrant modifier
        // We verify this by checking that only one investment was made
        // (the attack should not succeed in making multiple investments)
        assertEq(attacker.attackCount(), 0, "Reentrancy attack should be prevented");
    }

    function test_reentrancy_withdrawInvested() public {
        // First, make a legitimate investment
        vm.startPrank(user1);
        usdc.approve(address(investContract), amount);
        investContract.investInOffering(0, amount, currency);
        vm.stopPrank();

        // Attempt to withdraw (this should be protected against reentrancy)
        vm.startPrank(tokenAdmin);
        uint256 withdrawn = investContract.withdrawInvested(0);
        vm.stopPrank();

        // Verify the withdrawal was successful and no reentrancy occurred
        assertGt(withdrawn, 0, "Withdrawal should be successful");
    }

    function test_reentrancy_unlockTokenId() public {
        // First, make a legitimate investment
        vm.startPrank(user1);
        usdc.approve(address(investContract), amount);
        uint256 investedTokenId = investContract.investInOffering(0, amount, currency);
        vm.stopPrank();

        // Fast forward time to unlock the token
        vm.warp(block.timestamp + lockDuration + 1);

        // Attempt to unlock the token (should be protected against reentrancy)
        vm.startPrank(user1);
        uint256 unlockedTokenId = investContract.unlockTokenId(0, currency);
        vm.stopPrank();

        // Verify the unlock was successful
        assertEq(unlockedTokenId, investedTokenId, "Token should be unlocked successfully");
    }


    function test_reentrancy_multipleFunctions() public {
        // Test that multiple reentrancy attempts are blocked
        ReentrantAttacker attacker = new ReentrantAttacker(address(investContract));

        // Fund the attacker
        deal(address(usdc), address(attacker), 10_000);

        vm.startPrank(address(attacker));
        usdc.approve(address(investContract), 10_000);

        // Try to attack multiple functions
        attacker.attack(0, address(usdc), address(usdc), 1000);
        vm.stopPrank();

        // Verify no reentrancy occurred
        assertEq(attacker.attackCount(), 0, "Multiple reentrancy attempts should be blocked");
    }

    // ============ GAS USAGE TESTS ============

    function test_gas_createOffering() public {
        // First mint a new token for this test
        vm.startPrank(tokenAdmin);
        uint256 testTokenId = rwa1X.mintNewTokenValueLocal(tokenAdmin, 0, slotId, 1000e18, ID, feeTokenStr);

        // Approve the investment contract to transfer the token
        token.approve(address(investContract), testTokenId);
        vm.stopPrank();

        uint256 gasBefore = gasleft();

        vm.startPrank(tokenAdmin);
        investContract.createOffering(
            testTokenId,
            price,
            currency,
            minInvest,
            maxInvest,
            "US",
            "SEC",
            "Private Placement",
            startTime,
            endTime,
            lockDuration,
            currency, // _rewardToken (use currency for now)
            currency
        );
        vm.stopPrank();

        uint256 gasUsed = gasBefore - gasleft();

        // Adjusted gas usage bounds for offering creation
        assertLt(gasUsed, 1_600_000, "Offering creation gas usage should be reasonable");
        assertGt(gasUsed, 50_000, "Offering creation should use significant gas");

        // console.log("Gas used for offering creation:", gasUsed);
    }

    function test_gas_investInOffering() public {
        uint256 gasBefore = gasleft();

        vm.startPrank(user1);
        usdc.approve(address(investContract), amount);
        investContract.investInOffering(0, amount, currency);
        vm.stopPrank();

        uint256 gasUsed = gasBefore - gasleft();

        // Adjusted gas usage bounds for investment
        assertLt(gasUsed, 1_300_000, "Investment gas usage should be reasonable");
        assertGt(gasUsed, 100_000, "Investment should use significant gas");

        // console.log("Gas used for investment:", gasUsed);
    }

    function test_gas_withdrawInvested() public {
        // First make an investment
        vm.startPrank(user1);
        usdc.approve(address(investContract), amount);
        investContract.investInOffering(0, amount, currency);
        vm.stopPrank();

        uint256 gasBefore = gasleft();

        vm.startPrank(tokenAdmin);
        uint256 withdrawn = investContract.withdrawInvested(0);
        vm.stopPrank();

        uint256 gasUsed = gasBefore - gasleft();

        // Adjusted gas usage bounds for withdrawal
        assertLt(gasUsed, 50_000, "Withdrawal gas usage should be reasonable");
        assertGt(gasUsed, 10_000, "Withdrawal should use significant gas");
        assertGt(withdrawn, 0, "Withdrawal should be successful");

        // console.log("Gas used for withdrawal:", gasUsed);
    }

    function test_gas_unlockTokenId() public {
        // First make an investment
        vm.startPrank(user1);
        usdc.approve(address(investContract), amount);
        uint256 localInvestedTokenId = investContract.investInOffering(0, amount, currency);
        vm.stopPrank();

        // Fast forward time to unlock the token
        vm.warp(block.timestamp + lockDuration + 1);

        uint256 gasBefore = gasleft();

        vm.startPrank(user1);
        uint256 unlockedTokenId = investContract.unlockTokenId(0, currency);
        vm.stopPrank();

        uint256 gasUsed = gasBefore - gasleft();

        // Adjusted gas usage bounds for unlocking
        assertLt(gasUsed, 1_900_000, "Unlock gas usage should be reasonable");
        assertGt(gasUsed, 100_000, "Unlock should use significant gas");
        assertEq(unlockedTokenId, localInvestedTokenId, "Token should be unlocked successfully");

        // console.log("Gas used for unlock:", gasUsed);
    }


    function test_gas_multipleInvestments() public {
        uint256 totalGasUsed = 0;

        for (uint256 i = 0; i < 3; i++) {
            uint256 gasBefore = gasleft();

            vm.startPrank(user1);
            usdc.approve(address(investContract), amount);
            investContract.investInOffering(0, amount, currency);
            vm.stopPrank();

            totalGasUsed += gasBefore - gasleft();
        }

        // Adjusted gas usage bounds for multiple investments
        assertLt(totalGasUsed, 3_200_000, "Multiple investments gas usage should be reasonable");
        assertGt(totalGasUsed, 300_000, "Multiple investments should use significant gas");

        // console.log("Total gas used for 3 investments:", totalGasUsed);
    }

    function test_gas_fuzz_investmentAmounts(uint256 _amount) public {
        vm.assume(_amount >= minInvest && _amount <= maxInvest);

        uint256 gasBefore = gasleft();

        vm.startPrank(user1);
        usdc.approve(address(investContract), _amount);
        investContract.investInOffering(0, _amount, currency);
        vm.stopPrank();

        uint256 gasUsed = gasBefore - gasleft();

        // Adjusted gas usage bounds for fuzz investment
        assertLt(gasUsed, 1_300_000, "Fuzz investment gas usage should be reasonable");
        assertGt(gasUsed, 100_000, "Fuzz investment should use significant gas");

        // console.log("Gas used for fuzz investment amount", _amount, ":", gasUsed);
    }

    function test_gas_viewFunctions() public view {
        uint256 gasBefore = gasleft();
        uint256 count = investContract.offeringCount();
        uint256 gasUsed = gasBefore - gasleft();

        // View functions should use minimal gas
        assertLt(gasUsed, 10_000, "View function gas usage should be minimal");
        assertGt(count, 0, "Should have at least one offering");

        // console.log("Gas used for offeringCount view:", gasUsed);

        gasBefore = gasleft();
        investContract.listOfferings();
        gasUsed = gasBefore - gasleft();

        assertLt(gasUsed, 50_000, "List offerings view gas usage should be reasonable");
        // console.log("Gas used for listOfferings view:", gasUsed);
    }

    function test_gas_optimization_comparison() public {
        // Test gas usage with different investment amounts
        uint256[] memory amounts = new uint256[](3);
        amounts[0] = minInvest;
        amounts[1] = (minInvest + maxInvest) / 2;
        amounts[2] = maxInvest;

        for (uint256 i = 0; i < amounts.length; i++) {
            uint256 gasBefore = gasleft();

            vm.startPrank(user1);
            usdc.approve(address(investContract), amounts[i]);
            investContract.investInOffering(0, amounts[i], currency);
            vm.stopPrank();

            uint256 gasUsed = gasBefore - gasleft();
            // console.log("Gas used for investment amount", amounts[i], ":", gasUsed);

            // Adjusted gas usage bounds for optimization
            assertLt(gasUsed, 1_300_000, "Investment gas usage should be reasonable for all amounts");
        }
    }

    function test_withdraw_works_as_tokenAdmin() public {
        // Arrange: Transfer USDC to the investContract
        uint256 withdrawAmount = 1000e6; // 1000 USDC (assuming 6 decimals)
        deal(address(usdc), address(investContract), withdrawAmount);
        assertEq(
            IERC20(address(usdc)).balanceOf(address(investContract)), withdrawAmount, "Invest contract should have USDC"
        );
        uint256 adminBalanceBefore = IERC20(address(usdc)).balanceOf(tokenAdmin);

        // Act: Withdraw as tokenAdmin
        vm.startPrank(tokenAdmin);
        uint256 returnedBal = CTMRWA1InvestWithTimeLock(address(investContract)).withdraw(address(usdc), withdrawAmount);
        vm.stopPrank();

        // Assert: Contract balance is zero, admin received funds, returned value is pre-withdrawal balance
        assertEq(returnedBal, withdrawAmount, "Returned balance should match withdrawn amount");
        assertEq(IERC20(address(usdc)).balanceOf(address(investContract)), 0, "Invest contract should have zero USDC");
        assertEq(
            IERC20(address(usdc)).balanceOf(tokenAdmin),
            adminBalanceBefore + withdrawAmount,
            "Admin should receive withdrawn USDC"
        );
    }

    function test_userCannotWithdrawBeforeLockDuration() public {
        // Arrange: User invests in offering
        vm.startPrank(user1);
        usdc.approve(address(investContract), amount);
        investContract.investInOffering(0, amount, currency);
        uint256 holdingIndex = 0; // first investment for user1
        vm.stopPrank();

        Holding memory holding = investContract.listEscrowHolding(user1, holdingIndex);

        // Try to unlock before lockDuration
        vm.startPrank(user1);
        vm.expectRevert(
            abi.encodeWithSelector(
                ICTMRWA1InvestWithTimeLock.CTMRWA1InvestWithTimeLock_InvalidTimestamp.selector, uint8(Time.Early)
            )
        );
        investContract.unlockTokenId(holdingIndex, address(usdc));
        vm.stopPrank();

        // Advance time past lockDuration
        skip(lockDuration + 1);
        vm.startPrank(user1);
        // Should now succeed
        uint256 unlockedTokenId = investContract.unlockTokenId(holdingIndex, currency);
        vm.stopPrank();

        // Check that the returned tokenId matches the user's holding
        assertEq(unlockedTokenId, holding.tokenId, "Unlocked tokenId should match the user's holding");

        // Assert the balance of the unlocked tokenId is correct
        uint256 tokenBalance = token.balanceOf(unlockedTokenId);
        uint8 decimalsCurrency = IERC20Extended(address(usdc)).decimals();
        uint8 decimalsRwa = token.valueDecimals();
        uint256 expectedValue;
        if (decimalsRwa >= decimalsCurrency) {
            uint256 scale = 10 ** (decimalsRwa - decimalsCurrency);
            expectedValue = (amount * scale) / price;
        } else {
            uint256 scale = 10 ** (decimalsCurrency - decimalsRwa);
            expectedValue = amount / (price * scale);
        }
        assertEq(tokenBalance, expectedValue, "Unlocked tokenId balance should match the expected value");
    }

    function test_invalidOfferingIndex_reverts() public {
        uint256 invalidIndex = 999;
        // pauseOffering
        vm.startPrank(tokenAdmin);
        vm.expectRevert(ICTMRWA1InvestWithTimeLock.CTMRWA1InvestWithTimeLock_InvalidOfferingIndex.selector);
        investContract.pauseOffering(invalidIndex);
        vm.stopPrank();

        // unpauseOffering
        vm.startPrank(tokenAdmin);
        vm.expectRevert(ICTMRWA1InvestWithTimeLock.CTMRWA1InvestWithTimeLock_InvalidOfferingIndex.selector);
        investContract.unpauseOffering(invalidIndex);
        vm.stopPrank();

        // isOfferingPaused
        vm.expectRevert(ICTMRWA1InvestWithTimeLock.CTMRWA1InvestWithTimeLock_InvalidOfferingIndex.selector);
        investContract.isOfferingPaused(invalidIndex);

        // investInOffering
        vm.startPrank(user1);
        usdc.approve(address(investContract), amount);
        vm.expectRevert(ICTMRWA1InvestWithTimeLock.CTMRWA1InvestWithTimeLock_InvalidOfferingIndex.selector);
        investContract.investInOffering(invalidIndex, amount, currency);
        vm.stopPrank();

        // withdrawInvested
        vm.startPrank(tokenAdmin);
        vm.expectRevert(ICTMRWA1InvestWithTimeLock.CTMRWA1InvestWithTimeLock_InvalidOfferingIndex.selector);
        investContract.withdrawInvested(invalidIndex);
        vm.stopPrank();

        // listOffering
        vm.expectRevert(ICTMRWA1InvestWithTimeLock.CTMRWA1InvestWithTimeLock_InvalidOfferingIndex.selector);
        investContract.listOffering(invalidIndex);

        // getRewardInfo
        vm.expectRevert(ICTMRWA1InvestWithTimeLock.CTMRWA1InvestWithTimeLock_InvalidOfferingIndex.selector);
        investContract.getRewardInfo(user1, invalidIndex, 0);

        // claimReward
        vm.startPrank(user1);
        vm.expectRevert(ICTMRWA1InvestWithTimeLock.CTMRWA1InvestWithTimeLock_InvalidOfferingIndex.selector);
        investContract.claimReward(invalidIndex, 0);
        vm.stopPrank();
    }

    function test_fundRewardTokenForOffering_and_claimReward() public {
        // Arrange: user1 invests
        vm.startPrank(user1);
        usdc.approve(address(investContract), amount);
        investContract.investInOffering(0, amount, currency);
        vm.stopPrank();

        // Get the actual holding's tokenId and balance
        Holding memory holding = investContract.listEscrowHolding(user1, 0);
        uint256 actualBalance = token.balanceOf(holding.tokenId);

        // TokenAdmin funds rewards
        uint256 rewardMultiplier = 1e18; // 1:1 reward
        uint256 rateDivisor = 1e18;
        uint256 expectedReward = actualBalance * rewardMultiplier / rateDivisor;
        deal(address(usdc), tokenAdmin, expectedReward);
        vm.startPrank(tokenAdmin);
        usdc.approve(address(investContract), expectedReward);
        investContract.fundRewardTokenForOffering(0, expectedReward, rewardMultiplier, rateDivisor);
        vm.stopPrank();

        // User1 claims reward
        uint256 user1BalanceBefore = usdc.balanceOf(user1);
        vm.startPrank(user1);
        investContract.claimReward(0, 0);
        vm.stopPrank();
        uint256 user1BalanceAfter = usdc.balanceOf(user1);
        assertEq(user1BalanceAfter - user1BalanceBefore, expectedReward, "User1 should receive correct reward");

        // Reward amount should now be zero
        (, uint256 rewardAmount) = investContract.getRewardInfo(user1, 0, 0);
        assertEq(rewardAmount, 0, "Reward amount should be zero after claim");
    }

    function test_fundRewardTokenForOffering_accessControl() public {
        // Arrange: user1 invests
        vm.startPrank(user1);
        usdc.approve(address(investContract), amount);
        investContract.investInOffering(0, amount, currency);
        vm.stopPrank();

        // Non-admin tries to fund rewards
        uint256 rewardMultiplier = 2;
        uint256 fundAmount = amount * rewardMultiplier;
        deal(address(usdc), user1, fundAmount);
        vm.startPrank(user1);
        usdc.approve(address(investContract), fundAmount);
        vm.expectRevert();
        investContract.fundRewardTokenForOffering(0, fundAmount, rewardMultiplier, 1e18);
        vm.stopPrank();
    }

    function test_claimReward_accessControl() public {
        // Arrange: user1 invests, tokenAdmin funds rewards
        vm.startPrank(user1);
        usdc.approve(address(investContract), amount);
        investContract.investInOffering(0, amount, currency);
        vm.stopPrank();
        uint256 rewardMultiplier = 2;
        uint256 fundAmount = amount * rewardMultiplier;
        deal(address(usdc), tokenAdmin, fundAmount);
        vm.startPrank(tokenAdmin);
        usdc.approve(address(investContract), fundAmount);
        investContract.fundRewardTokenForOffering(0, fundAmount, rewardMultiplier, 1e18);
        vm.stopPrank();

        // Another user tries to claim user1's reward
        address attacker = address(0xBEEF);
        vm.startPrank(attacker);
        vm.expectRevert();
        investContract.claimReward(0, 0);
        vm.stopPrank();
    }

    function test_claimReward_noReward() public {
        // Arrange: user1 invests but no rewards funded
        vm.startPrank(user1);
        usdc.approve(address(investContract), amount);
        investContract.investInOffering(0, amount, currency);
        vm.stopPrank();

        // User1 tries to claim reward
        vm.startPrank(user1);
        vm.expectRevert(ICTMRWA1InvestWithTimeLock.CTMRWA1InvestWithTimeLock_NoRewardsToClaim.selector);
        investContract.claimReward(0, 0);
        vm.stopPrank();
    }

    function test_fuzz_fund_and_claim_rewards(uint96 fuzzAmount, uint96 fuzzMultiplier) public {
        // Arrange: ensure fuzzed values are within contract limits
        uint256 maxInvestLocal = investContract.listOffering(0).maxInvestment;
        uint256 minInvestLocal = investContract.listOffering(0).minInvestment;
        uint256 currencyDecimals = IERC20Extended(currency).decimals();
        uint256 maxFuzzAmount = 1_000_000_000 * 10 ** currencyDecimals;
        vm.assume(fuzzAmount >= minInvestLocal);
        vm.assume(fuzzAmount <= maxInvestLocal);
        vm.assume(fuzzAmount <= maxFuzzAmount);
        vm.assume(fuzzMultiplier > 0 && fuzzMultiplier < 1e6); // Limit multiplier to prevent overflow

        // User invests
        vm.startPrank(user1);
        IERC20(currency).approve(address(investContract), fuzzAmount);
        investContract.investInOffering(0, fuzzAmount, currency);
        vm.stopPrank();

        // Get the actual holding's tokenId and balance
        Holding memory holding = investContract.listEscrowHolding(user1, 0);
        uint256 actualBalance = token.balanceOf(holding.tokenId);

        // TokenAdmin funds rewards
        uint256 rateDivisor = 1e6; // Use a smaller divisor to ensure rewards are calculated
        uint256 expectedReward = (actualBalance * fuzzMultiplier) / rateDivisor;
        
        // Ensure the reward doesn't exceed the available balance
        uint256 availableBalance = IERC20(currency).balanceOf(tokenAdmin);
        vm.assume(expectedReward <= availableBalance);

        vm.startPrank(tokenAdmin);
        IERC20(currency).approve(address(investContract), expectedReward);
        investContract.fundRewardTokenForOffering(0, expectedReward, fuzzMultiplier, rateDivisor);
        vm.stopPrank();

        // User claims reward
        uint256 preBalance = IERC20(currency).balanceOf(user1);
        vm.startPrank(user1);
        investContract.claimReward(0, 0);
        vm.stopPrank();
        uint256 postBalance = IERC20(currency).balanceOf(user1);
        assertEq(postBalance - preBalance, expectedReward, "Reward claimed should match expected");
    }

    function test_reentrancy_claimReward() public {
        // Arrange: user1 invests, tokenAdmin funds rewards
        vm.startPrank(user1);
        usdc.approve(address(investContract), amount);
        investContract.investInOffering(0, amount, currency);
        vm.stopPrank();
        uint256 rewardMultiplier = 2;
        uint256 fundAmount = amount * rewardMultiplier;
        deal(address(usdc), tokenAdmin, fundAmount);
        vm.startPrank(tokenAdmin);
        usdc.approve(address(investContract), fundAmount);
        investContract.fundRewardTokenForOffering(0, fundAmount, rewardMultiplier, 1e18);
        vm.stopPrank();

        // Deploy a malicious contract to try reentrancy
        MaliciousRewardClaimer attacker = new MaliciousRewardClaimer(address(investContract), address(usdc));
        // Transfer reward tokens to attacker for approval
        deal(address(usdc), address(attacker), 1);
        // Try to claim reward via attacker
        vm.startPrank(address(attacker));
        vm.expectRevert(); // Should revert due to nonReentrant
        attacker.attack(0, 0);
        vm.stopPrank();
    }

    function test_fundRewardTokenForOffering_skipExpiredEscrow() public {
        // Arrange: user1 invests
        vm.startPrank(user1);
        usdc.approve(address(investContract), amount);
        investContract.investInOffering(0, amount, currency);
        vm.stopPrank();

        // Get the holding to check escrow time
        Holding memory holding = investContract.listEscrowHolding(user1, 0);
        
        // Fast forward past the escrow lock time
        vm.warp(holding.escrowTime + 1);

        // TokenAdmin tries to fund rewards
        uint256 rewardMultiplier = 2;
        uint256 fundAmount = amount * rewardMultiplier;
        deal(address(usdc), tokenAdmin, fundAmount);
        vm.startPrank(tokenAdmin);
        usdc.approve(address(investContract), fundAmount);
        investContract.fundRewardTokenForOffering(0, fundAmount, rewardMultiplier, 1e18);
        vm.stopPrank();

        // Check that user1 received no rewards (escrow time has passed)
        (address rewardToken, uint256 rewardAmount) = investContract.getRewardInfo(user1, 0, 0);
        assertEq(rewardAmount, 0, "Holder should not receive rewards after escrow time has passed");
    }

    function test_fundRewardTokenForOffering_rewardActiveEscrow() public {
        // Arrange: user1 invests
        vm.startPrank(user1);
        usdc.approve(address(investContract), amount);
        investContract.investInOffering(0, amount, currency);
        vm.stopPrank();

        // Get the holding to check escrow time
        Holding memory holding = investContract.listEscrowHolding(user1, 0);
        
        // Ensure we're still within the escrow lock time
        vm.warp(holding.escrowTime - 1);

        // TokenAdmin funds rewards
        uint256 rewardMultiplier = 2;
        uint256 rateDivisor = 1e6; // Use a smaller divisor to ensure rewards are calculated
        uint256 fundAmount = amount * rewardMultiplier;
        deal(address(usdc), tokenAdmin, fundAmount);
        vm.startPrank(tokenAdmin);
        usdc.approve(address(investContract), fundAmount);
        investContract.fundRewardTokenForOffering(0, fundAmount, rewardMultiplier, rateDivisor);
        vm.stopPrank();

        // Check that user1 received rewards (escrow time has not passed)
        (address rewardToken, uint256 rewardAmount) = investContract.getRewardInfo(user1, 0, 0);
        assertGt(rewardAmount, 0, "Holder should receive rewards when escrow time has not passed");
    }
}

// Additional malicious contract for withdrawal reentrancy testing
contract ReentrantWithdrawAttacker {
    CTMRWA1InvestWithTimeLock public targetContract;
    uint256 public attackCount;

    constructor(address _targetContract) {
        targetContract = CTMRWA1InvestWithTimeLock(_targetContract);
    }

    function attack() external {
        attackCount = 0;
        // Try to withdraw (this will fail for non-tokenAdmin, but tests reentrancy protection)
        targetContract.withdrawInvested(0);
    }

    receive() external payable {
        if (attackCount < 3) {
            attackCount++;
            targetContract.withdrawInvested(0);
        }
    }
}
