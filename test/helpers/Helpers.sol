// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.27;

import { Test } from "forge-std/Test.sol";

import { Accounts } from "./Accounts.sol";
import { Deployer } from "./Deployer.sol";
import { RWA } from "./RWA.sol";

contract Helpers is Test, Accounts, Deployer, RWA {
    function setUp() public virtual {
        address[] memory accounts = _getAccounts();
        admin = accounts[0];
        gov = accounts[1];
        treasury = accounts[2];
        user1 = accounts[3];
        user2 = accounts[4];
        tokenAdmin = accounts[5];
        tokenAdmin2 = accounts[6];

        (ctm, usdc) = _deployFeeTokens();

        vm.deal(admin, 100 ether);
        vm.deal(gov, 100 ether);
        vm.deal(tokenAdmin, 100 ether);
        vm.deal(tokenAdmin2, 100 ether);

        _dealAllERC20(address(usdc), _100_000 * 10);
        _dealAllERC20(address(ctm), _100_000 * 10);

        vm.startPrank(gov);

        _deployC3CallerContracts();
        usdc.approve(address(dappManager), 350 * 10 ** usdc.decimals()); // 350 USDC to cover 7x 50 USDC dapp deposits
        _initiateC3Fee(address(usdc), 50 * 10 ** usdc.decimals());
        _registerDAppIDs(address(usdc));
        _deployFeeManager(gov, address(ctm), address(usdc));
        _deployGateway(gov);
        _deployCTMRWA1X(gov);
        _deployMap(gov);
        _deployCTMRWADeployer(gov);
        _deployTokenFactory();
        _deployDividendFactory();
        _deployStorage(gov);
        _deploySentry(gov);

        vm.stopPrank();

        _setFeeContracts();

        // Give rwa1X contract token balances to pay fees
        deal(address(usdc), address(rwa1X), _100_000 * 10 ** usdc.decimals());
        deal(address(ctm), address(rwa1X), _100_000 * 10 ** ctm.decimals());
        
        // Give additional tokens for minting operations
        deal(address(usdc), address(rwa1X), _100_000 * 10 ** usdc.decimals() * 2);
        deal(address(ctm), address(rwa1X), _100_000 * 10 ** ctm.decimals() * 2);

        _approveAllERC20(address(usdc), _100_000 * 100, feeContracts);
        _approveAllERC20(address(ctm), _100_000 * 100, feeContracts);

        // Give rwa1X contract self-approvals to spend its own tokens for fees
        vm.startPrank(address(rwa1X));
        usdc.approve(address(rwa1X), type(uint256).max);
        ctm.approve(address(rwa1X), type(uint256).max);
        vm.stopPrank();
    }
}
