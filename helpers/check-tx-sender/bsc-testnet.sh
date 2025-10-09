#!/bin/bash

echo -e "\nBSC Testnet:"

result=$(cast call $GATEWAY_97 \
    "txSenders(address)(bool)" $TX_SENDER \
    --rpc-url bsc-testnet-rpc-url \
    --chain bsc-testnet)
if [ "$result" = "true" ]; then
    echo "✅ Gateway 97"
else
    echo "⚠️ Gateway 97"
fi

result=$(cast call $FEE_MANAGER_97 \
    "txSenders(address)(bool)" $TX_SENDER \
    --rpc-url bsc-testnet-rpc-url \
    --chain bsc-testnet)
if [ "$result" = "true" ]; then
    echo "✅ FeeManager 97"
else
    echo "⚠️ FeeManager 97"
fi

result=$(cast call $RWA1X_97 \
    "txSenders(address)(bool)" $TX_SENDER \
    --rpc-url bsc-testnet-rpc-url \
    --chain bsc-testnet)
if [ "$result" = "true" ]; then
    echo "✅ RWA1X 97"
else
    echo "⚠️ RWA1X 97"
fi

result=$(cast call $DEPLOYER_97 \
    "txSenders(address)(bool)" $TX_SENDER \
    --rpc-url bsc-testnet-rpc-url \
    --chain bsc-testnet)
if [ "$result" = "true" ]; then
    echo "✅ Deployer 97"
else
    echo "⚠️ Deployer 97"
fi

result=$(cast call $STORAGE_MANAGER_97 \
    "txSenders(address)(bool)" $TX_SENDER \
    --rpc-url bsc-testnet-rpc-url \
    --chain bsc-testnet)
if [ "$result" = "true" ]; then
    echo "✅ StorageManager 97"
else
    echo "⚠️ StorageManager 97"
fi

result=$(cast call $SENTRY_MANAGER_97 \
    "txSenders(address)(bool)" $TX_SENDER \
    --rpc-url bsc-testnet-rpc-url \
    --chain bsc-testnet)
if [ "$result" = "true" ]; then
    echo "✅ SentryManager 97"
else
    echo "⚠️ SentryManager 97"
fi

result=$(cast call $MAP_97 \
    "txSenders(address)(bool)" $TX_SENDER \
    --rpc-url bsc-testnet-rpc-url \
    --chain bsc-testnet)
if [ "$result" = "true" ]; then
    echo "✅ Map 97"
else
    echo "⚠️ Map 97"
fi
