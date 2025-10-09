#!/bin/bash

echo -e "\nScroll Sepolia:"

result=$(cast call $GATEWAY_534351 \
    "txSenders(address)(bool)" $TX_SENDER \
    --rpc-url scroll-sepolia-rpc-url \
    --chain scroll-sepolia)
if [ "$result" = "true" ]; then
    echo "✅ Gateway 534351"
else
    echo "⚠️ Gateway 534351"
fi

result=$(cast call $FEE_MANAGER_534351 \
    "txSenders(address)(bool)" $TX_SENDER \
    --rpc-url scroll-sepolia-rpc-url \
    --chain scroll-sepolia)
if [ "$result" = "true" ]; then
    echo "✅ FeeManager 534351"
else
    echo "⚠️ FeeManager 534351"
fi

result=$(cast call $RWA1X_534351 \
    "txSenders(address)(bool)" $TX_SENDER \
    --rpc-url scroll-sepolia-rpc-url \
    --chain scroll-sepolia)
if [ "$result" = "true" ]; then
    echo "✅ RWA1X 534351"
else
    echo "⚠️ RWA1X 534351"
fi

result=$(cast call $DEPLOYER_534351 \
    "txSenders(address)(bool)" $TX_SENDER \
    --rpc-url scroll-sepolia-rpc-url \
    --chain scroll-sepolia)
if [ "$result" = "true" ]; then
    echo "✅ Deployer 534351"
else
    echo "⚠️ Deployer 534351"
fi

result=$(cast call $STORAGE_MANAGER_534351 \
    "txSenders(address)(bool)" $TX_SENDER \
    --rpc-url scroll-sepolia-rpc-url \
    --chain scroll-sepolia)
if [ "$result" = "true" ]; then
    echo "✅ StorageManager 534351"
else
    echo "⚠️ StorageManager 534351"
fi

result=$(cast call $SENTRY_MANAGER_534351 \
    "txSenders(address)(bool)" $TX_SENDER \
    --rpc-url scroll-sepolia-rpc-url \
    --chain scroll-sepolia)
if [ "$result" = "true" ]; then
    echo "✅ SentryManager 534351"
else
    echo "⚠️ SentryManager 534351"
fi

result=$(cast call $MAP_534351 \
    "txSenders(address)(bool)" $TX_SENDER \
    --rpc-url scroll-sepolia-rpc-url \
    --chain scroll-sepolia)
if [ "$result" = "true" ]; then
    echo "✅ Map 534351"
else
    echo "⚠️ Map 534351"
fi
