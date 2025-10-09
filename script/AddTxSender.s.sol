// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.27;

import { Script } from "forge-std/Script.sol";
import { IC3GovernDApp } from "@c3caller/gov/IC3GovernDApp.sol";

contract AddTxSender is Script {
    address txSender;
    address gateway;
    address feeManager;
    address rwa1X;
    address deployer;
    address storageManager;
    address sentryManager;
    address map;

    function run() public {
        string memory chainIdStr = vm.toString(block.chainid);

        try vm.envAddress("TX_SENDER") returns (address _txSender) {
            txSender = _txSender;
        } catch {
            revert ("TX_SENDER not defined");
        }

        try vm.envAddress(string.concat("GATEWAY_", chainIdStr)) returns (address _gateway) {
            gateway = _gateway;
        } catch {
            revert ("GATEWAY_<chainid> not defined");
        }

        try vm.envAddress(string.concat("FEE_MANAGER_", chainIdStr)) returns (address _feeManager) {
            feeManager = _feeManager;
        } catch {
            revert ("FEE_MANAGER_<chainid> not defined");
        }

        try vm.envAddress(string.concat("RWA1X_", chainIdStr)) returns (address _rwa1X) {
            rwa1X = _rwa1X;
        } catch {
            revert ("RWA1X_<chainid> not defined");
        }

        try vm.envAddress(string.concat("DEPLOYER_", chainIdStr)) returns (address _deployer) {
            deployer = _deployer;
        } catch {
            revert ("DEPLOYER_<chainid> not defined");
        }

        try vm.envAddress(string.concat("STORAGE_MANAGER_", chainIdStr)) returns (address _storageManager) {
            storageManager = _storageManager;
        } catch {
            revert ("STORAGE_MANAGER_<chainid> not defined");
        }

        try vm.envAddress(string.concat("SENTRY_MANAGER_", chainIdStr)) returns (address _sentryManager) {
            sentryManager = _sentryManager;
        } catch {
            revert ("SENTRY_MANAGER_<chainid> not defined");
        }

        try vm.envAddress(string.concat("MAP_", chainIdStr)) returns (address _map) {
            map = _map;
        } catch {
            revert ("MAP_<chainid> not defined");
        }

        vm.startBroadcast();
        IC3GovernDApp(gateway).addTxSender(txSender);
        IC3GovernDApp(feeManager).addTxSender(txSender);
        IC3GovernDApp(rwa1X).addTxSender(txSender);
        IC3GovernDApp(deployer).addTxSender(txSender);
        IC3GovernDApp(storageManager).addTxSender(txSender);
        IC3GovernDApp(sentryManager).addTxSender(txSender);
        IC3GovernDApp(map).addTxSender(txSender);
        vm.stopBroadcast();
    }
}
