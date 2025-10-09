#!/bin/bash

echo -e "\nHolesky:"

result=$(cast call $GATEWAY_17000 \
    "txSenders(address)(bool)" $TX_SENDER \
    --rpc-url holesky-rpc-url \
    --chain holesky)
if [ "$result" = "true" ]; then
    echo "✅ Gateway 17000"
else
    echo "⚠️ Gateway 17000"
fi

result=$(cast call $FEE_MANAGER_17000 \
    "txSenders(address)(bool)" $TX_SENDER \
    --rpc-url holesky-rpc-url \
    --chain holesky)
if [ "$result" = "true" ]; then
    echo "✅ FeeManager 17000"
else
    echo "⚠️ FeeManager 17000"
fi

result=$(cast call $RWA1X_17000 \
    "txSenders(address)(bool)" $TX_SENDER \
    --rpc-url holesky-rpc-url \
    --chain holesky)
if [ "$result" = "true" ]; then
    echo "✅ RWA1X 17000"
else
    echo "⚠️ RWA1X 17000"
fi

result=$(cast call $DEPLOYER_17000 \
    "txSenders(address)(bool)" $TX_SENDER \
    --rpc-url holesky-rpc-url \
    --chain holesky)
if [ "$result" = "true" ]; then
    echo "✅ Deployer 17000"
else
    echo "⚠️ Deployer 17000"
fi

result=$(cast call $STORAGE_MANAGER_17000 \
    "txSenders(address)(bool)" $TX_SENDER \
    --rpc-url holesky-rpc-url \
    --chain holesky)
if [ "$result" = "true" ]; then
    echo "✅ StorageManager 17000"
else
    echo "⚠️ StorageManager 17000"
fi

result=$(cast call $SENTRY_MANAGER_17000 \
    "txSenders(address)(bool)" $TX_SENDER \
    --rpc-url holesky-rpc-url \
    --chain holesky)
if [ "$result" = "true" ]; then
    echo "✅ SentryManager 17000"
else
    echo "⚠️ SentryManager 17000"
fi

result=$(cast call $MAP_17000 \
    "txSenders(address)(bool)" $TX_SENDER \
    --rpc-url holesky-rpc-url \
    --chain holesky)
if [ "$result" = "true" ]; then
    echo "✅ Map 17000"
else
    echo "⚠️ Map 17000"
fi
