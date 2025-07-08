// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.22;

import { Test } from "forge-std/Test.sol";
import { console } from "forge-std/console.sol";

import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

import { Helpers } from "../helpers/Helpers.sol";

contract TestGateway is Helpers {
    using Strings for *;

    function test_CTMRWAGateway_chainContract() public view {
        uint256 nChains = gateway.getChainCount();
        assertEq(nChains, 2); // local chain + "ethereumGateway"

        // Check the local chain gateway at position 0 added by initialize
        string memory gatewayStr = gateway.getChainContract(cID().toString());
        // console.log(gatewayStr);
        assertTrue(stringsEqual(gatewayStr, _toLower(address(gateway).toHexString())));
        address gway = stringToAddress(gatewayStr);
        // console.log(gway);
        assertEq(gway, address(gateway));

        string memory chainIdStr;
        uint256 pos = 1;
        (chainIdStr, gatewayStr) = gateway.getChainContract(pos);  // Check position 1 in the array
        assertTrue(stringsEqual(chainIdStr, "1"));
        assertTrue(stringsEqual(gatewayStr, _toLower("ethereumGateway")));

        // Check for Ethereum chainID added by deployer test setup
        gatewayStr = gateway.getChainContract("1"); 
        assertTrue(stringsEqual(gatewayStr, _toLower("ethereumGateway")));
    }

    // function test_CTMRWAGateway_rwaXChain() public view {
    //     uint256 nChains = gateway.getRWAXCount(RWA_TYPE, VERSION);
    //     assertEq(nChains, 2);

    //     nChains = gateway.getRWAXCount(RWA_TYPE + 1, VERSION);
    //     assertEq(nChains, 0);   // There are no chains for rwaType == 2

    //     string memory rwaxChainStr;
    //     string memory chainIdStr;
    //     bool ok;
    //     // Check the local chain rwa1X, added automatically in initialize
    //     (ok, rwaxChainStr) = gateway.getAttachedRWAX(RWA_TYPE, VERSION, cIdStr);
    //     assertTrue(ok);
    //     console.log(chainIdStr);
    //     console.log(address(rwa1X).toHexString());
    //     assertTrue(stringsEqual(rwaxChainStr, _toLower(address(rwa1X).toHexString())));

    //     // Check the rwaxChainStr at position 1
       
    //     uint256 pos = 1;
    //     (chainIdStr, rwaxChainStr) = gateway.getAttachedRWAX(RWA_TYPE, VERSION, pos);
    //     assertTrue(stringsEqual(chainIdStr, _toLower("NEARChainId")));

    //     chainIdStr = "NEARChainId";
    //     assertTrue(stringsEqual(
    //         rwaxChainStr,
    //         _toLower("thisIsSomeRandomAddressOnNEARForTestingWallet123456789.test.near")
    //     ));
    // }

}
