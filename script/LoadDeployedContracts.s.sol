// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.27;

import { Script } from "forge-std/Script.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

import { DeployedContracts } from "./Utils.s.sol";

contract LoadDeployedContracts is Script {
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

    function all() public view returns (DeployedContracts[] memory) {
        uint256 nChains = _loadNChains();

        DeployedContracts[] memory deployedContracts = new DeployedContracts[](nChains);

        for (uint256 i = 0; i < nChains; i++) {
            string memory chainIdStr = vm.envString(string.concat("CHAIN_ID_", vm.toString(i)));
            DeployedContracts memory deployedContractsLocal = _deployedContractsLocal(chainIdStr);

            deployedContracts[i] = deployedContractsLocal;
        }

        return deployedContracts;
    }

    function local() public view returns (DeployedContracts memory) {
        uint256 nChains = _loadNChains();

        DeployedContracts memory deployedContractsLocal;

        for (uint256 i = 0; i < nChains; i++) {
            string memory chainIdStr = vm.envString(string.concat("CHAIN_ID_", vm.toString(i)));
            if (Strings.equal(chainIdStr, vm.toString(block.chainid))) {
                deployedContractsLocal = _deployedContractsLocal(chainIdStr);
                break;
            }
        }

        return deployedContractsLocal;
    }

    function _deployedContractsLocal(string memory _chainIdStr) internal view returns (DeployedContracts memory) {
        DeployedContracts memory deployedContracts = DeployedContracts({
            chainIdStr: _chainIdStr,
            feeManager: vm.envAddress(string.concat(feeManagerPrefix, _chainIdStr)),
            gateway: vm.envAddress(string.concat(gatewayPrefix, _chainIdStr)),
            rwa1X: vm.envAddress(string.concat(rwa1XPrefix, _chainIdStr)),
            rwa1XFallback: vm.envAddress(string.concat(rwa1XFallbackPrefix, _chainIdStr)),
            map: vm.envAddress(string.concat(mapPrefix, _chainIdStr)),
            deployer: vm.envAddress(string.concat(deployerPrefix, _chainIdStr)),
            deployInvest: vm.envAddress(string.concat(deployInvestPrefix, _chainIdStr)),
            erc20Deployer: vm.envAddress(string.concat(erc20DeployerPrefix, _chainIdStr)),
            tokenFactory: vm.envAddress(string.concat(tokenFactoryPrefix, _chainIdStr)),
            dividendFactory: vm.envAddress(string.concat(dividendFactoryPrefix, _chainIdStr)),
            storageManager: vm.envAddress(string.concat(storageManagerPrefix, _chainIdStr)),
            storageUtils: vm.envAddress(string.concat(storageUtilsPrefix, _chainIdStr)),
            sentryManager: vm.envAddress(string.concat(sentryManagerPrefix, _chainIdStr)),
            sentryUtils: vm.envAddress(string.concat(sentryUtilsPrefix, _chainIdStr)),
            feeToken: vm.envAddress(string.concat(feeTokenPrefix, _chainIdStr))
        });

        return deployedContracts;
    }

    function _loadNChains() internal view returns (uint256 nChains) {
        try vm.envUint("N_CHAINS") returns (uint256 _nChains) {
            nChains = _nChains;
        } catch {
            revert("N_CHAINS not set");
        }
    }
}
