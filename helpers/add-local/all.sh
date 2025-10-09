#!/bin/bash

# Check if required arguments are provided
if [ $# -lt 2 ]; then
    echo "Error: Missing required arguments."
    echo "Usage: $0 <ACCOUNT> <PASSWORD_FILE>"
    echo "Example: $0 0x1234... /path/to/password.txt"
    exit 1
fi

./helpers/add-local/arbitrum-sepolia.sh $1 $2
./helpers/add-local/arbitrum-sepolia.sh $1 $2
./helpers/add-local/arbitrum-sepolia.sh $1 $2
./helpers/add-local/bsc-testnet.sh $1 $2
./helpers/add-local/holesky.sh $1 $2
./helpers/add-local/opbnb-testnet.sh $1 $2
./helpers/add-local/scroll-sepolia.sh $1 $2
./helpers/add-local/sepolia.sh $1 $2
./helpers/add-local/soneium-minato-testnet.sh $1 $2
