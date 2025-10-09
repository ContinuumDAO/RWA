#!/bin/bash

echo -e "\nArbitrum Sepolia:"

result=$(cast call $GATEWAY_421614 \
    "txSenders(address)(bool)" $TX_SENDER \
    --rpc-url arbitrum-sepolia-rpc-url \
    --chain arbitrum-sepolia)
if [ "$result" = "true" ]; then
    echo "✅ Gateway 421614"
else
    echo "⚠️ Gateway 421614"
fi

result=$(cast call $FEE_MANAGER_421614 \
    "txSenders(address)(bool)" $TX_SENDER \
    --rpc-url arbitrum-sepolia-rpc-url \
    --chain arbitrum-sepolia)
if [ "$result" = "true" ]; then
    echo "✅ FeeManager 421614"
else
    echo "⚠️ FeeManager 421614"
fi

result=$(cast call $RWA1X_421614 \
    "txSenders(address)(bool)" $TX_SENDER \
    --rpc-url arbitrum-sepolia-rpc-url \
    --chain arbitrum-sepolia)
if [ "$result" = "true" ]; then
    echo "✅ RWA1X 421614"
else
    echo "⚠️ RWA1X 421614"
fi

result=$(cast call $DEPLOYER_421614 \
    "txSenders(address)(bool)" $TX_SENDER \
    --rpc-url arbitrum-sepolia-rpc-url \
    --chain arbitrum-sepolia)
if [ "$result" = "true" ]; then
    echo "✅ Deployer 421614"
else
    echo "⚠️ Deployer 421614"
fi

result=$(cast call $STORAGE_MANAGER_421614 \
    "txSenders(address)(bool)" $TX_SENDER \
    --rpc-url arbitrum-sepolia-rpc-url \
    --chain arbitrum-sepolia)
if [ "$result" = "true" ]; then
    echo "✅ StorageManager 421614"
else
    echo "⚠️ StorageManager 421614"
fi

result=$(cast call $SENTRY_MANAGER_421614 \
    "txSenders(address)(bool)" $TX_SENDER \
    --rpc-url arbitrum-sepolia-rpc-url \
    --chain arbitrum-sepolia)
if [ "$result" = "true" ]; then
    echo "✅ SentryManager 421614"
else
    echo "⚠️ SentryManager 421614"
fi

result=$(cast call $MAP_421614 \
    "txSenders(address)(bool)" $TX_SENDER \
    --rpc-url arbitrum-sepolia-rpc-url \
    --chain arbitrum-sepolia)
if [ "$result" = "true" ]; then
    echo "✅ Map 421614"
else
    echo "⚠️ Map 421614"
fi
