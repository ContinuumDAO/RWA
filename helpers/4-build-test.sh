#!/bin/bash

echo -e "\nBuilding test/core..."
forge build test/core/
echo -e "\nBuilding test/crosschain..."
forge build test/crosschain/
echo -e "\nBuilding test/deployment..."
echo -e "\nBuilding test/deployment/CTMRWA1TokenFactory.t.sol..."
forge build test/deployment/CTMRWA1TokenFactory.t.sol
echo -e "\nBuilding test/deployment/CTMRWADeployer.t.sol..."
forge build test/deployment/CTMRWADeployer.t.sol
echo -e "\nBuilding test/deployment/CTMRWADeployerUpgrades.t.sol..."
forge build test/deployment/CTMRWADeployerUpgrades.t.sol
echo -e "\nBuilding test/deployment/CTMRWADeployInvest.t.sol..."
forge build test/deployment/CTMRWADeployInvest.t.sol
echo -e "\nBuilding test/deployment/CTMRWAERC20Approval.t.sol..."
forge build test/deployment/CTMRWAERC20Approval.t.sol
echo -e "\nBuilding test/deployment/CTMRWAERC20Deployer.t.sol..."
forge build test/deployment/CTMRWAERC20Deployer.t.sol
echo -e "\nBuilding test/dividend..."
forge build test/dividend/
echo -e "\nBuilding test/identity..."
forge build test/identity/
echo -e "\nBuilding test/managers..."
echo -e "\nBuilding test/managers/FeeManager.t.sol..."
forge build test/managers/FeeManager.t.sol
echo -e "\nBuilding test/managers/FeeManagerFeeReduction.t.sol..."
forge build test/managers/FeeManagerFeeReduction.t.sol
echo -e "\nBuilding test/managers/FeeManagerUpgrades.t.sol..."
forge build test/managers/FeeManagerUpgrades.t.sol
echo -e "\nBuilding test/sentry..."
forge build test/sentry/
echo -e "\nBuilding test/shared..."
forge build test/shared/
echo -e "\nBuilding test/storage..."
forge build test/storage/
