// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {Accounts} from "./Accounts.sol";
import {Deployer} from "./Deployer.sol";

contract TestHelper is Test, Accounts, Deployer {
    function setUp() public {
        (admin, gov, treasury, user1, user2, issuer1, issuer2) = abi.decode(
            abi.encode(_getAccounts()),
            (address, address, address, address, address, address, address)
        );

        _dealAllERC20(usdc, _100_000);
        _dealAllERC20(ctm, _100_000);
    }
}
