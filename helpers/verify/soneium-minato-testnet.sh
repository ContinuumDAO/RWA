#!/bin/bash

# FeeManager (implementation)
forge verify-contract \
  --rpc-url soneium-minato-testnet-rpc-url \
  0x0c746cf1cadd15f800b7d64c3c023d690d6a271a \
  flattened/managers/FeeManager.sol:FeeManager \
  --verifier blockscout \
  --verifier-url https://soneium-minato.blockscout.com/api/ \
  --chain soneium-minato-testnet \
  --watch

sleep 10

# FeeManager (proxy)
forge verify-contract \
  --rpc-url soneium-minato-testnet-rpc-url \
  $FEE_MANAGER_1946 \
  flattened/utils/CTMRWAProxy.sol:CTMRWAProxy \
  --verifier blockscout \
  --verifier-url https://soneium-minato.blockscout.com/api/ \
  --chain soneium-minato-testnet \
  --watch

sleep 10

# Gateway (implementation)
forge verify-contract \
  --rpc-url soneium-minato-testnet-rpc-url \
  0x430e19f6bdeec59093aae877af874eef6d7d943e \
  flattened/crosschain/CTMRWAGateway.sol:CTMRWAGateway \
  --verifier blockscout \
  --verifier-url https://soneium-minato.blockscout.com/api/ \
  --chain soneium-minato-testnet \
  --watch

sleep 10

# Gateway (proxy)
forge verify-contract \
  --rpc-url soneium-minato-testnet-rpc-url \
  $GATEWAY_1946 \
  flattened/utils/CTMRWAProxy.sol:CTMRWAProxy \
  --verifier blockscout \
  --verifier-url https://soneium-minato.blockscout.com/api/ \
  --watch

sleep 10

# RWA1X (implementation)
forge verify-contract \
  --rpc-url soneium-minato-testnet-rpc-url \
  0xaa673263a8b36f60fdc4dd0ebef9216a45c2abce\
  flattened/crosschain/CTMRWA1X.sol:CTMRWA1X \
  --verifier blockscout \
  --verifier-url https://soneium-minato.blockscout.com/api/ \
  --chain soneium-minato-testnet \
  --watch

sleep 10

# RWA1X (proxy)
forge verify-contract \
  --rpc-url soneium-minato-testnet-rpc-url \
  $RWA1X_1946 \
  flattened/utils/CTMRWAProxy.sol:CTMRWAProxy \
  --verifier blockscout \
  --verifier-url https://soneium-minato.blockscout.com/api/ \
  --chain soneium-minato-testnet \
  --watch

sleep 10

# RWA1XFallback
forge verify-contract \
  --rpc-url soneium-minato-testnet-rpc-url \
  $RWA1X_FALLBACK_1946 \
  flattened/crosschain/CTMRWA1XFallback.sol:CTMRWA1XFallback \
  --verifier blockscout \
  --verifier-url https://soneium-minato.blockscout.com/api/ \
  --chain soneium-minato-testnet \
  --watch

sleep 10

# Map (implementation)
forge verify-contract \
  --rpc-url soneium-minato-testnet-rpc-url \
  0x02aec43e2005f0d514bf640c5802c107e60868e0 \
  flattened/shared/CTMRWAMap.sol:CTMRWAMap \
  --verifier blockscout \
  --verifier-url https://soneium-minato.blockscout.com/api/ \
  --chain soneium-minato-testnet \
  --watch

sleep 10

# Map (proxy)
forge verify-contract \
  --rpc-url soneium-minato-testnet-rpc-url \
  $MAP_1946 \
  flattened/utils/CTMRWAProxy.sol:CTMRWAProxy \
  --verifier blockscout \
  --verifier-url https://soneium-minato.blockscout.com/api/ \
  --chain soneium-minato-testnet \
  --watch

sleep 10

# Deployer (implementation)
forge verify-contract \
  --rpc-url soneium-minato-testnet-rpc-url \
  0x7581696b0ed142f6534e5797baaabbb9a1b27086\
  flattened/deployment/CTMRWADeployer.sol:CTMRWADeployer \
  --verifier blockscout \
  --verifier-url https://soneium-minato.blockscout.com/api/ \
  --chain soneium-minato-testnet \
  --watch

sleep 10

