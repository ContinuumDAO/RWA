#!/bin/bash

echo -e "\nOPBNB Testnet:"

result=$(cast call $GATEWAY_5611 \
    "txSenders(address)(bool)" $TX_SENDER \
    --rpc-url opbnb-testnet-rpc-url \
    --chain opbnb-testnet)
if [ "$result" = "true" ]; then
    echo "✅ Gateway 5611"
else
    echo "⚠️ Gateway 5611"
fi

result=$(cast call $FEE_MANAGER_5611 \
    "txSenders(address)(bool)" $TX_SENDER \
    --rpc-url opbnb-testnet-rpc-url \
    --chain opbnb-testnet)
if [ "$result" = "true" ]; then
    echo "✅ FeeManager 5611"
else
    echo "⚠️ FeeManager 5611"
fi

result=$(cast call $RWA1X_5611 \
    "txSenders(address)(bool)" $TX_SENDER \
    --rpc-url opbnb-testnet-rpc-url \
    --chain opbnb-testnet)
if [ "$result" = "true" ]; then
    echo "✅ RWA1X 5611"
else
    echo "⚠️ RWA1X 5611"
fi

result=$(cast call $DEPLOYER_5611 \
    "txSenders(address)(bool)" $TX_SENDER \
    --rpc-url opbnb-testnet-rpc-url \
    --chain opbnb-testnet)
if [ "$result" = "true" ]; then
    echo "✅ Deployer 5611"
else
    echo "⚠️ Deployer 5611"
fi

result=$(cast call $STORAGE_MANAGER_5611 \
    "txSenders(address)(bool)" $TX_SENDER \
    --rpc-url opbnb-testnet-rpc-url \
    --chain opbnb-testnet)
if [ "$result" = "true" ]; then
    echo "✅ StorageManager 5611"
else
    echo "⚠️ StorageManager 5611"
fi

result=$(cast call $SENTRY_MANAGER_5611 \
    "txSenders(address)(bool)" $TX_SENDER \
    --rpc-url opbnb-testnet-rpc-url \
    --chain opbnb-testnet)
if [ "$result" = "true" ]; then
    echo "✅ SentryManager 5611"
else
    echo "⚠️ SentryManager 5611"
fi

result=$(cast call $MAP_5611 \
    "txSenders(address)(bool)" $TX_SENDER \
    --rpc-url opbnb-testnet-rpc-url \
    --chain opbnb-testnet)
if [ "$result" = "true" ]; then
    echo "✅ Map 5611"
else
    echo "⚠️ Map 5611"
fi
