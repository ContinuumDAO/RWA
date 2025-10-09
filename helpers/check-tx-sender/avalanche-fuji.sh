#!/bin/bash

echo -e "\nAvalanche Fuji:"

result=$(cast call $GATEWAY_43113 \
    "txSenders(address)(bool)" $TX_SENDER \
    --rpc-url avalanche-fuji-rpc-url \
    --chain avalanche-fuji)
if [ "$result" = "true" ]; then
    echo "✅ Gateway 43113"
else
    echo "⚠️ Gateway 43113"
fi

result=$(cast call $FEE_MANAGER_43113 \
    "txSenders(address)(bool)" $TX_SENDER \
    --rpc-url avalanche-fuji-rpc-url \
    --chain avalanche-fuji)
if [ "$result" = "true" ]; then
    echo "✅ FeeManager 43113"
else
    echo "⚠️ FeeManager 43113"
fi

result=$(cast call $RWA1X_43113 \
    "txSenders(address)(bool)" $TX_SENDER \
    --rpc-url avalanche-fuji-rpc-url \
    --chain avalanche-fuji)
if [ "$result" = "true" ]; then
    echo "✅ RWA1X 43113"
else
    echo "⚠️ RWA1X 43113"
fi

result=$(cast call $DEPLOYER_43113 \
    "txSenders(address)(bool)" $TX_SENDER \
    --rpc-url avalanche-fuji-rpc-url \
    --chain avalanche-fuji)
if [ "$result" = "true" ]; then
    echo "✅ Deployer 43113"
else
    echo "⚠️ Deployer 43113"
fi

result=$(cast call $STORAGE_MANAGER_43113 \
    "txSenders(address)(bool)" $TX_SENDER \
    --rpc-url avalanche-fuji-rpc-url \
    --chain avalanche-fuji)
if [ "$result" = "true" ]; then
    echo "✅ StorageManager 43113"
else
    echo "⚠️ StorageManager 43113"
fi

result=$(cast call $SENTRY_MANAGER_43113 \
    "txSenders(address)(bool)" $TX_SENDER \
    --rpc-url avalanche-fuji-rpc-url \
    --chain avalanche-fuji)
if [ "$result" = "true" ]; then
    echo "✅ SentryManager 43113"
else
    echo "⚠️ SentryManager 43113"
fi

result=$(cast call $MAP_43113 \
    "txSenders(address)(bool)" $TX_SENDER \
    --rpc-url avalanche-fuji-rpc-url \
    --chain avalanche-fuji)
if [ "$result" = "true" ]; then
    echo "✅ Map 43113"
else
    echo "⚠️ Map 43113"
fi
