// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.27;

import { console } from "forge-std/console.sol";

import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

import { Helpers } from "../helpers/Helpers.sol";

import { ICTMRWA1 } from "../../src/core/ICTMRWA1.sol";
import { ICTMRWAERC20 } from "../../src/deployment/ICTMRWAERC20.sol";
import { ICTMRWAERC20Deployer } from "../../src/deployment/ICTMRWAERC20Deployer.sol";
import { IERC20Errors } from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";
import { FeeType } from "../../src/managers/IFeeManager.sol";
import { CTMRWAErrorParam } from "../../src/utils/CTMRWAUtils.sol";

error EnforcedPause();

contract TestERC20Deployer is Helpers {
    using Strings for *;


    function test_deployErc20_revertsOnNonExistentSlot() public {
        vm.startPrank(tokenAdmin);
        (ID, token) = _deployCTMRWA1(address(usdc));
        uint256 nonExistentSlot = 42;
        string memory name = "No Slot";
        usdc.approve(address(ctmRwaErc20Deployer), 100_000_000);
        vm.expectRevert(abi.encodeWithSelector(ICTMRWAERC20.CTMRWAERC20_NonExistentSlot.selector, nonExistentSlot));
        ctmRwaErc20Deployer.deployERC20(ID, 1, 1, nonExistentSlot, name, address(usdc));
        vm.stopPrank();
    }

    function test_deployErc20_deployment() public {
        vm.startPrank(tokenAdmin);
        (ID, token) = _deployCTMRWA1(address(usdc));
        _createSomeSlots(ID, address(usdc), address(rwa1X));
        uint256 slot = 1;
        string memory name = "Basic Stuff";
        usdc.approve(address(ctmRwaErc20Deployer), 100_000_000);
        address newErc20 = ctmRwaErc20Deployer.deployERC20(ID, 1, 1, slot, name, address(usdc));
        assertEq(stringsEqual(ICTMRWAERC20(newErc20).name(), "slot 1| Basic Stuff"), true);
        assertEq(stringsEqual(ICTMRWAERC20(newErc20).symbol(), "SFTX1"), true);
        assertEq(ICTMRWAERC20(newErc20).decimals(), 18);
        assertEq(ICTMRWAERC20(newErc20).totalSupply(), 0);
        vm.stopPrank();
    }

    function test_deployErc20_reverts() public {
        vm.startPrank(tokenAdmin);
        (ID, token) = _deployCTMRWA1(address(usdc));
        _createSomeSlots(ID, address(usdc), address(rwa1X));
        uint256 slot = ICTMRWA1(address(token)).slotByIndex(0); // just use the first slot
        string memory name = "Basic Stuff";
        usdc.approve(address(ctmRwaErc20Deployer), 100_000_000);
        ctmRwaErc20Deployer.deployERC20(ID, 1, 1, slot, name, address(usdc));
        vm.expectRevert(); // CREATE2 collision when trying to deploy for same slot
        ctmRwaErc20Deployer.deployERC20(ID, 1, 1, slot, name, address(usdc));
        vm.expectRevert(abi.encodeWithSelector(ICTMRWAERC20.CTMRWAERC20_NonExistentSlot.selector, 99));
        ctmRwaErc20Deployer.deployERC20(ID, 1, 1, 99, name, address(usdc));
        vm.stopPrank();
    }

    function test_minting_and_supply() public {
        vm.startPrank(tokenAdmin);
        (ID, token) = _deployCTMRWA1(address(usdc));
        _createSomeSlots(ID, address(usdc), address(rwa1X));
        uint256 slot = 1;
        string memory name = "Basic Stuff";
        string memory feeTokenStr = _toLower((address(usdc).toHexString()));
        usdc.approve(address(ctmRwaErc20Deployer), 100_000_000);
        address newErc20 = ctmRwaErc20Deployer.deployERC20(ID, 1, 1, slot, name, address(usdc));
        rwa1X.mintNewTokenValueLocal(user1, 0, slot, 2000, ID, VERSION, feeTokenStr);
        assertEq(ICTMRWAERC20(newErc20).balanceOf(user1), 2000);
        assertEq(ICTMRWAERC20(newErc20).totalSupply(), 2000);
        rwa1X.mintNewTokenValueLocal(user2, 0, slot, 3000, ID, VERSION, feeTokenStr);
        assertEq(ICTMRWAERC20(newErc20).totalSupply(), 5000);
        rwa1X.mintNewTokenValueLocal(user2, 0, slot, 4000, ID, VERSION, feeTokenStr);
        assertEq(ICTMRWAERC20(newErc20).balanceOf(user2), 7000);
        assertEq(ICTMRWAERC20(newErc20).totalSupply(), 9000);
        vm.stopPrank();
    }




    // Invariant: total supply equals sum of all balances
    function testInvariant_totalSupplyEqualsBalances() public {
        vm.startPrank(tokenAdmin);
        (ID, token) = _deployCTMRWA1(address(usdc));
        _createSomeSlots(ID, address(usdc), address(rwa1X));
        uint256 slot = 1;
        string memory name = "Basic Stuff";
        string memory feeTokenStr = _toLower((address(usdc).toHexString()));
        usdc.approve(address(ctmRwaErc20Deployer), 100_000_000);
        address newErc20 = ctmRwaErc20Deployer.deployERC20(ID, 1, 1, slot, name, address(usdc));
        rwa1X.mintNewTokenValueLocal(user1, 0, slot, 1000, ID, VERSION, feeTokenStr);
        rwa1X.mintNewTokenValueLocal(user2, 0, slot, 2000, ID, VERSION, feeTokenStr);
        uint256 total = ICTMRWAERC20(newErc20).balanceOf(user1) + ICTMRWAERC20(newErc20).balanceOf(user2);
        assertEq(ICTMRWAERC20(newErc20).totalSupply(), total);
        vm.stopPrank();
    }

    // Edge: transfer more than balance





    function test_deployErc20_withFeePayment() public {
        // Set up fee for ERC20 deployment
        vm.startPrank(gov);
        feeManager.setFeeMultiplier(FeeType.ERC20, 50); // Set ERC20 fee multiplier to 50
        vm.stopPrank();

        // Deploy CTMRWA1 contract
        vm.startPrank(tokenAdmin);
        (ID, token) = _deployCTMRWA1(address(usdc));
        _createSomeSlots(ID, address(usdc), address(rwa1X));
        
        uint256 slot = 1;
        string memory name = "Fee Test ERC20";
        
        // Get initial balances
        uint256 initialBalance = usdc.balanceOf(tokenAdmin);
        uint256 initialFeeManagerBalance = usdc.balanceOf(address(feeManager));
        
        // Debug: Check what fee is actually being charged
        string memory feeTokenStr = address(usdc).toHexString();
        uint256 actualFee = feeManager.getXChainFee(
            _stringToArray(block.chainid.toString()), 
            false, 
            FeeType.ERC20, 
            feeTokenStr
        );
        
        // Use the actual fee from the FeeManager
        uint256 expectedFee = actualFee;
        
        // Approve the CTMRWAERC20Deployer to spend the fee tokens
        usdc.approve(address(ctmRwaErc20Deployer), expectedFee);
        
        // Deploy the ERC20
        ctmRwaErc20Deployer.deployERC20(ID, 1, 1, slot, name, address(usdc));
        
        // Verify the ERC20 was deployed
        address newErc20 = token.getErc20(slot);
        assertEq(stringsEqual(ICTMRWAERC20(newErc20).name(), "slot 1| Fee Test ERC20"), true);
        assertEq(stringsEqual(ICTMRWAERC20(newErc20).symbol(), "SFTX1"), true);
        
        // Verify the fee was paid correctly
        uint256 finalBalance = usdc.balanceOf(tokenAdmin);
        uint256 finalFeeManagerBalance = usdc.balanceOf(address(feeManager));
        
        // The tokenAdmin should have paid the fee
        assertEq(initialBalance - finalBalance, expectedFee, "TokenAdmin should have paid the correct fee");
        
        // The FeeManager should have received the fee
        assertEq(finalFeeManagerBalance - initialFeeManagerBalance, expectedFee, "FeeManager should have received the fee");
        
        vm.stopPrank();
    }
}