# Deployer (proxy)
forge verify-contract \
  --rpc-url soneium-minato-testnet-rpc-url \
  $DEPLOYER_1946 \
  flattened/utils/CTMRWAProxy.sol:CTMRWAProxy \
  --verifier blockscout \
  --verifier-url https://soneium-minato.blockscout.com/api/ \
  --chain soneium-minato-testnet \
  --watch

sleep 10

# DeployInvest
forge verify-contract \
  --rpc-url soneium-minato-testnet-rpc-url \
  $DEPLOY_INVEST_1946 \
  flattened/deployment/CTMRWADeployInvest.sol:CTMRWADeployInvest \
  --verifier blockscout \
  --verifier-url https://soneium-minato.blockscout.com/api/ \
  --watch

sleep 10

# ERC20Deployer
forge verify-contract \
  --rpc-url soneium-minato-testnet-rpc-url \
  $ERC20_DEPLOYER_1946 \
  flattened/deployment/CTMRWAERC20Deployer.sol:CTMRWAERC20Deployer \
  --verifier blockscout \
  --verifier-url https://soneium-minato.blockscout.com/api/ \
  --chain soneium-minato-testnet \
  --watch

sleep 10

# TokenFactory
forge verify-contract \
  --rpc-url soneium-minato-testnet-rpc-url \
  $TOKEN_FACTORY_1946 \
  flattened/deployment/CTMRWA1TokenFactory.sol:CTMRWA1TokenFactory \
  --verifier blockscout \
  --verifier-url https://soneium-minato.blockscout.com/api/ \
  --watch

sleep 10

# DividendFactory
forge verify-contract \
  --rpc-url soneium-minato-testnet-rpc-url \
  $DIVIDEND_FACTORY_1946 \
  flattened/dividend/CTMRWA1DividendFactory.sol:CTMRWA1DividendFactory \
  --verifier blockscout \
  --verifier-url https://soneium-minato.blockscout.com/api/ \
  --chain soneium-minato-testnet \
  --watch

sleep 10

# StorageManager (implementation)
forge verify-contract \
  --rpc-url soneium-minato-testnet-rpc-url \
  0x76ff2cb03175900f1d83328c82d27ea9aeaf2355\
  flattened/storage/CTMRWA1StorageManager.sol:CTMRWA1StorageManager \
  --verifier blockscout \
  --verifier-url https://soneium-minato.blockscout.com/api/ \
  --chain soneium-minato-testnet \
  --watch

sleep 10

# StorageManager (proxy)
forge verify-contract \
  --rpc-url soneium-minato-testnet-rpc-url \
  $STORAGE_MANAGER_1946 \
  flattened/utils/CTMRWAProxy.sol:CTMRWAProxy \
  --verifier blockscout \
  --verifier-url https://soneium-minato.blockscout.com/api/ \
  --chain soneium-minato-testnet \
  --watch

sleep 10

# StorageUtils
forge verify-contract \
  --rpc-url soneium-minato-testnet-rpc-url \
  $STORAGE_UTILS_1946 \
  flattened/storage/CTMRWA1StorageUtils.sol:CTMRWA1StorageUtils \
  --verifier blockscout \
  --verifier-url https://soneium-minato.blockscout.com/api/ \
  --chain soneium-minato-testnet \
  --watch

sleep 10

# SentryManager (implementation)
forge verify-contract \
  --rpc-url soneium-minato-testnet-rpc-url \
  0x4ebd7ccbe32a51d1638cfe90e8ed1c4bdf42f729\
  flattened/sentry/CTMRWA1SentryManager.sol:CTMRWA1SentryManager \
  --verifier blockscout \
  --verifier-url https://soneium-minato.blockscout.com/api/ \
  --chain soneium-minato-testnet \
  --watch

sleep 10

# SentryManager (proxy)
forge verify-contract \
  --rpc-url soneium-minato-testnet-rpc-url \
  $SENTRY_MANAGER_1946 \
  flattened/utils/CTMRWAProxy.sol:CTMRWAProxy \
  --verifier blockscout \
  --verifier-url https://soneium-minato.blockscout.com/api/ \
  --chain soneium-minato-testnet \
  --watch

sleep 10

# SentryUtils
forge verify-contract \
  --rpc-url soneium-minato-testnet-rpc-url \
  $SENTRY_UTILS_1946 \
  flattened/sentry/CTMRWA1SentryUtils.sol:CTMRWA1SentryUtils \
  --verifier blockscout \
  --verifier-url https://soneium-minato.blockscout.com/api/ \
  --chain soneium-minato-testnet \
  --watch