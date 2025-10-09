#!/bin/bash

echo -e "\nSepolia:"

result=$(cast call $GATEWAY_11155111 \
    "txSenders(address)(bool)" $TX_SENDER \
    --rpc-url sepolia-rpc-url \
    --chain sepolia)
if [ "$result" = "true" ]; then
    echo "✅ Gateway 11155111"
else
    echo "⚠️ Gateway 11155111"
fi

result=$(cast call $FEE_MANAGER_11155111 \
    "txSenders(address)(bool)" $TX_SENDER \
    --rpc-url sepolia-rpc-url \
    --chain sepolia)
if [ "$result" = "true" ]; then
    echo "✅ FeeManager 11155111"
else
    echo "⚠️ FeeManager 11155111"
fi

result=$(cast call $RWA1X_11155111 \
    "txSenders(address)(bool)" $TX_SENDER \
    --rpc-url sepolia-rpc-url \
    --chain sepolia)
if [ "$result" = "true" ]; then
    echo "✅ RWA1X 11155111"
else
    echo "⚠️ RWA1X 11155111"
fi

result=$(cast call $DEPLOYER_11155111 \
    "txSenders(address)(bool)" $TX_SENDER \
    --rpc-url sepolia-rpc-url \
    --chain sepolia)
if [ "$result" = "true" ]; then
    echo "✅ Deployer 11155111"
else
    echo "⚠️ Deployer 11155111"
fi

result=$(cast call $STORAGE_MANAGER_11155111 \
    "txSenders(address)(bool)" $TX_SENDER \
    --rpc-url sepolia-rpc-url \
    --chain sepolia)
if [ "$result" = "true" ]; then
    echo "✅ StorageManager 11155111"
else
    echo "⚠️ StorageManager 11155111"
fi

result=$(cast call $SENTRY_MANAGER_11155111 \
    "txSenders(address)(bool)" $TX_SENDER \
    --rpc-url sepolia-rpc-url \
    --chain sepolia)
if [ "$result" = "true" ]; then
    echo "✅ SentryManager 11155111"
else
    echo "⚠️ SentryManager 11155111"
fi

result=$(cast call $MAP_11155111 \
    "txSenders(address)(bool)" $TX_SENDER \
    --rpc-url sepolia-rpc-url \
    --chain sepolia)
if [ "$result" = "true" ]; then
    echo "✅ Map 11155111"
else
    echo "⚠️ Map 11155111"
fi
