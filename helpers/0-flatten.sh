#!/bin/bash

# remove old flattened files
rm -r flattened/

# create folders
mkdir -p flattened/
mkdir -p flattened/core/
mkdir -p flattened/crosschain/
mkdir -p flattened/deployment/
mkdir -p flattened/dividend/
mkdir -p flattened/identity/
mkdir -p flattened/managers/
mkdir -p flattened/sentry/
mkdir -p flattened/shared/
mkdir -p flattened/storage/
mkdir -p flattened/utils/

# core
forge flatten src/core/CTMRWA1.sol --output flattened/core/CTMRWA1.sol

# crosschain
forge flatten src/crosschain/CTMRWA1X.sol --output flattened/crosschain/CTMRWA1X.sol
forge flatten src/crosschain/CTMRWA1XUtils.sol --output flattened/crosschain/CTMRWA1XUtils.sol
forge flatten src/crosschain/CTMRWAGateway.sol --output flattened/crosschain/CTMRWAGateway.sol

# deployment
forge flatten src/deployment/CTMRWA1InvestWithTimeLock.sol --output flattened/deployment/CTMRWA1InvestWithTimeLock.sol
forge flatten src/deployment/CTMRWA1TokenFactory.sol --output flattened/deployment/CTMRWA1TokenFactory.sol
forge flatten src/deployment/CTMRWADeployer.sol --output flattened/deployment/CTMRWADeployer.sol
forge flatten src/deployment/CTMRWADeployInvest.sol --output flattened/deployment/CTMRWADeployInvest.sol
forge flatten src/deployment/CTMRWAERC20Deployer.sol --output flattened/deployment/CTMRWAERC20Deployer.sol
forge flatten src/deployment/CTMRWAERC20.sol --output flattened/deployment/CTMRWAERC20.sol

# dividend
forge flatten src/dividend/CTMRWA1DividendFactory.sol --output flattened/dividend/CTMRWA1DividendFactory.sol
forge flatten src/dividend/CTMRWA1Dividend.sol --output flattened/dividend/CTMRWA1Dividend.sol

# identity
forge flatten src/identity/CTMRWA1Identity.sol --output flattened/identity/CTMRWA1Identity.sol

# managers
forge flatten src/managers/FeeManager.sol --output flattened/managers/FeeManager.sol

# sentry
forge flatten src/sentry/CTMRWA1SentryManager.sol --output flattened/sentry/CTMRWA1SentryManager.sol
forge flatten src/sentry/CTMRWA1Sentry.sol --output flattened/sentry/CTMRWA1Sentry.sol
forge flatten src/sentry/CTMRWA1SentryUtils.sol --output flattened/sentry/CTMRWA1SentryUtils.sol

# shared
forge flatten src/shared/CTMRWAMap.sol --output flattened/shared/CTMRWAMap.sol

# storage
forge flatten src/storage/CTMRWA1Storage.sol --output flattened/storage/CTMRWA1Storage.sol
forge flatten src/storage/CTMRWA1StorageManager.sol --output flattened/storage/CTMRWA1StorageManager.sol
forge flatten src/storage/CTMRWA1StorageUtils.sol --output flattened/storage/CTMRWA1StorageUtils.sol

# utils
forge flatten src/utils/CTMRWAProxy.sol --output flattened/utils/CTMRWAProxy.sol
