#!/bin/bash

echo -e "\n🔨 Building test/core..."
forge build test/core/
echo -e "\n🔨 Building test/crosschain..."
forge build test/crosschain/
echo -e "\n🔨 Building test/deployment..."
echo -e "🔨 Building test/deployment/CTMRWA1TokenFactory.t.sol..."
forge build test/deployment/CTMRWA1TokenFactory.t.sol
echo -e "🔨 Building test/deployment/CTMRWADeployer.t.sol..."
forge build test/deployment/CTMRWADeployer.t.sol
echo -e "🔨 Building test/deployment/CTMRWADeployerUpgrades.t.sol..."
forge build test/deployment/CTMRWADeployerUpgrades.t.sol
echo -e "🔨 Building test/deployment/CTMRWADeployInvest.t.sol..."
forge build test/deployment/CTMRWADeployInvest.t.sol
echo -e "🔨 Building test/deployment/CTMRWAERC20Approval.t.sol..."
forge build test/deployment/CTMRWAERC20Approval.t.sol
echo -e "🔨 Building test/deployment/CTMRWAERC20Deployer.t.sol..."
forge build test/deployment/CTMRWAERC20Deployer.t.sol
echo -e "\n🔨 Building test/dividend..."
forge build test/dividend/
echo -e "\n🔨 Building test/identity..."
forge build test/identity/
echo -e "\n🔨 Building test/managers..."
echo -e "🔨 Building test/managers/FeeManager.t.sol..."
forge build test/managers/FeeManager.t.sol
echo -e "🔨 Building test/managers/FeeManagerFeeReduction.t.sol..."
forge build test/managers/FeeManagerFeeReduction.t.sol
echo -e "🔨 Building test/managers/FeeManagerUpgrades.t.sol..."
forge build test/managers/FeeManagerUpgrades.t.sol
echo -e "\n🔨 Building test/sentry..."
forge build test/sentry/
echo -e "\n🔨 Building test/shared..."
forge build test/shared/
echo -e "\n🔨 Building test/storage..."
forge build test/storage/
