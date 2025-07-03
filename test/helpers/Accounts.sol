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

    error InvalidLabelLength();

    uint256 constant INITIAL_TOKEN_BALANCE = 100_000;

    function getAccounts() public returns (
        address, address, address, address, address, address, address, address, address, address
    ) {
        string memory mnemonic = "test test test test test test test test test test test junk";

        uint256 pk0 = vm.deriveKey(mnemonic, 0);
        address pub0 = vm.addr(pk0);
        vm.label(pub0, "Admin");
        uint256 pk1 = vm.deriveKey(mnemonic, 1);
        address pub1 = vm.addr(pk1);
        vm.label(pub1, "Governor");
        uint256 pk2 = vm.deriveKey(mnemonic, 2);
        address pub2 = vm.addr(pk2);
        vm.label(pub2, "Treasury");
        uint256 pk3 = vm.deriveKey(mnemonic, 3);
        address pub3 = vm.addr(pk3);
        vm.label(pub3, "User 1");
        uint256 pk4 = vm.deriveKey(mnemonic, 4);
        address pub4 = vm.addr(pk4);
        vm.label(pub4, "User 2");
        uint256 pk5 = vm.deriveKey(mnemonic, 5);
        address pub5 = vm.addr(pk5);
        vm.label(pub5, "User 3");
        uint256 pk6 = vm.deriveKey(mnemonic, 6);
        address pub6 = vm.addr(pk6);
        vm.label(pub6, "Issuer 1");
        uint256 pk7 = vm.deriveKey(mnemonic, 7);
        address pub7 = vm.addr(pk7);
        vm.label(pub7, "Issuer 2");
        uint256 pk8 = vm.deriveKey(mnemonic, 8);
        address pub8 = vm.addr(pk8);
        vm.label(pub8, "Issuer 3");
        uint256 pk9 = vm.deriveKey(mnemonic, 9);
        address pub9 = vm.addr(pk9);
        vm.label(pub9, "Extra");

        return (pub0, pub1, pub2, pub3, pub4, pub5, pub6, pub7, pub8, pub9);
    }

    function dealAllERC20(address token) internal {
        uint256 decimals = ITestERC20(token).decimals();
        uint256 amount = INITIAL_TOKEN_BALANCE * 10 ** decimals;
        deal(token, admin, amount, true);
        deal(token, gov, amount, true);
        deal(token, treasury, amount, true);
        deal(token, user1, amount, true);
        deal(token, user2, amount, true);
        deal(token, user3, amount, true);
        deal(token, issuer1, amount, true);
        deal(token, issuer2, amount, true);
        deal(token, issuer3, amount, true);
        deal(token, extra, amount, true);
    }
}
