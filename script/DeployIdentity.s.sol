// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.27;

import { Script } from "forge-std/Script.sol";
import { console } from "forge-std/console.sol";

import { CTMRWA1Identity, ICTMRWA1Identity } from "../flattened/identity/CTMRWA1Identity.sol";
import { ICTMRWA1SentryManager } from "../flattened/sentry/CTMRWA1SentryManager.sol";

contract DeployIdentity is Script {
    uint256 rwaType = 1;
    uint256 version = 1;

    address map;
    address sentryManager;
    address verifier; // zkMe
    address feeManager;

    function run() external {
        require(block.chainid == 534_351, "Must be connected to Scroll Sepolia");

        try vm.envAddress("MAP_534351") returns (address _map) {
            map = _map;
        } catch {
            revert ("MAP_534351 not defined");
        }

        try vm.envAddress("SENTRY_MANAGER_534351") returns (address _sentryManager) {
            sentryManager = _sentryManager;
        } catch {
            revert ("SENTRY_MANAGER_534351 not defined");
        }

        try vm.envAddress("FEE_MANAGER_534351") returns (address _feeManager) {
            feeManager = _feeManager;
        } catch {
            revert ("FEE_MANAGER_534351 not defined");
        }

        try vm.envAddress("VERIFIER_534351") returns (address _verifier) {
            verifier = _verifier;
        } catch {
            revert ("VERIFIER_534351 not defined");
        }

        vm.startBroadcast();

        console.log("Deploying Identity contract...");

        CTMRWA1Identity ctmIdentity =
            new CTMRWA1Identity(rwaType, version, map, sentryManager, verifier, feeManager);

        address ctmIdAddr = address(ctmIdentity);

        console.log("CTMRWA1Identity");
        console.log(ctmIdAddr);

        console.log("Setting zKMe verifier address");

        ICTMRWA1SentryManager(sentryManager).setIdentity(ctmIdAddr, verifier);

        console.log("Finished");

        vm.stopBroadcast();
    }
}
