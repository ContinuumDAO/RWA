#!/bin/bash

# remove old build files
rm -r build/

# create folders
mkdir -p build/
mkdir -p build/core/
mkdir -p build/crosschain/
mkdir -p build/deployment/
mkdir -p build/dividend/
mkdir -p build/identity/
mkdir -p build/managers/
mkdir -p build/sentry/
mkdir -p build/shared/
mkdir -p build/storage/
mkdir -p build/utils/

# core
forge flatten src/core/CTMRWA1.sol --output build/core/CTMRWA1.sol

# crosschain
forge flatten src/crosschain/CTMRWA1X.sol --output build/crosschain/CTMRWA1X.sol
forge flatten src/crosschain/CTMRWA1XUtils.sol --output build/crosschain/CTMRWA1XUtils.sol
forge flatten src/crosschain/CTMRWAGateway.sol --output build/crosschain/CTMRWAGateway.sol

# deployment
forge flatten src/deployment/CTMRWA1InvestWithTimeLock.sol --output build/deployment/CTMRWA1InvestWithTimeLock.sol
forge flatten src/deployment/CTMRWA1TokenFactory.sol --output build/deployment/CTMRWA1TokenFactory.sol
forge flatten src/deployment/CTMRWADeployer.sol --output build/deployment/CTMRWADeployer.sol
forge flatten src/deployment/CTMRWADeployInvest.sol --output build/deployment/CTMRWADeployInvest.sol
forge flatten src/deployment/CTMRWAERC20Deployer.sol --output build/deployment/CTMRWAERC20Deployer.sol
forge flatten src/deployment/CTMRWAERC20.sol --output build/deployment/CTMRWAERC20.sol

# dividend
forge flatten src/dividend/CTMRWA1DividendFactory.sol --output build/dividend/CTMRWA1DividendFactory.sol
forge flatten src/dividend/CTMRWA1Dividend.sol --output build/dividend/CTMRWA1Dividend.sol

# identity
forge flatten src/identity/CTMRWA1Identity.sol --output build/identity/CTMRWA1Identity.sol

# managers
forge flatten src/managers/FeeManager.sol --output build/managers/FeeManager.sol

# sentry
forge flatten src/sentry/CTMRWA1SentryManager.sol --output build/sentry/CTMRWA1SentryManager.sol
forge flatten src/sentry/CTMRWA1Sentry.sol --output build/sentry/CTMRWA1Sentry.sol
forge flatten src/sentry/CTMRWA1SentryUtils.sol --output build/sentry/CTMRWA1SentryUtils.sol

# shared
forge flatten src/shared/CTMRWAMap.sol --output build/shared/CTMRWAMap.sol

# storage
forge flatten src/storage/CTMRWA1Storage.sol --output build/storage/CTMRWA1Storage.sol
forge flatten src/storage/CTMRWA1StorageManager.sol --output build/storage/CTMRWA1StorageManager.sol
forge flatten src/storage/CTMRWA1StorageUtils.sol --output build/storage/CTMRWA1StorageUtils.sol

# utils
forge flatten src/utils/CTMRWAProxy.sol --output build/utils/CTMRWAProxy.sol
