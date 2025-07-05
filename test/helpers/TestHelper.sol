// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {Helpers} from "./Helpers.sol";

import {TestERC20} from "../../src/mocks/TestERC20.sol";

contract TestHelper is Test, Helpers {
    function setUp() public {
        (admin, gov, treasury, user1, user2, issuer1, issuer2) = abi.decode(
            abi.encode(_getAccounts()),
            (address, address, address, address, address, address, address)
        );

        TestERC20 ctm = new TestERC20("Continuum", "CTM", 18);
        TestERC20 usdc = new TestERC20("Circle USD", "USDC", 6);

        _dealAllERC20(address(usdc), _100_000);
        _dealAllERC20(address(ctm), _100_000);

        _deployC3Caller(gov);
        _deployFeeManager(gov, admin, address(ctm), address(usdc));
        _deployGateway(gov, admin);
        _deployCTMRWA1X(gov, admin);
        _deployMap();
    }
}
