// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.19;

import "forge-std/Test.sol";

import {ITestERC20} from "../../src/mocks/ITestERC20.sol";

contract Accounts is Test {
    address admin;
    address gov;
    address treasury;
    address user1;
    address user2;
    address user3;
    address issuer1;
    address issuer2;
    address issuer3;
    address extra;

    uint256 constant _100_000 = 100_000;

    function _getAccounts() internal returns (address[] memory accounts) {
        string memory mnemonic = "test test test test test test test test test test test junk";

        string[] memory labels = new string[](7);
        labels[0] = "Admin";
        labels[1] = "Governor";
        labels[2] = "Treasury";
        labels[3] = "User1";
        labels[4] = "User2";
        labels[5] = "Issuer1";
        labels[6] = "Issuer2";

        for (uint8 i = 0; i < 7; i++) {
            uint256 pk = vm.deriveKey(mnemonic, i);
            address pub = vm.addr(pk);
            vm.label(pub, labels[i]);
            accounts[i] = pub;
        }
    }

    function _dealAllERC20(address _token, uint256 _amount) internal {
        uint256 decimals = ITestERC20(_token).decimals();
        uint256 amount = _amount * 10 ** decimals;
        deal(_token, admin, amount, true);
        deal(_token, gov, amount, true);
        deal(_token, treasury, amount, true);
        deal(_token, user1, amount, true);
        deal(_token, user2, amount, true);
        deal(_token, user3, amount, true);
        deal(_token, issuer1, amount, true);
        deal(_token, issuer2, amount, true);
        deal(_token, issuer3, amount, true);
        deal(_token, extra, amount, true);
    }
}
