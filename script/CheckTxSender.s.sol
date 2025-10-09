// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.27;

import { Script } from "forge-std/Script.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { console } from "forge-std/console.sol";
import { IC3GovernDApp } from "@c3caller/gov/IC3GovernDApp.sol";

contract CheckTxSender is Script {
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
        bool isTxSenderGateway = IC3GovernDApp(gateway).txSenders(txSender);
        bool isTxSenderFeeManager = IC3GovernDApp(feeManager).txSenders(txSender);
        bool isTxSenderRWA1X = IC3GovernDApp(rwa1X).txSenders(txSender);
        bool isTxSenderDeployer = IC3GovernDApp(deployer).txSenders(txSender);
        bool isTxSenderStorageManager = IC3GovernDApp(storageManager).txSenders(txSender);
        bool isTxSenderSentryManager = IC3GovernDApp(sentryManager).txSenders(txSender);
        bool isTxSenderMap = IC3GovernDApp(map).txSenders(txSender);

        string memory resGateway = 
            string.concat("Gateway ", (isTxSenderGateway ? unicode"✅" : unicode"⚠️"));
        string memory resFeeManager = 
            string.concat("FeeManager ", (isTxSenderFeeManager ? unicode"✅" : unicode"⚠️"));
        string memory resRWA1X = 
            string.concat("RWA1X ", (isTxSenderRWA1X ? unicode"✅" : unicode"⚠️"));
        string memory resDeployer = 
            string.concat("Deployer ", (isTxSenderDeployer ? unicode"✅" : unicode"⚠️"));
        string memory resStorageManager = 
            string.concat("StorageManager ", (isTxSenderStorageManager ? unicode"✅" : unicode"⚠️"));
        string memory resSentryManager = 
            string.concat("SentryManager ", (isTxSenderSentryManager ? unicode"✅" : unicode"⚠️"));
        string memory resMap = 
            string.concat("Map ", (isTxSenderMap ? unicode"✅" : unicode"⚠️"));

        console.log(resGateway);
        console.log(resFeeManager);
        console.log(resRWA1X);
        console.log(resDeployer);
        console.log(resStorageManager);
        console.log(resSentryManager);
        console.log(resMap);
        vm.stopBroadcast();
    }
}
