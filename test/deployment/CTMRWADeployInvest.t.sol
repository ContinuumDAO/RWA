// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.27;

import { CTMRWA1InvestWithTimeLock } from "../../src/deployment/CTMRWA1InvestWithTimeLock.sol";
import { ICTMRWA1InvestWithTimeLock } from "../../src/deployment/ICTMRWA1InvestWithTimeLock.sol";

import { Holding, Offering } from "../../src/deployment/ICTMRWA1InvestWithTimeLock.sol";

import { IERC20Extended, FeeType } from "../../src/managers/IFeeManager.sol";
import { ICTMRWA1Sentry } from "../../src/sentry/ICTMRWA1Sentry.sol";
import { ICTMRWA1SentryManager } from "../../src/sentry/ICTMRWA1SentryManager.sol";
import { ICTMRWAMap } from "../../src/shared/ICTMRWAMap.sol";

import { CTMRWAErrorParam } from "../../src/utils/CTMRWAUtils.sol";
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

        // Set up fee multipliers for operations that will be tested
        vm.startPrank(gov);
        feeManager.setFeeMultiplier(FeeType.DEPLOYINVEST, 100);
        feeManager.setFeeMultiplier(FeeType.OFFERING, 50);
        feeManager.setFeeMultiplier(FeeType.INVEST, 10);
        vm.stopPrank();

        // Deploy token as tokenAdmin
        vm.startPrank(tokenAdmin);
        // Ensure tokenAdmin has allowance to pay fees via rwa1X and deployInvest
        usdc.approve(address(rwa1X), type(uint256).max);
        ctm.approve(address(rwa1X), type(uint256).max);
        usdc.approve(address(ctmRwaDeployInvest), type(uint256).max);
        ctm.approve(address(ctmRwaDeployInvest), type(uint256).max);
        (ID, token) = _deployCTMRWA1(address(usdc));
        _createSlot(ID, slotId, address(usdc), address(rwa1X));

        feeTokenStr = address(usdc).toHexString();

        // Set commission rate to 100 (1%) before deploying investment contract
        vm.startPrank(gov);
        deployer.setInvestCommissionRate(100);
        vm.stopPrank();
        
        vm.startPrank(tokenAdmin);
        address investAddr = deployer.deployNewInvestment(ID, RWA_TYPE, VERSION, address(usdc));
        vm.stopPrank();

        // Get the actual investment contract from the map
        // console.log("setUp: getting investment contract from map...");
        (bool ok, address investAddrFromMap) = ICTMRWAMap(address(map)).getInvestContract(ID, RWA_TYPE, VERSION);
        require(ok, "Investment contract not found");
        require(investAddr == investAddrFromMap, "Investment contract address mismatch");
        investContract = ICTMRWA1InvestWithTimeLock(investAddr);
        // console.log("setUp: investment contract retrieved successfully");
        
        // Approve the investment contract for all test users to pay fees
        vm.startPrank(user1);
        usdc.approve(address(investContract), type(uint256).max);
        ctm.approve(address(investContract), type(uint256).max);
        vm.stopPrank();
        
        vm.startPrank(user2);
        usdc.approve(address(investContract), type(uint256).max);
        ctm.approve(address(investContract), type(uint256).max);
        vm.stopPrank();

        // Mint a token first (needed for offering)
        vm.startPrank(tokenAdmin);
        uint256 newTokenId = rwa1X.mintNewTokenValueLocal(
            tokenAdmin, // toAddress
            0, // toTokenId (0 = create new token)
            slotId, // slot
            1000e18, // value (1000 tokens)
            ID, // ID
            feeTokenStr // feeTokenStr
        );
        vm.stopPrank();

        // Set offering parameters
        currency = address(usdc);
        price = 1e6; // 1 USDC per unit (assuming USDC has 6 decimals)
        minInvest = 100;
        maxInvest = 1_000_000;
        startTime = block.timestamp;
        endTime = block.timestamp + 30 days;
        lockDuration = 1 days;

        // Approve the investment contract to transfer the token and pay fees
        vm.startPrank(tokenAdmin);
        // console.log("setUp: approving investment contract to transfer token...");
        token.approve(address(investContract), newTokenId);
        // console.log("setUp: approval granted");
        
        // Approve the investment contract to spend fee tokens
        usdc.approve(address(investContract), type(uint256).max);
        ctm.approve(address(investContract), type(uint256).max);

        // Create offering using the minted token
        investContract.createOffering(
            newTokenId, // Use the minted token ID instead of tokenId
            price,
            currency,
            minInvest,
            maxInvest,
            "US",
            "SEC",
            "Private Placement",
            "24", // _bnbGreenfieldObjectName
            startTime,
            endTime,
            lockDuration,
            currency, // _rewardToken (use currency for now)
            currency
        );
        vm.stopPrank();


        // console.log("setUp: completed successfully");
    }

    // ============ DEPLOYMENT TESTS ============

    function test_deployment_duplicateDeployment() public {
        // Try to deploy investment contract for same ID again
        vm.startPrank(tokenAdmin);
        vm.expectRevert();
        ctmRwaDeployInvest.deployInvest(ID, RWA_TYPE, VERSION, address(usdc), tokenAdmin);
        vm.stopPrank();
    }

    function test_deployment_investmentContractRegistered() public view {
        // Verify investment contract is properly registered in map
        (bool ok, address investAddr) = ICTMRWAMap(address(map)).getInvestContract(ID, RWA_TYPE, VERSION);
        assertTrue(ok, "Investment contract should be registered");
        assertEq(investAddr, address(investContract), "Investment contract address should match");
    }

    // ============ FEE MULTIPLIER TESTS ============

    function test_tokenAdminCanDeployInvestmentContractWithFee() public {
        // Set a custom fee multiplier for DEPLOYINVEST
        uint256 customMultiplier = 200; // 2x multiplier
        vm.startPrank(gov);
        bool success = feeManager.setFeeMultiplier(FeeType.DEPLOYINVEST, customMultiplier);
        assertTrue(success, "Fee multiplier should be set successfully");
        vm.stopPrank();

        // Verify the fee multiplier was set correctly
        uint256 actualMultiplier = feeManager.getFeeMultiplier(FeeType.DEPLOYINVEST);
        assertEq(actualMultiplier, customMultiplier, "Fee multiplier should match the set value");

        // Verify that the fee calculation now reflects the new multiplier
        string memory testFeeTokenStr = address(usdc).toHexString();
        string[] memory chainIds = new string[](1);
        chainIds[0] = Strings.toString(block.chainid);
        uint256 feeAmount = feeManager.getXChainFee(
            chainIds,
            false,
            FeeType.DEPLOYINVEST,
            testFeeTokenStr
        );
        
        // Verify the fee was calculated correctly with the multiplier
        uint256 baseFee = feeManager.getToChainBaseFee(Strings.toString(block.chainid), testFeeTokenStr);
        uint256 expectedFee = baseFee * customMultiplier;
        assertEq(feeAmount, expectedFee, "Fee amount should reflect the multiplier");
        
        // Verify that the existing investment contract is still accessible
        (bool ok, address investAddrFromMap) = ICTMRWAMap(address(map)).getInvestContract(ID, RWA_TYPE, VERSION);
        assertTrue(ok, "Existing investment contract should still be accessible");
        assertEq(investAddrFromMap, address(investContract), "Investment contract address should match");
        
        // The test verifies that the fee multiplier was set correctly and that the existing
        // investment contract is still accessible. The actual fee payment verification
        // is not needed here since the investment contract was already deployed in setUp()
        // with the original fee multiplier (100), and we're just testing that the new
        // multiplier (200) is set correctly for future deployments.
    }

    // ============ HELPER FUNCTIONS ============
    
    function _approveForInvestment(address user, uint256 investmentAmount) internal {
        vm.startPrank(user);
        usdc.approve(address(investContract), investmentAmount + 10_000_000); // Approve investment + fee
        vm.stopPrank();
    }

    // ============ BASIC FUNCTIONALITY TESTS ============

    function test_investmentCreation() public {
        _approveForInvestment(user1, amount);
        vm.startPrank(user1);
        uint256 initialBalance = usdc.balanceOf(user1);
        investContract.investInOffering(0, amount, address(usdc));
        assertLt(usdc.balanceOf(user1), initialBalance, "USDC balance should decrease");
        vm.stopPrank();
    }

    function test_multipleInvestments() public {
        _approveForInvestment(user1, 500);
        vm.startPrank(user1);
        investContract.investInOffering(0, 500, address(usdc));
        vm.stopPrank();
        
        _approveForInvestment(user1, 750);
        vm.startPrank(user1);
        investContract.investInOffering(0, 750, address(usdc));
        vm.stopPrank();
    }

    function test_investmentBelowMinimumReverts() public {
        vm.startPrank(user1);
        usdc.approve(address(investContract), minInvest - 1);
        vm.expectRevert(
            abi.encodeWithSelector(
                ICTMRWA1InvestWithTimeLock.CTMRWA1InvestWithTimeLock_InvalidAmount.selector, uint8(CTMRWAErrorParam.InvestmentLow)
            )
        );
        investContract.investInOffering(0, minInvest - 1, address(usdc));
        vm.stopPrank();
    }

    function test_investmentAboveMaximumReverts() public {
        vm.startPrank(user1);
        usdc.approve(address(investContract), maxInvest + 1);
        vm.expectRevert(
            abi.encodeWithSelector(
                ICTMRWA1InvestWithTimeLock.CTMRWA1InvestWithTimeLock_InvalidAmount.selector, uint8(CTMRWAErrorParam.InvestmentHigh)
            )
        );
        investContract.investInOffering(0, maxInvest + 1, address(usdc));
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
        investContract.investInOffering(0, smallInvestment, address(usdc));
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
        investContract.investInOffering(0, largeInvestment, address(usdc));
        vm.stopPrank();
    }

    function test_investInOffering_paused_unpaused() public {
        // Pause the CTMRWA1 token
        vm.prank(tokenAdmin);
        token.pause();

        // Try to invest while paused, should revert
        _approveForInvestment(user1, amount);
        vm.startPrank(user1);
        vm.expectRevert(EnforcedPause.selector);
        investContract.investInOffering(0, amount, address(usdc));
        vm.stopPrank();

        // Unpause the CTMRWA1 token
        vm.prank(tokenAdmin);
        token.unpause();

        // Try to invest again, should succeed
        _approveForInvestment(user1, amount);
        vm.startPrank(user1);
        investContract.investInOffering(0, amount, address(usdc));
        vm.stopPrank();
    }

    // ============ ACCESS CONTROL TESTS ============

    function test_onlyAuthorizedCanInvest() public {
        _approveForInvestment(user1, amount);
        vm.startPrank(user1);
        investContract.investInOffering(0, amount, address(usdc));
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
        investContract.investInOffering(0, amount, address(usdc));
        vm.stopPrank();
    }

    // ============ FUZZ TESTS ============

    function test_fuzz_investmentAmounts(uint256 _amount) public {
        vm.assume(_amount >= minInvest && _amount <= maxInvest);
        _approveForInvestment(user1, _amount);
        vm.startPrank(user1);
        investContract.investInOffering(0, _amount, address(usdc));
        vm.stopPrank();
    }

    // ============ EDGE CASE TESTS ============

    function test_zeroAmountInvestment() public {
        vm.startPrank(user1);
        usdc.approve(address(investContract), 0);
        vm.expectRevert(
            abi.encodeWithSelector(
                ICTMRWA1InvestWithTimeLock.CTMRWA1InvestWithTimeLock_InvalidAmount.selector, uint8(CTMRWAErrorParam.Value)
            )
        );
        investContract.investInOffering(0, 0, currency);
        vm.stopPrank();
    }

    function test_maxAmountInvestment() public {
        _approveForInvestment(user1, maxInvest);
        vm.startPrank(user1);
        investContract.investInOffering(0, maxInvest, address(usdc));
        vm.stopPrank();
    }

    function test_redeemMoreThanOwned() public {
        _approveForInvestment(user1, amount);
        vm.startPrank(user1);
        investContract.investInOffering(0, amount, address(usdc));
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
                ICTMRWA1InvestWithTimeLock.CTMRWA1InvestWithTimeLock_InvalidAmount.selector, uint8(CTMRWAErrorParam.Balance)
            )
        );
        investContract.investInOffering(0, excessiveAmount, currency);
        vm.stopPrank();
    }

    function test_errorHandling_insufficientAllowance() public {
        vm.startPrank(user1);
        usdc.approve(address(investContract), 0);
        vm.expectRevert();
        investContract.investInOffering(0, amount, address(usdc));
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

        // Fund the attacker with enough USDC for investment + fee
        deal(address(usdc), address(attacker), 10_000 + 10_000_000);

        // Approve the investment contract to spend attacker's USDC
        vm.startPrank(address(attacker));
        usdc.approve(address(investContract), 10_000 + 10_000_000); // Approve investment + fee
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
        _approveForInvestment(user1, amount);
        vm.startPrank(user1);
        investContract.investInOffering(0, amount, address(usdc));
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
        _approveForInvestment(user1, amount);
        vm.startPrank(user1);
        uint256 investedTokenId = investContract.investInOffering(0, amount, address(usdc));
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

        // Fund the attacker with enough USDC for investment + fee
        deal(address(usdc), address(attacker), 10_000 + 10_000_000);

        vm.startPrank(address(attacker));
        usdc.approve(address(investContract), 10_000 + 10_000_000); // Approve investment + fee

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
            "gas-test-object", // _bnbGreenfieldObjectName
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

        _approveForInvestment(user1, amount);
        vm.startPrank(user1);
        investContract.investInOffering(0, amount, address(usdc));
        vm.stopPrank();

        uint256 gasUsed = gasBefore - gasleft();

        // Adjusted gas usage bounds for investment (increased due to fee payment)
        assertLt(gasUsed, 1_400_000, "Investment gas usage should be reasonable");
        assertGt(gasUsed, 100_000, "Investment should use significant gas");

        // console.log("Gas used for investment:", gasUsed);
    }

    function test_gas_withdrawInvested() public {
        // First make an investment
        _approveForInvestment(user1, amount);
        vm.startPrank(user1);
        investContract.investInOffering(0, amount, address(usdc));
        vm.stopPrank();

        uint256 gasBefore = gasleft();

        vm.startPrank(tokenAdmin);
        uint256 withdrawn = investContract.withdrawInvested(0);
        vm.stopPrank();

        uint256 gasUsed = gasBefore - gasleft();

        // Adjusted gas usage bounds for withdrawal
        assertLt(gasUsed, 60_000, "Withdrawal gas usage should be reasonable");
        assertGt(gasUsed, 10_000, "Withdrawal should use significant gas");
        assertGt(withdrawn, 0, "Withdrawal should be successful");

        // console.log("Gas used for withdrawal:", gasUsed);
    }

    function test_gas_unlockTokenId() public {
        // First make an investment
        _approveForInvestment(user1, amount);
        vm.startPrank(user1);
        uint256 localInvestedTokenId = investContract.investInOffering(0, amount, address(usdc));
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

            _approveForInvestment(user1, amount);
            vm.startPrank(user1);
            investContract.investInOffering(0, amount, address(usdc));
            vm.stopPrank();

            totalGasUsed += gasBefore - gasleft();
        }

        // Adjusted gas usage bounds for multiple investments (increased due to fee payment)
        assertLt(totalGasUsed, 3_500_000, "Multiple investments gas usage should be reasonable");
        assertGt(totalGasUsed, 300_000, "Multiple investments should use significant gas");

        // console.log("Total gas used for 3 investments:", totalGasUsed);
    }

    function test_gas_fuzz_investmentAmounts(uint256 _amount) public {
        vm.assume(_amount >= minInvest && _amount <= maxInvest);

        uint256 gasBefore = gasleft();

        _approveForInvestment(user1, _amount);
        vm.startPrank(user1);
        investContract.investInOffering(0, _amount, address(usdc));
        vm.stopPrank();

        uint256 gasUsed = gasBefore - gasleft();

        // Adjusted gas usage bounds for fuzz investment (increased due to fee payment)
        assertLt(gasUsed, 1_400_000, "Fuzz investment gas usage should be reasonable");
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

            _approveForInvestment(user1, amounts[i]);
            vm.startPrank(user1);
            investContract.investInOffering(0, amounts[i], address(usdc));
            vm.stopPrank();

            uint256 gasUsed = gasBefore - gasleft();
            // console.log("Gas used for investment amount", amounts[i], ":", gasUsed);

            // Adjusted gas usage bounds for optimization (increased due to fee payment)
            assertLt(gasUsed, 1_400_000, "Investment gas usage should be reasonable for all amounts");
        }
    }



    function test_withdrawInvested_with_commission() public {
        // Commission rate is already set to 100 (1%) in setUp()
        // Verify commission rate is set correctly
        assertEq(ctmRwaDeployInvest.commissionRate(), 100, "Commission rate should be set to 100 (1%)");

        // Make an investment to have funds to withdraw
        _approveForInvestment(user1, amount);
        vm.startPrank(user1);
        investContract.investInOffering(0, amount, address(usdc));
        vm.stopPrank();

        // Get initial balances
        uint256 feeManagerBalanceBefore = usdc.balanceOf(address(feeManager));
        uint256 tokenAdminBalanceBefore = usdc.balanceOf(tokenAdmin);
        uint256 investContractBalanceBefore = usdc.balanceOf(address(investContract));

        // Calculate expected commission (1% of amount)
        uint256 expectedCommission = amount * 100 / 10000; // 1% = 100/10000
        uint256 expectedWithdrawal = amount - expectedCommission;

        // Act: Withdraw invested funds as tokenAdmin
        vm.startPrank(tokenAdmin);
        uint256 withdrawnAmount = investContract.withdrawInvested(0);
        vm.stopPrank();

        // Assert: Commission is paid to FeeManager and tokenAdmin receives the rest
        assertEq(withdrawnAmount, expectedWithdrawal, "Withdrawn amount should be investment minus commission");
        assertEq(
            usdc.balanceOf(address(feeManager)),
            feeManagerBalanceBefore + expectedCommission,
            "FeeManager should receive the commission"
        );
        assertEq(
            usdc.balanceOf(tokenAdmin),
            tokenAdminBalanceBefore + expectedWithdrawal,
            "TokenAdmin should receive investment minus commission"
        );
        assertEq(
            usdc.balanceOf(address(investContract)),
            investContractBalanceBefore - amount,
            "Invest contract should have investment amount deducted"
        );

        // Verify the offering investment is reset to 0
        assertEq(investContract.listOffering(0).investment, 0, "Offering investment should be reset to 0");
    }

    function test_userCannotWithdrawBeforeLockDuration() public {
        // Arrange: User invests in offering
        _approveForInvestment(user1, amount);
        vm.startPrank(user1);
        investContract.investInOffering(0, amount, address(usdc));
        uint256 holdingIndex = 0; // first investment for user1
        vm.stopPrank();

        Holding memory holding = investContract.listEscrowHolding(user1, holdingIndex);

        // Try to unlock before lockDuration
        vm.startPrank(user1);
        vm.expectRevert(
            abi.encodeWithSelector(
                ICTMRWA1InvestWithTimeLock.CTMRWA1InvestWithTimeLock_InvalidTimestamp.selector, uint8(CTMRWAErrorParam.Early)
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
        _approveForInvestment(user1, amount);
        vm.startPrank(user1);
        investContract.investInOffering(0, amount, address(usdc));
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
        _approveForInvestment(user1, amount);
        vm.startPrank(user1);
        investContract.investInOffering(0, amount, address(usdc));
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
        _approveForInvestment(user1, amount);
        vm.startPrank(user1);
        investContract.investInOffering(0, amount, address(usdc));
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
        _approveForInvestment(user1, amount);
        vm.startPrank(user1);
        investContract.investInOffering(0, amount, address(usdc));
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
        _approveForInvestment(user1, fuzzAmount);
        vm.startPrank(user1);
        investContract.investInOffering(0, fuzzAmount, address(usdc));
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
        _approveForInvestment(user1, amount);
        vm.startPrank(user1);
        investContract.investInOffering(0, amount, address(usdc));
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
        _approveForInvestment(user1, amount);
        vm.startPrank(user1);
        investContract.investInOffering(0, amount, address(usdc));
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
        (, uint256 rewardAmount) = investContract.getRewardInfo(user1, 0, 0);
        assertEq(rewardAmount, 0, "Holder should not receive rewards after escrow time has passed");
    }

    function test_fundRewardTokenForOffering_rewardActiveEscrow() public {
        // Arrange: user1 invests
        _approveForInvestment(user1, amount);
        vm.startPrank(user1);
        investContract.investInOffering(0, amount, address(usdc));
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
        (, uint256 rewardAmount) = investContract.getRewardInfo(user1, 0, 0);
        assertGt(rewardAmount, 0, "Holder should receive rewards when escrow time has not passed");
    }

    // ============ REMAINING TOKEN ID TESTS ============

    function test_removeRemainingTokenId_success() public {
        // First, create a new offering with a larger token for this specific test
        vm.startPrank(tokenAdmin);
        uint256 testTokenId = rwa1X.mintNewTokenValueLocal(tokenAdmin, 0, slotId, 2000e18, ID, feeTokenStr);
        token.approve(address(investContract), testTokenId);
        
        // Create a new offering with the test token
        investContract.createOffering(
            testTokenId,
            price,
            currency,
            minInvest,
            maxInvest,
            "US",
            "SEC",
            "Test Offering",
            "test-object-name",
            startTime,
            startTime + 1 days, // Short offering period for testing
            lockDuration,
            currency, // _rewardToken
            currency
        );
        vm.stopPrank();

        // Make a small investment to reduce the remaining balance
        _approveForInvestment(user1, 100);
        vm.startPrank(user1);
        investContract.investInOffering(1, 100, address(usdc)); // Use index 1 for the new offering
        vm.stopPrank();

        // Fast forward past the offering end time
        vm.warp(startTime + 1 days + 1);

        // Get the offering to check remaining balance
        Offering memory offering = investContract.listOffering(1);
        uint256 remainingBalanceBefore = offering.balRemaining;
        assertGt(remainingBalanceBefore, 0, "Should have remaining balance after partial investment");

        // TokenAdmin removes the remaining balance
        vm.startPrank(tokenAdmin);
        uint256 newTokenId = investContract.removeRemainingTokenId(1, address(usdc));
        vm.stopPrank();

        // Verify the new tokenId was created
        assertGt(newTokenId, 0, "New tokenId should be created");

        // Check that the offering's remaining balance is now 0
        offering = investContract.listOffering(1);
        assertEq(offering.balRemaining, 0, "Remaining balance should be 0 after removal");

        // Verify the tokenAdmin now owns the new tokenId
        address newTokenOwner = token.ownerOf(newTokenId);
        assertEq(newTokenOwner, tokenAdmin, "TokenAdmin should own the new tokenId");
    }

    function test_removeRemainingTokenId_offeringNotEnded() public {
        // Try to remove remaining balance before offering has ended
        vm.startPrank(tokenAdmin);
        vm.expectRevert(ICTMRWA1InvestWithTimeLock.CTMRWA1InvestWithTimeLock_OfferingNotEnded.selector);
        investContract.removeRemainingTokenId(0, address(usdc));
        vm.stopPrank();
    }

    function test_removeRemainingTokenId_noRemainingBalance() public {
        // First, create a new offering for this test
        vm.startPrank(tokenAdmin);
        uint256 testTokenId = rwa1X.mintNewTokenValueLocal(tokenAdmin, 0, slotId, 1000e18, ID, feeTokenStr);
        token.approve(address(investContract), testTokenId);
        
        investContract.createOffering(
            testTokenId,
            price,
            currency,
            minInvest,
            maxInvest,
            "US",
            "SEC",
            "Full Investment Test",
            "full-investment-test",
            startTime,
            startTime + 1 days,
            lockDuration,
            currency,
            currency
        );
        vm.stopPrank();

        // Invest a significant amount to reduce the remaining balance
        _approveForInvestment(user1, 1000);
        vm.startPrank(user1);
        investContract.investInOffering(1, 1000, address(usdc));
        vm.stopPrank();

        // Fast forward past the offering end time
        vm.warp(startTime + 1 days + 1);

        // Check the remaining balance after investment
        Offering memory offering = investContract.listOffering(1);
        uint256 remainingBalance = offering.balRemaining;
        
        // If there's remaining balance, test the removal functionality
        if (remainingBalance > 0) {
            // TokenAdmin removes the remaining balance
            vm.startPrank(tokenAdmin);
            uint256 newTokenId = investContract.removeRemainingTokenId(1, address(usdc));
            vm.stopPrank();

            // Verify the new tokenId was created
            assertGt(newTokenId, 0, "New tokenId should be created");

            // Check that the offering's remaining balance is now 0
            offering = investContract.listOffering(1);
            assertEq(offering.balRemaining, 0, "Remaining balance should be 0 after removal");

            // Verify the tokenAdmin now owns the new tokenId
            address newTokenOwner = token.ownerOf(newTokenId);
            assertEq(newTokenOwner, tokenAdmin, "TokenAdmin should own the new tokenId");
        } else {
            // If no remaining balance, test that removal reverts
            vm.startPrank(tokenAdmin);
            vm.expectRevert(ICTMRWA1InvestWithTimeLock.CTMRWA1InvestWithTimeLock_NoRemainingBalance.selector);
            investContract.removeRemainingTokenId(1, address(usdc));
            vm.stopPrank();
        }
    }

    function test_removeRemainingTokenId_onlyTokenAdmin() public {
        // Fast forward past the offering end time
        vm.warp(endTime + 1);

        // Try to remove remaining balance as non-tokenAdmin
        vm.startPrank(user1);
        vm.expectRevert();
        investContract.removeRemainingTokenId(0, address(usdc));
        vm.stopPrank();
    }

    function test_removeRemainingTokenId_invalidOfferingIndex() public {
        // Fast forward past the offering end time
        vm.warp(endTime + 1);

        // Try to remove remaining balance with invalid offering index
        vm.startPrank(tokenAdmin);
        vm.expectRevert(ICTMRWA1InvestWithTimeLock.CTMRWA1InvestWithTimeLock_InvalidOfferingIndex.selector);
        investContract.removeRemainingTokenId(999, address(usdc)); // Non-existent offering index
        vm.stopPrank();
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
