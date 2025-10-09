#!/bin/bash

echo -e "\nSoneium Minato Testnet:"

result=$(cast call $GATEWAY_1946 \
    "txSenders(address)(bool)" $TX_SENDER \
    --rpc-url soneium-minato-testnet-rpc-url \
    --chain soneium-minato-testnet)
if [ "$result" = "true" ]; then
    echo "✅ Gateway 1946"
else
    echo "⚠️ Gateway 1946"
fi

result=$(cast call $FEE_MANAGER_1946 \
    "txSenders(address)(bool)" $TX_SENDER \
    --rpc-url soneium-minato-testnet-rpc-url \
    --chain soneium-minato-testnet)
if [ "$result" = "true" ]; then
    echo "✅ FeeManager 1946"
else
    echo "⚠️ FeeManager 1946"
fi

result=$(cast call $RWA1X_1946 \
    "txSenders(address)(bool)" $TX_SENDER \
    --rpc-url soneium-minato-testnet-rpc-url \
    --chain soneium-minato-testnet)
if [ "$result" = "true" ]; then
    echo "✅ RWA1X 1946"
else
    echo "⚠️ RWA1X 1946"
fi

result=$(cast call $DEPLOYER_1946 \
    "txSenders(address)(bool)" $TX_SENDER \
    --rpc-url soneium-minato-testnet-rpc-url \
    --chain soneium-minato-testnet)
if [ "$result" = "true" ]; then
    echo "✅ Deployer 1946"
else
    echo "⚠️ Deployer 1946"
fi

result=$(cast call $STORAGE_MANAGER_1946 \
    "txSenders(address)(bool)" $TX_SENDER \
    --rpc-url soneium-minato-testnet-rpc-url \
    --chain soneium-minato-testnet)
if [ "$result" = "true" ]; then
    echo "✅ StorageManager 1946"
else
    echo "⚠️ StorageManager 1946"
fi

result=$(cast call $SENTRY_MANAGER_1946 \
    "txSenders(address)(bool)" $TX_SENDER \
    --rpc-url soneium-minato-testnet-rpc-url \
    --chain soneium-minato-testnet)
if [ "$result" = "true" ]; then
    echo "✅ SentryManager 1946"
else
    echo "⚠️ SentryManager 1946"
fi

result=$(cast call $MAP_1946 \
    "txSenders(address)(bool)" $TX_SENDER \
    --rpc-url soneium-minato-testnet-rpc-url \
    --chain soneium-minato-testnet)
if [ "$result" = "true" ]; then
    echo "✅ Map 1946"
else
    echo "⚠️ Map 1946"
fi
