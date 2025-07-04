// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";

import {C3UUIDKeeper} from "@c3caller/C3UUIDKeeper.sol";
import {C3CallerProxy} from "@c3caller/C3CallerProxy.sol";
import {C3Caller} from "@c3caller/C3Caller.sol";
import {IC3Caller} from "@c3caller/IC3Caller.sol";

import {FeeManager} from "../../src/managers/FeeManager.sol";

contract Deployer is Test {
    C3UUIDKeeper c3UUIDKeeper;
    C3CallerProxy c3callerProxy;
    C3Caller c3callerImpl;
    IC3Caller c3caller;

    function _deployC3Caller(address gov) internal {
        vm.startPrank(gov);

        c3UUIDKeeper = new C3UUIDKeeper();
        c3callerImpl = new C3Caller();
        bytes memory initializerData = abi.encodeWithSignature(
            "initialize(address)",
            address(c3UUIDKeeper)
        );
        c3callerProxy = new C3CallerProxy(address(c3callerImpl), initializerData);
        c3caller = IC3Caller(address(c3callerProxy));

        vm.stopPrank();
    }
}
