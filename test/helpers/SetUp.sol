// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {Helpers} from "./Helpers.sol";

contract SetUp is Test, Helpers {
    function setUp() public {
        (admin, gov, treasury, user1, user2, tokenAdmin, tokenAdmin) = abi.decode(
            abi.encode(_getAccounts()),
            (address, address, address, address, address, address, address)
        );

        (ctm, usdc) = _deployFeeTokens();

        _dealAllERC20(address(usdc), _100_000);
        _dealAllERC20(address(ctm), _100_000);

        vm.startPrank(gov);

        _deployC3Caller(gov);
        _deployFeeManager(gov, admin, address(ctm), address(usdc));
        _deployGateway(gov, admin);
        _deployCTMRWA1X(gov, admin);
        _deployMap();
        _deployCTMRWADeployer(gov, admin);
        _deployTokenFactory();
        _deployDividendFactory();
        _deployStorage(gov, admin);
        _deploySentry(gov, admin);

        vm.stopPrank();

        _setFeeContracts();

        _approveAllERC20(address(usdc), _100_000, feeContracts);
        _approveAllERC20(address(ctm), _100_000, feeContracts);
    }
}
