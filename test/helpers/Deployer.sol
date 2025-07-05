// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.19;

// import {Test} from "forge-std/Test.sol";

import {Utils} from "./Utils.sol";

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

import {C3UUIDKeeper} from "@c3caller/uuid/C3UUIDKeeper.sol";
import {C3CallerProxy} from "@c3caller/C3CallerProxy.sol";
import {C3Caller} from "@c3caller/C3Caller.sol";
import {IC3Caller} from "@c3caller/IC3Caller.sol";

import {FeeManager} from "../../src/managers/FeeManager.sol";
import {FeeType} from "../../src/managers/IFeeManager.sol";

import {CTMRWAGateway} from "../../src/crosschain/CTMRWAGateway.sol";

import {CTMRWA1X} from "../../src/crosschain/CTMRWA1X.sol";
import {CTMRWA1XFallback} from "../../src/crosschain/CTMRWA1XFallback.sol";

import {CTMRWAMap} from "../../src/shared/CTMRWAMap.sol";

contract Deployer is Utils {
    using Strings for *;

    C3UUIDKeeper c3UUIDKeeper;
    C3CallerProxy c3callerProxy;
    C3Caller c3callerImpl;
    IC3Caller c3caller;

    FeeManager feeManager;
    string[]  tokensStr;
    uint256[] fees;

    CTMRWAGateway gateway;

    CTMRWA1X rwa1X;
    CTMRWA1XFallback rwa1XFallback;

    CTMRWAMap map;

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

        assertEq(c3caller.isCaller(address(c3callerProxy)), true);
    }

    function _deployFeeManager(address gov, address admin, address ctm, address usdc) internal {
        feeManager = new FeeManager(
            gov,
            address(c3caller),
            admin,
            1 // dappID = 1
        );

        vm.startPrank(gov);

        feeManager.addFeeToken(address(ctm).toHexString());
        feeManager.addFeeToken(address(usdc).toHexString());

        feeManager.setFeeMultiplier(FeeType.ADMIN, 5);
        feeManager.setFeeMultiplier(FeeType.DEPLOY, 100);
        feeManager.setFeeMultiplier(FeeType.MINT, 5);
        feeManager.setFeeMultiplier(FeeType.BURN, 5);
        feeManager.setFeeMultiplier(FeeType.TX, 1);
        feeManager.setFeeMultiplier(FeeType.WHITELIST, 1);
        feeManager.setFeeMultiplier(FeeType.COUNTRY, 1);

        string memory destChain = "1";
        string memory ctmAddrStr = _toLower(address(ctm).toHexString());
        string memory usdcAddrStr = _toLower(address(usdc).toHexString());

        tokensStr.push(ctmAddrStr);
        tokensStr.push(usdcAddrStr);

        fees.push(1000);
        fees.push(1000);

        feeManager.addFeeToken(
            destChain,
            tokensStr,
            fees
        );

        vm.stopPrank();
    }

    function _deployGateway(address gov, address admin) internal {
        gateway = new CTMRWAGateway(
            gov,
            address(c3caller),
            admin,
            4 // dappID = 4
        );
    }

    function _deployCTMRWA1X(address gov, address admin) internal {
        rwa1X = new CTMRWA1X(
            address(gateway),
            address(feeManager),
            gov,
            address(c3caller),
            admin,
            2 // dappID = 2
        );

        rwa1XFallback = new CTMRWA1XFallback(address(rwa1X));

        vm.prank(gov);
        rwa1X.setFallback(address(rwa1XFallback));

        string[] memory chainIdsStr = _stringToArray("1");
        string[] memory rwaXsStr = _stringToArray(address(rwa1X).toHexString());

        bool ok = gateway.attachRWAX(
            RWA_TYPE,
            VERSION,
            chainIdsStr,
            rwaXsStr
        );

        assertEq(ok, true);
    }

    function _deployMap() internal {
        map = new CTMRWAMap(
            address(gateway),
            address(rwa1X)
        );
    }
}
