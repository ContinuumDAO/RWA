#!/bin/bash

echo -e "\nBase Sepolia:"

result=$(cast call $GATEWAY_84532 \
    "txSenders(address)(bool)" $TX_SENDER \
    --rpc-url base-sepolia-rpc-url \
    --chain base-sepolia)
if [ "$result" = "true" ]; then
    echo "✅ Gateway 84532"
else
    echo "⚠️ Gateway 84532"
fi

result=$(cast call $FEE_MANAGER_84532 \
    "txSenders(address)(bool)" $TX_SENDER \
    --rpc-url base-sepolia-rpc-url \
    --chain base-sepolia)
if [ "$result" = "true" ]; then
    echo "✅ FeeManager 84532"
else
    echo "⚠️ FeeManager 84532"
fi

result=$(cast call $RWA1X_84532 \
    "txSenders(address)(bool)" $TX_SENDER \
    --rpc-url base-sepolia-rpc-url \
    --chain base-sepolia)
if [ "$result" = "true" ]; then
    echo "✅ RWA1X 84532"
else
    echo "⚠️ RWA1X 84532"
fi

result=$(cast call $DEPLOYER_84532 \
    "txSenders(address)(bool)" $TX_SENDER \
    --rpc-url base-sepolia-rpc-url \
    --chain base-sepolia)
if [ "$result" = "true" ]; then
    echo "✅ Deployer 84532"
else
    echo "⚠️ Deployer 84532"
fi

result=$(cast call $STORAGE_MANAGER_84532 \
    "txSenders(address)(bool)" $TX_SENDER \
    --rpc-url base-sepolia-rpc-url \
    --chain base-sepolia)
if [ "$result" = "true" ]; then
    echo "✅ StorageManager 84532"
else
    echo "⚠️ StorageManager 84532"
fi

result=$(cast call $SENTRY_MANAGER_84532 \
    "txSenders(address)(bool)" $TX_SENDER \
    --rpc-url base-sepolia-rpc-url \
    --chain base-sepolia)
if [ "$result" = "true" ]; then
    echo "✅ SentryManager 84532"
else
    echo "⚠️ SentryManager 84532"
fi

result=$(cast call $MAP_84532 \
    "txSenders(address)(bool)" $TX_SENDER \
    --rpc-url base-sepolia-rpc-url \
    --chain base-sepolia)
if [ "$result" = "true" ]; then
    echo "✅ Map 84532"
else
    echo "⚠️ Map 84532"
fi
