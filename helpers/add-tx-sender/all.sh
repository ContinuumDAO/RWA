#!/bin/bash

# Check if required arguments are provided
if [ $# -lt 2 ]; then
    echo "Error: Missing required arguments."
    echo "Usage: $0 <ACCOUNT> <PASSWORD_FILE>"
    echo "Example: $0 0x1234... /path/to/password.txt"
    exit 1
fi

./helpers/add-tx-sender/arbitrum-sepolia.sh $1 $2
./helpers/add-tx-sender/bsc-testnet.sh $1 $2
./helpers/add-tx-sender/sepolia.sh $1 $2
./helpers/add-tx-sender/base-sepolia.sh $1 $2
./helpers/add-tx-sender/avalanche-fuji.sh $1 $2
./helpers/add-tx-sender/holesky.sh $1 $2
./helpers/add-tx-sender/opbnb-testnet.sh $1 $2
./helpers/add-tx-sender/scroll-sepolia.sh $1 $2
./helpers/add-tx-sender/soneium-minato-testnet.sh $1 $2
