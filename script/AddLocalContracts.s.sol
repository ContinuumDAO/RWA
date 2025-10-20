// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.27;

import { Script } from "forge-std/Script.sol";
import { ICTMRWAGateway } from "../build/crosschain/CTMRWAGateway.sol";
import { LoadDeployedContracts } from "./LoadDeployedContracts.s.sol";
import { DeployedContracts } from "./Utils.s.sol";

contract AddLocalContracts is Script {
    address gateway;
    address rwa1X;
    address storageManager;
    address sentryManager;

    string gatewayPrefix = "GATEWAY_";
    string rwa1XPrefix = "RWA1X_";
    string storageManagerPrefix = "STORAGE_MANAGER_";
    string sentryManagerPrefix = "SENTRY_MANAGER_";

    string gatewayKey;
    string rwa1XKey;
    string storageManagerKey;
    string sentryManagerKey;

    uint256 RWA_TYPE = 1;
    uint256 VERSION = 1;

    DeployedContracts deployedContracts;

    function run() public {
        LoadDeployedContracts loadDeployedContracts = new LoadDeployedContracts();
        deployedContracts = loadDeployedContracts.local();

        string memory chainIdStr = vm.toString(block.chainid);
        string[] memory chainIdsStr = new string[](1);
        chainIdsStr[0] = chainIdStr;
        gatewayKey = string.concat(gatewayPrefix, chainIdStr);
        rwa1XKey = string.concat(rwa1XPrefix, chainIdStr);
        storageManagerKey = string.concat(storageManagerPrefix, chainIdStr);
        sentryManagerKey = string.concat(sentryManagerPrefix, chainIdStr);

        try vm.envAddress(gatewayKey) returns (address _gateway) {
            gateway = _gateway;
        } catch {
            revert(string.concat(gatewayKey, " not defined"));
        }

        try vm.envAddress(rwa1XKey) returns (address _rwa1X) {
            rwa1X = _rwa1X;
        } catch {
            revert(string.concat(rwa1XKey, " not defined"));
        }

        try vm.envAddress(storageManagerKey) returns (address _storageManager) {
            storageManager = _storageManager;
        } catch {
            revert(string.concat(storageManagerKey, " not defined"));
        }

        try vm.envAddress(sentryManagerKey) returns (address _sentryManager) {
            sentryManager = _sentryManager;
        } catch {
            revert(string.concat(sentryManagerKey, " not defined"));
        }

        string[] memory gatewaysStr = new string[](1);
        gatewaysStr[0] = vm.toString(gateway);

        string[] memory rwa1XsStr = new string[](1);
        rwa1XsStr[0] = vm.toString(rwa1X);

        string[] memory storageManagersStr = new string[](1);
        storageManagersStr[0] = vm.toString(storageManager);

        string[] memory sentryManagersStr = new string[](1);
        sentryManagersStr[0] = vm.toString(sentryManager);

        vm.startBroadcast();
            ICTMRWAGateway(gateway).addChainContract(chainIdsStr, gatewaysStr);
            ICTMRWAGateway(gateway).attachRWAX(RWA_TYPE, VERSION, chainIdsStr, rwa1XsStr);
            ICTMRWAGateway(gateway).attachStorageManager(RWA_TYPE, VERSION, chainIdsStr, storageManagersStr);
            ICTMRWAGateway(gateway).attachSentryManager(RWA_TYPE, VERSION, chainIdsStr, sentryManagersStr);
        vm.stopBroadcast();
    }
}
