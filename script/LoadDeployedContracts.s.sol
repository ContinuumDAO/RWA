// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.27;

import {Script} from "forge-std/Script.sol";
import {DeployedContracts} from "./Utils.s.sol";

contract LoadDeployedContracts is Script {
    uint256 nChains;

    string feeManagerPrefix = "FEE_MANAGER_";
    string gatewayPrefix = "GATEWAY_";
    string rwa1XPrefix = "RWA1X_";
    string rwa1XFallbackPrefix = "RWA1X_FALLBACK_";
    string mapPrefix = "MAP_";
    string deployerPrefix = "DEPLOYER_";
    string deployInvestPrefix = "DEPLOY_INVEST_";
    string erc20DeployerPrefix = "ERC20_DEPLOYER_";
    string tokenFactoryPrefix = "TOKEN_FACTORY_";
    string dividendFactoryPrefix = "DIVIDEND_FACTORY_";
    string storageManagerPrefix = "STORAGE_MANAGER_";
    string storageUtilsPrefix = "STORAGE_UTILS_";
    string sentryManagerPrefix = "SENTRY_MANAGER_";
    string sentryUtilsPrefix = "SENTRY_UTILS_";
    string feeTokenPrefix = "FEE_TOKEN_";

    DeployedContracts[] public deployedContracts;

    function run() public returns (DeployedContracts[] memory) {
        try vm.envUint("N_CHAINS") returns (uint256 _nChains) {
            nChains = _nChains;
        } catch {
            revert("N_CHAINS not set");
        }

        for (uint256 i = 0; i < nChains; i++) {
            string memory chainIdStr = vm.envString(string.concat("CHAIN_ID_", vm.toString(i)));
            DeployedContracts memory deployedContract = DeployedContracts({
                chainIdStr: chainIdStr,
                feeManager: vm.envAddress(string.concat(feeManagerPrefix, chainIdStr)),
                gateway: vm.envAddress(string.concat(gatewayPrefix, chainIdStr)),
                rwa1X: vm.envAddress(string.concat(rwa1XPrefix, chainIdStr)),
                rwa1XFallback: vm.envAddress(string.concat(rwa1XFallbackPrefix, chainIdStr)),
                map: vm.envAddress(string.concat(mapPrefix, chainIdStr)),
                deployer: vm.envAddress(string.concat(deployerPrefix, chainIdStr)),
                deployInvest: vm.envAddress(string.concat(deployInvestPrefix, chainIdStr)),
                erc20Deployer: vm.envAddress(string.concat(erc20DeployerPrefix, chainIdStr)),
                tokenFactory: vm.envAddress(string.concat(tokenFactoryPrefix, chainIdStr)),
                dividendFactory: vm.envAddress(string.concat(dividendFactoryPrefix, chainIdStr)),
                storageManager: vm.envAddress(string.concat(storageManagerPrefix, chainIdStr)),
                storageUtils: vm.envAddress(string.concat(storageUtilsPrefix, chainIdStr)),
                sentryManager: vm.envAddress(string.concat(sentryManagerPrefix, chainIdStr)),
                sentryUtils: vm.envAddress(string.concat(sentryUtilsPrefix, chainIdStr)),
                feeToken: vm.envAddress(string.concat(feeTokenPrefix, chainIdStr))
            });

            deployedContracts.push(deployedContract);
        }

        return deployedContracts;
    }
}